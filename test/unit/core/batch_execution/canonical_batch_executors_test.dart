import 'dart:math' as math;

import 'package:test/test.dart';
import 'package:turing_lab/core/batch_execution/batch_execution.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/pda.dart';
import 'package:turing_lab/core/models/pda_transition.dart';
import 'package:turing_lab/core/models/production.dart';
import 'package:turing_lab/core/models/regex_document.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/core/models/tm.dart';
import 'package:turing_lab/core/models/tm_transition.dart';
import 'package:turing_lab/core/transducers/transducers.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  test('FSA and Regex executors preserve accepted, rejected, and invalid input',
      () async {
    final fsa = _fsa();
    final fsaReport = await _run(
      FsaBatchExecutor(fsa),
      strategy: 'simulate',
      inputs: const ['a', '', '?'],
    );

    expect(fsaReport.results.map((result) => result.outcome), [
      BatchOutcomeCode.accepted,
      BatchOutcomeCode.rejected,
      BatchOutcomeCode.invalidInput,
    ]);

    final tokenized = await _run(
      FsaBatchExecutor(fsa),
      strategy: 'simulate',
      inputs: const ['a '],
      tokenizationMode: BatchTokenizationMode.explicitTokens,
      tokens: const [
        ['a'],
      ],
    );
    expect(tokenized.results.single.outcome, BatchOutcomeCode.accepted);

    final regex = RegexDocument(
      id: 'regex',
      name: 'a',
      source: 'a',
      alphabet: const ['a'],
    );
    final regexReport = await _run(
      RegexBatchExecutor(regex),
      strategy: 'match',
      inputs: const ['a', ''],
    );

    expect(regexReport.results.map((result) => result.outcome), [
      BatchOutcomeCode.accepted,
      BatchOutcomeCode.rejected,
    ]);
  });

  test('FSA executor enforces step and configuration bounds', () async {
    final stepBound = await _run(
      FsaBatchExecutor(_fsa()),
      strategy: 'simulate',
      inputs: const ['aa'],
      limits: const BatchExecutionLimits(maxSteps: 1),
    );
    expect(stepBound.results.single.outcome, BatchOutcomeCode.boundedUnknown);
    expect(stepBound.results.single.diagnosticCode, 'fsa.step-limit');

    final configurationBound = await _run(
      FsaBatchExecutor(_fsa()),
      strategy: 'simulate',
      inputs: const ['a'],
      limits: const BatchExecutionLimits(maxConfigurations: 1),
    );
    expect(
      configurationBound.results.single.outcome,
      BatchOutcomeCode.configurationLimit,
    );
    expect(
      configurationBound.results.single.diagnosticCode,
      'fsa.configuration-limit',
    );
  });

  test('PDA executor calls the canonical NPDA semantics', () async {
    final report = await _run(
      PdaBatchExecutor(_pda()),
      strategy: 'simulate',
      inputs: const ['a', ''],
    );

    expect(report.results.map((result) => result.outcome), [
      BatchOutcomeCode.accepted,
      BatchOutcomeCode.rejected,
    ]);
  });

  test(
      'TM executor preserves exact and proven-cycle outcomes with token inputs',
      () async {
    final machine = _tm();
    final exact = await _run(
      TmBatchExecutor(machine),
      strategy: 'simulate',
      inputs: const ['a', ''],
      tokenizationMode: BatchTokenizationMode.explicitTokens,
      tokens: const [
        ['a'],
        <String>[],
      ],
    );

    expect(exact.results.map((result) => result.outcome), [
      BatchOutcomeCode.accepted,
      BatchOutcomeCode.rejected,
    ]);

    final bounded = await _run(
      TmBatchExecutor(_loopingTm()),
      strategy: 'simulate',
      inputs: const ['a'],
      limits: const BatchExecutionLimits(maxSteps: 1),
    );
    expect(bounded.results.single.outcome, BatchOutcomeCode.provenCycle);
  });

  test('Grammar executor exposes strategy and conflict-safe typed results',
      () async {
    final grammar = _grammar();
    final earley = await _run(
      GrammarBatchExecutor(grammar),
      strategy: 'auto',
      inputs: const ['a', '', '?'],
    );

    expect(earley.results.map((result) => result.outcome), [
      BatchOutcomeCode.accepted,
      BatchOutcomeCode.rejected,
      BatchOutcomeCode.invalidInput,
    ]);

    final brute = await _run(
      GrammarBatchExecutor(grammar),
      strategy: 'bruteForce',
      inputs: const ['a'],
      retainTrace: true,
    );
    expect(brute.results.single.outcome, BatchOutcomeCode.accepted);
    expect(brute.results.single.metrics['witnesses'], 1);

    final conflictGrammar = grammar.copyWith(
      productions: {
        const Production(id: 'p0', leftSide: ['S'], rightSide: ['a']),
        const Production(id: 'p1', leftSide: ['S'], rightSide: ['a', 'a']),
      },
    );
    final conflict = await _run(
      GrammarBatchExecutor(conflictGrammar),
      strategy: 'll',
      inputs: const ['a'],
    );
    expect(conflict.results.single.outcome, BatchOutcomeCode.conflict);

    final timeout = await GrammarBatchExecutor(grammar).execute(
      BatchInputCase(id: 'timeout', input: 'a'),
      strategyId: 'auto',
      tokenizationMode: BatchTokenizationMode.unicodeScalar,
      limits: const BatchExecutionLimits(timeout: Duration(microseconds: -1)),
      retainTrace: false,
      cancellationToken: BatchCancellationToken(),
    );
    expect(timeout.outcome, BatchOutcomeCode.timeout);

    final multiTokenGrammar = grammar.copyWith(
      terminals: const {'aa'},
      productions: {
        const Production(id: 'p0', leftSide: ['S'], rightSide: ['aa']),
      },
    );
    final explicit = await _run(
      GrammarBatchExecutor(multiTokenGrammar),
      strategy: 'auto',
      inputs: const ['aa '],
      tokenizationMode: BatchTokenizationMode.explicitTokens,
      tokens: const [
        ['aa'],
      ],
    );
    expect(explicit.results.single.outcome, BatchOutcomeCode.accepted);
  });

  test('Mealy and Moore executors preserve output and undefined transitions',
      () async {
    final mealy = await _run(
      TransducerBatchExecutor(_mealy()),
      strategy: 'simulate',
      inputs: const ['a', 'aa'],
      tokenizationMode: BatchTokenizationMode.explicitTokens,
      tokens: const [
        ['a'],
        ['a', 'a'],
      ],
    );
    expect(mealy.results.first.outcome, BatchOutcomeCode.output);
    expect(mealy.results.first.output, ['x']);
    expect(mealy.results.last.outcome, BatchOutcomeCode.undefinedTransition);

    final moore = await _run(
      TransducerBatchExecutor(_moore()),
      strategy: 'simulate',
      inputs: const ['a'],
    );
    expect(moore.results.single.outcome, BatchOutcomeCode.output);
    expect(moore.results.single.output, ['zero', 'one']);
  });
}

