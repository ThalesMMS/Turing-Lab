//
//  fa_to_regex_step.dart
//  Turing Lab
//
//  Defines the detailed step model for FA→Regex conversion via state
//  elimination. Captures the eliminated state, incoming/outgoing transitions,
//  self-loops, intermediate regex expressions, and path combinations for
//  each algorithm step, enabling educational step-by-step visualization.
//
//  Thales Matheus Mendonça Santos - January 2026
//

import 'algorithm_step.dart';
import 'state.dart';
import 'fsa_transition.dart';

/// Represents a single step in FA to Regex conversion using state elimination
class FAToRegexStep {
  /// Base algorithm step information
  final AlgorithmStep baseStep;

  /// Type of operation performed in this step
  final FAToRegexStepType stepType;

  /// State being eliminated in this step (null for non-elimination steps)
  final State? eliminatedState;

  /// States with incoming transitions to the eliminated state
  final Set<State>? incomingStates;

  /// Transitions coming into the eliminated state
  final Set<FSATransition>? incomingTransitions;

  /// States with outgoing transitions from the eliminated state
  final Set<State>? outgoingStates;

  /// Transitions going out from the eliminated state
  final Set<FSATransition>? outgoingTransitions;

  /// Self-loop transitions on the eliminated state
  final Set<FSATransition>? selfLoopTransitions;

  /// Regex representing the self-loop (with Kleene star applied)
  final String? selfLoopRegex;

  /// New transitions created to bypass the eliminated state
  final Set<FSATransition>? newTransitions;

  /// Regex expressions being combined in this step
  final List<String>? combinedRegexes;

  /// Resulting regex after combination
  final String? resultingRegex;

  /// New initial state added (for normalization)
  final State? addedInitialState;

  /// New final state added (for normalization)
  final State? addedFinalState;

  /// Number of states remaining in the automaton
  final int? remainingStateCount;

  /// Current automaton state count before this step
  final int? currentStateCount;

  /// Final regex expression (for completion step)
  final String? finalRegex;

  const FAToRegexStep._internal({
    required this.baseStep,
    required this.stepType,
    this.eliminatedState,
    this.incomingStates,
    this.incomingTransitions,
    this.outgoingStates,
    this.outgoingTransitions,
    this.selfLoopTransitions,
    this.selfLoopRegex,
    this.newTransitions,
    this.combinedRegexes,
    this.resultingRegex,
    this.addedInitialState,
    this.addedFinalState,
    this.remainingStateCount,
    this.currentStateCount,
    this.finalRegex,
  });

  factory FAToRegexStep({
    required AlgorithmStep baseStep,
    required FAToRegexStepType stepType,
    State? eliminatedState,
    Set<State>? incomingStates,
    Set<FSATransition>? incomingTransitions,
    Set<State>? outgoingStates,
    Set<FSATransition>? outgoingTransitions,
    Set<FSATransition>? selfLoopTransitions,
    String? selfLoopRegex,
    Set<FSATransition>? newTransitions,
    List<String>? combinedRegexes,
    String? resultingRegex,
    State? addedInitialState,
    State? addedFinalState,
    int? remainingStateCount,
    int? currentStateCount,
    String? finalRegex,
  }) {
    return FAToRegexStep._internal(
      baseStep: baseStep,
      stepType: stepType,
      eliminatedState: eliminatedState,
      incomingStates:
          incomingStates != null ? Set.unmodifiable(incomingStates) : null,
      incomingTransitions: incomingTransitions != null
          ? Set.unmodifiable(incomingTransitions)
          : null,
      outgoingStates:
          outgoingStates != null ? Set.unmodifiable(outgoingStates) : null,
      outgoingTransitions: outgoingTransitions != null
          ? Set.unmodifiable(outgoingTransitions)
          : null,
      selfLoopTransitions: selfLoopTransitions != null
          ? Set.unmodifiable(selfLoopTransitions)
          : null,
      selfLoopRegex: selfLoopRegex,
      newTransitions:
          newTransitions != null ? Set.unmodifiable(newTransitions) : null,
      combinedRegexes:
          combinedRegexes != null ? List.unmodifiable(combinedRegexes) : null,
      resultingRegex: resultingRegex,
      addedInitialState: addedInitialState,
      addedFinalState: addedFinalState,
      remainingStateCount: remainingStateCount,
      currentStateCount: currentStateCount,
      finalRegex: finalRegex,
    );
  }

