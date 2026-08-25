//
//  app_store_capture_simulation_notifier.dart
//  Turing Lab
//
//  Simulation notifier used only while capturing screenshots. The workspace
//  renders the measured execution time of a run, which varies by a millisecond
//  between otherwise identical runs, so the capture pins it to a frozen value
//  and keeps the rendered pixels stable.
//
//  Thales Matheus Mendonça Santos - August 2026
//
import 'package:turing_lab/presentation/providers/automaton_simulation_provider.dart';

/// Simulation notifier that reports a frozen execution time.
class AppStoreCaptureSimulationNotifier extends AutomatonSimulationNotifier {
  AppStoreCaptureSimulationNotifier({
    required super.ref,
    required super.tracePersistenceService,
  });

  /// Execution time every captured simulation reports.
  static const Duration frozenExecutionTime = Duration(milliseconds: 1);

  @override
  Future<void> simulateAutomaton(String inputString) async {
    await super.simulateAutomaton(inputString);
    final result = state.simulationResult;
    if (result == null) {
      return;
    }
    state = state.copyWith(
      simulationResult: result.copyWith(
        executionTime: frozenExecutionTime,
      ),
    );
  }
}
