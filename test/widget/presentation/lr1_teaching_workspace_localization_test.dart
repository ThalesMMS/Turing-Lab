import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/lr1_parser.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/production.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/widgets/lr1_teaching_workspace.dart';

// feature-localization-contract: grammar-analysis-parsing-and-teaching
// feature-localization-surface: responsive-accessibility
void main() {
  for (final scenario in const [
    (
      locale: Locale('en'),
      semanticLabel:
          'LR parser construction. Explore the selected item-set state, its lookahead actions, and any conflicting actions.',
    ),
    (
      locale: Locale('pt', 'BR'),
      semanticLabel:
          'Construção do analisador LR. Explore o estado selecionado, suas ações de antecipação e eventuais ações em conflito.',
    ),
  ]) {
    testWidgets('localizes the LR(1) state selector semantics in '
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
        final grammar = _lrGrammar();
        final construction = LR1Parser.build(grammar).construction!;
        final parseResult = LR1Parser.parse(
          grammar,
          'id',
          construction: construction,
        );

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
                padding: const EdgeInsets.all(8),
                child: LR1TeachingWorkspace(
                  grammar: grammar,
                  construction: construction,
                  parseResult: parseResult,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.bySemanticsLabel(scenario.semanticLabel), findsOneWidget);
        if (scenario.locale.languageCode == 'pt') {
          expect(find.text('Coleção canônica'), findsOneWidget);
          expect(find.text('Tabela ACTION / GOTO'), findsOneWidget);
          expect(
            find.text('Execução por deslocamento e redução'),
            findsOneWidget,
          );
          expect(find.text('Estado'), findsWidgets);
          expect(find.text('AÇÃO id'), findsOneWidget);
          expect(
            find.bySemanticsLabel('Canonical LR(1) item sets'),
            findsNothing,
          );
        } else {
          expect(find.text('Canonical collection'), findsOneWidget);
          expect(find.text('ACTION / GOTO table'), findsOneWidget);
          expect(find.text('Shift-reduce execution'), findsOneWidget);
          expect(find.text('State'), findsWidgets);
          expect(find.text('ACTION id'), findsOneWidget);
        }
        final formalProduction = find.byKey(
          const ValueKey('lr1-production-p0'),
        );
        expect(
          find.descendant(
            of: formalProduction,
            matching: find.text('p0: S → id'),
          ),
          findsOneWidget,
        );
        expect(
          Directionality.of(tester.element(formalProduction)),
          TextDirection.ltr,
        );
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    });
  }
}

Grammar _lrGrammar() => Grammar(
  id: 'lr1-localization',
  name: 'LR(1) localization',
  terminals: const {'id'},
  nonterminals: const {'S'},
  startSymbol: 'S',
  productions: {
    const Production(id: 'p0', leftSide: ['S'], rightSide: ['id']),
  },
  type: GrammarType.contextFree,
  created: DateTime.utc(2026),
  modified: DateTime.utc(2026),
);
