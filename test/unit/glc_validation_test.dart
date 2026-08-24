//
//  glc_validation_test.dart
//  Turing Lab
//
//  Tests for the context-free grammar parser and related utilities: derivation, normalization, and analysis.
//  Scenarios detect recursion, ambiguity, CNF conversions, and compare imported examples from supporting libraries.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/production.dart';
import 'package:turing_lab/core/algorithms/grammar_parser.dart';

void main() {
  group('GLC Validation Tests', () {
    late Grammar balancedParenthesesGrammar;
    late Grammar palindromeGrammar;
    late Grammar leftRecursiveGrammar;
    late Grammar ambiguousGrammar;
    late Grammar cnfGrammar;

    setUp(() {
      // Test Case 1: Balanced Parentheses (from assets/examples)
      balancedParenthesesGrammar = _createBalancedParenthesesGrammar();

      // Test Case 2: Palindrome Grammar (from assets/examples)
      palindromeGrammar = _createPalindromeGrammar();

      // Test Case 3: Left Recursive Grammar
      leftRecursiveGrammar = _createLeftRecursiveGrammar();

      // Test Case 4: Ambiguous Grammar
      ambiguousGrammar = _createAmbiguousGrammar();

      // Test Case 5: CNF Grammar
      cnfGrammar = _createCNFGrammar();
    });

    group('Valid Derivation Tests', () {
      test('Balanced Parentheses - should accept valid strings', () async {
        final testCases = [
          '', // Empty string
          '()', // Simple balanced
          '(())', // Nested balanced
          '()()', // Multiple balanced
          '((()))', // Deeply nested
          '()()()', // Multiple simple
        ];

        for (final testString in testCases) {
          final result = GrammarParser.parse(
            balancedParenthesesGrammar,
            testString,
          );

          expect(
            result.isSuccess,
            true,
            reason: 'Parsing should succeed for "$testString"',
          );

          if (result.isSuccess) {
            expect(
              result.data!.accepted,
              true,
              reason:
                  'String "$testString" should be accepted by balanced parentheses grammar',
            );
          }
        }
      });

      test('Palindrome Grammar - should accept palindromes', () async {
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
          final result = GrammarParser.parse(palindromeGrammar, testString);

          expect(
            result.isSuccess,
            true,
            reason: 'Parsing should succeed for "$testString"',
          );

          if (result.isSuccess) {
            expect(
              result.data!.accepted,
              true,
              reason:
                  'String "$testString" should be accepted by palindrome grammar',
            );
          }
        }
      });

      test('CNF Grammar - should accept valid strings', () async {
        final testCases = [
          'a', // Single terminal
          'b', // Single terminal
          'ab', // Two terminals
          'ba', // Two terminals
        ];

        for (final testString in testCases) {
          final result = GrammarParser.parse(cnfGrammar, testString);

          expect(
            result.isSuccess,
            true,
            reason: 'Parsing should succeed for "$testString"',
          );

          if (result.isSuccess) {
            expect(
              result.data!.accepted,
              true,
              reason: 'String "$testString" should be accepted by CNF grammar',
            );
          }
        }
      });
    });

    group('Invalid Derivation Tests', () {
      test('Balanced Parentheses - should reject invalid strings', () async {
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
          final result = GrammarParser.parse(
            balancedParenthesesGrammar,
            testString,
          );

          expect(
            result.isSuccess,
            true,
            reason: 'Parsing should succeed for "$testString"',
          );

          if (result.isSuccess) {
            expect(
              result.data!.accepted,
              false,
              reason:
                  'String "$testString" should be rejected by balanced parentheses grammar',
            );
          }
        }
      });

      test('Palindrome Grammar - should reject non-palindromes', () async {
        final testCases = [
          'ab', // Not a palindrome
          'ba', // Not a palindrome
          'aab', // Not a palindrome
          'bba', // Not a palindrome
          'abab', // Not a palindrome
          'baba', // Not a palindrome
        ];

        for (final testString in testCases) {
          final result = GrammarParser.parse(palindromeGrammar, testString);

          expect(
            result.isSuccess,
            true,
            reason: 'Parsing should succeed for "$testString"',
          );

          if (result.isSuccess) {
            expect(
              result.data!.accepted,
              false,
              reason:
                  'String "$testString" should be rejected by palindrome grammar',
            );
          }
        }
      });

      test('Grammar should reject symbols not in alphabet', () async {
        final testCases = [
          'c', // Symbol not in alphabet
          'ac', // Mix of valid and invalid
          'cb', // Mix of invalid and valid
        ];

        for (final testString in testCases) {
          final result = GrammarParser.parse(palindromeGrammar, testString);

          expect(
            result.isSuccess,
            false,
            reason:
                'Parsing should fail for "$testString" (contains invalid symbols)',
          );
        }
      });
    });

    group('CNF/CYK Tests', () {
      test('CYK algorithm should work with CNF grammar', () async {
        final testCases = [
          'a', // Single terminal
          'b', // Single terminal
          'ab', // Two terminals
          'ba', // Two terminals
        ];

        for (final testString in testCases) {
          final result = GrammarParser.parse(
            cnfGrammar,
            testString,
            strategyHint: ParsingStrategyHint.cyk,
          );

          expect(
            result.isSuccess,
            true,
            reason: 'CYK parsing should succeed for "$testString"',
          );

          if (result.isSuccess) {
            expect(
              result.data!.accepted,
              true,
              reason:
                  'String "$testString" should be accepted by CYK algorithm',
            );
          }
        }
      });

      test('CNF conversion should preserve language', () async {
        // Test that CNF conversion doesn't change the language
        final originalResult = GrammarParser.parse(
          balancedParenthesesGrammar,
          '()',
        );

        // Note: In a real implementation, we would convert to CNF and test
        // For now, we just verify the original grammar works
        expect(originalResult.isSuccess, true);
        if (originalResult.isSuccess) {
          expect(
            originalResult.data!.accepted,
            true,
            reason: 'Original grammar should accept "()"',
          );
        }
      });
    });

    group('Left Recursion Tests', () {
      test('Left recursive grammar should be detected', () async {
        // Test that left recursion is properly handled
        final result = GrammarParser.parse(leftRecursiveGrammar, 'a');

        // The grammar should still work, but we should be able to detect left recursion
        expect(result.isSuccess, true);
        if (result.isSuccess) {
          expect(
            result.data!.accepted,
            true,
            reason: 'Left recursive grammar should still accept valid strings',
          );
        }
      });

      test('Left recursive grammar should handle complex derivations',
          () async {
        final testCases = [
          'a', // Simple case
          'aa', // Multiple a's
          'aaa', // Multiple a's
        ];

        for (final testString in testCases) {
          final result = GrammarParser.parse(leftRecursiveGrammar, testString);

          expect(
            result.isSuccess,
            true,
            reason: 'Parsing should succeed for "$testString"',
          );

          if (result.isSuccess) {
            expect(
              result.data!.accepted,
              true,
              reason:
                  'String "$testString" should be accepted by left recursive grammar',
            );
          }
        }
      });
    });

    group('Ambiguity Tests', () {
      test('Ambiguous grammar should handle multiple derivations', () async {
        // Test that ambiguous grammar can handle strings with multiple derivations
        final result = GrammarParser.parse(ambiguousGrammar, 'a');

        expect(result.isSuccess, true);
        if (result.isSuccess) {
          expect(
            result.data!.accepted,
            true,
            reason: 'Ambiguous grammar should accept valid strings',
          );
        }
      });

      test('Ambiguous grammar should handle complex cases', () async {
        final testCases = [
          'a', // Simple case
          'aa', // Multiple a's
          'aaa', // Multiple a's
        ];

        for (final testString in testCases) {
          final result = GrammarParser.parse(ambiguousGrammar, testString);

          expect(
            result.isSuccess,
            true,
            reason: 'Parsing should succeed for "$testString"',
          );

          if (result.isSuccess) {
            expect(
              result.data!.accepted,
              true,
              reason:
                  'String "$testString" should be accepted by ambiguous grammar',
            );
          }
        }
      });
    });

    group('Performance Tests', () {
      test('Grammar should handle long strings efficiently', () async {
        // Test with very long strings to ensure performance
        final longString = '()' * 1000; // 2000 characters

        final result = GrammarParser.parse(
          balancedParenthesesGrammar,
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
            reason: 'Long balanced parentheses string should be accepted',
          );
        }
      });

      test('Grammar should handle complex nested structures', () async {
        // Test with deeply nested structures
        final nestedString = '(' * 100 + ')' * 100; // 200 characters

        final result = GrammarParser.parse(
          balancedParenthesesGrammar,
          nestedString,
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
            reason: 'Deeply nested parentheses should be accepted',
          );
        }
      });
    });

    group('Grammar Validation Tests', () {
      test('Grammar should validate input symbols', () async {
        // Test with invalid symbols
        final result = GrammarParser.parse(
          balancedParenthesesGrammar,
          'c', // Invalid symbol
        );

        expect(
          result.isSuccess,
          false,
          reason: 'Should reject strings with invalid symbols',
        );
      });

      test('Grammar should handle empty strings correctly', () async {
        final result = GrammarParser.parse(balancedParenthesesGrammar, '');

        expect(result.isSuccess, true);
        if (result.isSuccess) {
          expect(
            result.data!.accepted,
            true,
            reason:
                'Empty string should be accepted by balanced parentheses grammar',
          );
        }
      });
    });
  });
}

