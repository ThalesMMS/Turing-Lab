//
//  nfa_to_dfa_step.dart
//  Turing Lab
//
//  Defines the detailed step model for NFA→DFA conversion via subset
//  construction. Captures ε-closures, processed symbols, source/destination
//  state sets, and textual explanations for each algorithm step, enabling
//  educational step-by-step visualization.
//
//  Thales Matheus Mendonça Santos - January 2026
//

import 'algorithm_step.dart';
import 'state.dart';
import 'step_explanation.dart';

/// Represents a single step in NFA to DFA conversion using subset construction.
///
/// TODO(#143): Keep for algorithm-internal construction. UI consumers should
/// use [toProperties] through generic [AlgorithmStep.properties].
class NFAToDFAStep {
  /// Base algorithm step information
  final AlgorithmStep baseStep;

  /// Type of operation performed in this step
  final NFAToDFAStepType stepType;

  /// Current state set being processed (NFA states that form a DFA state)
  final Set<State> currentStateSet;

  /// Symbol being processed in this step (null for epsilon closure steps)
  final String? processedSymbol;

  /// Epsilon closure computed in this step
  final Set<State>? epsilonClosure;

  /// States reachable on the processed symbol
  final Set<State>? reachableStates;

  /// Next state set computed (target DFA state)
  final Set<State>? nextStateSet;

  /// Whether the current state set contains any accepting states
  final bool isAcceptingState;

  /// Whether this state set is being processed for the first time
  final bool isNewState;

  /// DFA state ID created for this state set (if applicable)
  final String? dfaStateId;

  /// DFA state label created for this state set (if applicable)
  final String? dfaStateLabel;

  const NFAToDFAStep._internal({
    required this.baseStep,
    required this.stepType,
    required this.currentStateSet,
    this.processedSymbol,
    this.epsilonClosure,
    this.reachableStates,
    this.nextStateSet,
    required this.isAcceptingState,
    required this.isNewState,
    this.dfaStateId,
    this.dfaStateLabel,
  });

  factory NFAToDFAStep({
    required AlgorithmStep baseStep,
    required NFAToDFAStepType stepType,
    required Set<State> currentStateSet,
    String? processedSymbol,
    Set<State>? epsilonClosure,
    Set<State>? reachableStates,
    Set<State>? nextStateSet,
    bool isAcceptingState = false,
    bool isNewState = false,
    String? dfaStateId,
    String? dfaStateLabel,
  }) {
    return NFAToDFAStep._internal(
      baseStep: baseStep,
      stepType: stepType,
      currentStateSet: Set.unmodifiable(currentStateSet),
      processedSymbol: processedSymbol,
      epsilonClosure:
          epsilonClosure != null ? Set.unmodifiable(epsilonClosure) : null,
      reachableStates:
          reachableStates != null ? Set.unmodifiable(reachableStates) : null,
      nextStateSet:
          nextStateSet != null ? Set.unmodifiable(nextStateSet) : null,
      isAcceptingState: isAcceptingState,
      isNewState: isNewState,
      dfaStateId: dfaStateId,
      dfaStateLabel: dfaStateLabel,
    );
  }

  /// Creates an initial epsilon closure step
  factory NFAToDFAStep.initialEpsilonClosure({
    required String id,
    required int stepNumber,
    required State initialState,
    required Set<State> epsilonClosure,
    required bool containsAcceptingState,
  }) {
    final stateLabels = epsilonClosure.map((s) => s.label).join(', ');
    return NFAToDFAStep(
      baseStep: AlgorithmStep(
        id: id,
        stepNumber: stepNumber,
        title: 'Compute initial ε-closure',
        explanation:
            'Computing ε-closure of initial state ${initialState.label}. '
            'This gives us the set of states reachable without consuming input: {$stateLabels}. '
            '${containsAcceptingState ? "This set contains an accepting state, so the initial DFA state will be accepting." : ""}',
        stepExplanation: StepExplanation(
          title: 'Initial DFA state is the ε-closure of the NFA start state',
          categories: const [ExplanationCategory.conversion],
          bullets: [
            'Start from NFA start state ${initialState.label}.',
            'Take ε-transitions without consuming input to reach {$stateLabels}.',
            if (containsAcceptingState)
              'Because this set includes an accepting NFA state, the corresponding DFA state will be accepting.',
          ],
          highlights: [
            HighlightTarget(
              type: HighlightTargetType.state,
              data: {'stateIds': epsilonClosure.map((s) => s.id).toList()},
            ),
          ],
        ),
        type: AlgorithmType.nfaToDfa,
      ),
      stepType: NFAToDFAStepType.epsilonClosure,
      currentStateSet: {initialState},
      epsilonClosure: epsilonClosure,
      isAcceptingState: containsAcceptingState,
      isNewState: true,
      dfaStateId: 'q0',
      dfaStateLabel: '{${epsilonClosure.map((s) => s.label).join(',')}}',
    );
  }

