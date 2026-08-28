//
//  graphview_automaton_mapper.dart
//  Turing Lab
//
//  Utility that maps finite automata to snapshots consumed by GraphView and
//  rebuilds domain instances from visual edits. It creates nodes, edges, and
//  metadata, and keeps state consistent during template merges.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import '../../../core/models/fsa.dart';
import '../../../core/models/fsa_transition.dart';
import '../../../core/models/transition.dart';
import 'graphview_canvas_models.dart';
import 'graphview_mapper_helpers.dart';

/// Utility helpers to convert between [FSA] instances and GraphView snapshots.
class GraphViewAutomatonMapper {
  const GraphViewAutomatonMapper._();

  /// Converts the provided [automaton] into a snapshot consumed by the
  /// canvas controller.
  static GraphViewAutomatonSnapshot toSnapshot(FSA? automaton) {
    if (automaton == null) {
      return const GraphViewAutomatonSnapshot.empty();
    }

    final nodes = GraphViewMapperHelpers.nodesToGraphViewNodes(
      states: automaton.states,
      initialState: automaton.initialState,
      acceptingStates: automaton.acceptingStates,
    );

    final edges = automaton.fsaTransitions.map((transition) {
      return GraphViewCanvasEdge(
        id: transition.id,
        fromStateId: transition.fromState.id,
        toStateId: transition.toState.id,
        symbols: transition.inputSymbols.toList(),
        lambdaSymbol: transition.lambdaSymbol,
        controlPointX: transition.controlPoint.x,
        controlPointY: transition.controlPoint.y,
      );
    }).toList();

    final metadata = GraphViewMapperHelpers.buildMetadata(
      id: automaton.id,
      name: automaton.name,
      alphabet: automaton.alphabet,
    );

    return GraphViewAutomatonSnapshot(
      nodes: nodes,
      edges: edges,
      metadata: metadata,
    );
  }

  /// Rebuilds an [FSA] template with the snapshot produced by the canvas.
  static FSA mergeIntoTemplate(
    GraphViewAutomatonSnapshot snapshot,
    FSA template,
  ) {
    final states = GraphViewMapperHelpers.nodesFromSnapshot(snapshot.nodes);
    final stateMap = GraphViewMapperHelpers.buildStateMap(states);

    final transitions = snapshot.edges.map((edge) {
      final endpoints = GraphViewMapperHelpers.resolveEdgeEndpoints(
        stateMap: stateMap,
        edge: edge,
      );
      return FSATransition(
        id: edge.id,
        fromState: endpoints.fromState,
        toState: endpoints.toState,
        inputSymbols: edge.symbols.toSet(),
        lambdaSymbol: edge.lambdaSymbol,
        label: edge.label,
        controlPoint: GraphViewMapperHelpers.resolveOptionalControlPoint(edge),
      );
    }).toSet();

    final acceptingStates = GraphViewMapperHelpers.buildAcceptingStates(
      nodes: snapshot.nodes,
      stateMap: stateMap,
    );

    final alphabet = <String>{
      ...template.alphabet,
      for (final edge in snapshot.edges) ...edge.symbols,
    }..removeWhere((symbol) => symbol.isEmpty);

    final initialState = GraphViewMapperHelpers.resolveInitialState(
      nodes: snapshot.nodes,
      stateMap: stateMap,
      fallbackInitialState: template.initialState,
    );

    return template.copyWith(
      states: states,
      transitions: transitions.map<Transition>((t) => t).toSet(),
      acceptingStates: acceptingStates,
      initialState: initialState,
      alphabet: alphabet,
    );
  }
}
