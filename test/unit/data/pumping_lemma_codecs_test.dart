import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/formal_systems/formal_systems.dart';
import 'package:turing_lab/core/interoperability/interoperability.dart';
import 'package:turing_lab/core/pumping_lemma/pumping_lemma.dart';
import 'package:turing_lab/data/codecs/pumping_lemma_jflap_codec.dart';
import 'package:turing_lab/data/codecs/pumping_lemma_json_codec.dart';

void main() {
  group('Turing Lab pumping lemma JSON', () {
    for (final theorem in PumpingLemmaTheorem.values) {
      test('${theorem.name} round trip preserves typed session state', () {
        final codec = theorem == PumpingLemmaTheorem.regular
            ? const PumpingLemmaJsonCodec.regular()
            : const PumpingLemmaJsonCodec.contextFree();
        final source = _source(theorem);

        final encoded = codec.encode(source) as CodecSuccess<EncodedDocument>;
        final decoded = codec.decode(
          DocumentPayload(bytes: encoded.value.bytes, filename: 'session.json'),
        ) as CodecSuccess<InteroperableDocument<Object>>;

        expect(encoded.fidelity, DocumentFidelity.exact);
        expect(decoded.fidelity, DocumentFidelity.exact);
        expect(
          (decoded.value.document as PumpingLemmaDocument).toJson(),
          (source.document as PumpingLemmaDocument).toJson(),
        );
      });
    }

    test('wrong theorem and malformed JSON return typed failures', () {
      const regular = PumpingLemmaJsonCodec.regular();
      const cfl = PumpingLemmaJsonCodec.contextFree();
      final encoded = regular.encode(_source(PumpingLemmaTheorem.regular))
          as CodecSuccess<EncodedDocument>;

      expect(
        cfl.decode(DocumentPayload(bytes: encoded.value.bytes)),
        isA<CodecUnsupported<InteroperableDocument<Object>>>(),
      );
      expect(
        regular.decode(_payload('{"schema":false}')),
        isA<CodecMalformed<InteroperableDocument<Object>>>(),
      );
      expect(
        regular.decode(_payload(
          '{"schema":{"id":"turing-lab.pumping-lemma","version":2}}',
        )),
        isA<CodecUnsupported<InteroperableDocument<Object>>>(),
      );
    });
  });

  group('JFLAP pumping lemma XML', () {
    test('imports regular and CFL segment lengths into distinct models', () {
      const regularCodec = PumpingLemmaJflapCodec.regular();
      const cflCodec = PumpingLemmaJflapCodec.contextFree();
      final regular = regularCodec.decode(_payload('''
<structure><type>regular pumping lemma</type><name>Equal blocks</name>
<first_player>Human</first_player><m>2</m><w>aabb</w><i>0</i>
<xLength>0</xLength><yLength>1</yLength></structure>'''))
          as CodecSuccess<InteroperableDocument<Object>>;
      final cfl = cflCodec.decode(_payload('''
<structure><type>context-free pumping lemma</type><name>Three blocks</name>
<first_player>Human</first_player><m>2</m><w>aabbcc</w><i>0</i>
<uLength>0</uLength><vLength>1</vLength><xLength>0</xLength>
<yLength>1</yLength></structure>'''))
          as CodecSuccess<InteroperableDocument<Object>>;

      expect(regular.fidelity, DocumentFidelity.normalized);
      expect(regular.value.document, isA<RegularPumpingLemmaDocument>());
      expect(cfl.value.document, isA<ContextFreePumpingLemmaDocument>());
      expect(
        (regular.value.document as RegularPumpingLemmaDocument)
            .session
            .pumpedWord,
        ['a', 'b', 'b'],
      );
      expect(
        (cfl.value.document as ContextFreePumpingLemmaDocument)
            .session
            .pumpedWord,
        ['b', 'b', 'c', 'c'],
      );
    });

    test('local extension round trip preserves token vectors and progress', () {
      const codec = PumpingLemmaJflapCodec.contextFree();
      final source = _source(PumpingLemmaTheorem.contextFree);
      final encoded = codec.encode(source) as CodecSuccess<EncodedDocument>;
      final decoded = codec.decode(DocumentPayload(bytes: encoded.value.bytes))
          as CodecSuccess<InteroperableDocument<Object>>;

      expect(encoded.fidelity, DocumentFidelity.normalized);
      expect(decoded.fidelity, DocumentFidelity.exact);
      expect(
        (decoded.value.document as PumpingLemmaDocument).toJson(),
        (source.document as PumpingLemmaDocument).toJson(),
      );
    });

    test('malformed, unsafe, and theorem-mismatched XML fail typingly', () {
      const codec = PumpingLemmaJflapCodec.regular();
      expect(
        codec.decode(_payload('<structure>')),
        isA<CodecMalformed<InteroperableDocument<Object>>>(),
      );
      expect(
        codec.decode(_payload(
          '<!DOCTYPE x [<!ENTITY y "z">]><structure/>',
        )),
        isA<CodecResourceLimit<InteroperableDocument<Object>>>(),
      );
      expect(
        codec.decode(_payload(
          '<structure><type>context-free pumping lemma</type></structure>',
        )),
        isA<CodecUnsupported<InteroperableDocument<Object>>>(),
      );
    });
  });
}

