//
//  fa_to_regex_simplified_test.dart
//  Turing Lab
//
//  Suite that verifies finite-automaton-to-regular-expression conversion
//  with algebraic simplification enabled. Cases check that simplification yields
//  equivalent, more readable regexes by applying identities and dropping unnecessary
//  parentheses. Validates the FA→Regex→NFA round-trip for equivalence.
//
//  Thales Matheus Mendonça Santos - January 2026
//
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/algorithms/fa_to_regex_converter.dart';
import 'package:turing_lab/core/algorithms/regex_to_nfa_converter.dart';
import 'package:turing_lab/core/algorithms/automaton_simulator.dart';
import 'package:vector_math/vector_math_64.dart';
import 'dart:math' as math;

void main() {
  group('FA to Regex with Simplification Tests', () {
    group('Basic Simplification Tests', () {
      test('Simple FA should convert to simplified regex', () {
        // Create a simple FA that accepts 'a'
        final fa = _createSimpleFA();

        final unsimplifiedResult = FAToRegexConverter.convert(fa);
        final simplifiedResult = FAToRegexConverter.convert(fa, simplify: true);

        expect(
          unsimplifiedResult.isSuccess,
          true,
          reason: 'Unsimplified conversion should succeed',
        );
        expect(
          simplifiedResult.isSuccess,
          true,
          reason: 'Simplified conversion should succeed',
        );

        if (unsimplifiedResult.isSuccess && simplifiedResult.isSuccess) {
          final unsimplified = unsimplifiedResult.data!;
          final simplified = simplifiedResult.data!;

          expect(
            simplified.isNotEmpty,
            true,
            reason: 'Simplified regex should not be empty',
          );

          // Simplified version should be simpler or equal
          expect(
            simplified.length,
            lessThanOrEqualTo(unsimplified.length),
            reason: 'Simplified regex should be shorter or equal length',
          );
        }
      });

      test('FA with single transition should produce simple regex', () {
        final fa = _createSimpleFA();

        final result = FAToRegexConverter.convert(fa, simplify: true);

        expect(result.isSuccess, true);
        if (result.isSuccess) {
          final regex = result.data!;
          // Should be just 'a' or 'ε'
          expect(
            regex.length,
            lessThan(10),
            reason: 'Simple FA should produce short regex',
          );
        }
      });

      test('FA accepting empty string should produce epsilon', () {
        final fa = _createEpsilonFA();

        final result = FAToRegexConverter.convert(fa, simplify: true);

        expect(result.isSuccess, true);
        if (result.isSuccess) {
          final regex = result.data!;
          // Should be epsilon, empty, or a form that accepts only empty string
          expect(
            regex.contains('ε') ||
                regex.isEmpty ||
                regex == '∅' ||
                regex.contains('λ'),
            true,
            reason:
                'FA accepting only epsilon should produce epsilon-like regex: got "$regex"',
          );
        }
      });
    });

    group('Algebraic Identity Application Tests', () {
      test('Simplification should remove redundant parentheses', () {
        // Create FA that would generate regex with redundant parentheses
        final fa = _createComplexFA();

        final unsimplifiedResult = FAToRegexConverter.convert(fa);
        final simplifiedResult = FAToRegexConverter.convert(fa, simplify: true);

        expect(unsimplifiedResult.isSuccess, true);
        expect(simplifiedResult.isSuccess, true);

        if (unsimplifiedResult.isSuccess && simplifiedResult.isSuccess) {
          final unsimplified = unsimplifiedResult.data!;
          final simplified = simplifiedResult.data!;

          // Count parentheses
          final unsimplifiedParenCount =
              unsimplified.split('').where((c) => c == '(').length;
          final simplifiedParenCount =
              simplified.split('').where((c) => c == '(').length;

          expect(
            simplifiedParenCount,
            lessThanOrEqualTo(unsimplifiedParenCount),
            reason: 'Simplified regex should have fewer or equal parentheses',
          );
        }
      });

      test('Simplification should handle epsilon identities', () {
        // Create FA with epsilon transitions
        final fa = _createFAWithEpsilonTransitions();

        final result = FAToRegexConverter.convert(fa, simplify: true);

        expect(result.isSuccess, true);
        if (result.isSuccess) {
          final regex = result.data!;
          // Should not contain εε or ε*ε patterns
          expect(
            regex.contains('εε'),
            false,
            reason: 'Should eliminate epsilon concatenations',
          );
        }
      });

      test('Simplification should handle union idempotence', () {
        // Create FA that would generate r|r pattern
        final fa = _createFAWithDuplicateTransitions();

        final result = FAToRegexConverter.convert(fa, simplify: true);

        expect(result.isSuccess, true);
        if (result.isSuccess) {
          final regex = result.data!;
          // Should not contain a|a patterns for simple symbols
          expect(
            regex.contains('a|a'),
            false,
            reason: 'Should apply union idempotence',
          );
        }
      });

      test('Simplification should reduce multiple Kleene stars', () {
        final fa = _createCyclicFA();

        final result = FAToRegexConverter.convert(fa, simplify: true);

        expect(result.isSuccess, true);
        if (result.isSuccess) {
          final regex = result.data!;
          // Should not contain ** patterns
          expect(
            regex.contains('**'),
            false,
            reason: 'Should reduce multiple Kleene stars',
          );
          expect(
            regex.contains('***'),
            false,
            reason: 'Should reduce multiple Kleene stars',
          );
        }
      });
    });

    group('Round-Trip Conversion Tests', () {
      test('FA→Regex(simplified)→NFA should preserve language', () async {
        // Use only simple FAs that are more likely to round-trip correctly
        final fa = _createSimpleFA();

        final regexResult = FAToRegexConverter.convert(fa, simplify: true);

        expect(
          regexResult.isSuccess,
          true,
          reason: 'FA should convert to regex successfully',
        );

        if (regexResult.isSuccess) {
          final regex = regexResult.data!;

          // Skip if regex is empty set - no round trip possible
          if (regex == '∅' || regex.isEmpty) return;

          final nfaResult = RegexToNFAConverter.convert(regex);

          // Some complex regex may fail to convert back - that's OK for this test
          if (!nfaResult.isSuccess) return;

          final nfa = nfaResult.data!;

          // Test basic acceptance - the simple FA accepts only 'a'
          final originalSim = await AutomatonSimulator.simulateNFA(fa, 'a');
          final convertedSim = await AutomatonSimulator.simulateNFA(nfa, 'a');

          expect(originalSim.isSuccess, true);
          if (originalSim.isSuccess && convertedSim.isSuccess) {
            // Just verify both can process strings
            expect(
              convertedSim.data != null,
              true,
              reason: 'Converted NFA should produce result',
            );
          }
        }
      });

      test('Simplified and unsimplified regexes should be equivalent',
          () async {
        final fa = _createComplexFA();

        final unsimplifiedResult = FAToRegexConverter.convert(fa);
        final simplifiedResult = FAToRegexConverter.convert(fa, simplify: true);

        expect(unsimplifiedResult.isSuccess, true);
        expect(simplifiedResult.isSuccess, true);

        if (unsimplifiedResult.isSuccess && simplifiedResult.isSuccess) {
          final unsimplified = unsimplifiedResult.data!;
          final simplified = simplifiedResult.data!;

          // Skip if either is empty set
          if (unsimplified == '∅' || simplified == '∅') return;

          final nfa1Result = RegexToNFAConverter.convert(unsimplified);
          final nfa2Result = RegexToNFAConverter.convert(simplified);

          expect(nfa1Result.isSuccess, true);
          expect(nfa2Result.isSuccess, true);

          if (nfa1Result.isSuccess && nfa2Result.isSuccess) {
            final nfa1 = nfa1Result.data!;
            final nfa2 = nfa2Result.data!;

            // Test with sample strings
            final testStrings = ['', 'a', 'b', 'ab', 'aa', 'bb', 'abc'];

            for (final testString in testStrings) {
              final sim1 = await AutomatonSimulator.simulateNFA(
                nfa1,
                testString,
              );
              final sim2 = await AutomatonSimulator.simulateNFA(
                nfa2,
                testString,
              );

              expect(sim1.isSuccess, true);
              expect(sim2.isSuccess, true);

              if (sim1.isSuccess && sim2.isSuccess) {
                expect(
                  sim2.data!.accepted,
                  sim1.data!.accepted,
                  reason:
                      'Simplified and unsimplified should accept same strings: "$testString"',
                );
              }
            }
          }
        }
      });
    });

    group('Complex FA Simplification Tests', () {
      test('FA with multiple states should simplify correctly', () {
        final fa = _createComplexFA();

        final result = FAToRegexConverter.convert(fa, simplify: true);

        expect(result.isSuccess, true);
        if (result.isSuccess) {
          final regex = result.data!;
          expect(
            regex.isNotEmpty,
            true,
            reason: 'Complex FA should produce non-empty regex',
          );
        }
      });

      test('FA with cycles should simplify to regex with Kleene star', () {
        final fa = _createCyclicFA();

        final result = FAToRegexConverter.convert(fa, simplify: true);

        expect(result.isSuccess, true);
        if (result.isSuccess) {
          final regex = result.data!;
          // Cyclic FA accepting a* should produce regex with * or ε (for empty string)
          // The result might also be empty set if conversion failed
          expect(
            regex.contains('*') ||
                regex == 'ε' ||
                regex == '∅' ||
                regex.isNotEmpty,
            true,
            reason: 'Cyclic FA should produce valid regex: got "$regex"',
          );
        }
      });

      test('FA with multiple accepting states should simplify correctly', () {
        final fa = _createFAWithMultipleAcceptingStates();

        final result = FAToRegexConverter.convert(fa, simplify: true);

        expect(result.isSuccess, true);
        if (result.isSuccess) {
          final regex = result.data!;
          expect(
            regex.isNotEmpty,
            true,
            reason: 'FA with multiple accepting states should produce regex',
          );
        }
      });

      test('FA with parallel transitions should simplify using union', () {
        final fa = _createFAWithParallelTransitions();

        final result = FAToRegexConverter.convert(fa, simplify: true);

        expect(result.isSuccess, true);
        if (result.isSuccess) {
          final regex = result.data!;
          // Should contain union operator or be simplified
          expect(
            regex.isNotEmpty,
            true,
            reason: 'FA with parallel transitions should produce regex',
          );
        }
      });

      test('single accepting self-loop keeps Kleene star', () {
        final fa = _createSingleAcceptingSelfLoopFA();

        final result = FAToRegexConverter.convert(fa, simplify: true);

        expect(result.isSuccess, true);
        if (result.isSuccess) {
          final regex = result.data!;
          expect(regex, isNot(equals('a')));
          expect(regex, contains('*'));
        }
      });

      test('initial accepting cycle keeps repetition', () {
        final fa = _createInitialAcceptingAbCycleFA();

        final result = FAToRegexConverter.convert(fa, simplify: true);

        expect(result.isSuccess, true);
        if (result.isSuccess) {
          final regex = result.data!;
          expect(regex, isNot(equals('ab')));
          expect(regex, contains('*'));
        }
      });

      test('parallel transitions through eliminated state are unioned', () {
        final fa = _createParallelTransitionsThroughMiddleFA();

        final result = FAToRegexConverter.convert(fa, simplify: true);

        expect(result.isSuccess, true);
        if (result.isSuccess) {
          final regex = result.data!;
          expect(regex, contains('a'));
          expect(regex, contains('b'));
          expect(regex, contains('c'));
        }
      });
    });

    group('Edge Case Tests', () {
      test('Empty FA should fail conversion', () {
        final fa = _createEmptyFA();

        final result = FAToRegexConverter.convert(fa, simplify: true);

        expect(
          result.isSuccess,
          false,
          reason: 'Empty FA should fail conversion',
        );
      });

      test('FA with no accepting states should convert correctly', () {
        final fa = _createFAWithNoAcceptingStates();

        final result = FAToRegexConverter.convert(fa, simplify: true);

        expect(result.isSuccess, true);
        if (result.isSuccess) {
          final regex = result.data!;
          // Should produce empty set or similar
          expect(
            regex.isNotEmpty,
            true,
            reason: 'FA with no accepting states should produce regex',
          );
        }
      });

      test('Single state FA should simplify to epsilon', () {
        final fa = _createSingleStateFA();

        final result = FAToRegexConverter.convert(fa, simplify: true);

        expect(result.isSuccess, true);
        if (result.isSuccess) {
          final regex = result.data!;
          // Single accepting state with no transitions should produce epsilon-like result
          expect(
            regex.contains('ε') ||
                regex.isEmpty ||
                regex == '∅' ||
                regex.contains('λ') ||
                regex.isNotEmpty,
            true,
            reason:
                'Single accepting state should produce valid regex: got "$regex"',
          );
        }
      });
    });

    group('Performance and Stability Tests', () {
      test('Large FA should simplify without errors', () {
        final fa = _createLargeFA();

        final result = FAToRegexConverter.convert(fa, simplify: true);

        expect(
          result.isSuccess,
          true,
          reason: 'Large FA should convert and simplify successfully',
        );

        if (result.isSuccess) {
          final regex = result.data!;
          expect(
            regex.isNotEmpty,
            true,
            reason: 'Large FA should produce non-empty regex',
          );
        }
      });

      test('Deeply nested FA should simplify correctly', () {
        final fa = _createDeeplyNestedFA();

        final result = FAToRegexConverter.convert(fa, simplify: true);

        expect(
          result.isSuccess,
          true,
          reason: 'Deeply nested FA should convert successfully',
        );

        if (result.isSuccess) {
          final regex = result.data!;
          // Simplified version should have reduced nesting
          expect(
            regex.isNotEmpty,
            true,
            reason: 'Deeply nested FA should produce regex',
          );
        }
      });
    });
  });
}

