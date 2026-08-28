import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/presentation/localization/app_locale_policy.dart';

import '../../../tool/localization/pseudo_localizer.dart';

void main() {
  group('PseudoLocalizer', () {
    test('marks, accents, and expands plain text by 30 to 50 percent', () {
      const source = 'Save changes';

      final result = PseudoLocalizer.localize(source);

      expect(result, startsWith(PseudoLocalizer.openingMarker));
      expect(result, endsWith(PseudoLocalizer.closingMarker));
      expect(result, contains('Šåṽé çħåñğéš'));
      expect(result.length / source.length, inInclusiveRange(1.3, 1.5));
    });

    test('short and empty labels add markers without artificial padding', () {
      expect(PseudoLocalizer.localize('OK'), '⟦ØĶ⟧');
      expect(PseudoLocalizer.localize('Yes'), '⟦Ýéš⟧');
      expect(PseudoLocalizer.localize(''), '⟦⟧');
    });

    test('preserves placeholders and ICU syntax while transforming branches', () {
      const source =
          '{count, plural, =0 {No {item}} one {One {item}} other {{count} {item}s}}';

      final result = PseudoLocalizer.localize(source);

      expect(result, contains('{count, plural, =0 {'));
      expect(result, contains('one {'));
      expect(result, contains('other {'));
      expect('{count'.allMatches(result), hasLength(2));
      expect('{count}'.allMatches(result), hasLength(1));
      expect('{item}'.allMatches(result), hasLength(3));
      expect(result, contains('Ñø {item}'));
      expect(result, contains('Øñé {item}'));
    });

    test('does not alter protected formal or user-authored content', () {
      const formalBlock = 'M = (Q, Σ, δ)';
      const userContent = "Ana's machine";
      const source = 'Inspect M = (Q, Σ, δ) named Ana\'s machine';

      final result = PseudoLocalizer.localize(
        source,
        protectedText: const <String>[formalBlock, userContent],
      );

      expect(result, contains(formalBlock));
      expect(result, contains(userContent));
      expect(result, contains('Îñšþéçŧ'));
    });

    test('preserves source text that resembles a protection sentinel', () {
      const sentinelShapedText = '\u{e000}0\u{e001}';
      const source = 'Keep $sentinelShapedText and Ana';

      final result = PseudoLocalizer.localize(
        source,
        protectedText: const <String>['Ana'],
      );

      expect(result, contains(sentinelShapedText));
      expect(result, contains('Ana'));
      expect(result, contains('Ķééþ'));
    });

    test('is absent from production locale choices', () {
      expect(AppLocalePolicy.supportedLocales, const <Locale>[
        Locale('en', 'US'),
        Locale('pt', 'BR'),
      ]);
      expect(
        AppLocalePolicy.supportedLocales.map((locale) => locale.languageCode),
        isNot(contains('qps')),
      );
    });
  });
}
