import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/formal_systems/formal_systems.dart';
import 'package:turing_lab/core/interoperability/interoperability.dart';
import 'package:turing_lab/core/l_systems/l_systems.dart';
import 'package:turing_lab/core/messages/structured_message.dart';
import 'package:turing_lab/data/codecs/l_system_jflap_codec.dart';
import 'package:turing_lab/data/codecs/l_system_jflap_messages.dart';

void main() {
  const codec = LSystemJflapCodec();

  group('L-system JFLAP structured outcomes', () {
    test('unsupported and missing fields retain their legacy details', () {
      final root =
          codec.decode(_payload('<not-structure/>'))
              as CodecUnsupported<InteroperableDocument<LSystemDocument>>;
      expect(root.message, 'This XML document is not a JFLAP L-system.');
      _expectRoundTrip(
        root.structuredMessage!,
        'codec.l-system-jflap.invalid-root',
      );

      final type =
          codec.decode(_payload('<structure><type>grammar</type></structure>'))
              as CodecUnsupported<InteroperableDocument<LSystemDocument>>;
      expect(type.message, 'This XML document is not a JFLAP L-system.');
      expect(
        type.structuredMessage?.arguments['type'],
        StructuredMessageArgument.literal('grammar', role: 'document-type'),
      );
      _expectRoundTrip(
        type.structuredMessage!,
        'codec.l-system-jflap.unsupported-document-type',
      );

      final missingAxiom =
          codec.decode(_payload('<structure><type>lsystem</type></structure>'))
              as CodecMalformed<InteroperableDocument<LSystemDocument>>;
      expect(missingAxiom.message, 'JFLAP L-system XML requires an axiom.');
      _expectRoundTrip(
        missingAxiom.structuredMessage!,
        'codec.l-system-jflap.missing-axiom',
      );
    });

    test('parser failures preserve locations and carry typed messages', () {
      final malformed =
          codec.decode(_payload('<structure'))
              as CodecMalformed<InteroperableDocument<LSystemDocument>>;
      expect(malformed.reason, CodecMalformedReason.syntax);
      expect(malformed.location, isNotNull);
      _expectRoundTrip(
        malformed.structuredMessage!,
        'codec.l-system-jflap.malformed-xml',
      );

      final invalidUtf8 =
          codec.decode(DocumentPayload(bytes: Uint8List.fromList([0xff, 0xfe])))
              as CodecMalformed<InteroperableDocument<LSystemDocument>>;
      expect(invalidUtf8.reason, CodecMalformedReason.invalidUtf8);
      _expectRoundTrip(
        invalidUtf8.structuredMessage!,
        'codec.l-system-jflap.invalid-utf8',
      );

      final invalidParameter =
          codec.decode(
                _payload('''
<structure><type>lsystem</type><axiom>F</axiom>
<parameter><name>distance</name><value>not-a-number</value></parameter>
</structure>'''),
              )
              as CodecMalformed<InteroperableDocument<LSystemDocument>>;
      expect(
        invalidParameter.message,
        'Invalid numeric JFLAP parameter: not-a-number.',
      );
      expect(
        invalidParameter.structuredMessage?.arguments['parameter'],
        StructuredMessageArgument.literal('distance', role: 'parameter-name'),
      );
      _expectRoundTrip(
        invalidParameter.structuredMessage!,
        'codec.l-system-jflap.invalid-parameter',
      );

      final invalidContext =
          codec.decode(
                _payload('''
<structure><type>lsystem</type><axiom>F</axiom>
<production><left>5 A</left><right>B</right></production>
</structure>'''),
              )
              as CodecMalformed<InteroperableDocument<LSystemDocument>>;
      expect(invalidContext.message, 'Invalid JFLAP context predecessor: 5 A.');
      expect(
        invalidContext.structuredMessage?.arguments['production'],
        StructuredMessageArgument.literal('5 A', role: 'production-left'),
      );
      _expectRoundTrip(
        invalidContext.structuredMessage!,
        'codec.l-system-jflap.invalid-context-predecessor',
      );

      final invalidExtension =
          codec.decode(
                _payload('''
<structure><type>lsystem</type><axiom>F</axiom>
<parameter><name>turingLabExtensions</name><value>[]</value></parameter>
</structure>'''),
              )
              as CodecMalformed<InteroperableDocument<LSystemDocument>>;
      expect(
        invalidExtension.structuredMessage?.arguments['extension'],
        StructuredMessageArgument.literal(
          'turingLabExtensions',
          role: 'extension-key',
        ),
      );
      _expectRoundTrip(
        invalidExtension.structuredMessage!,
        'codec.l-system-jflap.invalid-extension',
      );
    });

    test('import preservation diagnostics carry structured payloads', () {
      final outcome =
          codec.decode(
                _payload('''
<structure><type>lsystem</type><axiom>F</axiom>
<production><left>F(x)</left><right>F(x+1)</right></production>
<parameter><name>vendorDrawing</name><value>kept</value></parameter>
<parameter><name>turingLabRandomSeed</name><value>17</value></parameter>
<metadata/>
</structure>'''),
              )
              as CodecSuccess<InteroperableDocument<LSystemDocument>>;

      expect(
        outcome.diagnostics.map((diagnostic) => diagnostic.code),
        containsAll({
          'jflap.l-system.advanced-variant-preserved',
          'jflap.l-system.parameters-preserved',
          'jflap.l-system.execution-extension-restored',
          'jflap.l-system.elements-preserved',
        }),
      );
      expect(
        outcome.diagnostics,
        everyElement(
          isA<CodecDiagnostic>().having(
            (diagnostic) => diagnostic.structuredMessage,
            'structuredMessage',
            isNotNull,
          ),
        ),
      );
      for (final diagnostic in outcome.diagnostics) {
        _expectRoundTrip(
          diagnostic.structuredMessage!,
          diagnostic.structuredMessage!.stableCode,
        );
      }
    });

    test('export diagnostics and unsupported schemas are structured', () {
      final document = InteroperableDocument<LSystemDocument>(
        document: _system(),
        systemKey: LSystemFormalSystemIds.key,
        schema: LSystemJflapCodec.schema,
      );
      final encoded = codec.encode(document) as CodecSuccess<EncodedDocument>;
      expect(encoded.fidelity, DocumentFidelity.normalized);
      expect(
        encoded.diagnostics.map((diagnostic) => diagnostic.code),
        containsAll({
          'jflap.l-system.execution-extension',
          'jflap.l-system.advanced-variant-extension',
        }),
      );
      for (final diagnostic in encoded.diagnostics) {
        expect(diagnostic.structuredMessage, isNotNull);
        _expectRoundTrip(
          diagnostic.structuredMessage!,
          diagnostic.structuredMessage!.stableCode,
        );
      }

      final wrongSystem =
          codec.encode(
                InteroperableDocument<LSystemDocument>(
                  document: _system(),
                  systemKey: DefaultFormalSystemIds.fsa,
                  schema: LSystemJflapCodec.schema,
                ),
              )
              as CodecUnsupported<EncodedDocument>;
      expect(
        wrongSystem.structuredMessage?.stableCode,
        'codec.l-system-jflap.requires-l-system-document',
      );

      final wrongSchema =
          codec.encode(
                InteroperableDocument<LSystemDocument>(
                  document: _system(),
                  systemKey: LSystemFormalSystemIds.key,
                  schema: const DocumentSchemaDescriptor(
                    id: DocumentSchemaId('turing-lab.l-system'),
                    version: DocumentSchemaVersion(2),
                  ),
                ),
              )
              as CodecUnsupported<EncodedDocument>;
      expect(
        wrongSchema.structuredMessage?.arguments['version'],
        StructuredMessageArgument.integer(2, role: 'schema-version'),
      );
      _expectRoundTrip(
        wrongSchema.structuredMessage!,
        'codec.l-system-jflap.unsupported-schema',
      );
    });

    test('resource limits keep their typed legacy outcome', () {
      final outcome = codec.decode(
        _payload('''
<!DOCTYPE x [<!ENTITY y "z">]>
<structure><type>lsystem</type><axiom>F</axiom></structure>'''),
      );
      expect(outcome, isA<CodecResourceLimit>());
      expect(
        (outcome as CodecResourceLimit).limit,
        CodecResourceLimitKind.xmlDtdOrEntity,
      );
    });
  });

  test('companion contracts are stable and JSON round-trippable', () {
    final messages = <StructuredMessage>[
      LSystemJflapMessages.invalidRoot(),
      LSystemJflapMessages.unsupportedDocumentType('grammar'),
      LSystemJflapMessages.missingAxiom(),
      LSystemJflapMessages.malformedXml(),
      LSystemJflapMessages.invalidUtf8(),
      LSystemJflapMessages.emptyPredecessor(),
      LSystemJflapMessages.invalidContextPredecessor('1 A B'),
      LSystemJflapMessages.invalidParameter(name: 'distance', value: 'x'),
      LSystemJflapMessages.invalidExtension('turingLabExtensions'),
      LSystemJflapMessages.invalidProductionMetadata(
        'turingLabProductionMetadata',
      ),
      LSystemJflapMessages.invalidCommandMapping(),
      LSystemJflapMessages.invalidDocument(),
      LSystemJflapMessages.requiresLSystemDocument(),
      LSystemJflapMessages.unsupportedSchema(2),
      LSystemJflapMessages.decodeFailed(),
      LSystemJflapMessages.encodeFailed(),
      LSystemJflapMessages.advancedVariantPreserved(),
      LSystemJflapMessages.parametersPreserved('vendorDrawing'),
      LSystemJflapMessages.executionExtensionRestored(),
      LSystemJflapMessages.elementsPreserved(),
      LSystemJflapMessages.executionExtension(),
      LSystemJflapMessages.advancedVariantExtension(),
    ];
    expect(messages, everyElement(isA<StructuredMessage>()));
    expect(
      messages.map((message) => message.namespace),
      everyElement(LSystemJflapMessages.namespace),
    );
    for (final message in messages) {
      _expectRoundTrip(message, message.stableCode);
    }
  });
}

DocumentPayload _payload(String source) => DocumentPayload(
  bytes: Uint8List.fromList(utf8.encode(source)),
  filename: 'l-system.jff',
);

void _expectRoundTrip(StructuredMessage message, String stableCode) {
  expect(message.stableCode, stableCode);
  expect(StructuredMessage.fromJson(message.toJson()), message);
}

LSystemDocument _system() => LSystemDocument(
  id: 'l-system',
  name: 'L-system',
  revision: 0,
  axiom: LSystemWord(const ['F']),
  productions: [
    LSystemProduction(
      id: 'p0',
      predecessor: 'F',
      successor: LSystemWord(const ['F', '+', 'F']),
      weight: 2,
    ),
  ],
  iterations: 2,
  turtle: LSystemTurtleSettings(),
  commandMapping: LSystemCommandMapping.jflap,
  randomSeed: 17,
  unsupportedVariants: const [LSystemUnsupportedVariant.parametric],
);
