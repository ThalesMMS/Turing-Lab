import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:turing_lab/presentation/widgets/base_simulation_panel.dart';

Future<void> _pumpSharedSimulationWidget(
  WidgetTester tester,
  Widget child,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    ),
  );
}

void main() {
  group('Shared simulation panel scaffolding', () {
    testWidgets('renders header with icon and title', (tester) async {
      await _pumpSharedSimulationWidget(
        tester,
        const SimulationPanelHeader(
          title: 'PDA Simulation',
          icon: Icons.play_arrow,
        ),
      );

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.text('PDA Simulation'), findsOneWidget);
    });

    testWidgets('renders input section with supplied field slots', (
      tester,
    ) async {
      await _pumpSharedSimulationWidget(
        tester,
        const SimulationInputSection(
          title: 'Simulation Input',
          children: [
            TextField(
              decoration: InputDecoration(labelText: 'Input String'),
            ),
            SizedBox(height: 12),
            Text('Examples: 101, 111'),
          ],
        ),
      );

      expect(find.text('Simulation Input'), findsOneWidget);
      expect(find.text('Input String'), findsOneWidget);
      expect(find.text('Examples: 101, 111'), findsOneWidget);
    });

    testWidgets('disables run button and shows progress while simulating', (
      tester,
    ) async {
      var pressed = false;

      await _pumpSharedSimulationWidget(
        tester,
        SimulationRunButton(
          isSimulating: true,
          label: 'Simulate TM',
          simulatingLabel: 'Simulating...',
          onPressed: () => pressed = true,
        ),
      );

      expect(find.text('Simulating...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      final buttonFinder = find.ancestor(
        of: find.text('Simulating...'),
        matching: find.bySubtype<ButtonStyleButton>(),
      );
      final button = tester.widget<ButtonStyleButton>(buttonFinder);
      expect(button.onPressed, isNull);
      expect(pressed, isFalse);
    });

    testWidgets('renders result section with detail slot', (tester) async {
      await _pumpSharedSimulationWidget(
        tester,
        const SimulationResultsSection(
          title: 'Simulation Results',
          child: Text('Accepted in 12 ms'),
        ),
      );

      expect(find.text('Simulation Results'), findsOneWidget);
      expect(find.text('Accepted in 12 ms'), findsOneWidget);
    });

    testWidgets('renders accepted and rejected status cards', (tester) async {
      await _pumpSharedSimulationWidget(
        tester,
        const Column(
          children: [
            SimulationStatusCard(
              isAccepted: true,
              message: 'Accepted',
              children: [Text('Time: 10 ms')],
            ),
            SizedBox(height: 12),
            SimulationStatusCard(
              isAccepted: false,
              message: 'Rejected',
              children: [Text('No valid transition')],
            ),
          ],
        ),
      );

      expect(find.text('Accepted'), findsOneWidget);
      expect(find.text('Time: 10 ms'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('Rejected'), findsOneWidget);
      expect(find.text('No valid transition'), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsOneWidget);
    });

    testWidgets('renders empty result placeholder', (tester) async {
      await _pumpSharedSimulationWidget(
        tester,
        const SimulationEmptyResults(),
      );

      expect(find.byIcon(Icons.psychology), findsOneWidget);
      expect(find.text('No simulation results yet'), findsOneWidget);
      expect(
        find.text('Enter an input string and click Simulate to see results'),
        findsOneWidget,
      );
    });
  });
}
