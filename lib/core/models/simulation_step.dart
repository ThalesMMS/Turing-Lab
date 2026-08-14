//
//  simulation_step.dart
//  Turing Lab
//
//  Registra cada passo de simulação com estado atual, entradas restantes e artefatos específicos de PDA ou TM. Oferece cópia, serialização e campos auxiliares que documentam consumo de símbolos e aceitação para rastreamento detalhado.
//
//  Thales Matheus Mendonça Santos - October 2025
//

import 'step_explanation.dart';

/// Single step in an automaton simulation
class SimulationStep {
  /// Current state in this step
  final String currentState;

  /// Remaining input string
  final String remainingInput;

  /// Stack contents (for PDA)
  final String stackContents;

  /// Tape contents (for TM)
  final String tapeContents;

  /// Transition used in this step (if any)
  final String? usedTransition;

  /// Step number in the simulation
  final int stepNumber;

  /// Description of what happens in this step
  final String? description;

  /// Whether this step results in acceptance
  final bool? isAccepted;

  /// Input symbol processed in this step
  final String? inputSymbol;

  /// Next state after this step
  final String? nextState;

  /// Input consumed while taking this step
  final String consumedInput;

  /// Head position on tape (for TM)
  final int? headPosition;

  /// Optional explanation payload for this step.
  final StepExplanation? explanation;

  const SimulationStep({
    required this.currentState,
    required this.remainingInput,
    this.stackContents = '',
    this.tapeContents = '',
    this.usedTransition,
    required this.stepNumber,
    this.description,
    this.isAccepted,
    this.inputSymbol,
    this.nextState,
    this.consumedInput = '',
    this.headPosition,
    this.explanation,
  });

  /// Creates a copy of this simulation step with updated properties
  SimulationStep copyWith({
    String? currentState,
    String? remainingInput,
    String? stackContents,
    String? tapeContents,
    String? usedTransition,
    int? stepNumber,
    String? description,
    bool? isAccepted,
    String? inputSymbol,
    String? nextState,
    String? consumedInput,
    int? headPosition,
    StepExplanation? explanation,
  }) {
    return SimulationStep(
      currentState: currentState ?? this.currentState,
      remainingInput: remainingInput ?? this.remainingInput,
      stackContents: stackContents ?? this.stackContents,
      tapeContents: tapeContents ?? this.tapeContents,
      usedTransition: usedTransition ?? this.usedTransition,
      stepNumber: stepNumber ?? this.stepNumber,
      description: description ?? this.description,
      isAccepted: isAccepted ?? this.isAccepted,
      inputSymbol: inputSymbol ?? this.inputSymbol,
      nextState: nextState ?? this.nextState,
      consumedInput: consumedInput ?? this.consumedInput,
      headPosition: headPosition ?? this.headPosition,
      explanation: explanation ?? this.explanation,
    );
  }

  /// Converts the simulation step to a JSON representation
  Map<String, dynamic> toJson() {
    return {
      'currentState': currentState,
      'remainingInput': remainingInput,
      'stackContents': stackContents,
      'tapeContents': tapeContents,
      'usedTransition': usedTransition,
      'stepNumber': stepNumber,
      'description': description,
      'isAccepted': isAccepted,
      'inputSymbol': inputSymbol,
      'nextState': nextState,
      'consumedInput': consumedInput,
      'headPosition': headPosition,
      'explanation': explanation?.toJson(),
    };
  }

