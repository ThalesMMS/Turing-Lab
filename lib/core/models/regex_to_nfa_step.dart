//
//  regex_to_nfa_step.dart
//  Turing Lab
//
//  Defines the detailed step model for Regex→NFA conversion via Thompson's
//  construction. Captures regex fragments, operations (basic symbol,
//  concatenation, union, Kleene star), created states and transitions, and
//  the NFA fragment stack for each algorithm step, enabling educational
//  step-by-step visualization.
//
//  Thales Matheus Mendonça Santos - January 2026
//

import 'algorithm_step.dart';
import '../messages/structured_message.dart';
import 'state.dart';
import 'transition.dart';

const regexToNfaTitleMessageProperty = 'regexToNfaTitleMessage';
const regexToNfaExplanationMessageProperty = 'regexToNfaExplanationMessage';

/// Represents a single step in Regex to NFA conversion using Thompson's construction.
///
/// TODO(#143): Keep for algorithm-internal construction. UI consumers should
/// use [toProperties] through generic [AlgorithmStep.properties].
class RegexToNFAStep {
  /// Base algorithm step information
  final AlgorithmStep baseStep;

  /// Type of operation performed in this step
  final RegexToNFAStepType stepType;

  /// Current regex substring being processed
  final String? regexFragment;

  /// Position in the original regex expression
  final int? regexPosition;

  /// Symbol being processed (for basic symbol steps)
  final String? processedSymbol;

  /// States created in this step
  final Set<State>? createdStates;

  /// Transitions created in this step
  final Set<Transition>? createdTransitions;

  /// Start state of the NFA fragment created/modified
  final State? fragmentStartState;

  /// Accept state of the NFA fragment created/modified
  final State? fragmentAcceptState;

  /// NFA fragment stack size after this step
  final int? stackSize;

  /// Whether this step combines two NFA fragments
  final bool combinesFragments;

  /// First fragment being combined (for binary operations)
  final String? firstFragmentLabel;

  /// Second fragment being combined (for binary operations)
  final String? secondFragmentLabel;

  /// Fragment being modified (for unary operations like Kleene star)
  final String? modifiedFragmentLabel;

  /// Accept states from the first fragment for binary operations.
  final Set<State>? firstFragmentAcceptStates;

  /// Accept states from the second fragment for binary operations.
  final Set<State>? secondFragmentAcceptStates;

  /// Accept states from the modified child fragment for unary operations.
  final Set<State>? modifiedFragmentAcceptStates;

  /// Whether this is the final NFA
  final bool isFinalNFA;

  /// Total number of states in the current NFA
  final int? totalStates;

  /// Total number of transitions in the current NFA
  final int? totalTransitions;

  const RegexToNFAStep._internal({
    required this.baseStep,
    required this.stepType,
    this.regexFragment,
    this.regexPosition,
    this.processedSymbol,
    this.createdStates,
    this.createdTransitions,
    this.fragmentStartState,
    this.fragmentAcceptState,
    this.stackSize,
    required this.combinesFragments,
    this.firstFragmentLabel,
    this.secondFragmentLabel,
    this.modifiedFragmentLabel,
    this.firstFragmentAcceptStates,
    this.secondFragmentAcceptStates,
    this.modifiedFragmentAcceptStates,
    required this.isFinalNFA,
    this.totalStates,
    this.totalTransitions,
  });

