import 'package:meta/meta.dart';

import 'grammar_symbol.dart';

@immutable
final class GrammarSymbolSequence implements Comparable<GrammarSymbolSequence> {
  GrammarSymbolSequence(Iterable<PhraseGrammarSymbol> symbols)
      : symbols = List<PhraseGrammarSymbol>.unmodifiable(symbols);

  const GrammarSymbolSequence.empty() : symbols = const [];

  final List<PhraseGrammarSymbol> symbols;

  int get length => symbols.length;
  bool get isEmpty => symbols.isEmpty;
  bool get isNotEmpty => symbols.isNotEmpty;

  PhraseGrammarSymbol operator [](int index) => symbols[index];

  bool matchesAt(GrammarSymbolSequence pattern, int start) {
    if (start < 0 || start + pattern.length > length) return false;
    for (var index = 0; index < pattern.length; index++) {
      if (symbols[start + index] != pattern[index]) return false;
    }
    return true;
  }

  GrammarSymbolSequence replaceRange(
    int start,
    int end,
    GrammarSymbolSequence replacement,
  ) =>
      GrammarSymbolSequence([
        ...symbols.take(start),
        ...replacement.symbols,
        ...symbols.skip(end),
      ]);

  List<Object?> toJson() => symbols.map((symbol) => symbol.toJson()).toList();

  static GrammarSymbolSequence fromJson(Object? encoded) {
    if (encoded is! List) {
      throw const FormatException('Grammar symbol sequence must be an array.');
    }
    return GrammarSymbolSequence(encoded.map(PhraseGrammarSymbol.fromJson));
  }

  String get stableKey => symbols
      .map((symbol) =>
          '${symbol.isTerminal ? 't' : 'n'}:${symbol.value.length}:${symbol.value}')
      .join('|');

  @override
  int compareTo(GrammarSymbolSequence other) {
    final shared = length < other.length ? length : other.length;
    for (var index = 0; index < shared; index++) {
      final order = symbols[index].compareTo(other.symbols[index]);
      if (order != 0) return order;
    }
    return length.compareTo(other.length);
  }

  @override
  bool operator ==(Object other) =>
      other is GrammarSymbolSequence && _sameSymbols(other.symbols, symbols);

  @override
  int get hashCode => Object.hashAll(symbols);

  @override
  String toString() => isEmpty ? 'ε' : symbols.join(' ');
}

bool _sameSymbols(
  List<PhraseGrammarSymbol> left,
  List<PhraseGrammarSymbol> right,
) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
