import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/annotations/annotations.dart';
import 'package:turing_lab/core/interoperability/interoperability.dart';
import 'package:turing_lab/core/transducers/transducers.dart';
import 'package:turing_lab/data/codecs/moore_document_codecs.dart';
import 'package:turing_lab/data/codecs/moore_jflap_document_codec.dart';

void main() {
  group('Moore JFLAP codec', () {
    test('declares state outputs without accepting-state semantics', () {
      final capabilities =
          MooreDocumentCodecs.jflap.descriptor.semanticCapabilities;

      expect(capabilities, contains(CodecSemanticCapabilityId.stateOutputs));
      expect(
        capabilities,
        isNot(contains(CodecSemanticCapabilityId.acceptingStates)),
      );
      expect(
        capabilities,
        isNot(contains(CodecSemanticCapabilityId.transitionOutputs)),
      );
    });

    test('imports canonical fixture and emits initial output first', () async {
      final outcome = MooreDocumentCodecs.jflap.decode(
        DocumentPayload(
          bytes: await File(
            'test/fixtures/interoperability/moore_canonical.jff',
          ).readAsBytes(),
          filename: 'parity.jff',
        ),
      );

      expect(outcome, isA<CodecSuccess<InteroperableDocument<Object>>>());
      final success = outcome as CodecSuccess<InteroperableDocument<Object>>;
      expect(success.fidelity, DocumentFidelity.normalized);
      expect(success.value.sourceMetadata.sourceFormatVersion, '7.1');
      final machine = success.value.document as MooreMachine;
      final empty = DeterministicTransducerSimulator.moore(machine).runRaw('');
      final one = DeterministicTransducerSimulator.moore(machine).runRaw('1');

      expect(empty, isA<TransducerSuccess>());
      expect(empty.output.values, ['even']);
      expect(empty.trace, isEmpty);
      expect(one, isA<TransducerSuccess>());
      expect(one.output.values, ['even', 'odd']);
      expect(one.trace.single.emittedOutput.values, ['odd']);
      expect(one.trace.single.transitionId.value, startsWith('mt_'));
    });

    test('reordered XML derives identical IDs and canonical bytes', () {
      final first = _decodeJflap(_parityXml(reversed: false));
      final second = _decodeJflap(_parityXml(reversed: true));
      final firstMachine = first.document as MooreMachine;
      final secondMachine = second.document as MooreMachine;

      expect(firstMachine.id, secondMachine.id);
      expect(
        firstMachine.transitions.map((transition) => transition.id).toList(),
        secondMachine.transitions.map((transition) => transition.id).toList(),
      );

      final firstEncoded = _encodeJflap(first);
      final secondEncoded = _encodeJflap(second);
      expect(firstEncoded.bytes, orderedEquals(secondEncoded.bytes));
      expect(
        utf8.decode(firstEncoded.bytes),
        isNot(contains('<structure type="moore">')),
      );
    });

    test('state output wins over conflicting inbound transout', () {
      final outcome = MooreDocumentCodecs.jflap.decode(
        _payload(
          _parityXml(reversed: false).replaceFirst(
            '<transout>odd</transout>',
            '<transout>wrong</transout>',
          ),
        ),
      ) as CodecSuccess<InteroperableDocument<Object>>;
      final machine = outcome.value.document as MooreMachine;

      expect(
        DeterministicTransducerSimulator.moore(machine)
            .runRaw('1')
            .output
            .values,
        ['even', 'odd'],
      );
      expect(
        outcome.diagnostics.map((diagnostic) => diagnostic.code),
        contains('jflap.moore.conflicting-transition-output-preserved'),
      );
      expect(
        outcome.value.extensions.values.values,
        contains('wrong'),
      );
    });

    test('round-trips multi-token and empty state output explicitly', () {
      final machine = MooreMachine(
        id: const TransducerMachineId('tokens'),
        name: 'Token outputs',
        revision: const TransducerRevision(0),
        inputAlphabet: {const TransducerInputSymbol('x')},
        outputAlphabet: {
          const TransducerOutputSymbol('á'),
          const TransducerOutputSymbol('β'),
        },
        transitions: const [
          MooreTransition(
            id: TransducerTransitionId('to_tokens'),
            from: TransducerStateId('empty'),
            to: TransducerStateId('tokens'),
            input: TransducerInputSymbol('x'),
          ),
          MooreTransition(
            id: TransducerTransitionId('stay'),
            from: TransducerStateId('tokens'),
            to: TransducerStateId('tokens'),
            input: TransducerInputSymbol('x'),
          ),
        ],
        states: [
          const MooreState(
            id: TransducerStateId('empty'),
            label: 'Empty',
            position: TransducerPoint(0, 0),
            output: TransducerOutputWord.empty,
            isInitial: true,
          ),
          MooreState(
            id: const TransducerStateId('tokens'),
            label: 'Tokens',
            position: const TransducerPoint(120, 0),
            output: TransducerOutputWord.fromValues(const ['á', 'β']),
          ),
        ],
      );
      final wrapper = InteroperableDocument<Object>(
        document: machine,
        systemKey: TransducerFormalSystemIds.moore,
        schema: MooreJflapDocumentCodec.schema,
      );

      final encoded = MooreDocumentCodecs.jflap.encode(wrapper)
          as CodecSuccess<EncodedDocument>;
      expect(encoded.fidelity, DocumentFidelity.normalized);
      expect(
        encoded.diagnostics.map((diagnostic) => diagnostic.code),
        contains('jflap.moore.output-token-vector-preserved'),
      );
      final decoded = MooreDocumentCodecs.jflap.decode(
        DocumentPayload(bytes: encoded.value.bytes),
      ) as CodecSuccess<InteroperableDocument<Object>>;
      final roundTrip = decoded.value.document as MooreMachine;
      expect(roundTrip.states.first.output, TransducerOutputWord.empty);
      expect(roundTrip.states.last.output.values, ['á', 'β']);
    });

    test('round-trips JFLAP notes and reports unsupported presentation', () {
      final decoded = MooreDocumentCodecs.jflap.decode(
        _payload(
          _parityXml(reversed: false).replaceFirst(
            '</automaton>',
            '<note><text>Unicode λ, 漢字, 🧠</text><x>45</x><y>55</y></note>'
                '</automaton>',
          ),
        ),
      ) as CodecSuccess<InteroperableDocument<Object>>;
      final imported = annotationsFromExtensions(decoded.value.extensions)!;

      expect(imported.annotations.single.text, 'Unicode λ, 漢字, 🧠');
      expect(imported.annotations.single.x, 45);
      expect(imported.annotations.single.y, 55);
      expect(
        MooreDocumentCodecs.jflap.descriptor.semanticCapabilities,
        contains(CodecSemanticCapabilityId.notes),
      );

      final styled = DocumentAnnotationCollection(
        documentId: imported.documentId,
        documentRevision: imported.documentRevision,
        annotations: [
          imported.annotations.single.copyWith(
            collapsed: true,
            authorLabel: 'Ada',
          ),
        ],
      );
      final encoded = MooreDocumentCodecs.jflap.encode(
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
      final restored = MooreDocumentCodecs.jflap.decode(
        DocumentPayload(bytes: encoded.value.bytes, filename: 'restored.jff'),
      ) as CodecSuccess<InteroperableDocument<Object>>;
      final restoredNote = annotationsFromExtensions(restored.value.extensions)!
          .annotations
          .single;
      expect(restoredNote.text, 'Unicode λ, 漢字, 🧠');
      expect(restoredNote.x, 45);
      expect(restoredNote.y, 55);
    });

    test('rejects final states, epsilon reads, and nondeterminism', () {
      expect(
        MooreDocumentCodecs.jflap.decode(
          _payload(
            _parityXml(reversed: false).replaceFirst(
              '<initial/>',
              '<initial/><final/>',
            ),
          ),
        ),
        isA<CodecUnsupported<InteroperableDocument<Object>>>(),
      );
      expect(
        MooreDocumentCodecs.jflap.decode(
          _payload(
            _parityXml(reversed: false)
                .replaceFirst('<read>1</read>', '<read/>'),
          ),
        ),
        isA<CodecMalformed<InteroperableDocument<Object>>>(),
      );
      expect(
        MooreDocumentCodecs.jflap.decode(
          _payload(
            _parityXml(reversed: false).replaceFirst(
              '</automaton>',
              '<transition><from>q0</from><to>q0</to><read>1</read>'
                  '<transout>even</transout></transition></automaton>',
            ),
          ),
        ),
        isA<CodecMalformed<InteroperableDocument<Object>>>(),
      );
    });
  });

  group('Moore JSON codec', () {
    test('round-trips Unicode, multi-character symbols, and extensions', () {
      final machine = _unicodeMachine();
      final original = InteroperableDocument<Object>(
        document: machine,
        systemKey: TransducerFormalSystemIds.moore,
        schema: MooreJflapDocumentCodec.schema,
        extensions: DocumentExtensionBag({
          'plugin.future': {'kept': true},
        }),
      );

      final encoded = MooreDocumentCodecs.json.encode(original)
          as CodecSuccess<EncodedDocument>;
      final decoded = MooreDocumentCodecs.json.decode(
        DocumentPayload(bytes: encoded.value.bytes, filename: 'moore.json'),
      ) as CodecSuccess<InteroperableDocument<Object>>;
      final machineAgain = decoded.value.document as MooreMachine;

      expect(machineAgain.inputAlphabet.single.value, 'ação');
      expect(machineAgain.states.single.output.values, ['✓', 'pronto']);
      expect(decoded.value.extensions.values['plugin.future'], {'kept': true});
      expect(
        MooreDocumentCodecs.json.descriptor.semanticCapabilities,
        isNot(contains(CodecSemanticCapabilityId.acceptingStates)),
      );
    });

    test('rejects invalid machines and future schemas', () {
      final duplicate = _unicodeMachine().copyWith(
        states: [
          ..._unicodeMachine().states,
          _unicodeMachine().states.single.copyWith(isInitial: false),
        ],
      );
      final duplicateJson = jsonEncode(duplicate.toJson());
      expect(
        MooreDocumentCodecs.json.decode(_payload(duplicateJson)),
        isA<CodecMalformed<InteroperableDocument<Object>>>(),
      );

      final fixture = jsonDecode(
        File('test/fixtures/interoperability/moore_canonical.json')
            .readAsStringSync(),
      ) as Map<String, dynamic>;
      ((fixture['document'] as Map)['schema'] as Map)['version'] = 2;
      expect(
        MooreDocumentCodecs.json.decode(_payload(jsonEncode(fixture))),
        isA<CodecUnsupported<InteroperableDocument<Object>>>(),
      );
    });
  });
}

InteroperableDocument<Object> _decodeJflap(String xml) {
  final outcome = MooreDocumentCodecs.jflap.decode(_payload(xml));
  expect(outcome, isA<CodecSuccess<InteroperableDocument<Object>>>());
  return (outcome as CodecSuccess<InteroperableDocument<Object>>).value;
}

EncodedDocument _encodeJflap(InteroperableDocument<Object> document) {
  final outcome = MooreDocumentCodecs.jflap.encode(document);
  expect(outcome, isA<CodecSuccess<EncodedDocument>>());
  return (outcome as CodecSuccess<EncodedDocument>).value;
}

DocumentPayload _payload(String source) => DocumentPayload(
      bytes: Uint8List.fromList(utf8.encode(source)),
      filename: 'machine.jff',
    );

String _parityXml({required bool reversed}) {
  const state0 = '<state id="q0"><x>0</x><y>0</y><initial/>'
      '<output>even</output></state>';
  const state1 = '<state id="q1"><x>100</x><y>0</y>'
      '<output>odd</output></state>';
  const transition0 = '<transition><from>q0</from><to>q1</to><read>1</read>'
      '<transout>odd</transout></transition>';
  const transition1 = '<transition><from>q1</from><to>q0</to><read>1</read>'
      '<transout>even</transout></transition>';
  final states = reversed ? '$state1$state0' : '$state0$state1';
  final transitions =
      reversed ? '$transition1$transition0' : '$transition0$transition1';
  return '<structure><type>moore</type><automaton>$states$transitions'
      '</automaton></structure>';
}

MooreMachine _unicodeMachine() => MooreMachine(
      id: const TransducerMachineId('unicode'),
      name: 'Unicode',
      revision: const TransducerRevision(2),
      inputAlphabet: {const TransducerInputSymbol('ação')},
      outputAlphabet: {
        const TransducerOutputSymbol('✓'),
        const TransducerOutputSymbol('pronto'),
      },
      states: [
        MooreState(
          id: const TransducerStateId('único'),
          label: 'Único',
          position: const TransducerPoint(12.5, 24),
          isInitial: true,
          output: TransducerOutputWord.fromValues(const ['✓', 'pronto']),
        ),
      ],
      transitions: const [
        MooreTransition(
          id: TransducerTransitionId('laço'),
          from: TransducerStateId('único'),
          to: TransducerStateId('único'),
          input: TransducerInputSymbol('ação'),
        ),
      ],
    );
