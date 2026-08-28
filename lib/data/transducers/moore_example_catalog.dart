import 'dart:convert';

import 'package:flutter/services.dart';

import '../../core/formal_systems/formal_systems.dart';
import '../../core/messages/structured_message.dart';
import '../../core/models/asset_example.dart';
import '../../core/transducers/transducers.dart';

final class MooreExampleCatalog
    implements ExampleCatalogCapability<MooreMachine> {
  MooreExampleCatalog({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  @override
  CapabilityNamespaceId get namespace =>
      const CapabilityNamespaceId('examples.transducer.moore.v1');

  @override
  Future<List<AssetExample<MooreMachine>>> loadExamples() async {
    final examples = <AssetExample<MooreMachine>>[];
    for (final definition in _definitions) {
      final encoded = await _bundle.loadString(definition.path);
      final decoded = jsonDecode(encoded);
      if (decoded is! Map) {
        throw FormatException(
          'transducer.example.json-object-required',
          definition.path,
        );
      }
      final machine = MooreMachine.fromJson(Map<String, Object?>.from(decoded));
      final analysis = TransducerAnalyzer.analyze(machine);
      if (!analysis.isStructurallyValid) {
        throw FormatException(
          'transducer.example.invalid-moore-machine',
          definition.path,
        );
      }
      examples.add(
        AssetExample<MooreMachine>(
          id: definition.id,
          nameMessage: _exampleMessage(definition.nameCode),
          descriptionMessage: _exampleMessage(definition.descriptionCode),
          category: ExampleCategory.moore,
          difficultyLevel: definition.difficulty,
          complexityLevel: definition.complexity,
          tags: definition.tags,
          payload: machine,
        ),
      );
    }
    return List<AssetExample<MooreMachine>>.unmodifiable(examples);
  }

  static const _definitions = <_MooreExampleDefinition>[
    _MooreExampleDefinition(
      id: 'asset/moore_parity',
      path: 'assets/examples/moore_parity.json',
      nameCode: 'moore-parity-name',
      descriptionCode: 'moore-parity-description',
      difficulty: DifficultyLevel.easy,
      complexity: ExampleComplexityLevel.low,
      tags: ['moore', 'parity', 'complete'],
    ),
    _MooreExampleDefinition(
      id: 'asset/moore_vending_control',
      path: 'assets/examples/moore_vending_control.json',
      nameCode: 'moore-vending-name',
      descriptionCode: 'moore-vending-description',
      difficulty: DifficultyLevel.medium,
      complexity: ExampleComplexityLevel.medium,
      tags: ['moore', 'vending', 'control', 'complete'],
    ),
    _MooreExampleDefinition(
      id: 'asset/moore_sequence_detector',
      path: 'assets/examples/moore_sequence_detector.json',
      nameCode: 'moore-sequence-name',
      descriptionCode: 'moore-sequence-description',
      difficulty: DifficultyLevel.medium,
      complexity: ExampleComplexityLevel.medium,
      tags: ['moore', 'sequence', 'detector'],
    ),
    _MooreExampleDefinition(
      id: 'asset/moore_partial',
      path: 'assets/examples/moore_partial.json',
      nameCode: 'moore-partial-name',
      descriptionCode: 'moore-partial-description',
      difficulty: DifficultyLevel.easy,
      complexity: ExampleComplexityLevel.low,
      tags: ['moore', 'partial', 'undefined'],
    ),
  ];
}

final class _MooreExampleDefinition {
  const _MooreExampleDefinition({
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
