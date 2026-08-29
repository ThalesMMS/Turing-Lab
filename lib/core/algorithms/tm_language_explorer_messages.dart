part of 'tm_messages.dart';

/// Locale-neutral messages emitted by bounded TM language exploration.
abstract final class TmLanguageExplorerMessages {
  static StructuredMessage maxInputLengthInvalid() =>
      _validation('max-input-length-invalid');

  static StructuredMessage candidateCapInvalid() =>
      _validation('candidate-cap-invalid');

  static StructuredMessage stepLimitInvalid() =>
      _validation('step-limit-invalid');

  static StructuredMessage configurationLimitInvalid() =>
      _validation('configuration-limit-invalid');

  static StructuredMessage timeoutInvalid() => _validation('timeout-invalid');

  static StructuredMessage operationsPerBatchInvalid() =>
      _validation('operations-per-batch-invalid');

  static StructuredMessage _validation(String code) => StructuredMessage(
    namespace: 'tm.language-explorer',
    code: code,
    category: StructuredMessageCategory.validation,
    severity: StructuredMessageSeverity.error,
  );
}
