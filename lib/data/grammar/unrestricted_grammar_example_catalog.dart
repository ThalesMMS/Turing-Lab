import '../../core/formal_systems/formal_systems.dart';
import '../../core/grammar/phrase_structure/phrase_structure.dart';
import '../../core/models/asset_example.dart';

final class UnrestrictedGrammarExampleCatalog
    implements ExampleCatalogCapability<Object> {
  const UnrestrictedGrammarExampleCatalog();

  @override
  CapabilityNamespaceId get namespace =>
      const CapabilityNamespaceId('examples.grammar.unrestricted.v1');

  @override
  Future<List<AssetExample<Object>>> loadExamples() async => [
    AssetExample<Object>(
      id: 'an-bn-cn',
      name: 'an-bn-cn',
      description: 'an-bn-cn',
      category: ExampleCategory.unrestrictedGrammar,
      difficultyLevel: DifficultyLevel.medium,
      complexityLevel: ExampleComplexityLevel.medium,
      tags: const ['context-sensitive', 'noncontracting'],
      payload: _anBnCn(),
    ),
    AssetExample<Object>(
      id: 'context-copying',
      name: 'context-copying',
      description: 'context-copying',
      category: ExampleCategory.unrestrictedGrammar,
      difficultyLevel: DifficultyLevel.hard,
      complexityLevel: ExampleComplexityLevel.medium,
      tags: const ['context-sensitive', 'copying'],
      payload: _contextCopying(),
    ),
    AssetExample<Object>(
      id: 'tm-generated',
      name: 'tm-generated',
      description: 'tm-generated',
      category: ExampleCategory.unrestrictedGrammar,
      difficultyLevel: DifficultyLevel.hard,
      complexityLevel: ExampleComplexityLevel.high,
      tags: const ['unrestricted', 'turing-machine', 'generated'],
      payload: _tmGenerated(),
    ),
  ];
}

UnrestrictedGrammar _anBnCn() => _grammar(
  id: 'an-bn-cn',
  terminals: const ['a', 'b', 'c'],
  nonterminals: const ['S', 'B', 'C'],
  productions: [
    _production('p0', ['n:S'], ['t:a', 'n:S', 'n:B', 'n:C'], 0),
    _production('p1', ['n:S'], ['t:a', 'n:B', 'n:C'], 1),
    _production('p2', ['n:C', 'n:B'], ['n:B', 'n:C'], 2),
    _production('p3', ['t:a', 'n:B'], ['t:a', 't:b'], 3),
    _production('p4', ['t:b', 'n:B'], ['t:b', 't:b'], 4),
    _production('p5', ['t:b', 'n:C'], ['t:b', 't:c'], 5),
    _production('p6', ['t:c', 'n:C'], ['t:c', 't:c'], 6),
  ],
);

UnrestrictedGrammar _contextCopying() => _grammar(
  id: 'context-copying',
  terminals: const ['a', 'b'],
  nonterminals: const ['S', 'M'],
  productions: [
    _production('p0', ['n:S'], ['t:a', 'n:M', 't:b'], 0),
    _production('p1', ['n:M', 't:b'], ['t:b', 'n:M'], 1),
    _production('p2', ['t:b', 'n:M'], ['t:b', 't:b'], 2),
  ],
);

UnrestrictedGrammar _tmGenerated() => _grammar(
  id: 'tm-generated',
  terminals: const ['a', '✓'],
  nonterminals: const ['S', '[q0,a]', '[q1,a]'],
  productions: [
    _production('p0', ['n:S'], ['n:[q0,a]'], 0),
    _production('p1', ['n:[q0,a]'], ['n:[q1,a]', 't:a'], 1),
    _production('p2', ['n:[q1,a]', 't:a'], ['t:✓'], 2),
  ],
);

UnrestrictedGrammar _grammar({
  required String id,
  required List<String> terminals,
  required List<String> nonterminals,
  required List<PhraseStructureProduction> productions,
}) => UnrestrictedGrammar(
  id: id,
  name: id,
  revision: 0,
  terminals: terminals.map(TerminalGrammarSymbol.new),
  nonterminals: nonterminals.map(NonterminalGrammarSymbol.new),
  startSymbol: const NonterminalGrammarSymbol('S'),
  productions: productions,
);

PhraseStructureProduction _production(
  String id,
  List<String> left,
  List<String> right,
  int order,
) => PhraseStructureProduction(
  id: id,
  order: order,
  left: GrammarSymbolSequence(left.map(_symbol)),
  right: GrammarSymbolSequence(right.map(_symbol)),
);

PhraseGrammarSymbol _symbol(String encoded) => encoded.startsWith('n:')
    ? NonterminalGrammarSymbol(encoded.substring(2))
    : TerminalGrammarSymbol(encoded.substring(2));
