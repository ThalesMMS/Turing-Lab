//
//  dfa_minimization_validation_test.dart
//  Turing Lab
//
//  Testes que verificam o algoritmo de minimização de DFAs assegurando redução correta de estados sem alterar a linguagem reconhecida.
//  Englobam autômatos básicos, estruturas redundantes, casos já minimizados e máquinas sem estados de aceitação para checar diagnósticos.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/algorithms/dfa_minimizer.dart';
import 'dart:math' as math;
import 'package:turing_lab/core/algorithms/automaton_simulator.dart';
import 'package:vector_math/vector_math_64.dart';

part 'dfa_minimization_validation_fixtures.dart';

void main() {
  group('DFA Minimization Validation Tests', () {
    late FSA basicDFA;
    late FSA complexDFA;
    late FSA minimalDFA;
    late FSA noFinalStatesDFA;
    late FSA redundantStatesDFA;

    setUp(() {
      // Test Case 1: Basic DFA
      basicDFA = _createBasicDFA();

      // Test Case 2: Complex DFA with redundant states
      complexDFA = _createComplexDFA();

      // Test Case 3: Already minimal DFA
      minimalDFA = _createMinimalDFA();

      // Test Case 4: DFA with no final states
      noFinalStatesDFA = _createNoFinalStatesDFA();

      // Test Case 5: DFA with redundant states
      redundantStatesDFA = _createRedundantStatesDFA();
    });

    group('Basic DFA Minimization Tests', () {
      test('Basic DFA should minimize correctly', () async {
        final minimizationResult = DFAMinimizer.minimize(basicDFA);

        expect(
          minimizationResult.isSuccess,
          true,
          reason: 'Basic DFA minimization should succeed',
        );

        if (minimizationResult.isSuccess) {
          final minimizedDFA = minimizationResult.data!;

          // Test that minimized DFA has correct structure
          expect(
            minimizedDFA.states.isNotEmpty,
            true,
            reason: 'Minimized DFA should have states',
          );
          expect(
            minimizedDFA.initialState,
            isNotNull,
            reason: 'Minimized DFA should have initial state',
          );
          expect(
            minimizedDFA.acceptingStates.isNotEmpty,
            true,
            reason: 'Minimized DFA should have accepting states',
          );

          // Test equivalence with original DFA
          final testStrings = [
            '0',
            '1',
            '00',
            '01',
            '10',
            '11',
            '000',
            '001',
            '010',
            '011',
          ];
          for (final testString in testStrings) {
            final originalResult = await AutomatonSimulator.simulate(
              basicDFA,
              testString,
            );
            final minimizedResult = await AutomatonSimulator.simulate(
              minimizedDFA,
              testString,
            );

            expect(
              originalResult.isSuccess,
              true,
              reason:
                  'Original DFA simulation should succeed for "$testString"',
            );
            expect(
              minimizedResult.isSuccess,
              true,
              reason:
                  'Minimized DFA simulation should succeed for "$testString"',
            );

            if (originalResult.isSuccess && minimizedResult.isSuccess) {
              expect(
                originalResult.data!.accepted,
                minimizedResult.data!.accepted,
                reason:
                    'Original and minimized DFA should have same acceptance for "$testString"',
              );
            }
          }
        }
      });

      test('Basic DFA minimization should reduce state count', () async {
        final minimizationResult = DFAMinimizer.minimize(basicDFA);

        expect(minimizationResult.isSuccess, true);

        if (minimizationResult.isSuccess) {
          final minimizedDFA = minimizationResult.data!;

          // Minimized DFA should have fewer or equal states
          expect(
            minimizedDFA.states.length,
            lessThanOrEqualTo(basicDFA.states.length),
            reason: 'Minimized DFA should have fewer or equal states',
          );
        }
      });
    });

    group('Complex DFA Minimization Tests', () {
      test('Complex DFA should minimize correctly', () async {
        final minimizationResult = DFAMinimizer.minimize(complexDFA);

        expect(
          minimizationResult.isSuccess,
          true,
          reason: 'Complex DFA minimization should succeed',
        );

        if (minimizationResult.isSuccess) {
          final minimizedDFA = minimizationResult.data!;

          // Test equivalence with original DFA
          final testStrings = [
            '0',
            '1',
            '00',
            '01',
            '10',
            '11',
            '000',
            '001',
            '010',
            '011',
            '100',
            '101',
            '110',
            '111',
          ];
          for (final testString in testStrings) {
            final originalResult = await AutomatonSimulator.simulate(
              complexDFA,
              testString,
            );
            final minimizedResult = await AutomatonSimulator.simulate(
              minimizedDFA,
              testString,
            );

            expect(
              originalResult.isSuccess,
              true,
              reason:
                  'Original DFA simulation should succeed for "$testString"',
            );
            expect(
              minimizedResult.isSuccess,
              true,
              reason:
                  'Minimized DFA simulation should succeed for "$testString"',
            );

            if (originalResult.isSuccess && minimizedResult.isSuccess) {
              expect(
                originalResult.data!.accepted,
                minimizedResult.data!.accepted,
                reason:
                    'Original and minimized DFA should have same acceptance for "$testString"',
              );
            }
          }
        }
      });

      test(
        'Complex DFA minimization should significantly reduce state count',
        () async {
          final minimizationResult = DFAMinimizer.minimize(complexDFA);

          expect(minimizationResult.isSuccess, true);

          if (minimizationResult.isSuccess) {
            final minimizedDFA = minimizationResult.data!;

            // Complex DFA should have significantly fewer states after minimization
            expect(
              minimizedDFA.states.length,
              lessThan(complexDFA.states.length),
              reason: 'Complex DFA should have fewer states after minimization',
            );
          }
        },
      );
    });

    group('Already Minimal DFA Tests', () {
      test('Already minimal DFA should remain equivalent', () async {
        final minimizationResult = DFAMinimizer.minimize(minimalDFA);

        expect(
          minimizationResult.isSuccess,
          true,
          reason: 'Minimal DFA minimization should succeed',
        );

        if (minimizationResult.isSuccess) {
          final minimizedDFA = minimizationResult.data!;

          // Test equivalence with original DFA
          final testStrings = ['0', '1', '00', '01', '10', '11'];
          for (final testString in testStrings) {
            final originalResult = await AutomatonSimulator.simulate(
              minimalDFA,
              testString,
            );
            final minimizedResult = await AutomatonSimulator.simulate(
              minimizedDFA,
              testString,
            );

            expect(
              originalResult.isSuccess,
              true,
              reason:
                  'Original DFA simulation should succeed for "$testString"',
            );
            expect(
              minimizedResult.isSuccess,
              true,
              reason:
                  'Minimized DFA simulation should succeed for "$testString"',
            );

            if (originalResult.isSuccess && minimizedResult.isSuccess) {
              expect(
                originalResult.data!.accepted,
                minimizedResult.data!.accepted,
                reason:
                    'Original and minimized DFA should have same acceptance for "$testString"',
              );
            }
          }
        }
      });

      test('Already minimal DFA should have same state count', () async {
        final minimizationResult = DFAMinimizer.minimize(minimalDFA);

        expect(minimizationResult.isSuccess, true);

        if (minimizationResult.isSuccess) {
          final minimizedDFA = minimizationResult.data!;

          // Already minimal DFA should have same number of states
          expect(
            minimizedDFA.states.length,
            equals(minimalDFA.states.length),
            reason: 'Already minimal DFA should have same state count',
          );
        }
      });
    });

    group('No Final States DFA Tests', () {
      test('DFA with no final states should minimize correctly', () async {
        final minimizationResult = DFAMinimizer.minimize(noFinalStatesDFA);

        expect(
          minimizationResult.isSuccess,
          true,
          reason: 'No final states DFA minimization should succeed',
        );

        if (minimizationResult.isSuccess) {
          final minimizedDFA = minimizationResult.data!;

          // Test equivalence with original DFA
          final testStrings = ['0', '1', '00', '01', '10', '11'];
          for (final testString in testStrings) {
            final originalResult = await AutomatonSimulator.simulate(
              noFinalStatesDFA,
              testString,
            );
            final minimizedResult = await AutomatonSimulator.simulate(
              minimizedDFA,
              testString,
            );

            expect(
              originalResult.isSuccess,
              true,
              reason:
                  'Original DFA simulation should succeed for "$testString"',
            );
            expect(
              minimizedResult.isSuccess,
              true,
              reason:
                  'Minimized DFA simulation should succeed for "$testString"',
            );

            if (originalResult.isSuccess && minimizedResult.isSuccess) {
              expect(
                originalResult.data!.accepted,
                minimizedResult.data!.accepted,
                reason:
                    'Original and minimized DFA should have same acceptance for "$testString"',
              );
            }
          }
        }
      });

      test(
        'DFA with no final states should have no accepting states after minimization',
        () async {
          final minimizationResult = DFAMinimizer.minimize(noFinalStatesDFA);

          expect(minimizationResult.isSuccess, true);

          if (minimizationResult.isSuccess) {
            final minimizedDFA = minimizationResult.data!;

            // DFA with no final states should have no accepting states
            expect(
              minimizedDFA.acceptingStates.isEmpty,
              true,
              reason:
                  'DFA with no final states should have no accepting states after minimization',
            );
          }
        },
      );
    });

    group('Redundant States DFA Tests', () {
      test('DFA with redundant states should minimize correctly', () async {
        final minimizationResult = DFAMinimizer.minimize(redundantStatesDFA);

        expect(
          minimizationResult.isSuccess,
          true,
          reason: 'Redundant states DFA minimization should succeed',
        );

        if (minimizationResult.isSuccess) {
          final minimizedDFA = minimizationResult.data!;

          // Test equivalence with original DFA
          final testStrings = [
            '0',
            '1',
            '00',
            '01',
            '10',
            '11',
            '000',
            '001',
            '010',
            '011',
          ];
          for (final testString in testStrings) {
            final originalResult = await AutomatonSimulator.simulate(
              redundantStatesDFA,
              testString,
            );
            final minimizedResult = await AutomatonSimulator.simulate(
              minimizedDFA,
              testString,
            );

            expect(
              originalResult.isSuccess,
              true,
              reason:
                  'Original DFA simulation should succeed for "$testString"',
            );
            expect(
              minimizedResult.isSuccess,
              true,
              reason:
                  'Minimized DFA simulation should succeed for "$testString"',
            );

            if (originalResult.isSuccess && minimizedResult.isSuccess) {
              expect(
                originalResult.data!.accepted,
                minimizedResult.data!.accepted,
                reason:
                    'Original and minimized DFA should have same acceptance for "$testString"',
              );
            }
          }
        }
      });

      test(
        'DFA with redundant states should significantly reduce state count',
        () async {
          final minimizationResult = DFAMinimizer.minimize(redundantStatesDFA);

          expect(minimizationResult.isSuccess, true);

          if (minimizationResult.isSuccess) {
            final minimizedDFA = minimizationResult.data!;

            // DFA with redundant states should have significantly fewer states
            expect(
              minimizedDFA.states.length,
              lessThan(redundantStatesDFA.states.length),
              reason:
                  'DFA with redundant states should have fewer states after minimization',
            );
          }
        },
      );
    });

    group('Equivalence Testing', () {
      test('Minimized DFA should be equivalent to original DFA', () async {
        final testCases = [
          (basicDFA, 'Basic DFA'),
          (complexDFA, 'Complex DFA'),
          (minimalDFA, 'Minimal DFA'),
          (noFinalStatesDFA, 'No Final States DFA'),
          (redundantStatesDFA, 'Redundant States DFA'),
        ];

        for (final (dfa, description) in testCases) {
          final minimizationResult = DFAMinimizer.minimize(dfa);

          expect(
            minimizationResult.isSuccess,
            true,
            reason: '$description minimization should succeed',
          );

          if (minimizationResult.isSuccess) {
            final minimizedDFA = minimizationResult.data!;

            // Test with various strings
            final testStrings = [
              '',
              '0',
              '1',
              '00',
              '01',
              '10',
              '11',
              '000',
              '001',
              '010',
              '011',
              '100',
              '101',
              '110',
              '111',
            ];

            for (final testString in testStrings) {
              final originalResult = await AutomatonSimulator.simulate(
                dfa,
                testString,
              );
              final minimizedResult = await AutomatonSimulator.simulate(
                minimizedDFA,
                testString,
              );

              expect(
                originalResult.isSuccess,
                true,
                reason:
                    'Original DFA simulation should succeed for "$testString" in $description',
              );
              expect(
                minimizedResult.isSuccess,
                true,
                reason:
                    'Minimized DFA simulation should succeed for "$testString" in $description',
              );

              if (originalResult.isSuccess && minimizedResult.isSuccess) {
                expect(
                  originalResult.data!.accepted,
                  minimizedResult.data!.accepted,
                  reason:
                      'Original and minimized DFA should have same acceptance for "$testString" in $description',
                );
              }
            }
          }
        }
      });

      test('Minimized DFA should handle edge cases', () async {
        final minimizationResult = DFAMinimizer.minimize(basicDFA);

        expect(minimizationResult.isSuccess, true);

        if (minimizationResult.isSuccess) {
          final minimizedDFA = minimizationResult.data!;

          // Test with edge case strings
          final edgeCases = ['', '0', '1', '00', '01', '10', '11'];

          for (final testString in edgeCases) {
            final originalResult = await AutomatonSimulator.simulate(
              basicDFA,
              testString,
            );
            final minimizedResult = await AutomatonSimulator.simulate(
              minimizedDFA,
              testString,
            );

            expect(
              originalResult.isSuccess,
              true,
              reason:
                  'Original DFA simulation should succeed for edge case "$testString"',
            );
            expect(
              minimizedResult.isSuccess,
              true,
              reason:
                  'Minimized DFA simulation should succeed for edge case "$testString"',
            );

            if (originalResult.isSuccess && minimizedResult.isSuccess) {
              expect(
                originalResult.data!.accepted,
                minimizedResult.data!.accepted,
                reason:
                    'Original and minimized DFA should have same acceptance for edge case "$testString"',
              );
            }
          }
        }
      });
    });

    group('Performance Tests', () {
      test('DFA minimization should complete within reasonable time', () async {
        final stopwatch = Stopwatch()..start();

        final minimizationResult = DFAMinimizer.minimize(complexDFA);

        stopwatch.stop();

        expect(
          minimizationResult.isSuccess,
          true,
          reason: 'Complex DFA minimization should succeed',
        );
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(1000),
          reason: 'DFA minimization should complete within 1 second',
        );
      });

      test('Minimized DFA should handle long strings efficiently', () async {
        final minimizationResult = DFAMinimizer.minimize(complexDFA);

        expect(minimizationResult.isSuccess, true);

        if (minimizationResult.isSuccess) {
          final minimizedDFA = minimizationResult.data!;

          // Test with longer strings
          final longString = '01' * 10; // 20 characters

          final stopwatch = Stopwatch()..start();
          final result = await AutomatonSimulator.simulate(
            minimizedDFA,
            longString,
          );
          stopwatch.stop();

          expect(
            result.isSuccess,
            true,
            reason: 'Minimized DFA simulation should succeed for long string',
          );
          expect(
            stopwatch.elapsedMilliseconds,
            lessThan(1000),
            reason: 'Minimized DFA simulation should complete within 1 second',
          );
        }
      });
    });

    group('Error Handling Tests', () {
      test('Empty DFA should fail minimization', () async {
        final emptyDFA = _createEmptyDFA();

        final minimizationResult = DFAMinimizer.minimize(emptyDFA);

        expect(
          minimizationResult.isSuccess,
          false,
          reason: 'Empty DFA minimization should fail',
        );
      });

      test('DFA without initial state should fail minimization', () async {
        final noInitialDFA = _createNoInitialDFA();

        final minimizationResult = DFAMinimizer.minimize(noInitialDFA);

        expect(
          minimizationResult.isSuccess,
          false,
          reason: 'DFA without initial state minimization should fail',
        );
      });
    });
  });
}
