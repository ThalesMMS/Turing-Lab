//
//  responsive_text_scale_and_locale_test.dart
//  Turing Lab
//
//  Pressure cases for the responsive contract: English and Portuguese on the
//  long-label surfaces, and the 1.0 / 1.3 / 2.0 dynamic-type ladder. Essential
//  actions must stay reachable at their touch target, not merely present.
//
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/presentation/pages/help_page.dart';
import 'package:turing_lab/presentation/pages/settings_page.dart';

import 'responsive_fixtures.dart';
import 'responsive_harness.dart';
import 'responsive_viewport_matrix.dart';
import 'responsive_workspaces.dart';

/// Viewports the pressure sweep runs on: the tightest phone, a tablet and a
/// desktop, one per layout band.
const List<ResponsiveViewport> _pressureViewports = [
  ResponsiveViewports.narrowPhone,
  ResponsiveViewports.tabletPortrait,
  ResponsiveViewports.desktopLarge,
];

String _localeName(Locale locale) => locale.languageCode;

void main() {
  group('home shell dynamic type', () {
    for (final locale in ResponsiveLocales.all) {
      for (final textScale in ResponsiveTextScales.all) {
        for (final viewport in _pressureViewports) {
          testWidgets(
              'keeps the app bar actions usable in ${_localeName(locale)} at '
              'x$textScale on ${viewport.name}', (tester) async {
            final surface = await pumpResponsiveHome(
              tester,
              viewport: viewport,
              locale: locale,
              textScale: textScale,
              prepare: loadResponsiveFixtures,
            );

            // Essential actions must survive dynamic type instead of being
            // pushed off screen or shrunk below the touch target.
            final actions = find.descendant(
              of: find.byType(AppBar),
              matching: find.byType(IconButton),
            );
            expectReachable(
              tester,
              actions,
              description: 'the home app bar actions',
            );
            expectTouchTarget(
              tester,
              actions,
              description: 'the home app bar actions',
            );
            expectWithinViewport(
              tester,
              actions,
              description: 'the home app bar actions',
            );

            await surface.assertNoLayoutErrors(
              'home shell in ${_localeName(locale)} at x$textScale on '
              '${viewport.name}',
            );
          });
        }
      }
    }
  });

  group('workspace dynamic type', () {
    for (final workspace in kResponsiveWorkspaces) {
      for (final locale in ResponsiveLocales.all) {
        testWidgets(
            '${workspace.name} holds together in ${_localeName(locale)} at the '
            'accessibility text scale', (tester) async {
          final surface = await pumpResponsiveWorkspace(
            tester,
            viewport: ResponsiveViewports.largePhone,
            workspace: workspace,
            locale: locale,
            textScale: ResponsiveTextScales.accessibility,
            prepare: loadResponsiveFixtures,
          );

          expect(find.byType(workspace.pageType), findsOneWidget);
          await surface.assertNoLayoutErrors(
            '${workspace.name} in ${_localeName(locale)} at the accessibility '
            'text scale',
          );
        });
      }
    }
  });

  group('long-label settings and help', () {
    for (final locale in ResponsiveLocales.all) {
      for (final textScale in ResponsiveTextScales.all) {
        testWidgets(
            'settings survives ${_localeName(locale)} at x$textScale on the '
            'narrow phone', (tester) async {
          final surface = await pumpResponsiveSurface(
            tester,
            viewport: ResponsiveViewports.narrowPhone,
            locale: locale,
            textScale: textScale,
            child: const SettingsPage(),
          );

          expect(find.byType(SettingsPage), findsOneWidget);
          await surface.assertNoLayoutErrors(
            'settings in ${_localeName(locale)} at x$textScale',
          );
        });

        testWidgets(
            'help survives ${_localeName(locale)} at x$textScale on the narrow '
            'phone', (tester) async {
          final surface = await pumpResponsiveSurface(
            tester,
            viewport: ResponsiveViewports.narrowPhone,
            locale: locale,
            textScale: textScale,
            child: const HelpPage(),
          );

          expect(find.byType(HelpPage), findsOneWidget);
          await surface.assertNoLayoutErrors(
            'help in ${_localeName(locale)} at x$textScale',
          );
        });
      }
    }
  });

  group('dark mode', () {
    for (final viewport in ResponsiveViewports.representative) {
      testWidgets('the home shell lays out in dark mode on ${viewport.name}', (
        tester,
      ) async {
        final surface = await pumpResponsiveHome(
          tester,
          viewport: viewport,
          brightness: Brightness.dark,
          prepare: loadResponsiveFixtures,
        );

        expect(
          Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
          Brightness.dark,
        );
        await surface.assertNoLayoutErrors(
          'home shell in dark mode on ${viewport.name}',
        );
      });
    }
  });
}