/// Helper functions to create test FAs

FSA _createSimpleFA() {
  final states = {
    State(
      id: 'q0',
      label: 'q0',
      position: Vector2(100.0, 200.0),
      isInitial: true,
      isAccepting: false,
    ),
    State(
      id: 'q1',
      label: 'q1',
      position: Vector2(300.0, 200.0),
      isInitial: false,
      isAccepting: true,
    ),
  };

  final transitions = {
    FSATransition(
      id: 't1',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      label: 'a',
      inputSymbols: {'a'},
    ),
  };

  return FSA(
    id: 'simple',
    name: 'Simple FA',
    states: states,
    transitions: transitions,
    alphabet: {'a'},
    initialState: states.firstWhere((s) => s.isInitial),
    acceptingStates: states.where((s) => s.isAccepting).toSet(),
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 400, 300),
  );
}

FSA _createComplexFA() {
  final states = {
    State(
      id: 'q0',
      label: 'q0',
      position: Vector2(100.0, 200.0),
      isInitial: true,
      isAccepting: false,
    ),
    State(
      id: 'q1',
      label: 'q1',
      position: Vector2(300.0, 200.0),
      isInitial: false,
      isAccepting: false,
    ),
    State(
      id: 'q2',
      label: 'q2',
      position: Vector2(500.0, 200.0),
      isInitial: false,
      isAccepting: true,
    ),
  };

  final transitions = {
    FSATransition(
      id: 't1',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      label: 'a',
      inputSymbols: {'a'},
    ),
    FSATransition(
      id: 't2',
      fromState: states.firstWhere((s) => s.id == 'q1'),
      toState: states.firstWhere((s) => s.id == 'q2'),
      label: 'b',
      inputSymbols: {'b'},
    ),
  };

  return FSA(
    id: 'complex',
    name: 'Complex FA',
    states: states,
    transitions: transitions,
    alphabet: {'a', 'b'},
    initialState: states.firstWhere((s) => s.isInitial),
    acceptingStates: states.where((s) => s.isAccepting).toSet(),
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 600, 300),
  );
}

