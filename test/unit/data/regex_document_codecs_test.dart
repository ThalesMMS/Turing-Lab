import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:turing_lab/core/algorithms/automaton_simulator.dart';
import 'package:turing_lab/core/algorithms/regex_to_nfa_converter.dart';
import 'package:turing_lab/core/formal_systems/formal_systems.dart';
import 'package:turing_lab/core/interoperability/interoperability.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/regex_document.dart';
import 'package:turing_lab/data/codecs/default_document_interoperability_registry.dart';
import 'package:turing_lab/data/codecs/regex_jflap_document_codec.dart';
import 'package:turing_lab/data/codecs/regex_json_document_codec.dart';

void main() {
  group('Regex JSON codec', () {
    test('preserves source, dialect, tokenization, alphabet, and canonical AST',
        () {
      const source = '((a|β))*|😀';
      final document = _regex(source, alphabet: const ['a', 'β', '😀']);

      final encoded = _encodeJson(document);
      final envelope = jsonDecode(utf8.decode(encoded.value.bytes)) as Map;
      final payload = (envelope['document'] as Map)['payload'] as Map;
      expect(payload['source'], source);
      expect(payload['sourceOfTruth'], 'source');
      expect(payload['dialect'], 'turingLabV1');
      expect(payload['tokenization'], 'unicodeScalar');
      expect(payload['canonicalAst'], isA<Map>());
      expect(payload, isNot(contains('testString')));
      expect(payload, isNot(contains('simplificationResult')));

      final decoded = _decodeJson(encoded.value.bytes);
      expect(decoded.fidelity, DocumentFidelity.exact);
      final restored = decoded.value.document as RegexDocument;
      expect(restored.source, source);
      expect(restored.alphabet, ['a', 'β', '😀']);
    });

    test('migrates the previous active-session shape without derived results',
        () {
      final legacy = {
        'currentRegex': '(a|b)*',
        'alphabet': 'ab',
        'testString': 'abba',
        'simplifyOutput': false,
        'matches': true,
      };

      final decoded = RegexJsonDocumentCodec().decode(
        _payload(_bytes(jsonEncode(legacy)), 'legacy-session.json'),
      ) as CodecSuccess<InteroperableDocument<Object>>;
      expect(decoded.fidelity, DocumentFidelity.normalized);
      final restored = decoded.value.document as RegexDocument;
      expect(restored.source, '(a|b)*');
      expect(restored.alphabet, ['a', 'b']);
    });

    test('rejects a stale canonical AST', () {
      final encoded = _encodeJson(_regex('a|b'));
      final envelope = jsonDecode(utf8.decode(encoded.value.bytes)) as Map;
      final payload = (envelope['document'] as Map)['payload'] as Map;
      payload['canonicalAst'] = {'type': 'symbol', 'symbol': 'a'};

      final decoded = RegexJsonDocumentCodec().decode(
        _payload(_bytes(jsonEncode(envelope)), 'stale.json'),
      );
      expect(decoded, isA<CodecMalformed<InteroperableDocument<Object>>>());
    });

    test('round-trips an empty Regex workspace', () {
      final decoded = _decodeJson(_encodeJson(_regex('')).value.bytes);
      final restored = decoded.value.document as RegexDocument;
      expect(restored.source, isEmpty);
      expect(restored.id, 'regex/id');
    });

    test('canonical fixture is byte-stable', () {
      final bytes = File(
        'test/fixtures/interoperability/regex_canonical.json',
      ).readAsBytesSync();
      final decoded = _decodeJson(bytes);
      final encoded = RegexJsonDocumentCodec().encode(decoded.value)
          as CodecSuccess<EncodedDocument>;
      expect(encoded.value.bytes, bytes);
    });

    test('rejects malformed source and multi-scalar alphabet tokens', () {
      for (final document in [
        _regex('(a|'),
        _regex('a', alphabet: const ['token']),
      ]) {
        final encoded = RegexJsonDocumentCodec().encode(_document(document));
        expect(encoded, isA<CodecOutcome<EncodedDocument>>());
        expect(encoded, isNot(isA<CodecSuccess<EncodedDocument>>()));
      }
    });
  });

  group('Regex JFLAP codec', () {
    test('opens the source-backed JFLAP fixture', () {
      final bytes = File(
        'test/fixtures/interoperability/regex_canonical.jff',
      ).readAsBytesSync();
      final decoded = const RegexJflapDocumentCodec().decode(
        _payload(bytes, 'regex_canonical.jff'),
      ) as CodecSuccess<InteroperableDocument<Object>>;
      expect((decoded.value.document as RegexDocument).source, '(a|b)*');
    });

    test('normalizes JFLAP union and epsilon with bounded semantics', () async {
      const source = '''<?xml version="1.0" encoding="UTF-8"?>
<structure><type>re</type><expression>((a+b)*)+!</expression></structure>''';
      final decoded = const RegexJflapDocumentCodec().decode(
        _textPayload(source, 'jflap-expression.jff'),
      ) as CodecSuccess<InteroperableDocument<Object>>;
      expect(decoded.fidelity, DocumentFidelity.normalized);
      final document = decoded.value.document as RegexDocument;
      expect(document.source, '((a|b)*)|ε');
      expect(document.alphabet, ['a', 'b']);

      await _expectSameBoundedLanguage(
        document.source,
        '((a|b)*)|ε',
        ['', 'a', 'b', 'ab', 'ba', 'c'],
      );
    });

    test('round-trips local source and metadata through the extension', () {
      final document = _regex('((a|b))*|ε', alphabet: const ['a', 'b']);
      const codec = RegexJflapDocumentCodec();

      final encoded =
          codec.encode(_document(document)) as CodecSuccess<EncodedDocument>;
      expect(encoded.fidelity, DocumentFidelity.lossy);
      final xml = utf8.decode(encoded.value.bytes);
      expect(xml, contains('<type>re</type>'));
      expect(xml, contains('<expression>((a+b))*+!</expression>'));
      expect(xml, contains('<turingLabRegex>'));

      final decoded = codec.decode(_payload(encoded.value.bytes, 'local.jff'))
          as CodecSuccess<InteroperableDocument<Object>>;
      expect(decoded.fidelity, DocumentFidelity.exact);
      final restored = decoded.value.document as RegexDocument;
      expect(restored.id, document.id);
      expect(restored.name, document.name);
      expect(restored.source, document.source);
      expect(restored.alphabet, document.alphabet);
    });

    test('preserves empty expressions, grouping, whitespace, and literals', () {
      const codec = RegexJflapDocumentCodec();
      for (final source in ['', '((a))', 'a b', r'\|', r'\?\[\]']) {
        final encoded = codec.encode(_document(_regex(source)));
        expect(encoded, isA<CodecSuccess<EncodedDocument>>(), reason: source);
        final bytes = (encoded as CodecSuccess<EncodedDocument>).value.bytes;
        final restored = codec.decode(_payload(bytes, 'round-trip.jff'))
            as CodecSuccess<InteroperableDocument<Object>>;
        expect((restored.value.document as RegexDocument).source, source);
      }
    });

    test('supports BMP Unicode and blocks unsafe JFLAP constructs', () {
      const codec = RegexJflapDocumentCodec();
      expect(
        codec.encode(_document(_regex('β'))),
        isA<CodecSuccess<EncodedDocument>>(),
      );
      for (final source in [
        '😀',
        '∅',
        '!',
        'ø',
        'λ',
        'a+',
        'a?',
        '.',
        '[ab]',
        r'\+',
        r'\ε',
      ]) {
        expect(
          codec.encode(_document(_regex(source))),
          isA<CodecUnsupported<EncodedDocument>>(),
          reason: source,
        );
      }
    });

    test('imports JFLAP-generated empty set as explicitly lossy', () async {
      const xml =
          '<structure><type>re</type><expression>ø</expression></structure>';
      final decoded = const RegexJflapDocumentCodec().decode(
        _textPayload(xml, 'empty-set.jff'),
      ) as CodecSuccess<InteroperableDocument<Object>>;
      expect(decoded.fidelity, DocumentFidelity.lossy);
      expect((decoded.value.document as RegexDocument).source, '∅');
      expect(
        decoded.diagnostics.map((diagnostic) => diagnostic.code),
        contains('jflap.regex-empty-set-interoperability'),
      );
      final nfa = _convert('∅');
      for (final input in ['', 'a', 'aa']) {
        final result = await AutomatonSimulator.simulateNFA(nfa, input);
        expect(result.data?.isAccepted, isFalse);
      }
    });

    test('preserves unknown optional XML and produces deterministic bytes', () {
      const source = '''<structure vendor="root"><type>re</type>
<expression>a+b</expression><vendorData value="1"/></structure>''';
      const codec = RegexJflapDocumentCodec();
      final decoded = codec.decode(_textPayload(source, 'vendor.jff'))
          as CodecSuccess<InteroperableDocument<Object>>;
      expect(decoded.value.extensions.values, isNotEmpty);
      final first =
          codec.encode(decoded.value) as CodecSuccess<EncodedDocument>;
      final second =
          codec.encode(decoded.value) as CodecSuccess<EncodedDocument>;
      expect(second.value.bytes, first.value.bytes);
      final xml = utf8.decode(first.value.bytes);
      expect(xml, contains('vendor="root"'));
      expect(xml, contains('<vendorData value="1"/>'));
    });

    test('rejects malformed syntax, duplicate fields, and profile epsilon', () {
      const codec = RegexJflapDocumentCodec();
      for (final source in [
        '<structure><type>re</type><expression>(a+b</expression></structure>',
        '<structure><type>re</type><expression>a</expression><expression>b</expression></structure>',
        '<structure><type>re</type><expression>λ</expression></structure>',
      ]) {
        final decoded = codec.decode(_textPayload(source, 'bad.jff'));
        expect(
          decoded,
          anyOf(
            isA<CodecMalformed<InteroperableDocument<Object>>>(),
            isA<CodecUnsupported<InteroperableDocument<Object>>>(),
          ),
        );
      }
    });

    test('registry detects content despite misleading extensions', () {
      final registry = DefaultDocumentInteroperabilityRegistry.create();
      final jflap = _textPayload(
        '<structure><type>re</type><expression>a+b</expression></structure>',
        'actually-json.json',
      );
      final detected = registry.detect(
        jflap,
        expectedSystem: DefaultFormalSystemIds.regex,
      ) as CodecSuccess<DetectedDocument>;
      expect(detected.value.descriptor.formatId,
          DefaultFormalSystemIds.jflapXmlFormat);

      final json = _encodeJson(_regex('a|b')).value.bytes;
      final detectedJson = registry.detect(
        _payload(json, 'actually-jflap.jff'),
        expectedSystem: DefaultFormalSystemIds.regex,
      ) as CodecSuccess<DetectedDocument>;
      expect(detectedJson.value.descriptor.formatId,
          DefaultFormalSystemIds.turingLabJsonFormat);
    });
  });

  test('Unicode scalar tokenization keeps non-BMP symbols atomic', () async {
    final nfa = _convert('😀');
    expect(nfa.alphabet, {'😀'});
    final accepted = await AutomatonSimulator.simulateNFA(nfa, '😀');
    final rejected = await AutomatonSimulator.simulateNFA(nfa, '');
    expect(accepted.data?.isAccepted, isTrue);
    expect(rejected.data?.isAccepted, isFalse);
  });
}

