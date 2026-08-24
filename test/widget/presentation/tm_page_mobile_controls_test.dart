import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turing_lab/core/constants/help_topic_ids.dart';
import 'package:turing_lab/core/models/simulation_step.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/injection/data_providers.dart';
import 'package:turing_lab/presentation/pages/help_page.dart';
import 'package:turing_lab/presentation/pages/tm_page.dart';
import 'package:turing_lab/presentation/providers/tm_editor_provider.dart';
import 'package:turing_lab/presentation/providers/workspace_quick_actions_provider.dart';
import 'package:turing_lab/presentation/widgets/workspace_quick_actions_bar.dart';
import 'package:turing_lab/presentation/widgets/canvas_simulation_playback_bar.dart';
import 'package:turing_lab/presentation/widgets/collapsible_canvas_panel.dart';
import 'package:turing_lab/presentation/widgets/common/algorithm_button.dart';
import 'package:turing_lab/presentation/widgets/automaton_workspace_scaffold.dart';
import 'package:turing_lab/presentation/widgets/graphview_canvas_toolbar.dart';
import 'package:turing_lab/presentation/widgets/tm_canvas_graphview.dart';
import 'package:turing_lab/presentation/widgets/tm_simulation_panel.dart';
import 'package:turing_lab/presentation/widgets/tm/tape_drawer.dart';

import 'canvas_toolbar_test_helpers.dart';
import 'examples_test_helpers.dart';

