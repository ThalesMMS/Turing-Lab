import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/automaton_simulator.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/simulation_step.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/core/models/step_explanation.dart';
import 'package:turing_lab/core/services/simulation_highlight_service.dart';
import 'package:vector_math/vector_math_64.dart';
import 'dart:math' as math;

List<String> transitionHighlightIds(SimulationStep step) => step
    .explanation!.highlights
    .where(
      (target) =>
          target.type == HighlightTargetType.transition && target.id != null,
    )
    .map((target) => target.id!)
    .toList(growable: false);

/// DFA: q0 --a--> q1 --b--> q2(accept)
FSA _simpleDFA({bool initialAccepting = false}) {
  final q0 = State(
    id: 'dfa-state-0',
    label: 'q0',
    position: Vector2(0, 0),
    isInitial: true,
    isAccepting: initialAccepting,
  );
  final q1 = State(
    id: 'dfa-state-1',
    label: 'q1',
    position: Vector2(100, 0),
  );
  final q2 = State(
    id: 'dfa-state-2',
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
    acceptingStates: {if (initialAccepting) q0, q2},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 400, 300),
  );
}

/// NFA: q0 --a--> q1, q0 --a--> q2(accept)
FSA _simpleNFA() {
  final q0 = State(
    id: 'nfa-state-0',
    label: 'q0',
    position: Vector2(0, 0),
    isInitial: true,
  );
  final q1 = State(
    id: 'nfa-state-1',
    label: 'q1',
    position: Vector2(100, 0),
  );
  final q2 = State(
    id: 'nfa-state-2',
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
    id: 'epsilon-state-0',
    label: 'q0',
    position: Vector2(0, 0),
    isInitial: true,
  );
  final q1 = State(
    id: 'epsilon-state-1',
    label: 'q1',
    position: Vector2(100, 0),
  );
  final q2 = State(
    id: 'epsilon-state-2',
    label: 'q2',
    position: Vector2(200, 0),
  );
  final q3 = State(
    id: 'epsilon-state-3',
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

FSA _epsilonAliasNFAWithParallelCycles() {
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
    id: 'epsilon-alias-nfa',
    name: 'Epsilon Alias NFA',
    states: {q0, q1, q2, q3},
    transitions: {
      FSATransition(
        id: 'initial-parallel-1',
        fromState: q0,
        toState: q1,
        inputSymbols: {'lambda'},
      ),
      FSATransition(
        id: 'initial-parallel-2',
        fromState: q0,
        toState: q1,
        inputSymbols: {'lambda'},
      ),
      FSATransition(
        id: 'initial-cycle',
        fromState: q1,
        toState: q0,
        inputSymbols: {'lambda'},
      ),
      FSATransition(
        id: 'symbol',
        fromState: q1,
        toState: q2,
        inputSymbols: {'a'},
      ),
      FSATransition(
        id: 'post-parallel-1',
        fromState: q2,
        toState: q3,
        inputSymbols: {'lambda'},
      ),
      FSATransition(
        id: 'post-parallel-2',
        fromState: q2,
        toState: q3,
        inputSymbols: {'lambda'},
      ),
      FSATransition(
        id: 'post-cycle',
        fromState: q3,
        toState: q2,
        inputSymbols: {'lambda'},
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

FSA _singleStateConsumingLoopFsa() {
  final state = State(
    id: 'loop-state',
    label: 'q0',
    position: Vector2.zero(),
    isInitial: true,
    isAccepting: true,
  );
  return FSA(
    id: 'consuming-loop-nfa',
    name: 'Consuming loop NFA',
    states: {state},
    transitions: {
      FSATransition(
        id: 'consume-a',
        fromState: state,
        toState: state,
        inputSymbols: const {'a'},
      ),
    },
    alphabet: const {'a'},
    initialState: state,
    acceptingStates: {state},
    created: DateTime.utc(2026),
    modified: DateTime.utc(2026),
    bounds: const math.Rectangle(0, 0, 100, 100),
  );
}

FSA _epsilonChainNfa(int stateCount) {
  final states = List<State>.generate(
    stateCount,
    (index) => State(
      id: 'epsilon-chain-$index',
      label: 'q$index',
      position: Vector2(index * 10.0, 0),
      isInitial: index == 0,
      isAccepting: index == stateCount - 1,
    ),
    growable: false,
  );
  return FSA(
    id: 'epsilon-chain-nfa',
    name: 'Epsilon chain NFA',
    states: states.toSet(),
    transitions: {
      for (var index = 0; index < stateCount - 1; index++)
        FSATransition(
          id: 'epsilon-chain-edge-$index',
          fromState: states[index],
          toState: states[index + 1],
          lambdaSymbol: 'ε',
        ),
    },
    alphabet: const {},
    initialState: states.first,
    acceptingStates: {states.last},
    created: DateTime.utc(2026),
    modified: DateTime.utc(2026),
    bounds: math.Rectangle(0, 0, stateCount * 10.0, 100),
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

    test('trace mode does not call long consuming input an infinite loop',
        () async {
      final result = await AutomatonSimulator.simulateNFA(
        _singleStateConsumingLoopFsa(),
        List.filled(1001, 'a').join(),
        stepByStep: true,
        timeout: const Duration(seconds: 20),
        maxTraceNodes: 2000,
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!.accepted, isTrue);
      expect(result.data!.isInfiniteLoop, isFalse);
    });

    test('trace mode bounds retained epsilon provenance by path depth',
        () async {
      final result = await AutomatonSimulator.simulateNFA(
        _epsilonChainNfa(300),
        '',
        stepByStep: true,
        maxTraceNodes: 10000,
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!.accepted, isFalse);
      expect(result.data!.isInfiniteLoop, isFalse);
      expect(result.data!.errorMessage, contains('epsilon-path limit'));
      expect(result.data!.computationTree, isNotNull);
    });

    test('trace mode checks timeout while enumerating initial epsilon paths',
        () async {
      final result = await AutomatonSimulator.simulateNFA(
        _epsilonChainNfa(300),
        '',
        stepByStep: true,
        timeout: Duration.zero,
        maxTraceNodes: 10000,
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!.isTimeout, isTrue);
    });
  });

  group('DFA simulator step recording', () {
    test('long consuming input is not reported as an infinite loop', () async {
      final result = await AutomatonSimulator.simulateDFA(
        _singleStateConsumingLoopFsa(),
        List.filled(10001, 'a').join(),
        stepByStep: true,
        timeout: const Duration(seconds: 20),
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!.accepted, isTrue);
      expect(result.data!.isInfiniteLoop, isFalse);
    });

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

    test('exposes stable DFA state ids without changing display or edge data',
        () async {
      final result = await AutomatonSimulator.simulateDFA(
        _simpleDFA(),
        'a',
        stepByStep: true,
      );

      expect(result.isSuccess, isTrue);
      final steps = result.data!.steps;
      expect(steps, hasLength(2));
      expect(steps.map((step) => step.currentState), ['q0', 'q1']);
      expect(steps[0].activeStateIds, {'dfa-state-0'});
      final step = steps[1];
      expect(step.activeStateIds, {'dfa-state-1'});
      expect(step.usedTransition, 'δ(q0, a) = q1');
      expect(transitionHighlightIds(step), ['t0']);
    });

    test('empty-input DFA keeps the initial stable id without a final copy',
        () async {
      final result = await AutomatonSimulator.simulateDFA(
        _simpleDFA(initialAccepting: true),
        '',
        stepByStep: true,
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!.accepted, isTrue);
      expect(result.data!.steps, hasLength(1));
      expect(result.data!.steps.single.currentState, 'q0');
      expect(result.data!.steps.single.activeStateIds, {'dfa-state-0'});
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

    test('symbol step exposes every matching NFA edge id', () async {
      final result = await AutomatonSimulator.simulateNFA(
        _simpleNFA(),
        'a',
        stepByStep: true,
      );

      expect(result.isSuccess, isTrue);
      final steps = result.data!.steps;
      expect(steps, hasLength(2));
      expect(steps.map((step) => step.currentState), ['q0', '{q1,q2}']);
      expect(steps.map((step) => step.stepNumber), [0, 1]);
      expect(steps[0].activeStateIds, {'nfa-state-0'});
      final step = steps[1];
      expect(step.activeStateIds, {'nfa-state-1', 'nfa-state-2'});
      expect(step.usedTransition, 'a');
      expect(transitionHighlightIds(step).toSet(), {'t0', 't1'});
    });

    test('epsilon closure steps expose their edges without changing the trace',
        () async {
      final result = await AutomatonSimulator.simulateNFA(
        _epsilonNFAWithInitialAndMidClosure(),
        'a',
        stepByStep: true,
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!.accepted, isTrue);
      final steps = result.data!.steps;
      expect(result.data!.computationTree?.totalSteps, 4);
      expect(steps.map((step) => step.stepNumber), [0, 1, 2, 3, 4]);
      expect(steps.map((step) => step.usedTransition), [
        isNull,
        'ε-closure',
        'a',
        'ε-closure',
        isNull,
      ]);
      expect(steps.map((step) => step.currentState), [
        '{q0,q1}',
        '{q0,q1}',
        'q2',
        '{q2,q3}',
        '{q2,q3}',
      ]);
      expect(steps.map((step) => step.activeStateIds), [
        {'epsilon-state-0', 'epsilon-state-1'},
        {'epsilon-state-0', 'epsilon-state-1'},
        {'epsilon-state-2'},
        {'epsilon-state-2', 'epsilon-state-3'},
        {'epsilon-state-2', 'epsilon-state-3'},
      ]);
      final closureSteps =
          steps.where((step) => step.usedTransition == 'ε-closure').toList();
      expect(transitionHighlightIds(closureSteps[0]), ['t0']);
      expect(transitionHighlightIds(closureSteps[1]), ['t2']);
      expect(transitionHighlightIds(steps[2]), ['t1']);
    });

    test('no-transition NFA emits an authoritative empty active set', () async {
      final result = await AutomatonSimulator.simulateNFA(
        _simpleNFA(),
        'b',
        stepByStep: true,
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!.accepted, isFalse);
      final steps = result.data!.steps;
      expect(steps, hasLength(2));
      expect(steps.last.currentState, '{}');
      expect(steps.last.usedTransition, 'b');
      expect(steps.last.activeStateIds, isEmpty);
      expect(
        SimulationHighlightService().computeFromSteps(steps, 1).stateIds,
        isEmpty,
      );
    });

    test('empty-input NFA keeps the initial stable id without a final copy',
        () async {
      final result = await AutomatonSimulator.simulateNFA(
        _simpleNFA(),
        '',
        stepByStep: true,
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!.steps, hasLength(1));
      expect(result.data!.steps.single.currentState, 'q0');
      expect(result.data!.steps.single.activeStateIds, {'nfa-state-0'});
    });

    test('epsilon alias closures keep parallel and cycle edge ids distinct',
        () async {
      final result = await AutomatonSimulator.simulateNFA(
        _epsilonAliasNFAWithParallelCycles(),
        'a',
        stepByStep: true,
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!.accepted, isTrue);
      final steps = result.data!.steps;
      expect(steps.map((step) => step.stepNumber), [0, 1, 2, 3, 4]);
      expect(steps.map((step) => step.usedTransition), [
        isNull,
        'ε-closure',
        'a',
        'ε-closure',
        isNull,
      ]);
      expect(transitionHighlightIds(steps[2]), ['symbol']);

      final closureSteps =
          steps.where((step) => step.usedTransition == 'ε-closure').toList();
      final closureTransitionIds =
          closureSteps.map(transitionHighlightIds).toList();
      expect(closureTransitionIds[0], hasLength(3));
      expect(
        closureTransitionIds[0].toSet(),
        {'initial-parallel-1', 'initial-parallel-2', 'initial-cycle'},
      );
      expect(closureTransitionIds[1], hasLength(3));
      expect(
        closureTransitionIds[1].toSet(),
        {'post-parallel-1', 'post-parallel-2', 'post-cycle'},
      );
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
