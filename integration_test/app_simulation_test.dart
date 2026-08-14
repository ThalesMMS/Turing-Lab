import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:turing_lab/data/data_sources/examples_asset_data_source.dart';
import 'package:turing_lab/main.dart' as app;
import 'package:turing_lab/presentation/providers/automaton_simulation_provider.dart';
import 'package:turing_lab/presentation/providers/automaton_state_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('loads example and runs simulations', (tester) async {
    SharedPreferences.setMockInitialValues(const {});

    app.main();
    await tester.pumpAndSettle();

    // Find MaterialApp to ensure the app is loaded
    final materialAppFinder = find.byType(MaterialApp);
    expect(
      materialAppFinder,
      findsOneWidget,
      reason: 'The MaterialApp should be available.',
    );

    // Get the ProviderScope container from any widget in the tree
    final container = ProviderScope.containerOf(
      tester.element(materialAppFinder),
      listen: false,
    );

    final examplesDataSource = ExamplesAssetDataSource();
    final exampleResult = await examplesDataSource.loadTypedFsaExample(
      'AFD - Termina com A',
    );
    expect(
      exampleResult.isSuccess,
      isTrue,
      reason: exampleResult.error ?? 'Expected example to load successfully.',
    );

    final automaton = exampleResult.data?.payload;
    expect(
      automaton,
      isNotNull,
      reason: 'The loaded example should contain an automaton.',
    );

    container.read(automatonStateProvider.notifier).updateAutomaton(automaton!);
    await tester.pumpAndSettle();

    // Open the simulation sheet through the quick action.
    final simulateAction = find.byTooltip('Simulate').first;
    await tester.tap(simulateAction);
    await tester.pumpAndSettle();

    final inputField = find.bySemanticsLabel('Simulation input string');
    expect(inputField, findsOneWidget);

    Future<void> runSimulation(String input, bool expectedAccepted) async {
      await tester.ensureVisible(inputField);
      await tester.pumpAndSettle();
      await tester.tap(inputField);
      await tester.enterText(inputField, input);
      await tester.pumpAndSettle();

      final simulateButton = find.widgetWithText(ElevatedButton, 'Simulate');
      expect(simulateButton, findsOneWidget);

      await tester.ensureVisible(simulateButton);
      await tester.pumpAndSettle();
      await tester.tap(simulateButton);

      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        final result =
            container.read(automatonSimulationProvider).simulationResult;
        if (result?.inputString == input) {
          expect(result!.accepted, expectedAccepted);
          return;
        }
      }

      final state = container.read(automatonSimulationProvider);
      fail(
        'Simulation for "$input" did not finish. '
        'Last result: ${state.simulationResult?.inputString}; '
        'loading: ${state.isLoading}; error: ${state.error}',
      );
    }

    await runSimulation('ba', true);
    await runSimulation('bb', false);
  });
}
