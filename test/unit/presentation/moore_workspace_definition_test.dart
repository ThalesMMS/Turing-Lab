import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/transducers/transducers.dart';
import 'package:turing_lab/presentation/transducers/graphview_transducer_canvas_controller.dart';
import 'package:turing_lab/presentation/transducers/moore_workspace_definition.dart';
import 'package:turing_lab/presentation/transducers/transducer_editor_state.dart';
import 'package:turing_lab/presentation/transducers/transducer_workspace_definition.dart';

void main() {
  test('Moore adapter keeps output on states and transitions input-only', () {
    final adapter = mooreWorkspaceDefinition.adapter;
    var machine = createEmptyMooreMachine();
    machine = adapter.updateAlphabets(
      machine,
      inputAlphabet: {const TransducerInputSymbol('a')},
      outputAlphabet: {const TransducerOutputSymbol('idle')},
    );
    machine = adapter.addState(
      machine,
      id: 'q0',
      label: 'Idle',
      position: const Offset(20, 30),
    );
    machine = adapter.updateState(
      machine,
      id: 'q0',
      isInitial: true,
      outputTokens: const ['idle'],
    );
    machine = adapter.putTransition(
      machine,
      id: 'loop',
      fromStateId: 'q0',
      toStateId: 'q0',
      draft: TransducerTransitionDraft(input: 'a'),
    );

    final mapping = adapter.toGraphMapping(machine);
    expect((mapping.nodes.single as MooreGraphNode).output.values, ['idle']);
    expect(mapping.edges.single, isA<MooreGraphEdge>());
    expect(
      () => adapter.putTransition(
        machine,
        id: 'invalid-output',
        fromStateId: 'q0',
        toStateId: 'q0',
        draft: TransducerTransitionDraft(
          input: 'a',
          outputTokens: const ['idle'],
        ),
      ),
      throwsUnsupportedError,
    );
  });

  test('Moore canvas output mutation participates in undo and redo', () {
    final initial = _machine();
    final notifier = TransducerEditorNotifier<MooreMachine>(initial);
    final controller = GraphViewTransducerCanvasController<MooreMachine>(
      notifier: notifier,
      definition: mooreWorkspaceDefinition,
    );
    addTearDown(controller.dispose);
    controller.synchronize(initial);

    controller.updateStateOutput('q0', const []);
    expect(notifier.document.states.first.output.values, isEmpty);
    expect(controller.undo(), isTrue);
    expect(notifier.document.states.first.output.values, ['idle', 'ready']);
    expect(controller.redo(), isTrue);
    expect(notifier.document.states.first.output.values, isEmpty);

    final snapshot = controller.toSnapshot(notifier.document);
    expect(snapshot.nodes.first.secondaryLabel, '[]');
    expect(snapshot.nodes.first.transducerOutput, TransducerOutputWord.empty);
    expect(snapshot.nodes.every((node) => !node.isAccepting), isTrue);
    expect(snapshot.edges.single.transducerOutput, isNull);
    expect(
      () => controller.updateStateFlags('q0', isAccepting: true),
      throwsUnsupportedError,
    );
  });
}

MooreMachine _machine() => MooreMachine(
      id: const TransducerMachineId('moore-test'),
      name: 'Moore test',
      revision: const TransducerRevision(0),
      inputAlphabet: {const TransducerInputSymbol('a')},
      outputAlphabet: {
        const TransducerOutputSymbol('idle'),
        const TransducerOutputSymbol('ready'),
      },
      states: [
        MooreState(
          id: const TransducerStateId('q0'),
          label: 'Idle',
          position: const TransducerPoint(0, 0),
          output: TransducerOutputWord.fromValues(const ['idle', 'ready']),
          isInitial: true,
        ),
      ],
      transitions: const [
        MooreTransition(
          id: TransducerTransitionId('loop'),
          from: TransducerStateId('q0'),
          to: TransducerStateId('q0'),
          input: TransducerInputSymbol('a'),
        ),
      ],
    );
