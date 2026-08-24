//
//  dfa_validation_test.dart
//  Turing Lab
//
//  Suite that compares Turing Lab's DFA simulator and minimizer with reference automata to confirm acceptance, rejection, and language stability.
//  Includes checks for the empty string, cycles, and equivalence between the original machine and its minimized form.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/algorithms/automaton_simulator.dart';
import 'package:turing_lab/core/algorithms/dfa_minimizer.dart';
import 'package:vector_math/vector_math_64.dart';
import 'dart:math' as math;

void main() {
  group('DFA Validation Tests', () {
    late FSA binaryDivisibleBy3DFA;
    late FSA endsWithADFA;
    late FSA noConsecutive11DFA;
    late FSA atLeastFourOnesDFA;

    setUp(() {
      // Test Case 1: Binary divisible by 3 (from assets/examples)
      binaryDivisibleBy3DFA = _createBinaryDivisibleBy3DFA();

      // Test Case 2: Ends with 'a' (from assets/examples)
      endsWithADFA = _createEndsWithADFA();

      // Test Case 4: No consecutive 11s (from Python reference)
      noConsecutive11DFA = _createNoConsecutive11DFA();

      // Test Case 5: At least four ones (from Python reference)
      atLeastFourOnesDFA = _createAtLeastFourOnesDFA();
    });

    group('Acceptance Tests', () {
      test(
        'Binary divisible by 3 - should accept valid binary numbers',
        () async {
          // Test cases: binary numbers divisible by 3
          final testCases = [
            '0', // 0 in decimal
            '11', // 3 in decimal
            '110', // 6 in decimal
            '1001', // 9 in decimal
            '1100', // 12 in decimal
            '1111', // 15 in decimal
          ];

          for (final testString in testCases) {
            final result = await AutomatonSimulator.simulate(
              binaryDivisibleBy3DFA,
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
                    'Binary "$testString" should be accepted (divisible by 3)',
              );
            }
          }
        },
      );

      test('Ends with A - should accept strings ending with a', () async {
        final testCases = ['a', 'ba', 'aba', 'bbba', 'aabba'];

        for (final testString in testCases) {
          final result = await AutomatonSimulator.simulate(
            endsWithADFA,
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
              reason: 'String "$testString" should be accepted (ends with a)',
            );
          }
        }
      });

      test('No consecutive 11s - should accept valid strings', () async {
        final testCases = [
          '',
          '0',
          '1',
          '01',
          '10',
          '001',
          '010',
          '100',
          '101',
          '0001',
          '0010',
          '0100',
          '0101',
          '1000',
          '1001',
          '1010',
        ];

        for (final testString in testCases) {
          final result = await AutomatonSimulator.simulate(
            noConsecutive11DFA,
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
                  'String "$testString" should be accepted (no consecutive 11s)',
            );
          }
        }
      });

      test('At least four ones - should accept strings with 4+ ones', () async {
        final testCases = [
          '1111',
          '11110',
          '01111',
          '11111',
          '1010101',
          '11110000',
        ];

        for (final testString in testCases) {
          final result = await AutomatonSimulator.simulate(
            atLeastFourOnesDFA,
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
              reason: 'String "$testString" should be accepted (4+ ones)',
            );
          }
        }
      });
    });

    group('Rejection Tests', () {
      test(
        'Binary divisible by 3 - should reject invalid binary numbers',
        () async {
          // Test cases: binary numbers NOT divisible by 3
          final testCases = [
            '1', // 1 in decimal
            '10', // 2 in decimal
            '100', // 4 in decimal
            '101', // 5 in decimal
            '1101', // 13 in decimal
            '1110', // 14 in decimal
          ];

          for (final testString in testCases) {
            final result = await AutomatonSimulator.simulate(
              binaryDivisibleBy3DFA,
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
                    'Binary "$testString" should be rejected (not divisible by 3)',
              );
            }
          }
        },
      );

      test('Ends with A - should reject strings not ending with a', () async {
        final testCases = ['', 'b', 'ab', 'bb', 'abab', 'bbbb'];

        for (final testString in testCases) {
          final result = await AutomatonSimulator.simulate(
            endsWithADFA,
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
                  'String "$testString" should be rejected (does not end with a)',
            );
          }
        }
      });

      test(
        'No consecutive 11s - should reject strings with consecutive 11s',
        () async {
          final testCases = [
            '11',
            '011',
            '110',
            '111',
            '0011',
            '1100',
            '0110',
            '1111',
          ];

          for (final testString in testCases) {
            final result = await AutomatonSimulator.simulate(
              noConsecutive11DFA,
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
                    'String "$testString" should be rejected (contains consecutive 11s)',
              );
            }
          }
        },
      );

      test(
        'At least four ones - should reject strings with less than 4 ones',
        () async {
          final testCases = [
            '',
            '0',
            '1',
            '10',
            '11',
            '101',
            '111',
            '1000',
            '1010',
            '1100',
          ];

          for (final testString in testCases) {
            final result = await AutomatonSimulator.simulate(
              atLeastFourOnesDFA,
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
                    'String "$testString" should be rejected (less than 4 ones)',
              );
            }
          }
        },
      );
    });

    group('Empty String Tests', () {
      test('Empty string acceptance behavior', () async {
        // Test empty string with different DFAs
        const emptyString = '';

        // Binary divisible by 3 should accept empty string (0 is divisible by 3)
        final result1 = await AutomatonSimulator.simulate(
          binaryDivisibleBy3DFA,
          emptyString,
        );
        expect(result1.isSuccess, true);
        if (result1.isSuccess) {
          expect(
            result1.data!.accepted,
            true,
            reason:
                'Empty string should be accepted by binary divisible by 3 DFA',
          );
        }

        // Ends with A should reject empty string
        final result2 = await AutomatonSimulator.simulate(
          endsWithADFA,
          emptyString,
        );
        expect(result2.isSuccess, true);
        if (result2.isSuccess) {
          expect(
            result2.data!.accepted,
            false,
            reason: 'Empty string should be rejected by ends with A DFA',
          );
        }

        // No consecutive 11s should accept empty string
        final result3 = await AutomatonSimulator.simulate(
          noConsecutive11DFA,
          emptyString,
        );
        expect(result3.isSuccess, true);
        if (result3.isSuccess) {
          expect(
            result3.data!.accepted,
            true,
            reason: 'Empty string should be accepted by no consecutive 11s DFA',
          );
        }
      });
    });

    group('Cycle Detection Tests', () {
      test('DFA with cycles should handle long inputs correctly', () async {
        // Test with very long strings to ensure cycle handling works
        final longString = '0' * 1000; // 1000 zeros

        final result = await AutomatonSimulator.simulate(
          binaryDivisibleBy3DFA,
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
            reason: 'Long string of zeros should be accepted (divisible by 3)',
          );
        }
      });

      test('DFA with cycles should maintain state correctly', () async {
        // Test cycling through states
        final cycleString = '01' * 100; // 100 repetitions of "01"

        final result = await AutomatonSimulator.simulate(
          noConsecutive11DFA,
          cycleString,
        );

        expect(
          result.isSuccess,
          true,
          reason: 'Should handle cycling inputs correctly',
        );

        if (result.isSuccess) {
          expect(
            result.data!.accepted,
            true,
            reason: 'Cycling string should be accepted (no consecutive 11s)',
          );
        }
      });
    });

    group('DFA Minimization Tests', () {
      test('DFA minimization should preserve language', () async {
        // Test that minimized DFA accepts same language
        final minimizationResult = DFAMinimizer.minimize(noConsecutive11DFA);

        expect(
          minimizationResult.isSuccess,
          true,
          reason: 'DFA minimization should succeed',
        );

        if (minimizationResult.isSuccess) {
          final minimizedDFA = minimizationResult.data!;

          // Test same strings on both original and minimized DFA
          final testStrings = [
            '',
            '0',
            '1',
            '01',
            '10',
            '001',
            '010',
            '100',
            '101',
          ];

          for (final testString in testStrings) {
            final originalResult = await AutomatonSimulator.simulate(
              noConsecutive11DFA,
              testString,
            );

            final minimizedResult = await AutomatonSimulator.simulate(
              minimizedDFA,
              testString,
            );

            expect(originalResult.isSuccess, true);
            expect(minimizedResult.isSuccess, true);

            if (originalResult.isSuccess && minimizedResult.isSuccess) {
              expect(
                originalResult.data!.accepted,
                minimizedResult.data!.accepted,
                reason:
                    'Minimized DFA should accept same strings as original for "$testString"',
              );
            }
          }
        }
      });
    });
  });
}

