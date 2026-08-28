//
//  graphview_pda_canvas_controller.dart
//  Turing Lab
//
//  Controller dedicated to pushdown automata that keeps GraphView in sync with
//  PDAEditorNotifier, handling node creation, movement, and labels, as well as
//  transitions configured with stack symbols. It also applies domain snapshots
//  and records useful logs during graph mutations.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:vector_math/vector_math_64.dart';

import '../../../core/models/pda.dart';
import '../../../presentation/providers/pda_editor_provider.dart';
import 'base_graphview_canvas_controller.dart';
import 'graphview_canvas_models.dart';
import 'graphview_pda_mapper.dart';
import 'graphview_state_notifier_adapter.dart';

void _logPdaCanvas(String message) {
  if (kDebugMode) {
    debugPrint('[GraphViewPdaCanvasController] $message');
  }
}

/// Controller responsible for synchronising GraphView with the
/// [PDAEditorNotifier].
class GraphViewPdaCanvasController
    extends BaseGraphViewCanvasController<PDAEditorNotifier, PDA>
    with SharedGraphViewStateController<PDAEditorNotifier, PDA> {
  GraphViewPdaCanvasController({
    required PDAEditorNotifier editorNotifier,
    super.graph,
    super.viewController,
    super.transformationController,
    super.historyLimit,
    super.cacheEvictionThreshold,
  }) : super(notifier: editorNotifier);

  PDAEditorNotifier get _notifier => notifier;

  @override
  late final GraphViewStateNotifierAdapter<PDA> stateNotifierAdapter =
      GraphViewStateNotifierAdapter<PDA>(
    currentData: () => _notifier.currentPda,
    stateIdsOf: (automaton) => automaton.states.map((state) => state.id),
    stateLabelsOf: (automaton) => automaton.states.map((state) => state.label),
    transitionIdsOf: (automaton) =>
        automaton.pdaTransitions.map((transition) => transition.id),
    addState: ({required id, required label, required position}) =>
        _notifier.addOrUpdateState(
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
    logMutation: _logPdaCanvas,
  );

  @override
  GraphViewAutomatonSnapshot toSnapshot(PDA? automaton) {
    return GraphViewPdaMapper.toSnapshot(automaton);
  }

  /// Synchronises the GraphView controller with the latest [automaton].
  @override
  void synchronize(PDA? automaton) {
    _logPdaCanvas(
      'Synchronizing PDA canvas (states=${automaton?.states.length ?? 0}, transitions=${automaton?.pdaTransitions.length ?? 0})',
    );
    synchronizeGraph(automaton);
  }

  /// Replaces the current PDA as one undoable editor operation.
  void replacePda(PDA pda) {
    performMutation(() => _notifier.setPda(pda));
  }

  /// Adds or updates a transition between [fromStateId] and [toStateId].
  void addOrUpdateTransition({
    required String fromStateId,
    required String toStateId,
    String? readSymbol,
    String? popSymbol,
    String? pushSymbol,
    List<String>? pushSymbols,
    bool? isLambdaInput,
    bool? isLambdaPop,
    bool? isLambdaPush,
    String? transitionId,
    double? controlPointX,
    double? controlPointY,
  }) {
    final edgeId = transitionId ?? generateEdgeId();
    final controlPoint = (controlPointX != null && controlPointY != null)
        ? Vector2(controlPointX, controlPointY)
        : null;
    _logPdaCanvas(
      'addOrUpdateTransition -> id=$edgeId from=$fromStateId to=$toStateId read=$readSymbol pop=$popSymbol push=$pushSymbol cp=${controlPoint?.toString()}',
    );
    performMutation(() {
      _notifier.upsertTransition(
        id: edgeId,
        fromStateId: fromStateId,
        toStateId: toStateId,
        readSymbol: readSymbol,
        popSymbol: popSymbol,
        pushSymbol: pushSymbol,
        pushSymbols: pushSymbols,
        isLambdaInput: isLambdaInput,
        isLambdaPop: isLambdaPop,
        isLambdaPush: isLambdaPush,
        controlPoint: controlPoint,
      );
    });
  }

  /// Removes the transition identified by [id] from the automaton.
  @override
  void removeTransition(String id) {
    _logPdaCanvas('removeTransition -> id=$id');
    performMutation(() {
      _notifier.removeTransition(id: id);
    });
  }

  @override
  void applySnapshotToDomain(GraphViewAutomatonSnapshot snapshot) {
    final initialStackSymbol = snapshot.metadata.initialStackSymbol ?? 'Z';
    final stackAlphabet = snapshot.metadata.stackAlphabet.isNotEmpty
        ? snapshot.metadata.stackAlphabet.toSet()
        : <String>{initialStackSymbol};
    final template = _notifier.currentPda ??
        PDA(
          id: snapshot.metadata.id ??
              'pda_${DateTime.now().microsecondsSinceEpoch}',
          name: snapshot.metadata.name ?? 'Canvas PDA',
          states: const {},
          transitions: const {},
          alphabet: snapshot.metadata.alphabet.toSet(),
          initialState: null,
          acceptingStates: const {},
          created: DateTime.now(),
          modified: DateTime.now(),
          bounds: const math.Rectangle<double>(0, 0, 800, 600),
          stackAlphabet: {...stackAlphabet, initialStackSymbol},
          initialStackSymbol: initialStackSymbol,
          panOffset: Vector2.zero(),
          zoomLevel: 1.0,
        );

    final merged =
        GraphViewPdaMapper.mergeIntoTemplate(snapshot, template).copyWith(
      id: snapshot.metadata.id ?? template.id,
      name: snapshot.metadata.name ?? template.name,
      alphabet: snapshot.metadata.alphabet.isNotEmpty
          ? snapshot.metadata.alphabet.toSet()
          : template.alphabet,
      modified: DateTime.now(),
    );

    _logPdaCanvas(
      'applySnapshotToDomain -> states=${merged.states.length} transitions=${merged.pdaTransitions.length}',
    );
    _notifier.setPda(merged);
    synchronize(merged);
  }

  @override
  void replaceDomainDocument(PDA document) {
    _notifier.setPda(document);
  }
}
