//
//  graphview_canvas_toolbar_test.dart
//  Turing Lab
//
//  Widget tests for GraphViewCanvasToolbar, covering status messages and
//  zoom, fit, reset, and history callbacks on a fake controller. Scenarios
//  confirm optional buttons and extra tools appear only when provided,
//  preserving the responsive UI contract.
//
//  Thales Matheus Mendonça Santos - October 2025
//

import 'dart:math' as math;
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:turing_lab/core/constants/help_topic_ids.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/state.dart' as automaton_state;
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/pages/help_page.dart';
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
  int viewportInsetsUpdateCount = 0;

  @override
  void updateViewportInsets(EdgeInsets insets) {
    viewportInsetsUpdateCount++;
    super.updateViewportInsets(insets);
  }

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

  testWidgets('defaults to one collapsed row of primary editing actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: GraphViewCanvasToolbar(
              controller: controller,
              enableToolSelection: true,
              showSelectionTool: true,
              onSelectTool: () {},
              onAddState: () {},
              onAddTransition: () {},
            ),
          ),
        ),
      ),
    );

    final icons = tester
        .widgetList<IconButton>(find.byType(IconButton))
        .map((button) => (button.icon as Icon).icon)
        .toList();
    expect(
      icons,
      <IconData>[
        Icons.pan_tool,
        Icons.add,
        Icons.arrow_right_alt,
        Icons.open_in_full,
      ],
    );
    expect(find.byType(FittedBox), findsNothing);
    expect(find.byType(SingleChildScrollView), findsNothing);

    final toolbarHeight = tester
        .getSize(find.byKey(const ValueKey('canvas-toolbar-surface')))
        .height;
    for (final button
        in tester.widgetList<IconButton>(find.byType(IconButton))) {
      expect(
        tester.getSize(find.byWidget(button)).shortestSide,
        greaterThanOrEqualTo(44),
      );
    }
    expect(toolbarHeight, lessThan(72));
  });

  testWidgets('expands in one row and exposes the ordered secondary actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
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

    await tester.tap(find.byIcon(Icons.open_in_full));
    await tester.pumpAndSettle();

    final icons = tester
        .widgetList<IconButton>(find.byType(IconButton))
        .map((button) => (button.icon as Icon).icon)
        .toList();
    expect(
      icons,
      <IconData>[
        Icons.pan_tool,
        Icons.add,
        Icons.arrow_right_alt,
        Icons.undo,
        Icons.redo,
        Icons.zoom_out,
        Icons.zoom_in,
        Icons.fit_screen,
        Icons.center_focus_strong,
        Icons.delete_outline,
        Icons.help_outline,
        Icons.close_fullscreen,
      ],
    );
    expect(find.text('100%'), findsOneWidget);
    for (final button
        in tester.widgetList<IconButton>(find.byType(IconButton))) {
      expect(
        tester.getSize(find.byWidget(button)).shortestSide,
        greaterThanOrEqualTo(44),
      );
    }
    expect(
      tester
          .getSize(find.byKey(const ValueKey('canvas-toolbar-surface')))
          .height,
      lessThan(72),
    );
  });

  testWidgets('uses explicit overflow instead of shrinking on narrow widths', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
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

    await tester.tap(find.byIcon(Icons.open_in_full));
    await tester.pumpAndSettle();

    expect(
        find.byKey(const ValueKey('canvas-toolbar-overflow')), findsOneWidget);
    expect(find.byType(FittedBox), findsNothing);
    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('canvas-toolbar-overflow')));
    await tester.pumpAndSettle();
    expect(find.text('Fit to content'), findsOneWidget);
    expect(find.text('Clear canvas'), findsOneWidget);
  });

  testWidgets('keeps every compact toolbar control visible at 320 width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: GraphViewCanvasToolbar(
              controller: controller,
              enableToolSelection: true,
              showSelectionTool: true,
              onSelectTool: () {},
              onAddState: () {},
              onAddTransition: () {},
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.open_in_full));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('100%'), findsNothing);

    final surfaceRect = tester.getRect(
      find.byKey(const ValueKey('canvas-toolbar-surface')),
    );
    final visibleControls = <Finder>[
      find.widgetWithIcon(IconButton, Icons.pan_tool),
      find.widgetWithIcon(IconButton, Icons.add),
      find.widgetWithIcon(IconButton, Icons.arrow_right_alt),
      find.byKey(const ValueKey('canvas-toolbar-overflow')),
      find.widgetWithIcon(IconButton, Icons.close_fullscreen),
    ];
    for (final control in visibleControls) {
      expect(control, findsOneWidget);
      final controlRect = tester.getRect(control);
      expect(surfaceRect.contains(controlRect.topLeft), isTrue);
      expect(surfaceRect.contains(controlRect.bottomRight), isTrue);
    }

    await tester.tap(find.byKey(const ValueKey('canvas-toolbar-overflow')));
    await tester.pumpAndSettle();

    expect(find.text('Zoom 100%'), findsOneWidget);
    expect(find.text('Fit to content'), findsOneWidget);
  });

  testWidgets('keeps zoom percentage and bound states synchronized', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: GraphViewCanvasToolbar(
              controller: controller,
              enableToolSelection: true,
              showSelectionTool: true,
              onSelectTool: () {},
              onAddState: () {},
              onAddTransition: () {},
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.open_in_full));
    await tester.pumpAndSettle();

    final transformation = controller.graphController.transformationController!;
    transformation.value = Matrix4.diagonal3Values(2, 2, 1);
    await tester.pump();

    expect(find.text('200%'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.zoom_in))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.zoom_out))
          .onPressed,
      isNotNull,
    );

    transformation.value = Matrix4.diagonal3Values(0.05, 0.05, 1);
    await tester.pump();

    expect(find.text('5%'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.zoom_out))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.zoom_in))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('reports measured safe viewport inset for bottom placement', (
    tester,
  ) async {
    EdgeInsets? reportedInsets;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: GraphViewCanvasToolbar(
              controller: controller,
              placement: CanvasToolbarPlacement.bottomCenter,
              onViewportInsetsChanged: (insets) => reportedInsets = insets,
              enableToolSelection: true,
              showSelectionTool: true,
              onSelectTool: () {},
              onAddState: () {},
              onAddTransition: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(reportedInsets, isNotNull);
    expect(reportedInsets!.bottom, greaterThanOrEqualTo(60));
    expect(reportedInsets!.top, 0);
    expect(controller.viewportInsets, reportedInsets);

    final initialUpdateCount = controller.viewportInsetsUpdateCount;
    controller.graphController.transformationController!.value =
        Matrix4.translationValues(12, 8, 0);
    await tester.pumpAndSettle();

    expect(controller.viewportInsetsUpdateCount, initialUpdateCount);
  });

  testWidgets('respects reduced motion and 200 percent text scaling', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(2),
              disableAnimations: true,
            ),
            child: Scaffold(
              body: GraphViewCanvasToolbar(
                controller: controller,
                enableToolSelection: true,
                showSelectionTool: true,
                onSelectTool: () {},
                onAddState: () {},
                onAddTransition: () {},
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.open_in_full));
    await tester.pump();

    expect(find.byType(AnimatedSize), findsNothing);
    expect(
      find.byKey(const ValueKey('canvas-toolbar-reduced-motion')),
      findsOneWidget,
    );
    expect(
        find.byKey(const ValueKey('canvas-toolbar-overflow')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('focus traversal orders follow the expanded visual order', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
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
    final collapsedOrders = tester
        .widgetList<FocusTraversalOrder>(find.byType(FocusTraversalOrder))
        .map((widget) => (widget.order as NumericFocusOrder).order)
        .toList();
    expect(collapsedOrders, orderedEquals(<double>[0, 1, 2, 900]));

    await tester.tap(find.byIcon(Icons.open_in_full));
    await tester.pumpAndSettle();

    final expandedOrders = tester
        .widgetList<FocusTraversalOrder>(find.byType(FocusTraversalOrder))
        .map((widget) => (widget.order as NumericFocusOrder).order)
        .toList();
    expect(
      expandedOrders,
      orderedEquals(<double>[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 900]),
    );
  });

  testWidgets('exposes the selected editing tool as a toggled semantic', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: GraphViewCanvasToolbar(
                controller: controller,
                enableToolSelection: true,
                showSelectionTool: true,
                activeTool: AutomatonCanvasTool.selection,
                onSelectTool: () {},
                onAddState: () {},
                onAddTransition: () {},
              ),
            ),
          ),
        ),
      );

      final node = tester.getSemantics(
        find.bySemanticsLabel('Canvas action: Select'),
      );
      expect(
        node.getSemanticsData().flagsCollection.isToggled,
        Tristate.isTrue,
      );
    } finally {
      semantics.dispose();
    }
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

    await tester.tap(find.byIcon(Icons.open_in_full));
    await tester.pumpAndSettle();

    expect(find.byTooltip('2 states · 1 transition'), findsOneWidget);
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

  testWidgets('Expanded layout renders expected actions', (tester) async {
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

    await tester.tap(find.byIcon(Icons.open_in_full));
    await tester.pumpAndSettle();

    expect(find.byType(IconButton), findsNWidgets(9));

    await tester.tap(find.widgetWithIcon(IconButton, Icons.add));
    await tester.pump();

    expect(addStateInvoked, isTrue);
    expect(
      tester.getSize(find.widgetWithIcon(IconButton, Icons.add)).height,
      greaterThanOrEqualTo(44),
    );
    expect(
      tester
          .getSize(find.widgetWithIcon(IconButton, Icons.help_outline))
          .height,
      greaterThanOrEqualTo(48),
    );
  });

  testWidgets('Expanded layout renders actions in grouped order', (
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

    await tester.tap(find.byIcon(Icons.open_in_full));
    await tester.pumpAndSettle();

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
        Icons.close_fullscreen,
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

    await tester.tap(find.byIcon(Icons.open_in_full));
    await tester.pumpAndSettle();

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

      await tester.tap(find.byIcon(Icons.open_in_full));
      await tester.pumpAndSettle();

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

    await tester.tap(find.byIcon(Icons.open_in_full));
    await tester.pumpAndSettle();

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

    await tester.tap(find.byIcon(Icons.open_in_full));
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

    await tester.tap(find.byIcon(Icons.open_in_full));
    await tester.pumpAndSettle();

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

    await tester.tap(find.byIcon(Icons.open_in_full));
    await tester.pumpAndSettle();

    await tester.tap(
      find.bySemanticsLabel('Canvas action: Help & Shortcuts'),
    );
    await tester.pump();

    expect(helpCount, equals(1));
  });

  testWidgets('fallback Help opens and focuses canvas shortcuts', (
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

    await tester.tap(find.byIcon(Icons.open_in_full));
    await tester.pumpAndSettle();

    await tester.tap(
      find.bySemanticsLabel('Canvas action: Help & Shortcuts'),
    );
    await tester.pumpAndSettle();

    final page = tester.widget<HelpPage>(find.byType(HelpPage));
    final node = find.byKey(
      const ValueKey('help-node-${HelpTopicIds.shortcutsCanvas}'),
    );
    expect(page.initialTopicId, HelpTopicIds.shortcutsCanvas);
    expect(tester.widget<InkWell>(node).focusNode?.hasFocus, isTrue);
    expect(
      find.byKey(
        const ValueKey('help-body-${HelpTopicIds.shortcutsCanvas}'),
      ),
      findsOneWidget,
    );
  });
}
