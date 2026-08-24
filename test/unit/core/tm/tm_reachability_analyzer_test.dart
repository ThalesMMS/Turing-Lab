import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/tm_reachability_analyzer.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/core/models/tm.dart';
import 'package:turing_lab/core/models/tm_execution_analysis.dart';
import 'package:turing_lab/core/models/tm_reachability_report.dart';
import 'package:turing_lab/core/models/tm_transition.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  group('TMReachabilityAnalyzer', () {
    test('separates structural edges from concrete semantic reachability',
        () async {
      final q0 = _state('q0', initial: true);
      final guarded = _state('guarded');
      final tm = _tm(
        states: {q0, guarded},
        initial: q0,
        alphabet: const {'1'},
        tapeAlphabet: const {'1', 'B'},
        transitions: {
          _transition('never', q0, guarded, '1', '1', TapeDirection.stay),
        },
      );

      final report = await TMReachabilityAnalyzer.analyze(
        tm,
        inputs: const [''],
      );

      expect(report.status, TMReachabilityStatus.complete);
      expect(report.structurallyReachableStateIds, {'q0', 'guarded'});
      expect(report.reachedWithinBoundsStateIds, {'q0'});
      expect(report.notObservedWithinBoundsStateIds, {'guarded'});
      expect(report.structurallyUnreachableStateIds, isEmpty);
    });

    test('records a shortest stable witness after writing a marker', () async {
      final q0 = _state('q0', initial: true);
      final q1 = _state('q1');
      final q2 = _state('q2');
      final tm = _tm(
        states: {q0, q1, q2},
        initial: q0,
        tapeAlphabet: const {'X', 'B'},
        transitions: {
          _transition('write-marker', q0, q1, 'B', 'X', TapeDirection.stay),
          _transition('read-marker', q1, q2, 'X', 'X', TapeDirection.right),
        },
      );

      final report = await TMReachabilityAnalyzer.analyze(
        tm,
        inputs: const [''],
      );
      final witness = report.witnessesByStateId['q2']!;

      expect(witness.step, 2);
      expect(witness.headPosition, 1);
      expect(witness.incomingTransitionId, 'read-marker');
      expect(witness.transitionIds, ['write-marker', 'read-marker']);
      expect(witness.stateIds, ['q0', 'q1', 'q2']);
    });

    test('combines an explicit input set and retains each witness input',
        () async {
      final q0 = _state('q0', initial: true);
      final qa = _state('qa');
      final qb = _state('qb');
      final tm = _tm(
        states: {q0, qa, qb},
        initial: q0,
        alphabet: const {'a', 'b'},
        tapeAlphabet: const {'a', 'b', 'B'},
        transitions: {
          _transition('on-a', q0, qa, 'a', 'a', TapeDirection.stay),
          _transition('on-b', q0, qb, 'b', 'b', TapeDirection.stay),
        },
      );

      final report = await TMReachabilityAnalyzer.analyze(
        tm,
        inputs: const ['b', 'a'],
      );

      expect(report.inputs, ['a', 'b']);
      expect(report.witnessesByStateId['qa']?.input, 'a');
      expect(report.witnessesByStateId['qb']?.input, 'b');
    });

    test('uses BFS so an NTM witness has minimum transition count', () async {
      final q0 = _state('q0', initial: true);
      final middle = _state('middle');
      final target = _state('target');
      final tm = _tm(
        states: {q0, middle, target},
        initial: q0,
        transitions: {
          _transition('a-indirect', q0, middle, 'B', 'B', TapeDirection.stay),
          _transition('z-direct', q0, target, 'B', 'B', TapeDirection.stay),
          _transition(
              'via-middle', middle, target, 'B', 'B', TapeDirection.stay),
        },
      );

      final report = await TMReachabilityAnalyzer.analyze(
        tm,
        inputs: const [''],
      );

      expect(report.witnessesByStateId['target']?.step, 1);
      expect(report.witnessesByStateId['target']?.transitionIds, ['z-direct']);
    });

    test('keeps disconnected states as exact structural evidence', () async {
      final q0 = _state('q0', initial: true);
      final disconnected = _state('disconnected');
      final tm = _tm(states: {q0, disconnected}, initial: q0);

      final report = await TMReachabilityAnalyzer.analyze(
        tm,
        inputs: const [''],
      );

      expect(report.structurallyUnreachableStateIds, {'disconnected'});
      expect(report.notObservedWithinBoundsStateIds, isEmpty);
    });

    test('reports an incomplete bound instead of a negative claim', () async {
      final q0 = _state('q0', initial: true);
      final q1 = _state('q1');
      final q2 = _state('q2');
      final tm = _tm(
        states: {q0, q1, q2},
        initial: q0,
        transitions: {
          _transition('first', q0, q1, 'B', 'B', TapeDirection.right),
          _transition('second', q1, q2, 'B', 'B', TapeDirection.right),
        },
      );

      final report = await TMReachabilityAnalyzer.analyze(
        tm,
        inputs: const [''],
        maxSteps: 1,
      );

      expect(report.status, TMReachabilityStatus.boundedIncomplete);
      expect(report.limit, TMExecutionLimit.steps);
      expect(report.notObservedWithinBoundsStateIds, {'q2'});
      expect(report.structurallyUnreachableStateIds, isEmpty);
    });

    test('configuration cap bounds a large explicit input scope', () async {
      final q0 = _state('q0', initial: true);
      final tm = _tm(
        states: {q0},
        initial: q0,
        alphabet: const {'a'},
        tapeAlphabet: const {'a', 'B'},
      );

      final report = await TMReachabilityAnalyzer.analyze(
        tm,
        inputs: List.generate(
          20,
          (index) => List.filled(index + 1, 'a').join(),
        ),
        maxConfigurations: 5,
      );

      expect(report.status, TMReachabilityStatus.boundedIncomplete);
      expect(report.limit, TMExecutionLimit.configurations);
      expect(report.configurationsExplored, lessThanOrEqualTo(5));
    });

    test('cooperative exploration can be cancelled', () async {
      final q0 = _state('q0', initial: true);
      final tm = _tm(
        states: {q0},
        initial: q0,
        transitions: {
          _transition('move', q0, q0, 'B', 'B', TapeDirection.right),
        },
      );
      var cancellationChecks = 0;

      final report = await TMReachabilityAnalyzer.analyze(
        tm,
        inputs: const [''],
        maxSteps: 10000,
        operationsPerBatch: 1,
        isCancelled: () => cancellationChecks++ > 2,
      );

      expect(report.status, TMReachabilityStatus.cancelled);
      expect(report.isComplete, isFalse);
    });

    test('publishes transition and configuration progress after each batch',
        () async {
      final q0 = _state('q0', initial: true);
      final q1 = _state('q1');
      final tm = _tm(
        states: {q0, q1},
        initial: q0,
        transitions: {
          _transition('reach', q0, q1, 'B', 'B', TapeDirection.stay),
        },
      );
      final progress = <(int, int)>[];

      final report = await TMReachabilityAnalyzer.analyze(
        tm,
        inputs: const [''],
        operationsPerBatch: 1,
        onProgress: (transitions, configurations) {
          progress.add((transitions, configurations));
        },
      );

      expect(report.isComplete, isTrue);
      expect(progress, isNotEmpty);
      expect(
        progress.last,
        (report.transitionsExplored, report.configurationsExplored),
      );
    });

    test('structural traversal is iterative for a large chain', () {
      const count = 5000;
      final states = <State>{};
      final transitions = <TMTransition>{};
      final ordered = List.generate(
        count,
        (index) => _state('q$index', initial: index == 0),
      );
      states.addAll(ordered);
      for (var index = 0; index < ordered.length - 1; index++) {
        transitions.add(
          _transition(
            't$index',
            ordered[index],
            ordered[index + 1],
            'B',
            'B',
            TapeDirection.stay,
          ),
        );
      }
      final tm = _tm(
        states: states,
        initial: ordered.first,
        transitions: transitions,
      );

      expect(
        TMReachabilityAnalyzer.structurallyReachableStateIds(tm),
        hasLength(count),
      );
    });
  });
}

State _state(String id, {bool initial = false}) => State(
      id: id,
      label: id,
      position: Vector2.zero(),
      isInitial: initial,
    );

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
  Set<String> alphabet = const {},
  Set<String> tapeAlphabet = const {'B'},
}) {
  return TM(
    id: 'reachability-tm',
    name: 'Reachability TM',
    states: states,
    transitions: transitions,
    alphabet: alphabet,
    initialState: initial,
    acceptingStates: const {},
    created: DateTime(2026),
    modified: DateTime(2026),
    bounds: const math.Rectangle(0, 0, 400, 300),
    tapeAlphabet: tapeAlphabet,
    blankSymbol: 'B',
    tapeCount: 1,
  );
}
