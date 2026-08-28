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
