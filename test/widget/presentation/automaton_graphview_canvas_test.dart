//
//  automaton_graphview_canvas_test.dart
//  Turing Lab
//
//  Suite abrangente que examina o AutomatonGraphViewCanvas, garantindo
//  integração com provedores simulados, controlador personalizado e repositório
//  de layout em cenários de interação por gestos. Os testes validam adição e
//  movimentação de estados, edição inline de transições e respostas a layouts
//  não suportados, assegurando consistência entre a interface e o estado do
//  autômato.
//
//  Thales Matheus Mendonça Santos - October 2025
//

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphview/graphview_turing_lab.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/simulation_highlight.dart';
import 'package:turing_lab/core/models/state.dart' as automaton_state;
import 'package:turing_lab/features/canvas/graphview/graphview_canvas_controller.dart';
import 'package:turing_lab/features/canvas/graphview/graphview_label_field_editor.dart';
import 'package:turing_lab/features/canvas/graphview/graphview_link_overlay_utils.dart';
import 'package:turing_lab/presentation/providers/automaton_state_provider.dart';
import 'package:turing_lab/presentation/widgets/automaton_canvas_tool.dart';
import 'package:turing_lab/presentation/widgets/automaton_graphview_canvas.dart';

class _RecordingAutomatonStateNotifier extends AutomatonStateNotifier {
  _RecordingAutomatonStateNotifier() : super();

  final List<Map<String, Object?>> transitionCalls = [];
  final List<String> removedTransitionIds = [];

  @override
  void addOrUpdateTransition({
    required String id,
    required String fromStateId,
    required String toStateId,
    required String label,
    double? controlPointX,
    double? controlPointY,
  }) {
    transitionCalls.add({
      'id': id,
      'fromStateId': fromStateId,
      'toStateId': toStateId,
      'label': label,
      'controlPointX': controlPointX,
      'controlPointY': controlPointY,
    });
    super.addOrUpdateTransition(
      id: id,
      fromStateId: fromStateId,
      toStateId: toStateId,
      label: label,
      controlPointX: controlPointX,
      controlPointY: controlPointY,
    );
  }

  @override
  void removeTransition({required String id}) {
    removedTransitionIds.add(id);
    super.removeTransition(id: id);
  }
}

class _RecordingGraphViewCanvasController extends GraphViewCanvasController {
  _RecordingGraphViewCanvasController({required super.automatonStateNotifier});

  final List<FSA?> synchronizedAutomata = [];
  int addStateAtCallCount = 0;
  Offset? lastAddStateWorldOffset;
  int moveStateCallCount = 0;
  int previewStatePositionCallCount = 0;
  String? lastMoveStateId;
  Offset? lastMoveStatePosition;

  @override
  void synchronize(FSA? automaton) {
    synchronizedAutomata.add(automaton);
    super.synchronize(automaton);
  }

  @override
  void addStateAt(Offset worldPosition) {
    addStateAtCallCount++;
    lastAddStateWorldOffset = worldPosition;
  }

  @override
  void moveState(String id, Offset position) {
    moveStateCallCount++;
    lastMoveStateId = id;
    lastMoveStatePosition = position;
  }

