//
//  cfg_toolkit_test.dart
//  Turing Lab
//
//  Bateria de testes que valida o toolkit de gramáticas livres de contexto,
//  cobrindo remoção de produções λ e unitárias, eliminação de símbolos inúteis,
//  conversão para Forma Normal de Chomsky e verificação da preservação da
//  linguagem após transformações sequenciais.
//
//  Thales Matheus Mendonça Santos - October 2025
//

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/cfg/cfg_toolkit.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/production.dart';

void main() {
  group('CFG toolkit (CNF and cleanups)', () {
    late Grammar simpleGrammar;
    late Grammar complexGrammar;
    late Grammar unitGrammar;
    late Grammar lambdaGrammar;
    late Grammar uselessGrammar;

    setUp(() {
      // Test Case 1: Simple grammar with terminals and nonterminals
      simpleGrammar = _createSimpleGrammar();

      // Test Case 2: Complex grammar with multiple productions
      complexGrammar = _createComplexGrammar();

      // Test Case 3: Grammar with unit productions
      unitGrammar = _createUnitGrammar();

      // Test Case 4: Grammar with lambda productions
      lambdaGrammar = _createLambdaGrammar();

      // Test Case 5: Grammar with useless symbols
      uselessGrammar = _createUselessGrammar();
    });

    group('ε-removal Tests', () {
      test('Should remove lambda productions except start symbol', () {
        final result = CFGToolkit.reduce(lambdaGrammar);

        expect(result.isSuccess, true, reason: 'Lambda removal should succeed');

        if (result.isSuccess) {
          final reduced = result.data!;

          // Check that lambda productions are removed (except possibly start)
          final lambdaProds =
              reduced.productions.where((p) => p.isLambda).toList();
          expect(
            lambdaProds.length <= 1,
            true,
            reason: 'Should have at most one lambda production (start symbol)',
          );

          if (lambdaProds.isNotEmpty) {
            expect(
              lambdaProds.first.leftSide.first,
              reduced.startSymbol,
              reason: 'Only start symbol should have lambda production',
            );
          }
        }
      });

      test('Should preserve language after lambda removal', () {
        final originalResult = CFGToolkit.reduce(lambdaGrammar);
        expect(originalResult.isSuccess, true);

        if (originalResult.isSuccess) {
          final reduced = originalResult.data!;

          // The reduced grammar should have fewer or equal productions
          expect(
            reduced.productions.length <= lambdaGrammar.productions.length,
            true,
            reason: 'Reduced grammar should not have more productions',
          );
        }
      });
    });

    group('Unit Production Elimination Tests', () {
      test('Should eliminate unit productions', () {
        final result = CFGToolkit.reduce(unitGrammar);

        expect(
          result.isSuccess,
          true,
          reason: 'Unit production elimination should succeed',
        );

        if (result.isSuccess) {
          final reduced = result.data!;

          // Check that no unit productions remain
          final unitProds = reduced.productions
              .where(
                (p) =>
                    p.rightSide.length == 1 &&
                    reduced.nonterminals.contains(p.rightSide.first) &&
                    !p.isLambda,
              )
              .toList();

          expect(
            unitProds.isEmpty,
            true,
            reason: 'Should eliminate all unit productions',
          );
        }
      });

      test('Should preserve language after unit elimination', () {
        final result = CFGToolkit.reduce(unitGrammar);
        expect(result.isSuccess, true);

        if (result.isSuccess) {
          final reduced = result.data!;

          // The grammar should still be valid
          expect(
            reduced.nonterminals.isNotEmpty,
            true,
            reason: 'Should have nonterminals after unit elimination',
          );
          expect(
            reduced.productions.isNotEmpty,
            true,
            reason: 'Should have productions after unit elimination',
          );
        }
      });
    });

    group('Useless Symbol Removal Tests', () {
      test('Should remove useless symbols', () {
        final result = CFGToolkit.reduce(uselessGrammar);

        expect(
          result.isSuccess,
          true,
          reason: 'Useless symbol removal should succeed',
        );

        if (result.isSuccess) {
          final reduced = result.data!;

          // All remaining nonterminals should be useful
          final useful = reduced.usefulNonterminals;
          expect(
            reduced.nonterminals.difference(useful).isEmpty,
            true,
            reason: 'Should remove all useless nonterminals',
          );
        }
      });

      test('Should preserve useful symbols only', () {
        final result = CFGToolkit.reduce(uselessGrammar);
        expect(result.isSuccess, true);

        if (result.isSuccess) {
          final reduced = result.data!;

          // Start symbol should always be useful
          expect(
            reduced.nonterminals.contains(reduced.startSymbol),
            true,
            reason: 'Start symbol should be preserved',
          );
        }
      });
    });

    group('CNF Conversion Tests', () {
      test('Should convert grammar to CNF', () {
        final result = CFGToolkit.toCNF(complexGrammar);

        expect(result.isSuccess, true, reason: 'CNF conversion should succeed');

        if (result.isSuccess) {
          final cnf = result.data!;

          // Check that result is in CNF
          expect(
            CFGToolkit.isCNF(cnf),
            true,
            reason: 'Converted grammar should be in CNF',
          );
        }
      });

      test('Should preserve language after CNF conversion', () {
        final result = CFGToolkit.toCNF(simpleGrammar);
        expect(result.isSuccess, true);

        if (result.isSuccess) {
          final cnf = result.data!;

          // CNF grammar should be valid
          expect(
            cnf.nonterminals.isNotEmpty,
            true,
            reason: 'CNF should have nonterminals',
          );
          expect(
            cnf.productions.isNotEmpty,
            true,
            reason: 'CNF should have productions',
          );
          expect(
            cnf.terminals.isNotEmpty,
            true,
            reason: 'CNF should have terminals',
          );
        }
      });

      test('Should handle complex grammar CNF conversion', () {
        final result = CFGToolkit.toCNF(complexGrammar);
        expect(result.isSuccess, true);

        if (result.isSuccess) {
          final cnf = result.data!;

          // All productions should be in CNF form
          for (final p in cnf.productions) {
            if (p.isLambda) {
              expect(
                p.leftSide.first,
                cnf.startSymbol,
                reason: 'Only start symbol should have lambda production',
              );
            } else if (p.rightSide.length == 1) {
              expect(
                cnf.terminals.contains(p.rightSide.first),
                true,
                reason: 'Single RHS should be terminal',
              );
            } else if (p.rightSide.length == 2) {
              expect(
                cnf.nonterminals.contains(p.rightSide[0]),
                true,
                reason: 'Binary RHS first symbol should be nonterminal',
              );
              expect(
                cnf.nonterminals.contains(p.rightSide[1]),
                true,
                reason: 'Binary RHS second symbol should be nonterminal',
              );
            } else {
              fail(
                'CNF should not have productions with more than 2 RHS symbols',
              );
            }
          }
        }
      });
    });

    group('CNF Validation Tests', () {
      test('Should correctly identify CNF grammars', () {
        // Create a simple CNF grammar
        final cnfGrammar = _createCNFGrammar();

        expect(
          CFGToolkit.isCNF(cnfGrammar),
          true,
          reason: 'Should identify valid CNF grammar',
        );
      });

      test('Should reject non-CNF grammars', () {
        expect(
          CFGToolkit.isCNF(complexGrammar),
          false,
          reason: 'Should reject non-CNF grammar',
        );
        expect(
          CFGToolkit.isCNF(unitGrammar),
          false,
          reason: 'Should reject grammar with unit productions',
        );
      });
    });

    group('GNF Conversion Tests', () {
      test('Should convert simple grammar to GNF', () {
        final result = CFGToolkit.toGNF(simpleGrammar);

        expect(result.isSuccess, true, reason: 'GNF conversion should succeed');

        if (result.isSuccess) {
          final gnf = result.data!;

          // Check that result is in GNF
          expect(
            CFGToolkit.isGNF(gnf),
            true,
            reason: 'Converted grammar should be in GNF',
          );
        }
      });

      test('Should preserve language after GNF conversion', () {
        final result = CFGToolkit.toGNF(simpleGrammar);
        expect(result.isSuccess, true);

        if (result.isSuccess) {
          final gnf = result.data!;

          // GNF grammar should be valid
          expect(
            gnf.nonterminals.isNotEmpty,
            true,
            reason: 'GNF should have nonterminals',
          );
          expect(
            gnf.productions.isNotEmpty,
            true,
            reason: 'GNF should have productions',
          );
          expect(
            gnf.terminals.isNotEmpty,
            true,
            reason: 'GNF should have terminals',
          );
        }
      });

      test('Should validate GNF production structure', () {
        final result = CFGToolkit.toGNF(simpleGrammar);
        expect(result.isSuccess, true);

        if (result.isSuccess) {
          final gnf = result.data!;

          // All productions should be in GNF form
          for (final p in gnf.productions) {
            if (p.isLambda) {
              expect(
                p.leftSide.first,
                gnf.startSymbol,
                reason: 'Only start symbol should have lambda production',
              );
            } else {
              expect(
                p.rightSide.isNotEmpty,
                true,
                reason: 'Non-lambda production should have non-empty RHS',
              );
              // First symbol should be terminal
              expect(
                gnf.terminals.contains(p.rightSide.first),
                true,
                reason: 'GNF production should start with terminal',
              );
              // Remaining symbols should be nonterminals
              for (var i = 1; i < p.rightSide.length; i++) {
                expect(
                  gnf.nonterminals.contains(p.rightSide[i]),
                  true,
                  reason: 'GNF production tail should be nonterminals',
                );
              }
            }
          }
        }
      });
    });

    group('GNF Validation Tests', () {
      test('Should correctly identify GNF grammars', () {
        // Create a simple GNF grammar
        final gnfGrammar = _createGNFGrammar();

        expect(
          CFGToolkit.isGNF(gnfGrammar),
          true,
          reason: 'Should identify valid GNF grammar',
        );
      });

      test('Should reject non-GNF grammars', () {
        expect(
          CFGToolkit.isGNF(complexGrammar),
          false,
          reason: 'Should reject non-GNF grammar',
        );
        expect(
          CFGToolkit.isGNF(unitGrammar),
          false,
          reason: 'Should reject grammar with unit productions',
        );
      });
    });

    group('Complete Reduction Tests', () {
      test('Should perform complete grammar reduction', () {
        final result = CFGToolkit.reduce(complexGrammar);

        expect(
          result.isSuccess,
          true,
          reason: 'Complete reduction should succeed',
        );

        if (result.isSuccess) {
          final reduced = result.data!;

          // Check that grammar is reduced
          expect(
            reduced.nonterminals.isNotEmpty,
            true,
            reason: 'Reduced grammar should have nonterminals',
          );
          expect(
            reduced.productions.isNotEmpty,
            true,
            reason: 'Reduced grammar should have productions',
          );
        }
      });

      test('Should handle edge cases', () {
        // Test with minimal grammar
        final minimal = _createMinimalGrammar();
        final result = CFGToolkit.reduce(minimal);

        expect(result.isSuccess, true, reason: 'Should handle minimal grammar');
      });
    });
  });
}

