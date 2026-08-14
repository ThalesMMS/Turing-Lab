//
//  grammar_entity.dart
//  Turing Lab
//
//  Estruturas imutáveis que representam gramáticas formais com identificador,
//  conjuntos terminais e não terminais, símbolo inicial e produções associadas.
//  As produções encapsulam lados esquerdo e direito como listas ordenadas, facilitando
//  a integração com conversões de autômatos e renderização de editores especializados.
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
