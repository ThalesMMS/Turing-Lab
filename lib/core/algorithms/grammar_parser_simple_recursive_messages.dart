import '../messages/structured_message.dart';

/// Locale-neutral diagnostics emitted by the simple recursive-descent parser.
///
/// The parser keeps its historical display strings in its result objects and
/// attaches these stable contracts for presentation-time localization.
abstract final class SimpleRecursiveDescentMessages {
  static StructuredMessage inputRejected(String input) => _parsing(
    'input-rejected',
    arguments: {
      'input': StructuredMessageArgument.literal(input, role: 'input-string'),
    },
  );

  static StructuredMessage timedOut() => _parsing(
    'recursive-descent-timed-out',
    severity: StructuredMessageSeverity.warning,
  );

  /// Compatibility-named factory for callers migrating from the shared
  /// grammar-parser message companion.
  static StructuredMessage recursiveDescentTimedOut() => timedOut();

  static StructuredMessage failed() => _analysis('recursive-descent-failed');

  /// Compatibility-named factory for callers migrating from the shared
  /// grammar-parser message companion.
  static StructuredMessage recursiveDescentFailed() => failed();

  static StructuredMessage _parsing(
    String code, {
    StructuredMessageSeverity severity = StructuredMessageSeverity.error,
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => _message(
    code,
    category: StructuredMessageCategory.parsing,
    severity: severity,
    arguments: arguments,
  );

  static StructuredMessage _analysis(String code) =>
      _message(code, category: StructuredMessageCategory.analysis);

  static StructuredMessage _message(
    String code, {
    required StructuredMessageCategory category,
    StructuredMessageSeverity severity = StructuredMessageSeverity.error,
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => StructuredMessage(
    // Keep the established wire namespace while this implementation is
    // extracted from the shared GrammarParserMessages companion.
    namespace: 'grammar.parser',
    code: code,
    category: category,
    severity: severity,
    arguments: arguments,
  );
}
