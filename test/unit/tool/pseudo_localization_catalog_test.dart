import 'package:flutter_test/flutter_test.dart';

import '../../../tool/localization/pseudo_localization_catalog.dart';

void main() {
  test(
    'transforms messages while preserving metadata, ICU, and formal text',
    () {
      const formal = 'S → aSb | ε';
      const source = <String, Object?>{
        '@@locale': 'en',
        'result':
            'For {grammar}, use S → aSb | ε. '
            '{count, plural, one {One derivation} other {{count} derivations}}',
        '@result': <String, Object?>{'description': 'Fixture metadata'},
      };

      final first = PseudoLocalizationCatalog.transform(
        source,
        protectedTextByMessage: const <String, List<String>>{
          'result': <String>[formal],
        },
      );
      final second = PseudoLocalizationCatalog.transform(
        source,
        protectedTextByMessage: const <String, List<String>>{
          'result': <String>[formal],
        },
      );

      expect(first, second);
      expect(first['@@locale'], 'en');
      expect(first['@result'], same(source['@result']));
      expect(first['result'], contains(formal));
      expect(first['result'], contains('{grammar}'));
      expect(first['result'], contains('{count, plural,'));
      expect(first['result'], contains('{count}'));
      expect(first['result'], startsWith('⟦'));
      expect(first['result'], endsWith('⟧'));
    },
  );

  test('rejects protection entries that do not name a message', () {
    expect(
      () => PseudoLocalizationCatalog.transform(
        const <String, Object?>{'message': 'Hello'},
        protectedTextByMessage: const <String, List<String>>{
          'missing': <String>['formal'],
        },
      ),
      throwsArgumentError,
    );
  });

  test('rejects non-string ARB messages', () {
    expect(
      () => PseudoLocalizationCatalog.transform(const <String, Object?>{
        'message': 3,
      }),
      throwsFormatException,
    );
  });
}
