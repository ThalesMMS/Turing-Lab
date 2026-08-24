import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/tm_space_profiler.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/core/models/tm.dart';
import 'package:turing_lab/core/models/tm_execution_analysis.dart';
import 'package:turing_lab/core/models/tm_space_profile.dart';
import 'package:turing_lab/core/models/tm_transition.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  group('TMSpaceProfiler', () {
    test(
      'profiles a right scan by input length without retaining traces',
      () async {
        final result = await TMSpaceProfiler.profile(
          _rightScanner(),
          limits: const TMSpaceProfileLimits(maxInputLength: 3),
        );

        expect(result.isSuccess, isTrue, reason: result.error);
        final report = result.data!;
        expect(report.rows.map((row) => row.inputLength), [0, 1, 2, 3]);
        for (final row in report.rows) {
          expect(row.enumerationMode, TMSpaceEnumerationMode.exhaustive);
          expect(row.isIncomplete, isFalse);
          expect(row.maximumVisitedSpan?.value, row.inputLength + 1);
          expect(row.maximumNonBlankCells?.value, row.inputLength);
          expect(
            row.maximumVisitedSpan?.witnessInput,
            List.filled(row.inputLength, '1').join(),
          );
          expect(row.inputs.single.analysis.trace, isEmpty);
          expect(
            row.inputs.single.analysis.traceMetrics?.retainedTraceSnapshots,
            0,
          );
        }
      },
    );

    test('keeps stable coordinates while growing left and right', () async {
      final result = await TMSpaceProfiler.profile(
        _bidirectionalGrowthMachine(),
        limits: const TMSpaceProfileLimits(maxInputLength: 0),
      );

      final input = result.data!.rows.single.inputs.single;
      expect(input.metrics.maximumVisitedSpan, 3);
      expect(input.metrics.maximumNonBlankCells, 3);
      expect(input.analysis.traceMetrics?.minimumHeadPosition, -1);
      expect(input.analysis.traceMetrics?.maximumHeadPosition, 1);
    });

    test(
      'blank writes erase cells without shrinking the visited span',
      () async {
        final result = await TMSpaceProfiler.profile(
          _eraser(),
          limits: const TMSpaceProfileLimits(maxInputLength: 2),
        );

        final input = result.data!.rows[2].inputs.single;
        expect(input.metrics.maximumVisitedSpan, 3);
        expect(input.metrics.maximumNonBlankCells, 2);
        expect(
          input.analysis.traceMetrics?.tapeDiff.values.map(
            (change) => change.finalSymbol,
          ),
          everyElement('B'),
        );
      },
    );

    test('time can grow while observed space remains one cell', () async {
      final result = await TMSpaceProfiler.profile(
        _constantSpaceChain(8),
        limits: const TMSpaceProfileLimits(maxInputLength: 0),
      );

      final input = result.data!.rows.single.inputs.single;
      expect(input.analysis.stepsExecuted, 8);
      expect(input.metrics.maximumVisitedSpan, 1);
      expect(input.metrics.maximumNonBlankCells, 1);
    });

    test('distinguishes proven cycles from bounded unknown rows', () async {
      final cycle = await TMSpaceProfiler.profile(
        _stationaryCycle(),
        limits: const TMSpaceProfileLimits(maxInputLength: 0),
      );
      final unknown = await TMSpaceProfiler.profile(
        _rightMovingForever(),
        limits: const TMSpaceProfileLimits(
          maxInputLength: 0,
          maxStepsPerInput: 3,
        ),
      );

      expect(
        cycle.data!.rows.single.inputs.single.analysis.outcome,
        TMExecutionOutcome.provenCycle,
      );
      expect(cycle.data!.rows.single.isIncomplete, isFalse);
      expect(
        unknown.data!.rows.single.inputs.single.analysis.outcome,
        TMExecutionOutcome.boundedUnknown,
      );
      expect(unknown.data!.rows.single.isIncomplete, isTrue);
      expect(unknown.data!.rows.single.maximumVisitedSpan?.value, 4);
    });

    test(
      'labels exhaustive and deterministic sampled groups separately',
      () async {
        final progress = <TMSpaceProfileProgress>[];
        final result = await TMSpaceProfiler.profile(
          _immediateRejector(alphabet: const {'b', 'a'}),
          limits: const TMSpaceProfileLimits(
            maxInputLength: 2,
            maxCandidatesPerLength: 2,
          ),
          onProgress: progress.add,
        );

        final report = result.data!;
        expect(report.requestedCandidates, BigInt.from(7));
        expect(report.scheduledCandidates, 5);
        expect(
          report.rows[1].enumerationMode,
          TMSpaceEnumerationMode.exhaustive,
        );
        expect(report.rows[1].isIncomplete, isFalse);
        expect(report.rows[2].enumerationMode, TMSpaceEnumerationMode.sampled);
        expect(report.rows[2].isIncomplete, isTrue);
        expect(report.rows[2].inputs.map((input) => input.input), ['aa', 'ab']);
        expect(progress.first.evaluatedCandidates, 0);
        expect(progress.last.evaluatedCandidates, 5);
      },
    );

    test(
      'aggregates NTM maxima without merging selected-branch metrics',
      () async {
        final result = await TMSpaceProfiler.profile(
          _differentSpaceNtmBranches(),
          limits: const TMSpaceProfileLimits(maxInputLength: 0),
        );

        final report = result.data!;
        final input = report.rows.single.inputs.single;
        final selectedBranch = input.analysis.traceMetrics!;
        expect(report.isNondeterministic, isTrue);
        expect(input.metrics.aggregatesNondeterministicBranches, isTrue);
        expect(input.metrics.maximumVisitedSpan, 3);
        expect(
          selectedBranch.maximumHeadPosition -
              selectedBranch.minimumHeadPosition +
              1,
          1,
          reason: 'The selected operation branch remains separate.',
        );
        expect(input.analysis.maxConfigurations, 100000);
      },
    );

    test(
      'cancellation preserves completed length rows and a partial row',
      () async {
        var cancel = false;
        final result = await TMSpaceProfiler.profile(
          _immediateRejector(alphabet: const {'a', 'b'}),
          limits: const TMSpaceProfileLimits(
            maxInputLength: 3,
            maxCandidatesPerLength: 8,
          ),
          isCancelled: () => cancel,
          onProgress: (progress) {
            if (progress.evaluatedCandidates == 2) cancel = true;
          },
        );

        final report = result.data!;
        expect(report.cancelled, isTrue);
        expect(report.isIncomplete, isTrue);
        expect(report.rows.map((row) => row.inputLength), [0, 1]);
        expect(report.rows.last.inputs.map((input) => input.input), ['a']);
        expect(report.rows.last.cancelled, isTrue);
      },
    );
  });
}

