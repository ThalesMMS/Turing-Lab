import 'dart:isolate';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/grammar/dependency_graph/dependency_graph.dart';
import 'package:turing_lab/core/grammar/phrase_structure/phrase_structure.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/production.dart';

void main() {
  group('variable dependency graph', () {
    test(
      'groups direct edges without losing production or position provenance',
      () {
        final grammar = _grammar(
          nonterminals: {'S', 'A', 'B'},
          terminals: {'x'},
          productions: {
            _production('p2', 'S', ['A', 'x', 'A'], order: 2),
            _production('p1', 'S', ['A', 'B'], order: 1),
            _production('a', 'A', ['x'], order: 3),
            _production('b', 'B', ['x'], order: 4),
          },
        );

        final report = VariableDependencyGraphAnalyzer.analyzeContextFree(
          grammar,
          sourceRevision: 11,
        );
        final edge = report.edges.singleWhere(
          (candidate) => candidate.from == 'S' && candidate.to == 'A',
        );

        expect(report.edges.map((candidate) => candidate.id), [
          'vdg-e0',
          'vdg-e1',
        ]);
        expect(edge.contributions.map((item) => item.productionId), [
          'p1',
          'p2',
          'p2',
        ]);
        expect(edge.contributions.map((item) => item.rightPosition), [0, 0, 2]);
      },
    );

    test('keeps direct, left-corner, and nullable-aware modes distinct', () {
      final grammar = _grammar(
        nonterminals: {'S', 'A', 'B'},
        terminals: {'x'},
        productions: {
          _production('s', 'S', ['A', 'B']),
          _production('a-empty', 'A', const [], lambda: true),
          _production('b', 'B', ['x']),
        },
      );

      Set<String> targets(VariableDependencyMode mode) =>
          VariableDependencyGraphAnalyzer.analyzeContextFree(
                grammar,
                sourceRevision: 1,
                mode: mode,
              ).edges
              .where((edge) => edge.from == 'S')
              .map((edge) => edge.to)
              .toSet();

      expect(targets(VariableDependencyMode.directOccurrence), {'A', 'B'});
      expect(targets(VariableDependencyMode.leftCorner), {'A'});
      expect(targets(VariableDependencyMode.nullableAwareLeftCorner), {
        'A',
        'B',
      });
    });

    test(
      'reports reachability, productivity, SCCs, cycles, sources and sinks',
      () {
        final grammar = _grammar(
          nonterminals: {'S', 'A', 'B', 'U', 'V'},
          terminals: {'x'},
          productions: {
            _production('s', 'S', ['A']),
            _production('a-b', 'A', ['B']),
            _production('b-a', 'B', ['A']),
            _production('b-x', 'B', ['x']),
            _production('u-v', 'U', ['V']),
            _production('v-u', 'V', ['U']),
          },
        );

        final report = VariableDependencyGraphAnalyzer.analyzeContextFree(
          grammar,
          sourceRevision: 4,
        );

        expect(report.reachableVariables, {'S', 'A', 'B'});
        expect(report.unreachableVariables, {'U', 'V'});
        expect(report.productiveVariables, containsAll({'S', 'A', 'B'}));
        expect(report.nonproductiveVariables, {'U', 'V'});
        expect(report.reachabilityWitnesses['B']!.variables, ['S', 'A', 'B']);
        expect(report.reachabilityWitnesses['B']!.productionIds, ['s', 'a-b']);
        expect(report.reachabilityWitnesses, isNot(contains('U')));
        expect(
          report.stronglyConnectedComponents,
          containsAll([
            ['A', 'B'],
            ['U', 'V'],
          ]),
        );
        expect(
          report.cycleWitnesses.map((witness) => witness.variables),
          containsAll([
            ['A', 'B', 'A'],
            ['U', 'V', 'U'],
          ]),
        );
        expect(
          report.cycleWitnesses
              .firstWhere((witness) => witness.variables.first == 'A')
              .productionIds,
          ['a-b', 'b-a'],
        );
        expect(report.sourceVariables, {'S'});
        expect(report.sinkVariables, isEmpty);
      },
    );

    test('is deterministic across production and symbol insertion order', () {
      final productions = [
        _production('s-a', 'S', ['A'], order: 2),
        _production('a-b', 'A', ['B'], order: 0),
        _production('b-a', 'B', ['A'], order: 1),
      ];
      final first = _grammar(
        nonterminals: {'S', 'A', 'B'},
        terminals: {'x'},
        productions: productions.toSet(),
      );
      String signature(Grammar source) {
        final report = VariableDependencyGraphAnalyzer.analyzeContextFree(
          source,
          sourceRevision: 1,
        );
        return [
          report.variables.join(','),
          report.edges
              .map((edge) => '${edge.id}:${edge.from}->${edge.to}')
              .join(','),
          report.stronglyConnectedComponents
              .map((component) => component.join('+'))
              .join(','),
          report.componentTopologicalOrder
              .map((component) => component.join('+'))
              .join(','),
          report.cycleWitnesses
              .map((witness) => witness.productionIds.join('+'))
              .join(','),
        ].join('|');
      }

      final expected = signature(first);
      for (var seed = 0; seed < 12; seed++) {
        final shuffled = [...productions]..shuffle(math.Random(seed));
        final variables = ['S', 'A', 'B']..shuffle(math.Random(seed + 100));
        final candidate = _grammar(
          nonterminals: variables.toSet(),
          terminals: {'x'},
          productions: shuffled.toSet(),
        );
        expect(signature(candidate), expected, reason: 'seed $seed');
      }
    });

    test('supports Unicode variables and self-recursion witnesses', () {
      final grammar = _grammar(
        start: 'Expr🙂',
        nonterminals: {'Expr🙂'},
        terminals: {'token'},
        productions: {
          _production('loop', 'Expr🙂', ['Expr🙂']),
          _production('leaf', 'Expr🙂', ['token']),
        },
      );

      final report = VariableDependencyGraphAnalyzer.analyzeContextFree(
        grammar,
        sourceRevision: 1,
      );

      expect(report.cycleWitnesses.single.variables, ['Expr🙂', 'Expr🙂']);
      expect(report.cycleWitnesses.single.productionIds, ['loop']);
      final summary = report.accessibleSummaryMessages();
      expect(
        summary.map((message) => message.stableCode),
        contains('grammar.dependency-graph.recursion-cycle-count'),
      );
      expect(
        summary
            .singleWhere(
              (message) =>
                  message.stableCode ==
                  'grammar.dependency-graph.recursion-cycle-count',
            )
            .arguments['cycle-count']!
            .value,
        1,
      );
    });

    test('gates unrestricted analysis to the documented direct mode', () {
      final grammar = UnrestrictedGrammar(
        id: 'unrestricted',
        name: 'Unrestricted',
        revision: 8,
        terminals: {const TerminalGrammarSymbol('a')},
        nonterminals: {
          const NonterminalGrammarSymbol('S'),
          const NonterminalGrammarSymbol('A'),
          const NonterminalGrammarSymbol('B'),
        },
        startSymbol: const NonterminalGrammarSymbol('S'),
        productions: [
          PhraseStructureProduction(
            id: 'pair',
            order: 0,
            left: GrammarSymbolSequence(const [
              NonterminalGrammarSymbol('S'),
              NonterminalGrammarSymbol('A'),
            ]),
            right: GrammarSymbolSequence(const [
              NonterminalGrammarSymbol('B'),
              TerminalGrammarSymbol('a'),
            ]),
          ),
        ],
      );

      final report = VariableDependencyGraphAnalyzer.analyzeUnrestricted(
        grammar,
      );

      expect(report.edges.map((edge) => '${edge.from}->${edge.to}'), [
        'A->B',
        'S->B',
      ]);
      expect(report.productivityAvailable, isFalse);
      expect(
        () => VariableDependencyGraphAnalyzer.analyzeUnrestricted(
          grammar,
          mode: VariableDependencyMode.leftCorner,
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            'Left-corner modes are defined only for context-free grammars.',
          ),
        ),
      );
    });

    test('handles a large acyclic grammar with stable counts', () {
      const count = 600;
      final productions = <Production>{};
      for (var index = 0; index < count - 1; index++) {
        productions.add(
          _production('p$index', 'N$index', ['N${index + 1}'], order: index),
        );
      }
      productions.add(
        _production('leaf', 'N${count - 1}', ['x'], order: count),
      );
      final grammar = _grammar(
        start: 'N0',
        nonterminals: {for (var index = 0; index < count; index++) 'N$index'},
        terminals: {'x'},
        productions: productions,
      );

      final report = VariableDependencyGraphAnalyzer.analyzeContextFree(
        grammar,
        sourceRevision: 1,
      );

      expect(report.variables, hasLength(count));
      expect(report.edges, hasLength(count - 1));
      expect(report.cycleWitnesses, isEmpty);
      expect(report.reachableVariables, hasLength(count));
    });

    test('analysis reports transfer across an isolate boundary', () async {
      final grammar = _grammar(
        nonterminals: {'S', 'A'},
        terminals: {'x'},
        productions: {
          _production('p1', 'S', ['A']),
          _production('p2', 'A', ['x']),
        },
      );

      final report = await Isolate.run(
        () => VariableDependencyGraphAnalyzer.analyzeContextFree(
          grammar,
          sourceRevision: 1,
        ),
      );

      expect(report.edges, hasLength(1));
    });
  });
}

Grammar _grammar({
  String start = 'S',
  required Set<String> nonterminals,
  required Set<String> terminals,
  required Set<Production> productions,
}) => Grammar(
  id: 'vdg-grammar',
  name: 'VDG grammar',
  terminals: terminals,
  nonterminals: nonterminals,
  startSymbol: start,
  productions: productions,
  type: GrammarType.contextFree,
  created: DateTime.utc(2026),
  modified: DateTime.utc(2026),
);

Production _production(
  String id,
  String left,
  List<String> right, {
  int order = 0,
  bool lambda = false,
}) => Production(
  id: id,
  leftSide: [left],
  rightSide: right,
  isLambda: lambda,
  order: order,
);
