import 'dart:convert';

import '../../core/formal_systems/formal_systems.dart';
import '../../core/interoperability/interoperability.dart';
import 'codec_json_security.dart';
import 'codec_utils.dart';
import 'versioned_json_messages.dart';

final class VersionedJsonDocumentCodec
    implements DocumentCodecCapability<Object> {
  VersionedJsonDocumentCodec({
    required this.systemKey,
    required this.schema,
    required this.codecId,
    required this.namespace,
    required this.fixture,
    required this.encodePayload,
    required this.decodePayload,
    required this.isLegacyPayload,
    required Set<String> knownPayloadFields,
    Set<CodecSemanticCapabilityId>? semanticCapabilities,
    List<DocumentMigrationStep<Map<String, dynamic>>> migrations = const [],
  }) : knownPayloadFields = Set<String>.unmodifiable(knownPayloadFields),
       semanticCapabilities = Set<CodecSemanticCapabilityId>.unmodifiable(
         semanticCapabilities ?? _defaultSemanticCapabilities,
       ),
       migrations = _validateMigrations(migrations, schema.version.value);

  static const envelopeFormat = 'turing-lab.document';
  static const envelopeVersion = 1;

  final FormalSystemKey systemKey;
  final DocumentSchemaDescriptor schema;
  final DocumentCodecId codecId;
  final CapabilityNamespaceId namespace;
  final String fixture;
  final Map<String, Object?> Function(Object document) encodePayload;
  final Object Function(Map<String, dynamic> payload) decodePayload;
  final bool Function(Map<String, dynamic> payload) isLegacyPayload;
  final Set<String> knownPayloadFields;
  final Set<CodecSemanticCapabilityId> semanticCapabilities;
  final List<DocumentMigrationStep<Map<String, dynamic>>> migrations;

  @override
  late final CodecDescriptor descriptor = CodecDescriptor(
    codecId: codecId,
    namespace: namespace,
    systemKey: systemKey,
    formatId: DefaultFormalSystemIds.turingLabJsonFormat,
    schemas: DocumentSchemaRange(
      minimum: migrations.isEmpty
          ? schema.version.value
          : migrations
                .map((migration) => migration.fromVersion.value)
                .reduce((left, right) => left < right ? left : right),
      maximum: schema.version.value,
    ),
    directions: const {
      DocumentFormatDirection.importDocument,
      DocumentFormatDirection.exportDocument,
    },
    priority: 100,
    compatibilityOwner: 'Turing Lab interoperability',
    canonicalFixtures: [fixture],
    semanticCapabilities: semanticCapabilities,
    knownUnsupportedFields: const {},
  );

  static final _defaultSemanticCapabilities = <CodecSemanticCapabilityId>{
    CodecSemanticCapabilityId.stateIds,
    CodecSemanticCapabilityId.stateNames,
    CodecSemanticCapabilityId.statePositions,
    CodecSemanticCapabilityId.initialStates,
    CodecSemanticCapabilityId.acceptingStates,
    CodecSemanticCapabilityId.transitionLabels,
    CodecSemanticCapabilityId.tokenVectors,
    CodecSemanticCapabilityId.extensions,
  };

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
      final json = decoded.cast<String, dynamic>();
      if (json['format'] == envelopeFormat) {
        final document = json['document'];
        if (document is! Map) return CodecSniffResult.none;
        final type = document['type'];
        final variant = document['variant'];
        if (type == systemKey.type.value &&
            variant == systemKey.variant.value) {
          final schemaJson = document['schema'];
          final version = schemaJson is Map
              ? schemaJson['version'] as int?
              : null;
          return CodecSniffResult(
            confidence: 100,
            detectedSystem: systemKey,
            // Future versions still belong to this codec family. Leave the
            // unsupported version for decode to report as a typed schema
            // outcome instead of presenting it as a broken codec contract.
            detectedSchemaVersion:
                version != null && descriptor.schemas.contains(version)
                ? version
                : null,
          );
        }
        return CodecSniffResult.none;
      }
      return isLegacyPayload(json)
          ? CodecSniffResult(
              confidence: 60,
              detectedSystem: systemKey,
              detectedSchemaVersion: schema.version.value,
            )
          : CodecSniffResult.none;
    } catch (_) {
      return CodecSniffResult.none;
    }
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
    late final String source;
    try {
      source = utf8Payload(payload);
    } on FormatException catch (error) {
      return CodecMalformed(
        reason: CodecMalformedReason.invalidUtf8,
        message: 'JSON is not valid UTF-8.',
        location: CodecSourceLocation(offset: error.offset),
        cause: error,
        structuredMessage: VersionedJsonMessages.invalidUtf8(),
      );
    }
    final lexicalDepth = _jsonDepth(source);
    if (lexicalDepth > descriptor.securityLimits.maximumDepth) {
      return CodecResourceLimit(
        limit: CodecResourceLimitKind.jsonDepth,
        maximum: descriptor.securityLimits.maximumDepth,
        actual: lexicalDepth,
      );
    }
    late final Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map) {
        return CodecMalformed(
          reason: CodecMalformedReason.invalidValue,
          message: 'Document JSON root must be an object.',
          location: const CodecSourceLocation(path: r'$'),
          structuredMessage: VersionedJsonMessages.rootMustBeObject(),
        );
      }
      json = decoded.cast<String, dynamic>();
    } on FormatException catch (error) {
      return CodecMalformed(
        reason: CodecMalformedReason.syntax,
        message: 'Malformed JSON document.',
        location: CodecSourceLocation(offset: error.offset, path: r'$'),
        cause: error,
        structuredMessage: VersionedJsonMessages.malformedJson(),
      );
    }
    final entries = _collectionEntries(json);
    if (entries > descriptor.securityLimits.maximumCollectionEntries) {
      return CodecResourceLimit(
        limit: CodecResourceLimitKind.collectionEntries,
        maximum: descriptor.securityLimits.maximumCollectionEntries,
        actual: entries,
      );
    }

    if (json['format'] != envelopeFormat) {
      if (!isLegacyPayload(json)) {
        return CodecUnsupported(
          reason: CodecUnsupportedReason.document,
          message: 'JSON payload is not a recognized Turing Lab document.',
          structuredMessage: VersionedJsonMessages.unsupportedDocument(),
        );
      }
      final legacyExtensions = <String, Object?>{};
      final legacyDiagnostics = <CodecDiagnostic>[
        CodecDiagnostic(
          code: 'json.legacy-envelope-migrated',
          message: 'Legacy unversioned JSON was migrated to envelope v1.',
          path: r'$',
          structuredMessage: VersionedJsonMessages.legacyEnvelopeMigrated(),
          disposition: CodecDiagnosticDisposition.normalized,
        ),
      ];
      for (final entry in json.entries) {
        if (knownPayloadFields.contains(entry.key)) continue;
        legacyExtensions['json.payload.${entry.key}'] = entry.value;
        legacyDiagnostics.add(
          CodecDiagnostic(
            code: 'json.unknown-field-preserved',
            message: 'An unknown legacy payload field was preserved.',
            path: r'$.' + entry.key,
            sourceValue: entry.value,
            structuredMessage: VersionedJsonMessages.unknownLegacyField(
              entry.key,
            ),
            disposition: CodecDiagnosticDisposition.normalized,
          ),
        );
      }
      return _decodePayload(
        json,
        metadata: const DocumentSourceMetadata(
          application: 'Turing Lab',
          sourceFormatVersion: 'legacy-unversioned',
        ),
        extensions: DocumentExtensionBag(legacyExtensions),
        fidelity: DocumentFidelity.normalized,
        diagnostics: legacyDiagnostics,
      );
    }
    final rawEnvelopeVersion = json['envelopeVersion'];
    if (rawEnvelopeVersion is! int || rawEnvelopeVersion <= 0) {
      return CodecMalformed(
        reason: CodecMalformedReason.invalidValue,
        message: 'Envelope version must be a positive integer.',
        location: const CodecSourceLocation(path: r'$.envelopeVersion'),
        structuredMessage: VersionedJsonMessages.envelopeVersionInvalid(),
      );
    }
    if (rawEnvelopeVersion > envelopeVersion) {
      return CodecUnsupported(
        reason: CodecUnsupportedReason.schema,
        message: 'Unsupported envelope version $rawEnvelopeVersion.',
        structuredMessage: VersionedJsonMessages.unsupportedEnvelopeVersion(
          rawEnvelopeVersion,
        ),
      );
    }
    final rawDocument = json['document'];
    if (rawDocument is! Map) {
      return CodecMalformed(
        reason: CodecMalformedReason.missingField,
        message: 'Envelope is missing its document object.',
        location: const CodecSourceLocation(path: r'$.document'),
        structuredMessage: VersionedJsonMessages.missingDocument(),
      );
    }
    final documentJson = rawDocument.cast<String, dynamic>();
    if (documentJson['type'] != systemKey.type.value ||
        documentJson['variant'] != systemKey.variant.value) {
      return CodecUnsupported(
        reason: CodecUnsupportedReason.document,
        message: 'Envelope document key does not match ${systemKey.value}.',
        structuredMessage: VersionedJsonMessages.documentKeyMismatch(
          systemKey.value,
        ),
      );
    }
    final rawSchema = documentJson['schema'];
    if (rawSchema is! Map) {
      return CodecMalformed(
        reason: CodecMalformedReason.missingField,
        message: 'Envelope is missing its schema object.',
        location: const CodecSourceLocation(path: r'$.document.schema'),
        structuredMessage: VersionedJsonMessages.missingSchema(),
      );
    }
    final schemaJson = rawSchema.cast<String, dynamic>();
    final version = schemaJson['version'];
    if (schemaJson['id'] != schema.id.value || version is! int) {
      return CodecMalformed(
        reason: CodecMalformedReason.invalidValue,
        message: 'Envelope schema identity is invalid.',
        location: const CodecSourceLocation(path: r'$.document.schema'),
        structuredMessage: VersionedJsonMessages.schemaIdentityInvalid(),
      );
    }
    if (version > schema.version.value ||
        !descriptor.schemas.contains(version)) {
      return CodecUnsupported(
        reason: CodecUnsupportedReason.schema,
        message: 'Unsupported ${systemKey.value} schema version $version.',
        structuredMessage: VersionedJsonMessages.unsupportedSchemaVersion(
          version,
        ),
      );
    }
    final rawPayload = documentJson['payload'];
    if (rawPayload is! Map) {
      return CodecMalformed(
        reason: CodecMalformedReason.missingField,
        message: 'Envelope is missing its payload object.',
        location: const CodecSourceLocation(path: r'$.document.payload'),
        structuredMessage: VersionedJsonMessages.missingPayload(),
      );
    }
    final sourceJson = json['source'];
    if (sourceJson != null && sourceJson is! Map) {
      return CodecMalformed(
        reason: CodecMalformedReason.invalidValue,
        message: 'Envelope source metadata must be an object.',
        location: const CodecSourceLocation(path: r'$.source'),
        structuredMessage: VersionedJsonMessages.sourceMetadataInvalid(),
      );
    }
    final sourceMap = sourceJson is Map
        ? sourceJson.cast<String, dynamic>()
        : const <String, dynamic>{};
    for (final field in const ['application', 'applicationVersion']) {
      if (sourceMap[field] != null && sourceMap[field] is! String) {
        return CodecMalformed(
          reason: CodecMalformedReason.invalidValue,
          message: 'Envelope source field $field must be a string.',
          location: CodecSourceLocation(path: r'$.source.' + field),
          structuredMessage: VersionedJsonMessages.sourceFieldInvalid(field),
        );
      }
    }
    final metadata = DocumentSourceMetadata(
      application: sourceMap['application'] as String?,
      applicationVersion: sourceMap['applicationVersion'] as String?,
      sourceFormatVersion: 'envelope-$rawEnvelopeVersion',
    );
    final extensionJson = json['extensions'];
    if (extensionJson != null && extensionJson is! Map) {
      return CodecMalformed(
        reason: CodecMalformedReason.invalidValue,
        message: 'Envelope extensions must be an object.',
        location: const CodecSourceLocation(path: r'$.extensions'),
        structuredMessage: VersionedJsonMessages.extensionsInvalid(),
      );
    }
    final diagnostics = <CodecDiagnostic>[];
    final originalPayloadMap = rawPayload.cast<String, dynamic>();
    var payloadMap = Map<String, dynamic>.from(originalPayloadMap);
    var migratedVersion = version;
    while (migratedVersion < schema.version.value) {
      DocumentMigrationStep<Map<String, dynamic>>? step;
      for (final candidate in migrations) {
        if (candidate.fromVersion.value == migratedVersion) {
          step = candidate;
          break;
        }
      }
      if (step == null) {
        return CodecUnsupported(
          reason: CodecUnsupportedReason.schema,
          message:
              'No migration path exists from schema version $migratedVersion.',
          structuredMessage: VersionedJsonMessages.migrationPathMissing(
            migratedVersion,
          ),
        );
      }
      try {
        payloadMap = step.migrate(Map<String, dynamic>.from(payloadMap));
      } on FormatException catch (error) {
        return CodecMalformed(
          reason: CodecMalformedReason.invalidValue,
          message: 'Document schema migration rejected the payload.',
          location: const CodecSourceLocation(path: r'$.document.payload'),
          cause: error,
          structuredMessage: VersionedJsonMessages.migrationRejected(),
        );
      } on TypeError catch (error) {
        return CodecMalformed(
          reason: CodecMalformedReason.invalidValue,
          message: 'Document schema migration received an invalid value.',
          location: const CodecSourceLocation(path: r'$.document.payload'),
          cause: error,
          structuredMessage: VersionedJsonMessages.migrationInvalidValue(),
        );
      } catch (error) {
        return CodecInternalFailure(
          stage: CodecInternalFailureStage.decode,
          message: 'Document schema migration failed.',
          cause: error,
          structuredMessage: VersionedJsonMessages.migrationFailed(),
        );
      }
      diagnostics.add(
        CodecDiagnostic(
          code: 'json.document-schema-migrated',
          message: 'The document payload was migrated to a newer schema.',
          path: r'$.document.schema.version',
          sourceValue: {'from': migratedVersion, 'to': step.toVersion.value},
          structuredMessage: VersionedJsonMessages.schemaMigrated(
            fromVersion: migratedVersion,
            toVersion: step.toVersion.value,
          ),
          disposition: CodecDiagnosticDisposition.normalized,
        ),
      );
      migratedVersion = step.toVersion.value;
    }
    final extensionValues = <String, Object?>{};
    if (extensionJson is Map) {
      try {
        extensionValues.addAll(extensionJson.cast<String, Object?>());
      } on TypeError catch (error) {
        return CodecMalformed(
          reason: CodecMalformedReason.invalidValue,
          message: 'Envelope extension keys must be strings.',
          location: const CodecSourceLocation(path: r'$.extensions'),
          cause: error,
          structuredMessage: VersionedJsonMessages.extensionKeysInvalid(),
        );
      }
    }
    for (final entry in json.entries) {
      if (!const {
        'format',
        'envelopeVersion',
        'document',
        'source',
        'extensions',
      }.contains(entry.key)) {
        extensionValues['json.envelope.${entry.key}'] = entry.value;
        diagnostics.add(
          CodecDiagnostic(
            code: 'json.unknown-field-preserved',
            message: 'An unknown envelope field was preserved.',
            path: r'$.' + entry.key,
            sourceValue: entry.value,
            structuredMessage: VersionedJsonMessages.unknownFieldPreserved(
              scope: 'envelope',
              field: entry.key,
            ),
            disposition: CodecDiagnosticDisposition.normalized,
          ),
        );
      }
    }
    for (final entry in documentJson.entries) {
      if (!const {'type', 'variant', 'schema', 'payload'}.contains(entry.key)) {
        extensionValues['json.document.${entry.key}'] = entry.value;
        diagnostics.add(
          CodecDiagnostic(
            code: 'json.unknown-field-preserved',
            message: 'An unknown document field was preserved.',
            path: r'$.document.' + entry.key,
            sourceValue: entry.value,
            structuredMessage: VersionedJsonMessages.unknownFieldPreserved(
              scope: 'document',
              field: entry.key,
            ),
            disposition: CodecDiagnosticDisposition.normalized,
          ),
        );
      }
    }
    for (final entry in schemaJson.entries) {
      if (!const {'id', 'version'}.contains(entry.key)) {
        extensionValues['json.schema.${entry.key}'] = entry.value;
        diagnostics.add(
          CodecDiagnostic(
            code: 'json.unknown-field-preserved',
            message: 'An unknown schema field was preserved.',
            path: r'$.document.schema.' + entry.key,
            sourceValue: entry.value,
            structuredMessage: VersionedJsonMessages.unknownFieldPreserved(
              scope: 'schema',
              field: entry.key,
            ),
            disposition: CodecDiagnosticDisposition.normalized,
          ),
        );
      }
    }
    for (final entry in sourceMap.entries) {
      if (!const {'application', 'applicationVersion'}.contains(entry.key)) {
        extensionValues['json.source.${entry.key}'] = entry.value;
        diagnostics.add(
          CodecDiagnostic(
            code: 'json.unknown-field-preserved',
            message: 'An unknown source metadata field was preserved.',
            path: r'$.source.' + entry.key,
            sourceValue: entry.value,
            structuredMessage: VersionedJsonMessages.unknownFieldPreserved(
              scope: 'source',
              field: entry.key,
            ),
            disposition: CodecDiagnosticDisposition.normalized,
          ),
        );
      }
    }
    for (final entry in originalPayloadMap.entries) {
      if (!knownPayloadFields.contains(entry.key)) {
        extensionValues['json.payload.${entry.key}'] = entry.value;
        diagnostics.add(
          CodecDiagnostic(
            code: 'json.unknown-field-preserved',
            message: 'An unknown payload field was preserved.',
            path: r'$.document.payload.' + entry.key,
            sourceValue: entry.value,
            structuredMessage: VersionedJsonMessages.unknownFieldPreserved(
              scope: 'payload',
              field: entry.key,
            ),
            disposition: CodecDiagnosticDisposition.normalized,
          ),
        );
      }
    }
    final extensions = DocumentExtensionBag(extensionValues);
    return _decodePayload(
      payloadMap,
      metadata: metadata,
      extensions: extensions,
      fidelity: diagnostics.isEmpty
          ? DocumentFidelity.exact
          : DocumentFidelity.normalized,
      diagnostics: diagnostics,
    );
  }

  CodecOutcome<InteroperableDocument<Object>> _decodePayload(
    Map<String, dynamic> payload, {
    required DocumentSourceMetadata metadata,
    required DocumentExtensionBag extensions,
    required DocumentFidelity fidelity,
    List<CodecDiagnostic> diagnostics = const [],
  }) {
    try {
      return CodecSuccess(
        value: InteroperableDocument<Object>(
          document: decodePayload(payload),
          systemKey: systemKey,
          schema: schema,
          sourceMetadata: metadata,
          extensions: extensions,
        ),
        fidelity: fidelity,
        diagnostics: diagnostics,
      );
    } on TypeError catch (error) {
      return CodecMalformed(
        reason: CodecMalformedReason.invalidValue,
        message: 'Document payload has an invalid value type.',
        location: const CodecSourceLocation(path: r'$.document.payload'),
        cause: error,
        structuredMessage: VersionedJsonMessages.payloadValueTypeInvalid(),
      );
    } on FormatException catch (error) {
      return CodecMalformed(
        reason: CodecMalformedReason.invalidValue,
        message: error.message,
        location: const CodecSourceLocation(path: r'$.document.payload'),
        cause: error,
        structuredMessage: VersionedJsonMessages.decoderValueTypeInvalid(),
      );
    } catch (error) {
      return CodecInternalFailure(
        stage: CodecInternalFailureStage.decode,
        message: 'Document model decoder failed.',
        cause: error,
        structuredMessage: VersionedJsonMessages.decoderFailed(),
      );
    }
  }

  @override
  CodecOutcome<EncodedDocument> encode(
    InteroperableDocument<Object> document, {
    String? filename,
  }) {
    if (document.systemKey != systemKey) {
      return CodecUnsupported(
        reason: CodecUnsupportedReason.document,
        message:
            'Codec ${codecId.value} cannot encode ${document.systemKey.value}.',
        structuredMessage: VersionedJsonMessages.encodeDocumentMismatch(
          document.systemKey.value,
        ),
      );
    }
    if (document.schema.id != schema.id ||
        document.schema.version != schema.version) {
      return CodecUnsupported(
        reason: CodecUnsupportedReason.schema,
        message: 'Unsupported ${systemKey.value} schema version.',
        structuredMessage: VersionedJsonMessages.encodeSchemaUnsupported(),
      );
    }
    late final Map<String, Object?> payload;
    try {
      payload = encodePayload(document.document);
    } on FormatException catch (error) {
      return CodecMalformed(
        reason: CodecMalformedReason.invalidValue,
        message: 'Document contains data that cannot be represented as JSON.',
        location: const CodecSourceLocation(path: r'$.document.payload'),
        cause: error,
        structuredMessage: VersionedJsonMessages.encodeValueInvalid(),
      );
    } catch (error) {
      return CodecInternalFailure(
        stage: CodecInternalFailureStage.encode,
        message: 'Document model encoder failed.',
        cause: error,
        structuredMessage: VersionedJsonMessages.encoderFailed(),
      );
    }
    try {
      final envelope = <String, Object?>{
        'format': envelopeFormat,
        'envelopeVersion': envelopeVersion,
        'document': <String, Object?>{
          'type': systemKey.type.value,
          'variant': systemKey.variant.value,
          'schema': <String, Object?>{
            'id': schema.id.value,
            'version': schema.version.value,
          },
          'payload': payload,
        },
        'source': <String, Object?>{
          'application': 'Turing Lab',
          if (document.sourceMetadata.applicationVersion != null)
            'applicationVersion': document.sourceMetadata.applicationVersion,
        },
        'extensions': document.extensions.values,
      };
      final encoded = '${canonicalJson(envelope)}\n';
      final diagnostics = <CodecDiagnostic>[];
      if ((document.sourceMetadata.application != null &&
              document.sourceMetadata.application != 'Turing Lab') ||
          document.sourceMetadata.sourceFormatVersion != null) {
        diagnostics.add(
          CodecDiagnostic(
            code: 'json.source-metadata-normalized',
            message: 'Source metadata was updated for the exported document.',
            path: r'$.source',
            structuredMessage: VersionedJsonMessages.sourceMetadataNormalized(),
            disposition: CodecDiagnosticDisposition.normalized,
          ),
        );
      }
      if (document.extensions.values.keys.any(
        (key) => key.startsWith('json.'),
      )) {
        diagnostics.add(
          CodecDiagnostic(
            code: 'json.unknown-field-sidecar-normalized',
            message: 'Unknown JSON fields were emitted in the extension bag.',
            path: r'$.extensions',
            structuredMessage:
                VersionedJsonMessages.unknownFieldsSidecarNormalized(),
            disposition: CodecDiagnosticDisposition.normalized,
          ),
        );
      }
      return CodecSuccess(
        value: EncodedDocument(
          bytes: utf8Bytes(encoded),
          mimeType: 'application/json',
          filename: filenameWithExtension(
            filename,
            systemKey.type.value,
            'json',
          ),
          schema: schema,
        ),
        fidelity: diagnostics.isEmpty
            ? DocumentFidelity.exact
            : DocumentFidelity.normalized,
        diagnostics: diagnostics,
      );
    } on FormatException catch (error) {
      return CodecMalformed(
        reason: CodecMalformedReason.invalidValue,
        message: 'Document contains data that cannot be represented as JSON.',
        location: const CodecSourceLocation(path: r'$.extensions'),
        cause: error,
        structuredMessage: VersionedJsonMessages.encodeValueInvalid(),
      );
    } catch (error) {
      return CodecInternalFailure(
        stage: CodecInternalFailureStage.encode,
        message: 'Document envelope serialization failed.',
        cause: error,
        structuredMessage: VersionedJsonMessages.envelopeSerializationFailed(),
      );
    }
  }
}

