import '../messages/structured_message.dart';
import 'transducer_analysis.dart';
import 'transducer_emission_rule.dart';
import 'transducer_ids.dart';
import 'transducer_models.dart';
import 'transducer_symbols.dart';

final class TransducerCancellationToken {
  bool _isCancelled = false;

  bool get isCancelled => _isCancelled;

  void cancel() => _isCancelled = true;
}

typedef TransducerCancellationCheckpoint =
    bool Function(int processedInputCount);

final class TransducerSimulationOptions {
  const TransducerSimulationOptions({
    this.maxSteps = 100000,
    this.maxRetainedTraceSteps = 1000,
    this.retainTrace = true,
    this.cancellationToken,
    this.cancellationCheckpoint,
  });

  final int maxSteps;
  final int maxRetainedTraceSteps;
  final bool retainTrace;
  final TransducerCancellationToken? cancellationToken;
  final TransducerCancellationCheckpoint? cancellationCheckpoint;

  TransducerSimulationOptions copyWith({
    int? maxSteps,
    int? maxRetainedTraceSteps,
    bool? retainTrace,
    TransducerCancellationToken? cancellationToken,
    TransducerCancellationCheckpoint? cancellationCheckpoint,
  }) => TransducerSimulationOptions(
    maxSteps: maxSteps ?? this.maxSteps,
    maxRetainedTraceSteps: maxRetainedTraceSteps ?? this.maxRetainedTraceSteps,
    retainTrace: retainTrace ?? this.retainTrace,
    cancellationToken: cancellationToken ?? this.cancellationToken,
    cancellationCheckpoint:
        cancellationCheckpoint ?? this.cancellationCheckpoint,
  );
}

final class TransducerExecutionStep {
  const TransducerExecutionStep({
    required this.index,
    required this.sourceStateId,
    required this.targetStateId,
    required this.transitionId,
    required this.consumedInput,
    required this.emittedOutput,
    required this.cumulativeOutput,
    required this.remainingInput,
    required this.sourceRevision,
  });

  final int index;
  final TransducerStateId sourceStateId;
  final TransducerStateId targetStateId;
  final TransducerTransitionId transitionId;
  final TransducerInputSymbol consumedInput;
  final TransducerOutputWord emittedOutput;
  final TransducerOutputWord cumulativeOutput;
  final TransducerInputSuffix remainingInput;
  final TransducerRevision sourceRevision;
}

sealed class TransducerExecutionOutcome {
  TransducerExecutionOutcome({
    required this.input,
    required this.output,
    required Iterable<TransducerExecutionStep> trace,
    required this.processedInputCount,
  }) : trace = List<TransducerExecutionStep>.unmodifiable(trace);

  final TransducerInputWord input;
  final TransducerOutputWord output;
  final List<TransducerExecutionStep> trace;
  final int processedInputCount;

  bool get traceWasTruncated => trace.length < processedInputCount;