Future<void> _pumpMobileTmPage(
  WidgetTester tester, {
  Size size = const Size(430, 932),
  TargetPlatform platform = TargetPlatform.android,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
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
            leading: const WorkspaceQuickActionsBar(tab: WorkspaceTab.tm),
            leadingWidth: 144,
          ),
          body: const TMPage(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('TM iOS canvas playback updates tape and head', (tester) async {
    await _pumpMobileTmPage(tester, platform: TargetPlatform.iOS);
    final canvas = tester.widget<TMCanvasGraphView>(
      find.byType(TMCanvasGraphView),
    );
    final controller = canvas.controller!;
    controller.addStateAt(const Offset(180, 300));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(TMCanvasGraphView)),
    );
    final stateId = container.read(tmEditorProvider).tm!.states.single.id;
    container.read(tmEditorProvider.notifier).updateStateFlags(
          id: stateId,
          isAccepting: true,
        );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Simulate'));
    await tester.pumpAndSettle();
    final panel = tester.widget<TMSimulationPanel>(
      find.byType(TMSimulationPanel),
    );
    expect(panel.onViewOnCanvas, isNotNull);
    panel.onViewOnCanvas!(
      [
        SimulationStep(
          currentState: stateId,
          activeStateIds: {stateId},
          remainingInput: '',
          tapeContents: '01',
          headPosition: 0,
          stepNumber: 0,
        ),
        SimulationStep(
          currentState: stateId,
          activeStateIds: {stateId},
          remainingInput: '',
          tapeContents: 'X1',
          headPosition: 1,
          stepNumber: 1,
        ),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.byType(TMSimulationPanel), findsNothing);
    expect(find.byType(CanvasSimulationPlaybackBar), findsOneWidget);
    final playbackRect = tester.getRect(
      find.byType(CanvasSimulationPlaybackBar),
    );
    final toolbarRect = tester.getRect(
      find.byKey(const ValueKey('canvas-toolbar-surface')),
    );
    expect(playbackRect.bottom, lessThanOrEqualTo(toolbarRect.top));
    expect(
      tester.widget<TMTapePanel>(find.byType(TMTapePanel)).tapeState.cells,
      ['0', '1'],
    );

    await tester.tap(
      find.descendant(
        of: find.byType(CanvasSimulationPlaybackBar),
        matching: find.byTooltip('Next Step'),
      ),
    );
    await tester.pumpAndSettle();
    final tape = tester.widget<TMTapePanel>(find.byType(TMTapePanel)).tapeState;
    expect(tape.cells, ['X', '1']);
    expect(tape.headPosition, 1);

    tester.view.physicalSize = const Size(1200, 932);
    await tester.pumpAndSettle();
    expect(find.byType(CanvasSimulationPlaybackBar), findsNothing);
    expect(controller.highlightNotifier.value.isEmpty, isTrue);

    tester.view.physicalSize = const Size(430, 932);
    await tester.pumpAndSettle();
    expect(find.byType(CanvasSimulationPlaybackBar), findsNothing);
  });

  testWidgets('TM uses one shared toolbar across canvas breakpoints', (
    tester,
  ) async {
    await _pumpMobileTmPage(tester, size: const Size(390, 900));

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
        reason: 'unexpected TM toolbar placement at ${width.toInt()}px',
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('TM mobile panels do not overlap editing controls', (
    tester,
  ) async {
    for (final size in const <Size>[Size(393, 852), Size(430, 932)]) {
      await _pumpMobileTmPage(tester, size: size);
      final canvas = tester.widget<TMCanvasGraphView>(
        find.byType(TMCanvasGraphView),
      );
      canvas.controller!.addStateAt(const Offset(180, 300));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Canvas action: Select'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Canvas action: Add transition'),
        findsOneWidget,
      );

      final appBarAlgorithms = find.descendant(
        of: find.byType(AppBar),
        matching: find.byTooltip('Algorithms'),
      );
      expect(appBarAlgorithms, findsOneWidget);
      final tape = tester.getRect(find.byType(CollapsibleCanvasPanel));
      final controlsSurface = find.byKey(
        const ValueKey('canvas-toolbar-surface'),
      );
      expect(controlsSurface, findsOneWidget);
      final controls = tester.getRect(controlsSurface);
      expect(tape.bottom, lessThanOrEqualTo(controls.top));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });

  testWidgets('TM mobile moves expanded and collapsed tape inspector', (
    tester,
  ) async {
    await _pumpMobileTmPage(tester);
    final canvas = tester.widget<TMCanvasGraphView>(
      find.byType(TMCanvasGraphView),
    );
    canvas.controller!.addStateAt(const Offset(180, 300));
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
      find.byTooltip('Expand tape panel'),
      const Offset(-48, 56),
    );
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(panel), isNot(collapsedStart));
  });

  testWidgets('empty TM keeps examples reachable and other actions disabled', (
    tester,
  ) async {
    await _pumpMobileTmPage(tester);

    await expandCanvasToolbar(tester);
    expect(
      find.byKey(const ValueKey('canvas-toolbar-overflow')),
      findsOneWidget,
    );
    // Content-dependent actions remain disabled, while Algorithms still opens
    // the examples that can create the first machine.
    for (final tooltip in const ['Simulate', 'Metrics']) {
      final button = tester.widget<IconButton>(
        find.ancestor(
          of: find.byTooltip(tooltip),
          matching: find.byType(IconButton),
        ),
      );
      expect(button.onPressed, isNull, reason: '$tooltip should be disabled');
    }
    final algorithms = tester.widget<IconButton>(
      find.ancestor(
        of: find.byTooltip('Algorithms'),
        matching: find.byType(IconButton),
      ),
    );
    expect(algorithms.onPressed, isNotNull);
    expect(find.byType(TMTapePanel), findsOneWidget);

    await tester.tap(find.byTooltip('Algorithms'));
    await tester.pumpAndSettle();
    await pumpUntilFound(tester, find.text('MT - a^n b^n'));
    for (final example in const [
      'MT - a^n b^n',
      'MT - Binário para unário',
      'MT - Cópia de string',
      'MT - Incremento binário',
      'MT - Verificador de palíndromo',
    ]) {
      expect(find.text(example), findsOneWidget);
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
      const ValueKey('help-node-${HelpTopicIds.tmEditorOverview}'),
    );
    expect(page.initialTopicId, HelpTopicIds.tmEditorOverview);
    expect(tester.widget<InkWell>(node).focusNode?.hasFocus, isTrue);
    expect(
      find.byKey(
        const ValueKey('help-body-${HelpTopicIds.tmEditorOverview}'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('populated TM Help opens theory and keeps decidability command', (
    tester,
  ) async {
    await _pumpMobileTmPage(tester);
    final canvas = tester.widget<TMCanvasGraphView>(
      find.byType(TMCanvasGraphView),
    );
    canvas.controller!.addStateAt(const Offset(180, 300));
    await tester.pumpAndSettle();

    await expandCanvasToolbar(tester);
    await tapSecondaryCanvasAction(
      tester,
      semanticLabel: 'Canvas action: Help & Shortcuts',
      menuLabel: 'Help & Shortcuts',
      opensRoute: true,
    );
    await tester.pumpAndSettle();

    final node = find.byKey(
      const ValueKey('help-node-${HelpTopicIds.tmTheoryTm}'),
    );
    expect(
      tester.widget<HelpPage>(find.byType(HelpPage)).initialTopicId,
      HelpTopicIds.tmTheoryTm,
    );
    expect(tester.widget<InkWell>(node).focusNode?.hasFocus, isTrue);
    expect(
      find.byKey(const ValueKey('help-body-${HelpTopicIds.tmTheoryTm}')),
      findsOneWidget,
    );

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Algorithms'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    final decidabilityButton = tester.widget<AlgorithmButton>(
      find.ancestor(
        of: find.text('Check Decidability'),
        matching: find.byType(AlgorithmButton),
      ),
    );
    expect(decidabilityButton.icon, Icons.fact_check_outlined);
  });

  testWidgets('TMPage mobile exposes and toggles transition mode', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var semanticsDisposed = false;
    addTearDown(() {
      if (!semanticsDisposed) {
        semantics.dispose();
        semanticsDisposed = true;
      }
    });
    await _pumpMobileTmPage(tester);

    final select = find.bySemanticsLabel('Canvas action: Select');
    final addTransition = find.bySemanticsLabel(
      'Canvas action: Add transition',
    );
    final originalCanvas = tester.widget<TMCanvasGraphView>(
      find.byType(TMCanvasGraphView),
    );

    expect(select, findsOneWidget);
    expect(addTransition, findsOneWidget);
    expect(
      tester
          .getSemantics(addTransition)
          .getSemanticsData()
          .flagsCollection
          .isToggled,
      Tristate.isFalse,
    );

    await tester.tap(addTransition);
    await tester.pump();

    expect(
      tester.widget<TMCanvasGraphView>(find.byType(TMCanvasGraphView)),
      same(originalCanvas),
    );

    expect(
      tester
          .getSemantics(addTransition)
          .getSemanticsData()
          .flagsCollection
          .isToggled,
      Tristate.isTrue,
    );

    await tester.tap(addTransition);
    await tester.pump();

    expect(
      tester.getSemantics(select).getSemanticsData().flagsCollection.isToggled,
      Tristate.isTrue,
    );

    semantics.dispose();
    semanticsDisposed = true;
  });

  testWidgets('TMPage mobile selects add-state mode when adding a state', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var semanticsDisposed = false;
    addTearDown(() {
      if (!semanticsDisposed) {
        semantics.dispose();
        semanticsDisposed = true;
      }
    });
    await _pumpMobileTmPage(tester);

    final addState = find.bySemanticsLabel('Canvas action: Add state');
    await tester.tap(addState);
    await tester.pump();

    expect(
      tester
          .getSemantics(addState)
          .getSemanticsData()
          .flagsCollection
          .isToggled,
      Tristate.isTrue,
    );

    semantics.dispose();
    semanticsDisposed = true;
  });

  testWidgets('TMPage mobile Clear resets tape and remains undoable', (
    tester,
  ) async {
    await _pumpMobileTmPage(tester);
    final canvas = tester.widget<TMCanvasGraphView>(
      find.byType(TMCanvasGraphView),
    );
    final controller = canvas.controller!;
    controller.addStateAt(const Offset(120, 120));
    await tester.pumpAndSettle();

    await expandCanvasToolbar(tester);
    await tapSecondaryCanvasAction(
      tester,
      semanticLabel: 'Canvas action: Clear canvas',
      menuLabel: 'Clear canvas',
      opensRoute: false,
    );

    final tapePanel = tester.widget<TMTapePanel>(find.byType(TMTapePanel));
    expect(tapePanel.tapeState.isEmpty, isTrue);
    expect(tapePanel.tapeState.blankSymbol, 'B');
    expect(controller.nodes, isEmpty);
    expect(controller.canUndo, isTrue);
    expect(controller.undo(), isTrue);
    await tester.pumpAndSettle();
    expect(controller.nodes, hasLength(1));
  });
}
