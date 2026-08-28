final class AssetExampleContentCopy {
  const AssetExampleContentCopy({
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

abstract final class AssetExampleContentCopies {
  static final _entries = List<_AssetExampleContentEntry>.unmodifiable([
    _entry(
      id: 'asset/afd_binary_divisible_by_3',
      en: const AssetExampleContentCopy(
        title: 'Binary numbers divisible by 3',
        summary:
            'A three-state DFA tracks the remainder modulo 3 while reading a binary word.',
        learningObjective:
            'Relate each transition on 0 or 1 to the updated remainder of the binary value.',
        limitation:
            'The word represents an unsigned binary number. Symbols outside 0 and 1 are not in this automaton alphabet.',
        accessibleDescription:
            'States q0, q1, and q2 represent remainders 0, 1, and 2. State q0 is initial and accepting; each transition moves to the state for the new remainder.',
      ),
      pt: const AssetExampleContentCopy(
        title: 'Números binários divisíveis por 3',
        summary:
            'Um AFD de três estados acompanha o resto módulo 3 durante a leitura de uma palavra binária.',
        learningObjective:
            'Relacione cada transição em 0 ou 1 ao novo resto do valor binário.',
        limitation:
            'A palavra representa um número binário sem sinal. Símbolos diferentes de 0 e 1 não pertencem ao alfabeto deste autômato.',
        accessibleDescription:
            'Os estados q0, q1 e q2 representam os restos 0, 1 e 2. O estado q0 é inicial e final; cada transição leva ao estado do novo resto.',
      ),
    ),
    _entry(
      id: 'asset/afd_contains_ab',
      en: const AssetExampleContentCopy(
        title: 'Words containing ab',
        summary:
            'A three-state DFA remembers progress toward the substring ab and accepts after finding it.',
        learningObjective:
            'Follow how the machine retains a useful trailing a until the next b completes the match.',
        limitation:
            'The alphabet contains only lowercase a and b, and the accepting state does not record later symbols.',
        accessibleDescription:
            'State q0 waits for a, q1 records a possible start of ab, and accepting state q2 loops on both symbols after ab has appeared.',
      ),
      pt: const AssetExampleContentCopy(
        title: 'Palavras que contêm ab',
        summary:
            'Um AFD de três estados memoriza o progresso até a subpalavra ab e aceita depois de encontrá-la.',
        learningObjective:
            'Acompanhe como a máquina preserva um a final útil até que o próximo b complete a correspondência.',
        limitation:
            'O alfabeto contém apenas a e b minúsculos, e o estado final não registra os símbolos posteriores.',
        accessibleDescription:
            'O estado q0 espera por a, q1 registra um possível início de ab, e o estado final q2 repete em ambos os símbolos depois que ab aparece.',
      ),
    ),
    _entry(
      id: 'asset/afd_ends_with_a',
      en: const AssetExampleContentCopy(
        title: 'Words ending in a',
        summary:
            'A two-state DFA records whether the most recently read symbol is a.',
        learningObjective:
            'See how one bit of state is enough to recognize a suffix of length one.',
        limitation:
            'The automaton uses only lowercase a and b and checks the final symbol, not whether a appears elsewhere.',
        accessibleDescription:
            'Initial state q0 means the word does not currently end in a. Accepting state q1 means it does; reading b returns to q0.',
      ),
      pt: const AssetExampleContentCopy(
        title: 'Palavras que terminam em a',
        summary:
            'Um AFD de dois estados registra se o símbolo lido mais recentemente é a.',
        learningObjective:
            'Observe como um único bit de estado basta para reconhecer um sufixo de comprimento um.',
        limitation:
            'O autômato usa apenas a e b minúsculos e verifica o símbolo final, não a presença de a em outra posição.',
        accessibleDescription:
            'O estado inicial q0 indica que a palavra ainda não termina em a. O estado final q1 indica que termina; a leitura de b retorna a q0.',
      ),
    ),
    _entry(
      id: 'asset/afd_parity_ab',
      en: const AssetExampleContentCopy(
        title: 'Even counts of a and b',
        summary:
            'A four-state DFA tracks the parity of the counts of a and b independently.',
        learningObjective:
            'Map each state to one even-or-odd pair and observe how a symbol flips one component.',
        limitation:
            'The machine records parity only. It cannot recover the exact number or order of symbols.',
        accessibleDescription:
            'Four states form a square of parity combinations. Initial accepting state q0 represents even a and even b; each a or b transition flips its matching parity.',
      ),
      pt: const AssetExampleContentCopy(
        title: 'Quantidades pares de a e b',
        summary:
            'Um AFD de quatro estados acompanha separadamente a paridade das quantidades de a e b.',
        learningObjective:
            'Associe cada estado a um par de valores par ou ímpar e observe como cada símbolo inverte um componente.',
        limitation:
            'A máquina registra apenas a paridade. Ela não recupera a quantidade exata nem a ordem dos símbolos.',
        accessibleDescription:
            'Quatro estados formam as combinações de paridade. O estado inicial e final q0 representa quantidades pares de a e b; cada transição inverte a paridade do símbolo lido.',
      ),
    ),
    _entry(
      id: 'asset/afn_lambda_a_or_ab',
      en: const AssetExampleContentCopy(
        title: 'Lambda NFA for a or ab',
        summary:
            'A lambda branch lets an NFA accept either the one-symbol word a or the two-symbol word ab.',
        learningObjective:
            'Compare direct acceptance with a lambda path that consumes a and then b.',
        limitation:
            'This finite example accepts exactly a and ab; it does not repeat either branch.',
        accessibleDescription:
            'From q0, reading a reaches accepting q1. A lambda transition instead reaches q2, then a leads to q3 and b leads to accepting q4.',
      ),
      pt: const AssetExampleContentCopy(
        title: 'AFN com lambda para a ou ab',
        summary:
            'Uma ramificação lambda permite que um AFN aceite a palavra a ou a palavra ab.',
        learningObjective:
            'Compare a aceitação direta com um caminho lambda que consome a e depois b.',
        limitation:
            'Este exemplo finito aceita exatamente a e ab; nenhuma das ramificações se repete.',
        accessibleDescription:
            'A partir de q0, a leitura de a chega ao estado final q1. Uma transição lambda leva a q2; depois, a leva a q3 e b leva ao estado final q4.',
      ),
    ),
    _entry(
      id: 'asset/apda_anb2n',
      en: const AssetExampleContentCopy(
        title: 'PDA for a^n b^2n',
        summary:
            'This PDA pushes two A symbols for each a, then pops one A for each b.',
        learningObjective:
            'Relate stack growth to the two-to-one count between the ordered a and b blocks.',
        limitation:
            'The machine requires every a before every b. It accepts the empty word when n is zero.',
        accessibleDescription:
            'State q0 pushes two A symbols per a. The first b moves to q1, where each b pops one A; q2 is reached when only the bottom marker Z remains.',
      ),
      pt: const AssetExampleContentCopy(
        title: 'APD para a^n b^2n',
        summary:
            'Este APD empilha dois símbolos A para cada a e depois desempilha um A para cada b.',
        learningObjective:
            'Relacione o crescimento da pilha à proporção de dois para um entre os blocos ordenados de a e b.',
        limitation:
            'A máquina exige todos os símbolos a antes de todos os b. Ela aceita a palavra vazia quando n é zero.',
        accessibleDescription:
            'O estado q0 empilha dois símbolos A por a. O primeiro b leva a q1, onde cada b desempilha um A; q2 é alcançado quando resta apenas o marcador de fundo Z.',
      ),
    ),
    _entry(
      id: 'asset/apda_anbn',
      en: const AssetExampleContentCopy(
        title: 'PDA for equal a and b blocks',
        summary:
            'This PDA pushes one stack symbol for each a and pops one for each following b.',
        learningObjective:
            'Use the stack as an unbounded counter that matches two ordered blocks symbol by symbol.',
        limitation:
            'This example accepts a^n b^n only for positive n; unlike the usual n greater than or equal to zero definition, it has no empty-word path.',
        accessibleDescription:
            'State q0 pushes an a marker while reading a symbols. Reading the first b enters q1, each b removes one marker, and an empty move over Z reaches final state q2.',
      ),
      pt: const AssetExampleContentCopy(
        title: 'APD para blocos iguais de a e b',
        summary:
            'Este APD empilha um símbolo para cada a e desempilha um para cada b posterior.',
        learningObjective:
            'Use a pilha como contador sem limite que compara dois blocos ordenados símbolo a símbolo.',
        limitation:
            'Este exemplo aceita a^n b^n apenas para n positivo; ao contrário da definição usual com n maior ou igual a zero, ele não tem caminho para a palavra vazia.',
        accessibleDescription:
            'O estado q0 empilha um marcador a durante a leitura dos símbolos a. O primeiro b leva a q1, cada b remove um marcador, e um movimento vazio sobre Z chega ao estado final q2.',
      ),
    ),
    _entry(
      id: 'asset/apda_balanced_parentheses',
      en: const AssetExampleContentCopy(
        title: 'PDA for balanced parentheses',
        summary:
            'The stack records every unmatched opening parenthesis and removes one for each closing parenthesis.',
        learningObjective:
            'Connect nested structure with last-in, first-out stack behavior.',
        limitation:
            'The alphabet contains only parentheses. The empty word is accepted as a balanced sequence.',
        accessibleDescription:
            'State q0 pushes an opening parenthesis for each left parenthesis and pops one for each right parenthesis. An empty move to final state q1 is available only over bottom marker Z.',
      ),
      pt: const AssetExampleContentCopy(
        title: 'APD para parênteses balanceados',
        summary:
            'A pilha registra cada parêntese de abertura sem par e remove um para cada parêntese de fechamento.',
        learningObjective:
            'Relacione a estrutura aninhada ao comportamento de último a entrar e primeiro a sair da pilha.',
        limitation:
            'O alfabeto contém apenas parênteses. A palavra vazia é aceita como sequência balanceada.',
        accessibleDescription:
            'O estado q0 empilha um marcador para cada parêntese de abertura e desempilha um para cada fechamento. Um movimento vazio até o estado final q1 só está disponível sobre o marcador de fundo Z.',
      ),
    ),
    _entry(
      id: 'asset/apda_mirrored_separator',
      en: const AssetExampleContentCopy(
        title: 'PDA for w#reverse(w)',
        summary:
            'The machine stores the symbols before # and matches them in reverse order after the separator.',
        learningObjective:
            'See how a visible midpoint removes the need to guess where stack comparison should begin.',
        limitation:
            'Exactly one # separates the halves. The word # is accepted when w is empty.',
        accessibleDescription:
            'State q0 pushes each a or b. Reading # enters q1 without changing the stack; q1 pops only a matching a or b, then an empty move over Z reaches final state q2.',
      ),
      pt: const AssetExampleContentCopy(
        title: 'APD para w#reverse(w)',
        summary:
            'A máquina armazena os símbolos anteriores a # e os compara em ordem inversa depois do separador.',
        learningObjective:
            'Observe como um ponto médio visível elimina a necessidade de adivinhar onde a comparação da pilha deve começar.',
        limitation:
            'Exatamente um # separa as metades. A palavra # é aceita quando w é vazio.',
        accessibleDescription:
            'O estado q0 empilha cada a ou b. A leitura de # leva a q1 sem mudar a pilha; q1 só desempilha um a ou b correspondente, e um movimento vazio sobre Z chega ao estado final q2.',
      ),
    ),
    _entry(
      id: 'asset/apda_palindrome',
      en: const AssetExampleContentCopy(
        title: 'Nondeterministic PDA for palindromes',
        summary:
            'This PDA stores a possible first half, guesses the midpoint, and matches the remaining symbols in reverse.',
        learningObjective:
            'Compare empty midpoint moves for even lengths with consumed midpoint symbols for odd lengths.',
        limitation:
            'The midpoint is chosen nondeterministically, so some branches may fail even when another branch accepts.',
        accessibleDescription:
            'State q0 pushes a and b symbols and can move to q1 either without input or while consuming one midpoint symbol. State q1 pops matching symbols, then q2 accepts over bottom marker Z.',
      ),
      pt: const AssetExampleContentCopy(
        title: 'APD não determinístico para palíndromos',
        summary:
            'Este APD armazena uma possível primeira metade, escolhe o ponto médio e compara os símbolos restantes em ordem inversa.',
        learningObjective:
            'Compare movimentos vazios no centro de comprimentos pares com o consumo do símbolo central em comprimentos ímpares.',
        limitation:
            'O ponto médio é escolhido de forma não determinística; algumas ramificações podem falhar mesmo quando outra aceita.',
        accessibleDescription:
            'O estado q0 empilha símbolos a e b e pode ir para q1 sem entrada ou consumindo um símbolo central. O estado q1 desempilha símbolos correspondentes, e q2 aceita sobre o marcador de fundo Z.',
      ),
    ),
    _entry(
      id: 'asset/glc_anbn',
      en: const AssetExampleContentCopy(
        title: 'Grammar for equal a and b blocks',
        summary:
            'The production S to aSb adds one a at the start and one b at the end; S to epsilon stops the derivation.',
        learningObjective:
            'Follow how recursive wrapping keeps both block lengths equal while preserving their order.',
        limitation:
            'The grammar generates only a^n b^n, including the empty word. It does not generate interleaved a and b symbols.',
        accessibleDescription:
            'There is one variable, S. Its productions are S to a S b and S to epsilon, so every recursive step surrounds the remaining S with a matching a and b.',
      ),
      pt: const AssetExampleContentCopy(
        title: 'Gramática para blocos iguais de a e b',
        summary:
            'A produção S para aSb acrescenta um a no início e um b no fim; S para épsilon encerra a derivação.',
        learningObjective:
            'Acompanhe como o envolvimento recursivo mantém iguais os comprimentos dos dois blocos e preserva sua ordem.',
        limitation:
            'A gramática gera apenas a^n b^n, incluindo a palavra vazia. Ela não gera símbolos a e b intercalados.',
        accessibleDescription:
            'Há uma variável, S. Suas produções são S para a S b e S para épsilon; assim, cada passo recursivo envolve o S restante com um a e um b correspondentes.',
      ),
    ),
    _entry(
      id: 'asset/glc_arithmetic_expressions',
      en: const AssetExampleContentCopy(
        title: 'Grammar for arithmetic expressions',
        summary:
            'Variables E, T, and F encode addition, multiplication, grouping, and the token id with standard precedence.',
        learningObjective:
            'Trace how separate expression, term, and factor levels make multiplication bind more tightly than addition.',
        limitation:
            'The grammar covers only id, +, *, and parentheses. Its left-recursive form is not suitable for every top-down parser without transformation.',
        accessibleDescription:
            'E expands to E plus T or T. T expands to T times F or F. F expands to a parenthesized E or id, placing multiplication below addition in the derivation tree.',
      ),
      pt: const AssetExampleContentCopy(
        title: 'Gramática para expressões aritméticas',
        summary:
            'As variáveis E, T e F representam adição, multiplicação, agrupamento e o token id com a precedência usual.',
        learningObjective:
            'Acompanhe como níveis separados de expressão, termo e fator fazem a multiplicação ter precedência sobre a adição.',
        limitation:
            'A gramática cobre apenas id, +, * e parênteses. Sua forma recursiva à esquerda não serve diretamente para todo analisador descendente.',
        accessibleDescription:
            'E deriva E mais T ou T. T deriva T vezes F ou F. F deriva E entre parênteses ou id, colocando a multiplicação abaixo da adição na árvore de derivação.',
      ),
    ),
    _entry(
      id: 'asset/glc_balanced_parentheses',
      en: const AssetExampleContentCopy(
        title: 'Grammar for balanced parentheses',
        summary:
            'The grammar builds balanced sequences by concatenating two sequences, wrapping one sequence, or using epsilon.',
        learningObjective:
            'Relate the productions S to SS and S to (S) to sequential and nested composition.',
        limitation:
            'The grammar is ambiguous because some balanced words have more than one split through S to SS.',
        accessibleDescription:
            'The single variable S has three productions: two S variables in sequence, S enclosed in parentheses, and epsilon for the empty sequence.',
      ),
      pt: const AssetExampleContentCopy(
        title: 'Gramática para parênteses balanceados',
        summary:
            'A gramática cria sequências balanceadas concatenando duas sequências, envolvendo uma sequência ou usando épsilon.',
        learningObjective:
            'Relacione as produções S para SS e S para (S) às composições sequencial e aninhada.',
        limitation:
            'A gramática é ambígua porque algumas palavras balanceadas admitem mais de uma divisão pela produção S para SS.',
        accessibleDescription:
            'A única variável S tem três produções: dois S em sequência, S entre parênteses e épsilon para a sequência vazia.',
      ),
    ),
    _entry(
      id: 'asset/glc_even_zeros',
      en: const AssetExampleContentCopy(
        title: 'Grammar for an even number of zeros',
        summary:
            'Variables S and A track whether the number of generated zeros is even or odd while ones preserve the current parity.',
        learningObjective:
            'Map each variable to a parity state and compare this right-linear grammar with a two-state automaton.',
        limitation:
            'The alphabet is binary, and only zero parity is constrained. The empty word is included.',
        accessibleDescription:
            'S represents even parity and can emit 1 while staying in S, emit 0 and move to A, or stop. A represents odd parity; 1 stays in A and 0 returns to S.',
      ),
      pt: const AssetExampleContentCopy(
        title: 'Gramática para uma quantidade par de zeros',
        summary:
            'As variáveis S e A registram se a quantidade de zeros gerados é par ou ímpar, enquanto os símbolos 1 preservam a paridade atual.',
        learningObjective:
            'Associe cada variável a um estado de paridade e compare esta gramática linear à direita com um autômato de dois estados.',
        limitation:
            'O alfabeto é binário, e apenas a paridade dos zeros é restringida. A palavra vazia está incluída.',
        accessibleDescription:
            'S representa paridade par e pode emitir 1 permanecendo em S, emitir 0 e ir para A ou encerrar. A representa paridade ímpar; 1 permanece em A e 0 retorna a S.',
      ),
    ),
    _entry(
      id: 'asset/glc_palindrome',
      en: const AssetExampleContentCopy(
        title: 'Grammar for palindromes over a and b',
        summary:
            'Recursive productions add matching symbols to both ends, with a, b, or epsilon at the center.',
        learningObjective:
            'Distinguish the base cases for odd and even lengths from the recursive symmetry step.',
        limitation:
            'The example also declares A to a and B to b, but S never references A or B; those unreachable productions are preserved from the source JSON.',
        accessibleDescription:
            'Start variable S derives a S a, b S b, a, b, or epsilon. Variables A and B have terminal productions but are unreachable from S.',
      ),
      pt: const AssetExampleContentCopy(
        title: 'Gramática para palíndromos sobre a e b',
        summary:
            'Produções recursivas acrescentam símbolos iguais às duas extremidades, com a, b ou épsilon no centro.',
        learningObjective:
            'Diferencie os casos-base de comprimentos ímpares e pares do passo recursivo de simetria.',
        limitation:
            'O exemplo também declara A para a e B para b, mas S nunca referencia A nem B; essas produções inalcançáveis são preservadas do JSON de origem.',
        accessibleDescription:
            'A variável inicial S deriva a S a, b S b, a, b ou épsilon. As variáveis A e B têm produções terminais, mas são inalcançáveis a partir de S.',
      ),
    ),
    _entry(
      id: 'asset/regex_a_star',
      en: const AssetExampleContentCopy(
        title: 'Zero or more a symbols',
        summary:
            'The expression a* accepts the empty word and every word made only of a.',
        learningObjective:
            'Connect the Kleene star with unrestricted repetition, including zero repetitions.',
        limitation:
            'The preset alphabet contains only a. Another regular-expression dialect may spell the same repetition differently.',
        accessibleDescription:
            'The expression contains the symbol a followed by a Kleene star, which allows the symbol to occur any nonnegative number of times.',
      ),
      pt: const AssetExampleContentCopy(
        title: 'Zero ou mais símbolos a',
        summary:
            'A expressão a* aceita a palavra vazia e toda palavra formada apenas por a.',
        learningObjective:
            'Relacione o fecho de Kleene à repetição sem limite, incluindo zero repetições.',
        limitation:
            'O alfabeto do exemplo contém apenas a. Outro dialeto de expressões regulares pode escrever a mesma repetição de outra forma.',
        accessibleDescription:
            'A expressão contém o símbolo a seguido por um fecho de Kleene, que permite qualquer quantidade não negativa de ocorrências.',
      ),
    ),
    _entry(
      id: 'asset/regex_a_then_b',
      en: const AssetExampleContentCopy(
        title: 'A block followed by a b block',
        summary:
            'The expression a*b* accepts any number of a symbols followed by any number of b symbols.',
        learningObjective:
            'Distinguish concatenation of two repeated blocks from arbitrary mixing of a and b.',
        limitation:
            'Once a b is read, no later a is allowed. The expression includes the empty word.',
        accessibleDescription:
            'The expression has a with a Kleene star followed by b with a Kleene star, so all a symbols precede all b symbols.',
      ),
      pt: const AssetExampleContentCopy(
        title: 'Bloco de a seguido por bloco de b',
        summary:
            'A expressão a*b* aceita qualquer quantidade de a seguida por qualquer quantidade de b.',
        learningObjective:
            'Diferencie a concatenação de dois blocos repetidos de uma mistura livre entre a e b.',
        limitation:
            'Depois da leitura de b, nenhum a pode aparecer. A expressão inclui a palavra vazia.',
        accessibleDescription:
            'A expressão tem a com fecho de Kleene seguido por b com fecho de Kleene; portanto, todos os símbolos a vêm antes dos símbolos b.',
      ),
    ),
    _entry(
      id: 'asset/regex_ab_or_ba_pairs',
      en: const AssetExampleContentCopy(
        title: 'Repeated ab or ba pairs',
        summary:
            'The expression (ab|ba)* builds words by repeating either ordered pair.',
        learningObjective:
            'Combine union, grouping, concatenation, and Kleene star in one expression.',
        limitation:
            'Every accepted nonempty word has even length and splits fully into ab or ba pairs.',
        accessibleDescription:
            'A grouped choice contains ab and ba, separated by union, and a Kleene star repeats the chosen two-symbol blocks.',
      ),
      pt: const AssetExampleContentCopy(
        title: 'Pares ab ou ba repetidos',
        summary:
            'A expressão (ab|ba)* constrói palavras repetindo qualquer um dos pares ordenados.',
        learningObjective:
            'Combine união, agrupamento, concatenação e fecho de Kleene em uma única expressão.',
        limitation:
            'Toda palavra não vazia aceita tem comprimento par e pode ser dividida inteiramente em pares ab ou ba.',
        accessibleDescription:
            'Uma escolha agrupada contém ab e ba, separados por união, e um fecho de Kleene repete os blocos escolhidos de dois símbolos.',
      ),
    ),
    _entry(
      id: 'asset/regex_binary_starts_zero',
      en: const AssetExampleContentCopy(
        title: 'Nonempty binary words starting with 0',
        summary:
            'The expression 0(0|1)* requires an initial 0 and then allows any binary suffix.',
        learningObjective:
            'Separate a required prefix from a repeated choice for the remaining positions.',
        limitation:
            'The empty word and every word starting with 1 are rejected; only symbols 0 and 1 belong to the alphabet.',
        accessibleDescription:
            'The expression begins with a required 0, followed by a grouped choice between 0 and 1 under a Kleene star.',
      ),
      pt: const AssetExampleContentCopy(
        title: 'Palavras binárias não vazias iniciadas por 0',
        summary:
            'A expressão 0(0|1)* exige um 0 inicial e depois permite qualquer sufixo binário.',
        learningObjective:
            'Separe um prefixo obrigatório de uma escolha repetida para as posições restantes.',
        limitation:
            'A palavra vazia e toda palavra iniciada por 1 são rejeitadas; apenas 0 e 1 pertencem ao alfabeto.',
        accessibleDescription:
            'A expressão começa com um 0 obrigatório, seguido por uma escolha agrupada entre 0 e 1 sob um fecho de Kleene.',
      ),
    ),
    _entry(
      id: 'asset/regex_ends_with_ab',
      en: const AssetExampleContentCopy(
        title: 'Words ending in ab',
        summary:
            'The expression (a|b)*ab accepts words over a and b whose final two symbols are ab.',
        learningObjective:
            'Identify how a free binary prefix combines with a required suffix.',
        limitation:
            'Words shorter than two symbols are rejected, and the match applies to the whole word.',
        accessibleDescription:
            'A grouped choice between a and b has a Kleene star for the prefix, followed by the required symbols a and b.',
      ),
      pt: const AssetExampleContentCopy(
        title: 'Palavras que terminam em ab',
        summary:
            'A expressão (a|b)*ab aceita palavras sobre a e b cujos dois símbolos finais são ab.',
        learningObjective:
            'Identifique como um prefixo binário livre se combina com um sufixo obrigatório.',
        limitation:
            'Palavras com menos de dois símbolos são rejeitadas, e a correspondência considera a palavra inteira.',
        accessibleDescription:
            'Uma escolha agrupada entre a e b tem fecho de Kleene para o prefixo, seguida pelos símbolos obrigatórios a e b.',
      ),
    ),
    _entry(
      id: 'asset/tm_anbn',
      en: const AssetExampleContentCopy(
        title: 'Equal blocks of a and b',
        summary:
            'This single-tape machine recognizes aⁿbⁿ by marking each a with X and its matching b with Y.',
        learningObjective:
            'Follow how repeated marking and return sweeps compare two ordered blocks without storing n in the finite control.',
        limitation:
            'The a symbols must precede all b symbols; X, Y, and B are reserved tape symbols. The empty word is accepted.',
        accessibleDescription:
            'A five-state single-tape machine repeatedly marks the leftmost unpaired a, scans right to mark one b, returns left, and accepts after only Y marks remain.',
      ),
      pt: const AssetExampleContentCopy(
        title: 'Blocos iguais de a e b',
        summary:
            'Esta máquina de uma fita reconhece aⁿbⁿ marcando cada a com X e o b correspondente com Y.',
        learningObjective:
            'Acompanhe como marcações repetidas e varreduras de retorno comparam dois blocos ordenados sem armazenar n no controle finito.',
        limitation:
            'Todos os símbolos a devem preceder os símbolos b; X, Y e B são símbolos reservados da fita. A palavra vazia é aceita.',
        accessibleDescription:
            'Uma máquina de uma fita com cinco estados marca repetidamente o a não pareado mais à esquerda, percorre a fita para marcar um b, retorna à esquerda e aceita quando restam apenas marcas Y.',
      ),
    ),
    _entry(
      id: 'asset/tm_binary_to_unary',
      en: const AssetExampleContentCopy(
        title: 'One unary mark per binary symbol',
        summary:
            'The machine replaces every input bit with X on a rightward pass, then rewrites each X as 1 while returning left.',
        learningObjective:
            'Distinguish a symbol-count transformation from a numeric base conversion by tracing the tape after each sweep.',
        limitation:
            'Despite the authored machine name, it does not evaluate the binary number: input 101 becomes 111, not five unary marks. The empty word remains empty.',
        accessibleDescription:
            'A three-state single-tape machine makes one pass to turn every 0 or 1 into X, then a reverse pass to turn every X into 1 before accepting.',
      ),
      pt: const AssetExampleContentCopy(
        title: 'Uma marca unária por símbolo binário',
        summary:
            'A máquina substitui cada bit da entrada por X em uma passagem para a direita e depois reescreve cada X como 1 ao retornar para a esquerda.',
        learningObjective:
            'Distinga uma transformação baseada na quantidade de símbolos de uma conversão numérica de base acompanhando a fita após cada varredura.',
        limitation:
            'Apesar do nome autoral da máquina, ela não calcula o valor binário: a entrada 101 vira 111, e não cinco marcas unárias. A palavra vazia permanece vazia.',
        accessibleDescription:
            'Uma máquina de uma fita com três estados faz uma passagem que transforma cada 0 ou 1 em X e depois uma passagem inversa que transforma cada X em 1 antes de aceitar.',
      ),
    ),
    _entry(
      id: 'asset/tm_copy_string',
      en: const AssetExampleContentCopy(
        title: 'Append a marked binary copy',
        summary:
            'The machine marks the source symbols with X and appends # followed by a symbol-for-symbol copy of the original binary word.',
        learningObjective:
            'Trace how the control state remembers one bit while the head travels to the copy area and returns to the next source symbol.',
        limitation:
            'The source block is not restored: a word w finishes as X repeated |w| times, then #w. The empty word produces only #.',
        accessibleDescription:
            'An eight-state single-tape machine marks one source bit, crosses the tape to append that bit after a separator, returns to the marked block, and repeats.',
      ),
      pt: const AssetExampleContentCopy(
        title: 'Anexar uma cópia binária marcada',
        summary:
            'A máquina marca os símbolos de origem com X e acrescenta # seguido por uma cópia símbolo a símbolo da palavra binária original.',
        learningObjective:
            'Acompanhe como o estado de controle memoriza um bit enquanto a cabeça percorre a fita até a área da cópia e retorna ao próximo símbolo de origem.',
        limitation:
            'O bloco de origem não é restaurado: uma palavra w termina como X repetido |w| vezes, seguido de #w. A palavra vazia produz apenas #.',
        accessibleDescription:
            'Uma máquina de uma fita com oito estados marca um bit de origem, atravessa a fita para anexar esse bit após um separador, retorna ao bloco marcado e repete o processo.',
      ),
    ),
    _entry(
      id: 'asset/tm_increment',
      en: const AssetExampleContentCopy(
        title: 'Increment a binary word',
        summary:
            'The machine scans to the right end, propagates a carry left across trailing 1s, and writes the incremented binary value.',
        learningObjective:
            'Relate binary addition by one to a tape sweep and a carry state.',
        limitation:
            'Only 0 and 1 are accepted as input symbols, leading zeros are preserved, and the empty tape is treated as zero and becomes 1.',
        accessibleDescription:
            'A three-state single-tape machine first crosses the input, then changes trailing 1s to 0s while moving left and changes the first 0 or left blank to 1.',
      ),
      pt: const AssetExampleContentCopy(
        title: 'Incrementar uma palavra binária',
        summary:
            'A máquina percorre a fita até a extremidade direita, propaga um transporte para a esquerda pelos 1 finais e escreve o valor binário incrementado.',
        learningObjective:
            'Relacione a adição binária de uma unidade com uma varredura da fita e um estado de transporte.',
        limitation:
            'A entrada aceita apenas 0 e 1, zeros à esquerda são preservados e a fita vazia é tratada como zero e se torna 1.',
        accessibleDescription:
            'Uma máquina de uma fita com três estados primeiro atravessa a entrada, depois transforma os 1 finais em 0 ao mover para a esquerda e transforma o primeiro 0 ou branco à esquerda em 1.',
      ),
    ),
    _entry(
      id: 'asset/tm_multitape_comparison',
      en: const AssetExampleContentCopy(
        title: 'Compare binary blocks around #',
        summary:
            'This two-tape machine copies the first block of w#w to the second tape, rewinds that copy, and compares it with the second block in lockstep.',
        learningObjective:
            'See how an auxiliary tape turns repeated rescanning into a direct symbol-by-symbol comparison.',
        limitation:
            'Both copies of w must be nonempty binary words and exactly one # must separate them; the machine does not accept # by itself.',
        accessibleDescription:
            'A four-state two-tape machine copies the first binary block, reverses the second tape head to its beginning, then advances both heads together and accepts only matching symbols and endpoints.',
      ),
      pt: const AssetExampleContentCopy(
        title: 'Comparar blocos binários ao redor de #',
        summary:
            'Esta máquina de duas fitas copia o primeiro bloco de w#w para a segunda fita, rebobina essa cópia e a compara em paralelo com o segundo bloco.',
        learningObjective:
            'Observe como uma fita auxiliar transforma novas varreduras em uma comparação direta símbolo a símbolo.',
        limitation:
            'As duas cópias de w devem ser palavras binárias não vazias e exatamente um # deve separá-las; a máquina não aceita # isoladamente.',
        accessibleDescription:
            'Uma máquina de duas fitas com quatro estados copia o primeiro bloco binário, retorna a cabeça da segunda fita ao início e então avança as duas cabeças juntas, aceitando apenas símbolos e extremidades correspondentes.',
      ),
    ),
    _entry(
      id: 'asset/tm_multitape_copy',
      en: const AssetExampleContentCopy(
        title: 'Copy a binary word to a second tape',
        summary:
            'This two-tape machine leaves the input unchanged on the first tape while writing the same binary word on the second tape.',
        learningObjective:
            'Read a multi-tape transition as simultaneous read, write, and head movement operations.',
        limitation:
            'The second tape must initially be blank and the input alphabet is limited to 0 and 1. The empty word is accepted and copied as empty.',
        accessibleDescription:
            'A two-state, two-tape machine moves both heads right together, preserves each bit on the first tape, writes it on the second tape, and accepts when both heads read blank.',
      ),
      pt: const AssetExampleContentCopy(
        title: 'Copiar uma palavra binária para a segunda fita',
        summary:
            'Esta máquina de duas fitas mantém a entrada inalterada na primeira fita enquanto escreve a mesma palavra binária na segunda.',
        learningObjective:
            'Leia uma transição multifitas como operações simultâneas de leitura, escrita e movimento das cabeças.',
        limitation:
            'A segunda fita deve começar vazia e o alfabeto de entrada se limita a 0 e 1. A palavra vazia é aceita e copiada como vazia.',
        accessibleDescription:
            'Uma máquina de duas fitas com dois estados move as duas cabeças juntas para a direita, preserva cada bit na primeira fita, escreve-o na segunda e aceita quando ambas leem branco.',
      ),
    ),
    _entry(
      id: 'asset/tm_multitape_palindrome',
      en: const AssetExampleContentCopy(
        title: 'Palindrome comparison on two tapes',
        summary:
            'The machine copies the binary input, then compares the first tape from right to left with the second tape from left to right.',
        learningObjective:
            'Use opposite head directions on two tapes to compare mirrored positions without marking the input.',
        limitation:
            'Only binary input is supported, and the copied word remains on the second tape after acceptance. The empty word is accepted.',
        accessibleDescription:
            'A four-state two-tape machine copies the word, rewinds the copy, positions the first head at the input end, and compares equal bits while the heads move in opposite directions.',
      ),
      pt: const AssetExampleContentCopy(
        title: 'Comparação de palíndromo em duas fitas',
        summary:
            'A máquina copia a entrada binária e depois compara a primeira fita da direita para a esquerda com a segunda da esquerda para a direita.',
        learningObjective:
            'Use direções opostas das cabeças em duas fitas para comparar posições espelhadas sem marcar a entrada.',
        limitation:
            'A entrada aceita apenas símbolos binários e a palavra copiada permanece na segunda fita após a aceitação. A palavra vazia é aceita.',
        accessibleDescription:
            'Uma máquina de duas fitas com quatro estados copia a palavra, rebobina a cópia, posiciona a primeira cabeça no fim da entrada e compara bits iguais enquanto as cabeças se movem em direções opostas.',
      ),
    ),
    _entry(
      id: 'asset/tm_multitape_work_tape',
      en: const AssetExampleContentCopy(
        title: 'Count unary symbols on a work tape',
        summary:
            'For every 1 read on the first tape, this machine preserves it and writes one X on the second tape.',
        learningObjective:
            'Interpret an auxiliary tape as a durable record of how many input symbols have been processed.',
        limitation:
            'The input language is 1*, so 0 has no transition. The X marks record length only and are not converted back; the empty word is accepted.',
        accessibleDescription:
            'A two-state, two-tape machine advances both heads once per input 1, leaves that 1 unchanged, writes X on the work tape, and accepts at the shared blank.',
      ),
      pt: const AssetExampleContentCopy(
        title: 'Contar símbolos unários em uma fita de trabalho',
        summary:
            'Para cada 1 lido na primeira fita, esta máquina o preserva e escreve um X na segunda.',
        learningObjective:
            'Interprete uma fita auxiliar como registro durável da quantidade de símbolos da entrada já processados.',
        limitation:
            'A linguagem de entrada é 1*, portanto não há transição para 0. As marcas X registram apenas o comprimento e não são reconvertidas; a palavra vazia é aceita.',
        accessibleDescription:
            'Uma máquina de duas fitas com dois estados avança as duas cabeças uma vez por símbolo 1, mantém esse 1, escreve X na fita de trabalho e aceita no branco compartilhado.',
      ),
    ),
    _entry(
      id: 'asset/tm_palindrome',
      en: const AssetExampleContentCopy(
        title: 'Mark-and-compare binary palindromes',
        summary:
            'This single-tape machine marks matched symbols with X while comparing the word from its outermost positions inward.',
        learningObjective:
            'Trace how destructive tape marks let finite control remember which mirrored positions have already matched.',
        limitation:
            'Only 0 and 1 are valid input symbols, and accepted input is left marked rather than restored. The empty word is accepted.',
        accessibleDescription:
            'A seven-state single-tape machine marks the leftmost unmatched bit, scans to the right edge to match it, returns to the left edge, and repeats until no unmarked bits remain.',
      ),
      pt: const AssetExampleContentCopy(
        title: 'Marcar e comparar palíndromos binários',
        summary:
            'Esta máquina de uma fita marca símbolos correspondentes com X enquanto compara a palavra das posições externas para as internas.',
        learningObjective:
            'Acompanhe como marcas destrutivas na fita permitem ao controle finito lembrar quais posições espelhadas já foram comparadas.',
        limitation:
            'A entrada aceita apenas 0 e 1, e a palavra aceita permanece marcada em vez de ser restaurada. A palavra vazia é aceita.',
        accessibleDescription:
            'Uma máquina de uma fita com sete estados marca o bit não comparado mais à esquerda, percorre a fita até a extremidade direita para compará-lo, retorna à extremidade esquerda e repete até não restarem bits sem marcação.',
      ),
    ),
  ]);

  static List<String> get ids =>
      List<String>.unmodifiable(_entries.map((entry) => entry.id));

  static AssetExampleContentCopy? maybeResolve({
    required String id,
    required String languageCode,
  }) {
    final matches = _entries.where((entry) => entry.id == id);
    if (matches.isEmpty) return null;
    final entry = matches.single;
    return languageCode.toLowerCase().startsWith('pt') ? entry.pt : entry.en;
  }

  static AssetExampleContentCopy resolve({
    required String id,
    required String languageCode,
  }) =>
      maybeResolve(id: id, languageCode: languageCode) ??
      (throw StateError('asset-example.copy-id'));
}

final class _AssetExampleContentEntry {
  const _AssetExampleContentEntry({
    required this.id,
    required this.en,
    required this.pt,
  });

  final String id;
  final AssetExampleContentCopy en;
  final AssetExampleContentCopy pt;
}

_AssetExampleContentEntry _entry({
  required String id,
  required AssetExampleContentCopy en,
  required AssetExampleContentCopy pt,
}) => _AssetExampleContentEntry(id: id, en: en, pt: pt);
