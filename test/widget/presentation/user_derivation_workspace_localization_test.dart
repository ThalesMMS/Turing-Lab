import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/grammar/phrase_structure/phrase_structure.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/widgets/user_derivation_workspace.dart';

// feature-localization-contract: grammar-analysis-parsing-and-teaching
// feature-localization-surface: localized-editor-fields
// feature-localization-surface: responsive-accessibility
void main() {
  testWidgets('localizes derivation controls and formats positions', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1100, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final scenario in const [
      (
        locale: Locale('en'),
        title: 'Derive target a',
        mode: 'Leftmost',
        position: 'Position 1,001',
      ),
      (
        locale: Locale('pt', 'BR'),
        title: 'Derive o alvo a',
        mode: 'Mais à esquerda',
        position: 'Posição 1.001',
      ),
    ]) {
      final grammar = _grammar();
      expect(PhraseGrammarClassifier.classify(grammar).isValid, isTrue);
      expect(
        PhraseProductionApplicator.allApplications(
          GrammarSymbolSequence(const [NonterminalGrammarSymbol('S')]),
          grammar.phraseProductions,
        ),
        hasLength(1),
      );
      await tester.pumpWidget(
        MaterialApp(
          locale: scenario.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: UserDerivationWorkspace(
                key: ValueKey(scenario.locale.toString()),
                grammar: grammar,
                target: GrammarSymbolSequence(const [
                  TerminalGrammarSymbol('a'),
                ]),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(scenario.title), findsOneWidget);
      expect(find.text(scenario.mode), findsOneWidget);
      expect(
        find.text(
          scenario.locale.languageCode == 'pt'
              ? 'Escolha o próximo passo da derivação.'
              : 'Choose the next derivation move.',
        ),
        findsOneWidget,
      );

      expect(
        tester
            .widget<ListTile>(
              find.byKey(const ValueKey('manual-production-prefix')),
            )
            .enabled,
        isTrue,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('manual-production-prefix')),
      );
      await tester.tap(find.byKey(const ValueKey('manual-production-prefix')));
      await tester.pumpAndSettle();
      expect(
        find.text(
          scenario.locale.languageCode == 'pt'
              ? 'Escolha a ocorrência exata'
              : 'Choose the exact occurrence',
        ),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('manual-occurrence-prefix-0')),
      );
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('manual-derivation-commit')),
      );
      await tester.tap(find.byKey(const ValueKey('manual-derivation-commit')));
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byKey(const ValueKey('manual-production-leaf')),
      );
      await tester.tap(find.byKey(const ValueKey('manual-production-leaf')));
      await tester.pump();
      expect(find.text(scenario.position), findsOneWidget);
      expect(
        find.text(
          scenario.locale.languageCode == 'pt'
              ? 'Derive target a'
              : 'Derive o alvo a',
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    }
  });
}

ContextFreeGrammar _grammar() {
  final prefix = <PhraseGrammarSymbol>[
    for (var index = 0; index < 1000; index++) const TerminalGrammarSymbol('a'),
    const NonterminalGrammarSymbol('A'),
  ];
  return ContextFreeGrammar(
    id: 'user-derivation-localization',
    name: 'User derivation localization',
    revision: 1,
    terminals: {const TerminalGrammarSymbol('a')},
    nonterminals: {
      const NonterminalGrammarSymbol('S'),
      const NonterminalGrammarSymbol('A'),
    },
    startSymbol: const NonterminalGrammarSymbol('S'),
    productions: [
      ContextFreeProduction(
        id: 'prefix',
        left: const NonterminalGrammarSymbol('S'),
        right: GrammarSymbolSequence(prefix),
        order: 0,
      ),
      ContextFreeProduction(
        id: 'leaf',
        left: const NonterminalGrammarSymbol('A'),
        right: GrammarSymbolSequence(const [TerminalGrammarSymbol('a')]),
        order: 1,
      ),
    ],
  );
}
