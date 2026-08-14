@TestOn('browser')
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/data/services/file_operations_service.dart';

void main() {
  Uint8List bytes(String xml) => Uint8List.fromList(utf8.encode(xml));

  group('FileOperationsService web JFLAP import', () {
    late FileOperationsService service;

    setUp(() {
      service = FileOperationsService();
    });

    test('resolves transitions that reference state names', () async {
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
      <from>q0</from>
      <to>q1</to>
      <read>a</read>
    </transition>
  </automaton>
</structure>''';

      final result = await service.loadAutomatonFromBytes(bytes(xml));

      expect(result.isSuccess, isTrue);
      final automaton = result.data!;
      expect(automaton.transitions, hasLength(1));
      final transition = automaton.transitions.single;
      expect(transition.fromState.label, equals('q0'));
      expect(transition.toState.label, equals('q1'));
    });
  });

  group('FileOperationsService web grammar import', () {
    late FileOperationsService service;

    setUp(() {
      service = FileOperationsService();
    });

    test('trims the declared start symbol', () async {
      const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<structure type="grammar">
  <grammar>
    <start>   S   </start>
    <production>
      <left>S</left>
      <right>a</right>
    </production>
  </grammar>
</structure>''';

      final result = await service.loadGrammarFromBytes(bytes(xml));

      expect(result.isSuccess, isTrue);
      expect(result.data!.startSymbol, equals('S'));
    });
  });
}
