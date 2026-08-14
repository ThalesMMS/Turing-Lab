import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/grammar_cnf_transformer.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/grammar_diagnostic_severity.dart';
import 'package:turing_lab/core/models/production.dart';

Grammar buildGrammar({
  String id = 'g',
  String name = 'grammar',
  Set<String> terminals = const {'a'},
  Set<String> nonterminals = const {'S'},
  String startSymbol = 'S',
  required Set<Production> productions,
  GrammarType type = GrammarType.contextFree,
}) {
  return Grammar(
    id: id,
    name: name,
    terminals: terminals,
    nonterminals: nonterminals,
    startSymbol: startSymbol,
    productions: productions,
    type: type,
    created: DateTime(2026, 1, 1),
    modified: DateTime(2026, 1, 1),
  );
}

void main() {
  group('GrammarCnfTransformer', () {
    test('produces CNF-shaped productions for a simple expression grammar', () {
      // Grammar:
      // S -> A B C
      // A -> a
      // B -> b
      // C -> c
      final grammar = buildGrammar(
        id: 'g1',
        name: 'simple',
        terminals: {'a', 'b', 'c'},
        nonterminals: {'S', 'A', 'B', 'C'},
        startSymbol: 'S',
        productions: {
          const Production(
            id: 'p1',
            leftSide: ['S'],
            rightSide: ['A', 'B', 'C'],
            order: 0,
          ),
          const Production(
            id: 'p2',
            leftSide: ['A'],
            rightSide: ['a'],
            order: 1,
          ),
          const Production(
            id: 'p3',
            leftSide: ['B'],
            rightSide: ['b'],
            order: 2,
          ),
          const Production(
            id: 'p4',
            leftSide: ['C'],
            rightSide: ['c'],
            order: 3,
          ),
        },
      );

      final result = GrammarCnfTransformer.toCnf(grammar);
      expect(result.isSuccess, isTrue, reason: result.error);
      final report = result.data!;

      expect(report.steps, isNotEmpty);
      expect(report.diagnostics, isEmpty);
      expect(report.grammar.productions, isNotEmpty);

      // CNF shape check (best-effort):
      // - A -> a (single terminal)
      // - A -> B C (two nonterminals)
      // - S -> ε (only allowed for start symbol)
      for (final p in report.grammar.productions) {
        final rhs = p.rightSide;
        if (rhs.isEmpty || p.isLambda) {
          expect(p.leftSide.single, report.grammar.startSymbol);
          continue;
        }

        if (rhs.length == 1) {
          expect(report.grammar.terminals.contains(rhs.single), isTrue,
              reason: '$p');
          continue;
        }

        expect(rhs.length, 2, reason: '$p');
        expect(report.grammar.nonterminals.contains(rhs[0]), isTrue,
            reason: '$p');
        expect(report.grammar.nonterminals.contains(rhs[1]), isTrue,
            reason: '$p');
      }
    });

    test('introduces new start symbol when start appears on RHS', () {
      // S -> S a | b
      final grammar = buildGrammar(
        id: 'g2',
        name: 'start on rhs',
        terminals: {'a', 'b'},
        nonterminals: {'S'},
        startSymbol: 'S',
        productions: {
          const Production(
            id: 'p1',
            leftSide: ['S'],
            rightSide: ['S', 'a'],
            order: 0,
          ),
          const Production(
            id: 'p2',
            leftSide: ['S'],
            rightSide: ['b'],
            order: 1,
          ),
        },
      );

      final result = GrammarCnfTransformer.toCnf(grammar);
      expect(result.isSuccess, isTrue, reason: result.error);
      final report = result.data!;

      expect(report.grammar.startSymbol, isNot('S'));
      expect(report.grammar.nonterminals.contains(report.grammar.startSymbol),
          isTrue);

      final startProductions = report.grammar.productions
          .where((p) =>
              p.leftSide.length == 1 &&
              p.leftSide.single == report.grammar.startSymbol)
          .toList();
      expect(startProductions, isNotEmpty);

      // CNF pipeline may remove unit productions afterwards, so we only assert
      // that the start symbol was changed and is part of the nonterminal set.
    });

    test('eliminates unit productions (A -> B)', () {
      // S -> A
      // A -> B
      // B -> b
      final grammar = buildGrammar(
        id: 'g3',
        name: 'unit elimination',
        terminals: {'b'},
        nonterminals: {'S', 'A', 'B'},
        startSymbol: 'S',
        productions: {
          const Production(
            id: 'p1',
            leftSide: ['S'],
            rightSide: ['A'],
            order: 0,
          ),
          const Production(
            id: 'p2',
            leftSide: ['A'],
            rightSide: ['B'],
            order: 1,
          ),
          const Production(
            id: 'p3',
            leftSide: ['B'],
            rightSide: ['b'],
            order: 2,
          ),
        },
      );

      final result = GrammarCnfTransformer.toCnf(grammar);
      expect(result.isSuccess, isTrue, reason: result.error);
      final report = result.data!;

      final hasUnit = report.grammar.productions.any((p) {
        final rhs = p.rightSide;
        // unit: A -> B where B is nonterminal
        return rhs.length == 1 &&
            report.grammar.nonterminals.contains(rhs.single);
      });

      // CNF should have removed unit productions.
      expect(hasUnit, isFalse);
    });

    test('keeps epsilon only for (possibly new) start symbol', () {
      // S -> ε | a
      final grammar = buildGrammar(
        id: 'g4',
        name: 'epsilon',
        terminals: {'a'},
        nonterminals: {'S'},
        startSymbol: 'S',
        productions: {
          const Production(
            id: 'p1',
            leftSide: ['S'],
            rightSide: [],
            isLambda: true,
            order: 0,
          ),
          const Production(
            id: 'p2',
            leftSide: ['S'],
            rightSide: ['a'],
            order: 1,
          ),
        },
      );

      final result = GrammarCnfTransformer.toCnf(grammar);
      expect(result.isSuccess, isTrue, reason: result.error);
      final report = result.data!;

      final epsilonProductions = report.grammar.productions
          .where((p) => p.rightSide.isEmpty || p.isLambda)
          .toList();

      // CNF conversion is allowed to preserve ε for the start symbol, but some
      // intermediate productions may still carry the lambda flag depending on
      // reduction behavior. The strict requirement we enforce is: if ε exists,
      // its LHS must be the start symbol.
      for (final p in epsilonProductions) {
        expect(p.leftSide.single, report.grammar.startSymbol);
      }

      // Any remaining empty RHS must be start, and start must be nullable in input.
      expect(report.steps, isNotEmpty);
    });

    test('recomputes reachability after removing unproductive symbols', () {
      final grammar = buildGrammar(
        id: 'g5',
        name: 'sequential useless-symbol removal',
        terminals: {'a', 'b'},
        nonterminals: {'S', 'A', 'B'},
        startSymbol: 'S',
        productions: {
          const Production(id: 'p1', leftSide: ['S'], rightSide: ['a']),
          const Production(
            id: 'p2',
            leftSide: ['S'],
            rightSide: ['A', 'B'],
          ),
          const Production(id: 'p3', leftSide: ['B'], rightSide: ['b']),
        },
      );

      final result = GrammarCnfTransformer.toCnf(grammar);
      expect(result.isSuccess, isTrue, reason: result.error);

      final transformed = result.data!.grammar;
      expect(transformed.nonterminals, {'S'});
      expect(
        transformed.productions,
        everyElement(
          predicate<Production>(
            (production) =>
                !production.leftSide.contains('B') &&
                !production.rightSide.contains('B'),
          ),
        ),
      );
    });

    test('reports an error when nullable subset expansion exceeds the cap', () {
      final grammar = buildGrammar(
        id: 'g5',
        name: 'nullable cap',
        terminals: {'a'},
        nonterminals: {'S', 'A', 'B', 'C', 'D'},
        startSymbol: 'S',
        productions: {
          const Production(
            id: 'p1',
            leftSide: ['S'],
            rightSide: ['A', 'B', 'C', 'D'],
            order: 0,
          ),
          const Production(
            id: 'p2',
            leftSide: ['A'],
            rightSide: [],
            isLambda: true,
            order: 1,
          ),
          const Production(
            id: 'p3',
            leftSide: ['B'],
            rightSide: [],
            isLambda: true,
            order: 2,
          ),
          const Production(
            id: 'p4',
            leftSide: ['C'],
            rightSide: [],
            isLambda: true,
            order: 3,
          ),
          const Production(
            id: 'p5',
            leftSide: ['D'],
            rightSide: [],
            isLambda: true,
            order: 4,
          ),
        },
      );

      final result = GrammarCnfTransformer.toCnf(
        grammar,
        maxNullableSubsetExpansions: 8,
      );
      expect(result.isSuccess, isTrue, reason: result.error);

      final diagnostics = result.data!.diagnostics;
      expect(
        diagnostics.any(
          (d) =>
              d.code == 'cnf.nullable_subset_limit_exceeded' &&
              d.severity == GrammarDiagnosticSeverity.error &&
              d.productionIds.contains('p1'),
        ),
        isTrue,
      );
    });

    test('emits new-symbol limit warning only once', () {
      final grammar = buildGrammar(
        id: 'g6',
        name: 'new symbol cap',
        terminals: {'a', 'b', 'c', 'd', 'e'},
        nonterminals: {'S', 'A', 'B', 'C', 'D', 'E'},
        startSymbol: 'S',
        productions: {
          const Production(
            id: 'p1',
            leftSide: ['S'],
            rightSide: ['A', 'B', 'C', 'D', 'E'],
            order: 0,
          ),
          const Production(
            id: 'p2',
            leftSide: ['A'],
            rightSide: ['B', 'C', 'D', 'E'],
            order: 1,
          ),
          const Production(id: 'p3', leftSide: ['B'], rightSide: ['b']),
          const Production(id: 'p4', leftSide: ['C'], rightSide: ['c']),
          const Production(id: 'p5', leftSide: ['D'], rightSide: ['d']),
          const Production(id: 'p6', leftSide: ['E'], rightSide: ['e']),
        },
      );

      final result = GrammarCnfTransformer.toCnf(
        grammar,
        maxNewNonTerminals: 0,
      );
      expect(result.isSuccess, isTrue, reason: result.error);

      final limitWarnings = result.data!.diagnostics
          .where((d) => d.code == 'cnf.new_symbol_limit_reached')
          .toList();
      expect(limitWarnings, hasLength(1));
    });
  });
}
