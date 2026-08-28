import 'dart:convert';

enum GenerationMode { valid, boundaryValid, malformed }

const stablePrngAlgorithm = 'xorshift32';
const stablePrngVersion = 1;

final class GenerationBudget {
  const GenerationBudget({
    this.maxSymbols = 6,
    this.maxWordLength = 12,
    this.maxStates = 8,
    this.maxTransitions = 24,
    this.maxProductions = 20,
    this.maxRegexNodes = 24,
    this.maxTapeCells = 24,
    this.maxStackDepth = 16,
    this.maxIterations = 8,
  })  : assert(maxSymbols >= 0),
        assert(maxWordLength >= 0),
        assert(maxStates >= 0),
        assert(maxTransitions >= 0),
        assert(maxProductions >= 0),
        assert(maxRegexNodes > 0),
        assert(maxTapeCells >= 0),
        assert(maxStackDepth >= 0),
        assert(maxIterations >= 0);

  final int maxSymbols;
  final int maxWordLength;
  final int maxStates;
  final int maxTransitions;
  final int maxProductions;
  final int maxRegexNodes;
  final int maxTapeCells;
  final int maxStackDepth;
  final int maxIterations;

  List<String> validate() => [
        if (maxSymbols < 0) 'maxSymbols must be non-negative.',
        if (maxWordLength < 0) 'maxWordLength must be non-negative.',
        if (maxStates < 0) 'maxStates must be non-negative.',
        if (maxTransitions < 0) 'maxTransitions must be non-negative.',
        if (maxProductions < 0) 'maxProductions must be non-negative.',
        if (maxRegexNodes <= 0) 'maxRegexNodes must be positive.',
        if (maxTapeCells < 0) 'maxTapeCells must be non-negative.',
        if (maxStackDepth < 0) 'maxStackDepth must be non-negative.',
        if (maxIterations < 0) 'maxIterations must be non-negative.',
      ];

  Map<String, Object?> toJson() => {
        'maxIterations': maxIterations,
        'maxProductions': maxProductions,
        'maxRegexNodes': maxRegexNodes,
        'maxStackDepth': maxStackDepth,
        'maxStates': maxStates,
        'maxSymbols': maxSymbols,
        'maxTapeCells': maxTapeCells,
        'maxTransitions': maxTransitions,
        'maxWordLength': maxWordLength,
      };
}

final class GeneratedCase<T> {
  GeneratedCase({
    required this.family,
    this.property = 'generated-case',
    this.generatorVersion = '1',
    this.streamId = 'default',
    required this.seed,
    required this.caseIndex,
    required this.mode,
    required this.budget,
    required this.value,
    required this.encodeValue,
  }) {
    if (family.trim().isEmpty) {
      throw ArgumentError.value(family, 'family', 'must not be empty');
    }
    if (property.trim().isEmpty) {
      throw ArgumentError.value(property, 'property', 'must not be empty');
    }
    if (generatorVersion.trim().isEmpty) {
      throw ArgumentError.value(
        generatorVersion,
        'generatorVersion',
        'must not be empty',
      );
    }
    if (streamId.trim().isEmpty) {
      throw ArgumentError.value(streamId, 'streamId', 'must not be empty');
    }
    if (seed < 0 || seed > 0xffffffff) {
      throw RangeError.range(seed, 0, 0xffffffff, 'seed');
    }
    if (caseIndex < 0 || caseIndex > 0xffffffff) {
      throw RangeError.range(caseIndex, 0, 0xffffffff, 'caseIndex');
    }
  }

  final String family;
  final String property;
  final String generatorVersion;
  final String streamId;
  final int seed;
  final int caseIndex;
  final GenerationMode mode;
  final GenerationBudget budget;
  final T value;
  final Object? Function(T value) encodeValue;

  String get id => '$family-${seed.toRadixString(16).padLeft(8, '0')}-'
      '${caseIndex.toString().padLeft(6, '0')}';

  String get reproductionCommand =>
      'dart run tool/hard_edge_cases.dart run --family $family '
      '--property $property --seed $seed';

  Map<String, Object?> toJson() => {
        'budget': budget.toJson(),
        'caseIndex': caseIndex,
        'family': family,
        'generatorVersion': generatorVersion,
        'id': id,
        'mode': mode.name,
        'prng': {
          'algorithm': stablePrngAlgorithm,
          'version': stablePrngVersion,
        },
        'property': property,
        'reproductionCommand': reproductionCommand,
        'seed': seed,
        'streamId': streamId,
        'value': encodeValue(value),
      };

  String toCanonicalJson() => canonicalJsonEncode(toJson());
}

String canonicalJsonEncode(Object? value) => jsonEncode(_canonicalize(value));

Object? _canonicalize(Object? value) {
  if (value is Map) {
    final entries = value.entries
        .map((entry) => MapEntry(entry.key.toString(), entry.value))
        .toList()
      ..sort((left, right) => left.key.compareTo(right.key));
    return <String, Object?>{
      for (final entry in entries) entry.key: _canonicalize(entry.value),
    };
  }
  if (value is Iterable) {
    return <Object?>[for (final item in value) _canonicalize(item)];
  }
  if (value == null || value is bool || value is num || value is String) {
    return value;
  }
  throw ArgumentError.value(value, 'value', 'is not JSON encodable');
}
