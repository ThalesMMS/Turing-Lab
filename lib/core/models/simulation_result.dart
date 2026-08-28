//
//  simulation_result.dart
//  Turing Lab
//
//  Models automaton simulation results, storing input, acceptance, detailed
//  steps, error messages, and execution metrics. Offers factories for
//  different scenarios (success, failure, timeout, or loop) plus
//  serialization utilities and helper analyses used in panels.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:collection/collection.dart';

import '../messages/structured_message.dart';
import 'nfa_computation_tree.dart';
import 'simulation_step.dart';

class SimulationResult {
  static const schemaVersion = 2;
  static const ListEquality<SimulationStep> _stepEquality =
      ListEquality<SimulationStep>();

  final String inputString;
  final bool accepted;
  bool get isAccepted => accepted;
  final List<SimulationStep> steps;
  final String errorMessage;
  final StructuredMessage? message;
  final Duration executionTime;
  final NFAComputationTree? computationTree;
  final bool _usesLegacyMessagePayload;

  SimulationResult._({
    required this.inputString,
    required this.accepted,
    required List<SimulationStep> steps,
    this.errorMessage = '',
    this.message,
    required this.executionTime,
    this.computationTree,
    bool usesLegacyMessagePayload = false,
  }) : steps = List<SimulationStep>.unmodifiable(steps),
       _usesLegacyMessagePayload = usesLegacyMessagePayload;

  factory SimulationResult.success({
    required String inputString,
    required List<SimulationStep> steps,
    required Duration executionTime,
    NFAComputationTree? computationTree,
  }) {
    return SimulationResult._(
      inputString: inputString,
      accepted: true,
      steps: steps,
      message: null,
      executionTime: executionTime,
      computationTree: computationTree,
    );
  }

  factory SimulationResult.failure({
    required String inputString,
    required List<SimulationStep> steps,
    required String errorMessage,
    required Duration executionTime,
    NFAComputationTree? computationTree,
  }) {
    return SimulationResult._(
      inputString: inputString,
      accepted: false,
      steps: steps,
      errorMessage: errorMessage,
      message: _legacyFailureMessage,
      executionTime: executionTime,
      computationTree: computationTree,
      usesLegacyMessagePayload: true,
    );
  }

  /// Creates a failure whose persisted form contains only semantic data.
  factory SimulationResult.structuredFailure({
    required String inputString,
    required List<SimulationStep> steps,
    required StructuredMessage message,
    required Duration executionTime,
    String? compatibilityErrorMessage,
    NFAComputationTree? computationTree,
  }) {
    return SimulationResult._(
      inputString: inputString,
      accepted: false,
      steps: steps,
      errorMessage: compatibilityErrorMessage ?? message.stableCode,
      message: message,
      executionTime: executionTime,
      computationTree: computationTree,
    );
  }

  factory SimulationResult.timeout({
    required String inputString,
    required List<SimulationStep> steps,
    required Duration executionTime,
    NFAComputationTree? computationTree,
  }) {
    return SimulationResult._(
      inputString: inputString,
      accepted: false,
      steps: steps,
      errorMessage:
          'Simulation timed out after ${executionTime.inSeconds} seconds',
      message: _timeoutMessage(executionTime),
      executionTime: executionTime,
      computationTree: computationTree,
    );
  }

  factory SimulationResult.infiniteLoop({
    required String inputString,
    required List<SimulationStep> steps,
    required Duration executionTime,
    NFAComputationTree? computationTree,
  }) {
    return SimulationResult._(
      inputString: inputString,
      accepted: false,
      steps: steps,
      errorMessage: 'Infinite loop detected after ${steps.length} steps',
      message: _provenCycleMessage(steps.length),
      executionTime: executionTime,
      computationTree: computationTree,
    );
  }

  /// Creates a copy of this simulation result with updated properties
  SimulationResult copyWith({
    String? inputString,
    bool? accepted,
    List<SimulationStep>? steps,
    String? errorMessage,
    StructuredMessage? message,
    Duration? executionTime,
    NFAComputationTree? computationTree,
  }) {
    return SimulationResult._(
      inputString: inputString ?? this.inputString,
      accepted: accepted ?? this.accepted,
      steps: steps ?? this.steps,
      errorMessage: errorMessage ?? this.errorMessage,
      message: message ?? this.message,
      executionTime: executionTime ?? this.executionTime,
      computationTree: computationTree ?? this.computationTree,
      usesLegacyMessagePayload: _usesLegacyMessagePayload && message == null,
    );
  }

  /// Converts the simulation result to a JSON representation
  Map<String, dynamic> toJson() {
    final shared = <String, dynamic>{
      'inputString': inputString,
      'accepted': accepted,
      'steps': steps.map((s) => s.toJson()).toList(),
      'executionTime': executionTime.inMilliseconds,
    };
    if (computationTree != null) {
      shared['computationTree'] = computationTree!.toJson();
    }
    if (_usesLegacyMessagePayload) {
      return {...shared, 'errorMessage': errorMessage};
    }
    return {
      'schemaVersion': schemaVersion,
      ...shared,
      'message': message?.toJson(),
    };
  }