  factory RegexToNFAStep({
    required AlgorithmStep baseStep,
    required RegexToNFAStepType stepType,
    String? regexFragment,
    int? regexPosition,
    String? processedSymbol,
    Set<State>? createdStates,
    Set<Transition>? createdTransitions,
    State? fragmentStartState,
    State? fragmentAcceptState,
    int? stackSize,
    bool combinesFragments = false,
    String? firstFragmentLabel,
    String? secondFragmentLabel,
    String? modifiedFragmentLabel,
    Set<State>? firstFragmentAcceptStates,
    Set<State>? secondFragmentAcceptStates,
    Set<State>? modifiedFragmentAcceptStates,
    bool isFinalNFA = false,
    int? totalStates,
    int? totalTransitions,
  }) {
    return RegexToNFAStep._internal(
      baseStep: baseStep.copyWith(
        title: _regexToNfaStepMessage(
          _regexToNfaStepCode(stepType, 'title'),
        ).stableCode,
        explanation: _regexToNfaStepMessage(
          _regexToNfaStepCode(stepType, 'explanation'),
        ).stableCode,
      ),
      stepType: stepType,
      regexFragment: regexFragment,
      regexPosition: regexPosition,
      processedSymbol: processedSymbol,
      createdStates: createdStates != null
          ? Set.unmodifiable(createdStates)
          : null,
      createdTransitions: createdTransitions != null
          ? Set.unmodifiable(createdTransitions)
          : null,
      fragmentStartState: fragmentStartState,
      fragmentAcceptState: fragmentAcceptState,
      stackSize: stackSize,
      combinesFragments: combinesFragments,
      firstFragmentLabel: firstFragmentLabel,
      secondFragmentLabel: secondFragmentLabel,
      modifiedFragmentLabel: modifiedFragmentLabel,
      firstFragmentAcceptStates: firstFragmentAcceptStates != null
          ? Set.unmodifiable(firstFragmentAcceptStates)
          : null,
      secondFragmentAcceptStates: secondFragmentAcceptStates != null
          ? Set.unmodifiable(secondFragmentAcceptStates)
          : null,
      modifiedFragmentAcceptStates: modifiedFragmentAcceptStates != null
          ? Set.unmodifiable(modifiedFragmentAcceptStates)
          : null,
      isFinalNFA: isFinalNFA,
      totalStates: totalStates,
      totalTransitions: totalTransitions,
    );
  }

  /// Creates a step for starting the conversion
  factory RegexToNFAStep.start({
    required String id,
    required int stepNumber,
    required String regex,
  }) {
    return RegexToNFAStep(
      baseStep: AlgorithmStep(
        id: id,
        stepNumber: stepNumber,
        title: _regexToNfaStepMessage('start-title').stableCode,
        explanation: _regexToNfaStepMessage('start-explanation').stableCode,
        type: AlgorithmType.regexToNfa,
      ),
      stepType: RegexToNFAStepType.start,
      regexFragment: regex,
      regexPosition: 0,
      stackSize: 0,
    );
  }

  /// Creates a step for processing a basic symbol
  factory RegexToNFAStep.basicSymbol({
    required String id,
    required int stepNumber,
    required String symbol,
    required int? position,
    required State startState,
    required State acceptState,
    required Transition transition,
    required int stackSize,
  }) {
    return RegexToNFAStep(
      baseStep: AlgorithmStep(
        id: id,
        stepNumber: stepNumber,
        title: _regexToNfaStepMessage('basic-symbol-title').stableCode,
        explanation: _regexToNfaStepMessage(
          'basic-symbol-explanation',
        ).stableCode,
        type: AlgorithmType.regexToNfa,
      ),
      stepType: RegexToNFAStepType.basicSymbol,
      regexFragment: symbol,
      regexPosition: position,
      processedSymbol: symbol,
      createdStates: {startState, acceptState},
      createdTransitions: {transition},
      fragmentStartState: startState,
      fragmentAcceptState: acceptState,
      stackSize: stackSize,
    );
  }

  /// Creates a step for the concatenation operation
  factory RegexToNFAStep.concatenation({
    required String id,
    required int stepNumber,
    required int? position,
    required String firstFragmentLabel,
    required String secondFragmentLabel,
    required State firstStart,
    required Set<State> firstAcceptStates,
    required State secondStart,
    required Set<State> secondAcceptStates,
    required Set<Transition> epsilonTransitions,
    required int stackSize,
  }) {
    return RegexToNFAStep(
      baseStep: AlgorithmStep(
        id: id,
        stepNumber: stepNumber,
        title: _regexToNfaStepMessage('concatenation-title').stableCode,
        explanation: _regexToNfaStepMessage(
          'concatenation-explanation',
        ).stableCode,
        type: AlgorithmType.regexToNfa,
      ),
      stepType: RegexToNFAStepType.concatenation,
      regexPosition: position,
      combinesFragments: true,
      firstFragmentLabel: firstFragmentLabel,
      secondFragmentLabel: secondFragmentLabel,
      firstFragmentAcceptStates: firstAcceptStates,
      secondFragmentAcceptStates: secondAcceptStates,
      createdTransitions: epsilonTransitions,
      fragmentStartState: firstStart,
      fragmentAcceptState: _stableState(secondAcceptStates),
      stackSize: stackSize,
    );
  }

