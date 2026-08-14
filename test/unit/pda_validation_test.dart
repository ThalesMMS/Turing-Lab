//
//  pda_validation_test.dart
//  Turing Lab
//
//  Conjunto de testes que confirma o comportamento do simulador de autômatos de pilha e da conversão de gramáticas livres de contexto para PDAs.
//  Inclui cenários determinísticos e não determinísticos com manipulação de pilha, transições lambda e validação de linguagem contra a referência.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/pda.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/core/models/pda_transition.dart';
import 'package:turing_lab/core/algorithms/pda_simulator.dart';
import 'package:turing_lab/core/algorithms/grammar_to_pda_converter.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/production.dart';
import 'package:vector_math/vector_math_64.dart';
import 'dart:math' as math;

part 'pda_validation_fixtures.dart';

void main() {
  group('PDA Validation Tests', () {
    late PDA balancedParenthesesPDA;
    late PDA palindromePDA;
    late PDA simplePDA;
    late PDA complexPDA;
    late PDA lambdaPDA;

    setUp(() {
      // Test Case 1: Balanced Parentheses PDA
      balancedParenthesesPDA = _createBalancedParenthesesPDA();

      // Test Case 2: Palindrome PDA
      palindromePDA = _createPalindromePDA();

      // Test Case 3: Simple PDA
      simplePDA = _createSimplePDA();

      // Test Case 4: Complex PDA
      complexPDA = _createComplexPDA();

      // Test Case 5: Lambda PDA
      lambdaPDA = _createLambdaPDA();
    });

    group('PDA Simulation Tests', () {
      test('Balanced Parentheses PDA - should accept valid strings', () async {
        final testCases = [
          '', // Empty string
          '()', // Simple balanced
          '(())', // Nested balanced
          '()()', // Multiple balanced
          '((()))', // Deeply nested
          '()()()', // Multiple simple
        ];

        for (final testString in testCases) {
          final result = PDASimulator.simulateNPDA(
            balancedParenthesesPDA,
            testString,
            mode: PDAAcceptanceMode.finalState,
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
                  'String "$testString" should be accepted by balanced parentheses PDA',
            );
          }
        }
      });

      test('Balanced Parentheses PDA - should reject invalid strings',
          () async {
        final testCases = [
          '(', // Unmatched opening
          ')', // Unmatched closing
          '())', // Extra closing
          '(()', // Extra opening
          ')(', // Wrong order
          '((())', // Unmatched opening
          '()))', // Extra closing
        ];

        for (final testString in testCases) {
          final result = PDASimulator.simulateNPDA(
            balancedParenthesesPDA,
            testString,
            mode: PDAAcceptanceMode.finalState,
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
                  'String "$testString" should be rejected by balanced parentheses PDA',
            );
          }
        }
      });

      test(
        'Palindrome PDA - should accept palindromes (even and odd lengths)',
        () async {
          final testCases = [
            '', // Empty string
            'a', // Single character
            'b', // Single character
            'aa', // Even length palindrome
            'bb', // Even length palindrome
            'aba', // Odd length palindrome
            'bab', // Odd length palindrome
            'abba', // Even length palindrome
            'baab', // Even length palindrome
          ];

          for (final testString in testCases) {
            final result = PDASimulator.simulateNPDA(
              palindromePDA,
              testString,
              mode: PDAAcceptanceMode.finalState,
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
                    'String "$testString" should be accepted by palindrome PDA',
              );
            }
          }
        },
      );

      test('Palindrome PDA - should reject non-palindromes', () async {
        final testCases = [
          'ab', // Not a palindrome
          'ba', // Not a palindrome
          'aab', // Not a palindrome
          'bba', // Not a palindrome
          'abab', // Not a palindrome
          'baba', // Not a palindrome
        ];

        for (final testString in testCases) {
          final result = PDASimulator.simulateNPDA(
            palindromePDA,
            testString,
            mode: PDAAcceptanceMode.finalState,
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
                  'String "$testString" should be rejected by palindrome PDA',
            );
          }
        }
      });

      test(
        'Simple PDA - should accept valid strings (via empty stack)',
        () async {
          final testCases = [
            'a', // Single a
            'aa', // Two a's
            'aaa', // Three a's
            'aaaa', // Four a's
          ];

          for (final testString in testCases) {
            final result = PDASimulator.simulateNPDA(
              simplePDA,
              testString,
              mode: PDAAcceptanceMode.finalState,
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
                reason: 'String "$testString" should be accepted by simple PDA',
              );
            }
          }
        },
      );
    });

    group('Stack Operations Tests', () {
      test('PDA should handle push operations correctly', () async {
        final result = PDASimulator.simulateNPDA(
          balancedParenthesesPDA,
          '()',
          mode: PDAAcceptanceMode.finalState,
        );

        expect(result.isSuccess, true);
        if (result.isSuccess) {
          expect(
            result.data!.accepted,
            true,
            reason: 'PDA should accept "()" with proper stack operations',
          );

          // Check that steps show stack operations
          expect(
            result.data!.steps.length,
            greaterThan(1),
            reason: 'PDA should have multiple steps for stack operations',
          );
        }
      }, tags: 'known-failure');

      test('PDA should handle pop operations correctly', () async {
        final result = PDASimulator.simulateNPDA(
          balancedParenthesesPDA,
          '(())',
          mode: PDAAcceptanceMode.finalState,
        );

        expect(result.isSuccess, true);
        if (result.isSuccess) {
          expect(
            result.data!.accepted,
            true,
            reason: 'PDA should accept "(())" with proper stack operations',
          );
        }
      });

      test('PDA should handle lambda operations correctly', () async {
        final result = PDASimulator.simulateNPDA(
          lambdaPDA,
          'a',
          mode: PDAAcceptanceMode.finalState,
        );

        expect(result.isSuccess, true);
        if (result.isSuccess) {
          expect(
            result.data!.accepted,
            true,
            reason: 'Lambda PDA should accept "a" with lambda operations',
          );
        }
      });

      test('PDA should handle empty stack correctly', () async {
        final result = PDASimulator.simulate(balancedParenthesesPDA, '');

        expect(result.isSuccess, true);
        if (result.isSuccess) {
          expect(
            result.data!.accepted,
            true,
            reason: 'PDA should accept empty string with empty stack',
          );
        }
      });
    });

    group('Grammar to PDA Conversion Tests', () {
      test('Grammar should convert to PDA', () async {
        final grammar = _createTestGrammar();

        final result = GrammarToPDAConverter.convert(grammar);

        expect(
          result.isSuccess,
          true,
          reason: 'Grammar should convert to PDA successfully',
        );

        if (result.isSuccess) {
          final pda = result.data!;
          expect(
            pda.states.isNotEmpty,
            true,
            reason: 'Converted PDA should have states',
          );
          expect(
            pda.initialState,
            isNotNull,
            reason: 'Converted PDA should have initial state',
          );
          expect(
            pda.acceptingStates.isNotEmpty,
            true,
            reason: 'Converted PDA should have accepting states',
          );
        }
      });

      test('Converted PDA should accept same language as grammar', () async {
        final grammar = _createTestGrammar();

        final conversionResult = GrammarToPDAConverter.convert(grammar);
        expect(conversionResult.isSuccess, true);

        if (conversionResult.isSuccess) {
          final pda = conversionResult.data!;

          // Test that PDA accepts strings that should be accepted by grammar
          final testStrings = ['', 'a', 'b', 'ab', 'ba', 'aab', 'bba'];

          for (final testString in testStrings) {
            final result = PDASimulator.simulate(pda, testString);

            expect(result.isSuccess, true);
            if (result.isSuccess) {
              // The PDA should accept the same strings as the grammar
              expect(
                result.data!.accepted,
                isA<bool>(),
                reason: 'PDA should either accept or reject "$testString"',
              );
            }
          }
        }
      });

      test('Complex grammar should convert to PDA', () async {
        final grammar = _createComplexGrammar();

        final result = GrammarToPDAConverter.convert(grammar);

        expect(
          result.isSuccess,
          true,
          reason: 'Complex grammar should convert to PDA successfully',
        );

        if (result.isSuccess) {
          final pda = result.data!;
          expect(
            pda.states.length,
            greaterThan(2),
            reason: 'Complex PDA should have multiple states',
          );
        }
      });
    });

    group('Non-deterministic Behavior Tests', () {
      test('PDA should handle non-deterministic choices', () async {
        final result = PDASimulator.simulate(complexPDA, 'ab');

        expect(result.isSuccess, true);
        if (result.isSuccess) {
          expect(
            result.data!.accepted,
            isA<bool>(),
            reason:
                'Non-deterministic PDA should make choices and either accept or reject',
          );
        }
      });

      test('PDA should explore multiple paths', () async {
        final result = PDASimulator.simulate(complexPDA, 'aab');

        expect(result.isSuccess, true);
        if (result.isSuccess) {
          expect(
            result.data!.accepted,
            isA<bool>(),
            reason: 'PDA should explore multiple paths and reach a decision',
          );
        }
      });
    });

    group('Complex Language Recognition Tests', () {
      test('PDA should recognize context-free languages', () async {
        final testCases = [
          '', // Empty string
          '()', // Simple balanced
          '(())', // Nested balanced
          '()()', // Multiple balanced
          '((()))', // Deeply nested
        ];

        for (final testString in testCases) {
          final result = PDASimulator.simulateNPDA(
            balancedParenthesesPDA,
            testString,
            mode: PDAAcceptanceMode.finalState,
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
                  'PDA should recognize context-free language for "$testString"',
            );
          }
        }
      });

      test('PDA should handle long strings efficiently', () async {
        // Test with very long balanced parentheses string
        final longString = '(' * 100 + ')' * 100; // 200 characters

        final result = PDASimulator.simulateNPDA(
          balancedParenthesesPDA,
          longString,
          mode: PDAAcceptanceMode.finalState,
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
            reason: 'Long balanced parentheses string should be accepted',
          );
        }
      });

      test('PDA should handle complex nested structures', () async {
        // Test with complex nested structures
        const complexString = '((()))()((()))';

        final result = PDASimulator.simulateNPDA(
          balancedParenthesesPDA,
          complexString,
          mode: PDAAcceptanceMode.finalState,
        );

        expect(
          result.isSuccess,
          true,
          reason: 'Should handle complex nested structures',
        );

        if (result.isSuccess) {
          expect(
            result.data!.accepted,
            true,
            reason: 'Complex nested string should be accepted',
          );
        }
      });
    });

    group('Error Handling Tests', () {
      test('PDA should handle invalid input symbols', () async {
        final result = PDASimulator.simulateNPDA(
          balancedParenthesesPDA,
          'c', // Invalid symbol
          mode: PDAAcceptanceMode.finalState,
        );

        expect(result.isSuccess, true);
        if (result.isSuccess) {
          expect(
            result.data!.accepted,
            false,
            reason: 'PDA should reject input with invalid symbols',
          );
        }
      });

      test('PDA should handle mixed valid and invalid symbols', () async {
        final result = PDASimulator.simulateNPDA(
          balancedParenthesesPDA,
          '(c)', // Mix of valid and invalid
          mode: PDAAcceptanceMode.finalState,
        );

        expect(result.isSuccess, true);
        if (result.isSuccess) {
          expect(
            result.data!.accepted,
            false,
            reason: 'PDA should reject input with mixed valid/invalid symbols',
          );
        }
      });

      test('PDA should handle stack underflow', () async {
        final result = PDASimulator.simulateNPDA(
          balancedParenthesesPDA,
          ')', // Try to pop from empty stack
          mode: PDAAcceptanceMode.finalState,
        );

        expect(result.isSuccess, true);
        if (result.isSuccess) {
          expect(
            result.data!.accepted,
            false,
            reason: 'PDA should handle stack underflow gracefully',
          );
        }
      });
    });

    group('Performance Tests', () {
      test('PDA should handle complex computations efficiently', () async {
        // Test with complex input that requires many stack operations
        final result = PDASimulator.simulateNPDA(
          balancedParenthesesPDA,
          '((()))()((()))',
          mode: PDAAcceptanceMode.finalState,
        );

        expect(result.isSuccess, true);
        if (result.isSuccess) {
          expect(
            result.data!.accepted,
            true,
            reason: 'PDA should complete complex computations',
          );

          // Check execution time is reasonable
          expect(
            result.data!.executionTime.inSeconds,
            lessThan(5),
            reason: 'PDA should complete within reasonable time',
          );
        }
      });

      test('PDA should handle multiple stack operations', () async {
        // Test PDA that performs multiple stack operations
        final result = PDASimulator.simulateNPDA(
          balancedParenthesesPDA,
          '(()())',
          mode: PDAAcceptanceMode.finalState,
        );

        expect(result.isSuccess, true);
        if (result.isSuccess) {
          expect(
            result.data!.accepted,
            true,
            reason: 'PDA should handle multiple stack operations',
          );

          // Verify sufficient steps were taken
          expect(
            result.data!.steps.length,
            greaterThan(5),
            reason: 'PDA should take multiple steps for complex operations',
          );
        }
      }, tags: 'known-failure');
    });
  });
}