  /// Persistence boundary used by trace history and current-trace restore.
  ///
  /// Legacy instances intentionally retain their legacy JSON until their
  /// producer has been migrated to structured messages.
  Map<String, dynamic> toPersistedJson() => toJson();

  bool get usesLegacyText =>
      _usesLegacyMessagePayload ||
      steps.any((step) => step.usesLegacyText) ||
      (computationTree?.errorMessage.isNotEmpty ?? false) &&
          computationTree?.structuredMessage == null;

  /// Creates a simulation result from a JSON representation
  factory SimulationResult.fromJson(Map<String, dynamic> json) {
    final version = json['schemaVersion'];
    if (version != null && version != schemaVersion) {
      throw FormatException('Unsupported simulation-result version: $version.');
    }
    final steps = (json['steps'] as List)
        .map((s) => SimulationStep.fromJson(s as Map<String, dynamic>))
        .toList();
    final executionTime = Duration(milliseconds: json['executionTime'] as int);
    final legacyError = version == null
        ? json['errorMessage'] as String? ?? ''
        : '';
    final message = json['message'] is Map
        ? StructuredMessage.fromJson(
            Map<String, Object?>.from(json['message'] as Map),
          )
        : _migrateLegacyError(
            legacyError,
            executionTime: executionTime,
            stepCount: steps.length,
          );
    return SimulationResult._(
      inputString: json['inputString'] as String,
      accepted: json['accepted'] as bool,
      steps: steps,
      errorMessage: version == null
          ? legacyError
          : _compatibilityTextFor(message),
      message: message,
      executionTime: executionTime,
      computationTree: json['computationTree'] != null
          ? NFAComputationTree.fromJson(
              json['computationTree'] as Map<String, dynamic>,
            )
          : null,
      usesLegacyMessagePayload: version == null && legacyError.isNotEmpty,
    );
  }

