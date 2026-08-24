//
//  pda_canvas_goldens_test.dart
//  Turing Lab
//
//  Visual regression golden tests for PDACanvasGraphView, capturing snapshots
//  of critical pushdown-automaton canvas states: empty, single marked states,
//  multiple states with PDA transitions (read, pop, and push symbols), and
//  balanced automata. Guards visual consistency across changes and catches
//  automatic regressions in PDA rendering.
//
//  Thales Matheus Mendonça Santos - January 2026
//
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:turing_lab/core/models/pda.dart';
import 'package:turing_lab/core/models/pda_transition.dart';
import 'package:turing_lab/core/models/simulation_highlight.dart';
import 'package:turing_lab/core/models/state.dart' as automaton_state;
import 'package:turing_lab/features/canvas/graphview/graphview_pda_canvas_controller.dart';
import 'package:turing_lab/presentation/providers/pda_editor_provider.dart';
import 'package:turing_lab/presentation/widgets/automaton_canvas_tool.dart';
import 'package:turing_lab/presentation/widgets/pda_canvas_graphview.dart';

class _TestPDAEditorProvider extends PDAEditorNotifier {
  _TestPDAEditorProvider();
}

void main() {
  group('PDACanvasGraphView golden tests', () {
    testGoldens('renders empty canvas', (tester) async {
      final provider = _TestPDAEditorProvider();
      final controller = GraphViewPdaCanvasController(editorNotifier: provider);
      final toolController = AutomatonCanvasToolController(
        AutomatonCanvasTool.selection,
      );

      final pda = PDA(
        id: 'empty',
        name: 'Empty PDA',
        states: <automaton_state.State>{},
        transitions: <PDATransition>{},
        alphabet: const <String>{},
        initialState: null,
        acceptingStates: <automaton_state.State>{},
        created: DateTime.utc(2024, 1, 1),
        modified: DateTime.utc(2024, 1, 1),
        bounds: const math.Rectangle<double>(0, 0, 400, 300),
        zoomLevel: 1,
        panOffset: Vector2.zero(),
        stackAlphabet: const {'Z'},
        initialStackSymbol: 'Z',
      );

      provider.setPda(pda);
      controller.synchronize(pda);

      final widget = ProviderScope(
        overrides: [pdaEditorProvider.overrideWith((ref) => provider)],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: PDACanvasGraphView(
                controller: controller,
                toolController: toolController,
                onPdaModified: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpWidgetBuilder(widget);

      await screenMatchesGolden(tester, 'pda_canvas_empty');

      controller.dispose();
      toolController.dispose();
    });

    testGoldens('renders single normal state', (tester) async {
      final provider = _TestPDAEditorProvider();
      final controller = GraphViewPdaCanvasController(editorNotifier: provider);
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

      final pda = PDA(
        id: 'single-state',
        name: 'Single State PDA',
        states: <automaton_state.State>{state},
        transitions: <PDATransition>{},
        alphabet: const <String>{},
        initialState: null,
        acceptingStates: <automaton_state.State>{},
        created: DateTime.utc(2024, 1, 1),
        modified: DateTime.utc(2024, 1, 1),
        bounds: const math.Rectangle<double>(0, 0, 400, 300),
        zoomLevel: 1,
        panOffset: Vector2.zero(),
        stackAlphabet: const {'Z'},
        initialStackSymbol: 'Z',
      );

      provider.setPda(pda);
      controller.synchronize(pda);

      final widget = ProviderScope(
        overrides: [pdaEditorProvider.overrideWith((ref) => provider)],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: PDACanvasGraphView(
                controller: controller,
                toolController: toolController,
                onPdaModified: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpWidgetBuilder(widget);

      await screenMatchesGolden(tester, 'pda_canvas_single_state');

      controller.dispose();
      toolController.dispose();
    });

    testGoldens('renders single initial state', (tester) async {
      final provider = _TestPDAEditorProvider();
      final controller = GraphViewPdaCanvasController(editorNotifier: provider);
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

      final pda = PDA(
        id: 'initial-state',
        name: 'Initial State PDA',
        states: <automaton_state.State>{state},
        transitions: <PDATransition>{},
        alphabet: const <String>{},
        initialState: state,
        acceptingStates: <automaton_state.State>{},
        created: DateTime.utc(2024, 1, 1),
        modified: DateTime.utc(2024, 1, 1),
        bounds: const math.Rectangle<double>(0, 0, 400, 300),
        zoomLevel: 1,
        panOffset: Vector2.zero(),
        stackAlphabet: const {'Z'},
        initialStackSymbol: 'Z',
      );

      provider.setPda(pda);
      controller.synchronize(pda);

      final widget = ProviderScope(
        overrides: [pdaEditorProvider.overrideWith((ref) => provider)],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: PDACanvasGraphView(
                controller: controller,
                toolController: toolController,
                onPdaModified: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpWidgetBuilder(widget);

      await screenMatchesGolden(tester, 'pda_canvas_initial_state');

      controller.dispose();
      toolController.dispose();
    });

    testGoldens('renders single accepting state', (tester) async {
      final provider = _TestPDAEditorProvider();
      final controller = GraphViewPdaCanvasController(editorNotifier: provider);
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

      final pda = PDA(
        id: 'accepting-state',
        name: 'Accepting State PDA',
        states: <automaton_state.State>{state},
        transitions: <PDATransition>{},
        alphabet: const <String>{},
        initialState: null,
        acceptingStates: <automaton_state.State>{state},
        created: DateTime.utc(2024, 1, 1),
        modified: DateTime.utc(2024, 1, 1),
        bounds: const math.Rectangle<double>(0, 0, 400, 300),
        zoomLevel: 1,
        panOffset: Vector2.zero(),
        stackAlphabet: const {'Z'},
        initialStackSymbol: 'Z',
      );

      provider.setPda(pda);
      controller.synchronize(pda);

      final widget = ProviderScope(
        overrides: [pdaEditorProvider.overrideWith((ref) => provider)],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: PDACanvasGraphView(
                controller: controller,
                toolController: toolController,
                onPdaModified: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpWidgetBuilder(widget);

      await screenMatchesGolden(tester, 'pda_canvas_accepting_state');

      controller.dispose();
      toolController.dispose();
    });

    testGoldens('renders initial and accepting state', (tester) async {
      final provider = _TestPDAEditorProvider();
      final controller = GraphViewPdaCanvasController(editorNotifier: provider);
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

      final pda = PDA(
        id: 'initial-accepting-state',
        name: 'Initial and Accepting State',
        states: <automaton_state.State>{state},
        transitions: <PDATransition>{},
        alphabet: const <String>{},
        initialState: state,
        acceptingStates: <automaton_state.State>{state},
        created: DateTime.utc(2024, 1, 1),
        modified: DateTime.utc(2024, 1, 1),
        bounds: const math.Rectangle<double>(0, 0, 400, 300),
        zoomLevel: 1,
        panOffset: Vector2.zero(),
        stackAlphabet: const {'Z'},
        initialStackSymbol: 'Z',
      );

      provider.setPda(pda);
      controller.synchronize(pda);

      final widget = ProviderScope(
        overrides: [pdaEditorProvider.overrideWith((ref) => provider)],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: PDACanvasGraphView(
                controller: controller,
                toolController: toolController,
                onPdaModified: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpWidgetBuilder(widget);

      await screenMatchesGolden(tester, 'pda_canvas_initial_accepting_state');

      controller.dispose();
      toolController.dispose();
    });

    testGoldens('renders multiple states with PDA transitions', (tester) async {
      final provider = _TestPDAEditorProvider();
      final controller = GraphViewPdaCanvasController(editorNotifier: provider);
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

      final transition = PDATransition.readAndStack(
        id: 't1',
        fromState: q0,
        toState: q1,
        inputSymbol: 'a',
        popSymbol: 'Z',
        pushSymbol: 'AZ',
        label: 'a, Z/AZ',
      );

      final pda = PDA(
        id: 'two-states',
        name: 'Two States with PDA Transition',
        states: <automaton_state.State>{q0, q1},
        transitions: <PDATransition>{transition},
        alphabet: const <String>{'a'},
        initialState: q0,
        acceptingStates: <automaton_state.State>{q1},
        created: DateTime.utc(2024, 1, 1),
        modified: DateTime.utc(2024, 1, 1),
        bounds: const math.Rectangle<double>(0, 0, 400, 300),
        zoomLevel: 1,
        panOffset: Vector2.zero(),
        stackAlphabet: const {'Z', 'A'},
        initialStackSymbol: 'Z',
      );

      provider.setPda(pda);
      controller.synchronize(pda);

      final widget = ProviderScope(
        overrides: [pdaEditorProvider.overrideWith((ref) => provider)],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: PDACanvasGraphView(
                controller: controller,
                toolController: toolController,
                onPdaModified: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpWidgetBuilder(widget);

      await screenMatchesGolden(
        tester,
        'pda_canvas_multiple_states_with_transitions',
      );

      controller.dispose();
      toolController.dispose();
    });

    testGoldens('renders self-loop transition', (tester) async {
      final provider = _TestPDAEditorProvider();
      final controller = GraphViewPdaCanvasController(editorNotifier: provider);
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

      final transition = PDATransition.readAndStack(
        id: 't1',
        fromState: q0,
        toState: q0,
        inputSymbol: 'a',
        popSymbol: 'Z',
        pushSymbol: 'Z',
        label: 'a, Z/Z',
      );

      final pda = PDA(
        id: 'self-loop',
        name: 'State with Self Loop',
        states: <automaton_state.State>{q0},
        transitions: <PDATransition>{transition},
        alphabet: const <String>{'a'},
        initialState: q0,
        acceptingStates: <automaton_state.State>{q0},
        created: DateTime.utc(2024, 1, 1),
        modified: DateTime.utc(2024, 1, 1),
        bounds: const math.Rectangle<double>(0, 0, 400, 300),
        zoomLevel: 1,
        panOffset: Vector2.zero(),
        stackAlphabet: const {'Z'},
        initialStackSymbol: 'Z',
      );

      provider.setPda(pda);
      controller.synchronize(pda);

      final widget = ProviderScope(
        overrides: [pdaEditorProvider.overrideWith((ref) => provider)],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: PDACanvasGraphView(
                controller: controller,
                toolController: toolController,
                onPdaModified: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpWidgetBuilder(widget);

      await screenMatchesGolden(tester, 'pda_canvas_self_loop');

      controller.dispose();
      toolController.dispose();
    });

    testGoldens('renders balanced parentheses PDA', (tester) async {
      final provider = _TestPDAEditorProvider();
      final controller = GraphViewPdaCanvasController(editorNotifier: provider);
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

      final t1 = PDATransition.readAndStack(
        id: 't1',
        fromState: q0,
        toState: q0,
        inputSymbol: '(',
        popSymbol: 'Z',
        pushSymbol: 'Z(',
        label: '(, Z/Z(',
      );

      final t2 = PDATransition.readAndStack(
        id: 't2',
        fromState: q0,
        toState: q0,
        inputSymbol: ')',
        popSymbol: '(',
        pushSymbol: '',
        label: '), (/',
      );

      final t3 = PDATransition.epsilon(
        id: 't3',
        fromState: q0,
        toState: q1,
        label: 'λ, Z/Z',
      );

      final pda = PDA(
        id: 'balanced-parens',
        name: 'Balanced Parentheses',
        states: <automaton_state.State>{q0, q1},
        transitions: <PDATransition>{t1, t2, t3},
        alphabet: const <String>{'(', ')'},
        initialState: q0,
        acceptingStates: <automaton_state.State>{q1},
        created: DateTime.utc(2024, 1, 1),
        modified: DateTime.utc(2024, 1, 1),
        bounds: const math.Rectangle<double>(0, 0, 400, 300),
        zoomLevel: 1,
        panOffset: Vector2.zero(),
        stackAlphabet: const {'Z', '('},
        initialStackSymbol: 'Z',
      );

      provider.setPda(pda);
      controller.synchronize(pda);

      final widget = ProviderScope(
        overrides: [pdaEditorProvider.overrideWith((ref) => provider)],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: PDACanvasGraphView(
                controller: controller,
                toolController: toolController,
                onPdaModified: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpWidgetBuilder(widget);

      await screenMatchesGolden(tester, 'pda_canvas_balanced_parentheses');

      controller.dispose();
      toolController.dispose();
    });

    testGoldens('renders complex PDA with multiple transitions', (
      tester,
    ) async {
      final provider = _TestPDAEditorProvider();
      final controller = GraphViewPdaCanvasController(editorNotifier: provider);
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

      final t1 = PDATransition.readAndStack(
        id: 't1',
        fromState: q0,
        toState: q1,
        inputSymbol: 'a',
        popSymbol: 'Z',
        pushSymbol: 'AZ',
        label: 'a, Z/AZ',
      );

      final t2 = PDATransition.readAndStack(
        id: 't2',
        fromState: q0,
        toState: q2,
        inputSymbol: 'b',
        popSymbol: 'Z',
        pushSymbol: 'BZ',
        label: 'b, Z/BZ',
      );

      final t3 = PDATransition.readAndStack(
        id: 't3',
        fromState: q1,
        toState: q2,
        inputSymbol: 'b',
        popSymbol: 'A',
        pushSymbol: '',
        label: 'b, A/',
      );

      final pda = PDA(
        id: 'complex',
        name: 'Complex PDA',
        states: <automaton_state.State>{q0, q1, q2},
        transitions: <PDATransition>{t1, t2, t3},
        alphabet: const <String>{'a', 'b'},
        initialState: q0,
        acceptingStates: <automaton_state.State>{q2},
        created: DateTime.utc(2024, 1, 1),
        modified: DateTime.utc(2024, 1, 1),
        bounds: const math.Rectangle<double>(0, 0, 400, 300),
        zoomLevel: 1,
        panOffset: Vector2.zero(),
        stackAlphabet: const {'Z', 'A', 'B'},
        initialStackSymbol: 'Z',
      );

      provider.setPda(pda);
      controller.synchronize(pda);

      final widget = ProviderScope(
        overrides: [pdaEditorProvider.overrideWith((ref) => provider)],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: PDACanvasGraphView(
                controller: controller,
                toolController: toolController,
                onPdaModified: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpWidgetBuilder(widget);

      await screenMatchesGolden(tester, 'pda_canvas_complex');

      controller.dispose();
      toolController.dispose();
    });

    testGoldens(
      'renders renderer migration scenario with highlighted adaptive edges',
      (tester) async {
        final provider = _TestPDAEditorProvider();
        final controller =
            GraphViewPdaCanvasController(editorNotifier: provider);
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

        final autoEdge = PDATransition(
          id: 'p_auto',
          fromState: stateA,
          toState: stateB,
          label: 'a,Z/AZ',
          inputSymbol: 'a',
          popSymbol: 'Z',
          pushSymbol: 'AZ',
        );
        final manualEdge = PDATransition(
          id: 'p_manual',
          fromState: stateA,
          toState: stateB,
          label: 'b,A/AA',
          controlPoint: Vector2(180, 20),
          inputSymbol: 'b',
          popSymbol: 'A',
          pushSymbol: 'AA',
        );
        final loopA = PDATransition(
          id: 'p_loop_a',
          fromState: stateA,
          toState: stateA,
          label: 'λ,A/λ',
          inputSymbol: '',
          popSymbol: 'A',
          pushSymbol: '',
          isLambdaInput: true,
          isLambdaPush: true,
        );
        final loopB = PDATransition(
          id: 'p_loop_b',
          fromState: stateA,
          toState: stateA,
          label: 'λ,Z/Z',
          inputSymbol: '',
          popSymbol: 'Z',
          pushSymbol: 'Z',
          isLambdaInput: true,
        );

        final pda = PDA(
          id: 'renderer-migration',
          name: 'Renderer Migration PDA',
          states: <automaton_state.State>{stateA, stateB, stateC},
          transitions: <PDATransition>{autoEdge, manualEdge, loopA, loopB},
          alphabet: const <String>{'a', 'b'},
          initialState: stateA,
          acceptingStates: <automaton_state.State>{stateB},
          created: DateTime.utc(2024, 1, 1),
          modified: DateTime.utc(2024, 1, 1),
          bounds: const math.Rectangle<double>(0, 0, 480, 360),
          zoomLevel: 1,
          panOffset: Vector2.zero(),
          stackAlphabet: const {'Z', 'A'},
          initialStackSymbol: 'Z',
        );

        provider.setPda(pda);
        controller.synchronize(pda);
        controller.applyHighlight(
          SimulationHighlight(
            transitionIds: <String>{'p_manual'},
          ),
        );

        await tester.pumpWidgetBuilder(
          ProviderScope(
            overrides: [pdaEditorProvider.overrideWith((ref) => provider)],
            child: MaterialApp(
              home: Scaffold(
                body: SizedBox(
                  width: 480,
                  height: 360,
                  child: PDACanvasGraphView(
                    controller: controller,
                    toolController: toolController,
                    onPdaModified: (_) {},
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 300));

        await expectLater(
          find.byType(Scaffold),
          matchesGoldenFile(
            'goldens/pda_canvas_renderer_migration_highlighted.png',
          ),
        );

        controller.dispose();
        toolController.dispose();
      },
    );
  });
}
