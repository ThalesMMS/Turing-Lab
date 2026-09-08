//
//  grammar_svg_renderer.dart
//  Turing Lab
//
//  Maps a grammar onto the shared state diagram: one node per nonterminal,
//  one edge per symbol occurrence in a production (simplified view).
//

import '../../../../core/entities/grammar_entity.dart';
import 'automaton_svg_renderer.dart';
import 'svg_diagram_renderer.dart';
import 'svg_export_options.dart';

class GrammarSvgRenderer implements SvgDiagramRenderer<GrammarEntity> {
  const GrammarSvgRenderer();

  static const _diagram = AutomatonDiagramSvgRenderer();

  @override
  SvgStyleRequest styles(GrammarEntity document, SvgExportOptions options) =>
      _diagram.styles(toDiagram(document), options);

  @override
  void render(
    StringBuffer buffer,
    GrammarEntity grammar, {
    required double width,
    required double height,
    required SvgExportOptions options,
  }) => _diagram.render(
    buffer,
    toDiagram(grammar),
    width: width,
    height: height,
    options: options,
  );

  /// Converts grammar to automaton for visualization (simplified).
  static SvgAutomatonDiagram toDiagram(GrammarEntity grammar) {
    // This is a simplified conversion for visualization purposes
    final states = <SvgDiagramState>[];
    final transitions = <String, List<String>>{};

    // Create states for each non-terminal
    for (final variable in grammar.nonTerminals) {
      states.add(
        SvgDiagramState(
          id: variable,
          name: variable,
          isInitial: variable == grammar.startSymbol,
          isFinal: false,
        ),
      );
    }

    var terminalId = 'terminal';
    while (grammar.nonTerminals.contains(terminalId)) {
      terminalId = '${terminalId}_0';
    }
    var hasTerminal = false;

    // Create transitions based on productions (simplified)
    for (final production in grammar.productions) {
      final from = production.leftSide.isNotEmpty
          ? production.leftSide.first
          : '';
      for (final symbol in production.rightSide) {
        if (symbol.isNotEmpty) {
          final to = grammar.nonTerminals.contains(symbol)
              ? symbol
              : terminalId;
          hasTerminal |= to == terminalId;
          transitions.putIfAbsent('$from|$symbol', () => []).add(to);
        }
      }
    }

    if (hasTerminal) {
      states.add(
        SvgDiagramState(
          id: terminalId,
          name: 'F',
          isInitial: false,
          isFinal: true,
        ),
      );
    }

    return SvgAutomatonDiagram(
      name: grammar.name,
      states: states,
      transitions: transitions,
    );
  }
}
