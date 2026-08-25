import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turing_lab/core/constants/help_topic_ids.dart';
import 'package:turing_lab/core/models/simulation_step.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/l10n/app_localizations_en.dart';
import 'package:turing_lab/l10n/app_localizations_workflows.dart';
import 'package:turing_lab/injection/data_providers.dart';
import 'package:turing_lab/presentation/pages/help_page.dart';
import 'package:turing_lab/presentation/pages/pda_page.dart';
import 'package:turing_lab/presentation/providers/pda_editor_provider.dart';
import 'package:turing_lab/presentation/providers/pda_simulation_provider.dart';
import 'package:turing_lab/presentation/widgets/automaton_canvas_tool.dart';
import 'package:turing_lab/presentation/widgets/automaton_workspace_scaffold.dart';
import 'package:turing_lab/presentation/providers/workspace_quick_actions_provider.dart';
import 'package:turing_lab/presentation/widgets/workspace_quick_actions_bar.dart';
import 'package:turing_lab/presentation/widgets/canvas_simulation_playback_bar.dart';
import 'package:turing_lab/presentation/widgets/collapsible_canvas_panel.dart';
import 'package:turing_lab/presentation/widgets/common/algorithm_button.dart';
import 'package:turing_lab/presentation/widgets/graphview_canvas_toolbar.dart';
import 'package:turing_lab/presentation/widgets/pda_canvas_graphview.dart';
import 'package:turing_lab/presentation/widgets/pda_simulation_panel.dart';
import 'package:turing_lab/presentation/widgets/pda/stack_drawer.dart';

import '../../support/workspace_dock_helpers.dart';

