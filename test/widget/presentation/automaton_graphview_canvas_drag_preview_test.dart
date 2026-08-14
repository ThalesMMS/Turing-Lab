//
//  automaton_graphview_canvas_drag_preview_test.dart
//  Turing Lab
//
//  Garante que arrastar um estado move o nó visualmente em tempo real, antes
//  de o ponteiro ser solto (pré-visualização ao vivo via previewStatePosition
//  e GraphObserver), em vez de o movimento aparecer apenas após o drop.
//
//  Thales Matheus Mendonça Santos - July 2026
//
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/state.dart' as automaton_state;
import 'package:turing_lab/features/canvas/graphview/graphview_canvas_controller.dart';
import 'package:turing_lab/presentation/providers/automaton_state_provider.dart';
import 'package:turing_lab/presentation/widgets/automaton_canvas_tool.dart';
import 'package:turing_lab/presentation/widgets/automaton_graphview_canvas.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('node follows the pointer while dragging, before pointer up', (
    tester,
  ) async {
    final provider = AutomatonStateNotifier();
    final controller = GraphViewCanvasController(
      automatonStateNotifier: provider,
    );
    final toolController = AutomatonCanvasToolController(
      AutomatonCanvasTool.selection,
    );

    // Far from the origin so RenderCustomLayoutBox's own pointer handling
    // cannot mask the app-level preview path (its hit-test rect starts at 0,0).
    final state = automaton_state.State(
      id: 'A',
      label: 'A',
      position: Vector2(400, 260),
      isInitial: true,
    );
    final automaton = FSA(
      id: 'drag-live-preview',
      name: 'Automaton',
      states: {state},
      transitions: const <FSATransition>{},
      alphabet: const <String>{'a'},
      initialState: state,
      acceptingStates: <automaton_state.State>{},
      created: DateTime.utc(2024, 1, 1),
      modified: DateTime.utc(2024, 1, 1),
      bounds: const math.Rectangle<double>(0, 0, 400, 300),
      zoomLevel: 1,
      panOffset: Vector2.zero(),
    );

    provider.updateAutomaton(automaton);
    controller.synchronize(automaton);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AutomatonGraphViewCanvas(
            automaton: automaton,
            canvasKey: GlobalKey(),
            controller: controller,
            toolController: toolController,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final nodeFinder = find.text('A');
    expect(nodeFinder, findsOneWidget);
    final before = tester.getCenter(nodeFinder);

    final gesture = await tester.startGesture(before);
    await tester.pump();
    await gesture.moveBy(const Offset(60, 45));
    await tester.pump();

    // Pointer is still down: the node must already have moved on screen.
    final during = tester.getCenter(nodeFinder);
    final movedWhileDragging = (during - before).distance;

    await gesture.up();
    await tester.pumpAndSettle();

    expect(
      movedWhileDragging,
      greaterThan(30),
      reason: 'node should visually follow the pointer during the drag '
          '(moved ${movedWhileDragging.toStringAsFixed(1)} px mid-drag)',
    );

    // And the domain must have received the final position on drop.
    final moved = provider.state.currentAutomaton!.states.first.position;
    expect(moved.x != 400 || moved.y != 260, isTrue);
  });
}
