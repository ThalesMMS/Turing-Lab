import '../messages/structured_message.dart';

/// Locale-neutral validation diagnostics emitted by FSA-to-grammar conversion.
abstract final class FsaToGrammarMessages {
  static StructuredMessage emptyAutomaton() => _validation('empty-automaton');

  static StructuredMessage missingInitialState() =>
      _validation('missing-initial-state');

  static StructuredMessage initialStateOutsideSet() =>
      _validation('initial-state-outside-set');

  static StructuredMessage acceptingStateOutsideSet() =>
      _validation('accepting-state-outside-set');

  static StructuredMessage _validation(String code) => StructuredMessage(
    namespace: 'automaton.fsa-to-grammar',
    code: code,
    category: StructuredMessageCategory.validation,
    severity: StructuredMessageSeverity.error,
  );
}