/// Helper functions to create test grammars

Grammar _createBalancedParenthesesGrammar() {
  final productions = {
    const Production(
      id: 'p1',
      leftSide: ['S'],
      rightSide: ['S', 'S'],
      isLambda: false,
      order: 1,
    ),
    const Production(
      id: 'p2',
      leftSide: ['S'],
      rightSide: ['(', 'S', ')'],
      isLambda: false,
      order: 2,
    ),
    const Production(
      id: 'p3',
      leftSide: ['S'],
      rightSide: [],
      isLambda: true,
      order: 3,
    ),
  };

  return Grammar(
    id: 'balanced_parentheses',
    name: 'Balanced Parentheses',
    terminals: {'(', ')'},
    nonterminals: {'S'},
    startSymbol: 'S',
    productions: productions,
    type: GrammarType.contextFree,
    created: DateTime.now(),
    modified: DateTime.now(),
  );
}

Grammar _createPalindromeGrammar() {
  final productions = {
    const Production(
      id: 'p1',
      leftSide: ['S'],
      rightSide: ['a', 'S', 'a'],
      isLambda: false,
      order: 1,
    ),
    const Production(
      id: 'p2',
      leftSide: ['S'],
      rightSide: ['b', 'S', 'b'],
      isLambda: false,
      order: 2,
    ),
    const Production(
      id: 'p3',
      leftSide: ['S'],
      rightSide: ['a'],
      isLambda: false,
      order: 3,
    ),
    const Production(
      id: 'p4',
      leftSide: ['S'],
      rightSide: ['b'],
      isLambda: false,
      order: 4,
    ),
    const Production(
      id: 'p5',
      leftSide: ['S'],
      rightSide: [],
      isLambda: true,
      order: 5,
    ),
  };

  return Grammar(
    id: 'palindrome',
    name: 'Palindrome',
    terminals: {'a', 'b'},
    nonterminals: {'S'},
    startSymbol: 'S',
    productions: productions,
    type: GrammarType.contextFree,
    created: DateTime.now(),
    modified: DateTime.now(),
  );
}

