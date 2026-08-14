//
//  graphview_canvas_toolbar_test.dart
//  Turing Lab
//
//  Conjunto de testes de widget que exercita o GraphViewCanvasToolbar,
//  validando exibição de mensagens de status e disparo dos callbacks de zoom,
//  enquadramento, reset e histórico no controlador falso durante interações.
//  Os cenários confirmam que botões opcionais e ferramentas adicionais aparecem
//  apenas quando fornecidos, mantendo o contrato da interface responsiva.
//
//  Thales Matheus Mendonça Santos - October 2025
//

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/state.dart' as automaton_state;
import 'package:turing_lab/presentation/providers/automaton_state_provider.dart';
import 'package:turing_lab/presentation/widgets/automaton_canvas_tool.dart';
import 'package:turing_lab/presentation/widgets/automaton_graphview_canvas.dart';
import 'package:turing_lab/presentation/widgets/graphview_canvas_toolbar.dart';
import 'package:turing_lab/features/canvas/graphview/graphview_canvas_controller.dart';

class _TestGraphViewCanvasController extends GraphViewCanvasController {
  _TestGraphViewCanvasController({required super.automatonStateNotifier});

  int zoomInCount = 0;
  int zoomOutCount = 0;
  int fitCount = 0;
  int resetCount = 0;
  int undoCount = 0;
  int redoCount = 0;

  @override
  void zoomIn() {
    zoomInCount++;
    super.zoomIn();
  }

  @override
  void zoomOut() {
    zoomOutCount++;
    super.zoomOut();
  }

  @override
  void fitToContent() {
    fitCount++;
    super.fitToContent();
  }

  @override
  void resetView() {
    resetCount++;
    super.resetView();
  }

  @override
  bool undo() {
    undoCount++;
    return super.undo();
  }

  @override
  bool redo() {
    redoCount++;
    return super.redo();
  }
}

