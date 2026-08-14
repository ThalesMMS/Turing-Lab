import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/automaton_simulator.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:vector_math/vector_math_64.dart';
import 'dart:math' as math;

/// DFA: q0 --a--> q1 --b--> q2(accept)
FSA _simpleDFA() {
  final q0 = State(
    id: 'q0',
    label: 'q0',
    position: Vector2(0, 0),
    isInitial: true,
  );
  final q1 = State(
    id: 'q1',
    label: 'q1',
    position: Vector2(100, 0),
  );
  final q2 = State(
    id: 'q2',
    label: 'q2',
    position: Vector2(200, 0),
    isAccepting: true,
  );
  return FSA(
    id: 'dfa1',
    name: 'Simple DFA',
    states: {q0, q1, q2},
    transitions: {
      FSATransition(
        id: 't0',
        fromState: q0,
        toState: q1,
        inputSymbols: {'a'},
        label: 'a',
      ),
      FSATransition(
        id: 't1',
        fromState: q1,
        toState: q2,
        inputSymbols: {'b'},
        label: 'b',
      ),
    },
    alphabet: {'a', 'b'},
    initialState: q0,
    acceptingStates: {q2},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 400, 300),
  );
}

/// NFA: q0 --a--> q1, q0 --a--> q2(accept)
FSA _simpleNFA() {
  final q0 = State(
    id: 'q0',
    label: 'q0',
    position: Vector2(0, 0),
    isInitial: true,
  );
  final q1 = State(
    id: 'q1',
    label: 'q1',
    position: Vector2(100, 0),
  );
  final q2 = State(
    id: 'q2',
    label: 'q2',
    position: Vector2(100, 100),
    isAccepting: true,
  );
  return FSA(
    id: 'nfa1',
    name: 'Simple NFA',
    states: {q0, q1, q2},
    transitions: {
      FSATransition(
        id: 't0',
        fromState: q0,
        toState: q1,
        inputSymbols: {'a'},
        label: 'a',
      ),
      FSATransition(
        id: 't1',
        fromState: q0,
        toState: q2,
        inputSymbols: {'a'},
        label: 'a',
      ),
    },
    alphabet: {'a'},
    initialState: q0,
    acceptingStates: {q2},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 400, 300),
  );
}

FSA _epsilonNFAWithInitialAndMidClosure() {
  final q0 = State(
    id: 'q0',
    label: 'q0',
    position: Vector2(0, 0),
    isInitial: true,
  );
  final q1 = State(
    id: 'q1',
    label: 'q1',
    position: Vector2(100, 0),
  );
  final q2 = State(
    id: 'q2',
    label: 'q2',
    position: Vector2(200, 0),
  );
  final q3 = State(
    id: 'q3',
    label: 'q3',
    position: Vector2(300, 0),
    isAccepting: true,
  );

  return FSA(
    id: 'epsilon-nfa',
    name: 'Epsilon NFA',
    states: {q0, q1, q2, q3},
    transitions: {
      FSATransition(
        id: 't0',
        fromState: q0,
        toState: q1,
        lambdaSymbol: 'ε',
      ),
      FSATransition(
        id: 't1',
        fromState: q1,
        toState: q2,
        inputSymbols: {'a'},
        label: 'a',
      ),
      FSATransition(
        id: 't2',
        fromState: q2,
        toState: q3,
        lambdaSymbol: 'ε',
      ),
    },
    alphabet: {'a'},
    initialState: q0,
    acceptingStates: {q3},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 400, 300),
  );
}

FSA _branchingNFA() {
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
  final transitions = <FSATransition>{};
  for (final from in [q0, q1]) {
    for (final to in [q0, q1]) {
      transitions.add(
        FSATransition(
          id: '${from.id}-${to.id}',
          fromState: from,
          toState: to,
          inputSymbols: {'a'},
          label: 'a',
        ),
      );
    }
  }
  return FSA(
    id: 'branching-nfa',
    name: 'Branching NFA',
    states: {q0, q1},
    transitions: transitions,
    alphabet: {'a'},
    initialState: q0,
    acceptingStates: {q1},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 200, 100),
  );
}

