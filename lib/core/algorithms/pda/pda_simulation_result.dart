part of 'pda_simulator.dart';

// ignore_for_file: constant_identifier_names

const String PDA_SIMULATION_TIMEOUT_ERROR = 'Simulation timed out';
const String PDA_SIMULATION_INFINITE_LOOP_ERROR = 'Infinite loop detected';
const String PDA_SIMULATION_LIMIT_REACHED_ERROR =
    'Search limit reached before acceptance could be determined';
const String PDA_SIMULATION_DEPTH_LIMIT_ERROR =
    'Depth limit reached before acceptance could be determined';
const String PDA_SIMULATION_MEMORY_LIMIT_ERROR =
    'Memory limit reached before acceptance could be determined';
const String PDA_SIMULATION_STALE_REQUEST_ERROR =
    'Simulation result belongs to a stale request';

enum PDASimulationOutcome {
  accepted,
  rejected,
  timeout,
  configurationLimit,
  depthLimit,
  memoryLimit,
  provenCycle,
  staleRequest,
}

/// Result of simulating a PDA
class PDASimulationResult {
  final String inputString;
  final bool accepted;
  final PDASimulationOutcome outcome;
  final List<SimulationStep> steps;
  final String? errorMessage;

  /// Locale-neutral replacement for [errorMessage].
  final StructuredMessage? structuredMessage;
  final Duration executionTime;

  PDASimulationResult._({
    required this.inputString,
    required this.accepted,
    required this.outcome,
    required List<SimulationStep> steps,
    this.errorMessage,
    this.structuredMessage,
    required this.executionTime,
  }) : steps = List.unmodifiable(steps);

  factory PDASimulationResult.success({
    required String inputString,
    required List<SimulationStep> steps,
    required Duration executionTime,
    StructuredMessage? structuredMessage,
  }) {
    return PDASimulationResult._(
      inputString: inputString,
      accepted: true,
      outcome: PDASimulationOutcome.accepted,
      steps: steps,
      structuredMessage: structuredMessage,
      executionTime: executionTime,
    );
  }

  factory PDASimulationResult.failure({
    required String inputString,
    required List<SimulationStep> steps,
    required String errorMessage,
    required Duration executionTime,
    StructuredMessage? structuredMessage,
  }) {
    return PDASimulationResult._(
      inputString: inputString,
      accepted: false,
      outcome: PDASimulationOutcome.rejected,
      steps: steps,
      errorMessage: errorMessage,
      structuredMessage: structuredMessage,
      executionTime: executionTime,
    );
  }

  factory PDASimulationResult.timeout({
    required String inputString,
    required List<SimulationStep> steps,
    required Duration executionTime,
  }) {
    return PDASimulationResult._(
      inputString: inputString,
      accepted: false,
      outcome: PDASimulationOutcome.timeout,
      steps: steps,
      errorMessage: PDA_SIMULATION_TIMEOUT_ERROR,
      structuredMessage: PDASimulationMessages.timeout(),
      executionTime: executionTime,
    );
  }

  factory PDASimulationResult.infiniteLoop({
    required String inputString,
    required List<SimulationStep> steps,
    required Duration executionTime,
  }) {
    return PDASimulationResult._(
      inputString: inputString,
      accepted: false,
      outcome: PDASimulationOutcome.provenCycle,
      steps: steps,
      errorMessage: PDA_SIMULATION_INFINITE_LOOP_ERROR,
      structuredMessage: PDASimulationMessages.infiniteLoop(),
      executionTime: executionTime,
    );
  }

  factory PDASimulationResult.limitReached({
    required String inputString,
    required List<SimulationStep> steps,
    required Duration executionTime,
  }) {
    return PDASimulationResult._(
      inputString: inputString,
      accepted: false,
      outcome: PDASimulationOutcome.configurationLimit,
      steps: steps,
      errorMessage: PDA_SIMULATION_LIMIT_REACHED_ERROR,
      structuredMessage: PDASimulationMessages.configurationLimit(),
      executionTime: executionTime,
    );
  }

  factory PDASimulationResult.depthLimit({
    required String inputString,
    required List<SimulationStep> steps,
    required Duration executionTime,
  }) => PDASimulationResult._(
    inputString: inputString,
    accepted: false,
    outcome: PDASimulationOutcome.depthLimit,
    steps: steps,
    errorMessage: PDA_SIMULATION_DEPTH_LIMIT_ERROR,
    structuredMessage: PDASimulationMessages.depthLimit(),
    executionTime: executionTime,
  );

  factory PDASimulationResult.memoryLimit({
    required String inputString,
    required List<SimulationStep> steps,
    required Duration executionTime,
  }) => PDASimulationResult._(
    inputString: inputString,
    accepted: false,
    outcome: PDASimulationOutcome.memoryLimit,
    steps: steps,
    errorMessage: PDA_SIMULATION_MEMORY_LIMIT_ERROR,
    structuredMessage: PDASimulationMessages.memoryLimit(),
    executionTime: executionTime,
  );

  factory PDASimulationResult.staleRequest({
    required String inputString,
    required List<SimulationStep> steps,
    required Duration executionTime,
  }) => PDASimulationResult._(
    inputString: inputString,
    accepted: false,
    outcome: PDASimulationOutcome.staleRequest,
    steps: steps,
    errorMessage: PDA_SIMULATION_STALE_REQUEST_ERROR,
    structuredMessage: PDASimulationMessages.staleRequest(),
    executionTime: executionTime,
  );

  bool get isInconclusive => switch (outcome) {
    PDASimulationOutcome.timeout ||
    PDASimulationOutcome.configurationLimit ||
    PDASimulationOutcome.depthLimit ||
    PDASimulationOutcome.memoryLimit ||
    PDASimulationOutcome.staleRequest => true,
    _ => false,
  };

  PDASimulationResult copyWith({
    String? inputString,
    bool? accepted,
    PDASimulationOutcome? outcome,
    List<SimulationStep>? steps,
    String? errorMessage,
    StructuredMessage? structuredMessage,
    Duration? executionTime,
  }) {
    return PDASimulationResult._(
      inputString: inputString ?? this.inputString,
      accepted: accepted ?? this.accepted,
      outcome: outcome ?? this.outcome,
      steps: steps ?? this.steps,
      errorMessage: errorMessage ?? this.errorMessage,
      structuredMessage: structuredMessage ?? this.structuredMessage,
      executionTime: executionTime ?? this.executionTime,
    );
  }
}