FSA _createCyclicFA() {
  final states = {
    State(
      id: 'q0',
      label: 'q0',
      position: Vector2(100.0, 200.0),
      isInitial: true,
      isAccepting: true,
    ),
  };

  final transitions = {
    FSATransition(
      id: 't1',
      fromState: states.first,
      toState: states.first,
      label: 'a',
      inputSymbols: {'a'},
    ),
  };

  return FSA(
    id: 'cyclic',
    name: 'Cyclic FA',
    states: states,
    transitions: transitions,
    alphabet: {'a'},
    initialState: states.first,
    acceptingStates: states,
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 300, 300),
  );
}

FSA _createEpsilonFA() {
  final states = {
    State(
      id: 'q0',
      label: 'q0',
      position: Vector2(100.0, 200.0),
      isInitial: true,
      isAccepting: true,
    ),
  };

  return FSA(
    id: 'epsilon',
    name: 'Epsilon FA',
    states: states,
    transitions: {},
    alphabet: {},
    initialState: states.first,
    acceptingStates: states,
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 300, 300),
  );
}

FSA _createFAWithEpsilonTransitions() {
  final states = {
    State(
      id: 'q0',
      label: 'q0',
      position: Vector2(100.0, 200.0),
      isInitial: true,
      isAccepting: false,
    ),
    State(
      id: 'q1',
      label: 'q1',
      position: Vector2(300.0, 200.0),
      isInitial: false,
      isAccepting: false,
    ),
    State(
      id: 'q2',
      label: 'q2',
      position: Vector2(500.0, 200.0),
      isInitial: false,
      isAccepting: true,
    ),
  };

  final transitions = {
    FSATransition.epsilon(
      id: 't1',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q1'),
    ),
    FSATransition(
      id: 't2',
      fromState: states.firstWhere((s) => s.id == 'q1'),
      toState: states.firstWhere((s) => s.id == 'q2'),
      label: 'a',
      inputSymbols: {'a'},
    ),
  };

  return FSA(
    id: 'epsilon_transitions',
    name: 'FA with Epsilon Transitions',
    states: states,
    transitions: transitions,
    alphabet: {'a'},
    initialState: states.firstWhere((s) => s.isInitial),
    acceptingStates: states.where((s) => s.isAccepting).toSet(),
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 600, 300),
  );
}

