import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/formal_systems/formal_systems.dart';
import 'package:turing_lab/core/interoperability/interoperability.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/core/models/tm.dart';
import 'package:turing_lab/core/models/tm_acceptance.dart';
import 'package:turing_lab/core/models/tm_building_blocks.dart';
import 'package:turing_lab/data/codecs/tm_jflap_document_codec.dart';
import 'package:turing_lab/data/codecs/tm_json_document_codec.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  test('canonical JSON preserves TM acceptance policy', () {
    final codec = TmJsonDocumentCodec();
    final encoded =
        codec.encode(_document(_machine())) as CodecSuccess<EncodedDocument>;
    final envelope = jsonDecode(utf8.decode(encoded.value.bytes)) as Map;
    final payload = (envelope['document'] as Map)['payload'] as Map;

    expect(payload['acceptancePolicy'], 'halting');

    final decoded = codec.decode(
      DocumentPayload(bytes: encoded.value.bytes, filename: 'policy.json'),
    ) as CodecSuccess<InteroperableDocument<Object>>;
    expect(
      (decoded.value.document as TM).acceptancePolicy,
      TMAcceptancePolicy.halting,
    );
  });

  test('canonical JSON rejects an invalid TM acceptance policy', () {
    final codec = TmJsonDocumentCodec();
    final encoded =
        codec.encode(_document(_machine())) as CodecSuccess<EncodedDocument>;
    final envelope =
        jsonDecode(utf8.decode(encoded.value.bytes)) as Map<String, dynamic>;
    final document = envelope['document'] as Map<String, dynamic>;
    final payload = document['payload'] as Map<String, dynamic>;
    payload['acceptancePolicy'] = 'not-a-policy';

    final decoded = codec.decode(
      DocumentPayload(
        bytes: Uint8List.fromList(utf8.encode(jsonEncode(envelope))),
        filename: 'invalid-policy.json',
      ),
    );

    expect(decoded, isA<CodecMalformed<Object>>());
    expect(
      (decoded as CodecMalformed<Object>).reason,
      CodecMalformedReason.invalidValue,
    );
  });

  test('JFLAP extension preserves TM acceptance policy locally', () {
    const codec = TmJflapDocumentCodec();
    final encoded =
        codec.encode(_document(_machine())) as CodecSuccess<EncodedDocument>;
    final xml = utf8.decode(encoded.value.bytes);

    expect(xml, contains('"acceptancePolicy":"halting"'));

    final decoded = codec.decode(
      DocumentPayload(bytes: encoded.value.bytes, filename: 'policy.jff'),
    ) as CodecSuccess<InteroperableDocument<Object>>;
    expect(
      (decoded.value.document as TM).acceptancePolicy,
      TMAcceptancePolicy.halting,
    );
    expect(
      encoded.diagnostics.map((diagnostic) => diagnostic.code),
      contains('jflap.tm-turing-lab-extension-portability'),
    );
  });

  test('standard JFLAP import diagnoses final-state policy default', () {
    const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<structure>
  <type>turing</type>
  <automaton>
    <state id="0" name="q0">
      <x>0</x><y>0</y><initial />
    </state>
  </automaton>
</structure>
''';
    const codec = TmJflapDocumentCodec();
    final decoded = codec.decode(
      DocumentPayload(
        bytes: Uint8List.fromList(utf8.encode(xml)),
        filename: 'standard.jff',
      ),
    ) as CodecSuccess<InteroperableDocument<Object>>;

    expect(
      (decoded.value.document as TM).acceptancePolicy,
      TMAcceptancePolicy.finalState,
    );
    expect(
      decoded.diagnostics
          .singleWhere(
            (diagnostic) => diagnostic.code == 'jflap.tm.canonical-order',
          )
          .message,
      contains('final-state acceptance'),
    );
  });

  test('JFLAP extension rejects an invalid TM acceptance policy', () {
    const codec = TmJflapDocumentCodec();
    final encoded =
        codec.encode(_document(_machine())) as CodecSuccess<EncodedDocument>;
    final xml = utf8.decode(encoded.value.bytes).replaceFirst(
        '"acceptancePolicy":"halting"', '"acceptancePolicy":"not-a-policy"');

    final decoded = codec.decode(
      DocumentPayload(
        bytes: Uint8List.fromList(utf8.encode(xml)),
        filename: 'invalid-policy.jff',
      ),
    );

    expect(decoded, isA<CodecMalformed<Object>>());
    final malformed = decoded as CodecMalformed<Object>;
    expect(malformed.reason, CodecMalformedReason.invalidValue);
    expect(malformed.location?.path, contains('acceptancePolicy'));
  });

  test('building-block JFLAP rejects conflicting acceptance policies', () {
    const codec = TmJflapDocumentCodec();
    final encoded = codec.encode(_document(_buildingBlockMachine()))
        as CodecSuccess<EncodedDocument>;
    final xml = _replaceRootMachinePolicy(
      utf8.decode(encoded.value.bytes),
      'finalStateOrHalting',
    );

    final decoded = codec.decode(
      DocumentPayload(
        bytes: Uint8List.fromList(utf8.encode(xml)),
        filename: 'conflicting-policy.jff',
      ),
    );

    expect(decoded, isA<CodecMalformed<Object>>());
    final malformed = decoded as CodecMalformed<Object>;
    expect(malformed.reason, CodecMalformedReason.invalidValue);
    expect(malformed.location?.path, contains('acceptancePolicy'));
  });

  test('building-block JFLAP does not mask an invalid machine policy', () {
    const codec = TmJflapDocumentCodec();
    final encoded = codec.encode(_document(_buildingBlockMachine()))
        as CodecSuccess<EncodedDocument>;
    final xml = _replaceRootMachinePolicy(
      utf8.decode(encoded.value.bytes),
      'not-a-policy',
    );

    final decoded = codec.decode(
      DocumentPayload(
        bytes: Uint8List.fromList(utf8.encode(xml)),
        filename: 'invalid-policy.jff',
      ),
    );

    expect(decoded, isA<CodecMalformed<Object>>());
    final malformed = decoded as CodecMalformed<Object>;
    expect(malformed.reason, CodecMalformedReason.invalidValue);
    expect(malformed.location?.path, contains('acceptancePolicy'));
  });
}

InteroperableDocument<Object> _document(TM machine) =>
    InteroperableDocument<Object>(
      document: machine,
      systemKey: DefaultFormalSystemIds.tm,
      schema: TmJsonDocumentCodec.schema,
    );

TM _machine({
  TMAcceptancePolicy policy = TMAcceptancePolicy.halting,
  Map<String, TMBlockDefinition> definitions = const {},
}) {
  final state = State(
    id: 'q0',
    label: 'q0',
    position: Vector2.zero(),
    isInitial: true,
  );
  return TM(
    id: 'policy-machine',
    name: 'Policy machine',
    states: {state},
    transitions: const {},
    alphabet: const {},
    initialState: state,
    acceptingStates: const {},
    created: DateTime.utc(2026),
    modified: DateTime.utc(2026),
    bounds: const math.Rectangle(0, 0, 200, 100),
    tapeAlphabet: const {'B'},
    acceptancePolicy: policy,
    blockDefinitions: definitions,
  );
}

TM _buildingBlockMachine() {
  final leaf = _machine(policy: TMAcceptancePolicy.finalState);
  return _machine(
    definitions: {
      'leaf': TMBlockDefinition(
        id: 'leaf',
        name: 'Leaf',
        revision: 1,
        machine: leaf.copyWith(id: 'leaf-machine'),
      ),
    },
  );
}

String _replaceRootMachinePolicy(String xml, String policy) {
  return xml.replaceFirstMapped(
    RegExp(r'<turingLabMachine>([^<]+)</turingLabMachine>'),
    (match) {
      final metadata =
          Map<String, dynamic>.from(jsonDecode(match.group(1)!) as Map);
      metadata['acceptancePolicy'] = policy;
      return '<turingLabMachine>${jsonEncode(metadata)}</turingLabMachine>';
    },
  );
}
