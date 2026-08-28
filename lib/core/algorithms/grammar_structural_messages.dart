import '../messages/structured_message.dart';

/// Locale-neutral diagnostics emitted by structural grammar analysis.
///
/// The legacy diagnostic message remains a stable code for callers that have
/// not moved to the structured payload yet. Presentation code must resolve
/// [StructuredMessage] at the active locale instead of translating domain
/// prose inside the analyzer.
abstract final class GrammarStructuralMessages {
  static StructuredMessage startSymbolMissing() => _message(
    'start-symbol-missing',
    category: StructuredMessageCategory.validation,
    severity: StructuredMessageSeverity.error,
  );

  static StructuredMessage startSymbolMissingForReachability() => _message(
    'start-symbol-missing-reachability',
    category: StructuredMessageCategory.validation,
    severity: StructuredMessageSeverity.error,
  );

  static StructuredMessage startSymbolNotNonterminal(String symbol) => _message(
    'start-symbol-not-nonterminal',
    category: StructuredMessageCategory.validation,
    severity: StructuredMessageSeverity.error,
    arguments: {
      'symbol': StructuredMessageArgument.symbol(
        symbol,
        role: 'grammar-start-symbol',
      ),
    },
  );

  static StructuredMessage startSymbolNotNonterminalForReachability(
    String symbol,
  ) => _message(
    'start-symbol-not-nonterminal-reachability',
    category: StructuredMessageCategory.validation,
    severity: StructuredMessageSeverity.error,
    arguments: {
      'symbol': StructuredMessageArgument.symbol(
        symbol,
        role: 'grammar-start-symbol',
      ),
    },
  );

  static StructuredMessage noProductions() => _message(
    'no-productions',
    category: StructuredMessageCategory.validation,
    severity: StructuredMessageSeverity.warning,
  );

  static StructuredMessage noProductionsForProductivity() => _message(
    'no-productions-productivity',
    category: StructuredMessageCategory.validation,
    severity: StructuredMessageSeverity.warning,
  );

  static StructuredMessage productionLeftSideEmpty(String productionId) =>
      _message(
        'production-left-side-empty',
        category: StructuredMessageCategory.validation,
        severity: StructuredMessageSeverity.error,
        arguments: {
          'production': StructuredMessageArgument.identifier(
            productionId,
            role: 'production-id',
          ),
        },
      );

  static StructuredMessage productionLeftSideNotSingleNonterminal(
    String productionId,
    String leftSide,
  ) => _message(
    'production-left-side-not-single-nonterminal',
    category: StructuredMessageCategory.validation,
    severity: StructuredMessageSeverity.error,
    arguments: {
      'production': StructuredMessageArgument.identifier(
        productionId,
        role: 'production-id',
      ),
      'left-side': StructuredMessageArgument.literal(
        leftSide,
        role: 'grammar-symbol-list',
      ),
    },
  );

  static StructuredMessage productionLeftSideEmptySymbol(String productionId) =>
      _message(
        'production-left-side-empty-symbol',
        category: StructuredMessageCategory.validation,
        severity: StructuredMessageSeverity.error,
        arguments: {
          'production': StructuredMessageArgument.identifier(
            productionId,
            role: 'production-id',
          ),
        },
      );

  static StructuredMessage productionLeftSideNotNonterminal(
    String productionId,
    String symbol,
  ) => _message(
    'production-left-side-not-nonterminal',
    category: StructuredMessageCategory.validation,
    severity: StructuredMessageSeverity.error,
    arguments: {
      'production': StructuredMessageArgument.identifier(
        productionId,
        role: 'production-id',
      ),
      'symbol': StructuredMessageArgument.symbol(
        symbol,
        role: 'grammar-nonterminal',
      ),
    },
  );

  static StructuredMessage productionReferencesUnknownSymbol(
    String productionId,
    String symbol,
  ) => _message(
    'production-unknown-symbol',
    category: StructuredMessageCategory.validation,
    severity: StructuredMessageSeverity.warning,
    arguments: {
      'production': StructuredMessageArgument.identifier(
        productionId,
        role: 'production-id',
      ),
      'symbol': StructuredMessageArgument.symbol(symbol),
    },
  );

  static StructuredMessage unknownSymbolForReachability(String symbol) =>
      _message(
        'unknown-symbol-reachability',
        category: StructuredMessageCategory.analysis,
        severity: StructuredMessageSeverity.warning,
        arguments: {'symbol': StructuredMessageArgument.symbol(symbol)},
      );

  static StructuredMessage unknownSymbolForProductivity(String symbol) =>
      _message(
        'unknown-symbol-productivity',
        category: StructuredMessageCategory.analysis,
        severity: StructuredMessageSeverity.warning,
        arguments: {'symbol': StructuredMessageArgument.symbol(symbol)},
      );

  static StructuredMessage lambdaProductionRhsNotEmpty(String productionId) =>
      _message(
        'lambda-production-rhs-not-empty',
        category: StructuredMessageCategory.validation,
        severity: StructuredMessageSeverity.error,
        arguments: {
          'production': StructuredMessageArgument.identifier(
            productionId,
            role: 'production-id',
          ),
        },
      );

  static StructuredMessage productionRhsEmpty(String productionId) => _message(
    'production-rhs-empty',
    category: StructuredMessageCategory.validation,
    severity: StructuredMessageSeverity.error,
    arguments: {
      'production': StructuredMessageArgument.identifier(
        productionId,
        role: 'production-id',
      ),
    },
  );

  static StructuredMessage unreachableNonterminals(int count, String symbols) =>
      _message(
        'unreachable-nonterminals',
        category: StructuredMessageCategory.analysis,
        severity: StructuredMessageSeverity.warning,
        arguments: {
          'count': StructuredMessageArgument.count(
            count,
            role: 'diagnostic-count',
          ),
          'symbols': StructuredMessageArgument.literal(
            symbols,
            role: 'grammar-symbol-list',
          ),
        },
      );

  static StructuredMessage unproductiveNonterminals(
    int count,
    String symbols,
  ) => _message(
    'unproductive-nonterminals',
    category: StructuredMessageCategory.analysis,
    severity: StructuredMessageSeverity.warning,
    arguments: {
      'count': StructuredMessageArgument.count(count, role: 'diagnostic-count'),
      'symbols': StructuredMessageArgument.literal(
        symbols,
        role: 'grammar-symbol-list',
      ),
    },
  );

  static StructuredMessage unproductiveProductions(String symbols) => _message(
    'unproductive-productions',
    category: StructuredMessageCategory.analysis,
    severity: StructuredMessageSeverity.information,
    arguments: {
      'symbols': StructuredMessageArgument.literal(
        symbols,
        role: 'grammar-symbol-list',
      ),
    },
  );

  static StructuredMessage _message(
    String code, {
    required StructuredMessageCategory category,
    required StructuredMessageSeverity severity,
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => StructuredMessage(
    namespace: 'grammar.structural',
    code: code,
    category: category,
    severity: severity,
    arguments: arguments,
  );
}
