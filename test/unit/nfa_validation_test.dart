//
//  nfa_validation_test.dart
//  Turing Lab
//
//  Casos de teste que avaliam o simulador de AFNs e a conversão para DFAs garantindo alinhamento com os exemplos clássicos usados como referência.
//  Os experimentos exploram caminhos não determinísticos, fechos epsilon, símbolos fora do alfabeto e verificações de aceitação versus rejeição.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/algorithms/automaton_simulator.dart';
import 'package:turing_lab/core/algorithms/nfa_to_dfa_converter.dart';
import 'package:vector_math/vector_math_64.dart';
import 'dart:math' as math;

void main() {
  group('NFA Validation Tests', () {
    late FSA lambdaAOrABNFA;
    late FSA nondeterministicNFA;
    late FSA epsilonClosureNFA;
    late FSA alphabetEdgeNFA;
    late FSA complexNFA;

    setUp(() {
      // Test Case 1: Lambda A or AB (from assets/examples)
      lambdaAOrABNFA = _createLambdaAOrABNFA();

      // Test Case 2: Nondeterministic NFA (from Python reference)
      nondeterministicNFA = _createNondeterministicNFA();

      // Test Case 3: Epsilon closure NFA
      epsilonClosureNFA = _createEpsilonClosureNFA();

      // Test Case 4: Alphabet edge cases
      alphabetEdgeNFA = _createAlphabetEdgeNFA();

      // Test Case 5: Complex NFA with multiple paths
      complexNFA = _createComplexNFA();
    });

    group('Nondeterminism Tests', () {
      test('NFA should handle multiple transitions from same state', () async {
        // Test nondeterministic NFA that can take multiple paths
        final testCases = [
          'a', // Should be accepted via path 1
          'ab', // Should be accepted via path 2
          'aa', // Should be accepted via path 1
        ];

        for (final testString in testCases) {
          final result = await AutomatonSimulator.simulateNFA(
            nondeterministicNFA,
            testString,
          );

          expect(
            result.isSuccess,
            true,
            reason: 'Simulation should succeed for "$testString"',
          );

          if (result.isSuccess) {
            expect(
              result.data!.accepted,
              true,
              reason:
                  'String "$testString" should be accepted by nondeterministic NFA',
            );
          }
        }
      });

      test('NFA should explore all possible paths', () async {
        // Test that NFA explores multiple paths and accepts if any path leads to acceptance
        final result = await AutomatonSimulator.simulateNFA(
          nondeterministicNFA,
          'ab',
        );

        expect(result.isSuccess, true);
        if (result.isSuccess) {
          expect(
            result.data!.accepted,
            true,
            reason:
                'NFA should accept "ab" through nondeterministic exploration',
          );
        }
      });
    });

    group('Epsilon Transition Tests', () {
      test('Lambda A or AB - should accept valid strings', () async {
        final testCases = [
          'a', // Direct path via epsilon transition
          'ab', // Path through epsilon transition
        ];

        for (final testString in testCases) {
          final result = await AutomatonSimulator.simulateNFA(
            lambdaAOrABNFA,
            testString,
          );

          expect(
            result.isSuccess,
            true,
            reason: 'Simulation should succeed for "$testString"',
          );

          if (result.isSuccess) {
            expect(
              result.data!.accepted,
              true,
              reason: 'String "$testString" should be accepted by lambda NFA',
            );
          }
        }
      });

      test('Lambda A or AB - should reject invalid strings', () async {
        final testCases = [
          '', // Empty string
          'b', // Invalid symbol
          'ba', // Wrong order
          'aab', // Too many a's
        ];

        for (final testString in testCases) {
          final result = await AutomatonSimulator.simulateNFA(
            lambdaAOrABNFA,
            testString,
          );

          expect(
            result.isSuccess,
            true,
            reason: 'Simulation should succeed for "$testString"',
          );

          if (result.isSuccess) {
            expect(
              result.data!.accepted,
              false,
              reason: 'String "$testString" should be rejected by lambda NFA',
            );
          }
        }
      });

      test('Epsilon closure should work correctly', () async {
        // Test NFA with epsilon closure
        final testCases = [
          '', // Should be accepted via epsilon closure
          'a', // Should be accepted
          'aa', // Should be accepted
        ];

        for (final testString in testCases) {
          final result = await AutomatonSimulator.simulateNFA(
            epsilonClosureNFA,
            testString,
          );

          expect(
            result.isSuccess,
            true,
            reason: 'Simulation should succeed for "$testString"',
          );

          if (result.isSuccess) {
            expect(
              result.data!.accepted,
              true,
              reason:
                  'String "$testString" should be accepted by epsilon closure NFA',
            );
          }
        }
      });
    });

    group('Acceptance Tests', () {
      test('Complex NFA should accept valid strings', () async {
        final testCases = ['a', 'b', 'ab', 'ba', 'aab', 'bba', 'abab'];

        for (final testString in testCases) {
          final result = await AutomatonSimulator.simulateNFA(
            complexNFA,
            testString,
          );

          expect(
            result.isSuccess,
            true,
            reason: 'Simulation should succeed for "$testString"',
          );

          if (result.isSuccess) {
            expect(
              result.data!.accepted,
              true,
              reason: 'String "$testString" should be accepted by complex NFA',
            );
          }
        }
      });

      test('NFA should handle empty string correctly', () async {
        // Test empty string acceptance
        final result = await AutomatonSimulator.simulateNFA(
          epsilonClosureNFA,
          '',
        );

        expect(result.isSuccess, true);
        if (result.isSuccess) {
          expect(
            result.data!.accepted,
            true,
            reason: 'Empty string should be accepted by epsilon closure NFA',
          );
        }
      });
    });

    group('Rejection Tests', () {
      test('NFA should reject invalid strings', () async {
        final testCases = [
          'c', // Symbol not in alphabet
          'abc', // Invalid sequence
          'aaa', // Too many a's
          'bbb', // Too many b's
        ];

        for (final testString in testCases) {
          final result = await AutomatonSimulator.simulateNFA(
            complexNFA,
            testString,
          );

          expect(
            result.isSuccess,
            true,
            reason: 'Simulation should succeed for "$testString"',
          );

          if (result.isSuccess) {
            expect(
              result.data!.accepted,
              false,
              reason: 'String "$testString" should be rejected by complex NFA',
            );
          }
        }
      });

      test('Lambda NFA should reject invalid strings', () async {
        final testCases = [
          'b', // Invalid symbol
          'ba', // Wrong order
          'aab', // Too many a's
          'c', // Symbol not in alphabet
        ];

        for (final testString in testCases) {
          final result = await AutomatonSimulator.simulateNFA(
            lambdaAOrABNFA,
            testString,
          );

          expect(
            result.isSuccess,
            true,
            reason: 'Simulation should succeed for "$testString"',
          );

          if (result.isSuccess) {
            expect(
              result.data!.accepted,
              false,
              reason: 'String "$testString" should be rejected by lambda NFA',
            );
          }
        }
      });
    });

    group('Alphabet Edge Cases', () {
      test('NFA should handle symbols not in alphabet', () async {
        final testCases = [
          'c', // Symbol not in alphabet
          'd', // Another symbol not in alphabet
          'ac', // Mix of valid and invalid symbols
          'cb', // Mix of invalid and valid symbols
        ];

        for (final testString in testCases) {
          final result = await AutomatonSimulator.simulateNFA(
            alphabetEdgeNFA,
            testString,
          );

          expect(
            result.isSuccess,
            true,
            reason: 'Simulation should succeed for "$testString"',
          );

          if (result.isSuccess) {
            expect(
              result.data!.accepted,
              false,
              reason:
                  'String "$testString" should be rejected (contains symbols not in alphabet)',
            );
          }
        }
      });

      test('NFA should handle empty alphabet gracefully', () async {
        // Test with NFA that has minimal alphabet
        final result = await AutomatonSimulator.simulateNFA(
          alphabetEdgeNFA,
          '',
        );

        expect(result.isSuccess, true);
        if (result.isSuccess) {
          expect(
            result.data!.accepted,
            true,
            reason: 'Empty string should be accepted by alphabet edge NFA',
          );
        }
      });
    });

    group('NFA to DFA Conversion Tests', () {
      test('NFA to DFA conversion should preserve language', () async {
        // Convert NFA to DFA and test that they accept the same language
        final conversionResult = NFAToDFAConverter.convert(nondeterministicNFA);

        expect(
          conversionResult.isSuccess,
          true,
          reason: 'NFA to DFA conversion should succeed',
        );

        if (conversionResult.isSuccess) {
          final dfa = conversionResult.data!;

          // Test same strings on both NFA and DFA
          final testStrings = ['', 'a', 'b', 'ab', 'ba', 'aa', 'bb'];

          for (final testString in testStrings) {
            final nfaResult = await AutomatonSimulator.simulateNFA(
              nondeterministicNFA,
              testString,
            );

            final dfaResult = await AutomatonSimulator.simulate(
              dfa,
              testString,
            );

            expect(nfaResult.isSuccess, true);
            expect(dfaResult.isSuccess, true);

            if (nfaResult.isSuccess && dfaResult.isSuccess) {
              expect(
                nfaResult.data!.accepted,
                dfaResult.data!.accepted,
                reason:
                    'NFA and converted DFA should accept same strings for "$testString"',
              );
            }
          }
        }
      });

      test('Lambda NFA to DFA conversion should work', () async {
        final conversionResult = NFAToDFAConverter.convert(lambdaAOrABNFA);

        expect(
          conversionResult.isSuccess,
          true,
          reason: 'Lambda NFA to DFA conversion should succeed',
        );

        if (conversionResult.isSuccess) {
          final dfa = conversionResult.data!;

          // Test that converted DFA accepts same language
          final testStrings = ['a', 'ab'];

          for (final testString in testStrings) {
            final nfaResult = await AutomatonSimulator.simulateNFA(
              lambdaAOrABNFA,
              testString,
            );

            final dfaResult = await AutomatonSimulator.simulate(
              dfa,
              testString,
            );

            expect(nfaResult.isSuccess, true);
            expect(dfaResult.isSuccess, true);

            if (nfaResult.isSuccess && dfaResult.isSuccess) {
              expect(
                nfaResult.data!.accepted,
                dfaResult.data!.accepted,
                reason:
                    'Lambda NFA and converted DFA should accept same strings for "$testString"',
              );
            }
          }
        }
      });
    });

    group('Performance Tests', () {
      test('NFA should handle long strings efficiently', () async {
        // Test with very long strings to ensure performance
        final longString = 'ab' * 1000; // 2000 characters

        final result = await AutomatonSimulator.simulateNFA(
          complexNFA,
          longString,
        );

        expect(
          result.isSuccess,
          true,
          reason: 'Should handle long strings without issues',
        );

        if (result.isSuccess) {
          expect(
            result.data!.accepted,
            true,
            reason: 'Long string should be accepted by complex NFA',
          );
        }
      });

      test('NFA should handle complex epsilon closures', () async {
        // Test with complex epsilon closure scenarios
        final result = await AutomatonSimulator.simulateNFA(
          epsilonClosureNFA,
          'a' * 100, // 100 a's
        );

        expect(
          result.isSuccess,
          true,
          reason: 'Should handle complex epsilon closures',
        );

        if (result.isSuccess) {
          expect(
            result.data!.accepted,
            true,
            reason: 'Complex epsilon closure should be accepted',
          );
        }
      });
    });
  });
}