  /// Creates a step for processing a symbol
  factory NFAToDFAStep.processSymbol({
    required String id,
    required int stepNumber,
    required Set<State> currentStateSet,
    required String symbol,
    required Set<State> reachableStates,
  }) {
    final currentLabels = currentStateSet.map((s) => s.label).join(', ');
    final reachableLabels = reachableStates.map((s) => s.label).join(', ');
    return NFAToDFAStep(
      baseStep: AlgorithmStep(
        id: id,
        stepNumber: stepNumber,
        title: 'Process symbol \'$symbol\'',
        explanation:
            'From state set {$currentLabels}, processing symbol \'$symbol\'. '
            'Following NFA transitions on \'$symbol\' leads to states: {$reachableLabels}.',
        stepExplanation: StepExplanation(
          title: 'Follow NFA transitions on the current symbol',
          categories: const [ExplanationCategory.conversion],
          bullets: [
            'Current DFA state represents NFA set {$currentLabels}.',
            'On input symbol \'$symbol\', collect all NFA destinations reachable from any state in the set.',
            'Reachable before ε-closure: {$reachableLabels}.',
          ],
          highlights: [
            HighlightTarget(
              type: HighlightTargetType.state,
              data: {'stateIds': reachableStates.map((s) => s.id).toList()},
            ),
          ],
        ),
        type: AlgorithmType.nfaToDfa,
      ),
      stepType: NFAToDFAStepType.processSymbol,
      currentStateSet: currentStateSet,
      processedSymbol: symbol,
      reachableStates: reachableStates,
      isAcceptingState: false,
    );
  }

  /// Creates a step for computing epsilon closure of reachable states
  factory NFAToDFAStep.epsilonClosureOfReachable({
    required String id,
    required int stepNumber,
    required Set<State> reachableStates,
    required Set<State> epsilonClosure,
    required bool containsAcceptingState,
    required bool isNewState,
  }) {
    final reachableLabels = reachableStates.map((s) => s.label).join(', ');
    final closureLabels = epsilonClosure.map((s) => s.label).join(', ');
    return NFAToDFAStep(
      baseStep: AlgorithmStep(
        id: id,
        stepNumber: stepNumber,
        title: 'Compute ε-closure of reachable states',
        explanation: 'Computing ε-closure of {$reachableLabels}. '
            'Following ε-transitions gives us the complete state set: {$closureLabels}. '
            '${isNewState ? "This is a new DFA state that needs to be processed." : "This state set has already been processed."} '
            '${containsAcceptingState ? "This set contains an accepting state." : ""}',
        stepExplanation: StepExplanation(
          title: 'Close under ε-transitions to form the next DFA state',
          categories: const [ExplanationCategory.conversion],
          bullets: [
            'ε-transitions do not consume input, so they must be included in the DFA state definition.',
            'Starting from reachable states {$reachableLabels}, follow ε-transitions to get {$closureLabels}.',
            if (isNewState)
              'This set has not appeared before, so we will create (and later process) a new DFA state for it.'
            else
              'This set already has a corresponding DFA state, so we can reuse it.',
            if (containsAcceptingState)
              'Because this set includes an accepting NFA state, the DFA state will be accepting.',
          ],
          highlights: [
            HighlightTarget(
              type: HighlightTargetType.state,
              data: {'stateIds': epsilonClosure.map((s) => s.id).toList()},
            ),
          ],
        ),
        type: AlgorithmType.nfaToDfa,
      ),
      stepType: NFAToDFAStepType.epsilonClosure,
      currentStateSet: reachableStates,
      epsilonClosure: epsilonClosure,
      nextStateSet: epsilonClosure,
      isAcceptingState: containsAcceptingState,
      isNewState: isNewState,
    );
  }

