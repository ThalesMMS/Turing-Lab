import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:turing_lab/core/algorithms/tm_execution_analyzer.dart';
import 'package:turing_lab/core/annotations/annotations.dart';
import 'package:turing_lab/core/formal_systems/formal_systems.dart';
import 'package:turing_lab/core/interoperability/interoperability.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/core/models/tm.dart';
import 'package:turing_lab/core/models/tm_building_blocks.dart';
import 'package:turing_lab/core/models/tm_transition.dart';
import 'package:turing_lab/core/models/transition.dart';
import 'package:turing_lab/data/codecs/tm_jflap_document_codec.dart';
import 'package:turing_lab/data/codecs/tm_json_document_codec.dart';

void main() {
  test('building-block failures preserve exact structured arguments', () {
    const source = '''
<structure><type>turing</type><automaton>
  <block id="node id" name="Block"><x>bad</x><y>0</y><initial/><tag>leaf</tag></block>
</automaton></structure>''';
    final decoded = const TmJflapDocumentCodec().decode(
      _textPayload(source, 'invalid-building-block.jff'),
    );
    final malformed = decoded as CodecMalformed<InteroperableDocument<Object>>;

    expect(malformed.reason, CodecMalformedReason.invalidValue);
    expect(
      malformed.location?.path,
      '/structure/automaton/block[@id="node id"]',
    );
    expect(malformed.message, 'JFLAP TM node node id has invalid coordinates.');
    expect(
      malformed.structuredMessage?.stableCode,
      'codec.tm-jflap.invalid-node-coordinate',
    );
    expect(malformed.structuredMessage?.arguments['node']?.value, 'node id');
  });

  test('building-block import carries unsupported diagnostics directly', () {
    const source = '''
<structure><type>turing</type><automaton>
  <block id="0" name="Block"><x>0</x><y>0</y><initial/><tag>leaf</tag></block>
  <state id="1" name="q1"><x>10</x><y>0</y><final/></state>
  <transition><from>0</from><to>1</to><read>~</read><write>a</write><move>R</move></transition>
</automaton></structure>''';
    final decoded = const TmJflapDocumentCodec().decode(
      _textPayload(source, 'unsupported-building-block.jff'),
    );
    final unsupported =
        decoded as CodecUnsupported<InteroperableDocument<Object>>;

    expect(unsupported.reason, CodecUnsupportedReason.feature);
    expect(
      unsupported.message,
      'JFLAP wildcard, negated, and variable TM reads are not supported.',
    );
    expect(
      unsupported.structuredMessage?.stableCode,
      'codec.tm-jflap.unsupported-read-predicate',
    );
  });

  test('building-block export preserves unsupported operation details', () {
    final machine = _singleSymbolMachine('a');
    final withBlocks = machine.copyWith(
      blockDefinitions: {
        'leaf': TMBlockDefinition(
          id: 'leaf',
          name: 'Leaf',
          revision: 1,
          machine: _singleSymbolMachine('token').copyWith(id: 'leaf-machine'),
        ),
      },
    );
    final encoded = const TmJflapDocumentCodec().encode(_document(withBlocks));
    final unsupported = encoded as CodecUnsupported<EncodedDocument>;

    expect(unsupported.reason, CodecUnsupportedReason.feature);
    expect(
      unsupported.message,
      'Transition t uses a read symbol that JFLAP cannot represent atomically.',
    );
    expect(
      unsupported.structuredMessage?.stableCode,
      'codec.tm-jflap.unsupported-operation',
    );
    expect(unsupported.structuredMessage?.arguments['transition']?.value, 't');
    expect(
      unsupported.structuredMessage?.arguments['operation']?.value,
      'read',
    );
    expect(unsupported.structuredMessage?.arguments['symbol']?.value, 'token');
  });

  group('TM JSON codec', () {
    test('persists the semantic variant and canonical endpoint identities', () {
      final machine = _twoTapeMachine();
      final encoded = _encodeJson(machine);
      final envelope = jsonDecode(utf8.decode(encoded.value.bytes)) as Map;
      final payload = (envelope['document'] as Map)['payload'] as Map;

      expect(payload['tmVariant'], 'multiTape');
      final decoded = _decodeJson(encoded.value.bytes);
      expect(decoded.fidelity, DocumentFidelity.exact);
      final restored = decoded.value.document as TM;
      expect(restored.documentVariant, TMDocumentVariant.multiTape);
      expect(restored.id, machine.id);
      expect(restored.name, machine.name);
      expect(restored.blankSymbol, '_');
      expect(restored.tapeCount, 2);
      final transition = restored.tmTransitions.single;
      expect(
        identical(
          transition.fromState,
          restored.states.singleWhere((state) => state.id == 'state/0'),
        ),
        isTrue,
      );
      expect(transition.readSymbols, ['a', '_']);
      expect(transition.directions, [TapeDirection.right, TapeDirection.stay]);
    });

    test('migrates embedded endpoints and scalar multi-tape operations', () {
      final encoded = _encodeJson(_twoTapeMachine());
      final envelope = jsonDecode(utf8.decode(encoded.value.bytes)) as Map;
      final payload = (envelope['document'] as Map)['payload'] as Map;
      final transition = (payload['transitions'] as List).single as Map;
      final states = payload['states'] as List;
      transition
        ..['fromState'] = states.first
        ..['toState'] = states.last
        ..remove('readSymbols')
        ..remove('writeSymbols')
        ..remove('directions')
        ..['tapeNumber'] = 0;
      payload.remove('tmVariant');

      final decoded = _decodeJson(_jsonBytes(envelope));
      expect(decoded.fidelity, DocumentFidelity.normalized);
      expect(
        decoded.diagnostics.map((diagnostic) => diagnostic.code),
        containsAll({
          'json.tm-variant-inferred',
          'json.tm-operation-vectors-migrated',
          'json.tm-endpoints-migrated-to-ids',
        }),
      );
      final restored = decoded.value.document as TM;
      final restoredTransition = restored.tmTransitions.single;
      expect(restoredTransition.readSymbols, ['a', '_']);
      expect(restoredTransition.writeSymbols, ['a', '_']);
      expect(restoredTransition.directions, [
        TapeDirection.right,
        TapeDirection.stay,
      ]);
      expect(
        identical(
          restoredTransition.toState,
          restored.states.singleWhere((state) => state.id == 'state/1'),
        ),
        isTrue,
      );
    });

    test('round-trips an empty workspace', () {
      final empty = TM.empty(
        id: 'empty',
        name: 'Empty TM',
        tapeAlphabet: {'_'},
        blankSymbol: '_',
        tapeCount: 1,
      );

      final decoded = _decodeJson(_encodeJson(empty).value.bytes);
      final restored = decoded.value.document as TM;
      expect(restored.states, isEmpty);
      expect(restored.transitions, isEmpty);
      expect(restored.initialState, isNull);
      expect(restored.documentVariant, TMDocumentVariant.singleTape);
    });

    test('rejects a declared variant that contradicts the payload', () {
      final encoded = _encodeJson(_twoTapeMachine());
      final envelope = jsonDecode(utf8.decode(encoded.value.bytes)) as Map;
      final payload = (envelope['document'] as Map)['payload'] as Map;
      payload['tmVariant'] = 'singleTape';

      final decoded = TmJsonDocumentCodec().decode(
        _payload(_jsonBytes(envelope), 'wrong-variant.json'),
      );
      expect(decoded, isA<CodecMalformed<InteroperableDocument<Object>>>());
    });

    test('turns malformed vector types into a typed codec failure', () {
      final encoded = _encodeJson(_twoTapeMachine());
      final envelope = jsonDecode(utf8.decode(encoded.value.bytes)) as Map;
      final payload = (envelope['document'] as Map)['payload'] as Map;
      final transition = (payload['transitions'] as List).single as Map;
      transition['readSymbols'] = ['a', 7];

      final decoded = TmJsonDocumentCodec().decode(
        _payload(_jsonBytes(envelope), 'bad-vector.json'),
      );
      expect(decoded, isA<CodecMalformed<InteroperableDocument<Object>>>());
    });
  });

  group('TM JFLAP codec', () {
    test('notes round-trip through typed annotations', () {
      const source = '''
<structure><type>turing</type><automaton>
  <state id="0" name="q0"><x>10</x><y>20</y><initial/></state>
  <note><text>TM invariant</text><x>45</x><y>55</y></note>
</automaton></structure>''';
      const codec = TmJflapDocumentCodec();
      final decoded =
          codec.decode(_textPayload(source, 'notes.jff'))
              as CodecSuccess<InteroperableDocument<Object>>;

      expect(
        annotationsFromExtensions(
          decoded.value.extensions,
        )!.annotations.single.text,
        'TM invariant',
      );

      final encoded =
          codec.encode(decoded.value) as CodecSuccess<EncodedDocument>;
      final restored =
          codec.decode(_payload(encoded.value.bytes, 'notes.jff'))
              as CodecSuccess<InteroperableDocument<Object>>;
      expect(
        annotationsFromExtensions(
          restored.value.extensions,
        )!.annotations.single.text,
        'TM invariant',
      );
    });

    test('keeps local metadata while reporting JFLAP extension loss', () async {
      final machine = _twoTapeMachine();
      const codec = TmJflapDocumentCodec();

      final encoded = codec.encode(_document(machine));
      expect(encoded, isA<CodecSuccess<EncodedDocument>>());
      final success = encoded as CodecSuccess<EncodedDocument>;
      expect(success.fidelity, DocumentFidelity.lossy);
      expect(
        success.diagnostics.map((diagnostic) => diagnostic.code),
        contains('jflap.tm-turing-lab-extension-portability'),
      );
      final xml = utf8.decode(success.value.bytes);
      expect(xml, contains('<turingLabTm>'));
      expect(xml, contains('<turingLabState>'));
      expect(xml, contains('<turingLabTransition>'));

      final decoded =
          codec.decode(_payload(success.value.bytes, 'local.jff'))
              as CodecSuccess<InteroperableDocument<Object>>;
      expect(decoded.fidelity, DocumentFidelity.exact);
      final restored = decoded.value.document as TM;
      expect(restored.id, machine.id);
      expect(restored.name, machine.name);
      expect(restored.blankSymbol, '_');
      expect(restored.tapeAlphabet, machine.tapeAlphabet);
      expect(restored.zoomLevel, machine.zoomLevel);
      expect(restored.panOffset, machine.panOffset);
      final state = restored.states.singleWhere(
        (value) => value.id == 'state/0',
      );
      expect(state.type, StateType.initial);
      expect(state.properties, {'note': 'entry'});
      final transition = restored.tmTransitions.single;
      expect(transition.id, 'transition/0');
      expect(transition.label, 'custom label');
      expect(transition.type, TransitionType.nondeterministic);
      expect(transition.controlPoint, Vector2(25, 30));

      final before = await TMExecutionAnalyzer.analyze(machine, 'a');
      final after = await TMExecutionAnalyzer.analyze(restored, 'a');
      expect(after.outcome, before.outcome);
      expect(
        after.multiTapeTrace.last.configuration.key,
        before.multiTapeTrace.last.configuration.key,
      );
    });

    test('round-trips an empty local JFLAP workspace', () {
      final empty = TM.empty(
        id: 'empty',
        name: 'Empty TM',
        tapeAlphabet: {'_'},
        blankSymbol: '_',
      );
      const codec = TmJflapDocumentCodec();

      final encoded =
          codec.encode(_document(empty)) as CodecSuccess<EncodedDocument>;
      final decoded =
          codec.decode(_payload(encoded.value.bytes, 'empty.jff'))
              as CodecSuccess<InteroperableDocument<Object>>;
      final restored = decoded.value.document as TM;
      expect(restored.states, isEmpty);
      expect(restored.initialState, isNull);
      expect(restored.blankSymbol, '_');

      final standard =
          codec.decode(
                _textPayload(
                  '<structure><type>turing</type><automaton/></structure>',
                  'standard-empty.jff',
                ),
              )
              as CodecSuccess<InteroperableDocument<Object>>;
      expect((standard.value.document as TM).states, isEmpty);
      expect(standard.fidelity, DocumentFidelity.normalized);
    });

    test('normalizes standard blank aliases and all movement values', () {
      const source = '''<?xml version="1.0" encoding="UTF-8"?>
<structure><type>turing</type><tapes>3</tapes><automaton>
<state id="0" name="same-as-label"><x>0</x><y>0</y><initial/></state>
<state id="same-as-label" name="accept"><x>100</x><y>0</y><final/></state>
<transition><from>0</from><to>same-as-label</to>
<read tape="1">a</read><write tape="1">a</write><move tape="1">L</move>
<read tape="2">□</read><write tape="2"/><move tape="2">R</move>
<read tape="3">b</read><write tape="3">c</write><move tape="3">S</move>
</transition></automaton></structure>''';

      final decoded =
          const TmJflapDocumentCodec().decode(
                _textPayload(source, 'standard.jff'),
              )
              as CodecSuccess<InteroperableDocument<Object>>;
      expect(decoded.fidelity, DocumentFidelity.normalized);
      final machine = decoded.value.document as TM;
      expect(machine.tapeCount, 3);
      expect(machine.initialState?.id, '0');
      final transition = machine.tmTransitions.single;
      expect(transition.toState.id, 'same-as-label');
      expect(transition.readSymbols, ['a', 'B', 'b']);
      expect(transition.directions, [
        TapeDirection.left,
        TapeDirection.right,
        TapeDirection.stay,
      ]);
    });

    test('keeps JFLAP final-state acceptance and halt rejection', () async {
      const codec = TmJflapDocumentCodec();
      for (final (finalMarker, expectedOutcome) in [
        ('<final/>', 'accepted'),
        ('', 'haltedRejected'),
      ]) {
        final source =
            '''<structure><type>turing</type><automaton>
<state id="0" name="q0"><x>0</x><y>0</y><initial/>$finalMarker</state>
</automaton></structure>''';
        final decoded =
            codec.decode(_textPayload(source, 'halt.jff'))
                as CodecSuccess<InteroperableDocument<Object>>;
        final result = await TMExecutionAnalyzer.analyze(
          decoded.value.document as TM,
          '',
        );
        expect(result.outcome.name, expectedOutcome);
      }
    });

    test('retains nondeterministic standard JFLAP branches', () {
      const source = '''<structure><type>turing</type><automaton>
<state id="0" name="q0"><x>0</x><y>0</y><initial/></state>
<state id="1" name="q1"><x>10</x><y>0</y><final/></state>
<state id="2" name="q2"><x>20</x><y>0</y></state>
<transition><from>0</from><to>1</to><read>a</read><write>a</write><move>R</move></transition>
<transition><from>0</from><to>2</to><read>a</read><write>b</write><move>L</move></transition>
</automaton></structure>''';

      final decoded =
          const TmJflapDocumentCodec().decode(
                _textPayload(source, 'nondeterministic.jff'),
              )
              as CodecSuccess<InteroperableDocument<Object>>;
      expect((decoded.value.document as TM).isNondeterministic, isTrue);
    });

    test('assigns stable ids when standard XML elements are reordered', () {
      const first = '''<structure><type>turing</type><automaton>
<state id="0" name="q0"><x>0</x><y>0</y><initial/></state>
<state id="1" name="q1"><x>10</x><y>0</y><final/></state>
<transition><from>0</from><to>1</to><read>a</read><write>a</write><move>R</move></transition>
</automaton></structure>''';
      const second = '''<structure><type>turing</type><automaton>
<state id="1" name="q1"><x>10</x><y>0</y><final/></state>
<transition><from>0</from><to>1</to><read>a</read><write>a</write><move>R</move></transition>
<state id="0" name="q0"><x>0</x><y>0</y><initial/></state>
</automaton></structure>''';
      const codec = TmJflapDocumentCodec();

      final left =
          (codec.decode(_textPayload(first, 'first.jff'))
                      as CodecSuccess<InteroperableDocument<Object>>)
                  .value
                  .document
              as TM;
      final right =
          (codec.decode(_textPayload(second, 'second.jff'))
                      as CodecSuccess<InteroperableDocument<Object>>)
                  .value
                  .document
              as TM;
      expect(right.id, left.id);
      expect(
        right.tmTransitions.map((transition) => transition.id),
        left.tmTransitions.map((transition) => transition.id),
      );
    });

    test('preserves unknown optional XML data through local re-export', () {
      const source =
          '''<structure vendor="root"><type>turing</type><vendorRoot/>
<automaton vendor="automaton">
<state id="0" name="q0" vendor="state"><x>0</x><y>0</y><initial/><vendorState/></state>
<state id="1" name="q1"><x>10</x><y>0</y><final/></state>
<transition vendor="transition"><from>0</from><to>1</to><read>a</read><write>a</write><move>R</move><vendorTransition/></transition>
<vendorAutomaton/>
</automaton></structure>''';
      const codec = TmJflapDocumentCodec();

      final decoded =
          codec.decode(_textPayload(source, 'vendor.jff'))
              as CodecSuccess<InteroperableDocument<Object>>;
      expect(decoded.value.extensions.values, isNotEmpty);
      expect(
        decoded.diagnostics.map((diagnostic) => diagnostic.code),
        containsAll({
          'jflap.unknown-optional-element',
          'jflap.unknown-optional-attribute',
        }),
      );

      final encoded =
          codec.encode(decoded.value) as CodecSuccess<EncodedDocument>;
      final xml = utf8.decode(encoded.value.bytes);
      expect(xml, contains('vendor="root"'));
      expect(xml, contains('<vendorRoot/>'));
      expect(xml, contains('vendor="state"'));
      expect(xml, contains('<vendorState/>'));
      expect(xml, contains('<vendorTransition/>'));
      expect(xml, contains('<vendorAutomaton/>'));
    });

    test('rejects invalid tape counts, endpoints, indices, moves, and ids', () {
      final cases = <String>[
        '''<structure><type>turing</type><tapes>6</tapes><automaton/></structure>''',
        _singleTransitionXml(from: 'missing'),
        _singleTransitionXml(readAttributes: ' tape="2"'),
        _singleTransitionXml(move: 'X'),
        _duplicateTransitionIdXml(),
      ];
      const codec = TmJflapDocumentCodec();

      for (var index = 0; index < cases.length; index++) {
        final decoded = codec.decode(
          _textPayload(cases[index], 'bad-$index.jff'),
        );
        expect(
          decoded,
          isA<CodecMalformed<InteroperableDocument<Object>>>(),
          reason: 'case $index',
        );
      }
    });

    test('refuses JFLAP predicates and non-atomic operation symbols', () {
      const codec = TmJflapDocumentCodec();
      for (final read in ['~', '!a', 'x}']) {
        final decoded = codec.decode(
          _textPayload(_singleTransitionXml(read: read), 'predicate.jff'),
        );
        expect(decoded, isA<CodecUnsupported<InteroperableDocument<Object>>>());
      }

      for (final symbol in ['token', '😀']) {
        final machine = _singleSymbolMachine(symbol);
        final encoded = codec.encode(_document(machine));
        expect(encoded, isA<CodecUnsupported<EncodedDocument>>());
      }
    });

    test('produces deterministic bytes for native and web transports', () {
      const codec = TmJflapDocumentCodec();
      final document = _document(_twoTapeMachine());
      final first = codec.encode(document) as CodecSuccess<EncodedDocument>;
      final second = codec.encode(document) as CodecSuccess<EncodedDocument>;
      expect(second.value.bytes, first.value.bytes);
      expect(second.value.mimeType, 'application/xml');
      expect(second.value.filename, 'machine.jff');
    });
  });
}