  /// Creates a validation step
  factory FAToRegexStep.validation({
    required String id,
    required int stepNumber,
    required int stateCount,
    required int transitionCount,
    required bool hasInitialState,
    required bool hasAcceptingStates,
  }) {
    return FAToRegexStep(
      baseStep: AlgorithmStep(
        id: id,
        stepNumber: stepNumber,
        title: 'Validate input automaton',
        explanation: 'Validating the input finite automaton. '
            'The automaton has $stateCount state(s) and $transitionCount transition(s). '
            '${hasInitialState ? "Initial state is present. " : "ERROR: No initial state found. "}'
            '${hasAcceptingStates ? "Accepting states are present." : "ERROR: No accepting states found."}',
        type: AlgorithmType.faToRegex,
      ),
      stepType: FAToRegexStepType.validation,
      currentStateCount: stateCount,
    );
  }

  /// Creates a step for adding a new initial state
  factory FAToRegexStep.addInitialState({
    required String id,
    required int stepNumber,
    required State oldInitialState,
    required State newInitialState,
  }) {
    return FAToRegexStep(
      baseStep: AlgorithmStep(
        id: id,
        stepNumber: stepNumber,
        title: 'Add new initial state',
        explanation:
            'Adding a new unique initial state ${newInitialState.label}. '
            'This state will have an ε-transition to the original initial state ${oldInitialState.label}. '
            'This normalization ensures the automaton has exactly one initial state with no incoming transitions.',
        type: AlgorithmType.faToRegex,
      ),
      stepType: FAToRegexStepType.addInitialState,
      addedInitialState: newInitialState,
    );
  }

  /// Creates a step for adding a new final state
  factory FAToRegexStep.addFinalState({
    required String id,
    required int stepNumber,
    required Set<State> oldAcceptingStates,
    required State newFinalState,
  }) {
    final oldLabels = oldAcceptingStates.map((s) => s.label).join(', ');
    return FAToRegexStep(
      baseStep: AlgorithmStep(
        id: id,
        stepNumber: stepNumber,
        title: 'Add new final state',
        explanation: 'Adding a new unique final state ${newFinalState.label}. '
            'All original accepting states {$oldLabels} will have ε-transitions to this new final state. '
            'This normalization ensures the automaton has exactly one accepting state with no outgoing transitions.',
        type: AlgorithmType.faToRegex,
      ),
      stepType: FAToRegexStepType.addFinalState,
      addedFinalState: newFinalState,
    );
  }

  /// Creates a step for selecting a state to eliminate
  factory FAToRegexStep.selectStateToEliminate({
    required String id,
    required int stepNumber,
    required State state,
    required int remainingStates,
  }) {
    return FAToRegexStep(
      baseStep: AlgorithmStep(
        id: id,
        stepNumber: stepNumber,
        title: 'Select state ${state.label} for elimination',
        explanation: 'Selecting state ${state.label} to eliminate. '
            'We will create new transitions to bypass this state and remove it from the automaton. '
            'After elimination, $remainingStates state(s) will remain.',
        type: AlgorithmType.faToRegex,
      ),
      stepType: FAToRegexStepType.selectState,
      eliminatedState: state,
      currentStateCount: remainingStates + 1,
      remainingStateCount: remainingStates,
    );
  }

