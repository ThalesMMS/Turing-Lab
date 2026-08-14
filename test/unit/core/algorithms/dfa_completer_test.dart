import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:turing_lab/core/algorithms/dfa_completer.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/state.dart';

void main() {
  group('DFACompleter', () {
    test('allocates collision-free IDs for arbitrary alphabet symbols', () {
      final q0 = _state('q0', 0, isInitial: true);
      final userTrap = _state('q_trap', 120, isAccepting: true);
      final dfa = _dfa(
        states: {q0, userTrap},
        alphabet: {'a b', 'a/b', 'a_b', 'λ', '🔥'},
        transitions: {
          _transition('t_complete', q0, q0, 'a b'),
          _transition('t_complete_1', userTrap, userTrap, 'a b'),
        },
        initialState: q0,
        acceptingStates: {userTrap},
      );

      final completed = DFACompleter.complete(dfa);
      final stateIds = completed.states.map((state) => state.id).toList();
      final transitionIds =
          completed.fsaTransitions.map((transition) => transition.id).toList();
      final generatedTrap = completed.states.singleWhere(
        (state) => state.type == StateType.trap,
      );

      expect(stateIds.toSet(), hasLength(stateIds.length));
      expect(transitionIds.toSet(), hasLength(transitionIds.length));
      expect(generatedTrap.id, 'q_trap_1');
      expect(generatedTrap.position.distanceTo(userTrap.position), 120);
      expect(completed.bounds.right, greaterThan(generatedTrap.position.x));
      expect(
        transitionIds.where((id) => id.startsWith('t_complete')),
        hasLength(transitionIds.length),
      );
      _expectComplete(completed);
    });

    test('reuses only a semantically complete non-accepting sink', () {
      final q0 = _state('q0', 0, isInitial: true);
      final sink = _state('existing_sink', 120);
      final dfa = _dfa(
        states: {q0, sink},
        alphabet: {'a', 'b'},
        transitions: {
          _transition('q0_a', q0, q0, 'a'),
          _transition('sink_a', sink, sink, 'a'),
          _transition('sink_b', sink, sink, 'b'),
        },
        initialState: q0,
      );

      final completed = DFACompleter.complete(dfa);

      expect(completed.states, hasLength(2));
      expect(
        completed.fsaTransitions
            .singleWhere(
              (transition) =>
                  transition.fromState.id == q0.id &&
                  transition.inputSymbols.contains('b'),
            )
            .toState,
        same(sink),
      );
      _expectComplete(completed);
    });

    test('is structurally idempotent once the DFA is complete', () {
      final q0 = _state('q0', 0, isInitial: true);
      final incomplete = _dfa(
        states: {q0},
        alphabet: {'a', 'b'},
        transitions: {_transition('q0_a', q0, q0, 'a')},
        initialState: q0,
      );

      final completed = DFACompleter.complete(incomplete);
      final completedAgain = DFACompleter.complete(completed);

      expect(completedAgain, same(completed));
    });

    test('round-trip keeps generated IDs and canonical canvas endpoints', () {
      final q0 = _state('q0', 20, isInitial: true);
      final completed = DFACompleter.complete(
        _dfa(
          states: {q0},
          alphabet: {'a b', '🔥'},
          transitions: const {},
          initialState: q0,
        ),
      );

      final restored = FSA.fromJson(completed.toJson());
      final statesById = {for (final state in restored.states) state.id: state};

      expect(statesById, hasLength(restored.states.length));
      expect(
        restored.fsaTransitions.map((transition) => transition.id).toSet(),
        hasLength(restored.fsaTransitions.length),
      );
      for (final transition in restored.fsaTransitions) {
        expect(transition.fromState, same(statesById[transition.fromState.id]));
        expect(transition.toState, same(statesById[transition.toState.id]));
      }
      _expectComplete(restored);
    });
  });
}

void _expectComplete(FSA dfa) {
  for (final state in dfa.states) {
    for (final symbol in dfa.alphabet) {
      expect(
        dfa.fsaTransitions.where(
          (transition) =>
              transition.fromState.id == state.id &&
              transition.inputSymbols.contains(symbol),
        ),
        hasLength(1),
        reason: '${state.id} must have one transition for "$symbol"',
      );
    }
  }
}

State _state(
  String id,
  double x, {
  bool isInitial = false,
  bool isAccepting = false,
}) {
  return State(
    id: id,
    label: id,
    position: Vector2(x, 100),
    isInitial: isInitial,
    isAccepting: isAccepting,
  );
}

FSATransition _transition(
  String id,
  State from,
  State to,
  String symbol,
) {
  return FSATransition.deterministic(
    id: id,
    fromState: from,
    toState: to,
    symbol: symbol,
    controlPoint: identical(from, to) ? from.position + Vector2(40, -40) : null,
  );
}

FSA _dfa({
  required Set<State> states,
  required Set<String> alphabet,
  required Set<FSATransition> transitions,
  required State initialState,
  Set<State> acceptingStates = const {},
}) {
  return FSA(
    id: 'dfa',
    name: 'DFA',
    states: states,
    transitions: transitions,
    alphabet: alphabet,
    initialState: initialState,
    acceptingStates: acceptingStates,
    created: DateTime.utc(2026),
    modified: DateTime.utc(2026),
    bounds: const math.Rectangle(0, 0, 200, 200),
  );
}
