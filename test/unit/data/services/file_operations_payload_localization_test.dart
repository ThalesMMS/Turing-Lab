import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/interoperability/interoperability.dart';
import 'package:turing_lab/core/messages/structured_message.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/data/services/file_operations_service.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  FSA invalidAutomaton() {
    final timestamp = DateTime.utc(2026);
    return FSA(
      id: 'invalid',
      name: 'Invalid',
      states: const {},
      transitions: const {},
      alphabet: const {},
      acceptingStates: const {},
      created: timestamp,
      modified: timestamp,
      bounds: const math.Rectangle<double>(0, 0, 100, 100),
      zoomLevel: 1,
      panOffset: Vector2.zero(),
    );
  }

  test(
    'interoperability review failure keeps locale-neutral semantics',
    () async {
      const source = '''
<structure type="fa" vendor="keep">
  <type>fa</type>
  <automaton>
    <state id="q0" name="q0"><x>0</x><y>0</y><initial/></state>
  </automaton>
</structure>
''';

      final result = await FileOperationsService().loadAutomatonFromBytes(
        Uint8List.fromList(utf8.encode(source)),
      );

      expect(result.error, 'codec.requires-interoperability-review');
      expect(
        result.structuredError?.stableCode,
        'service.file-operations.interoperability-review-required',
      );
      expect(
        StructuredMessage.fromJson(result.structuredError!.toJson()),
        result.structuredError,
      );
    },
  );

  test(
    'malformed payload does not append internal prose to protocol code',
    () async {
      final result = await FileOperationsService().loadAutomatonFromBytes(
        Uint8List.fromList(utf8.encode('<structure')),
      );

      expect(result.isFailure, isTrue);
      expect(result.error, startsWith('codec.malformed.'));
      expect(result.error, isNot(contains(':')));
      expect(result.structuredError, isNotNull);
    },
  );

  test('synchronous encode failure carries structured semantics', () {
    final service = FileOperationsService();
    final invalid = invalidAutomaton();

    expect(
      () => service.serializeAutomatonToJFLAPString(invalid),
      throwsA(
        isA<CodecOperationException>()
            .having(
              (error) => error.compatibilityCode,
              'compatibilityCode',
              'codec.malformed.syntax',
            )
            .having(
              (error) => error.structuredMessage.stableCode,
              'structuredMessage',
              'service.file-operations.codec-malformed',
            )
            .having(
              (error) => error.toString(),
              'safe string form',
              'codec.malformed.syntax',
            ),
      ),
    );
  });

  test('native save preserves structured encode failure', () async {
    final result = await FileOperationsService().saveAutomatonToJFLAP(
      invalidAutomaton(),
      'unused-invalid-automaton.jff',
    );

    expect(result.error, 'codec.malformed.syntax');
    expect(
      result.structuredError?.stableCode,
      'service.file-operations.codec-malformed',
    );
  });
}