  /// Creates a step for finding incoming transitions
  factory FAToRegexStep.findIncomingTransitions({
    required String id,
    required int stepNumber,
    required State eliminatedState,
    required Set<State> incomingStates,
    required Set<FSATransition> incomingTransitions,
  }) {
    final stateLabels = incomingStates.isNotEmpty
        ? incomingStates.map((s) => s.label).join(', ')
        : 'none';
    final transitionCount = incomingTransitions.length;
    return FAToRegexStep(
      baseStep: AlgorithmStep(
        id: id,
        stepNumber: stepNumber,
        title: 'Find incoming transitions',
        explanation:
            'Finding all transitions leading to ${eliminatedState.label}. '
            'Found $transitionCount incoming transition(s) from state(s): {$stateLabels}. '
            '${transitionCount == 0 ? "No incoming transitions, so no new transitions will be created from predecessors." : ""}',
        type: AlgorithmType.faToRegex,
      ),
      stepType: FAToRegexStepType.findIncoming,
      eliminatedState: eliminatedState,
      incomingStates: incomingStates,
      incomingTransitions: incomingTransitions,
    );
  }

  /// Creates a step for finding outgoing transitions
  factory FAToRegexStep.findOutgoingTransitions({
    required String id,
    required int stepNumber,
    required State eliminatedState,
    required Set<State> outgoingStates,
    required Set<FSATransition> outgoingTransitions,
  }) {
    final stateLabels = outgoingStates.isNotEmpty
        ? outgoingStates.map((s) => s.label).join(', ')
        : 'none';
    final transitionCount = outgoingTransitions.length;
    return FAToRegexStep(
      baseStep: AlgorithmStep(
        id: id,
        stepNumber: stepNumber,
        title: 'Find outgoing transitions',
        explanation:
            'Finding all transitions leaving from ${eliminatedState.label}. '
            'Found $transitionCount outgoing transition(s) to state(s): {$stateLabels}. '
            '${transitionCount == 0 ? "No outgoing transitions, so no new transitions will be created to successors." : ""}',
        type: AlgorithmType.faToRegex,
      ),
      stepType: FAToRegexStepType.findOutgoing,
      eliminatedState: eliminatedState,
      outgoingStates: outgoingStates,
      outgoingTransitions: outgoingTransitions,
    );
  }

  /// Creates a step for finding self-loop transitions
  factory FAToRegexStep.findSelfLoop({
    required String id,
    required int stepNumber,
    required State eliminatedState,
    required Set<FSATransition> selfLoopTransitions,
    required String selfLoopRegex,
  }) {
    final hasLoop = selfLoopTransitions.isNotEmpty;
    return FAToRegexStep(
      baseStep: AlgorithmStep(
        id: id,
        stepNumber: stepNumber,
        title: hasLoop ? 'Process self-loop' : 'Check for self-loop',
        explanation: hasLoop
            ? 'Found self-loop transition(s) on ${eliminatedState.label}. '
                'Combining them into regex: $selfLoopRegex. '
                'This expression will be inserted between incoming and outgoing transitions.'
            : 'No self-loop found on ${eliminatedState.label}. '
                'New transitions will directly connect incoming and outgoing states.',
        type: AlgorithmType.faToRegex,
      ),
      stepType: FAToRegexStepType.findSelfLoop,
      eliminatedState: eliminatedState,
      selfLoopTransitions: selfLoopTransitions,
      selfLoopRegex: selfLoopRegex,
    );
  }

  /// Creates a step for creating new bypass transitions
  factory FAToRegexStep.createBypassTransitions({
    required String id,
    required int stepNumber,
    required State eliminatedState,
    required Set<FSATransition> newTransitions,
    required String pathRegexExample,
  }) {
    final predecessorStates = newTransitions.isEmpty
        ? null
        : newTransitions.map((transition) => transition.fromState).toSet();
    final successorStates = newTransitions.isEmpty
        ? null
        : newTransitions.map((transition) => transition.toState).toSet();

    return FAToRegexStep(
      baseStep: AlgorithmStep(
        id: id,
        stepNumber: stepNumber,
        title: 'Create bypass transitions',
        explanation:
            'Creating ${newTransitions.length} new transition(s) to bypass ${eliminatedState.label}. '
            'Each new transition combines: (incoming label) + (self-loop)* + (outgoing label). '
            'Example path regex: $pathRegexExample. '
            'These transitions replace all paths that went through the eliminated state.',
        type: AlgorithmType.faToRegex,
      ),
      stepType: FAToRegexStepType.createBypass,
      eliminatedState: eliminatedState,
      incomingStates: predecessorStates,
      outgoingStates: successorStates,
      newTransitions: newTransitions,
      resultingRegex: pathRegexExample,
    );
  }

