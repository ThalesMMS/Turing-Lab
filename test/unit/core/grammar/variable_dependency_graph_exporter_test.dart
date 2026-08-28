import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/grammar/dependency_graph/dependency_graph.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/production.dart';
import 'package:turing_lab/presentation/widgets/export/variable_dependency_graph_exporter.dart';

void main() {
  final grammar = Grammar(
    id: 'svg-vdg',
    name: 'SVG VDG',
    terminals: const {'a'},
    nonterminals: const {'S', 'A<&'},
    startSymbol: 'S',
    productions: {
      const Production(id: 'p<&', leftSide: ['S'], rightSide: ['A<&']),
      const Production(id: 'loop', leftSide: ['A<&'], rightSide: ['A<&']),
      const Production(id: 'leaf', leftSide: ['A<&'], rightSide: ['a']),
    },
    type: GrammarType.contextFree,
    created: _date,
    modified: _date,
  );
  final report = VariableDependencyGraphAnalyzer.analyzeContextFree(
    grammar,
    sourceRevision: 3,
  );

  test(
    'exports deterministic SVG with labels, provenance, and text alternative',
    () {
      final first = VariableDependencyGraphExporter.toSvg(
        report,
        title: 'Localized title <&',
        description: 'Localized description <&',
      );
      final second = VariableDependencyGraphExporter.toSvg(
        report,
        title: 'Localized title <&',
        description: 'Localized description <&',
      );

      expect(first, second);
      expect(first, contains('<svg'));
      expect(first, contains('role="img"'));
      expect(first, contains('<desc id="vdg-description">'));
      expect(first, contains('Localized title &lt;&amp;'));
      expect(first, contains('Localized description &lt;&amp;'));
      expect(first, contains('data-production-ids="p&lt;&amp;"'));
      expect(first, contains('A&lt;&amp;'));
      expect(first, isNot(contains('NaN')));
    },
  );

  test('provides distinct finite positions for every layout', () {
    for (final mode in VariableDependencyLayout.values) {
      final positions = VariableDependencyGraphExporter.layout(report, mode);
      expect(positions.keys, containsAll(report.variables));
      expect(
        positions.values.map((point) => '${point.x},${point.y}').toSet(),
        hasLength(report.variables.length),
      );
      expect(
        positions.values.every((point) => point.x.isFinite && point.y.isFinite),
        isTrue,
      );
    }
  });
}

final _date = DateTime.utc(2026);
