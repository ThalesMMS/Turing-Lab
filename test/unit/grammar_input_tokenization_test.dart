import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/cfg/cyk_parser.dart';
import 'package:turing_lab/core/algorithms/grammar_parser.dart';
import 'package:turing_lab/core/algorithms/grammar_parser_earley.dart';
import 'package:turing_lab/core/algorithms/grammar_parser_simple_recursive.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/production.dart';

void main() {
  final now = DateTime(2026);

  Grammar grammar(Set<Production> productions) => Grammar(
        id: 'tokenization-test',
        name: 'Overlapping terminals',
        terminals: const {'i', 'id', 'd'},
        nonterminals: const {'S', 'A', 'D'},
        startSymbol: 'S',
        productions: productions,
        type: GrammarType.contextFree,
        created: now,
        modified: now,
      );

  final longestTokenGrammar = grammar({
    const Production(id: 'p1', leftSide: ['S'], rightSide: ['id']),
  });
  final shorterTokenSequenceGrammar = grammar({
    const Production(id: 'p1', leftSide: ['S'], rightSide: ['A', 'D']),
    const Production(id: 'p2', leftSide: ['A'], rightSide: ['i']),
    const Production(id: 'p3', leftSide: ['D'], rightSide: ['d']),
  });

  group('shared grammar input tokenization', () {
    for (final strategy in ParsingStrategyHint.values.where(
      (strategy) => strategy != ParsingStrategyHint.lr,
    )) {
      test('$strategy accepts the longest declared terminal', () {
        final result = GrammarParser.parse(
          longestTokenGrammar,
          'id',
          strategyHint: strategy,
        );

        expect(result.isSuccess, isTrue);
        expect(result.data!.accepted, isTrue);
      });

      test('$strategy rejects a non-maximal segmentation', () {
        final result = GrammarParser.parse(
          shorterTokenSequenceGrammar,
          'id',
          strategyHint: strategy,
        );

        expect(result.isSuccess, isTrue);
        expect(result.data!.accepted, isFalse);
      });
    }

    test('direct Earley recognition follows maximal munch', () {
      expect(EarleyRecognizer(longestTokenGrammar).recognizes('id'), isTrue);
      expect(
        EarleyRecognizer(shorterTokenSequenceGrammar).recognizes('id'),
        isFalse,
      );
    });

    test('Earley reports raw offsets after consuming a multi-character token',
        () {
      final report = EarleyRecognizer(
        grammar({
          const Production(
            id: 'p1',
            leftSide: ['S'],
            rightSide: ['id', 'd'],
          ),
        }),
      ).recognizeWithReport('id');

      expect(report.accepted, isFalse);
      expect(report.farthestPosition, 2);
      expect(report.expectedSymbols, {'d'});
    });

    test('direct recursive parsing accepts a multi-character terminal', () {
      final longest = SimpleRecursiveDescentParser(longestTokenGrammar).parse(
        'id',
      );
      final shorter = SimpleRecursiveDescentParser(
        shorterTokenSequenceGrammar,
      ).parse('id');

      expect(longest.isSuccess, isTrue);
      expect(longest.data!.accepted, isTrue);
      expect(shorter.isFailure, isTrue);
    });

    test('direct CYK parsing follows maximal munch', () {
      final longest = CYKParser.parse(longestTokenGrammar, 'id');
      final shorter = CYKParser.parse(shorterTokenSequenceGrammar, 'id');

      expect(longest.isSuccess, isTrue);
      expect(longest.data!.accepted, isTrue);
      expect(shorter.isSuccess, isTrue);
      expect(shorter.data!.accepted, isFalse);
    });

    test('CYK trace indexes a multi-character terminal as one token', () {
      final result = CYKParser.parseWithSteps(longestTokenGrammar, 'id');

      expect(result.isSuccess, isTrue);
      expect(result.data!.accepted, isTrue);
      expect(result.data!.table, hasLength(1));
      expect(
        result.data!.steps.where((step) => step.terminal == 'id'),
        hasLength(1),
      );
    });
  });
}
