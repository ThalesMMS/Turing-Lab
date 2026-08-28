//
//  simulation_step.dart
//  Turing Lab
//
//  Records each simulation step with the current state, remaining input, and
//  PDA- or TM-specific artifacts. Offers copy, serialization, and helper
//  fields that document symbol consumption and acceptance for detailed
//  tracing.
//
//  Thales Matheus Mendonça Santos - October 2025
//

import 'package:collection/collection.dart';

import '../messages/structured_message.dart';
import 'step_explanation.dart';

/// Single step in an automaton simulation
class SimulationStep {
  static const schemaVersion = 2;
  static const SetEquality<String> _setEquality = SetEquality<String>();
  static const ListEquality<String> _listEquality = ListEquality<String>();

  /// Current state in this step
  final String currentState;

  /// Stable ids of the states active in this configuration.
  ///
  /// A null value means the trace does not provide authoritative state ids.
  /// An empty set explicitly means that no state is active.
  final Set<String>? activeStateIds;

  /// Remaining input string
  final String remainingInput;

  /// Stack contents (for PDA)
  final String stackContents;

  /// Ordered atomic PDA stack symbols, from bottom to top.
  ///
  /// `null` identifies legacy traces that only stored [stackContents].
  final List<String>? stackTokens;

  /// Tape contents (for TM)
  final String tapeContents;

  /// Transition used in this step (if any)
  final String? usedTransition;

  /// Step number in the simulation
  final int stepNumber;

  /// Description of what happens in this step
  final String? description;

