import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/widgets/trace_viewers/timeline_scrubber.dart';

void main() {
  testWidgets('formats displayed and announced step counts for the locale', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    Widget app(Locale locale) => MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: TimelineScrubber(
          currentStep: 999,
          totalSteps: 1234,
          onStepChanged: (_) {},
        ),
      ),
    );

    await tester.pumpWidget(app(const Locale('en')));

    expect(find.text('Step 1,000 of 1,234'), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(TimelineScrubber)).value,
      'Step 1,000 of 1,234',
    );

    await tester.pumpWidget(app(const Locale('pt', 'BR')));
    await tester.pump();

    expect(find.text('Passo 1.000 de 1.234'), findsOneWidget);
    expect(find.text('Passo 1000 de 1234'), findsNothing);
    expect(
      tester.getSemantics(find.byType(TimelineScrubber)).value,
      'Passo 1.000 de 1.234',
    );

    semantics.dispose();
  });
}
