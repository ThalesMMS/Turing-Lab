import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/formal_systems/formal_systems.dart';
import 'package:turing_lab/core/interoperability/interoperability.dart';
import 'package:turing_lab/core/messages/structured_message.dart';
import 'package:turing_lab/data/codecs/versioned_json_document_codec.dart';
import 'package:turing_lab/data/codecs/versioned_json_messages.dart';

void main() {
  test('envelope failures expose locale-neutral structured payloads', () {
    final codec = _codec();

    final root = codec.decode(_payload('[]'));
    expect(
      (root as CodecMalformed<InteroperableDocument<Object>>)
          .structuredMessage
          ?.stableCode,
      'codec.turing-lab-json.root-must-be-object',
    );

    final malformed = codec.decode(_payload('{'));
    expect(
      (malformed as CodecMalformed<InteroperableDocument<Object>>)
          .structuredMessage
          ?.stableCode,
      'codec.turing-lab-json.malformed-json',
    );

    final future = codec.decode(
      _payload(jsonEncode(_envelope(envelopeVersion: 2))),
    );
    expect(
      (future as CodecUnsupported<InteroperableDocument<Object>>)
          .structuredMessage
          ?.arguments['version']
          ?.value,
      2,
    );
  });

  test('legacy migration diagnostics retain typed structured peers', () {
    final codec = _codec(isLegacy: true);
    final outcome =
        codec.decode(
              _payload(jsonEncode({'value': 'legacy', 'vendorField': true})),
            )
            as CodecSuccess<InteroperableDocument<Object>>;

    expect(outcome.fidelity, DocumentFidelity.normalized);
    expect(
      outcome.diagnostics.map(
        (diagnostic) => diagnostic.structuredMessage?.stableCode,
      ),
      containsAll(<String>[
        'codec.turing-lab-json.legacy-envelope-migrated',
        'codec.turing-lab-json.unknown-field-preserved',
      ]),
    );
    final unknown = outcome.diagnostics.last.structuredMessage!;
    expect(unknown.arguments['field']?.value, 'vendorField');
  });

  test('decoder and encoder failures preserve structured contracts', () {
    final decodingCodec = _codec(decodePayload: (_) => throw TypeError());
    final decoded =
        decodingCodec.decode(_payload(jsonEncode(_envelope())))
            as CodecMalformed<InteroperableDocument<Object>>;
    expect(
      decoded.structuredMessage?.stableCode,
      'codec.turing-lab-json.payload-value-type-invalid',
    );

    final codec = _codec();
    final wrongDocument =
        codec.encode(
              InteroperableDocument<Object>(
                document: const {},
                systemKey: DefaultFormalSystemIds.regex,
                schema: _schema,
              ),
            )
            as CodecUnsupported<EncodedDocument>;
    expect(
      wrongDocument.structuredMessage?.stableCode,
      'codec.turing-lab-json.encode-document-mismatch',
    );
  });

  test('companion factories are stable and JSON round-trippable', () {
    final messages = <StructuredMessage>[
      VersionedJsonMessages.invalidUtf8(),
      VersionedJsonMessages.unknownFieldPreserved(
        scope: 'payload',
        field: 'vendor',
      ),
      VersionedJsonMessages.schemaMigrated(fromVersion: 1, toVersion: 2),
      VersionedJsonMessages.encodeDocumentMismatch('fsa'),
    ];

    for (final message in messages) {
      expect(StructuredMessage.fromJson(message.toJson()), message);
    }
  });
}

const _schema = DocumentSchemaDescriptor(
  id: DocumentSchemaId('turing-lab.fsa'),
  version: DocumentSchemaVersion(1),
);

VersionedJsonDocumentCodec _codec({
  bool isLegacy = false,
  Object Function(Map<String, dynamic>)? decodePayload,
}) => VersionedJsonDocumentCodec(
  systemKey: DefaultFormalSystemIds.fsa,
  schema: _schema,
  codecId: const DocumentCodecId('test.versioned-json'),
  namespace: const CapabilityNamespaceId('codec.test.versioned-json'),
  fixture: 'test/fixtures/interoperability/fsa_canonical.json',
  encodePayload: (document) => document as Map<String, Object?>,
  decodePayload: decodePayload ?? (payload) => payload,
  isLegacyPayload: isLegacy
      ? (payload) => payload['value'] is String
      : (_) => false,
  knownPayloadFields: const {'value'},
);

DocumentPayload _payload(String source) =>
    DocumentPayload(bytes: utf8.encode(source), filename: 'document.json');

Map<String, Object?> _envelope({int envelopeVersion = 1}) => {
  'format': VersionedJsonDocumentCodec.envelopeFormat,
  'envelopeVersion': envelopeVersion,
  'document': {
    'type': DefaultFormalSystemIds.fsa.type.value,
    'variant': DefaultFormalSystemIds.fsa.variant.value,
    'schema': {'id': _schema.id.value, 'version': _schema.version.value},
    'payload': {'value': 'ok'},
  },
};
