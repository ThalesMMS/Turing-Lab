import '../messages/structured_message.dart';

/// Locale-neutral diagnostics emitted by canonical LR(1) construction and
/// parsing.
abstract final class Lr1ParserMessages {
  static StructuredMessage staleConstruction() =>
      _tableFailure('stale-construction');

  static StructuredMessage invalidGrammar() => _validation('invalid-grammar');

  static StructuredMessage missingStartSymbol() =>
      _validation('missing-start-symbol');

  static StructuredMessage malformedProduction() =>
      _validation('malformed-production');

  static StructuredMessage duplicateProductionId(String productionId) =>
      _validation(
        'duplicate-production-id',
        arguments: {
          'production': StructuredMessageArgument.identifier(
            productionId,
            role: 'production-id',
          ),
        },
      );

  static StructuredMessage undeclaredSymbol({
    required String productionId,
    required String symbol,
  }) => _validation(
    'undeclared-symbol',
    arguments: {
      'production': StructuredMessageArgument.identifier(
        productionId,
        role: 'production-id',
      ),
      'symbol': StructuredMessageArgument.symbol(
        symbol,
        role: 'grammar-symbol',
      ),
    },
  );

  static StructuredMessage constructionCancelled() => _construction(
    'construction-cancelled',
    severity: StructuredMessageSeverity.information,
  );

  static StructuredMessage constructionTimedOut(Duration timeout) =>
      _construction(
        'construction-timed-out',
        severity: StructuredMessageSeverity.warning,
        arguments: {'timeout': _duration(timeout)},
      );

  static StructuredMessage constructionStateLimit() => _construction(
    'construction-state-limit',
    severity: StructuredMessageSeverity.warning,
  );

  static StructuredMessage constructionItemLimit() => _construction(
    'construction-item-limit',
    severity: StructuredMessageSeverity.warning,
  );

  static StructuredMessage conflict({
    required String stateId,
    required String lookahead,
  }) => _analysis(
    'conflict',
    severity: StructuredMessageSeverity.warning,
    arguments: {
      'state': StructuredMessageArgument.identifier(
        stateId,
        role: 'parser-state-id',
      ),
      'lookahead': StructuredMessageArgument.symbol(
        lookahead,
        role: 'grammar-lookahead',
      ),
    },
  );

  static StructuredMessage cancelled() =>
      _parsing('cancelled', severity: StructuredMessageSeverity.information);

  static StructuredMessage timedOut(Duration timeout) => _parsing(
    'timed-out',
    severity: StructuredMessageSeverity.warning,
    arguments: {'timeout': _duration(timeout)},
  );

  static StructuredMessage stepLimitReached(int limit) => _parsing(
    'step-limit-reached',
    severity: StructuredMessageSeverity.warning,
    arguments: {
      'limit': StructuredMessageArgument.bound(
        limit,
        role: 'parser-step-limit',
      ),
    },
  );

  static StructuredMessage emptyActionCell({
    required String stateId,
    required String lookahead,
  }) => _parsing(
    'empty-action-cell',
    arguments: {
      'state': StructuredMessageArgument.identifier(
        stateId,
        role: 'parser-state-id',
      ),
      'lookahead': StructuredMessageArgument.symbol(
        lookahead,
        role: 'grammar-lookahead',
      ),
    },
  );

  static StructuredMessage actionConflict({
    required String stateId,
    required String lookahead,
  }) => _analysis(
    'action-conflict',
    severity: StructuredMessageSeverity.warning,
    arguments: {
      'state': StructuredMessageArgument.identifier(
        stateId,
        role: 'parser-state-id',
      ),
      'lookahead': StructuredMessageArgument.symbol(
        lookahead,
        role: 'grammar-lookahead',
      ),
    },
  );

  static StructuredMessage shifted({
    required String symbol,
    required String targetState,
  }) => _parsing(
    'shifted',
    severity: StructuredMessageSeverity.information,
    arguments: {
      'symbol': StructuredMessageArgument.symbol(symbol, role: 'input-symbol'),
      'target-state': StructuredMessageArgument.identifier(
        targetState,
        role: 'parser-state-id',
      ),
    },
  );

  static StructuredMessage reduced({
    required String productionId,
    required String leftSide,
    required String rightSide,
  }) => _parsing(
    'reduced',
    severity: StructuredMessageSeverity.information,
    arguments: {
      'production': StructuredMessageArgument.identifier(
        productionId,
        role: 'production-id',
      ),
      'left-side': StructuredMessageArgument.symbol(
        leftSide,
        role: 'grammar-nonterminal',
      ),
      'right-side': StructuredMessageArgument.literal(
        rightSide,
        role: 'grammar-production-right-side',
      ),
    },
  );

  static StructuredMessage accepted() =>
      _parsing('accepted', severity: StructuredMessageSeverity.information);

  static StructuredMessage invalidParserState() =>
      _tableFailure('invalid-parser-state');

  static StructuredMessage missingGoto({
    required String stateId,
    required String nonTerminal,
  }) => _tableFailure(
    'missing-goto',
    arguments: {
      'state': StructuredMessageArgument.identifier(
        stateId,
        role: 'parser-state-id',
      ),
      'non-terminal': StructuredMessageArgument.symbol(
        nonTerminal,
        role: 'grammar-nonterminal',
      ),
    },
  );

  static StructuredMessage _validation(
    String code, {
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => _message(
    code,
    category: StructuredMessageCategory.validation,
    arguments: arguments,
  );

  static StructuredMessage _construction(
    String code, {
    StructuredMessageSeverity severity = StructuredMessageSeverity.error,
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => _message(
    code,
    category: StructuredMessageCategory.analysis,
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

  static StructuredMessage _tableFailure(
    String code, {
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => _message(
    code,
    category: StructuredMessageCategory.analysis,
    arguments: arguments,
  );

  static StructuredMessageArgument _duration(Duration timeout) =>
      StructuredMessageArgument.duration(
        timeout.isNegative ? Duration.zero : timeout,
        role: 'parser-timeout',
      );

  static StructuredMessage _message(
    String code, {
    required StructuredMessageCategory category,
    StructuredMessageSeverity severity = StructuredMessageSeverity.error,
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => StructuredMessage(
    namespace: 'grammar.lr1',
    code: code,
    category: category,
    severity: severity,
    arguments: arguments,
  );
}