/// Helper functions to create test NFAs

FSA _createLambdaAOrABNFA() {
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
      position: Vector2(320.0, 120.0),
      isInitial: false,
      isAccepting: true,
    ),
    State(
      id: 'q2',
      label: 'q2',
      position: Vector2(320.0, 280.0),
      isInitial: false,
      isAccepting: false,
    ),
    State(
      id: 'q3',
      label: 'q3',
      position: Vector2(520.0, 280.0),
      isInitial: false,
      isAccepting: false,
    ),
    State(
      id: 'q4',
      label: 'q4',
      position: Vector2(520.0, 120.0),
      isInitial: false,
      isAccepting: true,
    ),
  };

  final transitions = {
    // Epsilon transitions from q0 to q2 (standardized epsilon)
    FSATransition.epsilon(
      id: 't2',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q2'),
    ),
    // Transition from q2 to q3 on 'a'
    FSATransition(
      id: 't3',
      fromState: states.firstWhere((s) => s.id == 'q2'),
      toState: states.firstWhere((s) => s.id == 'q3'),
      label: 'a',
      inputSymbols: {'a'},
    ),
    // Transition from q3 to q4 on 'b'
    FSATransition(
      id: 't4',
      fromState: states.firstWhere((s) => s.id == 'q3'),
      toState: states.firstWhere((s) => s.id == 'q4'),
      label: 'b',
      inputSymbols: {'b'},
    ),
    // Add epsilon from q3 to accepting q4 so single 'a' can accept via ε after 'a'
    FSATransition.epsilon(
      id: 't5',
      fromState: states.firstWhere((s) => s.id == 'q3'),
      toState: states.firstWhere((s) => s.id == 'q4'),
    ),
  };

  return FSA(
    id: 'lambda_a_or_ab',
    name: 'Lambda A or AB',
    states: states,
    transitions: transitions,
    alphabet: {'a', 'b'},
    initialState: states.firstWhere((s) => s.isInitial),
    acceptingStates: states.where((s) => s.isAccepting).toSet(),
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 600, 400),
  );
}

