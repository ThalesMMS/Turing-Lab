import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/annotations/annotations.dart';
import 'package:turing_lab/core/algorithms/pda_simulator.dart';
import 'package:turing_lab/core/formal_systems/formal_systems.dart';
import 'package:turing_lab/core/interoperability/interoperability.dart';
import 'package:turing_lab/core/models/pda.dart';
import 'package:turing_lab/core/models/pda_transition.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/data/codecs/default_document_interoperability_registry.dart';
import 'package:turing_lab/data/codecs/pda_jflap_document_codec.dart';
import 'package:turing_lab/data/codecs/pda_json_document_codec.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  final registry = DefaultDocumentInteroperabilityRegistry.create();

  test('canonical PDA fixtures are registered and importable', () {
    for (final fixture in const [
      'test/fixtures/interoperability/pda_canonical.json',
      'test/fixtures/interoperability/pda_canonical.jff',
    ]) {
      final decoded = registry.decode(
        DocumentPayload(
          bytes: File(fixture).readAsBytesSync(),
          filename: fixture,
        ),
        expectedSystem: DefaultFormalSystemIds.pda,
        expectedFormat: fixture.endsWith('.json')
            ? DefaultFormalSystemIds.turingLabJsonFormat
            : DefaultFormalSystemIds.jflapXmlFormat,
      );

      expect(
        decoded,
        isA<CodecSuccess<InteroperableDocument<Object>>>(),
        reason: fixture,
      );
      final pda = (decoded as CodecSuccess<InteroperableDocument<Object>>)
          .value
          .document as PDA;
      expect(pda.initialState?.id, 'q0');
      expect(pda.pdaTransitions.single.pushSymbols, ['A', 'Z']);
    }
  });

  test('canonical JSON preserves tokens, epsilon flags, mode, and extensions',
      () {
    final source = _document(
      extensions: DocumentExtensionBag({
        'future': {'kept': true}
      }),
    );
    final encoded =
        PdaJsonDocumentCodec().encode(source) as CodecSuccess<EncodedDocument>;
    final decoded = PdaJsonDocumentCodec().decode(
      DocumentPayload(bytes: encoded.value.bytes, filename: 'machine.data'),
    ) as CodecSuccess<InteroperableDocument<Object>>;
    final pda = decoded.value.document as PDA;

    expect(encoded.fidelity, DocumentFidelity.exact);
    expect(pda.acceptanceMode, PDAAcceptanceMode.both);
    expect(pda.initialStackSymbol, 'BOTTOM');
    expect(pda.pdaTransitions.single.pushSymbols, ['LONG', 'BOTTOM']);
    expect(pda.pdaTransitions.single.isLambdaPop, isFalse);
    expect(decoded.value.extensions.values['future'], {'kept': true});
  });

  test('both codecs preserve every local acceptance mode', () {
    for (final mode in PDAAcceptanceMode.values) {
      final source = _document(acceptanceMode: mode);
      final json = PdaJsonDocumentCodec().encode(source)
          as CodecSuccess<EncodedDocument>;
      final jsonDecoded = PdaJsonDocumentCodec().decode(
        DocumentPayload(bytes: json.value.bytes, filename: 'machine.json'),
      ) as CodecSuccess<InteroperableDocument<Object>>;
      expect((jsonDecoded.value.document as PDA).acceptanceMode, mode);

      final xml = const PdaJflapDocumentCodec().encode(source)
          as CodecSuccess<EncodedDocument>;
      final xmlDecoded = const PdaJflapDocumentCodec().decode(
        DocumentPayload(bytes: xml.value.bytes, filename: 'machine.jff'),
      ) as CodecSuccess<InteroperableDocument<Object>>;
      expect((xmlDecoded.value.document as PDA).acceptanceMode, mode);
    }
  });

  test('Turing Lab JFLAP extension round-trips atomic stack tokens locally',
      () {
    const codec = PdaJflapDocumentCodec();
    final encoded = codec.encode(_document()) as CodecSuccess<EncodedDocument>;
    final decoded = codec.decode(
      DocumentPayload(bytes: encoded.value.bytes, filename: 'machine.jff'),
    ) as CodecSuccess<InteroperableDocument<Object>>;
    final pda = decoded.value.document as PDA;

    expect(encoded.fidelity, DocumentFidelity.lossy);
    expect(
      encoded.diagnostics.map((item) => item.code),
      contains('jflap.pda-turing-lab-extension-portability'),
    );
    expect(decoded.fidelity, DocumentFidelity.exact);
    expect(pda.acceptanceMode, PDAAcceptanceMode.both);
    expect(pda.initialStackSymbol, 'BOTTOM');
    expect(pda.pdaTransitions.single.id, 'transition-id');
    expect(pda.pdaTransitions.single.pushSymbols, ['LONG', 'BOTTOM']);
  });

  test('standard JFLAP normalizes push text and assumes final-state mode', () {
    const codec = PdaJflapDocumentCodec();
    final decoded = codec.decode(_payload(_standardJflap))
        as CodecSuccess<InteroperableDocument<Object>>;
    final pda = decoded.value.document as PDA;

    expect(decoded.fidelity, DocumentFidelity.normalized);
    expect(pda.acceptanceMode, PDAAcceptanceMode.finalState);
    expect(pda.initialStackSymbol, 'Z');
    expect(pda.pdaTransitions.single.pushSymbols, ['A', 'Z']);
    expect(
      decoded.diagnostics.map((item) => item.code),
      contains('jflap.pda-acceptance-mode-assumed-final-state'),
    );
  });

  test('JFLAP PDA notes round-trip through typed annotations', () {
    const codec = PdaJflapDocumentCodec();
    final source = _standardJflap.replaceFirst(
      '</automaton>',
      '<note><text>PDA invariant</text><x>45</x><y>55</y></note>'
          '</automaton>',
    );

    final decoded = codec.decode(_payload(source))
        as CodecSuccess<InteroperableDocument<Object>>;
    final annotations = annotationsFromExtensions(decoded.value.extensions)!;
    expect(annotations.annotations.single.text, 'PDA invariant');

    final encoded =
        codec.encode(decoded.value) as CodecSuccess<EncodedDocument>;
    final restored = codec.decode(
      DocumentPayload(bytes: encoded.value.bytes, filename: 'notes.jff'),
    ) as CodecSuccess<InteroperableDocument<Object>>;
    expect(
      annotationsFromExtensions(restored.value.extensions)!
          .annotations
          .single
          .text,
      'PDA invariant',
    );
  });

  test('standard JFLAP reports multi-character pop semantics as lossy', () {
    final source = _standardJflap.replaceFirst('<pop>Z</pop>', '<pop>AZ</pop>');
    final decoded = const PdaJflapDocumentCodec().decode(_payload(source))
        as CodecSuccess<InteroperableDocument<Object>>;

    expect(decoded.fidelity, DocumentFidelity.lossy);
    expect(
      decoded.diagnostics.map((item) => item.code),
      contains('jflap.pda-pop-word-treated-as-atomic-token'),
    );
  });

  test('epsilon aliases become explicit flags without phantom symbols', () {
    const codec = PdaJflapDocumentCodec();
    final source = _standardJflap
        .replaceFirst('<read>a</read>', '<read>eps</read>')
        .replaceFirst('<pop>Z</pop>', '<pop>λ</pop>')
        .replaceFirst('<push>AZ</push>', '<push>epsilon</push>');
    final decoded = codec.decode(_payload(source))
        as CodecSuccess<InteroperableDocument<Object>>;
    final transition = (decoded.value.document as PDA).pdaTransitions.single;

    expect(decoded.fidelity, DocumentFidelity.lossy);
    expect(transition.isLambdaInput, isTrue);
    expect(transition.isLambdaPop, isTrue);
    expect(transition.isLambdaPush, isTrue);
    expect(transition.inputSymbol, isEmpty);
    expect(transition.popSymbol, isEmpty);
    expect(transition.pushSymbols, isEmpty);
  });

  test('self-closing JFLAP operations represent lambda without aliases', () {
    final source = _standardJflap
        .replaceFirst('<read>a</read>', '<read/>')
        .replaceFirst('<pop>Z</pop>', '<pop/>')
        .replaceFirst('<push>AZ</push>', '<push/>');
    final decoded = const PdaJflapDocumentCodec().decode(_payload(source))
        as CodecSuccess<InteroperableDocument<Object>>;
    final transition = (decoded.value.document as PDA).pdaTransitions.single;

    expect(transition.isLambdaInput, isTrue);
    expect(transition.isLambdaPop, isTrue);
    expect(transition.isLambdaPush, isTrue);
    expect(transition.pushSymbols, isEmpty);
  });

  test('endpoint resolution uses ids even when labels collide with ids', () {
    const source = '''
<structure><type>pda</type><automaton>
  <state id="0" name="1"><x>0</x><y>0</y><initial/></state>
  <state id="1" name="0"><x>100</x><y>0</y><final/></state>
  <transition><from>0</from><to>1</to><read>a</read><pop>Z</pop><push>Z</push></transition>
</automaton></structure>
''';
    final decoded = const PdaJflapDocumentCodec().decode(_payload(source))
        as CodecSuccess<InteroperableDocument<Object>>;
    final transition = (decoded.value.document as PDA).pdaTransitions.single;

    expect(transition.fromState.id, '0');
    expect(transition.toState.id, '1');
    expect(transition.fromState.label, '1');
    expect(transition.toState.label, '0');
  });

  test('malformed identities and endpoints return typed paths', () {
    final cases = [
      _standardJflap.replaceFirst('id="q1"', 'id="q0"'),
      _standardJflap.replaceFirst('<to>q1</to>', '<to>missing</to>'),
    ];
    for (final source in cases) {
      final decoded = const PdaJflapDocumentCodec().decode(_payload(source));
      expect(decoded, isA<CodecMalformed<InteroperableDocument<Object>>>());
      expect(
        (decoded as CodecMalformed<InteroperableDocument<Object>>)
            .location
            ?.path,
        contains('/structure/automaton'),
      );
    }
  });

  test('empty and malformed PDA documents fail without replacing a model', () {
    final cases = <CodecOutcome<InteroperableDocument<Object>>>[
      const PdaJflapDocumentCodec().decode(
        _payload('<structure><type>pda</type><automaton/></structure>'),
      ),
      const PdaJflapDocumentCodec().decode(_payload('<structure><type>pda')),
      PdaJsonDocumentCodec().decode(_payload('{not-json')),
    ];

    for (final outcome in cases) {
      expect(outcome, isA<CodecMalformed<InteroperableDocument<Object>>>());
      expect(
        (outcome as CodecMalformed<InteroperableDocument<Object>>).location,
        isNotNull,
      );
    }
  });

  test('duplicate explicit JFLAP transition ids report the extension path', () {
    const source = '''
<structure><type>pda</type><automaton>
  <state id="q0" name="q0"><x>0</x><y>0</y><initial/></state>
  <state id="q1" name="q1"><x>100</x><y>0</y><final/></state>
  <transition><from>q0</from><to>q1</to><read>a</read><pop>Z</pop><push>Z</push><turingLabTransition>{"id":"same"}</turingLabTransition></transition>
  <transition><from>q0</from><to>q1</to><read>b</read><pop>Z</pop><push>Z</push><turingLabTransition>{"id":"same"}</turingLabTransition></transition>
</automaton></structure>
''';
    final decoded = const PdaJflapDocumentCodec().decode(_payload(source));

    expect(decoded, isA<CodecMalformed<InteroperableDocument<Object>>>());
    expect(
      (decoded as CodecMalformed<InteroperableDocument<Object>>).location?.path,
      contains('turingLabTransition'),
    );
  });

  test('invalid acceptance modes are rejected by both versioned codecs', () {
    final jsonSource = jsonDecode(
      File(
        'test/fixtures/interoperability/pda_canonical.json',
      ).readAsStringSync(),
    ) as Map<String, dynamic>
      ..['acceptanceMode'] = 'sometimes';
    final jsonOutcome = PdaJsonDocumentCodec().decode(
      _payload(jsonEncode(jsonSource)),
    );
    expect(
      jsonOutcome,
      isA<CodecMalformed<InteroperableDocument<Object>>>(),
    );

    final xmlSource = utf8
        .decode(
          (const PdaJflapDocumentCodec().encode(_document())
                  as CodecSuccess<EncodedDocument>)
              .value
              .bytes,
        )
        .replaceFirst(
            '"acceptanceMode":"both"', '"acceptanceMode":"sometimes"');
    final xmlOutcome = const PdaJflapDocumentCodec().decode(
      _payload(xmlSource),
    );
    expect(xmlOutcome, isA<CodecMalformed<InteroperableDocument<Object>>>());
    expect(
      (xmlOutcome as CodecMalformed<InteroperableDocument<Object>>)
          .location
          ?.path,
      '/structure/turingLabPda/acceptanceMode',
    );
  });

  test('unknown JFLAP XML survives a local decode-encode cycle', () {
    const source = '''
<structure vendor="root"><type>pda</type><vendorRoot key="one"/><automaton vendor="automaton">
  <state id="q0" name="q0" vendor="state"><x>0</x><y>0</y><initial/><vendorState/></state>
  <state id="q1" name="q1"><x>100</x><y>0</y><final/></state>
  <transition vendor="edge"><from>q0</from><to>q1</to><read>a</read><pop>Z</pop><push>Z</push><vendorEdge/></transition>
  <vendorAutomaton/>
</automaton></structure>
''';
    const codec = PdaJflapDocumentCodec();
    final decoded = codec.decode(_payload(source))
        as CodecSuccess<InteroperableDocument<Object>>;
    final encoded =
        codec.encode(decoded.value) as CodecSuccess<EncodedDocument>;
    final xml = utf8.decode(encoded.value.bytes);

    expect(xml, contains('vendor="root"'));
    expect(xml, contains('<vendorRoot key="one"'));
    expect(xml, contains('vendor="automaton"'));
    expect(xml, contains('vendor="state"'));
    expect(xml, contains('<vendorState'));
    expect(xml, contains('vendor="edge"'));
    expect(xml, contains('<vendorEdge'));
    expect(xml, contains('<vendorAutomaton'));
  });

  test('element order canonicalizes to stable identities and JSON', () {
    const codec = PdaJflapDocumentCodec();
    final original = codec.decode(_payload(_standardJflap))
        as CodecSuccess<InteroperableDocument<Object>>;
    final reordered = codec.decode(_payload(_reorderedJflap))
        as CodecSuccess<InteroperableDocument<Object>>;
    final originalPda = original.value.document as PDA;
    final reorderedPda = reordered.value.document as PDA;

    expect(reorderedPda.id, originalPda.id);
    expect(
      reorderedPda.pdaTransitions.single.id,
      originalPda.pdaTransitions.single.id,
    );
    final jsonCodec = PdaJsonDocumentCodec();
    final originalJson =
        jsonCodec.encode(original.value) as CodecSuccess<EncodedDocument>;
    final reorderedJson =
        jsonCodec.encode(reordered.value) as CodecSuccess<EncodedDocument>;
    expect(reorderedJson.value.bytes, originalJson.value.bytes);
  });

  test('bounded behavior is unchanged by a local JFLAP cycle', () {
    const codec = PdaJflapDocumentCodec();
    final imported = codec.decode(_payload(_standardJflap))
        as CodecSuccess<InteroperableDocument<Object>>;
    final encoded =
        codec.encode(imported.value) as CodecSuccess<EncodedDocument>;
    final roundTripped = codec.decode(
      DocumentPayload(bytes: encoded.value.bytes, filename: 'cycle.jff'),
    ) as CodecSuccess<InteroperableDocument<Object>>;
    final before = imported.value.document as PDA;
    final after = roundTripped.value.document as PDA;

    for (final input in const ['', 'a', 'aa']) {
      final beforeResult = PDASimulator.simulateNPDA(
        before,
        input,
        mode: before.acceptanceMode,
        maxDepth: 20,
        maxConfigurations: 100,
      );
      final afterResult = PDASimulator.simulateNPDA(
        after,
        input,
        mode: after.acceptanceMode,
        maxDepth: 20,
        maxConfigurations: 100,
      );
      expect(afterResult.data?.accepted, beforeResult.data?.accepted);
    }
  });

  test('legacy JSON infers explicit flags and Unicode scalar push tokens', () {
    final legacy = jsonDecode(
      File(
        'test/fixtures/interoperability/pda_canonical.json',
      ).readAsStringSync(),
    ) as Map<String, dynamic>;
    final transition =
        (legacy['transitions'] as List).single as Map<String, dynamic>;
    transition
      ..remove('pushSymbols')
      ..remove('isLambdaInput')
      ..remove('isLambdaPop')
      ..remove('isLambdaPush')
      ..['pushSymbol'] = '🙂Z';
    (legacy['stackAlphabet'] as List).add('🙂');
    legacy.remove('acceptanceMode');

    final decoded = PdaJsonDocumentCodec().decode(
      _payload(jsonEncode(legacy)),
    ) as CodecSuccess<InteroperableDocument<Object>>;
    final pda = decoded.value.document as PDA;

    expect(pda.pdaTransitions.single.pushSymbols, ['🙂', 'Z']);
    expect(pda.acceptanceMode, PDAAcceptanceMode.finalState);
    expect(decoded.fidelity, DocumentFidelity.normalized);
  });

  test('content detection ignores a wrong filename extension', () {
    final decoded = registry.detect(
      _payload(_standardJflap, filename: 'renamed.txt'),
    ) as CodecSuccess<DetectedDocument>;

    expect(decoded.value.descriptor.systemKey, DefaultFormalSystemIds.pda);
  });
}

