/// Syntax dialect used as the source of truth for a regex document.
enum RegexDialect {
  turingLabV1,
}

/// Token boundary convention used by the current Regex workspace.
enum RegexTokenization {
  unicodeScalar,
}

/// Durable, language-neutral state of a regular-expression document.
final class RegexDocument {
  RegexDocument({
    required this.id,
    required this.name,
    required this.source,
    required Iterable<String> alphabet,
    this.dialect = RegexDialect.turingLabV1,
    this.tokenization = RegexTokenization.unicodeScalar,
    this.epsilonSymbol = 'ε',
    this.emptyLanguageSymbol = '∅',
  }) : alphabet = List<String>.unmodifiable(alphabet);

  final String id;
  final String name;
  final String source;
  final List<String> alphabet;
  final RegexDialect dialect;
  final RegexTokenization tokenization;
  final String epsilonSymbol;
  final String emptyLanguageSymbol;

  List<String> validate() {
    final errors = <String>[];
    if (id.trim().isEmpty) errors.add('Regex document id must be non-empty.');
    if (name.trim().isEmpty) {
      errors.add('Regex document name must be non-empty.');
    }
    if (epsilonSymbol.isEmpty || emptyLanguageSymbol.isEmpty) {
      errors.add('Regex special symbols must be non-empty.');
    }
    if (epsilonSymbol == emptyLanguageSymbol) {
      errors.add('Regex epsilon and empty-language symbols must differ.');
    }
    final seen = <String>{};
    for (final symbol in alphabet) {
      if (symbol.isEmpty) {
        errors.add('Regex alphabet symbols must be non-empty.');
      } else if (!seen.add(symbol)) {
        errors.add('Regex alphabet symbols must be unique.');
      } else if (symbol.runes.length != 1) {
        errors.add(
          'The unicodeScalar tokenization requires one scalar per alphabet symbol.',
        );
      }
    }
    return errors;
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'source': source,
        'dialect': dialect.name,
        'tokenization': tokenization.name,
        'alphabet': alphabet,
        'epsilonSymbol': epsilonSymbol,
        'emptyLanguageSymbol': emptyLanguageSymbol,
      };

  factory RegexDocument.fromJson(Map<String, dynamic> json) {
    final rawAlphabet = json['alphabet'];
    final alphabet = switch (rawAlphabet) {
      List() => rawAlphabet.cast<String>(),
      String() => rawAlphabet.runes.map(String.fromCharCode).toList(),
      null => const <String>[],
      _ => throw const FormatException(
          'Regex alphabet must be a string or an array of symbols.',
        ),
    };
    final source = json['source'] ?? json['currentRegex'] ?? '';
    if (source is! String) {
      throw const FormatException('Regex source must be a string.');
    }
    return RegexDocument(
      id: json['id'] as String? ?? 'regex-document',
      name: json['name'] as String? ?? 'Regular expression',
      source: source,
      alphabet: alphabet,
      dialect: _enumValue(
        RegexDialect.values,
        json['dialect'],
        RegexDialect.turingLabV1,
        'dialect',
      ),
      tokenization: _enumValue(
        RegexTokenization.values,
        json['tokenization'],
        RegexTokenization.unicodeScalar,
        'tokenization',
      ),
      epsilonSymbol: json['epsilonSymbol'] as String? ?? 'ε',
      emptyLanguageSymbol: json['emptyLanguageSymbol'] as String? ?? '∅',
    );
  }
}

T _enumValue<T extends Enum>(
  List<T> values,
  Object? raw,
  T fallback,
  String field,
) {
  if (raw == null) return fallback;
  if (raw is! String) throw FormatException('Regex $field must be a string.');
  for (final value in values) {
    if (value.name == raw) return value;
  }
  throw FormatException('Unsupported regex $field: $raw.');
}
