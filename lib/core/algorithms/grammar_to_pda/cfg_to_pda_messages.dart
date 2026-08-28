import '../../messages/structured_message.dart';

/// Locale-neutral diagnostics emitted by CFG-to-PDA construction.
abstract final class CfgToPdaMessages {
  static StructuredMessage emptyGrammar() => _validation('empty-grammar');

  static StructuredMessage missingStartSymbol() =>
      _validation('missing-start-symbol');

  static StructuredMessage undeclaredStartSymbol(String symbol) => _validation(
    'undeclared-start-symbol',
    arguments: {
      'symbol': StructuredMessageArgument.symbol(symbol, role: 'start-symbol'),
    },
  );

  static StructuredMessage malformedProduction(String productionId) =>
      _validation(
        'malformed-production',
        arguments: {
          'production': StructuredMessageArgument.identifier(
            productionId,
            role: 'production-id',
          ),
        },
      );

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

  static StructuredMessage llAnalysisFailed() =>
      _analysis('ll-analysis-failed');

  static StructuredMessage llConflict({
    required String nonTerminal,
    required String lookahead,
    required String productionIds,
  }) => _analysis(
    'll-conflict',
    arguments: {
      'nonterminal': StructuredMessageArgument.symbol(
        nonTerminal,
        role: 'nonterminal',
      ),
      'lookahead': StructuredMessageArgument.symbol(
        lookahead,
        role: 'lookahead-symbol',
      ),
      'productions': StructuredMessageArgument.literal(
        productionIds,
        role: 'production-id-list',
      ),
    },
  );

  static StructuredMessage lrConstructionUnavailable() =>
      _analysis('lr-construction-unavailable');

  static StructuredMessage lrConflict({
    required int state,
    required String lookahead,
    required String productionIds,
  }) => _analysis(
    'lr-conflict',
    arguments: {
      'state': StructuredMessageArgument.integer(state, role: 'lr-state'),
      'lookahead': StructuredMessageArgument.symbol(
        lookahead,
        role: 'lookahead-symbol',
      ),
      'productions': StructuredMessageArgument.literal(
        productionIds,
        role: 'production-id-list',
      ),
    },
  );

  static StructuredMessage outputInvalid() => _analysis('output-invalid');

  static StructuredMessage _validation(
    String code, {
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => _message(
    code,
    category: StructuredMessageCategory.validation,
    arguments: arguments,
  );

  static StructuredMessage _analysis(
    String code, {
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => _message(
    code,
    category: StructuredMessageCategory.analysis,
    arguments: arguments,
  );

  static StructuredMessage _message(
    String code, {
    required StructuredMessageCategory category,
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => StructuredMessage(
    namespace: 'cfg.to-pda',
    code: code,
    category: category,
    severity: StructuredMessageSeverity.error,
    arguments: arguments,
  );
}
