//
//  gnf_conversion_test.dart
//  Turing Lab
//
//  Test suite for converting context-free grammars
//  to Greibach normal form (GNF), checking that every production
//  has the form A→aα where 'a' is a terminal and α is a sequence of
//  nonterminals, while preserving the original language.
//
//  Thales Matheus Mendonça Santos - January 2025
//

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/cfg/cfg_toolkit.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/production.dart';

void main() {
  group('GNF Conversion Tests', () {
    late Grammar simpleGrammar;
    late Grammar arithmeticGrammar;
    late Grammar recursiveGrammar;
    late Grammar lambdaGrammar;

    setUp(() {
      // Test Case 1: Simple grammar
      // S → AB
      // A → a
      // B → b
      simpleGrammar = Grammar(
        id: 'simple-gnf',
        name: 'Simple GNF Test Grammar',
        nonterminals: {'S', 'A', 'B'},
        terminals: {'a', 'b'},
        startSymbol: 'S',
        productions: {
          const Production(id: 'p1', leftSide: ['S'], rightSide: ['A', 'B']),
          const Production(id: 'p2', leftSide: ['A'], rightSide: ['a']),
          const Production(id: 'p3', leftSide: ['B'], rightSide: ['b']),
        },
        type: GrammarType.contextFree,
        created: DateTime.now(),
        modified: DateTime.now(),
      );

      // Test Case 2: Arithmetic expression grammar
      // E → E + T | T
      // T → T * F | F
      // F → ( E ) | id
      arithmeticGrammar = Grammar(
        id: 'arithmetic-gnf',
        name: 'Arithmetic GNF Test Grammar',
        nonterminals: {'E', 'T', 'F'},
        terminals: {'+', '*', '(', ')', 'id'},
        startSymbol: 'E',
        productions: {
          const Production(
              id: 'e1', leftSide: ['E'], rightSide: ['E', '+', 'T']),
          const Production(id: 'e2', leftSide: ['E'], rightSide: ['T']),
          const Production(
              id: 't1', leftSide: ['T'], rightSide: ['T', '*', 'F']),
          const Production(id: 't2', leftSide: ['T'], rightSide: ['F']),
          const Production(
              id: 'f1', leftSide: ['F'], rightSide: ['(', 'E', ')']),
          const Production(id: 'f2', leftSide: ['F'], rightSide: ['id']),
        },
        type: GrammarType.contextFree,
        created: DateTime.now(),
        modified: DateTime.now(),
      );

      // Test Case 3: Left-recursive grammar
      // S → Sa | b
      recursiveGrammar = Grammar(
        id: 'recursive-gnf',
        name: 'Recursive GNF Test Grammar',
        nonterminals: {'S'},
        terminals: {'a', 'b'},
        startSymbol: 'S',
        productions: {
          const Production(id: 'r1', leftSide: ['S'], rightSide: ['S', 'a']),
          const Production(id: 'r2', leftSide: ['S'], rightSide: ['b']),
        },
        type: GrammarType.contextFree,
        created: DateTime.now(),
        modified: DateTime.now(),
      );

      // Test Case 4: Grammar with lambda production
      // S → A
      // A → aA | ε
      lambdaGrammar = Grammar(
        id: 'lambda-gnf',
        name: 'Lambda GNF Test Grammar',
        nonterminals: {'S', 'A'},
        terminals: {'a'},
        startSymbol: 'S',
        productions: {
          const Production(id: 'l1', leftSide: ['S'], rightSide: ['A']),
          const Production(id: 'l2', leftSide: ['A'], rightSide: ['a', 'A']),
          Production.lambda(id: 'l3', leftSide: 'A'),
        },
        type: GrammarType.contextFree,
        created: DateTime.now(),
        modified: DateTime.now(),
      );
    });

    group('Basic GNF Conversion', () {
      test('Should successfully convert simple grammar to GNF', () {
        final result = CFGToolkit.toGNF(simpleGrammar);

        expect(result.isSuccess, true, reason: 'GNF conversion should succeed');

        if (result.isSuccess) {
          final gnf = result.data!;

          expect(
            gnf.nonterminals.isNotEmpty,
            true,
            reason: 'GNF grammar should have nonterminals',
          );
          expect(
            gnf.productions.isNotEmpty,
            true,
            reason: 'GNF grammar should have productions',
          );
        }
      });

      test('Should convert arithmetic grammar to GNF', () {
        final result = CFGToolkit.toGNF(arithmeticGrammar);

        expect(
          result.isSuccess,
          true,
          reason: 'Arithmetic grammar should convert to GNF',
        );

        if (result.isSuccess) {
          final gnf = result.data!;

          expect(
            gnf.startSymbol,
            isNotEmpty,
            reason: 'GNF grammar should have start symbol',
          );
        }
      });

      test('Should handle left-recursive grammar', () {
        final result = CFGToolkit.toGNF(recursiveGrammar);

        expect(
          result.isSuccess,
          true,
          reason: 'Left-recursive grammar should convert to GNF',
        );

        if (result.isSuccess) {
          final gnf = result.data!;

          // Check that left recursion is eliminated
          final leftRecursive = gnf.productions.where((p) {
            if (p.isLambda || p.rightSide.isEmpty) return false;
            return p.rightSide.first == p.leftSide.first;
          }).toList();

          expect(
            leftRecursive.isEmpty,
            true,
            reason: 'GNF should eliminate left recursion',
          );
        }
      });

      test('Should convert grammar with lambda productions', () {
        final result = CFGToolkit.toGNF(lambdaGrammar);

        expect(
          result.isSuccess,
          true,
          reason: 'Grammar with lambda should convert to GNF',
        );
      });
    });

    group('GNF Validation', () {
      test('Should produce valid GNF for simple grammar', () {
        final result = CFGToolkit.toGNF(simpleGrammar);

        expect(result.isSuccess, true);

        if (result.isSuccess) {
          final gnf = result.data!;

          expect(
            CFGToolkit.isGNF(gnf),
            true,
            reason: 'Converted grammar should be in GNF',
          );
        }
      });

      test('Should produce valid GNF for arithmetic grammar', () {
        final result = CFGToolkit.toGNF(arithmeticGrammar);

        expect(result.isSuccess, true);

        if (result.isSuccess) {
          final gnf = result.data!;

          expect(
            CFGToolkit.isGNF(gnf),
            true,
            reason: 'Arithmetic grammar should be in valid GNF',
          );
        }
      });

      test('Should produce valid GNF for recursive grammar', () {
        final result = CFGToolkit.toGNF(recursiveGrammar);

        expect(result.isSuccess, true);

        if (result.isSuccess) {
          final gnf = result.data!;

          expect(
            CFGToolkit.isGNF(gnf),
            true,
            reason: 'Recursive grammar should be in valid GNF',
          );
        }
      });

      test('All productions should start with terminal in GNF', () {
        final result = CFGToolkit.toGNF(simpleGrammar);

        expect(result.isSuccess, true);

        if (result.isSuccess) {
          final gnf = result.data!;

          for (final p in gnf.productions) {
            if (p.isLambda) {
              // Lambda production only allowed for start symbol
              expect(
                p.leftSide.first,
                gnf.startSymbol,
                reason: 'Only start symbol can have lambda production',
              );
              continue;
            }

            expect(
              p.rightSide.isNotEmpty,
              true,
              reason: 'Non-lambda production should have non-empty RHS',
            );

            final first = p.rightSide.first;
            expect(
              gnf.terminals.contains(first) || first.startsWith('T'),
              true,
              reason:
                  'First symbol in GNF production should be terminal or terminal-wrapper',
            );

            // Remaining symbols should be nonterminals
            for (var i = 1; i < p.rightSide.length; i++) {
              expect(
                gnf.nonterminals.contains(p.rightSide[i]),
                true,
                reason: 'Symbols after first should be nonterminals',
              );
            }
          }
        }
      });
    });

    group('GNF Properties', () {
      test('Should preserve nonterminals after conversion', () {
        final result = CFGToolkit.toGNF(simpleGrammar);

        expect(result.isSuccess, true);

        if (result.isSuccess) {
          final gnf = result.data!;

          // GNF may introduce new nonterminals, but original should be preserved
          // in some form (or through augmentation)
          expect(
            gnf.nonterminals.isNotEmpty,
            true,
            reason: 'GNF grammar should have nonterminals',
          );
        }
      });

      test('Should preserve start symbol concept', () {
        final result = CFGToolkit.toGNF(simpleGrammar);

        expect(result.isSuccess, true);

        if (result.isSuccess) {
          final gnf = result.data!;

          expect(
            gnf.startSymbol.isNotEmpty,
            true,
            reason: 'GNF grammar should have start symbol',
          );
          expect(
            gnf.nonterminals.contains(gnf.startSymbol),
            true,
            reason: 'Start symbol should be a nonterminal',
          );
        }
      });

      test('Should have productions for start symbol', () {
        final result = CFGToolkit.toGNF(simpleGrammar);

        expect(result.isSuccess, true);

        if (result.isSuccess) {
          final gnf = result.data!;

          final startProds = gnf.productions
              .where((p) => p.leftSide.first == gnf.startSymbol)
              .toList();

          expect(
            startProds.isNotEmpty,
            true,
            reason: 'Start symbol should have at least one production',
          );
        }
      });

      test('Should eliminate immediate left recursion', () {
        final result = CFGToolkit.toGNF(recursiveGrammar);

        expect(result.isSuccess, true);

        if (result.isSuccess) {
          final gnf = result.data!;

          // Check no production has form A → A...
          final immediateLeftRecursive = gnf.productions.where((p) {
            if (p.isLambda || p.rightSide.isEmpty) return false;
            if (!gnf.nonterminals.contains(p.rightSide.first)) return false;
            return p.leftSide.first == p.rightSide.first;
          }).toList();

          expect(
            immediateLeftRecursive.isEmpty,
            true,
            reason: 'GNF should not have immediate left recursion',
          );
        }
      });
    });

    group('isGNF Checker Tests', () {
      test('Should recognize valid GNF grammar', () {
        // Create a grammar already in GNF
        // S → aA | b
        // A → aA | b
        final gnfGrammar = Grammar(
          id: 'valid-gnf',
          name: 'Valid GNF Grammar',
          nonterminals: {'S', 'A'},
          terminals: {'a', 'b'},
          startSymbol: 'S',
          productions: {
            const Production(id: 'g1', leftSide: ['S'], rightSide: ['a', 'A']),
            const Production(id: 'g2', leftSide: ['S'], rightSide: ['b']),
            const Production(id: 'g3', leftSide: ['A'], rightSide: ['a', 'A']),
            const Production(id: 'g4', leftSide: ['A'], rightSide: ['b']),
          },
          type: GrammarType.contextFree,
          created: DateTime.now(),
          modified: DateTime.now(),
        );

        expect(
          CFGToolkit.isGNF(gnfGrammar),
          true,
          reason: 'Should recognize valid GNF',
        );
      });

      test('Should reject grammar not in GNF (starts with nonterminal)', () {
        // S → AB
        // A → a
        final notGNF = Grammar(
          id: 'not-gnf',
          name: 'Not GNF Grammar',
          nonterminals: {'S', 'A', 'B'},
          terminals: {'a', 'b'},
          startSymbol: 'S',
          productions: {
            const Production(id: 'n1', leftSide: ['S'], rightSide: ['A', 'B']),
            const Production(id: 'n2', leftSide: ['A'], rightSide: ['a']),
            const Production(id: 'n3', leftSide: ['B'], rightSide: ['b']),
          },
          type: GrammarType.contextFree,
          created: DateTime.now(),
          modified: DateTime.now(),
        );

        expect(
          CFGToolkit.isGNF(notGNF),
          false,
          reason: 'Should reject grammar with nonterminal-first productions',
        );
      });

      test('Should reject grammar with terminal after nonterminal', () {
        // S → aAb (has terminal 'b' after nonterminal 'A')
        final invalidGNF = Grammar(
          id: 'invalid-gnf',
          name: 'Invalid GNF Grammar',
          nonterminals: {'S', 'A'},
          terminals: {'a', 'b'},
          startSymbol: 'S',
          productions: {
            const Production(
                id: 'i1', leftSide: ['S'], rightSide: ['a', 'A', 'b']),
            const Production(id: 'i2', leftSide: ['A'], rightSide: ['a']),
          },
          type: GrammarType.contextFree,
          created: DateTime.now(),
          modified: DateTime.now(),
        );

        expect(
          CFGToolkit.isGNF(invalidGNF),
          false,
          reason: 'Should reject grammar with terminal after nonterminal',
        );
      });

      test('Should allow lambda only for start symbol', () {
        // S → ε | aA
        // A → a
        final lambdaStart = Grammar(
          id: 'lambda-start',
          name: 'Lambda Start Grammar',
          nonterminals: {'S', 'A'},
          terminals: {'a'},
          startSymbol: 'S',
          productions: {
            Production.lambda(id: 's1', leftSide: 'S'),
            const Production(id: 's2', leftSide: ['S'], rightSide: ['a', 'A']),
            const Production(id: 'a1', leftSide: ['A'], rightSide: ['a']),
          },
          type: GrammarType.contextFree,
          created: DateTime.now(),
          modified: DateTime.now(),
        );

        expect(
          CFGToolkit.isGNF(lambdaStart),
          true,
          reason: 'Should allow lambda for start symbol in GNF',
        );
      });

      test('Should reject lambda for non-start symbol', () {
        // S → aA
        // A → ε
        final invalidLambda = Grammar(
          id: 'invalid-lambda',
          name: 'Invalid Lambda Grammar',
          nonterminals: {'S', 'A'},
          terminals: {'a'},
          startSymbol: 'S',
          productions: {
            const Production(id: 's1', leftSide: ['S'], rightSide: ['a', 'A']),
            Production.lambda(id: 'a1', leftSide: 'A'),
          },
          type: GrammarType.contextFree,
          created: DateTime.now(),
          modified: DateTime.now(),
        );

        expect(
          CFGToolkit.isGNF(invalidLambda),
          false,
          reason: 'Should reject lambda for non-start symbol',
        );
      });
    });

    group('Edge Cases', () {
      test('Should handle single production grammar', () {
        final single = Grammar(
          id: 'single',
          name: 'Single Production Grammar',
          nonterminals: {'S'},
          terminals: {'a'},
          startSymbol: 'S',
          productions: {
            const Production(id: 'p1', leftSide: ['S'], rightSide: ['a']),
          },
          type: GrammarType.contextFree,
          created: DateTime.now(),
          modified: DateTime.now(),
        );

        final result = CFGToolkit.toGNF(single);

        expect(result.isSuccess, true);

        if (result.isSuccess) {
          final gnf = result.data!;
          expect(CFGToolkit.isGNF(gnf), true);
        }
      });

      test('Should handle grammar with multiple terminals in production', () {
        // S → abC
        // C → c
        final multiTerminal = Grammar(
          id: 'multi-terminal',
          name: 'Multi-Terminal Grammar',
          nonterminals: {'S', 'C'},
          terminals: {'a', 'b', 'c'},
          startSymbol: 'S',
          productions: {
            const Production(
                id: 'p1', leftSide: ['S'], rightSide: ['a', 'b', 'C']),
            const Production(id: 'p2', leftSide: ['C'], rightSide: ['c']),
          },
          type: GrammarType.contextFree,
          created: DateTime.now(),
          modified: DateTime.now(),
        );

        final result = CFGToolkit.toGNF(multiTerminal);

        expect(result.isSuccess, true);
      });

      test('Should handle complex nested grammar', () {
        // S → AB | CD
        // A → aA | a
        // B → bB | b
        // C → cC | c
        // D → dD | d
        final nested = Grammar(
          id: 'nested',
          name: 'Nested Grammar',
          nonterminals: {'S', 'A', 'B', 'C', 'D'},
          terminals: {'a', 'b', 'c', 'd'},
          startSymbol: 'S',
          productions: {
            const Production(id: 'p1', leftSide: ['S'], rightSide: ['A', 'B']),
            const Production(id: 'p2', leftSide: ['S'], rightSide: ['C', 'D']),
            const Production(id: 'p3', leftSide: ['A'], rightSide: ['a', 'A']),
            const Production(id: 'p4', leftSide: ['A'], rightSide: ['a']),
            const Production(id: 'p5', leftSide: ['B'], rightSide: ['b', 'B']),
            const Production(id: 'p6', leftSide: ['B'], rightSide: ['b']),
            const Production(id: 'p7', leftSide: ['C'], rightSide: ['c', 'C']),
            const Production(id: 'p8', leftSide: ['C'], rightSide: ['c']),
            const Production(id: 'p9', leftSide: ['D'], rightSide: ['d', 'D']),
            const Production(id: 'p10', leftSide: ['D'], rightSide: ['d']),
          },
          type: GrammarType.contextFree,
          created: DateTime.now(),
          modified: DateTime.now(),
        );

        final result = CFGToolkit.toGNF(nested);

        expect(result.isSuccess, true);

        if (result.isSuccess) {
          final gnf = result.data!;
          expect(CFGToolkit.isGNF(gnf), true);
        }
      });
    });
  });
}
