part of 'tm_messages.dart';

/// Locale-neutral messages emitted by bounded TM space profiling.
abstract final class TmSpaceProfileMessages {
  static StructuredMessage emptyMachine() => _validation('empty-machine');

  static StructuredMessage missingInitialState() =>
      _validation('missing-initial-state');

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

  static StructuredMessage missingSpaceMetrics() =>
      _analysis('missing-space-metrics');

  static StructuredMessage _validation(String code) =>
      _message(code, category: StructuredMessageCategory.validation);

  static StructuredMessage _analysis(String code) =>
      _message(code, category: StructuredMessageCategory.analysis);

  static StructuredMessage _message(
    String code, {
    required StructuredMessageCategory category,
    StructuredMessageSeverity severity = StructuredMessageSeverity.error,
  }) => StructuredMessage(
    namespace: 'tm.space-profile',
    code: code,
    category: category,
    severity: severity,
  );
}
