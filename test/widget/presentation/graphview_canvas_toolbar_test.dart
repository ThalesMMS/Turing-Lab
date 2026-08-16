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
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/providers/automaton_state_provider.dart';
import 'package:turing_lab/presentation/widgets/automaton_canvas_tool.dart';
import 'package:turing_lab/presentation/widgets/automaton_graphview_canvas.dart';
import 'package:turing_lab/presentation/widgets/graphview_canvas_toolbar.dart';
import 'package:turing_lab/presentation/widgets/keyboard_shortcuts_dialog.dart';
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
            ),
          ),
        ),
      ),
    );

    expect(find.byType(IconButton), findsNWidgets(8));

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
        Icons.zoom_out,
        Icons.zoom_in,
        Icons.fit_screen,
        Icons.center_focus_strong,
        Icons.delete_outline,
        Icons.help_outline,
      ]),
    );
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
            ),
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Canvas action: Add state'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Canvas action: Zoom out'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Canvas action: Zoom in'),
      findsOneWidget,
    );
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

  testWidgets('localizes desktop canvas actions in Portuguese', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            locale: const Locale('pt'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: GraphViewCanvasToolbar(
                controller: controller,
                enableToolSelection: true,
                showSelectionTool: true,
                onSelectTool: () {},
                onAddState: () {},
                onAddTransition: () {},
                onClear: () {},
              ),
            ),
          ),
        ),
      );

      for (final label in <String>[
        'Selecionar',
        'Adicionar estado',
        'Adicionar transição',
        'Desfazer',
        'Refazer',
        'Diminuir zoom',
        'Aumentar zoom',
        'Ajustar ao conteúdo',
        'Redefinir visualização',
        'Limpar canvas',
        'Ajuda e atalhos',
      ]) {
        expect(
          find.bySemanticsLabel('Ação do canvas: $label'),
          findsOneWidget,
        );
      }
    } finally {
      semantics.dispose();
    }
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
            ),
          ),
        ),
      ),
    );

    final initialFitCount = controller.fitCount;
    final initialResetCount = controller.resetCount;

    await tester.tap(find.widgetWithIcon(IconButton, Icons.zoom_out));
    await tester.pump();
    await tester.tap(find.widgetWithIcon(IconButton, Icons.zoom_in));
    await tester.pump();

    expect(controller.zoomOutCount, 1);
    expect(controller.zoomInCount, 1);

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

  testWidgets('routes help through a custom callback', (tester) async {
    var helpCount = 0;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: GraphViewCanvasToolbar(
              controller: controller,
              onAddState: () {},
              onHelp: () => helpCount++,
            ),
          ),
        ),
      ),
    );

    await tester.tap(
      find.bySemanticsLabel('Canvas action: Help & Shortcuts'),
    );
    await tester.pump();

    expect(helpCount, equals(1));
  });

  testWidgets('opens keyboard shortcuts when no help callback is provided', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: GraphViewCanvasToolbar(
              controller: controller,
              onAddState: () {},
            ),
          ),
        ),
      ),
    );

    await tester.tap(
      find.bySemanticsLabel('Canvas action: Help & Shortcuts'),
    );
    await tester.pumpAndSettle();

    expect(find.byType(KeyboardShortcutsDialog), findsOneWidget);
  });
}
