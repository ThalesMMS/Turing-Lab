//
//  simulation_panel_goldens_test.dart
//  Turing Lab
//
//  Testes golden de regressão visual para o painel de simulação, capturando
//  snapshots de estados críticos: painel vazio, resultados aceitos/rejeitados,
//  modo passo-a-passo, resultados de regex, e layouts responsivos. Garante
//  consistência visual da interface de simulação entre mudanças e detecta
//  regressões automáticas.
//
//  Thales Matheus Mendonça Santos - January 2026
//

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

import 'package:turing_lab/core/models/simulation_result.dart';
import 'package:turing_lab/core/models/simulation_step.dart';
import 'package:turing_lab/core/models/simulation_highlight.dart';
import 'package:turing_lab/core/services/simulation_highlight_service.dart';
import 'package:turing_lab/presentation/widgets/simulation_panel.dart';

class _TestSimulationHighlightService extends SimulationHighlightService {
  @override
  SimulationHighlight emitFromSteps(
    List<SimulationStep> steps,
    int currentIndex,
  ) {
    return super.emitFromSteps(steps, currentIndex);
  }
}

class _SimulationCallback {
  void call(String input) {}
}

Future<void> _pumpSimulationPanel(
  WidgetTester tester, {
  SimulationResult? simulationResult,
  String? regexResult,
  Size size = const Size(800, 600),
}) async {
  final callback = _SimulationCallback();
  final highlightService = _TestSimulationHighlightService();

  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;

  await tester.pumpWidgetBuilder(
    ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: SimulationPanel(
            onSimulate: callback.call,
            simulationResult: simulationResult,
            regexResult: regexResult,
            highlightService: highlightService,
            animationSpeed: 1.0,
            onAnimationSpeedChanged: (_) {},
          ),
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

void _invokeEnabledNextStep(WidgetTester tester) {
  final nextButton = tester
      .widgetList<IconButton>(find.widgetWithIcon(IconButton, Icons.skip_next))
      .firstWhere((button) => button.onPressed != null);
  nextButton.onPressed!.call();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SimulationPanel golden tests', () {
    testGoldens('renders empty panel in desktop layout', (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpSimulationPanel(tester, size: const Size(800, 600));

      await screenMatchesGolden(tester, 'simulation_panel_empty_desktop');
    });

    testGoldens('renders empty panel in tablet layout', (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpSimulationPanel(tester, size: const Size(600, 800));

      await screenMatchesGolden(tester, 'simulation_panel_empty_tablet');
    });

    testGoldens('renders empty panel in mobile layout', (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpSimulationPanel(tester, size: const Size(400, 700));

      await screenMatchesGolden(tester, 'simulation_panel_empty_mobile');
    });

    testGoldens('renders accepted simulation result', (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final result = SimulationResult.success(
        inputString: 'abc',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            remainingInput: 'abc',
            stepNumber: 0,
          ),
          const SimulationStep(
            currentState: 'q1',
            remainingInput: 'bc',
            stepNumber: 1,
            usedTransition: 'a',
          ),
          const SimulationStep(
            currentState: 'q2',
            remainingInput: 'c',
            stepNumber: 2,
            usedTransition: 'b',
          ),
          const SimulationStep(
            currentState: 'q3',
            remainingInput: '',
            stepNumber: 3,
            usedTransition: 'c',
          ),
        ],
        executionTime: const Duration(milliseconds: 150),
      );

      await _pumpSimulationPanel(
        tester,
        simulationResult: result,
        size: const Size(800, 600),
      );

      await screenMatchesGolden(tester, 'simulation_panel_accepted');
    });

    testGoldens('renders rejected simulation result with error', (
      tester,
    ) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final result = SimulationResult.failure(
        inputString: 'xyz',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            remainingInput: 'xyz',
            stepNumber: 0,
          ),
          const SimulationStep(
            currentState: 'q1',
            remainingInput: 'yz',
            stepNumber: 1,
            usedTransition: 'x',
          ),
        ],
        errorMessage: 'No valid transition found',
        executionTime: const Duration(milliseconds: 75),
      );

      await _pumpSimulationPanel(
        tester,
        simulationResult: result,
        size: const Size(800, 600),
      );

      await screenMatchesGolden(tester, 'simulation_panel_rejected');
    });

    testGoldens('renders regex result', (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpSimulationPanel(
        tester,
        regexResult: 'a(b|c)*d',
        size: const Size(800, 600),
      );

      await screenMatchesGolden(tester, 'simulation_panel_regex_result');
    });

    testGoldens('renders step-by-step mode at first step', (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final result = SimulationResult.success(
        inputString: 'ab',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            remainingInput: 'ab',
            stepNumber: 0,
          ),
          const SimulationStep(
            currentState: 'q1',
            remainingInput: 'b',
            stepNumber: 1,
            usedTransition: 'a',
          ),
          const SimulationStep(
            currentState: 'q2',
            remainingInput: '',
            stepNumber: 2,
            usedTransition: 'b',
          ),
        ],
        executionTime: const Duration(milliseconds: 100),
      );

      await _pumpSimulationPanel(
        tester,
        simulationResult: result,
        size: const Size(800, 700),
      );

      // Enable step-by-step mode
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'simulation_panel_step_mode_first');
    });

    testGoldens('renders step-by-step mode at middle step', (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final result = SimulationResult.success(
        inputString: 'ab',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            remainingInput: 'ab',
            stepNumber: 0,
          ),
          const SimulationStep(
            currentState: 'q1',
            remainingInput: 'b',
            stepNumber: 1,
            usedTransition: 'a',
          ),
          const SimulationStep(
            currentState: 'q2',
            remainingInput: '',
            stepNumber: 2,
            usedTransition: 'b',
          ),
        ],
        executionTime: const Duration(milliseconds: 100),
      );

      await _pumpSimulationPanel(
        tester,
        simulationResult: result,
        size: const Size(800, 700),
      );

      // Enable step-by-step mode
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // Go to next step
      _invokeEnabledNextStep(tester);
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'simulation_panel_step_mode_middle');
    });

    testGoldens('renders step-by-step mode at final step', (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final result = SimulationResult.success(
        inputString: 'ab',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            remainingInput: 'ab',
            stepNumber: 0,
          ),
          const SimulationStep(
            currentState: 'q1',
            remainingInput: 'b',
            stepNumber: 1,
            usedTransition: 'a',
          ),
          const SimulationStep(
            currentState: 'q2',
            remainingInput: '',
            stepNumber: 2,
            usedTransition: 'b',
          ),
        ],
        executionTime: const Duration(milliseconds: 100),
      );

      await _pumpSimulationPanel(
        tester,
        simulationResult: result,
        size: const Size(800, 700),
      );

      // Enable step-by-step mode
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // Go to last step
      _invokeEnabledNextStep(tester);
      await tester.pumpAndSettle();
      _invokeEnabledNextStep(tester);
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'simulation_panel_step_mode_final');
    });

    testGoldens('renders epsilon transition in step-by-step mode', (
      tester,
    ) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final result = SimulationResult.success(
        inputString: '',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            remainingInput: '',
            stepNumber: 0,
          ),
          const SimulationStep(
            currentState: 'q1',
            remainingInput: '',
            stepNumber: 1,
            usedTransition: '',
          ),
        ],
        executionTime: const Duration(milliseconds: 50),
      );

      await _pumpSimulationPanel(
        tester,
        simulationResult: result,
        size: const Size(800, 700),
      );

      // Enable step-by-step mode
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'simulation_panel_epsilon');
    });

    testGoldens('renders accepted result in mobile layout', (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final result = SimulationResult.success(
        inputString: 'abc',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            remainingInput: 'abc',
            stepNumber: 0,
          ),
          const SimulationStep(
            currentState: 'q1',
            remainingInput: '',
            stepNumber: 1,
          ),
        ],
        executionTime: const Duration(milliseconds: 100),
      );

      await _pumpSimulationPanel(
        tester,
        simulationResult: result,
        size: const Size(400, 700),
      );

      await screenMatchesGolden(tester, 'simulation_panel_accepted_mobile');
    });

    testGoldens('renders rejected result in tablet layout', (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final result = SimulationResult.failure(
        inputString: 'xyz',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            remainingInput: 'xyz',
            stepNumber: 0,
          ),
        ],
        errorMessage: 'Invalid input symbol',
        executionTime: const Duration(milliseconds: 50),
      );

      await _pumpSimulationPanel(
        tester,
        simulationResult: result,
        size: const Size(600, 800),
      );

      await screenMatchesGolden(tester, 'simulation_panel_rejected_tablet');
    });
  });
}
