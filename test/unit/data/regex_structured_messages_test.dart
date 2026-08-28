import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/formal_systems/formal_systems.dart';
import 'package:turing_lab/core/interoperability/interoperability.dart';
import 'package:turing_lab/core/messages/structured_message.dart';
import 'package:turing_lab/core/models/regex_document.dart';
import 'package:turing_lab/data/codecs/regex_codec_messages.dart';
import 'package:turing_lab/data/codecs/regex_jflap_document_codec.dart';
import 'package:turing_lab/data/codecs/regex_json_document_codec.dart';

void main() {
  const jflap = RegexJflapDocumentCodec();

  test('JFLAP document failures preserve structured diagnostics', () {
    final unsupported =
        jflap.decode(_payload('<structure><type>fa</type></structure>'))
            as CodecUnsupported<InteroperableDocument<Object>>;
    expect(
      unsupported.structuredMessage?.stableCode,
      'codec.regex-jflap.unsupported-document',
    );

    final duplicate =
        jflap.decode(
              _payload(
                '<structure><type>re</type><expression>a</expression>'
                '<expression>b</expression></structure>',
              ),
            )
            as CodecMalformed<InteroperableDocument<Object>>;
    expect(
      duplicate.structuredMessage?.stableCode,
      'codec.regex-jflap.multiple-expressions',
    );

    final malformed =
        jflap.decode(
              _payload(
                '<structure><type>re</type><expression>(a+b</expression></structure>',
              ),
            )
            as CodecMalformed<InteroperableDocument<Object>>;
    expect(
      malformed.structuredMessage?.stableCode,
      'codec.regex-jflap.unbalanced-parentheses',
    );

    final emptySet =
        jflap.decode(
              _payload(
                '<structure><type>re</type><expression>ø</expression></structure>',
              ),
            )
            as CodecSuccess<InteroperableDocument<Object>>;
    expect(
      emptySet.diagnostics.map(
        (diagnostic) => diagnostic.structuredMessage?.stableCode,
      ),
      contains('codec.regex-jflap.empty-set-interoperability'),
    );
  });

  test('JFLAP export feature failures carry typed arguments', () {
    final outcome = jflap.encode(
      _document(
        RegexDocument(
          id: 'regex/id',
          name: 'Regex',
          source: '😀',
          alphabet: ['😀'],
        ),
      ),
    );
    final unsupported = outcome as CodecUnsupported<EncodedDocument>;
    expect(
      unsupported.structuredMessage?.stableCode,
      'codec.regex-jflap.unsupported-feature',
    );
    expect(
      unsupported.structuredMessage?.arguments['feature']?.kind,
      StructuredMessageArgumentKind.literal,
    );
  });

  test('JSON validation failures preserve structured diagnostics', () {
    final codec = RegexJsonDocumentCodec();
    final encoded =
        codec.encode(_document(_regex('a|b'))) as CodecSuccess<EncodedDocument>;
    final envelope = jsonDecode(utf8.decode(encoded.value.bytes)) as Map;
    final payload = (envelope['document'] as Map)['payload'] as Map;
    payload['canonicalAst'] = {'type': 'symbol', 'symbol': 'a'};
    final mismatch =
        codec.decode(_payload(jsonEncode(envelope)))
            as CodecMalformed<InteroperableDocument<Object>>;
    expect(
      mismatch.structuredMessage?.stableCode,
      'codec.regex-json.canonical-ast-mismatch',
    );

    final wrong =
        codec.encode(
              InteroperableDocument<Object>(
                document: const {},
                systemKey: DefaultFormalSystemIds.regex,
                schema: RegexJsonDocumentCodec.schema,
              ),
            )
            as CodecUnsupported<EncodedDocument>;
    expect(
      wrong.structuredMessage?.stableCode,
      'codec.regex-json.expected-regex-document',
    );
  });

  test('Regex codec companions round-trip through JSON', () {
    final messages = <StructuredMessage>[
      RegexJflapMessages.unsupportedFeature('non-BMP symbol'),
      RegexJflapMessages.unbalancedParentheses(),
      RegexJflapMessages.emptySetInteroperability(),
      RegexJsonMessages.canonicalAstMismatch(),
      RegexJsonMessages.unsupportedDialect(),
    ];
    for (final message in messages) {
      expect(StructuredMessage.fromJson(message.toJson()), message);
    }
  });
}

RegexDocument _regex(String source) => RegexDocument(
  id: 'regex/id',
  name: 'Regex',
  source: source,
  alphabet: const ['a', 'b'],
);

InteroperableDocument<Object> _document(RegexDocument document) =>
    InteroperableDocument<Object>(
      document: document,
      systemKey: DefaultFormalSystemIds.regex,
      schema: RegexJsonDocumentCodec.schema,
    );

DocumentPayload _payload(String source) => DocumentPayload(
  bytes: Uint8List.fromList(utf8.encode(source)),
  filename: 'regex.jff',
);