List<DocumentMigrationStep<Map<String, dynamic>>> _validateMigrations(
  List<DocumentMigrationStep<Map<String, dynamic>>> migrations,
  int currentVersion,
) {
  final bySource = <int, DocumentMigrationStep<Map<String, dynamic>>>{};
  for (final migration in migrations) {
    final from = migration.fromVersion.value;
    final to = migration.toVersion.value;
    if (to != from + 1 || to > currentVersion || bySource.containsKey(from)) {
      throw ArgumentError(
        'JSON migrations must be unique, contiguous one-version steps.',
      );
    }
    bySource[from] = migration;
  }
  final ordered = migrations.toList()
    ..sort(
      (left, right) =>
          left.fromVersion.value.compareTo(right.fromVersion.value),
    );
  for (var index = 1; index < ordered.length; index++) {
    if (ordered[index].fromVersion != ordered[index - 1].toVersion) {
      throw ArgumentError('JSON migrations must form one contiguous chain.');
    }
  }
  if (ordered.isNotEmpty && ordered.last.toVersion.value != currentVersion) {
    throw ArgumentError('JSON migration chain must end at the current schema.');
  }
  return List<DocumentMigrationStep<Map<String, dynamic>>>.unmodifiable(
    ordered,
  );
}

int _jsonDepth(String source) {
  var inString = false;
  var escaped = false;
  var depth = 0;
  var maximum = 0;
  for (final code in source.codeUnits) {
    if (inString) {
      if (escaped) {
        escaped = false;
      } else if (code == 92) {
        escaped = true;
      } else if (code == 34) {
        inString = false;
      }
      continue;
    }
    if (code == 34) {
      inString = true;
    } else if (code == 123 || code == 91) {
      depth++;
      if (depth > maximum) maximum = depth;
    } else if ((code == 125 || code == 93) && depth > 0) {
      depth--;
    }
  }
  return maximum;
}

int _collectionEntries(Object? value) {
  var count = 0;
  final pending = <Object?>[value];
  while (pending.isNotEmpty) {
    final current = pending.removeLast();
    if (current is Map) {
      count += current.length;
      pending.addAll(current.values);
    } else if (current is List) {
      count += current.length;
      pending.addAll(current);
    }
  }
  return count;
}
