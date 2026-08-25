//
//  responsive_resize_transitions_test.dart
//  Turing Lab
//
//  Drives every workspace through live window resizes that cross the 1024 and
//  1400 layout boundaries in both directions, asserting the tree keeps its
//  loaded document and reports no framework error across the transitions.
//
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/presentation/providers/automaton_state_provider.dart';
import 'package:turing_lab/presentation/providers/grammar_provider.dart';
import 'package:turing_lab/presentation/providers/home_navigation_provider.dart';
import 'package:turing_lab/presentation/providers/pda_editor_provider.dart';
import 'package:turing_lab/presentation/providers/regex_editor_provider.dart';
import 'package:turing_lab/presentation/providers/tm_editor_provider.dart';

import 'responsive_fixtures.dart';
import 'responsive_harness.dart';
import 'responsive_viewport_matrix.dart';
import 'responsive_workspaces.dart';

/// Window widths the sweep steps through. They are chosen so the width the
/// workspace itself receives - the window minus the home navigation rail -
/// lands below 1024, between 1024 and 1400, and above 1400.
const List<double> _sweepWidths = [800, 1100, 1500, 1900, 1100, 800];

const double _sweepHeight = 900;

/// Runs the resize sweep and returns the workspace widths it observed.
Future<List<double>> _sweep(
  WidgetTester tester,
  ResponsiveSurface surface,
  ResponsiveWorkspace workspace,
) async {
  final observedWidths = <double>[];
  for (final width in _sweepWidths) {
    await surface.resizeTo(
      Size(width, _sweepHeight),
      label: 'resize-${width.toInt()}',
    );

    expect(
      find.byType(workspace.pageType),
      findsOneWidget,
      reason: '${workspace.name} disappeared at ${width}px',
    );

    // Measure the page itself rather than the window: the home shell keeps a
    // navigation rail beside it, so the band the workspace lands in is decided
    // by the width it is actually handed.
    observedWidths.add(tester.getSize(find.byType(workspace.pageType)).width);

    await surface.assertNoLayoutErrors(
      '${workspace.name} resized to ${width}px',
    );
  }
  return observedWidths;
}

void main() {
  for (final workspace in kResponsiveWorkspaces) {
    testWidgets(
        '${workspace.name} survives resizes across the 1024 and 1400 bands',
        (tester) async {
      // Compile the semantics tree on every frame so a breakpoint change that
      // breaks traversal or semantics order reports instead of passing. The
      // handle has to be released inside the body: the binding verifies that
      // before test tear-downs run.
      final semantics = tester.ensureSemantics();
      final List<double> observedWidths;
      final ResponsiveSurface surface;
      try {
        surface = await pumpResponsiveHome(
          tester,
          viewport: ResponsiveViewports.desktopCompact,
          workspaceIndex: workspace.navigationIndex,
          prepare: loadResponsiveFixtures,
        );
        observedWidths = await _sweep(tester, surface, workspace);
      } finally {
        semantics.dispose();
      }

      expect(
        observedWidths.reduce((a, b) => a < b ? a : b),
        lessThan(ResponsiveBreakpoints.mobile),
        reason: 'the sweep never reached the mobile band',
      );
      expect(
        observedWidths.reduce((a, b) => a > b ? a : b),
        greaterThanOrEqualTo(ResponsiveBreakpoints.tablet),
        reason: 'the sweep never reached the desktop band',
      );

      final container = surface.container;
      expect(
        container.read(homeNavigationProvider),
        workspace.navigationIndex,
        reason: '${workspace.name} lost its navigation index across resizes',
      );
      expect(
        container.read(automatonStateProvider).currentAutomaton?.states.length,
        3,
        reason: 'the FSA document did not survive the resize sweep',
      );
      expect(
        container.read(pdaEditorProvider).pda?.states.length,
        3,
        reason: 'the PDA document did not survive the resize sweep',
      );
      expect(
        container.read(tmEditorProvider).tm?.states.length,
        3,
        reason: 'the TM document did not survive the resize sweep',
      );
      expect(
        container.read(grammarProvider).productions.length,
        3,
        reason: 'the grammar productions did not survive the resize sweep',
      );
      expect(
        container.read(regexEditorProvider).currentRegex,
        kResponsiveRegexFixture,
        reason: 'the regular expression did not survive the resize sweep',
      );
    });
  }

  testWidgets('the home shell swaps navigation without throwing mid-resize', (
    tester,
  ) async {
    final surface = await pumpResponsiveHome(
      tester,
      viewport: ResponsiveViewports.desktopCompact,
      prepare: loadResponsiveFixtures,
    );

    // Land exactly on each side of the rail boundaries so the frame where the
    // shell swaps its navigation is actually rendered.
    for (final width in [
      ResponsiveBreakpoints.homeNavigationRail - 1,
      ResponsiveBreakpoints.homeNavigationRail,
      ResponsiveBreakpoints.extendedNavigationRail - 1,
      ResponsiveBreakpoints.extendedNavigationRail,
    ]) {
      await surface.resizeTo(
        Size(width, _sweepHeight),
        label: 'rail-${width.toInt()}',
      );
      await surface.assertNoLayoutErrors('home shell at ${width}px');
    }
  });
}
