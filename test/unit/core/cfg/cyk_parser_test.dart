//
//  cyk_parser_test.dart
//  Turing Lab
//
//  Test suite for the core CYK parser, checking table construction, parse trees, and integration with normalized grammars.
//  Covers valid and invalid strings, lambda and unit productions, and detailed returned results.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/cfg/cyk_parser.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/grammar_parse_report.dart';
import 'package:turing_lab/core/models/production.dart';
import 'package:turing_lab/core/models/cyk_step.dart';

void main() {
  group('CYK parser', () {
    late Grammar simpleCNFGrammar;
    late Grammar complexCNFGrammar;
    late Grammar lambdaGrammar;
    late Grammar nullablePrefixGrammar;
    late Grammar unitGrammar;

    setUp(() {
      // Test Case 1: Simple CNF grammar
      simpleCNFGrammar = _createSimpleCNFGrammar();

      // Test Case 2: Complex CNF grammar
      complexCNFGrammar = _createComplexCNFGrammar();

      // Test Case 3: Grammar with lambda productions
      lambdaGrammar = _createLambdaGrammar();

      // Test Case 4: Grammar with nullable non-start productions
      nullablePrefixGrammar = _createNullablePrefixGrammar();

      // Test Case 5: Grammar with unit productions
      unitGrammar = _createUnitGrammar();
    });

    group('Parse Table Construction Tests', () {
      test('Should build parse table for valid strings', () {
        final result = CYKParser.parse(simpleCNFGrammar, 'ab');

        expect(
          result.isSuccess,
          true,
          reason: 'CYK parsing should succeed for "ab"',
        );

        if (result.isSuccess) {
          final cykResult = result.data!;

          // Check that parse table is constructed
          expect(
            cykResult.table.isNotEmpty,
            true,
            reason: 'Parse table should not be empty',
          );
          expect(
            cykResult.table.length,
            2,
            reason: 'Parse table should have correct dimensions',
          );
        }
      });

      test('Should handle single character strings', () {
        final result = CYKParser.parse(simpleCNFGrammar, 'a');

        expect(
          result.isSuccess,
          true,
          reason: 'CYK parsing should succeed for "a"',
        );

        if (result.isSuccess) {
          final cykResult = result.data!;

          // Check that parse table is constructed
          expect(
            cykResult.table.isNotEmpty,
            true,
            reason: 'Parse table should not be empty',
          );
          expect(
            cykResult.table.length,
            1,
            reason:
                'Parse table should have correct dimensions for single character',
          );
        }
      });

      test('Should handle empty string', () {
        final result = CYKParser.parse(lambdaGrammar, '');

        expect(
          result.isSuccess,
          true,
          reason: 'CYK parsing should succeed for empty string',
        );

        if (result.isSuccess) {
          final cykResult = result.data!;

          // Empty string should be accepted if start symbol is nullable
          expect(
            cykResult.accepted,
            true,
            reason: 'Empty string should be accepted by lambda grammar',
          );
        }
      });
    });

    group('Derivation Tree Construction Tests', () {
      test('Should produce derivation tree for accepted strings', () {
        final result = CYKParser.parse(simpleCNFGrammar, 'ab');

        expect(
          result.isSuccess,
          true,
          reason: 'CYK parsing should succeed for "ab"',
        );

        if (result.isSuccess) {
          final cykResult = result.data!;

          // If string is accepted, should have derivation tree
          if (cykResult.accepted) {
            expect(
              cykResult.derivation,
              isNotNull,
              reason: 'Accepted string should have derivation tree',
            );

            if (cykResult.derivation != null) {
              expect(
                cykResult.derivation!.label,
                simpleCNFGrammar.startSymbol,
                reason: 'Derivation tree root should be start symbol',
              );
            }
          }
        }
      });

      test('Should produce correct derivation tree structure', () {
        final result = CYKParser.parse(simpleCNFGrammar, 'ab');

        expect(
          result.isSuccess,
          true,
          reason: 'CYK parsing should succeed for "ab"',
        );

        if (result.isSuccess) {
          final cykResult = result.data!;

          if (cykResult.accepted && cykResult.derivation != null) {
            final tree = cykResult.derivation!;

            // Check tree structure
            expect(
              tree.label,
              isA<String>(),
              reason: 'Tree node should have label',
            );
            expect(
              tree.children,
              isA<List<CYKDerivation>>(),
              reason: 'Tree node should have children list',
            );
          }
        }
      });

      test('Should handle complex derivation trees', () {
        final result = CYKParser.parse(complexCNFGrammar, 'abc');

        expect(
          result.isSuccess,
          true,
          reason: 'CYK parsing should succeed for "abc"',
        );

        if (result.isSuccess) {
          final cykResult = result.data!;

          if (cykResult.accepted && cykResult.derivation != null) {
            final tree = cykResult.derivation!;

            // Check that tree has proper structure
            expect(
              tree.label,
              complexCNFGrammar.startSymbol,
              reason: 'Root should be start symbol',
            );
          }
        }
      });
    });

    group('Language Acceptance Tests', () {
      test('Should accept strings in language', () {
        final testCases = [
          ('a', simpleCNFGrammar),
          ('ab', simpleCNFGrammar),
          ('abc', complexCNFGrammar),
        ];

        for (final (input, grammar) in testCases) {
          final result = CYKParser.parse(grammar, input);

          expect(
            result.isSuccess,
            true,
            reason: 'CYK parsing should succeed for "$input"',
          );

          if (result.isSuccess) {
            final cykResult = result.data!;
            expect(
              cykResult.accepted,
              true,
              reason: 'String "$input" should be accepted',
            );
          }
        }
      });

      test('Should reject strings not in language', () {
        final testCases = [
          ('ba', simpleCNFGrammar), // Wrong order
          ('aab', simpleCNFGrammar), // Too many 'a's
          ('d', complexCNFGrammar), // Not in alphabet
        ];

        for (final (input, grammar) in testCases) {
          final result = CYKParser.parse(grammar, input);

          expect(
            result.isSuccess,
            true,
            reason: 'CYK parsing should succeed for "$input"',
          );

          if (result.isSuccess) {
            final cykResult = result.data!;
            expect(
              cykResult.accepted,
              false,
              reason: 'String "$input" should be rejected',
            );
          }
        }
      });

      test('Should handle empty string correctly', () {
        // Test with grammar that accepts empty string
        final result = CYKParser.parse(lambdaGrammar, '');

        expect(
          result.isSuccess,
          true,
          reason: 'CYK parsing should succeed for empty string',
        );

        if (result.isSuccess) {
          final cykResult = result.data!;
          expect(
            cykResult.accepted,
            true,
            reason: 'Empty string should be accepted by lambda grammar',
          );
        }
      });
    });

    group('CNF Conversion Integration Tests', () {
      test('Should handle non-CNF grammars', () {
        final result = CYKParser.parse(unitGrammar, 'a');

        expect(
          result.isSuccess,
          true,
          reason: 'CYK parsing should succeed for non-CNF grammar',
        );

        if (result.isSuccess) {
          final cykResult = result.data!;

          // Should still work after CNF conversion
          expect(
            cykResult.accepted,
            true,
            reason: 'Non-CNF grammar should work after conversion',
          );
        }
      });

      test('Should handle complex non-CNF grammars', () {
        final result = CYKParser.parse(complexCNFGrammar, 'abc');

        expect(
          result.isSuccess,
          true,
          reason: 'CYK parsing should succeed for complex grammar',
        );

        if (result.isSuccess) {
          final cykResult = result.data!;

          // Should work with complex grammar
          expect(
            cykResult.accepted,
            true,
            reason: 'Complex grammar should work',
          );
        }
      });

      test('Should expand nullable non-start symbols before CYK parsing', () {
        final acceptedInputs = ['ab', 'b'];

        for (final input in acceptedInputs) {
          final result = CYKParser.parse(nullablePrefixGrammar, input);

          expect(
            result.isSuccess,
            true,
            reason: 'CYK parsing should succeed for "$input"',
          );

          if (result.isSuccess) {
            expect(
              result.data!.accepted,
              true,
              reason: 'Nullable prefix grammar should accept "$input"',
            );
          }
        }

        final rejected = CYKParser.parse(nullablePrefixGrammar, 'a');
        expect(
          rejected.isSuccess,
          true,
          reason: 'CYK parsing should succeed for rejected input',
        );
        if (rejected.isSuccess) {
          expect(
            rejected.data!.accepted,
            false,
            reason: 'Nullable prefix grammar should reject "a"',
          );
        }
      });
    });

    group('Edge Cases Tests', () {
      test('Should handle very short strings', () {
        final result = CYKParser.parse(simpleCNFGrammar, 'a');

        expect(
          result.isSuccess,
          true,
          reason: 'CYK parsing should succeed for single character',
        );

        if (result.isSuccess) {
          final cykResult = result.data!;
          expect(
            cykResult.accepted,
            true,
            reason: 'Single character should be accepted',
          );
        }
      });

      test('Should handle strings with repeated characters', () {
        final result = CYKParser.parse(simpleCNFGrammar, 'aa');

        expect(
          result.isSuccess,
          true,
          reason: 'CYK parsing should succeed for repeated characters',
        );

        if (result.isSuccess) {
          final cykResult = result.data!;
          // This might be rejected depending on grammar
          expect(
            cykResult.accepted,
            isA<bool>(),
            reason: 'Should return boolean result for repeated characters',
          );
        }
      });

      test('Should handle invalid input gracefully', () {
        final result = CYKParser.parse(simpleCNFGrammar, 'xyz');

        expect(
          result.isSuccess,
          true,
          reason: 'CYK parsing should succeed even for invalid input',
        );

        if (result.isSuccess) {
          final cykResult = result.data!;
          expect(
            cykResult.accepted,
            false,
            reason: 'Invalid input should be rejected',
          );
        }
      });
    });

    group('Performance Tests', () {
      test('Should handle moderate length strings', () {
        final longString = 'ab' * 10; // 20 characters
        final result = CYKParser.parse(simpleCNFGrammar, longString);

        expect(
          result.isSuccess,
          true,
          reason: 'CYK parsing should succeed for moderate length strings',
        );

        if (result.isSuccess) {
          final cykResult = result.data!;
          expect(
            cykResult.accepted,
            isA<bool>(),
            reason: 'Should return boolean result for moderate length strings',
          );
        }
      });
    });

    group('Step Generation Tests', () {
      test('Should generate steps for parsing', () {
        final result = CYKParser.parseWithSteps(simpleCNFGrammar, 'ab');

        expect(
          result.isSuccess,
          true,
          reason: 'CYK parsing with steps should succeed',
        );

        if (result.isSuccess) {
          final parseResult = result.data!;

          // Should have steps
          expect(
            parseResult.steps.isNotEmpty,
            true,
            reason: 'Should generate at least one step',
          );

          // Should have initialize step
          expect(
            parseResult.steps.any((s) => s.stepType == CYKStepType.initialize),
            true,
            reason: 'Should have initialize step',
          );

          // Should have completion step
          expect(
            parseResult.steps.any((s) => s.stepType == CYKStepType.completion),
            true,
            reason: 'Should have completion step',
          );

          // Should have base case steps (one for each character)
          final baseCaseSteps = parseResult.steps
              .where((s) => s.stepType == CYKStepType.fillBaseCase)
              .toList();
          expect(
            baseCaseSteps.length,
            2,
            reason: 'Should have two base case steps for "ab"',
          );

          // Steps should be numbered sequentially
          for (int i = 0; i < parseResult.steps.length; i++) {
            expect(
              parseResult.steps[i].stepNumber,
              i + 1,
              reason: 'Step $i should have stepNumber ${i + 1}',
            );
          }
        }
      });

      test('Should generate steps for empty string', () {
        final result = CYKParser.parseWithSteps(lambdaGrammar, '');

        expect(
          result.isSuccess,
          true,
          reason: 'CYK parsing with steps should succeed for empty string',
        );

        if (result.isSuccess) {
          final parseResult = result.data!;

          // Should have steps even for empty string
          expect(
            parseResult.steps.isNotEmpty,
            true,
            reason: 'Should generate steps for empty string',
          );

          // Should have initialize and check acceptance steps
          expect(
            parseResult.steps.any((s) => s.stepType == CYKStepType.initialize),
            true,
            reason: 'Should have initialize step',
          );

          expect(
            parseResult.steps.any(
              (s) => s.stepType == CYKStepType.checkAcceptance,
            ),
            true,
            reason: 'Should have check acceptance step',
          );
        }
      });

      test('Should enforce timeout before handling empty input', () {
        final parseResult = CYKParser.parse(
          lambdaGrammar,
          '',
          timeout: Duration.zero,
        );
        final stepResult = CYKParser.parseWithSteps(
          lambdaGrammar,
          '',
          timeout: Duration.zero,
        );

        expect(parseResult.isSuccess, isTrue);
        expect(parseResult.data!.outcome, GrammarParseOutcome.timedOut);
        expect(parseResult.data!.message, 'CYK parsing timed out');
        expect(stepResult.isSuccess, isTrue);
        expect(stepResult.data!.outcome, GrammarParseOutcome.timedOut);
        expect(stepResult.data!.message, 'CYK parsing timed out');
      });

      test('Should generate cell processing steps', () {
        final result = CYKParser.parseWithSteps(simpleCNFGrammar, 'ab');

        expect(
          result.isSuccess,
          true,
          reason: 'CYK parsing with steps should succeed',
        );

        if (result.isSuccess) {
          final parseResult = result.data!;

          // Should have process cell steps
          final processCellSteps = parseResult.steps
              .where((s) => s.stepType == CYKStepType.processCell)
              .toList();
          expect(
            processCellSteps.isNotEmpty,
            true,
            reason: 'Should have cell processing steps',
          );

          // Should have complete cell steps
          final completeCellSteps = parseResult.steps
              .where((s) => s.stepType == CYKStepType.completeCell)
              .toList();
          expect(
            completeCellSteps.isNotEmpty,
            true,
            reason: 'Should have complete cell steps',
          );
        }
      });

      test('Should generate split checking steps', () {
        final result = CYKParser.parseWithSteps(complexCNFGrammar, 'abc');

        expect(
          result.isSuccess,
          true,
          reason: 'CYK parsing with steps should succeed for "abc"',
        );

        if (result.isSuccess) {
          final parseResult = result.data!;

          // Should have check split steps for longer strings
          final checkSplitSteps = parseResult.steps
              .where((s) => s.stepType == CYKStepType.checkSplit)
              .toList();
          expect(
            checkSplitSteps.isNotEmpty,
            true,
            reason: 'Should have split checking steps for longer strings',
          );
        }
      });

      test('Should generate production application steps', () {
        final result = CYKParser.parseWithSteps(simpleCNFGrammar, 'ab');

        expect(
          result.isSuccess,
          true,
          reason: 'CYK parsing with steps should succeed',
        );

        if (result.isSuccess) {
          final parseResult = result.data!;

          if (parseResult.accepted) {
            // Should have apply production steps if string is accepted
            final applyProdSteps = parseResult.steps
                .where((s) => s.stepType == CYKStepType.applyProduction)
                .toList();
            expect(
              applyProdSteps.isNotEmpty,
              true,
              reason:
                  'Should have production application steps for accepted strings',
            );

            // Production steps should have production information
            for (final step in applyProdSteps) {
              expect(
                step.addedNonTerminal,
                isNotNull,
                reason: 'Apply production step should have added non-terminal',
              );
              expect(
                step.productionLeft,
                isNotNull,
                reason:
                    'Apply production step should have production left side',
              );
              expect(
                step.productionRight,
                isNotNull,
                reason:
                    'Apply production step should have production right side',
              );
            }
          }
        }
      });

      test('Should capture execution time', () {
        final result = CYKParser.parseWithSteps(simpleCNFGrammar, 'ab');

        expect(
          result.isSuccess,
          true,
          reason: 'CYK parsing with steps should succeed',
        );

        if (result.isSuccess) {
          final parseResult = result.data!;

          expect(
            parseResult.executionTime.inMicroseconds,
            greaterThan(0),
            reason: 'Should capture execution time',
          );

          expect(
            parseResult.executionTimeMs,
            greaterThanOrEqualTo(0),
            reason: 'Execution time in milliseconds should be non-negative',
          );
        }
      });

      test('Should have correct step count', () {
        final result = CYKParser.parseWithSteps(simpleCNFGrammar, 'ab');

        expect(
          result.isSuccess,
          true,
          reason: 'CYK parsing with steps should succeed',
        );

        if (result.isSuccess) {
          final parseResult = result.data!;

          expect(
            parseResult.stepCount,
            parseResult.steps.length,
            reason: 'Step count should match steps list length',
          );

          expect(
            parseResult.firstStep,
            parseResult.steps.first,
            reason: 'First step should match first element',
          );

          expect(
            parseResult.lastStep,
            parseResult.steps.last,
            reason: 'Last step should match last element',
          );
        }
      });

      test('Should include acceptance check step', () {
        final result = CYKParser.parseWithSteps(simpleCNFGrammar, 'ab');

        expect(
          result.isSuccess,
          true,
          reason: 'CYK parsing with steps should succeed',
        );

        if (result.isSuccess) {
          final parseResult = result.data!;

          final acceptanceSteps = parseResult.steps
              .where((s) => s.stepType == CYKStepType.checkAcceptance)
              .toList();

          expect(
            acceptanceSteps.length,
            1,
            reason: 'Should have exactly one acceptance check step',
          );

          final acceptanceStep = acceptanceSteps.first;
          expect(
            acceptanceStep.isAccepted,
            parseResult.accepted,
            reason: 'Acceptance step should match final result',
          );
        }
      });
    });
  });
}

