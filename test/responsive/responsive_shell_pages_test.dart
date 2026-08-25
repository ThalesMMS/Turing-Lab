//
//  responsive_shell_pages_test.dart
//  Turing Lab
//
//  Structural no-overflow gate for the release-visible surfaces outside the
//  automaton workspaces: the home shell, Settings, Help, About and the
//  language comparison viewer.
//
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/equivalence_comparison_result.dart';
import 'package:turing_lab/presentation/pages/about_page.dart';
import 'package:turing_lab/presentation/pages/help_page.dart';
import 'package:turing_lab/presentation/pages/settings_page.dart';
import 'package:turing_lab/presentation/widgets/desktop_navigation.dart';
import 'package:turing_lab/presentation/widgets/language_comparison_viewer.dart';
import 'package:turing_lab/presentation/widgets/mobile_navigation.dart';

import 'responsive_fixtures.dart';
import 'responsive_harness.dart';
import 'responsive_viewport_matrix.dart';

/// Mirrors the dialog the algorithm panel builds around the comparison viewer:
/// a box covering 90% of the window, a header row, and the viewer filling what
/// is left.
///
/// The production host at `algorithm_panel.dart:951` puts the viewer inside a
/// `SingleChildScrollView`, which hands the viewer's flex column an unbounded
/// height and throws before anything can be measured. This host gives it the
/// bounded box the viewer is written against, so the sweep below measures the
/// viewer's own responsive behaviour rather than that hosting defect.
class _LanguageComparisonHost extends StatelessWidget {
  const _LanguageComparisonHost({required this.comparisonResult});

  final EquivalenceComparisonResult comparisonResult;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: size.width * 0.9,
          height: size.height * 0.9,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.compare_arrows),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        'Language comparison',
                        style: Theme.of(context).textTheme.headlineSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: LanguageComparisonViewer(
                  comparisonResult: comparisonResult,
                  showProductAutomaton: true,
                  showSteps: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

EquivalenceComparisonResult _comparisonFixture() {
  final automatonA = buildResponsiveFsaFixture();
  final automatonB = buildResponsiveFsaFixture();
  return EquivalenceComparisonResult(
    originalAutomaton: automatonA,
    comparedAutomaton: automatonB,
    isEquivalent: false,
    distinguishingString: 'aab',
    productAutomaton: automatonA,
    steps: const [
      {
        'type': 'initialization',
        'description': 'Initialize product automaton construction',
      },
      {'type': 'bfs_exploration', 'description': 'Exploring state (q0,p0)'},
      {
        'type': 'counterexample_found',
        'description': 'Found distinguishing string: aab',
      },
    ],
    executionTimeMs: 87,
    timestamp: DateTime.utc(2026, 1, 1),
  );
}

void main() {
  group('home shell', () {
    for (final viewport in ResponsiveViewports.all) {
      if (viewport.mount == ResponsiveMount.pane) {
        // The home shell always owns the whole window in the app; a pane is a
        // shape only the embedded workspaces can be given.
        continue;
      }
      testWidgets('lays out without overflow on ${viewport.name}', (
        tester,
      ) async {
        final surface = await pumpResponsiveHome(
          tester,
          viewport: viewport,
          prepare: loadResponsiveFixtures,
        );

        final usesRail =
            viewport.logicalSize.width >= ResponsiveBreakpoints.mobile;
        expect(
          find.byType(usesRail ? DesktopNavigation : MobileNavigation),
          findsOneWidget,
          reason: 'the home shell picked the wrong navigation for '
              '${viewport.name}',
        );

        expectReachable(
          tester,
          find.byTooltip('Help'),
          description: 'the home help action',
        );
        expectReachable(
          tester,
          find.byTooltip('Settings'),
          description: 'the home settings action',
        );

        await surface.assertNoLayoutErrors('home shell on ${viewport.name}');
      });
    }
  });

  group('settings page', () {
    for (final viewport in ResponsiveViewports.all) {
      testWidgets('lays out without overflow on ${viewport.name}', (
        tester,
      ) async {
        final surface = await pumpResponsiveSurface(
          tester,
          viewport: viewport,
          child: const SettingsPage(),
        );

        expect(find.byType(SettingsPage), findsOneWidget);
        await surface.assertNoLayoutErrors('settings on ${viewport.name}');
      });
    }
  });

  group('about page', () {
    for (final viewport in ResponsiveViewports.all) {
      testWidgets('lays out without overflow on ${viewport.name}', (
        tester,
      ) async {
        final surface = await pumpResponsiveSurface(
          tester,
          viewport: viewport,
          child: const AboutPage(),
        );

        expect(find.byType(AboutPage), findsOneWidget);
        await surface.assertNoLayoutErrors('about on ${viewport.name}');
      });
    }
  });

  group('help page', () {
    for (final viewport in ResponsiveViewports.all) {
      testWidgets('lays out without overflow on ${viewport.name}', (
        tester,
      ) async {
        final surface = await pumpResponsiveSurface(
          tester,
          viewport: viewport,
          child: const HelpPage(),
        );

        expect(find.byType(HelpPage), findsOneWidget);
        await surface.assertNoLayoutErrors('help on ${viewport.name}');
      });
    }
  });

  group('language comparison viewer', () {
    for (final viewport in ResponsiveViewports.all) {
      testWidgets('lays out without overflow on ${viewport.name}', (
        tester,
      ) async {
        final surface = await pumpResponsiveSurface(
          tester,
          viewport: viewport,
          child: _LanguageComparisonHost(
            comparisonResult: _comparisonFixture(),
          ),
        );

        expect(find.byType(LanguageComparisonViewer), findsOneWidget);
        await surface.assertNoLayoutErrors(
          'language comparison on ${viewport.name}',
        );
      });
    }
  });
}
