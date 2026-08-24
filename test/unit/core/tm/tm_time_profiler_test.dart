import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:turing_lab/core/algorithms/tm_time_profiler.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/core/models/tm.dart';
import 'package:turing_lab/core/models/tm_execution_analysis.dart';
import 'package:turing_lab/core/models/tm_time_profile.dart';
import 'package:turing_lab/core/models/tm_transition.dart';

void main() {
  group('TMTimeProfiler DTM transition counts', () {
    test('profiles a linear right scan by input length including epsilon',
        () async {
      final q0 = _state('q0', initial: true);
      final qa = _state('qa', accepting: true);
      final tm = _tm(
        states: {q0, qa},
        initial: q0,
        accepting: {qa},
        alphabet: const {'a'},
        tapeAlphabet: const {'a', 'B'},
        transitions: {
          _transition('scan', q0, q0, 'a', 'a', TapeDirection.right),
          _transition('halt', q0, qa, 'B', 'B', TapeDirection.stay),
        },
      );

      final report = await TMTimeProfiler.profile(
        tm,
        bounds: const TMTimeProfileBounds(maxLength: 3),
      );

      expect(report.status, TMTimeProfileStatus.complete);
      expect(report.kind, TMTimeProfileKind.deterministicTime);
      expect(report.rows.map((row) => row.inputLength), [0, 1, 2, 3]);
      expect(
          report.rows.map((row) => row.maximumTransitionSteps), [1, 2, 3, 4]);
      expect(report.rows.first.maximumTransitionWitness?.input, '');
      expect(report.rows.last.maximumTransitionWitness?.input, 'aaa');
      expect(report.rows.last.maximumTransitionWitness?.execution.trace,
          hasLength(5));
    });

    test('reports different costs and the maximum witness at one length',
        () async {
      final q0 = _state('q0', initial: true);
      final q1 = _state('q1');
      final qa = _state('qa', accepting: true);
      final tm = _tm(
        states: {q0, q1, qa},
        initial: q0,
        accepting: {qa},
        alphabet: const {'a', 'b'},
        tapeAlphabet: const {'a', 'b', 'B'},
        transitions: {
          _transition('fast', q0, qa, 'a', 'a', TapeDirection.stay),
          _transition('slow-1', q0, q1, 'b', 'b', TapeDirection.right),
          _transition('slow-2', q1, qa, 'B', 'B', TapeDirection.stay),
        },
      );

      final report = await TMTimeProfiler.profile(
        tm,
        bounds: const TMTimeProfileBounds(maxLength: 1),
      );
      final row = report.rows[1];

      expect(row.candidateCount, 2);
      expect(row.completedCount, 2);
      expect(row.minimumTransitionSteps, 1);
      expect(row.maximumTransitionSteps, 2);
      expect(row.maximumTransitionWitness?.input, 'b');
      expect(
        row.maximumTransitionWitness?.execution.trace
            .map((step) => step.usedTransition),
        contains('q1,B → qa,B,S'),
      );
    });

    test('counts a halting run beyond the historical 10000-step limit',
        () async {
      final tm = _binaryCountdownTm(bitCount: 12);

      final report = await TMTimeProfiler.profile(
        tm,
        bounds: const TMTimeProfileBounds(
          maxLength: 0,
          maxStepsPerCandidate: 50000,
          timeoutPerCandidate: Duration(seconds: 20),
          operationsPerBatch: 1000,
        ),
      );

      expect(report.status, TMTimeProfileStatus.complete);
      expect(report.rows.single.maximumTransitionSteps, greaterThan(10000));
      expect(
        report.rows.single.maximumTransitionWitness?.execution.outcome,
        TMExecutionOutcome.accepted,
      );
    });

    test('distinguishes proven cycles from bounded-unknown candidates',
        () async {
      final q0 = _state('q0', initial: true);
      final moving = _state('moving');
      final tm = _tm(
        states: {q0, moving},
        initial: q0,
        alphabet: const {'a', 'b'},
        tapeAlphabet: const {'a', 'b', 'B'},
        transitions: {
          _transition('cycle', q0, q0, 'a', 'a', TapeDirection.stay),
          _transition(
              'start-moving', q0, moving, 'b', 'b', TapeDirection.right),
          _transition('move', moving, moving, 'B', 'B', TapeDirection.right),
        },
      );

      final report = await TMTimeProfiler.profile(
        tm,
        bounds:
            const TMTimeProfileBounds(maxLength: 1, maxStepsPerCandidate: 5),
      );
      final row = report.rows[1];

      expect(report.status, TMTimeProfileStatus.incomplete);
      expect(row.provenCycleCount, 1);
      expect(row.unknownCount, 1);
      expect(row.completedCount, 0);
      expect(row.isComplete, isFalse);
      expect(row.maximumTransitionSteps, isNull);
    });

    test('marks sampled rows incomplete and samples deterministically',
        () async {
      final q0 = _state('q0', initial: true, accepting: true);
      final tm = _tm(
        states: {q0},
        initial: q0,
        accepting: {q0},
        alphabet: const {'b', 'a'},
        tapeAlphabet: const {'a', 'b', 'B'},
        transitions: const {},
      );
      const bounds = TMTimeProfileBounds(
        maxLength: 2,
        maxCandidatesPerLength: 2,
      );

      final first = await TMTimeProfiler.profile(tm, bounds: bounds);
      final second = await TMTimeProfiler.profile(tm, bounds: bounds);

      expect(first.plan.plannedCandidateCount, 5);
      expect(first.rows[0].isSampled, isFalse);
      expect(first.rows[1].isSampled, isFalse);
      expect(first.rows[2].possibleCandidateCount, BigInt.from(4));
      expect(first.rows[2].candidateCount, 2);
      expect(first.rows[2].isSampled, isTrue);
      expect(first.rows[2].isComplete, isFalse);
      expect(first.status, TMTimeProfileStatus.incomplete);
      expect(first.rows[2].maximumTransitionWitness?.input, 'aa');
      expect(
        second.rows[2].maximumTransitionWitness?.input,
        first.rows[2].maximumTransitionWitness?.input,
      );
    });
  });

  test('cancellation stops between batches and reports progress', () async {
    final q0 = _state('q0', initial: true, accepting: true);
    final tm = _tm(
      states: {q0},
      initial: q0,
      accepting: {q0},
      alphabet: const {'a', 'b'},
      tapeAlphabet: const {'a', 'b', 'B'},
      transitions: const {},
    );
    var cancel = false;
    final progress = <TMTimeProfileProgress>[];

    final report = await TMTimeProfiler.profile(
      tm,
      bounds: const TMTimeProfileBounds(maxLength: 5),
      isCancelled: () => cancel,
      onProgress: (value) {
        progress.add(value);
        if (!value.isWitnessReplay && value.completedCandidates >= 3) {
          cancel = true;
        }
      },
    );

    expect(report.status, TMTimeProfileStatus.cancelled);
    expect(progress.first.completedCandidates, 0);
    expect(progress.last.completedCandidates, 3);
    expect(report.rows.last.isComplete, isFalse);
  });

  test('labels NTM depth and configuration metrics as exploration', () async {
    final q0 = _state('q0', initial: true);
    final q1 = _state('q1');
    final qa = _state('qa', accepting: true);
    final tm = _tm(
      states: {q0, q1, qa},
      initial: q0,
      accepting: {qa},
      alphabet: const {'a'},
      tapeAlphabet: const {'a', 'B'},
      transitions: {
        _transition('accept', q0, qa, 'a', 'a', TapeDirection.stay),
        _transition('branch', q0, q1, 'a', 'a', TapeDirection.right),
      },
    );

    final report = await TMTimeProfiler.profile(
      tm,
      bounds: const TMTimeProfileBounds(maxLength: 1),
    );
    final row = report.rows[1];

    expect(report.kind, TMTimeProfileKind.nondeterministicExploration);
    expect(row.minimumTransitionSteps, isNull);
    expect(row.maximumTransitionSteps, isNull);
    expect(row.maximumExplorationDepth, 1);
    expect(row.maximumConfigurationsExplored, greaterThanOrEqualTo(2));
    expect(row.maximumDepthWitness?.input, 'a');
    expect(row.maximumDepthWitness?.execution.trace, isNotEmpty);
    expect(row.maximumConfigurationsWitness?.input, 'a');
  });
}

