import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../algorithms/automaton_simulator.dart';
import '../algorithms/brute_force_cfg_parser.dart';
import '../algorithms/grammar_parser.dart';
import '../algorithms/grammar_input_tokenizer.dart';
import '../algorithms/pda_simulator.dart';
import '../algorithms/regex_to_nfa_converter.dart';
import '../algorithms/tm_block_execution_engine.dart';
import '../algorithms/tm_execution_analyzer.dart';
import '../models/brute_force_parse_models.dart';
import '../models/fsa.dart';
import '../models/grammar.dart';
import '../models/grammar_parse_report.dart';
import '../models/pda.dart';
import '../models/regex_document.dart';
import '../models/simulation_step.dart';
import '../models/tm.dart';
import '../models/tm_building_blocks.dart';
import '../models/tm_execution_analysis.dart';
import '../messages/structured_message.dart';
import '../result.dart';
import '../simulation_cancelled_exception.dart';
import '../transducers/transducers.dart';
import 'batch_execution_models.dart';
import 'batch_execution_runner.dart';

final class FsaBatchExecutor implements BatchCaseExecutor {
  const FsaBatchExecutor(this.automaton);

  final FSA automaton;

  @override
  String get modelId => automaton.id;

  @override
  String get modelRevision => automaton.modified.toUtc().toIso8601String();

  @override
  Set<String> get strategyIds => const {'simulate'};

  @override
  Future<BatchCaseExecution> execute(
    BatchInputCase inputCase, {
    required String strategyId,
    required BatchTokenizationMode tokenizationMode,
    required BatchExecutionLimits limits,
    required bool retainTrace,
    required BatchCancellationToken cancellationToken,
  }) async {
    final tokenError = _unsupportedScalarTokens(inputCase, tokenizationMode);
    if (tokenError != null) return tokenError;
    if (cancellationToken.isCancelled) return _cancelled();
    final input = _scalarInput(inputCase, tokenizationMode);
    final inputLength = await _boundedScalarCount(
      input,
      limit: limits.maxSteps,
      cancellationToken: cancellationToken,
    );
    if (inputLength == null) return _cancelled();
    if (inputLength > limits.maxSteps) {
      return BatchCaseExecution(
        outcome: BatchOutcomeCode.boundedUnknown,
        diagnosticCode: 'fsa.step-limit',
        metrics: {'steps': limits.maxSteps},
      );
    }
    final configurationCount = inputLength + 1;
    if (configurationCount > limits.maxConfigurations) {
      return BatchCaseExecution(
        outcome: BatchOutcomeCode.configurationLimit,
        diagnosticCode: 'fsa.configuration-limit',
        metrics: {
          'steps': inputLength,
          'configurations': limits.maxConfigurations,
        },
      );
    }
    final outcome = await AutomatonSimulator.simulate(
      automaton,
      input,
      stepByStep: retainTrace,
      timeout: limits.timeout,
    );
    if (cancellationToken.isCancelled) return _cancelled();
    if (!outcome.isSuccess) {
      return _algorithmFailure(outcome.error, 'fsa.simulation-invalid');
    }
    final result = outcome.data!;
    final code = result.isTimeout
        ? BatchOutcomeCode.timeout
        : result.isInfiniteLoop
        ? BatchOutcomeCode.boundedUnknown
        : result.accepted
        ? BatchOutcomeCode.accepted
        : BatchOutcomeCode.rejected;
    return BatchCaseExecution(
      outcome: code,
      diagnosticCode: switch (code) {
        BatchOutcomeCode.timeout => 'fsa.simulation-timeout',
        BatchOutcomeCode.boundedUnknown => 'fsa.simulation-bounded',
        BatchOutcomeCode.rejected => 'fsa.rejected',
        _ => null,
      },
      message: result.errorMessage.isEmpty ? null : result.errorMessage,
      metrics: {
        'steps': inputLength,
        'configurations': configurationCount,
        'executionMicros': result.executionTime.inMicroseconds,
      },
      trace: retainTrace ? _simulationTrace(result.steps) : const [],
    );
  }
}

