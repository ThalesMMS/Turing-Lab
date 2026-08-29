part of 'tm_messages.dart';

/// Locale-neutral messages emitted by bounded TM time profiling.
abstract final class TmTimeProfileMessages {
  static StructuredMessage maxLengthInvalid() =>
      _validation('max-length-invalid');

  static StructuredMessage candidateCapInvalid() =>
      _validation('candidate-cap-invalid');

  static StructuredMessage stepLimitInvalid() =>
      _validation('step-limit-invalid');

  static StructuredMessage configurationLimitInvalid() =>
      _validation('configuration-limit-invalid');

  static StructuredMessage timeoutInvalid() => _validation('timeout-invalid');

  static StructuredMessage operationsPerBatchInvalid() =>
      _validation('operations-per-batch-invalid');

  static StructuredMessage complete() =>
      _analysis('complete', severity: StructuredMessageSeverity.information);

  static StructuredMessage incomplete() =>
      _analysis('incomplete', severity: StructuredMessageSeverity.warning);

  static StructuredMessage cancelled() =>
      _analysis('cancelled', severity: StructuredMessageSeverity.information);

  static StructuredMessage invalidMachine() => _analysis('invalid-machine');

  static StructuredMessage _validation(String code) =>
      _message(code, category: StructuredMessageCategory.validation);

  static StructuredMessage _analysis(
    String code, {
    StructuredMessageSeverity severity = StructuredMessageSeverity.error,
  }) => _message(
    code,
    category: StructuredMessageCategory.analysis,
    severity: severity,
  );

  static StructuredMessage _message(
    String code, {
    required StructuredMessageCategory category,
    StructuredMessageSeverity severity = StructuredMessageSeverity.error,
  }) => StructuredMessage(
    namespace: 'tm.time-profile',
    code: code,
    category: category,
    severity: severity,
  );
}
