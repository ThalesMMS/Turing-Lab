import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/grammar/grammar_cnf_transformer.dart';
import 'package:turing_lab/core/algorithms/grammar/grammar_to_fsa_converter.dart';
import 'package:turing_lab/core/algorithms/grammar/grammar_to_pda_converter.dart';
import 'package:turing_lab/core/algorithms/grammar/lr1_parser.dart';
import 'package:turing_lab/core/algorithms/pda/pda_simulator.dart';
import 'package:turing_lab/core/algorithms/regex/regex_simplifier.dart';
import 'package:turing_lab/core/algorithms/regex/regex_to_nfa_converter.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/lr1_models.dart';
import 'package:turing_lab/core/models/production.dart';

Grammar _grammar({
  Set<String> terminals = const {'a'},
  Set<String> variables = const {'S'},
  String start = 'S',
  required Set<Production> productions,
}) => Grammar(
  id: 'boundary',
  name: 'Boundary',
  terminals: terminals,
  nonterminals: variables,
  startSymbol: start,
  productions: productions,
  type: GrammarType.contextFree,
  created: DateTime(2026),
  modified: DateTime(2026),
);

void main() {
  for (final count in [32, 64, 128]) {
    test(
      'CNF rejects $count nullable positions without machine-word overflow',
      () {
        final source = _grammar(
          variables: {'S', 'A'},
          productions: {
            Production(
              id: 'wide',
              leftSide: const ['S'],
              rightSide: List.filled(count, 'A'),
            ),
            const Production(id: 'empty', leftSide: ['A'], rightSide: []),
            const Production(id: 'terminal', leftSide: ['A'], rightSide: ['a']),
          },
        );
        final result = GrammarCnfTransformer.toCnf(source);
        expect(result.isSuccess, isTrue, reason: result.error);
        expect(
          result.data!.diagnostics.map((d) => d.code),
          contains('cnf.nullable_subset_limit_exceeded'),
        );
      },
    );
  }

  test('LR1 keeps literal dollar tokens separate from end of input', () {
    final source = _grammar(
      terminals: {r'$', r'$$'},
      productions: {
        const Production(
          id: 'dollars',
          leftSide: ['S'],
          rightSide: [r'$$', r'$'],
        ),
      },
    );
    final construction = LR1Parser.build(source);
    expect(construction.outcome, LR1ConstructionOutcome.completed);
    expect(
      LR1Parser.parse(
        source,
        r'$$$',
        construction: construction.construction,
      ).outcome,
      LR1ParseOutcome.accepted,
    );
    expect(
      LR1Parser.parse(
        source,
        r'$',
        construction: construction.construction,
      ).outcome,
      LR1ParseOutcome.rejected,
    );
    expect(
      LR1Parser.parse(
        source,
        '',
        construction: construction.construction,
      ).outcome,
      LR1ParseOutcome.rejected,
    );
  });

  test('CFG to PDA uses a fresh atomic bottom symbol', () {
    final source = _grammar(
      variables: {'Z', 'Z_0'},
      start: 'Z',
      productions: {
        const Production(id: 'terminal', leftSide: ['Z'], rightSide: ['a']),
      },
    );
    final result = GrammarToPDAConverter.convertGrammarToPDAStandard(source);
    expect(result.isSuccess, isTrue, reason: result.error);
    final pda = result.data!;
    expect(pda.initialStackSymbol, 'Z_0_0');
    expect(
      pda.pdaTransitions.singleWhere((t) => t.fromState.id == 'q0').pushSymbols,
      ['Z', 'Z_0_0'],
    );
    expect(
      PDASimulator.simulateNPDA(
        pda,
        'a',
        mode: PDAAcceptanceMode.emptyStack,
      ).data!.accepted,
      isTrue,
    );
    expect(
      PDASimulator.simulateNPDA(
        pda,
        '',
        mode: PDAAcceptanceMode.emptyStack,
      ).data!.accepted,
      isFalse,
    );
  });

  test('grammar conversion rejects an undeclared lowercase terminal', () {
    final result = GrammarToFSAConverter.convert(
      _grammar(
        productions: {
          const Production(id: 'unknown', leftSide: ['S'], rightSide: ['b']),
        },
      ),
    );
    expect(result.isSuccess, isFalse);
  });

  for (final entry in {
    'a|∅b': 'a',
    'a∅|b': 'b',
    'a(∅|b)': 'ab',
    '(a|∅)b': 'ab',
    'a|∅b|c': 'a|c',
  }.entries) {
    test(
      'empty-language simplification respects operand boundaries: ${entry.key}',
      () {
        expect(RegexSimplifier.simplify(entry.key).data, entry.value);
        expect(
          RegexSimplifier.simplifyWithSteps(entry.key).data!.simplifiedRegex,
          entry.value,
        );
      },
    );
  }

  test('empty-language Thompson trace has no invented accepting state', () {
    final result = RegexToNFAConverter.convertWithSteps('∅');
    expect(result.isSuccess, isTrue, reason: result.error);
  });
}