Future<int?> _boundedScalarCount(
  String input, {
  required int limit,
  required BatchCancellationToken cancellationToken,
}) async {
  var count = 0;
  for (final _ in input.runes) {
    if (cancellationToken.isCancelled) return null;
    count++;
    if (count > limit) return count;
    if (count % 256 == 0) await Future<void>.delayed(Duration.zero);
  }
  return cancellationToken.isCancelled ? null : count;
}

final class RegexBatchExecutor implements BatchCaseExecutor {
  RegexBatchExecutor(this.document)
    : _conversion = RegexToNFAConverter.convert(
        document.source,
        contextAlphabet: document.alphabet.toSet(),
      );

  final RegexDocument document;
  final Result<FSA> _conversion;

  @override
  String get modelId => document.id;

  @override
  String get modelRevision => _stableRevision({
    'source': document.source,
    'alphabet': [...document.alphabet]..sort(),
    'dialect': document.dialect.name,
    'tokenization': document.tokenization.name,
  });

  @override
  Set<String> get strategyIds => const {'match'};

  @override
  Future<BatchCaseExecution> execute(
    BatchInputCase inputCase, {
    required String strategyId,
    required BatchTokenizationMode tokenizationMode,
    required BatchExecutionLimits limits,
    required bool retainTrace,
    required BatchCancellationToken cancellationToken,
  }) async {
    if (!_conversion.isSuccess) {
      return BatchCaseExecution(
        outcome: BatchOutcomeCode.modelError,
        diagnosticCode: 'regex.invalid-expression',
        message: _conversion.error,
      );
    }
    final delegate = FsaBatchExecutor(_conversion.data!);
    final result = await delegate.execute(
      inputCase,
      strategyId: 'simulate',
      tokenizationMode: tokenizationMode,
      limits: limits,
      retainTrace: retainTrace,
      cancellationToken: cancellationToken,
    );
    return BatchCaseExecution(
      outcome: result.outcome,
      diagnosticCode: result.diagnosticCode?.replaceFirst('fsa.', 'regex.'),
      message: result.message,
      metrics: result.metrics,
      trace: result.trace,
    );
  }
}

final class PdaBatchExecutor implements BatchCaseExecutor {
  const PdaBatchExecutor(this.automaton);

  final PDA automaton;

  @override
  String get modelId => automaton.id;

  @override
  String get modelRevision => automaton.modified.toUtc().toIso8601String();

  @override
  Set<String> get strategyIds => const {'simulate'};

  @override
  Future<BatchCaseExecution> execute(
    BatchInputCase inputCase, {
    required String strategyId,
    required BatchTokenizationMode tokenizationMode,
    required BatchExecutionLimits limits,
    required bool retainTrace,
    required BatchCancellationToken cancellationToken,
  }) async {
    final tokenError = _unsupportedScalarTokens(inputCase, tokenizationMode);
    if (tokenError != null) return tokenError;
    try {
      final outcome = await PDASimulator.simulateCooperative(
        automaton,
        _scalarInput(inputCase, tokenizationMode),
        stepByStep: retainTrace,
        timeout: limits.timeout,
        mode: automaton.acceptanceMode,
        maxDepth: limits.maxSteps,
        maxConfigurations: limits.maxConfigurations,
        isCancelled: () => cancellationToken.isCancelled,
      );
      if (!outcome.isSuccess) {
        return _algorithmFailure(outcome.error, 'pda.simulation-invalid');
      }
      final result = outcome.data!;
      final code = switch (result.errorMessage) {
        PDA_SIMULATION_TIMEOUT_ERROR => BatchOutcomeCode.timeout,
        PDA_SIMULATION_LIMIT_REACHED_ERROR ||
        PDA_SIMULATION_INFINITE_LOOP_ERROR => BatchOutcomeCode.boundedUnknown,
        _ =>
          result.accepted
              ? BatchOutcomeCode.accepted
              : BatchOutcomeCode.rejected,
      };
      return BatchCaseExecution(
        outcome: code,
        diagnosticCode: switch (code) {
          BatchOutcomeCode.timeout => 'pda.simulation-timeout',
          BatchOutcomeCode.boundedUnknown => 'pda.simulation-bounded',
          BatchOutcomeCode.rejected => 'pda.rejected',
          _ => null,
        },
        message: result.errorMessage,
        metrics: {
          'steps': result.steps.length,
          'executionMicros': result.executionTime.inMicroseconds,
        },
        trace: retainTrace ? _simulationTrace(result.steps) : const [],
      );
    } on SimulationCancelledException {
      return _cancelled();
    }
  }
}

