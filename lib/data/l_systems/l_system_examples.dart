import '../../core/l_systems/l_systems.dart';
import '../../core/formal_systems/formal_systems.dart';
import '../../core/models/asset_example.dart';

final class LSystemExample {
  const LSystemExample({
    required this.id,
    required this.name,
    required this.description,
    required this.document,
  });

  final String id;
  final String name;
  final String description;
  final LSystemDocument document;
}

/// Built-in examples are code-backed so they remain available without I/O.
abstract final class LSystemExamples {
  static final values = List<LSystemExample>.unmodifiable([
    _example(
      id: 'l-system.koch-curve',
      name: 'Koch curve',
      description: 'A four-segment replacement with 60 degree turns.',
      axiom: 'F',
      iterations: 4,
      angle: 60,
      rules: {'F': 'F+F--F+F'},
    ),
    _example(
      id: 'l-system.sierpinski-triangle',
      name: 'Sierpiński triangle',
      description: 'Mutually rewriting draw symbols form a triangle gasket.',
      axiom: 'F-G-G',
      iterations: 5,
      angle: 120,
      rules: {'F': 'F-G+F+G-F', 'G': 'GG'},
    ),
    _example(
      id: 'l-system.dragon-curve',
      name: 'Dragon curve',
      description: 'Two control symbols generate a right-angle dragon.',
      axiom: 'FX',
      iterations: 10,
      angle: 90,
      rules: {'X': 'X+YF+', 'Y': '-FX-Y'},
    ),
    _example(
      id: 'l-system.fractal-plant',
      name: 'Fractal plant',
      description: 'Nested branches produce a compact botanical form.',
      axiom: 'X',
      iterations: 5,
      angle: 25,
      rules: {'X': 'F+[[X]-X]-F[-FX]+X', 'F': 'FF'},
    ),
    _example(
      id: 'l-system.branching-tree',
      name: 'Branching tree',
      description: 'Balanced push and pop commands create repeated branches.',
      axiom: 'F',
      iterations: 5,
      angle: 25,
      rules: {'F': 'F[+F]F[-F]F'},
    ),
    LSystemExample(
      id: 'l-system.seeded-context-turtle',
      name: 'Seeded context turtle',
      description:
          'Seeded alternatives and a left/right context produce styled pitch and polygon commands.',
      document: LSystemDocument(
        id: 'l-system.seeded-context-turtle',
        name: 'Seeded context turtle',
        revision: 0,
        axiom: LSystemWord(const ['L', 'A', 'R']),
        productions: [
          LSystemProduction(
            id: 'seeded-context-green',
            predecessor: 'A',
            successor: LSystemWord(const [
              'color(#2e7d32)',
              '!',
              'g',
              '[',
              '&',
              'g',
              ']',
              '{',
              'g',
              '+',
              'g',
              '+',
              'g',
              '}',
            ]),
            leftContext: LSystemWord(const ['L']),
            rightContext: LSystemWord(const ['R']),
            weight: 2,
          ),
          LSystemProduction(
            id: 'seeded-context-blue',
            predecessor: 'A',
            successor: LSystemWord(const [
              'color(#1565c0)',
              'g',
              '/',
              'g',
              '#',
              'g',
            ]),
            leftContext: LSystemWord(const ['L']),
            rightContext: LSystemWord(const ['R']),
          ),
        ],
        iterations: 1,
        turtle: LSystemTurtleSettings(
          angleDegrees: 60,
          lineWidthIncrement: 1.5,
          hueIncrementDegrees: 45,
        ),
        commandMapping: LSystemCommandMapping.jflap,
        randomSeed: 352,
      ),
    ),
  ]);
}

final class LSystemExampleCatalog
    implements ExampleCatalogCapability<LSystemDocument> {
  const LSystemExampleCatalog();

  @override
  CapabilityNamespaceId get namespace =>
      const CapabilityNamespaceId('examples.l-system.v1');

  @override
  Future<List<AssetExample<LSystemDocument>>> loadExamples() async => [
        for (final example in LSystemExamples.values)
          AssetExample<LSystemDocument>(
            id: example.id,
            name: example.name,
            description: example.description,
            category: ExampleCategory.lSystem,
            difficultyLevel: DifficultyLevel.medium,
            complexityLevel: ExampleComplexityLevel.medium,
            tags: const ['l-system', 'turtle-graphics', 'parallel-rewriting'],
            payload: example.document,
          ),
      ];
}

LSystemExample _example({
  required String id,
  required String name,
  required String description,
  required String axiom,
  required int iterations,
  required double angle,
  required Map<String, String> rules,
}) =>
    LSystemExample(
      id: id,
      name: name,
      description: description,
      document: LSystemDocument(
        id: id,
        name: name,
        revision: 0,
        axiom: LSystemWord(_characters(axiom)),
        productions: [
          for (final entry in rules.entries)
            LSystemProduction(
              id: '$id.${entry.key}',
              predecessor: entry.key,
              successor: LSystemWord(_characters(entry.value)),
            ),
        ],
        iterations: iterations,
        turtle: LSystemTurtleSettings(angleDegrees: angle),
        commandMapping: LSystemCommandMapping.standard,
      ),
    );

List<String> _characters(String value) =>
    value.runes.map(String.fromCharCode).toList(growable: false);
