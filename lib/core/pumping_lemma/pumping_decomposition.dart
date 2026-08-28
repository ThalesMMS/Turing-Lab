import 'package:collection/collection.dart';

import 'pumping_lemma_messages.dart';

enum PumpingLemmaTheorem { regular, contextFree }

enum PumpingDecompositionViolation {
  emptyPumpedSection,
  windowExceedsPumpingLength,
}

const defaultMaximumPumpedTokens = 1000000;

sealed class PumpingWordOutcome {
  const PumpingWordOutcome();
}

final class PumpingWordCompleted extends PumpingWordOutcome {
  PumpingWordCompleted(List<String> tokens)
    : tokens = List<String>.unmodifiable(tokens);

  final List<String> tokens;
}

final class PumpingWordBounded extends PumpingWordOutcome {
  const PumpingWordBounded({
    required this.maximumTokens,
    required this.minimumRequiredTokens,
  });

  final int maximumTokens;
  final int minimumRequiredTokens;
}

final class PumpingWordLimitException implements Exception {
  const PumpingWordLimitException(this.result);

  final PumpingWordBounded result;
}

final class PumpingSegment {
  PumpingSegment({
    required this.label,
    required this.start,
    required this.end,
    required this.pumped,
    required List<String> tokens,
  }) : tokens = List<String>.unmodifiable(tokens);

  final String label;
  final int start;
  final int end;
  final bool pumped;
  final List<String> tokens;

  Map<String, Object?> toJson() => {
    'label': label,
    'start': start,
    'end': end,
    'pumped': pumped,
    'tokens': tokens,
  };
}

sealed class PumpingDecomposition {
  PumpingDecomposition();

  PumpingLemmaTheorem get theorem;

  List<String> get word;

  List<PumpingSegment> get segments;

  List<String> pump(
    int exponent, {
    int maximumTokens = defaultMaximumPumpedTokens,
  });

  PumpingWordOutcome pumpBounded(
    int exponent, {
    int maximumTokens = defaultMaximumPumpedTokens,
  });

  List<PumpingDecompositionViolation> validate({required int pumpingLength});

  Map<String, Object?> toJson();

  static PumpingDecomposition fromJson(Map<String, Object?> json) {
    return switch (json['theorem']) {
      'regular' => RegularPumpingDecomposition.fromJson(json),
      'contextFree' => ContextFreePumpingDecomposition.fromJson(json),
      final value => throw FormatException(
        'Unsupported pumping decomposition theorem: $value',
      ),
    };
  }
}

final class RegularPumpingDecomposition extends PumpingDecomposition {
  RegularPumpingDecomposition({
    required List<String> x,
    required List<String> y,
    required List<String> z,
  }) : x = List<String>.unmodifiable(x),
       y = List<String>.unmodifiable(y),
       z = List<String>.unmodifiable(z);

  factory RegularPumpingDecomposition.fromJson(Map<String, Object?> json) {
    List<String> tokens(String field) => List<String>.unmodifiable(
      (json[field] as List<Object?>).cast<String>(),
    );

    return RegularPumpingDecomposition(
      x: tokens('x'),
      y: tokens('y'),
      z: tokens('z'),
    );
  }

  final List<String> x;
  final List<String> y;
  final List<String> z;

  @override
  PumpingLemmaTheorem get theorem => PumpingLemmaTheorem.regular;

  @override
  List<String> get word => List<String>.unmodifiable([...x, ...y, ...z]);

  @override
  List<PumpingSegment> get segments => List.unmodifiable([
    PumpingSegment(
      label: 'x',
      start: 0,
      end: x.length,
      pumped: false,
      tokens: x,
    ),
    PumpingSegment(
      label: 'y',
      start: x.length,
      end: x.length + y.length,
      pumped: true,
      tokens: y,
    ),
    PumpingSegment(
      label: 'z',
      start: x.length + y.length,
      end: word.length,
      pumped: false,
      tokens: z,
    ),
  ]);

