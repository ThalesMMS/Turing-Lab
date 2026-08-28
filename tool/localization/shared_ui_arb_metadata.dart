import 'dart:convert';
import 'dart:io';

const _scopePath = 'tool/localization/shared_ui_scope.v1.json';
const _englishArbPath = 'lib/l10n/app_en.arb';
const _portugueseArbPath = 'lib/l10n/app_pt.arb';

final _propertyNamePattern = RegExp(r'\.\s*([A-Za-z][A-Za-z0-9_]*)');
final _placeholderPattern = RegExp(r'\{([A-Za-z][A-Za-z0-9_]*)\s*(?:,|\})');

Set<String> discoverSharedUiMessageKeys(
  Directory root,
  Map<String, Object?> englishArb,
) {
  final scope =
      jsonDecode(File('${root.path}/$_scopePath').readAsStringSync())
          as Map<String, Object?>;
  final keys = <String>{};

  for (final relativePath
      in (scope['files']! as List<Object?>).cast<String>()) {
    final source = File('${root.path}/$relativePath').readAsStringSync();
    for (final match in _propertyNamePattern.allMatches(source)) {
      final candidate = match.group(1)!;
      if (englishArb.containsKey(candidate)) {
        keys.add(candidate);
      }
    }
  }

  return keys;
}

List<String> validateSharedUiArbMetadata(
  Directory root, {
  Map<String, Object?>? englishArb,
  Map<String, Object?>? portugueseArb,
}) {
  final english = englishArb ?? _readArb(root, _englishArbPath);
  final portuguese = portugueseArb ?? _readArb(root, _portugueseArbPath);
  final keys = discoverSharedUiMessageKeys(root, english).toList()..sort();
  final errors = <String>[];

  if (keys.length < 400) {
    errors.add(
      'Shared UI message discovery found only ${keys.length} keys; '
      'expected at least 400 source-backed keys.',
    );
  }

  for (final key in keys) {
    final englishMessage = english[key];
    final portugueseMessage = portuguese[key];
    if (englishMessage is! String || portugueseMessage is! String) {
      errors.add('$key must have string messages in both ARB files.');
      continue;
    }

    final englishMetadata = _metadata(english, key, 'en', errors);
    final portugueseMetadata = _metadata(portuguese, key, 'pt-BR', errors);
    if (englishMetadata == null || portugueseMetadata == null) {
      continue;
    }

    final englishPlaceholders = _messagePlaceholders(englishMessage);
    final portuguesePlaceholders = _messagePlaceholders(portugueseMessage);
    if (!_sameSet(englishPlaceholders, portuguesePlaceholders)) {
      errors.add(
        '$key has message placeholder drift: '
        'en=$englishPlaceholders pt-BR=$portuguesePlaceholders.',
      );
    }

    final englishContract = _placeholderContract(englishMetadata);
    final portugueseContract = _placeholderContract(portugueseMetadata);
    if (!_sameSet(englishPlaceholders, englishContract.keys)) {
      errors.add(
        '$key has incomplete en placeholder metadata: '
        'message=$englishPlaceholders metadata=${englishContract.keys.toSet()}.',
      );
    }
    if (!_sameSet(portuguesePlaceholders, portugueseContract.keys)) {
      errors.add(
        '$key has incomplete pt-BR placeholder metadata: '
        'message=$portuguesePlaceholders '
        'metadata=${portugueseContract.keys.toSet()}.',
      );
    }
    if (!_sameContract(englishContract, portugueseContract)) {
      errors.add('$key has placeholder metadata drift between locales.');
    }
  }

  return errors;
}

Map<String, Object?> _readArb(Directory root, String relativePath) =>
    (jsonDecode(File('${root.path}/$relativePath').readAsStringSync())
        as Map<String, Object?>);

Map<String, Object?>? _metadata(
  Map<String, Object?> arb,
  String key,
  String locale,
  List<String> errors,
) {
  final metadata = arb['@$key'];
  if (metadata is! Map<String, Object?>) {
    errors.add('$key is missing $locale metadata.');
    return null;
  }
  final description = metadata['description'];
  if (description is! String || description.trim().isEmpty) {
    errors.add('$key is missing a $locale metadata description.');
  }
  return metadata;
}

Set<String> _messagePlaceholders(String message) => _placeholderPattern
    .allMatches(message)
    .map((match) => match.group(1)!)
    .toSet();

Map<String, Object?> _placeholderContract(Map<String, Object?> metadata) {
  final placeholders = metadata['placeholders'];
  if (placeholders is! Map<String, Object?>) {
    return const <String, Object?>{};
  }
  return placeholders;
}

bool _sameSet(Iterable<String> left, Iterable<String> right) {
  final leftSet = left.toSet();
  final rightSet = right.toSet();
  return leftSet.length == rightSet.length && leftSet.containsAll(rightSet);
}

bool _sameContract(Map<String, Object?> left, Map<String, Object?> right) {
  if (!_sameSet(left.keys, right.keys)) return false;
  for (final key in left.keys) {
    final leftValue = _semanticPlaceholderContract(left[key]);
    final rightValue = _semanticPlaceholderContract(right[key]);
    if (jsonEncode(leftValue) != jsonEncode(rightValue)) return false;
  }
  return true;
}

Object? _semanticPlaceholderContract(Object? value) {
  if (value is! Map<String, Object?>) return value;
  return <String, Object?>{
    for (final field in const ['type', 'format', 'optionalParameters'])
      if (value.containsKey(field)) field: value[field],
  };
}
