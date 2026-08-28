import '../../messages/structured_message.dart';

/// Locale-neutral diagnostics emitted by the CYK parser.
abstract final class CykParserMessages {
  static StructuredMessage timedOut() =>
      _message('timed-out', severity: StructuredMessageSeverity.warning);

  static StructuredMessage inputRejected(String input) => _message(
    'input-rejected',
    arguments: {
      'input': StructuredMessageArgument.literal(input, role: 'input-string'),
    },
  );

  static StructuredMessage parseFailed() =>
      _message('parse-failed', category: StructuredMessageCategory.analysis);

  static StructuredMessage _message(
    String code, {
    StructuredMessageCategory category = StructuredMessageCategory.parsing,
    StructuredMessageSeverity severity = StructuredMessageSeverity.error,
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => StructuredMessage(
    namespace: 'grammar.cyk',
    code: code,
    category: category,
    severity: severity,
    arguments: arguments,
  );
}
