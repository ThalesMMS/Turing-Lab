import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turing_lab/core/models/simulation_step.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/pages/fsa_page.dart';
import 'package:turing_lab/presentation/providers/unified_trace_provider.dart';
import 'package:turing_lab/presentation/widgets/algorithm_panel.dart';
import 'package:turing_lab/presentation/widgets/algorithm_step_navigator.dart';
import 'package:turing_lab/presentation/widgets/automaton_graphview_canvas.dart';
import 'package:turing_lab/presentation/widgets/automaton_workspace_scaffold.dart';
import 'package:turing_lab/presentation/widgets/canvas_simulation_playback_bar.dart';
import 'package:turing_lab/presentation/widgets/context_aware_help_panel.dart';
import 'package:turing_lab/presentation/widgets/fsa/determinism_badge.dart';
import 'package:turing_lab/presentation/widgets/keyboard_shortcuts_dialog.dart';
import 'package:turing_lab/presentation/widgets/mobile_automaton_controls.dart';
import 'package:turing_lab/presentation/widgets/simulation_panel.dart';
import 'package:turing_lab/presentation/providers/workspace_quick_actions_provider.dart';
import 'package:turing_lab/presentation/widgets/workspace_quick_actions_bar.dart';

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
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
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

void main() {
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

    await tester.tap(find.byTooltip('Clear canvas'));
    await tester.pumpAndSettle();

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
    expect(find.byType(MobileAutomatonControls), findsOneWidget);
    expect(find.byType(AlgorithmPanel), findsNothing);
    expect(find.byType(FSADeterminismOverlay), findsOneWidget);
    expect(find.byType(AlgorithmStepNavigator), findsOneWidget);
  });

  testWidgets('FSAPage desktop uses shared canvas simulation algorithm order', (
    tester,
  ) async {
    await _pumpFsaPage(tester, viewSize: const Size(1600, 900));

    final canvasX = tester.getTopLeft(find.byType(AutomatonGraphViewCanvas)).dx;
    final simulationX = tester.getTopLeft(find.byType(SimulationPanel)).dx;
    final algorithmX = tester.getTopLeft(find.byType(AlgorithmPanel)).dx;

    expect(canvasX, lessThan(simulationX));
    expect(simulationX, lessThan(algorithmX));
    expect(find.byType(FSADeterminismOverlay), findsOneWidget);
    expect(find.byType(AlgorithmStepNavigator), findsOneWidget);
  });

  testWidgets('FSAPage desktop help opens context then keyboard shortcuts', (
    tester,
  ) async {
    await _pumpFsaPage(tester, viewSize: const Size(1600, 900));

    await tester.tap(
      find.bySemanticsLabel('Canvas action: Help & Shortcuts'),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ContextAwareHelpPanel), findsOneWidget);
    await tester.tap(find.widgetWithIcon(TextButton, Icons.keyboard));
    await tester.pumpAndSettle();

    expect(find.byType(ContextAwareHelpPanel), findsNothing);
    expect(find.byType(KeyboardShortcutsDialog), findsOneWidget);
  });

  testWidgets('FSAPage mobile Clear remains undoable', (tester) async {
    await _pumpFsaPage(tester, viewSize: const Size(800, 900));
    final canvas = tester.widget<AutomatonGraphViewCanvas>(
      find.byType(AutomatonGraphViewCanvas),
    );
    final controller = canvas.controller!;
    controller.addStateAt(const Offset(120, 120));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Clear canvas'));
    await tester.pumpAndSettle();

    expect(controller.nodes, isEmpty);
    expect(controller.canUndo, isTrue);
    expect(controller.undo(), isTrue);
    await tester.pumpAndSettle();
    expect(controller.nodes, hasLength(1));
  });
}
