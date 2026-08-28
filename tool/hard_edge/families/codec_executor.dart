import 'dart:async';

import '../catalog.dart';
import '../dispatch.dart';
import '../mutation.dart';
import '../runner.dart';
import '../shrinking.dart';
import 'codec_certification.dart';
import 'codec_family.dart';
import 'codec_matrix.dart';
import 'codec_mutations.dart';

const codecFixtureShrinker = CodecFixtureShrinker();

typedef CodecHardEdgeShrinkApplicability = FutureOr<bool> Function(
  CodecHardEdgeFixture fixture,
);

HardEdgeShrinkAdapter codecHardEdgeShrinkAdapter({
  required CodecHardEdgeShrinkApplicability isApplicable,
}) =>
    HardEdgeShrinkAdapter(
      shrinker: const _CodecHardEdgeJsonShrinker(),
      isValid: (raw) {
        try {
          CodecHardEdgeFixture.fromJson(raw);
          return true;
        } on Object {
          return false;
        }
      },
      isApplicable: (raw) async {
        try {
          final fixture = CodecHardEdgeFixture.fromJson(raw);
          final expectedSignature = fixture.payload['failureSignature'];
          if (expectedSignature is! String || !await isApplicable(fixture)) {
            return false;
          }
          final check = await CodecCertificationRunner().runProperty(fixture);
          return check.status == CodecCertificationStatus.failed &&
              check.failureSignature == expectedSignature;
        } on Object {
          return false;
        }
      },
    );

final class _CodecHardEdgeJsonShrinker implements DomainShrinker<Object?> {
  const _CodecHardEdgeJsonShrinker();

  @override
  Iterable<Object?> candidates(Object? value) sync* {
    final fixture = CodecHardEdgeFixture.fromJson(value);
    for (final candidate in codecFixtureShrinker.candidates(fixture)) {
      yield candidate.toJson();
    }
  }
}

final class CodecHardEdgePropertyExecutor
    implements HardEdgeGeneratedPropertyExecutor {
  const CodecHardEdgePropertyExecutor();

  @override
  Future<Object?> materialize(
    HardEdgeCatalogCase template,
    Object? templateFixture,
    int seed,
  ) async {
    _validateDescriptor(template);
    return materializeCodecPropertyFixture(
      codecId: template.algorithm,
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
    final check = await CodecCertificationRunner().runProperty(
      CodecHardEdgeFixture.fromJson(fixture),
    );
    return switch (check.status) {
      CodecCertificationStatus.passed => HardEdgeExecutionOutcome.pass,
      CodecCertificationStatus.failed => HardEdgeExecutionOutcome.violation,
      CodecCertificationStatus.inconclusive => HardEdgeExecutionOutcome.bounded,
    };
  }

  static void _validateDescriptor(HardEdgeCatalogCase testCase) {
    final supported = codecHardEdgeCaseDescriptors.any(
      (descriptor) =>
          descriptor.algorithm == testCase.algorithm &&
          descriptor.property == testCase.property,
    );
    if (testCase.family != 'codec' || !supported) {
      throw FormatException(
        'Unsupported codec hard-edge case '
        '${testCase.algorithm}/${testCase.property}.',
      );
    }
  }
}

final class CodecHardEdgeMutationExecutor implements HardEdgeMutationExecutor {
  const CodecHardEdgeMutationExecutor();

  @override
  Future<HardEdgeMutationStatus> execute(
    HardEdgeMutation mutation,
    Object? fixture,
  ) async {
    if (mutation.family != 'codec') {
      throw FormatException('Unsupported mutation family ${mutation.family}.');
    }
    final operator = codecMutationOperators[mutation.operatorId];
    if (operator == null) {
      throw FormatException(
        'Unknown codec mutation operator ${mutation.operatorId}.',
      );
    }
    final evidence = await evaluateCodecProductionMutation(operator);
    return evidence.killed
        ? HardEdgeMutationStatus.killed
        : HardEdgeMutationStatus.survived;
  }
}