final class TmBatchExecutor implements BatchCaseExecutor {
  const TmBatchExecutor(this.machine, {this.blockProject});

  final TM machine;
  final TMBlockProject? blockProject;

  @override
  String get modelId => machine.id;

  @override
  String get modelRevision => machine.modified.toUtc().toIso8601String();

  @override
  Set<String> get strategyIds => {
    'simulate',
    if (blockProject != null) 'buildingBlocks',
  };

  @override
  Future<BatchCaseExecution> execute(
    BatchInputCase inputCase, {
    required String strategyId,
    required BatchTokenizationMode tokenizationMode,
    required BatchExecutionLimits limits,
    required bool retainTrace,
    required BatchCancellationToken cancellationToken,
  }) async {
    if (strategyId == 'buildingBlocks') {
      final tokenError = _unsupportedScalarTokens(inputCase, tokenizationMode);
      if (tokenError != null) return tokenError;
      return _executeBlocks(
        inputCase,
        tokenizationMode,
        limits,
        retainTrace,
        cancellationToken,
      );
    }
    final tokens = _tokens(inputCase, tokenizationMode);
    final result = await TMExecutionAnalyzer.analyzeTokens(
      machine,
      tokens,
      maxSteps: limits.maxSteps,
      maxConfigurations: limits.maxConfigurations,
      timeout: limits.timeout,
      includeTrace: retainTrace,
      isCancelled: () => cancellationToken.isCancelled,
    );
    return _tmExecution(result, retainTrace);
  }

  BatchCaseExecution _executeBlocks(
    BatchInputCase inputCase,
    BatchTokenizationMode tokenizationMode,
    BatchExecutionLimits limits,
    bool retainTrace,
    BatchCancellationToken cancellationToken,
  ) {
    final project = blockProject;
    if (project == null) {
      return BatchCaseExecution(
        outcome: BatchOutcomeCode.modelError,
        diagnosticCode: 'tm.missing-block-project',
      );
    }
    final result = TMBlockExecutionEngine.execute(
      project,
      _scalarInput(inputCase, tokenizationMode),
      maxSteps: limits.maxSteps,
      maxConfigurations: limits.maxConfigurations,
      timeout: limits.timeout,
      includeTrace: retainTrace,
      isCancelled: () => cancellationToken.isCancelled,
    );
    return BatchCaseExecution(
      outcome: _tmOutcome(result.outcome, result.limit),
      diagnosticCode: result.diagnostics.isEmpty
          ? _tmDiagnostic(result.outcome, result.limit)
          : 'tm.block.${result.diagnostics.first.code.name}',
      message: result.message,
      structuredMessage: _tmPolicyMessage(
        result.acceptancePolicy.name,
        result.acceptanceReason.name,
      ),
      metrics: {
        'steps': result.stepsExecuted,
        'configurations': result.configurationsExplored,
        'blockEntries': result.metrics.blockEntries,
        'blockReturns': result.metrics.blockReturns,
      },
      trace: retainTrace
          ? result.trace.map((step) => step.toJson()).toList()
          : const [],
    );
  }
}

final class GrammarBatchExecutor implements BatchCaseExecutor {
  const GrammarBatchExecutor(this.grammar);

  final Grammar grammar;

  @override
  String get modelId => grammar.id;

  @override
  String get modelRevision => _stableRevision({
    'terminals': [...grammar.terminals]..sort(),
    'nonterminals': [...grammar.nonterminals]..sort(),
    'startSymbol': grammar.startSymbol,
    'type': grammar.type.name,
    'productions':
        grammar.productions.map((production) => production.toJson()).toList()
          ..sort(
            (left, right) => jsonEncode(left).compareTo(jsonEncode(right)),
          ),
  });

