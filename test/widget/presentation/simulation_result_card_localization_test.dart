import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/automaton_simulation_messages.dart';
import 'package:turing_lab/core/models/simulation_result.dart';
import 'package:turing_lab/core/models/simulation_step.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/widgets/common/simulation_result_card.dart';

void main() {
  testWidgets('formats fractional execution seconds for Portuguese', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt', 'BR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SimulationResultCard(
            result: SimulationResult.success(
              inputString: 'a',
              steps: const [],
              executionTime: const Duration(milliseconds: 1234),
            ),
          ),
        ),
      ),
    );

    expect(find.text('1,23s'), findsOneWidget);
    expect(find.text('1.23s'), findsNothing);
  });

  testWidgets('formats simulation counts for Portuguese', (tester) async {
    final steps = List<SimulationStep>.generate(
      1234,
      (index) => SimulationStep(
        currentState: 'q$index',
        remainingInput: '',
        stepNumber: index,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt', 'BR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SimulationResultCard(
            result: SimulationResult.success(
              inputString: '',
              steps: steps,
              executionTime: Duration.zero,
            ),
            showPathVisualization: false,
            showTransitionSequence: false,
          ),
        ),
      ),
    );

    expect(find.text('1.234'), findsWidgets);
    expect(find.text('1234'), findsNothing);
  });

  testWidgets('renders a structured-only simulation failure', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt', 'BR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SimulationResultCard(
            result: SimulationResult.structuredFailure(
              inputString: 'a',
              steps: const [],
              message: AutomatonSimulationMessages.missingInitialState(),
              compatibilityErrorMessage: '',
              executionTime: Duration.zero,
            ),
          ),
        ),
      ),
    );

    expect(find.text('O autômato deve ter um estado inicial.'), findsOneWidget);
    expect(
      find.text('automaton.simulation.missing-initial-state'),
      findsNothing,
    );
  });
}
