import '../messages/structured_message.dart';

/// Locale-neutral validation diagnostics for regex simplification.
abstract final class RegexSimplificationMessages {
  static StructuredMessage emptyInput() =>
      _message('empty-input', severity: StructuredMessageSeverity.error);

  static StructuredMessage unmatchedClosingParenthesis(int position) =>
      _message(
        'unmatched-closing-parenthesis',
        severity: StructuredMessageSeverity.error,
        arguments: {
          'position': StructuredMessageArgument.index(
            position,
            role: 'regex-position',
          ),
        },
      );

  static StructuredMessage unclosedOpeningParentheses(int count) => _message(
    'unclosed-opening-parentheses',
    severity: StructuredMessageSeverity.error,
    arguments: {
      'count': StructuredMessageArgument.count(
        count,
        role: 'parenthesis-count',
      ),
    },
  );

  static StructuredMessage _message(
    String code, {
    required StructuredMessageSeverity severity,
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => StructuredMessage(
    namespace: 'regex.simplification',
    code: code,
    category: StructuredMessageCategory.validation,
    severity: severity,
    arguments: arguments,
  );
}