  /// Creates a step for the union (alternation) operation
  factory RegexToNFAStep.union({
    required String id,
    required int stepNumber,
    required int? position,
    required String firstFragmentLabel,
    required String secondFragmentLabel,
    required State newStart,
    required State newAccept,
    required State firstStart,
    required Set<State> firstAcceptStates,
    required State secondStart,
    required Set<State> secondAcceptStates,
    required Set<Transition> newTransitions,
    required int stackSize,
  }) {
    return RegexToNFAStep(
      baseStep: AlgorithmStep(
        id: id,
        stepNumber: stepNumber,
        title: _regexToNfaStepMessage('union-title').stableCode,
        explanation: _regexToNfaStepMessage('union-explanation').stableCode,
        type: AlgorithmType.regexToNfa,
      ),
      stepType: RegexToNFAStepType.union,
      regexPosition: position,
      combinesFragments: true,
      firstFragmentLabel: firstFragmentLabel,
      secondFragmentLabel: secondFragmentLabel,
      firstFragmentAcceptStates: firstAcceptStates,
      secondFragmentAcceptStates: secondAcceptStates,
      createdStates: {newStart, newAccept},
      createdTransitions: newTransitions,
      fragmentStartState: newStart,
      fragmentAcceptState: newAccept,
      stackSize: stackSize,
    );
  }

  /// Creates a step for the Kleene star operation
  factory RegexToNFAStep.kleeneStar({
    required String id,
    required int stepNumber,
    required int? position,
    required String fragmentLabel,
    required State newStart,
    required State newAccept,
    required State oldStart,
    required Set<State> oldAcceptStates,
    required Set<Transition> newTransitions,
    required int stackSize,
  }) {
    return RegexToNFAStep(
      baseStep: AlgorithmStep(
        id: id,
        stepNumber: stepNumber,
        title: _regexToNfaStepMessage('kleene-star-title').stableCode,
        explanation: _regexToNfaStepMessage(
          'kleene-star-explanation',
        ).stableCode,
        type: AlgorithmType.regexToNfa,
      ),
      stepType: RegexToNFAStepType.kleeneStar,
      regexPosition: position,
      modifiedFragmentLabel: fragmentLabel,
      modifiedFragmentAcceptStates: oldAcceptStates,
      createdStates: {newStart, newAccept},
      createdTransitions: newTransitions,
      fragmentStartState: newStart,
      fragmentAcceptState: newAccept,
      stackSize: stackSize,
    );
  }

  /// Creates a step for the plus operation (one or more)
  factory RegexToNFAStep.plus({
    required String id,
    required int stepNumber,
    required int? position,
    required String fragmentLabel,
    required State newStart,
    required State newAccept,
    required State oldStart,
    required Set<State> oldAcceptStates,
    required Set<Transition> newTransitions,
    required int stackSize,
  }) {
    return RegexToNFAStep(
      baseStep: AlgorithmStep(
        id: id,
        stepNumber: stepNumber,
        title: _regexToNfaStepMessage('plus-title').stableCode,
        explanation: _regexToNfaStepMessage('plus-explanation').stableCode,
        type: AlgorithmType.regexToNfa,
      ),
      stepType: RegexToNFAStepType.plus,
      regexPosition: position,
      modifiedFragmentLabel: fragmentLabel,
      modifiedFragmentAcceptStates: oldAcceptStates,
      createdStates: {newStart, newAccept},
      createdTransitions: newTransitions,
      fragmentStartState: newStart,
      fragmentAcceptState: newAccept,
      stackSize: stackSize,
    );
  }

  /// Creates a step for the optional operation (zero or one)
  factory RegexToNFAStep.optional({
    required String id,
    required int stepNumber,
    required int? position,
    required String fragmentLabel,
    required State newStart,
    required State newAccept,
    required State oldStart,
    required Set<State> oldAcceptStates,
    required Set<Transition> newTransitions,
    required int stackSize,
  }) {
    return RegexToNFAStep(
      baseStep: AlgorithmStep(
        id: id,
        stepNumber: stepNumber,
        title: _regexToNfaStepMessage('optional-title').stableCode,
        explanation: _regexToNfaStepMessage('optional-explanation').stableCode,
        type: AlgorithmType.regexToNfa,
      ),
      stepType: RegexToNFAStepType.optional,
      regexPosition: position,
      modifiedFragmentLabel: fragmentLabel,
      modifiedFragmentAcceptStates: oldAcceptStates,
      createdStates: {newStart, newAccept},
      createdTransitions: newTransitions,
      fragmentStartState: newStart,
      fragmentAcceptState: newAccept,
      stackSize: stackSize,
    );
  }

