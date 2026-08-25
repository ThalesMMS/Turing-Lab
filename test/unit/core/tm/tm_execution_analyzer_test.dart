import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/tm_execution_analyzer.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/core/models/tm.dart';
import 'package:turing_lab/core/models/tm_execution_analysis.dart';
import 'package:turing_lab/core/models/tm_transition.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  group('TMExecutionAnalyzer DTM', () {
    test('proves a stationary repeated configuration', () async {
      final q0 = _state('q0', initial: true);
      final tm = _tm(
        states: {q0},
        initial: q0,
        transitions: {
          _transition('loop', q0, q0, 'B', 'B', TapeDirection.stay),
        },
      );

      final result = await TMExecutionAnalyzer.analyze(tm, '');

      expect(result.outcome, TMExecutionOutcome.provenCycle);
      expect(result.cycle?.startStep, 0);
      expect(result.cycle?.period, 1);
      expect(result.cycle?.configuration.headPosition, 0);
      expect(result.traceMetrics?.transitionExecutionCounts, {'loop': 1});
    });

    test('reports the exact period of a two-state cycle', () async {
      final q0 = _state('q0', initial: true);
      final q1 = _state('q1');
      final tm = _tm(
        states: {q0, q1},
        initial: q0,
        transitions: {
          _transition('to-q1', q0, q1, 'B', 'B', TapeDirection.stay),
          _transition('to-q0', q1, q0, 'B', 'B', TapeDirection.stay),
        },
      );

      final result = await TMExecutionAnalyzer.analyze(tm, '');

      expect(result.outcome, TMExecutionOutcome.provenCycle);
      expect(result.cycle?.startStep, 0);
      expect(result.cycle?.period, 2);
    });

    test('detects a cycle after tape contents are changed and restored',
        () async {
      final q0 = _state('q0', initial: true);
      final q1 = _state('q1');
      final tm = _tm(
        states: {q0, q1},
        initial: q0,
        tapeAlphabet: const {'1', 'B'},
        transitions: {
          _transition('write', q0, q1, 'B', '1', TapeDirection.stay),
          _transition('erase', q1, q0, '1', 'B', TapeDirection.stay),
        },
      );

      final result = await TMExecutionAnalyzer.analyze(tm, '');

      expect(result.outcome, TMExecutionOutcome.provenCycle);
      expect(result.cycle?.startStep, 0);
      expect(result.cycle?.period, 2);
      expect(result.cycle?.configuration.nonBlankCells, isEmpty);
    });

    test('returns bounded unknown when configurations keep changing', () async {
      final q0 = _state('q0', initial: true);
      final tm = _tm(
        states: {q0},
        initial: q0,
        transitions: {
          _transition('move', q0, q0, 'B', 'B', TapeDirection.right),
        },
      );

      final result = await TMExecutionAnalyzer.analyze(
        tm,
        '',
        maxSteps: 20,
        maxConfigurations: 100,
      );

      expect(result.outcome, TMExecutionOutcome.boundedUnknown);
      expect(result.limit, TMExecutionLimit.steps);
      expect(result.cycle, isNull);
      expect(result.stepsExecuted, 20);
      expect(result.traceMetrics?.movementCounts, {'right': 20});
    });

    test('can accept after more than ten thousand transitions', () async {
      final q0 = _state('q0', initial: true);
      final qa = _state('qa', accepting: true);
      final tm = _tm(
        states: {q0, qa},
        initial: q0,
        accepting: {qa},
        alphabet: const {'1'},
        tapeAlphabet: const {'1', 'B'},
        transitions: {
          _transition('scan', q0, q0, '1', '1', TapeDirection.right),
          _transition('accept', q0, qa, 'B', 'B', TapeDirection.stay),
        },
      );

      final result = await TMExecutionAnalyzer.analyze(
        tm,
        List.filled(10001, '1').join(),
        maxSteps: 10002,
        maxConfigurations: 10010,
        // Generous wall-clock budget: this case asserts the step bound, not a
        // performance target, and a tight budget makes it fail under load.
        timeout: const Duration(minutes: 2),
        includeTrace: false,
      );

      expect(result.outcome, TMExecutionOutcome.accepted);
      expect(result.stepsExecuted, 10002);
      expect(result.trace, isEmpty);
      expect(result.traceMetrics?.retainedTraceSnapshots, 0);
      expect(result.traceMetrics?.readCounts, {'1': 10001, 'B': 1});
      expect(result.traceMetrics?.transitionExecutionCounts, {
        'scan': 10001,
        'accept': 1,
      });
    });

    test('returns cancelled without calling it rejection', () async {
      final q0 = _state('q0', initial: true);
      final tm = _tm(
        states: {q0},
        initial: q0,
        transitions: {
          _transition('move', q0, q0, 'B', 'B', TapeDirection.right),
        },
      );
      var checks = 0;

      final result = await TMExecutionAnalyzer.analyze(
        tm,
        '',
        maxSteps: 1000,
        operationsPerBatch: 1,
        isCancelled: () => checks++ > 2,
      );

      expect(result.outcome, TMExecutionOutcome.cancelled);
      expect(result.isExact, isFalse);
    });

    test('keeps timeout distinct from rejection and cycle evidence', () async {
      final q0 = _state('q0', initial: true);
      final tm = _tm(
        states: {q0},
        initial: q0,
        transitions: {
          _transition('move', q0, q0, 'B', 'B', TapeDirection.right),
        },
      );

      final result = await TMExecutionAnalyzer.analyze(
        tm,
        '',
        maxSteps: 100000,
        timeout: const Duration(microseconds: 1),
      );

      expect(result.outcome, TMExecutionOutcome.boundedUnknown);
      expect(result.limit, TMExecutionLimit.timeout);
      expect(result.cycle, isNull);
    });
  });

  group('TMExecutionAnalyzer NTM', () {
    test('accepts when another branch revisits a configuration', () async {
      final q0 = _state('q0', initial: true);
      final qa = _state('qa', accepting: true);
      final tm = _tm(
        states: {q0, qa},
        initial: q0,
        accepting: {qa},
        transitions: {
          _transition('cycle', q0, q0, 'B', 'B', TapeDirection.stay),
          _transition('accept', q0, qa, 'B', 'B', TapeDirection.stay),
        },
      );

      final result = await TMExecutionAnalyzer.analyze(tm, '');

      expect(result.outcome, TMExecutionOutcome.accepted);
      expect(result.repeatedConfigurationsObserved, 1);
      expect(
        result.traceMetrics?.branchSelection,
        TMExecutionBranchSelection.acceptingBranch,
      );
      expect(result.traceMetrics?.transitionExecutionCounts, {'accept': 1});
      expect(
        result.traceMetrics?.definedButNotExecutedTransitionIds,
        contains('cycle'),
      );
    });

    test('rejects only after the finite configuration graph is exhausted',
        () async {
      final q0 = _state('q0', initial: true);
      final tm = _tm(
        states: {q0},
        initial: q0,
        transitions: {
          _transition('cycle', q0, q0, 'B', 'B', TapeDirection.stay),
          _transition('duplicate', q0, q0, 'B', 'B', TapeDirection.stay),
        },
      );

      final result = await TMExecutionAnalyzer.analyze(tm, '');

      expect(result.outcome, TMExecutionOutcome.haltedRejected);
      expect(result.repeatedConfigurationsObserved, greaterThan(0));
      expect(result.configurationsExplored, 1);
      expect(
        result.traceMetrics?.branchSelection,
        TMExecutionBranchSelection.cyclicBranch,
      );
    });

    test('labels a selected halting branch instead of merging NTM metrics',
        () async {
      final q0 = _state('q0', initial: true);
      final q1 = _state('q1');
      final q2 = _state('q2');
      final tm = _tm(
        states: {q0, q1, q2},
        initial: q0,
        transitions: {
          _transition('a-branch', q0, q1, 'B', 'B', TapeDirection.stay),
          _transition('b-branch', q0, q2, 'B', 'B', TapeDirection.stay),
        },
      );

      final result = await TMExecutionAnalyzer.analyze(tm, '');

      expect(result.outcome, TMExecutionOutcome.haltedRejected);
      expect(
        result.traceMetrics?.branchSelection,
        TMExecutionBranchSelection.rejectingBranch,
      );
      expect(result.traceMetrics?.transitionExecutionCounts.values, [1]);
    });

    test('labels the longest selected branch when bounds stop exploration',
        () async {
      final q0 = _state('q0', initial: true);
      final tm = _tm(
        states: {q0},
        initial: q0,
        transitions: {
          _transition('move', q0, q0, 'B', 'B', TapeDirection.right),
          _transition('stay', q0, q0, 'B', 'B', TapeDirection.stay),
        },
      );

      final result = await TMExecutionAnalyzer.analyze(
        tm,
        '',
        maxSteps: 2,
      );

      expect(result.outcome, TMExecutionOutcome.boundedUnknown);
      expect(
        result.traceMetrics?.branchSelection,
        TMExecutionBranchSelection.longestBoundedBranch,
      );
      expect(result.traceMetrics?.transitionExecutionCounts['move'], 2);
    });
  });

  group('TM trace metrics', () {
    test('pure right scan counts operations and stable logical cells',
        () async {
      final q0 = _state('q0', initial: true);
      final dead = _state('dead');
      final tm = _tm(
        states: {q0, dead},
        initial: q0,
        alphabet: const {'1'},
        tapeAlphabet: const {'1', 'B'},
        transitions: {
          _transition('scan', q0, q0, '1', '1', TapeDirection.right),
          _transition('unused', dead, dead, 'B', 'B', TapeDirection.stay),
        },
      );

      final result = await TMExecutionAnalyzer.analyze(tm, '11');
      final metrics = result.traceMetrics!;

      expect(result.outcome, TMExecutionOutcome.haltedRejected);
      expect(metrics.readCounts, {'1': 2});
      expect(metrics.writeCountsByOldSymbol, {'1': 2});
      expect(metrics.writeCountsByNewSymbol, {'1': 2});
      expect(metrics.movementCounts, {'right': 2});
      expect(metrics.minimumHeadPosition, 0);
      expect(metrics.maximumHeadPosition, 2);
      expect(metrics.visitedCells, {0, 1, 2});
      expect(metrics.tapeDiff, isEmpty);
      expect(metrics.definedButNotExecutedTransitionIds, {'unused'});
    });

    test('left growth keeps negative cell positions stable', () async {
      final q0 = _state('q0', initial: true);
      final q1 = _state('q1');
      final qa = _state('qa', accepting: true);
      final tm = _tm(
        states: {q0, q1, qa},
        initial: q0,
        accepting: {qa},
        tapeAlphabet: const {'X', 'Y', 'B'},
        transitions: {
          _transition('write-zero', q0, q1, 'B', 'X', TapeDirection.left),
          _transition('write-left', q1, qa, 'B', 'Y', TapeDirection.stay),
        },
      );

      final metrics = (await TMExecutionAnalyzer.analyze(tm, '')).traceMetrics!;

      expect(metrics.minimumHeadPosition, -1);
      expect(metrics.maximumHeadPosition, 0);
      expect(metrics.visitedCells, {0, -1});
      expect(metrics.tapeDiff[-1]?.finalSymbol, 'Y');
      expect(metrics.tapeDiff[0]?.finalSymbol, 'X');
      expect(metrics.maximumSimultaneousNonBlankCells, 2);
    });

    test('repeated overwrite reports changes, stays, and blank erasure',
        () async {
      final q0 = _state('q0', initial: true);
      final q1 = _state('q1');
      final q2 = _state('q2');
      final qa = _state('qa', accepting: true);
      final tm = _tm(
        states: {q0, q1, q2, qa},
        initial: q0,
        accepting: {qa},
        tapeAlphabet: const {'X', 'Y', 'B'},
        transitions: {
          _transition('x', q0, q1, 'B', 'X', TapeDirection.stay),
          _transition('y', q1, q2, 'X', 'Y', TapeDirection.stay),
          _transition('erase', q2, qa, 'Y', 'B', TapeDirection.stay),
        },
      );

      final metrics = (await TMExecutionAnalyzer.analyze(tm, '')).traceMetrics!;

      expect(metrics.changedWrites, 3);
      expect(metrics.movementCounts, {'stay': 3});
      expect(metrics.maximumSimultaneousNonBlankCells, 1);
      expect(metrics.tapeDiff, isEmpty);
      expect(metrics.cellTouchRanges[0]?.firstStep, 0);
      expect(metrics.cellTouchRanges[0]?.lastStep, 3);
    });

    test('opposite moves count one direction reversal', () async {
      final q0 = _state('q0', initial: true);
      final q1 = _state('q1');
      final q2 = _state('q2');
      final qa = _state('qa', accepting: true);
      final tm = _tm(
        states: {q0, q1, q2, qa},
        initial: q0,
        accepting: {qa},
        transitions: {
          _transition('right', q0, q1, 'B', 'B', TapeDirection.right),
          _transition('left', q1, q2, 'B', 'B', TapeDirection.left),
          _transition('halt', q2, qa, 'B', 'B', TapeDirection.stay),
        },
      );

      final metrics = (await TMExecutionAnalyzer.analyze(tm, '')).traceMetrics!;

      expect(metrics.movementCounts, {'right': 1, 'left': 1, 'stay': 1});
      expect(metrics.headReversals, 1);
    });
  });

  test('publishes transition and configuration progress after each batch',
      () async {
    final q0 = _state('q0', initial: true);
    final q1 = _state('q1');
    final qa = _state('qa', accepting: true);
    final tm = _tm(
      states: {q0, q1, qa},
      initial: q0,
      accepting: {qa},
      transitions: {
        _transition('first', q0, q1, 'B', 'B', TapeDirection.right),
        _transition('second', q1, qa, 'B', 'B', TapeDirection.stay),
      },
    );
    final progress = <(int, int)>[];

    final result = await TMExecutionAnalyzer.analyze(
      tm,
      '',
      operationsPerBatch: 1,
      onProgress: (steps, configurations) {
        progress.add((steps, configurations));
      },
    );

    expect(progress, isNotEmpty);
    expect(
        progress.last, (result.stepsExecuted, result.configurationsExplored));
    expect(progress.first.$1, greaterThan(0));
  });

  test('canonical snapshots ignore redundant blank cells and map order', () {
    final first = TMConfigurationSnapshot.canonical(
      stateId: 'q0',
      headPosition: 4,
      tape: {10: 'B', 2: '1', -3: 'B', 8: '0'},
      blankSymbol: 'B',
    );
    final second = TMConfigurationSnapshot.canonical(
      stateId: 'q0',
      headPosition: 4,
      tape: {8: '0', 2: '1'},
      blankSymbol: 'B',
    );

    expect(first.key, second.key);
    expect(first.nonBlankCells, {2: '1', 8: '0'});
  });
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
