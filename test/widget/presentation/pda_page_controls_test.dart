import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turing_lab/core/models/simulation_step.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/pages/pda_page.dart';
import 'package:turing_lab/presentation/providers/pda_editor_provider.dart';
import 'package:turing_lab/presentation/providers/pda_simulation_provider.dart';
import 'package:turing_lab/presentation/providers/unified_trace_provider.dart';
import 'package:turing_lab/presentation/widgets/automaton_canvas_tool.dart';
import 'package:turing_lab/presentation/providers/workspace_quick_actions_provider.dart';
import 'package:turing_lab/presentation/widgets/workspace_quick_actions_bar.dart';
import 'package:turing_lab/presentation/widgets/canvas_simulation_playback_bar.dart';
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
  TargetPlatform platform = TargetPlatform.android,
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
      child: MaterialApp(
        theme: ThemeData(platform: platform),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          appBar: AppBar(
            leading: const WorkspaceQuickActionsBar(tab: WorkspaceTab.pda),
            leadingWidth: 144,
          ),
          body: const PDAPage(),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  testWidgets('PDA iOS canvas playback updates stack and highlights', (
    tester,
  ) async {
    await _pumpPdaPage(
      tester,
      size: const Size(800, 900),
      platform: TargetPlatform.iOS,
    );
    final canvas = tester.widget<PDACanvasGraphView>(
      find.byType(PDACanvasGraphView),
    );
    final controller = canvas.controller!;
    controller.addStateAt(const Offset(140, 180));
    controller.addStateAt(const Offset(340, 180));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Simulate'));
    await tester.pumpAndSettle();
    final panel = tester.widget<PDASimulationPanel>(
      find.byType(PDASimulationPanel),
    );
    expect(panel.onViewOnCanvas, isNotNull);
    final stateIds = controller.nodes.map((node) => node.id).toList();
    panel.onViewOnCanvas!(
      [
        SimulationStep(
          currentState: stateIds[0],
          activeStateIds: {stateIds[0]},
          remainingInput: 'a',
          stackContents: 'Z',
          stepNumber: 0,
        ),
        SimulationStep(
          currentState: stateIds[1],
          activeStateIds: {stateIds[1]},
          remainingInput: '',
          stackContents: 'AZ',
          stepNumber: 1,
        ),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.byType(PDASimulationPanel), findsNothing);
    expect(find.byType(CanvasSimulationPlaybackBar), findsOneWidget);
    expect(
      tester
          .widget<PDAStackPanel>(find.byType(PDAStackPanel))
          .stackState
          .symbols,
      ['Z'],
    );

    await tester.tap(
      find.descendant(
        of: find.byType(CanvasSimulationPlaybackBar),
        matching: find.byTooltip('Next Step'),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<PDAStackPanel>(find.byType(PDAStackPanel))
          .stackState
          .symbols,
      ['A', 'Z'],
    );
    expect(controller.highlightNotifier.value.stateIds, {stateIds[1]});

    await tester.tap(
      find.descendant(
        of: find.byType(CanvasSimulationPlaybackBar),
        matching: find.byTooltip('Close'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CanvasSimulationPlaybackBar), findsNothing);
    expect(controller.highlightNotifier.value.isEmpty, isTrue);
  });

  testWidgets('PDA replacement clears canvas playback and projected stack', (
    tester,
  ) async {
    await _pumpPdaPage(
      tester,
      size: const Size(800, 900),
      platform: TargetPlatform.iOS,
    );
    final canvas = tester.widget<PDACanvasGraphView>(
      find.byType(PDACanvasGraphView),
    );
    final controller = canvas.controller!;
    controller.addStateAt(const Offset(140, 180));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(PDACanvasGraphView)),
    );
    final pda = container.read(pdaEditorProvider).pda!;
    final stateId = pda.states.single.id;
    final steps = [
      SimulationStep(
        currentState: stateId,
        activeStateIds: {stateId},
        remainingInput: '',
        stackContents: 'AZ',
        stepNumber: 0,
      ),
    ];

    await tester.tap(find.byTooltip('Simulate'));
    await tester.pumpAndSettle();
    tester
        .widget<PDASimulationPanel>(find.byType(PDASimulationPanel))
        .onViewOnCanvas!(steps);
    await tester.pumpAndSettle();
    container.read(pdaSimulationProvider.notifier)
      ..setPda(pda)
      ..setResult(
        PDASimulationResult.success(
          inputString: '',
          steps: steps,
          executionTime: Duration.zero,
        ),
      );

    container.read(pdaEditorProvider.notifier).setPda(
          pda.copyWith(id: 'replacement-pda'),
        );
    await tester.pumpAndSettle();

    expect(find.byType(CanvasSimulationPlaybackBar), findsNothing);
    expect(
      tester
          .widget<PDAStackPanel>(find.byType(PDAStackPanel))
          .stackState
          .symbols,
      isEmpty,
    );
    expect(container.read(pdaSimulationProvider).result, isNull);
    expect(controller.highlightNotifier.value.isEmpty, isTrue);
  });

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

    // Tapping the panel body (outside interactive children) collapses it.
    await tester.tapAt(
      tester.getTopLeft(find.byType(CollapsibleCanvasPanel)) +
          const Offset(4, 4),
    );
    await tester.pump();

    expect(find.byType(PDAStackPanel), findsNothing);
    expect(
      tester.getSize(find.byType(CollapsibleCanvasPanel)),
      const Size.square(48),
    );
    await tester.tap(find.byTooltip('Fit to content'));
    await tester.pump();
  });

  testWidgets('PDA mobile moves expanded and collapsed stack inspector', (
    tester,
  ) async {
    await _pumpPdaPage(tester, size: const Size(800, 900));
    final canvas = tester.widget<PDACanvasGraphView>(
      find.byType(PDACanvasGraphView),
    );
    canvas.controller!.addStateAt(const Offset(120, 120));
    await tester.pumpAndSettle();

    final panel = find.byType(CollapsibleCanvasPanel);
    final expandedStart = tester.getTopLeft(panel);
    await tester.drag(panel, const Offset(-96, 112), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(panel), isNot(expandedStart));

    // Tapping the expanded panel body collapses it to the toggle button.
    await tester.tapAt(tester.getTopLeft(panel) + const Offset(4, 4));
    await tester.pumpAndSettle();
    expect(tester.getSize(panel), const Size.square(48));

    final collapsedStart = tester.getTopLeft(panel);
    await tester.drag(
      find.byTooltip('Expand Stack panel'),
      const Offset(-48, 56),
    );
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(panel), isNot(collapsedStart));
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

  testWidgets(
      'empty PDA mobile keeps help reachable and disables quick actions', (
    tester,
  ) async {
    await _pumpPdaPage(tester, size: const Size(800, 900));

    final trayHelp = find.descendant(
      of: find.byType(MobileAutomatonControls),
      matching: find.byTooltip('Help'),
    );
    expect(trayHelp, findsOneWidget);
    // With no machine loaded the quick actions stay visible but disabled,
    // and the stack inspector is still available.
    for (final tooltip in const ['Simulate', 'Algorithms']) {
      final button = tester.widget<IconButton>(
        find.ancestor(
          of: find.byTooltip(tooltip),
          matching: find.byType(IconButton),
        ),
      );
      expect(button.onPressed, isNull, reason: '$tooltip should be disabled');
    }
    expect(find.byType(PDAStackPanel), findsOneWidget);

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
