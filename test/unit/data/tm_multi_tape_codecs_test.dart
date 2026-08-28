import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/formal_systems/formal_systems.dart';
import 'package:turing_lab/core/interoperability/interoperability.dart';
import 'package:turing_lab/core/models/tm.dart';
import 'package:turing_lab/data/codecs/default_document_interoperability_registry.dart';

void main() {
  final registry = DefaultDocumentInteroperabilityRegistry.create();

  test('canonical JSON and JFLAP fixtures preserve two-tape vectors', () {
    for (final fixture in const [
      'test/fixtures/interoperability/tm_multi_canonical.json',
      'test/fixtures/interoperability/tm_multi_canonical.jff',
    ]) {
      final format = fixture.endsWith('.json')
          ? DefaultFormalSystemIds.turingLabJsonFormat
          : DefaultFormalSystemIds.jflapXmlFormat;
      final decoded = registry.decode(
        DocumentPayload(
          bytes: File(fixture).readAsBytesSync(),
          filename: fixture,
        ),
        expectedSystem: DefaultFormalSystemIds.tm,
        expectedFormat: format,
      );

      expect(decoded, isA<CodecSuccess<InteroperableDocument<Object>>>(),
          reason: fixture);
      final machine = (decoded as CodecSuccess<InteroperableDocument<Object>>)
          .value
          .document as TM;
      expect(machine.tapeCount, 2);
      expect(machine.tmTransitions.single.readSymbols, ['a', 'B']);
      expect(machine.tmTransitions.single.directions.length, 2);
    }
  });

  test('JSON rejects mismatched operation vector lengths explicitly', () {
    final source = File(
      'test/fixtures/interoperability/tm_multi_canonical.json',
    ).readAsStringSync();
    final malformed = source.replaceFirst(
      '"readSymbols":["a","B"]',
      '"readSymbols":["a"]',
    );

    final decoded = registry.decode(
      _payload(malformed, 'mismatch.json'),
      expectedSystem: DefaultFormalSystemIds.tm,
      expectedFormat: DefaultFormalSystemIds.turingLabJsonFormat,
    );

    expect(decoded, isA<CodecMalformed<InteroperableDocument<Object>>>());
  });

  test('JFLAP rejects invalid tape indices and movement values', () {
    final source = File(
      'test/fixtures/interoperability/tm_multi_canonical.jff',
    ).readAsStringSync();
    final invalidTape = source.replaceFirst(
      '<read tape="2"',
      '<read tape="3"',
    );
    final invalidMove = source.replaceFirst(
      '<move tape="2">S</move>',
      '<move tape="2">X</move>',
    );

    for (final malformed in [invalidTape, invalidMove]) {
      final decoded = registry.decode(
        _payload(malformed, 'malformed.jff'),
        expectedSystem: DefaultFormalSystemIds.tm,
        expectedFormat: DefaultFormalSystemIds.jflapXmlFormat,
      );
      expect(decoded, isA<CodecMalformed<InteroperableDocument<Object>>>());
    }
  });

  test('content detection ignores misleading TM filename extensions', () {
    final jflap = File(
      'test/fixtures/interoperability/tm_multi_canonical.jff',
    ).readAsStringSync();
    final json = File(
      'test/fixtures/interoperability/tm_multi_canonical.json',
    ).readAsStringSync();

    for (final (source, filename) in [
      (jflap, 'machine.json'),
      (json, 'machine.jff'),
    ]) {
      final decoded = registry.decode(
        _payload(source, filename),
        expectedSystem: DefaultFormalSystemIds.tm,
      );
      expect(decoded, isA<CodecSuccess<InteroperableDocument<Object>>>());
    }
  });

  test('legacy single-tape JSON migrates into one-element vectors', () {
    final envelope = jsonDecode(
      File(
        'test/fixtures/interoperability/tm_multi_canonical.json',
      ).readAsStringSync(),
    ) as Map<String, dynamic>;
    final document = envelope['document'] as Map<String, dynamic>;
    final payload = Map<String, dynamic>.from(
      document['payload'] as Map<String, dynamic>,
    );
    payload['tapeCount'] = 1;
    payload.remove('tmVariant');
    final transitions = (payload['transitions'] as List)
        .map((raw) => Map<String, dynamic>.from(raw as Map))
        .toList();
    transitions.single
      ..remove('readSymbols')
      ..remove('writeSymbols')
      ..remove('directions');
    payload['transitions'] = transitions;

    final decoded = registry.decode(
      _payload(jsonEncode(payload), 'legacy.json'),
      expectedSystem: DefaultFormalSystemIds.tm,
      expectedFormat: DefaultFormalSystemIds.turingLabJsonFormat,
    );

    expect(decoded, isA<CodecSuccess<InteroperableDocument<Object>>>());
    final machine = (decoded as CodecSuccess<InteroperableDocument<Object>>)
        .value
        .document as TM;
    expect(machine.tapeCount, 1);
    expect(machine.tmTransitions.single.readSymbols, ['a']);
    expect(machine.tmTransitions.single.writeSymbols, ['a']);
  });
}

DocumentPayload _payload(String source, String filename) => DocumentPayload(
      bytes: utf8.encode(source),
      filename: filename,
    );