TM _binaryCountdownTm({required int bitCount}) {
  final initializers = <State>[
    for (var index = 0; index < bitCount; index++)
      _state('init-$index', initial: index == 0),
  ];
  final decrement = _state('decrement');
  final checkNonZero = _state('check-nonzero');
  final returnToEnd = _state('return-to-end');
  final accept = _state('accept', accepting: true);
  final transitions = <TMTransition>{
    for (var index = 0; index < bitCount; index++)
      _transition(
        'initialize-$index',
        initializers[index],
        index == bitCount - 1 ? decrement : initializers[index + 1],
        'B',
        '1',
        index == bitCount - 1 ? TapeDirection.stay : TapeDirection.right,
      ),
    _transition(
      'decrement-one',
      decrement,
      checkNonZero,
      '1',
      '0',
      TapeDirection.left,
    ),
    _transition(
      'borrow',
      decrement,
      decrement,
      '0',
      '1',
      TapeDirection.left,
    ),
    _transition(
      'check-zero',
      checkNonZero,
      checkNonZero,
      '0',
      '0',
      TapeDirection.left,
    ),
    _transition(
      'found-one',
      checkNonZero,
      returnToEnd,
      '1',
      '1',
      TapeDirection.right,
    ),
    _transition(
      'counter-empty',
      checkNonZero,
      accept,
      'B',
      'B',
      TapeDirection.stay,
    ),
    _transition(
      'return-over-zero',
      returnToEnd,
      returnToEnd,
      '0',
      '0',
      TapeDirection.right,
    ),
    _transition(
      'return-over-one',
      returnToEnd,
      returnToEnd,
      '1',
      '1',
      TapeDirection.right,
    ),
    _transition(
      'next-decrement',
      returnToEnd,
      decrement,
      'B',
      'B',
      TapeDirection.left,
    ),
  };
  return _tm(
    states: {
      ...initializers,
      decrement,
      checkNonZero,
      returnToEnd,
      accept,
    },
    initial: initializers.first,
    accepting: {accept},
    transitions: transitions,
    tapeAlphabet: const {'0', '1', 'B'},
  );
}

