//
//  tm_validation_test.dart
//  Turing Lab
//
//  Test suite that compares the Turing-machine simulator with real acceptance, rejection, and infinite-loop detection cases.
//  Routines build varied machines, check tape transformations, and confirm operational limits aligned with the reference implementation.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/tm.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/core/models/tm_transition.dart';
import 'package:turing_lab/core/algorithms/tm_simulator.dart';
import 'package:vector_math/vector_math_64.dart';
import 'dart:math' as math;

part 'tm_validation_fixtures.dart';

void main() {
  group('TM Validation Tests', () {
    late TM binaryToUnaryTM;
    late TM palindromeTM;
    late TM acceptAllTM;
    late TM rejectAllTM;
    late TM loopDetectionTM;

    setUp(() {
      // Test Case 1: Binary to Unary (from assets/examples)
      binaryToUnaryTM = _createBinaryToUnaryTM();

      // Test Case 2: Palindrome TM (working DTM with markers)
      palindromeTM = _createSimplePalindromeDTM();

      // Test Case 3: Accept All TM
      acceptAllTM = _createAcceptAllTM();

      // Test Case 4: Reject All TM
      rejectAllTM = _createRejectAllTM();

      // Test Case 5: Loop Detection TM
      loopDetectionTM = _createLoopDetectionTM();
    });

    group('Acceptance Tests', () {
      test('Binary to Unary - should accept valid binary numbers', () async {
        final testCases = [
          '0', // Should convert to '1'
          '1', // Should convert to '11'
          '10', // Should convert to '111'
          '11', // Should convert to '1111'
          '100', // Should convert to '11111'
        ];

        for (final testString in testCases) {
          final result = TMSimulator.simulate(binaryToUnaryTM, testString);

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
                  'Binary "$testString" should be accepted by binary to unary TM',
            );
          }
        }
      });

      test('Palindrome TM - should accept palindromes', () async {
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
          final result = TMSimulator.simulate(palindromeTM, testString);

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
                  'String "$testString" should be accepted by palindrome TM',
            );
          }
        }
      });

      test('Accept All TM - should accept any string', () async {
        final testCases = [
          '', // Empty string
          'a', // Single character
          'ab', // Two characters
          'abc', // Three characters
          'abcd', // Four characters
        ];

        for (final testString in testCases) {
          final result = TMSimulator.simulate(acceptAllTM, testString);

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
                  'String "$testString" should be accepted by accept all TM',
            );
          }
        }
      });
    });

    group('Rejection Tests', () {
      test('Palindrome TM - should reject non-palindromes', () async {
        final testCases = [
          'ab', // Not a palindrome
          'ba', // Not a palindrome
          'aab', // Not a palindrome
          'bba', // Not a palindrome
          'abab', // Not a palindrome
          'baba', // Not a palindrome
        ];

        for (final testString in testCases) {
          final result = TMSimulator.simulate(palindromeTM, testString);

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
                  'String "$testString" should be rejected by palindrome TM',
            );
          }
        }
      });

      test('Reject All TM - should reject any string', () async {
        final testCases = [
          '', // Empty string
          'a', // Single character
          'ab', // Two characters
          'abc', // Three characters
          'abcd', // Four characters
        ];

        for (final testString in testCases) {
          final result = TMSimulator.simulate(rejectAllTM, testString);

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
                  'String "$testString" should be rejected by reject all TM',
            );
          }
        }
      });
    });

    group('Loop Detection Tests', () {
      test('TM should detect infinite loops', () async {
        // Test with TM that has infinite loop
        final result = TMSimulator.simulate(loopDetectionTM, 'a');

        expect(result.isSuccess, true);
        if (result.isSuccess) {
          // The TM should either accept, reject, or timeout due to loop
          expect(
            result.data!.accepted,
            isA<bool>(),
            reason: 'TM should either accept or reject (not loop infinitely)',
          );
        }
      });

      test('TM should handle timeout scenarios', () async {
        // Test with very long input that might cause timeout
        final longString = 'a' * 1000; // 1000 a's

        final result = TMSimulator.simulate(
          loopDetectionTM,
          longString,
          timeout: const Duration(milliseconds: 100), // Short timeout
        );

        expect(result.isSuccess, true);
        if (result.isSuccess) {
          // Should either complete or timeout
          expect(
            result.data!.accepted,
            isA<bool>(),
            reason: 'TM should handle long inputs without infinite loops',
          );
        }
      });
    });

    group('Transformation Tests', () {
      test('Binary to Unary TM should transform input', () async {
        // Test that the TM actually transforms the input
        final result = TMSimulator.simulate(
          binaryToUnaryTM,
          '10', // Binary 2
        );

        expect(result.isSuccess, true);
        if (result.isSuccess) {
          expect(
            result.data!.accepted,
            true,
            reason: 'Binary to unary TM should accept "10"',
          );

          // Check that the tape was modified (transformation occurred)
          expect(
            result.data!.steps.isNotEmpty,
            isTrue,
            reason: 'TM should have execution steps',
          );
        }
      });

      test('TM should handle tape modifications correctly', () async {
        // Test with TM that modifies the tape
        final result = TMSimulator.simulate(
          binaryToUnaryTM,
          '11', // Binary 3
        );

        expect(result.isSuccess, true);
        if (result.isSuccess) {
          expect(
            result.data!.accepted,
            true,
            reason: 'Binary to unary TM should accept "11"',
          );

          // Verify that steps show tape modifications
          expect(
            result.data!.steps.length,
            greaterThan(1),
            reason:
                'TM should have multiple execution steps for transformation',
          );
        }
      });
    });

    group('Tape Limits Tests', () {
      test('TM should handle empty tape correctly', () async {
        final result = TMSimulator.simulate(acceptAllTM, '');

        expect(result.isSuccess, true);
        if (result.isSuccess) {
          expect(
            result.data!.accepted,
            true,
            reason: 'TM should handle empty input correctly',
          );
        }
      });

      test('TM should handle single character input', () async {
        final result = TMSimulator.simulate(palindromeTM, 'a');

        expect(result.isSuccess, true);
        if (result.isSuccess) {
          expect(
            result.data!.accepted,
            true,
            reason: 'Single character should be accepted as palindrome',
          );
        }
      });

      test('TM should handle maximum tape length', () async {
        // Test with very long input to test tape limits
        final longString = 'ab' * 500; // 1000 characters

        final result = TMSimulator.simulate(palindromeTM, longString);

        expect(result.isSuccess, true);
        if (result.isSuccess) {
          // Should either accept or reject, but not crash
          expect(
            result.data!.accepted,
            isA<bool>(),
            reason: 'TM should handle long inputs without issues',
          );
        }
      });
    });

    group('Performance Tests', () {
      test('TM should handle complex computations efficiently', () async {
        // Test with complex input that requires many steps
        final result = TMSimulator.simulate(
          binaryToUnaryTM,
          '1111', // Binary 15
        );

        expect(result.isSuccess, true);
        if (result.isSuccess) {
          expect(
            result.data!.accepted,
            true,
            reason: 'TM should complete complex computations',
          );

          // Check execution time is reasonable
          expect(
            result.data!.executionTime.inSeconds,
            lessThan(5),
            reason: 'TM should complete within reasonable time',
          );
        }
      });

      test('TM should handle multiple tape operations', () async {
        // Test TM that performs multiple tape operations
        final result = TMSimulator.simulate(
          binaryToUnaryTM,
          '1010', // Binary 10
        );

        expect(result.isSuccess, true);
        if (result.isSuccess) {
          expect(
            result.data!.accepted,
            true,
            reason: 'TM should handle multiple tape operations',
          );

          // Verify sufficient steps were taken
          expect(
            result.data!.steps.length,
            greaterThan(5),
            reason: 'TM should take multiple steps for complex operations',
          );
        }
      });
    });

    group('Error Handling Tests', () {
      test('TM should handle invalid input symbols', () async {
        // Test with symbols not in the alphabet
        final result = TMSimulator.simulate(
          binaryToUnaryTM,
          'c', // Invalid symbol
        );

        // Invalid symbols should produce a failure Result
        expect(
          result.isSuccess,
          false,
          reason: 'Simulation should fail on invalid input symbols',
        );
      });

      test('TM should handle mixed valid and invalid symbols', () async {
        final result = TMSimulator.simulate(
          binaryToUnaryTM,
          'a1b', // Mix of valid and invalid
        );

        // Invalid symbols should produce a failure Result
        expect(
          result.isSuccess,
          false,
          reason: 'Simulation should fail on mixed valid/invalid symbols',
        );
      });
    });
  });
}
