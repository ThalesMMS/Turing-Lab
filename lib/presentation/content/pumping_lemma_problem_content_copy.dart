final class PumpingLemmaProblemContentCopy {
  const PumpingLemmaProblemContentCopy({
    required this.title,
    required this.learningObjective,
    required this.explanation,
    required this.hint,
  });

  final String title;
  final String learningObjective;
  final String explanation;
  final String hint;

  String get semanticLabel => '$title. $learningObjective';
}

abstract final class PumpingLemmaProblemContentCopies {
  static const _hintEn =
      'Track the theorem quantifiers before testing a pump exponent.';
  static const _hintPt =
      'Acompanhe os quantificadores do teorema antes de testar um expoente de bombeamento.';

  static final _entries = List<_PumpingLemmaProblemContentEntry>.unmodifiable([
    _entry(
      id: 'regular.equal-blocks',
      en: const PumpingLemmaProblemContentCopy(
        title: 'Equal a and b blocks',
        learningObjective:
            'Choose a witness that forces an early pump to change only one block.',
        explanation:
            'Pumping a nonempty part of the first block breaks equal counts.',
        hint: _hintEn,
      ),
      pt: const PumpingLemmaProblemContentCopy(
        title: 'Blocos iguais de a e b',
        learningObjective:
            'Escolha uma testemunha que force um bombeamento inicial a alterar apenas um bloco.',
        explanation:
            'Bombear uma parte não vazia do primeiro bloco quebra a igualdade das contagens.',
        hint: _hintPt,
      ),
    ),
    _entry(
      id: 'regular.equal-counts',
      en: const PumpingLemmaProblemContentCopy(
        title: 'Equal symbol counts',
        learningObjective:
            'Separate an unordered counting condition from the easier ordered-block proof.',
        explanation:
            'A witness strategy must handle every valid early decomposition.',
        hint: _hintEn,
      ),
      pt: const PumpingLemmaProblemContentCopy(
        title: 'Contagens iguais de símbolos',
        learningObjective:
            'Separe uma condição de contagem sem ordem da prova mais simples com blocos ordenados.',
        explanation:
            'Uma estratégia de testemunha deve lidar com toda decomposição inicial válida.',
        hint: _hintPt,
      ),
    ),
    _entry(
      id: 'regular.unary-squares',
      en: const PumpingLemmaProblemContentCopy(
        title: 'Unary square lengths',
        learningObjective:
            'Use gaps between square lengths to select a damaging pump exponent.',
        explanation:
            'Pumping changes the length by a fixed amount and can leave the squares.',
        hint: _hintEn,
      ),
      pt: const PumpingLemmaProblemContentCopy(
        title: 'Comprimentos quadrados unários',
        learningObjective:
            'Use as lacunas entre comprimentos quadrados para escolher um expoente de bombeamento que produza contradição.',
        explanation:
            'O bombeamento altera o comprimento por uma quantidade fixa e pode sair do conjunto dos quadrados.',
        hint: _hintPt,
      ),
    ),
    _entry(
      id: 'regular.even-a',
      en: const PumpingLemmaProblemContentCopy(
        title: 'Even unary length',
        learningObjective:
            'Recognize a regular control language where a valid decomposition can keep every pump even.',
        explanation:
            'This language is regular. Failure to find a contradiction is not a proof of regularity.',
        hint: _hintEn,
      ),
      pt: const PumpingLemmaProblemContentCopy(
        title: 'Comprimento unário par',
        learningObjective:
            'Reconheça uma linguagem regular de controle na qual uma decomposição válida pode manter todo bombeamento par.',
        explanation:
            'Esta linguagem é regular. Não encontrar uma contradição não é uma prova de regularidade.',
        hint: _hintPt,
      ),
    ),
    _entry(
      id: 'regular.unary-primes',
      en: const PumpingLemmaProblemContentCopy(
        title: 'Prime unary lengths',
        learningObjective:
            'Turn the pumped length into a composite multiple of the repeated segment.',
        explanation:
            'A suitable pump exponent makes the new unary length composite.',
        hint: _hintEn,
      ),
      pt: const PumpingLemmaProblemContentCopy(
        title: 'Comprimentos primos unários',
        learningObjective:
            'Transforme o comprimento bombeado em um múltiplo composto do segmento repetido.',
        explanation:
            'Um expoente de bombeamento adequado torna composto o novo comprimento unário.',
        hint: _hintPt,
      ),
    ),
    _entry(
      id: 'regular.binary-palindromes',
      en: const PumpingLemmaProblemContentCopy(
        title: 'Binary palindromes',
        learningObjective:
            'Place the pump before the mirrored suffix and track the broken symmetry.',
        explanation:
            'Changing an early segment without changing its mirror can destroy the palindrome.',
        hint: _hintEn,
      ),
      pt: const PumpingLemmaProblemContentCopy(
        title: 'Palíndromos binários',
        learningObjective:
            'Coloque o bombeamento antes do sufixo espelhado e acompanhe a quebra da simetria.',
        explanation:
            'Alterar um segmento inicial sem alterar seu espelho pode destruir o palíndromo.',
        hint: _hintPt,
      ),
    ),
    _entry(
      id: 'regular.duplicated-word',
      en: const PumpingLemmaProblemContentCopy(
        title: 'Duplicated binary word',
        learningObjective:
            'Show that pumping one copy cannot make the second copy change with it.',
        explanation:
            'The pump window can alter one half while the other half stays fixed.',
        hint: _hintEn,
      ),
      pt: const PumpingLemmaProblemContentCopy(
        title: 'Palavra binária duplicada',
        learningObjective:
            'Mostre que bombear uma cópia não pode fazer a segunda cópia mudar junto.',
        explanation:
            'A janela de bombeamento pode alterar uma metade enquanto a outra permanece fixa.',
        hint: _hintPt,
      ),
    ),
    _entry(
      id: 'regular.double-second-block',
      en: const PumpingLemmaProblemContentCopy(
        title: 'Twice as many b symbols',
        learningObjective:
            'Track a fixed ratio between ordered blocks after an adversarial early split.',
        explanation:
            'Pumping inside the a block changes n without adding the required pair of b symbols.',
        hint: _hintEn,
      ),
      pt: const PumpingLemmaProblemContentCopy(
        title: 'O dobro de símbolos b',
        learningObjective:
            'Acompanhe uma proporção fixa entre blocos ordenados após uma divisão inicial adversária.',
        explanation:
            'Bombear dentro do bloco de a altera n sem adicionar o par necessário de símbolos b.',
        hint: _hintPt,
      ),
    ),
    _entry(
      id: 'regular.more-a-than-b',
      en: const PumpingLemmaProblemContentCopy(
        title: 'More a symbols than b symbols',
        learningObjective:
            'Reason about a global count inequality without assuming the symbols form blocks.',
        explanation:
            'Pumping down a forced a segment can erase the strict count advantage.',
        hint: _hintEn,
      ),
      pt: const PumpingLemmaProblemContentCopy(
        title: 'Mais símbolos a que símbolos b',
        learningObjective:
            'Raciocine sobre uma desigualdade global de contagens sem supor que os símbolos formem blocos.',
        explanation:
            'Bombear para baixo um segmento forçado de a pode eliminar a vantagem estrita da contagem.',
        hint: _hintPt,
      ),
    ),
    _entry(
      id: 'regular.contains-ab',
      en: const PumpingLemmaProblemContentCopy(
        title: 'Contains ab',
        learningObjective:
            'Identify a local substring condition that a finite automaton can preserve.',
        explanation:
            'A decomposition can leave one occurrence of ab untouched for every exponent.',
        hint: _hintEn,
      ),
      pt: const PumpingLemmaProblemContentCopy(
        title: 'Contém ab',
        learningObjective:
            'Identifique uma condição local de subpalavra que um autômato finito pode preservar.',
        explanation:
            'Uma decomposição pode deixar uma ocorrência de ab intacta para todo expoente.',
        hint: _hintPt,
      ),
    ),
    _entry(
      id: 'regular.ends-with-a',
      en: const PumpingLemmaProblemContentCopy(
        title: 'Ends with a',
        learningObjective:
            'Distinguish a finite suffix property from an unbounded matching condition.',
        explanation: 'Pumping a prefix does not need to change the final a.',
        hint: _hintEn,
      ),
      pt: const PumpingLemmaProblemContentCopy(
        title: 'Termina com a',
        learningObjective:
            'Diferencie uma propriedade finita de sufixo de uma condição ilimitada de correspondência.',
        explanation: 'Bombear um prefixo não precisa alterar o a final.',
        hint: _hintPt,
      ),
    ),
    _entry(
      id: 'regular.alternating-ab',
      en: const PumpingLemmaProblemContentCopy(
        title: 'Alternating ab pairs',
        learningObjective:
            'Find a decomposition aligned to a repeated finite pattern.',
        explanation:
            'Choosing a complete ab pair as the pumped segment preserves the language.',
        hint: _hintEn,
      ),
      pt: const PumpingLemmaProblemContentCopy(
        title: 'Pares ab alternados',
        learningObjective:
            'Encontre uma decomposição alinhada a um padrão finito repetido.',
        explanation:
            'Escolher um par ab completo como segmento bombeado preserva a linguagem.',
        hint: _hintPt,
      ),
    ),
    _entry(
      id: 'regular.at-most-two-a',
      en: const PumpingLemmaProblemContentCopy(
        title: 'At most two a symbols',
        learningObjective:
            'Use a bounded-count control language to test the limits of contradiction searches.',
        explanation:
            'A valid split can pump only b symbols, keeping the number of a symbols bounded.',
        hint: _hintEn,
      ),
      pt: const PumpingLemmaProblemContentCopy(
        title: 'No máximo dois símbolos a',
        learningObjective:
            'Use uma linguagem de controle com contagem limitada para testar os limites das buscas por contradição.',
        explanation:
            'Uma divisão válida pode bombear apenas símbolos b, mantendo limitada a quantidade de símbolos a.',
        hint: _hintPt,
      ),
    ),
    _entry(
      id: 'cfl.equal-three-blocks',
      en: const PumpingLemmaProblemContentCopy(
        title: 'Equal a, b, and c blocks',
        learningObjective:
            'Choose a witness whose short pump window cannot update all three blocks.',
        explanation:
            'The bounded vxy window cannot cover all three block boundaries.',
        hint: _hintEn,
      ),
      pt: const PumpingLemmaProblemContentCopy(
        title: 'Blocos iguais de a, b e c',
        learningObjective:
            'Escolha uma testemunha cuja janela curta de bombeamento não possa atualizar os três blocos.',
        explanation:
            'A janela limitada vxy não pode cobrir as três fronteiras entre blocos.',
        hint: _hintPt,
      ),
    ),
    _entry(
      id: 'cfl.copy-language',
      en: const PumpingLemmaProblemContentCopy(
        title: 'Copy language',
        learningObjective:
            'Handle two independently pumped segments without losing the exact copy relation.',
        explanation:
            'Simultaneous pumping must preserve two identical halves to remain in the language.',
        hint: _hintEn,
      ),
      pt: const PumpingLemmaProblemContentCopy(
        title: 'Linguagem de cópia',
        learningObjective:
            'Trate dois segmentos bombeados independentemente sem perder a relação de cópia exata.',
        explanation:
            'O bombeamento simultâneo deve preservar duas metades idênticas para permanecer na linguagem.',
        hint: _hintPt,
      ),
    ),
    _entry(
      id: 'cfl.equal-multiple-blocks',
      en: const PumpingLemmaProblemContentCopy(
        title: 'Equal multiple blocks',
        learningObjective:
            'Track four synchronized blocks against one bounded decomposition window.',
        explanation:
            'A short pumping window cannot adjust all four blocks together.',
        hint: _hintEn,
      ),
      pt: const PumpingLemmaProblemContentCopy(
        title: 'Vários blocos iguais',
        learningObjective:
            'Acompanhe quatro blocos sincronizados diante de uma única janela limitada de decomposição.',
        explanation:
            'Uma janela curta de bombeamento não pode ajustar os quatro blocos juntos.',
        hint: _hintPt,
      ),
    ),
    _entry(
      id: 'cfl.equal-two-blocks',
      en: const PumpingLemmaProblemContentCopy(
        title: 'Context-free counterexample',
        learningObjective:
            'Recognize a context-free control language that this lemma should not disprove.',
        explanation:
            'This language is context-free, so this lemma cannot prove that it is not context-free.',
        hint: _hintEn,
      ),
      pt: const PumpingLemmaProblemContentCopy(
        title: 'Contraexemplo livre de contexto',
        learningObjective:
            'Reconheça uma linguagem livre de contexto de controle que este lema não deve refutar.',
        explanation:
            'Esta linguagem é livre de contexto, portanto este lema não pode provar que ela não é livre de contexto.',
        hint: _hintPt,
      ),
    ),
    _entry(
      id: 'cfl.marked-mirror',
      en: const PumpingLemmaProblemContentCopy(
        title: 'Marked mirror',
        learningObjective:
            'Use the marker to pair each symbol with its mirror through a stack discipline.',
        explanation:
            'This language is context-free; the marker lets a pushdown automaton switch from pushing to matching.',
        hint: _hintEn,
      ),
      pt: const PumpingLemmaProblemContentCopy(
        title: 'Espelho marcado',
        learningObjective:
            'Use o marcador para emparelhar cada símbolo com seu espelho por meio de uma disciplina de pilha.',
        explanation:
            'Esta linguagem é livre de contexto; o marcador permite que um autômato com pilha passe de empilhar para comparar.',
        hint: _hintPt,
      ),
    ),
    _entry(
      id: 'cfl.balanced-parentheses',
      en: const PumpingLemmaProblemContentCopy(
        title: 'Balanced parentheses',
        learningObjective:
            'Recognize nested stack structure and avoid treating every failed pump as a proof.',
        explanation:
            'Balanced parentheses form a context-free language with decompositions that pump matched structure.',
        hint: _hintEn,
      ),
      pt: const PumpingLemmaProblemContentCopy(
        title: 'Parênteses balanceados',
        learningObjective:
            'Reconheça a estrutura aninhada de pilha e evite tratar todo bombeamento malsucedido como prova.',
        explanation:
            'Parênteses balanceados formam uma linguagem livre de contexto com decomposições que bombeiam estruturas correspondentes.',
        hint: _hintPt,
      ),
    ),
    _entry(
      id: 'cfl.equal-ab-with-tail',
      en: const PumpingLemmaProblemContentCopy(
        title: 'Equal a and b blocks with a c tail',
        learningObjective:
            'Separate one stack-matched dependency from an independent trailing block.',
        explanation:
            'A pushdown automaton can match a and b counts, then consume any number of c symbols.',
        hint: _hintEn,
      ),
      pt: const PumpingLemmaProblemContentCopy(
        title: 'Blocos iguais de a e b com uma cauda de c',
        learningObjective:
            'Separe uma dependência correspondida por pilha de um bloco final independente.',
        explanation:
            'Um autômato com pilha pode comparar as contagens de a e b e depois consumir qualquer quantidade de símbolos c.',
        hint: _hintPt,
      ),
    ),
    _entry(
      id: 'cfl.head-with-equal-bc',
      en: const PumpingLemmaProblemContentCopy(
        title: 'Free a prefix with equal b and c blocks',
        learningObjective:
            'Locate the single count dependency after an unconstrained prefix.',
        explanation:
            'The a prefix is independent; one stack is enough to match the b and c blocks.',
        hint: _hintEn,
      ),
      pt: const PumpingLemmaProblemContentCopy(
        title: 'Prefixo livre de a com blocos iguais de b e c',
        learningObjective:
            'Localize a única dependência de contagem após um prefixo sem restrição.',
        explanation:
            'O prefixo de a é independente; uma pilha basta para comparar os blocos de b e c.',
        hint: _hintPt,
      ),
    ),
    _entry(
      id: 'cfl.crossed-dependencies',
      en: const PumpingLemmaProblemContentCopy(
        title: 'Crossed block dependencies',
        learningObjective:
            'Contrast nested stack matching with two dependencies that cross in input order.',
        explanation:
            'A bounded vxy window cannot keep both crossed count equalities synchronized.',
        hint: _hintEn,
      ),
      pt: const PumpingLemmaProblemContentCopy(
        title: 'Dependências cruzadas entre blocos',
        learningObjective:
            'Compare a correspondência aninhada por pilha com duas dependências que se cruzam na ordem da entrada.',
        explanation:
            'Uma janela limitada vxy não pode manter sincronizadas as duas igualdades cruzadas de contagem.',
        hint: _hintPt,
      ),
    ),
    _entry(
      id: 'cfl.marked-copy',
      en: const PumpingLemmaProblemContentCopy(
        title: 'Marked exact copy',
        learningObjective:
            'Compare exact copying with the stack-friendly marked mirror language.',
        explanation:
            'A stack reverses its input, so a marker does not make exact same-order copying context-free.',
        hint: _hintEn,
      ),
      pt: const PumpingLemmaProblemContentCopy(
        title: 'Cópia exata marcada',
        learningObjective:
            'Compare a cópia exata com a linguagem de espelho marcado adequada a pilhas.',
        explanation:
            'Uma pilha inverte sua entrada, portanto um marcador não torna livre de contexto a cópia exata na mesma ordem.',
        hint: _hintPt,
      ),
    ),
    _entry(
      id: 'cfl.unary-squares',
      en: const PumpingLemmaProblemContentCopy(
        title: 'Unary square lengths',
        learningObjective:
            'Use the fact that every unary context-free language must be regular.',
        explanation:
            'Square-length gaps grow, so a fixed pump cannot stay on square lengths for every exponent.',
        hint: _hintEn,
      ),
      pt: const PumpingLemmaProblemContentCopy(
        title: 'Comprimentos quadrados unários',
        learningObjective:
            'Use o fato de que toda linguagem livre de contexto unária deve ser regular.',
        explanation:
            'As lacunas entre comprimentos quadrados crescem, portanto um bombeamento fixo não pode permanecer nos quadrados para todo expoente.',
        hint: _hintPt,
      ),
    ),
    _entry(
      id: 'cfl.unary-powers-of-two',
      en: const PumpingLemmaProblemContentCopy(
        title: 'Unary powers of two',
        learningObjective:
            'Choose an exponent that lands between consecutive powers of two.',
        explanation:
            'The distance between accepted unary lengths eventually exceeds any fixed pumped segment.',
        hint: _hintEn,
      ),
      pt: const PumpingLemmaProblemContentCopy(
        title: 'Potências de dois unárias',
        learningObjective:
            'Escolha um expoente que fique entre potências consecutivas de dois.',
        explanation:
            'A distância entre comprimentos unários aceitos acaba excedendo qualquer segmento bombeado fixo.',
        hint: _hintPt,
      ),
    ),
    _entry(
      id: 'cfl.equal-ab-or-bc',
      en: const PumpingLemmaProblemContentCopy(
        title: 'Either adjacent block pair is equal',
        learningObjective:
            'Use closure under union without assuming both count equalities must hold.',
        explanation:
            'The language is a union of two context-free block languages, one matching a with b and one matching b with c.',
        hint: _hintEn,
      ),
      pt: const PumpingLemmaProblemContentCopy(
        title: 'Um dos pares de blocos adjacentes é igual',
        learningObjective:
            'Use o fechamento por união sem supor que as duas igualdades de contagem devam valer.',
        explanation:
            'A linguagem é a união de duas linguagens de blocos livres de contexto: uma compara a com b e a outra compara b com c.',
        hint: _hintPt,
      ),
    ),
  ]);

