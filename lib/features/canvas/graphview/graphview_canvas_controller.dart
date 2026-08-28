//
//  graphview_canvas_controller.dart
//  Turing Lab
//
//  Controller that keeps the finite-automaton GraphView canvas in sync with
//  AutomatonStateProvider, coordinating state, transition, and label creation
//  as the user interacts. It also generates predictable identifiers, handles
//  undo/redo, and applies domain snapshots to update the displayed graph.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:graphview/graphview_turing_lab.dart';
import 'package:vector_math/vector_math_64.dart';

import '../../../core/models/fsa.dart';
import '../../../core/services/algorithm_step_highlight_service.dart';
import '../../../presentation/providers/automaton_state_provider.dart';
import 'base_graphview_canvas_controller.dart';
import 'graphview_automaton_mapper.dart';
import 'graphview_canvas_models.dart';
import 'graphview_state_notifier_adapter.dart';

void _logGraphViewCanvas(String message) {
  if (kDebugMode) {
    debugPrint('[GraphViewCanvasController] $message');
  }
}

/// Controller that keeps the [Graph] in sync with the [AutomatonStateNotifier].
class GraphViewCanvasController
    extends BaseGraphViewCanvasController<AutomatonStateNotifier, FSA>
    with SharedGraphViewStateController<AutomatonStateNotifier, FSA> {
  GraphViewCanvasController({
    required AutomatonStateNotifier automatonStateNotifier,
    super.graph,
    super.viewController,
    super.transformationController,
    super.historyLimit,
    super.cacheEvictionThreshold,
  }) : super(notifier: automatonStateNotifier);

  AutomatonStateNotifier get _provider => notifier;

  @override
  late final GraphViewStateNotifierAdapter<FSA> stateNotifierAdapter =
      GraphViewStateNotifierAdapter<FSA>(
    currentData: () => _provider.currentAutomaton,
    stateIdsOf: (automaton) => automaton.states.map((state) => state.id),
    stateLabelsOf: (automaton) => automaton.states.map((state) => state.label),
    transitionIdsOf: (automaton) =>
        automaton.transitions.map((transition) => transition.id),
    addState: ({required id, required label, required position}) =>
        _provider.addState(
      id: id,
      label: label,
      x: position.dx,
      y: position.dy,
    ),
    moveState: ({required id, required position}) =>
        _provider.moveState(id: id, x: position.dx, y: position.dy),
    updateStateLabel: ({required id, required label}) =>
        _provider.updateStateLabel(id: id, label: label),
    updateStateFlags: ({required id, isInitial, isAccepting}) =>
        _provider.updateStateFlags(
      id: id,
      isInitial: isInitial,
      isAccepting: isAccepting,
    ),
    removeState: (id) => _provider.removeState(id: id),
    logMutation: _logGraphViewCanvas,
  );

  /// Algorithm step highlight service, if configured.
  AlgorithmStepHighlightService? algorithmStepHighlightService;

  @override
  GraphViewAutomatonSnapshot toSnapshot(FSA? automaton) {
    return GraphViewAutomatonMapper.toSnapshot(automaton);
  }

  /// Synchronises the GraphView controller with the latest [automaton].
  @override
  void synchronize(FSA? automaton) {
    _logGraphViewCanvas(
      'Synchronizing canvas with automaton id=${automaton?.id} states=${automaton?.states.length ?? 0} transitions=${automaton?.transitions.length ?? 0}',
    );
    synchronizeGraph(automaton);
  }

  /// Adds or updates a transition between [fromStateId] and [toStateId].
  void addOrUpdateTransition({
    required String fromStateId,
    required String toStateId,
    required String label,
    String? transitionId,
    double? controlPointX,
    double? controlPointY,
  }) {
    final edgeId = transitionId ?? generateEdgeId();
    _logGraphViewCanvas(
      'addOrUpdateTransition -> id=$edgeId from=$fromStateId to=$toStateId label=$label cp=(${controlPointX?.toStringAsFixed(2)}, ${controlPointY?.toStringAsFixed(2)})',
    );
    performMutation(() {
      _provider.addOrUpdateTransition(
        id: edgeId,
        fromStateId: fromStateId,
        toStateId: toStateId,
        label: label,
        controlPointX: controlPointX,
        controlPointY: controlPointY,
      );
    });
  }

  /// Removes the transition identified by [id] from the automaton.
  @override
  void removeTransition(String id) {
    _logGraphViewCanvas('removeTransition -> id=$id');
    performMutation(() {
      _provider.removeTransition(id: id);
    });
  }

  /// Applies algorithm step highlight from step metadata.
  void applyAlgorithmStepHighlight(Map<String, dynamic>? metadata) {
    if (metadata == null || metadata.isEmpty) {
      clearHighlight();
      return;
    }

    final service = algorithmStepHighlightService;
    if (service == null) {
      _logGraphViewCanvas(
        'Cannot apply algorithm step highlight: service not configured',
      );
      return;
    }

    final highlight = service.computeFromMetadata(metadata);
    applyHighlight(highlight);
    _logGraphViewCanvas(
      'Applied algorithm step highlight (states: ${highlight.stateIds.length}, transitions: ${highlight.transitionIds.length})',
    );
  }

  /// Clears any algorithm step highlight from the canvas.
  void clearAlgorithmStepHighlight() {
    clearHighlight();
    _logGraphViewCanvas('Cleared algorithm step highlight');
  }

  @override
  void applySnapshotToDomain(GraphViewAutomatonSnapshot snapshot) {
    final template = _provider.currentAutomaton ??
        FSA(
          id: snapshot.metadata.id ??
              'automaton_${DateTime.now().microsecondsSinceEpoch}',
          name: snapshot.metadata.name ?? 'Untitled Automaton',
          states: const {},
          transitions: const {},
          alphabet: snapshot.metadata.alphabet.toSet(),
          initialState: null,
          acceptingStates: const {},
          created: DateTime.now(),
          modified: DateTime.now(),
          bounds: const math.Rectangle<double>(0, 0, 800, 600),
          panOffset: Vector2.zero(),
          zoomLevel: 1.0,
        );

    final merged =
        GraphViewAutomatonMapper.mergeIntoTemplate(snapshot, template).copyWith(
      id: snapshot.metadata.id ?? template.id,
      name: snapshot.metadata.name ?? template.name,
      alphabet: snapshot.metadata.alphabet.isNotEmpty
          ? snapshot.metadata.alphabet.toSet()
          : template.alphabet,
      modified: DateTime.now(),
    );

    _logGraphViewCanvas(
      'applySnapshotToDomain -> states=${merged.states.length} transitions=${merged.transitions.length}',
    );
    _provider.updateAutomaton(merged);
    synchronize(merged);
  }

  @override
  void replaceDomainDocument(FSA document) {
    _provider.updateAutomaton(document);
  }
}
