//
//  pda_svg_renderer.dart
//  Turing Lab
//
//  Maps a pushdown automaton onto the shared state diagram, labelling each
//  transition with its read, pop and push symbols.
//

import '../../../../core/models/pda.dart';
import '../../../../core/models/pda_transition.dart';
import '../../../../core/utils/epsilon_utils.dart';
import 'automaton_svg_renderer.dart';
import 'svg_diagram_renderer.dart';
import 'svg_export_options.dart';

class PdaSvgRenderer implements SvgDiagramRenderer<PDA> {
  const PdaSvgRenderer();

  static const _diagram = AutomatonDiagramSvgRenderer();

  @override
  SvgStyleRequest styles(PDA document, SvgExportOptions options) =>
      _diagram.styles(toDiagram(document), options);

  @override
  void render(
    StringBuffer buffer,
    PDA pda, {
    required double width,
    required double height,
    required SvgExportOptions options,
  }) => _diagram.render(
    buffer,
    toDiagram(pda),
    width: width,
    height: height,
    options: options,
  );

  static SvgAutomatonDiagram toDiagram(PDA pda) {
    final transitions = <String, List<String>>{};

    for (final transition in pda.pdaTransitions) {
      final label = _formatPdaTransitionLabel(transition);
      final key = '${transition.fromState.id}|$label';
      transitions.putIfAbsent(key, () => <String>[]).add(transition.toState.id);
    }

    return SvgAutomatonDiagram(
      name: pda.name,
      states: pda.states
          .map(
            (state) => SvgDiagramState(
              id: state.id,
              name: state.label,
              isInitial: state.isInitial,
              isFinal: state.isAccepting,
              position: state.position,
            ),
          )
          .toList(),
      transitions: transitions,
    );
  }

  static String _formatPdaTransitionLabel(PDATransition transition) {
    final read = normalizeToEpsilon(
      transition.isLambdaInput ? '' : transition.inputSymbol,
    );
    final pop = normalizeToEpsilon(
      transition.isLambdaPop ? '' : transition.popSymbol,
    );
    final push = normalizeToEpsilon(
      transition.isLambdaPush ? '' : transition.pushSymbol,
    );
    return '$read,$pop->$push';
  }
}
