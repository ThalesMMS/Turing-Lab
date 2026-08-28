import 'package:collection/collection.dart';

import '../../core/formal_systems/formal_systems.dart';
import '../../core/interoperability/interoperability.dart';
import '../../core/transducers/transducers.dart';
import 'mealy_json_messages.dart';
import 'mealy_jflap_codec.dart';
import 'versioned_json_document_codec.dart';

final class MealyJsonDocumentCodec implements DocumentCodecCapability<Object> {
  MealyJsonDocumentCodec()
    : _delegate = VersionedJsonDocumentCodec(
        systemKey: TransducerFormalSystemIds.mealy,
        schema: MealyJflapDocumentCodec.schema,
        codecId: const DocumentCodecId('mealy.turing-lab-json.v1'),
        namespace: const CapabilityNamespaceId(
          'codec.transducer.mealy.turing-lab-json',
        ),
        fixture: 'test/fixtures/interoperability/mealy_canonical.json',
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
          CodecSemanticCapabilityId.transitionOutputs,
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
    if (document is! MealyMachine) {
      return CodecInternalFailure(
        stage: CodecInternalFailureStage.decode,
        message: 'Mealy JSON decoder returned an unexpected document type.',
        structuredMessage: MealyJsonMessages.unexpectedDocumentType(),
      );
    }
    final invalid = _firstMealyError(document);
    return invalid ?? outcome;
  }

  @override
  CodecOutcome<EncodedDocument> encode(
    InteroperableDocument<Object> document, {
    String? filename,
  }) {
    final machine = document.document;
    if (machine is MealyMachine) {
      final invalid = _firstMealyError(machine);
      if (invalid != null) return invalid;
    }
    return _delegate.encode(document, filename: filename);
  }

  static Map<String, Object?> _encodePayload(Object document) {
    if (document is! MealyMachine) {
      throw const FormatException('Expected a Mealy machine.');
    }
    return document.toJson();
  }

  static Object _decodePayload(Map<String, dynamic> payload) =>
      MealyMachine.fromJson(payload);

  static bool _isLegacyPayload(Map<String, dynamic> payload) {
    final schema = payload['schema'];
    return schema is Map && schema['id'] == 'turing-lab.mealy';
  }
}

CodecMalformed<Never>? _firstMealyError(MealyMachine machine) {
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
    message: 'Invalid Mealy machine: ${diagnostic.code.name}.',
    location: CodecSourceLocation(
      path: r'$.document.payload.' + diagnostic.subject,
    ),
    structuredMessage: MealyJsonMessages.invalidDocument(diagnostic.code.name),
  );
}