FSA _createNondeterministicNFA() {
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
      position: Vector2(300.0, 120.0),
      isInitial: false,
      isAccepting: true,
    ),
    State(
      id: 'q2',
      label: 'q2',
      position: Vector2(300.0, 280.0),
      isInitial: false,
      isAccepting: true,
    ),
    State(
      id: 'q3',
      label: 'q3',
      position: Vector2(500.0, 200.0),
      isInitial: false,
      isAccepting: false,
    ),
  };

  final transitions = {
    // Nondeterministic transitions from q0 on 'a'
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
      label: 'a',
      inputSymbols: {'a'},
    ),
    // Transitions from q1 and q2
    FSATransition(
      id: 't3',
      fromState: states.firstWhere((s) => s.id == 'q1'),
      toState: states.firstWhere((s) => s.id == 'q2'),
      label: 'b',
      inputSymbols: {'b'},
    ),
    FSATransition(
      id: 't1a',
      fromState: states.firstWhere((s) => s.id == 'q1'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      label: 'a',
      inputSymbols: {'a'},
    ),
  };

  return FSA(
    id: 'nondeterministic',
    name: 'Nondeterministic NFA',
    states: states,
    transitions: transitions,
    alphabet: {'a', 'b'},
    initialState: states.firstWhere((s) => s.isInitial),
    acceptingStates: states.where((s) => s.isAccepting).toSet(),
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 600, 400),
  );
}

