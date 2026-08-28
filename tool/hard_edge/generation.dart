import 'models.dart';

/// A xorshift32 generator with explicitly masked 32-bit arithmetic.
///
/// The algorithm and seed mixing are part of the fixture format. Do not replace
/// them with `dart:math.Random`, whose sequence is not a cross-runtime contract.
final class StableRandom {
  StableRandom(int seed) : _state = _normalizeSeed(seed);

  factory StableRandom.forCase(
    int seed,
    int caseIndex, {
    String streamId = 'default',
  }) {
    if (caseIndex < 0 || caseIndex > _uint32Mask) {
      throw RangeError.range(caseIndex, 0, _uint32Mask, 'caseIndex');
    }
    if (streamId.trim().isEmpty) {
      throw ArgumentError.value(streamId, 'streamId', 'must not be empty');
    }
    return StableRandom(
      _mix32(
        seed & _uint32Mask,
        caseIndex & _uint32Mask,
        streamId == 'default' ? 0 : _streamHash(streamId),
      ),
    );
  }

  static const int _uint32Mask = 0xffffffff;
  static const int _uint32Range = 0x100000000;
  static const int _zeroSeedReplacement = 0x6d2b79f5;

  int _state;

  int nextUint32() {
    var value = _state;
    value ^= (value << 13) & _uint32Mask;
    value ^= value >>> 17;
    value ^= (value << 5) & _uint32Mask;
    _state = value & _uint32Mask;
    return _state;
  }

  int nextInt(int upperBound) {
    if (upperBound <= 0 || upperBound > _uint32Range) {
      throw RangeError.range(upperBound, 1, _uint32Range, 'upperBound');
    }
    final acceptedRange = _uint32Range - (_uint32Range % upperBound);
    while (true) {
      final value = nextUint32();
      if (value < acceptedRange) return value % upperBound;
    }
  }

  bool nextBool() => (nextUint32() & 1) == 1;

  T choose<T>(List<T> values) {
    if (values.isEmpty) {
      throw ArgumentError('Cannot choose from an empty list.');
    }
    return values[nextInt(values.length)];
  }

  List<T> shuffled<T>(Iterable<T> values) {
    final result = values.toList();
    for (var index = result.length - 1; index > 0; index--) {
      final swapIndex = nextInt(index + 1);
      final value = result[index];
      result[index] = result[swapIndex];
      result[swapIndex] = value;
    }
    return result;
  }

  static int _normalizeSeed(int seed) {
    final normalized = seed & _uint32Mask;
    return normalized == 0 ? _zeroSeedReplacement : normalized;
  }

  static int _mix32(int seed, int caseIndex, int streamHash) {
    var value = (seed ^ 0x9e3779b9 ^ caseIndex ^ streamHash) & _uint32Mask;
    // Only shifts and XORs are used here. Multiplying two uint32 values can
    // exceed JavaScript's exact integer range and change low bits on Web.
    for (var round = 0; round < 3; round++) {
      value ^= (value << 13) & _uint32Mask;
      value ^= value >>> 17;
      value ^= (value << 5) & _uint32Mask;
      value &= _uint32Mask;
    }
    return value == 0 ? _zeroSeedReplacement : value;
  }

  static int _streamHash(String value) {
    var hash = 0x811c9dc5;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = ((hash << 5) | (hash >>> 27)) & _uint32Mask;
      hash ^= hash >>> 11;
      hash &= _uint32Mask;
    }
    return hash;
  }
}

final class GenerationContext {
  GenerationContext({
    required this.seed,
    required this.caseIndex,
    required this.mode,
    required this.budget,
    this.streamId = 'default',
  }) : random = StableRandom.forCase(
          seed,
          caseIndex,
          streamId: streamId,
        ) {
    if (seed < 0 || seed > 0xffffffff) {
      throw RangeError.range(seed, 0, 0xffffffff, 'seed');
    }
    if (caseIndex < 0 || caseIndex > 0xffffffff) {
      throw RangeError.range(caseIndex, 0, 0xffffffff, 'caseIndex');
    }
    final budgetIssues = budget.validate();
    if (budgetIssues.isNotEmpty) {
      throw ArgumentError.value(budget, 'budget', budgetIssues.join(' '));
    }
  }

  final int seed;
  final int caseIndex;
  final GenerationMode mode;
  final GenerationBudget budget;
  final String streamId;
  final StableRandom random;
  final Map<String, int> _idCounters = {};

  String nextId(String prefix) {
    final index =
        _idCounters.update(prefix, (value) => value + 1, ifAbsent: () => 0);
    return stableId(prefix, index);
  }

  int size({required int maximum, int minimum = 0}) {
    if (maximum < 0) {
      throw ArgumentError.value(maximum, 'maximum', 'must be non-negative');
    }
    final lower = minimum.clamp(0, maximum);
    if (mode == GenerationMode.boundaryValid) return maximum;
    if (lower == maximum) return maximum;
    return lower + random.nextInt(maximum - lower + 1);
  }
}

abstract interface class DomainGenerator<T> {
  T generate(GenerationContext context);
}

String stableId(String prefix, int index) {
  if (prefix.isEmpty) throw ArgumentError('ID prefix must be non-empty.');
  if (index < 0) {
    throw ArgumentError.value(index, 'index', 'must be non-negative');
  }
  return '$prefix-${index.toString().padLeft(6, '0')}';
}

GeneratedCase<T> generateCase<T>({
  required String family,
  String property = 'generated-case',
  String generatorVersion = '1',
  required int seed,
  required int caseIndex,
  required GenerationMode mode,
  required GenerationBudget budget,
  required DomainGenerator<T> generator,
  required Object? Function(T value) encodeValue,
}) {
  final streamId = '$family/$property/$generatorVersion';
  final context = GenerationContext(
    seed: seed,
    caseIndex: caseIndex,
    mode: mode,
    budget: budget,
    streamId: streamId,
  );
  return GeneratedCase<T>(
    family: family,
    property: property,
    generatorVersion: generatorVersion,
    streamId: streamId,
    seed: seed,
    caseIndex: caseIndex,
    mode: mode,
    budget: budget,
    value: generator.generate(context),
    encodeValue: encodeValue,
  );
}
