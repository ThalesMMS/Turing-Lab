import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/transducers/transducers.dart';
import 'package:turing_lab/presentation/transducers/graphview_transducer_canvas_controller.dart';
import 'package:turing_lab/presentation/transducers/mealy_workspace_definition.dart';
import 'package:turing_lab/presentation/transducers/transducer_editor_state.dart';
import 'package:turing_lab/presentation/transducers/transducer_workspace_definition.dart';

void main() {
  test('Mealy canvas mutations are undoable and never create acceptance', () {
    final notifier = TransducerEditorNotifier<MealyMachine>(
      createEmptyMealyMachine(),
    );
    final controller = GraphViewTransducerCanvasController<MealyMachine>(
      notifier: notifier,
      definition: mealyWorkspaceDefinition,
    );
    addTearDown(controller.dispose);

    controller.synchronize(notifier.document);
    controller.addStateAt(const Offset(40, 60));
    final state = notifier.document.states.single;
    controller.updateStateFlags(state.id.value, isInitial: true);
    controller.updateAlphabets(
      inputAlphabet: {const TransducerInputSymbol('a')},
      outputAlphabet: {const TransducerOutputSymbol('x')},
    );
    controller.putTransition(
      fromStateId: state.id.value,
      toStateId: state.id.value,
      draft: TransducerTransitionDraft(input: 'a', outputTokens: const ['x']),
    );

    final snapshot = controller.toSnapshot(notifier.document);
    expect(snapshot.nodes.single.isAccepting, isFalse);
    expect(snapshot.edges.single.transducerOutput?.values, ['x']);
    expect(controller.undo(), isTrue);
    expect(notifier.document.transitions, isEmpty);
    expect(controller.redo(), isTrue);
    expect(notifier.document.transitions, hasLength(1));
  });

  test('Mealy adapter rejects accepting-state mutations', () {
    final notifier = TransducerEditorNotifier<MealyMachine>(
      createEmptyMealyMachine(),
    );
    final controller = GraphViewTransducerCanvasController<MealyMachine>(
      notifier: notifier,
      definition: mealyWorkspaceDefinition,
    );
    addTearDown(controller.dispose);

    expect(
      () => controller.updateStateFlags('q0', isAccepting: true),
      throwsUnsupportedError,
    );
    expect(
      () => controller.updateStateOutput('q0', const ['x']),
      throwsUnsupportedError,
    );
    expect(controller.undo(), isFalse);
  });
}
