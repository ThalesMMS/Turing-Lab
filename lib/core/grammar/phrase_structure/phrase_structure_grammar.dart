import 'package:meta/meta.dart';

import 'grammar_symbol.dart';
import 'phrase_structure_production.dart';

@immutable
sealed class PhraseStructureGrammar {
  PhraseStructureGrammar({
    required this.id,
    required this.name,
    required this.revision,
    required Iterable<TerminalGrammarSymbol> terminals,
    required Iterable<NonterminalGrammarSymbol> nonterminals,
    required this.startSymbol,
  })  : terminals = Set<TerminalGrammarSymbol>.unmodifiable(terminals),
        nonterminals = Set<NonterminalGrammarSymbol>.unmodifiable(nonterminals);

  final String id;
  final String name;
  final int revision;
  final Set<TerminalGrammarSymbol> terminals;
  final Set<NonterminalGrammarSymbol> nonterminals;
  final NonterminalGrammarSymbol startSymbol;

  List<PhraseStructureProduction> get phraseProductions;
}

final class ContextFreeGrammar extends PhraseStructureGrammar {
  ContextFreeGrammar({
    required super.id,
    required super.name,
    required super.revision,
    required super.terminals,
    required super.nonterminals,
    required super.startSymbol,
    required Iterable<ContextFreeProduction> productions,
  }) : productions = List<ContextFreeProduction>.unmodifiable(
          productions.toList()..sort(),
        );

  final List<ContextFreeProduction> productions;

  @override
  List<PhraseStructureProduction> get phraseProductions =>
      List<PhraseStructureProduction>.unmodifiable(
        productions.map((production) => production.toPhraseStructure()),
      );

  UnrestrictedGrammar toUnrestricted() => UnrestrictedGrammar(
        id: id,
        name: name,
        revision: revision,
        terminals: terminals,
        nonterminals: nonterminals,
        startSymbol: startSymbol,
        productions: phraseProductions,
      );
}

final class UnrestrictedGrammar extends PhraseStructureGrammar {
  UnrestrictedGrammar({
    required super.id,
    required super.name,
    required super.revision,
    required super.terminals,
    required super.nonterminals,
    required super.startSymbol,
    required Iterable<PhraseStructureProduction> productions,
  }) : productions = List<PhraseStructureProduction>.unmodifiable(
          productions.toList()..sort(),
        );

  final List<PhraseStructureProduction> productions;

  @override
  List<PhraseStructureProduction> get phraseProductions => productions;

  UnrestrictedGrammar copyWith({
    String? id,
    String? name,
    int? revision,
    Iterable<TerminalGrammarSymbol>? terminals,
    Iterable<NonterminalGrammarSymbol>? nonterminals,
    NonterminalGrammarSymbol? startSymbol,
    Iterable<PhraseStructureProduction>? productions,
  }) =>
      UnrestrictedGrammar(
        id: id ?? this.id,
        name: name ?? this.name,
        revision: revision ?? this.revision,
        terminals: terminals ?? this.terminals,
        nonterminals: nonterminals ?? this.nonterminals,
        startSymbol: startSymbol ?? this.startSymbol,
        productions: productions ?? this.productions,
      );

  Map<String, Object?> toJson() => {
        'schema': {'id': 'turing-lab.unrestricted-grammar', 'version': 1},
        'id': id,
        'name': name,
        'revision': revision,
        'terminals':
            (terminals.toList()..sort()).map((symbol) => symbol.value).toList(),
        'nonterminals': (nonterminals.toList()..sort())
            .map((symbol) => symbol.value)
            .toList(),
        'startSymbol': startSymbol.value,
        'productions':
            productions.map((production) => production.toJson()).toList(),
      };

  static UnrestrictedGrammar fromJson(Map<String, Object?> encoded) {
    final schema = encoded['schema'];
    if (schema is! Map ||
        schema['id'] != 'turing-lab.unrestricted-grammar' ||
        schema['version'] != 1) {
      throw const FormatException('Unsupported unrestricted grammar schema.');
    }
    final id = encoded['id'];
    final name = encoded['name'];
    final revision = encoded['revision'];
    final start = encoded['startSymbol'];
    final terminals = encoded['terminals'];
    final nonterminals = encoded['nonterminals'];
    final productions = encoded['productions'];
    if (id is! String ||
        name is! String ||
        revision is! int ||
        start is! String ||
        terminals is! List ||
        nonterminals is! List ||
        productions is! List ||
        terminals.any((value) => value is! String) ||
        nonterminals.any((value) => value is! String)) {
      throw const FormatException('Malformed unrestricted grammar payload.');
    }
    return UnrestrictedGrammar(
      id: id,
      name: name,
      revision: revision,
      terminals: terminals.cast<String>().map(TerminalGrammarSymbol.new),
      nonterminals:
          nonterminals.cast<String>().map(NonterminalGrammarSymbol.new),
      startSymbol: NonterminalGrammarSymbol(start),
      productions: productions.map(PhraseStructureProduction.fromJson),
    );
  }
}
