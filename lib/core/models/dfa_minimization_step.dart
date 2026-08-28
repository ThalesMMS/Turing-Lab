//
//  dfa_minimization_step.dart
//  Turing Lab
//
//  Defines the detailed step model for DFA minimization via Hopcroft's
//  algorithm. Captures partitions, equivalence classes, distinguishing
//  symbols, predecessors, and partition refinements for each stage, enabling
//  educational step-by-step visualization of minimization.
//
//  Thales Matheus Mendonça Santos - January 2026
//

import 'algorithm_step.dart';
import '../messages/structured_message.dart';
import 'dfa_minimization_step_messages.dart';
import 'state.dart';

/// Represents a single step in DFA minimization using Hopcroft's algorithm.
///
/// TODO(#143): Keep for algorithm-internal construction. UI consumers should
/// use [toProperties] through generic [AlgorithmStep.properties].
class DFAMinimizationStep {
  /// Base algorithm step information
  final AlgorithmStep baseStep;

  /// Type of operation performed in this step
  final DFAMinimizationStepType stepType;

  /// Current partition of states (list of equivalence classes)
  final List<Set<State>> currentPartition;

  /// Equivalence class being processed from worklist (null for non-processing steps)
  final Set<State>? processingSet;

  /// Symbol being used to refine the partition
  final String? distinguishingSymbol;

  /// Predecessor states (states that transition to processing set on symbol)
  final Set<State>? predecessors;

  /// Equivalence class being split (null if no split occurs)
  final Set<State>? splitSet;

  /// States in split set that are predecessors (intersection)
  final Set<State>? splitIntersection;

  /// States in split set that are not predecessors (difference)
  final Set<State>? splitDifference;

  /// New partition after refinement (null if no refinement)
  final List<Set<State>>? newPartition;

  /// Number of equivalence classes in current partition
  final int partitionSize;

  /// Whether this step resulted in a split
  final bool causedSplit;

  /// Equivalence class ID being created (for final state creation)
  final String? equivalenceClassId;

  /// States that form this equivalence class (for final state creation)
  final Set<State>? equivalenceClassStates;

  const DFAMinimizationStep._internal({
    required this.baseStep,
    required this.stepType,
    required this.currentPartition,
    this.processingSet,
    this.distinguishingSymbol,
    this.predecessors,
    this.splitSet,
    this.splitIntersection,
    this.splitDifference,
    this.newPartition,
    required this.partitionSize,
    required this.causedSplit,
    this.equivalenceClassId,
    this.equivalenceClassStates,
  });

  factory DFAMinimizationStep({
    required AlgorithmStep baseStep,
    required DFAMinimizationStepType stepType,
    required List<Set<State>> currentPartition,
    Set<State>? processingSet,
    String? distinguishingSymbol,
    Set<State>? predecessors,
    Set<State>? splitSet,
    Set<State>? splitIntersection,
    Set<State>? splitDifference,
    List<Set<State>>? newPartition,
    int? partitionSize,
    bool causedSplit = false,
    String? equivalenceClassId,
    Set<State>? equivalenceClassStates,
  }) {
    return DFAMinimizationStep._internal(
      baseStep: baseStep,
      stepType: stepType,
      currentPartition: List.unmodifiable(
        currentPartition.map((set) => Set<State>.unmodifiable(set)).toList(),
      ),
      processingSet: processingSet != null
          ? Set.unmodifiable(processingSet)
          : null,
      distinguishingSymbol: distinguishingSymbol,
      predecessors: predecessors != null
          ? Set.unmodifiable(predecessors)
          : null,
      splitSet: splitSet != null ? Set.unmodifiable(splitSet) : null,
      splitIntersection: splitIntersection != null
          ? Set.unmodifiable(splitIntersection)
          : null,
      splitDifference: splitDifference != null
          ? Set.unmodifiable(splitDifference)
          : null,
      newPartition: newPartition != null
          ? List.unmodifiable(
              newPartition.map((set) => Set<State>.unmodifiable(set)).toList(),
            )
          : null,
      partitionSize: partitionSize ?? currentPartition.length,
      causedSplit: causedSplit,
      equivalenceClassId: equivalenceClassId,
      equivalenceClassStates: equivalenceClassStates != null
          ? Set.unmodifiable(equivalenceClassStates)
          : null,
    );
  }