  /// Creates a step for combining parallel transitions
  factory FAToRegexStep.combineTransitions({
    required String id,
    required int stepNumber,
    required State fromState,
    required State toState,
    required List<String> combinedRegexes,
    required String resultingRegex,
  }) {
    return FAToRegexStep(
      baseStep: AlgorithmStep(
        id: id,
        stepNumber: stepNumber,
        title: 'Combine parallel transitions',
        explanation:
            'Found multiple transitions from ${fromState.label} to ${toState.label}. '
            'Combining ${combinedRegexes.length} regex expression(s) using union (|): ${combinedRegexes.join(", ")}. '
            'Resulting expression: $resultingRegex',
        type: AlgorithmType.faToRegex,
      ),
      stepType: FAToRegexStepType.combineTransitions,
      combinedRegexes: combinedRegexes,
      resultingRegex: resultingRegex,
    );
  }

  /// Creates a step for completing state elimination
  factory FAToRegexStep.completeElimination({
    required String id,
    required int stepNumber,
    required State eliminatedState,
    required int remainingStates,
  }) {
    return FAToRegexStep(
      baseStep: AlgorithmStep(
        id: id,
        stepNumber: stepNumber,
        title: 'Complete elimination of ${eliminatedState.label}',
        explanation:
            'Successfully eliminated state ${eliminatedState.label} from the automaton. '
            'All paths through this state have been replaced with equivalent direct transitions. '
            'Remaining state count: $remainingStates.',
        type: AlgorithmType.faToRegex,
      ),
      stepType: FAToRegexStepType.completeElimination,
      eliminatedState: eliminatedState,
      remainingStateCount: remainingStates,
    );
  }

  /// Creates a step for extracting the final regex
  factory FAToRegexStep.extractRegex({
    required String id,
    required int stepNumber,
    required String regex,
    required State initialState,
    required State finalState,
  }) {
    return FAToRegexStep(
      baseStep: AlgorithmStep(
        id: id,
        stepNumber: stepNumber,
        title: 'Extract final regular expression',
        explanation: 'All intermediate states have been eliminated. '
            'The automaton now has only the initial state ${initialState.label} and final state ${finalState.label}. '
            'Extracting the regex from the transition(s) between them: $regex',
        type: AlgorithmType.faToRegex,
      ),
      stepType: FAToRegexStepType.extractRegex,
      finalRegex: regex,
      resultingRegex: regex,
    );
  }

  /// Creates a completion step
  factory FAToRegexStep.completion({
    required String id,
    required int stepNumber,
    required String finalRegex,
    required int originalStates,
    required int stepsExecuted,
  }) {
    return FAToRegexStep(
      baseStep: AlgorithmStep(
        id: id,
        stepNumber: stepNumber,
        title: 'Conversion complete',
        explanation: 'FA to Regex conversion completed successfully. '
            'Converted automaton with $originalStates state(s) to regular expression: $finalRegex. '
            'Total steps executed: $stepsExecuted. '
            'The resulting regular expression accepts the same language as the original automaton.',
        type: AlgorithmType.faToRegex,
      ),
      stepType: FAToRegexStepType.completion,
      finalRegex: finalRegex,
      resultingRegex: finalRegex,
    );
  }