Future<void> _expectSameBoundedLanguage(
  String left,
  String right,
  Iterable<String> samples,
) async {
  final leftNfa = _convert(left);
  final rightNfa = _convert(right);
  for (final sample in samples) {
    final leftResult = await AutomatonSimulator.simulateNFA(leftNfa, sample);
    final rightResult = await AutomatonSimulator.simulateNFA(rightNfa, sample);
    expect(
      leftResult.data?.isAccepted,
      rightResult.data?.isAccepted,
      reason: 'sample "$sample"',
    );
  }
}

FSA _convert(String source) {
  final result =
      RegexToNFAConverter.convert(source, contextAlphabet: {'a', 'b'});
  expect(result.isSuccess, isTrue, reason: result.error);
  return result.data!;
}

RegexDocument _regex(
  String source, {
  List<String> alphabet = const ['a', 'b'],
}) =>
    RegexDocument(
      id: 'regex/id',
      name: 'Regex name',
      source: source,
      alphabet: alphabet,
    );

InteroperableDocument<Object> _document(RegexDocument document) =>
    InteroperableDocument<Object>(
      document: document,
      systemKey: DefaultFormalSystemIds.regex,
      schema: RegexJsonDocumentCodec.schema,
    );

CodecSuccess<EncodedDocument> _encodeJson(RegexDocument document) =>
    RegexJsonDocumentCodec().encode(_document(document))
        as CodecSuccess<EncodedDocument>;

CodecSuccess<InteroperableDocument<Object>> _decodeJson(Uint8List bytes) =>
    RegexJsonDocumentCodec().decode(_payload(bytes, 'regex.json'))
        as CodecSuccess<InteroperableDocument<Object>>;

DocumentPayload _textPayload(String source, String filename) =>
    _payload(_bytes(source), filename);

DocumentPayload _payload(Uint8List bytes, String filename) =>
    DocumentPayload(bytes: bytes, filename: filename);

Uint8List _bytes(String source) => Uint8List.fromList(utf8.encode(source));