  /// Creates a step for creating a new DFA state
  factory NFAToDFAStep.createDFAState({
    required String id,
    required int stepNumber,
    required Set<State> nfaStateSet,
    required String dfaStateId,
    required String dfaStateLabel,
    required bool isAccepting,
  }) {
    final stateLabels = nfaStateSet.map((s) => s.label).join(', ');
    return NFAToDFAStep(
      baseStep: AlgorithmStep(
        id: id,
        stepNumber: stepNumber,
        title: 'Create DFA state $dfaStateId',
        explanation:
            'Creating new DFA state $dfaStateId to represent NFA state set {$stateLabels}. '
            '${isAccepting ? "This is an accepting state because the NFA state set contains at least one accepting state." : "This is a non-accepting state."}',
        stepExplanation: StepExplanation(
          title: 'One DFA state represents an entire set of NFA states',
          categories: const [ExplanationCategory.conversion],
          bullets: [
            'Subset construction creates a DFA state for each distinct reachable NFA state set.',
            'This DFA state represents {$stateLabels}.',
            if (isAccepting)
              'It is accepting because at least one state in the set is accepting in the NFA.'
            else
              'It is non-accepting because none of the states in the set are accepting in the NFA.',
          ],
          highlights: [
            HighlightTarget(type: HighlightTargetType.state, id: dfaStateId),
            HighlightTarget(
              type: HighlightTargetType.state,
              data: {'stateIds': nfaStateSet.map((s) => s.id).toList()},
            ),
          ],
        ),
        type: AlgorithmType.nfaToDfa,
      ),
      stepType: NFAToDFAStepType.createState,
      currentStateSet: nfaStateSet,
      isAcceptingState: isAccepting,
      isNewState: true,
      dfaStateId: dfaStateId,
      dfaStateLabel: dfaStateLabel,
    );
  }

  /// Creates a step for creating a DFA transition
  factory NFAToDFAStep.createDFATransition({
    required String id,
    required int stepNumber,
    required Set<State> fromStateSet,
    required String fromDfaStateId,
    required String symbol,
    required Set<State> toStateSet,
    required String toDfaStateId,
  }) {
    final fromLabels = fromStateSet.map((s) => s.label).join(', ');
    final toLabels = toStateSet.map((s) => s.label).join(', ');
    return NFAToDFAStep(
      baseStep: AlgorithmStep(
        id: id,
        stepNumber: stepNumber,
        title: 'Create transition on \'$symbol\'',
        explanation:
            'Adding DFA transition: $fromDfaStateId --($symbol)--> $toDfaStateId. '
            'This represents moving from NFA state set {$fromLabels} to {$toLabels} on symbol \'$symbol\'.',
        stepExplanation: StepExplanation(
          title: 'DFA transitions summarize all possible NFA moves on a symbol',
          categories: const [ExplanationCategory.conversion],
          bullets: [
            'From NFA set {$fromLabels}, on \'$symbol\' you can reach {$toLabels} (after ε-closure).',
            'In the DFA, this becomes a single deterministic transition.',
          ],
          highlights: [
            HighlightTarget(
              type: HighlightTargetType.state,
              id: fromDfaStateId,
            ),
            HighlightTarget(type: HighlightTargetType.state, id: toDfaStateId),
            HighlightTarget(
              type: HighlightTargetType.transition,
              data: {
                'fromStateId': fromDfaStateId,
                'toStateId': toDfaStateId,
                'symbol': symbol,
              },
            ),
          ],
        ),
        type: AlgorithmType.nfaToDfa,
      ),
      stepType: NFAToDFAStepType.createTransition,
      currentStateSet: fromStateSet,
      processedSymbol: symbol,
      nextStateSet: toStateSet,
      isAcceptingState: false,
      dfaStateId: fromDfaStateId,
    );
  }

  /// Creates a completion step
  factory NFAToDFAStep.completion({
    required String id,
    required int stepNumber,
    required int totalStates,
    required int totalTransitions,
    required int totalAcceptingStates,
  }) {
    return NFAToDFAStep(
      baseStep: AlgorithmStep(
        id: id,
        stepNumber: stepNumber,
        title: 'Conversion complete',
        explanation: 'NFA to DFA conversion completed successfully. '
            'The resulting DFA has $totalStates states, $totalTransitions transitions, '
            'and $totalAcceptingStates accepting state(s). '
            'All reachable state sets have been processed.',
        stepExplanation: StepExplanation(
          title: 'All reachable subsets have been converted to DFA components',
          categories: const [ExplanationCategory.conversion],
          bullets: [
            'Created $totalStates DFA state(s).',
            'Created $totalTransitions transition(s).',
            'Marked $totalAcceptingStates accepting state(s).',
          ],
        ),
        type: AlgorithmType.nfaToDfa,
      ),
      stepType: NFAToDFAStepType.completion,
      currentStateSet: {},
      isAcceptingState: false,
      isNewState: false,
    );
  }