  /// Creates a copy of this step with updated properties
  FAToRegexStep copyWith({
    AlgorithmStep? baseStep,
    FAToRegexStepType? stepType,
    State? eliminatedState,
    Set<State>? incomingStates,
    Set<FSATransition>? incomingTransitions,
    Set<State>? outgoingStates,
    Set<FSATransition>? outgoingTransitions,
    Set<FSATransition>? selfLoopTransitions,
    String? selfLoopRegex,
    Set<FSATransition>? newTransitions,
    List<String>? combinedRegexes,
    String? resultingRegex,
    State? addedInitialState,
    State? addedFinalState,
    int? remainingStateCount,
    int? currentStateCount,
    String? finalRegex,
  }) {
    return FAToRegexStep(
      baseStep: baseStep ?? this.baseStep,
      stepType: stepType ?? this.stepType,
      eliminatedState: eliminatedState ?? this.eliminatedState,
      incomingStates: incomingStates ?? this.incomingStates,
      incomingTransitions: incomingTransitions ?? this.incomingTransitions,
      outgoingStates: outgoingStates ?? this.outgoingStates,
      outgoingTransitions: outgoingTransitions ?? this.outgoingTransitions,
      selfLoopTransitions: selfLoopTransitions ?? this.selfLoopTransitions,
      selfLoopRegex: selfLoopRegex ?? this.selfLoopRegex,
      newTransitions: newTransitions ?? this.newTransitions,
      combinedRegexes: combinedRegexes ?? this.combinedRegexes,
      resultingRegex: resultingRegex ?? this.resultingRegex,
      addedInitialState: addedInitialState ?? this.addedInitialState,
      addedFinalState: addedFinalState ?? this.addedFinalState,
      remainingStateCount: remainingStateCount ?? this.remainingStateCount,
      currentStateCount: currentStateCount ?? this.currentStateCount,
      finalRegex: finalRegex ?? this.finalRegex,
    );
  }

  /// Converts the step to a JSON representation
  Map<String, dynamic> toJson() {
    return {
      'baseStep': baseStep.toJson(),
      'stepType': stepType.name,
      'eliminatedState': eliminatedState?.toJson(),
      'incomingStates': incomingStates?.map((s) => s.toJson()).toList(),
      'incomingTransitions':
          incomingTransitions?.map((t) => t.toJson()).toList(),
      'outgoingStates': outgoingStates?.map((s) => s.toJson()).toList(),
      'outgoingTransitions':
          outgoingTransitions?.map((t) => t.toJson()).toList(),
      'selfLoopTransitions':
          selfLoopTransitions?.map((t) => t.toJson()).toList(),
      'selfLoopRegex': selfLoopRegex,
      'newTransitions': newTransitions?.map((t) => t.toJson()).toList(),
      'combinedRegexes': combinedRegexes,
      'resultingRegex': resultingRegex,
      'addedInitialState': addedInitialState?.toJson(),
      'addedFinalState': addedFinalState?.toJson(),
      'remainingStateCount': remainingStateCount,
      'currentStateCount': currentStateCount,
      'finalRegex': finalRegex,
    };
  }

