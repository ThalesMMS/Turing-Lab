import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/grammar_transformation_step.dart';
import 'package:turing_lab/core/models/production.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/empty_string_notation.dart';
import 'package:turing_lab/presentation/widgets/grammar_transformation_history.dart';

void main() {
  testWidgets('localizes the visible and semantic transformation step number', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final grammar = Grammar.empty(
      id: 'grammar',
      name: 'Grammar',
      type: GrammarType.contextFree,
    );
    final step = GrammarTransformationStep(
      id: 'normalize-s',
      operation: 'Normalize S',
      rationale: '',
      before: grammar,
      after: grammar,
    );

    Widget app(Locale locale) => MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: SingleChildScrollView(
            child: GrammarTransformationHistory(
              steps: [step],
              onApplyGrammar: (_) {},
            ),
          ),
        ),
      ),
    );

    await tester.pumpWidget(app(const Locale('en')));

    expect(find.text('Step 1. Normalize S'), findsOneWidget);
    expect(
      tester.getSemantics(find.text('Step 1. Normalize S')).label,
      contains('Step 1. Normalize S'),
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(app(const Locale('pt', 'BR')));
    await tester.pump();

    expect(find.text('Passo 1. Normalize S'), findsOneWidget);
    expect(find.text('1. Normalize S'), findsNothing);
    expect(
      tester.getSemantics(find.text('Passo 1. Normalize S')).label,
      contains('Passo 1. Normalize S'),
    );
    expect(tester.takeException(), isNull);

    semantics.dispose();
  });

  testWidgets('renders an empty right side with the selected notation', (
    tester,
  ) async {
    final before = Grammar.empty(
      id: 'before',
      name: 'Before',
      type: GrammarType.contextFree,
    );
    final after = before.copyWith(
      id: 'after',
      productions: {
        const Production(
          id: 'empty',
          leftSide: ['S'],
          rightSide: [],
          isLambda: false,
        ),
      },
    );
    final step = GrammarTransformationStep(
      id: 'empty-step',
      operation: 'Keep empty production',
      rationale: '',
      before: before,
      after: after,
    );

    await tester.pumpWidget(
      EmptyStringNotation(
        symbol: kLambdaSymbol,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: GrammarTransformationHistory(
              steps: [step],
              onApplyGrammar: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Step 1. Keep empty production'));
    await tester.pumpAndSettle();

    expect(find.textContaining('S → λ'), findsOneWidget);
  });
}
