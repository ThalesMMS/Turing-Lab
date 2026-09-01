import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/grammar_to_pda_converter.dart';
import 'package:turing_lab/core/algorithms/grammar_parser.dart';
import 'package:turing_lab/core/algorithms/pda_simulator.dart';
import 'package:turing_lab/core/algorithms/pda_to_cfg_converter.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/production.dart';

void main() {
  test('preserves bounded language through CFG-PDA-CFG round trips', () {
    final cases = <_RoundTripCase>[
      _RoundTripCase(
        name: 'balanced delimiters',
        grammar: _grammar(
          id: 'round-trip-balanced',
          terminals: {'a', 'b'},
          nonterminals: {'S'},
          productions: {
            const Production(
              id: 'wrap',
              leftSide: ['S'],
              rightSide: ['a', 'S', 'b'],
            ),
            const Production(
              id: 'empty',
              leftSide: ['S'],
              rightSide: [],
              isLambda: true,
              order: 1,
            ),
          },
        ),
        accepted: ['', 'ab', 'aabb', 'aaabbb'],
        rejected: ['a', 'aab', 'abb', 'ba'],
      ),
      _RoundTripCase(
        name: 'atomic multi-character terminals',
        grammar: _grammar(
          id: 'round-trip-atomic-terminals',
          terminals: {'id', ' ', '+'},
          nonterminals: {'S'},
          productions: {
            const Production(
              id: 'expression',
              leftSide: ['S'],
              rightSide: ['id', ' ', '+', ' ', 'id'],
            ),
          },
        ),
        accepted: ['id + id'],
        rejected: ['id+id', 'id  + id'],
      ),
      _RoundTripCase(
        name: 'grammar analysis witness',
        grammar: _grammar(
          id: 'round-trip-witness',
          terminals: {'a', 'b'},
          nonterminals: {'S', 'A'},
          productions: {
            const Production(id: 'start', leftSide: ['S'], rightSide: ['A']),
            const Production(
              id: 'append',
              leftSide: ['A'],
              rightSide: ['A', 'a'],
              order: 1,
            ),
            const Production(
              id: 'join',
              leftSide: ['A'],
              rightSide: ['A', 'A'],
              order: 2,
            ),
            const Production(
              id: 'ab',
              leftSide: ['A'],
              rightSide: ['a', 'b'],
              order: 3,
            ),
            const Production(
              id: 'a',
              leftSide: ['A'],
              rightSide: ['a'],
              order: 4,
            ),
            const Production(
              id: 'empty',
              leftSide: ['A'],
              rightSide: [],
              isLambda: true,
              order: 5,
            ),
          },
        ),
        accepted: ['a', 'ab', 'abaaab'],
        rejected: ['b', 'ba', 'bbb'],
        useGreibach: true,
      ),
    ];

    for (final testCase in cases) {
      final conversion = testCase.useGreibach
          ? GrammarToPDAConverter.convertGrammarToPDAGreibach(testCase.grammar)
          : GrammarToPDAConverter.convertGrammarToPDAStandard(testCase.grammar);
      expect(
        conversion.isSuccess,
        isTrue,
        reason: '${testCase.name}: ${conversion.error}',
      );
      final pda = conversion.data!;

      for (final input in [...testCase.accepted, ...testCase.rejected]) {
        final simulation = PDASimulator.simulateNPDA(
          pda,
          input,
          timeout: const Duration(seconds: 2),
          maxDepth: 1000,
          maxConfigurations: 100000,
        );
        expect(
          simulation.isSuccess,
          isTrue,
          reason: '${testCase.name}: PDA simulation failed for "$input"',
        );
        expect(
          simulation.data!.outcome,
          anyOf(PDASimulationOutcome.accepted, PDASimulationOutcome.rejected),
          reason: '${testCase.name}: inconclusive PDA result for "$input"',
        );
        expect(
          simulation.data!.accepted,
          testCase.accepted.contains(input),
          reason: '${testCase.name}: PDA mismatch for "$input"',
        );
      }

      final roundTrip = PDAtoCFGConverter.convert(
        pda,
        maxGeneratedProductions: 100000,
      );
      expect(
        roundTrip.isSuccess,
        isTrue,
        reason: '${testCase.name}: ${roundTrip.error}',
      );
      final convertedGrammar = roundTrip.data!.grammar;

      for (final input in [...testCase.accepted, ...testCase.rejected]) {
        final parse = GrammarParser.parseWithReport(
          convertedGrammar,
          input,
          strategyHint: ParsingStrategyHint.auto,
          timeout: const Duration(seconds: 2),
        );
        expect(
          parse.isSuccess,
          isTrue,
          reason: '${testCase.name}: round-trip parse failed for "$input"',
        );
        expect(
          parse.data!.accepted,
          testCase.accepted.contains(input),
          reason: '${testCase.name}: round-trip CFG mismatch for "$input"',
        );
      }
    }
  });
}

Grammar _grammar({
  required String id,
  required Set<String> terminals,
  required Set<String> nonterminals,
  required Set<Production> productions,
}) {
  final timestamp = DateTime.utc(2026, 9, 1);
  return Grammar(
    id: id,
    name: id,
    terminals: terminals,
    nonterminals: nonterminals,
    startSymbol: 'S',
    productions: productions,
    type: GrammarType.contextFree,
    created: timestamp,
    modified: timestamp,
  );
}

class _RoundTripCase {
  const _RoundTripCase({
    required this.name,
    required this.grammar,
    required this.accepted,
    required this.rejected,
    this.useGreibach = false,
  });

  final String name;
  final Grammar grammar;
  final List<String> accepted;
  final List<String> rejected;
  final bool useGreibach;
}
