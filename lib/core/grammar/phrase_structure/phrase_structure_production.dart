import 'package:meta/meta.dart';

import 'grammar_symbol.dart';
import 'symbol_sequence.dart';

@immutable
final class PhraseStructureProduction
    implements Comparable<PhraseStructureProduction> {
  const PhraseStructureProduction({
    required this.id,
    required this.left,
    required this.right,
    required this.order,
  });

  final String id;
  final GrammarSymbolSequence left;
  final GrammarSymbolSequence right;
  final int order;

  String get structuralKey => '${left.stableKey}->${right.stableKey}';

  Map<String, Object?> toJson() => {
        'id': id,
        'order': order,
        'left': left.toJson(),
        'right': right.toJson(),
      };

  static PhraseStructureProduction fromJson(Object? encoded) {
    if (encoded is! Map) {
      throw const FormatException('Production must be an object.');
    }
    final map = Map<String, Object?>.from(encoded);
    final id = map['id'];
    final order = map['order'];
    if (id is! String || order is! int) {
      throw const FormatException('Production id/order are malformed.');
    }
    return PhraseStructureProduction(
      id: id,
      order: order,
      left: GrammarSymbolSequence.fromJson(map['left']),
      right: GrammarSymbolSequence.fromJson(map['right']),
    );
  }

  @override
  int compareTo(PhraseStructureProduction other) {
    final byOrder = order.compareTo(other.order);
    if (byOrder != 0) return byOrder;
    final byId = id.compareTo(other.id);
    if (byId != 0) return byId;
    final byLeft = left.compareTo(other.left);
    return byLeft != 0 ? byLeft : right.compareTo(other.right);
  }
}

@immutable
final class ContextFreeProduction implements Comparable<ContextFreeProduction> {
  const ContextFreeProduction({
    required this.id,
    required this.left,
    required this.right,
    required this.order,
  });

  final String id;
  final NonterminalGrammarSymbol left;
  final GrammarSymbolSequence right;
  final int order;

  PhraseStructureProduction toPhraseStructure() => PhraseStructureProduction(
        id: id,
        left: GrammarSymbolSequence([left]),
        right: right,
        order: order,
      );

  @override
  int compareTo(ContextFreeProduction other) =>
      toPhraseStructure().compareTo(other.toPhraseStructure());
}