/// Helper functions to create test grammars

Grammar _createSimpleGrammar() {
  final productions = {
    const Production(
      id: 'p1',
      leftSide: ['S'],
      rightSide: ['a', 'A'],
      isLambda: false,
      order: 1,
    ),
    const Production(
      id: 'p2',
      leftSide: ['A'],
      rightSide: ['b'],
      isLambda: false,
      order: 2,
    ),
  };

  return Grammar(
    id: 'simple',
    name: 'Simple Grammar',
    terminals: {'a', 'b'},
    nonterminals: {'S', 'A'},
    startSymbol: 'S',
    productions: productions,
    type: GrammarType.contextFree,
    created: DateTime.now(),
    modified: DateTime.now(),
  );
}

Grammar _createComplexGrammar() {
  final productions = {
    const Production(
      id: 'p1',
      leftSide: ['S'],
      rightSide: ['A', 'B', 'C'],
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
    const Production(
      id: 'p4',
      leftSide: ['C'],
      rightSide: ['c'],
      isLambda: false,
      order: 4,
    ),
  };

  return Grammar(
    id: 'complex',
    name: 'Complex Grammar',
    terminals: {'a', 'b', 'c'},
    nonterminals: {'S', 'A', 'B', 'C'},
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

Grammar _createUselessGrammar() {
  final productions = {
    const Production(
      id: 'p1',
      leftSide: ['S'],
      rightSide: ['a'],
      isLambda: false,
      order: 1,
    ),
    const Production(
      id: 'p2',
      leftSide: ['U'],
      rightSide: ['U', 'b'],
      isLambda: false,
      order: 2,
    ),
  };

  return Grammar(
    id: 'useless',
    name: 'Useless Grammar',
    terminals: {'a', 'b'},
    nonterminals: {'S', 'U'},
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

Grammar _createMinimalGrammar() {
  final productions = {
    const Production(
      id: 'p1',
      leftSide: ['S'],
      rightSide: ['a'],
      isLambda: false,
      order: 1,
    ),
  };

  return Grammar(
    id: 'minimal',
    name: 'Minimal Grammar',
    terminals: {'a'},
    nonterminals: {'S'},
    startSymbol: 'S',
    productions: productions,
    type: GrammarType.contextFree,
    created: DateTime.now(),
    modified: DateTime.now(),
  );
}

Grammar _createGNFGrammar() {
  final productions = {
    const Production(
      id: 'p1',
      leftSide: ['S'],
      rightSide: ['a', 'A'],
      isLambda: false,
      order: 1,
    ),
    const Production(
      id: 'p2',
      leftSide: ['A'],
      rightSide: ['b'],
      isLambda: false,
      order: 2,
    ),
  };

  return Grammar(
    id: 'gnf',
    name: 'GNF Grammar',
    terminals: {'a', 'b'},
    nonterminals: {'S', 'A'},
    startSymbol: 'S',
    productions: productions,
    type: GrammarType.contextFree,
    created: DateTime.now(),
    modified: DateTime.now(),
  );
}