Future<BatchExecutionReport> _run(
  BatchCaseExecutor executor, {
  required String strategy,
  required List<String> inputs,
  List<List<String>>? tokens,
  BatchTokenizationMode tokenizationMode = BatchTokenizationMode.unicodeScalar,
  BatchExecutionLimits limits = const BatchExecutionLimits(),
  bool retainTrace = false,
}) =>
    const BatchExecutionRunner()
        .start(
          BatchExecutionRequest(
            modelId: executor.modelId,
            modelRevision: executor.modelRevision,
            strategyId: strategy,
            tokenizationMode: tokenizationMode,
            cases: [
              for (var index = 0; index < inputs.length; index++)
                BatchInputCase(
                  id: 'case-$index',
                  input: inputs[index],
                  tokens: tokens?[index],
                ),
            ],
            sharedLimits: limits,
            traceRetention: retainTrace
                ? BatchTraceRetention.all
                : BatchTraceRetention.none,
          ),
          executor,
        )
        .report;

FSA _fsa() {
  final q0 = State(
    id: 'q0',
    label: 'q0',
    position: Vector2.zero(),
    isInitial: true,
  );
  final q1 = State(
    id: 'q1',
    label: 'q1',
    position: Vector2(100, 0),
    isAccepting: true,
  );
  return FSA(
    id: 'fsa',
    name: 'FSA',
    states: {q0, q1},
    transitions: {
      FSATransition.deterministic(
        id: 't0',
        fromState: q0,
        toState: q1,
        symbol: 'a',
      ),
    },
    alphabet: const {'a'},
    initialState: q0,
    acceptingStates: {q1},
    created: DateTime.utc(2026),
    modified: DateTime.utc(2026),
    bounds: const math.Rectangle(0, 0, 200, 100),
  );
}

