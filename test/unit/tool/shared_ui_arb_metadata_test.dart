import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../tool/localization/shared_ui_arb_metadata.dart';

void main() {
  final root = Directory.current;

  test('source-backed shared UI messages have complete ARB metadata', () {
    final errors = validateSharedUiArbMetadata(root);
    expect(errors, isEmpty, reason: errors.join('\n'));
  });

  test('validator rejects a missing shared-key description', () {
    final english = _readArb(root, 'lib/l10n/app_en.arb');
    final portuguese = _readArb(root, 'lib/l10n/app_pt.arb');
    final keys = discoverSharedUiMessageKeys(root, english).toList()..sort();
    final key = keys.first;
    final metadata = Map<String, Object?>.from(
      english['@$key']! as Map<String, Object?>,
    )..remove('description');
    final mutatedEnglish = Map<String, Object?>.from(english)
      ..['@$key'] = metadata;

    expect(
      validateSharedUiArbMetadata(
        root,
        englishArb: mutatedEnglish,
        portugueseArb: portuguese,
      ),
      contains('$key is missing a en metadata description.'),
    );
  });
}

Map<String, Object?> _readArb(Directory root, String relativePath) =>
    jsonDecode(File('${root.path}/$relativePath').readAsStringSync())
        as Map<String, Object?>;
