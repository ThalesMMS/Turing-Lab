import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/grammar_analyzer.dart';
import 'package:turing_lab/core/algorithms/grammar_parser.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/grammar_parse_report.dart';
import 'package:turing_lab/core/models/ll1_parse_step.dart';
import 'package:turing_lab/core/models/production.dart';
import 'package:turing_lab/core/parsers/grammar_xml_codec.dart';

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

    test('preserves production ids and consulted table cells in the trace', () {
      final simpleGrammar = grammar(
        terminals: {'a'},
        nonterminals: {'S'},
        startSymbol: 'S',
        productions: {
          const Production(id: 'stable-p1', leftSide: ['S'], rightSide: ['a']),
        },
      );

      final result = GrammarParser.parseLL1(simpleGrammar, 'a').data!;
      final expansion = result.ll1Steps.first;

      expect(result.outcome, GrammarParseOutcome.accepted);
      expect(expansion.productionId, 'stable-p1');
      expect(expansion.tableNonTerminal, 'S');
      expect(expansion.tableLookahead, 'a');
    });

    test('returns typed conflict, cancellation, and work-limit outcomes', () {
      final conflictingGrammar = grammar(
        terminals: {'a'},
        nonterminals: {'S'},
        startSymbol: 'S',
        productions: {
          const Production(id: 'p1', leftSide: ['S'], rightSide: ['a']),
          const Production(id: 'p2', leftSide: ['S'], rightSide: ['a', 'a']),
        },
      );
      final simpleGrammar = grammar(
        terminals: {'a'},
        nonterminals: {'S'},
        startSymbol: 'S',
        productions: {
          const Production(id: 'p1', leftSide: ['S'], rightSide: ['a']),
        },
      );

      final conflict = GrammarParser.parseLL1(conflictingGrammar, 'a').data!;
      final cancelled = GrammarParser.parseLL1(
        simpleGrammar,
        'a',
        isCancelled: () => true,
      ).data!;
      final bounded = GrammarParser.parseLL1(
        simpleGrammar,
        'a',
        maxSteps: 1,
      ).data!;

      expect(conflict.outcome, GrammarParseOutcome.conflict);
      expect(
        conflict.ll1Steps.single.diagnostic,
        LL1ParseDiagnostic.conflict,
      );
      expect(cancelled.outcome, GrammarParseOutcome.cancelled);
      expect(
        cancelled.ll1Steps.single.diagnostic,
        LL1ParseDiagnostic.cancelled,
      );
      expect(bounded.outcome, GrammarParseOutcome.stepLimit);
      expect(bounded.ll1Steps.last.diagnostic, LL1ParseDiagnostic.stepLimit);
    });

    test('classifies typed conflicts and deduplicates dual provenance', () {
      final dualProvenanceGrammar = grammar(
        terminals: {'a'},
        nonterminals: {'S', 'A', 'B'},
        startSymbol: 'S',
        productions: {
          const Production(id: 'p1', leftSide: ['S'], rightSide: ['A', 'a']),
          const Production(id: 'p2', leftSide: ['A'], rightSide: ['B']),
          const Production(id: 'p3', leftSide: ['B'], rightSide: ['a']),
          const Production(
            id: 'p4',
            leftSide: ['B'],
            rightSide: [],
            isLambda: true,
          ),
        },
      );

      final table =
          GrammarAnalyzer.buildLL1ParseTable(dualProvenanceGrammar).data!.value;
      final aEntry = table.entriesAt('A', 'a').single;
      final conflict = table.typedConflicts.single;

      expect(aEntry.productionId, 'p2');
      expect(
        aEntry.placements,
        {LL1TablePlacement.first, LL1TablePlacement.follow},
      );
      expect(conflict.kind, LL1ConflictKind.firstFollow);
      expect(conflict.nonTerminal, 'B');
      expect(conflict.entries.map((entry) => entry.productionId), ['p3', 'p4']);
    });

    test('reproduces the canonical JFLAP grammar fixture', () {
      final xml = File(
        'test/fixtures/interoperability/grammar_canonical.jff',
      ).readAsStringSync();
      final imported = const GrammarXmlCodec().decodeGrammarXml(xml).data!;

      final table = GrammarAnalyzer.buildLL1ParseTable(imported).data!.value;
      final accepted = GrammarParser.parseLL1(imported, 'a').data!;
      final rejected = GrammarParser.parseLL1(imported, 'aa').data!;

      expect(table.entriesAt('S', 'a').single.rightSide, ['a']);
      expect(accepted.outcome, GrammarParseOutcome.accepted);
      expect(rejected.outcome, GrammarParseOutcome.rejected);
    });

    test('reports Unicode tokens and malformed grammars without throwing', () {
      final unicodeGrammar = grammar(
        terminals: {'🙂'},
        nonterminals: {'S'},
        startSymbol: 'S',
        productions: {
          const Production(id: 'p1', leftSide: ['S'], rightSide: ['🙂']),
        },
      );
      final malformedGrammar = grammar(
        terminals: const {},
        nonterminals: {'S'},
        startSymbol: 'S',
        productions: const {},
      );

      expect(
        GrammarParser.parseLL1(unicodeGrammar, '🙂').data!.outcome,
        GrammarParseOutcome.accepted,
      );
      expect(
        GrammarParser.parseLL1(malformedGrammar, '').data!.outcome,
        GrammarParseOutcome.invalidInput,
      );
      expect(
        GrammarParser.parseLL1(unicodeGrammar, 'a').data!.outcome,
        GrammarParseOutcome.tokenizationFailure,
      );
      expect(
        GrammarParser.parseWithReport(
          unicodeGrammar,
          'a',
          strategyHint: ParsingStrategyHint.ll,
        ).data!.outcome,
        GrammarParseOutcome.tokenizationFailure,
      );
    });
  });
}