  /// Creates an initial partition step
  factory DFAMinimizationStep.initialPartition({
    required String id,
    required int stepNumber,
    required Set<State> acceptingStates,
    required Set<State> nonAcceptingStates,
  }) {
    final partition = <Set<State>>[
      if (acceptingStates.isNotEmpty) acceptingStates,
      if (nonAcceptingStates.isNotEmpty) nonAcceptingStates,
    ];

    final acceptingLabels = acceptingStates.map((s) => s.label).join(', ');
    final nonAcceptingLabels = nonAcceptingStates
        .map((s) => s.label)
        .join(', ');
    final titleMessage = DfaMinimizationStepMessages.initialPartitionTitle();
    final explanationMessage =
        DfaMinimizationStepMessages.initialPartitionExplanation(
          acceptingStates: acceptingLabels,
          nonAcceptingStates: nonAcceptingLabels,
        );

    return DFAMinimizationStep(
      baseStep: _dfaMinimizationBaseStep(
        id: id,
        stepNumber: stepNumber,
        title: 'Create initial partition',
        explanation:
            'Starting DFA minimization by creating the initial partition. '
            'We split states into two equivalence classes: accepting states {$acceptingLabels} '
            'and non-accepting states {$nonAcceptingLabels}. States in different classes cannot be equivalent.',
        titleMessage: titleMessage,
        explanationMessage: explanationMessage,
      ),
      stepType: DFAMinimizationStepType.initialPartition,
      currentPartition: partition,
      partitionSize: partition.length,
    );
  }

  /// Creates a step for removing unreachable states
  factory DFAMinimizationStep.removeUnreachable({
    required String id,
    required int stepNumber,
    required Set<State> unreachableStates,
    required Set<State> reachableStates,
  }) {
    final unreachableLabels = unreachableStates.map((s) => s.label).join(', ');
    final titleMessage = DfaMinimizationStepMessages.removeUnreachableTitle();
    final explanationMessage =
        DfaMinimizationStepMessages.removeUnreachableExplanation(
          unreachableStates: unreachableLabels,
          reachableStateCount: reachableStates.length,
        );
    return DFAMinimizationStep(
      baseStep: _dfaMinimizationBaseStep(
        id: id,
        stepNumber: stepNumber,
        title: 'Remove unreachable states',
        explanation:
            'Removing unreachable states before minimization: {$unreachableLabels}. '
            'These states cannot be reached from the initial state and do not affect the language accepted by the DFA. '
            'Remaining ${reachableStates.length} reachable state(s).',
        titleMessage: titleMessage,
        explanationMessage: explanationMessage,
      ),
      stepType: DFAMinimizationStepType.removeUnreachable,
      currentPartition: [],
      partitionSize: 0,
    );
  }

  /// Creates a step for selecting a set to process
  factory DFAMinimizationStep.selectProcessingSet({
    required String id,
    required int stepNumber,
    required List<Set<State>> currentPartition,
    required Set<State> processingSet,
  }) {
    final setLabels = processingSet.map((s) => s.label).join(', ');
    final titleMessage = DfaMinimizationStepMessages.selectSetTitle();
    final explanationMessage = DfaMinimizationStepMessages.selectSetExplanation(
      setLabels,
    );
    return DFAMinimizationStep(
      baseStep: _dfaMinimizationBaseStep(
        id: id,
        stepNumber: stepNumber,
        title: 'Select set to process',
        explanation:
            'Selecting equivalence class {$setLabels} from the worklist to process. '
            'We will check if any other equivalence classes can be split based on transitions to this set.',
        titleMessage: titleMessage,
        explanationMessage: explanationMessage,
      ),
      stepType: DFAMinimizationStepType.selectSet,
      currentPartition: currentPartition,
      processingSet: processingSet,
    );
  }

