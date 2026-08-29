import '../messages/structured_message.dart';

/// Locale-neutral diagnostics emitted while proving PDA language emptiness.
abstract final class PdaLanguageEmptinessMessages {
  static StructuredMessage invalidLimits() => _validation('invalid-limits');

  static StructuredMessage cancelled() => _analysis('cancelled');

  static StructuredMessage witnessReplayFailed() =>
      _analysis('witness-replay-failed');

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
    namespace: 'pda.language-emptiness',
    code: code,
    category: category,
    severity: severity,
  );
}