void main() {
  group('NFA recognition fast path', () {
    test('does not construct path nodes when trace mode is disabled', () async {
      final stopwatch = Stopwatch()..start();
      final result = await AutomatonSimulator.simulateNFA(
        _branchingNFA(),
        List.filled(1000, 'a').join(),
      );
      stopwatch.stop();

      expect(result.isSuccess, isTrue);
      expect(result.data!.accepted, isTrue);
      expect(result.data!.steps, isEmpty);
      expect(result.data!.computationTree, isNull);
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 2)));
    });

    test('trace mode stops at the configured node limit', () async {
      final result = await AutomatonSimulator.simulateNFA(
        _branchingNFA(),
        'aa',
        stepByStep: true,
        maxTraceNodes: 3,
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!.accepted, isFalse);
      expect(result.data!.errorMessage, contains('NFA trace truncated'));
      expect(result.data!.computationTree, isNotNull);
    });
  });

  group('DFA simulator step recording', () {
    test('Step records destination state, not source', () async {
      final dfa = _simpleDFA();
      final result = await AutomatonSimulator.simulateDFA(
        dfa,
        'ab',
        stepByStep: true,
      );
      expect(result.isSuccess, true);
      final steps = result.data!.steps;

      // steps[0] = initial (q0), steps[1] = after 'a', steps[2] = after 'b', steps[3] = final
      expect(steps.length, greaterThanOrEqualTo(3));

      // After consuming 'a', current state should be q1 (destination)
      final stepAfterA = steps[1];
      expect(stepAfterA.currentState, 'q1');

      // After consuming 'b', current state should be q2 (destination)
      final stepAfterB = steps[2];
      expect(stepAfterB.currentState, 'q2');
    });

    test('preserves each remaining input suffix exactly', () async {
      final result = await AutomatonSimulator.simulateDFA(
        _simpleDFA(),
        'ab',
        stepByStep: true,
      );

      expect(result.isSuccess, isTrue);
      expect(
        result.data!.steps.map((step) => step.remainingInput),
        ['ab', 'b', ''],
      );
    });
  });

  group('NFA simulator step recording', () {
    test('Step records destination states, not source', () async {
      final nfa = _simpleNFA();
      final result = await AutomatonSimulator.simulateNFA(
        nfa,
        'a',
        stepByStep: true,
      );
      expect(result.isSuccess, true);
      final steps = result.data!.steps;

      // After consuming 'a', current state should be the destination set {q1,q2}
      // (not the source q0)
      final intermediateSteps = steps.where((s) => s.stepNumber > 0).toList();
      expect(intermediateSteps, isNotEmpty);
      for (final step in intermediateSteps) {
        expect(step.currentState, isNot('q0'));
      }
    });

    test('epsilon annotation steps have unique step numbers', () async {
      final nfa = _epsilonNFAWithInitialAndMidClosure();
      final result = await AutomatonSimulator.simulateNFA(
        nfa,
        'a',
        stepByStep: true,
      );
      expect(result.isSuccess, true);
      final steps = result.data!.steps;
      final stepNumbers = steps.map((s) => s.stepNumber).toList();

      expect(stepNumbers.toSet(), hasLength(stepNumbers.length));
    });

    test('appends final verdict after trailing epsilon closure step', () async {
      final nfa = _epsilonNFAWithInitialAndMidClosure();
      final result = await AutomatonSimulator.simulateNFA(
        nfa,
        'a',
        stepByStep: true,
      );
      expect(result.isSuccess, true);

      final steps = result.data!.steps;
      expect(steps.where((s) => s.usedTransition == 'ε-closure'), isNotEmpty);
      expect(steps[steps.length - 2].usedTransition, 'ε-closure');
      expect(steps.last.usedTransition, isNull);
      expect(steps.last.remainingInput, isEmpty);
      expect(steps.last.currentState, '{q2,q3}');
    });

    test('does not duplicate final symbol step without epsilon closure',
        () async {
      final nfa = _simpleNFA();
      final result = await AutomatonSimulator.simulateNFA(
        nfa,
        'a',
        stepByStep: true,
      );
      expect(result.isSuccess, true);

      final steps = result.data!.steps;
      expect(steps.last.remainingInput, isEmpty);
      expect(steps.last.currentState, '{q1,q2}');
      expect(
        steps.where(
          (s) => s.remainingInput.isEmpty && s.currentState == '{q1,q2}',
        ),
        hasLength(1),
      );
      expect(result.data!.computationTree?.totalSteps, steps.last.stepNumber);
    });
  });
}