/// Helper functions to create test DFAs

FSA _createBinaryDivisibleBy3DFA() {
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
      position: Vector2(300.0, 120.0),
      isInitial: false,
      isAccepting: false,
    ),
    State(
      id: 'q2',
      label: 'q2',
      position: Vector2(300.0, 280.0),
      isInitial: false,
      isAccepting: false,
    ),
  };

  final transitions = {
    FSATransition(
      id: 't1',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q0'),
      label: '0',
      inputSymbols: {'0'},
    ),
    FSATransition(
      id: 't2',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      label: '1',
      inputSymbols: {'1'},
    ),
    FSATransition(
      id: 't3',
      fromState: states.firstWhere((s) => s.id == 'q1'),
      toState: states.firstWhere((s) => s.id == 'q2'),
      label: '0',
      inputSymbols: {'0'},
    ),
    FSATransition(
      id: 't4',
      fromState: states.firstWhere((s) => s.id == 'q1'),
      toState: states.firstWhere((s) => s.id == 'q0'),
      label: '1',
      inputSymbols: {'1'},
    ),
    FSATransition(
      id: 't5',
      fromState: states.firstWhere((s) => s.id == 'q2'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      label: '0',
      inputSymbols: {'0'},
    ),
    FSATransition(
      id: 't6',
      fromState: states.firstWhere((s) => s.id == 'q2'),
      toState: states.firstWhere((s) => s.id == 'q2'),
      label: '1',
      inputSymbols: {'1'},
    ),
  };

  return FSA(
    id: 'binary_divisible_by_3',
    name: 'Binary Divisible by 3',
    states: states,
    transitions: transitions,
    alphabet: {'0', '1'},
    initialState: states.firstWhere((s) => s.isInitial),
    acceptingStates: states.where((s) => s.isAccepting).toSet(),
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 500, 400),
  );
}

