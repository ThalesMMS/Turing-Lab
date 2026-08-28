import 'dart:async';

import '../catalog.dart';
import '../dispatch.dart';
import '../shrinking.dart';
import '../mutation.dart';
import '../runner.dart';
import 'pda_family.dart';
import 'pda_oracle.dart';

const pdaFixtureShrinker = PdaFixtureShrinker();
final pdaMutationProbeDescriptors = Map<String, PdaOracleMutation>.unmodifiable(
  const {
    'ignore-push': PdaOracleMutation.ignorePush,
    'reverse-push-order': PdaOracleMutation.reversePushOrder,
    'omit-stack-from-configuration':
        PdaOracleMutation.omitStackFromConfiguration,
    'accept-before-input-consumed': PdaOracleMutation.acceptBeforeInputConsumed,
  },
);

typedef PdaHardEdgeShrinkApplicability = FutureOr<bool> Function(
  PdaHardEdgeFixture fixture,
);

/// Builds the typed central shrink adapter for serialized PDA fixtures.
HardEdgeShrinkAdapter pdaHardEdgeShrinkAdapter({
  required PdaHardEdgeShrinkApplicability isApplicable,
}) =>
    HardEdgeShrinkAdapter(
      shrinker: const _PdaHardEdgeJsonShrinker(),
      isValid: (raw) {
        try {
          final fixture = PdaHardEdgeFixture.fromJson(raw);
          final errors = fixture.pda.validate();
          return fixture.property == 'invalid-model'
              ? errors.isNotEmpty
              : errors.isEmpty;
        } on Object {
          return false;
        }
      },
      isApplicable: (raw) async {
        try {
          return await isApplicable(PdaHardEdgeFixture.fromJson(raw));
        } on Object {
          return false;
        }
      },
    );

final class _PdaHardEdgeJsonShrinker implements DomainShrinker<Object?> {
  const _PdaHardEdgeJsonShrinker();

  @override
  Iterable<Object?> candidates(Object? value) sync* {
    final fixture = PdaHardEdgeFixture.fromJson(value);
    for (final candidate in pdaFixtureShrinker.candidates(fixture)) {
      yield candidate.toJson();
    }
  }
}

/// Adapter for registering PDA cases in the shared hard-edge runner.
///
/// Each catalog case selects one algorithm/property pair from
/// [pdaHardEdgeCaseDescriptors], so the central report retains granular
/// algorithm, property, and seed coverage.
final class PdaHardEdgePropertyExecutor
    implements HardEdgeGeneratedPropertyExecutor {
  const PdaHardEdgePropertyExecutor();

  @override
  Future<Object?> materialize(
    HardEdgeCatalogCase template,
    Object? templateFixture,
    int seed,
  ) async {
    _validateDescriptor(template);
    return materializePdaPropertyFixture(
      property: template.property,
      seed: seed,
    ).toJson();
  }

  @override
  Future<HardEdgeExecutionOutcome> execute(
    HardEdgeCatalogCase testCase,
    Object? fixture,
  ) async {
    _validateDescriptor(testCase);
    final materialized = PdaHardEdgeFixture.fromJson(fixture);
    final check = await const PdaCertificationRunner().runProperty(
      property: testCase.property,
      fixture: materialized,
    );
    if (!check.algorithmIds.contains(testCase.algorithm)) {
      throw FormatException(
        'PDA property ${testCase.property} does not certify algorithm '
        '${testCase.algorithm}.',
      );
    }
    return switch (check.status) {
      PdaCertificationStatus.passed => HardEdgeExecutionOutcome.pass,
      PdaCertificationStatus.failed => HardEdgeExecutionOutcome.violation,
      PdaCertificationStatus.inconclusive => HardEdgeExecutionOutcome.bounded,
    };
  }

  static void _validateDescriptor(HardEdgeCatalogCase testCase) {
    final supported = pdaHardEdgeCaseDescriptors.any(
      (descriptor) =>
          descriptor.algorithm == testCase.algorithm &&
          descriptor.property == testCase.property,
    );
    if (testCase.family != 'pda' || !supported) {
      throw FormatException(
        'Unsupported PDA hard-edge case ${testCase.algorithm}/'
        '${testCase.property}.',
      );
    }
  }
}

final class PdaHardEdgeMutationExecutor implements HardEdgeMutationExecutor {
  const PdaHardEdgeMutationExecutor();

  @override
  Future<HardEdgeMutationStatus> execute(
    HardEdgeMutation mutation,
    Object? fixture,
  ) async {
    if (mutation.family != 'pda') {
      throw FormatException(
        'Unsupported mutation family "${mutation.family}".',
      );
    }
    final operator = pdaMutationProbeDescriptors[mutation.operatorId];
    if (operator == null) {
      throw FormatException(
        'Unknown PDA mutation operator "${mutation.operatorId}".',
      );
    }
    final materialized = PdaHardEdgeFixture.fromJson(fixture);
    final evidence = evaluatePdaProductionMutation(materialized, operator);
    if (!evidence.originalOracle.isDefinitive ||
        !evidence.canonicalProduction.isDefinitive ||
        !evidence.mutantProduction.isDefinitive) {
      return HardEdgeMutationStatus.notRun;
    }
    return evidence.killed
        ? HardEdgeMutationStatus.killed
        : HardEdgeMutationStatus.survived;
  }
}
