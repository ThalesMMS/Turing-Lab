import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/cfg/cyk_parser.dart';
import 'package:turing_lab/core/algorithms/grammar_parser.dart';
import 'package:turing_lab/core/models/derivation_tree.dart';
import 'package:turing_lab/core/models/derivation_tree_node.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/production.dart';

void main() {
  test('CYK preserves source trees across CNF normalization boundaries', () {
    final cases = <_CykCase>[
      _CykCase(
        name: 'nullable long rhs',
        grammar: _grammar(
          id: 'cyk-nullable-long-rhs',
          terminals: {'a', 'b', 'c'},
          nonterminals: {'S', 'A', 'B', 'C'},
          productions: {
            const Production(
              id: 'start',
              leftSide: ['S'],
              rightSide: ['A', 'B', 'C'],
            ),
            const Production(id: 'a', leftSide: ['A'], rightSide: ['a']),
            const Production(
              id: 'empty-a',
              leftSide: ['A'],
              rightSide: [],
              isLambda: true,
            ),
            const Production(id: 'b', leftSide: ['B'], rightSide: ['b']),
            const Production(id: 'c', leftSide: ['C'], rightSide: ['c']),
          },
        ),
        accepted: ['abc', 'bc'],
        rejected: ['ac', 'abb'],
      ),
      _CykCase(
        name: 'unit chain',
        grammar: _grammar(
          id: 'cyk-unit-chain',
          terminals: {'a'},
          nonterminals: {'S', 'A', 'B'},
          productions: {
            const Production(id: 's-a', leftSide: ['S'], rightSide: ['A']),
            const Production(id: 'a-b', leftSide: ['A'], rightSide: ['B']),
            const Production(id: 'b-a', leftSide: ['B'], rightSide: ['a']),
          },
        ),
        accepted: ['a'],
        rejected: ['', 'aa'],
      ),
      _CykCase(
        name: 'start symbol on rhs',
        grammar: _grammar(
          id: 'cyk-start-on-rhs',
          terminals: {'a', 'b'},
          nonterminals: {'S'},
          productions: {
            const Production(
              id: 'grow',
              leftSide: ['S'],
              rightSide: ['a', 'S'],
            ),
            const Production(id: 'finish', leftSide: ['S'], rightSide: ['b']),
          },
        ),
        accepted: ['b', 'ab', 'aab'],
        rejected: ['', 'a', 'ba'],
      ),
      _CykCase(
        name: 'multi-character terminals',
        grammar: _grammar(
          id: 'cyk-multi-character',
          terminals: {'id', '='},
          nonterminals: {'S'},
          productions: {
            const Production(
              id: 'assignment',
              leftSide: ['S'],
              rightSide: ['id', '=', 'id'],
            ),
          },
        ),
        accepted: ['id=id'],
        rejected: ['id', 'id==id'],
      ),
      _CykCase(
        name: 'declared whitespace terminal',
        grammar: _grammar(
          id: 'cyk-whitespace-terminal',
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
      _CykCase(
        name: 'collision-safe helpers',
        grammar: _grammar(
          id: 'cyk-helper-collisions',
          terminals: {'a', 'b', 'c'},
          nonterminals: {'S', 'N0', 'T0'},
          productions: {
            const Production(
              id: 'long',
              leftSide: ['S'],
              rightSide: ['a', 'b', 'c'],
            ),
          },
        ),
        accepted: ['abc'],
        rejected: ['ab', 'ac'],
      ),
    ];

    for (final testCase in cases) {
      final original = testCase.grammar.toJson();
      for (final input in [...testCase.accepted, ...testCase.rejected]) {
        final reportResult = GrammarParser.parseWithReport(
          testCase.grammar,
          input,
          timeout: const Duration(seconds: 2),
          strategyHint: ParsingStrategyHint.cyk,
        );
        final report = reportResult.data;
        final expectedAccepted = testCase.accepted.contains(input);

        expect(
          reportResult.isSuccess,
          isTrue,
          reason: '${testCase.name}: $input',
        );
        expect(
          report?.accepted,
          expectedAccepted,
          reason: '${testCase.name}: $input',
        );

        final steppedResult = CYKParser.parseWithSteps(
          testCase.grammar,
          input,
          timeout: const Duration(seconds: 2),
        );
        expect(
          steppedResult.isSuccess,
          isTrue,
          reason: '${testCase.name}: $input steps',
        );
        expect(
          steppedResult.data!.accepted,
          expectedAccepted,
          reason: '${testCase.name}: $input steps',
        );

        if (expectedAccepted) {
          expect(
            report!.trees,
            isNotEmpty,
            reason: '${testCase.name}: $input source tree',
          );
          _expectSourceTree(testCase.grammar, report.trees.first, input);
          expect(steppedResult.data!.derivation, isNotNull);
        } else {
          expect(report!.trees, isEmpty);
          expect(steppedResult.data!.derivation, isNull);
        }
      }
      expect(testCase.grammar.toJson(), original, reason: testCase.name);
    }
  });
}

Grammar _grammar({
  required String id,
  required Set<String> terminals,
  required Set<String> nonterminals,
  required Set<Production> productions,
}) => Grammar(
  id: id,
  name: id,
  terminals: terminals,
  nonterminals: nonterminals,
  startSymbol: 'S',
  productions: productions,
  type: GrammarType.contextFree,
  created: DateTime.utc(2026),
  modified: DateTime.utc(2026),
);

void _expectSourceTree(Grammar grammar, DerivationTree tree, String input) {
  expect(tree.isShallow, isFalse);
  expect(tree.root.symbol, grammar.startSymbol);

  String visit(DerivationTreeNode node) {
    if (grammar.terminals.contains(node.symbol)) {
      expect(node.children, isEmpty, reason: 'terminal ${node.symbol}');
      expect(node.lexeme, isNotNull, reason: 'terminal ${node.symbol}');
      return node.lexeme!;
    }
    if (node.symbol == 'ε') {
      expect(node.children, isEmpty);
      return '';
    }

    expect(grammar.nonterminals, contains(node.symbol));
    final childSymbols = node.children.map((child) => child.symbol).toList();
    final validProduction = grammar.productions
        .where((production) => production.leftSide.single == node.symbol)
        .any((production) {
          final right = production.isLambda
              ? const ['ε']
              : production.rightSide;
          return _sameSymbols(childSymbols, right);
        });
    expect(validProduction, isTrue, reason: '${node.symbol} -> $childSymbols');
    return node.children.map(visit).join();
  }

  expect(visit(tree.root), input);
}

bool _sameSymbols(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

class _CykCase {
  const _CykCase({
    required this.name,
    required this.grammar,
    required this.accepted,
    required this.rejected,
  });

  final String name;
  final Grammar grammar;
  final List<String> accepted;
  final List<String> rejected;
}
