//
//  graphview_tm_mapper.dart
//  Turing Lab
//
//  Utility that converts Turing machines into GraphView-compatible snapshots
//  and rehydrates domain models from visual edits. The mapping preserves
//  states, transitions, tape direction, and alphabets so the visual layer
//  stays consistent with the core data.
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

    final invocationByState = {
      for (final invocation in machine.blockInvocations)
        invocation.stateId: invocation,
    };
    final nodes = GraphViewMapperHelpers.nodesToGraphViewNodes(
      states: machine.states,
      initialState: machine.initialState,
      acceptingStates: machine.acceptingStates,
    ).map((node) {
      final invocation = invocationByState[node.id];
      if (invocation == null) return node;
      final definition = machine.blockDefinitions[invocation.reference.blockId];
      if (definition == null) {
        return node.copyWith(
          label: 'Block: ${invocation.reference.blockId}',
          secondaryLabel: 'Missing reference',
        );
      }
      final validRevision =
          definition.revision == invocation.reference.revision;
      return node.copyWith(
        label: 'Block: ${definition.name}',
        secondaryLabel:
            validRevision ? 'Building block · valid' : 'Revision mismatch',
      );
    }).toList(growable: false);

    final edges = machine.tmTransitions.map((transition) {
      final operations = transition.operationsForTapeCount(
        machine.tapeCount,
        machine.blankSymbol,
      );
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
        tmOperations: TmGraphViewOperationVectors(
          readSymbols: operations.readSymbols,
          writeSymbols: operations.writeSymbols,
          directions: operations.directions,
        ),
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

      final readSymbols = edge.tmReadSymbols ??
          <String>[edge.readSymbol ?? template.blankSymbol];
      final writeSymbols = edge.tmWriteSymbols ??
          <String>[edge.writeSymbol ?? template.blankSymbol];
      final directions = edge.tmDirections ??
          <TapeDirection>[edge.direction ?? TapeDirection.right];

      return TMTransition(
        id: edge.id,
        fromState: endpoints.fromState,
        toState: endpoints.toState,
        label: edge.label,
        controlPoint: controlPoint,
        readSymbols: readSymbols,
        writeSymbols: writeSymbols,
        directions: directions,
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
    Iterable<String> edgeReadSymbols(GraphViewCanvasEdge edge) {
      if (edge.tmReadSymbols case final symbols?) {
        return symbols;
      }
      return edge.readSymbol == null
          ? const <String>[]
          : <String>[edge.readSymbol!];
    }

    Iterable<String> edgeWriteSymbols(GraphViewCanvasEdge edge) {
      if (edge.tmWriteSymbols case final symbols?) {
        return symbols;
      }
      return edge.writeSymbol == null
          ? const <String>[]
          : <String>[edge.writeSymbol!];
    }

    final alphabet = baseAlphabet.isNotEmpty
        ? baseAlphabet.toSet()
        : <String>{
            for (final edge in snapshot.edges)
              for (final symbol in edgeReadSymbols(edge))
                if (symbol.isNotEmpty && symbol != blankSymbol) symbol,
          };
    final tapeAlphabet = <String>{
      ...baseTapeAlphabet,
      for (final edge in snapshot.edges)
        for (final symbol in edgeReadSymbols(edge))
          if (symbol.isNotEmpty) symbol,
      for (final edge in snapshot.edges)
        for (final symbol in edgeWriteSymbols(edge))
          if (symbol.isNotEmpty) symbol,
    };
    final tapeCount = snapshot.edges.fold<int>(
      snapshot.metadata.tapeCount ?? template.tapeCount,
      (count, edge) => math.max(
        count,
        edge.tmReadSymbols?.length ?? (edge.tapeNumber ?? 0) + 1,
      ),
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
      blockInvocations: template.blockInvocations
          .where((invocation) => stateMap.containsKey(invocation.stateId)),
    );
  }
}
