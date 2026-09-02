import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/grammar_parser.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/production.dart';
import 'package:turing_lab/presentation/providers/grammar_provider.dart';

void main() {
  test(
    'buildGrammar restores fragmented declared nonterminals before parsing',
    () {
      final provider = GrammarProvider()
        ..createNewGrammar(
          name: 'Expression grammar',
          startSymbol: 'S',
          type: GrammarType.contextFree,
        );

      void addCompact(String leftSide, String rightSide) {
        provider.addProduction(
          leftSide: [leftSide],
          rightSide: rightSide.split(''),
        );
      }

      void addLambda(String leftSide) {
        provider.addProduction(
          leftSide: [leftSide],
          rightSide: const [],
          isLambda: true,
        );
      }

      addCompact('S', 'Expr');
      addCompact('Expr', 'TermoExpr’');
      addCompact('Expr’', '+TermoExpr’');
      addLambda('Expr’');
      addCompact('Termo', 'FatorTermo’');
      addCompact('Termo’', 'xFatorTermo’');
      addLambda('Termo’');
      addCompact('Fator', 'num');
      addCompact('Fator', 'id');
      addCompact('Fator', '(Expr)');

      final grammar = provider.buildGrammar();

      Production production(String id) =>
          grammar.productions.singleWhere((production) => production.id == id);

      expect(production('p1').rightSide, ['Expr']);
      expect(production('p2').rightSide, ['Termo', 'Expr’']);
      expect(production('p3').rightSide, ['+', 'Termo', 'Expr’']);
      expect(production('p5').rightSide, ['Fator', 'Termo’']);
      expect(production('p6').rightSide, ['x', 'Fator', 'Termo’']);
      expect(production('p10').rightSide, ['(', 'Expr', ')']);
      expect(
        grammar.nonterminals,
        containsAll({'S', 'Expr', 'Expr’', 'Termo', 'Termo’', 'Fator'}),
      );
      expect(grammar.nonterminals, isNot(contains('E')));
      expect(grammar.nonterminals, isNot(contains('T')));
      expect(grammar.nonterminals, isNot(contains('F')));

      final result = GrammarParser.parseWithReport(
        grammar,
        'id+id',
        strategyHint: ParsingStrategyHint.auto,
      );

      expect(result.isSuccess, isTrue, reason: result.error);
      expect(result.data!.accepted, isTrue, reason: result.data!.message);
    },
  );
}
