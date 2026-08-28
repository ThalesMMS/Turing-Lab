import '../../core/transducers/transducers.dart';
import '../../features/canvas/graphview/base_graphview_canvas_controller.dart';
import '../../features/canvas/graphview/graphview_canvas_models.dart';
import '../../features/canvas/graphview/graphview_state_notifier_adapter.dart';
import 'transducer_editor_state.dart';
import 'transducer_workspace_definition.dart';

enum TransducerEditError {
  unknownState,
  inputRequired,
  inputOutsideAlphabet,
  outputOutsideAlphabet,
  duplicateInput,
  unexpectedTransitionOutput,
  unexpectedStateOutput,
}

class GraphViewTransducerCanvasController<
        TMachine extends DeterministicFiniteStateTransducer>
    extends BaseGraphViewCanvasController<TransducerEditorNotifier<TMachine>,
        TMachine>
    with
        SharedGraphViewStateController<TransducerEditorNotifier<TMachine>,
            TMachine> {
  GraphViewTransducerCanvasController({
    required super.notifier,
    required this.definition,
    super.graph,
    super.viewController,
    super.transformationController,
  });

  final TransducerWorkspaceDefinition<TMachine> definition;

  TMachine _mutate(
    TMachine Function(TMachine machine) mutation,
  ) {
    final updated = mutation(notifier.document);
    notifier.replaceDocument(updated);
    return updated;
  }

  @override
  late final GraphViewStateNotifierAdapter<TMachine> stateNotifierAdapter =
      GraphViewStateNotifierAdapter<TMachine>(
    currentData: () => notifier.document,
    stateIdsOf: (machine) => machine.states.map((state) => state.id.value),
    stateLabelsOf: (machine) => machine.states.map((state) => state.label),
    transitionIdsOf: (machine) =>
        machine.transitions.map((transition) => transition.id.value),
    addState: ({required id, required label, required position}) => _mutate(
      (machine) => definition.adapter.addState(
        machine,
        id: id,
        label: label,
        position: position,
      ),
    ),
    moveState: ({required id, required position}) => _mutate(
      (machine) => definition.adapter.moveState(
        machine,
        id: id,
        position: position,
      ),
    ),
    updateStateLabel: ({required id, required label}) => _mutate(
      (machine) => definition.adapter.updateState(
        machine,
        id: id,
        label: label,
      ),
    ),
    updateStateFlags: ({required id, isInitial, isAccepting}) {
      if (isAccepting != null) {
        throw UnsupportedError(
          'Transducer canvases do not support accepting states.',
        );
      }
      _mutate(
        (machine) => definition.adapter.updateState(
          machine,
          id: id,
          isInitial: isInitial,
        ),
      );
    },
    removeState: (id) => _mutate(
      (machine) => definition.adapter.removeState(machine, id),
    ),
    logMutation: (_) {},
  );

  @override
  GraphViewAutomatonSnapshot toSnapshot(TMachine? data) => data == null
      ? const GraphViewAutomatonSnapshot.empty()
      : definition.canvasBridge.toSnapshot(data);

  @override
  void applySnapshotToDomain(GraphViewAutomatonSnapshot snapshot) {
    notifier.replaceDocument(
      definition.canvasBridge.mergeSnapshot(notifier.document, snapshot),
    );
  }

  @override
  void replaceDomainDocument(TMachine document) {
    notifier.replaceDocument(document);
  }

  @override
  void removeTransition(String id) {
    performMutation(
      () => _mutate(
        (machine) => definition.adapter.removeTransition(machine, id),
      ),
    );
  }

  @override
  void updateStateFlags(String id, {bool? isInitial, bool? isAccepting}) {
    if (isAccepting != null) {
      throw UnsupportedError(
        'Transducer canvases do not support accepting states.',
      );
    }
    super.updateStateFlags(id, isInitial: isInitial);
  }

  void putTransition({
    required String fromStateId,
    required String toStateId,
    required TransducerTransitionDraft draft,
    String? transitionId,
  }) {
    final error = validateTransitionDraft(
      fromStateId: fromStateId,
      toStateId: toStateId,
      transitionId: transitionId,
      draft: draft,
    );
    if (error != null) throw ArgumentError(error.name);
    performMutation(
      () => _mutate(
        (machine) => definition.adapter.putTransition(
          machine,
          id: transitionId ?? generateEdgeId(),
          fromStateId: fromStateId,
          toStateId: toStateId,
          draft: draft,
        ),
      ),
    );
  }

  TransducerEditError? validateTransitionDraft({
    required String fromStateId,
    required String toStateId,
    required String? transitionId,
    required TransducerTransitionDraft draft,
  }) {
    final machine = notifier.document;
    final stateIds = machine.states.map((state) => state.id.value).toSet();
    if (!stateIds.contains(fromStateId) || !stateIds.contains(toStateId)) {
      return TransducerEditError.unknownState;
    }
    if (definition.emissionRule is MooreEmissionRule &&
        draft.outputTokens != null) {
      return TransducerEditError.unexpectedTransitionOutput;
    }
    final input = TransducerInputSymbol(draft.input);
    if (draft.input.isEmpty || !machine.inputAlphabet.contains(input)) {
      return draft.input.isEmpty
          ? TransducerEditError.inputRequired
          : TransducerEditError.inputOutsideAlphabet;
    }
    for (final output in draft.outputTokens ?? const <String>[]) {
      if (output.isEmpty ||
          !machine.outputAlphabet.contains(TransducerOutputSymbol(output))) {
        return TransducerEditError.outputOutsideAlphabet;
      }
    }
    final duplicate = machine.transitions.any(
      (candidate) =>
          candidate.id.value != transitionId &&
          candidate.from.value == fromStateId &&
          candidate.input == input,
    );
    if (duplicate) {
      return TransducerEditError.duplicateInput;
    }
    return null;
  }

  void updateStateOutput(String id, Iterable<String> output) {
    final tokens = output.toList(growable: false);
    final error = validateStateOutput(id, tokens);
    if (error == TransducerEditError.unexpectedStateOutput) {
      throw UnsupportedError(error!.name);
    }
    if (error != null) throw ArgumentError(error.name);
    performMutation(
      () => _mutate(
        (machine) => definition.adapter.updateState(
          machine,
          id: id,
          outputTokens: tokens,
        ),
      ),
    );
  }

  TransducerEditError? validateStateOutput(String id, List<String> tokens) {
    if (definition.emissionRule is MealyEmissionRule) {
      return TransducerEditError.unexpectedStateOutput;
    }
    if (!notifier.document.states.any((state) => state.id.value == id)) {
      return TransducerEditError.unknownState;
    }
    for (final token in tokens) {
      if (token.isEmpty ||
          !notifier.document.outputAlphabet
              .contains(TransducerOutputSymbol(token))) {
        return TransducerEditError.outputOutsideAlphabet;
      }
    }
    return null;
  }

  void updateStateDetails({
    required String id,
    required String label,
    required bool isInitial,
    List<String>? outputTokens,
  }) {
    if (outputTokens != null) {
      final error = validateStateOutput(id, outputTokens);
      if (error != null) throw ArgumentError(error.name);
    } else if (!notifier.document.states.any((state) => state.id.value == id)) {
      throw ArgumentError(TransducerEditError.unknownState.name);
    }
    performMutation(
      () => _mutate(
        (machine) => definition.adapter.updateState(
          machine,
          id: id,
          label: label,
          isInitial: isInitial,
          outputTokens: outputTokens,
        ),
      ),
    );
  }

  void updateAlphabets({
    required Set<TransducerInputSymbol> inputAlphabet,
    required Set<TransducerOutputSymbol> outputAlphabet,
  }) {
    performMutation(
      () => _mutate(
        (machine) => definition.adapter.updateAlphabets(
          machine,
          inputAlphabet: inputAlphabet,
          outputAlphabet: outputAlphabet,
        ),
      ),
    );
  }
}