  static List<String> get ids =>
      List<String>.unmodifiable(_entries.map((entry) => entry.id));

  static PumpingLemmaProblemContentCopy resolve({
    required String id,
    required String languageCode,
    String? fallbackTitle,
  }) {
    final entry = _entries.where((candidate) => candidate.id == id).firstOrNull;
    if (entry == null) {
      final portuguese = languageCode.toLowerCase().startsWith('pt');
      return PumpingLemmaProblemContentCopy(
        title: fallbackTitle ?? id,
        learningObjective: portuguese
            ? 'Reconstrua o desafio importado e justifique cada escolha do teorema.'
            : 'Reconstruct the imported challenge and justify each theorem choice.',
        hint: portuguese
            ? 'Problema JFLAP importado. A pertinência exige raciocínio do usuário.'
            : 'Imported JFLAP problem. Membership requires user reasoning.',
        explanation: portuguese
            ? 'O JFLAP não codifica um predicado portátil de pertinência à linguagem.'
            : 'JFLAP does not encode a portable language membership predicate.',
      );
    }
    return languageCode.toLowerCase().startsWith('pt') ? entry.pt : entry.en;
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

final class _PumpingLemmaProblemContentEntry {
  const _PumpingLemmaProblemContentEntry({
    required this.id,
    required this.en,
    required this.pt,
  });

  final String id;
  final PumpingLemmaProblemContentCopy en;
  final PumpingLemmaProblemContentCopy pt;
}

_PumpingLemmaProblemContentEntry _entry({
  required String id,
  required PumpingLemmaProblemContentCopy en,
  required PumpingLemmaProblemContentCopy pt,
}) => _PumpingLemmaProblemContentEntry(id: id, en: en, pt: pt);
