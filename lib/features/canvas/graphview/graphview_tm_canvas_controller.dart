//
//  graphview_tm_canvas_controller.dart
//  Turing Lab
//
//  Controller that keeps the GraphView canvas aligned with Turing machine
//  editing state, syncing nodes and transitions with TMEditorNotifier and
//  providing create, move, label, and flag operations. It also generates
//  stable identifiers, applies domain snapshots, and records useful
//  telemetry during graph mutations.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:vector_math/vector_math_64.dart';

import '../../../core/models/tm.dart';
import '../../../core/models/tm_transition.dart';
import '../../../presentation/providers/tm_editor_provider.dart';
import 'base_graphview_canvas_controller.dart';
import 'graphview_canvas_models.dart';
import 'graphview_mapper_helpers.dart';
import 'graphview_state_notifier_adapter.dart';
import 'graphview_tm_mapper.dart';

void _logTmCanvas(String message) {
  if (kDebugMode) {
    debugPrint('[GraphViewTmCanvasController] $message');
  }
}

/// Controller responsible for synchronising GraphView with the
/// [TMEditorNotifier].
class GraphViewTmCanvasController
    extends BaseGraphViewCanvasController<TMEditorNotifier, TM>
    with SharedGraphViewStateController<TMEditorNotifier, TM> {
  GraphViewTmCanvasController({
    required TMEditorNotifier editorNotifier,
    super.graph,
    super.viewController,
    super.transformationController,
    super.historyLimit,
    super.cacheEvictionThreshold,
  }) : super(notifier: editorNotifier);

  TMEditorNotifier get _notifier => notifier;

  @override
  late final GraphViewStateNotifierAdapter<TM> stateNotifierAdapter =
      GraphViewStateNotifierAdapter<TM>(
    currentData: () => _notifier.currentTm,
    stateIdsOf: (machine) => machine.states.map((state) => state.id),
    stateLabelsOf: (machine) => machine.states.map((state) => state.label),
    transitionIdsOf: (machine) =>
        machine.tmTransitions.map((transition) => transition.id),
    addState: ({required id, required label, required position}) =>
        _notifier.upsertState(
      id: id,
      label: label,
      x: position.dx,
      y: position.dy,
    ),
    moveState: ({required id, required position}) =>
        _notifier.moveState(id: id, x: position.dx, y: position.dy),
    updateStateLabel: ({required id, required label}) =>
        _notifier.updateStateLabel(id: id, label: label),
    updateStateFlags: ({required id, isInitial, isAccepting}) =>
        _notifier.updateStateFlags(
      id: id,
      isInitial: isInitial,
      isAccepting: isAccepting,
    ),
    removeState: (id) => _notifier.removeState(id: id),
    logMutation: _logTmCanvas,
  );

  @override
  GraphViewAutomatonSnapshot toSnapshot(TM? machine) {
    return GraphViewTmMapper.toSnapshot(machine);
  }

  /// Synchronises the GraphView controller with the latest [machine].
  @override
  void synchronize(TM? machine) {
    _logTmCanvas(
      'Synchronizing TM canvas (states=${machine?.states.length ?? 0}, transitions=${machine?.tmTransitions.length ?? 0})',
    );
    synchronizeGraph(machine);
  }

  /// Adds or updates a TM transition between [fromStateId] and [toStateId].
  void addOrUpdateTransition({
    required String fromStateId,
    required String toStateId,
    String? readSymbol,
    String? writeSymbol,
    TapeDirection? direction,
    int? tapeNumber,
    String? transitionId,
    double? controlPointX,
    double? controlPointY,
  }) {
    final edgeId = transitionId ?? generateEdgeId();
    final controlPoint = (controlPointX != null && controlPointY != null)
        ? Vector2(controlPointX, controlPointY)
        : null;
    _logTmCanvas(
      'addOrUpdateTransition -> id=$edgeId from=$fromStateId to=$toStateId read=$readSymbol write=$writeSymbol dir=$direction tape=$tapeNumber cp=${controlPoint?.toString()}',
    );
    performMutation(() {
      _notifier.addOrUpdateTransition(
        id: edgeId,
        fromStateId: fromStateId,
        toStateId: toStateId,
        readSymbol: readSymbol,
        writeSymbol: writeSymbol,
        direction: direction,
        tapeNumber: tapeNumber,
        controlPoint: controlPoint,
      );
    });
  }

  /// Removes the transition identified by [id] from the machine.
  @override
  void removeTransition(String id) {
    _logTmCanvas('removeTransition -> id=$id');
    performMutation(() {
      _notifier.removeTransition(id: id);
    });
  }

  @override
  void applySnapshotToDomain(GraphViewAutomatonSnapshot snapshot) {
    final metadataBlankSymbol = snapshot.metadata.blankSymbol ?? 'B';
    final initialTapeAlphabet = GraphViewMapperHelpers.effectiveTapeAlphabet(
      metadataTapeAlphabet: snapshot.metadata.tapeAlphabet,
      fallbackTapeAlphabet: snapshot.metadata.alphabet,
      blankSymbol: metadataBlankSymbol,
    );
    final template = _notifier.currentTm ??
        TM(
          id: snapshot.metadata.id ??
              'tm_${DateTime.now().microsecondsSinceEpoch}',
          name: snapshot.metadata.name ?? 'Canvas TM',
          states: const {},
          transitions: const {},
          alphabet: snapshot.metadata.alphabet.toSet(),
          initialState: null,
          acceptingStates: const {},
          created: DateTime.now(),
          modified: DateTime.now(),
          bounds: const math.Rectangle<double>(0, 0, 800, 600),
          tapeAlphabet: initialTapeAlphabet,
          blankSymbol: metadataBlankSymbol,
          tapeCount: snapshot.metadata.tapeCount ?? 1,
          panOffset: Vector2.zero(),
          zoomLevel: 1.0,
        );

    final merged =
        GraphViewTmMapper.mergeIntoTemplate(snapshot, template).copyWith(
      id: snapshot.metadata.id ?? template.id,
      name: snapshot.metadata.name ?? template.name,
      modified: DateTime.now(),
    );

    _logTmCanvas(
      'applySnapshotToDomain -> states=${merged.states.length} transitions=${merged.tmTransitions.length}',
    );
    _notifier.setTm(merged);
    synchronize(merged);
  }
}
