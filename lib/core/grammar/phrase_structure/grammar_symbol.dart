import 'package:meta/meta.dart';

@immutable
sealed class PhraseGrammarSymbol implements Comparable<PhraseGrammarSymbol> {
  const PhraseGrammarSymbol(this.value);

  final String value;

  bool get isTerminal => this is TerminalGrammarSymbol;
  bool get isNonterminal => this is NonterminalGrammarSymbol;

  Map<String, Object?> toJson() => {
        'kind': isTerminal ? 'terminal' : 'nonterminal',
        'value': value,
      };

  static PhraseGrammarSymbol fromJson(Object? encoded) {
    if (encoded is! Map) {
      throw const FormatException('Grammar symbol must be an object.');
    }
    final map = Map<String, Object?>.from(encoded);
    final value = map['value'];
    if (value is! String) {
      throw const FormatException('Grammar symbol value must be a string.');
    }
    return switch (map['kind']) {
      'terminal' => TerminalGrammarSymbol(value),
      'nonterminal' => NonterminalGrammarSymbol(value),
      _ => throw const FormatException('Unknown grammar symbol kind.'),
    };
  }

  @override
  int compareTo(PhraseGrammarSymbol other) {
    final kindOrder = isNonterminal == other.isNonterminal
        ? 0
        : isNonterminal
            ? -1
            : 1;
    return kindOrder != 0 ? kindOrder : value.compareTo(other.value);
  }

  @override
  bool operator ==(Object other) =>
      other.runtimeType == runtimeType &&
      other is PhraseGrammarSymbol &&
      other.value == value;

  @override
  int get hashCode => Object.hash(runtimeType, value);

  @override
  String toString() => value;
}

final class TerminalGrammarSymbol extends PhraseGrammarSymbol {
  const TerminalGrammarSymbol(super.value);
}

final class NonterminalGrammarSymbol extends PhraseGrammarSymbol {
  const NonterminalGrammarSymbol(super.value);
}