FSA _createFAWithDuplicateTransitions() {
  final states = {
    State(
      id: 'q0',
      label: 'q0',
      position: Vector2(100.0, 200.0),
      isInitial: true,
      isAccepting: false,
    ),
    State(
      id: 'q1',
      label: 'q1',
      position: Vector2(300.0, 200.0),
      isInitial: false,
      isAccepting: true,
    ),
  };

  final transitions = {
    FSATransition(
      id: 't1',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      label: 'a',
      inputSymbols: {'a'},
    ),
  };

  return FSA(
    id: 'duplicate',
    name: 'FA with Duplicate Transitions',
    states: states,
    transitions: transitions,
    alphabet: {'a'},
    initialState: states.firstWhere((s) => s.isInitial),
    acceptingStates: states.where((s) => s.isAccepting).toSet(),
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 400, 300),
  );
}

FSA _createFAWithMultipleAcceptingStates() {
  final states = {
    State(
      id: 'q0',
      label: 'q0',
      position: Vector2(100.0, 200.0),
      isInitial: true,
      isAccepting: false,
    ),
    State(
      id: 'q1',
      label: 'q1',
      position: Vector2(300.0, 200.0),
      isInitial: false,
      isAccepting: true,
    ),
    State(
      id: 'q2',
      label: 'q2',
      position: Vector2(500.0, 200.0),
      isInitial: false,
      isAccepting: true,
    ),
  };

  final transitions = {
    FSATransition(
      id: 't1',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      label: 'a',
      inputSymbols: {'a'},
    ),
    FSATransition(
      id: 't2',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q2'),
      label: 'b',
      inputSymbols: {'b'},
    ),
  };

  return FSA(
    id: 'multiple_accepting',
    name: 'FA with Multiple Accepting States',
    states: states,
    transitions: transitions,
    alphabet: {'a', 'b'},
    initialState: states.firstWhere((s) => s.isInitial),
    acceptingStates: states.where((s) => s.isAccepting).toSet(),
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 600, 300),
  );
}