  factory SimulationResult.fromPersistedJson(Map<String, dynamic> json) =>
      SimulationResult.fromJson(json);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SimulationResult &&
        other.inputString == inputString &&
        other.accepted == accepted &&
        _stepEquality.equals(other.steps, steps) &&
        other._usesLegacyMessagePayload == _usesLegacyMessagePayload &&
        (!_usesLegacyMessagePayload || other.errorMessage == errorMessage) &&
        other.message == message &&
        other.executionTime == executionTime &&
        other.computationTree == computationTree;
  }

  @override
  int get hashCode {
    return Object.hash(
      inputString,
      accepted,
      _stepEquality.hash(steps),
      _usesLegacyMessagePayload,
      _usesLegacyMessagePayload ? errorMessage : null,
      message,
      executionTime,
      computationTree,
    );
  }

  @override
  String toString() {
    return 'SimulationResult(inputString: $inputString, accepted: $accepted, steps: ${steps.length}, executionTime: $executionTime)';
  }

  /// Gets the number of simulation steps
  int get stepCount => steps.length;

  /// Gets the first step of the simulation
  SimulationStep? get firstStep => steps.isNotEmpty ? steps.first : null;

  /// Gets the last step of the simulation
  SimulationStep? get lastStep => steps.isNotEmpty ? steps.last : null;

  /// Gets the final state of the simulation
  String? get finalState => lastStep?.currentState;

  /// Gets the remaining input after simulation
  String get remainingInput => lastStep?.remainingInput ?? '';

  /// Checks if the simulation was successful
  bool get isSuccessful => accepted && errorMessage.isEmpty;

  /// Checks if the simulation failed
  bool get isFailed => !accepted || errorMessage.isNotEmpty;

  /// Checks if the simulation timed out
  bool get isTimeout {
    if (message?.stableCode == 'simulation.timeout') return true;
    final normalizedError = errorMessage.toLowerCase();
    return normalizedError.contains('timeout') ||
        normalizedError.contains('timed out');
  }

  /// Checks if the simulation had an infinite loop
  bool get isInfiniteLoop =>
      message?.stableCode == 'simulation.proven-cycle' ||
      errorMessage.contains('infinite loop') ||
      errorMessage.contains('Infinite loop');

  /// Gets a detailed explanation of why the string was rejected.
  ///
  /// This method analyzes the simulation result and provides an educational
  /// explanation of the rejection reason, helping students understand the
  /// automaton's behavior.
  ///
  /// Returns an empty string if the simulation was accepted or if there's
  /// already a custom error message (timeout, infinite loop, etc.).
  String get rejectionReason {
    // If accepted, no rejection reason
    if (accepted) {
      return '';
    }

    // If there's already a specific error message, use it
    if (errorMessage.isNotEmpty) {
      return errorMessage;
    }

    // If there are no steps, we couldn't start the simulation
    if (steps.isEmpty) {
      return 'No simulation steps recorded';
    }

    final lastStep = steps.last;
    final hasRemainingInput = lastStep.remainingInput.isNotEmpty;
    final currentState = lastStep.currentState;

    // Case 1: Got stuck with remaining input (no valid transition)
    if (hasRemainingInput) {
      final nextSymbol = lastStep.remainingInput.isNotEmpty
          ? lastStep.remainingInput[0]
          : '';

      if (nextSymbol.isNotEmpty) {
        return 'No valid transition from state $currentState on symbol \'$nextSymbol\'. '
            'Input remaining: \'${lastStep.remainingInput}\'';
      } else {
        return 'Stuck at state $currentState with ${lastStep.remainingInput.length} '
            'symbol(s) remaining';
      }
    }

    // Case 2: Consumed all input but ended in non-accepting state
    if (!hasRemainingInput) {
      return 'Input fully consumed but ended in non-accepting state $currentState';
    }

    // Default case
    return 'String rejected by automaton';
  }

  /// Gets the execution time in milliseconds
  int get executionTimeMs => executionTime.inMilliseconds;

  /// Gets the execution time in seconds
  double get executionTimeSeconds => executionTime.inMicroseconds / 1000000.0;

  /// Gets all states visited during the simulation
  Set<String> get visitedStates {
    return steps.map((step) => step.currentState).toSet();
  }

  /// Gets all transitions used during the simulation
  Set<String> get usedTransitions {
    return steps
        .where((step) => step.usedTransition != null)
        .map((step) => step.usedTransition!)
        .toSet();
  }

  /// Gets the path taken during the simulation
  List<String> get path {
    return steps.map((step) => step.currentState).toList();
  }

  /// Gets the sequence of transitions used
  List<String> get transitionSequence {
    return steps
        .where((step) => step.usedTransition != null)
        .map((step) => step.usedTransition!)
        .toList();
  }

  /// Gets the sequence of input symbols consumed
  List<String> get inputSequence {
    final sequence = <String>[];
    String remaining = inputString;

    for (final step in steps) {
      if (step.remainingInput.length < remaining.length) {
        final consumed = remaining.substring(
          0,
          remaining.length - step.remainingInput.length,
        );
        sequence.addAll(consumed.split(''));
        remaining = step.remainingInput;
      }
    }

    return sequence;
  }

  /// Gets the number of input symbols consumed
  int get inputSymbolsConsumed {
    return inputString.length - remainingInput.length;
  }

  /// Gets the number of input symbols remaining
  int get inputSymbolsRemaining {
    return remainingInput.length;
  }

  /// Checks if all input was consumed
  bool get allInputConsumed => remainingInput.isEmpty;

  /// Gets the stack contents at the end of simulation (for PDA)
  String get finalStackContents => lastStep?.stackContents ?? '';

  /// Gets the tape contents at the end of simulation (for TM)
  String get finalTapeContents => lastStep?.tapeContents ?? '';

  /// Creates an error simulation result
  factory SimulationResult.error({
    required String inputString,
    required String errorMessage,
    required Duration executionTime,
    NFAComputationTree? computationTree,
  }) {
    return SimulationResult._(
      inputString: inputString,
      accepted: false,
      steps: [],
      errorMessage: errorMessage,
      message: _legacyFailureMessage,
      executionTime: executionTime,
      computationTree: computationTree,
      usesLegacyMessagePayload: true,
    );
  }
}

final StructuredMessage _legacyFailureMessage = StructuredMessage.legacyAdapter(
  namespace: 'simulation',
  code: 'legacy-failure',
  category: StructuredMessageCategory.simulation,
);

StructuredMessage _timeoutMessage(Duration executionTime) => StructuredMessage(
  namespace: 'simulation',
  code: 'timeout',
  category: StructuredMessageCategory.simulation,
  severity: StructuredMessageSeverity.warning,
  arguments: {'elapsed': StructuredMessageArgument.duration(executionTime)},
);

StructuredMessage _provenCycleMessage(int stepCount) => StructuredMessage(
  namespace: 'simulation',
  code: 'proven-cycle',
  category: StructuredMessageCategory.simulation,
  severity: StructuredMessageSeverity.warning,
  arguments: {'steps': StructuredMessageArgument.count(stepCount)},
);

StructuredMessage? _migrateLegacyError(
  String legacyError, {
  required Duration executionTime,
  required int stepCount,
}) {
  if (legacyError.isEmpty) return null;
  final normalized = legacyError.toLowerCase();
  if (normalized.contains('timeout') || normalized.contains('timed out')) {
    return _timeoutMessage(executionTime);
  }
  if (normalized.contains('infinite loop')) {
    return _provenCycleMessage(stepCount);
  }
  return _legacyFailureMessage;
}

String _compatibilityTextFor(StructuredMessage? message) {
  if (message == null) return '';
  return switch (message.stableCode) {
    'simulation.timeout' =>
      'Simulation timed out after ${((message.arguments['elapsed']?.value as int? ?? 0) / 1000).floor()} seconds',
    'simulation.proven-cycle' =>
      'Infinite loop detected after ${message.arguments['steps']?.value ?? 0} steps',
    _ => message.stableCode,
  };
}
