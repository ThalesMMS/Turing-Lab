import 'dart:convert';
import 'dart:io';

import 'pseudo_localization_catalog.dart';
import 'pseudo_localizer.dart';

void main() {
  final errors = <String>[];
  final sourceFile = File('lib/l10n/app_en.arb');
  final source = _readCatalog(sourceFile, errors);
  if (source == null) {
    _finish(errors);
  }

  Map<String, Object?> transformed;
  try {
    transformed = PseudoLocalizationCatalog.transform(source);
  } on Object catch (error) {
    errors.add('cannot pseudo-localize ${sourceFile.path}: $error');
    _finish(errors);
  }

  final repeated = PseudoLocalizationCatalog.transform(source);
  if (jsonEncode(transformed) != jsonEncode(repeated)) {
    errors.add('catalog transformation is not deterministic');
  }
  if (!_sameKeys(source, transformed)) {
    errors.add('catalog keys changed during pseudo-localization');
  }
  for (final entry in source.entries) {
    final transformedValue = transformed[entry.key];
    if (entry.key.startsWith('@')) {
      if (jsonEncode(entry.value) != jsonEncode(transformedValue)) {
        errors.add('metadata changed during pseudo-localization: ${entry.key}');
      }
      continue;
    }
    if (transformedValue is! String ||
        !transformedValue.startsWith(PseudoLocalizer.openingMarker) ||
        !transformedValue.endsWith(PseudoLocalizer.closingMarker)) {
      errors.add(
        'message is not marked after pseudo-localization: ${entry.key}',
      );
    }
  }

  const formal = 'M = (Q, Σ, δ)';
  const fixture = <String, Object?>{
    'trace':
        'Inspect {machine}: M = (Q, Σ, δ). '
        '{count, plural, one {One step} other {{count} steps}}',
    '@trace': <String, Object?>{
      'description': 'Contract fixture',
      'placeholders': <String, Object?>{
        'machine': <String, Object?>{'type': 'String'},
        'count': <String, Object?>{'type': 'int'},
      },
    },
  };
  final protected = PseudoLocalizationCatalog.transform(
    fixture,
    protectedTextByMessage: const <String, List<String>>{
      'trace': <String>[formal],
    },
  );
  final trace = protected['trace']! as String;
  if (!trace.contains(formal)) {
    errors.add('protected formal content changed');
  }
  for (final token in const <String>[
    '{machine}',
    '{count, plural,',
    '{count}',
  ]) {
    if (!trace.contains(token)) errors.add('ICU token changed: $token');
  }
  if (jsonEncode(protected['@trace']) != jsonEncode(fixture['@trace'])) {
    errors.add('fixture metadata changed');
  }

  if (errors.isEmpty) {
    final messageCount = source.keys
        .where((key) => !key.startsWith('@'))
        .length;
    stdout.writeln(
      'Pseudo-localization contract passed for $messageCount messages.',
    );
  }
  _finish(errors);
}

Map<String, Object?>? _readCatalog(File file, List<String> errors) {
  try {
    final value = jsonDecode(file.readAsStringSync());
    if (value is Map<String, Object?>) return value;
    errors.add('${file.path} must contain a JSON object');
  } on Object catch (error) {
    errors.add('cannot read ${file.path}: $error');
  }
  return null;
}

bool _sameKeys(Map<String, Object?> left, Map<String, Object?> right) {
  return left.length == right.length && left.keys.every(right.containsKey);
}

Never _finish(List<String> errors) {
  if (errors.isEmpty) exit(0);
  stderr.writeln('Pseudo-localization contract failed:');
  for (final error in errors) {
    stderr.writeln('- $error');
  }
  exit(1);
}