void main() {
  late AutomatonStateNotifier provider;
  late _TestGraphViewCanvasController controller;

  setUp(() {
    provider = AutomatonStateNotifier();
    controller = _TestGraphViewCanvasController(
      automatonStateNotifier: provider,
    )..synchronize(provider.state.currentAutomaton);
  });

  tearDown(() {
    controller.dispose();
  });

  testWidgets('GraphViewCanvasToolbar renders provided status message', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: GraphViewCanvasToolbar(
              controller: controller,
              onAddState: () {},
              statusMessage: '2 states · 1 transition',
              layout: GraphViewCanvasToolbarLayout.desktop,
            ),
          ),
        ),
      ),
    );

    expect(find.text('2 states · 1 transition'), findsOneWidget);
  });

  testWidgets('GraphViewCanvasToolbar hides status message when absent', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: GraphViewCanvasToolbar(
              controller: controller,
              onAddState: () {},
              layout: GraphViewCanvasToolbarLayout.desktop,
            ),
          ),
        ),
      ),
    );

    expect(find.textContaining('states'), findsNothing);
    expect(find.textContaining('transition'), findsNothing);
  });

  testWidgets('Desktop layout renders expected actions', (tester) async {
    bool addStateInvoked = false;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: GraphViewCanvasToolbar(
              controller: controller,
              onAddState: () => addStateInvoked = true,
              layout: GraphViewCanvasToolbarLayout.desktop,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(IconButton), findsNWidgets(6));

    await tester.tap(find.widgetWithIcon(IconButton, Icons.add));
    await tester.pump();

    expect(addStateInvoked, isTrue);
    expect(
      tester.getSize(find.widgetWithIcon(IconButton, Icons.add)).height,
      greaterThanOrEqualTo(44),
    );
  });

  testWidgets('Desktop layout renders actions in grouped order', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: GraphViewCanvasToolbar(
              controller: controller,
              onAddState: () {},
              onClear: () {},
              layout: GraphViewCanvasToolbarLayout.desktop,
            ),
          ),
        ),
      ),
    );

    final buttons =
        tester.widgetList<IconButton>(find.byType(IconButton)).toList();
    final icons = buttons.map((button) => (button.icon as Icon).icon).toList();

    expect(
      icons,
      equals(<IconData>[
        Icons.add,
        Icons.undo,
        Icons.redo,
        Icons.fit_screen,
        Icons.center_focus_strong,
        Icons.delete_outline,
        Icons.help_outline,
      ]),
    );
  });

  testWidgets('Mobile layout renders filled buttons with labels', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: GraphViewCanvasToolbar(
              controller: controller,
              onAddState: () {},
              layout: GraphViewCanvasToolbarLayout.mobile,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Add state'), findsOneWidget);
    expect(find.text('Redo'), findsOneWidget);
    expect(find.text('Fit to content'), findsOneWidget);
    expect(find.text('Reset view'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);
    final addStateButton = find.ancestor(
      of: find.text('Add state'),
      matching: find.bySubtype<ButtonStyleButton>(),
    );
    expect(
      tester.getSize(addStateButton).height,
      greaterThanOrEqualTo(44),
    );
  });

  testWidgets('Mobile layout renders actions in grouped order', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: GraphViewCanvasToolbar(
              controller: controller,
              onAddState: () {},
              onClear: () {},
              layout: GraphViewCanvasToolbarLayout.mobile,
            ),
          ),
        ),
      ),
    );

    final labels = <String>[
      'Add state',
      'Undo',
      'Redo',
      'Fit to content',
      'Reset view',
      'Clear canvas',
      'Help & Shortcuts',
    ];

    final renderedLabels = tester
        .elementList(
          find.descendant(
            of: find.byType(GraphViewCanvasToolbar),
            matching: find.byType(Text),
          ),
        )
        .map((element) => (element.widget as Text).data)
        .nonNulls
        .where(labels.contains)
        .toList();

    expect(renderedLabels, labels);
  });

  testWidgets('exposes semantic labels for toolbar actions', (tester) async {
    final handle = tester.ensureSemantics();
    var handleDisposed = false;
    addTearDown(() {
      if (!handleDisposed) {
        handle.dispose();
        handleDisposed = true;
      }
    });

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: GraphViewCanvasToolbar(
              controller: controller,
              onAddState: () {},
              layout: GraphViewCanvasToolbarLayout.desktop,
            ),
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Canvas action: Add state'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Canvas action: Fit to content'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Canvas action: Help & Shortcuts'),
      findsOneWidget,
    );

    handle.dispose();
    handleDisposed = true;
  });

  testWidgets('invokes controller commands when action buttons pressed', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: GraphViewCanvasToolbar(
              controller: controller,
              onAddState: () {},
              layout: GraphViewCanvasToolbarLayout.desktop,
            ),
          ),
        ),
      ),
    );

    final initialFitCount = controller.fitCount;
    final initialResetCount = controller.resetCount;

    await tester.tap(find.widgetWithIcon(IconButton, Icons.fit_screen));
    await tester.pump();

    expect(controller.fitCount, initialFitCount + 1);

    await tester.tap(
      find.widgetWithIcon(IconButton, Icons.center_focus_strong),
    );
    await tester.pump();

    expect(controller.resetCount, greaterThan(initialResetCount));
  });

  testWidgets('toolbar viewport actions settle on the expected final matrix', (
    tester,
  ) async {
    final state = automaton_state.State(
      id: 'A',
      label: 'A',
      position: Vector2(240, 180),
      isInitial: true,
    );
    final automaton = FSA(
      id: 'toolbar-canvas',
      name: 'Toolbar Canvas',
      states: {state},
      transitions: const <FSATransition>{},
      alphabet: const <String>{'a'},
      initialState: state,
      acceptingStates: const <automaton_state.State>{},
      created: DateTime.utc(2024, 1, 1),
      modified: DateTime.utc(2024, 1, 1),
      bounds: const math.Rectangle<double>(0, 0, 600, 400),
      zoomLevel: 1,
      panOffset: Vector2.zero(),
    );
    provider.updateAutomaton(automaton);
    controller.synchronize(automaton);

    final canvasKey = GlobalKey();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                GraphViewCanvasToolbar(
                  controller: controller,
                  onAddState: () {},
                  layout: GraphViewCanvasToolbarLayout.desktop,
                ),
                Expanded(
                  child: AutomatonGraphViewCanvas(
                    automaton: automaton,
                    canvasKey: canvasKey,
                    controller: controller,
                    toolController: AutomatonCanvasToolController(
                      AutomatonCanvasTool.selection,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final transformation = controller.graphController.transformationController!;
    transformation.value = Matrix4.identity();
    await tester.pump();

    await tester.tap(find.widgetWithIcon(IconButton, Icons.fit_screen));
    await tester.pumpAndSettle();

    final fitMatrix = Matrix4.copy(transformation.value);
    expect(fitMatrix, isNot(equals(Matrix4.identity())));

    await tester.tap(
      find.widgetWithIcon(IconButton, Icons.center_focus_strong),
    );
    await tester.pumpAndSettle();

    expect(
      List<double>.from(transformation.value.storage),
      equals(List<double>.from(Matrix4.identity().storage)),
    );
  });

  testWidgets('renders undo and redo buttons respecting history state', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: GraphViewCanvasToolbar(
              controller: controller,
              onAddState: controller.addStateAtCenter,
              layout: GraphViewCanvasToolbarLayout.desktop,
            ),
          ),
        ),
      ),
    );

    final undoFinder = find.widgetWithIcon(IconButton, Icons.undo);
    final redoFinder = find.widgetWithIcon(IconButton, Icons.redo);

    expect(tester.widget<IconButton>(undoFinder).onPressed, isNull);
    expect(tester.widget<IconButton>(redoFinder).onPressed, isNull);

    controller.addStateAtCenter();
    await tester.pumpAndSettle();

    expect(tester.widget<IconButton>(undoFinder).onPressed, isNotNull);
  });

  testWidgets('renders editing tool toggles when enabled', (tester) async {
    bool addStateInvoked = false;
    bool transitionInvoked = false;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: GraphViewCanvasToolbar(
              controller: controller,
              enableToolSelection: true,
              activeTool: AutomatonCanvasTool.transition,
              onAddState: () => addStateInvoked = true,
              onAddTransition: () => transitionInvoked = true,
              layout: GraphViewCanvasToolbarLayout.desktop,
            ),
          ),
        ),
      ),
    );

    expect(find.widgetWithIcon(IconButton, Icons.pan_tool), findsNothing);
    await tester.tap(find.widgetWithIcon(IconButton, Icons.add));
    await tester.tap(find.widgetWithIcon(IconButton, Icons.arrow_right_alt));
    await tester.pump();

    expect(addStateInvoked, isTrue);
    expect(transitionInvoked, isTrue);
  });
}