CodecSuccess<EncodedDocument> _encodeJson(TM machine) =>
    TmJsonDocumentCodec().encode(_document(machine))
        as CodecSuccess<EncodedDocument>;

CodecSuccess<InteroperableDocument<Object>> _decodeJson(Uint8List bytes) =>
    TmJsonDocumentCodec().decode(_payload(bytes, 'machine.json'))
        as CodecSuccess<InteroperableDocument<Object>>;

InteroperableDocument<Object> _document(TM machine) =>
    InteroperableDocument<Object>(
      document: machine,
      systemKey: DefaultFormalSystemIds.tm,
      schema: TmJsonDocumentCodec.schema,
    );

DocumentPayload _textPayload(String source, String filename) =>
    _payload(Uint8List.fromList(utf8.encode(source)), filename);

DocumentPayload _payload(Uint8List bytes, String filename) =>
    DocumentPayload(bytes: bytes, filename: filename);

Uint8List _jsonBytes(Object value) =>
    Uint8List.fromList(utf8.encode(jsonEncode(value)));

TM _twoTapeMachine() {
  final start = State(
    id: 'state/0',
    label: 'start',
    position: Vector2(10, 20),
    isInitial: true,
    type: StateType.initial,
    properties: const {'note': 'entry'},
  );
  final accept = State(
    id: 'state/1',
    label: 'accept',
    position: Vector2(110, 20),
    isAccepting: true,
  );
  final transition = TMTransition(
    id: 'transition/0',
    fromState: start,
    toState: accept,
    label: 'custom label',
    controlPoint: Vector2(25, 30),
    type: TransitionType.nondeterministic,
    readSymbols: const ['a', '_'],
    writeSymbols: const ['a', '_'],
    directions: const [TapeDirection.right, TapeDirection.stay],
  );
  return TM(
    id: 'tm/custom',
    name: 'Custom two-tape TM',
    states: {start, accept},
    transitions: {transition},
    alphabet: const {'a'},
    initialState: start,
    acceptingStates: {accept},
    created: DateTime.utc(2026, 8, 25, 1, 2, 3),
    modified: DateTime.utc(2026, 8, 25, 4, 5, 6),
    bounds: const math.Rectangle(1, 2, 300, 200),
    zoomLevel: 1.5,
    panOffset: Vector2(4, 5),
    tapeAlphabet: const {'_', 'a', 'β'},
    blankSymbol: '_',
    tapeCount: 2,
  );
}

