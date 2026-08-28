import 'dart:io';

import '../catalog.dart';
import '../mutation.dart';
import '../runner.dart';
import '../shrinking.dart';
import 'tm_certification.dart';
import 'tm_matrix.dart';

const tmFamilyId = 'tm';
const tmGeneratorVersion = 'tm-v1';
const tmOracleVersion = 'tm-independent-v1';

final class TmHardEdgeDescriptor {
  const TmHardEdgeDescriptor({
    required this.id,
    required this.algorithm,
    required this.property,
    required this.fixture,
  });

  final String id;
  final String algorithm;
  final String property;
  final String fixture;

  String get reproductionCommand =>
      'dart run tool/hard_edge_tm.dart --property $property';
}

final tmHardEdgeDescriptors = <TmHardEdgeDescriptor>[
  for (final entry in tmAlgorithmInventory)
    TmHardEdgeDescriptor(
      id: 'tm-path-${entry.id}',
      algorithm: entry.id,
      property: entry.properties.first,
      fixture: _fixtureForProperty(entry.properties.first),
    ),
];

final class TmHardEdgeExecutor implements HardEdgeGeneratedPropertyExecutor {
  TmHardEdgeExecutor({Directory? repositoryRoot})
      : _runner = TmCertificationRunner(
          repositoryRoot: repositoryRoot ?? Directory.current,
        );

  final TmCertificationRunner _runner;

  @override
  Future<HardEdgeExecutionOutcome> execute(
    HardEdgeCatalogCase testCase,
    Object? fixture,
  ) async {
    if (testCase.family != tmFamilyId) {
      throw HardEdgeConfigurationException(
        'TM executor cannot run family "${testCase.family}".',
      );
    }
    final entry = _inventoryEntry(testCase.algorithm);
    if (!entry.properties.contains(testCase.property)) {
      throw HardEdgeConfigurationException(
        'Property "${testCase.property}" does not certify '
        '"${testCase.algorithm}".',
      );
    }
    final spec = _TmFixtureSpec.parse(fixture, testCase.property);
    if (spec.scenario != _scenarioForProperty(testCase.property)) {
      return HardEdgeExecutionOutcome.violation;
    }
    final check = await _runner.runProperty(
      testCase.property,
      TmCertificationOptions(
        seed: spec.seed ?? testCase.seed,
        cases: spec.cases ?? 1,
      ),
    );
    if (spec.expectedStatus != null &&
        spec.expectedStatus != check.status.name) {
      return HardEdgeExecutionOutcome.violation;
    }
    return switch (check.status) {
      TmCertificationStatus.passed => HardEdgeExecutionOutcome.pass,
      TmCertificationStatus.failed => HardEdgeExecutionOutcome.violation,
      TmCertificationStatus.incomplete => HardEdgeExecutionOutcome.bounded,
    };
  }

  @override
  Future<Object?> materialize(
    HardEdgeCatalogCase template,
    Object? templateFixture,
    int seed,
  ) async {
    if (template.family != tmFamilyId) {
      throw HardEdgeConfigurationException(
        'TM executor cannot materialize family "${template.family}".',
      );
    }
    final entry = _inventoryEntry(template.algorithm);
    if (!entry.properties.contains(template.property)) {
      throw HardEdgeConfigurationException(
        'Property "${template.property}" does not certify '
        '"${template.algorithm}".',
      );
    }
    final fixture = _TmFixtureSpec.parse(templateFixture, template.property);
    return <String, Object?>{
      ...fixture.source,
      'family': tmFamilyId,
      'generatorVersion': tmGeneratorVersion,
      'oracleVersion': tmOracleVersion,
      'property': template.property,
      'seed': seed,
    };
  }
}

final class TmHardEdgeMutationExecutor implements HardEdgeMutationExecutor {
  TmHardEdgeMutationExecutor({
    Future<bool> Function(String operatorId)? mutationProbe,
  }) : _mutationProbe = mutationProbe ?? tmMutationProbeKilled;

  final Future<bool> Function(String operatorId) _mutationProbe;

