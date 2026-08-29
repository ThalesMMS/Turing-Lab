import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/interoperability/interoperability.dart';
import 'package:turing_lab/core/messages/structured_message.dart';
import 'package:turing_lab/data/codecs/pda_jflap_document_codec.dart';
import 'package:turing_lab/data/codecs/pda_jflap_messages.dart';
import 'package:turing_lab/data/codecs/pda_json_document_codec.dart';
import 'package:turing_lab/data/codecs/pda_json_messages.dart';
import 'package:turing_lab/data/codecs/tm_jflap_document_codec.dart';
import 'package:turing_lab/data/codecs/tm_jflap_messages.dart';
import 'package:turing_lab/data/codecs/tm_json_document_codec.dart';
import 'package:turing_lab/data/codecs/tm_json_messages.dart';

void main() {
  test('PDA JFLAP outcomes and diagnostics carry typed messages', () {
    const codec = PdaJflapDocumentCodec();

    final invalidUtf8 = codec.decode(
      DocumentPayload(
        bytes: Uint8List.fromList([0xff]),
        filename: 'document.jff',
      ),
    );
    expect(
      (invalidUtf8 as CodecMalformed<InteroperableDocument<Object>>)
          .structuredMessage
          ?.stableCode,
      'codec.pda-jflap.invalid-utf8',
    );

    final unsupported = codec.decode(
      _payload('<structure><type>fa</type></structure>'),
    );
    final unsupportedOutcome =
        unsupported as CodecUnsupported<InteroperableDocument<Object>>;
    expect(
      unsupportedOutcome.structuredMessage?.stableCode,
      'codec.pda-jflap.unsupported-document-type',
    );
    expect(
      unsupportedOutcome.structuredMessage?.arguments['type'],
      StructuredMessageArgument.literal('fa', role: 'document-type'),
    );

    final missingAutomaton = codec.decode(
      _payload('<structure><type>pda</type></structure>'),
    );
    final malformed =
        missingAutomaton as CodecMalformed<InteroperableDocument<Object>>;
    expect(
      malformed.structuredMessage?.stableCode,
      'codec.pda-jflap.missing-automaton',
    );

    final standard = codec.decode(
      _payload('''
<structure><type>pda</type><automaton>
  <state id="q0" name="q0"><x>0</x><y>0</y><initial/></state>
  <state id="q1" name="q1"><x>100</x><y>0</y><final/></state>
  <transition><from>q0</from><to>q1</to><read>a</read><pop>Z</pop><push>AZ</push></transition>
</automaton></structure>'''),
    );
    final success = standard as CodecSuccess<InteroperableDocument<Object>>;
    expect(success.diagnostics, isNotEmpty);
    expect(success.diagnostics, everyElement(_hasStructuredMessage));

    for (final message in [
      PdaJflapMessages.unsupportedDocumentType('fa'),
      PdaJflapMessages.missingAutomaton(),
      PdaJflapMessages.invalidStateCoordinate('q0'),
      PdaJflapMessages.unknownTransitionEndpoints(from: 'q0', to: 'q9'),
      PdaJflapMessages.requiresPdaDocument(),
      PdaJflapMessages.unsupportedSchema(2),
      PdaJflapMessages.extensionPortability(),
    ]) {
      _expectRoundTrip(message);
    }
  });

  test('PDA JSON validation carries a codec-specific structured message', () {
    final decoded = PdaJsonDocumentCodec().decode(
      _payload(
        File(
          'test/fixtures/interoperability/pda_canonical.json',
        ).readAsStringSync(),
      ),
    );
    expect(decoded, isA<CodecSuccess<InteroperableDocument<Object>>>());

    final document =
        (decoded as CodecSuccess<InteroperableDocument<Object>>).value;
    final encoded = PdaJsonDocumentCodec().encode(document);
    expect(encoded, isA<CodecSuccess<EncodedDocument>>());

    final malformedJson =
        jsonDecode(
              utf8.decode(
                (encoded as CodecSuccess<EncodedDocument>).value.bytes,
              ),
            )
            as Map<String, dynamic>;
    final malformedPayload =
        (malformedJson['document'] as Map<String, dynamic>)['payload']
            as Map<String, dynamic>;
    malformedPayload['stackAlphabet'] = <String>[];

    final malformed = PdaJsonDocumentCodec().decode(
      _payload(jsonEncode(malformedJson)),
    );
    expect(malformed, isNot(isA<CodecSuccess<Object>>()));
    final expectedMalformedMessage = PdaJsonMessages.invalidDocument();
    expect(
      (malformed as CodecMalformed<InteroperableDocument<Object>>)
          .structuredMessage,
      isNotNull,
    );
    expect(
      malformed.structuredMessage!.toJson(),
      expectedMalformedMessage.toJson(),
    );

    _expectRoundTrip(PdaJsonMessages.invalidDocument());
    _expectRoundTrip(PdaJsonMessages.unexpectedDocumentType());
  });

  test('TM JFLAP outcomes and diagnostics carry typed messages', () {
    const codec = TmJflapDocumentCodec();

    final invalidUtf8 = codec.decode(
      DocumentPayload(
        bytes: Uint8List.fromList([0xff]),
        filename: 'document.jff',
      ),
    );
    expect(
      (invalidUtf8 as CodecMalformed<InteroperableDocument<Object>>)
          .structuredMessage
          ?.stableCode,
      'codec.tm-jflap.invalid-utf8',
    );

    final invalidRoot = codec.decode(_payload('<not-structure/>'));
    final malformed =
        invalidRoot as CodecMalformed<InteroperableDocument<Object>>;
    expect(
      malformed.structuredMessage?.stableCode,
      'codec.tm-jflap.invalid-root',
    );

    final unsupported = codec.decode(
      _payload('<structure><type>fa</type></structure>'),
    );
    final unsupportedOutcome =
        unsupported as CodecUnsupported<InteroperableDocument<Object>>;
    expect(
      unsupportedOutcome.structuredMessage?.stableCode,
      'codec.tm-jflap.unsupported-document-type',
    );
    expect(
      unsupportedOutcome.structuredMessage?.arguments['type'],
      StructuredMessageArgument.literal('fa', role: 'document-type'),
    );

    final standard = codec.decode(
      _payload('''
<structure><type>turing</type><automaton>
  <state id="0" name="q0"><x>0</x><y>0</y><initial/></state>
  <state id="1" name="q1"><x>100</x><y>0</y><final/></state>
  <transition><from>0</from><to>1</to><read>a</read><write>a</write><move>R</move></transition>
</automaton></structure>'''),
    );
    final success = standard as CodecSuccess<InteroperableDocument<Object>>;
    expect(success.diagnostics, isNotEmpty);
    expect(success.diagnostics, everyElement(_hasStructuredMessage));

    for (final message in [
      TmJflapMessages.unsupportedDocumentType('fa'),
      TmJflapMessages.invalidTapeCount(),
      TmJflapMessages.missingAutomaton(),
      TmJflapMessages.invalidStateCoordinate('0'),
      TmJflapMessages.unknownTransitionEndpoints(from: '0', to: '9'),
      TmJflapMessages.unsupportedOperation(
        transitionId: 't0',
        operation: 'read',
        symbol: 'token',
      ),
      TmJflapMessages.requiresTmDocument(),
      TmJflapMessages.unsupportedSchema(2),
      TmJflapMessages.buildingBlocksImported(),
    ]) {
      _expectRoundTrip(message);
    }
  });

  test('TM JSON migration and validation diagnostics are structured', () {
    final source =
        jsonDecode(
              File(
                'test/fixtures/interoperability/tm_multi_canonical.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final payload = source['document'] is Map
        ? source['document']['payload'] as Map<String, dynamic>
        : source;
    payload.remove('tmVariant');
    final migrated = TmJsonDocumentCodec().decode(_payload(jsonEncode(source)));
    final success = migrated as CodecSuccess<InteroperableDocument<Object>>;
    expect(
      success.diagnostics
          .where((diagnostic) => diagnostic.code == 'json.tm-variant-inferred')
          .single
          .structuredMessage
          ?.stableCode,
      'codec.tm-json.variant-inferred',
    );

    _expectRoundTrip(TmJsonMessages.unexpectedDocumentType());
    _expectRoundTrip(TmJsonMessages.invalidDocument());
    _expectRoundTrip(TmJsonMessages.variantMismatch());
    _expectRoundTrip(TmJsonMessages.variantInferred());
    _expectRoundTrip(TmJsonMessages.operationVectorsMigrated());
    _expectRoundTrip(TmJsonMessages.endpointsMigratedToIds());
  });
}

bool _hasStructuredMessage(CodecDiagnostic diagnostic) =>
    diagnostic.structuredMessage != null;

DocumentPayload _payload(String source) =>
    DocumentPayload(bytes: utf8.encode(source), filename: 'document.data');

void _expectRoundTrip(StructuredMessage message) {
  expect(StructuredMessage.fromJson(message.toJson()), message);
}
