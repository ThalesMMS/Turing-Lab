//
//  responsive_workspace_pages_test.dart
//  Turing Lab
//
//  Structural no-overflow gate for the FSA, Grammar, PDA, TM and Regex
//  workspaces. Every case mounts the real page with a populated document and
//  fails on any framework error the frame reports.
//
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/presentation/widgets/workspace_dock.dart';

import 'responsive_fixtures.dart';
import 'responsive_harness.dart';
import 'responsive_viewport_matrix.dart';
import 'responsive_workspaces.dart';

void main() {
  for (final workspace in kResponsiveWorkspaces) {
    group('${workspace.name} workspace', () {
      for (final viewport in ResponsiveViewports.all) {
        testWidgets('lays out without overflow on ${viewport.name}', (
          tester,
        ) async {
          final surface = await pumpResponsiveWorkspace(
            tester,
            viewport: viewport,
            workspace: workspace,
            prepare: loadResponsiveFixtures,
          );

          expect(
            find.byType(workspace.pageType),
            findsOneWidget,
            reason: '${workspace.name} page should be the mounted workspace',
          );

          if (viewport.mount == ResponsiveMount.pane) {
            expect(
              tester.getSize(find.byType(workspace.pageType)).width,
              closeTo(viewport.layoutWidth, 0.5),
              reason: '${workspace.name} did not receive the pane width, so '
                  'the constrained case is not being exercised',
            );
          }

          // Core actions live in the app bar on every band; they have to stay
          // tappable and within the window rather than merely mounted.
          final appBarActions = find.descendant(
            of: find.byType(AppBar),
            matching: find.byType(IconButton),
          );
          expectReachable(
            tester,
            appBarActions,
            description: '${workspace.name} app bar actions',
          );
          expectTouchTarget(
            tester,
            appBarActions,
            description: '${workspace.name} app bar actions',
          );
          expectWithinViewport(
            tester,
            appBarActions,
            description: '${workspace.name} app bar actions',
          );

          await surface.assertNoLayoutErrors(
            '${workspace.name} on ${viewport.name}',
          );
        });
      }
    });
  }

  group('workspace band selection', () {
    for (final workspace in kResponsiveWorkspaces) {
      for (final viewport in ResponsiveViewports.all) {
        testWidgets(
            '${workspace.name} matches its measured band on ${viewport.name}',
            (tester) async {
          final surface = await pumpResponsiveWorkspace(
            tester,
            viewport: viewport,
            workspace: workspace,
            prepare: loadResponsiveFixtures,
          );

          final page = find.byType(workspace.pageType);
          expect(page, findsOneWidget);

          // The band must follow the width the page is actually given, which
          // is narrower than the window whenever it is mounted in a pane.
          final width = tester.getSize(page).width;
          final isWideBand = width >= ResponsiveBreakpoints.mobile;
          expect(
            find.byType(WorkspaceDock),
            isWideBand ? findsOneWidget : findsNothing,
            reason: '${workspace.name} received ${width}px on '
                '${viewport.name} and picked the wrong layout band',
          );

          await surface.assertNoLayoutErrors(
            '${workspace.name} band on ${viewport.name}',
          );
        });
      }
    }
  });
}