  /// Creates a step for completing the NFA construction
  factory RegexToNFAStep.complete({
    required String id,
    required int stepNumber,
    required State finalStartState,
    required State finalAcceptState,
    required int totalStates,
    required int totalTransitions,
  }) {
    return RegexToNFAStep(
      baseStep: AlgorithmStep(
        id: id,
        stepNumber: stepNumber,
        title: _regexToNfaStepMessage('complete-title').stableCode,
        explanation: _regexToNfaStepMessage('complete-explanation').stableCode,
        type: AlgorithmType.regexToNfa,
      ),
      stepType: RegexToNFAStepType.complete,
      fragmentStartState: finalStartState,
      fragmentAcceptState: finalAcceptState,
      isFinalNFA: true,
      totalStates: totalStates,
      totalTransitions: totalTransitions,
      stackSize: 1,
    );
  }

  /// Locale-neutral title contract resolved at the presentation boundary.
  StructuredMessage get titleMessage => switch (stepType) {
    RegexToNFAStepType.basicSymbol => _regexToNfaStepMessage(
      'basic-symbol-title',
      arguments: {
        'symbol': _regexToNfaLiteral(
          _displayRegexSymbol(processedSymbol),
          'regex-symbol',
        ),
      },
    ),
    _ => _regexToNfaStepMessage(_regexToNfaStepCode(stepType, 'title')),
  };

  /// Locale-neutral explanation contract resolved at the presentation
  /// boundary.
  StructuredMessage get explanationMessage => switch (stepType) {
    RegexToNFAStepType.start => _regexToNfaStepMessage(
      'start-explanation',
      arguments: {'regex': _regexToNfaLiteral(regexFragment ?? '', 'regex')},
    ),
    RegexToNFAStepType.basicSymbol => _regexToNfaStepMessage(
      'basic-symbol-explanation',
      arguments: {
        'symbol': _regexToNfaLiteral(
          _displayRegexSymbol(processedSymbol),
          'regex-symbol',
        ),
        'position': _regexToNfaPosition(regexPosition),
        'start-state': _regexToNfaLiteral(
          fragmentStartState?.label ?? '',
          'state-label',
        ),
        'accept-state': _regexToNfaLiteral(
          fragmentAcceptState?.label ?? '',
          'state-label',
        ),
        'state-count': StructuredMessageArgument.count(
          createdStates?.length ?? 0,
        ),
        'transition-count': StructuredMessageArgument.count(
          createdTransitions?.length ?? 0,
        ),
        'transitions': _regexToNfaLiteral(
          _transitionPlan(createdTransitions),
          'nfa-transitions',
        ),
        'stack-size': StructuredMessageArgument.count(stackSize ?? 0),
      },
    ),
    RegexToNFAStepType.concatenation => _regexToNfaStepMessage(
      'concatenation-explanation',
      arguments: {
        'position': _regexToNfaPosition(regexPosition),
        'first-fragment': _regexToNfaLiteral(
          firstFragmentLabel ?? '',
          'regex-fragment',
        ),
        'second-fragment': _regexToNfaLiteral(
          secondFragmentLabel ?? '',
          'regex-fragment',
        ),
        'start-state': _regexToNfaLiteral(
          fragmentStartState?.label ?? '',
          'state-label',
        ),
        'accept-states': _regexToNfaLiteral(
          _stateLabels(secondFragmentAcceptStates ?? const {}),
          'state-labels',
        ),
        'transitions': _regexToNfaLiteral(
          _transitionPlan(createdTransitions),
          'nfa-transitions',
        ),
        'stack-size': StructuredMessageArgument.count(stackSize ?? 0),
      },
    ),
    RegexToNFAStepType.union => _regexToNfaStepMessage(
      'union-explanation',
      arguments: {
        'position': _regexToNfaPosition(regexPosition),
        'pattern': _regexToNfaLiteral(
          '(${firstFragmentLabel ?? ''}|${secondFragmentLabel ?? ''})',
          'regex-fragment',
        ),
        'start-state': _regexToNfaLiteral(
          fragmentStartState?.label ?? '',
          'state-label',
        ),
        'accept-state': _regexToNfaLiteral(
          fragmentAcceptState?.label ?? '',
          'state-label',
        ),
        'transitions': _regexToNfaLiteral(
          _transitionPlan(createdTransitions),
          'nfa-transitions',
        ),
        'stack-size': StructuredMessageArgument.count(stackSize ?? 0),
      },
    ),
    RegexToNFAStepType.kleeneStar ||
    RegexToNFAStepType.plus ||
    RegexToNFAStepType.optional => _regexToNfaStepMessage(
      _regexToNfaStepCode(stepType, 'explanation'),
      arguments: {
        'fragment': _regexToNfaLiteral(
          modifiedFragmentLabel ?? '',
          'regex-fragment',
        ),
        'position': _regexToNfaPosition(regexPosition),
        'start-state': _regexToNfaLiteral(
          fragmentStartState?.label ?? '',
          'state-label',
        ),
        'accept-state': _regexToNfaLiteral(
          fragmentAcceptState?.label ?? '',
          'state-label',
        ),
        'transitions': _regexToNfaLiteral(
          _transitionPlan(createdTransitions),
          'nfa-transitions',
        ),
        'stack-size': StructuredMessageArgument.count(stackSize ?? 0),
      },
    ),
    RegexToNFAStepType.complete => _regexToNfaStepMessage(
      'complete-explanation',
      arguments: {
        'start-state': _regexToNfaLiteral(
          fragmentStartState?.label ?? '',
          'state-label',
        ),
        'accept-state': _regexToNfaLiteral(
          fragmentAcceptState?.label ?? '',
          'state-label',
        ),
        'state-count': StructuredMessageArgument.count(totalStates ?? 0),
        'transition-count': StructuredMessageArgument.count(
          totalTransitions ?? 0,
        ),
      },
    ),
  };

