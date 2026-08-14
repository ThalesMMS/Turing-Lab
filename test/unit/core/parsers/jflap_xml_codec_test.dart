import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/state.dart' as automaton_state;
import 'package:turing_lab/core/parsers/jflap_xml_codec.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  group('JflapXmlCodec', () {
    const codec = JflapXmlCodec();

    test('encodes each FSA input symbol as a separate JFLAP transition', () {
      final q0 = _state('q0', isInitial: true);
      final q1 = _state('q1', x: 100, isAccepting: true);
      final automaton = FSA(
        id: 'multi_symbol',
        name: 'Multi-symbol FSA',
        states: {q0, q1},
        transitions: {
          FSATransition(
            id: 't0',
            fromState: q0,
            toState: q1,
            label: 'a,b',
            inputSymbols: const {'a', 'b'},
          ),
          FSATransition.epsilon(
            id: 't1',
            fromState: q1,
            toState: q0,
          ),
        },
        alphabet: const {'a', 'b'},
        initialState: q0,
        acceptingStates: {q1},
        created: DateTime(2026),
        modified: DateTime(2026),
        bounds: const math.Rectangle(0, 0, 400, 300),
      );

      final xml = codec.encodeFsa(automaton);

      expect(RegExp('<transition>').allMatches(xml), hasLength(3));
      expect(xml, contains('<read>a</read>'));
      expect(xml, contains('<read>b</read>'));
      expect(xml, contains(RegExp(r'<read\s*/>')));
      expect(xml, isNot(contains('<read>ε</read>')));
    });

    test('decodes FSA transitions that reference state ids', () {
      const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<structure type="fa">
  <automaton>
    <state id="0" name="q0">
      <x>0</x>
      <y>0</y>
      <initial/>
    </state>
    <state id="1" name="q1">
      <x>100</x>
      <y>0</y>
      <final/>
    </state>
    <transition>
      <from>0</from>
      <to>1</to>
      <read>a</read>
    </transition>
  </automaton>
</structure>''';

      final result = codec.decodeFsaXml(xml);

      expect(result.isSuccess, isTrue);
      final transition =
          result.data!.transitions.whereType<FSATransition>().single;
      expect(transition.fromState.id, equals('0'));
      expect(transition.toState.id, equals('1'));
      expect(transition.label, equals('a'));
    });

    test('rejects FSA transitions that reference state labels instead of ids',
        () {
      const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<structure type="fa">
  <automaton>
    <state id="0" name="q0">
      <initial/>
    </state>
    <state id="1" name="q1">
      <final/>
    </state>
    <transition>
      <from>q0</from>
      <to>q1</to>
      <read>a</read>
    </transition>
  </automaton>
</structure>''';

      final result = codec.decodeFsaXml(xml);

      expect(result.isFailure, isTrue);
      expect(result.error, contains('unknown state'));
    });

    test('does not fabricate an initial state when marker is absent', () {
      const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<structure type="fa">
  <automaton>
    <state id="q0" name="q0"/>
    <state id="q1" name="q1">
      <final/>
    </state>
  </automaton>
</structure>''';

      final result = codec.decodeFsaXml(xml);

      expect(result.isSuccess, isTrue);
      expect(result.data!.initialState, isNull);
      expect(
        result.data!.states.where((state) => state.isInitial),
        isEmpty,
      );
    });

    test('resolves ambiguous FSA transition endpoints by id only', () {
      const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<structure type="fa">
  <automaton>
    <state id="q0" name="q1">
      <initial/>
    </state>
    <state id="q1" name="q0">
      <final/>
    </state>
    <transition>
      <from>q0</from>
      <to>q1</to>
      <read>a</read>
    </transition>
  </automaton>
</structure>''';

      final result = codec.decodeFsaXml(xml);

      expect(result.isSuccess, isTrue);
      final transition =
          result.data!.transitions.whereType<FSATransition>().single;
      expect(transition.fromState.id, equals('q0'));
      expect(transition.toState.id, equals('q1'));
    });

    test('rejects empty FSA imports with the existing file-service message',
        () {
      const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<structure type="fa">
  <automaton>
  </automaton>
</structure>''';

      final result = codec.decodeFsaXml(xml);

      expect(result.isFailure, isTrue);
      expect(result.error, contains('does not contain any states'));
    });

    test('keeps empty serializable automata round-trippable', () {
      final xml = codec.encodeSerializableAutomaton({
        'type': 'dfa',
        'states': <Map<String, dynamic>>[],
        'transitions': <String, List<String>>{},
        'alphabet': <String>[],
      });

      final result = codec.decodeSerializableAutomaton(xml);

      expect(xml, contains('<automaton>'));
      expect(result.isSuccess, isTrue);
      expect(result.data!['type'], equals('dfa'));
      expect(result.data!['states'], isEmpty);
      expect(result.data!['transitions'], isEmpty);
      expect(result.data!['nextId'], equals(0));
    });

    test('reports dangling serializable transition references', () {
      const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<structure type="fa">
  <type>fa</type>
  <automaton>
    <state id="q0" name="q0">
      <initial/>
    </state>
    <transition>
      <from>q0</from>
      <to>q9</to>
      <read>a</read>
    </transition>
  </automaton>
</structure>''';

      final result = codec.decodeSerializableAutomaton(xml);

      expect(result.isFailure, isTrue);
      expect(result.error, contains('unknown state'));
    });

    test('decodes serializable transitions by id when names conflict', () {
      const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<structure type="fa">
  <type>fa</type>
  <automaton>
    <state id="q0" name="q1">
      <initial/>
    </state>
    <state id="q1" name="q0">
      <final/>
    </state>
    <transition>
      <from>q0</from>
      <to>q1</to>
      <read>a</read>
    </transition>
  </automaton>
</structure>''';

      final result = codec.decodeSerializableAutomaton(xml);

      expect(result.isSuccess, isTrue);
      final transitions =
          result.data!['transitions'] as Map<String, List<String>>;
      expect(transitions['q0|a'], equals(['q1']));
    });
  });
}

automaton_state.State _state(
  String id, {
  double x = 0,
  double y = 0,
  bool isInitial = false,
  bool isAccepting = false,
}) {
  return automaton_state.State(
    id: id,
    label: id,
    position: Vector2(x, y),
    isInitial: isInitial,
    isAccepting: isAccepting,
  );
}
