import 'dart:convert';

import 'package:flutter/services.dart';

import '../../core/formal_systems/formal_systems.dart';
import '../../core/messages/structured_message.dart';
import '../../core/models/asset_example.dart';
import '../../core/transducers/transducers.dart';

final class MealyExampleCatalog
    implements ExampleCatalogCapability<MealyMachine> {
  MealyExampleCatalog({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  @override
  CapabilityNamespaceId get namespace =>
      const CapabilityNamespaceId('examples.transducer.mealy.v1');

  @override
  Future<List<AssetExample<MealyMachine>>> loadExamples() async {
    final examples = <AssetExample<MealyMachine>>[];
    for (final definition in _definitions) {
      final encoded = await _bundle.loadString(definition.path);
      final decoded = jsonDecode(encoded);
      if (decoded is! Map) {
        throw FormatException(
          'transducer.example.json-object-required',
          definition.path,
        );
      }
      examples.add(
        AssetExample<MealyMachine>(
          id: definition.id,
          nameMessage: _exampleMessage(definition.nameCode),
          descriptionMessage: _exampleMessage(definition.descriptionCode),
          category: ExampleCategory.mealy,
          difficultyLevel: definition.difficulty,
          complexityLevel: definition.complexity,
          tags: definition.tags,
          payload: MealyMachine.fromJson(Map<String, Object?>.from(decoded)),
        ),
      );
    }
    return List<AssetExample<MealyMachine>>.unmodifiable(examples);
  }

  static const _definitions = <_MealyExampleDefinition>[
    _MealyExampleDefinition(
      path: 'assets/examples/mealy_identity.json',
      id: 'mealy.identity',
      nameCode: 'mealy-identity-name',
      descriptionCode: 'mealy-identity-description',
      difficulty: DifficultyLevel.easy,
      complexity: ExampleComplexityLevel.low,
      tags: ['mealy', 'identity', 'complete'],
    ),
    _MealyExampleDefinition(
      path: 'assets/examples/mealy_parity.json',
      id: 'mealy.parity',
      nameCode: 'mealy-parity-name',
      descriptionCode: 'mealy-parity-description',
      difficulty: DifficultyLevel.medium,
      complexity: ExampleComplexityLevel.medium,
      tags: ['mealy', 'parity', 'complete'],
    ),
    _MealyExampleDefinition(
      path: 'assets/examples/mealy_sequence_detector.json',
      id: 'mealy.sequence-detector',
      nameCode: 'mealy-sequence-name',
      descriptionCode: 'mealy-sequence-description',
      difficulty: DifficultyLevel.medium,
      complexity: ExampleComplexityLevel.medium,
      tags: ['mealy', 'sequence', 'detector'],
    ),
    _MealyExampleDefinition(
      path: 'assets/examples/mealy_partial.json',
      id: 'mealy.partial',
      nameCode: 'mealy-partial-name',
      descriptionCode: 'mealy-partial-description',
      difficulty: DifficultyLevel.easy,
      complexity: ExampleComplexityLevel.low,
      tags: ['mealy', 'partial', 'undefined'],
    ),
  ];
}

final class _MealyExampleDefinition {
  const _MealyExampleDefinition({
    required this.id,
    required this.path,
    required this.nameCode,
    required this.descriptionCode,
    required this.difficulty,
    required this.complexity,
    required this.tags,
  });

  final String path;
  final String id;
  final String nameCode;
  final String descriptionCode;
  final DifficultyLevel difficulty;
  final ExampleComplexityLevel complexity;
  final List<String> tags;
}

StructuredMessage _exampleMessage(String code) => StructuredMessage(
  namespace: 'transducer.example',
  code: code,
  category: StructuredMessageCategory.analysis,
  severity: StructuredMessageSeverity.information,
);