  /// Creates a step for finding predecessors
  factory DFAMinimizationStep.findPredecessors({
    required String id,
    required int stepNumber,
    required List<Set<State>> currentPartition,
    required Set<State> processingSet,
    required String symbol,
    required Set<State> predecessors,
  }) {
    final setLabels = processingSet.map((s) => s.label).join(', ');
    final predLabels = predecessors.isNotEmpty
        ? predecessors.map((s) => s.label).join(', ')
        : 'none';
    final titleMessage = DfaMinimizationStepMessages.findPredecessorsTitle(
      symbol,
    );
    final explanationMessage =
        DfaMinimizationStepMessages.findPredecessorsExplanation(
          states: setLabels,
          symbol: symbol,
          predecessors: predecessors.isNotEmpty ? predLabels : '',
          hasPredecessors: predecessors.isNotEmpty,
        );
    return DFAMinimizationStep(
      baseStep: _dfaMinimizationBaseStep(
        id: id,
        stepNumber: stepNumber,
        title: 'Find predecessors on \'$symbol\'',
        explanation:
            'Finding all states that transition to {$setLabels} on symbol \'$symbol\'. '
            'Predecessors: {$predLabels}. '
            '${predecessors.isEmpty ? "No predecessors found, so no split will occur." : "We will use these to refine the partition."}',
        titleMessage: titleMessage,
        explanationMessage: explanationMessage,
      ),
      stepType: DFAMinimizationStepType.findPredecessors,
      currentPartition: currentPartition,
      processingSet: processingSet,
      distinguishingSymbol: symbol,
      predecessors: predecessors,
    );
  }

  /// Creates a step for splitting an equivalence class
  factory DFAMinimizationStep.splitClass({
    required String id,
    required int stepNumber,
    required List<Set<State>> currentPartition,
    required Set<State> splitSet,
    required Set<State> intersection,
    required Set<State> difference,
    required String symbol,
    required List<Set<State>> newPartition,
  }) {
    final splitLabels = splitSet.map((s) => s.label).join(', ');
    final intersectionLabels = intersection.map((s) => s.label).join(', ');
    final differenceLabels = difference.map((s) => s.label).join(', ');
    final titleMessage = DfaMinimizationStepMessages.splitClassTitle();
    final explanationMessage =
        DfaMinimizationStepMessages.splitClassExplanation(
          splitStates: splitLabels,
          symbol: symbol,
          intersectionStates: intersectionLabels,
          differenceStates: differenceLabels,
          oldPartitionSize: currentPartition.length,
          newPartitionSize: newPartition.length,
        );

    return DFAMinimizationStep(
      baseStep: _dfaMinimizationBaseStep(
        id: id,
        stepNumber: stepNumber,
        title: 'Split equivalence class',
        explanation:
            'Splitting equivalence class {$splitLabels} based on symbol \'$symbol\'. '
            'States that can reach the processing set: {$intersectionLabels}. '
            'States that cannot: {$differenceLabels}. '
            'These two groups are not equivalent and must be in separate classes. '
            'Partition size: ${currentPartition.length} → ${newPartition.length}.',
        titleMessage: titleMessage,
        explanationMessage: explanationMessage,
      ),
      stepType: DFAMinimizationStepType.splitClass,
      currentPartition: currentPartition,
      distinguishingSymbol: symbol,
      splitSet: splitSet,
      splitIntersection: intersection,
      splitDifference: difference,
      newPartition: newPartition,
      partitionSize: newPartition.length,
      causedSplit: true,
    );
  }

  /// Creates a step for when no split occurs
  factory DFAMinimizationStep.noSplit({
    required String id,
    required int stepNumber,
    required List<Set<State>> currentPartition,
    required Set<State> checkedSet,
    required String symbol,
  }) {
    final setLabels = checkedSet.map((s) => s.label).join(', ');
    final titleMessage = DfaMinimizationStepMessages.noSplitTitle(symbol);
    final explanationMessage = DfaMinimizationStepMessages.noSplitExplanation(
      states: setLabels,
      symbol: symbol,
    );
    return DFAMinimizationStep(
      baseStep: _dfaMinimizationBaseStep(
        id: id,
        stepNumber: stepNumber,
        title: 'No split on \'$symbol\'',
        explanation:
            'Checked equivalence class {$setLabels} for symbol \'$symbol\'. '
            'All states in this class have the same transition behavior - either all can reach the processing set or none can. '
            'No split is needed.',
        titleMessage: titleMessage,
        explanationMessage: explanationMessage,
      ),
      stepType: DFAMinimizationStepType.noSplit,
      currentPartition: currentPartition,
      splitSet: checkedSet,
      distinguishingSymbol: symbol,
    );
  }

