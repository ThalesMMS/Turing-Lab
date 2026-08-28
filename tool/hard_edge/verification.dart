import 'dart:convert';

/// One unordered semantic fact. [tokens] remain an ordered vector, so
/// multi-character tokens cannot be confused with a concatenated string.
final class SemanticRecord {
  SemanticRecord({
    required this.kind,
    Iterable<String> tokens = const [],
    Map<String, Object?> attributes = const {},
  })  : tokens = List<String>.unmodifiable(tokens),
        attributes = Map<String, Object?>.unmodifiable(attributes) {
    if (kind.isEmpty) throw ArgumentError('Record kind must not be empty.');
    if (this.tokens.any((token) => token.isEmpty)) {
      throw ArgumentError('Semantic tokens must not be empty.');
    }
  }

  final String kind;
  final List<String> tokens;
  final Map<String, Object?> attributes;

  Object? toCanonicalValue() => _canonicalize({
        'attributes': attributes,
        'kind': kind,
        'tokens': tokens,
      });
}

/// Canonicalizes only semantics supplied by [recordsOf]. IDs are deliberately
/// absent from this API; callers must map references to semantic records first.
final class SemanticCanonicalizer<T> {
  const SemanticCanonicalizer({required this.recordsOf});

  final Iterable<SemanticRecord> Function(T value) recordsOf;

  String canonicalize(T value) {
    final records = recordsOf(value)
        .map((record) => jsonEncode(record.toCanonicalValue()))
        .toList()
      ..sort();
    return jsonEncode(records);
  }

  bool equivalent(T left, T right) => canonicalize(left) == canonicalize(right);
}

Object? _canonicalize(Object? value) {
  if (value is Map) {
    final keys = value.keys.map((key) => key.toString()).toList()..sort();
    return <String, Object?>{
      for (final key in keys) key: _canonicalize(value[key]),
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

sealed class PropertyObservation {
  const PropertyObservation();
}

final class PropertySatisfied extends PropertyObservation {
  const PropertySatisfied();
}

final class PropertyViolated extends PropertyObservation {
  const PropertyViolated(this.message);

  final String message;
}

final class PropertyInconclusive extends PropertyObservation {
  const PropertyInconclusive(this.message);

  final String message;
}

final class MetamorphicVerification<T> {
  const MetamorphicVerification({
    required this.original,
    required this.transformed,
    required this.observation,
  });

  final T original;
  final T transformed;
  final PropertyObservation observation;
}

final class MetamorphicProperty<T> {
  const MetamorphicProperty({
    required this.name,
    required this.transform,
    required this.relation,
  });

  final String name;
  final T Function(T value) transform;
  final PropertyObservation Function(T original, T transformed) relation;

  MetamorphicVerification<T> verify(T value) {
    final transformed = transform(value);
    return MetamorphicVerification(
      original: value,
      transformed: transformed,
      observation: relation(value, transformed),
    );
  }

  factory MetamorphicProperty.semanticPreservation({
    required String name,
    required T Function(T value) transform,
    required SemanticCanonicalizer<T> canonicalizer,
  }) =>
      MetamorphicProperty(
        name: name,
        transform: transform,
        relation: (original, transformed) =>
            canonicalizer.equivalent(original, transformed)
                ? const PropertySatisfied()
                : PropertyViolated('$name changed semantics.'),
      );

  factory MetamorphicProperty.idempotent({
    required String name,
    required T Function(T value) transform,
    required bool Function(T left, T right) equivalent,
  }) =>
      MetamorphicProperty(
        name: name,
        transform: transform,
        relation: (_, transformed) {
          final twice = transform(transformed);
          return equivalent(transformed, twice)
              ? const PropertySatisfied()
              : PropertyViolated('$name is not idempotent.');
        },
      );
}

final class RecordedTraceStep<S, A> {
  const RecordedTraceStep({
    required this.before,
    required this.action,
    required this.after,
  });

  final S before;
  final A action;
  final S after;
}

sealed class ReplayApplication<S> {
  const ReplayApplication();
}

final class ReplayApplied<S> extends ReplayApplication<S> {
  const ReplayApplied(this.state);

  final S state;
}

final class ReplayRejected<S> extends ReplayApplication<S> {
  const ReplayRejected(this.reason);

  final String reason;
}

enum TraceReplayFailureKind {
  beforeMismatch,
  invalidAction,
  afterMismatch,
  finalResultMismatch,
}

sealed class TraceReplayResult<S, R> {
  const TraceReplayResult();
}

final class TraceReplayPassed<S, R> extends TraceReplayResult<S, R> {
  const TraceReplayPassed({required this.finalState, required this.result});

  final S finalState;
  final R result;
}

final class TraceReplayFailed<S, R> extends TraceReplayResult<S, R> {
  const TraceReplayFailed({
    required this.kind,
    required this.stepIndex,
    required this.message,
  });

  final TraceReplayFailureKind kind;
  final int? stepIndex;
  final String message;
}

final class TraceReplayVerifier<S, A, R> {
  const TraceReplayVerifier({
    required this.apply,
    required this.statesEquivalent,
    required this.resultFromState,
    required this.resultsEquivalent,
  });

  final ReplayApplication<S> Function(S state, A action) apply;
  final bool Function(S left, S right) statesEquivalent;
  final R Function(S finalState) resultFromState;
  final bool Function(R left, R right) resultsEquivalent;

  TraceReplayResult<S, R> verify({
    required S initialState,
    required Iterable<RecordedTraceStep<S, A>> steps,
    required R reportedResult,
  }) {
    var current = initialState;
    var index = 0;
    for (final step in steps) {
      if (!statesEquivalent(current, step.before)) {
        return TraceReplayFailed(
          kind: TraceReplayFailureKind.beforeMismatch,
          stepIndex: index,
          message: 'Trace step $index does not start at the replayed state.',
        );
      }
      final application = apply(current, step.action);
      if (application case ReplayRejected<S>(reason: final reason)) {
        return TraceReplayFailed(
          kind: TraceReplayFailureKind.invalidAction,
          stepIndex: index,
          message: reason,
        );
      }
      final actual = (application as ReplayApplied<S>).state;
      if (!statesEquivalent(actual, step.after)) {
        return TraceReplayFailed(
          kind: TraceReplayFailureKind.afterMismatch,
          stepIndex: index,
          message: 'Trace step $index records the wrong successor state.',
        );
      }
      current = actual;
      index++;
    }
    final replayedResult = resultFromState(current);
    if (!resultsEquivalent(replayedResult, reportedResult)) {
      return const TraceReplayFailed(
        kind: TraceReplayFailureKind.finalResultMismatch,
        stepIndex: null,
        message: 'Reported result does not match the replayed final state.',
      );
    }
    return TraceReplayPassed(finalState: current, result: replayedResult);
  }
}