  /// Locale-neutral execution summary resolved only at presentation time.
  StructuredMessage get structuredMessage => switch (this) {
    TransducerInvalidMachine(:final analysis) => StructuredMessage(
      namespace: 'transducer.execution',
      code: 'invalid-machine',
      category: StructuredMessageCategory.simulation,
      severity: StructuredMessageSeverity.error,
      arguments: {
        'diagnostic-count': StructuredMessageArgument.count(
          analysis.diagnostics.length,
        ),
      },
    ),
    TransducerInvalidInput(:final invalidSymbol?) => StructuredMessage(
      namespace: 'transducer.execution',
      code: 'invalid-input-symbol',
      category: StructuredMessageCategory.validation,
      severity: StructuredMessageSeverity.error,
      arguments: {
        'symbol': StructuredMessageArgument.symbol(
          invalidSymbol.value,
          role: 'input-symbol',
        ),
      },
    ),
    TransducerInvalidInput(:final tokenizationFailure?) => StructuredMessage(
      namespace: 'transducer.execution',
      code: 'tokenization-failure',
      category: StructuredMessageCategory.validation,
      severity: StructuredMessageSeverity.error,
      arguments: {
        'offset': StructuredMessageArgument.index(
          tokenizationFailure.offset,
          role: 'input-offset',
        ),
      },
    ),
    TransducerInvalidInput() => StructuredMessage(
      namespace: 'transducer.execution',
      code: 'invalid-input',
      category: StructuredMessageCategory.validation,
      severity: StructuredMessageSeverity.error,
    ),
    TransducerIncomplete(:final stateId, :final nextInput) => StructuredMessage(
      namespace: 'transducer.execution',
      code: 'undefined-transition',
      category: StructuredMessageCategory.simulation,
      severity: StructuredMessageSeverity.warning,
      arguments: {
        'state': StructuredMessageArgument.identifier(
          stateId.value,
          role: 'state',
        ),
        'symbol': StructuredMessageArgument.symbol(
          nextInput.value,
          role: 'input-symbol',
        ),
      },
    ),
    TransducerCancelled() => StructuredMessage(
      namespace: 'transducer.execution',
      code: 'cancelled',
      category: StructuredMessageCategory.simulation,
      severity: StructuredMessageSeverity.information,
      arguments: {
        'processed': StructuredMessageArgument.count(processedInputCount),
      },
    ),
    TransducerBounded(:final maxSteps) => StructuredMessage(
      namespace: 'transducer.execution',
      code: 'bounded',
      category: StructuredMessageCategory.simulation,
      severity: StructuredMessageSeverity.warning,
      arguments: {
        'processed': StructuredMessageArgument.count(processedInputCount),
        'limit': StructuredMessageArgument.bound(maxSteps),
      },
    ),
    TransducerSuccess() => StructuredMessage(
      namespace: 'transducer.execution',
      code: 'success',
      category: StructuredMessageCategory.simulation,
      severity: StructuredMessageSeverity.information,
      arguments: {
        'processed': StructuredMessageArgument.count(processedInputCount),
        'output-count': StructuredMessageArgument.count(output.symbols.length),
      },
    ),
  };
}

final class TransducerSuccess extends TransducerExecutionOutcome {
  TransducerSuccess({
    required super.input,
    required super.output,
    required super.trace,
    required super.processedInputCount,
  });
}

final class TransducerInvalidMachine extends TransducerExecutionOutcome {
  TransducerInvalidMachine({required super.input, required this.analysis})
    : super(
        output: TransducerOutputWord.empty,
        trace: const [],
        processedInputCount: 0,
      );

  final TransducerAnalysisReport analysis;
}

final class TransducerInvalidInput extends TransducerExecutionOutcome {
  TransducerInvalidInput({
    required super.input,
    required this.invalidSymbol,
    this.tokenizationFailure,
  }) : super(
         output: TransducerOutputWord.empty,
         trace: const [],
         processedInputCount: 0,
       );

  final TransducerInputSymbol? invalidSymbol;
  final TransducerTokenizationFailure? tokenizationFailure;
}

final class TransducerCancelled extends TransducerExecutionOutcome {
  TransducerCancelled({
    required super.input,
    required super.output,
    required super.trace,
    required super.processedInputCount,
  });
}

final class TransducerBounded extends TransducerExecutionOutcome {
  TransducerBounded({
    required super.input,
    required super.output,
    required super.trace,
    required super.processedInputCount,
    required this.maxSteps,
  });

  final int maxSteps;
}

final class TransducerIncomplete extends TransducerExecutionOutcome {
  TransducerIncomplete({
    required super.input,
    required super.output,
    required super.trace,
    required super.processedInputCount,
    required this.stateId,
    required this.nextInput,
  });

  final TransducerStateId stateId;
  final TransducerInputSymbol nextInput;
}

final class DeterministicTransducerSimulator {
  DeterministicTransducerSimulator._(this.machine, this.emissionRule)
    : transitionIndex = TransducerTransitionIndex(machine),
      _statesById = {for (final state in machine.states) state.id: state};

  factory DeterministicTransducerSimulator.mealy(MealyMachine machine) =>
      DeterministicTransducerSimulator._(machine, const MealyEmissionRule());

  factory DeterministicTransducerSimulator.moore(MooreMachine machine) =>
      DeterministicTransducerSimulator._(machine, const MooreEmissionRule());

