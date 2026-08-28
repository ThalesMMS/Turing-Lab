import '../messages/structured_message.dart';

/// Locale-neutral diagnostics emitted by the CFG transformation toolkit.
abstract final class CfgToolkitMessages {
  static StructuredMessage reduceFailed() => _failure('reduce-failed');

  static StructuredMessage toCnfFailed() => _failure('to-cnf-failed');

  static StructuredMessage toGnfFailed() => _failure('to-gnf-failed');

  static StructuredMessage _failure(String code) => StructuredMessage(
    namespace: 'grammar.cfg-toolkit',
    code: code,
    category: StructuredMessageCategory.transformation,
    severity: StructuredMessageSeverity.error,
  );
}