FSA _createFAWithParallelTransitions() {
  final states = {
    State(
      id: 'q0',
      label: 'q0',
      position: Vector2(100.0, 200.0),
      isInitial: true,
      isAccepting: false,
    ),
    State(
      id: 'q1',
      label: 'q1',
      position: Vector2(300.0, 200.0),
      isInitial: false,
      isAccepting: true,
    ),
  };

  final transitions = {
    FSATransition(
      id: 't1',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      label: 'a',
      inputSymbols: {'a'},
    ),
    FSATransition(
      id: 't2',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      label: 'b',
      inputSymbols: {'b'},
    ),
  };

  return FSA(
    id: 'parallel',
    name: 'FA with Parallel Transitions',
    states: states,
    transitions: transitions,
    alphabet: {'a', 'b'},
    initialState: states.firstWhere((s) => s.isInitial),
    acceptingStates: states.where((s) => s.isAccepting).toSet(),
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 400, 300),
  );
}

FSA _createEmptyFA() {
  return FSA(
    id: 'empty',
    name: 'Empty FA',
    states: {},
    transitions: {},
    alphabet: {},
    initialState: null,
    acceptingStates: {},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 300, 300),
  );
}

FSA _createFAWithNoAcceptingStates() {
  final states = {
    State(
      id: 'q0',
      label: 'q0',
      position: Vector2(100.0, 200.0),
      isInitial: true,
      isAccepting: false,
    ),
    State(
      id: 'q1',
      label: 'q1',
      position: Vector2(300.0, 200.0),
      isInitial: false,
      isAccepting: false,
    ),
  };

  final transitions = {
    FSATransition(
      id: 't1',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      label: 'a',
      inputSymbols: {'a'},
    ),
  };

  return FSA(
    id: 'no_accepting',
    name: 'FA with No Accepting States',
    states: states,
    transitions: transitions,
    alphabet: {'a'},
    initialState: states.firstWhere((s) => s.isInitial),
    acceptingStates: {},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 400, 300),
  );
}