  final DeterministicFiniteStateTransducer machine;
  final TransducerEmissionRule emissionRule;
  final TransducerTransitionIndex transitionIndex;
  final Map<TransducerStateId, TransducerState> _statesById;

  TransducerState? stateFor(TransducerStateId id) => _statesById[id];

  TransducerState? get uniqueInitialState {
    final initial = machine.states.where((state) => state.isInitial).toList();
    return initial.length == 1 ? initial.single : null;
  }

  TransducerExecutionOutcome runRaw(
    String raw, {
    TransducerSimulationOptions options = const TransducerSimulationOptions(),
  }) {
    final tokenized = TransducerInputTokenizer.tokenize(
      raw,
      machine.inputAlphabet,
    );
    return switch (tokenized) {
      TransducerTokenizationSuccess(:final word) => run(word, options: options),
      TransducerTokenizationFailure() => TransducerInvalidInput(
        input: tokenized.prefix,
        invalidSymbol: null,
        tokenizationFailure: tokenized,
      ),
    };
  }

  TransducerExecutionOutcome run(
    TransducerInputWord input, {
    TransducerSimulationOptions options = const TransducerSimulationOptions(),
  }) {
    if (options.maxSteps < 0) {
      throw ArgumentError.value(
        options.maxSteps,
        'maxSteps',
        'transducer.validation.non-negative-required',
      );
    }
    if (options.maxRetainedTraceSteps < 0) {
      throw ArgumentError.value(
        options.maxRetainedTraceSteps,
        'maxRetainedTraceSteps',
        'transducer.validation.non-negative-required',
      );
    }
    final analysis = TransducerAnalyzer.analyze(machine);
    if (!analysis.isStructurallyValid) {
      return TransducerInvalidMachine(input: input, analysis: analysis);
    }
    for (final symbol in input.symbols) {
      if (!machine.inputAlphabet.contains(symbol)) {
        return TransducerInvalidInput(input: input, invalidSymbol: symbol);
      }
    }
    var current = uniqueInitialState!;
    final outputSymbols = <TransducerOutputSymbol>[
      ...emissionRule.initialOutput(current).symbols,
    ];
    final trace = <TransducerExecutionStep>[];
    var processed = 0;
    while (processed < input.symbols.length) {
      if ((options.cancellationToken?.isCancelled ?? false) ||
          (options.cancellationCheckpoint?.call(processed) ?? false)) {
        return TransducerCancelled(
          input: input,
          output: TransducerOutputWord(outputSymbols),
          trace: trace,
          processedInputCount: processed,
        );
      }
      if (processed >= options.maxSteps) {
        return TransducerBounded(
          input: input,
          output: TransducerOutputWord(outputSymbols),
          trace: trace,
          processedInputCount: processed,
          maxSteps: options.maxSteps,
        );
      }
      final symbol = input.symbols[processed];
      final lookup = transitionIndex.lookup(current.id, symbol);
      if (lookup case TransducerTransitionMissing()) {
        return TransducerIncomplete(
          input: input,
          output: TransducerOutputWord(outputSymbols),
          trace: trace,
          processedInputCount: processed,
          stateId: current.id,
          nextInput: symbol,
        );
      }
      if (lookup case TransducerTransitionAmbiguous()) {
        return TransducerInvalidMachine(input: input, analysis: analysis);
      }
      final transition = (lookup as TransducerTransitionFound).transition;
      final target = stateFor(transition.to)!;
      final emitted = emissionRule.transitionOutput(transition, target);
      outputSymbols.addAll(emitted.symbols);
      if (options.retainTrace && trace.length < options.maxRetainedTraceSteps) {
        trace.add(
          TransducerExecutionStep(
            index: processed,
            sourceStateId: current.id,
            targetStateId: target.id,
            transitionId: transition.id,
            consumedInput: symbol,
            emittedOutput: emitted,
            cumulativeOutput: TransducerOutputWord(outputSymbols),
            remainingInput: TransducerInputSuffix(input, processed + 1),
            sourceRevision: machine.revision,
          ),
        );
      }
      current = target;
      processed++;
    }
    if ((options.cancellationToken?.isCancelled ?? false) ||
        (options.cancellationCheckpoint?.call(processed) ?? false)) {
      return TransducerCancelled(
        input: input,
        output: TransducerOutputWord(outputSymbols),
        trace: trace,
        processedInputCount: processed,
      );
    }
    return TransducerSuccess(
      input: input,
      output: TransducerOutputWord(outputSymbols),
      trace: trace,
      processedInputCount: processed,
    );
  }

