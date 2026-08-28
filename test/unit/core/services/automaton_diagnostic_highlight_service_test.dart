import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/core/models/transition.dart';
import 'package:turing_lab/core/services/automaton_diagnostic_highlight_service.dart';

void main() {
  const service = AutomatonDiagnosticHighlightService();

  test('finds every FSA transition in a same-symbol conflict', () {
    final automaton = _automaton();

    expect(
      service.conflictingFsaTransitionIds(automaton),
      {'conflict-a', 'conflict-b'},
    );
  });

  test('keeps epsilon transitions in their standalone diagnostic', () {
    final automaton = _automaton();

    expect(service.epsilonFsaTransitionIds(automaton), {'epsilon-edge'});
    expect(
      service.conflictingFsaTransitionIds(automaton),
      isNot(contains('epsilon-edge')),
    );
  });

  test('does not mutate the automaton while building highlights', () {
    final automaton = _automaton();
    final transitionsBefore = Set<Transition>.of(automaton.transitions);

    final highlight = service.transitionHighlight(
      service.conflictingFsaTransitionIds(automaton),
    );

    expect(highlight.transitionIds, {'conflict-a', 'conflict-b'});
    expect(automaton.transitions, transitionsBefore);
  });
}

FSA _automaton() {
  final start = State(
    id: 'q0',
    label: 'q0',
    position: Vector2(80, 80),
    isInitial: true,
  );
  final first = State(
    id: 'q1',
    label: 'q1',
    position: Vector2(240, 40),
    isAccepting: true,
  );
  final second = State(
    id: 'q2',
    label: 'q2',
    position: Vector2(240, 160),
  );
  return FSA(
    id: 'diagnostic-fsa',
    name: 'Diagnostic FSA',
    states: {start, first, second},
    transitions: {
      FSATransition(
        id: 'conflict-a',
        fromState: start,
        toState: first,
        inputSymbols: const {'a'},
      ),
      FSATransition(
        id: 'conflict-b',
        fromState: start,
        toState: second,
        inputSymbols: const {'a'},
      ),
      FSATransition(
        id: 'independent-edge',
        fromState: start,
        toState: first,
        inputSymbols: const {'b', 'c'},
      ),
      FSATransition(
        id: 'epsilon-edge',
        fromState: first,
        toState: second,
        lambdaSymbol: 'ε',
      ),
    },
    alphabet: const {'a', 'b', 'c'},
    initialState: start,
    acceptingStates: {first},
    created: DateTime(2026),
    modified: DateTime(2026),
    bounds: const math.Rectangle(0, 0, 400, 300),
  );
}
