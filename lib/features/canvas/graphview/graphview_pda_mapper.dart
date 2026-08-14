//
//  graphview_pda_mapper.dart
//  Turing Lab
//
//  Utilitário que traduz autômatos de pilha para snapshots manipulados pelo
//  GraphView e recompõe modelos do domínio durante salvamentos do canvas. O
//  código mantém estados, símbolos de entrada e de pilha, além de inferir
//  marcadores lambda ao reconstruir as transições.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import '../../../core/models/pda.dart';
import '../../../core/models/pda_transition.dart';
import '../../../core/models/transition.dart';
import 'graphview_canvas_models.dart';
import 'graphview_mapper_helpers.dart';

/// Converts between [PDA] instances and GraphView snapshots consumed by the PDA
/// canvas controller.
class GraphViewPdaMapper {
  const GraphViewPdaMapper._();

  static bool _isLambdaPush(GraphViewCanvasEdge edge) {
    final hasAtomicSymbols =
        edge.pushSymbols?.any((symbol) => symbol.isNotEmpty) ?? false;
    return edge.isLambdaPush ??
        (!hasAtomicSymbols && (edge.pushSymbol?.isEmpty ?? true));
  }

  static Iterable<String> _concretePushSymbols(GraphViewCanvasEdge edge) {
    final atomicSymbols = edge.pushSymbols;
    if (atomicSymbols != null) {
      return atomicSymbols.where((symbol) => symbol.isNotEmpty);
    }
    final legacySymbol = edge.pushSymbol;
    return legacySymbol == null || legacySymbol.isEmpty
        ? const <String>[]
        : legacySymbol.split('');
  }

  /// Formats a PDA transition label in the format: input, pop/push
  /// Lambda transitions are represented as λ
  static String formatPdaTransitionLabel({
    required String inputSymbol,
    required String popSymbol,
    required String pushSymbol,
    required bool isLambdaInput,
    required bool isLambdaPop,
    required bool isLambdaPush,
  }) {
    final input = isLambdaInput ? 'λ' : inputSymbol;
    final pop = isLambdaPop ? 'λ' : popSymbol;
    final push = isLambdaPush ? 'λ' : pushSymbol;
    return '$input, $pop/$push';
  }

  /// Converts the provided [automaton] into a GraphView snapshot.
  static GraphViewAutomatonSnapshot toSnapshot(PDA? automaton) {
    if (automaton == null) {
      return const GraphViewAutomatonSnapshot.empty();
    }

    final nodes = GraphViewMapperHelpers.nodesToGraphViewNodes(
      states: automaton.states,
      initialState: automaton.initialState,
      acceptingStates: automaton.acceptingStates,
    );

    final edges = automaton.pdaTransitions.map((transition) {
      return GraphViewCanvasEdge(
        id: transition.id,
        fromStateId: transition.fromState.id,
        toStateId: transition.toState.id,
        symbols: const <String>[],
        controlPointX: transition.controlPoint.x,
        controlPointY: transition.controlPoint.y,
        readSymbol: transition.inputSymbol,
        popSymbol: transition.popSymbol,
        pushSymbol: transition.pushSymbol,
        pushSymbols: transition.pushSymbols,
        isLambdaInput: transition.isLambdaInput,
        isLambdaPop: transition.isLambdaPop,
        isLambdaPush: transition.isLambdaPush,
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

  /// Rebuilds a [PDA] template with the data contained in [snapshot].
  static PDA mergeIntoTemplate(
    GraphViewAutomatonSnapshot snapshot,
    PDA template,
  ) {
    final states = GraphViewMapperHelpers.nodesFromSnapshot(snapshot.nodes);
    final stateMap = GraphViewMapperHelpers.buildStateMap(states);

    final transitions = snapshot.edges.map((edge) {
      final endpoints = GraphViewMapperHelpers.resolveEdgeEndpoints(
        stateMap: stateMap,
        edge: edge,
      );
      final controlPoint = GraphViewMapperHelpers.resolveControlPoint(edge);

      final isLambdaInput =
          edge.isLambdaInput ?? (edge.readSymbol?.isEmpty ?? true);
      final isLambdaPop = edge.isLambdaPop ?? (edge.popSymbol?.isEmpty ?? true);
      final isLambdaPush = _isLambdaPush(edge);

      final inputSymbol = isLambdaInput ? '' : (edge.readSymbol ?? '');
      final popSymbol = isLambdaPop ? '' : (edge.popSymbol ?? '');
      final pushSymbol = isLambdaPush
          ? ''
          : (edge.pushSymbol ?? edge.pushSymbols?.join() ?? '');

      final label = formatPdaTransitionLabel(
        inputSymbol: inputSymbol,
        popSymbol: popSymbol,
        pushSymbol: pushSymbol,
        isLambdaInput: isLambdaInput,
        isLambdaPop: isLambdaPop,
        isLambdaPush: isLambdaPush,
      );

      return PDATransition(
        id: edge.id,
        fromState: endpoints.fromState,
        toState: endpoints.toState,
        label: label,
        controlPoint: controlPoint,
        type: TransitionType.deterministic,
        inputSymbol: inputSymbol,
        popSymbol: popSymbol,
        pushSymbol: pushSymbol,
        pushSymbols: isLambdaPush ? const <String>[] : edge.pushSymbols,
        isLambdaInput: isLambdaInput,
        isLambdaPop: isLambdaPop,
        isLambdaPush: isLambdaPush,
      );
    }).toSet();

    final acceptingStates = GraphViewMapperHelpers.buildAcceptingStates(
      nodes: snapshot.nodes,
      stateMap: stateMap,
    );

    final alphabet = <String>{
      ...template.alphabet,
      for (final edge in snapshot.edges)
        if (!(edge.isLambdaInput ?? false) &&
            (edge.readSymbol != null && edge.readSymbol!.isNotEmpty))
          edge.readSymbol!,
    };

    final stackAlphabet = <String>{
      ...template.stackAlphabet,
      for (final edge in snapshot.edges)
        if (!(edge.isLambdaPop ?? false) &&
            (edge.popSymbol != null && edge.popSymbol!.isNotEmpty))
          edge.popSymbol!,
      for (final edge in snapshot.edges)
        if (!_isLambdaPush(edge)) ..._concretePushSymbols(edge),
    };

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
      stackAlphabet: stackAlphabet,
    );
  }
}
