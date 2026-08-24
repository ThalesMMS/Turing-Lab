//
//  regex_validation_test.dart
//  Turing Lab
//
//  Suite that verifies conversions between regular expressions and finite automata, covering the round-trip formal-language pipeline.
//  Cases exercise advanced operators, simulate the generated automata, and confirm consistency with the reference implementation.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/algorithms/regex_to_nfa_converter.dart';
import 'package:turing_lab/core/algorithms/fa_to_regex_converter.dart';
import 'package:turing_lab/core/algorithms/automaton_simulator.dart';
import 'package:vector_math/vector_math_64.dart';
import 'dart:math' as math;

void main() {
  group('REGEX Validation Tests', () {
    group('Regex to NFA Conversion Tests', () {
      test('Simple regex should convert to NFA', () async {
        final testCases = [
          'a', // Single symbol
          'ab', // Concatenation
          'a|b', // Union
          'a*', // Kleene star
          'a+', // Kleene plus
          'a?', // Optional
        ];

        for (final regex in testCases) {
          final result = RegexToNFAConverter.convert(regex);

          expect(
            result.isSuccess,
            true,
            reason: 'Regex "$regex" should convert to NFA successfully',
          );

          if (result.isSuccess) {
            final nfa = result.data!;
            expect(
              nfa.states.isNotEmpty,
              true,
              reason: 'Converted NFA should have states',
            );
            expect(
              nfa.initialState,
              isNotNull,
              reason: 'Converted NFA should have initial state',
            );
            expect(
              nfa.acceptingStates.isNotEmpty,
              true,
              reason: 'Converted NFA should have accepting states',
            );
          }
        }
      });

      test('Complex regex should convert to NFA', () async {
        final testCases = [
          'a*b', // Kleene star followed by symbol
          '(a|b)*', // Union with Kleene star
          'a(b|c)*', // Symbol followed by union with Kleene star
          '(ab)*', // Concatenation with Kleene star
          'a+', // Kleene plus
          'a?', // Optional
          '(a|b)(c|d)', // Complex union and concatenation
        ];

        for (final regex in testCases) {
          final result = RegexToNFAConverter.convert(regex);

          expect(
            result.isSuccess,
            true,
            reason: 'Complex regex "$regex" should convert to NFA successfully',
          );

          if (result.isSuccess) {
            final nfa = result.data!;
            expect(
              nfa.states.length,
              greaterThan(2),
              reason: 'Complex NFA should have multiple states',
            );
          }
        }
      });

      test('Regex with parentheses should convert correctly', () async {
        final testCases = [
          '(a)', // Simple parentheses
          '(a|b)', // Union in parentheses
          '((a|b))', // Nested parentheses
          '(a|b)*', // Parentheses with Kleene star
          '((a|b)|(c|d))', // Complex nested union
        ];

        for (final regex in testCases) {
          final result = RegexToNFAConverter.convert(regex);

          expect(
            result.isSuccess,
            true,
            reason:
                'Regex with parentheses "$regex" should convert successfully',
          );
        }
      });

      test('Invalid regex should fail conversion', () async {
        final testCases = [
          '', // Empty regex
          'a|', // Incomplete union
          '|a', // Union without left operand
          'a**', // Double Kleene star
          'a++', // Double Kleene plus
          'a??', // Double optional
          '((a)', // Unbalanced parentheses
          'a)', // Unbalanced parentheses
          'a|b|', // Incomplete union chain
        ];

        for (final regex in testCases) {
          final result = RegexToNFAConverter.convert(regex);

          expect(
            result.isSuccess,
            false,
            reason: 'Invalid regex "$regex" should fail conversion',
          );
        }
      });
    });

    group('FA to Regex Conversion Tests', () {
      test('Simple FA should convert to regex', () async {
        // Create a simple FA that accepts 'a'
        final fa = _createSimpleFA();

        final result = FAToRegexConverter.convert(fa);

        expect(
          result.isSuccess,
          true,
          reason: 'Simple FA should convert to regex successfully',
        );

        if (result.isSuccess) {
          final regex = result.data!;
          expect(
            regex.isNotEmpty,
            true,
            reason: 'Converted regex should not be empty',
          );
        }
      });

      test('FA with multiple states should convert to regex', () async {
        // Create a more complex FA
        final fa = _createComplexFA();

        final result = FAToRegexConverter.convert(fa);

        expect(
          result.isSuccess,
          true,
          reason: 'Complex FA should convert to regex successfully',
        );

        if (result.isSuccess) {
          final regex = result.data!;
          expect(
            regex.isNotEmpty,
            true,
            reason: 'Converted regex should not be empty',
          );
        }
      });

      test('FA with cycles should convert to regex', () async {
        // Create FA with cycles
        final fa = _createCyclicFA();

        final result = FAToRegexConverter.convert(fa);

        expect(
          result.isSuccess,
          true,
          reason: 'FA with cycles should convert to regex successfully',
        );

        if (result.isSuccess) {
          final regex = result.data!;
          expect(
            regex.isNotEmpty,
            true,
            reason: 'Converted regex should not be empty',
          );
        }
      });

      test('Empty FA should fail conversion', () async {
        // Create empty FA
        final fa = _createEmptyFA();

        final result = FAToRegexConverter.convert(fa);

        expect(
          result.isSuccess,
          false,
          reason: 'Empty FA should fail conversion',
        );
      });
    });

    group('Regex Equivalence Tests', () {
      test('Equivalent regexes should produce equivalent NFAs', () async {
        final equivalentPairs = [
          ['a', 'a'], // Same regex
          ['a|b', 'b|a'], // Union commutativity
          ['(a|b)|c', 'a|(b|c)'], // Union associativity
          ['(ab)c', 'a(bc)'], // Concatenation associativity
          ['a*', 'a*'], // Same Kleene star
          ['a+', 'aa*'], // Kleene plus equivalence
          ['a?', 'a|ε'], // Optional equivalence
        ];

        for (final pair in equivalentPairs) {
          final regex1 = pair[0];
          final regex2 = pair[1];

          final result1 = RegexToNFAConverter.convert(regex1);
          final result2 = RegexToNFAConverter.convert(regex2);

          expect(
            result1.isSuccess,
            true,
            reason: 'First regex "$regex1" should convert successfully',
          );
          expect(
            result2.isSuccess,
            true,
            reason: 'Second regex "$regex2" should convert successfully',
          );

          if (result1.isSuccess && result2.isSuccess) {
            final nfa1 = result1.data!;
            final nfa2 = result2.data!;

            // Test with sample strings
            final testStrings = ['', 'a', 'b', 'ab', 'aa', 'bb', 'abab'];

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
                  sim1.data!.accepted,
                  sim2.data!.accepted,
                  reason: 'NFAs should accept same strings for "$testString"',
                );
              }
            }
          }
        }
      });

      test('Non-equivalent regexes should produce different NFAs', () async {
        final nonEquivalentPairs = [
          ['a', 'b'], // Different symbols
          ['a*', 'a+'], // Kleene star vs plus
          ['a|b', 'ab'], // Union vs concatenation
          ['a*', 'a'], // Kleene star vs single
          ['(a|b)*', 'a*|b*'], // Different grouping
        ];

        for (final pair in nonEquivalentPairs) {
          final regex1 = pair[0];
          final regex2 = pair[1];

          final result1 = RegexToNFAConverter.convert(regex1);
          final result2 = RegexToNFAConverter.convert(regex2);

          expect(
            result1.isSuccess,
            true,
            reason: 'First regex "$regex1" should convert successfully',
          );
          expect(
            result2.isSuccess,
            true,
            reason: 'Second regex "$regex2" should convert successfully',
          );

          if (result1.isSuccess && result2.isSuccess) {
            final nfa1 = result1.data!;
            final nfa2 = result2.data!;

            // Test with sample strings - should find at least one difference
            final testStrings = ['', 'a', 'b', 'ab', 'aa', 'bb', 'abab'];
            bool foundDifference = false;

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
                if (sim1.data!.accepted != sim2.data!.accepted) {
                  foundDifference = true;
                  break;
                }
              }
            }

            expect(
              foundDifference,
              true,
              reason:
                  'Non-equivalent regexes should produce different behavior',
            );
          }
        }
      });
    });

    group('Regex Validation Tests', () {
      test('Valid regex patterns should be accepted', () async {
        final validPatterns = [
          'a', // Single symbol
          'ab', // Concatenation
          'a|b', // Union
          'a*', // Kleene star
          'a+', // Kleene plus
          'a?', // Optional
          '(a)', // Parentheses
          '(a|b)', // Union in parentheses
          '((a|b))', // Nested parentheses
          'a(b|c)', // Mixed operations
          'a*b+', // Multiple operators
          '(a|b)*', // Union with Kleene star
        ];

        for (final pattern in validPatterns) {
          final result = RegexToNFAConverter.convert(pattern);

          expect(
            result.isSuccess,
            true,
            reason: 'Valid pattern "$pattern" should be accepted',
          );
        }
      });

      test('Invalid regex patterns should be rejected', () async {
        final invalidPatterns = [
          '', // Empty
          '|', // Union without operands
          'a|', // Incomplete union
          '|a', // Union without left operand
          'a**', // Double Kleene star
          'a++', // Double Kleene plus
          'a??', // Double optional
          '((a)', // Unbalanced parentheses
          'a)', // Unbalanced parentheses
          'a|b|', // Incomplete union chain
          'a|b|c|', // Incomplete union chain
        ];

        for (final pattern in invalidPatterns) {
          final result = RegexToNFAConverter.convert(pattern);

          expect(
            result.isSuccess,
            false,
            reason: 'Invalid pattern "$pattern" should be rejected',
          );
        }
      });
    });

    group('Complex Regex Operations Tests', () {
      test('Union operations should work correctly', () async {
        final testCases = [
          'a|b', // Simple union
          'a|b|c', // Multiple union
          '(a|b)|c', // Grouped union
          'a|(b|c)', // Grouped union
          '(a|b)|(c|d)', // Complex union
        ];

        for (final regex in testCases) {
          final result = RegexToNFAConverter.convert(regex);

          expect(
            result.isSuccess,
            true,
            reason: 'Union regex "$regex" should convert successfully',
          );

          if (result.isSuccess) {
            final nfa = result.data!;

            // Test that NFA accepts at least one of the union operands
            final testStrings = ['a', 'b', 'c', 'd'];
            bool acceptsAtLeastOne = false;

            for (final testString in testStrings) {
              final sim = await AutomatonSimulator.simulateNFA(nfa, testString);
              if (sim.isSuccess && sim.data!.accepted) {
                acceptsAtLeastOne = true;
                break;
              }
            }

            expect(
              acceptsAtLeastOne,
              true,
              reason: 'Union NFA should accept at least one operand',
            );
          }
        }
      });

      test('Concatenation operations should work correctly', () async {
        final testCases = [
          'ab', // Simple concatenation
          'abc', // Multiple concatenation
          'a(bc)', // Concatenation with grouping
          '(ab)c', // Grouped concatenation
          'a*b', // Kleene star with concatenation
          'a+b', // Kleene plus with concatenation
        ];

        for (final regex in testCases) {
          final result = RegexToNFAConverter.convert(regex);

          expect(
            result.isSuccess,
            true,
            reason: 'Concatenation regex "$regex" should convert successfully',
          );

          if (result.isSuccess) {
            final nfa = result.data!;

            // Test that NFA has proper concatenation behavior
            expect(
              nfa.states.length,
              greaterThan(1),
              reason: 'Concatenation NFA should have multiple states',
            );
          }
        }
      });

      test('Kleene star operations should work correctly', () async {
        final testCases = [
          'a*', // Simple Kleene star
          '(a|b)*', // Union with Kleene star
          'a*b*', // Multiple Kleene stars
          '(ab)*', // Concatenation with Kleene star
          'a*|b*', // Union of Kleene stars
        ];

        for (final regex in testCases) {
          final result = RegexToNFAConverter.convert(regex);

          expect(
            result.isSuccess,
            true,
            reason: 'Kleene star regex "$regex" should convert successfully',
          );

          if (result.isSuccess) {
            final nfa = result.data!;

            // Test that NFA accepts empty string (Kleene star property)
            final emptySim = await AutomatonSimulator.simulateNFA(nfa, '');
            expect(emptySim.isSuccess, true);
            if (emptySim.isSuccess) {
              expect(
                emptySim.data!.accepted,
                true,
                reason: 'Kleene star NFA should accept empty string',
              );
            }
          }
        }
      });
    });

    group('Performance Tests', () {
      test('Complex regex should convert efficiently', () async {
        const complexRegex =
            '(a|b|c|d|e|f|g|h|i|j|k|l|m|n|o|p|q|r|s|t|u|v|w|x|y|z)*';

        final result = RegexToNFAConverter.convert(complexRegex);

        expect(
          result.isSuccess,
          true,
          reason: 'Complex regex should convert successfully',
        );

        if (result.isSuccess) {
          final nfa = result.data!;
          expect(
            nfa.states.length,
            greaterThan(10),
            reason: 'Complex NFA should have many states',
          );
        }
      });

      test('Deeply nested regex should convert', () async {
        const nestedRegex = '((((a))))';

        final result = RegexToNFAConverter.convert(nestedRegex);

        expect(
          result.isSuccess,
          true,
          reason: 'Deeply nested regex should convert successfully',
        );
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
