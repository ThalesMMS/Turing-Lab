//
//  workspace_dock_helpers.dart
//  Turing Lab
//
//  Helpers for driving the wide-layout workspace dock from widget tests.
//  Side panels start collapsed, so a test that asserts on panel content has
//  to open the panel first, the same way a user would.
//
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/presentation/widgets/automaton_workspace_scaffold.dart';
import 'package:turing_lab/presentation/widgets/workspace_dock.dart';

/// Taps the dock rail button for [panelId] and settles the frame.
///
/// Tapping again collapses the panel, mirroring the production toggle.
Future<void> toggleWorkspaceDockPanel(
  WidgetTester tester,
  String panelId,
) async {
  final railButton = find.byKey(WorkspaceDock.railButtonKey(panelId));
  expect(
    railButton,
    findsOneWidget,
    reason: 'the "$panelId" dock rail button should be mounted',
  );
  await tester.tap(railButton);
  // Two bounded pumps rather than `pumpAndSettle`: the dock itself does not
  // animate, and some workspaces keep a perpetual canvas animation running
  // that would make settling time out.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

/// Opens the shared Algorithms dock panel.
Future<void> openWorkspaceAlgorithmsPanel(WidgetTester tester) =>
    toggleWorkspaceDockPanel(
      tester,
      AutomatonWorkspaceScaffold.algorithmPanelId,
    );

/// Opens the shared Simulation dock panel. Grammar labels the same slot
/// "Parser", but the identifier is shared.
Future<void> openWorkspaceSimulationPanel(WidgetTester tester) =>
    toggleWorkspaceDockPanel(
      tester,
      AutomatonWorkspaceScaffold.simulationPanelId,
    );

/// Opens the shared Info dock panel.
Future<void> openWorkspaceInfoPanel(WidgetTester tester) =>
    toggleWorkspaceDockPanel(tester, AutomatonWorkspaceScaffold.infoPanelId);
