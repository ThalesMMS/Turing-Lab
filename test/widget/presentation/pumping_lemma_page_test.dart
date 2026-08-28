import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:turing_lab/core/constants/help_topic_ids.dart';
import 'package:turing_lab/core/formal_systems/formal_systems.dart';
import 'package:turing_lab/core/pumping_lemma/pumping_lemma.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/pages/help_page.dart';
import 'package:turing_lab/presentation/pages/pumping_lemma_page.dart';
import 'package:turing_lab/presentation/providers/pumping_lemma_progress_provider.dart';
import 'package:turing_lab/presentation/providers/workspace_quick_actions_provider.dart';
import 'package:turing_lab/presentation/providers/workspace_registry_provider.dart';
import 'package:turing_lab/presentation/widgets/pumping_lemma_progress.dart';
import 'package:turing_lab/presentation/widgets/pumping_lemma_workspace.dart';
import 'package:turing_lab/presentation/widgets/workspace_dock.dart';
import 'package:turing_lab/presentation/widgets/workspace_quick_actions_bar.dart';

FormalSystemKey _workspaceKey(PumpingLemmaTheorem theorem) =>
    theorem == PumpingLemmaTheorem.regular
    ? DefaultFormalSystemIds.regularPumping
    : DefaultFormalSystemIds.contextFreePumping;

FormalSystemKey _otherWorkspaceKey(PumpingLemmaTheorem theorem) =>
    theorem == PumpingLemmaTheorem.regular
    ? DefaultFormalSystemIds.contextFreePumping
    : DefaultFormalSystemIds.regularPumping;