import 'canvas_toolbar_test_helpers.dart';
import 'examples_test_helpers.dart';

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
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        examplesRepositoryProvider.overrideWithValue(TestExamplesRepository()),
      ],
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
    final playbackRect = tester.getRect(
      find.byType(CanvasSimulationPlaybackBar),
    );
    final toolbarRect = tester.getRect(
      find.byKey(const ValueKey('canvas-toolbar-surface')),
    );
    expect(playbackRect.bottom, lessThanOrEqualTo(toolbarRect.top));
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

  testWidgets('PDA uses one shared toolbar across canvas breakpoints', (
    tester,
  ) async {
    await _pumpPdaPage(tester, size: const Size(390, 900));

    for (final width in const [390.0, 430.0, 800.0, 1200.0]) {
      tester.view.physicalSize = Size(width, 900);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(GraphViewCanvasToolbar), findsOneWidget);
      final toolbar = tester.widget<GraphViewCanvasToolbar>(
        find.byType(GraphViewCanvasToolbar),
      );
      expect(
        toolbar.placement,
        width < AutomatonWorkspaceScaffold.mobileBreakpoint
            ? CanvasToolbarPlacement.bottomCenter
            : CanvasToolbarPlacement.topRight,
        reason: 'unexpected PDA toolbar placement at ${width.toInt()}px',
      );
      expect(tester.takeException(), isNull);
    }
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
    await expandCanvasToolbar(tester);
    await tapSecondaryCanvasAction(
      tester,
      semanticLabel: 'Canvas action: Fit to content',
      menuLabel: 'Fit to content',
      opensRoute: false,
    );
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
      'empty PDA keeps Algorithms presets reachable and other actions disabled',
      (
    tester,
  ) async {
    await _pumpPdaPage(tester, size: const Size(800, 900));

    await expandCanvasToolbar(tester);
    final simulateButton = tester.widget<IconButton>(
      find.ancestor(
        of: find.byTooltip('Simulate'),
        matching: find.byType(IconButton),
      ),
    );
    expect(simulateButton.onPressed, isNull);
    final algorithms = find.byTooltip('Algorithms');
    expect(
      tester
          .widget<IconButton>(
            find.ancestor(
              of: algorithms,
              matching: find.byType(IconButton),
            ),
          )
          .onPressed,
      isNotNull,
    );
    expect(find.byType(PDAStackPanel), findsOneWidget);

    await tester.tap(algorithms);
    await tester.pumpAndSettle();
    // The examples keep their canonical names; the sheet shows them through
    // the active locale, which is English here.
    final exampleL10n = AppLocalizationsEn();
    await pumpUntilFound(
      tester,
      find.text(
          exampleL10n.localizedExampleName('APD - Parênteses Balanceados')),
    );
    for (final example in const [
      'APD - Parênteses Balanceados',
      'APD - a^n b^n',
      'APD - Palíndromo',
      'APD - a^n b^2n',
      'APD - w#reverse(w)',
    ]) {
      expect(
        find.text(exampleL10n.localizedExampleName(example)),
        findsOneWidget,
      );
    }
    Navigator.of(tester.element(find.byType(BottomSheet))).pop();
    await tester.pumpAndSettle();

    await tapSecondaryCanvasAction(
      tester,
      semanticLabel: 'Canvas action: Help & Shortcuts',
      menuLabel: 'Help & Shortcuts',
      opensRoute: true,
    );

    final page = tester.widget<HelpPage>(find.byType(HelpPage));
    final node = find.byKey(
      const ValueKey('help-node-${HelpTopicIds.pdaEditorOverview}'),
    );
    expect(page.initialTopicId, HelpTopicIds.pdaEditorOverview);
    expect(tester.widget<InkWell>(node).focusNode?.hasFocus, isTrue);
    expect(
      find.byKey(
        const ValueKey('help-body-${HelpTopicIds.pdaEditorOverview}'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('populated PDA Help maps theory and active stack workflow', (
    tester,
  ) async {
    await _pumpPdaPage(tester, size: const Size(800, 900));
    final canvas = tester.widget<PDACanvasGraphView>(
      find.byType(PDACanvasGraphView),
    );
    canvas.controller!.addStateAt(const Offset(140, 180));
    await tester.pumpAndSettle();

    await expandCanvasToolbar(tester);
    await tapSecondaryCanvasAction(
      tester,
      semanticLabel: 'Canvas action: Help & Shortcuts',
      menuLabel: 'Help & Shortcuts',
      opensRoute: true,
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<HelpPage>(find.byType(HelpPage)).initialTopicId,
      HelpTopicIds.pdaTheoryPda,
    );
    expect(
      find.byKey(
        const ValueKey('help-body-${HelpTopicIds.pdaTheoryPda}'),
      ),
      findsOneWidget,
    );

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Simulate'));
    await tester.pumpAndSettle();
    final simulation = tester.widget<PDASimulationPanel>(
      find.byType(PDASimulationPanel),
    );
    simulation.onStackChanged!(const StackState(symbols: ['Z']));
    await tester.pump();
    Navigator.of(tester.element(find.byType(PDASimulationPanel))).pop();
    await tester.pumpAndSettle();

    await tapSecondaryCanvasAction(
      tester,
      semanticLabel: 'Canvas action: Help & Shortcuts',
      menuLabel: 'Help & Shortcuts',
      opensRoute: true,
    );
    await tester.pumpAndSettle();
    final workflowNode = find.byKey(
      const ValueKey('help-node-${HelpTopicIds.pdaEditorSimulation}'),
    );
    expect(
      tester.widget<HelpPage>(find.byType(HelpPage)).initialTopicId,
      HelpTopicIds.pdaEditorSimulation,
    );
    expect(
      tester.widget<InkWell>(workflowNode).focusNode?.hasFocus,
      isTrue,
    );

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Algorithms'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    final determinismButton = tester.widget<AlgorithmButton>(
      find.ancestor(
        of: find.text('Check Determinism'),
        matching: find.byType(AlgorithmButton),
      ),
    );
    expect(determinismButton.icon, Icons.fact_check_outlined);
  });

  testWidgets('PDA mobile transition action toggles back to selection', (
    tester,
  ) async {
    await _pumpPdaPage(tester, size: const Size(800, 900));
    final transitionAction = find.bySemanticsLabel(
      'Canvas action: Add transition',
    );
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

    await openWorkspaceSimulationPanel(tester);
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

    await expandCanvasToolbar(tester);
    await tapSecondaryCanvasAction(
      tester,
      semanticLabel: 'Canvas action: Clear canvas',
      menuLabel: 'Clear canvas',
      opensRoute: false,
    );

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
