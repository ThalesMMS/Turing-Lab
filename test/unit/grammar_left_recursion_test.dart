import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/grammar_analyzer.dart';
import 'package:turing_lab/core/algorithms/grammar_analysis_messages.dart';
import 'package:turing_lab/core/algorithms/grammar_parser_earley.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/production.dart';

void main() {
  final timestamp = DateTime(2026, 1, 1);

  Grammar grammar({
    required String id,
    required String start,
    required List<String> nonterminals,
    required List<String> terminals,
    required List<Production> productions,
  }) {
    return Grammar(
      id: id,
      name: id,
      terminals: terminals.toSet(),
      nonterminals: nonterminals.toSet(),
      startSymbol: start,
      productions: productions.toSet(),
      type: GrammarType.contextFree,
      created: timestamp,
      modified: timestamp,
    );
  }

  Production production(
    String id,
    int order,
    String left,
    List<String> right, {
    bool isLambda = false,
  }) {
    return Production(
      id: id,
      order: order,
      leftSide: [left],
      rightSide: right,
      isLambda: isLambda,
    );
  }

  List<String> formattedProductions(Grammar value) {
    final productions = value.productions.toList()
      ..sort((left, right) {
        final order = left.order.compareTo(right.order);
        return order != 0 ? order : left.id.compareTo(right.id);
      });
    return productions.map((production) {
      final right = production.isLambda || production.rightSide.isEmpty
          ? 'ε'
          : production.rightSide.join(' ');
      return '${production.leftSide.single} -> $right';
    }).toList();
  }

  bool hasLeftCornerCycle(Grammar value) {
    final graph = <String, Set<String>>{
      for (final nonterminal in value.nonterminals) nonterminal: <String>{},
    };
    for (final production in value.productions) {
      if (production.leftSide.length != 1 || production.rightSide.isEmpty) {
        continue;
      }
      final left = production.leftSide.single;
      final corner = production.rightSide.first;
      if (graph.containsKey(left) && value.nonterminals.contains(corner)) {
        graph[left]!.add(corner);
      }
    }

    bool visit(String node, Set<String> visiting, Set<String> visited) {
      if (visiting.contains(node)) return true;
      if (!visited.add(node)) return false;
      visiting.add(node);
      for (final next in graph[node]!) {
        if (visit(next, visiting, visited)) return true;
      }
      visiting.remove(node);
      return false;
    }

    final visited = <String>{};
    return graph.keys.any((node) => visit(node, <String>{}, visited));
  }

  Iterable<String> boundedWords(List<String> alphabet, int maxLength) sync* {
    Iterable<String> wordsOfLength(int length) sync* {
      if (length == 0) {
        yield '';
        return;
      }
      for (final prefix in wordsOfLength(length - 1)) {
        for (final symbol in alphabet) {
          yield '$prefix$symbol';
        }
      }
    }

    for (var length = 0; length <= maxLength; length++) {
      yield* wordsOfLength(length);
    }
  }

  void expectSameBoundedLanguage(
    Grammar original,
    Grammar transformed,
    List<String> alphabet,
    int maxLength,
  ) {
    final originalParser = EarleyRecognizer(original);
    final transformedParser = EarleyRecognizer(transformed);
    for (final word in boundedWords(alphabet, maxLength)) {
      expect(
        transformedParser.recognizes(word),
        originalParser.recognizes(word),
        reason: 'Language differs for "$word".',
      );
    }
  }

  group('ordered left-recursion elimination', () {
    test('retains the direct-recursion rewrite', () {
      final input = grammar(
        id: 'direct',
        start: 'A',
        nonterminals: ['A'],
        terminals: ['a', 'b'],
        productions: [
          production('p0', 0, 'A', ['A', 'a']),
          production('p1', 1, 'A', ['b']),
        ],
      );

      final result = GrammarAnalyzer.removeLeftRecursion(input);

      expect(result.isSuccess, isTrue);
      expect(
        formattedProductions(result.data!.value),
        ["A -> b A'", "A' -> a A'", "A' -> ε"],
      );
      expect(result.data!.steps, hasLength(1));
      expect(
          result.data!.steps.single.operation, startsWith('Direct recursion'));
    });

    test('eliminates a two-nonterminal cycle and preserves bounded language',
        () {
      final input = grammar(
        id: 'two-cycle',
        start: 'S',
        nonterminals: ['S', 'A'],
        terminals: ['a', 'b', 'c', 'd'],
        productions: [
          production('p0', 0, 'S', ['A', 'a']),
          production('p1', 1, 'S', ['b']),
          production('p2', 2, 'A', ['S', 'c']),
          production('p3', 3, 'A', ['d']),
        ],
      );

      final result = GrammarAnalyzer.removeLeftRecursion(input);

      expect(result.isSuccess, isTrue);
      final report = result.data!;
      expect(hasLeftCornerCycle(report.value), isFalse);
      expect(
        report.steps.any((step) => step.operation.startsWith('Substitution')),
        isTrue,
      );
      expect(
        report.steps.any(
          (step) => step.operation.startsWith('Direct recursion'),
        ),
        isTrue,
      );
      expectSameBoundedLanguage(input, report.value, ['a', 'b', 'c', 'd'], 4);
    });

    test('eliminates a three-nonterminal cycle', () {
      final input = grammar(
        id: 'three-cycle',
        start: 'S',
        nonterminals: ['S', 'A', 'B'],
        terminals: ['x', 'y', 'z', 's', 'a', 'b'],
        productions: [
          production('p0', 0, 'S', ['A', 'x']),
          production('p1', 1, 'S', ['s']),
          production('p2', 2, 'A', ['B', 'y']),
          production('p3', 3, 'A', ['a']),
          production('p4', 4, 'B', ['S', 'z']),
          production('p5', 5, 'B', ['b']),
        ],
      );

      final result = GrammarAnalyzer.removeLeftRecursion(input);

      expect(result.isSuccess, isTrue);
      expect(hasLeftCornerCycle(result.data!.value), isFalse);
      expect(
        result.data!.steps
            .where((step) => step.operation.startsWith('Substitution')),
        isNotEmpty,
      );
    });

    test('handles direct and indirect recursion in the same grammar', () {
      final input = grammar(
        id: 'mixed',
        start: 'S',
        nonterminals: ['S', 'A'],
        terminals: ['x', 'y', 'z', 's', 'a'],
        productions: [
          production('p0', 0, 'S', ['S', 'x']),
          production('p1', 1, 'S', ['A', 'y']),
          production('p2', 2, 'S', ['s']),
          production('p3', 3, 'A', ['S', 'z']),
          production('p4', 4, 'A', ['a']),
        ],
      );

      final result = GrammarAnalyzer.removeLeftRecursion(input);

      expect(result.isSuccess, isTrue);
      expect(hasLeftCornerCycle(result.data!.value), isFalse);
      expect(
        result.data!.steps
            .where((step) => step.operation.startsWith('Direct recursion'))
            .length,
        greaterThanOrEqualTo(2),
      );
    });

    test('preserves epsilon alternatives during substitution', () {
      final input = grammar(
        id: 'epsilon',
        start: 'S',
        nonterminals: ['S', 'A'],
        terminals: ['a', 'c', 'd'],
        productions: [
          production('p0', 0, 'S', ['A', 'a']),
          production(
            'p1',
            1,
            'S',
            const [],
            isLambda: true,
          ),
          production('p2', 2, 'A', ['S', 'c']),
          production('p3', 3, 'A', ['d']),
        ],
      );

      final result = GrammarAnalyzer.removeLeftRecursion(input);

      expect(result.isSuccess, isTrue);
      final transformed = result.data!.value;
      expect(hasLeftCornerCycle(transformed), isFalse);
      expect(
        formattedProductions(transformed),
        contains("A -> c A'"),
      );
      expectSameBoundedLanguage(input, transformed, ['a', 'c', 'd'], 4);
    });

    test('returns a grammar without left recursion by identity', () {
      final input = grammar(
        id: 'no-cycle',
        start: 'S',
        nonterminals: ['S', 'A'],
        terminals: ['a', 's'],
        productions: [
          production('p0', 10, 'S', ['A']),
          production('p1', 20, 'S', ['s']),
          production('p2', 30, 'A', ['a']),
        ],
      );

      final result = GrammarAnalyzer.removeLeftRecursion(input);

      expect(result.isSuccess, isTrue);
      expect(result.data!.value, same(input));
      expect(
        formattedProductions(result.data!.value),
        formattedProductions(input),
      );
      expect(result.data!.steps, isEmpty);
      expect(
        result.data!.notes,
        ['No direct or indirect left recursion detected.'],
      );
      expect(
        result.data!.structuredNotes,
        [GrammarAnalysisMessages.noLeftRecursion()],
      );
    });

    test('processes unreachable recursive nonterminals', () {
      final input = grammar(
        id: 'unreachable',
        start: 'S',
        nonterminals: ['S', 'U', 'V'],
        terminals: ['s', 'x', 'y', 'u', 'v'],
        productions: [
          production('p0', 0, 'S', ['s']),
          production('p1', 1, 'U', ['V', 'x']),
          production('p2', 2, 'U', ['u']),
          production('p3', 3, 'V', ['U', 'y']),
          production('p4', 4, 'V', ['v']),
        ],
      );

      final result = GrammarAnalyzer.removeLeftRecursion(input);

      expect(result.isSuccess, isTrue);
      expect(hasLeftCornerCycle(result.data!.value), isFalse);
      expect(result.data!.value.productions.any((p) => p.leftSide.first == 'S'),
          isTrue);
    });

    test('is deterministic, idempotent, and does not mutate the input', () {
      final input = grammar(
        id: 'stable',
        start: 'S',
        nonterminals: ['S', 'A'],
        terminals: ['a', 'b', 'c', 'd'],
        productions: [
          production('p0', 4, 'S', ['A', 'a']),
          production('p1', 8, 'S', ['b']),
          production('p2', 12, 'A', ['S', 'c']),
          production('p3', 16, 'A', ['d']),
        ],
      );
      final originalJson = input.productions
          .map((production) => production.toJson().toString())
          .toList();

      final first = GrammarAnalyzer.removeLeftRecursion(input).data!;
      final second = GrammarAnalyzer.removeLeftRecursion(input).data!;

      expect(
        formattedProductions(first.value),
        formattedProductions(second.value),
      );
      expect(
        first.value.productions.map((production) => production.id).toList(),
        second.value.productions.map((production) => production.id).toList(),
      );
      expect(first.value.modified, timestamp);
      expect(input.modified, timestamp);
      expect(
        input.productions
            .map((production) => production.toJson().toString())
            .toList(),
        originalJson,
      );

      final repeated = GrammarAnalyzer.removeLeftRecursion(first.value);
      expect(repeated.isSuccess, isTrue);
      expect(repeated.data!.value, same(first.value));
      expect(
        formattedProductions(repeated.data!.value),
        formattedProductions(first.value),
      );
      expect(repeated.data!.steps, isEmpty);
    });
  });
}
