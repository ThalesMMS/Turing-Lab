// Mutable fixture collections verify registry extension behavior.
// ignore_for_file: prefer_const_constructors

import 'package:test/test.dart';
import 'package:turing_lab/core/formal_systems/formal_systems.dart';
import 'package:turing_lab/core/models/asset_example.dart';
import 'package:turing_lab/core/transducers/transducers.dart';

void main() {
  group('GraphView mapping boundary', () {
    test('maps Mealy output only onto edges', () {
      final mapping = TransducerGraphMapping.fromMachine(_mealy());

      expect(mapping.nodes.single, isA<MealyGraphNode>());
      expect(mapping.edges.single, isA<MealyGraphEdge>());
      expect((mapping.edges.single as MealyGraphEdge).output.values, ['x']);
      expect(mapping.nodes.single.toJson(), isNot(contains('isAccepting')));
      expect(mapping.edges.single.toJson(), isNot(contains('isEpsilon')));
    });

    test('maps Moore output only onto nodes', () {
      final mapping = TransducerGraphMapping.fromMachine(_moore());

      expect(mapping.nodes.single, isA<MooreGraphNode>());
      expect((mapping.nodes.single as MooreGraphNode).output.values, ['x']);
      expect(mapping.edges.single, isA<MooreGraphEdge>());
      expect(mapping.nodes.single.toJson(), isNot(contains('isAccepting')));
      expect(mapping.edges.single.toJson(), isNot(contains('isEpsilon')));
    });
  });

  group('formal-system registry hooks', () {
    test('publishes stable schemas without modifying the default registry', () {
      expect(
        FormalSystemRegistry.defaultRegistry
            .descriptorFor(TransducerFormalSystemIds.mealy),
        isNull,
      );
      expect(
        TransducerFormalSystemModules.mealy.descriptor.schema,
        const DocumentSchemaDescriptor(
          id: DocumentSchemaId('turing-lab.mealy'),
          version: DocumentSchemaVersion(1),
        ),
      );
      expect(
        TransducerFormalSystemModules.moore.descriptor.schema.id.value,
        'turing-lab.moore',
      );
      expect(TransducerFormalSystemModules.mealy.codecs, isEmpty);
      expect(TransducerFormalSystemModules.moore.codecs, isEmpty);
    });

    test('session capabilities round trip both variants', () {
      final mealySession = TransducerFormalSystemModules.mealy.session!;
      final mooreSession = TransducerFormalSystemModules.moore.session!;

      final restoredMealy = mealySession.decodeSession(
        mealySession.encodeSession(_mealy()),
        schema: TransducerFormalSystemModules.mealy.descriptor.schema,
      );
      final restoredMoore = mooreSession.decodeSession(
        mooreSession.encodeSession(_moore()),
        schema: TransducerFormalSystemModules.moore.descriptor.schema,
      );

      expect(restoredMealy.toJson(), _mealy().toJson());
      expect(restoredMoore.toJson(), _moore().toJson());
    });

    test('injects an example catalog without a central dispatch edit',
        () async {
      final module = TransducerFormalSystemModule<MealyMachine>(
        descriptor: TransducerFormalSystemModules.mealy.descriptor,
        session: TransducerFormalSystemModules.mealy.session,
        examples: const _MealyExamples(),
      );
      final registry = FormalSystemRegistry(
        modules: <FormalSystemModule<Object>>[module],
        formats: FormalSystemRegistry.defaultRegistry.formats.formats,
      );

      final examples = await registry
          .moduleFor(TransducerFormalSystemIds.mealy)!
          .examples!
          .loadExamples();
      expect(examples.single.name, 'Identity');
      expect(examples.single.payload, isA<MealyMachine>());
    });
  });
}

final class _MealyExamples implements ExampleCatalogCapability<MealyMachine> {
  const _MealyExamples();

  @override
  CapabilityNamespaceId get namespace =>
      const CapabilityNamespaceId('examples.transducer.mealy.test');

  @override
  Future<List<AssetExample<MealyMachine>>> loadExamples() async => [
        AssetExample(
          name: 'Identity',
          description: 'Test-only Mealy machine.',
          category: ExampleCategory.dfa,
          difficultyLevel: DifficultyLevel.easy,
          complexityLevel: ExampleComplexityLevel.low,
          tags: ['transducer'],
          payload: _mealy(),
        ),
      ];
}

MealyMachine _mealy() => MealyMachine(
      id: const TransducerMachineId('mealy'),
      name: 'Mealy',
      revision: const TransducerRevision(1),
      inputAlphabet: {TransducerInputSymbol('a')},
      outputAlphabet: {TransducerOutputSymbol('x')},
      states: [
        MealyState(
          id: TransducerStateId('q0'),
          label: 'zero',
          position: TransducerPoint(0, 0),
          isInitial: true,
        ),
      ],
      transitions: [
        MealyTransition(
          id: TransducerTransitionId('t0'),
          from: TransducerStateId('q0'),
          to: TransducerStateId('q0'),
          input: TransducerInputSymbol('a'),
          output: TransducerOutputWord([TransducerOutputSymbol('x')]),
        ),
      ],
    );

MooreMachine _moore() => MooreMachine(
      id: const TransducerMachineId('moore'),
      name: 'Moore',
      revision: const TransducerRevision(1),
      inputAlphabet: {TransducerInputSymbol('a')},
      outputAlphabet: {TransducerOutputSymbol('x')},
      states: [
        MooreState(
          id: TransducerStateId('q0'),
          label: 'zero',
          position: TransducerPoint(0, 0),
          isInitial: true,
          output: TransducerOutputWord([TransducerOutputSymbol('x')]),
        ),
      ],
      transitions: [
        MooreTransition(
          id: TransducerTransitionId('t0'),
          from: TransducerStateId('q0'),
          to: TransducerStateId('q0'),
          input: TransducerInputSymbol('a'),
        ),
      ],
    );
