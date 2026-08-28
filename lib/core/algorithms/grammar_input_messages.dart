import '../messages/structured_message.dart';

/// Locale-neutral diagnostics emitted by the grammar input tokenizer.
///
/// The input symbol and zero-based source position remain formal data; only
/// the explanatory sentence is translated at the presentation boundary.
abstract final class GrammarInputMessages {
  static StructuredMessage invalidSymbol({
    required String symbol,
    required int position,
  }) => StructuredMessage(
    namespace: 'grammar.input-tokenizer',
    code: 'invalid-symbol',
    category: StructuredMessageCategory.parsing,
    severity: StructuredMessageSeverity.error,
    arguments: {
      'symbol': StructuredMessageArgument.symbol(symbol, role: 'input-symbol'),
      'position': StructuredMessageArgument.index(
        position,
        role: 'input-position',
      ),
    },
  );
}
