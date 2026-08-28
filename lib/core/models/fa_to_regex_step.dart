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
import '../messages/structured_message.dart';
import 'state.dart';
import 'fsa_transition.dart';

const faToRegexTitleMessageProperty = 'faToRegexTitleMessage';
const faToRegexExplanationMessageProperty = 'faToRegexExplanationMessage';

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
      incomingStates: incomingStates != null
          ? Set.unmodifiable(incomingStates)
          : null,
      incomingTransitions: incomingTransitions != null
          ? Set.unmodifiable(incomingTransitions)
          : null,
      outgoingStates: outgoingStates != null
          ? Set.unmodifiable(outgoingStates)
          : null,
      outgoingTransitions: outgoingTransitions != null
          ? Set.unmodifiable(outgoingTransitions)
          : null,
      selfLoopTransitions: selfLoopTransitions != null
          ? Set.unmodifiable(selfLoopTransitions)
          : null,
      selfLoopRegex: selfLoopRegex,
      newTransitions: newTransitions != null
          ? Set.unmodifiable(newTransitions)
          : null,
      combinedRegexes: combinedRegexes != null
          ? List.unmodifiable(combinedRegexes)
          : null,
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
      baseStep: _faToRegexBaseStep(
        id: id,
        stepNumber: stepNumber,
        stepType: FAToRegexStepType.validation,
        arguments: {
          'state-count': StructuredMessageArgument.count(stateCount),
          'transition-count': StructuredMessageArgument.count(transitionCount),
          'has-initial-state': StructuredMessageArgument.boolean(
            hasInitialState,
            role: 'automaton-validation',
          ),
          'has-accepting-states': StructuredMessageArgument.boolean(
            hasAcceptingStates,
            role: 'automaton-validation',
          ),
        },
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
      baseStep: _faToRegexBaseStep(
        id: id,
        stepNumber: stepNumber,
        stepType: FAToRegexStepType.addInitialState,
        titleState: newInitialState.label,
        arguments: {
          'new-state': _faToRegexLiteral(newInitialState.label, 'state-label'),
          'old-state': _faToRegexLiteral(oldInitialState.label, 'state-label'),
        },
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
    final oldLabels = _faToRegexStateLabels(oldAcceptingStates);
    return FAToRegexStep(
      baseStep: _faToRegexBaseStep(
        id: id,
        stepNumber: stepNumber,
        stepType: FAToRegexStepType.addFinalState,
        titleState: newFinalState.label,
        arguments: {
          'new-state': _faToRegexLiteral(newFinalState.label, 'state-label'),
          'old-states': _faToRegexLiteral(oldLabels, 'state-labels'),
        },
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
      baseStep: _faToRegexBaseStep(
        id: id,
        stepNumber: stepNumber,
        stepType: FAToRegexStepType.selectState,
        titleState: state.label,
        arguments: {
          'state': _faToRegexLiteral(state.label, 'state-label'),
          'remaining-state-count': StructuredMessageArgument.count(
            remainingStates,
          ),
        },
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
    final stateLabels = _faToRegexStateLabels(incomingStates);
    return FAToRegexStep(
      baseStep: _faToRegexBaseStep(
        id: id,
        stepNumber: stepNumber,
        stepType: FAToRegexStepType.findIncoming,
        titleState: eliminatedState.label,
        arguments: {
          'state': _faToRegexLiteral(eliminatedState.label, 'state-label'),
          'transition-count': StructuredMessageArgument.count(
            incomingTransitions.length,
          ),
          'states': _faToRegexLiteral(stateLabels, 'state-labels'),
        },
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
    final stateLabels = _faToRegexStateLabels(outgoingStates);
    return FAToRegexStep(
      baseStep: _faToRegexBaseStep(
        id: id,
        stepNumber: stepNumber,
        stepType: FAToRegexStepType.findOutgoing,
        titleState: eliminatedState.label,
        arguments: {
          'state': _faToRegexLiteral(eliminatedState.label, 'state-label'),
          'transition-count': StructuredMessageArgument.count(
            outgoingTransitions.length,
          ),
          'states': _faToRegexLiteral(stateLabels, 'state-labels'),
        },
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
    return FAToRegexStep(
      baseStep: _faToRegexBaseStep(
        id: id,
        stepNumber: stepNumber,
        stepType: FAToRegexStepType.findSelfLoop,
        titleState: eliminatedState.label,
        arguments: {
          'state': _faToRegexLiteral(eliminatedState.label, 'state-label'),
          'has-loop': StructuredMessageArgument.boolean(
            selfLoopTransitions.isNotEmpty,
            role: 'self-loop-presence',
          ),
          'self-loop-regex': _faToRegexLiteral(
            selfLoopRegex,
            'regular-expression',
          ),
        },
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
      baseStep: _faToRegexBaseStep(
        id: id,
        stepNumber: stepNumber,
        stepType: FAToRegexStepType.createBypass,
        titleState: eliminatedState.label,
        arguments: {
          'state': _faToRegexLiteral(eliminatedState.label, 'state-label'),
          'transition-count': StructuredMessageArgument.count(
            newTransitions.length,
          ),
          'path-regex': _faToRegexLiteral(
            pathRegexExample,
            'regular-expression',
          ),
        },
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
      baseStep: _faToRegexBaseStep(
        id: id,
        stepNumber: stepNumber,
        stepType: FAToRegexStepType.combineTransitions,
        arguments: {
          'from-state': _faToRegexLiteral(fromState.label, 'state-label'),
          'to-state': _faToRegexLiteral(toState.label, 'state-label'),
          'regex-count': StructuredMessageArgument.count(
            combinedRegexes.length,
          ),
          'regexes': _faToRegexLiteral(
            combinedRegexes.join(', '),
            'regular-expressions',
          ),
          'resulting-regex': _faToRegexLiteral(
            resultingRegex,
            'regular-expression',
          ),
        },
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
      baseStep: _faToRegexBaseStep(
        id: id,
        stepNumber: stepNumber,
        stepType: FAToRegexStepType.completeElimination,
        titleState: eliminatedState.label,
        arguments: {
          'state': _faToRegexLiteral(eliminatedState.label, 'state-label'),
          'remaining-state-count': StructuredMessageArgument.count(
            remainingStates,
          ),
        },
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
      baseStep: _faToRegexBaseStep(
        id: id,
        stepNumber: stepNumber,
        stepType: FAToRegexStepType.extractRegex,
        arguments: {
          'initial-state': _faToRegexLiteral(initialState.label, 'state-label'),
          'final-state': _faToRegexLiteral(finalState.label, 'state-label'),
          'regex': _faToRegexLiteral(regex, 'regular-expression'),
        },
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
      baseStep: _faToRegexBaseStep(
        id: id,
        stepNumber: stepNumber,
        stepType: FAToRegexStepType.completion,
        arguments: {
          'original-state-count': StructuredMessageArgument.count(
            originalStates,
          ),
          'regex': _faToRegexLiteral(finalRegex, 'regular-expression'),
          'step-count': StructuredMessageArgument.count(stepsExecuted),
        },
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
      'incomingTransitions': incomingTransitions
          ?.map((t) => t.toJson())
          .toList(),
      'outgoingStates': outgoingStates?.map((s) => s.toJson()).toList(),
      'outgoingTransitions': outgoingTransitions
          ?.map((t) => t.toJson())
          .toList(),
      'selfLoopTransitions': selfLoopTransitions
          ?.map((t) => t.toJson())
          .toList(),
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
      combinedRegexes: (json['combinedRegexes'] as List?)
          ?.map((r) => r as String)
          .toList(),
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

  /// Locale-neutral title contract resolved at the presentation boundary.
  StructuredMessage? get titleMessage =>
      _faToRegexMessageProperty(baseStep, faToRegexTitleMessageProperty);

  /// Locale-neutral explanation contract resolved at the presentation
  /// boundary.
  StructuredMessage? get explanationMessage =>
      _faToRegexMessageProperty(baseStep, faToRegexExplanationMessageProperty);

  /// Compatibility code for callers awaiting presentation resolution.
  String get eliminationSummary => eliminationSummaryMessage.stableCode;

  /// Locale-neutral summary of the state elimination operation.
  StructuredMessage get eliminationSummaryMessage => _faToRegexStepMessage(
    'elimination-summary',
    arguments: {
      'has-state': StructuredMessageArgument.boolean(
        eliminatedState != null,
        role: 'state-elimination-presence',
      ),
      'state': _faToRegexLiteral(eliminatedState?.label ?? '', 'state-label'),
      'incoming-state-count': StructuredMessageArgument.count(
        incomingStates?.length ?? 0,
      ),
      'outgoing-state-count': StructuredMessageArgument.count(
        outgoingStates?.length ?? 0,
      ),
      'has-self-loop': StructuredMessageArgument.boolean(
        selfLoopTransitions?.isNotEmpty ?? false,
        role: 'self-loop-presence',
      ),
    },
  );

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

AlgorithmStep _faToRegexBaseStep({
  required String id,
  required int stepNumber,
  required FAToRegexStepType stepType,
  String titleState = '',
  Map<String, StructuredMessageArgument> arguments = const {},
}) {
  final titleMessage = _faToRegexStepMessage(
    'title',
    arguments: {
      'type': StructuredMessageArgument.outcome(
        stepType.name,
        role: 'fa-to-regex-step-type',
      ),
      'state': _faToRegexLiteral(titleState, 'state-label'),
    },
  );
  final explanationMessage = _faToRegexStepMessage(
    '${_faToRegexStepCode(stepType)}-explanation',
    arguments: arguments,
  );
  return AlgorithmStep(
    id: id,
    stepNumber: stepNumber,
    title: titleMessage.stableCode,
    explanation: explanationMessage.stableCode,
    type: AlgorithmType.faToRegex,
    properties: {
      faToRegexTitleMessageProperty: titleMessage.toJson(),
      faToRegexExplanationMessageProperty: explanationMessage.toJson(),
    },
  );
}

StructuredMessage _faToRegexStepMessage(
  String code, {
  Map<String, StructuredMessageArgument> arguments = const {},
}) => StructuredMessage(
  namespace: 'automaton.fa-to-regex.step',
  code: code,
  category: StructuredMessageCategory.transformation,
  severity: StructuredMessageSeverity.information,
  arguments: arguments,
);

StructuredMessageArgument _faToRegexLiteral(String value, String role) =>
    StructuredMessageArgument.literal(value, role: role);

String _faToRegexStateLabels(Set<State> states) {
  if (states.isEmpty) return '∅';
  final labels = states.map((state) => state.label).toList()..sort();
  return labels.join(', ');
}

StructuredMessage? _faToRegexMessageProperty(AlgorithmStep step, String key) {
  final raw = step.properties[key];
  if (raw is! Map) return null;
  try {
    return StructuredMessage.fromJson(Map<String, Object?>.from(raw));
  } on FormatException {
    return null;
  }
}

String _faToRegexStepCode(FAToRegexStepType type) => switch (type) {
  FAToRegexStepType.validation => 'validation',
  FAToRegexStepType.addInitialState => 'add-initial-state',
  FAToRegexStepType.addFinalState => 'add-final-state',
  FAToRegexStepType.selectState => 'select-state',
  FAToRegexStepType.findIncoming => 'find-incoming',
  FAToRegexStepType.findOutgoing => 'find-outgoing',
  FAToRegexStepType.findSelfLoop => 'find-self-loop',
  FAToRegexStepType.createBypass => 'create-bypass',
  FAToRegexStepType.combineTransitions => 'combine-transitions',
  FAToRegexStepType.completeElimination => 'complete-elimination',
  FAToRegexStepType.extractRegex => 'extract-regex',
  FAToRegexStepType.completion => 'completion',
};

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
  /// Compatibility code for callers awaiting presentation resolution.
  String get displayName => labelMessage.stableCode;

  /// Compatibility code for callers awaiting presentation resolution.
  String get description => descriptionMessage.stableCode;

  StructuredMessage get labelMessage =>
      _faToRegexStepTypeMessage('label', this);

  StructuredMessage get descriptionMessage =>
      _faToRegexStepTypeMessage('description', this);
}

StructuredMessage _faToRegexStepTypeMessage(
  String code,
  FAToRegexStepType type,
) => StructuredMessage(
  namespace: 'automaton.fa-to-regex.step-type',
  code: code,
  category: StructuredMessageCategory.transformation,
  severity: StructuredMessageSeverity.information,
  arguments: {
    'type': StructuredMessageArgument.outcome(
      type.name,
      role: 'fa-to-regex-step-type',
    ),
  },
);
