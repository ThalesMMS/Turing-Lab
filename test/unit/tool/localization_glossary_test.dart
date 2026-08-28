import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shared EN/PT-BR glossary has stable, complete entries', () {
    final json =
        jsonDecode(
              File('docs/localization/terminology.v1.json').readAsStringSync(),
            )
            as Map<String, Object?>;
    expect(json['schemaVersion'], 1);
    expect(json['reviewStatus'], 'technical-reviewed');
    expect(
      json['reviewProvenance'],
      containsPair('editorialReview', 'pending'),
    );
    expect(json['sourceLocale'], 'en-US');
    expect(json['targetLocale'], 'pt-BR');

    final terms = (json['terms']! as List<Object?>)
        .cast<Map<String, Object?>>();
    final ids = <String>{};
    for (final term in terms) {
      expect(ids.add(term['id']! as String), isTrue);
      expect((term['en-US']! as String).trim(), isNotEmpty);
      expect((term['pt-BR']! as String).trim(), isNotEmpty);
      expect((term['definition']! as String).trim(), isNotEmpty);
      expect((term['usage']! as String).trim(), isNotEmpty);
    }
    expect(
      ids,
      containsAll(<String>{
        'automaton',
        'state',
        'transition',
        'grammar',
        'parsing',
        'tape',
        'stack',
        'output',
        'accept',
        'reject',
        'halt',
        'unknown_outcome',
        'empty_string',
        'pumping_lemma',
        'workspace',
      }),
    );
  });
}
