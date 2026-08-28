import '../messages/structured_message.dart';

/// Locale-neutral diagnostics emitted by NFA-to-DFA subset construction.
abstract final class NfaToDfaMessages {
  static StructuredMessage emptyAutomaton() => _validation('empty-automaton');

  static StructuredMessage missingInitialState() =>
      _validation('missing-initial-state');

  static StructuredMessage initialStateOutsideSet() =>
      _validation('initial-state-outside-set');

  static StructuredMessage acceptingStateOutsideSet() =>
      _validation('accepting-state-outside-set');

  static StructuredMessage stateLimitExceeded(int limit) => _analysis(
    'state-limit-exceeded',
    arguments: {
      'limit': StructuredMessageArgument.bound(limit, role: 'dfa-state-limit'),
    },
  );

  static StructuredMessage conversionFailed({
    required Object error,
    required bool withSteps,
  }) => _analysis(
    'conversion-failed',
    arguments: {
      'error': StructuredMessageArgument.literal(
        error.toString(),
        role: 'error-detail',
      ),
      'with-steps': StructuredMessageArgument.boolean(
        withSteps,
        role: 'step-capture',
      ),
    },
  );

  static StructuredMessage _validation(String code) =>
      _message(code, category: StructuredMessageCategory.validation);

  static StructuredMessage _analysis(
    String code, {
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => _message(
    code,
    category: StructuredMessageCategory.analysis,
    arguments: arguments,
  );

  static StructuredMessage _message(
    String code, {
    required StructuredMessageCategory category,
    StructuredMessageSeverity severity = StructuredMessageSeverity.error,
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => StructuredMessage(
    namespace: 'automaton.nfa-to-dfa',
    code: code,
    category: category,
    severity: severity,
    arguments: arguments,
  );
}
