final class LSystemExampleContentCopy {
  const LSystemExampleContentCopy({
    required this.title,
    required this.summary,
    required this.learningObjective,
    required this.limitation,
    required this.accessibleVisualizationDescription,
  });

  final String title;
  final String summary;
  final String learningObjective;
  final String limitation;
  final String accessibleVisualizationDescription;

  String get semanticLabel => [
    title,
    summary,
    learningObjective,
    limitation,
    accessibleVisualizationDescription,
  ].join(' ');
}

abstract final class LSystemExampleContentCopies {
  static final _entries = List<_LSystemExampleContentEntry>.unmodifiable([
    _entry(
      id: 'l-system.koch-curve',
      en: const LSystemExampleContentCopy(
        title: 'Koch curve',
        summary:
            'A deterministic replacement turns each segment into a repeating snowflake edge.',
        learningObjective:
            'Observe how parallel rewriting creates self-similar detail at every generation.',
        limitation:
            'This preset focuses on context-free deterministic rewriting and does not explore weighted alternatives.',
        accessibleVisualizationDescription:
            'The turtle drawing is an angular open curve made of repeating triangular peaks at progressively smaller scales.',
      ),
      pt: const LSystemExampleContentCopy(
        title: 'Curva de Koch',
        summary:
            'Uma substituição determinística transforma cada segmento em uma borda de floco de neve repetitiva.',
        learningObjective:
            'Observe como a reescrita paralela cria detalhes autossimilares a cada geração.',
        limitation:
            'Este exemplo se concentra em reescrita determinística livre de contexto e não explora alternativas ponderadas.',
        accessibleVisualizationDescription:
            'O desenho da tartaruga é uma curva aberta angular, formada por picos triangulares repetidos em escalas cada vez menores.',
      ),
    ),
    _entry(
      id: 'l-system.sierpinski-triangle',
      en: const LSystemExampleContentCopy(
        title: 'Sierpiński triangle',
        summary:
            'Two drawing symbols rewrite together to form a triangular gasket.',
        learningObjective:
            'Compare the roles of cooperating symbols in a deterministic parallel grammar.',
        limitation:
            'The preset illustrates one fixed triangular construction rather than arbitrary polygonal fractals.',
        accessibleVisualizationDescription:
            'The turtle drawing forms a large triangle subdivided into many smaller triangles, with repeated triangular gaps.',
      ),
      pt: const LSystemExampleContentCopy(
        title: 'Triângulo de Sierpiński',
        summary:
            'Dois símbolos de desenho são reescritos em conjunto para formar uma malha triangular.',
        learningObjective:
            'Compare as funções de símbolos cooperantes em uma gramática paralela determinística.',
        limitation:
            'O exemplo ilustra uma construção triangular fixa, não fractais poligonais arbitrários.',
        accessibleVisualizationDescription:
            'O desenho da tartaruga forma um grande triângulo dividido em muitos triângulos menores, com lacunas triangulares repetidas.',
      ),
    ),
    _entry(
      id: 'l-system.dragon-curve',
      en: const LSystemExampleContentCopy(
        title: 'Dragon curve',
        summary:
            'Two control symbols guide a folded path while only the drawing command leaves a visible trace.',
        learningObjective:
            'Distinguish rewriting symbols that control growth from commands that draw the result.',
        limitation:
            'The control symbols are tuned for this curve and do not describe every paper-folding sequence.',
        accessibleVisualizationDescription:
            'The turtle drawing is a dense right-angled curve that repeatedly folds around itself without crossing its segments.',
      ),
      pt: const LSystemExampleContentCopy(
        title: 'Curva do dragão',
        summary:
            'Dois símbolos de controle orientam um caminho dobrado, enquanto apenas o comando de desenho deixa um traço visível.',
        learningObjective:
            'Diferencie símbolos de reescrita que controlam o crescimento de comandos que desenham o resultado.',
        limitation:
            'Os símbolos de controle foram ajustados para esta curva e não descrevem toda sequência de dobraduras.',
        accessibleVisualizationDescription:
            'O desenho da tartaruga é uma curva densa, feita de ângulos retos, que se dobra repetidamente ao redor de si sem cruzar os segmentos.',
      ),
    ),
    _entry(
      id: 'l-system.fractal-plant',
      en: const LSystemExampleContentCopy(
        title: 'Fractal plant',
        summary:
            'Nested branch commands turn parallel rewriting into a compact botanical form.',
        learningObjective:
            'Relate saved turtle positions to branches that return to a common stem.',
        limitation:
            'The result is a stylized planar plant, not a biological growth model.',
        accessibleVisualizationDescription:
            'The turtle drawing resembles a leafy plant with a central stem, angled side branches, and smaller branches nested within them.',
      ),
      pt: const LSystemExampleContentCopy(
        title: 'Planta fractal',
        summary:
            'Comandos de ramificação aninhados transformam a reescrita paralela em uma forma botânica compacta.',
        learningObjective:
            'Relacione posições salvas da tartaruga a ramos que retornam a um caule comum.',
        limitation:
            'O resultado é uma planta plana estilizada, não um modelo de crescimento biológico.',
        accessibleVisualizationDescription:
            'O desenho da tartaruga lembra uma planta folhosa, com caule central, ramos laterais inclinados e ramificações menores aninhadas.',
      ),
    ),
    _entry(
      id: 'l-system.branching-tree',
      en: const LSystemExampleContentCopy(
        title: 'Branching tree',
        summary:
            'Balanced branch commands repeat the same tree structure at smaller scales.',
        learningObjective:
            'Inspect how push and pop operations preserve the trunk while side branches are drawn.',
        limitation:
            'Every branch follows the same deterministic pattern, so the tree has no natural variation.',
        accessibleVisualizationDescription:
            'The turtle drawing is a symmetric tree with a vertical trunk and repeated forked branches on both sides.',
      ),
      pt: const LSystemExampleContentCopy(
        title: 'Árvore ramificada',
        summary:
            'Comandos de ramificação balanceados repetem a mesma estrutura de árvore em escalas menores.',
        learningObjective:
            'Observe como operações de empilhar e desempilhar preservam o tronco durante o desenho dos ramos laterais.',
        limitation:
            'Todos os ramos seguem o mesmo padrão determinístico, portanto a árvore não apresenta variação natural.',
        accessibleVisualizationDescription:
            'O desenho da tartaruga é uma árvore simétrica, com tronco vertical e ramos bifurcados repetidos nos dois lados.',
      ),
    ),
    _entry(
      id: 'l-system.seeded-context-turtle',
      en: const LSystemExampleContentCopy(
        title: 'Seeded context turtle',
        summary:
            'Context checks and weighted choices select styled turtle commands reproducibly.',
        learningObjective:
            'Explore how neighboring symbols, a fixed random seed, and turtle styling affect one rewrite.',
        limitation:
            'The preset runs a short seeded scenario and does not represent the full range of stochastic growth.',
        accessibleVisualizationDescription:
            'The turtle visualization draws a short colored construction whose path can branch or close into a polygon according to the seeded choice.',
      ),
      pt: const LSystemExampleContentCopy(
        title: 'Tartaruga contextual com semente',
        summary:
            'Verificações de contexto e escolhas ponderadas selecionam comandos estilizados da tartaruga de forma reproduzível.',
        learningObjective:
            'Explore como símbolos vizinhos, uma semente aleatória fixa e o estilo da tartaruga afetam uma reescrita.',
        limitation:
            'O exemplo executa um cenário curto com semente e não representa toda a variedade do crescimento estocástico.',
        accessibleVisualizationDescription:
            'A visualização da tartaruga desenha uma construção colorida curta, cujo caminho pode se ramificar ou formar um polígono conforme a escolha determinada pela semente.',
      ),
    ),
  ]);

  static List<String> get ids =>
      List<String>.unmodifiable(_entries.map((entry) => entry.id));

  static LSystemExampleContentCopy resolve({
    required String id,
    required String languageCode,
  }) {
    final entry = _entries.firstWhere(
      (candidate) => candidate.id == id,
      orElse: () => throw StateError('l-system-example.copy-id'),
    );
    return languageCode.toLowerCase().startsWith('pt') ? entry.pt : entry.en;
  }
}

final class _LSystemExampleContentEntry {
  const _LSystemExampleContentEntry({
    required this.id,
    required this.en,
    required this.pt,
  });

  final String id;
  final LSystemExampleContentCopy en;
  final LSystemExampleContentCopy pt;
}

_LSystemExampleContentEntry _entry({
  required String id,
  required LSystemExampleContentCopy en,
  required LSystemExampleContentCopy pt,
}) => _LSystemExampleContentEntry(id: id, en: en, pt: pt);
