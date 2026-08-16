//
//  graphview_tm_mapper.dart
//  Turing Lab
//
//  Utilitário que converte máquinas de Turing em snapshots compatíveis com o
//  GraphView e reidrata modelos do domínio a partir de edições visuais. O
//  mapeamento preserva estados, transições, direção de fita e alfabetos para
//  garantir consistência entre a camada visual e os dados centrais.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'dart:math' as math;

import '../../../core/models/tm.dart';
import '../../../core/models/tm_transition.dart';
import '../../../core/models/transition.dart';
import 'graphview_canvas_models.dart';
import 'graphview_mapper_helpers.dart';

/// Converts between [TM] instances and GraphView snapshots consumed by the TM
/// canvas controller.
class GraphViewTmMapper {
  const GraphViewTmMapper._();

  /// Converts the provided Turing Machine into a GraphView snapshot.
  static GraphViewAutomatonSnapshot toSnapshot(TM? machine) {
    if (machine == null) {
      return const GraphViewAutomatonSnapshot.empty();
    }

    final nodes = GraphViewMapperHelpers.nodesToGraphViewNodes(
      states: machine.states,
      initialState: machine.initialState,
      acceptingStates: machine.acceptingStates,
    );

    final edges = machine.tmTransitions.map((transition) {
      return GraphViewCanvasEdge(
        id: transition.id,
        fromStateId: transition.fromState.id,
        toStateId: transition.toState.id,
        symbols: const <String>[],
        controlPointX: transition.controlPoint.x,
        controlPointY: transition.controlPoint.y,
        readSymbol: transition.readSymbol,
        writeSymbol: transition.writeSymbol,
        direction: transition.direction,
        tapeNumber: transition.tapeNumber,
      );
    }).toList();

    final metadata = GraphViewMapperHelpers.buildMetadata(
      id: machine.id,
      name: machine.name,
      alphabet: machine.alphabet,
      tapeAlphabet: machine.tapeAlphabet,
      blankSymbol: machine.blankSymbol,
      tapeCount: machine.tapeCount,
    );

    return GraphViewAutomatonSnapshot(
      nodes: nodes,
      edges: edges,
      metadata: metadata,
    );
  }

  /// Rebuilds a [TM] template using the data contained in [snapshot].
  static TM mergeIntoTemplate(
    GraphViewAutomatonSnapshot snapshot,
    TM template,
  ) {
    final states = GraphViewMapperHelpers.nodesFromSnapshot(snapshot.nodes);
    final stateMap = GraphViewMapperHelpers.buildStateMap(states);

    final transitions = snapshot.edges.map((edge) {
      final endpoints = GraphViewMapperHelpers.resolveEdgeEndpoints(
        stateMap: stateMap,
        edge: edge,
      );
      final controlPoint = GraphViewMapperHelpers.resolveControlPoint(edge);

      final direction = edge.direction ?? TapeDirection.right;

      return TMTransition(
        id: edge.id,
        fromState: endpoints.fromState,
        toState: endpoints.toState,
        label: edge.label,
        controlPoint: controlPoint,
        readSymbol: edge.readSymbol ?? '',
        writeSymbol: edge.writeSymbol ?? '',
        direction: direction,
        tapeNumber: edge.tapeNumber ?? 0,
      );
    }).toSet();

    final acceptingStates = GraphViewMapperHelpers.buildAcceptingStates(
      nodes: snapshot.nodes,
      stateMap: stateMap,
    );

    final blankSymbol = snapshot.metadata.blankSymbol ?? template.blankSymbol;
    final baseTapeAlphabet = GraphViewMapperHelpers.effectiveTapeAlphabet(
      metadataTapeAlphabet: snapshot.metadata.tapeAlphabet,
      fallbackTapeAlphabet: template.tapeAlphabet,
      blankSymbol: blankSymbol,
    );
    final baseAlphabet = snapshot.metadata.alphabet.isNotEmpty
        ? snapshot.metadata.alphabet.toSet()
        : template.alphabet;
    // Transitions read from the tape alphabet, so their read symbols may be
    // markers the machine wrote itself. Only fall back to them when no input
    // alphabet is known; otherwise the authoritative one is preserved.
    final alphabet = baseAlphabet.isNotEmpty
        ? baseAlphabet.toSet()
        : <String>{
            for (final edge in snapshot.edges)
              if (edge.readSymbol case final symbol?
                  when symbol.isNotEmpty && symbol != blankSymbol)
                symbol,
          };
    final tapeAlphabet = <String>{
      ...baseTapeAlphabet,
      for (final edge in snapshot.edges)
        if (edge.readSymbol case final symbol? when symbol.isNotEmpty) symbol,
      for (final edge in snapshot.edges)
        if (edge.writeSymbol case final symbol? when symbol.isNotEmpty) symbol,
    };
    final tapeCount = snapshot.edges.fold<int>(
      snapshot.metadata.tapeCount ?? template.tapeCount,
      (count, edge) => math.max(count, (edge.tapeNumber ?? 0) + 1),
    );

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
      tapeAlphabet: tapeAlphabet,
      blankSymbol: blankSymbol,
      tapeCount: tapeCount,
    );
  }
}
