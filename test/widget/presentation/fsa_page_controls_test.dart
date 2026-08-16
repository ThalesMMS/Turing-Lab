import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/pages/fsa_page.dart';
import 'package:turing_lab/presentation/providers/unified_trace_provider.dart';
import 'package:turing_lab/presentation/widgets/algorithm_panel.dart';
import 'package:turing_lab/presentation/widgets/algorithm_step_navigator.dart';
import 'package:turing_lab/presentation/widgets/automaton_graphview_canvas.dart';
import 'package:turing_lab/presentation/widgets/automaton_workspace_scaffold.dart';
import 'package:turing_lab/presentation/widgets/context_aware_help_panel.dart';
import 'package:turing_lab/presentation/widgets/fsa/determinism_badge.dart';
import 'package:turing_lab/presentation/widgets/keyboard_shortcuts_dialog.dart';
import 'package:turing_lab/presentation/widgets/mobile_automaton_controls.dart';
import 'package:turing_lab/presentation/widgets/simulation_panel.dart';

Future<void> _pumpFsaPage(
  WidgetTester tester, {
  required Size viewSize,
  double? paneWidth,
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
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: page,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
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
