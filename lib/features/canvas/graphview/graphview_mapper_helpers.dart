import 'package:vector_math/vector_math_64.dart';

import '../../../core/models/state.dart';
import 'graphview_canvas_models.dart';

/// Shared mapping utilities used by the FSA, PDA, and TM GraphView mappers.
class GraphViewMapperHelpers {
  const GraphViewMapperHelpers._();

  static List<GraphViewCanvasNode> nodesToGraphViewNodes({
    required Iterable<State> states,
    required State? initialState,
    required Iterable<State> acceptingStates,
  }) {
    final initialStateId = initialState?.id;
    final acceptingStateIds = acceptingStates.map((state) => state.id).toSet();

    return states.map((state) {
      return GraphViewCanvasNode(
        id: state.id,
        label: state.label,
        x: state.position.x,
        y: state.position.y,
        isInitial: initialStateId == state.id,
        isAccepting: acceptingStateIds.contains(state.id),
      );
    }).toList();
  }

  static GraphViewAutomatonMetadata buildMetadata({
    required String id,
    required String name,
    required Iterable<String> alphabet,
    Iterable<String> stackAlphabet = const <String>[],
    String? initialStackSymbol,
    Iterable<String> tapeAlphabet = const <String>[],
    String? blankSymbol,
    int? tapeCount,
  }) {
    return GraphViewAutomatonMetadata(
      id: id,
      name: name,
      alphabet: alphabet.toList(),
      stackAlphabet: stackAlphabet.toList(),
      initialStackSymbol: initialStackSymbol,
      tapeAlphabet: tapeAlphabet.toList(),
      blankSymbol: blankSymbol,
      tapeCount: tapeCount,
    );
  }

  static Set<State> nodesFromSnapshot(List<GraphViewCanvasNode> nodes) {
    return nodes
        .map(
          (node) => State(
            id: node.id,
            label: node.label,
            position: Vector2(node.x, node.y),
            isInitial: node.isInitial,
            isAccepting: node.isAccepting,
          ),
        )
        .toSet();
  }

  static Map<String, State> buildStateMap(Set<State> states) {
    return {for (final state in states) state.id: state};
  }

  static Set<State> buildAcceptingStates({
    required List<GraphViewCanvasNode> nodes,
    required Map<String, State> stateMap,
  }) {
    return {
      for (final node in nodes.where((node) => node.isAccepting))
        stateMap[node.id]!,
    };
  }

  static State? resolveInitialState({
    required List<GraphViewCanvasNode> nodes,
    required Map<String, State> stateMap,
    required State? fallbackInitialState,
  }) {
    for (final node in nodes) {
      if (node.isInitial) {
        return stateMap[node.id];
      }
    }
    final fallbackId = fallbackInitialState?.id;
    return fallbackId == null ? null : stateMap[fallbackId];
  }

  static ({State fromState, State toState}) resolveEdgeEndpoints({
    required Map<String, State> stateMap,
    required GraphViewCanvasEdge edge,
  }) {
    final fromState = stateMap[edge.fromStateId];
    final toState = stateMap[edge.toStateId];
    if (fromState == null || toState == null) {
      throw StateError('Edge references missing state: ${edge.toJson()}');
    }
    return (fromState: fromState, toState: toState);
  }

  static Vector2? resolveOptionalControlPoint(GraphViewCanvasEdge edge) {
    if (edge.controlPointX != null && edge.controlPointY != null) {
      return Vector2(edge.controlPointX!, edge.controlPointY!);
    }
    return null;
  }

  static Vector2 resolveControlPoint(GraphViewCanvasEdge edge) {
    return resolveOptionalControlPoint(edge) ?? Vector2.zero();
  }

  static Set<String> effectiveTapeAlphabet({
    required Iterable<String> metadataTapeAlphabet,
    required Iterable<String> fallbackTapeAlphabet,
    required String blankSymbol,
  }) {
    final metadataAlphabet = metadataTapeAlphabet.toSet();
    final baseAlphabet = metadataAlphabet.isNotEmpty
        ? metadataAlphabet
        : fallbackTapeAlphabet.toSet();
    return {
      ...baseAlphabet,
      if (blankSymbol.isNotEmpty) blankSymbol,
    };
  }
}
