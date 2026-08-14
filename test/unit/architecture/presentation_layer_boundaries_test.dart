import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('presentation and feature code do not import the data layer', () {
    final dataImport = RegExp(
      r'''import\s+['"](?:package:turing_lab/data/|(?:\.\./)+data/)''',
    );
    final offenders = ['lib/presentation', 'lib/features']
        .expand(
          (path) => Directory(path)
              .listSync(recursive: true)
              .whereType<File>()
              .where((file) => file.path.endsWith('.dart')),
        )
        .where((file) => dataImport.hasMatch(file.readAsStringSync()))
        .map((file) => file.path)
        .toList()
      ..sort();

    expect(offenders, isEmpty);
  });
}