Future<ProviderContainer> _pumpPumpingPage(
  WidgetTester tester, {
  required Size size,
  Locale locale = const Locale('en'),
  PumpingLemmaTheorem theorem = PumpingLemmaTheorem.regular,
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final container = ProviderContainer(
    overrides: [
      formalSystemRegistryProvider.overrideWithValue(
        FormalSystemRegistry.defaultRegistry,
      ),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(
          appBar: AppBar(
            leadingWidth: 120,
            leading: WorkspaceQuickActionsBar(
              workspaceKey: _workspaceKey(theorem),
            ),
          ),
          body: PumpingLemmaPage(theorem: theorem),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

Finder get _progressAction =>
    find.byKey(const ValueKey('workspace-quick-action-progress'));

void main() {
  for (final scenario in const [
    (
      PumpingLemmaTheorem.regular,
      Locale('en'),
      'Progress',
      'Hide Game',
      'Show Help',
    ),
    (
      PumpingLemmaTheorem.contextFree,
      Locale('pt'),
      'Progresso',
      'Ocultar jogo',
      'Mostrar ajuda',
    ),
  ]) {
    testWidgets(
      'compact ${scenario.$1.name} opens statistics in a bottom sheet',
      (tester) async {
        final container = await _pumpPumpingPage(
          tester,
          size: const Size(430, 932),
          locale: scenario.$2,
          theorem: scenario.$1,
        );

        expect(find.byType(PumpingLemmaWorkspace), findsOneWidget);
        expect(find.byType(PumpingLemmaProgress), findsNothing);
        expect(find.text(scenario.$4), findsNothing);
        expect(find.text(scenario.$5), findsNothing);
        expect(find.byTooltip(scenario.$3), findsOneWidget);
        expect(
          find.descendant(
            of: _progressAction,
            matching: find.byIcon(Icons.bar_chart),
          ),
          findsOneWidget,
        );

        final actions = container.read(
          workspaceQuickActionsProvider(_workspaceKey(scenario.$1)),
        );
        expect(actions?.onHelp, isNotNull);
        expect(actions?.onProgress, isNotNull);
        expect(actions?.progressEnabled, isTrue);
        expect(
          container.read(
            workspaceQuickActionsProvider(_otherWorkspaceKey(scenario.$1)),
          ),
          isNull,
        );

        await tester.tap(_progressAction);
        await tester.pumpAndSettle();

        // The sheet overlays the game; the workspace stays mounted so the
        // active round survives.
        expect(find.byType(BottomSheet), findsOneWidget);
        expect(find.byType(PumpingLemmaWorkspace), findsOneWidget);
        expect(find.byType(PumpingLemmaProgress), findsOneWidget);
        expect(
          tester
              .widget<PumpingLemmaProgress>(find.byType(PumpingLemmaProgress))
              .theorem,
          scenario.$1,
        );

        await tester.tap(
          find.descendant(
            of: find.byType(BottomSheet),
            matching: find.byIcon(Icons.close),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(PumpingLemmaWorkspace), findsOneWidget);
        expect(find.byType(PumpingLemmaProgress), findsNothing);
        expect(
          container
              .read(workspaceQuickActionsProvider(_workspaceKey(scenario.$1)))
              ?.progressFocusNode
              ?.hasFocus,
          isTrue,
        );

        final activeProgress = container.read(
          scenario.$1 == PumpingLemmaTheorem.regular
              ? regularPumpingLemmaProgressProvider
              : contextFreePumpingLemmaProgressProvider,
        );
        final inactiveProgress = container.read(
          scenario.$1 == PumpingLemmaTheorem.regular
              ? contextFreePumpingLemmaProgressProvider
              : regularPumpingLemmaProgressProvider,
        );
        expect(activeProgress.totalChallenges, greaterThan(0));
        expect(inactiveProgress.totalChallenges, 0);
      },
    );
  }

  for (final scenario in const [
    (
      'tablet EN',
      Size(1200, 900),
      Locale('en'),
      PumpingLemmaTheorem.regular,
      'Progress',
    ),
    (
      'desktop PT',
      Size(1600, 1000),
      Locale('pt'),
      PumpingLemmaTheorem.contextFree,
      'Progresso',
    ),
  ]) {
    testWidgets('${scenario.$1} quick action controls the only dock panel', (
      tester,
    ) async {
      final container = await _pumpPumpingPage(
        tester,
        size: scenario.$2,
        locale: scenario.$3,
        theorem: scenario.$4,
      );

      expect(find.byType(PumpingLemmaWorkspace), findsOneWidget);
      expect(find.byType(PumpingLemmaProgress), findsNothing);
      expect(find.byTooltip(scenario.$5), findsWidgets);

      await tester.tap(_progressAction);
      await tester.pumpAndSettle();

      expect(find.byType(PumpingLemmaWorkspace), findsOneWidget);
      expect(find.byType(PumpingLemmaProgress), findsOneWidget);
      expect(find.byKey(WorkspaceDock.panelKey('progress')), findsOneWidget);

      await tester.tap(find.byKey(WorkspaceDock.railButtonKey('progress')));
      await tester.pumpAndSettle();
      expect(find.byType(PumpingLemmaProgress), findsNothing);

      await tester.tap(_progressAction);
      await tester.pumpAndSettle();
      await tester.tap(_progressAction);
      await tester.pumpAndSettle();
      expect(
        container
            .read(workspaceQuickActionsProvider(_workspaceKey(scenario.$4)))
            ?.progressFocusNode
            ?.hasFocus,
        isTrue,
      );
    });
  }

  testWidgets('Progress sheet survives crossing the compact breakpoint', (
    tester,
  ) async {
    await _pumpPumpingPage(tester, size: const Size(430, 932));

    await tester.tap(_progressAction);
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(PumpingLemmaProgress), findsOneWidget);

    // The sheet is a route, so a resize to a wide layout keeps it open and
    // the game mounted underneath.
    tester.view.physicalSize = const Size(1200, 900);
    await tester.pumpAndSettle();
    expect(find.byType(PumpingLemmaProgress), findsOneWidget);
    expect(find.byType(PumpingLemmaWorkspace), findsOneWidget);
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(430, 932);
    await tester.pumpAndSettle();
    expect(find.byType(PumpingLemmaProgress), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final scenario in const [
    (PumpingLemmaTheorem.regular, Size(430, 932), Locale('en')),
    (PumpingLemmaTheorem.contextFree, Size(1200, 900), Locale('pt')),
  ]) {
    testWidgets(
      'global Help preserves the ${scenario.$1.name} pumping session',
      (tester) async {
        final container = await _pumpPumpingPage(
          tester,
          size: scenario.$2,
          locale: scenario.$3,
          theorem: scenario.$1,
        );
        const sessionValue = '7';
        await tester.enterText(
          find.byKey(const ValueKey('pumping-length-input')),
          sessionValue,
        );

        container
            .read(workspaceQuickActionsProvider(_workspaceKey(scenario.$1)))!
            .onHelp!();
        await tester.pumpAndSettle();

        final page = tester.widget<HelpPage>(find.byType(HelpPage));
        expect(page.initialTopicId, HelpTopicIds.pumpingEditorGame);
        expect(
          find.byKey(
            const ValueKey('help-body-${HelpTopicIds.pumpingEditorGame}'),
          ),
          findsOneWidget,
        );

        Navigator.of(tester.element(find.byType(HelpPage))).pop();
        await tester.pumpAndSettle();
        expect(find.byType(PumpingLemmaWorkspace), findsOneWidget);
        expect(
          tester
              .widget<TextField>(
                find.byKey(const ValueKey('pumping-length-input')),
              )
              .controller
              ?.text,
          sessionValue,
        );
      },
    );
  }

  testWidgets('compact 320 px layout supports Portuguese at 200 percent text', (
    tester,
  ) async {
    await _pumpPumpingPage(
      tester,
      size: const Size(320, 700),
      locale: const Locale('pt'),
      theorem: PumpingLemmaTheorem.contextFree,
      textScale: 2,
    );

    expect(find.byType(PumpingLemmaWorkspace), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(_progressAction);
    await tester.pumpAndSettle();
    expect(find.byType(PumpingLemmaProgress), findsOneWidget);
    expect(find.byType(PumpingLemmaWorkspace), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