FSA _createEndsWithADFA() {
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
      toState: states.firstWhere((s) => s.id == 'q0'),
      label: 'b',
      inputSymbols: {'b'},
    ),
    FSATransition(
      id: 't3',
      fromState: states.firstWhere((s) => s.id == 'q1'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      label: 'a',
      inputSymbols: {'a'},
    ),
    FSATransition(
      id: 't4',
      fromState: states.firstWhere((s) => s.id == 'q1'),
      toState: states.firstWhere((s) => s.id == 'q0'),
      label: 'b',
      inputSymbols: {'b'},
    ),
  };

  return FSA(
    id: 'ends_with_a',
    name: 'Ends with A',
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

FSA _createNoConsecutive11DFA() {
  final states = {
    State(
      id: 'p0',
      label: 'p0',
      position: Vector2(100.0, 200.0),
      isInitial: true,
      isAccepting: true,
    ),
    State(
      id: 'p1',
      label: 'p1',
      position: Vector2(300.0, 200.0),
      isInitial: false,
      isAccepting: true,
    ),
    State(
      id: 'p2',
      label: 'p2',
      position: Vector2(500.0, 200.0),
      isInitial: false,
      isAccepting: false,
    ),
  };

  final transitions = {
    FSATransition(
      id: 't1',
      fromState: states.firstWhere((s) => s.id == 'p0'),
      toState: states.firstWhere((s) => s.id == 'p0'),
      label: '0',
      inputSymbols: {'0'},
    ),
    FSATransition(
      id: 't2',
      fromState: states.firstWhere((s) => s.id == 'p0'),
      toState: states.firstWhere((s) => s.id == 'p1'),
      label: '1',
      inputSymbols: {'1'},
    ),
    FSATransition(
      id: 't3',
      fromState: states.firstWhere((s) => s.id == 'p1'),
      toState: states.firstWhere((s) => s.id == 'p0'),
      label: '0',
      inputSymbols: {'0'},
    ),
    FSATransition(
      id: 't4',
      fromState: states.firstWhere((s) => s.id == 'p1'),
      toState: states.firstWhere((s) => s.id == 'p2'),
      label: '1',
      inputSymbols: {'1'},
    ),
    FSATransition(
      id: 't5',
      fromState: states.firstWhere((s) => s.id == 'p2'),
      toState: states.firstWhere((s) => s.id == 'p2'),
      label: '0',
      inputSymbols: {'0'},
    ),
    FSATransition(
      id: 't6',
      fromState: states.firstWhere((s) => s.id == 'p2'),
      toState: states.firstWhere((s) => s.id == 'p2'),
      label: '1',
      inputSymbols: {'1'},
    ),
  };

  return FSA(
    id: 'no_consecutive_11',
    name: 'No Consecutive 11s',
    states: states,
    transitions: transitions,
    alphabet: {'0', '1'},
    initialState: states.firstWhere((s) => s.isInitial),
    acceptingStates: states.where((s) => s.isAccepting).toSet(),
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 600, 300),
  );
}