  /// Creates a copy of this step with updated properties
  NFAToDFAStep copyWith({
    AlgorithmStep? baseStep,
    NFAToDFAStepType? stepType,
    Set<State>? currentStateSet,
    String? processedSymbol,
    Set<State>? epsilonClosure,
    Set<State>? reachableStates,
    Set<State>? nextStateSet,
    bool? isAcceptingState,
    bool? isNewState,
    String? dfaStateId,
    String? dfaStateLabel,
  }) {
    return NFAToDFAStep(
      baseStep: baseStep ?? this.baseStep,
      stepType: stepType ?? this.stepType,
      currentStateSet: currentStateSet ?? this.currentStateSet,
      processedSymbol: processedSymbol ?? this.processedSymbol,
      epsilonClosure: epsilonClosure ?? this.epsilonClosure,
      reachableStates: reachableStates ?? this.reachableStates,
      nextStateSet: nextStateSet ?? this.nextStateSet,
      isAcceptingState: isAcceptingState ?? this.isAcceptingState,
      isNewState: isNewState ?? this.isNewState,
      dfaStateId: dfaStateId ?? this.dfaStateId,
      dfaStateLabel: dfaStateLabel ?? this.dfaStateLabel,
    );
  }

  /// Converts this specialized step to generic, JSON-friendly step properties.
  Map<String, dynamic> toProperties() {
    final properties = <String, dynamic>{
      'stepType': stepType.displayName,
      'isAcceptingState': isAcceptingState,
      'isNewState': isNewState,
    };

    _putStateIds(properties, 'currentStateIds', currentStateSet);
    _putStateIds(properties, 'epsilonClosureIds', epsilonClosure);
    _putStateIds(properties, 'reachableStateIds', reachableStates);
    _putStateIds(properties, 'nextStateIds', nextStateSet);
    _putIfNotNull(properties, 'processedSymbol', processedSymbol);
    _putIfNotNull(properties, 'dfaStateId', dfaStateId);
    _putIfNotNull(properties, 'dfaStateLabel', dfaStateLabel);

    return Map<String, dynamic>.unmodifiable(properties);
  }

  /// Converts the step to a JSON representation
  Map<String, dynamic> toJson() {
    return {
      'baseStep': baseStep.toJson(),
      'stepType': stepType.name,
      'currentStateSet': currentStateSet.map((s) => s.toJson()).toList(),
      'processedSymbol': processedSymbol,
      'epsilonClosure': epsilonClosure?.map((s) => s.toJson()).toList(),
      'reachableStates': reachableStates?.map((s) => s.toJson()).toList(),
      'nextStateSet': nextStateSet?.map((s) => s.toJson()).toList(),
      'isAcceptingState': isAcceptingState,
      'isNewState': isNewState,
      'dfaStateId': dfaStateId,
      'dfaStateLabel': dfaStateLabel,
    };
  }

