import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/l10n/app_localizations_en.dart';
import 'package:turing_lab/l10n/app_localizations_pt.dart';
import 'package:turing_lab/presentation/localization/locale_value_formatter.dart';
import 'package:turing_lab/presentation/providers/pumping_lemma_progress_provider.dart';
import 'package:turing_lab/presentation/widgets/pumping_lemma_progress.dart';

Future<void> _pumpProgress(
  WidgetTester tester, {
  required Locale locale,
  required Size size,
  required double textScale,
  bool populateHistory = true,
  int totalChallenges = 12,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final container = ProviderContainer();
  addTearDown(container.dispose);
  final progress = container.read(regularPumpingLemmaProgressProvider.notifier);
  progress.startNewGame(totalChallenges: totalChallenges);
  if (populateHistory) {
    progress.recordAnswer(
      challengeId: 1,
      challengeContentId: 'regular.equal-blocks',
      language: '{ a^n b^n | n >= 0 }',
      isCorrect: false,
    );
    progress.recordRetry(
      challengeId: 1,
      challengeContentId: 'regular.equal-blocks',
      language: '{ a^n b^n | n >= 0 }',
    );
  }

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
        home: const Scaffold(
          body: SingleChildScrollView(child: PumpingLemmaProgress()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final locale in const [Locale('en'), Locale('pt')]) {
    testWidgets(
      'overall progress exposes localized semantics at 320 px and 200% in ${locale.languageCode}',
      (tester) async {
        await _pumpProgress(
          tester,
          locale: locale,
          size: const Size(320, 700),
          textScale: 2,
          populateHistory: false,
        );
        final semantics = tester.ensureSemantics();
        final l10n = locale.languageCode == 'pt'
            ? AppLocalizationsPt()
            : AppLocalizationsEn();
        try {
          final progressSemantics = tester.getSemantics(
            find.bySemanticsLabel(l10n.overallProgress),
          );

          expect(progressSemantics.label, l10n.overallProgress);
          expect(
            progressSemantics.value,
            LocaleValueFormatter(locale).percentFromRatio(0, decimalDigits: 0),
          );
          expect(tester.takeException(), isNull);
        } finally {
          semantics.dispose();
        }
      },
    );
  }

  for (final locale in const [Locale('en'), Locale('pt')]) {
    testWidgets(
      'statistics and populated history reflow at 320 px and 200% in ${locale.languageCode}',
      (tester) async {
        await _pumpProgress(
          tester,
          locale: locale,
          size: const Size(320, 900),
          textScale: 2,
        );

        expect(find.byType(PumpingLemmaProgress), findsOneWidget);
        final accuracy = find.text(
          locale.languageCode == 'pt' ? 'Precisão' : 'Accuracy',
        );
        final correct = find.text(
          locale.languageCode == 'pt' ? 'Corretas' : 'Correct',
        );
        expect(accuracy, findsOneWidget);
        expect(correct, findsOneWidget);
        expect(
          tester.getRect(accuracy).top,
          lessThan(tester.getRect(correct).top),
        );
        expect(
          find.text(locale.languageCode == 'pt' ? 'Errado' : 'Wrong'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);

        await tester.ensureVisible(find.byType(ListView));
        await tester.pumpAndSettle();
        await tester.drag(find.byType(ListView), const Offset(0, -400));
        await tester.pumpAndSettle();
        expect(
          find.text(
            locale.languageCode == 'pt'
                ? 'Repetir selecionados'
                : 'Retry selected',
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final locale in const [Locale('en'), Locale('pt')]) {
    testWidgets(
      'empty history grows naturally at 320 px and 200% in ${locale.languageCode}',
      (tester) async {
        await _pumpProgress(
          tester,
          locale: locale,
          size: const Size(320, 900),
          textScale: 2,
          populateHistory: false,
        );

        expect(
          find.text(
            locale.languageCode == 'pt'
                ? 'Nenhum desafio concluído ainda'
                : 'No challenges completed yet',
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('keeps the wide statistics and history side by side', (
    tester,
  ) async {
    await _pumpProgress(
      tester,
      locale: const Locale('en'),
      size: const Size(800, 900),
      textScale: 1,
    );

    final accuracy = tester.getRect(find.text('Accuracy'));
    final correct = tester.getRect(find.text('Correct').first);
    expect(accuracy.top, correct.top);
    expect(accuracy.left, lessThan(correct.left));

    final challenge = tester.getRect(find.text('Equal a and b blocks').first);
    final result = tester.getRect(find.text('Wrong'));
    expect(result.left, greaterThan(challenge.left));
    expect(result.center.dy, closeTo(challenge.center.dy, 48));
    expect(tester.takeException(), isNull);
  });

  testWidgets('formats progress counts for Portuguese', (tester) async {
    await _pumpProgress(
      tester,
      locale: const Locale('pt', 'BR'),
      size: const Size(800, 900),
      textScale: 1,
      populateHistory: false,
      totalChallenges: 1234,
    );

    expect(find.text('0/1.234'), findsOneWidget);
    expect(find.textContaining('1.234'), findsWidgets);
    expect(find.text('0/1234'), findsNothing);
  });
}
