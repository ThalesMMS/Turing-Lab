import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/entities/grammar_entity.dart';
import 'package:turing_lab/presentation/widgets/export/svg/grammar_svg_renderer.dart';
import 'package:turing_lab/presentation/widgets/export/svg_exporter.dart';

void main() {
  test('grammar SVG retains terminal edges and uses a collision-free sink', () {
    const grammar = GrammarEntity(
      id: 'edges',
      name: 'Edges',
      terminals: {'a'},
      nonTerminals: {'S', 'terminal'},
      startSymbol: 'S',
      productions: [
        ProductionEntity(
          id: 'p',
          leftSide: ['S'],
          rightSide: ['a', 'terminal'],
        ),
      ],
    );
    final diagram = GrammarSvgRenderer.toDiagram(grammar);
    expect(diagram.transitions['S|a'], ['terminal_0']);
    expect(diagram.transitions['S|terminal'], ['terminal']);
    expect(
      diagram.states.map((s) => s.id),
      containsAll(['S', 'terminal', 'terminal_0']),
    );
    final svg = SvgExporter.exportGrammarToSvg(grammar);
    expect(svg, contains('>a</text>'));
  });

  test('grammar SVG preserves English and Portuguese document titles', () {
    for (final name in ['Grammar & examples', 'Gramática & exemplos']) {
      final grammar = GrammarEntity(
        id: 'title-example',
        name: name,
        terminals: const {},
        nonTerminals: const {'S'},
        startSymbol: 'S',
        productions: const [],
      );
      final svg = SvgExporter.exportGrammarToSvg(grammar);
      expect(svg, contains(name.replaceAll('&', '&amp;')));
      expect(svg, isNot(contains('(Visualization)')));
    }
  });
}