  /// Creates a step from a JSON representation
  factory FAToRegexStep.fromJson(Map<String, dynamic> json) {
    final statesById = <String, State>{};

    State? readState(String key) {
      final stateJson = json[key];
      if (stateJson == null) return null;

      final state = State.fromJson((stateJson as Map).cast<String, dynamic>());
      return statesById.putIfAbsent(state.id, () => state);
    }

    Set<State>? readStates(String key) {
      final stateList = json[key] as List?;
      if (stateList == null) return null;

      return stateList.map((stateJson) {
        final state = State.fromJson(
          (stateJson as Map).cast<String, dynamic>(),
        );
        return statesById.putIfAbsent(state.id, () => state);
      }).toSet();
    }

    Set<FSATransition>? readTransitions(String key) {
      final transitionList = json[key] as List?;
      if (transitionList == null) return null;

      return transitionList
          .map(
            (transitionJson) => FSATransition.fromJson(
              (transitionJson as Map).cast<String, dynamic>(),
              statesById: statesById,
            ),
          )
          .toSet();
    }

    final eliminatedState = readState('eliminatedState');
    final incomingStates = readStates('incomingStates');
    final outgoingStates = readStates('outgoingStates');
    final addedInitialState = readState('addedInitialState');
    final addedFinalState = readState('addedFinalState');

    return FAToRegexStep(
      baseStep: AlgorithmStep.fromJson(
        json['baseStep'] as Map<String, dynamic>,
      ),
      stepType: FAToRegexStepType.values.firstWhere(
        (e) => e.name == json['stepType'],
        orElse: () => FAToRegexStepType.validation,
      ),
      eliminatedState: eliminatedState,
      incomingStates: incomingStates,
      incomingTransitions: readTransitions('incomingTransitions'),
      outgoingStates: outgoingStates,
      outgoingTransitions: readTransitions('outgoingTransitions'),
      selfLoopTransitions: readTransitions('selfLoopTransitions'),
      selfLoopRegex: json['selfLoopRegex'] as String?,
      newTransitions: readTransitions('newTransitions'),
      combinedRegexes:
          (json['combinedRegexes'] as List?)?.map((r) => r as String).toList(),
      resultingRegex: json['resultingRegex'] as String?,
      addedInitialState: addedInitialState,
      addedFinalState: addedFinalState,
      remainingStateCount: json['remainingStateCount'] as int?,
      currentStateCount: json['currentStateCount'] as int?,
      finalRegex: json['finalRegex'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FAToRegexStep &&
        other.baseStep == baseStep &&
        other.stepType == stepType &&
        other.eliminatedState == eliminatedState &&
        other.selfLoopRegex == selfLoopRegex &&
        other.resultingRegex == resultingRegex &&
        other.remainingStateCount == remainingStateCount &&
        other.currentStateCount == currentStateCount &&
        other.finalRegex == finalRegex;
  }

  @override
  int get hashCode {
    return Object.hash(
      baseStep,
      stepType,
      eliminatedState,
      selfLoopRegex,
      resultingRegex,
      remainingStateCount,
      currentStateCount,
      finalRegex,
    );
  }

  @override
  String toString() {
    return 'FAToRegexStep(stepNumber: ${baseStep.stepNumber}, '
        'type: ${stepType.name}, title: ${baseStep.title})';
  }

  /// Gets the step number
  int get stepNumber => baseStep.stepNumber;

  /// Gets the step title
  String get title => baseStep.title;

  /// Gets the step explanation
  String get explanation => baseStep.explanation;

  /// Gets a summary of the state elimination operation
  String get eliminationSummary {
    if (eliminatedState == null) return 'No state elimination';

    final buffer = StringBuffer();
    buffer.write('Eliminating ${eliminatedState!.label}');

    if (incomingStates != null && incomingStates!.isNotEmpty) {
      buffer.write(' (${incomingStates!.length} incoming)');
    }

    if (outgoingStates != null && outgoingStates!.isNotEmpty) {
      buffer.write(' (${outgoingStates!.length} outgoing)');
    }

    if (selfLoopTransitions != null && selfLoopTransitions!.isNotEmpty) {
      buffer.write(' [has self-loop]');
    }

    return buffer.toString();
  }

  /// Gets the number of incoming transitions
  int get incomingTransitionCount => incomingTransitions?.length ?? 0;

  /// Gets the number of outgoing transitions
  int get outgoingTransitionCount => outgoingTransitions?.length ?? 0;

  /// Gets the number of new transitions created
  int get newTransitionCount => newTransitions?.length ?? 0;

  /// Checks if this step involves state elimination
  bool get eliminatesState =>
      stepType == FAToRegexStepType.selectState ||
      stepType == FAToRegexStepType.findIncoming ||
      stepType == FAToRegexStepType.findOutgoing ||
      stepType == FAToRegexStepType.findSelfLoop ||
      stepType == FAToRegexStepType.createBypass ||
      stepType == FAToRegexStepType.completeElimination;

  /// Checks if this step adds a new state for normalization
  bool get addsState =>
      stepType == FAToRegexStepType.addInitialState ||
      stepType == FAToRegexStepType.addFinalState;

  /// Checks if this step has a self-loop
  bool get hasSelfLoop =>
      selfLoopTransitions != null && selfLoopTransitions!.isNotEmpty;

  /// Checks if this step creates new transitions
  bool get createsTransitions =>
      newTransitions != null && newTransitions!.isNotEmpty;

  /// Checks if this step combines regex expressions
  bool get combinesRegex =>
      stepType == FAToRegexStepType.combineTransitions ||
      (combinedRegexes != null && combinedRegexes!.length > 1);

  /// Gets the state count change in this step
  int? get stateCountChange {
    if (currentStateCount != null && remainingStateCount != null) {
      return remainingStateCount! - currentStateCount!;
    }
    return null;
  }
}

/// Types of steps in FA to Regex conversion
enum FAToRegexStepType {
  /// Validating the input automaton
  validation,

  /// Adding a new unique initial state
  addInitialState,

  /// Adding a new unique final state
  addFinalState,

  /// Selecting a state to eliminate
  selectState,

  /// Finding incoming transitions to the state
  findIncoming,

  /// Finding outgoing transitions from the state
  findOutgoing,

  /// Finding and processing self-loop transitions
  findSelfLoop,

  /// Creating bypass transitions
  createBypass,

  /// Combining parallel transitions
  combineTransitions,

  /// Completing the elimination of a state
  completeElimination,

  /// Extracting the final regex
  extractRegex,

  /// Conversion completion
  completion,
}

/// Extension methods for FAToRegexStepType
extension FAToRegexStepTypeExtension on FAToRegexStepType {
  /// Gets a human-readable name for the step type
  String get displayName {
    switch (this) {
      case FAToRegexStepType.validation:
        return 'Validation';
      case FAToRegexStepType.addInitialState:
        return 'Add Initial State';
      case FAToRegexStepType.addFinalState:
        return 'Add Final State';
      case FAToRegexStepType.selectState:
        return 'Select State';
      case FAToRegexStepType.findIncoming:
        return 'Find Incoming';
      case FAToRegexStepType.findOutgoing:
        return 'Find Outgoing';
      case FAToRegexStepType.findSelfLoop:
        return 'Find Self-Loop';
      case FAToRegexStepType.createBypass:
        return 'Create Bypass';
      case FAToRegexStepType.combineTransitions:
        return 'Combine Transitions';
      case FAToRegexStepType.completeElimination:
        return 'Complete Elimination';
      case FAToRegexStepType.extractRegex:
        return 'Extract Regex';
      case FAToRegexStepType.completion:
        return 'Completion';
    }
  }

  /// Gets a description of what this step type does
  String get description {
    switch (this) {
      case FAToRegexStepType.validation:
        return 'Validates that the input automaton is well-formed';
      case FAToRegexStepType.addInitialState:
        return 'Adds a new unique initial state for normalization';
      case FAToRegexStepType.addFinalState:
        return 'Adds a new unique final state for normalization';
      case FAToRegexStepType.selectState:
        return 'Selects the next state to eliminate from the automaton';
      case FAToRegexStepType.findIncoming:
        return 'Finds all transitions coming into the state to be eliminated';
      case FAToRegexStepType.findOutgoing:
        return 'Finds all transitions going out from the state to be eliminated';
      case FAToRegexStepType.findSelfLoop:
        return 'Finds and processes self-loop transitions on the state';
      case FAToRegexStepType.createBypass:
        return 'Creates new transitions to bypass the eliminated state';
      case FAToRegexStepType.combineTransitions:
        return 'Combines multiple parallel transitions using regex union';
      case FAToRegexStepType.completeElimination:
        return 'Completes the elimination of a state from the automaton';
      case FAToRegexStepType.extractRegex:
        return 'Extracts the final regular expression from the simplified automaton';
      case FAToRegexStepType.completion:
        return 'Marks the completion of the FA to Regex conversion';
    }
  }
}