  @override
  Future<HardEdgeMutationStatus> execute(
    HardEdgeMutation mutation,
    Object? fixture,
  ) async {
    if (mutation.family != tmFamilyId || mutation.property != 'tm.mutations') {
      throw const HardEdgeConfigurationException(
        'TM mutation executor received an incompatible mutation.',
      );
    }
    if (!tmMutationOperatorIds.contains(mutation.operatorId)) {
      throw HardEdgeConfigurationException(
        'Unknown TM mutation operator "${mutation.operatorId}".',
      );
    }
    final spec = _TmFixtureSpec.parse(fixture, mutation.property);
    final operators = spec.source['operators'];
    if (operators is! List || !operators.contains(mutation.operatorId)) {
      throw FormatException(
        'Mutation fixture does not register "${mutation.operatorId}".',
      );
    }
    return await _mutationProbe(mutation.operatorId)
        ? HardEdgeMutationStatus.killed
        : HardEdgeMutationStatus.survived;
  }
}

final class TmFailureFixtureShrinker implements DomainShrinker<Object?> {
  const TmFailureFixtureShrinker();

  @override
  Iterable<Object?> candidates(Object? value) =>
      tmFailureFixtureCandidates(value);
}

const DomainShrinker<Object?> tmFailureFixtureShrinker =
    TmFailureFixtureShrinker();

TmAlgorithmInventoryEntry _inventoryEntry(String algorithm) {
  for (final entry in tmAlgorithmInventory) {
    if (entry.id == algorithm) return entry;
  }
  throw HardEdgeConfigurationException('Unknown TM algorithm "$algorithm".');
}

String _fixtureForProperty(String property) => switch (property) {
      'tm.multi-tape-atomicity' ||
      'tm.trace-replay' =>
        'test/fixtures/hard_edge/tm/multi_tape.json',
      'tm.reachability-language' ||
      'tm.metrics-trace' =>
        'test/fixtures/hard_edge/tm/analysis.json',
      'tm.building-blocks' => 'test/fixtures/hard_edge/tm/building_blocks.json',
      'tm.grammar-conversion' =>
        'test/fixtures/hard_edge/tm/grammar_conversion.json',
      'tm.generated-shrink' => 'test/fixtures/hard_edge/tm/shrink_probe.json',
      'tm.mutations' => 'test/fixtures/hard_edge/tm/mutation_probes.json',
      _ => 'test/fixtures/hard_edge/tm/core_oracle.json',
    };

String _scenarioForProperty(String property) => switch (property) {
      'tm.multi-tape-atomicity' || 'tm.trace-replay' => 'multi-tape',
      'tm.reachability-language' || 'tm.metrics-trace' => 'analysis',
      'tm.building-blocks' => 'building-blocks',
      'tm.grammar-conversion' => 'grammar-conversion',
      'tm.generated-shrink' => 'shrink',
      'tm.mutations' => 'mutations',
      _ => 'core-oracle',
    };

final class _TmFixtureSpec {
  const _TmFixtureSpec({
    required this.source,
    required this.scenario,
    required this.seed,
    required this.cases,
    required this.expectedStatus,
  });

  final Map<String, Object?> source;
  final String scenario;
  final int? seed;
  final int? cases;
  final String? expectedStatus;

  static _TmFixtureSpec parse(Object? value, String property) {
    if (value is! Map) {
      throw const FormatException('TM hard-edge fixture must be an object.');
    }
    final source = <String, Object?>{
      for (final entry in value.entries) entry.key.toString(): entry.value,
    };
    if (source['family'] != tmFamilyId || source['scenario'] is! String) {
      throw const FormatException('TM hard-edge fixture has invalid metadata.');
    }
    final declaredProperty = source['property'];
    if (declaredProperty != null && declaredProperty != property) {
      throw FormatException(
        'Fixture property "$declaredProperty" does not match "$property".',
      );
    }
    final seed = source['seed'];
    final cases = source['cases'];
    final expectedStatus = source['expectedStatus'];
    if (seed != null && seed is! int ||
        cases != null && cases is! int ||
        expectedStatus != null && expectedStatus is! String) {
      throw const FormatException('TM fixture options have invalid types.');
    }
    return _TmFixtureSpec(
      source: source,
      scenario: source['scenario']! as String,
      seed: seed as int?,
      cases: cases as int?,
      expectedStatus: expectedStatus as String?,
    );
  }
}
