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
import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

Finder get _moreActionsButton =>
    find.byKey(const ValueKey('canvas-toolbar-overflow'));

Finder get _popupMenuItems =>
    find.byWidgetPredicate((widget) => widget is PopupMenuItem);

Future<void> _openMoreActions(WidgetTester tester) async {
  await tester.tap(_moreActionsButton);
  await tester.pumpAndSettle();
}

Finder _menuItem(String label) => find.ancestor(
  of: find.text(label),
  matching: find.byWidgetPredicate((widget) => widget is PopupMenuItem),
);

Future<void> _selectMenuAction(WidgetTester tester, String label) async {
  await _openMoreActions(tester);
  await tester.tap(_menuItem(label).last);
  await tester.pumpAndSettle();
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

  testWidgets('defaults to primary editing actions plus More', (tester) async {
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

    expect(find.byIcon(Icons.pan_tool), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.byIcon(Icons.arrow_right_alt), findsOneWidget);
    expect(find.byIcon(Icons.more_horiz), findsOneWidget);
    expect(_moreActionsButton, findsOneWidget);
    expect(find.byTooltip('More canvas actions'), findsOneWidget);
    expect(
      tester
          .getSemantics(
            find.bySemanticsLabel('Canvas action: More canvas actions'),
          )
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isTrue,
    );
    expect(find.byIcon(Icons.open_in_full), findsNothing);
    expect(find.byIcon(Icons.close_fullscreen), findsNothing);
    expect(find.byType(FittedBox), findsNothing);
    expect(find.byType(SingleChildScrollView), findsNothing);

    final toolbarHeight = tester
        .getSize(find.byKey(const ValueKey('canvas-toolbar-surface')))
        .height;
    for (final control in <Finder>[
      find.widgetWithIcon(IconButton, Icons.pan_tool),
      find.widgetWithIcon(IconButton, Icons.add),
      find.widgetWithIcon(IconButton, Icons.arrow_right_alt),
      _moreActionsButton,
    ]) {
      expect(tester.getSize(control).shortestSide, greaterThanOrEqualTo(44));
    }
    expect(toolbarHeight, lessThan(72));
  });

  testWidgets('More exposes the ordered secondary actions at wide widths', (
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

    await _openMoreActions(tester);

    expect(
      tester.getTopLeft(_popupMenuItems.first).dy,
      greaterThanOrEqualTo(tester.getBottomLeft(_moreActionsButton).dy),
    );

    const labels = <String>[
      'Undo',
      'Redo',
      'Zoom out',
      'Zoom 100%',
      'Zoom in',
      'Fit to content',
      'Reset view',
      'Clear canvas',
      'Help & Shortcuts',
    ];
    for (final label in labels) {
      expect(find.text(label), findsOneWidget);
    }
    final verticalPositions = labels
        .map((label) => tester.getTopLeft(find.text(label)).dy)
        .toList();
    expect(verticalPositions, orderedEquals([...verticalPositions]..sort()));
    for (var index = 0; index < _popupMenuItems.evaluate().length; index++) {
      expect(
        tester.getSize(_popupMenuItems.at(index)).height,
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

  testWidgets('uses explicit overflow without shrinking on narrow widths', (
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

    expect(_moreActionsButton, findsOneWidget);
    expect(find.byType(FittedBox), findsNothing);
    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(tester.takeException(), isNull);

    await _openMoreActions(tester);
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

    expect(tester.takeException(), isNull);
    expect(find.text('100%'), findsNothing);

    final surfaceRect = tester.getRect(
      find.byKey(const ValueKey('canvas-toolbar-surface')),
    );
    final visibleControls = <Finder>[
      find.widgetWithIcon(IconButton, Icons.pan_tool),
      find.widgetWithIcon(IconButton, Icons.add),
      find.widgetWithIcon(IconButton, Icons.arrow_right_alt),
      _moreActionsButton,
    ];
    for (final control in visibleControls) {
      expect(control, findsOneWidget);
      final controlRect = tester.getRect(control);
      expect(surfaceRect.contains(controlRect.topLeft), isTrue);
      expect(surfaceRect.contains(controlRect.bottomRight), isTrue);
    }

    await _openMoreActions(tester);

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
    final transformation = controller.graphController.transformationController!;
    transformation.value = Matrix4.diagonal3Values(2, 2, 1);
    await tester.pump();

    await _openMoreActions(tester);
    expect(find.text('Zoom 200%'), findsOneWidget);
    expect(
      tester.widget<PopupMenuItem<dynamic>>(_menuItem('Zoom in')).enabled,
      isFalse,
    );
    expect(
      tester.widget<PopupMenuItem<dynamic>>(_menuItem('Zoom out')).enabled,
      isTrue,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    transformation.value = Matrix4.diagonal3Values(0.05, 0.05, 1);
    await tester.pump();

    await _openMoreActions(tester);
    expect(find.text('Zoom 5%'), findsOneWidget);
    expect(
      tester.widget<PopupMenuItem<dynamic>>(_menuItem('Zoom out')).enabled,
      isFalse,
    );
    expect(
      tester.widget<PopupMenuItem<dynamic>>(_menuItem('Zoom in')).enabled,
      isTrue,
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

    expect(find.byType(AnimatedSize), findsNothing);
    expect(
      find.byKey(const ValueKey('canvas-toolbar-reduced-motion')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('canvas-toolbar-overflow')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('focus traversal places More after primary actions', (
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
    final orders = tester
        .widgetList<FocusTraversalOrder>(find.byType(FocusTraversalOrder))
        .map((widget) => (widget.order as NumericFocusOrder).order)
        .toList();
    expect(orders, orderedEquals(<double>[0, 1, 2, 800]));
  });

  testWidgets('More supports keyboard activation and regains focus on close', (
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
                onSelectTool: () {},
                onAddState: () {},
                onAddTransition: () {},
              ),
            ),
          ),
        ),
      );

      final focusable = tester.widget<FocusableActionDetector>(
        find.ancestor(
          of: _moreActionsButton,
          matching: find.byType(FocusableActionDetector),
        ),
      );
      focusable.focusNode!.requestFocus();
      await tester.pump();
      expect(focusable.focusNode!.hasFocus, isTrue);
      final focusedDecoration = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey('canvas-toolbar-overflow-focus-indicator')),
      );
      expect((focusedDecoration.decoration as BoxDecoration).border, isNotNull);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Fit to content'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Fit to content'), findsNothing);
      expect(focusable.focusNode!.hasFocus, isTrue);
      final restoredDecoration = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey('canvas-toolbar-overflow-focus-indicator')),
      );
      expect(
        (restoredDecoration.decoration as BoxDecoration).border,
        isNotNull,
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('Clear is destructive and dispatches exactly once', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      var clearCount = 0;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: GraphViewCanvasToolbar(
                controller: controller,
                onAddState: () {},
                onClear: () => clearCount++,
              ),
            ),
          ),
        ),
      );

      final focusable = tester.widget<FocusableActionDetector>(
        find.ancestor(
          of: _moreActionsButton,
          matching: find.byType(FocusableActionDetector),
        ),
      );
      await _openMoreActions(tester);
      expect(
        find.bySemanticsLabel(
          'Canvas action: Clear canvas. Destructive action.',
        ),
        findsOneWidget,
      );
      expect(
        tester
            .getSemantics(
              find.bySemanticsLabel(
                'Canvas action: Clear canvas. Destructive action.',
              ),
            )
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isTrue,
      );
      final clearText = tester.widget<Text>(find.text('Clear canvas'));
      expect(
        clearText.style?.color,
        Theme.of(tester.element(find.byWidget(clearText))).colorScheme.error,
      );

      await tester.tap(_menuItem('Clear canvas'));
      await tester.pumpAndSettle();

      expect(clearCount, 1);
      expect(find.text('Clear canvas'), findsNothing);
      expect(focusable.focusNode!.hasFocus, isTrue);
    } finally {
      semantics.dispose();
    }
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

    await _openMoreActions(tester);
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

  testWidgets('primary actions stay inline while secondary actions use More', (
    tester,
  ) async {
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

    expect(find.byType(IconButton), findsOneWidget);
    expect(_moreActionsButton, findsOneWidget);

    await tester.tap(find.widgetWithIcon(IconButton, Icons.add));
    await tester.pump();

    expect(addStateInvoked, isTrue);
    expect(
      tester.getSize(find.widgetWithIcon(IconButton, Icons.add)).height,
      greaterThanOrEqualTo(44),
    );
    await _openMoreActions(tester);
    expect(_menuItem('Help & Shortcuts'), findsOneWidget);
  });

  testWidgets('More renders secondary actions in grouped order', (
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

    await _openMoreActions(tester);

    final icons = tester
        .widgetList<Icon>(
          find.descendant(of: _popupMenuItems, matching: find.byType(Icon)),
        )
        .map((icon) => icon.icon)
        .toList();

    expect(
      icons,
      equals(<IconData>[
        Icons.undo,
        Icons.redo,
        Icons.zoom_out,
        Icons.zoom_in_map,
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
      find.bySemanticsLabel('Canvas action: More canvas actions'),
      findsOneWidget,
    );
    await _openMoreActions(tester);
    expect(find.bySemanticsLabel('Canvas action: Zoom out'), findsOneWidget);
    expect(find.bySemanticsLabel('Canvas action: Zoom in'), findsOneWidget);
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

  testWidgets('localizes desktop canvas actions in Portuguese', (tester) async {
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
        'Mais ações do canvas',
      ]) {
        expect(find.bySemanticsLabel('Ação do canvas: $label'), findsOneWidget);
      }

      await _openMoreActions(tester);
      for (final label in <String>[
        'Desfazer',
        'Refazer',
        'Diminuir zoom',
        'Aumentar zoom',
        'Ajustar ao conteúdo',
        'Redefinir visualização',
        'Ajuda e atalhos',
      ]) {
        expect(find.bySemanticsLabel('Ação do canvas: $label'), findsOneWidget);
      }
      expect(
        find.bySemanticsLabel(
          'Ação do canvas: Limpar canvas. Ação destrutiva.',
        ),
        findsOneWidget,
      );
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

    await _selectMenuAction(tester, 'Zoom out');
    await _selectMenuAction(tester, 'Zoom in');

    expect(controller.zoomOutCount, 1);
    expect(controller.zoomInCount, 1);

    await _selectMenuAction(tester, 'Fit to content');

    expect(controller.fitCount, initialFitCount + 1);

    await _selectMenuAction(tester, 'Reset view');

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

    await _selectMenuAction(tester, 'Fit to content');

    final fitMatrix = Matrix4.copy(transformation.value);
    expect(fitMatrix, isNot(equals(Matrix4.identity())));

    await _selectMenuAction(tester, 'Reset view');

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

    await _openMoreActions(tester);
    expect(
      tester.widget<PopupMenuItem<dynamic>>(_menuItem('Undo')).enabled,
      isFalse,
    );
    expect(
      tester.widget<PopupMenuItem<dynamic>>(_menuItem('Redo')).enabled,
      isFalse,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    controller.addStateAtCenter();
    await tester.pumpAndSettle();

    await _openMoreActions(tester);
    expect(
      tester.widget<PopupMenuItem<dynamic>>(_menuItem('Undo')).enabled,
      isTrue,
    );
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

    await _selectMenuAction(tester, 'Help & Shortcuts');

    expect(helpCount, equals(1));
  });

  testWidgets(
    'document actions keep their order and dispatch exactly once from More',
    (tester) async {
      var arrangeCount = 0;
      var importCount = 0;
      var notesCount = 0;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: GraphViewCanvasToolbar(
                controller: controller,
                onAddState: () {},
                onArrangeAutomaton: () => arrangeCount++,
                onImportAutomaton: () => importCount++,
                onDocumentNotes: () => notesCount++,
              ),
            ),
          ),
        ),
      );

      await _openMoreActions(tester);
      const labels = [
        'Arrange automaton states',
        'Import automaton',
        'Document notes',
      ];
      final positions = labels
          .map((label) => tester.getTopLeft(find.text(label)).dy)
          .toList();
      expect(positions, orderedEquals([...positions]..sort()));
      expect(find.text('New note'), findsNothing);
      await tester.tap(_menuItem(labels[0]).last);
      await tester.pumpAndSettle();
      await _selectMenuAction(tester, labels[1]);
      await _selectMenuAction(tester, labels[2]);

      expect((arrangeCount, importCount, notesCount), (1, 1, 1));
    },
  );

  testWidgets(
    'document actions are capability-driven and disabled without a document',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: GraphViewCanvasToolbar(
                controller: controller,
                onAddState: () {},
                onArrangeAutomaton: () {},
                onImportAutomaton: () {},
                onDocumentNotes: () {},
                documentActionsEnabled: false,
              ),
            ),
          ),
        ),
      );

      await _openMoreActions(tester);
      for (final label in const [
        'Arrange automaton states',
        'Import automaton',
        'Document notes',
      ]) {
        expect(
          tester.widget<PopupMenuItem<dynamic>>(_menuItem(label)).enabled,
          isFalse,
        );
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: GraphViewCanvasToolbar(
                controller: controller,
                onAddState: () {},
              ),
            ),
          ),
        ),
      );
      await _openMoreActions(tester);
      expect(find.text('Arrange automaton states'), findsNothing);
      expect(find.text('Import automaton'), findsNothing);
      expect(find.text('Document notes'), findsNothing);
    },
  );

  testWidgets(
    'document actions remain semantic and localized at 320 px and 200 percent',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            locale: const Locale('pt', 'BR'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: Scaffold(
              body: GraphViewCanvasToolbar(
                controller: controller,
                onAddState: () {},
                onArrangeAutomaton: () {},
                onImportAutomaton: () {},
                onDocumentNotes: () {},
              ),
            ),
          ),
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Organizar estados do autômato'), findsOneWidget);
      expect(find.text('Importar autômato'), findsOneWidget);
      expect(find.text('Notas do documento'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Ação do canvas: Importar autômato'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

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

    await _selectMenuAction(tester, 'Help & Shortcuts');

    final page = tester.widget<HelpPage>(find.byType(HelpPage));
    final node = find.byKey(
      const ValueKey('help-node-${HelpTopicIds.shortcutsCanvas}'),
    );
    expect(page.initialTopicId, HelpTopicIds.shortcutsCanvas);
    expect(tester.widget<InkWell>(node).focusNode?.hasFocus, isTrue);
    expect(
      find.byKey(const ValueKey('help-body-${HelpTopicIds.shortcutsCanvas}')),
      findsOneWidget,
    );
  });
}
