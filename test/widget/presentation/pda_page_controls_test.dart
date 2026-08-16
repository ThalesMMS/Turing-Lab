import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/pages/pda_page.dart';
import 'package:turing_lab/presentation/providers/unified_trace_provider.dart';
import 'package:turing_lab/presentation/widgets/automaton_canvas_tool.dart';
import 'package:turing_lab/presentation/widgets/canvas_quick_actions.dart';
import 'package:turing_lab/presentation/widgets/collapsible_canvas_panel.dart';
import 'package:turing_lab/presentation/widgets/context_aware_help_panel.dart';
import 'package:turing_lab/presentation/widgets/graphview_canvas_toolbar.dart';
import 'package:turing_lab/presentation/widgets/keyboard_shortcuts_dialog.dart';
import 'package:turing_lab/presentation/widgets/mobile_automaton_controls.dart';
import 'package:turing_lab/presentation/widgets/pda_canvas_graphview.dart';
import 'package:turing_lab/presentation/widgets/pda_simulation_panel.dart';
import 'package:turing_lab/presentation/widgets/pda/stack_drawer.dart';

Future<void> _pumpPdaPage(
  WidgetTester tester, {
  required Size size,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PDAPage(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  testWidgets('PDA mobile stack inspector collapses out of the canvas', (
    tester,
  ) async {
    await _pumpPdaPage(tester, size: const Size(800, 900));
    final canvas = tester.widget<PDACanvasGraphView>(
      find.byType(PDACanvasGraphView),
    );
    canvas.controller!.addStateAt(const Offset(120, 120));
    await tester.pumpAndSettle();

    expect(find.byType(CollapsibleCanvasPanel), findsOneWidget);
    expect(find.byType(PDAStackPanel), findsOneWidget);

    await tester.tap(find.byTooltip('Collapse Stack panel'));
    await tester.pump();

    expect(find.byType(PDAStackPanel), findsNothing);
    expect(
      tester.getSize(find.byType(CollapsibleCanvasPanel)),
      const Size.square(48),
    );
    await tester.tap(find.byTooltip('Fit to content'));
    await tester.pump();
  });

  for (final width in const [1200.0, 1500.0]) {
    testWidgets('PDA at ${width.toInt()}px docks stack outside the canvas', (
      tester,
    ) async {
      await _pumpPdaPage(tester, size: Size(width, 900));

      final canvasRect = tester.getRect(find.byType(PDACanvasGraphView));
      final stackRect = tester.getRect(find.byType(PDAStackPanel));

      expect(canvasRect.overlaps(stackRect), isFalse);
    });
  }

  testWidgets('empty PDA mobile keeps help reachable from both surfaces', (
    tester,
  ) async {
    await _pumpPdaPage(tester, size: const Size(800, 900));

    final trayHelp = find.descendant(
      of: find.byType(MobileAutomatonControls),
      matching: find.byTooltip('Help'),
    );
    final quickHelp = find.descendant(
      of: find.byType(CanvasQuickActions),
      matching: find.byTooltip('Help'),
    );
    expect(trayHelp, findsOneWidget);
    expect(quickHelp, findsOneWidget);

    await tester.tap(trayHelp);
    await tester.pumpAndSettle();

    expect(find.byType(ContextAwareHelpPanel), findsOneWidget);
    await tester.tap(find.widgetWithIcon(TextButton, Icons.keyboard));
    await tester.pumpAndSettle();

    expect(find.byType(ContextAwareHelpPanel), findsNothing);
    expect(find.byType(KeyboardShortcutsDialog), findsOneWidget);
  });

  testWidgets('PDA mobile transition action toggles back to selection', (
    tester,
  ) async {
    await _pumpPdaPage(tester, size: const Size(800, 900));
    final transitionAction = find.bySemanticsLabel('Add transition');
    final originalCanvas = tester.widget<PDACanvasGraphView>(
      find.byType(PDACanvasGraphView),
    );

    await tester.tap(transitionAction);
    await tester.pump();

    expect(
      tester.widget<PDACanvasGraphView>(find.byType(PDACanvasGraphView)),
      same(originalCanvas),
    );

    expect(
      tester
          .widget<MobileAutomatonControls>(
            find.byType(MobileAutomatonControls),
          )
          .activeTool,
      AutomatonCanvasTool.transition,
    );

    await tester.tap(transitionAction);
    await tester.pump();

    expect(
      tester
          .widget<MobileAutomatonControls>(
            find.byType(MobileAutomatonControls),
          )
          .activeTool,
      AutomatonCanvasTool.selection,
    );
  });

  testWidgets('PDA desktop transition action toggles back to selection', (
    tester,
  ) async {
    await _pumpPdaPage(tester, size: const Size(1200, 900));
    final canvas = tester.widget<PDACanvasGraphView>(
      find.byType(PDACanvasGraphView),
    );
    expect(canvas.currentStack, isNotNull);
    expect(canvas.currentStack!.symbols, isEmpty);
    final transitionAction = find.bySemanticsLabel(
      'Canvas action: Add transition',
    );

    await tester.tap(transitionAction);
    await tester.pump();

    expect(
      tester
          .widget<GraphViewCanvasToolbar>(
            find.byType(GraphViewCanvasToolbar),
          )
          .activeTool,
      AutomatonCanvasTool.transition,
    );

    await tester.tap(transitionAction);
    await tester.pump();

    expect(
      tester
          .widget<GraphViewCanvasToolbar>(
            find.byType(GraphViewCanvasToolbar),
          )
          .activeTool,
      AutomatonCanvasTool.selection,
    );
  });

  testWidgets('PDA desktop Clear resets stack and remains undoable', (
    tester,
  ) async {
    await _pumpPdaPage(tester, size: const Size(1500, 900));
    var canvas = tester.widget<PDACanvasGraphView>(
      find.byType(PDACanvasGraphView),
    );
    final controller = canvas.controller!;
    controller.addStateAt(const Offset(120, 120));
    await tester.pump();

    final simulationPanel = tester.widget<PDASimulationPanel>(
      find.byType(PDASimulationPanel),
    );
    simulationPanel.onStackChanged!(
      const StackState(symbols: ['Z', 'A']),
    );
    await tester.pump();
    canvas = tester.widget<PDACanvasGraphView>(
      find.byType(PDACanvasGraphView),
    );
    expect(canvas.currentStack!.symbols, ['Z', 'A']);

    await tester.tap(
      find.bySemanticsLabel('Canvas action: Clear canvas'),
    );
    await tester.pump();

    canvas = tester.widget<PDACanvasGraphView>(
      find.byType(PDACanvasGraphView),
    );
    expect(canvas.currentStack!.symbols, isEmpty);
    expect(controller.nodes, isEmpty);
    expect(controller.canUndo, isTrue);
    expect(controller.undo(), isTrue);
    await tester.pump();
    expect(controller.nodes, hasLength(1));
  });
}
