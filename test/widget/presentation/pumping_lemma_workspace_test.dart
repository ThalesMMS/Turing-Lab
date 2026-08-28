import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/pumping_lemma/pumping_lemma.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/content/pumping_lemma_problem_content_copy.dart';
import 'package:turing_lab/presentation/providers/pumping_lemma_progress_provider.dart';
import 'package:turing_lab/presentation/widgets/pumping_lemma_workspace.dart';

Future<ProviderContainer> _pumpWorkspace(
  WidgetTester tester, {
  required PumpingLemmaTheorem theorem,
  Size size = const Size(800, 1000),
  double textScale = 1,
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
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(body: PumpingLemmaWorkspace(theorem: theorem)),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

Future<void> _tapKey(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  for (final theorem in PumpingLemmaTheorem.values) {
    testWidgets('${theorem.name} follows the adversarial quantifier order', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final container = await _pumpWorkspace(tester, theorem: theorem);

      expect(find.textContaining('Step 1, for every p'), findsOneWidget);
      await _tapKey(tester, 'choose-pumping-length');
      expect(find.textContaining('Step 2, there exists w'), findsOneWidget);

      await _tapKey(tester, 'choose-witness');
      expect(
        find.textContaining('valid decompositions enumerated'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Step 3, for every valid decomposition'),
        findsOneWidget,
      );

      await _tapKey(tester, 'choose-decomposition');
      expect(find.textContaining('Step 4, there exists i'), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp(r'^Decomposition\.')),
        findsOneWidget,
      );
      semantics.dispose();

      await _tapKey(tester, 'choose-exponent');
      expect(find.textContaining('Step 5: check concrete'), findsOneWidget);
      await _tapKey(tester, 'record-pumping-evidence');

      expect(find.textContaining('Round complete. Score: 1.'), findsOneWidget);
      expect(
        find.textContaining('This exponent is concrete counterexample'),
        findsOneWidget,
      );
      final progress = container.read(
        theorem == PumpingLemmaTheorem.regular
            ? regularPumpingLemmaProgressProvider
            : contextFreePumpingLemmaProgressProvider,
      );
      expect(progress.attempts, 1);
      expect(progress.score, 1);

      await _tapKey(tester, 'pumping-retry');
      expect(
        find.textContaining('Step 3, for every valid decomposition'),
        findsOneWidget,
      );
      expect(
        container
            .read(
              theorem == PumpingLemmaTheorem.regular
                  ? regularPumpingLemmaProgressProvider
                  : contextFreePumpingLemmaProgressProvider,
            )
            .score,
        1,
      );
    });
  }

  testWidgets('compact layout supports 200 percent text without overflow', (
    tester,
  ) async {
    await _pumpWorkspace(
      tester,
      theorem: PumpingLemmaTheorem.contextFree,
      size: const Size(320, 700),
      textScale: 2,
    );

    expect(find.text('Context-free pumping lemma'), findsWidgets);
    expect(tester.takeException(), isNull);
    await _tapKey(tester, 'choose-pumping-length');
    expect(tester.takeException(), isNull);
  });

  testWidgets('oversized pumped word stays on the exponent step', (
    tester,
  ) async {
    await _pumpWorkspace(tester, theorem: PumpingLemmaTheorem.regular);
    await _tapKey(tester, 'choose-pumping-length');
    await _tapKey(tester, 'choose-witness');
    await _tapKey(tester, 'choose-decomposition');
    await tester.enterText(
      find.byKey(const ValueKey('pumping-exponent-input')),
      '${defaultMaximumPumpedTokens + 1}',
    );

    await _tapKey(tester, 'choose-exponent');

    expect(find.textContaining('the limit is 1000000'), findsOneWidget);
    expect(find.textContaining('Step 4, there exists i'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final theorem in PumpingLemmaTheorem.values) {
    testWidgets(
      '${theorem.name} challenge chooser exposes every curated problem',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await _pumpWorkspace(
          tester,
          theorem: theorem,
          size: const Size(320, 700),
          textScale: 2,
        );
        final problems = theorem == PumpingLemmaTheorem.regular
            ? PumpingLemmaProblemCatalog.regular
            : PumpingLemmaProblemCatalog.contextFree;
        final selected = problems.last;
        final copy = PumpingLemmaProblemContentCopies.resolve(
          id: selected.id,
          languageCode: 'en',
          fallbackTitle: selected.customTitle,
        );

        expect(
          find.bySemanticsLabel(RegExp(r'^Pumping challenge')),
          findsOneWidget,
        );
        await _tapKey(tester, 'pumping-problem-picker-${problems.first.id}');
        final option = find.byKey(
          ValueKey('pumping-problem-option-${selected.id}'),
        );
        await tester.scrollUntilVisible(
          option,
          120,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.tap(option);
        await tester.pumpAndSettle();

        expect(find.text(copy.title), findsWidgets);
        expect(
          find.text('Learning objective: ${copy.learningObjective}'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        semantics.dispose();
      },
    );
  }
}
