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

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/data/services/file_operations_service.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/l10n/app_localizations_structured_messages.dart';

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
      expect(result.error, 'codec.malformed.syntax');
      expect(
        result.structuredError?.stableCode,
        'parser.jflap-xml.empty-automaton',
      );
      expect(
        lookupAppLocalizations(
          const Locale('en'),
        ).resolveStructuredMessage(result.structuredError!),
        contains('has no states'),
      );
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
      expect(result.error, 'codec.malformed.syntax');
      expect(
        result.structuredError?.stableCode,
        'parser.jflap-xml.unknown-transition-endpoints',
      );
      expect(
        lookupAppLocalizations(
          const Locale('en'),
        ).resolveStructuredMessage(result.structuredError!),
        contains('references an unknown state'),
      );
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
      final transition = result.data!.transitions
          .whereType<FSATransition>()
          .single;
      expect(transition.isEpsilonTransition, isTrue);
      expect(transition.lambdaSymbol, equals('ε'));
      expect(result.data!.alphabet, isEmpty);
    });

    test('invalid JSON returns the codec-malformed contract', () async {
      final directory = await Directory.systemTemp.createTemp(
        'turing-lab-invalid-automaton-json-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final file = File(
        '${directory.path}${Platform.pathSeparator}invalid.json',
      );
      await file.writeAsString('{invalid');

      final result = await service.loadAutomatonFromJson(file.path);

      expect(result.isFailure, isTrue);
      expect(result.error, 'service.file-operations.codec-malformed');
      expect(
        result.structuredError?.stableCode,
        'service.file-operations.codec-malformed',
      );
      expect(
        result.structuredError?.arguments['reason']?.value,
        'invalidValue',
      );
    });
  });

  group('FileOperationsService file access messaging', () {
    test('permission denied writes return a stable structured code', () {
      final message = FileOperationsService.describeFileAccessFailure(
        const FileSystemException(
          'Cannot open file',
          '/tmp/export.jff',
          OSError('Operation not permitted', 1),
        ),
        isWrite: true,
      );

      expect(message.stableCode, 'service.file-operations.access-denied');
      expect(message.arguments['operation']?.value, 'write');
    });

    test('missing reads return a stable structured code', () {
      final message = FileOperationsService.describeFileAccessFailure(
        const FileSystemException(
          'Cannot open file',
          '/tmp/missing.jff',
          OSError('No such file or directory', 2),
        ),
        isWrite: false,
      );

      expect(message.stableCode, 'service.file-operations.location-missing');
      expect(message.arguments['operation']?.value, 'read');
    });

    test('permission denied reads return a stable structured code', () {
      final message = FileOperationsService.describeFileAccessFailure(
        const FileSystemException(
          'Cannot open file',
          '/tmp/restricted.jff',
          OSError('Permission denied', 13),
        ),
        isWrite: false,
      );

      expect(message.stableCode, 'service.file-operations.access-denied');
      expect(message.arguments['operation']?.value, 'read');
    });

    test('classifies native Windows access and path error codes', () {
      final denied = FileOperationsService.describeFileAccessFailure(
        const FileSystemException(
          'Localized system failure',
          r'C:\restricted\export.jff',
          OSError('Localized system failure', 5),
        ),
        isWrite: true,
      );
      final missing = FileOperationsService.describeFileAccessFailure(
        const FileSystemException(
          'Localized system failure',
          r'C:\missing\input.jff',
          OSError('Localized system failure', 3),
        ),
        isWrite: false,
      );

      expect(
        denied.stableCode,
        Platform.isWindows
            ? 'service.file-operations.access-denied'
            : 'service.file-operations.access-failed',
      );
      expect(
        missing.stableCode,
        Platform.isWindows
            ? 'service.file-operations.location-missing'
            : 'service.file-operations.access-failed',
      );
    });

    test('does not infer the failure kind from the file path', () {
      for (final path in [
        '/tmp/permission denied/export.jff',
        '/tmp/not permitted/export.jff',
        '/tmp/does not exist/export.jff',
      ]) {
        final message = FileOperationsService.describeFileAccessFailure(
          FileSystemException(
            'Localized system failure',
            path,
            const OSError('Localized system failure', 999),
          ),
          isWrite: false,
        );

        expect(
          message.stableCode,
          'service.file-operations.access-failed',
          reason: path,
        );
      }
    });

    test(
      'missing file failures carry a localizable operation contract',
      () async {
        final service = FileOperationsService();
        final directory = await Directory.systemTemp.createTemp(
          'turing-lab-file-operations-',
        );
        addTearDown(() => directory.delete(recursive: true));

        final result = await service.readBytes(
          '${directory.path}${Platform.pathSeparator}missing.jff',
        );

        expect(result.error, 'service.file-operations.location-missing');
        expect(
          result.structuredError?.stableCode,
          'service.file-operations.location-missing',
        );
        expect(result.structuredError?.arguments['operation']?.value, 'read');
        expect(
          result.structuredError?.arguments['operation']?.role,
          'file-operation',
        );
        final english = lookupAppLocalizations(
          const Locale('en'),
        ).resolveStructuredMessage(result.structuredError!);
        final portuguese = lookupAppLocalizations(
          const Locale('pt'),
        ).resolveStructuredMessage(result.structuredError!);
        expect(english, isNot(portuguese));
        expect(english, isNot(contains('service.file-operations')));
        expect(portuguese, isNot(contains('service.file-operations')));
      },
    );
  });
}

Uint8List _bytes(String xml) => Uint8List.fromList(utf8.encode(xml));