TM _singleSymbolMachine(String symbol) {
  final start = State(
    id: '0',
    label: 'q0',
    position: Vector2.zero(),
    isInitial: true,
  );
  final accept = State(
    id: '1',
    label: 'q1',
    position: Vector2(100, 0),
    isAccepting: true,
  );
  return TM(
    id: 'symbol-machine',
    name: 'Symbol machine',
    states: {start, accept},
    transitions: {
      TMTransition(
        id: 't',
        fromState: start,
        toState: accept,
        label: 'symbol',
        readSymbol: symbol,
        writeSymbol: symbol,
        direction: TapeDirection.stay,
      ),
    },
    alphabet: {symbol},
    initialState: start,
    acceptingStates: {accept},
    created: DateTime.utc(2026),
    modified: DateTime.utc(2026),
    bounds: const math.Rectangle(0, 0, 200, 100),
    tapeAlphabet: {'B', symbol},
    blankSymbol: 'B',
  );
}

String _singleTransitionXml({
  String from = '0',
  String read = 'a',
  String readAttributes = '',
  String move = 'R',
}) =>
    '''<structure><type>turing</type><automaton>
<state id="0" name="q0"><x>0</x><y>0</y><initial/></state>
<state id="1" name="q1"><x>10</x><y>0</y><final/></state>
<transition><from>$from</from><to>1</to><read$readAttributes>$read</read><write>a</write><move>$move</move></transition>
</automaton></structure>''';

String _duplicateTransitionIdXml() =>
    '''<structure><type>turing</type><automaton>
<state id="0" name="q0"><x>0</x><y>0</y><initial/></state>
<state id="1" name="q1"><x>10</x><y>0</y><final/></state>
<transition><from>0</from><to>1</to><read>a</read><write>a</write><move>R</move><turingLabTransition>{"id":"same"}</turingLabTransition></transition>
<transition><from>0</from><to>1</to><read>b</read><write>b</write><move>S</move><turingLabTransition>{"id":"same"}</turingLabTransition></transition>
</automaton></structure>''';