  /// Converts this specialized step to generic, JSON-friendly step properties.
  Map<String, dynamic> toProperties() {
    final properties = <String, dynamic>{
      'stepType': stepType.legacyPropertyValue,
      'stepTypeCode': stepType.name,
      'combinesFragments': combinesFragments,
      'isFinalNFA': isFinalNFA,
      regexToNfaTitleMessageProperty: titleMessage.toJson(),
      regexToNfaExplanationMessageProperty: explanationMessage.toJson(),
    };

    _putStateIds(properties, 'createdStateIds', createdStates);
    _putTransitionIds(properties, 'createdTransitionIds', createdTransitions);
    _putIfNotNull(properties, 'fragmentStartStateId', fragmentStartState?.id);
    _putIfNotNull(properties, 'fragmentAcceptStateId', fragmentAcceptState?.id);
    _putIfNotNull(properties, 'regexFragment', regexFragment);
    _putIfNotNull(properties, 'regexPosition', regexPosition);
    _putIfNotNull(properties, 'processedSymbol', processedSymbol);
    _putIfNotNull(properties, 'stackSize', stackSize);
    _putIfNotNull(properties, 'firstFragmentLabel', firstFragmentLabel);
    _putIfNotNull(properties, 'secondFragmentLabel', secondFragmentLabel);
    _putIfNotNull(properties, 'modifiedFragmentLabel', modifiedFragmentLabel);
    _putIfNotNull(properties, 'totalStates', totalStates);
    _putIfNotNull(properties, 'totalTransitions', totalTransitions);

    return Map<String, dynamic>.unmodifiable(properties);
  }

  static String _stateLabels(Set<State> states) {
    final labels = states.map((state) => state.label).toList()..sort();
    return labels.join(', ');
  }

  static String _transitionPlan(Set<Transition>? transitions) {
    if (transitions == null || transitions.isEmpty) return '∅';
    final labels =
        transitions
            .map(
              (transition) =>
                  '${transition.fromState.label} → ${transition.toState.label} '
                  '(${_displayRegexSymbol(transition.label)})',
            )
            .toList()
          ..sort();
    return labels.join(', ');
  }

