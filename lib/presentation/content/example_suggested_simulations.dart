/// Locale-neutral inputs that demonstrate each simulation-capable example.
///
/// Keys are stable example IDs. Formal words remain untranslated so the same
/// suggestion can be verified against the bundled payload in every locale.
abstract final class ExampleSuggestedSimulations {
  static const byExampleId = <String, List<String>>{
    'asset/afd_binary_divisible_by_3': ['110'],
    'asset/afd_contains_ab': ['aab'],
    'asset/afd_ends_with_a': ['ba'],
    'asset/afd_parity_ab': ['aabb'],
    'asset/afn_lambda_a_or_ab': ['a', 'ab'],
    'asset/apda_anb2n': ['aabbbb'],
    'asset/apda_anbn': ['aabb'],
    'asset/apda_balanced_parentheses': ['(())'],
    'asset/apda_mirrored_separator': ['ab#ba'],
    'asset/apda_palindrome': ['abba'],
    'asset/glc_anbn': ['aabb'],
    'asset/glc_arithmetic_expressions': ['id+id*id'],
    'asset/glc_balanced_parentheses': ['(())'],
    'asset/glc_even_zeros': ['0011'],
    'asset/glc_palindrome': ['abba'],
    'asset/regex_a_star': ['aaaa'],
    'asset/regex_a_then_b': ['aaabbb'],
    'asset/regex_ab_or_ba_pairs': ['abba'],
    'asset/regex_binary_starts_zero': ['0101'],
    'asset/regex_ends_with_ab': ['baab'],
    'asset/tm_anbn': ['aaabbb'],
    'asset/tm_binary_to_unary': ['101'],
    'asset/tm_copy_string': ['101'],
    'asset/tm_increment': ['101'],
    'asset/tm_multitape_comparison': ['101#101'],
    'asset/tm_multitape_copy': ['101'],
    'asset/tm_multitape_palindrome': ['1001'],
    'asset/tm_multitape_work_tape': ['111'],
    'asset/tm_palindrome': ['1001'],
    'mealy.identity': ['0101'],
    'mealy.parity': ['1011'],
    'mealy.sequence-detector': ['aab'],
    'mealy.partial': ['aaa'],
    'asset/moore_parity': ['1011'],
    'asset/moore_vending_control': ['coin vend'],
    'asset/moore_sequence_detector': ['1010'],
    'asset/moore_partial': ['ab'],
    'an-bn-cn': ['aabbcc'],
    'context-copying': ['abb'],
    'tm-generated': ['✓'],
    'tm-building-blocks-composition': ['111'],
  };

  static List<String> resolve(String exampleId) =>
      byExampleId[exampleId] ?? const [];
}

/// What a simulation of a suggested input is expected to produce.
enum ExampleSimulationExpectation {
  /// The word belongs to the language; the run reaches acceptance.
  accepted,

  /// The word uses only alphabet symbols but is not in the language.
  rejected,

  /// The word contains a symbol outside the example alphabet, so it is
  /// invalid input rather than a rejected word of the language.
  invalidSymbol,
}

/// A commented input for an example: the word, the conclusive outcome the
/// bundled payload produces for it, and a short didactic justification.
///
/// Rationales never promise a single accepting or rejecting path, because
/// nondeterministic payloads may explore several branches.
final class ExampleSuggestedSimulation {
  const ExampleSuggestedSimulation({
    required this.input,
    required this.expectation,
    required this.rationaleEn,
    required this.rationalePt,
  });

  final String input;
  final ExampleSimulationExpectation expectation;
  final String rationaleEn;
  final String rationalePt;

  String rationaleFor(String languageCode) =>
      languageCode.toLowerCase().startsWith('pt') ? rationalePt : rationaleEn;
}

