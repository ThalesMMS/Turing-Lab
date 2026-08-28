import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/manual_conversions/manual_conversion_session.dart';
import 'package:turing_lab/core/manual_conversions/regex_to_fa_session_factory.dart';
import 'package:turing_lab/core/models/regex_document.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/widgets/regex_to_fa_fragment_editor.dart';

// feature-localization-contract: automata-conversions-and-fragments
// feature-localization-surface: responsive-accessibility
void main() {
  for (final scenario in const [
    (
      locale: Locale('en'),
      semanticLabel: 'Active syntax node and fragment invariant',
    ),
    (
      locale: Locale('pt', 'BR'),
      semanticLabel: 'Nó sintático ativo e invariante do fragmento',
    ),
  ]) {
    testWidgets('localizes Regex-to-FA invariant semantics in '
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
                padding: const EdgeInsets.all(16),
                child: RegexToFaFragmentEditor(
                  requirement: _requirement(),
                  onSubmit: (_) {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final invariant = find.bySemanticsLabel(scenario.semanticLabel);
        expect(invariant, findsOneWidget);
        expect(tester.getSemantics(invariant).label, scenario.semanticLabel);
        if (scenario.locale.languageCode == 'pt') {
          expect(
            find.bySemanticsLabel('Active syntax node and fragment invariant'),
            findsNothing,
          );
          expect(find.text('Nó sintático ativo'), findsOneWidget);
          expect(find.text('Invariante do fragmento'), findsOneWidget);
          expect(
            find.text(
              '2 estados, 1 transição, uma entrada e 1 estado de aceitação. '
              'Alfabeto: a.',
            ),
            findsOneWidget,
          );
          expect(find.textContaining('one entry state'), findsNothing);
          expect(find.textContaining('Estados ·'), findsOneWidget);
          expect(find.textContaining('esperados'), findsNWidgets(2));
          expect(find.text('Adicionar estado'), findsOneWidget);
          expect(
            find.text('Ainda não há transições neste fragmento.'),
            findsOneWidget,
          );
          expect(find.text('Verificar fragmento'), findsOneWidget);
          expect(find.text('Add state'), findsNothing);
          final addState = find.byKey(const ValueKey('regex-fa-add-state'));
          await tester.ensureVisible(addState);
          await tester.tap(addState);
          await tester.pumpAndSettle();
          expect(find.text('ID do estado'), findsOneWidget);
          expect(find.text('Rótulo de exibição'), findsOneWidget);
          expect(find.text('Estado de entrada'), findsOneWidget);
          expect(find.text('Estado de aceitação'), findsOneWidget);
          expect(find.text('Salvar estado'), findsOneWidget);
          expect(find.text('Adicionar estado'), findsWidgets);
          expect(find.text('State ID'), findsNothing);
        }
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    });
  }
}

ManualConversionRequirement _requirement() {
  final session = RegexToFaSessionFactory.create(
    source: RegexDocument(
      id: 'regex-fragment-localization',
      name: 'Regex fragment localization',
      source: 'a',
      alphabet: const ['a'],
    ),
    sourceRevision: 1,
  );
  return session.currentRequirement!;
}