InteroperableDocument<Object> _document({
  DocumentExtensionBag? extensions,
  PDAAcceptanceMode acceptanceMode = PDAAcceptanceMode.both,
}) {
  final q0 = State(
    id: 'state-start',
    label: 'start',
    position: Vector2(10, 20),
    isInitial: true,
  );
  final q1 = State(
    id: 'state-final',
    label: 'final',
    position: Vector2(200, 20),
    isAccepting: true,
    properties: const {'note': 'kept'},
  );
  final transition = PDATransition(
    id: 'transition-id',
    fromState: q0,
    toState: q1,
    label: 'token, BOTTOM/LONG BOTTOM',
    controlPoint: Vector2(90, -30),
    inputSymbol: 'token',
    popSymbol: 'BOTTOM',
    pushSymbol: 'LONGBOTTOM',
    pushSymbols: const ['LONG', 'BOTTOM'],
  );
  return InteroperableDocument<Object>(
    document: PDA(
      id: 'pda-token-safe',
      name: 'Token-safe PDA',
      states: {q0, q1},
      transitions: {transition},
      alphabet: const {'token'},
      initialState: q0,
      acceptingStates: {q1},
      created: DateTime.utc(2026),
      modified: DateTime.utc(2026),
      bounds: const math.Rectangle(0, 0, 400, 300),
      stackAlphabet: const {'BOTTOM', 'LONG'},
      initialStackSymbol: 'BOTTOM',
      acceptanceMode: acceptanceMode,
    ),
    systemKey: DefaultFormalSystemIds.pda,
    schema: PdaJsonDocumentCodec.schema,
    extensions: extensions ?? DocumentExtensionBag(),
  );
}

DocumentPayload _payload(String source, {String? filename}) => DocumentPayload(
      bytes: utf8.encode(source),
      filename: filename,
    );

const _standardJflap = '''
<?xml version="1.0" encoding="UTF-8"?>
<structure>
  <type>pda</type>
  <automaton>
    <state id="q0" name="q0"><x>0</x><y>0</y><initial/></state>
    <state id="q1" name="q1"><x>100</x><y>0</y><final/></state>
    <transition>
      <from>q0</from><to>q1</to><read>a</read><pop>Z</pop><push>AZ</push>
    </transition>
  </automaton>
</structure>
''';

const _reorderedJflap = '''
<?xml version="1.0" encoding="UTF-8"?>
<structure>
  <type>pda</type>
  <automaton>
    <transition>
      <push>AZ</push><pop>Z</pop><read>a</read><to>q1</to><from>q0</from>
    </transition>
    <state id="q1" name="q1"><final/><y>0</y><x>100</x></state>
    <state id="q0" name="q0"><initial/><y>0</y><x>0</x></state>
  </automaton>
</structure>
''';
