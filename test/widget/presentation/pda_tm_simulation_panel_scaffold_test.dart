import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:turing_lab/core/models/state.dart' as automaton_state;
import 'package:turing_lab/core/models/pda.dart';
import 'package:turing_lab/core/models/tm.dart';
import 'package:turing_lab/core/algorithms/pda_simulator.dart';
import 'package:turing_lab/core/algorithms/tm_simulator.dart';
import 'package:turing_lab/core/services/simulation_runner.dart';
import 'package:turing_lab/presentation/providers/pda_editor_provider.dart';
import 'package:turing_lab/presentation/providers/tm_editor_provider.dart';
import 'package:turing_lab/presentation/widgets/pda_simulation_panel.dart';
import 'package:turing_lab/presentation/widgets/tm_simulation_panel.dart';

Future<void> _pumpPanel(
  WidgetTester tester,
  Widget panel, {
  List<Override> overrides = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 480,
            height: 720,
            child: panel,
          ),
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

Future<void> _pumpUntilText(WidgetTester tester, String text) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
    if (find.text(text).evaluate().isNotEmpty) return;
  }
}

class _PendingTask<T> implements SimulationTask<T> {
  final completer = Completer<SimulationOutcome<T>>();
  var cancelled = false;

  @override
  Future<SimulationOutcome<T>> get outcome => completer.future;

  @override
  void cancel() {
    cancelled = true;
  }
}

class _FakeSimulationBackend implements SimulationRunnerBackend {
  final pdaTasks = <_PendingTask<PDASimulationResult>>[];
  final tmTasks = <_PendingTask<TMSimulationResult>>[];

  @override
  SimulationTask<PDASimulationResult> runPda(
    PDA pda,
    String inputString, {
    required bool stepByStep,
    required Duration timeout,
  }) {
    final task = _PendingTask<PDASimulationResult>();
    pdaTasks.add(task);
    return task;
  }

  @override
  SimulationTask<TMSimulationResult> runTm(
    TM tm,
    String inputString, {
    required bool stepByStep,
    required Duration timeout,
  }) {
    final task = _PendingTask<TMSimulationResult>();
    tmTasks.add(task);
    return task;
  }
}

