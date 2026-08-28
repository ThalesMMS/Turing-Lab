import '../messages/structured_message.dart';

/// Locale-neutral diagnostics emitted by DFA minimization.
abstract final class DfaMinimizerMessages {
  static StructuredMessage emptyDfa() => _validation('empty-dfa');

  static StructuredMessage missingInitialState() =>
      _validation('missing-initial-state');

  static StructuredMessage initialStateOutsideSet() =>
      _validation('initial-state-outside-set');

  static StructuredMessage acceptingStateOutsideSet() =>
      _validation('accepting-state-outside-set');

  static StructuredMessage nondeterministicInput() =>
      _validation('nondeterministic-input');

  static StructuredMessage minimizationFailed() =>
      _analysis('minimization-failed');

  static StructuredMessage minimizationWithStepsFailed() =>
      _analysis('minimization-with-steps-failed');

  static StructuredMessage _validation(String code) =>
      _message(code, category: StructuredMessageCategory.validation);

  static StructuredMessage _analysis(String code) =>
      _message(code, category: StructuredMessageCategory.analysis);

  static StructuredMessage _message(
    String code, {
    required StructuredMessageCategory category,
    StructuredMessageSeverity severity = StructuredMessageSeverity.error,
  }) => StructuredMessage(
    namespace: 'automaton.dfa-minimization',
    code: code,
    category: category,
    severity: severity,
  );
}