  @override
  Set<String> get strategyIds => {
    for (final strategy in ParsingStrategyHint.values) strategy.name,
  };

  @override
  Future<BatchCaseExecution> execute(
    BatchInputCase inputCase, {
    required String strategyId,
    required BatchTokenizationMode tokenizationMode,
    required BatchExecutionLimits limits,
    required bool retainTrace,
    required BatchCancellationToken cancellationToken,
  }) async {
    final grammarErrors = grammar.validate();
    if (grammarErrors.isNotEmpty) {
      return BatchCaseExecution(
        outcome: BatchOutcomeCode.modelError,
        diagnosticCode: 'grammar.invalid-model',
        message: grammarErrors.first,
      );
    }
    final normalizedInput = _normalizedGrammarInput(
      grammar,
      inputCase,
      tokenizationMode,
    );
    if (normalizedInput case final BatchCaseExecution failure) return failure;
    final normalizedCase = BatchInputCase(
      id: inputCase.id,
      input: normalizedInput as String,
      tokens: inputCase.tokens,
    );
    final strategy = ParsingStrategyHint.values.byName(strategyId);
    if (strategy == ParsingStrategyHint.bruteForce) {
      return _executeBruteForce(
        normalizedCase,
        limits,
        retainTrace,
        cancellationToken,
      );
    }
    if (cancellationToken.isCancelled) return _cancelled();
    final outcome = GrammarParser.parseWithReport(
      grammar,
      normalizedCase.input,
      timeout: limits.timeout,
      maxSteps: limits.maxSteps,
      maxStates: limits.maxConfigurations,
      maxItems: limits.maxConfigurations,
      isCancelled: () => cancellationToken.isCancelled,
      strategyHint: strategy,
    );
    if (!outcome.isSuccess) {
      return BatchCaseExecution(
        outcome: BatchOutcomeCode.invalidInput,
        diagnosticCode: 'grammar.invalid-input',
        message: outcome.error,
      );
    }
    return _grammarExecution(outcome.data!, retainTrace);
  }

  Future<BatchCaseExecution> _executeBruteForce(
    BatchInputCase inputCase,
    BatchExecutionLimits limits,
    bool retainTrace,
    BatchCancellationToken cancellationToken,
  ) async {
    final token = BruteForceCancellationToken();
    final result = await BruteForceCFGParser.searchAsync(
      grammar,
      inputCase.input,
      limits: BruteForceSearchLimits(
        maxDepth: limits.maxSteps,
        maxExploredNodes: limits.maxConfigurations,
        maxFrontierSize: limits.maxConfigurations,
        maxRetainedStates: limits.maxConfigurations,
        resultCap: 1,
        timeLimit: limits.timeout,
      ),
      cancellationToken: token,
      onProgress: (_) {
        if (cancellationToken.isCancelled) token.cancel();
      },
    );
    return BatchCaseExecution(
      outcome: switch (result.outcome) {
        BruteForceParseOutcome.accepted => BatchOutcomeCode.accepted,
        BruteForceParseOutcome.rejected => BatchOutcomeCode.rejected,
        BruteForceParseOutcome.boundedUnknown =>
          BatchOutcomeCode.boundedUnknown,
        BruteForceParseOutcome.cancelled => BatchOutcomeCode.cancelled,
        BruteForceParseOutcome.invalidGrammar => BatchOutcomeCode.modelError,
        BruteForceParseOutcome.invalidInput => BatchOutcomeCode.invalidInput,
      },
      diagnosticCode: result.diagnostic == null
          ? null
          : 'grammar.brute.${result.diagnostic!.name}',
      message: result.message,
      structuredMessage: result.structuredMessage,
      metrics: {
        'steps': result.statistics.currentDepth,
        'configurations': result.statistics.exploredNodes,
        'witnesses': result.witnessCount,
      },
      trace: retainTrace && result.witnesses.isNotEmpty
          ? result.witnesses.first.steps
                .map((step) => step.toJson().cast<String, Object?>())
                .toList()
          : const [],
    );
  }
}

