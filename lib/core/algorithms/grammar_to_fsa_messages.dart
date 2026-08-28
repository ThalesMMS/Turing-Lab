import '../messages/structured_message.dart';

/// Locale-neutral validation diagnostics emitted by grammar-to-FSA conversion.
abstract final class GrammarToFsaMessages {
  static StructuredMessage missingNonterminals() =>
      _validation('missing-nonterminals');

  static StructuredMessage undeclaredStartSymbol() =>
      _validation('undeclared-start-symbol');

  static StructuredMessage leftSideNotSingle(String productionId) =>
      _validation(
        'left-side-not-single',
        arguments: {
          'production': StructuredMessageArgument.identifier(
            productionId,
            role: 'production-id',
          ),
        },
      );

  static StructuredMessage unknownLeftNonterminal(
    String productionId,
    String symbol,
  ) => _validation(
    'unknown-left-nonterminal',
    arguments: {
      'production': StructuredMessageArgument.identifier(
        productionId,
        role: 'production-id',
      ),
      'symbol': StructuredMessageArgument.symbol(symbol, role: 'nonterminal'),
    },
  );

  static StructuredMessage unknownRightNonterminal(
    String productionId,
    String symbol,
  ) => _validation(
    'unknown-right-nonterminal',
    arguments: {
      'production': StructuredMessageArgument.identifier(
        productionId,
        role: 'production-id',
      ),
      'symbol': StructuredMessageArgument.symbol(symbol, role: 'nonterminal'),
    },
  );

  static StructuredMessage tooManyRightSymbols(String productionId) =>
      _validation(
        'too-many-right-symbols',
        arguments: {
          'production': StructuredMessageArgument.identifier(
            productionId,
            role: 'production-id',
          ),
        },
      );

  static StructuredMessage firstSymbolNotTerminal(String productionId) =>
      _validation(
        'first-symbol-not-terminal',
        arguments: {
          'production': StructuredMessageArgument.identifier(
            productionId,
            role: 'production-id',
          ),
        },
      );

  static StructuredMessage lastSymbolNotNonterminal(String productionId) =>
      _validation(
        'last-symbol-not-nonterminal',
        arguments: {
          'production': StructuredMessageArgument.identifier(
            productionId,
            role: 'production-id',
          ),
        },
      );

  static StructuredMessage _validation(
    String code, {
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => StructuredMessage(
    namespace: 'grammar.to-fsa',
    code: code,
    category: StructuredMessageCategory.validation,
    severity: StructuredMessageSeverity.error,
    arguments: arguments,
  );
}
