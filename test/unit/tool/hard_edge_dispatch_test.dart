import 'package:flutter_test/flutter_test.dart';

import '../../../tool/hard_edge/catalog.dart';
import '../../../tool/hard_edge/dispatch.dart';
import '../../../tool/hard_edge/models.dart';
import '../../../tool/hard_edge/mutation.dart';
import '../../../tool/hard_edge/runner.dart';
import '../../../tool/hard_edge/shrinking.dart';

void main() {
  group('HardEdgePropertyExecutorRegistry', () {
    test('routes execution and materialization by family', () async {
      final alpha = _RecordingPropertyExecutor(HardEdgeExecutionOutcome.pass);
      final beta = _RecordingPropertyExecutor(
        HardEdgeExecutionOutcome.violation,
      );
      final registry = HardEdgePropertyExecutorRegistry({
        'alpha': alpha,
        'beta': beta,
      });
      final alphaCase = _testCase(family: 'alpha');
      final betaCase = _testCase(family: 'beta');

      expect(
        await registry.execute(alphaCase, const {'fixture': 'alpha'}),
        HardEdgeExecutionOutcome.pass,
      );
      expect(
        await registry.execute(betaCase, const {'fixture': 'beta'}),
        HardEdgeExecutionOutcome.violation,
      );
      expect(
        await registry.materialize(alphaCase, const {'template': true}, 17),
        const {'seed': 17},
      );
      expect(alpha.executedFamilies, ['alpha']);
      expect(beta.executedFamilies, ['beta']);
    });

    test('rejects unregistered families', () async {
      final registry = HardEdgePropertyExecutorRegistry({
        'alpha': _RecordingPropertyExecutor(HardEdgeExecutionOutcome.pass),
      });

      await expectLater(
        registry.execute(_testCase(family: 'missing'), const {}),
        throwsA(isA<HardEdgeConfigurationException>()),
      );
    });

    test('rejects seed generation when the family has no generator', () async {
      final registry = HardEdgePropertyExecutorRegistry({
        'fixed': const _FixedPropertyExecutor(),
      });

      await expectLater(
        registry.materialize(_testCase(family: 'fixed'), const {}, 9),
        throwsA(isA<HardEdgeConfigurationException>()),
      );
    });

    test('requires a non-empty registry and family identifiers', () {
      expect(
        () => HardEdgePropertyExecutorRegistry(const {}),
        throwsArgumentError,
      );
      expect(
        () => HardEdgePropertyExecutorRegistry({
          '  ': const _FixedPropertyExecutor(),
        }),
        throwsArgumentError,
      );
    });
  });

  group('HardEdgeMutationExecutorRegistry', () {
    test('routes mutations by family and rejects unknown families', () async {
      final executor = _RecordingMutationExecutor();
      final registry = HardEdgeMutationExecutorRegistry({'alpha': executor});

      expect(
        await registry.execute(_mutation(family: 'alpha'), const {}),
        HardEdgeMutationStatus.killed,
      );
      expect(executor.executedFamilies, ['alpha']);
      await expectLater(
        registry.execute(_mutation(family: 'missing'), const {}),
        throwsA(isA<HardEdgeConfigurationException>()),
      );
    });
  });

  group('HardEdgeShrinkAdapterRegistry', () {
    test('resolves registered adapters and leaves fallback families absent',
        () {
      final adapter = HardEdgeShrinkAdapter(
        shrinker: const _FixtureShrinker(),
        isValid: (fixture) => fixture is Map,
        isApplicable: (fixture) => fixture == const {'fails': true},
      );
      final registry = HardEdgeShrinkAdapterRegistry({'alpha': adapter});

      expect(registry.forFamily('alpha'), same(adapter));
      expect(registry.forFamily('framework'), isNull);
    });

    test('requires a non-empty registry and family identifiers', () {
      final adapter = HardEdgeShrinkAdapter(
        shrinker: const _FixtureShrinker(),
        isValid: (_) => true,
        isApplicable: (_) => true,
      );

      expect(
          () => HardEdgeShrinkAdapterRegistry(const {}), throwsArgumentError);
      expect(
        () => HardEdgeShrinkAdapterRegistry({' ': adapter}),
        throwsArgumentError,
      );
    });
  });
}

final class _FixtureShrinker implements DomainShrinker<Object?> {
  const _FixtureShrinker();

  @override
  Iterable<Object?> candidates(Object? value) => const [];
}

final class _RecordingPropertyExecutor
    implements HardEdgeGeneratedPropertyExecutor {
  _RecordingPropertyExecutor(this.outcome);

  final HardEdgeExecutionOutcome outcome;
  final List<String> executedFamilies = [];

  @override
  Future<HardEdgeExecutionOutcome> execute(
    HardEdgeCatalogCase testCase,
    Object? fixture,
  ) async {
    executedFamilies.add(testCase.family);
    return outcome;
  }

  @override
  Future<Object?> materialize(
    HardEdgeCatalogCase template,
    Object? templateFixture,
    int seed,
  ) async =>
      {'seed': seed};
}

final class _FixedPropertyExecutor implements HardEdgePropertyExecutor {
  const _FixedPropertyExecutor();

  @override
  Future<HardEdgeExecutionOutcome> execute(
    HardEdgeCatalogCase testCase,
    Object? fixture,
  ) async =>
      HardEdgeExecutionOutcome.pass;
}

final class _RecordingMutationExecutor implements HardEdgeMutationExecutor {
  final List<String> executedFamilies = [];

  @override
  Future<HardEdgeMutationStatus> execute(
    HardEdgeMutation mutation,
    Object? fixture,
  ) async {
    executedFamilies.add(mutation.family);
    return HardEdgeMutationStatus.killed;
  }
}

HardEdgeCatalogCase _testCase({required String family}) => HardEdgeCatalogCase(
      id: '$family-case',
      family: family,
      algorithm: 'algorithm',
      sourceKind: HardEdgeSourceKind.independent,
      seed: 1,
      property: 'property',
      provenance: const HardEdgeProvenance(
        origin: 'test',
        independentlyAuthored: true,
        generator: 'test',
        licenseBasis: 'LICENSE.txt',
      ),
      license: 'Apache-2.0',
      regressionIssue: 334,
      platforms: const ['all'],
      fixture: 'fixture.json',
      sha256: List.filled(64, 'a').join(),
      generatorVersion: 'test-v1',
      oracleVersion: 'test-v1',
      budget: const GenerationBudget(
        maxStates: 1,
        maxTransitions: 1,
        maxSymbols: 1,
        maxWordLength: 1,
        maxStackDepth: 1,
        maxTapeCells: 1,
        maxProductions: 1,
        maxRegexNodes: 1,
        maxIterations: 1,
      ),
      expectedOutcome: HardEdgeExpectedOutcome.pass,
      requiredTool: null,
    );

HardEdgeMutation _mutation({required String family}) => HardEdgeMutation(
      id: '$family-mutation',
      family: family,
      property: 'property',
      operatorId: 'operator',
      fixture: 'fixture.json',
      sha256: List.filled(64, 'b').join(),
      requiredTool: null,
    );
