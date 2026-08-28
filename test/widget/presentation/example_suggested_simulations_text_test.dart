import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/formal_systems/formal_systems.dart';
import 'package:turing_lab/core/models/asset_example.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/transducers/transducer_examples_panel.dart';
import 'package:turing_lab/presentation/widgets/example_suggested_simulations_text.dart';

final class _ExampleCatalog implements ExampleCatalogCapability<Object> {
  const _ExampleCatalog();

  @override
  CapabilityNamespaceId get namespace =>
      const CapabilityNamespaceId('examples.transducer.suggestions.test');

  @override
  Future<List<AssetExample<Object>>> loadExamples() async => [
    AssetExample<Object>(
      id: 'mealy.identity',
      name: 'Identity',
      description: 'Echoes every input symbol.',
      category: ExampleCategory.mealy,
      difficultyLevel: DifficultyLevel.easy,
      complexityLevel: ExampleComplexityLevel.low,
      tags: const ['test'],
      payload: Object(),
    ),
  ];
}

Future<void> _pumpSuggestions(
  WidgetTester tester, {
  required Locale locale,
  required List<String> suggestions,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ExampleSuggestedSimulationsText(suggestions: suggestions),
      ),
    ),
  );
}

void main() {
  testWidgets('renders singular English suggestion with full semantics', (
    tester,
  ) async {
    await _pumpSuggestions(
      tester,
      locale: const Locale('en'),
      suggestions: const ['aaabbb'],
    );

    expect(find.text('Suggested simulation: aaabbb'), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(ExampleSuggestedSimulationsText)).label,
      'Suggested simulation: aaabbb.',
    );
  });

  testWidgets(
    'renders plural Brazilian Portuguese suggestions with semantics',
    (tester) async {
      await _pumpSuggestions(
        tester,
        locale: const Locale('pt', 'BR'),
        suggestions: const ['a', 'ab'],
      );

      expect(find.text('Simulações sugeridas: a, ab'), findsOneWidget);
      expect(
        tester.getSemantics(find.byType(ExampleSuggestedSimulationsText)).label,
        'Simulações sugeridas: a, ab.',
      );
    },
  );

  testWidgets(
    'transducer example exposes the localized suggestion in both locales',
    (tester) async {
      tester.view
        ..physicalSize = const Size(320, 700)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      Future<void> pump(Locale locale) async {
        await tester.pumpWidget(
          MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: Scaffold(
              body: TransducerExamplesPanel<Object>(
                catalog: const _ExampleCatalog(),
                onLoad: (_) {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      await pump(const Locale('en'));
      expect(find.text('Suggested simulation: 0101'), findsOneWidget);
      expect(
        tester
            .getSemantics(
              find.byKey(const ValueKey('transducer-example-mealy.identity')),
            )
            .label,
        contains('Suggested simulation: 0101.'),
      );
      expect(tester.takeException(), isNull);

      await pump(const Locale('pt', 'BR'));
      expect(find.text('Simulação sugerida: 0101'), findsOneWidget);
      expect(
        tester
            .getSemantics(
              find.byKey(const ValueKey('transducer-example-mealy.identity')),
            )
            .label,
        contains('Simulação sugerida: 0101.'),
      );
      expect(tester.takeException(), isNull);
    },
  );
}