final class TransducerBatchExecutor implements BatchCaseExecutor {
  TransducerBatchExecutor(this.machine)
    : simulator = switch (machine) {
        MealyMachine value => DeterministicTransducerSimulator.mealy(value),
        MooreMachine value => DeterministicTransducerSimulator.moore(value),
        _ => throw ArgumentError.value(machine, 'machine'),
      };

  final DeterministicFiniteStateTransducer machine;
  final DeterministicTransducerSimulator simulator;

  @override
  String get modelId => machine.id.value;

  @override
  String get modelRevision => machine.revision.value.toString();

  @override
  Set<String> get strategyIds => const {'simulate'};

  @override
  Future<BatchCaseExecution> execute(
    BatchInputCase inputCase, {
    required String strategyId,
    required BatchTokenizationMode tokenizationMode,
    required BatchExecutionLimits limits,
    required bool retainTrace,
    required BatchCancellationToken cancellationToken,
  }) async {
    final transducerCancellation = TransducerCancellationToken();
    final options = TransducerSimulationOptions(
      maxSteps: limits.maxSteps,
      maxRetainedTraceSteps: limits.maxRetainedTraceSteps,
      retainTrace: retainTrace,
      cancellationToken: transducerCancellation,
      cancellationCheckpoint: (_) {
        if (cancellationToken.isCancelled) transducerCancellation.cancel();
        return cancellationToken.isCancelled;
      },
    );
    final tokens = inputCase.tokens;
    final outcome =
        tokenizationMode == BatchTokenizationMode.explicitTokens &&
            tokens != null
        ? simulator.run(
            TransducerInputWord.fromValues(tokens),
            options: options,
          )
        : simulator.runRaw(inputCase.input, options: options);
    return BatchCaseExecution(
      outcome: switch (outcome) {
        TransducerSuccess() => BatchOutcomeCode.output,
        TransducerIncomplete() => BatchOutcomeCode.undefinedTransition,
        TransducerInvalidMachine() => BatchOutcomeCode.modelError,
        TransducerInvalidInput() => BatchOutcomeCode.invalidInput,
        TransducerCancelled() => BatchOutcomeCode.cancelled,
        TransducerBounded() => BatchOutcomeCode.boundedUnknown,
      },
      diagnosticCode: switch (outcome) {
        TransducerSuccess() => null,
        TransducerIncomplete() => 'transducer.undefined-transition',
        TransducerInvalidMachine() => 'transducer.invalid-machine',
        TransducerInvalidInput() => 'transducer.invalid-input',
        TransducerCancelled() => 'transducer.cancelled',
        TransducerBounded() => 'transducer.step-limit',
      },
      output: outcome.output.values,
      metrics: {'steps': outcome.processedInputCount},
      trace: retainTrace
          ? outcome.trace.map(_transducerTraceStep).toList()
          : const [],
    );
  }
}

BatchCaseExecution _tmExecution(TMExecutionAnalysis result, bool retainTrace) =>
    BatchCaseExecution(
      outcome: _tmOutcome(result.outcome, result.limit),
      diagnosticCode: _tmDiagnostic(result.outcome, result.limit),
      message: result.message,
      structuredMessage: _tmPolicyMessage(
        result.acceptancePolicy.name,
        result.acceptanceReason.name,
      ),
      metrics: {
        'steps': result.stepsExecuted,
        'configurations': result.configurationsExplored,
      },
      trace: retainTrace
          ? [
              ..._simulationTrace(result.trace),
              ...result.multiTapeTrace.map(_multiTapeTraceStep),
            ]
          : const [],
    );

String _stableRevision(Object value) {
  final source = jsonEncode(value);
  return sha256.convert(utf8.encode(source)).toString();
}

