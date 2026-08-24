import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/grammar_parser.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/ll1_parse_step.dart';
import 'package:turing_lab/core/models/production.dart';

void main() {
  final now = DateTime(2026);

  Grammar grammar({
    required Set<String> terminals,
    required Set<String> nonterminals,
    required String startSymbol,
    required Set<Production> productions,
  }) {
    return Grammar(
      id: 'll1-test',
      name: 'LL(1) test grammar',
      terminals: terminals,
      nonterminals: nonterminals,
      startSymbol: startSymbol,
      productions: productions,
      type: GrammarType.contextFree,
      created: now,
      modified: now,
    );
  }

  group('LL(1) predictive parser', () {
    test('is advertised as available', () {
      final capability = GrammarParser.capabilityFor(ParsingStrategyHint.ll);

      expect(capability.isAvailable, isTrue);
      expect(capability.unavailableReason, isNull);
    });

    test('accepts an LL(1) expression grammar with multi-character terminals',
        () {
      final expressionGrammar = grammar(
        terminals: {'id', '+'},
        nonterminals: {'E', "E'", 'T'},
        startSymbol: 'E',
        productions: {
          const Production(
            id: 'p1',
            leftSide: ['E'],
            rightSide: ['T', "E'"],
          ),
          const Production(
            id: 'p2',
            leftSide: ["E'"],
            rightSide: ['+', 'T', "E'"],
          ),
          const Production(
            id: 'p3',
            leftSide: ["E'"],
            rightSide: [],
            isLambda: true,
          ),
          const Production(
            id: 'p4',
            leftSide: ['T'],
            rightSide: ['id'],
          ),
        },
      );

      final result = GrammarParser.parse(
        expressionGrammar,
        'id+id',
        strategyHint: ParsingStrategyHint.ll,
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!.accepted, isTrue);
      expect(result.data!.ll1Steps, isNotEmpty);
      expect(result.data!.ll1Steps.last.action, LL1ParseAction.accept);
      expect(
        result.data!.ll1Steps
            .where((step) => step.action == LL1ParseAction.match)
            .map((step) => step.lookahead),
        ['id', '+', 'id'],
      );
      for (final step in result.data!.ll1Steps) {
        expect(step.stack, isNotEmpty);
        expect(step.remainingInput, isNotEmpty);
        expect(step.lookahead, isNotEmpty);
      }
    });

    test('tokenizes overlapping terminals with deterministic longest match',
        () {
      final overlappingTerminalsGrammar = grammar(
        terminals: {'i', 'id'},
        nonterminals: {'S', 'U'},
        startSymbol: 'S',
        productions: {
          const Production(id: 'p1', leftSide: ['S'], rightSide: ['id']),
          const Production(id: 'p2', leftSide: ['U'], rightSide: ['i']),
        },
      );

      final result = GrammarParser.parse(
        overlappingTerminalsGrammar,
        'id',
        strategyHint: ParsingStrategyHint.ll,
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!.accepted, isTrue);
      expect(
        result.data!.ll1Steps
            .where((step) => step.action == LL1ParseAction.match)
            .single
            .lookahead,
        'id',
      );
    });

    test('uses FOLLOW entries for a nullable start symbol', () {
      final nullableGrammar = grammar(
        terminals: const {},
        nonterminals: {'S'},
        startSymbol: 'S',
        productions: {
          const Production(
            id: 'p1',
            leftSide: ['S'],
            rightSide: [],
            isLambda: true,
          ),
        },
      );

      final result = GrammarParser.parse(
        nullableGrammar,
        '',
        strategyHint: ParsingStrategyHint.ll,
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!.accepted, isTrue);
      final expansion = result.data!.ll1Steps.first;
      expect(expansion.action, LL1ParseAction.expand);
      expect(expansion.lookahead, r'$');
      expect(expansion.production, isEmpty);
      expect(expansion.productionDisplay, 'S → ε');
    });

    test('normalizes an explicit epsilon symbol without pushing it', () {
      final nullableGrammar = grammar(
        terminals: const {},
        nonterminals: {'S'},
        startSymbol: 'S',
        productions: {
          const Production(
            id: 'p1',
            leftSide: ['S'],
            rightSide: ['ε'],
          ),
        },
      );

      final result = GrammarParser.parse(
        nullableGrammar,
        '',
        strategyHint: ParsingStrategyHint.ll,
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!.accepted, isTrue);
      expect(result.data!.ll1Steps.first.production, isEmpty);
      expect(
        result.data!.ll1Steps
            .map((step) => step.stack)
            .expand((stack) => stack),
        isNot(contains('ε')),
      );
    });

    test('handles nested nullable nonterminals', () {
      final nestedNullableGrammar = grammar(
        terminals: const {},
        nonterminals: {'S', 'A', 'B'},
        startSymbol: 'S',
        productions: {
          const Production(
            id: 'p1',
            leftSide: ['S'],
            rightSide: ['A', 'B'],
          ),
          const Production(
            id: 'p2',
            leftSide: ['A'],
            rightSide: [],
            isLambda: true,
          ),
          const Production(
            id: 'p3',
            leftSide: ['B'],
            rightSide: [],
            isLambda: true,
          ),
        },
      );

      final result = GrammarParser.parse(
        nestedNullableGrammar,
        '',
        strategyHint: ParsingStrategyHint.ll,
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!.accepted, isTrue);
      expect(
        result.data!.ll1Steps
            .where((step) => step.action == LL1ParseAction.expand)
            .map((step) => step.nonTerminal),
        ['S', 'A', 'B'],
      );
    });

    test('reports expected terminals for an empty table cell', () {
      final predictiveGrammar = grammar(
        terminals: {'a', 'b'},
        nonterminals: {'S', 'U'},
        startSymbol: 'S',
        productions: {
          const Production(id: 'p1', leftSide: ['S'], rightSide: ['a']),
          const Production(id: 'p2', leftSide: ['U'], rightSide: ['b']),
        },
      );

      final result = GrammarParser.parse(
        predictiveGrammar,
        'b',
        strategyHint: ParsingStrategyHint.ll,
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!.accepted, isFalse);
      expect(result.data!.farthestPosition, 0);
      expect(result.data!.expectedSymbols, {'a'});
      expect(result.data!.errorMessage, contains('expected one of: a'));
      expect(result.data!.ll1Steps.single.action, LL1ParseAction.error);
    });

    test('reports premature end and trailing input separately', () {
      final twoTerminalGrammar = grammar(
        terminals: {'a', 'b'},
        nonterminals: {'S'},
        startSymbol: 'S',
        productions: {
          const Production(
            id: 'p1',
            leftSide: ['S'],
            rightSide: ['a', 'b'],
          ),
        },
      );
      final singleTerminalGrammar = grammar(
        terminals: {'a'},
        nonterminals: {'S'},
        startSymbol: 'S',
        productions: {
          const Production(id: 'p1', leftSide: ['S'], rightSide: ['a']),
        },
      );

      final premature = GrammarParser.parse(
        twoTerminalGrammar,
        'a',
        strategyHint: ParsingStrategyHint.ll,
      ).data!;
      final trailing = GrammarParser.parse(
        singleTerminalGrammar,
        'aa',
        strategyHint: ParsingStrategyHint.ll,
      ).data!;

      expect(premature.accepted, isFalse);
      expect(premature.expectedSymbols, {'b'});
      expect(premature.errorMessage, contains('end of input'));
      expect(trailing.accepted, isFalse);
      expect(trailing.expectedSymbols, {r'$'});
      expect(trailing.errorMessage, contains('trailing input'));
    });

    test('refuses a conflicting table and names the cell and productions', () {
      final conflictingGrammar = grammar(
        terminals: {'a'},
        nonterminals: {'S', 'A', 'B'},
        startSymbol: 'S',
        productions: {
          const Production(
            id: 'p1',
            leftSide: ['S'],
            rightSide: ['a', 'A'],
          ),
          const Production(
            id: 'p2',
            leftSide: ['S'],
            rightSide: ['a', 'B'],
          ),
          const Production(
            id: 'p3',
            leftSide: ['A'],
            rightSide: [],
            isLambda: true,
          ),
          const Production(
            id: 'p4',
            leftSide: ['B'],
            rightSide: [],
            isLambda: true,
          ),
        },
      );

      final result = GrammarParser.parse(
        conflictingGrammar,
        'a',
        strategyHint: ParsingStrategyHint.ll,
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!.accepted, isFalse);
      expect(result.data!.errorMessage, contains('Grammar is not LL(1)'));
      expect(result.data!.errorMessage, contains('[S, a]'));
      expect(result.data!.errorMessage, contains('a A'));
      expect(result.data!.errorMessage, contains('a B'));
      expect(result.data!.ll1Steps.single.action, LL1ParseAction.error);
    });

    test('formats conflict diagnostics independently of production order', () {
      const first = Production(
        id: 'p1',
        leftSide: ['S'],
        rightSide: ['a', 'A'],
      );
      const second = Production(
        id: 'p2',
        leftSide: ['S'],
        rightSide: ['a', 'B'],
      );
      const nullableA = Production(
        id: 'p3',
        leftSide: ['A'],
        rightSide: [],
        isLambda: true,
      );
      const nullableB = Production(
        id: 'p4',
        leftSide: ['B'],
        rightSide: [],
        isLambda: true,
      );

      Grammar orderedGrammar(List<Production> productions) => grammar(
            terminals: {'a'},
            nonterminals: {'S', 'A', 'B'},
            startSymbol: 'S',
            productions: Set<Production>.from(productions),
          );

      final forward = GrammarParser.parse(
        orderedGrammar([first, second, nullableA, nullableB]),
        'a',
        strategyHint: ParsingStrategyHint.ll,
      ).data!;
      final reversed = GrammarParser.parse(
        orderedGrammar([nullableB, nullableA, second, first]),
        'a',
        strategyHint: ParsingStrategyHint.ll,
      ).data!;

      expect(forward.errorMessage, reversed.errorMessage);
    });

    test('structured report preserves LL(1) trace and failure position', () {
      final simpleGrammar = grammar(
        terminals: {'a'},
        nonterminals: {'S'},
        startSymbol: 'S',
        productions: {
          const Production(id: 'p1', leftSide: ['S'], rightSide: ['a']),
        },
      );

      final report = GrammarParser.parseWithReport(
        simpleGrammar,
        'aa',
        strategyHint: ParsingStrategyHint.ll,
      );

      expect(report.isSuccess, isTrue);
      expect(report.data!.accepted, isFalse);
      expect(report.data!.farthestPosition, 1);
      expect(report.data!.expectedSymbols, {r'$'});
      expect(report.data!.ll1Steps, isNotEmpty);
    });
  });
}
