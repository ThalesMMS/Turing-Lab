import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:turing_lab/core/algorithms/tm_messages.dart';
import 'package:turing_lab/core/models/step_explanation.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/widgets/step_explanation_card.dart';

void main() {
  testWidgets('StepExplanationCard renders title, bullets, and suggested fixes', (
    tester,
  ) async {
    const explanation = StepExplanation(
      title: 'Why this step happened',
      bullets: ['Consumed symbol: a', 'Transition taken: q0 → q1'],
      suggestedFixes: [
        SuggestedFix(
          label: 'Add a missing transition',
          details:
              'If no transition matches the input symbol, the automaton halts.',
        ),
      ],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Material(child: StepExplanationCard(explanation: explanation)),
      ),
    );

    expect(find.text('Why this step happened'), findsOneWidget);
    expect(find.text('Consumed symbol: a'), findsOneWidget);
    expect(find.text('Transition taken: q0 → q1'), findsOneWidget);
    expect(find.text('Suggested fixes'), findsOneWidget);
    expect(find.text('Add a missing transition'), findsOneWidget);
    expect(
      find.text(
        'If no transition matches the input symbol, the automaton halts.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'StepExplanationCard uses fallbackText when explanation is empty',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Material(
            child: StepExplanationCard(
              explanation: null,
              fallbackText: 'Legacy explanation text',
            ),
          ),
        ),
      );

      expect(find.text('Explanation'), findsOneWidget);
      expect(find.text('Legacy explanation text'), findsOneWidget);
    },
  );

  testWidgets('StepExplanationCard collapses when there is nothing to show', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Material(child: StepExplanationCard(explanation: null)),
      ),
    );

    expect(find.byType(Card), findsNothing);
    expect(find.byType(StepExplanationCard), findsOneWidget);
  });

  testWidgets('StepExplanationCard resolves structured TM messages', (
    tester,
  ) async {
    final explanation = StepExplanation(
      titleMessage: TmSimulationMessages.transitionTitle(),
      bulletMessages: [
        TmSimulationMessages.readSymbol(symbol: 'a', position: 0, state: 'q0'),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Material(child: StepExplanationCard(explanation: explanation)),
      ),
    );

    expect(find.text('Transição da máquina de Turing'), findsOneWidget);
    expect(find.textContaining('Leu a na posição 0'), findsOneWidget);
    expect(find.textContaining('tm.simulation.'), findsNothing);
  });
}
