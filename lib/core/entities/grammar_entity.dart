//
//  grammar_entity.dart
//  Turing Lab
//
//  Immutable structures representing formal grammars with an identifier,
//  terminal and nonterminal sets, start symbol, and associated productions.
//  Productions encapsulate left- and right-hand sides as ordered lists,
//  facilitating automaton conversions and specialized editor rendering.
//
//  Thales Matheus Mendonça Santos - October 2025
//
class GrammarEntity {
  final String id;
  final String name;
  final Set<String> terminals;
  final Set<String> nonTerminals;
  final String startSymbol;
  final List<ProductionEntity> productions;

  const GrammarEntity({
    required this.id,
    required this.name,
    required this.terminals,
    required this.nonTerminals,
    required this.startSymbol,
    required this.productions,
  });
}

class ProductionEntity {
  final String id;
  final List<String> leftSide;
  final List<String> rightSide;

  const ProductionEntity({
    required this.id,
    required this.leftSide,
    required this.rightSide,
  });
}
