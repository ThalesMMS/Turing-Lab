//
//  file_operations_service_test.dart
//  Turing Lab
//
//  Focused tests for FileOperationsService covering JFLAP import
//  on legacy-parser edge cases, with emphasis on predictable messages and
//  epsilon-transition normalization.
//
//  Thales Matheus Mendonça Santos - October 2025
//

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/data/services/file_operations_service.dart';

void main() {
  group('FileOperationsService JFLAP import edge cases', () {
    late FileOperationsService service;

    setUp(() {
      service = FileOperationsService();
    });

    test('empty automaton returns descriptive failure', () async {
      const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<structure type="fa">
  <automaton>
  </automaton>
</structure>''';

      final result = await service.loadAutomatonFromBytes(_bytes(xml));

      expect(result.isFailure, isTrue);
      expect(result.error, contains('does not contain any states'));
    });

    test('missing coordinates fall back to defaults', () async {
      const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<structure type="fa">
  <automaton>
    <state id="q0" name="q0">
      <initial/>
      <final/>
    </state>
  </automaton>
</structure>''';

      final result = await service.loadAutomatonFromBytes(_bytes(xml));

      expect(result.isSuccess, isTrue);
      final state = result.data!.states.single;
      expect(state.position.x, equals(0.0));
      expect(state.position.y, equals(0.0));
    });

    test('transition referencing missing state returns failure', () async {
      const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<structure type="fa">
  <automaton>
    <state id="q0" name="q0">
      <x>0</x>
      <y>0</y>
      <initial/>
    </state>
    <transition>
      <from>q0</from>
      <to>q9</to>
      <read>a</read>
    </transition>
  </automaton>
</structure>''';

      final result = await service.loadAutomatonFromBytes(_bytes(xml));

      expect(result.isFailure, isTrue);
      expect(result.error, contains('references an unknown state'));
    });

    test('epsilon transitions are parsed correctly', () async {
      const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<structure type="fa">
  <automaton>
    <state id="q0" name="q0">
      <x>0</x>
      <y>0</y>
      <initial/>
    </state>
    <state id="q1" name="q1">
      <x>100</x>
      <y>0</y>
      <final/>
    </state>
    <transition>
      <from>q0</from>
      <to>q1</to>
      <read/>
    </transition>
  </automaton>
</structure>''';

      final result = await service.loadAutomatonFromBytes(_bytes(xml));

      expect(result.isSuccess, isTrue);
      final transition =
          result.data!.transitions.whereType<FSATransition>().single;
      expect(transition.isEpsilonTransition, isTrue);
      expect(transition.lambdaSymbol, equals('ε'));
      expect(result.data!.alphabet, isEmpty);
    });
  });

  group('FileOperationsService file access messaging', () {
    test('permission denied writes return sandbox-safe guidance', () {
      final message = FileOperationsService.describeFileAccessFailure(
        const FileSystemException(
          'Cannot open file',
          '/tmp/export.jff',
          OSError('Operation not permitted', 1),
        ),
        isWrite: true,
      );

      expect(message, contains('could not write to the selected location'));
      expect(message, contains('system save dialog'));
    });

    test('missing reads ask the user to reselect the file', () {
      final message = FileOperationsService.describeFileAccessFailure(
        const FileSystemException(
          'Cannot open file',
          '/tmp/missing.jff',
          OSError('No such file or directory', 2),
        ),
        isWrite: false,
      );

      expect(message, contains('no longer available'));
      expect(message, contains('Pick the file again'));
    });

    test('permission denied reads mention access restrictions', () {
      final message = FileOperationsService.describeFileAccessFailure(
        const FileSystemException(
          'Cannot open file',
          '/tmp/restricted.jff',
          OSError('Permission denied', 13),
        ),
        isWrite: false,
      );

      expect(message, contains('could not read the selected file'));
      expect(message, contains('system dialog'));
    });
  });
}

Uint8List _bytes(String xml) => Uint8List.fromList(utf8.encode(xml));
