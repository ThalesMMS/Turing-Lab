import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/brute_force_cfg_parser.dart';
import 'package:turing_lab/core/algorithms/grammar_parser.dart';
import 'package:turing_lab/core/models/brute_force_parse_models.dart';
import 'package:turing_lab/core/models/derivation_tree.dart';
import 'package:turing_lab/core/models/derivation_tree_node.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/production.dart';

void main() {
  test('Automatic exposes a tree when the fast Dyck recognizer accepts', () {
    final grammar = _grammar(
      id: 'automatic-dyck',
      terminals: {'(', ')'},
      nonterminals: {'S'},
      productions: {
        const Production(id: 'concat', leftSide: ['S'], rightSide: ['S', 'S']),
        const Production(
          id: 'wrapped',
          leftSide: ['S'],
          rightSide: ['(', 'S', ')'],
        ),
        const Production(
          id: 'empty',
          leftSide: ['S'],
          rightSide: [],
          isLambda: true,
        ),
      },
    );

    final oracle = BruteForceCFGParser.search(
      grammar,
      '()',
      limits: const BruteForceSearchLimits(
        maxDepth: 8,
        resultCap: 1,
        timeLimit: Duration(seconds: 2),
      ),
    );
    final automatic = GrammarParser.parseWithReport(
      grammar,
      '()',
      strategyHint: ParsingStrategyHint.auto,
    ).data!;

    expect(oracle.accepted, isTrue);
    expect(automatic.accepted, isTrue);
    expect(automatic.trees, isNotEmpty);
    _expectSourceTree(grammar, automatic.trees.first, '()');
  });

  test(
    'Automatic agrees with bounded Brute Force across grammar edge cases',
    () {
      final cases = <_DifferentialCase>[
        _DifferentialCase(
          name: 'nullable',
          grammar: _grammar(
            id: 'automatic-nullable',
            terminals: {'a', 'b'},
            nonterminals: {'S', 'A', 'B'},
            productions: {
              const Production(
                id: 'start',
                leftSide: ['S'],
                rightSide: ['A', 'B'],
              ),
              const Production(id: 'a', leftSide: ['A'], rightSide: ['a']),
              const Production(
                id: 'empty-a',
                leftSide: ['A'],
                rightSide: [],
                isLambda: true,
              ),
              const Production(id: 'b', leftSide: ['B'], rightSide: ['b']),
              const Production(
                id: 'empty-b',
                leftSide: ['B'],
                rightSide: [],
                isLambda: true,
              ),
            },
          ),
          accepted: ['', 'a', 'b', 'ab'],
          rejected: ['ba', 'aa', 'bb'],
        ),
        _DifferentialCase(
          name: 'ambiguous-left-recursive',
          grammar: _grammar(
            id: 'automatic-ambiguous',
            terminals: {'a', 'b'},
            nonterminals: {'S', 'A'},
            productions: {
              const Production(id: 'start', leftSide: ['S'], rightSide: ['A']),
              const Production(
                id: 'append',
                leftSide: ['A'],
                rightSide: ['A', 'a'],
              ),
              const Production(
                id: 'join',
                leftSide: ['A'],
                rightSide: ['A', 'A'],
              ),
              const Production(
                id: 'ab',
                leftSide: ['A'],
                rightSide: ['a', 'b'],
              ),
              const Production(id: 'a', leftSide: ['A'], rightSide: ['a']),
              const Production(
                id: 'empty',
                leftSide: ['A'],
                rightSide: [],
                isLambda: true,
              ),
            },
          ),
          accepted: ['', 'a', 'ab', 'abaaab'],
          rejected: ['b', 'ba', 'bbb'],
        ),
        _DifferentialCase(
          name: 'overlapping-terminals',
          grammar: _grammar(
            id: 'automatic-overlap',
            terminals: {'a', 'aa', 'b'},
            nonterminals: {'S'},
            productions: {
              const Production(id: 'aa', leftSide: ['S'], rightSide: ['aa']),
              const Production(
                id: 'ab',
                leftSide: ['S'],
                rightSide: ['a', 'b'],
              ),
            },
          ),
          accepted: ['aa', 'ab'],
          rejected: ['a', 'aaa', 'b'],
        ),
        _DifferentialCase(
          name: 'declared-whitespace',
          grammar: _grammar(
            id: 'automatic-whitespace',
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
      ];

      for (final testCase in cases) {
        for (final input in [...testCase.accepted, ...testCase.rejected]) {
          final oracle = BruteForceCFGParser.search(
            testCase.grammar,
            input,
            limits: const BruteForceSearchLimits(
              maxDepth: 12,
              resultCap: 3,
              timeLimit: Duration(seconds: 2),
            ),
          );
          final automaticResult = GrammarParser.parseWithReport(
            testCase.grammar,
            input,
            timeout: const Duration(seconds: 2),
            maxTrees: 3,
            strategyHint: ParsingStrategyHint.auto,
          );
          final automatic = automaticResult.data;

          expect(
            automaticResult.isSuccess,
            isTrue,
            reason: '${testCase.name}: $input',
          );
          expect(
            automatic?.accepted,
            oracle.accepted,
            reason: '${testCase.name}: $input',
          );
          if (oracle.accepted) {
            expect(
              automatic!.trees,
              isNotEmpty,
              reason: '${testCase.name}: $input should expose a witness tree',
            );
            _expectSourceTree(testCase.grammar, automatic.trees.first, input);
          }
        }
      }
    },
  );
}

Grammar _grammar({
  required String id,
  required Set<String> terminals,
  required Set<String> nonterminals,
  required Set<Production> productions,
  String startSymbol = 'S',
}) => Grammar(
  id: id,
  name: id,
  terminals: terminals,
  nonterminals: nonterminals,
  startSymbol: startSymbol,
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
      return node.lexeme ?? node.symbol;
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

class _DifferentialCase {
  const _DifferentialCase({
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
