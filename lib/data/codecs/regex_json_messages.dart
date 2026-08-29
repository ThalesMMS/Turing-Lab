import '../../core/messages/structured_message.dart';

/// Locale-neutral diagnostics emitted by the Regex JSON codec.
abstract final class RegexJsonMessages {
  static const namespace = 'codec.regex-json';

  static StructuredMessage unexpectedDecoderType() =>
      _error('unexpected-decoder-type');

  static StructuredMessage sourceOfTruthInvalid() =>
      _error('source-of-truth-invalid');

  static StructuredMessage canonicalAstMismatch() =>
      _error('canonical-ast-mismatch');

  static StructuredMessage expectedRegexDocument() =>
      _error('expected-regex-document');

  static StructuredMessage invalidDocument() => _error('invalid-document');

  static StructuredMessage unsupportedDialect() =>
      _unsupported('unsupported-dialect');

  static StructuredMessage invalidSource() => _error('invalid-source');

  static StructuredMessage unexpectedValidationOutcome() =>
      _error('unexpected-validation-outcome');

  static StructuredMessage _unsupported(String code) =>
      _message(code, severity: StructuredMessageSeverity.error);

  static StructuredMessage _error(String code) =>
      _message(code, severity: StructuredMessageSeverity.error);

  static StructuredMessage _message(
    String code, {
    required StructuredMessageSeverity severity,
  }) => StructuredMessage(
    namespace: namespace,
    code: code,
    category: StructuredMessageCategory.interoperability,
    severity: severity,
  );
}
