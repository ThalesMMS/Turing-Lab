//
//  equivalence_validation_test.dart
//  Turing Lab
//
//  Conjunto de testes que valida o EquivalenceChecker para DFAs e NFAs, cobrindo cenários equivalentes, não equivalentes e comparações cruzadas entre autômatos construídos de maneiras distintas.
//  O arquivo monta máquinas de exemplo para assegurar diagnósticos coerentes e resultados consistentes mesmo em casos extremos e entradas malformadas.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/algorithms/equivalence_checker.dart';
import 'package:vector_math/vector_math_64.dart';
import 'dart:math' as math;

import 'core/algorithms/fsa_test_fixtures.dart';

void main() {
  group('Equivalence Checker Validation Tests', () {
    late FSA dfa1;
    late FSA dfa2;
    late FSA nfa1;
    late FSA nfa2;
    late FSA nonEquivalentDFA;

    setUp(() {
      // Test Case 1: Equivalent DFAs
      dfa1 = _createDFA1();
      dfa2 = _createDFA2();

      // Test Case 2: Equivalent NFAs
      nfa1 = _createNFA1();
      nfa2 = _createNFA2();

      // Test Case 4: Non-equivalent DFA
      nonEquivalentDFA = _createNonEquivalentDFA();
    });

    group('DFA Equivalence Tests', () {
      test('Equivalent DFAs should be recognized as equivalent', () {
        final isEquivalent = EquivalenceChecker.areEquivalent(dfa1, dfa2);

        expect(
          isEquivalent,
          true,
          reason: 'Equivalent DFAs should be recognized as equivalent',
        );
      });

      test('Same DFA should be equivalent to itself', () {
        final isEquivalent = EquivalenceChecker.areEquivalent(dfa1, dfa1);

        expect(
          isEquivalent,
          true,
          reason: 'Same DFA should be equivalent to itself',
        );
      });

      test('Non-equivalent DFAs should be recognized as non-equivalent', () {
        final isEquivalent = EquivalenceChecker.areEquivalent(
          dfa1,
          nonEquivalentDFA,
        );

        expect(
          isEquivalent,
          false,
          reason: 'Non-equivalent DFAs should be recognized as non-equivalent',
        );
      });
    });

    group('NFA Equivalence Tests', () {
      test('Equivalent NFAs should be recognized as equivalent', () {
        final isEquivalent = EquivalenceChecker.areEquivalent(nfa1, nfa2);

        expect(
          isEquivalent,
          true,
          reason: 'Equivalent NFAs should be recognized as equivalent',
        );
      });

      test('Same NFA should be equivalent to itself', () {
        final isEquivalent = EquivalenceChecker.areEquivalent(nfa1, nfa1);

        expect(
          isEquivalent,
          true,
          reason: 'Same NFA should be equivalent to itself',
        );
      });

      test('NFA determinization failure is exposed as inconclusive', () {
        final invalidNfa = createNFAWithInvalidAcceptingState().copyWith(
          alphabet: dfa1.alphabet,
        );

        final result = EquivalenceChecker.areEquivalentResult(
          invalidNfa,
          dfa1,
        );

        expect(result.isFailure, true);
        expect(result.error, contains('Failed to determinize automaton A'));
        expect(
          result.error,
          contains('Accepting state must be in the states set'),
        );
      });
    });

    group('Cross-Type Equivalence Tests', () {
      test('DFA and NFA with same language should be equivalent', () {
        final isEquivalent = EquivalenceChecker.areEquivalent(dfa1, nfa1);

        expect(
          isEquivalent,
          true,
          reason: 'DFA and NFA with same language should be equivalent',
        );
      });

      test('DFA and NFA with different languages should not be equivalent', () {
        // Use nonEquivalentDFA which has a different language
        final isEquivalent = EquivalenceChecker.areEquivalent(
          nfa1,
          nonEquivalentDFA,
        );

        expect(
          isEquivalent,
          false,
          reason:
              'DFA and NFA with different languages should not be equivalent',
        );
      });
    });

    group('Edge Cases Tests', () {
      test('Empty automata should not be equivalent', () {
        final emptyDFA1 = _createEmptyDFA();
        final emptyDFA2 = _createEmptyDFA();

        final isEquivalent = EquivalenceChecker.areEquivalent(
          emptyDFA1,
          emptyDFA2,
        );

        expect(
          isEquivalent,
          false,
          reason: 'Empty automata should not be equivalent',
        );
      });

      test('Automata with different alphabets should not be equivalent', () {
        final dfaA = _createDFAWithAlphabet({'a', 'b'});
        final dfaB = _createDFAWithAlphabet({'0', '1'});

        final isEquivalent = EquivalenceChecker.areEquivalent(dfaA, dfaB);

        expect(
          isEquivalent,
          false,
          reason: 'Automata with different alphabets should not be equivalent',
        );
      });

      test('Automata with no initial state should not be equivalent', () {
        final noInitialDFA1 = _createNoInitialDFA();
        final noInitialDFA2 = _createNoInitialDFA();

        final isEquivalent = EquivalenceChecker.areEquivalent(
          noInitialDFA1,
          noInitialDFA2,
        );

        expect(
          isEquivalent,
          false,
          reason: 'Automata with no initial state should not be equivalent',
        );
      });
    });

    group('Performance Tests', () {
      test('Equivalence checking should complete within reasonable time', () {
        final stopwatch = Stopwatch()..start();

        final isEquivalent = EquivalenceChecker.areEquivalent(dfa1, dfa2);

        stopwatch.stop();

        expect(
          isEquivalent,
          true,
          reason: 'Equivalent DFAs should be recognized as equivalent',
        );
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(1000),
          reason: 'Equivalence checking should complete within 1 second',
        );
      });
    });
  });
}