  /// Locale-neutral replacement for [description].
  final StructuredMessage? descriptionMessage;

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
    this.activeStateIds,
    required this.remainingInput,
    this.stackContents = '',
    this.stackTokens,
    this.tapeContents = '',
    this.usedTransition,
    required this.stepNumber,
    this.description,
    this.descriptionMessage,
    this.isAccepted,
    this.inputSymbol,
    this.nextState,
    this.consumedInput = '',
    this.headPosition,
    this.explanation,
  }) : assert(
         description == null || descriptionMessage == null,
         'A simulation step cannot contain both legacy and structured descriptions.',
       );

  /// Creates a copy of this simulation step with updated properties
  ///
  /// Omitting [activeStateIds] retains the existing set, and passing `null` is
  /// indistinguishable from omitting it. Construct a new [SimulationStep] when
  /// a trace has to drop its authoritative state ids.
  SimulationStep copyWith({
    String? currentState,
    Set<String>? activeStateIds,
    String? remainingInput,
    String? stackContents,
    List<String>? stackTokens,
    String? tapeContents,
    String? usedTransition,
    int? stepNumber,
    String? description,
    StructuredMessage? descriptionMessage,
    bool? isAccepted,
    String? inputSymbol,
    String? nextState,
    String? consumedInput,
    int? headPosition,
    StepExplanation? explanation,
  }) {
    return SimulationStep(
      currentState: currentState ?? this.currentState,
      activeStateIds: activeStateIds ?? this.activeStateIds,
      remainingInput: remainingInput ?? this.remainingInput,
      stackContents: stackContents ?? this.stackContents,
      stackTokens: stackTokens ?? this.stackTokens,
      tapeContents: tapeContents ?? this.tapeContents,
      usedTransition: usedTransition ?? this.usedTransition,
      stepNumber: stepNumber ?? this.stepNumber,
      description: description ?? this.description,
      descriptionMessage: descriptionMessage ?? this.descriptionMessage,
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
    if (description != null && descriptionMessage != null) {
      throw StateError(
        'A simulation step cannot contain both legacy and structured descriptions.',
      );
    }
    final shared = <String, dynamic>{
      'currentState': currentState,
      'activeStateIds': activeStateIds?.toList(),
      'remainingInput': remainingInput,
      'stackContents': stackContents,
      'stackTokens': stackTokens,
      'tapeContents': tapeContents,
      'usedTransition': usedTransition,
      'stepNumber': stepNumber,
      'isAccepted': isAccepted,
      'inputSymbol': inputSymbol,
      'nextState': nextState,
      'consumedInput': consumedInput,
      'headPosition': headPosition,
      'explanation': explanation?.toJson(),
    };
    if (description != null) {
      return {...shared, 'description': description};
    }
    return {
      'schemaVersion': schemaVersion,
      ...shared,
      'descriptionMessage': descriptionMessage?.toJson(),
    };
  }

  bool get usesLegacyText =>
      description != null || (explanation?.usesLegacyText ?? false);

  /// Creates a simulation step from a JSON representation
  factory SimulationStep.fromJson(Map<String, dynamic> json) {
    final version = json['schemaVersion'];
    if (version != null && version != schemaVersion) {
      throw FormatException('Unsupported simulation-step version: $version.');
    }
    final description = json['description'] as String?;
    final descriptionMessage = json['descriptionMessage'] is Map
        ? StructuredMessage.fromJson(
            Map<String, Object?>.from(json['descriptionMessage'] as Map),
          )
        : null;
    if (description != null && descriptionMessage != null) {
      throw const FormatException(
        'Simulation step contains both legacy and structured descriptions.',
      );
    }
    return SimulationStep(
      currentState: json['currentState'] as String,
      activeStateIds: json['activeStateIds'] is List
          ? Set<String>.unmodifiable(
              (json['activeStateIds'] as List).whereType<String>(),
            )
          : null,
      remainingInput: json['remainingInput'] as String,
      stackContents: json['stackContents'] as String? ?? '',
      stackTokens: json['stackTokens'] is List
          ? List<String>.unmodifiable(
              (json['stackTokens'] as List).cast<String>(),
            )
          : null,
      tapeContents: json['tapeContents'] as String? ?? '',
      usedTransition: json['usedTransition'] as String?,
      stepNumber: json['stepNumber'] as int,
      description: description,
      descriptionMessage: descriptionMessage,
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
        _setEquality.equals(other.activeStateIds, activeStateIds) &&
        other.remainingInput == remainingInput &&
        other.stackContents == stackContents &&
        _listEquality.equals(other.stackTokens, stackTokens) &&
        other.tapeContents == tapeContents &&
        other.usedTransition == usedTransition &&
        other.stepNumber == stepNumber &&
        other.description == description &&
        other.descriptionMessage == descriptionMessage &&
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
      _setEquality.hash(activeStateIds),
      remainingInput,
      stackContents,
      _listEquality.hash(stackTokens),
      tapeContents,
      usedTransition,
      stepNumber,
      description,
      descriptionMessage,
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

  /// Atomic stack symbols when available, or Unicode scalar values for a
  /// legacy flattened trace.
  List<String> get effectiveStackTokens =>
      stackTokens ?? stackContents.runes.map(String.fromCharCode).toList();

  /// Checks if this step has tape operations (for TM)
  bool get hasTapeOperations => tapeContents.isNotEmpty;

  /// Gets the number of remaining input symbols
  int get remainingInputLength => remainingInput.length;

  /// Gets the number of stack symbols (for PDA)
  int get stackLength => effectiveStackTokens.length;

  /// Gets the number of tape symbols (for TM)
  int get tapeLength => tapeContents.length;

  /// Gets the top of the stack (for PDA)
  String? get stackTop =>
      effectiveStackTokens.isEmpty ? null : effectiveStackTokens.last;

  /// Gets the current tape symbol (for TM)
  String? get currentTapeSymbol {
    if (tapeContents.isEmpty) return null;
    if (headPosition != null && headPosition! < tapeContents.length) {
      return tapeContents[headPosition!];
    }
    return tapeContents[0]; // fallback for non-TM steps
  }

  /// Gets the next input symbol
  String? get nextInputSymbol => remainingInput.isNotEmpty
      ? String.fromCharCode(remainingInput.runes.first)
      : null;

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
    Set<String>? activeStateIds,
    required String remainingInput,
    String? usedTransition,
    required int stepNumber,
    String consumedInput = '',
    StepExplanation? explanation,
  }) {
    return SimulationStep(
      currentState: currentState,
      activeStateIds: activeStateIds,
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
    Set<String>? activeStateIds,
    required String remainingInput,
    required String stackContents,
    List<String>? stackTokens,
    String? usedTransition,
    required int stepNumber,
    String consumedInput = '',
    StepExplanation? explanation,
  }) {
    return SimulationStep(
      currentState: currentState,
      activeStateIds: activeStateIds,
      remainingInput: remainingInput,
      stackContents: stackContents,
      stackTokens: stackTokens == null
          ? null
          : List<String>.unmodifiable(stackTokens),
      usedTransition: usedTransition,
      stepNumber: stepNumber,
      consumedInput: consumedInput,
      explanation: explanation,
    );
  }

  /// Creates a simulation step for TM
  factory SimulationStep.tm({
    required String currentState,
    Set<String>? activeStateIds,
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
      activeStateIds: activeStateIds,
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
    Set<String>? activeStateIds,
    required String inputString,
    String? initialStackSymbol,
    List<String>? initialStackTokens,
    String? initialTapeSymbol,
    String consumedInput = '',
  }) {
    return SimulationStep(
      currentState: initialState,
      activeStateIds: activeStateIds,
      remainingInput: inputString,
      stackContents: initialStackSymbol ?? '',
      stackTokens: initialStackTokens == null
          ? null
          : List<String>.unmodifiable(initialStackTokens),
      tapeContents: initialTapeSymbol ?? '',
      stepNumber: 0,
      consumedInput: consumedInput,
    );
  }

  /// Creates a final simulation step
  factory SimulationStep.finalStep({
    required String finalState,
    Set<String>? activeStateIds,
    required String remainingInput,
    required String stackContents,
    List<String>? stackTokens,
    required String tapeContents,
    required int stepNumber,
    String consumedInput = '',
    int? headPosition,
  }) {
    return SimulationStep(
      currentState: finalState,
      activeStateIds: activeStateIds,
      remainingInput: remainingInput,
      stackContents: stackContents,
      stackTokens: stackTokens == null
          ? null
          : List<String>.unmodifiable(stackTokens),
      tapeContents: tapeContents,
      stepNumber: stepNumber,
      consumedInput: consumedInput,
      headPosition: headPosition,
    );
  }
}