State _state(
  String id, {
  bool initial = false,
  bool accepting = false,
}) {
  return State(
    id: id,
    label: id,
    position: Vector2.zero(),
    isInitial: initial,
    isAccepting: accepting,
  );
}

TMTransition _transition(
  String id,
  State from,
  State to,
  String read,
  String write,
  TapeDirection direction,
) {
  return TMTransition(
    id: id,
    fromState: from,
    toState: to,
    label: TMTransition.formatLabel(
      readSymbol: read,
      writeSymbol: write,
      direction: direction,
    ),
    readSymbol: read,
    writeSymbol: write,
    direction: direction,
  );
}

TM _tm({
  required Set<State> states,
  required State initial,
  required Set<TMTransition> transitions,
  Set<State> accepting = const {},
  Set<String> alphabet = const {},
  Set<String> tapeAlphabet = const {'B'},
}) {
  return TM(
    id: 'tm',
    name: 'TM',
    states: states,
    transitions: transitions,
    alphabet: alphabet,
    initialState: initial,
    acceptingStates: accepting,
    created: DateTime(2026),
    modified: DateTime(2026),
    bounds: const math.Rectangle(0, 0, 400, 300),
    tapeAlphabet: tapeAlphabet,
    blankSymbol: 'B',
    tapeCount: 1,
  );
}