  /// Creates a step for partition stabilization
  factory DFAMinimizationStep.partitionStable({
    required String id,
    required int stepNumber,
    required List<Set<State>> finalPartition,
  }) {
    final titleMessage = DfaMinimizationStepMessages.partitionStableTitle();
    final explanationMessage =
        DfaMinimizationStepMessages.partitionStableExplanation(
          finalPartition.length,
        );
    return DFAMinimizationStep(
      baseStep: _dfaMinimizationBaseStep(
        id: id,
        stepNumber: stepNumber,
        title: 'Partition stabilized',
        explanation:
            'The partition has stabilized with ${finalPartition.length} equivalence class(es). '
            'No further refinement is possible - all states in each class are truly equivalent. '
            'We can now create the minimized DFA by merging states within each class.',
        titleMessage: titleMessage,
        explanationMessage: explanationMessage,
      ),
      stepType: DFAMinimizationStepType.partitionStable,
      currentPartition: finalPartition,
    );
  }

  /// Creates a step for creating a minimized state
  factory DFAMinimizationStep.createMinimizedState({
    required String id,
    required int stepNumber,
    required String stateId,
    required Set<State> equivalenceClass,
    required bool isAccepting,
    required bool isInitial,
  }) {
    final classLabels = equivalenceClass.map((s) => s.label).join(', ');
    final titleMessage = DfaMinimizationStepMessages.createMinimizedStateTitle(
      stateId,
    );
    final explanationMessage =
        DfaMinimizationStepMessages.createMinimizedStateExplanation(
          stateId: stateId,
          equivalenceClass: classLabels,
          isInitial: isInitial,
          isAccepting: isAccepting,
        );
    return DFAMinimizationStep(
      baseStep: _dfaMinimizationBaseStep(
        id: id,
        stepNumber: stepNumber,
        title: 'Create minimized state $stateId',
        explanation:
            'Creating minimized state $stateId by merging equivalence class {$classLabels}. '
            '${isInitial ? "This is the initial state. " : ""}'
            '${isAccepting ? "This is an accepting state because the class contains an accepting state." : "This is a non-accepting state."}',
        titleMessage: titleMessage,
        explanationMessage: explanationMessage,
      ),
      stepType: DFAMinimizationStepType.createState,
      currentPartition: [],
      equivalenceClassId: stateId,
      equivalenceClassStates: equivalenceClass,
    );
  }

  /// Creates a step for creating a minimized transition
  factory DFAMinimizationStep.createMinimizedTransition({
    required String id,
    required int stepNumber,
    required String fromStateId,
    required String toStateId,
    required String symbol,
  }) {
    final titleMessage =
        DfaMinimizationStepMessages.createMinimizedTransitionTitle(symbol);
    final explanationMessage =
        DfaMinimizationStepMessages.createMinimizedTransitionExplanation(
          fromState: fromStateId,
          toState: toStateId,
          symbol: symbol,
        );
    return DFAMinimizationStep(
      baseStep: _dfaMinimizationBaseStep(
        id: id,
        stepNumber: stepNumber,
        title: 'Create transition on \'$symbol\'',
        explanation:
            'Adding transition: $fromStateId --($symbol)--> $toStateId. '
            'This represents the combined transition behavior of all states in the source equivalence class.',
        titleMessage: titleMessage,
        explanationMessage: explanationMessage,
      ),
      stepType: DFAMinimizationStepType.createTransition,
      currentPartition: [],
      distinguishingSymbol: symbol,
    );
  }

  /// Creates a completion step
  factory DFAMinimizationStep.completion({
    required String id,
    required int stepNumber,
    required int originalStates,
    required int minimizedStates,
    required int totalTransitions,
  }) {
    final reduction = originalStates - minimizedStates;
    final titleMessage = DfaMinimizationStepMessages.completionTitle();
    final explanationMessage =
        DfaMinimizationStepMessages.completionExplanation(
          originalStateCount: originalStates,
          minimizedStateCount: minimizedStates,
          transitionCount: totalTransitions,
          reduction: reduction,
        );
    return DFAMinimizationStep(
      baseStep: _dfaMinimizationBaseStep(
        id: id,
        stepNumber: stepNumber,
        title: 'Minimization complete',
        explanation:
            'DFA minimization completed successfully. '
            'Original DFA had $originalStates state(s), minimized DFA has $minimizedStates state(s). '
            '${reduction > 0 ? "Reduced by $reduction state(s). " : "DFA was already minimal. "}'
            'The minimized DFA has $totalTransitions transition(s) and accepts the same language as the original.',
        titleMessage: titleMessage,
        explanationMessage: explanationMessage,
      ),
      stepType: DFAMinimizationStepType.completion,
      currentPartition: [],
    );
  }