/// Commented boundary inputs and counterexamples for the recognition
/// examples of finite automata and pushdown automata.
///
/// Every entry is verified against the bundled payload by
/// `test/unit/presentation/example_suggested_simulations_payload_test.dart`,
/// which distinguishes rejection, invalid input and inconclusive execution.
abstract final class ExampleCounterexamples {
  static const byExampleId = <String, List<ExampleSuggestedSimulation>>{
    'asset/afd_binary_divisible_by_3': [
      ExampleSuggestedSimulation(
        input: '111',
        expectation: ExampleSimulationExpectation.rejected,
        rationaleEn:
            '111 is 7 in binary and 7 leaves remainder 1, so the run ends in q1, which is not accepting.',
        rationalePt:
            '111 é 7 em binário e 7 deixa resto 1, então a execução termina em q1, que não é final.',
      ),
      ExampleSuggestedSimulation(
        input: '',
        expectation: ExampleSimulationExpectation.accepted,
        rationaleEn:
            'The empty word reads no digits and stays in q0, which is accepting because the value 0 is divisible by 3.',
        rationalePt:
            'A palavra vazia não lê dígitos e permanece em q0, que é final porque o valor 0 é divisível por 3.',
      ),
    ],
    'asset/afd_contains_ab': [
      ExampleSuggestedSimulation(
        input: 'ba',
        expectation: ExampleSimulationExpectation.rejected,
        rationaleEn:
            'The b comes before any a, so the substring ab never appears and the run ends before reaching q2.',
        rationalePt:
            'O b aparece antes de qualquer a, então a subpalavra ab nunca ocorre e a execução termina antes de alcançar q2.',
      ),
      ExampleSuggestedSimulation(
        input: 'abc',
        expectation: ExampleSimulationExpectation.invalidSymbol,
        rationaleEn:
            'c is not in the alphabet {a, b}: the simulator reports an invalid input symbol instead of rejecting a word of the language.',
        rationalePt:
            'c não pertence ao alfabeto {a, b}: o simulador informa um símbolo de entrada inválido em vez de rejeitar uma palavra da linguagem.',
      ),
    ],
    'asset/afd_ends_with_a': [
      ExampleSuggestedSimulation(
        input: 'ab',
        expectation: ExampleSimulationExpectation.rejected,
        rationaleEn:
            'Only the last symbol matters: the final b moves the machine back to the non-accepting state.',
        rationalePt:
            'Só o último símbolo importa: o b final leva a máquina de volta ao estado não final.',
      ),
      ExampleSuggestedSimulation(
        input: '',
        expectation: ExampleSimulationExpectation.rejected,
        rationaleEn:
            'The empty word has no last symbol, so it cannot end in a and the initial state stays non-accepting.',
        rationalePt:
            'A palavra vazia não tem último símbolo, então não pode terminar em a e o estado inicial continua não final.',
      ),
    ],
    'asset/afd_parity_ab': [
      ExampleSuggestedSimulation(
        input: 'aab',
        expectation: ExampleSimulationExpectation.rejected,
        rationaleEn:
            'Two a are even but the single b is odd, so the run ends in the state for odd b count.',
        rationalePt:
            'Dois a são pares, mas o único b é ímpar, então a execução termina no estado de quantidade ímpar de b.',
      ),
      ExampleSuggestedSimulation(
        input: '',
        expectation: ExampleSimulationExpectation.accepted,
        rationaleEn:
            'Zero a and zero b are both even counts, so the initial state is accepting for the empty word.',
        rationalePt:
            'Zero a e zero b são quantidades pares, então o estado inicial é final para a palavra vazia.',
      ),
    ],
    'asset/afn_lambda_a_or_ab': [
      ExampleSuggestedSimulation(
        input: 'b',
        expectation: ExampleSimulationExpectation.rejected,
        rationaleEn:
            'Every branch, including the λ-moves, needs an a first; no branch can consume b from the initial state.',
        rationalePt:
            'Todo ramo, inclusive os movimentos λ, precisa de um a primeiro; nenhum ramo consegue consumir b a partir do estado inicial.',
      ),
      ExampleSuggestedSimulation(
        input: 'abb',
        expectation: ExampleSimulationExpectation.rejected,
        rationaleEn:
            'The branches that read a or ab reach acceptance, but the remaining b has no transition, so no branch accepts the whole word.',
        rationalePt:
            'Os ramos que leem a ou ab chegam à aceitação, mas o b restante não tem transição, então nenhum ramo aceita a palavra inteira.',
      ),
    ],
    'asset/apda_anb2n': [
      ExampleSuggestedSimulation(
        input: 'aabb',
        expectation: ExampleSimulationExpectation.rejected,
        rationaleEn:
            'Each a must be matched by two b. Two a need four b, so the stack still holds markers when the input ends.',
        rationalePt:
            'Cada a precisa ser compensado por dois b. Dois a exigem quatro b, então a pilha ainda guarda marcadores quando a entrada termina.',
      ),
    ],
    'asset/apda_anbn': [
      ExampleSuggestedSimulation(
        input: 'aab',
        expectation: ExampleSimulationExpectation.rejected,
        rationaleEn:
            'Two a push two markers but only one b pops, so the stack is not back to the bottom marker at the end.',
        rationalePt:
            'Dois a empilham dois marcadores, mas só um b desempilha, então a pilha não volta ao marcador de fundo no final.',
      ),
      ExampleSuggestedSimulation(
        input: 'ba',
        expectation: ExampleSimulationExpectation.rejected,
        rationaleEn:
            'A b before any a finds no marker to pop, so no configuration can continue.',
        rationalePt:
            'Um b antes de qualquer a não encontra marcador para desempilhar, então nenhuma configuração consegue continuar.',
      ),
    ],
    'asset/apda_balanced_parentheses': [
      ExampleSuggestedSimulation(
        input: '(()',
        expectation: ExampleSimulationExpectation.rejected,
        rationaleEn:
            'One opening parenthesis is never closed, so a marker remains on the stack when the input ends.',
        rationalePt:
            'Um parêntese de abertura nunca é fechado, então um marcador permanece na pilha quando a entrada termina.',
      ),
      ExampleSuggestedSimulation(
        input: ')(',
        expectation: ExampleSimulationExpectation.rejected,
        rationaleEn:
            'The closing parenthesis arrives with no opening marker to pop, so the run is stuck immediately.',
        rationalePt:
            'O parêntese de fechamento chega sem marcador de abertura para desempilhar, então a execução trava imediatamente.',
      ),
    ],
    'asset/apda_mirrored_separator': [
      ExampleSuggestedSimulation(
        input: 'ab#ab',
        expectation: ExampleSimulationExpectation.rejected,
        rationaleEn:
            'After the separator the stack holds the first half reversed (b then a), and the second half ab does not match it.',
        rationalePt:
            'Depois do separador a pilha guarda a primeira metade invertida (b e depois a), e a segunda metade ab não corresponde.',
      ),
    ],
    'asset/apda_palindrome': [
      ExampleSuggestedSimulation(
        input: 'abab',
        expectation: ExampleSimulationExpectation.rejected,
        rationaleEn:
            'Whatever middle the machine guesses, the second half never mirrors the first, so every branch fails.',
        rationalePt:
            'Seja qual for o meio que a máquina adivinhe, a segunda metade nunca espelha a primeira, então todos os ramos falham.',
      ),
      ExampleSuggestedSimulation(
        input: 'abc',
        expectation: ExampleSimulationExpectation.invalidSymbol,
        rationaleEn:
            'c is not in the alphabet {a, b}; the run stops because no transition reads it, which is invalid input rather than a rejected palindrome.',
        rationalePt:
            'c não pertence ao alfabeto {a, b}; a execução para porque nenhuma transição o lê, o que é entrada inválida e não um palíndromo rejeitado.',
      ),
    ],
  };

  static List<ExampleSuggestedSimulation> resolve(String exampleId) =>
      byExampleId[exampleId] ?? const [];
}
