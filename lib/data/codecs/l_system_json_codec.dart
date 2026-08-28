import '../../core/formal_systems/formal_systems.dart';
import '../../core/interoperability/interoperability.dart';
import '../../core/l_systems/l_systems.dart';
import 'versioned_json_document_codec.dart';

final class LSystemJsonCodec
    implements DocumentCodecCapability<LSystemDocument> {
  LSystemJsonCodec()
      : _delegate = VersionedJsonDocumentCodec(
          systemKey: LSystemFormalSystemIds.key,
          schema: const DocumentSchemaDescriptor(
            id: DocumentSchemaId('turing-lab.l-system'),
            version: DocumentSchemaVersion(1),
          ),
          codecId: const DocumentCodecId('l-system.turing-lab-json.v1'),
          namespace:
              const CapabilityNamespaceId('codec.l-system.turing-lab-json'),
          fixture: 'test/fixtures/interoperability/l_system_canonical.json',
          encodePayload: (document) {
            if (document is! LSystemDocument) {
              throw const FormatException('Expected an L-system document.');
            }
            return document.toJson();
          },
          decodePayload: (payload) => LSystemDocument.fromJson(payload),
          isLegacyPayload: (payload) {
            final schema = payload['schema'];
            return schema is Map && schema['id'] == 'turing-lab.l-system';
          },
          knownPayloadFields: const {
            'schema',
            'id',
            'name',
            'revision',
            'axiom',
            'iterations',
            'productions',
            'turtle',
            'commandMapping',
            'unsupportedVariants',
            'unsupportedMetadata',
          },
          semanticCapabilities: {
            CodecSemanticCapabilityId.tokenVectors,
            CodecSemanticCapabilityId.extensions,
          },
        );

  final VersionedJsonDocumentCodec _delegate;

  @override
  CodecDescriptor get descriptor => _delegate.descriptor;

  @override
  CodecSniffResult sniff(DocumentPayload payload) => _delegate.sniff(payload);

  @override
  CodecOutcome<InteroperableDocument<LSystemDocument>> decode(
    DocumentPayload payload,
  ) {
    final outcome = _delegate.decode(payload);
    return switch (outcome) {
      CodecSuccess<InteroperableDocument<Object>>() => CodecSuccess(
          value: InteroperableDocument(
            document: outcome.value.document as LSystemDocument,
            systemKey: outcome.value.systemKey,
            schema: outcome.value.schema,
            sourceMetadata: outcome.value.sourceMetadata,
            extensions: outcome.value.extensions,
          ),
          fidelity: outcome.fidelity,
          diagnostics: outcome.diagnostics,
        ),
      CodecUnsupported<InteroperableDocument<Object>>() => CodecUnsupported(
          reason: outcome.reason,
          message: outcome.message,
          roadmapIssue: outcome.roadmapIssue,
        ),
      CodecAmbiguous<InteroperableDocument<Object>>() =>
        CodecAmbiguous(codecIds: outcome.codecIds),
      CodecMalformed<InteroperableDocument<Object>>() => CodecMalformed(
          reason: outcome.reason,
          message: outcome.message,
          location: outcome.location,
          cause: outcome.cause,
        ),
      CodecResourceLimit<InteroperableDocument<Object>>() => CodecResourceLimit(
          limit: outcome.limit,
          maximum: outcome.maximum,
          actual: outcome.actual,
        ),
      CodecInternalFailure<InteroperableDocument<Object>>() =>
        CodecInternalFailure(
          stage: outcome.stage,
          message: outcome.message,
          cause: outcome.cause,
        ),
    };
  }

  @override
  CodecOutcome<EncodedDocument> encode(
    InteroperableDocument<LSystemDocument> document, {
    String? filename,
  }) =>
      _delegate.encode(
        InteroperableDocument<Object>(
          document: document.document,
          systemKey: document.systemKey,
          schema: document.schema,
          sourceMetadata: document.sourceMetadata,
          extensions: document.extensions,
        ),
        filename: filename,
      );
}
