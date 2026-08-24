/// Bundled regular-expression example that can populate the Regex workspace.
class RegexPreset {
  const RegexPreset({
    required this.id,
    required this.name,
    required this.expression,
    required this.alphabet,
  });

  final String id;
  final String name;
  final String expression;
  final String alphabet;
}
