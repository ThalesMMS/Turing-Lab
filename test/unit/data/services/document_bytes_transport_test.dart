import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/data/services/file_operations_service.dart';

void main() {
  test('generic native byte gateway reads exactly what it writes', () async {
    final directory = Directory.systemTemp.createTempSync(
      'turing-lab-document-transport-',
    );
    addTearDown(() => directory.deleteSync(recursive: true));
    final path = '${directory.path}${Platform.pathSeparator}document.json';
    final bytes = Uint8List.fromList(utf8.encode('{"value":1}'));
    final service = FileOperationsService();

    final written = await service.writeBytes(
      bytes,
      path,
      mimeType: 'application/json',
    );
    final read = await service.readBytes(path);

    expect(written.isSuccess, isTrue);
    expect(written.data, path);
    expect(read.isSuccess, isTrue);
    expect(read.data, bytes);
  });

  test('legacy model-only import rejects extension sidecar loss', () async {
    const source = '''
<structure type="fa" vendor="keep">
  <type>fa</type>
  <automaton>
    <state id="q0" name="q0"><x>0</x><y>0</y><initial/></state>
  </automaton>
</structure>
''';
    final service = FileOperationsService();

    final result = await service.loadAutomatonFromBytes(
      Uint8List.fromList(utf8.encode(source)),
    );

    expect(result.isFailure, isTrue);
    expect(result.error, 'codec.requires-interoperability-review');
  });

  test('legacy model-only import rejects lossy epsilon interpretation',
      () async {
    const source = '''
<structure type="fa">
  <type>fa</type>
  <automaton>
    <state id="q0" name="q0"><x>0</x><y>0</y><initial/></state>
    <state id="q1" name="q1"><x>1</x><y>1</y></state>
    <transition><from>q0</from><to>q1</to><read>eps</read></transition>
  </automaton>
</structure>
''';
    final service = FileOperationsService();

    final result = await service.loadAutomatonFromBytes(
      Uint8List.fromList(utf8.encode(source)),
    );

    expect(result.isFailure, isTrue);
    expect(result.error, 'codec.requires-interoperability-review');
  });
}