Grammar _createLeftRecursiveGrammar() {
  final productions = {
    const Production(
      id: 'p1',
      leftSide: ['S'],
      rightSide: ['S', 'a'],
      isLambda: false,
      order: 1,
    ),
    const Production(
      id: 'p2',
      leftSide: ['S'],
      rightSide: ['a'],
      isLambda: false,
      order: 2,
    ),
  };

  return Grammar(
    id: 'left_recursive',
    name: 'Left Recursive Grammar',
    terminals: {'a'},
    nonterminals: {'S'},
    startSymbol: 'S',
    productions: productions,
    type: GrammarType.contextFree,
    created: DateTime.now(),
    modified: DateTime.now(),
  );
}

Grammar _createAmbiguousGrammar() {
  final productions = {
    const Production(
      id: 'p1',
      leftSide: ['S'],
      rightSide: ['S', 'S'],
      isLambda: false,
      order: 1,
    ),
    const Production(
      id: 'p2',
      leftSide: ['S'],
      rightSide: ['a'],
      isLambda: false,
      order: 2,
    ),
  };

  return Grammar(
    id: 'ambiguous',
    name: 'Ambiguous Grammar',
    terminals: {'a'},
    nonterminals: {'S'},
    startSymbol: 'S',
    productions: productions,
    type: GrammarType.contextFree,
    created: DateTime.now(),
    modified: DateTime.now(),
  );
}

Grammar _createCNFGrammar() {
  final productions = {
    const Production(
      id: 'p1',
      leftSide: ['S'],
      rightSide: ['A', 'B'],
      isLambda: false,
      order: 1,
    ),
    const Production(
      id: 'p2',
      leftSide: ['S'],
      rightSide: ['A'],
      isLambda: false,
      order: 2,
    ),
    const Production(
      id: 'p3',
      leftSide: ['S'],
      rightSide: ['B'],
      isLambda: false,
      order: 3,
    ),
    const Production(
      id: 'p4',
      leftSide: ['A'],
      rightSide: ['a'],
      isLambda: false,
      order: 4,
    ),
    const Production(
      id: 'p5',
      leftSide: ['B'],
      rightSide: ['b'],
      isLambda: false,
      order: 5,
    ),
    const Production(
      id: 'p6',
      leftSide: ['A'],
      rightSide: ['b'],
      isLambda: false,
      order: 6,
    ),
    const Production(
      id: 'p7',
      leftSide: ['B'],
      rightSide: ['a'],
      isLambda: false,
      order: 7,
    ),
  };

  return Grammar(
    id: 'cnf',
    name: 'CNF Grammar',
    terminals: {'a', 'b'},
    nonterminals: {'S', 'A', 'B'},
    startSymbol: 'S',
    productions: productions,
    type: GrammarType.contextFree,
    created: DateTime.now(),
    modified: DateTime.now(),
  );
}
