import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/grammar_analyzer.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/grammar_diagnostic_severity.dart';
import 'package:turing_lab/core/models/production.dart';

void main() {
  Grammar buildGrammar({
    required String startSymbol,
    required Set<String> nonterminals,
    required Set<String> terminals,
    required Set<Production> productions,
  }) {
    return Grammar(
      id: 'g',
      name: 'G',
      startSymbol: startSymbol,
      nonterminals: nonterminals,
      terminals: terminals,
      productions: productions,
      type: GrammarType.contextFree,
      created: DateTime(2026, 1, 1),
      modified: DateTime(2026, 1, 1),
    );
  }

  group('GrammarAnalyzer diagnostics', () {
    test('detectUnreachableNonTerminals reports unreachable symbols', () {
      final grammar = buildGrammar(
        startSymbol: 'S',
        nonterminals: {'S', 'A', 'B'},
        terminals: {'a'},
        productions: {
          const Production(id: 'p1', leftSide: ['S'], rightSide: ['a']),
          const Production(id: 'p2', leftSide: ['A'], rightSide: ['a']),
        },
      );

      final report = GrammarAnalyzer.detectUnreachableNonTerminals(grammar);
      expect(report.isSuccess, isTrue);

      final diagnostics = report.data!.diagnostics;
      expect(
        diagnostics.any(
          (d) =>
              d.code == 'grammar.unreachable_nonterminal' &&
              d.symbols.contains('A'),
        ),
        isTrue,
      );
      expect(
        diagnostics.any(
          (d) =>
              d.code == 'grammar.unreachable_nonterminal' &&
              d.symbols.contains('B'),
        ),
        isTrue,
      );
    });

    test('detectUnreachableNonTerminals warns once per unknown symbol', () {
      final grammar = buildGrammar(
        startSymbol: 'S',
        nonterminals: {'S', 'A'},
        terminals: const {},
        productions: {
          const Production(id: 'p1', leftSide: ['S'], rightSide: ['A', 'X']),
          const Production(id: 'p2', leftSide: ['A'], rightSide: ['X']),
        },
      );

      final report = GrammarAnalyzer.detectUnreachableNonTerminals(grammar);
      expect(report.isSuccess, isTrue);

      final unknownDiagnostics = report.data!.diagnostics
          .where((d) => d.code == 'grammar.unknown_symbol')
          .toList();
      expect(unknownDiagnostics, hasLength(1));
      expect(unknownDiagnostics.single.symbols, ['X']);
    });

    test('detectUnproductiveNonTerminals reports non-deriving symbols', () {
      final grammar = buildGrammar(
        startSymbol: 'S',
        nonterminals: {'S', 'A'},
        terminals: {'a'},
        productions: {
          const Production(id: 'p1', leftSide: ['S'], rightSide: ['A']),
          const Production(id: 'p2', leftSide: ['A'], rightSide: ['A']),
        },
      );

      final report = GrammarAnalyzer.detectUnproductiveNonTerminals(grammar);
      expect(report.isSuccess, isTrue);

      final diagnostics = report.data!.diagnostics;
      expect(
        diagnostics.any(
          (d) =>
              d.code == 'grammar.unproductive_nonterminal' &&
              d.symbols.contains('A'),
        ),
        isTrue,
      );
      expect(
        diagnostics.any(
          (d) =>
              d.code == 'grammar.unproductive_nonterminal' &&
              d.symbols.contains('S'),
        ),
        isTrue,
      );
      expect(
        diagnostics.any(
          (d) =>
              d.code == 'grammar.unproductive_nonterminal' &&
              d.severity == GrammarDiagnosticSeverity.warning &&
              d.symbols.contains('A') &&
              d.symbols.contains('S'),
        ),
        isTrue,
      );
    });

    test('detectUnproductiveNonTerminals warns once per unknown symbol', () {
      final grammar = buildGrammar(
        startSymbol: 'S',
        nonterminals: {'S', 'A'},
        terminals: const {},
        productions: {
          const Production(id: 'p1', leftSide: ['S'], rightSide: ['A', 'X']),
          const Production(id: 'p2', leftSide: ['A'], rightSide: ['X']),
        },
      );

      final report = GrammarAnalyzer.detectUnproductiveNonTerminals(grammar);
      expect(report.isSuccess, isTrue);

      final unknownDiagnostics = report.data!.diagnostics
          .where((d) => d.code == 'grammar.unknown_symbol')
          .toList();
      expect(unknownDiagnostics, hasLength(1));
      expect(unknownDiagnostics.single.symbols, ['X']);
    });

    test('validateMalformedProductions reports missing/invalid start symbol',
        () {
      final grammar = buildGrammar(
        startSymbol: 'S',
        nonterminals: {'A'},
        terminals: {'a'},
        productions: {
          const Production(id: 'p1', leftSide: ['A'], rightSide: ['a']),
        },
      );

      final report = GrammarAnalyzer.validateMalformedProductions(grammar);
      expect(report.isSuccess, isTrue);

      final diagnostics = report.data!.diagnostics;
      expect(
        diagnostics.any(
          (d) =>
              d.severity == GrammarDiagnosticSeverity.error &&
              d.code == 'grammar.start_symbol_not_nonterminal' &&
              d.symbols.contains('S'),
        ),
        isTrue,
      );
    });

    test(
        'validateMalformedProductions tolerates unknown RHS symbols by warning',
        () {
      final grammar = buildGrammar(
        startSymbol: 'S',
        nonterminals: {'S'},
        terminals: {'a'},
        productions: {
          const Production(id: 'p1', leftSide: ['S'], rightSide: ['a', 'X']),
        },
      );

      final report = GrammarAnalyzer.validateMalformedProductions(grammar);
      expect(report.isSuccess, isTrue);

      final diagnostics = report.data!.diagnostics;
      expect(
        diagnostics.any(
          (d) =>
              d.severity == GrammarDiagnosticSeverity.warning &&
              d.code == 'grammar.unknown_symbol',
        ),
        isTrue,
      );
    });

    test('combined diagnostics do not crash for empty grammar-like input', () {
      final grammar = buildGrammar(
        startSymbol: '',
        nonterminals: <String>{},
        terminals: <String>{},
        productions: const {},
      );

      final malformedResult =
          GrammarAnalyzer.validateMalformedProductions(grammar);
      final unreachableResult =
          GrammarAnalyzer.detectUnreachableNonTerminals(grammar);
      final unproductiveResult =
          GrammarAnalyzer.detectUnproductiveNonTerminals(grammar);

      expect(malformedResult.isSuccess, isTrue);
      expect(malformedResult.data, isNotNull);
      expect(unreachableResult.isSuccess, isTrue);
      expect(unreachableResult.data, isNotNull);
      expect(unproductiveResult.isSuccess, isTrue);
      expect(unproductiveResult.data, isNotNull);

      final malformed = malformedResult.data!;
      expect(malformed.diagnostics.isNotEmpty, isTrue);
    });

    test('computeFollowSets fails for invalid start symbol', () {
      final grammar = buildGrammar(
        startSymbol: 'S',
        nonterminals: {'A'},
        terminals: {'a'},
        productions: {
          const Production(id: 'p1', leftSide: ['A'], rightSide: ['a']),
        },
      );

      final result = GrammarAnalyzer.computeFollowSets(grammar);

      expect(result.isFailure, isTrue);
      final error = result.error.toString().toLowerCase();
      expect(error, contains('start symbol "s"'));
    });

    test('buildLL1ParseTable fails for undeclared production LHS', () {
      final grammar = buildGrammar(
        startSymbol: 'S',
        nonterminals: {'S'},
        terminals: const {},
        productions: {
          const Production(id: 'p1', leftSide: ['S'], rightSide: ['A']),
          const Production(
            id: 'p2',
            leftSide: ['A'],
            rightSide: [],
            isLambda: true,
          ),
        },
      );

      final result = GrammarAnalyzer.buildLL1ParseTable(grammar);

      expect(result.isFailure, isTrue);
      final error = result.error.toString().toLowerCase();
      expect(error, contains('production lhs "a"'));
    });
  });
}
