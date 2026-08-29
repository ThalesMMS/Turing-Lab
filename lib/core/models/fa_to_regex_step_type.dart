part of 'fa_to_regex_step.dart';

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
  completion;

  /// Compatibility code for callers awaiting presentation resolution.
  String get displayName => labelMessage.stableCode;

  /// Compatibility code for callers awaiting presentation resolution.
  String get description => descriptionMessage.stableCode;

  StructuredMessage get labelMessage => _message('label');

  StructuredMessage get descriptionMessage => _message('description');

  StructuredMessage _message(String code) => StructuredMessage(
    namespace: 'automaton.fa-to-regex.step-type',
    code: code,
    category: StructuredMessageCategory.transformation,
    severity: StructuredMessageSeverity.information,
    arguments: {
      'type': StructuredMessageArgument.outcome(
        name,
        role: 'fa-to-regex-step-type',
      ),
    },
  );
}