FSA _createEpsilonClosureNFA() {
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
    // Epsilon transition from q0 to q1
    FSATransition.epsilon(
      id: 't1',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q1'),
    ),
    // Transition from q1 to q2 on 'a'
    FSATransition(
      id: 't2',
      fromState: states.firstWhere((s) => s.id == 'q1'),
      toState: states.firstWhere((s) => s.id == 'q2'),
      label: 'a',
      inputSymbols: {'a'},
    ),
    // Epsilon transition from q2 to q1 (creates epsilon closure)
    FSATransition.epsilon(
      id: 't3',
      fromState: states.firstWhere((s) => s.id == 'q2'),
      toState: states.firstWhere((s) => s.id == 'q1'),
    ),
  };

  return FSA(
    id: 'epsilon_closure',
    name: 'Epsilon Closure NFA',
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

FSA _createAlphabetEdgeNFA() {
  final states = {
    State(
      id: 'q0',
      label: 'q0',
      position: Vector2(100.0, 200.0),
      isInitial: true,
      isAccepting: true,
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
    // Only transition on 'a' and 'b'
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
    id: 'alphabet_edge',
    name: 'Alphabet Edge NFA',
    states: states,
    transitions: transitions,
    alphabet: {'a', 'b'}, // Only a and b, no c, d, etc.
    initialState: states.firstWhere((s) => s.isInitial),
    acceptingStates: states.where((s) => s.isAccepting).toSet(),
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 400, 300),
  );
}

FSA _createComplexNFA() {
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
      position: Vector2(300.0, 120.0),
      isInitial: false,
      isAccepting: true,
    ),
    State(
      id: 'q2',
      label: 'q2',
      position: Vector2(300.0, 280.0),
      isInitial: false,
      isAccepting: true,
    ),
    State(
      id: 'q3',
      label: 'q3',
      position: Vector2(500.0, 200.0),
      isInitial: false,
      isAccepting: true,
    ),
    // Non-accepting intermediates to allow double letters before switching
    State(
      id: 'qdA',
      label: 'qdA',
      position: Vector2(420.0, 80.0),
      isInitial: false,
      isAccepting: false,
    ),
    State(
      id: 'qdB',
      label: 'qdB',
      position: Vector2(420.0, 320.0),
      isInitial: false,
      isAccepting: false,
    ),
  };

  final transitions = {
    // From start
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
    // Switch to combined accepting
    FSATransition(
      id: 't3',
      fromState: states.firstWhere((s) => s.id == 'q1'),
      toState: states.firstWhere((s) => s.id == 'q3'),
      label: 'b',
      inputSymbols: {'b'},
    ),
    FSATransition(
      id: 't4',
      fromState: states.firstWhere((s) => s.id == 'q2'),
      toState: states.firstWhere((s) => s.id == 'q3'),
      label: 'a',
      inputSymbols: {'a'},
    ),
    // Alternate while accepting
    FSATransition(
      id: 't5_alt',
      fromState: states.firstWhere((s) => s.id == 'q3'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      label: 'a',
      inputSymbols: {'a'},
    ),
    FSATransition(
      id: 't6_alt',
      fromState: states.firstWhere((s) => s.id == 'q3'),
      toState: states.firstWhere((s) => s.id == 'q2'),
      label: 'b',
      inputSymbols: {'b'},
    ),
    // Allow exactly two same letters before switching
    FSATransition(
      id: 't7',
      fromState: states.firstWhere((s) => s.id == 'q1'),
      toState: states.firstWhere((s) => s.id == 'qdA'),
      label: 'a',
      inputSymbols: {'a'},
    ),
    FSATransition(
      id: 't8',
      fromState: states.firstWhere((s) => s.id == 'qdA'),
      toState: states.firstWhere((s) => s.id == 'q3'),
      label: 'b',
      inputSymbols: {'b'},
    ),
    FSATransition(
      id: 't9',
      fromState: states.firstWhere((s) => s.id == 'q2'),
      toState: states.firstWhere((s) => s.id == 'qdB'),
      label: 'b',
      inputSymbols: {'b'},
    ),
    FSATransition(
      id: 't10',
      fromState: states.firstWhere((s) => s.id == 'qdB'),
      toState: states.firstWhere((s) => s.id == 'q3'),
      label: 'a',
      inputSymbols: {'a'},
    ),
  };

  return FSA(
    id: 'complex',
    name: 'Complex NFA',
    states: states,
    transitions: transitions,
    alphabet: {'a', 'b'},
    initialState: states.firstWhere((s) => s.isInitial),
    acceptingStates: states.where((s) => s.isAccepting).toSet(),
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 600, 400),
  );
}