  /// Creates a copy of this step with updated properties
  DFAMinimizationStep copyWith({
    AlgorithmStep? baseStep,
    DFAMinimizationStepType? stepType,
    List<Set<State>>? currentPartition,
    Set<State>? processingSet,
    String? distinguishingSymbol,
    Set<State>? predecessors,
    Set<State>? splitSet,
    Set<State>? splitIntersection,
    Set<State>? splitDifference,
    List<Set<State>>? newPartition,
    int? partitionSize,
    bool? causedSplit,
    String? equivalenceClassId,
    Set<State>? equivalenceClassStates,
  }) {
    return DFAMinimizationStep(
      baseStep: baseStep ?? this.baseStep,
      stepType: stepType ?? this.stepType,
      currentPartition: currentPartition ?? this.currentPartition,
      processingSet: processingSet ?? this.processingSet,
      distinguishingSymbol: distinguishingSymbol ?? this.distinguishingSymbol,
      predecessors: predecessors ?? this.predecessors,
      splitSet: splitSet ?? this.splitSet,
      splitIntersection: splitIntersection ?? this.splitIntersection,
      splitDifference: splitDifference ?? this.splitDifference,
      newPartition: newPartition ?? this.newPartition,
      partitionSize: partitionSize ?? this.partitionSize,
      causedSplit: causedSplit ?? this.causedSplit,
      equivalenceClassId: equivalenceClassId ?? this.equivalenceClassId,
      equivalenceClassStates:
          equivalenceClassStates ?? this.equivalenceClassStates,
    );
  }

  /// Converts this specialized step to generic, JSON-friendly step properties.
  Map<String, dynamic> toProperties() {
    final properties = <String, dynamic>{
      'stepType': stepType.displayName,
      'partitionSize': partitionSize,
      'causedSplit': causedSplit,
    };

    final titleMessage = this.titleMessage;
    if (titleMessage != null) {
      properties[dfaMinimizationTitleMessageProperty] = titleMessage.toJson();
    }
    final explanationMessage = this.explanationMessage;
    if (explanationMessage != null) {
      properties[dfaMinimizationExplanationMessageProperty] = explanationMessage
          .toJson();
    }

    final partitionIds = currentPartition
        .map(_stateIds)
        .where((ids) => ids.isNotEmpty)
        .toList(growable: false);
    if (partitionIds.isNotEmpty) {
      properties['currentPartitionIds'] = partitionIds;
    }

    _putStateIds(properties, 'processingSetIds', processingSet);
    _putStateIds(properties, 'predecessorStateIds', predecessors);
    _putStateIds(properties, 'splitSetIds', splitSet);
    _putStateIds(properties, 'splitIntersectionIds', splitIntersection);
    _putStateIds(properties, 'splitDifferenceIds', splitDifference);
    _putStateIds(
      properties,
      'equivalenceClassStateIds',
      equivalenceClassStates,
    );
    _putIfNotNull(properties, 'distinguishingSymbol', distinguishingSymbol);
    _putIfNotNull(properties, 'equivalenceClassId', equivalenceClassId);

    return Map<String, dynamic>.unmodifiable(properties);
  }

  /// Converts the step to a JSON representation
  Map<String, dynamic> toJson() {
    return {
      'baseStep': baseStep.toJson(),
      'stepType': stepType.name,
      'currentPartition': currentPartition
          .map((set) => set.map((s) => s.toJson()).toList())
          .toList(),
      'processingSet': processingSet?.map((s) => s.toJson()).toList(),
      'distinguishingSymbol': distinguishingSymbol,
      'predecessors': predecessors?.map((s) => s.toJson()).toList(),
      'splitSet': splitSet?.map((s) => s.toJson()).toList(),
      'splitIntersection': splitIntersection?.map((s) => s.toJson()).toList(),
      'splitDifference': splitDifference?.map((s) => s.toJson()).toList(),
      'newPartition': newPartition
          ?.map((set) => set.map((s) => s.toJson()).toList())
          .toList(),
      'partitionSize': partitionSize,
      'causedSplit': causedSplit,
      'equivalenceClassId': equivalenceClassId,
      'equivalenceClassStates': equivalenceClassStates
          ?.map((s) => s.toJson())
          .toList(),
    };
  }