/// Helper functions to create test automata

FSA _createDFA1() {
  final states = {
    State(
      id: 'q0',
      label: 'q0',
      position: Vector2(0, 0),
      isInitial: true,
      isAccepting: false,
    ),
    State(
      id: 'q1',
      label: 'q1',
      position: Vector2(100, 0),
      isInitial: false,
      isAccepting: true,
    ),
  };

  final transitions = {
    FSATransition(
      id: 't1',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      symbol: '1',
    ),
    FSATransition(
      id: 't2',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q0'),
      symbol: '0',
    ),
    FSATransition(
      id: 't3',
      fromState: states.firstWhere((s) => s.id == 'q1'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      symbol: '0',
    ),
    FSATransition(
      id: 't4',
      fromState: states.firstWhere((s) => s.id == 'q1'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      symbol: '1',
    ),
  };

  return FSA(
    id: 'dfa1',
    name: 'DFA1',
    states: states,
    transitions: transitions,
    alphabet: {'0', '1'},
    initialState: states.firstWhere((s) => s.id == 'q0'),
    acceptingStates: {states.firstWhere((s) => s.id == 'q1')},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 200, 100),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}

FSA _createDFA2() {
  final states = {
    State(
      id: 'p0',
      label: 'p0',
      position: Vector2(0, 0),
      isInitial: true,
      isAccepting: false,
    ),
    State(
      id: 'p1',
      label: 'p1',
      position: Vector2(100, 0),
      isInitial: false,
      isAccepting: true,
    ),
  };

  final transitions = {
    FSATransition(
      id: 't1',
      fromState: states.firstWhere((s) => s.id == 'p0'),
      toState: states.firstWhere((s) => s.id == 'p1'),
      symbol: '1',
    ),
    FSATransition(
      id: 't2',
      fromState: states.firstWhere((s) => s.id == 'p0'),
      toState: states.firstWhere((s) => s.id == 'p0'),
      symbol: '0',
    ),
    FSATransition(
      id: 't3',
      fromState: states.firstWhere((s) => s.id == 'p1'),
      toState: states.firstWhere((s) => s.id == 'p1'),
      symbol: '0',
    ),
    FSATransition(
      id: 't4',
      fromState: states.firstWhere((s) => s.id == 'p1'),
      toState: states.firstWhere((s) => s.id == 'p1'),
      symbol: '1',
    ),
  };

  return FSA(
    id: 'dfa2',
    name: 'DFA2',
    states: states,
    transitions: transitions,
    alphabet: {'0', '1'},
    initialState: states.firstWhere((s) => s.id == 'p0'),
    acceptingStates: {states.firstWhere((s) => s.id == 'p1')},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 200, 100),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}

FSA _createNFA1() {
  final states = {
    State(
      id: 's0',
      label: 's0',
      position: Vector2(0, 0),
      isInitial: true,
      isAccepting: false,
    ),
    State(
      id: 's1',
      label: 's1',
      position: Vector2(100, 0),
      isInitial: false,
      isAccepting: true,
    ),
  };

  final transitions = {
    FSATransition(
      id: 't1',
      fromState: states.firstWhere((s) => s.id == 's0'),
      toState: states.firstWhere((s) => s.id == 's1'),
      symbol: '1',
    ),
    FSATransition(
      id: 't2',
      fromState: states.firstWhere((s) => s.id == 's0'),
      toState: states.firstWhere((s) => s.id == 's0'),
      symbol: '0',
    ),
    FSATransition(
      id: 't3',
      fromState: states.firstWhere((s) => s.id == 's1'),
      toState: states.firstWhere((s) => s.id == 's1'),
      symbol: '0',
    ),
    FSATransition(
      id: 't4',
      fromState: states.firstWhere((s) => s.id == 's1'),
      toState: states.firstWhere((s) => s.id == 's1'),
      symbol: '1',
    ),
  };

  return FSA(
    id: 'nfa1',
    name: 'NFA1',
    states: states,
    transitions: transitions,
    alphabet: {'0', '1'},
    initialState: states.firstWhere((s) => s.id == 's0'),
    acceptingStates: {states.firstWhere((s) => s.id == 's1')},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 200, 100),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}

FSA _createNFA2() {
  // NFA equivalent to NFA1 (accepts strings containing at least one '1')
  // Different structure but same language
  final states = {
    State(
      id: 't0',
      label: 't0',
      position: Vector2(0, 0),
      isInitial: true,
      isAccepting: false,
    ),
    State(
      id: 't1',
      label: 't1',
      position: Vector2(100, 0),
      isInitial: false,
      isAccepting: true,
    ),
  };

  final transitions = {
    FSATransition(
      id: 't1',
      fromState: states.firstWhere((s) => s.id == 't0'),
      toState: states.firstWhere((s) => s.id == 't1'),
      symbol: '1',
    ),
    FSATransition(
      id: 't2',
      fromState: states.firstWhere((s) => s.id == 't0'),
      toState: states.firstWhere((s) => s.id == 't0'),
      symbol: '0',
    ),
    FSATransition(
      id: 't3',
      fromState: states.firstWhere((s) => s.id == 't1'),
      toState: states.firstWhere((s) => s.id == 't1'),
      symbol: '0',
    ),
    FSATransition(
      id: 't4',
      fromState: states.firstWhere((s) => s.id == 't1'),
      toState: states.firstWhere((s) => s.id == 't1'),
      symbol: '1',
    ),
  };

  return FSA(
    id: 'nfa2',
    name: 'NFA2',
    states: states,
    transitions: transitions,
    alphabet: {'0', '1'},
    initialState: states.firstWhere((s) => s.id == 't0'),
    acceptingStates: {states.firstWhere((s) => s.id == 't1')},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 200, 100),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}

FSA _createNonEquivalentDFA() {
  final states = {
    State(
      id: 'r0',
      label: 'r0',
      position: Vector2(0, 0),
      isInitial: true,
      isAccepting: false,
    ),
    State(
      id: 'r1',
      label: 'r1',
      position: Vector2(100, 0),
      isInitial: false,
      isAccepting: true,
    ),
  };

  final transitions = {
    FSATransition(
      id: 't1',
      fromState: states.firstWhere((s) => s.id == 'r0'),
      toState: states.firstWhere((s) => s.id == 'r1'),
      symbol: '0',
    ),
    FSATransition(
      id: 't2',
      fromState: states.firstWhere((s) => s.id == 'r0'),
      toState: states.firstWhere((s) => s.id == 'r0'),
      symbol: '1',
    ),
    FSATransition(
      id: 't3',
      fromState: states.firstWhere((s) => s.id == 'r1'),
      toState: states.firstWhere((s) => s.id == 'r1'),
      symbol: '0',
    ),
    FSATransition(
      id: 't4',
      fromState: states.firstWhere((s) => s.id == 'r1'),
      toState: states.firstWhere((s) => s.id == 'r1'),
      symbol: '1',
    ),
  };

  return FSA(
    id: 'non_equivalent_dfa',
    name: 'Non-Equivalent DFA',
    states: states,
    transitions: transitions,
    alphabet: {'0', '1'},
    initialState: states.firstWhere((s) => s.id == 'r0'),
    acceptingStates: {states.firstWhere((s) => s.id == 'r1')},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 200, 100),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}

FSA _createEmptyDFA() {
  return FSA(
    id: 'empty_dfa',
    name: 'Empty DFA',
    states: {},
    transitions: {},
    alphabet: {},
    initialState: null,
    acceptingStates: {},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 0, 0),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}

FSA _createDFAWithAlphabet(Set<String> alphabet) {
  final states = {
    State(
      id: 'q0',
      label: 'q0',
      position: Vector2(0, 0),
      isInitial: true,
      isAccepting: false,
    ),
  };

  return FSA(
    id: 'dfa_with_alphabet',
    name: 'DFA with Alphabet',
    states: states,
    transitions: {},
    alphabet: alphabet,
    initialState: states.firstWhere((s) => s.id == 'q0'),
    acceptingStates: {},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 100, 100),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}

FSA _createNoInitialDFA() {
  final states = {
    State(
      id: 'q0',
      label: 'q0',
      position: Vector2(0, 0),
      isInitial: false,
      isAccepting: false,
    ),
  };

  return FSA(
    id: 'no_initial_dfa',
    name: 'No Initial DFA',
    states: states,
    transitions: {},
    alphabet: {'a'},
    initialState: null,
    acceptingStates: {},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 100, 100),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}
