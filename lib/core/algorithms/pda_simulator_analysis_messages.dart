import '../messages/structured_message.dart';

/// Locale-neutral diagnostics emitted while analyzing a PDA.
abstract final class PdaAnalysisMessages {
  static StructuredMessage emptyPda() => _validation('empty-pda');

  static StructuredMessage invalidMaxInputLength() =>
      _validation('invalid-max-input-length');

  static StructuredMessage invalidTimeout() => _validation('invalid-timeout');

  static StructuredMessage timedOut() =>
      _analysis('timed-out', severity: StructuredMessageSeverity.warning);

  static StructuredMessage failure(Object error) => _analysis(
    'failure',
    arguments: {
      'error': StructuredMessageArgument.literal(
        error.toString(),
        role: 'error-detail',
      ),
    },
  );

  static StructuredMessage _validation(String code) =>
      _message(code, category: StructuredMessageCategory.validation);

  static StructuredMessage _analysis(
    String code, {
    StructuredMessageSeverity severity = StructuredMessageSeverity.error,
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => _message(
    code,
    category: StructuredMessageCategory.analysis,
    severity: severity,
    arguments: arguments,
  );

  static StructuredMessage _message(
    String code, {
    required StructuredMessageCategory category,
    StructuredMessageSeverity severity = StructuredMessageSeverity.error,
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => StructuredMessage(
    namespace: 'pda.analysis',
    code: code,
    category: category,
    severity: severity,
    arguments: arguments,
  );
}