  /// Creates a step from a JSON representation
  factory DFAMinimizationStep.fromJson(Map<String, dynamic> json) {
    return DFAMinimizationStep(
      baseStep: AlgorithmStep.fromJson(
        json['baseStep'] as Map<String, dynamic>,
      ),
      stepType: DFAMinimizationStepType.values.firstWhere(
        (e) => e.name == json['stepType'],
        orElse: () => DFAMinimizationStepType.initialPartition,
      ),
      currentPartition:
          (json['currentPartition'] as List?)
              ?.map(
                (partition) => (partition as List)
                    .map((s) => State.fromJson(s as Map<String, dynamic>))
                    .toSet(),
              )
              .toList() ??
          [],
      processingSet: (json['processingSet'] as List?)
          ?.map((s) => State.fromJson(s as Map<String, dynamic>))
          .toSet(),
      distinguishingSymbol: json['distinguishingSymbol'] as String?,
      predecessors: (json['predecessors'] as List?)
          ?.map((s) => State.fromJson(s as Map<String, dynamic>))
          .toSet(),
      splitSet: (json['splitSet'] as List?)
          ?.map((s) => State.fromJson(s as Map<String, dynamic>))
          .toSet(),
      splitIntersection: (json['splitIntersection'] as List?)
          ?.map((s) => State.fromJson(s as Map<String, dynamic>))
          .toSet(),
      splitDifference: (json['splitDifference'] as List?)
          ?.map((s) => State.fromJson(s as Map<String, dynamic>))
          .toSet(),
      newPartition: (json['newPartition'] as List?)
          ?.map(
            (partition) => (partition as List)
                .map((s) => State.fromJson(s as Map<String, dynamic>))
                .toSet(),
          )
          .toList(),
      partitionSize: json['partitionSize'] as int? ?? 0,
      causedSplit: json['causedSplit'] as bool? ?? false,
      equivalenceClassId: json['equivalenceClassId'] as String?,
      equivalenceClassStates: (json['equivalenceClassStates'] as List?)
          ?.map((s) => State.fromJson(s as Map<String, dynamic>))
          .toSet(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DFAMinimizationStep &&
        other.baseStep == baseStep &&
        other.stepType == stepType &&
        other.distinguishingSymbol == distinguishingSymbol &&
        other.partitionSize == partitionSize &&
        other.causedSplit == causedSplit &&
        other.equivalenceClassId == equivalenceClassId;
  }

  @override
  int get hashCode {
    return Object.hash(
      baseStep,
      stepType,
      distinguishingSymbol,
      partitionSize,
      causedSplit,
      equivalenceClassId,
    );
  }

  @override
  String toString() {
    return 'DFAMinimizationStep(stepNumber: ${baseStep.stepNumber}, '
        'type: ${stepType.name}, title: ${baseStep.title})';
  }

  /// Gets the step number
  int get stepNumber => baseStep.stepNumber;

  /// Gets the step title
  String get title => baseStep.title;

  /// Gets the step explanation
  String get explanation => baseStep.explanation;

  /// Locale-neutral title contract resolved at the presentation boundary.
  StructuredMessage? get titleMessage => _dfaMinimizationMessageProperty(
    baseStep,
    dfaMinimizationTitleMessageProperty,
  );

  /// Locale-neutral explanation contract resolved at the presentation boundary.
  StructuredMessage? get explanationMessage => _dfaMinimizationMessageProperty(
    baseStep,
    dfaMinimizationExplanationMessageProperty,
  );

  /// Gets a summary of the partition state
  String get partitionSummary {
    if (currentPartition.isEmpty) return 'No partition data';
    final classes = currentPartition
        .map((set) {
          return '{${set.map((s) => s.label).join(',')}}';
        })
        .join(', ');
    return 'Partition ($partitionSize class${partitionSize != 1 ? 'es' : ''}): $classes';
  }

  /// Gets the number of states in the processing set
  int? get processingSetSize => processingSet?.length;

  /// Gets the number of predecessors
  int? get predecessorCount => predecessors?.length;

  /// Checks if this step involves partition refinement
  bool get refinesPartition =>
      stepType == DFAMinimizationStepType.splitClass ||
      stepType == DFAMinimizationStepType.noSplit;

  /// Checks if this step creates a minimized DFA component
  bool get createsComponent =>
      stepType == DFAMinimizationStepType.createState ||
      stepType == DFAMinimizationStepType.createTransition;

  /// Gets the split ratio if a split occurred
  String? get splitRatio {
    if (splitIntersection != null && splitDifference != null) {
      return '${splitIntersection!.length}:${splitDifference!.length}';
    }
    return null;
  }

  static void _putStateIds(
    Map<String, dynamic> properties,
    String key,
    Set<State>? states,
  ) {
    final ids = states == null ? null : _stateIds(states);
    if (ids != null && ids.isNotEmpty) {
      properties[key] = ids;
    }
  }

  static List<String> _stateIds(Set<State> states) {
    return states
        .map((state) => state.id.trim())
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
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

AlgorithmStep _dfaMinimizationBaseStep({
  required String id,
  required int stepNumber,
  required String title,
  required String explanation,
  required StructuredMessage titleMessage,
  required StructuredMessage explanationMessage,
}) => AlgorithmStep(
  id: id,
  stepNumber: stepNumber,
  title: title,
  explanation: explanation,
  type: AlgorithmType.dfaMinimization,
  properties: {
    dfaMinimizationTitleMessageProperty: titleMessage.toJson(),
    dfaMinimizationExplanationMessageProperty: explanationMessage.toJson(),
  },
);

StructuredMessage? _dfaMinimizationMessageProperty(
  AlgorithmStep step,
  String key,
) {
  final raw = step.properties[key];
  if (raw is! Map) return null;
  try {
    return StructuredMessage.fromJson(Map<String, Object?>.from(raw));
  } on FormatException {
    return null;
  }
}

/// Types of steps in DFA minimization
enum DFAMinimizationStepType {
  /// Removing unreachable states before minimization
  removeUnreachable,

  /// Creating the initial partition (accepting vs non-accepting)
  initialPartition,

  /// Selecting an equivalence class to process
  selectSet,

  /// Finding predecessor states
  findPredecessors,

  /// Splitting an equivalence class
  splitClass,

  /// Checking a class but not splitting it
  noSplit,

  /// Partition has stabilized
  partitionStable,

  /// Creating a new minimized state
  createState,

  /// Creating a new minimized transition
  createTransition,

  /// Minimization completion
  completion,
}

/// Extension methods for DFAMinimizationStepType
extension DFAMinimizationStepTypeExtension on DFAMinimizationStepType {
  /// Gets a human-readable name for the step type
  String get displayName {
    switch (this) {
      case DFAMinimizationStepType.removeUnreachable:
        return 'Remove Unreachable';
      case DFAMinimizationStepType.initialPartition:
        return 'Initial Partition';
      case DFAMinimizationStepType.selectSet:
        return 'Select Set';
      case DFAMinimizationStepType.findPredecessors:
        return 'Find Predecessors';
      case DFAMinimizationStepType.splitClass:
        return 'Split Class';
      case DFAMinimizationStepType.noSplit:
        return 'No Split';
      case DFAMinimizationStepType.partitionStable:
        return 'Partition Stable';
      case DFAMinimizationStepType.createState:
        return 'Create State';
      case DFAMinimizationStepType.createTransition:
        return 'Create Transition';
      case DFAMinimizationStepType.completion:
        return 'Completion';
    }
  }

  /// Gets a description of what this step type does
  String get description {
    switch (this) {
      case DFAMinimizationStepType.removeUnreachable:
        return 'Removes states that cannot be reached from the initial state';
      case DFAMinimizationStepType.initialPartition:
        return 'Creates the initial partition of accepting and non-accepting states';
      case DFAMinimizationStepType.selectSet:
        return 'Selects an equivalence class from the worklist to process';
      case DFAMinimizationStepType.findPredecessors:
        return 'Finds all states that transition to the processing set on a symbol';
      case DFAMinimizationStepType.splitClass:
        return 'Splits an equivalence class based on distinguishing behavior';
      case DFAMinimizationStepType.noSplit:
        return 'Verifies that an equivalence class does not need to be split';
      case DFAMinimizationStepType.partitionStable:
        return 'Confirms that the partition has reached a stable state';
      case DFAMinimizationStepType.createState:
        return 'Creates a new state in the minimized DFA from an equivalence class';
      case DFAMinimizationStepType.createTransition:
        return 'Adds a transition to the minimized DFA';
      case DFAMinimizationStepType.completion:
        return 'Marks the completion of the minimization algorithm';
    }
  }
}
