import '../algorithms/pda_simulator.dart';
import '../algorithms/tm_simulator.dart';
import '../models/pda.dart';
import '../models/tm.dart';
import '../models/tm_execution_analysis.dart';

enum SimulationOutcomeKind {
  accepted,
  rejected,
  provenCycle,
  boundedUnknown,
  timeout,
  configurationLimit,
  cancelled,
  failed,
}

class SimulationOutcome<T> {
  const SimulationOutcome({required this.kind, this.result, this.message});

  final SimulationOutcomeKind kind;
  final T? result;
  final String? message;
}

abstract class SimulationTask<T> {
  Future<SimulationOutcome<T>> get outcome;

  void cancel();
}

abstract class SimulationRunnerBackend {
  SimulationTask<PDASimulationResult> runPda(
    PDA pda,
    String inputString, {
    required bool stepByStep,
    required Duration timeout,
  });

  SimulationTask<TMSimulationResult> runTm(
    TM tm,
    String inputString, {
    required bool stepByStep,
    required Duration timeout,
  });
}

SimulationOutcome<PDASimulationResult> classifyPdaResult(
  PDASimulationResult result,
) {
  final message = result.errorMessage;
  final kind = result.accepted
      ? SimulationOutcomeKind.accepted
      : message == PDA_SIMULATION_TIMEOUT_ERROR
          ? SimulationOutcomeKind.timeout
          : message == PDA_SIMULATION_LIMIT_REACHED_ERROR ||
                  message == PDA_SIMULATION_INFINITE_LOOP_ERROR
              ? SimulationOutcomeKind.configurationLimit
              : SimulationOutcomeKind.rejected;
  return SimulationOutcome(kind: kind, result: result, message: message);
}

SimulationOutcome<TMSimulationResult> classifyTmResult(
  TMSimulationResult result,
) {
  final kind = switch (result.outcome) {
    TMExecutionOutcome.accepted => SimulationOutcomeKind.accepted,
    TMExecutionOutcome.haltedRejected => SimulationOutcomeKind.rejected,
    TMExecutionOutcome.provenCycle => SimulationOutcomeKind.provenCycle,
    TMExecutionOutcome.boundedUnknown => switch (result.limit) {
        TMExecutionLimit.timeout => SimulationOutcomeKind.timeout,
        TMExecutionLimit.configurations =>
          SimulationOutcomeKind.configurationLimit,
        TMExecutionLimit.steps || null => SimulationOutcomeKind.boundedUnknown,
      },
    TMExecutionOutcome.cancelled => SimulationOutcomeKind.cancelled,
    TMExecutionOutcome.invalidMachine => SimulationOutcomeKind.failed,
  };
  return SimulationOutcome(
    kind: kind,
    result: result,
    message: result.errorMessage,
  );
}
