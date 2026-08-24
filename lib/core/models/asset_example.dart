/// Typed bundled example exposed to the application layer.
class AssetExample<TPayload> {
  AssetExample({
    required this.name,
    required this.description,
    required this.category,
    required this.difficultyLevel,
    required this.complexityLevel,
    required List<String> tags,
    required this.payload,
  }) : tags = List<String>.unmodifiable(tags);

  final String name;
  final String description;
  final ExampleCategory category;
  final DifficultyLevel difficultyLevel;
  final ExampleComplexityLevel complexityLevel;
  final List<String> tags;
  final TPayload payload;
}

enum DifficultyLevel {
  easy,
  medium,
  hard,
}

enum ExampleComplexityLevel {
  low,
  medium,
  high,
}

enum ExampleCategory {
  dfa,
  nfa,
  cfg,
  pda,
  tm,
  regex,
}
