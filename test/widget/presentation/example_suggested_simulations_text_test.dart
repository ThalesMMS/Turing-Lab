import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/formal_systems/formal_systems.dart';
import 'package:turing_lab/core/models/asset_example.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/content/example_suggested_simulations.dart';
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
  List<ExampleSuggestedSimulation> counterexamples = const [],
  ValueChanged<String>? onUseInput,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ExampleSuggestedSimulationsText(
          suggestions: suggestions,
          counterexamples: counterexamples,
          onUseInput: onUseInput,
        ),
      ),
    ),
  );
}

const _counterexamples = [
  ExampleSuggestedSimulation(
    input: 'ba',
    expectation: ExampleSimulationExpectation.rejected,
    rationaleEn: 'The b comes first.',
    rationalePt: 'O b vem primeiro.',
  ),
  ExampleSuggestedSimulation(
    input: '',
    expectation: ExampleSimulationExpectation.accepted,
    rationaleEn: 'Empty word stays in q0.',
    rationalePt: 'A palavra vazia fica em q0.',
  ),
  ExampleSuggestedSimulation(
    input: 'abc',
    expectation: ExampleSimulationExpectation.invalidSymbol,
    rationaleEn: 'c is outside the alphabet.',
    rationalePt: 'c está fora do alfabeto.',
  ),
];

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

  testWidgets('renders commented inputs with expectation and rationale', (
    tester,
  ) async {
    await _pumpSuggestions(
      tester,
      locale: const Locale('en'),
      suggestions: const ['aab'],
      counterexamples: _counterexamples,
    );

    expect(find.text('Commented inputs:'), findsOneWidget);
    expect(find.text('ba'), findsOneWidget);
    expect(find.text('Expected: rejected'), findsOneWidget);
    expect(find.text('The b comes first.'), findsOneWidget);
    expect(find.text('ε'), findsOneWidget);
    expect(find.text('Expected: accepted'), findsOneWidget);
    expect(find.text('Invalid for the alphabet'), findsOneWidget);
    expect(find.text('c is outside the alphabet.'), findsOneWidget);
    final label = tester
        .getSemantics(find.byType(ExampleSuggestedSimulationsText))
        .label;
    expect(label, contains('Suggested simulation: aab.'));
    expect(label, contains('ba: Expected: rejected. The b comes first.'));
    expect(label, contains('ε: Expected: accepted. Empty word stays in q0.'));
  });

  testWidgets('commented inputs expose Use input chips in Portuguese', (
    tester,
  ) async {
    final used = <String>[];
    await _pumpSuggestions(
      tester,
      locale: const Locale('pt', 'BR'),
      suggestions: const ['aab'],
      counterexamples: _counterexamples,
      onUseInput: used.add,
    );

    expect(find.text('Entradas comentadas:'), findsOneWidget);
    expect(find.text('Esperado: rejeitada'), findsOneWidget);
    expect(find.text('Esperado: aceita'), findsOneWidget);
    expect(find.text('Inválida para o alfabeto'), findsOneWidget);
    expect(find.text('O b vem primeiro.'), findsOneWidget);
    expect(find.byTooltip('Usar entrada'), findsNWidgets(4));

    await tester.tap(
      find.byKey(ExampleSuggestedSimulationsText.useInputKey('')),
    );
    await tester.tap(
      find.byKey(ExampleSuggestedSimulationsText.useInputKey('ba')),
    );
    expect(used, ['', 'ba']);
  });

  testWidgets('actionable chips keep their tap semantics', (tester) async {
    await _pumpSuggestions(
      tester,
      locale: const Locale('en'),
      suggestions: const ['aab'],
      counterexamples: _counterexamples,
      onUseInput: (_) {},
    );

    for (final input in ['aab', 'ba', '', 'abc']) {
      final chip = find.byKey(
        ExampleSuggestedSimulationsText.useInputKey(input),
      );
      expect(chip, findsOneWidget, reason: 'chip for "$input"');
      expect(
        tester
            .getSemantics(chip)
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isTrue,
        reason: 'chip for "$input" exposes a tap action',
      );
    }
    expect(
      tester.getSemantics(find.byType(ExampleSuggestedSimulationsText)).label,
      contains('Suggested simulation: aab.'),
    );
  });
}