  @override
  List<String> pump(
    int exponent, {
    int maximumTokens = defaultMaximumPumpedTokens,
  }) {
    final outcome = pumpBounded(exponent, maximumTokens: maximumTokens);
    if (outcome case PumpingWordBounded()) {
      throw PumpingWordLimitException(outcome);
    }
    return (outcome as PumpingWordCompleted).tokens;
  }

  @override
  PumpingWordOutcome pumpBounded(
    int exponent, {
    int maximumTokens = defaultMaximumPumpedTokens,
  }) {
    if (exponent < 0) {
      throw PumpingLemmaArgumentError.value(
        exponent,
        'exponent',
        PumpingLemmaMessages.exponentNonNegative(),
      );
    }
    final bounded = _boundedPumpedLength(
      fixedTokens: x.length + z.length,
      repeatedTokens: y.length,
      exponent: exponent,
      maximumTokens: maximumTokens,
    );
    if (bounded != null) return bounded;
    return PumpingWordCompleted([
      ...x,
      for (var index = 0; index < exponent; index++) ...y,
      ...z,
    ]);
  }

  @override
  List<PumpingDecompositionViolation> validate({required int pumpingLength}) {
    if (pumpingLength < 1) {
      throw PumpingLemmaArgumentError.value(
        pumpingLength,
        'pumpingLength',
        PumpingLemmaMessages.pumpingLengthPositive(),
      );
    }
    return List<PumpingDecompositionViolation>.unmodifiable([
      if (y.isEmpty) PumpingDecompositionViolation.emptyPumpedSection,
      if (x.length + y.length > pumpingLength)
        PumpingDecompositionViolation.windowExceedsPumpingLength,
    ]);
  }

  @override
  Map<String, Object?> toJson() => {
    'theorem': theorem.name,
    'x': x,
    'y': y,
    'z': z,
  };

  @override
  bool operator ==(Object other) =>
      other is RegularPumpingDecomposition &&
      const ListEquality<String>().equals(x, other.x) &&
      const ListEquality<String>().equals(y, other.y) &&
      const ListEquality<String>().equals(z, other.z);

  @override
  int get hashCode => Object.hash(
    const ListEquality<String>().hash(x),
    const ListEquality<String>().hash(y),
    const ListEquality<String>().hash(z),
  );
}

final class ContextFreePumpingDecomposition extends PumpingDecomposition {
  ContextFreePumpingDecomposition({
    required List<String> u,
    required List<String> v,
    required List<String> x,
    required List<String> y,
    required List<String> z,
  }) : u = List<String>.unmodifiable(u),
       v = List<String>.unmodifiable(v),
       x = List<String>.unmodifiable(x),
       y = List<String>.unmodifiable(y),
       z = List<String>.unmodifiable(z);

  factory ContextFreePumpingDecomposition.fromJson(Map<String, Object?> json) {
    List<String> tokens(String field) => List<String>.unmodifiable(
      (json[field] as List<Object?>).cast<String>(),
    );

    return ContextFreePumpingDecomposition(
      u: tokens('u'),
      v: tokens('v'),
      x: tokens('x'),
      y: tokens('y'),
      z: tokens('z'),
    );
  }

  final List<String> u;
  final List<String> v;
  final List<String> x;
  final List<String> y;
  final List<String> z;

  @override
  PumpingLemmaTheorem get theorem => PumpingLemmaTheorem.contextFree;

  @override
  List<String> get word =>
      List<String>.unmodifiable([...u, ...v, ...x, ...y, ...z]);

