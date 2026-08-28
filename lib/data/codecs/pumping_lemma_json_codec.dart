import 'dart:convert';

import '../../core/formal_systems/formal_systems.dart';
import '../../core/interoperability/interoperability.dart';
import '../../core/pumping_lemma/pumping_lemma.dart';
import 'codec_json_security.dart';
import 'codec_utils.dart';

final class PumpingLemmaJsonCodec implements DocumentCodecCapability<Object> {
  const PumpingLemmaJsonCodec._({
    required this.theorem,
    required this.systemKey,
    required this.schema,
    required this.codecId,
    required this.namespace,
    required this.fixture,
  });

  const PumpingLemmaJsonCodec.regular()
      : this._(
          theorem: PumpingLemmaTheorem.regular,
          systemKey: DefaultFormalSystemIds.regularPumping,
          schema: const DocumentSchemaDescriptor(
            id: DocumentSchemaId('turing-lab.pumping-lemma.regular'),
            version: DocumentSchemaVersion(1),
          ),
          codecId: const DocumentCodecId(
            'pumping-lemma.regular.turing-lab-json.v1',
          ),
          namespace: const CapabilityNamespaceId(
            'codec.pumping-lemma.regular.turing-lab-json',
          ),
          fixture:
              'test/fixtures/interoperability/pumping_lemma_regular_canonical.json',
        );

  const PumpingLemmaJsonCodec.contextFree()
      : this._(
          theorem: PumpingLemmaTheorem.contextFree,
          systemKey: DefaultFormalSystemIds.contextFreePumping,
          schema: const DocumentSchemaDescriptor(
            id: DocumentSchemaId('turing-lab.pumping-lemma.context-free'),
            version: DocumentSchemaVersion(1),
          ),
          codecId: const DocumentCodecId(
            'pumping-lemma.context-free.turing-lab-json.v1',
          ),
          namespace: const CapabilityNamespaceId(
            'codec.pumping-lemma.context-free.turing-lab-json',
          ),
          fixture:
              'test/fixtures/interoperability/pumping_lemma_context_free_canonical.json',
        );

  final PumpingLemmaTheorem theorem;
  final FormalSystemKey systemKey;
  final DocumentSchemaDescriptor schema;
  final DocumentCodecId codecId;
  final CapabilityNamespaceId namespace;
  final String fixture;

  @override
  CodecDescriptor get descriptor => CodecDescriptor(
        codecId: codecId,
        namespace: namespace,
        systemKey: systemKey,
        formatId: DefaultFormalSystemIds.turingLabJsonFormat,
        schemas: DocumentSchemaRange(minimum: 1, maximum: 1),
        directions: const {
          DocumentFormatDirection.importDocument,
          DocumentFormatDirection.exportDocument,
        },
        priority: 110,
        compatibilityOwner: 'Turing Lab pumping lemma JSON',
        canonicalFixtures: [fixture],
        semanticCapabilities: {
          CodecSemanticCapabilityId.tokenVectors,
          CodecSemanticCapabilityId.extensions,
        },
        knownUnsupportedFields: const {},
      );

  @override
  CodecSniffResult sniff(DocumentPayload payload) {
    if (payload.bytes.length > descriptor.securityLimits.maximumBytes) {
      return CodecSniffResult.none;
    }
    try {
      final source = utf8Payload(payload);
      if (codecJsonLexicalDepth(source) >
          descriptor.securityLimits.maximumDepth) {
        return CodecSniffResult.none;
      }
      final decoded = jsonDecode(source);
      if (decoded is! Map) return CodecSniffResult.none;
      final schema = decoded['schema'];
      final problem = decoded['problem'];
      if (schema is Map &&
          schema['id'] == 'turing-lab.pumping-lemma' &&
          schema['version'] == 1 &&
          problem is Map &&
          problem['theorem'] == theorem.name) {
        return CodecSniffResult(
          confidence: 100,
          detectedSystem: systemKey,
          detectedSchemaVersion: 1,
        );
      }
    } catch (_) {}
    return CodecSniffResult.none;
  }

