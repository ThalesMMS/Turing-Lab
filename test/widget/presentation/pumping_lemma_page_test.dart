import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:turing_lab/core/constants/help_topic_ids.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/pages/help_page.dart';
import 'package:turing_lab/presentation/pages/pumping_lemma_page.dart';
import 'package:turing_lab/presentation/providers/workspace_quick_actions_provider.dart';
import 'package:turing_lab/presentation/widgets/pumping_lemma_game/pumping_lemma_game.dart';
import 'package:turing_lab/presentation/widgets/pumping_lemma_progress.dart';

import '../../support/workspace_dock_helpers.dart';

Future<ProviderContainer> _pumpPumpingPage(
  WidgetTester tester, {
  required Size size,
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final container = ProviderContainer();
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const PumpingLemmaPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('mobile Show Help opens catalog and preserves the active game', (
    tester,
  ) async {
    await _pumpPumpingPage(tester, size: const Size(430, 932));

    await tester.tap(find.text('Start Game'));
    await tester.pumpAndSettle();
    expect(find.text('Score: 0'), findsOneWidget);

    await tester.tap(find.text('Show Help'));
    await tester.pumpAndSettle();

    final page = tester.widget<HelpPage>(find.byType(HelpPage));
    expect(page.initialTopicId, HelpTopicIds.pumpingEditorGame);
    expect(
      find.byKey(
        const ValueKey('help-body-${HelpTopicIds.pumpingEditorGame}'),
      ),
      findsOneWidget,
    );

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Score: 0'), findsOneWidget);
    expect(find.text('Show Help'), findsOneWidget);
    expect(find.text('Pumping Lemma Help'), findsNothing);

    await tester.tap(find.text('Show Progress'));
    await tester.pumpAndSettle();
    expect(find.byType(PumpingLemmaProgress), findsOneWidget);
  });

  for (final scenario in const [
    ('tablet', Size(1200, 900), Locale('en'), 'Show Progress'),
    ('desktop', Size(1600, 1000), Locale('pt'), 'Mostrar Progresso'),
  ]) {
    testWidgets('${scenario.$1} keeps the board clear until progress is asked',
        (
      tester,
    ) async {
      await _pumpPumpingPage(
        tester,
        size: scenario.$2,
        locale: scenario.$3,
      );

      // The board owns the pane; progress waits behind the dock rail.
      expect(find.byType(PumpingLemmaGame), findsOneWidget);
      expect(find.byType(PumpingLemmaProgress), findsNothing);
      expect(find.text('Pumping Lemma Help'), findsNothing);
      expect(find.text('Theory'), findsNothing);
      expect(find.byTooltip(scenario.$4), findsOneWidget);

      final fullWidthGame = tester.getRect(find.byType(PumpingLemmaGame));
      expect(fullWidthGame.width, greaterThan(scenario.$2.width * 0.85));

      await toggleWorkspaceDockPanel(tester, 'progress');

      final gameRect = tester.getRect(find.byType(PumpingLemmaGame));
      final progressRect = tester.getRect(find.byType(PumpingLemmaProgress));
      expect(gameRect.right, lessThanOrEqualTo(progressRect.left));
      expect(gameRect.width, greaterThan(progressRect.width));
      expect(gameRect.width, greaterThan(scenario.$2.width * 0.55));
    });

    testWidgets('${scenario.$1} publishes Help for the Pumping game topic', (
      tester,
    ) async {
      final container = await _pumpPumpingPage(
        tester,
        size: scenario.$2,
        locale: scenario.$3,
      );

      // The wide layout no longer paints its own help button: the shell's
      // app bar renders the published action instead.
      final actions =
          container.read(workspaceQuickActionsProvider(WorkspaceTab.pumping));
      expect(actions?.onHelp, isNotNull);

      actions!.onHelp!();
      await tester.pumpAndSettle();

      final page = tester.widget<HelpPage>(find.byType(HelpPage));
      expect(page.initialTopicId, HelpTopicIds.pumpingEditorGame);
      expect(
        find.byKey(
          const ValueKey('help-body-${HelpTopicIds.pumpingEditorGame}'),
        ),
        findsOneWidget,
      );
    });
  }
}