  /// Creates a step from a JSON representation
  factory NFAToDFAStep.fromJson(Map<String, dynamic> json) {
    return NFAToDFAStep(
      baseStep: AlgorithmStep.fromJson(
        json['baseStep'] as Map<String, dynamic>,
      ),
      stepType: NFAToDFAStepType.values.firstWhere(
        (e) => e.name == json['stepType'],
        orElse: () => NFAToDFAStepType.epsilonClosure,
      ),
      currentStateSet: (json['currentStateSet'] as List?)
              ?.map((s) => State.fromJson(s as Map<String, dynamic>))
              .toSet() ??
          {},
      processedSymbol: json['processedSymbol'] as String?,
      epsilonClosure: (json['epsilonClosure'] as List?)
          ?.map((s) => State.fromJson(s as Map<String, dynamic>))
          .toSet(),
      reachableStates: (json['reachableStates'] as List?)
          ?.map((s) => State.fromJson(s as Map<String, dynamic>))
          .toSet(),
      nextStateSet: (json['nextStateSet'] as List?)
          ?.map((s) => State.fromJson(s as Map<String, dynamic>))
          .toSet(),
      isAcceptingState: json['isAcceptingState'] as bool? ?? false,
      isNewState: json['isNewState'] as bool? ?? false,
      dfaStateId: json['dfaStateId'] as String?,
      dfaStateLabel: json['dfaStateLabel'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NFAToDFAStep &&
        other.baseStep == baseStep &&
        other.stepType == stepType &&
        other.processedSymbol == processedSymbol &&
        other.isAcceptingState == isAcceptingState &&
        other.isNewState == isNewState &&
        other.dfaStateId == dfaStateId &&
        other.dfaStateLabel == dfaStateLabel;
  }

  @override
  int get hashCode {
    return Object.hash(
      baseStep,
      stepType,
      processedSymbol,
      isAcceptingState,
      isNewState,
      dfaStateId,
      dfaStateLabel,
    );
  }

  @override
  String toString() {
    return 'NFAToDFAStep(stepNumber: ${baseStep.stepNumber}, '
        'type: ${stepType.name}, title: ${baseStep.title})';
  }

  /// Gets the step number
  int get stepNumber => baseStep.stepNumber;

  /// Gets the step title
  String get title => baseStep.title;

  /// Gets the step explanation
  String get explanation => baseStep.explanation;

  /// Gets a summary of state sets involved
  String get stateSetsSummary {
    final buffer = StringBuffer();
    buffer.write('Current: {${_stateSetLabels(currentStateSet)}}');

    if (epsilonClosure != null) {
      buffer.write(' → ε-closure: {${_stateSetLabels(epsilonClosure!)}}');
    }

    if (reachableStates != null) {
      buffer.write(' → reachable: {${_stateSetLabels(reachableStates!)}}');
    }

    if (nextStateSet != null) {
      buffer.write(' → next: {${_stateSetLabels(nextStateSet!)}}');
    }

    return buffer.toString();
  }

  /// Helper to get comma-separated state labels
  String _stateSetLabels(Set<State> states) {
    return states.map((s) => s.label).join(', ');
  }

  /// Gets the number of states in the current state set
  int get currentStateSetSize => currentStateSet.length;

  /// Gets the number of states in the epsilon closure (if computed)
  int? get epsilonClosureSize => epsilonClosure?.length;

  /// Checks if this step involves epsilon transitions
  bool get hasEpsilonClosure => epsilonClosure != null;

  /// Checks if this step processes a symbol
  bool get processesSymbol => processedSymbol != null;

  /// Checks if this step creates a new DFA component
  bool get createsNewComponent =>
      stepType == NFAToDFAStepType.createState ||
      stepType == NFAToDFAStepType.createTransition;

  static void _putStateIds(
    Map<String, dynamic> properties,
    String key,
    Set<State>? states,
  ) {
    final ids = states
        ?.map((state) => state.id.trim())
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    if (ids != null && ids.isNotEmpty) {
      properties[key] = ids;
    }
  }

  static void _putIfNotNull(
    Map<String, dynamic> properties,
    String key,
    Object? value,
  ) {
    if (value != null) {
      properties[key] = value;
    }
  }
}

/// Types of steps in NFA to DFA conversion
enum NFAToDFAStepType {
  /// Computing epsilon closure of a state set
  epsilonClosure,

  /// Processing a symbol from a state set
  processSymbol,

  /// Creating a new DFA state
  createState,

  /// Creating a new DFA transition
  createTransition,

  /// Conversion completion
  completion,
}

/// Extension methods for NFAToDFAStepType
extension NFAToDFAStepTypeExtension on NFAToDFAStepType {
  /// Gets a human-readable name for the step type
  String get displayName {
    switch (this) {
      case NFAToDFAStepType.epsilonClosure:
        return 'Epsilon Closure';
      case NFAToDFAStepType.processSymbol:
        return 'Process Symbol';
      case NFAToDFAStepType.createState:
        return 'Create DFA State';
      case NFAToDFAStepType.createTransition:
        return 'Create DFA Transition';
      case NFAToDFAStepType.completion:
        return 'Completion';
    }
  }

  /// Gets a description of what this step type does
  String get description {
    switch (this) {
      case NFAToDFAStepType.epsilonClosure:
        return 'Computes all states reachable via epsilon transitions';
      case NFAToDFAStepType.processSymbol:
        return 'Finds states reachable on a specific input symbol';
      case NFAToDFAStepType.createState:
        return 'Creates a new state in the resulting DFA';
      case NFAToDFAStepType.createTransition:
        return 'Adds a transition to the resulting DFA';
      case NFAToDFAStepType.completion:
        return 'Marks the completion of the conversion algorithm';
    }
  }
}