FSA _createAtLeastFourOnesDFA() {
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
      position: Vector2(200.0, 200.0),
      isInitial: false,
      isAccepting: false,
    ),
    State(
      id: 'q2',
      label: 'q2',
      position: Vector2(300.0, 200.0),
      isInitial: false,
      isAccepting: false,
    ),
    State(
      id: 'q3',
      label: 'q3',
      position: Vector2(400.0, 200.0),
      isInitial: false,
      isAccepting: false,
    ),
    State(
      id: 'q4',
      label: 'q4',
      position: Vector2(500.0, 200.0),
      isInitial: false,
      isAccepting: true,
    ),
  };

  final transitions = {
    FSATransition(
      id: 't1',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q0'),
      label: '0',
      inputSymbols: {'0'},
    ),
    FSATransition(
      id: 't2',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      label: '1',
      inputSymbols: {'1'},
    ),
    FSATransition(
      id: 't3',
      fromState: states.firstWhere((s) => s.id == 'q1'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      label: '0',
      inputSymbols: {'0'},
    ),
    FSATransition(
      id: 't4',
      fromState: states.firstWhere((s) => s.id == 'q1'),
      toState: states.firstWhere((s) => s.id == 'q2'),
      label: '1',
      inputSymbols: {'1'},
    ),
    FSATransition(
      id: 't5',
      fromState: states.firstWhere((s) => s.id == 'q2'),
      toState: states.firstWhere((s) => s.id == 'q2'),
      label: '0',
      inputSymbols: {'0'},
    ),
    FSATransition(
      id: 't6',
      fromState: states.firstWhere((s) => s.id == 'q2'),
      toState: states.firstWhere((s) => s.id == 'q3'),
      label: '1',
      inputSymbols: {'1'},
    ),
    FSATransition(
      id: 't7',
      fromState: states.firstWhere((s) => s.id == 'q3'),
      toState: states.firstWhere((s) => s.id == 'q3'),
      label: '0',
      inputSymbols: {'0'},
    ),
    FSATransition(
      id: 't8',
      fromState: states.firstWhere((s) => s.id == 'q3'),
      toState: states.firstWhere((s) => s.id == 'q4'),
      label: '1',
      inputSymbols: {'1'},
    ),
    FSATransition(
      id: 't9',
      fromState: states.firstWhere((s) => s.id == 'q4'),
      toState: states.firstWhere((s) => s.id == 'q4'),
      label: '0',
      inputSymbols: {'0'},
    ),
    FSATransition(
      id: 't10',
      fromState: states.firstWhere((s) => s.id == 'q4'),
      toState: states.firstWhere((s) => s.id == 'q4'),
      label: '1',
      inputSymbols: {'1'},
    ),
  };

  return FSA(
    id: 'at_least_four_ones',
    name: 'At Least Four Ones',
    states: states,
    transitions: transitions,
    alphabet: {'0', '1'},
    initialState: states.firstWhere((s) => s.isInitial),
    acceptingStates: states.where((s) => s.isAccepting).toSet(),
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 600, 300),
  );
}
