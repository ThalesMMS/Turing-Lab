import '../messages/structured_message.dart';

/// Locale-neutral diagnostics emitted by the grammar parser coordinator and
/// its LL(1), Earley, and recursive-descent implementations.
abstract final class GrammarParserMessages {
  static StructuredMessage emptyGrammar() => _validation('empty-grammar');

  static StructuredMessage missingStartSymbol() =>
      _validation('missing-start-symbol');

  static StructuredMessage startSymbolNotNonterminal() =>
      _validation('start-symbol-not-nonterminal');

  static StructuredMessage inputRejected(String input) => _parsing(
    'input-rejected',
    arguments: {
      'input': StructuredMessageArgument.literal(input, role: 'input-string'),
    },
  );

  static StructuredMessage allStrategiesFailed(String strategy) => _parsing(
    'all-strategies-failed',
    arguments: {
      'strategy': StructuredMessageArgument.strategy(
        strategy,
        role: 'parser-strategy',
      ),
    },
  );

  static StructuredMessage generatedStringsFailed() =>
      _analysis('generated-strings-failed');

  static StructuredMessage ll1StepLimitInvalid(int limit) => _validation(
    'll1-step-limit-invalid',
    arguments: {
      'limit': StructuredMessageArgument.bound(
        limit,
        role: 'parser-step-limit',
      ),
    },
  );

  static StructuredMessage ll1Conflict({
    required String nonTerminal,
    required String lookahead,
    required String alternatives,
  }) => _analysis(
    'll1-conflict',
    severity: StructuredMessageSeverity.warning,
    arguments: {
      'non-terminal': StructuredMessageArgument.symbol(
        nonTerminal,
        role: 'grammar-nonterminal',
      ),
      'lookahead': StructuredMessageArgument.symbol(
        lookahead,
        role: 'grammar-lookahead',
      ),
      'alternatives': StructuredMessageArgument.literal(
        alternatives,
        role: 'grammar-productions',
      ),
    },
  );

  static StructuredMessage ll1Cancelled() => _parsing(
    'll1-cancelled',
    severity: StructuredMessageSeverity.information,
  );

  static StructuredMessage ll1TimedOut(Duration timeout) => _parsing(
    'll1-timed-out',
    severity: StructuredMessageSeverity.warning,
    arguments: {'timeout': _duration(timeout, role: 'parser-timeout')},
  );

  static StructuredMessage ll1StepLimitReached(int limit) => _parsing(
    'll1-step-limit-reached',
    severity: StructuredMessageSeverity.warning,
    arguments: {
      'limit': StructuredMessageArgument.bound(
        limit,
        role: 'parser-step-limit',
      ),
    },
  );

  static StructuredMessage ll1TrailingInput({
    required String lookahead,
    required int position,
  }) => _parsing(
    'll1-trailing-input',
    arguments: {
      'lookahead': StructuredMessageArgument.symbol(
        lookahead,
        role: 'input-symbol',
      ),
      'position': StructuredMessageArgument.index(
        position,
        role: 'input-position',
      ),
    },
  );

  static StructuredMessage ll1UnexpectedEnd(String expected) => _parsing(
    'll1-unexpected-end',
    arguments: {
      'expected': StructuredMessageArgument.symbol(
        expected,
        role: 'expected-symbol',
      ),
    },
  );

  static StructuredMessage ll1TerminalMismatch({
    required String expected,
    required String found,
    required int position,
  }) => _parsing(
    'll1-terminal-mismatch',
    arguments: {
      'expected': StructuredMessageArgument.symbol(
        expected,
        role: 'expected-symbol',
      ),
      'found': StructuredMessageArgument.symbol(found, role: 'found-symbol'),
      'position': StructuredMessageArgument.index(
        position,
        role: 'input-position',
      ),
    },
  );

  static StructuredMessage ll1EmptyTableCell({
    required String nonTerminal,
    required String lookahead,
    required String expected,
  }) => _parsing(
    'll1-empty-table-cell',
    arguments: {
      'non-terminal': StructuredMessageArgument.symbol(
        nonTerminal,
        role: 'grammar-nonterminal',
      ),
      'lookahead': StructuredMessageArgument.symbol(
        lookahead,
        role: 'grammar-lookahead',
      ),
      'expected': StructuredMessageArgument.literal(
        expected,
        role: 'expected-symbol-list',
      ),
    },
  );

  static StructuredMessage ll1ConflictCell({
    required String nonTerminal,
    required String lookahead,
    required String productions,
  }) => ll1Conflict(
    nonTerminal: nonTerminal,
    lookahead: lookahead,
    alternatives: productions,
  );

  static StructuredMessage ll1EmptyStack() =>
      _parsing('ll1-empty-stack', severity: StructuredMessageSeverity.warning);

  static StructuredMessage earleyMalformedProduction() =>
      _validation('earley-malformed-production');

  static StructuredMessage earleyMissingStartSymbol() =>
      _validation('earley-missing-start-symbol');

  static StructuredMessage earleyTimedOut(Duration timeout) => _parsing(
    'earley-timed-out',
    severity: StructuredMessageSeverity.warning,
    arguments: {'timeout': _duration(timeout, role: 'parser-timeout')},
  );

  static StructuredMessage recursiveDescentTimedOut() => _parsing(
    'recursive-descent-timed-out',
    severity: StructuredMessageSeverity.warning,
  );

  static StructuredMessage recursiveDescentFailed() =>
      _analysis('recursive-descent-failed');

  static StructuredMessage _validation(
    String code, {
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => _message(
    code,
    category: StructuredMessageCategory.validation,
    arguments: arguments,
  );

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

  static StructuredMessage _analysis(
    String code, {
    StructuredMessageSeverity severity = StructuredMessageSeverity.error,
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => _message(
    code,
    category: StructuredMessageCategory.analysis,
    severity: severity,
    arguments: arguments,
  );

  static StructuredMessageArgument _duration(
    Duration duration, {
    required String role,
  }) => StructuredMessageArgument.duration(
    duration.isNegative ? Duration.zero : duration,
    role: role,
  );

  static StructuredMessage _message(
    String code, {
    required StructuredMessageCategory category,
    StructuredMessageSeverity severity = StructuredMessageSeverity.error,
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => StructuredMessage(
    namespace: 'grammar.parser',
    code: code,
    category: category,
    severity: severity,
    arguments: arguments,
  );
}
