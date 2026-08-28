//
//  tablet_layout_test.dart
//  Turing Lab
//
//  Checks that every workspace picks the canvas-first dock layout on a
//  tablet-band viewport, that no side panel is open until the rail is used,
//  and that a rail button toggles its panel. The viewport itself comes from
//  the canonical responsive matrix.
//
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/presentation/pages/fsa_page.dart';
import 'package:turing_lab/presentation/pages/grammar_page.dart';
import 'package:turing_lab/presentation/pages/pda_page.dart';
import 'package:turing_lab/presentation/pages/pumping_lemma_page.dart';
import 'package:turing_lab/presentation/pages/regex_page.dart';
import 'package:turing_lab/presentation/pages/tm_page.dart';
import 'package:turing_lab/presentation/widgets/automaton_workspace_scaffold.dart';
import 'package:turing_lab/presentation/widgets/pumping_lemma_progress.dart';
import 'package:turing_lab/presentation/widgets/pumping_lemma_workspace.dart';
import 'package:turing_lab/presentation/widgets/workspace_dock.dart';

import 'responsive/responsive_harness.dart';
import 'responsive/responsive_viewport_matrix.dart';

/// Tablet-band viewport shared with the responsive gate. Landscape keeps the
/// width between the mobile and desktop breakpoints, which is what selects the
/// tablet layout.
const ResponsiveViewport _tabletViewport = ResponsiveViewports.tabletLandscape;

void main() {
  group('Tablet Layout Tests', () {
    test('the shared viewport sits inside the tablet band', () {
      expect(
        _tabletViewport.logicalSize.width,
        greaterThanOrEqualTo(ResponsiveBreakpoints.mobile),
      );
      expect(
        _tabletViewport.logicalSize.width,
        lessThan(ResponsiveBreakpoints.tablet),
      );
    });

    for (final entry in <String, Widget>{
      'FSAPage': const FSAPage(),
      'RegexPage': const RegexPage(),
      'GrammarPage': const GrammarPage(),
      'TMPage': const TMPage(),
      'PDAPage': const PDAPage(),
      'PumpingLemmaPage': const PumpingLemmaPage(),
    }.entries) {
      testWidgets('${entry.key} uses the workspace dock on tablet width', (
        tester,
      ) async {
        final surface = await pumpResponsiveSurface(
          tester,
          viewport: _tabletViewport,
          child: entry.value,
        );

        expect(find.byType(WorkspaceDock), findsOneWidget);
        await surface.assertNoLayoutErrors('${entry.key} on tablet width');
      });
    }

    testWidgets('workspace panels stay collapsed until the rail is used', (
      tester,
    ) async {
      final surface = await pumpResponsiveSurface(
        tester,
        viewport: _tabletViewport,
        child: const FSAPage(),
      );

      final algorithmsRail = find.byKey(
        WorkspaceDock.railButtonKey(
          AutomatonWorkspaceScaffold.algorithmPanelId,
        ),
      );
      final algorithmsPanel = find.byKey(
        WorkspaceDock.panelKey(AutomatonWorkspaceScaffold.algorithmPanelId),
      );

      expect(algorithmsRail, findsOneWidget);
      expect(algorithmsPanel, findsNothing);

      await tester.tap(algorithmsRail);
      await surface.settle();
      expect(algorithmsPanel, findsOneWidget);

      await tester.tap(algorithmsRail);
      await surface.settle();
      expect(algorithmsPanel, findsNothing);

      await surface.assertNoLayoutErrors('fsa dock toggling on tablet width');
    });

    testWidgets('PumpingLemmaPage keeps the board clear of the progress panel',
        (tester) async {
      final surface = await pumpResponsiveSurface(
        tester,
        viewport: _tabletViewport,
        child: const PumpingLemmaPage(),
      );

      expect(find.byType(PumpingLemmaWorkspace), findsOneWidget);
      expect(find.byType(PumpingLemmaProgress), findsNothing);

      final progressRail = find.byKey(WorkspaceDock.railButtonKey('progress'));
      await tester.tap(progressRail);
      await surface.settle();

      expect(find.byType(PumpingLemmaProgress), findsOneWidget);
      expect(
        tester.getRect(find.byType(PumpingLemmaWorkspace)).right,
        lessThanOrEqualTo(
          tester.getRect(find.byType(PumpingLemmaProgress)).left,
        ),
      );
      await surface.assertNoLayoutErrors('pumping lemma on tablet width');
    });
  });
}
