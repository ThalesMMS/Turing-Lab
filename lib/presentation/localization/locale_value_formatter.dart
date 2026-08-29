import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Formats display-only numeric values without changing their source values.
final class LocaleValueFormatter {
  LocaleValueFormatter(Locale locale)
    : _localeName = Intl.canonicalizedLocale(locale.toLanguageTag());

  factory LocaleValueFormatter.of(BuildContext context) =>
      LocaleValueFormatter(Localizations.localeOf(context));

  final String _localeName;

  String integer(int value) =>
      NumberFormat.decimalPattern(_localeName).format(value);

  String number(num value, {int decimalDigits = 2}) {
    if (value is int || value == value.roundToDouble()) {
      return integer(value.toInt());
    }
    return decimal(value.toDouble(), decimalDigits: decimalDigits);
  }

  /// Formats an integer interpolated into an already localized template.
  ///
  /// Generated localization methods accept typed integers, but their ICU
  /// interpolation does not apply the presentation grouping used by the
  /// surrounding UI. Comparing a probe render preserves the exact argument
  /// position without matching identical digits in user-controlled content.
  String inLocalizedTemplate(String Function(int value) template, int value) {
    final text = template(value);
    final raw = value.toString();
    final formatted = integer(value);
    if (raw == formatted) return text;
    final range = _integerInterpolationRange(template, value, text);
    if (range == null) return text;
    return text.replaceRange(range.$1, range.$2, formatted);
  }

  /// Formats controlled integer arguments after a message has been localized.
  ///
  /// Replacing longer raw values first through placeholders avoids corrupting
  /// overlaps such as `1` and `1001`. Each item in [values] authorizes one
  /// replacement, so incidental matching digits in an identifier stay intact.
  String integersInLocalizedText(String text, Iterable<int> values) {
    final replacementCounts = <int, int>{};
    for (final value in values) {
      replacementCounts.update(value, (count) => count + 1, ifAbsent: () => 1);
    }
    final uniqueValues = replacementCounts.keys.toList()
      ..sort(
        (left, right) =>
            right.toString().length.compareTo(left.toString().length),
      );
    var result = text;
    final replacements = <String, String>{};
    var placeholderIndex = 0;
    for (final value in uniqueValues) {
      final raw = value.toString();
      for (
        var occurrence = 0;
        occurrence < replacementCounts[value]!;
        occurrence++
      ) {
        final index = _controlledIntegerTokenIndex(result, raw);
        if (index < 0) break;
        final placeholder = String.fromCharCode(0xE000 + placeholderIndex++);
        result = result.replaceRange(index, index + raw.length, placeholder);
        replacements[placeholder] = integer(value);
      }
    }
    for (final replacement in replacements.entries) {
      result = result.replaceAll(replacement.key, replacement.value);
    }
    return result;
  }

  String integerBigInt(BigInt value) {
    final format = NumberFormat.decimalPattern(_localeName);
    final asInt = value.toInt();
    if (BigInt.from(asInt) == value) {
      return format.format(asInt);
    }

    final pattern = format.symbols.DECIMAL_PATTERN.split('.').first;
    final groups = pattern.split(',');
    final primaryGroupSize = groups.last.length;
    final secondaryGroupSize = groups.length > 2
        ? groups[groups.length - 2].length
        : primaryGroupSize;
    final digits = value.abs().toString();
    final grouped = groups.length == 1
        ? digits
        : _groupDigits(
            digits,
            format.symbols.GROUP_SEP,
            primaryGroupSize,
            secondaryGroupSize,
          );
    final zeroDigit = format.symbols.ZERO_DIGIT.runes.first;
    final localizedDigits = String.fromCharCodes(
      grouped.runes.map(
        (rune) => rune >= 0x30 && rune <= 0x39 ? zeroDigit + rune - 0x30 : rune,
      ),
    );
    return '${value.isNegative ? format.symbols.MINUS_SIGN : ''}$localizedDigits';
  }

  String decimal(double value, {int decimalDigits = 2}) {
    final format = NumberFormat.decimalPattern(_localeName)
      ..minimumFractionDigits = decimalDigits
      ..maximumFractionDigits = decimalDigits;
    return format.format(value);
  }

  String percentFromRatio(double ratio, {int decimalDigits = 1}) {
    final format = NumberFormat.percentPattern(_localeName)
      ..minimumFractionDigits = decimalDigits
      ..maximumFractionDigits = decimalDigits;
    return format.format(ratio);
  }

  String compactDuration(Duration duration) {
    if (duration.inMilliseconds.abs() > 0) {
      return '${integer(duration.inMilliseconds)} ms';
    }
    return '${integer(duration.inMicroseconds)} µs';
  }

  String timeOfDay(DateTime value) =>
      DateFormat.jms(_localeName).format(value.toLocal());
}

(int, int)? _integerInterpolationRange(
  String Function(int value) template,
  int value,
  String text,
) {
  for (final offset in const [1000003, -1000033, 2000003]) {
    final probe = value + offset;
    final probeRaw = probe.toString();
    final probeText = template(probe);
    var searchStart = 0;
    while (searchStart < probeText.length) {
      final index = probeText.indexOf(probeRaw, searchStart);
      if (index < 0) break;
      final restored = probeText.replaceRange(
        index,
        index + probeRaw.length,
        value.toString(),
      );
      if (restored == text) {
        return (index, index + value.toString().length);
      }
      searchStart = index + probeRaw.length;
    }
  }
  return null;
}

int _controlledIntegerTokenIndex(String text, String raw) {
  var searchStart = 0;
  while (searchStart < text.length) {
    final index = text.indexOf(raw, searchStart);
    if (index < 0) return -1;
    final end = index + raw.length;
    if (!_hasIdentifierBoundaryBefore(text, index) &&
        !_hasIdentifierBoundaryAfter(text, end)) {
      return index;
    }
    searchStart = end;
  }
  return -1;
}

bool _hasIdentifierBoundaryBefore(String text, int index) {
  if (index == 0) return false;
  final character = text[index - 1];
  if (_isIdentifierCoreCharacter(character)) return true;
  return _isIdentifierSeparator(character) &&
      index > 1 &&
      _isIdentifierCoreCharacter(text[index - 2]);
}

bool _hasIdentifierBoundaryAfter(String text, int end) {
  if (end == text.length) return false;
  final character = text[end];
  if (_isIdentifierCoreCharacter(character)) return true;
  return _isIdentifierSeparator(character) &&
      end + 1 < text.length &&
      _isIdentifierCoreCharacter(text[end + 1]);
}

bool _isIdentifierCoreCharacter(String character) =>
    RegExp(r'[A-Za-z0-9_]').hasMatch(character);

bool _isIdentifierSeparator(String character) =>
    character == '.' || character == '-';

String _groupDigits(
  String digits,
  String separator,
  int primaryGroupSize,
  int secondaryGroupSize,
) {
  if (digits.length <= primaryGroupSize || primaryGroupSize <= 0) {
    return digits;
  }

  final groups = <String>[];
  var end = digits.length;
  var groupSize = primaryGroupSize;
  while (end > groupSize) {
    final start = end - groupSize;
    groups.insert(0, digits.substring(start, end));
    end = start;
    groupSize = secondaryGroupSize;
  }
  groups.insert(0, digits.substring(0, end));
  return groups.join(separator);
}