BatchOutcomeCode _tmOutcome(
  TMExecutionOutcome outcome,
  TMExecutionLimit? limit,
) => switch (outcome) {
  TMExecutionOutcome.accepted => BatchOutcomeCode.accepted,
  TMExecutionOutcome.haltedRejected => BatchOutcomeCode.rejected,
  TMExecutionOutcome.provenCycle => BatchOutcomeCode.provenCycle,
  TMExecutionOutcome.boundedUnknown => switch (limit) {
    TMExecutionLimit.timeout => BatchOutcomeCode.timeout,
    TMExecutionLimit.configurations => BatchOutcomeCode.configurationLimit,
    TMExecutionLimit.steps || null => BatchOutcomeCode.boundedUnknown,
  },
  TMExecutionOutcome.cancelled => BatchOutcomeCode.cancelled,
  TMExecutionOutcome.invalidMachine => BatchOutcomeCode.modelError,
};

String? _tmDiagnostic(TMExecutionOutcome outcome, TMExecutionLimit? limit) =>
    switch (outcome) {
      TMExecutionOutcome.accepted => null,
      TMExecutionOutcome.haltedRejected => 'tm.rejected',
      TMExecutionOutcome.provenCycle => 'tm.proven-cycle',
      TMExecutionOutcome.boundedUnknown =>
        'tm.${limit?.name ?? 'bounded-unknown'}',
      TMExecutionOutcome.cancelled => 'tm.cancelled',
      TMExecutionOutcome.invalidMachine => 'tm.invalid-machine',
    };

BatchCaseExecution _grammarExecution(
  GrammarParseReport result,
  bool retainTrace,
) => BatchCaseExecution(
  outcome: switch (result.outcome) {
    GrammarParseOutcome.accepted => BatchOutcomeCode.accepted,
    GrammarParseOutcome.rejected => BatchOutcomeCode.rejected,
    GrammarParseOutcome.conflict => BatchOutcomeCode.conflict,
    GrammarParseOutcome.timedOut => BatchOutcomeCode.timeout,
    GrammarParseOutcome.cancelled => BatchOutcomeCode.cancelled,
    GrammarParseOutcome.stepLimit ||
    GrammarParseOutcome.boundedUnknown => BatchOutcomeCode.boundedUnknown,
    GrammarParseOutcome.invalidInput ||
    GrammarParseOutcome.tokenizationFailure => BatchOutcomeCode.invalidInput,
  },
  diagnosticCode: result.outcome == GrammarParseOutcome.accepted
      ? null
      : 'grammar.${result.outcome.name}',
  message: result.message,
  metrics: {
    'steps': result.ll1Steps.isNotEmpty
        ? result.ll1Steps.length
        : result.lr1Steps.length,
    'executionMicros': result.executionTime.inMicroseconds,
    'trees': result.trees.length,
  },
  trace: retainTrace
      ? [
          for (final step in result.ll1Steps)
            {
              'step': step.stepNumber,
              'action': step.action.name,
              'stack': step.stack,
              'remainingInput': step.remainingInput,
              'lookahead': step.lookahead,
              'productionId': step.productionId,
              'diagnostic': step.diagnostic?.name,
            },
          for (final step in result.lr1Steps)
            {
              'step': step.stepNumber,
              'state': step.lookupState,
              'remainingInput': step.remainingInput,
              'lookahead': step.lookahead,
              'action': step.action?.toString(),
              'productionId': step.reducedProductionId,
              'diagnostic': step.diagnostic?.name,
            },
        ]
      : const [],
);

BatchCaseExecution _algorithmFailure(String? message, String code) =>
    BatchCaseExecution(
      outcome: message?.toLowerCase().contains('input') ?? false
          ? BatchOutcomeCode.invalidInput
          : BatchOutcomeCode.modelError,
      diagnosticCode: code,
      message: message,
    );

BatchCaseExecution? _unsupportedScalarTokens(
  BatchInputCase inputCase,
  BatchTokenizationMode tokenizationMode,
) {
  if (tokenizationMode != BatchTokenizationMode.explicitTokens ||
      inputCase.tokens == null) {
    return null;
  }
  if (inputCase.tokens!.any((token) => token.runes.length != 1)) {
    return BatchCaseExecution(
      outcome: BatchOutcomeCode.invalidInput,
      diagnosticCode: 'batch.scalar-tokenization-required',
      structuredMessage: _executionMessage('scalar-tokenization-required'),
    );
  }
  return null;
}

