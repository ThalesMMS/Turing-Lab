import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/pda_simulator.dart';
import 'package:turing_lab/core/algorithms/tm_simulator.dart';
import 'package:turing_lab/core/models/pda.dart';
import 'package:turing_lab/core/models/tm.dart';
import 'package:turing_lab/core/models/tm_acceptance.dart';
import 'package:turing_lab/core/services/simulation_runner.dart';
import 'package:turing_lab/presentation/providers/tm_editor_provider.dart';
import 'package:turing_lab/presentation/widgets/tm_simulation_panel.dart';

void main() {
  testWidgets('TM acceptance selector is labeled and persists in the document',
      (tester) async {
    final notifier = _notifier();
    await _pump(tester, notifier, width: 320);

    final control = find.byKey(const Key('tm-acceptance-policy-control'));
    expect(control, findsOneWidget);
    final semantics = tester.getSemantics(control);
    expect(semantics.label, contains('Turing machine acceptance policy'));
    expect(semantics.value, contains('Final state'));

    await tester.tap(control);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Halting').last);
    await tester.pumpAndSettle();

    expect(
      notifier.currentTm?.acceptancePolicy,
      TMAcceptancePolicy.halting,
    );
    expect(
      notifier.currentTm?.toJson()['acceptancePolicy'],
      'halting',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('TM acceptance selector fits a wide panel', (tester) async {
    await _pump(tester, _notifier(), width: 900);

    expect(
      find.byKey(const Key('tm-acceptance-policy-control')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('TM acceptance selector opens from the keyboard', (tester) async {
    await _pump(tester, _notifier(), width: 480);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(find.text('Halting'), findsWidgets);
    expect(find.text('Final state or halting'), findsWidgets);
  });

  testWidgets('TM acceptance selector follows external document changes',
      (tester) async {
    final notifier = _notifier();
    await _pump(tester, notifier, width: 480);

    expect(find.text('Final state'), findsOneWidget);

    notifier.setAcceptancePolicy(TMAcceptancePolicy.halting);
    await tester.pumpAndSettle();

    expect(find.text('Halting'), findsOneWidget);
    expect(find.text('Final state'), findsNothing);
  });

  testWidgets('bounded TM result is inconclusive rather than rejected',
      (tester) async {
    final result = TMSimulationResult.stepLimit(
      inputString: '',
      steps: const [],
      executionTime: Duration.zero,
    );
    final runner = SimulationRunner(
      backendOverride: _CompletedSimulationBackend(result),
    );
    await _pump(tester, _notifier(), width: 480, runner: runner);

    await tester.tap(find.text('Simulate TM'));
    await tester.pumpAndSettle();

    expect(find.textContaining('inconclusive'), findsOneWidget);
    expect(find.textContaining('Rejected'), findsNothing);
  });
}

TMEditorNotifier _notifier() {
  final notifier = TMEditorNotifier();
  notifier.upsertState(
    id: 'q0',
    label: 'q0',
    x: 0,
    y: 0,
    isInitial: true,
  );
  return notifier;
}

Future<void> _pump(
  WidgetTester tester,
  TMEditorNotifier notifier, {
  required double width,
  SimulationRunner? runner,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [tmEditorProvider.overrideWith((ref) => notifier)],
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: width,
            height: 900,
            child: SingleChildScrollView(
              child: TMSimulationPanel(simulationRunner: runner),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _CompletedSimulationBackend implements SimulationRunnerBackend {
  _CompletedSimulationBackend(this.result);

  final TMSimulationResult result;

  @override
  SimulationTask<PDASimulationResult> runPda(
    PDA pda,
    String inputString, {
    required bool stepByStep,
    required Duration timeout,
  }) {
    throw UnimplementedError();
  }

  @override
  SimulationTask<TMSimulationResult> runTm(
    TM tm,
    String inputString, {
    required bool stepByStep,
    required Duration timeout,
  }) =>
      _CompletedTask(classifyTmResult(result));
}

class _CompletedTask<T> implements SimulationTask<T> {
  const _CompletedTask(this.value);

  final SimulationOutcome<T> value;

  @override
  Future<SimulationOutcome<T>> get outcome async => value;

  @override
  void cancel() {}
}
