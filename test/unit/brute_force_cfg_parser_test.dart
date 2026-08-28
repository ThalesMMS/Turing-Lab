import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/brute_force_cfg_parser.dart';
import 'package:turing_lab/core/algorithms/grammar_parser.dart';
import 'package:turing_lab/core/models/brute_force_parse_models.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/grammar_parse_report.dart';
import 'package:turing_lab/core/models/production.dart';
import 'package:turing_lab/core/parsers/grammar_xml_codec.dart';

void main() {
  final now = DateTime(2026);

  Grammar grammar({
    String id = 'brute-force-test',
    required Set<String> terminals,
    required Set<String> nonTerminals,
    String start = 'S',
    required Iterable<Production> productions,
  }) =>
      Grammar(
        id: id,
        name: 'Brute-force test grammar',
        terminals: terminals,
        nonterminals: nonTerminals,
        startSymbol: start,
        productions: productions.toSet(),
        type: GrammarType.contextFree,
        created: now,
        modified: now,
      );

  const p = Production.new;

  group('bounded CFG brute-force search', () {
    test('parses the ambiguous JFLAP grammar fixture without flattening tokens',
        () {
      final xml = File(
        'test/fixtures/interoperability/grammar_brute_force_ambiguous.jff',
      ).readAsStringSync();
      final decoded = const GrammarXmlCodec().decodeGrammarXml(xml);

      expect(decoded.isSuccess, isTrue);
      final result = BruteForceCFGParser.search(
        decoded.data!,
        'ididid',
        limits: const BruteForceSearchLimits(resultCap: 3),
      );

      expect(result.outcome, BruteForceParseOutcome.accepted);
      expect(result.witnessCount, 2);
      expect(result.witnesses, hasLength(2));
      expect(
        result.witnesses.map((witness) => witness.steps.last.after),
        everyElement(equals(const ['id', 'id', 'id'])),
      );
    });

    test('BFS returns the shortest production-ID witness', () {
      final source = grammar(
        terminals: {'a'},
        nonTerminals: {'S', 'A', 'B', 'C'},
        productions: [
          p(id: 'long-1', leftSide: ['S'], rightSide: ['B'], order: 0),
          p(id: 'short-1', leftSide: ['S'], rightSide: ['A'], order: 1),
          p(id: 'long-2', leftSide: ['B'], rightSide: ['C'], order: 2),
          p(id: 'long-3', leftSide: ['C'], rightSide: ['a'], order: 3),
          p(id: 'short-2', leftSide: ['A'], rightSide: ['a'], order: 4),
        ],
      );

      final result = BruteForceCFGParser.search(
        source,
        'a',
        limits: const BruteForceSearchLimits(resultCap: 1),
      );

      expect(result.outcome, BruteForceParseOutcome.accepted);
      expect(result.witnesses.single.depth, 2);
      expect(
        result.witnesses.single.steps.map((step) => step.productionId),
        ['short-1', 'short-2'],
      );
      expect(result.witnesses.single.tree.root.symbol, 'S');
      expect(result.witnesses.single.tree.root.children.single.symbol, 'A');
    });

    test('leftmost, rightmost, and all-position modes choose token positions',
        () {
      final source = grammar(
        terminals: {'a'},
        nonTerminals: {'S', 'A'},
        productions: [
          p(id: 'split', leftSide: ['S'], rightSide: ['A', 'A']),
          p(id: 'leaf', leftSide: ['A'], rightSide: ['a']),
        ],
      );

      final left = BruteForceCFGParser.search(
        source,
        'aa',
        mode: BruteForceDerivationMode.leftmost,
      );
      final right = BruteForceCFGParser.search(
        source,
        'aa',
        mode: BruteForceDerivationMode.rightmost,
      );
      final all = BruteForceCFGParser.search(
        source,
        'aa',
        mode: BruteForceDerivationMode.allPositions,
        limits: const BruteForceSearchLimits(resultCap: 2),
      );

      expect(left.witnesses.single.steps.map((step) => step.occurrenceIndex),
          [0, 0, 1]);
      expect(right.witnesses.single.steps.map((step) => step.occurrenceIndex),
          [0, 1, 0]);
      expect(all.witnesses, hasLength(2));
      expect(
        all.witnesses.map((witness) => witness.stableKey).toSet(),
        hasLength(2),
      );
    });

    test('retains ambiguous and duplicate-production witnesses up to the cap',
        () {
      final ambiguous = grammar(
        terminals: {'a'},
        nonTerminals: {'S', 'A', 'B'},
        productions: [
          p(id: 'to-a', leftSide: ['S'], rightSide: ['A']),
          p(id: 'to-b', leftSide: ['S'], rightSide: ['B']),
          p(id: 'a-leaf', leftSide: ['A'], rightSide: ['a']),
          p(id: 'b-leaf', leftSide: ['B'], rightSide: ['a']),
        ],
      );
      final duplicates = grammar(
        terminals: {'a'},
        nonTerminals: {'S'},
        productions: [
          p(id: 'first', leftSide: ['S'], rightSide: ['a']),
          p(id: 'second', leftSide: ['S'], rightSide: ['a']),
        ],
      );

      final ambiguousResult = BruteForceCFGParser.search(
        ambiguous,
        'a',
        limits: const BruteForceSearchLimits(resultCap: 2),
      );
      final duplicateResult = BruteForceCFGParser.search(
        duplicates,
        'a',
        limits: const BruteForceSearchLimits(resultCap: 2),
      );

      expect(ambiguousResult.witnesses, hasLength(2));
      expect(
        duplicateResult.witnesses
            .map((witness) => witness.steps.single.productionId),
        {'first', 'second'},
      );
    });

    test('supports epsilon, recursion, and Unicode multi-character terminals',
        () {
      final source = grammar(
        terminals: {'token🙂'},
        nonTerminals: {'S'},
        productions: [
          p(id: 'grow', leftSide: ['S'], rightSide: ['token🙂', 'S']),
          p(
            id: 'empty',
            leftSide: ['S'],
            rightSide: [],
            isLambda: true,
          ),
        ],
      );

      final empty = BruteForceCFGParser.search(source, '');
      final repeated = BruteForceCFGParser.search(source, 'token🙂token🙂');

      expect(empty.accepted, isTrue);
      expect(empty.witnesses.single.tree.root.prettyPrint(), contains('ε'));
      expect(repeated.accepted, isTrue);
      expect(repeated.witnesses.single.depth, 3);
      final terminalLeaves = repeated.witnesses.single.tree.root.prettyPrint();
      expect(terminalLeaves, contains('token🙂("token🙂")'));
    });

    test('uses sound prefix/suffix/yield pruning and can prove exhaustion', () {
      final source = grammar(
        terminals: {'a', 'b'},
        nonTerminals: {'S'},
        productions: [
          p(id: 'grow', leftSide: ['S'], rightSide: ['a', 'S', 'b']),
          p(id: 'leaf', leftSide: ['S'], rightSide: ['a']),
        ],
      );

      final result = BruteForceCFGParser.search(source, 'b');

      expect(result.outcome, BruteForceParseOutcome.rejected);
      expect(result.statistics.prunedNodes, greaterThan(0));
      expect(
        result.statistics.prunedByReason.keys,
        contains(BruteForcePruneReason.terminalPrefix),
      );
      expect(result.limit, isNull);
    });

    test('reports each search bound as boundedUnknown, never rejection', () {
      final chain = grammar(
        terminals: {'a'},
        nonTerminals: {'S', 'A'},
        productions: [
          p(id: 'to-a', leftSide: ['S'], rightSide: ['A']),
          p(id: 'leaf', leftSide: ['A'], rightSide: ['a']),
        ],
      );
      BruteForceParseResult run(BruteForceSearchLimits limits) =>
          BruteForceCFGParser.search(chain, 'a', limits: limits);

      expect(
        run(const BruteForceSearchLimits(maxDepth: 1)).limit,
        BruteForceSearchLimit.depth,
      );
      expect(
        run(const BruteForceSearchLimits(maxExploredNodes: 1)).limit,
        BruteForceSearchLimit.exploredNodes,
      );
      expect(
        run(const BruteForceSearchLimits(maxRetainedStates: 1)).limit,
        BruteForceSearchLimit.retainedStates,
      );
      expect(
        run(const BruteForceSearchLimits(timeLimit: Duration.zero)).limit,
        BruteForceSearchLimit.time,
      );
      for (final result in [
        run(const BruteForceSearchLimits(maxDepth: 1)),
        run(const BruteForceSearchLimits(maxExploredNodes: 1)),
        run(const BruteForceSearchLimits(maxRetainedStates: 1)),
        run(const BruteForceSearchLimits(timeLimit: Duration.zero)),
      ]) {
        expect(result.outcome, BruteForceParseOutcome.boundedUnknown);
      }

      final branching = grammar(
        terminals: {'a', 'b'},
        nonTerminals: {'S', 'A', 'B'},
        productions: [
          p(id: 'one', leftSide: ['S'], rightSide: ['A']),
          p(id: 'two', leftSide: ['S'], rightSide: ['B']),
          p(id: 'a', leftSide: ['A'], rightSide: ['a']),
          p(id: 'b', leftSide: ['B'], rightSide: ['a']),
        ],
      );
      final frontier = BruteForceCFGParser.search(
        branching,
        'b',
        limits: const BruteForceSearchLimits(maxFrontierSize: 1),
      );
      expect(frontier.outcome, BruteForceParseOutcome.boundedUnknown);
      expect(frontier.limit, BruteForceSearchLimit.frontier);

      final symbols = grammar(
        terminals: {'a'},
        nonTerminals: {'S', 'A'},
        productions: [
          p(id: 'split', leftSide: ['S'], rightSide: ['A', 'A']),
          p(
            id: 'empty',
            leftSide: ['A'],
            rightSide: [],
            isLambda: true,
          ),
        ],
      );
      final symbolLimit = BruteForceCFGParser.search(
        symbols,
        'a',
        limits: const BruteForceSearchLimits(maxSymbolCount: 1),
      );
      expect(symbolLimit.outcome, BruteForceParseOutcome.boundedUnknown);
      expect(symbolLimit.limit, BruteForceSearchLimit.symbolCount);
      final initialSymbolLimit = BruteForceCFGParser.search(
        chain,
        'a',
        limits: const BruteForceSearchLimits(maxSymbolCount: 0),
      );
      expect(
        initialSymbolLimit.outcome,
        BruteForceParseOutcome.boundedUnknown,
      );
      expect(initialSymbolLimit.limit, BruteForceSearchLimit.symbolCount);
    });

    test('supports cooperative cancellation and progress on the async path',
        () async {
      final source = grammar(
        terminals: {'a'},
        nonTerminals: {'S'},
        productions: [
          p(id: 'branch', leftSide: ['S'], rightSide: ['S', 'S']),
          p(
            id: 'empty',
            leftSide: ['S'],
            rightSide: [],
            isLambda: true,
          ),
        ],
      );
      final token = BruteForceCancellationToken();
      var progressCalls = 0;

      final result = await BruteForceCFGParser.searchAsync(
        source,
        'a',
        cancellationToken: token,
        limits: const BruteForceSearchLimits(
          operationsPerBatch: 1,
          maxSymbolCount: 100,
        ),
        onProgress: (_) {
          progressCalls++;
          token.cancel();
        },
      );

      expect(progressCalls, greaterThan(0));
      expect(result.outcome, BruteForceParseOutcome.cancelled);
    });

    test('batch inputs are independent and omit traces by default', () {
      final source = grammar(
        terminals: {'a'},
        nonTerminals: {'S'},
        productions: [
          p(id: 'leaf', leftSide: ['S'], rightSide: ['a']),
        ],
      );

      final batch = BruteForceCFGParser.searchBatch(source, ['a', '', 'x']);

      expect(batch.items, hasLength(3));
      expect(batch.items[0].result.outcome, BruteForceParseOutcome.accepted);
      expect(batch.items[0].result.witnessCount, 1);
      expect(batch.items[0].result.witnesses, isEmpty);
      expect(batch.items[1].result.outcome, BruteForceParseOutcome.rejected);
      expect(
          batch.items[2].result.outcome, BruteForceParseOutcome.invalidInput);
    });

    test('is deterministic across production insertion order', () {
      final productions = [
        p(id: 'first', leftSide: ['S'], rightSide: ['A'], order: 0),
        p(id: 'second', leftSide: ['S'], rightSide: ['B'], order: 1),
        p(id: 'a', leftSide: ['A'], rightSide: ['x'], order: 2),
        p(id: 'b', leftSide: ['B'], rightSide: ['x'], order: 3),
      ];
      final forward = grammar(
        terminals: {'x'},
        nonTerminals: {'S', 'A', 'B'},
        productions: productions,
      );
      final reverse = grammar(
        terminals: {'x'},
        nonTerminals: {'B', 'A', 'S'},
        productions: productions.reversed,
      );

      final a = BruteForceCFGParser.search(
        forward,
        'x',
        limits: const BruteForceSearchLimits(resultCap: 2),
      );
      final b = BruteForceCFGParser.search(
        reverse,
        'x',
        limits: const BruteForceSearchLimits(resultCap: 2),
      );

      expect(
        a.witnesses.map((witness) => witness.stableKey),
        b.witnesses.map((witness) => witness.stableKey),
      );
    });

    test('agrees with Earley on compatible recursive CFG inputs', () {
      final source = grammar(
        terminals: {'a', 'b'},
        nonTerminals: {'S'},
        productions: [
          p(id: 'grow', leftSide: ['S'], rightSide: ['a', 'S']),
          p(id: 'leaf', leftSide: ['S'], rightSide: ['b']),
        ],
      );

      for (final input in ['b', 'ab', 'aab', '', 'a', 'ba']) {
        final brute = BruteForceCFGParser.search(source, input);
        final earley = GrammarParser.parse(
          source,
          input,
          strategyHint: ParsingStrategyHint.auto,
        );

        expect(brute.outcome, isNot(BruteForceParseOutcome.boundedUnknown));
        expect(brute.accepted, earley.data!.accepted, reason: input);
      }
    });

    test('reports malformed grammar, input, and limits distinctly', () {
      final source = grammar(
        terminals: {'a'},
        nonTerminals: {'S'},
        productions: [
          p(id: 'leaf', leftSide: ['S'], rightSide: ['a']),
        ],
      );
      final emptyGrammar = source.copyWith(productions: const {});

      expect(
        BruteForceCFGParser.search(emptyGrammar, '').outcome,
        BruteForceParseOutcome.invalidGrammar,
      );
      expect(
        BruteForceCFGParser.search(source, 'x').outcome,
        BruteForceParseOutcome.invalidInput,
      );
      expect(
        BruteForceCFGParser.search(
          source,
          'a',
          limits: const BruteForceSearchLimits(resultCap: 0),
        ).outcome,
        BruteForceParseOutcome.invalidInput,
      );
      final malformedProduction = source.copyWith(
        productions: {
          p(
            id: 'broken',
            leftSide: ['S'],
            rightSide: ['a'],
            isLambda: true,
          ),
        },
      );
      expect(
        BruteForceCFGParser.search(malformedProduction, '').diagnostic,
        BruteForceParseDiagnostic.malformedProduction,
      );
      final overlappingSymbols = grammar(
        terminals: {'S'},
        nonTerminals: {'S'},
        productions: [
          p(id: 'self', leftSide: ['S'], rightSide: ['S']),
        ],
      );
      expect(
        BruteForceCFGParser.search(overlappingSymbols, 'S').diagnostic,
        BruteForceParseDiagnostic.overlappingSymbolDeclaration,
      );
    });

    test('GrammarParser exposes witnesses and boundedUnknown honestly', () {
      final source = grammar(
        terminals: {'a'},
        nonTerminals: {'S'},
        productions: [
          p(id: 'first', leftSide: ['S'], rightSide: ['a']),
          p(id: 'second', leftSide: ['S'], rightSide: ['a']),
        ],
      );

      final accepted = GrammarParser.parseWithReport(
        source,
        'a',
        strategyHint: ParsingStrategyHint.bruteForce,
      );
      final bounded = GrammarParser.parse(
        source,
        'a',
        strategyHint: ParsingStrategyHint.bruteForce,
        timeout: Duration.zero,
      );

      expect(accepted.isSuccess, isTrue);
      expect(accepted.data!.trees, hasLength(2));
      expect(accepted.data!.isAmbiguous, isTrue);
      expect(accepted.data!.bruteForceResult!.witnessCount, 2);
      expect(bounded.isSuccess, isTrue);
      expect(bounded.data!.accepted, isFalse);
      expect(bounded.data!.outcome, GrammarParseOutcome.boundedUnknown);
      expect(
        bounded.data!.bruteForceResult!.limit,
        BruteForceSearchLimit.time,
      );
    });
  });
}