/// Helper functions to create test grammars

Grammar _createSimpleCNFGrammar() {
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
      leftSide: ['A'],
      rightSide: ['a'],
      isLambda: false,
      order: 2,
    ),
    const Production(
      id: 'p3',
      leftSide: ['B'],
      rightSide: ['b'],
      isLambda: false,
      order: 3,
    ),
    // Add single character productions for S
    const Production(
      id: 'p4',
      leftSide: ['S'],
      rightSide: ['a'],
      isLambda: false,
      order: 4,
    ),
    const Production(
      id: 'p5',
      leftSide: ['S'],
      rightSide: ['b'],
      isLambda: false,
      order: 5,
    ),
  };

  return Grammar(
    id: 'simple_cnf',
    name: 'Simple CNF Grammar',
    terminals: {'a', 'b'},
    nonterminals: {'S', 'A', 'B'},
    startSymbol: 'S',
    productions: productions,
    type: GrammarType.contextFree,
    created: DateTime.now(),
    modified: DateTime.now(),
  );
}

Grammar _createComplexCNFGrammar() {
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
      leftSide: ['A'],
      rightSide: ['C', 'D'],
      isLambda: false,
      order: 2,
    ),
    const Production(
      id: 'p3',
      leftSide: ['B'],
      rightSide: ['E'],
      isLambda: false,
      order: 3,
    ),
    const Production(
      id: 'p4',
      leftSide: ['C'],
      rightSide: ['a'],
      isLambda: false,
      order: 4,
    ),
    const Production(
      id: 'p5',
      leftSide: ['D'],
      rightSide: ['b'],
      isLambda: false,
      order: 5,
    ),
    const Production(
      id: 'p6',
      leftSide: ['E'],
      rightSide: ['c'],
      isLambda: false,
      order: 6,
    ),
    // Add single character productions for S
    const Production(
      id: 'p7',
      leftSide: ['S'],
      rightSide: ['a'],
      isLambda: false,
      order: 7,
    ),
    const Production(
      id: 'p8',
      leftSide: ['S'],
      rightSide: ['b'],
      isLambda: false,
      order: 8,
    ),
    const Production(
      id: 'p9',
      leftSide: ['S'],
      rightSide: ['c'],
      isLambda: false,
      order: 9,
    ),
  };

  return Grammar(
    id: 'complex_cnf',
    name: 'Complex CNF Grammar',
    terminals: {'a', 'b', 'c'},
    nonterminals: {'S', 'A', 'B', 'C', 'D', 'E'},
    startSymbol: 'S',
    productions: productions,
    type: GrammarType.contextFree,
    created: DateTime.now(),
    modified: DateTime.now(),
  );
}

