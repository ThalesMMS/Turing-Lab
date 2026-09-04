import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/production.dart';
import 'package:turing_lab/presentation/providers/grammar_provider.dart';

void main() {
  group('GrammarProvider declared symbol kinds', () {
    test('declareSymbolKinds records kinds and the latest choice wins', () {
      final provider = GrammarProvider();

      provider.declareSymbolKinds({
        'id': GrammarSymbolKind.terminal,
        'Expr': GrammarSymbolKind.nonterminal,
      });
      expect(provider.state.declaredTerminals, {'id'});
      expect(provider.state.declaredNonterminals, {'Expr'});

      provider.declareSymbolKinds({'id': GrammarSymbolKind.nonterminal});
      expect(provider.state.declaredTerminals, isEmpty);
      expect(provider.state.declaredNonterminals, {'id', 'Expr'});

      expect(provider.symbolKindOf('id'), GrammarSymbolKind.nonterminal);
      expect(provider.symbolKindOf('num'), GrammarSymbolKind.terminal);
      expect(provider.symbolKindOf('A'), GrammarSymbolKind.nonterminal);
    });

    test('buildGrammar honours declared kinds over uppercase heuristic', () {
      final provider = GrammarProvider()
        ..createNewGrammar(startSymbol: 'S', type: GrammarType.contextFree)
        ..declareSymbolKinds({
          'X': GrammarSymbolKind.terminal,
          'expr': GrammarSymbolKind.nonterminal,
        })
        ..addProduction(leftSide: ['S'], rightSide: ['X', 'expr'])
        ..addProduction(leftSide: ['expr'], rightSide: ['id']);

      final grammar = provider.buildGrammar();

      expect(grammar.terminals, {'X', 'id'});
      expect(grammar.nonterminals, {'S', 'expr'});
    });

    test('buildGrammar re-joins fragments of declared terminals', () {
      final provider = GrammarProvider()
        ..createNewGrammar(startSymbol: 'S', type: GrammarType.contextFree)
        ..declareSymbolKinds({'id': GrammarSymbolKind.terminal})
        ..addProduction(leftSide: ['S'], rightSide: ['i', 'd', 'A'])
        ..addProduction(leftSide: ['A'], rightSide: ['i', 'd']);

      final grammar = provider.buildGrammar();
      final byLeft = {
        for (final production in grammar.productions)
          production.leftSide.first: production.rightSide,
      };

      expect(byLeft['S'], ['id', 'A']);
      expect(byLeft['A'], ['id']);
      expect(grammar.terminals, {'id'});
      expect(grammar.terminals, isNot(contains('i')));
    });

    test('applyGrammar seeds declared kinds; clearProductions resets them', () {
      final provider = GrammarProvider();
      final now = DateTime(2026, 1, 1);
      final grammar = Grammar(
        id: 'g1',
        name: 'Expressions',
        terminals: {'id', '+'},
        nonterminals: {'E'},
        startSymbol: 'E',
        productions: {
          Production(
            id: 'p1',
            leftSide: const ['E'],
            rightSide: const ['E', '+', 'id'],
            order: 0,
          ),
          Production(
            id: 'p2',
            leftSide: const ['E'],
            rightSide: const ['id'],
            order: 1,
          ),
        },
        type: GrammarType.contextFree,
        created: now,
        modified: now,
      );

      provider.applyGrammar(grammar);
      expect(provider.state.declaredTerminals, {'id', '+'});
      expect(provider.state.declaredNonterminals, {'E'});
      expect(provider.knownSymbols, containsAll(['id', '+', 'E']));

      provider.clearProductions();
      expect(provider.state.declaredTerminals, isEmpty);
      expect(provider.state.declaredNonterminals, isEmpty);
    });
  });
}
