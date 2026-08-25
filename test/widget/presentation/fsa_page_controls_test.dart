import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:turing_lab/core/constants/help_topic_ids.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/production.dart';
import 'package:turing_lab/core/models/simulation_step.dart';
import 'package:turing_lab/core/models/state.dart' as automaton_state;
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/l10n/app_localizations_en.dart';
import 'package:turing_lab/l10n/app_localizations_workflows.dart';
import 'package:turing_lab/injection/data_providers.dart';
import 'package:turing_lab/presentation/pages/fsa_page.dart';
import 'package:turing_lab/presentation/pages/help_page.dart';
import 'package:turing_lab/presentation/providers/automaton_state_provider.dart';
import 'package:turing_lab/presentation/providers/grammar_provider.dart';
import 'package:turing_lab/presentation/providers/home_navigation_provider.dart';
import 'package:turing_lab/presentation/providers/regex_editor_provider.dart';
import 'package:turing_lab/presentation/widgets/algorithm_panel.dart';
import 'package:turing_lab/presentation/widgets/algorithm_step_navigator.dart';
import 'package:turing_lab/presentation/widgets/automaton_graphview_canvas.dart';
import 'package:turing_lab/presentation/widgets/automaton_workspace_scaffold.dart';
import 'package:turing_lab/presentation/widgets/canvas_simulation_playback_bar.dart';
import 'package:turing_lab/presentation/widgets/fsa/determinism_badge.dart';
import 'package:turing_lab/presentation/widgets/graphview_canvas_toolbar.dart';
import 'package:turing_lab/presentation/widgets/simulation_panel.dart';
import 'package:turing_lab/presentation/providers/workspace_quick_actions_provider.dart';
import 'package:turing_lab/presentation/widgets/workspace_dock.dart';
import 'package:turing_lab/presentation/widgets/workspace_quick_actions_bar.dart';

import '../../support/workspace_dock_helpers.dart';
import 'canvas_toolbar_test_helpers.dart';
import 'examples_test_helpers.dart';

Future<void> _pumpFsaPage(
  WidgetTester tester, {
  required Size viewSize,
  double? paneWidth,
  TargetPlatform platform = TargetPlatform.android,
}) async {
  tester.view.physicalSize = viewSize;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();

  final page = paneWidth == null
      ? const FSAPage()
      : Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: paneWidth, child: const FSAPage()),
        );

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
            leading: const WorkspaceQuickActionsBar(tab: WorkspaceTab.fsa),
            leadingWidth: 144,
          ),
          body: page,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

FSA _singleStateFsa() {
  final state = automaton_state.State(
    id: 'q0',
    label: 'q0',
    position: Vector2(120, 120),
    isInitial: true,
    isAccepting: true,
  );
  return FSA(
    id: 'single-state-fsa',
    name: 'Single state FSA',
    states: {state},
    transitions: const {},
    alphabet: const {'a'},
    initialState: state,
    acceptingStates: {state},
    created: DateTime(2026),
    modified: DateTime(2026),
    bounds: const math.Rectangle(0, 0, 400, 300),
  );
}

Grammar _loadedGrammar() {
  const production = Production(
    id: 'loaded-production',
    leftSide: ['S'],
    rightSide: ['b'],
  );
  return Grammar(
    id: 'loaded-grammar',
    name: 'Loaded grammar',
    terminals: const {'b'},
    nonterminals: const {'S'},
    startSymbol: 'S',
    productions: {production},
    type: GrammarType.regular,
    created: DateTime(2026),
    modified: DateTime(2026),
  );
}