List<String> _tokens(
  BatchInputCase inputCase,
  BatchTokenizationMode tokenizationMode,
) =>
    tokenizationMode == BatchTokenizationMode.explicitTokens &&
        inputCase.tokens != null
    ? inputCase.tokens!
    : inputCase.input.runes.map(String.fromCharCode).toList();

Object _normalizedGrammarInput(
  Grammar grammar,
  BatchInputCase inputCase,
  BatchTokenizationMode tokenizationMode,
) {
  if (tokenizationMode != BatchTokenizationMode.explicitTokens) {
    return inputCase.input;
  }
  final tokens = inputCase.tokens!;
  final joined = tokens.join();
  final canonical = GrammarInputTokenizer.tokenize(grammar, joined);
  if (!canonical.isSuccess ||
      !_sameStrings(canonical.data!.map((token) => token.lexeme), tokens)) {
    return BatchCaseExecution(
      outcome: BatchOutcomeCode.invalidInput,
      diagnosticCode: 'grammar.explicit-tokenization-mismatch',
      structuredMessage: _executionMessage('grammar-tokenization-mismatch'),
    );
  }
  return joined;
}

bool _sameStrings(Iterable<String> left, List<String> right) {
  final leftValues = left.toList(growable: false);
  if (leftValues.length != right.length) return false;
  for (var index = 0; index < leftValues.length; index++) {
    if (leftValues[index] != right[index]) return false;
  }
  return true;
}

String _scalarInput(
  BatchInputCase inputCase,
  BatchTokenizationMode tokenizationMode,
) =>
    tokenizationMode == BatchTokenizationMode.explicitTokens &&
        inputCase.tokens != null
    ? inputCase.tokens!.join()
    : inputCase.input;

BatchCaseExecution _cancelled() => BatchCaseExecution(
  outcome: BatchOutcomeCode.cancelled,
  diagnosticCode: 'batch.cancelled',
);

StructuredMessage _executionMessage(
  String code, {
  Map<String, StructuredMessageArgument> arguments = const {},
}) => StructuredMessage(
  namespace: 'batch.execution',
  code: code,
  category: StructuredMessageCategory.simulation,
  severity: StructuredMessageSeverity.error,
  arguments: arguments,
);

StructuredMessage _tmPolicyMessage(String policy, String reason) =>
    _executionMessage(
      'tm-policy-reason',
      arguments: {
        'policy': StructuredMessageArgument.outcome(
          policy,
          role: 'tm-acceptance-policy',
        ),
        'reason': StructuredMessageArgument.outcome(
          reason,
          role: 'tm-acceptance-reason',
        ),
      },
    );

List<Map<String, Object?>> _simulationTrace(Iterable<SimulationStep> steps) =>
    steps
        .map((step) => step.toJson().cast<String, Object?>())
        .toList(growable: false);

Map<String, Object?> _multiTapeTraceStep(TMMultiTapeTraceStep step) => {
  'step': step.step,
  'fromStateId': step.fromStateId,
  'toStateId': step.toStateId,
  'transitionId': step.transitionId,
  'readSymbols': step.readSymbols,
  'writeSymbols': step.writeSymbols,
  'directions': step.directions.map((direction) => direction.name).toList(),
  'stateId': step.configuration.stateId,
  'headPositions': step.configuration.headPositions,
};

Map<String, Object?> _transducerTraceStep(TransducerExecutionStep step) => {
  'step': step.index,
  'sourceStateId': step.sourceStateId.value,
  'targetStateId': step.targetStateId.value,
  'transitionId': step.transitionId.value,
  'consumedInput': step.consumedInput.value,
  'emittedOutput': step.emittedOutput.values,
  'cumulativeOutput': step.cumulativeOutput.values,
  'remainingInput': step.remainingInput.values.toList(),
  'sourceRevision': step.sourceRevision.value,
};