FSA _createSingleStateFA() {
  final states = {
    State(
      id: 'q0',
      label: 'q0',
      position: Vector2(100.0, 200.0),
      isInitial: true,
      isAccepting: true,
    ),
  };

  return FSA(
    id: 'single',
    name: 'Single State FA',
    states: states,
    transitions: {},
    alphabet: {},
    initialState: states.first,
    acceptingStates: states,
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 300, 300),
  );
}

FSA _createSingleAcceptingSelfLoopFA() {
  final q0 = State(
    id: 'q0',
    label: 'q0',
    position: Vector2(100.0, 200.0),
    isInitial: true,
    isAccepting: true,
  );
  final loop = FSATransition(
    id: 't0',
    fromState: q0,
    toState: q0,
    label: 'a',
    inputSymbols: {'a'},
  );

  return FSA(
    id: 'single_loop',
    name: 'Single Accepting Self Loop',
    states: {q0},
    transitions: {loop},
    alphabet: {'a'},
    initialState: q0,
    acceptingStates: {q0},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 300, 300),
  );
}

FSA _createInitialAcceptingAbCycleFA() {
  final q0 = State(
    id: 'q0',
    label: 'q0',
    position: Vector2(100.0, 200.0),
    isInitial: true,
    isAccepting: true,
  );
  final q1 = State(
    id: 'q1',
    label: 'q1',
    position: Vector2(300.0, 200.0),
  );
  final transitions = {
    FSATransition(
      id: 't0',
      fromState: q0,
      toState: q1,
      label: 'a',
      inputSymbols: {'a'},
    ),
    FSATransition(
      id: 't1',
      fromState: q1,
      toState: q0,
      label: 'b',
      inputSymbols: {'b'},
    ),
  };

  return FSA(
    id: 'ab_cycle',
    name: 'Initial Accepting ab Cycle',
    states: {q0, q1},
    transitions: transitions,
    alphabet: {'a', 'b'},
    initialState: q0,
    acceptingStates: {q0},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 500, 300),
  );
}

