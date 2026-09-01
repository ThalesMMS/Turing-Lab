import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/brute_force_cfg_parser.dart';
import 'package:turing_lab/core/algorithms/cfg/cyk_parser.dart';
import 'package:turing_lab/core/algorithms/grammar_parser.dart';
import 'package:turing_lab/core/algorithms/grammar_parser_simple_recursive.dart';
import 'package:turing_lab/core/models/brute_force_parse_models.dart';
import 'package:turing_lab/core/models/derivation_tree.dart';
import 'package:turing_lab/core/models/derivation_tree_node.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/production.dart';

void main() {
  test(
    'all brute-force derivation modes retain the complete tree frontier',
    () {
      for (final mode in BruteForceDerivationMode.values) {
        final result = BruteForceCFGParser.search(
          testGrammar,
          testInput,
          mode: mode,
          limits: const BruteForceSearchLimits(
            resultCap: 1,
            timeLimit: Duration(seconds: 2),
          ),
        );

        expect(result.accepted, isTrue, reason: 'mode=${mode.name}');
        expect(result.witnesses, isNotEmpty, reason: 'mode=${mode.name}');
        _expectOriginalTree(result.witnesses.first.tree);
      }
    },
  );

  test('automatic parsing exposes a non-shallow derivation tree', () {
    final report = GrammarParser.parseWithReport(
      testGrammar,
      testInput,
      strategyHint: ParsingStrategyHint.auto,
    ).data!;

    expect(report.accepted, isTrue);
    expect(report.trees, isNotEmpty);
    expect(report.isAmbiguous, isTrue);
    expect(report.trees.first.isShallow, isFalse);
    for (final tree in report.trees) {
      _expectOriginalTree(tree);
    }

    final legacy = GrammarParser.parse(testGrammar, testInput).data!;
    expect(legacy.accepted, isTrue);
    expect(legacy.tree, isNotNull);
    expect(legacy.tree!.isShallow, isFalse);
    _expectOriginalTree(legacy.tree!);
  });

  test('CYK parsing exposes the reconstructed tree through the report', () {
    final report = GrammarParser.parseWithReport(
      testGrammar,
      testInput,
      strategyHint: ParsingStrategyHint.cyk,
    ).data!;

    expect(report.accepted, isTrue);
    expect(report.trees, isNotEmpty);
    expect(report.trees.first.isShallow, isFalse);
    expect(report.trees.first.root.symbol, 'S');
    expect(_yield(report.trees.first.root), testInput);
    _expectOriginalTree(report.trees.first);

    final steps = CYKParser.parseWithSteps(testGrammar, testInput).data!;
    expect(steps.accepted, isTrue);
    expect(steps.derivation, isNotNull);
  });

  test('recursive descent preserves nested and epsilon nodes', () {
    final nestedGrammar = Grammar(
      id: 'recursive-tree-regression',
      name: 'Recursive tree regression grammar',
      terminals: {'a', 'b'},
      nonterminals: {'S', 'A'},
      startSymbol: 'S',
      productions: {
        const Production(
          id: 'nested-start',
          leftSide: ['S'],
          rightSide: ['A', 'b'],
        ),
        const Production(id: 'nested-leaf', leftSide: ['A'], rightSide: ['a']),
      },
      type: GrammarType.contextFree,
      created: DateTime.utc(2026),
      modified: DateTime.utc(2026),
    );
    final nestedReport = SimpleRecursiveDescentParser(
      nestedGrammar,
    ).parseWithReport('ab').data!;
    final nestedTree = nestedReport.trees.single.root;

    expect(nestedReport.accepted, isTrue);
    expect(nestedTree.symbol, 'S');
    expect(nestedTree.children.map((child) => child.symbol), ['A', 'b']);
    expect(nestedTree.children.first.children.single.symbol, 'a');
    expect(nestedTree.children.last.start, 1);
    expect(nestedTree.children.last.end, 2);

    final emptyGrammar = Grammar(
      id: 'recursive-epsilon-tree-regression',
      name: 'Recursive epsilon tree regression grammar',
      terminals: const {},
      nonterminals: const {'S', 'A'},
      startSymbol: 'S',
      productions: {
        const Production(
          id: 'epsilon-start',
          leftSide: ['S'],
          rightSide: ['A'],
        ),
        const Production(
          id: 'epsilon-leaf',
          leftSide: ['A'],
          rightSide: [],
          isLambda: true,
        ),
      },
      type: GrammarType.contextFree,
      created: DateTime.utc(2026),
      modified: DateTime.utc(2026),
    );
    final emptyTree = SimpleRecursiveDescentParser(
      emptyGrammar,
    ).parseWithReport('').data!.trees.single.root;

    expect(emptyTree.symbol, 'S');
    expect(emptyTree.children.single.symbol, 'A');
    expect(emptyTree.children.single.children.single.symbol, 'ε');
  });
}

void _expectOriginalTree(DerivationTree tree) {
  expect(tree.root.symbol, 'S');
  expect(_yield(tree.root), testInput);
  _validateOriginalNode(tree.root);
}

void _validateOriginalNode(DerivationTreeNode node) {
  if (node.symbol == 'ε') {
    expect(node.children, isEmpty);
    return;
  }
  if (testGrammar.terminals.contains(node.symbol)) {
    expect(node.children, isEmpty, reason: 'terminal ${node.symbol}');
    return;
  }

  final childSymbols = node.children.map((child) => child.symbol).toList();
  final matchesProduction = testGrammar.productions
      .where((production) => production.leftSide.single == node.symbol)
      .any(
        (production) => _sameSymbols(
          childSymbols,
          production.isLambda ? const ['ε'] : production.rightSide,
        ),
      );
  expect(
    matchesProduction,
    isTrue,
    reason: '${node.symbol} -> ${childSymbols.join(' ')}',
  );
  for (final child in node.children) {
    _validateOriginalNode(child);
  }
}

bool _sameSymbols(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

String _yield(DerivationTreeNode node) {
  if (node.symbol == 'ε') return '';
  if (testGrammar.terminals.contains(node.symbol)) return node.symbol;
  return node.children.map(_yield).join();
}

final testGrammar = Grammar(
  id: 'derivation-tree-regression',
  name: 'Derivation tree regression grammar',
  terminals: {'a', 'b'},
  nonterminals: {'S', 'A'},
  startSymbol: 'S',
  productions: {
    const Production(id: 'p1', leftSide: ['S'], rightSide: ['A'], order: 0),
    const Production(
      id: 'p2',
      leftSide: ['A'],
      rightSide: ['A', 'a'],
      order: 1,
    ),
    const Production(
      id: 'p3',
      leftSide: ['A'],
      rightSide: ['A', 'A'],
      order: 2,
    ),
    const Production(
      id: 'p4',
      leftSide: ['A'],
      rightSide: ['a', 'b'],
      order: 3,
    ),
    const Production(id: 'p5', leftSide: ['A'], rightSide: ['a'], order: 4),
    const Production(
      id: 'p6',
      leftSide: ['A'],
      rightSide: [],
      isLambda: true,
      order: 5,
    ),
  },
  type: GrammarType.contextFree,
  created: DateTime.utc(2026),
  modified: DateTime.utc(2026),
);

const testInput = 'abaaab';