void main() {
  testWidgets('FSA to Grammar transfers the result and switches workspace', (
    tester,
  ) async {
    await _pumpFsaPage(tester, viewSize: const Size(430, 900));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(FSAPage)),
      listen: false,
    );
    container
        .read(automatonStateProvider.notifier)
        .updateAutomaton(_singleStateFsa());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Algorithms'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('FSA to Grammar'));
    await tester.tap(find.text('FSA to Grammar'));
    await tester.pumpAndSettle();

    expect(container.read(grammarProvider).productions, isNotEmpty);
    expect(
      container.read(homeNavigationProvider),
      HomeNavigationNotifier.grammarIndex,
    );
    expect(find.byType(AlgorithmPanel), findsNothing);
  });

  testWidgets('FA to Regex transfers the result and switches workspace', (
    tester,
  ) async {
    await _pumpFsaPage(tester, viewSize: const Size(430, 900));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(FSAPage)),
      listen: false,
    );
    container
        .read(automatonStateProvider.notifier)
        .updateAutomaton(_singleStateFsa());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Algorithms'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('FA to Regex'));
    await tester.tap(find.text('FA to Regex'));
    await tester.pumpAndSettle();

    expect(container.read(regexEditorProvider).currentRegex, isNotEmpty);
    expect(
      container.read(homeNavigationProvider),
      HomeNavigationNotifier.regexIndex,
    );
    expect(find.byType(AlgorithmPanel), findsNothing);
  });

  testWidgets('FSA to Grammar cancel preserves the loaded grammar', (
    tester,
  ) async {
    await _pumpFsaPage(tester, viewSize: const Size(430, 900));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(FSAPage)),
      listen: false,
    );
    final loadedGrammar = _loadedGrammar();
    container
        .read(automatonStateProvider.notifier)
        .updateAutomaton(_singleStateFsa());
    container.read(grammarProvider.notifier).applyGrammar(loadedGrammar);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Algorithms'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('FSA to Grammar'));
    await tester.tap(find.text('FSA to Grammar'));
    await tester.pumpAndSettle();

    expect(
      find.text('A grammar is already loaded. Do you want to replace it?'),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(
        container.read(grammarProvider).productions, loadedGrammar.productions);
    expect(
      container.read(homeNavigationProvider),
      HomeNavigationNotifier.fsaIndex,
    );
    expect(find.byType(AlgorithmPanel), findsOneWidget);
  });

  testWidgets('FA to Regex cancel preserves the loaded regex', (
    tester,
  ) async {
    await _pumpFsaPage(tester, viewSize: const Size(430, 900));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(FSAPage)),
      listen: false,
    );
    container
        .read(automatonStateProvider.notifier)
        .updateAutomaton(_singleStateFsa());
    container.read(regexEditorProvider.notifier).validateRegex('b');
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Algorithms'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('FA to Regex'));
    await tester.tap(find.text('FA to Regex'));
    await tester.pumpAndSettle();

    expect(
      find.text('A regex is already loaded. Do you want to replace it?'),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(container.read(regexEditorProvider).currentRegex, 'b');
    expect(
      container.read(homeNavigationProvider),
      HomeNavigationNotifier.fsaIndex,
    );
    expect(find.byType(AlgorithmPanel), findsOneWidget);
  });

  testWidgets('empty FSA exposes five presets through Algorithms', (
    tester,
  ) async {
    await _pumpFsaPage(tester, viewSize: const Size(430, 900));

    final algorithms = find.descendant(
      of: find.byType(AppBar),
      matching: find.byTooltip('Algorithms'),
    );
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

    await tester.tap(algorithms);
    await tester.pumpAndSettle();
    final exampleL10n = AppLocalizationsEn();
    await pumpUntilFound(
      tester,
      find.text(exampleL10n.localizedExampleName('AFD - Termina com A')),
    );

    for (final example in const [
      'AFD - Termina com A',
      'AFD - Binário divisível por 3',
      'AFD - Paridade AB',
      'AFD - Contém AB',
      'AFNλ - A ou AB',
    ]) {
      expect(
        find.text(exampleL10n.localizedExampleName(example)),
        findsOneWidget,
      );
    }

    await tester.tap(
      find.text(exampleL10n.localizedExampleName('AFD - Contém AB')),
    );
    await pumpUntilFound(tester, find.textContaining('Example loaded:'));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(AutomatonGraphViewCanvas)),
    );
    expect(
      container.read(automatonStateProvider).currentAutomaton?.name,
      'AFD - Contém AB',
    );
  });

  testWidgets('FSA iOS canvas playback closes the sheet and highlights steps', (
    tester,
  ) async {
    await _pumpFsaPage(
      tester,
      viewSize: const Size(800, 900),
      platform: TargetPlatform.iOS,
    );
    final canvas = tester.widget<AutomatonGraphViewCanvas>(
      find.byType(AutomatonGraphViewCanvas),
    );
    final controller = canvas.controller!;
    controller.addStateAt(const Offset(140, 180));
    controller.addStateAt(const Offset(340, 180));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Simulate'));
    await tester.pumpAndSettle();
    final panel = tester.widget<SimulationPanel>(find.byType(SimulationPanel));
    expect(panel.onViewOnCanvas, isNotNull);
    final stateIds = controller.nodes.map((node) => node.id).toList();
    panel.onViewOnCanvas!(
      [
        SimulationStep(
          currentState: stateIds[0],
          activeStateIds: {stateIds[0]},
          remainingInput: 'a',
          stepNumber: 0,
        ),
        SimulationStep(
          currentState: stateIds[1],
          activeStateIds: {stateIds[1]},
          remainingInput: '',
          stepNumber: 1,
        ),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.byType(SimulationPanel), findsNothing);
    expect(find.byType(CanvasSimulationPlaybackBar), findsOneWidget);
    final playbackRect = tester.getRect(
      find.byType(CanvasSimulationPlaybackBar),
    );
    final toolbarRect = tester.getRect(
      find.byKey(const ValueKey('canvas-toolbar-surface')),
    );
    expect(playbackRect.bottom, lessThanOrEqualTo(toolbarRect.top));
    expect(controller.highlightNotifier.value.stateIds, {stateIds[0]});

    await tester.tap(
      find.descendant(
        of: find.byType(CanvasSimulationPlaybackBar),
        matching: find.byTooltip('Next Step'),
      ),
    );
    await tester.pumpAndSettle();
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

  testWidgets('FSA uses one shared toolbar across canvas breakpoints', (
    tester,
  ) async {
    await _pumpFsaPage(tester, viewSize: const Size(390, 900));

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
        reason: 'unexpected FSA toolbar placement at ${width.toInt()}px',
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('FSA clear canvas stops an active canvas playback', (
    tester,
  ) async {
    await _pumpFsaPage(
      tester,
      viewSize: const Size(800, 900),
      platform: TargetPlatform.iOS,
    );
    final canvas = tester.widget<AutomatonGraphViewCanvas>(
      find.byType(AutomatonGraphViewCanvas),
    );
    final controller = canvas.controller!;
    controller.addStateAt(const Offset(140, 180));
    controller.addStateAt(const Offset(340, 180));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Simulate'));
    await tester.pumpAndSettle();
    final panel = tester.widget<SimulationPanel>(find.byType(SimulationPanel));
    final stateIds = controller.nodes.map((node) => node.id).toList();
    panel.onViewOnCanvas!(
      [
        SimulationStep(
          currentState: stateIds[0],
          activeStateIds: {stateIds[0]},
          remainingInput: 'a',
          stepNumber: 0,
        ),
      ],
    );
    await tester.pumpAndSettle();
    expect(find.byType(CanvasSimulationPlaybackBar), findsOneWidget);

    await expandCanvasToolbar(tester);
    await tapSecondaryCanvasAction(
      tester,
      semanticLabel: 'Canvas action: Clear canvas',
      menuLabel: 'Clear canvas',
      opensRoute: false,
    );

    expect(find.byType(CanvasSimulationPlaybackBar), findsNothing);
    expect(controller.highlightNotifier.value.isEmpty, isTrue);
    expect(controller.nodes, isEmpty);
  });

  testWidgets('FSA Android compact canvas playback callback is absent', (
    tester,
  ) async {
    await _pumpFsaPage(tester, viewSize: const Size(800, 900));
    final canvas = tester.widget<AutomatonGraphViewCanvas>(
      find.byType(AutomatonGraphViewCanvas),
    );
    canvas.controller!.addStateAt(const Offset(140, 180));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Simulate'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<SimulationPanel>(find.byType(SimulationPanel))
          .onViewOnCanvas,
      isNull,
    );
  });

  testWidgets('FSA canvas playback stops when iOS leaves compact layout', (
    tester,
  ) async {
    await _pumpFsaPage(
      tester,
      viewSize: const Size(800, 900),
      platform: TargetPlatform.iOS,
    );
    final canvas = tester.widget<AutomatonGraphViewCanvas>(
      find.byType(AutomatonGraphViewCanvas),
    );
    final controller = canvas.controller!;
    controller.addStateAt(const Offset(140, 180));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Simulate'));
    await tester.pumpAndSettle();
    final stateId = controller.nodes.single.id;
    tester
        .widget<SimulationPanel>(find.byType(SimulationPanel))
        .onViewOnCanvas!(
      [
        SimulationStep(
          currentState: stateId,
          activeStateIds: {stateId},
          remainingInput: '',
          stepNumber: 0,
        ),
      ],
    );
    await tester.pumpAndSettle();
    expect(find.byType(CanvasSimulationPlaybackBar), findsOneWidget);

    tester.view.physicalSize = const Size(1200, 900);
    await tester.pumpAndSettle();
    expect(find.byType(CanvasSimulationPlaybackBar), findsNothing);
    expect(controller.highlightNotifier.value.isEmpty, isTrue);

    tester.view.physicalSize = const Size(800, 900);
    await tester.pumpAndSettle();
    expect(find.byType(CanvasSimulationPlaybackBar), findsNothing);
  });

  testWidgets('FSAPage follows pane constraints in a wide window', (
    tester,
  ) async {
    await _pumpFsaPage(
      tester,
      viewSize: const Size(1600, 900),
      paneWidth: 800,
    );

    expect(find.byType(AutomatonWorkspaceScaffold), findsOneWidget);
    expect(find.byType(GraphViewCanvasToolbar), findsOneWidget);
    expect(find.byType(AlgorithmPanel), findsNothing);
    expect(find.byType(FSADeterminismOverlay), findsOneWidget);
    expect(find.byType(AlgorithmStepNavigator), findsOneWidget);
  });

  testWidgets(
      'FSAPage uses mobile determinism overlay geometry in a narrow pane', (
    tester,
  ) async {
    await _pumpFsaPage(
      tester,
      viewSize: const Size(1600, 900),
      paneWidth: 800,
    );
    final canvasFinder = find.byType(AutomatonGraphViewCanvas);
    final canvas = tester.widget<AutomatonGraphViewCanvas>(canvasFinder);
    canvas.controller!.addStateAt(const Offset(140, 180));
    await tester.pumpAndSettle();

    final canvasRect = tester.getRect(canvasFinder);
    final badgeFinder = find.byType(FsaTypeBadge);
    expect(tester.getTopLeft(badgeFinder).dy, canvasRect.top + 60);

    await tester.tap(badgeFinder);
    await tester.pumpAndSettle();

    final panelRect = tester.getRect(find.byType(NonDeterminismPanel));
    expect(panelRect.top, canvasRect.top + 100);
    expect(panelRect.left, canvasRect.left + 16);
  });

  testWidgets('FSAPage desktop uses shared canvas simulation algorithm order', (
    tester,
  ) async {
    await _pumpFsaPage(tester, viewSize: const Size(1600, 900));

    // The canvas owns the pane by default; the panels are one rail tap away
    // and open beside it, simulation before algorithms.
    expect(find.byType(SimulationPanel), findsNothing);
    expect(find.byType(AlgorithmPanel), findsNothing);

    final simulationRailY = tester
        .getTopLeft(
          find.byKey(
            WorkspaceDock.railButtonKey(
              AutomatonWorkspaceScaffold.simulationPanelId,
            ),
          ),
        )
        .dy;
    final algorithmRailY = tester
        .getTopLeft(
          find.byKey(
            WorkspaceDock.railButtonKey(
              AutomatonWorkspaceScaffold.algorithmPanelId,
            ),
          ),
        )
        .dy;
    expect(simulationRailY, lessThan(algorithmRailY));

    await openWorkspaceSimulationPanel(tester);
    final canvasX = tester.getTopLeft(find.byType(AutomatonGraphViewCanvas)).dx;
    final simulationX = tester.getTopLeft(find.byType(SimulationPanel)).dx;
    expect(canvasX, lessThan(simulationX));

    await openWorkspaceAlgorithmsPanel(tester);
    expect(find.byType(SimulationPanel), findsNothing);
    expect(
      tester.getTopLeft(find.byType(AlgorithmPanel)).dx,
      greaterThan(canvasX),
    );

    expect(find.byType(FSADeterminismOverlay), findsOneWidget);
    expect(find.byType(AlgorithmStepNavigator), findsOneWidget);
  });

  testWidgets('FSAPage desktop places the determinism badge below the toolbar',
      (
    tester,
  ) async {
    await _pumpFsaPage(tester, viewSize: const Size(1600, 900));
    final canvas = tester.widget<AutomatonGraphViewCanvas>(
      find.byType(AutomatonGraphViewCanvas),
    );
    canvas.controller!.addStateAt(const Offset(140, 180));
    await tester.pumpAndSettle();

    final badgeRect = tester.getRect(find.byType(FsaTypeBadge));
    final toolbarRect = tester.getRect(
      find.byKey(const ValueKey('canvas-toolbar-surface')),
    );
    expect(badgeRect.top, greaterThanOrEqualTo(toolbarRect.bottom + 8));
  });

  testWidgets('FSA Help maps empty, DFA, epsilon, and NFA contexts', (
    tester,
  ) async {
    await _pumpFsaPage(tester, viewSize: const Size(1600, 900));
    await expandCanvasToolbar(tester);

    Future<void> expectHelpTopic(String topicId) async {
      await tapSecondaryCanvasAction(
        tester,
        semanticLabel: 'Canvas action: Help & Shortcuts',
        menuLabel: 'Help & Shortcuts',
        opensRoute: true,
      );
      await tester.pumpAndSettle();
      final page = tester.widget<HelpPage>(find.byType(HelpPage));
      final node = find.byKey(ValueKey('help-node-$topicId'));
      expect(page.initialTopicId, topicId);
      expect(node, findsOneWidget);
      expect(tester.widget<InkWell>(node).focusNode?.hasFocus, isTrue);
      expect(find.byKey(ValueKey('help-body-$topicId')), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
    }

    await expectHelpTopic(HelpTopicIds.fsaEditorOverview);

    final canvas = tester.widget<AutomatonGraphViewCanvas>(
      find.byType(AutomatonGraphViewCanvas),
    );
    canvas.controller!
      ..addStateAt(const Offset(120, 160))
      ..addStateAt(const Offset(320, 160))
      ..addStateAt(const Offset(520, 160));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(AutomatonGraphViewCanvas)),
    );
    final notifier = container.read(automatonStateProvider.notifier);
    var automaton = container.read(automatonStateProvider).currentAutomaton!;
    final states = automaton.states.toList(growable: false);

    await expectHelpTopic(HelpTopicIds.fsaTheoryDfa);
    expect(
      find.descendant(
        of: find.byType(FsaTypeBadge),
        matching: find.byIcon(Icons.info_outline),
      ),
      findsOneWidget,
    );

    automaton = automaton.copyWith(
      transitions: {
        FSATransition(
          id: 'epsilon',
          fromState: states[0],
          toState: states[1],
          lambdaSymbol: 'ε',
        ),
      },
    );
    notifier.updateAutomaton(automaton);
    await tester.pumpAndSettle();
    await expectHelpTopic(HelpTopicIds.fsaTheoryEpsilon);

    automaton = automaton.copyWith(
      alphabet: {'a'},
      transitions: {
        FSATransition(
          id: 'nfa-1',
          fromState: states[0],
          toState: states[1],
          inputSymbols: {'a'},
        ),
        FSATransition(
          id: 'nfa-2',
          fromState: states[0],
          toState: states[2],
          inputSymbols: {'a'},
        ),
      },
    );
    notifier.updateAutomaton(automaton);
    await tester.pumpAndSettle();
    await expectHelpTopic(HelpTopicIds.fsaTheoryNfa);
  });

  testWidgets('FSAPage mobile Clear remains undoable', (tester) async {
    await _pumpFsaPage(tester, viewSize: const Size(800, 900));
    final canvas = tester.widget<AutomatonGraphViewCanvas>(
      find.byType(AutomatonGraphViewCanvas),
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

    expect(controller.nodes, isEmpty);
    expect(controller.canUndo, isTrue);
    expect(controller.undo(), isTrue);
    await tester.pumpAndSettle();
    expect(controller.nodes, hasLength(1));
  });
}
