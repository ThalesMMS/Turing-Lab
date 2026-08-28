import '../messages/structured_message.dart';

/// Typed bundled example exposed to the application layer.
class AssetExample<TPayload> {
  AssetExample({
    String? id,
    String? name,
    String? description,
    this.nameMessage,
    this.descriptionMessage,
    required this.category,
    required this.difficultyLevel,
    required this.complexityLevel,
    required List<String> tags,
    required this.payload,
  }) : name = _exampleText(name, nameMessage, 'name'),
       description = _exampleText(
         description,
         descriptionMessage,
         'description',
       ),
       id =
           id ??
           name ??
           nameMessage?.stableCode ??
           (throw ArgumentError('asset-example.id-or-name-required')),
       tags = List<String>.unmodifiable(tags);

  final String id;
  final String name;
  final String description;
  final StructuredMessage? nameMessage;
  final StructuredMessage? descriptionMessage;
  final ExampleCategory category;
  final DifficultyLevel difficultyLevel;
  final ExampleComplexityLevel complexityLevel;
  final List<String> tags;
  final TPayload payload;
}

String _exampleText(
  String? legacyText,
  StructuredMessage? message,
  String field,
) {
  final value = legacyText ?? message?.stableCode;
  if (value != null) return value;
  throw ArgumentError(
    field == 'name'
        ? 'asset-example.name-or-message-required'
        : 'asset-example.description-or-message-required',
  );
}

enum DifficultyLevel { easy, medium, hard }

enum ExampleComplexityLevel { low, medium, high }

enum ExampleCategory {
  dfa,
  nfa,
  cfg,
  pda,
  tm,
  regex,
  mealy,
  moore,
  unrestrictedGrammar,
  lSystem,
}
