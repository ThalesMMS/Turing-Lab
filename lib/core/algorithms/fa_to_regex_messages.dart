import '../messages/structured_message.dart';

/// Locale-neutral diagnostics emitted by the FA-to-regex converter.
abstract final class FaToRegexMessages {
  static StructuredMessage emptyAutomaton() => _validation('empty-automaton');

  static StructuredMessage missingInitialState() =>
      _validation('missing-initial-state');

  static StructuredMessage initialStateOutsideSet() =>
      _validation('initial-state-outside-set');

  static StructuredMessage acceptingStateOutsideSet() =>
      _validation('accepting-state-outside-set');

  static StructuredMessage simplificationFailed() =>
      _analysis('simplification-failed');

  static StructuredMessage internalFailure() => _analysis('internal-failure');

  static StructuredMessage _validation(String code) => _message(
    code,
    category: StructuredMessageCategory.validation,
    severity: StructuredMessageSeverity.error,
  );

  static StructuredMessage _analysis(String code) => _message(
    code,
    category: StructuredMessageCategory.analysis,
    severity: StructuredMessageSeverity.error,
  );

  static StructuredMessage _message(
    String code, {
    required StructuredMessageCategory category,
    required StructuredMessageSeverity severity,
  }) => StructuredMessage(
    namespace: 'automaton.fa-to-regex',
    code: code,
    category: category,
    severity: severity,
  );
}
