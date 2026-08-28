import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/annotations/annotations.dart';
import 'package:turing_lab/core/formal_systems/formal_systems.dart';
import 'package:turing_lab/core/interoperability/interoperability.dart';
import 'package:turing_lab/core/transducers/transducers.dart';
import 'package:turing_lab/data/codecs/default_document_interoperability_registry.dart';
import 'package:turing_lab/data/codecs/mealy_jflap_codec.dart';
import 'package:turing_lab/data/codecs/mealy_json_document_codec.dart';
import 'package:turing_lab/data/transducers/default_transducer_registry.dart';

void main() {
  late DocumentInteroperabilityRegistry registry;

  setUp(() {
    registry = DefaultDocumentInteroperabilityRegistry.create(
      formalSystems: DefaultTransducerRegistry.registry,
    );
  });

  test('operational module registers session, examples, and two codecs',
      () async {
    final module = DefaultTransducerRegistry.registry.moduleFor(
      TransducerFormalSystemIds.mealy,
    );

    expect(module, isNotNull);
    expect(module!.session, isNotNull);
    expect(module.examples, isNotNull);
    expect(module.codecs.map((codec) => codec.descriptor.codecId.value), {
      'mealy.jflap-xml.v1',
      'mealy.turing-lab-json.v1',
    });
    expect(await module.examples!.loadExamples(), hasLength(4));
  });

  test('JFLAP reordered elements keep machine and transition identities', () {
    const first = '''
<structure><type>mealy</type><automaton>
<state id="0" name="q0"><x>0</x><y>0</y><initial/></state>
<state id="1" name="q1"><x>100</x><y>0</y></state>
<transition><from>0</from><to>1</to><read>a</read><transout>x</transout></transition>
<transition><from>1</from><to>0</to><read>b</read><transout>y</transout></transition>
</automaton></structure>''';
    const reordered = '''
<structure><type>mealy</type><automaton>
<transition><transout>y</transout><read>b</read><to>0</to><from>1</from></transition>
<state name="q1" id="1"><y>0</y><x>100</x></state>
<transition><transout>x</transout><to>1</to><from>0</from><read>a</read></transition>
<state name="q0" id="0"><initial/><y>0</y><x>0</x></state>
</automaton></structure>''';

    final left = _decodeJflapFixture(first);
    final right = _decodeJflapFixture(reordered);
    expect(right.id, left.id);
    expect(
      right.transitions.map((transition) => transition.id).toList(),
      left.transitions.map((transition) => transition.id).toList(),
    );
    expect(right.toJson(), left.toJson());
  });

  test('JFLAP final metadata is preserved but never becomes acceptance', () {
    const xml = '''
<structure><type>mealy</type><automaton>
<state id="0" name="q0"><x>0</x><y>0</y><initial/><final/></state>
</automaton></structure>''';
    final outcome = const MealyJflapDocumentCodec().decode(
      _payload(xml, filename: 'legacy-final.jff'),
    );

    expect(outcome, isA<CodecSuccess<InteroperableDocument<Object>>>());
    final success = outcome as CodecSuccess<InteroperableDocument<Object>>;
    final machine = success.value.document as MealyMachine;
    expect(machine.states.single.isInitial, isTrue);
    expect(machine.toJson().toString(), isNot(contains('accept')));
    expect(success.value.extensions.values['stateChildren.0'], ['<final/>']);
  });

  test('JFLAP notes round-trip through typed annotations with loss review', () {
    const source = '''
<structure><type>mealy</type><automaton>
<state id="0" name="q0"><x>0</x><y>0</y><initial/></state>
<note><text>Unicode λ, 漢字, 🧠</text><x>45</x><y>55</y></note>
</automaton></structure>''';
    const codec = MealyJflapDocumentCodec();
    final decoded = codec.decode(_payload(source))
        as CodecSuccess<InteroperableDocument<Object>>;
    final imported = annotationsFromExtensions(decoded.value.extensions)!;

    expect(imported.annotations.single.text, 'Unicode λ, 漢字, 🧠');
    expect(imported.annotations.single.x, 45);
    expect(imported.annotations.single.y, 55);
    expect(
      codec.descriptor.semanticCapabilities,
      contains(CodecSemanticCapabilityId.notes),
    );

    final styled = DocumentAnnotationCollection(
      documentId: imported.documentId,
      documentRevision: imported.documentRevision,
      annotations: [
        imported.annotations.single.copyWith(
          width: 320,
          styleRole: AnnotationStyleRole.warning,
        ),
      ],
    );
    final encoded = codec.encode(
      InteroperableDocument<Object>(
        document: decoded.value.document,
        systemKey: decoded.value.systemKey,
        schema: decoded.value.schema,
        extensions: extensionsWithAnnotations(
          decoded.value.extensions,
          styled,
        ),
      ),
    ) as CodecSuccess<EncodedDocument>;

    expect(encoded.fidelity, DocumentFidelity.lossy);
    expect(
      encoded.diagnostics.map((diagnostic) => diagnostic.code),
      contains('jflap.note-presentation-dropped'),
    );
    final restored = codec.decode(
      DocumentPayload(bytes: encoded.value.bytes, filename: 'restored.jff'),
    ) as CodecSuccess<InteroperableDocument<Object>>;
    final restoredNote = annotationsFromExtensions(restored.value.extensions)!
        .annotations
        .single;
    expect(restoredNote.text, 'Unicode λ, 漢字, 🧠');
    expect(restoredNote.x, 45);
    expect(restoredNote.y, 55);
  });

  test(
      'JFLAP preserves Unicode, multi-character input, empty output, and extras',
      () {
    const xml = '''
<structure vendor="lab"><type>mealy</type><automaton>
<state id="α" name="início" custom="yes"><x>0</x><y>0</y><initial/><note>n</note></state>
<transition extra="v"><from>α</from><to>α</to><read>🙂ab</read><transout/><hint>h</hint></transition>
</automaton></structure>''';
    final decoded = const MealyJflapDocumentCodec().decode(_payload(xml));
    expect(decoded, isA<CodecSuccess<InteroperableDocument<Object>>>());
    final success = decoded as CodecSuccess<InteroperableDocument<Object>>;
    final machine = success.value.document as MealyMachine;
    expect(machine.inputAlphabet.single.value, '🙂ab');
    expect(machine.transitions.single.output, TransducerOutputWord.empty);
    expect(success.value.extensions.values, contains('rootAttributes'));
    expect(success.value.extensions.values, contains('stateAttributes.α'));
    expect(success.value.extensions.values, contains('stateChildren.α'));
    final transitionId = machine.transitions.single.id.value;
    expect(
      success.value.extensions.values,
      contains('transitionAttributes.$transitionId'),
    );
    final encoded = const MealyJflapDocumentCodec().encode(success.value);
    expect(encoded, isA<CodecSuccess<EncodedDocument>>());
    final text = utf8.decode(
      (encoded as CodecSuccess<EncodedDocument>).value.bytes,
    );
    expect(text, contains('vendor="lab"'));
    expect(text, contains('custom="yes"'));
    expect(text, contains('<note>n</note>'));
    expect(text, contains('<hint>h</hint>'));
    expect(text, contains('<read>🙂ab</read>'));
    expect(text, contains('<transout/>'));
  });

  test('JFLAP rejects duplicate deterministic input and malformed XML', () {
    const duplicate = '''
<structure><type>mealy</type><automaton>
<state id="0"><x>0</x><y>0</y><initial/></state>
<state id="1"><x>1</x><y>0</y></state>
<transition><from>0</from><to>0</to><read>a</read><transout>x</transout></transition>
<transition><from>0</from><to>1</to><read>a</read><transout>y</transout></transition>
</automaton></structure>''';
    expect(
      const MealyJflapDocumentCodec().decode(_payload(duplicate)),
      isA<CodecMalformed<InteroperableDocument<Object>>>(),
    );
    expect(
      const MealyJflapDocumentCodec().decode(_payload('<structure>')),
      isA<CodecMalformed<InteroperableDocument<Object>>>(),
    );
  });

  test('multi-token JFLAP output is lossy and export needs consent', () async {
    const codec = MealyJflapDocumentCodec();
    final outcome = codec.encode(InteroperableDocument<Object>(
      document: _machine(output: const ['left', 'right']),
      systemKey: TransducerFormalSystemIds.mealy,
      schema: MealyJflapDocumentCodec.schema,
    ));

    expect(outcome, isA<CodecSuccess<EncodedDocument>>());
    final success = outcome as CodecSuccess<EncodedDocument>;
    expect(success.fidelity, DocumentFidelity.lossy);
    expect(
      success.diagnostics.map((diagnostic) => diagnostic.code),
      contains('jflap.mealy.output-token-boundaries-dropped'),
    );
    final transport = MemoryDocumentTransport();
    final transaction = DocumentExportTransaction.prepare(
      outcome: outcome,
      transport: transport,
      location: 'machine.jff',
    );
    expect(transaction.requiresLossConfirmation, isTrue);
    await expectLater(transaction.commit(), throwsStateError);
    await transaction.commit(allowLossy: true);
    expect((await transport.read('machine.jff')).bytes, success.value.bytes);
  });

  test('canonical JFLAP and JSON fixtures round trip deterministically', () {
    for (final path in const [
      'test/fixtures/interoperability/mealy_canonical.jff',
      'test/fixtures/interoperability/mealy_canonical.json',
    ]) {
      final payload = DocumentPayload(
        bytes: File(path).readAsBytesSync(),
        filename: path,
        sourcePath: path,
      );
      final decoded = registry.decode(payload);
      expect(decoded, isA<CodecSuccess<InteroperableDocument<Object>>>(),
          reason: path);
      final document =
          (decoded as CodecSuccess<InteroperableDocument<Object>>).value;
      final format = path.endsWith('.jff')
          ? DefaultFormalSystemIds.jflapXmlFormat
          : DefaultFormalSystemIds.turingLabJsonFormat;
      final first = registry.encode(document, format: format);
      expect(first, isA<CodecSuccess<EncodedDocument>>(), reason: path);
      final firstBytes = (first as CodecSuccess<EncodedDocument>).value.bytes;
      final secondDecode = registry.decode(DocumentPayload(
        bytes: firstBytes,
        filename: path,
      ));
      expect(secondDecode, isA<CodecSuccess<InteroperableDocument<Object>>>(),
          reason: path);
      final second = registry.encode(
        (secondDecode as CodecSuccess<InteroperableDocument<Object>>).value,
        format: format,
      );
      expect((second as CodecSuccess<EncodedDocument>).value.bytes, firstBytes,
          reason: path);
    }
  });

  test('future JSON schema and malformed payload have typed outcomes', () {
    final current = File(
      'test/fixtures/interoperability/mealy_canonical.json',
    ).readAsStringSync();
    final futureJson = jsonDecode(current) as Map<String, dynamic>;
    final document = futureJson['document'] as Map<String, dynamic>;
    final schema = document['schema'] as Map<String, dynamic>;
    schema['version'] = 2;
    final future = jsonEncode(futureJson);
    expect(
      registry.decode(_payload(future, filename: 'future.json')),
      isA<CodecUnsupported<InteroperableDocument<Object>>>(),
    );
    expect(
      registry.decode(
        _payload('{"format":', filename: 'broken.json'),
        expectedSystem: TransducerFormalSystemIds.mealy,
        expectedFormat: DefaultFormalSystemIds.turingLabJsonFormat,
      ),
      isA<CodecMalformed<InteroperableDocument<Object>>>(),
    );
  });

  test('JSON rejects structurally invalid Mealy machines', () {
    final fixture = jsonDecode(
      File('test/fixtures/interoperability/mealy_canonical.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;
    final document = fixture['document'] as Map<String, dynamic>;
    final payload = document['payload'] as Map<String, dynamic>;

    final invalidPayloads = <Map<String, dynamic>>[
      _mutate(payload, (copy) {
        final states = copy['states'] as List<dynamic>;
        states.add(Map<String, dynamic>.from(states.first as Map));
      }),
      _mutate(payload, (copy) {
        final states = copy['states'] as List<dynamic>;
        (states[1] as Map<String, dynamic>)['isInitial'] = true;
      }),
      _mutate(payload, (copy) {
        final transitions = copy['transitions'] as List<dynamic>;
        (transitions.first as Map<String, dynamic>)['to'] = 'missing';
      }),
      _mutate(payload, (copy) {
        final transitions = copy['transitions'] as List<dynamic>;
        (transitions.first as Map<String, dynamic>)['input'] = 'outside';
      }),
    ];

    for (final invalidPayload in invalidPayloads) {
      final invalidEnvelope =
          jsonDecode(jsonEncode(fixture)) as Map<String, dynamic>;
      final invalidDocument =
          invalidEnvelope['document'] as Map<String, dynamic>;
      invalidDocument['payload'] = invalidPayload;
      final outcome = MealyJsonDocumentCodec().decode(
        _payload(jsonEncode(invalidEnvelope), filename: 'invalid.json'),
      );
      expect(
        outcome,
        isA<CodecMalformed<InteroperableDocument<Object>>>(),
        reason: invalidPayload.toString(),
      );
    }
  });
}

Map<String, dynamic> _mutate(
  Map<String, dynamic> source,
  void Function(Map<String, dynamic>) mutation,
) {
  final copy = jsonDecode(jsonEncode(source)) as Map<String, dynamic>;
  mutation(copy);
  return copy;
}

MealyMachine _decodeJflapFixture(String xml) {
  final outcome = const MealyJflapDocumentCodec().decode(_payload(xml));
  expect(outcome, isA<CodecSuccess<InteroperableDocument<Object>>>());
  return (outcome as CodecSuccess<InteroperableDocument<Object>>).value.document
      as MealyMachine;
}

DocumentPayload _payload(String value, {String filename = 'machine.jff'}) =>
    DocumentPayload(
      bytes: Uint8List.fromList(utf8.encode(value)),
      filename: filename,
    );

MealyMachine _machine({required List<String> output}) => MealyMachine(
      id: const TransducerMachineId('machine'),
      name: 'Machine',
      revision: const TransducerRevision(1),
      inputAlphabet: {const TransducerInputSymbol('a')},
      outputAlphabet: output.map(TransducerOutputSymbol.new),
      states: const [
        MealyState(
          id: TransducerStateId('q0'),
          label: 'q0',
          position: TransducerPoint(0, 0),
          isInitial: true,
        ),
      ],
      transitions: [
        MealyTransition(
          id: const TransducerTransitionId('t0'),
          from: const TransducerStateId('q0'),
          to: const TransducerStateId('q0'),
          input: const TransducerInputSymbol('a'),
          output: TransducerOutputWord.fromValues(output),
        ),
      ],
    );