void main() {
  group('PDA/TM simulation panel shared scaffolding', () {
    testWidgets('PDA panel keeps stack-specific input slots', (tester) async {
      await _pumpPanel(tester, const PDASimulationPanel());

      expect(find.text('PDA Simulation'), findsOneWidget);
      expect(find.text('Simulation Input'), findsOneWidget);
      expect(find.text('Input String'), findsOneWidget);
      expect(
        find.text('Leave blank for ε; whitespace is preserved'),
        findsOneWidget,
      );
      expect(find.text('Initial Stack Symbol'), findsOneWidget);
      expect(find.text('Record step-by-step trace'), findsOneWidget);
      expect(find.text('Simulate PDA'), findsOneWidget);
      expect(find.text('Simulation Results'), findsOneWidget);
      expect(find.text('No simulation results yet'), findsOneWidget);
    });

    testWidgets('TM panel keeps tape-oriented input slots', (tester) async {
      await _pumpPanel(tester, const TMSimulationPanel());

      expect(find.text('TM Simulation'), findsOneWidget);
      expect(find.text('Simulation Input'), findsOneWidget);
      expect(find.text('Input String'), findsOneWidget);
      expect(
        find.text('Leave blank for ε; whitespace is preserved'),
        findsOneWidget,
      );
      expect(
        find.text('Examples: 101 (binary), 1100 (palindrome), 111 (counting)'),
        findsOneWidget,
      );
      expect(find.text('Simulate TM'), findsOneWidget);
      expect(find.text('Simulation Results'), findsOneWidget);
      expect(find.text('No simulation results yet'), findsOneWidget);
    });

    testWidgets('PDA panel simulates blank input as epsilon', (tester) async {
      final notifier = PDAEditorNotifier();
      notifier.updateFromCanvas(
        states: [
          automaton_state.State(
            id: 'q0',
            label: 'q0',
            position: Vector2.zero(),
            isInitial: true,
            isAccepting: true,
          ),
        ],
        transitions: const [],
      );

      await _pumpPanel(
        tester,
        const PDASimulationPanel(),
        overrides: [pdaEditorProvider.overrideWith((ref) => notifier)],
      );
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Simulate PDA'));
      await _pumpUntilText(tester, 'Accepted');

      expect(find.text('Accepted'), findsOneWidget);
      expect(find.text('Please enter an input string'), findsNothing);
    });

    testWidgets('TM panel simulates blank input as epsilon', (tester) async {
      final notifier = TMEditorNotifier();
      notifier.upsertState(
        id: 'q0',
        label: 'q0',
        x: 0,
        y: 0,
        isInitial: true,
        isAccepting: true,
      );

      await _pumpPanel(
        tester,
        const TMSimulationPanel(),
        overrides: [tmEditorProvider.overrideWith((ref) => notifier)],
      );
      await tester.tap(find.text('Simulate TM'));
      await _pumpUntilText(tester, 'Accepted');

      expect(find.text('Accepted'), findsOneWidget);
    });

    testWidgets('PDA simulation can be cancelled and ignores its stale result',
        (tester) async {
      final notifier = PDAEditorNotifier();
      notifier.updateFromCanvas(
        states: [
          automaton_state.State(
            id: 'q0',
            label: 'q0',
            position: Vector2.zero(),
            isInitial: true,
            isAccepting: true,
          ),
        ],
        transitions: const [],
      );
      final backend = _FakeSimulationBackend();
      final runner = SimulationRunner(backendOverride: backend);

      await _pumpPanel(
        tester,
        PDASimulationPanel(simulationRunner: runner),
        overrides: [pdaEditorProvider.overrideWith((ref) => notifier)],
      );
      await tester.tap(find.text('Simulate PDA'));
      await tester.pump();
      expect(find.text('Cancel simulation'), findsOneWidget);

      await tester.tap(find.text('Cancel simulation'));
      await tester.pump();
      expect(backend.pdaTasks.single.cancelled, isTrue);
      expect(find.text('Simulation cancelled'), findsOneWidget);

      await tester.tap(find.text('Simulate PDA'));
      await tester.pump();
      final latestTask = backend.pdaTasks.last;
      latestTask.completer.complete(
        SimulationOutcome(
          kind: SimulationOutcomeKind.accepted,
          result: PDASimulationResult.success(
            inputString: '',
            steps: const [],
            executionTime: Duration.zero,
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Accepted'), findsOneWidget);

      backend.pdaTasks.first.completer.complete(
        SimulationOutcome(
          kind: SimulationOutcomeKind.rejected,
          result: PDASimulationResult.failure(
            inputString: '',
            steps: const [],
            errorMessage: 'stale rejection',
            executionTime: Duration.zero,
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Accepted'), findsOneWidget);
      expect(find.text('stale rejection'), findsNothing);
    });

    testWidgets('TM simulation exposes cancellation', (tester) async {
      final notifier = TMEditorNotifier();
      notifier.upsertState(
        id: 'q0',
        label: 'q0',
        x: 0,
        y: 0,
        isInitial: true,
        isAccepting: true,
      );
      final backend = _FakeSimulationBackend();

      await _pumpPanel(
        tester,
        TMSimulationPanel(
          simulationRunner: SimulationRunner(backendOverride: backend),
        ),
        overrides: [tmEditorProvider.overrideWith((ref) => notifier)],
      );
      await tester.tap(find.text('Simulate TM'));
      await tester.pump();
      await tester.tap(find.text('Cancel simulation'));
      await tester.pump();

      expect(backend.tmTasks.single.cancelled, isTrue);
      expect(find.text('Simulation cancelled'), findsOneWidget);
    });
  });
}