  /// Creates a simulation step from a JSON representation
  factory SimulationStep.fromJson(Map<String, dynamic> json) {
    return SimulationStep(
      currentState: json['currentState'] as String,
      remainingInput: json['remainingInput'] as String,
      stackContents: json['stackContents'] as String? ?? '',
      tapeContents: json['tapeContents'] as String? ?? '',
      usedTransition: json['usedTransition'] as String?,
      stepNumber: json['stepNumber'] as int,
      description: json['description'] as String?,
      isAccepted: json['isAccepted'] as bool?,
      inputSymbol: json['inputSymbol'] as String?,
      nextState: json['nextState'] as String?,
      consumedInput: json['consumedInput'] as String? ?? '',
      headPosition: json['headPosition'] as int?,
      explanation: json['explanation'] is Map
          ? StepExplanation.fromJson(
              Map<String, dynamic>.from(json['explanation'] as Map),
            )
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SimulationStep &&
        other.currentState == currentState &&
        other.remainingInput == remainingInput &&
        other.stackContents == stackContents &&
        other.tapeContents == tapeContents &&
        other.usedTransition == usedTransition &&
        other.stepNumber == stepNumber &&
        other.description == description &&
        other.isAccepted == isAccepted &&
        other.inputSymbol == inputSymbol &&
        other.nextState == nextState &&
        other.consumedInput == consumedInput &&
        other.headPosition == headPosition &&
        other.explanation == explanation;
  }

  @override
  int get hashCode {
    return Object.hash(
      currentState,
      remainingInput,
      stackContents,
      tapeContents,
      usedTransition,
      stepNumber,
      description,
      isAccepted,
      inputSymbol,
      nextState,
      consumedInput,
      headPosition,
      explanation,
    );
  }

  @override
  String toString() {
    return 'SimulationStep(stepNumber: $stepNumber, currentState: $currentState, remainingInput: $remainingInput)';
  }

  /// Checks if this is the first step
  bool get isFirstStep => stepNumber == 1;

  /// Checks if this is the last step (step number is 0 only for final steps
  /// created by [SimulationStep.finalStep] when no transitions occurred).
  /// For a reliable check, compare against the simulation result's step list.
  bool get isLastStep => false; // Cannot determine without simulation context

  /// Checks if a transition was used in this step
  bool get hasTransition => usedTransition != null;

  /// Checks if this step has stack operations (for PDA)
  bool get hasStackOperations => stackContents.isNotEmpty;

  /// Checks if this step has tape operations (for TM)
  bool get hasTapeOperations => tapeContents.isNotEmpty;

  /// Gets the number of remaining input symbols
  int get remainingInputLength => remainingInput.length;

  /// Gets the number of stack symbols (for PDA)
  int get stackLength => stackContents.length;

  /// Gets the number of tape symbols (for TM)
  int get tapeLength => tapeContents.length;

  /// Gets the top of the stack (for PDA)
  String? get stackTop => stackContents.isNotEmpty ? stackContents[0] : null;

  /// Gets the current tape symbol (for TM)
  String? get currentTapeSymbol {
    if (tapeContents.isEmpty) return null;
    if (headPosition != null && headPosition! < tapeContents.length) {
      return tapeContents[headPosition!];
    }
    return tapeContents[0]; // fallback for non-TM steps
  }

  /// Gets the next input symbol
  String? get nextInputSymbol =>
      remainingInput.isNotEmpty ? remainingInput[0] : null;

  /// Gets the stack operation performed (for PDA)
  String get stackOperation {
    if (stackContents.isEmpty) return 'none';
    return 'stack: $stackContents';
  }

  /// Gets the tape operation performed (for TM)
  String get tapeOperation {
    if (tapeContents.isEmpty) return 'none';
    return 'tape: $tapeContents';
  }

  /// Gets a summary of this step
  String get summary {
    final buffer = StringBuffer();
    buffer.write('Step $stepNumber: State $currentState');

    if (remainingInput.isNotEmpty) {
      buffer.write(', Input: $remainingInput');
    }

    if (stackContents.isNotEmpty) {
      buffer.write(', Stack: $stackContents');
    }

    if (tapeContents.isNotEmpty) {
      buffer.write(', Tape: $tapeContents');
    }

    if (usedTransition != null) {
      buffer.write(', Transition: $usedTransition');
    }

    return buffer.toString();
  }

  /// Creates a simulation step for FSA
  factory SimulationStep.fsa({
    required String currentState,
    required String remainingInput,
    String? usedTransition,
    required int stepNumber,
    String consumedInput = '',
    StepExplanation? explanation,
  }) {
    return SimulationStep(
      currentState: currentState,
      remainingInput: remainingInput,
      usedTransition: usedTransition,
      stepNumber: stepNumber,
      consumedInput: consumedInput,
      explanation: explanation,
    );
  }

  /// Creates a simulation step for PDA
  factory SimulationStep.pda({
    required String currentState,
    required String remainingInput,
    required String stackContents,
    String? usedTransition,
    required int stepNumber,
    String consumedInput = '',
    StepExplanation? explanation,
  }) {
    return SimulationStep(
      currentState: currentState,
      remainingInput: remainingInput,
      stackContents: stackContents,
      usedTransition: usedTransition,
      stepNumber: stepNumber,
      consumedInput: consumedInput,
      explanation: explanation,
    );
  }

  /// Creates a simulation step for TM
  factory SimulationStep.tm({
    required String currentState,
    required String remainingInput,
    required String tapeContents,
    String? usedTransition,
    required int stepNumber,
    int? headPosition,
    String consumedInput = '',
    StepExplanation? explanation,
  }) {
    return SimulationStep(
      currentState: currentState,
      remainingInput: remainingInput,
      tapeContents: tapeContents,
      usedTransition: usedTransition,
      stepNumber: stepNumber,
      consumedInput: consumedInput,
      headPosition: headPosition,
      explanation: explanation,
    );
  }

  /// Creates an initial simulation step
  factory SimulationStep.initial({
    required String initialState,
    required String inputString,
    String? initialStackSymbol,
    String? initialTapeSymbol,
    String consumedInput = '',
  }) {
    return SimulationStep(
      currentState: initialState,
      remainingInput: inputString,
      stackContents: initialStackSymbol ?? '',
      tapeContents: initialTapeSymbol ?? '',
      stepNumber: 0,
      consumedInput: consumedInput,
    );
  }

  /// Creates a final simulation step
  factory SimulationStep.finalStep({
    required String finalState,
    required String remainingInput,
    required String stackContents,
    required String tapeContents,
    required int stepNumber,
    String consumedInput = '',
    int? headPosition,
  }) {
    return SimulationStep(
      currentState: finalState,
      remainingInput: remainingInput,
      stackContents: stackContents,
      tapeContents: tapeContents,
      stepNumber: stepNumber,
      consumedInput: consumedInput,
      headPosition: headPosition,
    );
  }
}
