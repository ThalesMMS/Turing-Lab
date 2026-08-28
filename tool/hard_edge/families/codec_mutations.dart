import 'dart:io';

import 'codec_certification.dart';
import 'codec_family.dart';

enum CodecMutationOperator {
  acceptFutureSchema,
  dropExtensionSidecar,
  corruptTransportCopy,
  escalateFidelity,
}

const codecMutationOperators = <String, CodecMutationOperator>{
  codecAcceptFutureSchemaMutationId: CodecMutationOperator.acceptFutureSchema,
  codecDropExtensionSidecarMutationId:
      CodecMutationOperator.dropExtensionSidecar,
  codecCorruptTransportCopyMutationId:
      CodecMutationOperator.corruptTransportCopy,
  codecEscalateFidelityMutationId: CodecMutationOperator.escalateFidelity,
};

final class CodecMutationEvidence {
  const CodecMutationEvidence({
    required this.operator,
    required this.canonicalObservation,
    required this.mutantObservation,
    required this.killed,
  });

  final CodecMutationOperator operator;
  final String canonicalObservation;
  final String mutantObservation;
  final bool killed;

  Map<String, Object?> toJson() => {
        'canonicalObservation': canonicalObservation,
        'mutantObservation': mutantObservation,
        'operator': operator.name,
        'status': killed ? 'killed' : 'survived',
      };
}

/// Runs a certification property once normally and once through a semantic
/// adapter mutation. A mutation is killed only when the canonical property
/// passes and the same property rejects the mutated observation.
Future<CodecMutationEvidence> evaluateCodecProductionMutation(
  CodecMutationOperator operator, {
  Directory? repositoryRoot,
}) async {
  final target = switch (operator) {
    CodecMutationOperator.acceptFutureSchema => (
        codecId: 'fsa.turing-lab-json.v1',
        property: 'migration-extensions',
        id: codecAcceptFutureSchemaMutationId,
      ),
    CodecMutationOperator.dropExtensionSidecar => (
        codecId: 'fsa.turing-lab-json.v1',
        property: 'migration-extensions',
        id: codecDropExtensionSidecarMutationId,
      ),
    CodecMutationOperator.corruptTransportCopy => (
        codecId: 'fsa.jflap-xml.v1',
        property: 'transport-parity',
        id: codecCorruptTransportCopyMutationId,
      ),
    CodecMutationOperator.escalateFidelity => (
        codecId: 'regex.jflap.v1',
        property: 'corpus-fidelity',
        id: codecEscalateFidelityMutationId,
      ),
  };
  final fixture = materializeCodecPropertyFixture(
    codecId: target.codecId,
    property: target.property,
    seed: 340,
    repositoryRoot: repositoryRoot,
  );
  final runner = CodecCertificationRunner(repositoryRoot: repositoryRoot);
  final canonical = await runner.runProperty(fixture);
  final mutant = await runner.runProperty(
    fixture,
    mutationOperatorId: target.id,
  );
  return CodecMutationEvidence(
    operator: operator,
    canonicalObservation: '${canonical.status.name}:${canonical.message}',
    mutantObservation: '${mutant.status.name}:${mutant.message}',
    killed: canonical.status == CodecCertificationStatus.passed &&
        mutant.status == CodecCertificationStatus.failed,
  );
}
