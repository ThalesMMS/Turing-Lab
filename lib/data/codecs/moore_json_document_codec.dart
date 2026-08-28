import 'package:collection/collection.dart';

import '../../core/formal_systems/formal_systems.dart';
import '../../core/interoperability/interoperability.dart';
import '../../core/transducers/transducers.dart';
import 'moore_json_messages.dart';
import 'moore_jflap_document_codec.dart';
import 'versioned_json_document_codec.dart';

final class MooreJsonDocumentCodec implements DocumentCodecCapability<Object> {
  MooreJsonDocumentCodec()
    : _delegate = VersionedJsonDocumentCodec(
        systemKey: TransducerFormalSystemIds.moore,
        schema: MooreJflapDocumentCodec.schema,
        codecId: const DocumentCodecId('moore.turing-lab-json.v1'),
        namespace: const CapabilityNamespaceId(
          'codec.transducer.moore.turing-lab-json',
        ),
        fixture: 'test/fixtures/interoperability/moore_canonical.json',
        encodePayload: _encodePayload,
        decodePayload: _decodePayload,
        isLegacyPayload: _isLegacyPayload,
        knownPayloadFields: const {
          'schema',
          'id',
          'name',
          'revision',
          'inputAlphabet',
          'outputAlphabet',
          'states',
          'transitions',
        },
        semanticCapabilities: {
          CodecSemanticCapabilityId.stateIds,
          CodecSemanticCapabilityId.stateNames,
          CodecSemanticCapabilityId.statePositions,
          CodecSemanticCapabilityId.stateLabels,
          CodecSemanticCapabilityId.initialStates,
          CodecSemanticCapabilityId.transitionLabels,
          CodecSemanticCapabilityId.tokenVectors,
          CodecSemanticCapabilityId.stateOutputs,
          CodecSemanticCapabilityId.extensions,
        },
      );

  final VersionedJsonDocumentCodec _delegate;

  @override
  CodecDescriptor get descriptor => _delegate.descriptor;

  @override
  CodecSniffResult sniff(DocumentPayload payload) => _delegate.sniff(payload);

  @override
  CodecOutcome<InteroperableDocument<Object>> decode(DocumentPayload payload) {
    final outcome = _delegate.decode(payload);
    if (outcome is! CodecSuccess<InteroperableDocument<Object>>) {
      return outcome;
    }
    final document = outcome.value.document;
    if (document is! MooreMachine) {
      return CodecInternalFailure(
        stage: CodecInternalFailureStage.decode,
        message: 'Moore JSON decoder returned an unexpected document type.',
        structuredMessage: MooreJsonMessages.unexpectedDocumentType(),
      );
    }
    final invalid = _firstError(document);
    if (invalid != null) return invalid;
    return outcome;
  }

  @override
  CodecOutcome<EncodedDocument> encode(
    InteroperableDocument<Object> document, {
    String? filename,
  }) {
    final machine = document.document;
    if (machine is MooreMachine) {
      final invalid = _firstError(machine);
      if (invalid != null) return invalid;
    }
    return _delegate.encode(document, filename: filename);
  }

  static Map<String, Object?> _encodePayload(Object document) {
    if (document is! MooreMachine) {
      throw const FormatException('Expected a Moore machine.');
    }
    return document.toJson();
  }

  static Object _decodePayload(Map<String, dynamic> payload) =>
      MooreMachine.fromJson(payload);

  static bool _isLegacyPayload(Map<String, dynamic> payload) {
    final schema = payload['schema'];
    return schema is Map && schema['id'] == 'turing-lab.moore';
  }
}

CodecMalformed<Never>? _firstError(MooreMachine machine) {
  final diagnostic = TransducerAnalyzer.analyze(machine).diagnostics
      .firstWhereOrNull(
        (candidate) => candidate.severity == TransducerDiagnosticSeverity.error,
      );
  if (diagnostic == null) return null;
  return CodecMalformed(
    reason:
        diagnostic.code == TransducerDiagnosticCode.duplicateStateId ||
            diagnostic.code == TransducerDiagnosticCode.duplicateTransitionId
        ? CodecMalformedReason.duplicateIdentity
        : CodecMalformedReason.invalidValue,
    message: 'Invalid Moore machine: ${diagnostic.code.name}.',
    location: CodecSourceLocation(
      path: r'$.document.payload.' + diagnostic.subject,
    ),
    structuredMessage: MooreJsonMessages.invalidDocument(diagnostic.code.name),
  );
}