  @override
  void previewStatePosition(String id, Offset position) {
    previewStatePositionCallCount++;
    super.previewStatePosition(id, position);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AutomatonGraphViewCanvas gestures', () {
    late _RecordingAutomatonStateNotifier provider;
    late _RecordingGraphViewCanvasController controller;
    late AutomatonCanvasToolController toolController;

    setUp(() {
      provider = _RecordingAutomatonStateNotifier();
      controller = _RecordingGraphViewCanvasController(
        automatonStateNotifier: provider,
      );
      toolController = AutomatonCanvasToolController(
        AutomatonCanvasTool.addState,
      );
    });

    tearDown(() {
      controller.dispose();
      toolController.dispose();
    });

    testWidgets(
      'delegates taps on empty background to controller when add-state tool is active',
      (tester) async {
        final automaton = FSA(
          id: 'empty',
          name: 'Empty Automaton',
          states: <automaton_state.State>{},
          transitions: const <FSATransition>{},
          alphabet: const <String>{},
          initialState: null,
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

        await tester.tap(find.byType(AutomatonGraphViewCanvas));
        await tester.pump();

        expect(controller.addStateAtCallCount, equals(1));
        expect(controller.lastAddStateWorldOffset, isNotNull);
      },
    );

    testWidgets(
      'resynchronizes when automaton structure changes with same identity fields',
      (tester) async {
        final canvasKey = GlobalKey();
        final state = automaton_state.State(
          id: 'q0',
          label: 'q0',
          position: Vector2(40, 40),
          isInitial: true,
        );
        final automaton = FSA(
          id: 'same-id',
          name: 'Same Name',
          states: {state},
          transitions: const <FSATransition>{},
          alphabet: const <String>{},
          initialState: state,
          acceptingStates: <automaton_state.State>{},
          created: DateTime.utc(2024, 1, 1),
          modified: DateTime.utc(2024, 1, 1),
          bounds: const math.Rectangle<double>(0, 0, 400, 300),
          zoomLevel: 1,
          panOffset: Vector2.zero(),
        );

        provider.updateAutomaton(automaton);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AutomatonGraphViewCanvas(
                automaton: automaton,
                canvasKey: canvasKey,
                controller: controller,
                toolController: toolController,
              ),
            ),
          ),
        );
        await tester.pump();

        final initialSyncCount = controller.synchronizedAutomata.length;
        expect(initialSyncCount, greaterThan(0));

        final movedState = state.copyWith(position: Vector2(180, 120));
        final updatedAutomaton = automaton.copyWith(
          states: {movedState},
          initialState: movedState,
        );

        provider.updateAutomaton(updatedAutomaton);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AutomatonGraphViewCanvas(
                automaton: updatedAutomaton,
                canvasKey: canvasKey,
                controller: controller,
                toolController: toolController,
              ),
            ),
          ),
        );
        await tester.pump();

        expect(
          controller.synchronizedAutomata.length,
          greaterThan(initialSyncCount),
        );
        expect(controller.synchronizedAutomata.last, same(updatedAutomaton));
      },
    );

    testWidgets('exposes canvas states and transitions to semantics', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      addTearDown(semantics.dispose);

      final state = automaton_state.State(
        id: 'A',
        label: 'A',
        position: Vector2(40, 40),
        isInitial: true,
      );
      final acceptingState = automaton_state.State(
        id: 'B',
        label: 'B',
        position: Vector2(160, 40),
        isAccepting: true,
      );
      final automaton = FSA(
        id: 'semantic-canvas',
        name: 'Semantic Canvas',
        states: {state, acceptingState},
        transitions: {
          FSATransition(
            id: 't0',
            fromState: state,
            toState: acceptingState,
            inputSymbols: const {'a'},
          ),
        },
        alphabet: const <String>{'a'},
        initialState: state,
        acceptingStates: <automaton_state.State>{acceptingState},
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

      expect(
        find.bySemanticsLabel(
          'Automaton canvas viewport. 2 states, 1 transition.',
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          'State A. Initial state. 1 outgoing transition. '
          '0 incoming transitions.',
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          'State B. Accepting state. 0 outgoing transitions. '
          '1 incoming transition.',
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Transition t0 from A to B labeled a.'),
        findsOneWidget,
      );
    });

    testWidgets('supports keyboard shortcuts for core canvas tools', (
      tester,
    ) async {
      final automaton = FSA(
        id: 'keyboard-canvas',
        name: 'Keyboard Canvas',
        states: <automaton_state.State>{},
        transitions: const <FSATransition>{},
        alphabet: const <String>{},
        initialState: null,
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

      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      await tester.pump();
      expect(controller.addStateAtCallCount, equals(1));

      await tester.sendKeyEvent(LogicalKeyboardKey.keyT);
      await tester.pump();
      expect(toolController.activeTool, AutomatonCanvasTool.transition);

      await tester.sendKeyEvent(LogicalKeyboardKey.keyV);
      await tester.pump();
      expect(toolController.activeTool, AutomatonCanvasTool.selection);
    });

    testWidgets(
      'keeps controller-owned transformation usable after teardown until the '
      'controller is disposed',
      (tester) async {
        final transformation =
            controller.graphController.transformationController!;
        final automaton = FSA(
          id: 'teardown',
          name: 'Teardown Automaton',
          states: <automaton_state.State>{},
          transitions: const <FSATransition>{},
          alphabet: const <String>{},
          initialState: null,
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

        await tester.pump();
        await tester.pumpWidget(const SizedBox.shrink());

        // The view detaching must not dispose the transformation controller:
        // the canvas controller owns it and may attach another view later.
        expect(
          () => transformation.value = Matrix4.identity(),
          returnsNormally,
        );

        controller.dispose();

        expect(
          () => transformation.value = Matrix4.identity()
            ..translateByDouble(1.0, 0.0, 0.0, 1.0),
          throwsFlutterError,
        );
      },
    );

    for (final tool in [
      AutomatonCanvasTool.addState,
      AutomatonCanvasTool.transition,
    ]) {
      testWidgets(
        "ignores drag gestures when ${tool.toString().split('.').last} tool is active",
        (tester) async {
          toolController.setActiveTool(tool);
          final state = automaton_state.State(
            id: 'A',
            label: 'A',
            position: Vector2(40, 40),
            isInitial: true,
          );
          final automaton = FSA(
            id: 'drag',
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

          final canvasKey = GlobalKey();
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: AutomatonGraphViewCanvas(
                  automaton: automaton,
                  canvasKey: canvasKey,
                  controller: controller,
                  toolController: toolController,
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();

          final transformation =
              controller.graphController.transformationController;
          expect(transformation, isNotNull);
          final initialMatrix = List<double>.from(
            transformation!.value.storage,
          );

          await tester.drag(find.text('A'), const Offset(32, 0));
          await tester.pump();

          await tester.drag(find.byKey(canvasKey), const Offset(48, -16));
          await tester.pump();

          expect(controller.moveStateCallCount, equals(0));
          expect(controller.lastMoveStateId, isNull);
          expect(
            List<double>.from(transformation.value.storage),
            equals(initialMatrix),
          );
        },
      );
    }

    testWidgets('disables GraphView interpolation while a node is dragged', (
      tester,
    ) async {
      toolController.setActiveTool(AutomatonCanvasTool.selection);

      final state = automaton_state.State(
        id: 'A',
        label: 'A',
        position: Vector2(40, 40),
        isInitial: true,
      );
      final automaton = FSA(
        id: 'drag-motion',
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

      expect(tester.widget<GraphView>(find.byType(GraphView)).animated, isTrue);

      final gesture =
          await tester.startGesture(tester.getCenter(find.text('A')));
      await gesture.moveBy(const Offset(24, 0));
      await tester.pump();

      expect(controller.previewStatePositionCallCount, greaterThan(0));
      expect(controller.moveStateCallCount, equals(0));
      expect(
        tester.widget<GraphView>(find.byType(GraphView)).animated,
        isFalse,
      );

      await gesture.up();
      await tester.pumpAndSettle();

      expect(controller.moveStateCallCount, equals(1));
      expect(tester.widget<GraphView>(find.byType(GraphView)).animated, isTrue);
    });
  });

  group('AutomatonGraphViewCanvas', () {
    late _RecordingAutomatonStateNotifier provider;
    late GraphViewCanvasController controller;
    late AutomatonCanvasToolController toolController;
    late automaton_state.State stateA;
    late automaton_state.State stateB;

    setUp(() {
      provider = _RecordingAutomatonStateNotifier();
      controller = GraphViewCanvasController(automatonStateNotifier: provider);
      toolController = AutomatonCanvasToolController(
        AutomatonCanvasTool.transition,
      );

      stateA = automaton_state.State(
        id: 'A',
        label: 'A',
        position: Vector2(40, 40),
        isInitial: true,
      );
      stateB = automaton_state.State(
        id: 'B',
        label: 'B',
        position: Vector2(200, 160),
        isAccepting: true,
      );
    });

    tearDown(() {
      controller.dispose();
      toolController.dispose();
    });

    FSA buildAutomaton(Set<FSATransition> transitions) {
      final automaton = FSA(
        id: 'auto',
        name: 'Automaton',
        states: {stateA, stateB},
        transitions: transitions,
        alphabet: const {'a', 'b'},
        initialState: stateA,
        acceptingStates: {stateB},
        created: DateTime.utc(2024, 1, 1),
        modified: DateTime.utc(2024, 1, 1),
        bounds: const math.Rectangle<double>(0, 0, 400, 300),
        zoomLevel: 1,
        panOffset: Vector2.zero(),
      );
      provider.updateAutomaton(automaton);
      controller.synchronize(automaton);
      return automaton;
    }

    Future<void> pumpCanvas(WidgetTester tester, FSA automaton) async {
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
    }

    testWidgets('renders disconnected states without transitions', (
      tester,
    ) async {
      final automaton = buildAutomaton({});

      await pumpCanvas(tester, automaton);

      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
    });

    testWidgets(
      'shows transition editor after jittery taps when transition tool is active',
      (tester) async {
        final automaton = buildAutomaton({});

        await pumpCanvas(tester, automaton);

        final sourceGesture = await tester.startGesture(
          tester.getCenter(find.text('A')),
        );
        await sourceGesture.moveBy(const Offset(1, 1));
        await sourceGesture.up();
        await tester.pump();

        final targetGesture = await tester.startGesture(
          tester.getCenter(find.text('B')),
        );
        await targetGesture.moveBy(const Offset(1, -1));
        await targetGesture.up();
        await tester.pumpAndSettle();

        expect(find.byType(GraphViewLabelFieldEditor), findsOneWidget);
      },
    );

    testWidgets('allows creating a new edge when one already exists', (
      tester,
    ) async {
      const existingId = 'transition_existing';
      final transition = FSATransition(
        id: existingId,
        fromState: stateA,
        toState: stateB,
        label: 'x',
        inputSymbols: const {'x'},
        controlPoint: Vector2(120, 40),
      );
      final automaton = buildAutomaton({transition});

      await pumpCanvas(tester, automaton);

      await tester.tap(find.text('A'));
      await tester.pump();
      await tester.tap(find.text('B'), warnIfMissed: false);
      await tester.pumpAndSettle();

      final createNewFinder = find.byKey(
        const ValueKey('automaton-transition-choice-create-new'),
      );
      expect(createNewFinder, findsOneWidget);
      await tester.tap(createNewFinder);
      await tester.pumpAndSettle();

      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);
      await tester.enterText(textFieldFinder, 'b');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(provider.transitionCalls, hasLength(1));
      final call = provider.transitionCalls.single;
      expect(call['id'], isNot(equals(existingId)));
      expect(call['fromStateId'], equals('A'));
      expect(call['toStateId'], equals('B'));
      expect(call['label'], equals('b'));
    });

    testWidgets('edits an existing transition selected from the dialog', (
      tester,
    ) async {
      const existingId = 'transition_existing';
      final transition = FSATransition(
        id: existingId,
        fromState: stateA,
        toState: stateB,
        label: 'x',
        inputSymbols: const {'x'},
        controlPoint: Vector2(120, 40),
      );
      final automaton = buildAutomaton({transition});

      await pumpCanvas(tester, automaton);

      await tester.tap(find.text('A'));
      await tester.pump();
      await tester.tap(find.text('B'), warnIfMissed: false);
      await tester.pumpAndSettle();

      final existingOptionFinder = find.byKey(
        const ValueKey('automaton-transition-choice-transition_existing'),
      );
      expect(existingOptionFinder, findsOneWidget);
      await tester.tap(existingOptionFinder);
      await tester.pumpAndSettle();

      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);
      final textField = tester.widget<TextField>(textFieldFinder);
      expect(textField.controller?.text, equals('x'));

      await tester.enterText(textFieldFinder, 'edited');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(provider.transitionCalls, hasLength(1));
      final call = provider.transitionCalls.single;
      expect(call['id'], equals(existingId));
      expect(call['label'], equals('edited'));
    });

    testWidgets('deletes only the selected existing transition', (
      tester,
    ) async {
      const existingId = 'transition_existing';
      final transition = FSATransition(
        id: existingId,
        fromState: stateA,
        toState: stateB,
        label: 'x',
        inputSymbols: const {'x'},
        controlPoint: Vector2(120, 40),
      );
      final automaton = buildAutomaton({transition});

      await pumpCanvas(tester, automaton);

      await tester.tap(find.text('A'));
      await tester.pump();
      await tester.tap(find.text('B'), warnIfMissed: false);
      await tester.pumpAndSettle();

      final existingOptionFinder = find.byKey(
        const ValueKey('automaton-transition-choice-transition_existing'),
      );
      expect(existingOptionFinder, findsOneWidget);
      await tester.tap(existingOptionFinder);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(provider.removedTransitionIds, equals([existingId]));
      expect(provider.transitionCalls, isEmpty);
    });

    testWidgets('animates node highlight emphasis to the highlighted state', (
      tester,
    ) async {
      final automaton = buildAutomaton({});

      await pumpCanvas(tester, automaton);

      final scaleFinder = find.ancestor(
        of: find.text('A'),
        matching: find.byType(AnimatedScale),
      );

      expect(tester.widget<AnimatedScale>(scaleFinder).scale, equals(1.0));

      controller.applyHighlight(
        SimulationHighlight(
          stateIds: {'A'},
          transitionIds: <String>{},
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.widget<AnimatedScale>(scaleFinder).scale, equals(1.04));

      controller.clearHighlight();
      await tester.pumpAndSettle();

      expect(tester.widget<AnimatedScale>(scaleFinder).scale, equals(1.0));
    });

    testWidgets(
      'recomputes grouped transition anchor while dragging before pointer up',
      (tester) async {
        toolController.setActiveTool(AutomatonCanvasTool.selection);

        final transition = FSATransition(
          id: 'transition_drag',
          fromState: stateA,
          toState: stateB,
          label: 'a',
          inputSymbols: const {'a'},
        );
        final automaton = buildAutomaton({transition});

        await pumpCanvas(tester, automaton);

        final edgeBefore = controller.edgeById('transition_drag');
        expect(edgeBefore, isNotNull);
        final anchorBefore = resolveLinkAnchorWorld(controller, edgeBefore!);
        expect(anchorBefore, isNotNull);

        final gesture = await tester.startGesture(
          tester.getCenter(find.text('B'), warnIfMissed: false),
        );
        await gesture.moveBy(const Offset(0, -96));
        await tester.pump();

        final edgeDuringDrag = controller.edgeById('transition_drag');
        expect(edgeDuringDrag, isNotNull);
        final anchorDuringDrag = resolveLinkAnchorWorld(
          controller,
          edgeDuringDrag!,
        );
        expect(anchorDuringDrag, isNotNull);
        expect(
          (anchorDuringDrag! - anchorBefore!).distance,
          greaterThan(8),
        );

        await gesture.up();
        await tester.pumpAndSettle();
      },
    );
  });
}
