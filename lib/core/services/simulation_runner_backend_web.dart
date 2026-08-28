import 'dart:async';

import '../algorithms/pda_simulator.dart';
import '../algorithms/tm_simulator.dart';
import '../models/pda.dart';
import '../models/tm.dart';
import '../simulation_cancelled_exception.dart';
import 'simulation_runner_models.dart';
import 'simulation_runner_messages.dart';

SimulationRunnerBackend createSimulationRunnerBackend() =>
    createWebSimulationRunnerBackend();

SimulationRunnerBackend createWebSimulationRunnerBackend() =>
    _WebSimulationRunnerBackend();

class _WebSimulationRunnerBackend implements SimulationRunnerBackend {
  @override
  SimulationTask<PDASimulationResult> runPda(
    PDA pda,
    String inputString, {
    required bool stepByStep,
    required Duration timeout,
  }) {
    return _WebSimulationTask((isCancelled) async {
      final result = await PDASimulator.simulateCooperative(
        pda,
        inputString,
        stepByStep: stepByStep,
        timeout: timeout,
        mode: pda.acceptanceMode,
        isCancelled: isCancelled,
      );
      return result.isSuccess
          ? classifyPdaResult(result.data!)
          : SimulationOutcome(
              kind: SimulationOutcomeKind.failed,
              message: result.error,
              structuredMessage:
                  result.structuredError ??
                  SimulationRunnerMessages.executionFailed(),
            );
    });
  }

  @override
  SimulationTask<TMSimulationResult> runTm(
    TM tm,
    String inputString, {
    required bool stepByStep,
    required Duration timeout,
  }) {
    return _WebSimulationTask((isCancelled) async {
      final result = await TMSimulator.simulateCooperative(
        tm,
        inputString,
        stepByStep: stepByStep,
        timeout: timeout,
        isCancelled: isCancelled,
      );
      return result.isSuccess
          ? classifyTmResult(result.data!)
          : SimulationOutcome(
              kind: SimulationOutcomeKind.failed,
              message: result.error,
              structuredMessage:
                  result.structuredError ??
                  SimulationRunnerMessages.executionFailed(),
            );
    });
  }
}

class _WebSimulationTask<T> implements SimulationTask<T> {
  _WebSimulationTask(
    Future<SimulationOutcome<T>> Function(bool Function() isCancelled) run,
  ) {
    scheduleMicrotask(() async {
      if (_cancelled) return;
      try {
        final result = await run(() => _cancelled);
        if (!_cancelled) _completer.complete(result);
      } on SimulationCancelledException {
        if (!_completer.isCompleted) {
          _completer.complete(
            const SimulationOutcome(kind: SimulationOutcomeKind.cancelled),
          );
        }
      } catch (error) {
        if (!_cancelled) {
          _completer.complete(
            SimulationOutcome(
              kind: SimulationOutcomeKind.failed,
              message: error.toString(),
              structuredMessage: SimulationRunnerMessages.executionFailed(),
            ),
          );
        }
      }
    });
  }

  final Completer<SimulationOutcome<T>> _completer = Completer();
  bool _cancelled = false;

  @override
  Future<SimulationOutcome<T>> get outcome => _completer.future;

  @override
  void cancel() {
    if (_completer.isCompleted) return;
    _cancelled = true;
    _completer.complete(
      const SimulationOutcome(kind: SimulationOutcomeKind.cancelled),
    );
  }
}