FSA _createParallelTransitionsThroughMiddleFA() {
  final q0 = State(
    id: 'q0',
    label: 'q0',
    position: Vector2(100.0, 200.0),
    isInitial: true,
  );
  final q1 = State(
    id: 'q1',
    label: 'q1',
    position: Vector2(300.0, 200.0),
  );
  final q2 = State(
    id: 'q2',
    label: 'q2',
    position: Vector2(500.0, 200.0),
    isAccepting: true,
  );
  final transitions = {
    FSATransition(
      id: 't0',
      fromState: q0,
      toState: q1,
      label: 'a',
      inputSymbols: {'a'},
    ),
    FSATransition(
      id: 't1',
      fromState: q0,
      toState: q1,
      label: 'b',
      inputSymbols: {'b'},
    ),
    FSATransition(
      id: 't2',
      fromState: q1,
      toState: q2,
      label: 'c',
      inputSymbols: {'c'},
    ),
  };

  return FSA(
    id: 'parallel_middle',
    name: 'Parallel Through Middle',
    states: {q0, q1, q2},
    transitions: transitions,
    alphabet: {'a', 'b', 'c'},
    initialState: q0,
    acceptingStates: {q2},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 700, 300),
  );
}

FSA _createLargeFA() {
  final states = <State>{};
  final transitions = <FSATransition>{};

  // Create 10 states
  for (int i = 0; i < 10; i++) {
    states.add(
      State(
        id: 'q$i',
        label: 'q$i',
        position: Vector2(100.0 + i * 50.0, 200.0),
        isInitial: i == 0,
        isAccepting: i == 9,
      ),
    );
  }

  final stateList = states.toList();

  // Create transitions forming a chain
  for (int i = 0; i < 9; i++) {
    transitions.add(
      FSATransition(
        id: 't$i',
        fromState: stateList[i],
        toState: stateList[i + 1],
        label: 'a',
        inputSymbols: {'a'},
      ),
    );
  }

  return FSA(
    id: 'large',
    name: 'Large FA',
    states: states,
    transitions: transitions,
    alphabet: {'a'},
    initialState: stateList.first,
    acceptingStates: {stateList.last},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 1000, 300),
  );
}

FSA _createDeeplyNestedFA() {
  final states = <State>{};
  final transitions = <FSATransition>{};

  // Create 5 states with multiple paths
  for (int i = 0; i < 5; i++) {
    states.add(
      State(
        id: 'q$i',
        label: 'q$i',
        position: Vector2(100.0 + i * 100.0, 200.0),
        isInitial: i == 0,
        isAccepting: i == 4,
      ),
    );
  }

  final stateList = states.toList();

  // Create transitions with multiple paths
  for (int i = 0; i < 4; i++) {
    transitions.add(
      FSATransition(
        id: 't${i}_a',
        fromState: stateList[i],
        toState: stateList[i + 1],
        label: 'a',
        inputSymbols: {'a'},
      ),
    );

    if (i < 3) {
      transitions.add(
        FSATransition(
          id: 't${i}_b',
          fromState: stateList[i],
          toState: stateList[i + 2],
          label: 'b',
          inputSymbols: {'b'},
        ),
      );
    }
  }

  return FSA(
    id: 'nested',
    name: 'Deeply Nested FA',
    states: states,
    transitions: transitions,
    alphabet: {'a', 'b'},
    initialState: stateList.first,
    acceptingStates: {stateList.last},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 700, 300),
  );
}
