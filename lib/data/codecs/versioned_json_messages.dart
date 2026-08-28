import '../../core/messages/structured_message.dart';

/// Locale-neutral messages emitted by the shared Turing Lab JSON envelope.
///
/// The envelope is used by several document codecs. Keeping these payloads in
/// one companion prevents each codec from having to duplicate the same
/// envelope diagnostics while legacy prose remains available to callers.
abstract final class VersionedJsonMessages {
  static const namespace = 'codec.turing-lab-json';

  static StructuredMessage invalidUtf8() => _error('invalid-utf8');

  static StructuredMessage rootMustBeObject() => _error('root-must-be-object');

  static StructuredMessage malformedJson() => _error('malformed-json');

  static StructuredMessage unsupportedDocument() =>
      _unsupported('unsupported-document');

  static StructuredMessage legacyEnvelopeMigrated() =>
      _information('legacy-envelope-migrated');

  static StructuredMessage unknownLegacyField(String field) => _information(
    'unknown-field-preserved',
    arguments: {
      'scope': StructuredMessageArgument.literal(
        'legacy-payload',
        role: 'json-scope',
      ),
      'field': StructuredMessageArgument.literal(field, role: 'json-field'),
    },
  );

  static StructuredMessage envelopeVersionInvalid() =>
      _error('envelope-version-invalid');

  static StructuredMessage unsupportedEnvelopeVersion(int version) =>
      _unsupported(
        'unsupported-envelope-version',
        arguments: {
          'version': StructuredMessageArgument.integer(
            version,
            role: 'envelope-version',
          ),
        },
      );

  static StructuredMessage missingDocument() => _error('missing-document');

  static StructuredMessage documentKeyMismatch(String systemKey) =>
      _unsupported(
        'document-key-mismatch',
        arguments: {
          'system': StructuredMessageArgument.literal(
            systemKey,
            role: 'formal-system',
          ),
        },
      );

  static StructuredMessage missingSchema() => _error('missing-schema');

  static StructuredMessage schemaIdentityInvalid() =>
      _error('schema-identity-invalid');

  static StructuredMessage unsupportedSchemaVersion(int version) =>
      _unsupported(
        'unsupported-schema-version',
        arguments: {
          'version': StructuredMessageArgument.integer(
            version,
            role: 'schema-version',
          ),
        },
      );

  static StructuredMessage missingPayload() => _error('missing-payload');

  static StructuredMessage sourceMetadataInvalid() =>
      _error('source-metadata-invalid');

  static StructuredMessage sourceFieldInvalid(String field) => _error(
    'source-field-invalid',
    arguments: {
      'field': StructuredMessageArgument.literal(field, role: 'metadata-field'),
    },
  );

  static StructuredMessage extensionsInvalid() => _error('extensions-invalid');

  static StructuredMessage migrationPathMissing(int version) => _unsupported(
    'migration-path-missing',
    arguments: {
      'version': StructuredMessageArgument.integer(
        version,
        role: 'schema-version',
      ),
    },
  );

  static StructuredMessage migrationRejected() => _error('migration-rejected');

  static StructuredMessage migrationInvalidValue() =>
      _error('migration-invalid-value');

  static StructuredMessage migrationFailed() => _error('migration-failed');

  static StructuredMessage schemaMigrated({
    required int fromVersion,
    required int toVersion,
  }) => _information(
    'schema-migrated',
    arguments: {
      'from': StructuredMessageArgument.integer(
        fromVersion,
        role: 'from-schema-version',
      ),
      'to': StructuredMessageArgument.integer(
        toVersion,
        role: 'to-schema-version',
      ),
    },
  );

  static StructuredMessage extensionKeysInvalid() =>
      _error('extension-keys-invalid');

  static StructuredMessage unknownFieldPreserved({
    required String scope,
    required String field,
  }) => _information(
    'unknown-field-preserved',
    arguments: {
      'scope': StructuredMessageArgument.literal(scope, role: 'json-scope'),
      'field': StructuredMessageArgument.literal(field, role: 'json-field'),
    },
  );

  static StructuredMessage payloadValueTypeInvalid() =>
      _error('payload-value-type-invalid');

  static StructuredMessage decoderValueTypeInvalid() =>
      _error('decoder-value-type-invalid');

  static StructuredMessage decoderFailed() => _error('decoder-failed');

  static StructuredMessage encodeDocumentMismatch(String systemKey) =>
      _unsupported(
        'encode-document-mismatch',
        arguments: {
          'system': StructuredMessageArgument.literal(
            systemKey,
            role: 'formal-system',
          ),
        },
      );

  static StructuredMessage encodeSchemaUnsupported() =>
      _unsupported('encode-schema-unsupported');

  static StructuredMessage encodeValueInvalid() =>
      _error('encode-value-invalid');

  static StructuredMessage encoderFailed() => _error('encoder-failed');

  static StructuredMessage sourceMetadataNormalized() =>
      _information('source-metadata-normalized');

  static StructuredMessage unknownFieldsSidecarNormalized() =>
      _information('unknown-fields-sidecar-normalized');

  static StructuredMessage envelopeSerializationFailed() =>
      _error('envelope-serialization-failed');

  static StructuredMessage _unsupported(
    String code, {
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => _message(
    code,
    severity: StructuredMessageSeverity.error,
    arguments: arguments,
  );

  static StructuredMessage _error(
    String code, {
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => _message(
    code,
    severity: StructuredMessageSeverity.error,
    arguments: arguments,
  );

  static StructuredMessage _information(
    String code, {
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => _message(
    code,
    severity: StructuredMessageSeverity.information,
    arguments: arguments,
  );

  static StructuredMessage _message(
    String code, {
    required StructuredMessageSeverity severity,
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => StructuredMessage(
    namespace: namespace,
    code: code,
    category: StructuredMessageCategory.interoperability,
    severity: severity,
    arguments: arguments,
  );
}
