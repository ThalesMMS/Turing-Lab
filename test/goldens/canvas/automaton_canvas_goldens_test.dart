//
//  automaton_canvas_goldens_test.dart
//  Turing Lab
//
//  Visual regression golden tests for AutomatonGraphViewCanvas, capturing
//  snapshots of critical canvas states: empty, single states, multiple states
//  with transitions, start/accept markings, and simulation highlights. Guards
//  visual consistency across changes and catches automatic regressions in
//  automaton rendering.
//
//  Thales Matheus Mendonça Santos - January 2026
//

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/simulation_highlight.dart';
import 'package:turing_lab/core/models/state.dart' as automaton_state;
import 'package:turing_lab/features/canvas/graphview/graphview_canvas_controller.dart';
import 'package:turing_lab/presentation/providers/automaton_state_provider.dart';
import 'package:turing_lab/presentation/widgets/automaton_canvas_tool.dart';
import 'package:turing_lab/presentation/widgets/automaton_graphview_canvas.dart';

class _TestAutomatonStateNotifier extends AutomatonStateNotifier {
  _TestAutomatonStateNotifier() : super();
}

void main() {
  group('AutomatonGraphViewCanvas golden tests', () {
    testGoldens('renders empty canvas', (tester) async {
      final provider = _TestAutomatonStateNotifier();
      final controller = GraphViewCanvasController(
        automatonStateNotifier: provider,
      );
      final toolController = AutomatonCanvasToolController(
        AutomatonCanvasTool.selection,
      );

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

      final widget = MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 300,
            child: AutomatonGraphViewCanvas(
              automaton: automaton,
              canvasKey: GlobalKey(),
              controller: controller,
              toolController: toolController,
            ),
          ),
        ),
      );

      await tester.pumpWidgetBuilder(widget);

      await screenMatchesGolden(tester, 'automaton_canvas_empty');

      controller.dispose();
      toolController.dispose();
    });

    testGoldens('renders single normal state', (tester) async {
      final provider = _TestAutomatonStateNotifier();
      final controller = GraphViewCanvasController(
        automatonStateNotifier: provider,
      );
      final toolController = AutomatonCanvasToolController(
        AutomatonCanvasTool.selection,
      );

      final state = automaton_state.State(
        id: 'q0',
        label: 'q0',
        position: Vector2(200, 150),
        isInitial: false,
        isAccepting: false,
      );

      final automaton = FSA(
        id: 'single-state',
        name: 'Single State Automaton',
        states: <automaton_state.State>{state},
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

      final widget = MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 300,
            child: AutomatonGraphViewCanvas(
              automaton: automaton,
              canvasKey: GlobalKey(),
              controller: controller,
              toolController: toolController,
            ),
          ),
        ),
      );

      await tester.pumpWidgetBuilder(widget);

      await screenMatchesGolden(tester, 'automaton_canvas_single_state');

      controller.dispose();
      toolController.dispose();
    });

    testGoldens('renders single initial state', (tester) async {
      final provider = _TestAutomatonStateNotifier();
      final controller = GraphViewCanvasController(
        automatonStateNotifier: provider,
      );
      final toolController = AutomatonCanvasToolController(
        AutomatonCanvasTool.selection,
      );

      final state = automaton_state.State(
        id: 'q0',
        label: 'q0',
        position: Vector2(200, 150),
        isInitial: true,
        isAccepting: false,
      );

      final automaton = FSA(
        id: 'initial-state',
        name: 'Initial State Automaton',
        states: <automaton_state.State>{state},
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
      controller.synchronize(automaton);

      final widget = MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 300,
            child: AutomatonGraphViewCanvas(
              automaton: automaton,
              canvasKey: GlobalKey(),
              controller: controller,
              toolController: toolController,
            ),
          ),
        ),
      );

      await tester.pumpWidgetBuilder(widget);

      await screenMatchesGolden(tester, 'automaton_canvas_initial_state');

      controller.dispose();
      toolController.dispose();
    });

    testGoldens('renders single accepting state', (tester) async {
      final provider = _TestAutomatonStateNotifier();
      final controller = GraphViewCanvasController(
        automatonStateNotifier: provider,
      );
      final toolController = AutomatonCanvasToolController(
        AutomatonCanvasTool.selection,
      );

      final state = automaton_state.State(
        id: 'q0',
        label: 'q0',
        position: Vector2(200, 150),
        isInitial: false,
        isAccepting: true,
      );

      final automaton = FSA(
        id: 'accepting-state',
        name: 'Accepting State Automaton',
        states: <automaton_state.State>{state},
        transitions: const <FSATransition>{},
        alphabet: const <String>{},
        initialState: null,
        acceptingStates: <automaton_state.State>{state},
        created: DateTime.utc(2024, 1, 1),
        modified: DateTime.utc(2024, 1, 1),
        bounds: const math.Rectangle<double>(0, 0, 400, 300),
        zoomLevel: 1,
        panOffset: Vector2.zero(),
      );

      provider.updateAutomaton(automaton);
      controller.synchronize(automaton);

      final widget = MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 300,
            child: AutomatonGraphViewCanvas(
              automaton: automaton,
              canvasKey: GlobalKey(),
              controller: controller,
              toolController: toolController,
            ),
          ),
        ),
      );

      await tester.pumpWidgetBuilder(widget);

      await screenMatchesGolden(tester, 'automaton_canvas_accepting_state');

      controller.dispose();
      toolController.dispose();
    });

    testGoldens('renders initial and accepting state', (tester) async {
      final provider = _TestAutomatonStateNotifier();
      final controller = GraphViewCanvasController(
        automatonStateNotifier: provider,
      );
      final toolController = AutomatonCanvasToolController(
        AutomatonCanvasTool.selection,
      );

      final state = automaton_state.State(
        id: 'q0',
        label: 'q0',
        position: Vector2(200, 150),
        isInitial: true,
        isAccepting: true,
      );

      final automaton = FSA(
        id: 'initial-accepting-state',
        name: 'Initial and Accepting State',
        states: <automaton_state.State>{state},
        transitions: const <FSATransition>{},
        alphabet: const <String>{},
        initialState: state,
        acceptingStates: <automaton_state.State>{state},
        created: DateTime.utc(2024, 1, 1),
        modified: DateTime.utc(2024, 1, 1),
        bounds: const math.Rectangle<double>(0, 0, 400, 300),
        zoomLevel: 1,
        panOffset: Vector2.zero(),
      );

      provider.updateAutomaton(automaton);
      controller.synchronize(automaton);

      final widget = MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 300,
            child: AutomatonGraphViewCanvas(
              automaton: automaton,
              canvasKey: GlobalKey(),
              controller: controller,
              toolController: toolController,
            ),
          ),
        ),
      );

      await tester.pumpWidgetBuilder(widget);

      await screenMatchesGolden(
        tester,
        'automaton_canvas_initial_accepting_state',
      );

      controller.dispose();
      toolController.dispose();
    });

    testGoldens('renders multiple states with transitions', (tester) async {
      final provider = _TestAutomatonStateNotifier();
      final controller = GraphViewCanvasController(
        automatonStateNotifier: provider,
      );
      final toolController = AutomatonCanvasToolController(
        AutomatonCanvasTool.selection,
      );

      final q0 = automaton_state.State(
        id: 'q0',
        label: 'q0',
        position: Vector2(100, 150),
        isInitial: true,
        isAccepting: false,
      );

      final q1 = automaton_state.State(
        id: 'q1',
        label: 'q1',
        position: Vector2(300, 150),
        isInitial: false,
        isAccepting: true,
      );

      final transition = FSATransition(
        id: 't1',
        fromState: q0,
        toState: q1,
        symbol: 'a',
        label: 'a',
      );

      final automaton = FSA(
        id: 'two-states',
        name: 'Two States with Transition',
        states: <automaton_state.State>{q0, q1},
        transitions: <FSATransition>{transition},
        alphabet: const <String>{'a'},
        initialState: q0,
        acceptingStates: <automaton_state.State>{q1},
        created: DateTime.utc(2024, 1, 1),
        modified: DateTime.utc(2024, 1, 1),
        bounds: const math.Rectangle<double>(0, 0, 400, 300),
        zoomLevel: 1,
        panOffset: Vector2.zero(),
      );

      provider.updateAutomaton(automaton);
      controller.synchronize(automaton);

      final widget = MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 300,
            child: AutomatonGraphViewCanvas(
              automaton: automaton,
              canvasKey: GlobalKey(),
              controller: controller,
              toolController: toolController,
            ),
          ),
        ),
      );

      await tester.pumpWidgetBuilder(widget);

      await screenMatchesGolden(
        tester,
        'automaton_canvas_multiple_states_with_transitions',
      );

      controller.dispose();
      toolController.dispose();
    });

    testGoldens('renders self-loop transition', (tester) async {
      final provider = _TestAutomatonStateNotifier();
      final controller = GraphViewCanvasController(
        automatonStateNotifier: provider,
      );
      final toolController = AutomatonCanvasToolController(
        AutomatonCanvasTool.selection,
      );

      final q0 = automaton_state.State(
        id: 'q0',
        label: 'q0',
        position: Vector2(200, 150),
        isInitial: true,
        isAccepting: true,
      );

      final transition = FSATransition(
        id: 't1',
        fromState: q0,
        toState: q0,
        symbol: 'a',
        label: 'a',
      );

      final automaton = FSA(
        id: 'self-loop',
        name: 'State with Self Loop',
        states: <automaton_state.State>{q0},
        transitions: <FSATransition>{transition},
        alphabet: const <String>{'a'},
        initialState: q0,
        acceptingStates: <automaton_state.State>{q0},
        created: DateTime.utc(2024, 1, 1),
        modified: DateTime.utc(2024, 1, 1),
        bounds: const math.Rectangle<double>(0, 0, 400, 300),
        zoomLevel: 1,
        panOffset: Vector2.zero(),
      );

      provider.updateAutomaton(automaton);
      controller.synchronize(automaton);

      final widget = MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 300,
            child: AutomatonGraphViewCanvas(
              automaton: automaton,
              canvasKey: GlobalKey(),
              controller: controller,
              toolController: toolController,
            ),
          ),
        ),
      );

      await tester.pumpWidgetBuilder(widget);

      await screenMatchesGolden(tester, 'automaton_canvas_self_loop');

      controller.dispose();
      toolController.dispose();
    });

    testGoldens('renders complex automaton with multiple transitions', (
      tester,
    ) async {
      final provider = _TestAutomatonStateNotifier();
      final controller = GraphViewCanvasController(
        automatonStateNotifier: provider,
      );
      final toolController = AutomatonCanvasToolController(
        AutomatonCanvasTool.selection,
      );

      final q0 = automaton_state.State(
        id: 'q0',
        label: 'q0',
        position: Vector2(100, 150),
        isInitial: true,
        isAccepting: false,
      );

      final q1 = automaton_state.State(
        id: 'q1',
        label: 'q1',
        position: Vector2(300, 100),
        isInitial: false,
        isAccepting: false,
      );

      final q2 = automaton_state.State(
        id: 'q2',
        label: 'q2',
        position: Vector2(300, 200),
        isInitial: false,
        isAccepting: true,
      );

      final t1 = FSATransition(
        id: 't1',
        fromState: q0,
        toState: q1,
        symbol: 'a',
        label: 'a',
      );

      final t2 = FSATransition(
        id: 't2',
        fromState: q0,
        toState: q2,
        symbol: 'b',
        label: 'b',
      );

      final t3 = FSATransition(
        id: 't3',
        fromState: q1,
        toState: q2,
        symbol: 'b',
        label: 'b',
      );

      final automaton = FSA(
        id: 'complex',
        name: 'Complex Automaton',
        states: <automaton_state.State>{q0, q1, q2},
        transitions: <FSATransition>{t1, t2, t3},
        alphabet: const <String>{'a', 'b'},
        initialState: q0,
        acceptingStates: <automaton_state.State>{q2},
        created: DateTime.utc(2024, 1, 1),
        modified: DateTime.utc(2024, 1, 1),
        bounds: const math.Rectangle<double>(0, 0, 400, 300),
        zoomLevel: 1,
        panOffset: Vector2.zero(),
      );

      provider.updateAutomaton(automaton);
      controller.synchronize(automaton);

      final widget = MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 300,
            child: AutomatonGraphViewCanvas(
              automaton: automaton,
              canvasKey: GlobalKey(),
              controller: controller,
              toolController: toolController,
            ),
          ),
        ),
      );

      await tester.pumpWidgetBuilder(widget);

      await screenMatchesGolden(tester, 'automaton_canvas_complex');

      controller.dispose();
      toolController.dispose();
    });

    testGoldens(
      'renders renderer migration scenario with highlighted adaptive edges',
      (tester) async {
        final provider = _TestAutomatonStateNotifier();
        final controller = GraphViewCanvasController(
          automatonStateNotifier: provider,
        );
        final toolController = AutomatonCanvasToolController(
          AutomatonCanvasTool.selection,
        );

        final stateA = automaton_state.State(
          id: 'A',
          label: 'A',
          position: Vector2(40, 120),
          isInitial: true,
        );
        final stateB = automaton_state.State(
          id: 'B',
          label: 'B',
          position: Vector2(260, 120),
          isAccepting: true,
        );
        final stateC = automaton_state.State(
          id: 'C',
          label: 'C',
          position: Vector2(340, 240),
        );

        final autoEdge = FSATransition(
          id: 't_auto',
          fromState: stateA,
          toState: stateB,
          symbol: '0',
          label: '0',
        );
        final manualEdge = FSATransition(
          id: 't_manual',
          fromState: stateA,
          toState: stateB,
          symbol: '1',
          label: '1',
          controlPoint: Vector2(180, 20),
        );
        final loopA = FSATransition(
          id: 't_loop_a',
          fromState: stateA,
          toState: stateA,
          symbol: 'x',
          label: 'x',
        );
        final loopB = FSATransition(
          id: 't_loop_b',
          fromState: stateA,
          toState: stateA,
          symbol: 'y',
          label: 'y',
        );

        final automaton = FSA(
          id: 'renderer-migration',
          name: 'Renderer Migration',
          states: <automaton_state.State>{stateA, stateB, stateC},
          transitions: <FSATransition>{autoEdge, manualEdge, loopA, loopB},
          alphabet: const <String>{'0', '1', 'x', 'y'},
          initialState: stateA,
          acceptingStates: <automaton_state.State>{stateB},
          created: DateTime.utc(2024, 1, 1),
          modified: DateTime.utc(2024, 1, 1),
          bounds: const math.Rectangle<double>(0, 0, 480, 360),
          zoomLevel: 1,
          panOffset: Vector2.zero(),
        );

        provider.updateAutomaton(automaton);
        controller.synchronize(automaton);
        controller.applyHighlight(
          SimulationHighlight(
            transitionIds: <String>{'t_manual'},
          ),
        );

        await tester.pumpWidgetBuilder(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 480,
                height: 360,
                child: AutomatonGraphViewCanvas(
                  automaton: automaton,
                  canvasKey: GlobalKey(),
                  controller: controller,
                  toolController: toolController,
                ),
              ),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 300));

        await expectLater(
          find.byType(Scaffold),
          matchesGoldenFile(
            'goldens/automaton_canvas_renderer_migration_highlighted.png',
          ),
        );

        controller.dispose();
        toolController.dispose();
      },
    );
  });
}
