import 'resources.dart';

final class ExhaustiveOracleSample<T> {
  ExhaustiveOracleSample({
    required Iterable<String> word,
    required this.value,
  }) : word = List<String>.unmodifiable(word);

  final List<String> word;
  final T value;
}

final class ExhaustiveOracleEvidence {
  const ExhaustiveOracleEvidence({
    required this.evaluatedWords,
    required this.maximumWordLength,
    required this.alphabetSize,
  });

  final int evaluatedWords;
  final int maximumWordLength;
  final int alphabetSize;
}

/// Clarity-first exhaustive oracle for bounded token languages.
///
/// Words are enumerated breadth-first in the supplied alphabet order. Token
/// vectors are never flattened into strings. Reaching [maximumCases] while a
/// further word exists returns bounded unknown with the evaluated prefix.
OracleResult<List<ExhaustiveOracleSample<T>>, ExhaustiveOracleEvidence>
    evaluateTokenWords<T>({
  required Iterable<String> alphabet,
  required int maximumWordLength,
  required int maximumCases,
  required T Function(List<String> word) evaluate,
}) {
  final symbols = List<String>.unmodifiable(alphabet);
  if (symbols.any((symbol) => symbol.isEmpty)) {
    throw ArgumentError('Oracle alphabet tokens must not be empty.');
  }
  if (symbols.toSet().length != symbols.length) {
    throw ArgumentError('Oracle alphabet tokens must be unique.');
  }
  if (maximumWordLength < 0) {
    throw ArgumentError.value(
      maximumWordLength,
      'maximumWordLength',
      'must not be negative',
    );
  }
  if (maximumCases <= 0) {
    throw ArgumentError.value(
      maximumCases,
      'maximumCases',
      'must be positive',
    );
  }
  final iterator = _tokenWords(symbols, maximumWordLength).iterator;
  final samples = <ExhaustiveOracleSample<T>>[];
  while (iterator.moveNext()) {
    if (samples.length >= maximumCases) {
      final evidence = ExhaustiveOracleEvidence(
        evaluatedWords: samples.length,
        maximumWordLength: maximumWordLength,
        alphabetSize: symbols.length,
      );
      return OracleBoundedUnknown(
        limit: ResourceLimitEvidence(
          kind: ResourceLimitKind.frontier,
          observed: samples.length + 1,
          maximum: maximumCases,
          unit: 'words',
          partialEvidence: List<ExhaustiveOracleSample<T>>.unmodifiable(
            samples,
          ),
        ),
        evidence: evidence,
      );
    }
    final word = iterator.current;
    samples.add(ExhaustiveOracleSample(word: word, value: evaluate(word)));
  }
  return OracleDefinitive(
    value: List<ExhaustiveOracleSample<T>>.unmodifiable(samples),
    evidence: ExhaustiveOracleEvidence(
      evaluatedWords: samples.length,
      maximumWordLength: maximumWordLength,
      alphabetSize: symbols.length,
    ),
  );
}

Iterable<List<String>> _tokenWords(
  List<String> alphabet,
  int maximumWordLength,
) sync* {
  var frontier = <List<String>>[const []];
  for (var length = 0; length <= maximumWordLength; length++) {
    for (final word in frontier) {
      yield List<String>.unmodifiable(word);
    }
    if (length == maximumWordLength || alphabet.isEmpty) return;
    frontier = [
      for (final prefix in frontier)
        for (final symbol in alphabet) [...prefix, symbol],
    ];
  }
}

enum OracleInapplicability {
  unsupportedDomain,
  preconditionFailed,
  inputTooLarge,
  missingReference,
  platformUnsupported,
}

sealed class OracleResult<T, E extends Object> {
  const OracleResult();

  bool get isDefinitive => this is OracleDefinitive<T, E>;
}

final class OracleDefinitive<T, E extends Object> extends OracleResult<T, E> {
  const OracleDefinitive({required this.value, required this.evidence});

  final T value;
  final E evidence;
}

final class OracleNotApplicable<T, E extends Object>
    extends OracleResult<T, E> {
  const OracleNotApplicable({
    required this.reason,
    required this.evidence,
    this.message,
  });

  final OracleInapplicability reason;
  final E evidence;
  final String? message;
}

final class OracleBoundedUnknown<T, E extends Object>
    extends OracleResult<T, E> {
  const OracleBoundedUnknown({required this.limit, required this.evidence});

  final ResourceLimitEvidence limit;
  final E evidence;
}

enum DifferentialInconclusiveReason {
  leftNotApplicable,
  rightNotApplicable,
  bothNotApplicable,
  leftBounded,
  rightBounded,
  bothBounded,
  mixedNonDefinitive,
}

sealed class DifferentialComparison<T, E extends Object> {
  const DifferentialComparison({required this.left, required this.right});

  final OracleResult<T, E> left;
  final OracleResult<T, E> right;
}

final class DifferentialMatch<T, E extends Object>
    extends DifferentialComparison<T, E> {
  const DifferentialMatch({required super.left, required super.right});
}

final class DifferentialMismatch<T, E extends Object>
    extends DifferentialComparison<T, E> {
  const DifferentialMismatch({
    required super.left,
    required super.right,
    required this.leftValue,
    required this.rightValue,
  });

  final T leftValue;
  final T rightValue;
}

final class DifferentialInconclusive<T, E extends Object>
    extends DifferentialComparison<T, E> {
  const DifferentialInconclusive({
    required super.left,
    required super.right,
    required this.reason,
  });

  final DifferentialInconclusiveReason reason;
}

DifferentialComparison<T, E> compareOracleResults<T, E extends Object>(
  OracleResult<T, E> left,
  OracleResult<T, E> right, {
  required bool Function(T left, T right) equivalent,
}) {
  if (left case OracleDefinitive<T, E>(value: final leftValue)) {
    if (right case OracleDefinitive<T, E>(value: final rightValue)) {
      return equivalent(leftValue, rightValue)
          ? DifferentialMatch(left: left, right: right)
          : DifferentialMismatch(
              left: left,
              right: right,
              leftValue: leftValue,
              rightValue: rightValue,
            );
    }
  }
  return DifferentialInconclusive(
    left: left,
    right: right,
    reason: _inconclusiveReason(left, right),
  );
}

DifferentialInconclusiveReason _inconclusiveReason<T, E extends Object>(
  OracleResult<T, E> left,
  OracleResult<T, E> right,
) {
  final leftNotApplicable = left is OracleNotApplicable<T, E>;
  final rightNotApplicable = right is OracleNotApplicable<T, E>;
  final leftBounded = left is OracleBoundedUnknown<T, E>;
  final rightBounded = right is OracleBoundedUnknown<T, E>;
  if (leftNotApplicable && rightNotApplicable) {
    return DifferentialInconclusiveReason.bothNotApplicable;
  }
  if (leftBounded && rightBounded) {
    return DifferentialInconclusiveReason.bothBounded;
  }
  if (leftNotApplicable && right.isDefinitive) {
    return DifferentialInconclusiveReason.leftNotApplicable;
  }
  if (rightNotApplicable && left.isDefinitive) {
    return DifferentialInconclusiveReason.rightNotApplicable;
  }
  if (leftBounded && right.isDefinitive) {
    return DifferentialInconclusiveReason.leftBounded;
  }
  if (rightBounded && left.isDefinitive) {
    return DifferentialInconclusiveReason.rightBounded;
  }
  return DifferentialInconclusiveReason.mixedNonDefinitive;
}
