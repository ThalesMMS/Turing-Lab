//
//  graphview_tm_canvas_controller.dart
//  Turing Lab
//
//  Controlador que mantém o canvas GraphView alinhado ao estado de edição de
//  máquinas de Turing, sincronizando nós e transições com o TMEditorNotifier e
//  oferecendo operações de criação, movimentação, rótulo e flags. Também cuida
//  da geração de identificadores estáveis, da aplicação de snapshots vindos do
//  domínio e do registro de telemetria útil durante mutações do grafo.
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

const double _kTmFitToContentMaxScale = 1.35;

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
  double get fitToContentMaxScale => _kTmFitToContentMaxScale;

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
    String? transitionId,
    double? controlPointX,
    double? controlPointY,
  }) {
    final edgeId = transitionId ?? generateEdgeId();
    final controlPoint = (controlPointX != null && controlPointY != null)
        ? Vector2(controlPointX, controlPointY)
        : null;
    _logTmCanvas(
      'addOrUpdateTransition -> id=$edgeId from=$fromStateId to=$toStateId read=$readSymbol write=$writeSymbol dir=$direction cp=${controlPoint?.toString()}',
    );
    performMutation(() {
      _notifier.addOrUpdateTransition(
        id: edgeId,
        fromStateId: fromStateId,
        toStateId: toStateId,
        readSymbol: readSymbol,
        writeSymbol: writeSymbol,
        direction: direction,
        controlPoint: controlPoint,
      );
    });
  }

  /// Updates the control point for the transition identified by [id].
  void updateTransitionControlPoint(
    String id,
    double controlPointX,
    double controlPointY,
  ) {
    final edge = edgeById(id);
    if (edge == null) {
      _logTmCanvas(
        'updateTransitionControlPoint skipped -> id=$id (edge not found)',
      );
      return;
    }

    _logTmCanvas(
      'updateTransitionControlPoint -> id=$id cp=(${controlPointX.toStringAsFixed(2)}, ${controlPointY.toStringAsFixed(2)})',
    );
    addOrUpdateTransition(
      fromStateId: edge.fromStateId,
      toStateId: edge.toStateId,
      readSymbol: edge.readSymbol,
      writeSymbol: edge.writeSymbol,
      direction: edge.direction,
      transitionId: id,
      controlPointX: controlPointX,
      controlPointY: controlPointY,
    );
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