PDA _pda() {
  final q0 = State(
    id: 'q0',
    label: 'q0',
    position: Vector2.zero(),
    isInitial: true,
  );
  final q1 = State(
    id: 'q1',
    label: 'q1',
    position: Vector2(100, 0),
    isAccepting: true,
  );
  return PDA(
    id: 'pda',
    name: 'PDA',
    states: {q0, q1},
    transitions: {
      PDATransition(
        id: 't0',
        fromState: q0,
        toState: q1,
        label: 'a, Z/Z',
        inputSymbol: 'a',
        popSymbol: 'Z',
        pushSymbol: 'Z',
      ),
    },
    alphabet: const {'a'},
    initialState: q0,
    acceptingStates: {q1},
    created: DateTime.utc(2026),
    modified: DateTime.utc(2026),
    bounds: const math.Rectangle(0, 0, 200, 100),
    stackAlphabet: const {'Z'},
  );
}

TM _tm() {
  final q0 = State(
    id: 'q0',
    label: 'q0',
    position: Vector2.zero(),
    isInitial: true,
  );
  final q1 = State(
    id: 'q1',
    label: 'q1',
    position: Vector2(100, 0),
    isAccepting: true,
  );
  return TM(
    id: 'tm',
    name: 'TM',
    states: {q0, q1},
    transitions: {
      TMTransition(
        id: 't0',
        fromState: q0,
        toState: q1,
        label: 'a/a,S',
        readSymbol: 'a',
        writeSymbol: 'a',
        direction: TapeDirection.stay,
      ),
    },
    alphabet: const {'a'},
    initialState: q0,
    acceptingStates: {q1},
    created: DateTime.utc(2026),
    modified: DateTime.utc(2026),
    bounds: const math.Rectangle(0, 0, 200, 100),
    tapeAlphabet: const {'a', 'B'},
    blankSymbol: 'B',
  );
}

TM _loopingTm() {
  final q0 = State(
    id: 'q0',
    label: 'q0',
    position: Vector2.zero(),
    isInitial: true,
  );
  return TM(
    id: 'loop',
    name: 'Loop',
    states: {q0},
    transitions: {
      TMTransition(
        id: 'loop',
        fromState: q0,
        toState: q0,
        label: 'a/a,S',
        readSymbol: 'a',
        writeSymbol: 'a',
        direction: TapeDirection.stay,
      ),
    },
    alphabet: const {'a'},
    initialState: q0,
    acceptingStates: const {},
    created: DateTime.utc(2026),
    modified: DateTime.utc(2026),
    bounds: const math.Rectangle(0, 0, 100, 100),
    tapeAlphabet: const {'a', 'B'},
    blankSymbol: 'B',
  );
}

Grammar _grammar() => Grammar(
      id: 'grammar',
      name: 'Grammar',
      terminals: const {'a'},
      nonterminals: const {'S'},
      startSymbol: 'S',
      productions: {
        const Production(id: 'p0', leftSide: ['S'], rightSide: ['a']),
      },
      type: GrammarType.contextFree,
      created: DateTime.utc(2026),
      modified: DateTime.utc(2026),
    );

MealyMachine _mealy() => MealyMachine(
      id: const TransducerMachineId('mealy'),
      name: 'Mealy',
      revision: const TransducerRevision(1),
      inputAlphabet: {const TransducerInputSymbol('a')},
      outputAlphabet: {const TransducerOutputSymbol('x')},
      states: const [
        MealyState(
          id: TransducerStateId('q0'),
          label: 'q0',
          position: TransducerPoint(0, 0),
          isInitial: true,
        ),
        MealyState(
          id: TransducerStateId('q1'),
          label: 'q1',
          position: TransducerPoint(100, 0),
        ),
      ],
      transitions: [
        MealyTransition(
          id: const TransducerTransitionId('t0'),
          from: const TransducerStateId('q0'),
          to: const TransducerStateId('q1'),
          input: const TransducerInputSymbol('a'),
          output: TransducerOutputWord.fromValues(const ['x']),
        ),
      ],
    );

MooreMachine _moore() => MooreMachine(
      id: const TransducerMachineId('moore'),
      name: 'Moore',
      revision: const TransducerRevision(1),
      inputAlphabet: {const TransducerInputSymbol('a')},
      outputAlphabet: {
        const TransducerOutputSymbol('zero'),
        const TransducerOutputSymbol('one'),
      },
      states: [
        MooreState(
          id: const TransducerStateId('q0'),
          label: 'q0',
          position: const TransducerPoint(0, 0),
          isInitial: true,
          output: TransducerOutputWord.fromValues(const ['zero']),
        ),
        MooreState(
          id: const TransducerStateId('q1'),
          label: 'q1',
          position: const TransducerPoint(100, 0),
          output: TransducerOutputWord.fromValues(const ['one']),
        ),
      ],
      transitions: const [
        MooreTransition(
          id: TransducerTransitionId('t0'),
          from: TransducerStateId('q0'),
          to: TransducerStateId('q1'),
          input: TransducerInputSymbol('a'),
        ),
      ],
    );