  @override
  List<PumpingSegment> get segments {
    final uEnd = u.length;
    final vEnd = uEnd + v.length;
    final xEnd = vEnd + x.length;
    final yEnd = xEnd + y.length;
    return List.unmodifiable([
      PumpingSegment(label: 'u', start: 0, end: uEnd, pumped: false, tokens: u),
      PumpingSegment(
        label: 'v',
        start: uEnd,
        end: vEnd,
        pumped: true,
        tokens: v,
      ),
      PumpingSegment(
        label: 'x',
        start: vEnd,
        end: xEnd,
        pumped: false,
        tokens: x,
      ),
      PumpingSegment(
        label: 'y',
        start: xEnd,
        end: yEnd,
        pumped: true,
        tokens: y,
      ),
      PumpingSegment(
        label: 'z',
        start: yEnd,
        end: word.length,
        pumped: false,
        tokens: z,
      ),
    ]);
  }

  @override
  List<String> pump(
    int exponent, {
    int maximumTokens = defaultMaximumPumpedTokens,
  }) {
    final outcome = pumpBounded(exponent, maximumTokens: maximumTokens);
    if (outcome case PumpingWordBounded()) {
      throw PumpingWordLimitException(outcome);
    }
    return (outcome as PumpingWordCompleted).tokens;
  }

  @override
  PumpingWordOutcome pumpBounded(
    int exponent, {
    int maximumTokens = defaultMaximumPumpedTokens,
  }) {
    if (exponent < 0) {
      throw PumpingLemmaArgumentError.value(
        exponent,
        'exponent',
        PumpingLemmaMessages.exponentNonNegative(),
      );
    }
    final bounded = _boundedPumpedLength(
      fixedTokens: u.length + x.length + z.length,
      repeatedTokens: v.length + y.length,
      exponent: exponent,
      maximumTokens: maximumTokens,
    );
    if (bounded != null) return bounded;
    return PumpingWordCompleted([
      ...u,
      for (var index = 0; index < exponent; index++) ...v,
      ...x,
      for (var index = 0; index < exponent; index++) ...y,
      ...z,
    ]);
  }

  @override
  List<PumpingDecompositionViolation> validate({required int pumpingLength}) {
    if (pumpingLength < 1) {
      throw PumpingLemmaArgumentError.value(
        pumpingLength,
        'pumpingLength',
        PumpingLemmaMessages.pumpingLengthPositive(),
      );
    }
    return List<PumpingDecompositionViolation>.unmodifiable([
      if (v.isEmpty && y.isEmpty)
        PumpingDecompositionViolation.emptyPumpedSection,
      if (v.length + x.length + y.length > pumpingLength)
        PumpingDecompositionViolation.windowExceedsPumpingLength,
    ]);
  }

  @override
  Map<String, Object?> toJson() => {
    'theorem': theorem.name,
    'u': u,
    'v': v,
    'x': x,
    'y': y,
    'z': z,
  };

  @override
  bool operator ==(Object other) =>
      other is ContextFreePumpingDecomposition &&
      const ListEquality<String>().equals(u, other.u) &&
      const ListEquality<String>().equals(v, other.v) &&
      const ListEquality<String>().equals(x, other.x) &&
      const ListEquality<String>().equals(y, other.y) &&
      const ListEquality<String>().equals(z, other.z);

  @override
  int get hashCode => Object.hash(
    const ListEquality<String>().hash(u),
    const ListEquality<String>().hash(v),
    const ListEquality<String>().hash(x),
    const ListEquality<String>().hash(y),
    const ListEquality<String>().hash(z),
  );
}

PumpingWordBounded? _boundedPumpedLength({
  required int fixedTokens,
  required int repeatedTokens,
  required int exponent,
  required int maximumTokens,
}) {
  if (maximumTokens < 0) {
    throw PumpingLemmaArgumentError.value(
      maximumTokens,
      'maximumTokens',
      PumpingLemmaMessages.maximumTokensNonNegative(),
    );
  }
  if (fixedTokens > maximumTokens ||
      repeatedTokens > 0 &&
          exponent > (maximumTokens - fixedTokens) ~/ repeatedTokens) {
    return PumpingWordBounded(
      maximumTokens: maximumTokens,
      minimumRequiredTokens: maximumTokens + 1,
    );
  }
  return null;
}