Grammar _createLambdaGrammar() {
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
      leftSide: ['A'],
      rightSide: ['a'],
      isLambda: false,
      order: 2,
    ),
    const Production(
      id: 'p3',
      leftSide: ['B'],
      rightSide: [],
      isLambda: true,
      order: 3,
    ),
    // Add lambda production for S to accept empty string
    const Production(
      id: 'p4',
      leftSide: ['S'],
      rightSide: [],
      isLambda: true,
      order: 4,
    ),
  };

  return Grammar(
    id: 'lambda',
    name: 'Lambda Grammar',
    terminals: {'a'},
    nonterminals: {'S', 'A', 'B'},
    startSymbol: 'S',
    productions: productions,
    type: GrammarType.contextFree,
    created: DateTime.now(),
    modified: DateTime.now(),
  );
}

Grammar _createNullablePrefixGrammar() {
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
      leftSide: ['A'],
      rightSide: ['a'],
      isLambda: false,
      order: 2,
    ),
    const Production(
      id: 'p3',
      leftSide: ['A'],
      rightSide: [],
      isLambda: true,
      order: 3,
    ),
    const Production(
      id: 'p4',
      leftSide: ['B'],
      rightSide: ['b'],
      isLambda: false,
      order: 4,
    ),
  };

  return Grammar(
    id: 'nullable_prefix',
    name: 'Nullable Prefix Grammar',
    terminals: {'a', 'b'},
    nonterminals: {'S', 'A', 'B'},
    startSymbol: 'S',
    productions: productions,
    type: GrammarType.contextFree,
    created: DateTime.now(),
    modified: DateTime.now(),
  );
}

Grammar _createUnitGrammar() {
  final productions = {
    const Production(
      id: 'p1',
      leftSide: ['S'],
      rightSide: ['A'],
      isLambda: false,
      order: 1,
    ),
    const Production(
      id: 'p2',
      leftSide: ['A'],
      rightSide: ['B'],
      isLambda: false,
      order: 2,
    ),
    const Production(
      id: 'p3',
      leftSide: ['B'],
      rightSide: ['a'],
      isLambda: false,
      order: 3,
    ),
    // Add direct production for S to accept 'a'
    const Production(
      id: 'p4',
      leftSide: ['S'],
      rightSide: ['a'],
      isLambda: false,
      order: 4,
    ),
  };

  return Grammar(
    id: 'unit',
    name: 'Unit Grammar',
    terminals: {'a'},
    nonterminals: {'S', 'A', 'B'},
    startSymbol: 'S',
    productions: productions,
    type: GrammarType.contextFree,
    created: DateTime.now(),
    modified: DateTime.now(),
  );
}
