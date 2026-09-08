import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/grammar/brute_force_cfg_parser.dart';
import 'package:turing_lab/core/models/brute_force_parse_models.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/production.dart';

void main() {
  final now = DateTime(2026);

  Grammar grammar({
    String id = 'brute-force-test',
    required Set<String> terminals,
    required Set<String> nonTerminals,
    String start = 'S',
    required Iterable<Production> productions,
  }) => Grammar(
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

  test('caps distinct paths retained for the same intermediate form', () {
    final source = grammar(
      terminals: {'a'},
      nonTerminals: {'S', 'A'},
      productions: [
        for (var i = 0; i < 5; i++)
          p(id: 'path-$i', leftSide: ['S'], rightSide: ['A'], order: i),
        p(id: 'leaf', leftSide: ['A'], rightSide: ['a'], order: 5),
      ],
    );
    final result = BruteForceCFGParser.search(
      source,
      'a',
      limits: const BruteForceSearchLimits(resultCap: 2, maxRetainedStates: 3),
    );
    expect(result.outcome, BruteForceParseOutcome.accepted);
    expect(result.witnesses, hasLength(2));
    expect(
      result.statistics.prunedByReason[BruteForcePruneReason.duplicateWitness],
      3,
    );
    expect(result.statistics.retainedStates, 3);
  });
}
