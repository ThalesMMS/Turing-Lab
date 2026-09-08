import '../algorithms/pda/pda_simulator.dart';
import '../algorithms/tm/tm_simulator.dart';
import '../models/pda.dart';
import '../models/tm.dart';
import 'simulation_runner_backend_stub.dart'
    if (dart.library.io) 'simulation_runner_backend_native.dart'
    if (dart.library.html) 'simulation_runner_backend_web.dart'
    as backend;
import 'simulation_runner_models.dart';

export 'simulation_runner_models.dart';

class SimulationRunner {
  SimulationRunner({SimulationRunnerBackend? backendOverride})
    : _backend = backendOverride ?? backend.createSimulationRunnerBackend();

  final SimulationRunnerBackend _backend;

  SimulationTask<PDASimulationResult> runPda(
    PDA pda,
    String inputString, {
    bool stepByStep = true,
    Duration timeout = const Duration(seconds: 5),
  }) {
    return _backend.runPda(
      pda,
      inputString,
      stepByStep: stepByStep,
      timeout: timeout,
    );
  }

  SimulationTask<TMSimulationResult> runTm(
    TM tm,
    String inputString, {
    bool stepByStep = true,
    Duration timeout = const Duration(seconds: 5),
  }) {
    return _backend.runTm(
      tm,
      inputString,
      stepByStep: stepByStep,
      timeout: timeout,
    );
  }
}
