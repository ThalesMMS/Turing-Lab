import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('transducer foundation stays independent of Flutter and presentation',
      () {
    final files = Directory('lib/core/transducers')
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in files) {
      final source = file.readAsStringSync();
      expect(source, isNot(contains('package:flutter/')), reason: file.path);
      expect(source, isNot(contains('package:flutter_riverpod/')),
          reason: file.path);
      expect(source, isNot(contains('../../presentation/')), reason: file.path);
      expect(source, isNot(contains('../../data/')), reason: file.path);
    }
  });
}
