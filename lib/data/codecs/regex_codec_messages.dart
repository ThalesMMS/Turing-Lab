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

  static StructuredMessage unsupportedDialect() =>
      _unsupported('unsupported-dialect');

  static StructuredMessage nonBmpSymbol() => _unsupported('non-bmp-symbol');

  static StructuredMessage escapeUnsupported(String symbol) => _unsupported(
    'escape-unsupported',
    arguments: {
      'symbol': StructuredMessageArgument.symbol(symbol, role: 'regex-symbol'),
    },
  );

  static StructuredMessage emptyLanguageUnsupported() =>
      _unsupported('empty-language-unsupported');

  static StructuredMessage reservedLiteral(String symbol) => _unsupported(
    'reserved-literal',
    arguments: {
      'symbol': StructuredMessageArgument.symbol(symbol, role: 'regex-symbol'),
    },
  );

  static StructuredMessage unsupportedConstruct(String symbol) => _unsupported(
    'unsupported-construct',
    arguments: {
      'symbol': StructuredMessageArgument.symbol(symbol, role: 'regex-symbol'),
    },
  );

  static StructuredMessage profileDependentSymbol(String symbol) =>
      _unsupported(
        'profile-dependent-symbol',
        arguments: {
          'symbol': StructuredMessageArgument.symbol(
            symbol,
            role: 'regex-symbol',
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
