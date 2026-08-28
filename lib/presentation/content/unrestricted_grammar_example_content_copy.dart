final class UnrestrictedGrammarExampleContentCopy {
  const UnrestrictedGrammarExampleContentCopy({
    required this.title,
    required this.summary,
    required this.learningObjective,
    required this.limitation,
    required this.accessibleDescription,
  });

  final String title;
  final String summary;
  final String learningObjective;
  final String limitation;
  final String accessibleDescription;

  String get semanticLabel => [
    title,
    summary,
    learningObjective,
    limitation,
    accessibleDescription,
  ].join(' ');
}

abstract final class UnrestrictedGrammarExampleContentCopies {
  static final _entries = List<_UnrestrictedGrammarExampleContentEntry>.unmodifiable([
    _entry(
      id: 'an-bn-cn',
      en: const UnrestrictedGrammarExampleContentCopy(
        title: 'a^n b^n c^n',
        summary:
            'A noncontracting grammar builds equal-sized blocks of a, b, and c.',
        learningObjective:
            'Trace how the B and C markers change order before each marker becomes a terminal.',
        limitation:
            'The preset illustrates one context-sensitive construction for n greater than or equal to 1.',
        accessibleDescription:
            'The productions first add a with paired B and C markers, swap every C B pair to B C, and then replace the markers with b and c.',
      ),
      pt: const UnrestrictedGrammarExampleContentCopy(
        title: 'a^n b^n c^n',
        summary:
            'Uma gramática não contrativa constrói blocos de a, b e c com o mesmo tamanho.',
        learningObjective:
            'Acompanhe como os marcadores B e C mudam de ordem antes que cada marcador se torne um terminal.',
        limitation:
            'O exemplo ilustra uma construção sensível ao contexto para n maior ou igual a 1.',
        accessibleDescription:
            'As produções primeiro acrescentam a com marcadores B e C emparelhados, trocam cada par C B por B C e depois substituem os marcadores por b e c.',
      ),
    ),
    _entry(
      id: 'context-copying',
      en: const UnrestrictedGrammarExampleContentCopy(
        title: 'Context copying with a marker',
        summary:
            'A multi-symbol left side moves a marker through terminal context before removing it.',
        learningObjective:
            'Follow a rewrite whose applicability depends on the marker and its neighboring terminal.',
        limitation:
            'The preset demonstrates one short marker derivation, not a general copying-language construction.',
        accessibleDescription:
            'S becomes a M b, the M b pair becomes b M, and the final b M pair becomes b b.',
      ),
      pt: const UnrestrictedGrammarExampleContentCopy(
        title: 'Cópia de contexto com marcador',
        summary:
            'Um lado esquerdo com vários símbolos move um marcador pelo contexto terminal antes de removê-lo.',
        learningObjective:
            'Acompanhe uma reescrita cuja aplicação depende do marcador e do terminal vizinho.',
        limitation:
            'O exemplo demonstra uma derivação curta com marcador, não uma construção geral para linguagens de cópia.',
        accessibleDescription:
            'S se torna a M b, o par M b se torna b M e o par final b M se torna b b.',
      ),
    ),
    _entry(
      id: 'tm-generated',
      en: const UnrestrictedGrammarExampleContentCopy(
        title: 'TM-generated unrestricted grammar',
        summary:
            'Composite nonterminals encode a small fragment of Turing machine state and tape context.',
        learningObjective:
            'Distinguish state-and-symbol nonterminals from the terminals produced by the simulated step.',
        limitation:
            'The preset is an illustrative conversion fragment, not a complete proof of a machine-language conversion.',
        accessibleDescription:
            'S becomes the composite symbol q0 with a, that symbol emits a and q1 with a, and the last context pair produces a check mark.',
      ),
      pt: const UnrestrictedGrammarExampleContentCopy(
        title: 'Gramática irrestrita gerada por MT',
        summary:
            'Não terminais compostos codificam um pequeno fragmento do estado e do contexto de fita de uma máquina de Turing.',
        learningObjective:
            'Diferencie não terminais de estado e símbolo dos terminais produzidos pelo passo simulado.',
        limitation:
            'O exemplo é um fragmento ilustrativo de conversão, não uma prova completa da conversão da linguagem de uma máquina.',
        accessibleDescription:
            'S se torna o símbolo composto q0 com a, esse símbolo produz a e q1 com a, e o último par de contexto produz uma marca de confirmação.',
      ),
    ),
  ]);

  static List<String> get ids =>
      List<String>.unmodifiable(_entries.map((entry) => entry.id));

  static UnrestrictedGrammarExampleContentCopy resolve({
    required String id,
    required String languageCode,
  }) {
    final entry = _entries.firstWhere(
      (candidate) => candidate.id == id,
      orElse: () => throw StateError('unrestricted-grammar-example.copy-id'),
    );
    return languageCode.toLowerCase().startsWith('pt') ? entry.pt : entry.en;
  }
}

final class _UnrestrictedGrammarExampleContentEntry {
  const _UnrestrictedGrammarExampleContentEntry({
    required this.id,
    required this.en,
    required this.pt,
  });

  final String id;
  final UnrestrictedGrammarExampleContentCopy en;
  final UnrestrictedGrammarExampleContentCopy pt;
}

_UnrestrictedGrammarExampleContentEntry _entry({
  required String id,
  required UnrestrictedGrammarExampleContentCopy en,
  required UnrestrictedGrammarExampleContentCopy pt,
}) => _UnrestrictedGrammarExampleContentEntry(id: id, en: en, pt: pt);
