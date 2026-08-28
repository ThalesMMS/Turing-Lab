import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/grammar_parser.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/providers/grammar_provider.dart';
import 'package:turing_lab/presentation/widgets/grammar_simulation_panel.dart';

// feature-localization-contract: grammar-analysis-parsing-and-teaching
// feature-localization-surface: localized-editor-fields
// feature-localization-surface: responsive-accessibility
void main() {
  testWidgets('grammar batch parsing controls follow the active locale', (
    tester,
  ) async {
    final grammar = GrammarProvider()
      ..addProduction(leftSide: ['S'], rightSide: const ['a']);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [grammarProvider.overrideWith((ref) => grammar)],
        child: const MaterialApp(
          locale: Locale('pt', 'BR'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: GrammarSimulationPanel(useExpanded: false),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Análise em lote'), findsOneWidget);
    await tester.ensureVisible(find.text('Análise em lote'));
    await tester.tap(find.text('Análise em lote'));
    await tester.pumpAndSettle();

    expect(find.text('Execução em lote de gramáticas'), findsOneWidget);
    expect(find.textContaining('Automático (Earley)'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('batch-configuration')));
    await tester.tap(find.byKey(const Key('batch-configuration')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('batch-strategy')));
    await tester.tap(find.byKey(const Key('batch-strategy')));
    await tester.pumpAndSettle();
    expect(find.text('Força bruta'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('formats rejected parser positions in English and Portuguese', (
    tester,
  ) async {
    final grammar = GrammarProvider()
      ..addProduction(leftSide: ['S'], rightSide: const ['a']);
    final panelKey = GlobalKey();
    final input = List<String>.filled(1234, 'a').join();

    Future<void> pump(Locale locale) {
      return tester.pumpWidget(
        ProviderScope(
          overrides: [grammarProvider.overrideWith((ref) => grammar)],
          child: MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SingleChildScrollView(
                child: GrammarSimulationPanel(
                  key: panelKey,
                  useExpanded: false,
                ),
              ),
            ),
          ),
        ),
      );
    }

    await pump(const Locale('en'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<ParsingStrategyHint>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('LL(1)').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('grammar-parser-input')),
      input,
    );
    await tester.tap(find.text('Parse String'));
    for (var attempt = 0; attempt < 100; attempt++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump(const Duration(milliseconds: 50));
      if (find.text('Farthest position: 1 / 1,234').evaluate().isNotEmpty) {
        break;
      }
    }
    expect(find.text('Farthest position: 1 / 1,234'), findsOneWidget);

    await pump(const Locale('pt', 'BR'));
    await tester.pump();
    expect(find.text('Posição mais distante: 1 / 1.234'), findsOneWidget);
  });

  testWidgets('LL parse-table cell semantics follow the active locale', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    tester.view
      ..physicalSize = const Size(320, 700)
      ..devicePixelRatio = 1;
    addTearDown(() {
      tester.view
        ..resetPhysicalSize()
        ..resetDevicePixelRatio();
    });

    final grammar = GrammarProvider()
      ..addProduction(leftSide: ['S'], rightSide: const ['a']);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [grammarProvider.overrideWith((ref) => grammar)],
        child: const MaterialApp(
          locale: Locale('pt', 'BR'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: GrammarSimulationPanel(useExpanded: false),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(DropdownButtonFormField<ParsingStrategyHint>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('LL(1)').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('grammar-parser-input')),
      'a',
    );
    final parseButton = find.text('Analisar cadeia');
    await tester.ensureVisible(parseButton);
    await tester.tap(parseButton);
    for (var attempt = 0; attempt < 100; attempt++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump(const Duration(milliseconds: 50));
      if (find.byKey(const ValueKey('ll1-cell-S-a')).evaluate().isNotEmpty) {
        break;
      }
    }

    final cellSemantics = tester.getSemantics(
      find.byKey(const ValueKey('ll1-cell-S-a')),
    );
    expect(cellSemantics.label, contains('Célula da tabela'));
    expect(cellSemantics.label, isNot(contains('Table cell')));
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}