  @override
  CodecOutcome<InteroperableDocument<Object>> decode(DocumentPayload payload) {
    if (payload.bytes.length > descriptor.securityLimits.maximumBytes) {
      return CodecResourceLimit(
        limit: CodecResourceLimitKind.bytes,
        maximum: descriptor.securityLimits.maximumBytes,
        actual: payload.bytes.length,
      );
    }
    try {
      final source = utf8Payload(payload);
      final depth = codecJsonLexicalDepth(source);
      if (depth > descriptor.securityLimits.maximumDepth) {
        return CodecResourceLimit(
          limit: CodecResourceLimitKind.jsonDepth,
          maximum: descriptor.securityLimits.maximumDepth,
          actual: depth,
        );
      }
      final decoded = jsonDecode(source);
      final entries = codecJsonCollectionEntries(decoded);
      if (entries > descriptor.securityLimits.maximumCollectionEntries) {
        return CodecResourceLimit(
          limit: CodecResourceLimitKind.collectionEntries,
          maximum: descriptor.securityLimits.maximumCollectionEntries,
          actual: entries,
        );
      }
      if (decoded is! Map) {
        return const CodecMalformed(
          reason: CodecMalformedReason.invalidValue,
          message: 'Pumping lemma JSON must be an object.',
        );
      }
      final map = Map<String, Object?>.from(decoded);
      final rawSchema = map['schema'];
      if (rawSchema is! Map) {
        return const CodecMalformed(
          reason: CodecMalformedReason.invalidValue,
          message: 'Pumping lemma schema must be an object.',
          location: CodecSourceLocation(path: r'$.schema'),
        );
      }
      final schemaId = rawSchema['id'];
      final schemaVersion = rawSchema['version'];
      if (schemaId is! String || schemaVersion is! int || schemaVersion <= 0) {
        return const CodecMalformed(
          reason: CodecMalformedReason.invalidValue,
          message: 'Pumping lemma schema identity and version are invalid.',
          location: CodecSourceLocation(path: r'$.schema'),
        );
      }
      if (schemaId != 'turing-lab.pumping-lemma' || schemaVersion != 1) {
        return const CodecUnsupported(
          reason: CodecUnsupportedReason.schema,
          message: 'Unsupported pumping lemma schema.',
        );
      }
      final document = PumpingLemmaDocument.fromJson(map);
      if (document.theorem != theorem) {
        return const CodecUnsupported(
          reason: CodecUnsupportedReason.document,
          message: 'The pumping lemma theorem does not match this workspace.',
        );
      }
      final storedSession = map['session'];
      final boundedSessionNormalized = storedSession is Map &&
          storedSession['pumpExponent'] != null &&
          document.erasedSession.pumpExponent == null &&
          document.erasedSession.stage == PumpingLemmaStage.awaitingExponent;
      return CodecSuccess(
        value: InteroperableDocument<Object>(
          document: document,
          systemKey: systemKey,
          schema: schema,
          extensions: DocumentExtensionBag({
            for (final entry in map.entries)
              if (!_pumpingLemmaDocumentFields.contains(entry.key))
                entry.key: entry.value,
          }),
        ),
        fidelity: boundedSessionNormalized
            ? DocumentFidelity.normalized
            : DocumentFidelity.exact,
        diagnostics: [
          if (boundedSessionNormalized)
            const CodecDiagnostic(
              code: 'pumping.session.bounded-exponent-reset',
              message: 'The stored exponent exceeded the current pumped-word '
                  'limit and was reset so it can be chosen again.',
              path: r'$.session.pumpExponent',
              disposition: CodecDiagnosticDisposition.normalized,
            ),
        ],
      );
    } on FormatException catch (error) {
      return CodecMalformed(
        reason: CodecMalformedReason.invalidValue,
        message: error.message,
        cause: error,
      );
    } catch (error) {
      return CodecMalformed(
        reason: CodecMalformedReason.invalidValue,
        message: 'Malformed pumping lemma JSON.',
        cause: error,
      );
    }
  }

  @override
  CodecOutcome<EncodedDocument> encode(
    InteroperableDocument<Object> document, {
    String? filename,
  }) {
    if (document.systemKey != systemKey ||
        document.schema != schema ||
        document.document is! PumpingLemmaDocument) {
      return const CodecUnsupported(
        reason: CodecUnsupportedReason.document,
        message: 'Expected a pumping lemma document for this workspace.',
      );
    }
    final pumping = document.document as PumpingLemmaDocument;
    if (pumping.theorem != theorem) {
      return const CodecUnsupported(
        reason: CodecUnsupportedReason.document,
        message: 'The pumping lemma theorem does not match this workspace.',
      );
    }
    final payload = <String, Object?>{
      ...pumping.toJson(),
      for (final entry in document.extensions.values.entries)
        if (!_pumpingLemmaDocumentFields.contains(entry.key))
          entry.key: entry.value,
    };
    return CodecSuccess(
      value: EncodedDocument(
        bytes: utf8Bytes('${canonicalJson(payload)}\n'),
        mimeType: 'application/json',
        filename: filenameWithExtension(
          filename,
          theorem == PumpingLemmaTheorem.regular
              ? 'regular-pumping-lemma'
              : 'context-free-pumping-lemma',
          'json',
        ),
        schema: schema,
      ),
      fidelity: DocumentFidelity.exact,
    );
  }
}

const _pumpingLemmaDocumentFields = {
  'schema',
  'problem',
  'session',
  'progress',
};