TM _rightScanner() {
  final scan = _state('scan', initial: true);
  final accept = _state('accept', accepting: true);
  return _tm(
    states: {scan, accept},
    initial: scan,
    accepting: {accept},
    alphabet: const {'1'},
    tapeAlphabet: const {'1', 'B'},
    transitions: {
      _transition('scan-one', scan, scan, '1', '1', TapeDirection.right),
      _transition('accept', scan, accept, 'B', 'B', TapeDirection.stay),
    },
  );
}

TM _bidirectionalGrowthMachine() {
  final q0 = _state('q0', initial: true);
  final q1 = _state('q1');
  final q2 = _state('q2');
  final q3 = _state('q3');
  final accept = _state('accept', accepting: true);
  return _tm(
    states: {q0, q1, q2, q3, accept},
    initial: q0,
    accepting: {accept},
    tapeAlphabet: const {'X', 'Y', 'Z', 'B'},
    transitions: {
      _transition('write-center', q0, q1, 'B', 'X', TapeDirection.left),
      _transition('write-left', q1, q2, 'B', 'Y', TapeDirection.right),
      _transition('cross-center', q2, q3, 'X', 'X', TapeDirection.right),
      _transition('write-right', q3, accept, 'B', 'Z', TapeDirection.stay),
    },
  );
}

TM _eraser() {
  final erase = _state('erase', initial: true);
  final accept = _state('accept', accepting: true);
  return _tm(
    states: {erase, accept},
    initial: erase,
    accepting: {accept},
    alphabet: const {'1'},
    tapeAlphabet: const {'1', 'B'},
    transitions: {
      _transition('erase', erase, erase, '1', 'B', TapeDirection.right),
      _transition('accept', erase, accept, 'B', 'B', TapeDirection.stay),
    },
  );
}

TM _constantSpaceChain(int steps) {
  final states = [
    for (var index = 0; index <= steps; index++)
      _state('q$index', initial: index == 0, accepting: index == steps),
  ];
  return _tm(
    states: states.toSet(),
    initial: states.first,
    accepting: {states.last},
    tapeAlphabet: const {'X', 'Y', 'B'},
    transitions: {
      for (var index = 0; index < steps; index++)
        _transition(
          'step-$index',
          states[index],
          states[index + 1],
          index == 0
              ? 'B'
              : index.isOdd
                  ? 'X'
                  : 'Y',
          index.isEven ? 'X' : 'Y',
          TapeDirection.stay,
        ),
    },
  );
}

TM _stationaryCycle() {
  final q0 = _state('q0', initial: true);
  return _tm(
    states: {q0},
    initial: q0,
    transitions: {_transition('cycle', q0, q0, 'B', 'B', TapeDirection.stay)},
  );
}

TM _rightMovingForever() {
  final q0 = _state('q0', initial: true);
  return _tm(
    states: {q0},
    initial: q0,
    transitions: {_transition('move', q0, q0, 'B', 'B', TapeDirection.right)},
  );
}

TM _immediateRejector({Set<String> alphabet = const {}}) {
  final q0 = _state('q0', initial: true);
  return _tm(
    states: {q0},
    initial: q0,
    alphabet: alphabet,
    tapeAlphabet: {...alphabet, 'B'},
  );
}

TM _differentSpaceNtmBranches() {
  final q0 = _state('q0', initial: true);
  final stay1 = _state('stay1');
  final stay2 = _state('stay2');
  final wide1 = _state('wide1');
  final wide2 = _state('wide2');
  return _tm(
    states: {q0, stay1, stay2, wide1, wide2},
    initial: q0,
    transitions: {
      _transition('a-stay', q0, stay1, 'B', 'B', TapeDirection.stay),
      _transition('b-wide', q0, wide1, 'B', 'B', TapeDirection.left),
      _transition('stay-again', stay1, stay2, 'B', 'B', TapeDirection.stay),
      _transition('wide-again', wide1, wide2, 'B', 'B', TapeDirection.left),
    },
  );
}

State _state(String id, {bool initial = false, bool accepting = false}) {
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
  Set<TMTransition> transitions = const {},
  Set<State> accepting = const {},
  Set<String> alphabet = const {},
  Set<String> tapeAlphabet = const {'B'},
}) {
  return TM(
    id: 'space-profile-tm',
    name: 'Space profile TM',
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
  );
}
