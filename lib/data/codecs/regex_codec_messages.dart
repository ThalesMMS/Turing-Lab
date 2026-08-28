import '../../core/messages/structured_message.dart';

/// Locale-neutral diagnostics emitted by Regex document codecs.
abstract final class RegexJflapMessages {
  static const namespace = 'codec.regex-jflap';

  static StructuredMessage unsupportedDocument() =>
      _error('unsupported-document');

  static StructuredMessage multipleExpressions() =>
      _error('multiple-expressions');

  static StructuredMessage multipleExtensions() =>
      _error('multiple-extensions');

  static StructuredMessage invalidExtension() => _error('invalid-extension');

  static StructuredMessage extensionMismatch() => _error('extension-mismatch');

  static StructuredMessage dialectNormalized() =>
      _information('dialect-normalized');

  static StructuredMessage unsupportedFeature(String feature) => _unsupported(
    'unsupported-feature',
    arguments: {
      'feature': StructuredMessageArgument.literal(
        feature,
        role: 'feature-description',
      ),
    },
  );

  static StructuredMessage invalidDocument() => _error('invalid-document');

  static StructuredMessage malformedDocument() => _error('malformed-document');

  static StructuredMessage expectedRegexDocument() =>
      _error('expected-regex-document');

  static StructuredMessage portabilityLossy() =>
      _warning('turing-lab-extension-portability');

  static StructuredMessage emptySetInteroperability() =>
      _warning('empty-set-interoperability');

  static StructuredMessage unbalancedParentheses() =>
      _error('unbalanced-parentheses');

  static StructuredMessage malformedOperators() =>
      _error('malformed-operators');

  static StructuredMessage unionMissingOperand() =>
      _error('union-missing-operand');

  static StructuredMessage epsilonLeftConcatenation() =>
      _error('epsilon-left-concatenation');

  static StructuredMessage epsilonRightConcatenation() =>
      _error('epsilon-right-concatenation');

  static StructuredMessage escapeMissingSymbol() =>
      _error('escape-missing-symbol');

  static StructuredMessage invalidSource() => _error('invalid-source');

  static StructuredMessage _unsupported(
    String code, {
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => _message(
    code,
    severity: StructuredMessageSeverity.error,
    arguments: arguments,
  );

  static StructuredMessage _error(
    String code, {
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => _message(
    code,
    severity: StructuredMessageSeverity.error,
    arguments: arguments,
  );

  static StructuredMessage _warning(
    String code, {
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => _message(
    code,
    severity: StructuredMessageSeverity.warning,
    arguments: arguments,
  );

  static StructuredMessage _information(
    String code, {
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => _message(
    code,
    severity: StructuredMessageSeverity.information,
    arguments: arguments,
  );

  static StructuredMessage _message(
    String code, {
    required StructuredMessageSeverity severity,
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => StructuredMessage(
    namespace: namespace,
    code: code,
    category: StructuredMessageCategory.interoperability,
    severity: severity,
    arguments: arguments,
  );
}

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