  static State _stableState(Set<State> states) {
    if (states.isEmpty) {
      throw ArgumentError.value(states, 'states', 'must not be empty');
    }
    final sorted = states.toList()
      ..sort((a, b) {
        final idComparison = a.id.compareTo(b.id);
        if (idComparison != 0) return idComparison;
        return a.label.compareTo(b.label);
      });
    return sorted.first;
  }

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

  static void _putTransitionIds(
    Map<String, dynamic> properties,
    String key,
    Set<Transition>? transitions,
  ) {
    final ids = transitions
        ?.map((transition) => transition.id.trim())
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

StructuredMessage _regexToNfaStepMessage(
  String code, {
  Map<String, StructuredMessageArgument> arguments = const {},
}) => StructuredMessage(
  namespace: 'regex.to-nfa.step',
  code: code,
  category: StructuredMessageCategory.transformation,
  severity: StructuredMessageSeverity.information,
  arguments: arguments,
);

StructuredMessageArgument _regexToNfaLiteral(String value, String role) =>
    StructuredMessageArgument.literal(value, role: role);

StructuredMessageArgument _regexToNfaPosition(int? position) =>
    StructuredMessageArgument.integer(position ?? -1, role: 'regex-position');

String _displayRegexSymbol(String? symbol) =>
    symbol == null || symbol.isEmpty ? 'ε' : symbol;

String _regexToNfaStepCode(RegexToNFAStepType type, String suffix) =>
    '${switch (type) {
      RegexToNFAStepType.start => 'start',
      RegexToNFAStepType.basicSymbol => 'basic-symbol',
      RegexToNFAStepType.concatenation => 'concatenation',
      RegexToNFAStepType.union => 'union',
      RegexToNFAStepType.kleeneStar => 'kleene-star',
      RegexToNFAStepType.plus => 'plus',
      RegexToNFAStepType.optional => 'optional',
      RegexToNFAStepType.complete => 'complete',
    }}-$suffix';

/// Types of steps in regex to NFA conversion
enum RegexToNFAStepType {
  /// Starting the Thompson's construction algorithm
  start,

  /// Creating NFA for a basic symbol or epsilon
  basicSymbol,

  /// Concatenating two NFA fragments
  concatenation,

  /// Creating union (alternation) of two NFA fragments
  union,

  /// Applying Kleene star (zero or more) to an NFA fragment
  kleeneStar,

  /// Applying plus (one or more) to an NFA fragment
  plus,

  /// Applying optional (zero or one) to an NFA fragment
  optional,

  /// Completing the final NFA
  complete,
}

/// Extension methods for RegexToNFAStepType
extension RegexToNFAStepTypeExtension on RegexToNFAStepType {
  /// Compatibility code for callers that have not adopted presentation
  /// resolution yet.
  String get displayName => labelMessage.stableCode;

  String get description => descriptionMessage.stableCode;

  /// Historical JSON property retained for persisted step compatibility.
  /// Presentation code must resolve [labelMessage] instead.
  String get legacyPropertyValue => switch (this) {
    RegexToNFAStepType.start => 'Start',
    RegexToNFAStepType.basicSymbol => 'Basic Symbol',
    RegexToNFAStepType.concatenation => 'Concatenation',
    RegexToNFAStepType.union => 'Union',
    RegexToNFAStepType.kleeneStar => 'Kleene Star',
    RegexToNFAStepType.plus => 'Plus',
    RegexToNFAStepType.optional => 'Optional',
    RegexToNFAStepType.complete => 'Complete',
  };

  StructuredMessage get labelMessage =>
      _regexToNfaStepTypeMessage('label', this);

  StructuredMessage get descriptionMessage =>
      _regexToNfaStepTypeMessage('description', this);
}

StructuredMessage _regexToNfaStepTypeMessage(
  String code,
  RegexToNFAStepType type,
) => StructuredMessage(
  namespace: 'regex.to-nfa.step-type',
  code: code,
  category: StructuredMessageCategory.transformation,
  severity: StructuredMessageSeverity.information,
  arguments: {
    'type': StructuredMessageArgument.outcome(
      type.name,
      role: 'regex-to-nfa-step-type',
    ),
  },
);
