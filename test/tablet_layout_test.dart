//
//  tablet_layout_test.dart
//  Turing Lab
//
//  Checks that every workspace picks its tablet layout on a tablet-band
//  viewport, and that the shared tablet container can collapse and expand its
//  sidebar. The viewport itself comes from the canonical responsive matrix.
//
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/presentation/pages/fsa_page.dart';
import 'package:turing_lab/presentation/pages/grammar_page.dart';
import 'package:turing_lab/presentation/pages/pda_page.dart';
import 'package:turing_lab/presentation/pages/pumping_lemma_page.dart';
import 'package:turing_lab/presentation/pages/regex_page.dart';
import 'package:turing_lab/presentation/pages/tm_page.dart';
import 'package:turing_lab/presentation/widgets/pumping_lemma_game/pumping_lemma_game.dart';
import 'package:turing_lab/presentation/widgets/pumping_lemma_progress.dart';
import 'package:turing_lab/presentation/widgets/tablet_layout_container.dart';

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
    }.entries) {
      testWidgets('${entry.key} uses TabletLayoutContainer on tablet width', (
        tester,
      ) async {
        final surface = await pumpResponsiveSurface(
          tester,
          viewport: _tabletViewport,
          child: entry.value,
        );

        expect(find.byType(TabletLayoutContainer), findsOneWidget);
        await surface.assertNoLayoutErrors('${entry.key} on tablet width');
      });
    }

    testWidgets('PumpingLemmaPage splits game and progress on tablet width', (
      tester,
    ) async {
      final surface = await pumpResponsiveSurface(
        tester,
        viewport: _tabletViewport,
        child: const PumpingLemmaPage(),
      );

      // The page dropped its tabbed container when the inline help panel was
      // retired for the shared help route: a tablet now shows the game beside
      // the progress panel, with help reachable from the workspace actions.
      expect(find.byType(TabletLayoutContainer), findsNothing);
      expect(find.byType(PumpingLemmaGame), findsOneWidget);
      expect(find.byType(PumpingLemmaProgress), findsOneWidget);
      expect(
        tester.getRect(find.byType(PumpingLemmaGame)).right,
        lessThanOrEqualTo(
          tester.getRect(find.byType(PumpingLemmaProgress)).left,
        ),
      );
      await surface.assertNoLayoutErrors('pumping lemma on tablet width');
    });

    testWidgets('TabletLayoutContainer sidebar can be collapsed and expanded', (
      tester,
    ) async {
      final surface = await pumpResponsiveSurface(
        tester,
        viewport: _tabletViewport,
        child: const Scaffold(
          body: TabletLayoutContainer(
            canvas: Text('Canvas Content'),
            algorithmPanel: Text('Algorithm Panel Content'),
            simulationPanel: Text('Simulation Panel Content'),
          ),
        ),
      );

      // Initially expanded
      expect(find.text('Algorithm Panel Content'), findsOneWidget);
      expect(find.byIcon(Icons.close_fullscreen), findsOneWidget);

      // Collapse
      await tester.tap(find.byIcon(Icons.close_fullscreen));
      await surface.settle();

      // Sidebar content should be gone
      expect(find.text('Algorithm Panel Content'), findsNothing);
      expect(find.byIcon(Icons.menu_open), findsOneWidget);

      // Expand
      await tester.tap(find.byIcon(Icons.menu_open));
      await surface.settle();

      expect(find.text('Algorithm Panel Content'), findsOneWidget);
      expect(find.byIcon(Icons.close_fullscreen), findsOneWidget);
      await surface.assertNoLayoutErrors('tablet sidebar toggling');
    });
  });
}