  /// Runs cooperatively, yielding between bounded chunks so cancellation from
  /// an interactive host can be observed without moving immutable documents
  /// across isolates.
  Future<TransducerExecutionOutcome> runAsync(
    TransducerInputWord input, {
    TransducerSimulationOptions options = const TransducerSimulationOptions(),
    int yieldEvery = 256,
  }) async {
    if (yieldEvery <= 0) {
      throw ArgumentError.value(
        yieldEvery,
        'yieldEvery',
        'transducer.validation.positive-required',
      );
    }
    if (options.maxSteps < 0 || options.maxRetainedTraceSteps < 0) {
      throw ArgumentError('transducer.validation.non-negative-required');
    }
    final analysis = TransducerAnalyzer.analyze(machine);
    if (!analysis.isStructurallyValid) {
      return TransducerInvalidMachine(input: input, analysis: analysis);
    }
    for (final symbol in input.symbols) {
      if (!machine.inputAlphabet.contains(symbol)) {
        return TransducerInvalidInput(input: input, invalidSymbol: symbol);
      }
    }
    var current = uniqueInitialState!;
    final outputSymbols = <TransducerOutputSymbol>[
      ...emissionRule.initialOutput(current).symbols,
    ];
    final trace = <TransducerExecutionStep>[];
    var processed = 0;
    while (processed < input.symbols.length) {
      if (processed > 0 && processed % yieldEvery == 0) {
        await Future<void>.delayed(Duration.zero);
      }
      if ((options.cancellationToken?.isCancelled ?? false) ||
          (options.cancellationCheckpoint?.call(processed) ?? false)) {
        return TransducerCancelled(
          input: input,
          output: TransducerOutputWord(outputSymbols),
          trace: trace,
          processedInputCount: processed,
        );
      }
      if (processed >= options.maxSteps) {
        return TransducerBounded(
          input: input,
          output: TransducerOutputWord(outputSymbols),
          trace: trace,
          processedInputCount: processed,
          maxSteps: options.maxSteps,
        );
      }
      final symbol = input.symbols[processed];
      final lookup = transitionIndex.lookup(current.id, symbol);
      if (lookup case TransducerTransitionMissing()) {
        return TransducerIncomplete(
          input: input,
          output: TransducerOutputWord(outputSymbols),
          trace: trace,
          processedInputCount: processed,
          stateId: current.id,
          nextInput: symbol,
        );
      }
      if (lookup case TransducerTransitionAmbiguous()) {
        return TransducerInvalidMachine(input: input, analysis: analysis);
      }
      final transition = (lookup as TransducerTransitionFound).transition;
      final target = stateFor(transition.to)!;
      final emitted = emissionRule.transitionOutput(transition, target);
      outputSymbols.addAll(emitted.symbols);
      if (options.retainTrace && trace.length < options.maxRetainedTraceSteps) {
        trace.add(
          TransducerExecutionStep(
            index: processed,
            sourceStateId: current.id,
            targetStateId: target.id,
            transitionId: transition.id,
            consumedInput: symbol,
            emittedOutput: emitted,
            cumulativeOutput: TransducerOutputWord(outputSymbols),
            remainingInput: TransducerInputSuffix(input, processed + 1),
            sourceRevision: machine.revision,
          ),
        );
      }
      current = target;
      processed++;
    }
    if ((options.cancellationToken?.isCancelled ?? false) ||
        (options.cancellationCheckpoint?.call(processed) ?? false)) {
      return TransducerCancelled(
        input: input,
        output: TransducerOutputWord(outputSymbols),
        trace: trace,
        processedInputCount: processed,
      );
    }
    return TransducerSuccess(
      input: input,
      output: TransducerOutputWord(outputSymbols),
      trace: trace,
      processedInputCount: processed,
    );
  }
}
