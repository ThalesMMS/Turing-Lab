import 'dart:math' as math;

/// Pseudo-localizes messages for development and test builds.
///
/// This utility lives outside `lib/` and does not register an app locale. ICU
/// arguments and selectors remain unchanged. Callers can also protect formal
/// notation or user-authored text passed inline.
abstract final class PseudoLocalizer {
  static const String openingMarker = '⟦';
  static const String closingMarker = '⟧';

  static const double _targetExpansion = 1.4;
  static const String _paddingCharacter = '~';
  static const String _protectedStart = '\u{e000}';
  static const String _protectedEnd = '\u{e001}';

  static const Map<String, String> _accentedCharacters = <String, String>{
    'A': 'Å',
    'B': 'Ɓ',
    'C': 'Ç',
    'D': 'Ð',
    'E': 'É',
    'F': 'Ƒ',
    'G': 'Ğ',
    'H': 'Ħ',
    'I': 'Î',
    'J': 'Ĵ',
    'K': 'Ķ',
    'L': 'Ļ',
    'M': 'Ṁ',
    'N': 'Ñ',
    'O': 'Ø',
    'P': 'Þ',
    'Q': 'Ǫ',
    'R': 'Ŕ',
    'S': 'Š',
    'T': 'Ŧ',
    'U': 'Û',
    'V': 'Ṽ',
    'W': 'Ŵ',
    'X': 'Ẋ',
    'Y': 'Ý',
    'Z': 'Ž',
    'a': 'å',
    'b': 'ƀ',
    'c': 'ç',
    'd': 'đ',
    'e': 'é',
    'f': 'ƒ',
    'g': 'ğ',
    'h': 'ħ',
    'i': 'î',
    'j': 'ĵ',
    'k': 'ķ',
    'l': 'ļ',
    'm': 'ṁ',
    'n': 'ñ',
    'o': 'ø',
    'p': 'þ',
    'q': 'ǫ',
    'r': 'ŕ',
    's': 'š',
    't': 'ŧ',
    'u': 'û',
    'v': 'ṽ',
    'w': 'ŵ',
    'x': 'ẋ',
    'y': 'ý',
    'z': 'ž',
  };

  /// Returns a marked, accented message about 40 percent longer than [source].
  ///
  /// The visible markers count toward that target. For strings shorter than four
  /// code units, their fixed two-character overhead necessarily exceeds 50% and
  /// no additional padding is added.
  ///
  /// Entries in [protectedText] are restored unchanged. Empty entries are
  /// ignored. Longer entries take precedence when protected values overlap.
  static String localize(
    String source, {
    Iterable<String> protectedText = const <String>[],
  }) {
    final protectedValues =
        protectedText.where((value) => value.isNotEmpty).toSet().toList()
          ..sort((left, right) => right.length.compareTo(left.length));

    var masked = source;
    final replacements = <String, String>{};
    // Avoid private-use sentinel collisions with source or already masked text.
    var sentinelIndex = 0;
    for (final value in protectedValues) {
      if (!masked.contains(value)) continue;
      String sentinel;
      do {
        sentinel = '$_protectedStart${sentinelIndex++}$_protectedEnd';
      } while (masked.contains(sentinel));
      masked = masked.replaceAll(value, sentinel);
      replacements[sentinel] = value;
    }

    var transformed = _transformMessage(masked);
    for (final replacement in replacements.entries) {
      transformed = transformed.replaceAll(replacement.key, replacement.value);
    }

    final targetLength = (source.length * _targetExpansion).ceil();
    final markedLength =
        transformed.length + openingMarker.length + closingMarker.length;
    final paddingLength = math.max(0, targetLength - markedLength);
    final padding = _paddingCharacter * paddingLength;

    return '$openingMarker$transformed$padding$closingMarker';
  }

  static String _transformMessage(String source) {
    final result = StringBuffer();
    var index = 0;

    while (index < source.length) {
      if (source[index] != '{') {
        result.write(_accentedCharacters[source[index]] ?? source[index]);
        index += 1;
        continue;
      }

      final closingBrace = _findClosingBrace(source, index);
      if (closingBrace == null) {
        result.write(_accentedCharacters[source[index]] ?? source[index]);
        index += 1;
        continue;
      }

      result.write(
        _transformExpression(source.substring(index, closingBrace + 1)),
      );
      index = closingBrace + 1;
    }

    return result.toString();
  }

  static String _transformExpression(String expression) {
    final inner = expression.substring(1, expression.length - 1);
    final commas = _topLevelCommas(inner);
    if (commas.length < 2) return expression;

    final argumentType = inner
        .substring(commas[0] + 1, commas[1])
        .trim()
        .toLowerCase();
    if (argumentType != 'plural' &&
        argumentType != 'select' &&
        argumentType != 'selectordinal') {
      return expression;
    }

    final result = StringBuffer('{')..write(inner.substring(0, commas[1] + 1));
    final variants = inner.substring(commas[1] + 1);
    var index = 0;

    while (index < variants.length) {
      final openingBrace = variants.indexOf('{', index);
      if (openingBrace < 0) {
        result.write(variants.substring(index));
        break;
      }

      result.write(variants.substring(index, openingBrace + 1));
      final closingBrace = _findClosingBrace(variants, openingBrace);
      if (closingBrace == null) {
        result.write(variants.substring(openingBrace + 1));
        break;
      }

      result.write(
        _transformMessage(variants.substring(openingBrace + 1, closingBrace)),
      );
      result.write('}');
      index = closingBrace + 1;
    }

    result.write('}');
    return result.toString();
  }

  static List<int> _topLevelCommas(String source) {
    final commas = <int>[];
    var depth = 0;
    for (var index = 0; index < source.length; index += 1) {
      switch (source[index]) {
        case '{':
          depth += 1;
        case '}':
          depth -= 1;
        case ',':
          if (depth == 0) commas.add(index);
      }
    }
    return commas;
  }

  static int? _findClosingBrace(String source, int openingBrace) {
    var depth = 0;
    for (var index = openingBrace; index < source.length; index += 1) {
      switch (source[index]) {
        case '{':
          depth += 1;
        case '}':
          depth -= 1;
          if (depth == 0) return index;
      }
    }
    return null;
  }
}
