import '../messages/structured_message.dart';

/// Locale-neutral messages emitted by the bounded CFG brute-force parser.
abstract final class BruteForceMessages {
  static StructuredMessage _message(
    String code, {
    StructuredMessageCategory category = StructuredMessageCategory.validation,
    StructuredMessageSeverity severity = StructuredMessageSeverity.error,
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => StructuredMessage(
    namespace: 'grammar.brute-force',
    code: code,
    category: category,
    severity: severity,
    arguments: arguments,
  );

  static StructuredMessage invalidLimitNonNegative(String limit) => _message(
    'invalid-limit-non-negative',
    arguments: {
      'limit': StructuredMessageArgument.outcome(
        limit,
        role: 'brute-force-limit',
      ),
    },
  );

  static StructuredMessage invalidLimitPositive(String limit) => _message(
    'invalid-limit-positive',
    arguments: {
      'limit': StructuredMessageArgument.outcome(
        limit,
        role: 'brute-force-limit',
      ),
    },
  );

  static StructuredMessage emptyGrammar() => _message('empty-grammar');

  static StructuredMessage invalidStartSymbol() =>
      _message('invalid-start-symbol');

  static StructuredMessage overlappingSymbols(String symbols) => _message(
    'overlapping-symbols',
    arguments: {
      'symbols': StructuredMessageArgument.literal(
        symbols,
        role: 'grammar-symbol-list',
      ),
    },
  );

  static StructuredMessage malformedProduction() =>
      _message('malformed-production');

  static StructuredMessage duplicateProductionId() =>
      _message('duplicate-production-id');

  static StructuredMessage undeclaredSymbol({
    required String productionId,
    required String symbol,
  }) => _message(
    'undeclared-symbol',
    arguments: {
      'production': StructuredMessageArgument.identifier(
        productionId,
        role: 'production-id',
      ),
      'symbol': StructuredMessageArgument.symbol(symbol),
    },
  );

  static StructuredMessage invalidInputSymbol(String symbol) => _message(
    'invalid-input-symbol',
    arguments: {
      'symbol': StructuredMessageArgument.symbol(symbol, role: 'input-symbol'),
    },
  );

  static StructuredMessage cancelled() => _message(
    'cancelled',
    category: StructuredMessageCategory.parsing,
    severity: StructuredMessageSeverity.information,
  );

  static StructuredMessage rejectedExhausted() => _message(
    'rejected-exhausted',
    category: StructuredMessageCategory.parsing,
    severity: StructuredMessageSeverity.information,
  );

  static StructuredMessage acceptedAtLimit(String limit) => _message(
    'accepted-at-limit',
    category: StructuredMessageCategory.parsing,
    severity: StructuredMessageSeverity.information,
    arguments: {
      'limit': StructuredMessageArgument.outcome(
        limit,
        role: 'brute-force-limit',
      ),
    },
  );

  static StructuredMessage boundedAtLimit(String limit) => _message(
    'bounded-at-limit',
    category: StructuredMessageCategory.parsing,
    severity: StructuredMessageSeverity.warning,
    arguments: {
      'limit': StructuredMessageArgument.outcome(
        limit,
        role: 'brute-force-limit',
      ),
    },
  );
}
