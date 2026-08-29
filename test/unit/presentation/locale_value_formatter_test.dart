import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:turing_lab/core/algorithms/regex_simplifier.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/localization/locale_value_formatter.dart';

void main() {
  test('formats display values for English and Brazilian Portuguese', () {
    final english = LocaleValueFormatter(const Locale('en'));
    final portuguese = LocaleValueFormatter(const Locale('pt', 'BR'));
    expect(english.integer(1234), '1,234');
    expect(portuguese.integer(1234), '1.234');
    expect(english.decimal(2.5), '2.50');
    expect(portuguese.decimal(2.5), '2,50');
    expect(english.percentFromRatio(0.125), '12.5%');
    expect(portuguese.percentFromRatio(0.125), '12,5%');
  });

  test('formats multiple integers after localized wording is selected', () {
    final portuguese = LocaleValueFormatter(const Locale('pt', 'BR'));

    expect(
      portuguese.integersInLocalizedText(
        'Passo 1 de 1001; total 1234/1234',
        const [1, 1001, 1234, 1234],
      ),
      'Passo 1 de 1.001; total 1.234/1.234',
    );
    expect(
      portuguese.integersInLocalizedText(
        'Relatório report-1234.csv: importados 1234 casos.',
        const [1234],
      ),
      'Relatório report-1234.csv: importados 1.234 casos.',
    );
  });

  test('formats an integer immediately before sentence punctuation', () {
    final portuguese = LocaleValueFormatter(const Locale('pt', 'BR'));

    expect(
      portuguese.integersInLocalizedText(
        'A quantidade de casos não pode exceder 10000.',
        const [10000],
      ),
      'A quantidade de casos não pode exceder 10.000.',
    );
  });

  test('formats compact durations without changing the Duration', () {
    final english = LocaleValueFormatter(const Locale('en'));
    final portuguese = LocaleValueFormatter(const Locale('pt', 'BR'));
    const duration = Duration(milliseconds: 1234);

    expect(english.compactDuration(duration), '1,234 ms');
    expect(portuguese.compactDuration(duration), '1.234 ms');
    expect(duration.inMilliseconds, 1234);
  });

  test('keeps negative millisecond durations in milliseconds', () {
    final english = LocaleValueFormatter(const Locale('en'));
    final portuguese = LocaleValueFormatter(const Locale('pt', 'BR'));
    const duration = Duration(milliseconds: -1500);

    expect(english.compactDuration(duration), '-1,500 ms');
    expect(portuguese.compactDuration(duration), '-1.500 ms');
  });

  test('formats arbitrary BigInt values by locale', () {
    final english = LocaleValueFormatter(const Locale('en'));
    final portuguese = LocaleValueFormatter(const Locale('pt', 'BR'));
    final value = BigInt.parse('12345678901234567890');

    expect(english.integerBigInt(value), '12,345,678,901,234,567,890');
    expect(portuguese.integerBigInt(value), '12.345.678.901.234.567.890');
    expect(english.integerBigInt(-value), '-12,345,678,901,234,567,890');
    expect(portuguese.integerBigInt(-value), '-12.345.678.901.234.567.890');
  });

  test('formats typed integers inside localized ICU templates', () {
    final english = LocaleValueFormatter(const Locale('en'));
    final portuguese = LocaleValueFormatter(const Locale('pt', 'BR'));
    final en = lookupAppLocalizations(const Locale('en'));
    final pt = lookupAppLocalizations(const Locale('pt', 'BR'));

    expect(
      english.inLocalizedTemplate(en.tapeCellSemantics, 1234),
      'Tape cell 1,234',
    );
    expect(
      portuguese.inLocalizedTemplate(pt.tapeCellSemantics, 1234),
      'Célula 1.234 da fita',
    );
    expect(
      portuguese.inLocalizedTemplate(
        (value) => pt.tmMultiTapeAtomicTransition('t0', value),
        2,
      ),
      'Transição t0; 2 fitas atualizadas atomicamente',
    );
    expect(
      portuguese.inLocalizedTemplate(
        (value) => 'report-1234.csv: $value registros',
        1234,
      ),
      'report-1234.csv: 1.234 registros',
    );
  });

  test('locale formatting does not change machine-readable result values', () {
    final previousLocale = Intl.defaultLocale;
    addTearDown(() => Intl.defaultLocale = previousLocale);
    Intl.defaultLocale = 'pt_BR';
    const result = RegexSimplificationResult(
      originalRegex: '(a|∅)ε',
      simplifiedRegex: 'a',
      steps: [],
      executionTime: Duration(milliseconds: 1234),
      totalRulesApplied: 2,
    );

    final payload = result.toJson();
    final encoded = jsonEncode(payload);

    expect(payload['originalRegex'], '(a|∅)ε');
    expect(payload['simplifiedRegex'], 'a');
    expect(payload['executionTimeMs'], 1234);
    expect(payload['reductionPercentage'], closeTo(83.3333333333, 0.000001));
    expect(encoded, contains('"executionTimeMs":1234'));
    expect(encoded, contains('"reductionPercentage":83.33333333333334'));
    expect(encoded, isNot(contains('1.234')));
    expect(encoded, isNot(contains('83,333')));
  });
}
