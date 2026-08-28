import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/production.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/widgets/grammar_normalization_teaching_workspace.dart';

// feature-localization-contract: grammar-analysis-parsing-and-teaching
// feature-localization-surface: responsive-accessibility
void main() {
  for (final scenario in const [
    (
      locale: Locale('en'),
      referenceSemantic: 'Generated reference grammar',
      referenceTitle: 'Generated reference. Read only.',
    ),
    (
      locale: Locale('pt', 'BR'),
      referenceSemantic: 'Gramática de referência gerada',
      referenceTitle: 'Referência gerada. Somente leitura.',
    ),
  ]) {
    testWidgets('localizes the normalization reference semantics in '
        '${scenario.locale.languageCode} at narrow high text scale', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(320, 700)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();

      try {
        await tester.pumpWidget(
          MaterialApp(
            locale: scenario.locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: Scaffold(
              body: SingleChildScrollView(
                child: GrammarNormalizationTeachingWorkspace(
                  grammar: _normalizationGrammar(),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final toggle = find.byKey(
          const ValueKey('toggle-normalization-reference'),
        );
        await tester.ensureVisible(toggle);
        await tester.tap(toggle);
        await tester.pumpAndSettle();

        final referenceTitle = find.text(scenario.referenceTitle);
        expect(referenceTitle, findsOneWidget);
        final referenceSemantics = tester.getSemantics(referenceTitle);
        expect(referenceSemantics.label, contains(scenario.referenceSemantic));
        if (scenario.locale.languageCode == 'pt') {
          expect(
            referenceSemantics.label,
            isNot(contains('Generated reference grammar')),
          );
        }
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    });
  }

  testWidgets('localizes normalization validation diagnostics in Portuguese', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt', 'BR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: GrammarNormalizationTeachingWorkspace(
            grammar: _normalizationGrammar(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('normalization-draft')),
      'S -> Z',
    );
    await tester.tap(
      find.byKey(const ValueKey('validate-normalization-draft')),
    );
    await tester.pump();

    expect(find.text('Símbolo desconhecido. Linha 1. Z'), findsOneWidget);
    expect(find.textContaining('Unknown symbol.'), findsNothing);
  });
}

Grammar _normalizationGrammar() => Grammar(
  id: 'normalization-reference-localization',
  name: 'Normalization reference localization',
  terminals: const {'a', 'b'},
  nonterminals: const {'S', 'A', 'B'},
  startSymbol: 'S',
  productions: {
    const Production(id: 'p0', leftSide: ['S'], rightSide: ['A', 'B']),
    const Production(id: 'p1', leftSide: ['A'], rightSide: [], isLambda: true),
    const Production(id: 'p2', leftSide: ['A'], rightSide: ['a']),
    const Production(id: 'p3', leftSide: ['B'], rightSide: ['b']),
  },
  type: GrammarType.contextFree,
  created: DateTime.utc(2026),
  modified: DateTime.utc(2026),
);
