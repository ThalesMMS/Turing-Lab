import 'dart:collection';

abstract base class TransducerSymbol {
  const TransducerSymbol(this.value);

  final String value;

  @override
  bool operator ==(Object other) =>
      other.runtimeType == runtimeType &&
      other is TransducerSymbol &&
      other.value == value;

  @override
  int get hashCode => Object.hash(runtimeType, value);

  @override
  String toString() => value;
}

final class TransducerInputSymbol extends TransducerSymbol
    implements Comparable<TransducerInputSymbol> {
  const TransducerInputSymbol(super.value);

  @override
  int compareTo(TransducerInputSymbol other) => value.compareTo(other.value);
}

final class TransducerOutputSymbol extends TransducerSymbol
    implements Comparable<TransducerOutputSymbol> {
  const TransducerOutputSymbol(super.value);

  @override
  int compareTo(TransducerOutputSymbol other) => value.compareTo(other.value);
}

final class TransducerInputWord {
  factory TransducerInputWord(Iterable<TransducerInputSymbol> symbols) =>
      TransducerInputWord._(List<TransducerInputSymbol>.unmodifiable(symbols));

  const TransducerInputWord._(this.symbols);

  static const empty = TransducerInputWord._([]);

  factory TransducerInputWord.fromValues(Iterable<String> values) =>
      TransducerInputWord._(
        List<TransducerInputSymbol>.unmodifiable(
          values.map(TransducerInputSymbol.new),
        ),
      );

  final List<TransducerInputSymbol> symbols;

  List<String> get values =>
      UnmodifiableListView(symbols.map((symbol) => symbol.value));

  String render() => values.join();

  @override
  bool operator ==(Object other) =>
      other is TransducerInputWord && _listEquals(symbols, other.symbols);

  @override
  int get hashCode => Object.hashAll(symbols);
}

/// Immutable suffix view over an input word without copying its symbols.
final class TransducerInputSuffix {
  TransducerInputSuffix(this.source, this.offset) {
    if (offset < 0 || offset > source.symbols.length) {
      throw RangeError.range(offset, 0, source.symbols.length, 'offset');
    }
  }

  final TransducerInputWord source;
  final int offset;

  Iterable<TransducerInputSymbol> get symbols => source.symbols.skip(offset);
  Iterable<String> get values => symbols.map((symbol) => symbol.value);
  int get length => source.symbols.length - offset;
  bool get isEmpty => offset == source.symbols.length;

  Iterable<String> previewValues(int limit) sync* {
    if (limit < 0) throw ArgumentError.value(limit, 'limit');
    final end = (offset + limit).clamp(offset, source.symbols.length);
    for (var index = offset; index < end; index++) {
      yield source.symbols[index].value;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is TransducerInputSuffix &&
      other.offset == offset &&
      other.source == source;

  @override
  int get hashCode => Object.hash(source, offset);
}

final class TransducerOutputWord {
  factory TransducerOutputWord(Iterable<TransducerOutputSymbol> symbols) =>
      TransducerOutputWord._(
        List<TransducerOutputSymbol>.unmodifiable(symbols),
      );

  const TransducerOutputWord._(this.symbols);

  static const empty = TransducerOutputWord._([]);

  factory TransducerOutputWord.fromValues(Iterable<String> values) =>
      TransducerOutputWord._(
        List<TransducerOutputSymbol>.unmodifiable(
          values.map(TransducerOutputSymbol.new),
        ),
      );

  final List<TransducerOutputSymbol> symbols;

  List<String> get values =>
      UnmodifiableListView(symbols.map((symbol) => symbol.value));

  String render() => values.join();

  TransducerOutputWord followedBy(TransducerOutputWord other) =>
      TransducerOutputWord(
        List<TransducerOutputSymbol>.unmodifiable([
          ...symbols,
          ...other.symbols,
        ]),
      );

  @override
  bool operator ==(Object other) =>
      other is TransducerOutputWord && _listEquals(symbols, other.symbols);

  @override
  int get hashCode => Object.hashAll(symbols);
}

sealed class TransducerTokenizationOutcome {
  const TransducerTokenizationOutcome();
}

final class TransducerTokenizationSuccess
    extends TransducerTokenizationOutcome {
  const TransducerTokenizationSuccess(this.word);

  final TransducerInputWord word;
}

final class TransducerTokenizationFailure
    extends TransducerTokenizationOutcome {
  const TransducerTokenizationFailure({
    required this.offset,
    required this.remaining,
    required this.prefix,
  });

  /// Offset in Dart string (UTF-16 code-unit) coordinates.
  final int offset;
  final String remaining;
  final TransducerInputWord prefix;
}

abstract final class TransducerInputTokenizer {
  static TransducerTokenizationOutcome tokenize(
    String raw,
    Iterable<TransducerInputSymbol> alphabet,
  ) {
    final candidates =
        alphabet.where((symbol) => symbol.value.isNotEmpty).toList()
          ..sort((left, right) {
            final byLength = right.value.length.compareTo(left.value.length);
            return byLength != 0 ? byLength : left.value.compareTo(right.value);
          });
    final symbols = <TransducerInputSymbol>[];
    var offset = 0;
    while (offset < raw.length) {
      TransducerInputSymbol? match;
      for (final candidate in candidates) {
        if (raw.startsWith(candidate.value, offset)) {
          match = candidate;
          break;
        }
      }
      if (match == null) {
        return TransducerTokenizationFailure(
          offset: offset,
          remaining: raw.substring(offset),
          prefix: TransducerInputWord(List.unmodifiable(symbols)),
        );
      }
      symbols.add(match);
      offset += match.value.length;
    }
    return TransducerTokenizationSuccess(
      TransducerInputWord(List.unmodifiable(symbols)),
    );
  }
}

bool _listEquals<T>(List<T> left, List<T> right) {
  if (identical(left, right)) return true;
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