InteroperableDocument<Object> _source(PumpingLemmaTheorem theorem) {
  if (theorem == PumpingLemmaTheorem.regular) {
    final problem = PumpingLemmaProblemCatalog.regular.first;
    return InteroperableDocument<Object>(
      document: RegularPumpingLemmaDocument(
        problem: problem,
        session: PumpingLemmaSession<RegularPumpingDecomposition>(
          sessionId: 'regular-session',
          challengeId: problem.id,
          sourceRevision: problem.sourceRevision,
          theorem: theorem,
          mode: PumpingLemmaMode.guidedPractice,
          role: PumpingLemmaRole.learner,
          targetLanguage: problem.languageDescription,
          pumpingLength: 2,
          witness: const ['a', 'a', 'b', 'b'],
          decomposition: RegularPumpingDecomposition(
            x: const [],
            y: const ['a'],
            z: const ['a', 'b', 'b'],
          ),
          pumpExponent: 0,
        ),
        progress: PumpingLemmaEnvironmentProgress(
          challengeScores: {problem.id: 1},
        ),
      ),
      systemKey: DefaultFormalSystemIds.regularPumping,
      schema: const DocumentSchemaDescriptor(
        id: DocumentSchemaId('turing-lab.pumping-lemma.regular'),
        version: DocumentSchemaVersion(1),
      ),
    );
  }
  final problem = PumpingLemmaProblemCatalog.contextFree.first;
  return InteroperableDocument<Object>(
    document: ContextFreePumpingLemmaDocument(
      problem: problem,
      session: PumpingLemmaSession<ContextFreePumpingDecomposition>(
        sessionId: 'cfl-session',
        challengeId: problem.id,
        sourceRevision: problem.sourceRevision,
        theorem: theorem,
        mode: PumpingLemmaMode.freeForm,
        role: PumpingLemmaRole.learner,
        targetLanguage: problem.languageDescription,
        pumpingLength: 2,
        witness: const ['multi', '🙂', 'b'],
        decomposition: ContextFreePumpingDecomposition(
          u: const [],
          v: const ['multi'],
          x: const [],
          y: const ['🙂'],
          z: const ['b'],
        ),
        pumpExponent: 2,
      ),
      progress: PumpingLemmaEnvironmentProgress(
        challengeScores: {problem.id: 2},
      ),
    ),
    systemKey: DefaultFormalSystemIds.contextFreePumping,
    schema: const DocumentSchemaDescriptor(
      id: DocumentSchemaId('turing-lab.pumping-lemma.context-free'),
      version: DocumentSchemaVersion(1),
    ),
  );
}

DocumentPayload _payload(String source) => DocumentPayload(
      bytes: Uint8List.fromList(utf8.encode(source)),
    );
