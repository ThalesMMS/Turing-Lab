import '../algorithms/equivalence_checker.dart';
import '../algorithms/regex_to_nfa_converter.dart';
import '../models/fsa.dart';
import '../models/fsa_transition.dart';

const String _emptySet = '∅';
const String _epsilon = 'ε';

/// Failure codes exposed by the pure FA-to-regex construction oracle.
enum FaToRegexManualErrorCode {
  invalidSource,
  unknownState,
  protectedState,
  staleInspection,
  missingPairLabel,
  unexpectedPairLabel,
  invalidPairLabel,
  incompleteConstruction,
}

/// A typed precondition or validation failure.
final class FaToRegexManualException implements Exception {
  const FaToRegexManualException(this.code, this.message);

  final FaToRegexManualErrorCode code;
  final String message;

  @override
  String toString() => 'FaToRegexManualException(${code.name}): $message';
}

/// One immutable state in the normalized generalized automaton.
final class FaToRegexGnfaState {
  const FaToRegexGnfaState({
    required this.id,
    required this.label,
    required this.sourceStateId,
    required this.isProtected,
  });

  final String id;
  final String label;
  final String? sourceStateId;
  final bool isProtected;
}

/// Stable key for one directed GNFA label.
final class FaToRegexStatePair implements Comparable<FaToRegexStatePair> {
  const FaToRegexStatePair(this.fromStateId, this.toStateId);

  final String fromStateId;
  final String toStateId;

  @override
  int compareTo(FaToRegexStatePair other) {
    final fromOrder = fromStateId.compareTo(other.fromStateId);
    return fromOrder != 0 ? fromOrder : toStateId.compareTo(other.toStateId);
  }

  @override
  bool operator ==(Object other) =>
      other is FaToRegexStatePair &&
      other.fromStateId == fromStateId &&
      other.toStateId == toStateId;

  @override
  int get hashCode => Object.hash(fromStateId, toStateId);

  @override
  String toString() => '$fromStateId→$toStateId';
}

/// Immutable normalized generalized automaton used by learner sessions.
final class FaToRegexGnfa {
  FaToRegexGnfa._({
    required this.id,
    required this.sourceDocumentId,
    required this.sourceRevision,
    required this.revision,
    required this.startStateId,
    required this.finalStateId,
    required Iterable<FaToRegexGnfaState> states,
    required Map<FaToRegexStatePair, String> labels,
    required Iterable<String> alphabet,
  })  : states = List<FaToRegexGnfaState>.unmodifiable(states),
        labels = Map<FaToRegexStatePair, String>.unmodifiable(labels),
        alphabet = Set<String>.unmodifiable(alphabet);

  final String id;
  final String sourceDocumentId;
  final String sourceRevision;
  final int revision;
  final String startStateId;
  final String finalStateId;
  final List<FaToRegexGnfaState> states;
  final Map<FaToRegexStatePair, String> labels;
  final Set<String> alphabet;

  List<String> get removableStateIds => List<String>.unmodifiable(
        states.where((state) => !state.isProtected).map((state) => state.id),
      );

  String expressionBetween(String fromStateId, String toStateId) =>
      labels[FaToRegexStatePair(fromStateId, toStateId)] ?? _emptySet;
}

/// Provenance for one R_ij update while eliminating state k.
final class FaToRegexPairFormula {
  const FaToRegexPairFormula({
    required this.id,
    required this.pair,
    required this.eliminatedStateId,
    required this.directExpression,
    required this.incomingExpression,
    required this.loopExpression,
    required this.outgoingExpression,
    required this.bypassExpression,
    required this.expectedExpression,
  });

  final String id;
  final FaToRegexStatePair pair;
  final String eliminatedStateId;
  final String directExpression;
  final String incomingExpression;
  final String loopExpression;
  final String outgoingExpression;
  final String bypassExpression;
  final String expectedExpression;
}

/// Read-only oracle output shown before a learner commits an elimination.
final class FaToRegexEliminationInspection {
  FaToRegexEliminationInspection._({
    required this.gnfaId,
    required this.gnfaRevision,
    required this.stateId,
    required Iterable<String> incomingStateIds,
    required Iterable<String> outgoingStateIds,
    required this.loopExpression,
    required Iterable<FaToRegexPairFormula> formulas,
  })  : incomingStateIds = List<String>.unmodifiable(incomingStateIds),
        outgoingStateIds = List<String>.unmodifiable(outgoingStateIds),
        formulas = List<FaToRegexPairFormula>.unmodifiable(formulas);

  final String gnfaId;
  final int gnfaRevision;
  final String stateId;
  final List<String> incomingStateIds;
  final List<String> outgoingStateIds;
  final String loopExpression;
  final List<FaToRegexPairFormula> formulas;

  Map<FaToRegexStatePair, FaToRegexPairFormula> get formulasByPair =>
      Map<FaToRegexStatePair, FaToRegexPairFormula>.unmodifiable({
        for (final formula in formulas) formula.pair: formula,
      });
}

/// Exact-language validation of a learner-supplied pair label.
final class FaToRegexPairValidation {
  const FaToRegexPairValidation({
    required this.formula,
    required this.learnerExpression,
    required this.isValid,
    required this.isExactTextMatch,
    this.message,
  });

  final FaToRegexPairFormula formula;
  final String learnerExpression;
  final bool isValid;
  final bool isExactTextMatch;
  final String? message;
}

/// Stateless, deterministic oracle for manual GNFA state elimination.
final class FaToRegexManualOracle {
  const FaToRegexManualOracle._();

  /// Clones [source] into a GNFA with fresh protected start and final states.
  static FaToRegexGnfa normalize(FSA source) {
    _validateSource(source);

    final originalStates = source.states.toList()
      ..sort((left, right) => left.id.compareTo(right.id));
    final usedIds = originalStates.map((state) => state.id).toSet();
    final startId = _uniqueId(usedIds, '__gnfa_start__');
    usedIds.add(startId);
    final finalId = _uniqueId(usedIds, '__gnfa_final__');

    final states = <FaToRegexGnfaState>[
      FaToRegexGnfaState(
        id: startId,
        label: 'GNFA start',
        sourceStateId: null,
        isProtected: true,
      ),
      for (final state in originalStates)
        FaToRegexGnfaState(
          id: state.id,
          label: state.label,
          sourceStateId: state.id,
          isProtected: false,
        ),
      FaToRegexGnfaState(
        id: finalId,
        label: 'GNFA final',
        sourceStateId: null,
        isProtected: true,
      ),
    ];

    final grouped = <FaToRegexStatePair, List<String>>{};
    final transitions = source.fsaTransitions.toList()
      ..sort((left, right) {
        final leftKey = _transitionSortKey(left);
        final rightKey = _transitionSortKey(right);
        return leftKey.compareTo(rightKey);
      });
    for (final transition in transitions) {
      final pair = FaToRegexStatePair(
        transition.fromState.id,
        transition.toState.id,
      );
      grouped.putIfAbsent(pair, () => <String>[]).addAll(
            _sourceTransitionExpressions(transition),
          );
    }

    final initialStateId = source.initialState!.id;
    grouped
        .putIfAbsent(
          FaToRegexStatePair(startId, initialStateId),
          () => <String>[],
        )
        .add(_epsilon);
    final acceptingIds =
        source.acceptingStates.map((state) => state.id).toList()..sort();
    for (final acceptingId in acceptingIds) {
      grouped
          .putIfAbsent(
            FaToRegexStatePair(acceptingId, finalId),
            () => <String>[],
          )
          .add(_epsilon);
    }

    final sortedPairs = grouped.keys.toList()..sort();
    final labels = <FaToRegexStatePair, String>{};
    for (final pair in sortedPairs) {
      final expression = _union(grouped[pair]!);
      if (expression != _emptySet) labels[pair] = expression;
    }

    return FaToRegexGnfa._(
      id: '${source.id}::fa-to-regex-gnfa',
      sourceDocumentId: source.id,
      sourceRevision: _sourceRevision(source),
      revision: 0,
      startStateId: startId,
      finalStateId: finalId,
      states: states,
      labels: labels,
      alphabet: source.alphabet,
    );
  }

  /// Computes every affected R_ij label for eliminating [stateId].
  static FaToRegexEliminationInspection inspectElimination(
    FaToRegexGnfa gnfa,
    String stateId,
  ) {
    final state = _stateById(gnfa, stateId);
    if (state.isProtected) {
      throw FaToRegexManualException(
        FaToRegexManualErrorCode.protectedState,
        'State $stateId is a protected GNFA endpoint.',
      );
    }

    final remainingIds = gnfa.states
        .where((candidate) => candidate.id != stateId)
        .map((candidate) => candidate.id)
        .toList()
      ..sort();
    final incoming = remainingIds
        .where(
          (candidate) =>
              gnfa.expressionBetween(candidate, stateId) != _emptySet,
        )
        .toList(growable: false);
    final outgoing = remainingIds
        .where(
          (candidate) =>
              gnfa.expressionBetween(stateId, candidate) != _emptySet,
        )
        .toList(growable: false);
    final loop = gnfa.expressionBetween(stateId, stateId);
    final formulas = <FaToRegexPairFormula>[];

    for (final fromStateId in incoming) {
      for (final toStateId in outgoing) {
        final pair = FaToRegexStatePair(fromStateId, toStateId);
        final direct = gnfa.expressionBetween(fromStateId, toStateId);
        final incomingExpression = gnfa.expressionBetween(
          fromStateId,
          stateId,
        );
        final outgoingExpression = gnfa.expressionBetween(
          stateId,
          toStateId,
        );
        final bypass = _concatenate([
          incomingExpression,
          _star(loop),
          outgoingExpression,
        ]);
        formulas.add(
          FaToRegexPairFormula(
            id: _formulaId(gnfa.revision, stateId, pair),
            pair: pair,
            eliminatedStateId: stateId,
            directExpression: direct,
            incomingExpression: incomingExpression,
            loopExpression: loop,
            outgoingExpression: outgoingExpression,
            bypassExpression: bypass,
            expectedExpression: _union([direct, bypass]),
          ),
        );
      }
    }

    formulas.sort((left, right) => left.pair.compareTo(right.pair));
    return FaToRegexEliminationInspection._(
      gnfaId: gnfa.id,
      gnfaRevision: gnfa.revision,
      stateId: stateId,
      incomingStateIds: incoming,
      outgoingStateIds: outgoing,
      loopExpression: loop,
      formulas: formulas,
    );
  }

  /// Validates one submitted label against the canonical formula by language.
  static FaToRegexPairValidation validatePairLabel({
    required FaToRegexGnfa gnfa,
    required FaToRegexEliminationInspection inspection,
    required FaToRegexStatePair pair,
    required String learnerExpression,
  }) {
    _verifyInspection(gnfa, inspection);
    final formula = inspection.formulasByPair[pair];
    if (formula == null) {
      throw FaToRegexManualException(
        FaToRegexManualErrorCode.unexpectedPairLabel,
        'Pair $pair is not affected by this elimination.',
      );
    }

    final submitted = learnerExpression.trim();
    if (submitted.isEmpty) {
      return FaToRegexPairValidation(
        formula: formula,
        learnerExpression: submitted,
        isValid: false,
        isExactTextMatch: false,
        message: 'A resulting expression is required for pair $pair.',
      );
    }
    if (submitted == formula.expectedExpression) {
      return FaToRegexPairValidation(
        formula: formula,
        learnerExpression: submitted,
        isValid: true,
        isExactTextMatch: true,
      );
    }

    final expectedNfa = RegexToNFAConverter.convert(
      formula.expectedExpression,
      contextAlphabet: gnfa.alphabet,
    );
    final learnerNfa = RegexToNFAConverter.convert(
      submitted,
      contextAlphabet: gnfa.alphabet,
    );
    if (!expectedNfa.isSuccess || !learnerNfa.isSuccess) {
      return FaToRegexPairValidation(
        formula: formula,
        learnerExpression: submitted,
        isValid: false,
        isExactTextMatch: false,
        message: learnerNfa.error ?? expectedNfa.error,
      );
    }

    final sharedAlphabet = <String>{
      ...gnfa.alphabet,
      ...expectedNfa.data!.alphabet,
      ...learnerNfa.data!.alphabet,
    };
    final equivalence = EquivalenceChecker.areEquivalentResult(
      expectedNfa.data!.copyWith(alphabet: sharedAlphabet),
      learnerNfa.data!.copyWith(alphabet: sharedAlphabet),
    );
    return FaToRegexPairValidation(
      formula: formula,
      learnerExpression: submitted,
      isValid: equivalence.isSuccess && equivalence.data == true,
      isExactTextMatch: false,
      message: equivalence.isFailure
          ? equivalence.error
          : equivalence.data == true
              ? null
              : 'The submitted expression is not equivalent to the formula.',
    );
  }

  /// Applies a fully validated elimination and returns the next immutable GNFA.
  static FaToRegexGnfa applyElimination({
    required FaToRegexGnfa gnfa,
    required FaToRegexEliminationInspection inspection,
    required Map<FaToRegexStatePair, String> pairLabels,
  }) {
    _verifyInspection(gnfa, inspection);
    final expectedPairs =
        inspection.formulas.map((formula) => formula.pair).toSet();
    final missingPairs = expectedPairs.difference(pairLabels.keys.toSet());
    if (missingPairs.isNotEmpty) {
      final sorted = missingPairs.toList()..sort();
      throw FaToRegexManualException(
        FaToRegexManualErrorCode.missingPairLabel,
        'Missing resulting label for ${sorted.first}.',
      );
    }
    final unexpectedPairs = pairLabels.keys.toSet().difference(expectedPairs);
    if (unexpectedPairs.isNotEmpty) {
      final sorted = unexpectedPairs.toList()..sort();
      throw FaToRegexManualException(
        FaToRegexManualErrorCode.unexpectedPairLabel,
        'Unexpected resulting label for ${sorted.first}.',
      );
    }

    for (final formula in inspection.formulas) {
      final validation = validatePairLabel(
        gnfa: gnfa,
        inspection: inspection,
        pair: formula.pair,
        learnerExpression: pairLabels[formula.pair]!,
      );
      if (!validation.isValid) {
        throw FaToRegexManualException(
          FaToRegexManualErrorCode.invalidPairLabel,
          validation.message ?? 'Invalid resulting label for ${formula.pair}.',
        );
      }
    }

    final labels = <FaToRegexStatePair, String>{};
    final retained = gnfa.labels.entries
        .where(
          (entry) =>
              entry.key.fromStateId != inspection.stateId &&
              entry.key.toStateId != inspection.stateId,
        )
        .toList()
      ..sort((left, right) => left.key.compareTo(right.key));
    for (final entry in retained) {
      labels[entry.key] = entry.value;
    }
    for (final formula in inspection.formulas) {
      if (formula.expectedExpression == _emptySet) {
        labels.remove(formula.pair);
      } else {
        labels[formula.pair] = formula.expectedExpression;
      }
    }
    final sortedEntries = labels.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));

    return FaToRegexGnfa._(
      id: gnfa.id,
      sourceDocumentId: gnfa.sourceDocumentId,
      sourceRevision: gnfa.sourceRevision,
      revision: gnfa.revision + 1,
      startStateId: gnfa.startStateId,
      finalStateId: gnfa.finalStateId,
      states: gnfa.states.where((state) => state.id != inspection.stateId),
      labels: {
        for (final entry in sortedEntries) entry.key: entry.value,
      },
      alphabet: gnfa.alphabet,
    );
  }

  /// Returns the final start-to-final label after every other state is removed.
  static String finalRegex(FaToRegexGnfa gnfa) {
    if (gnfa.states.length != 2 || gnfa.removableStateIds.isNotEmpty) {
      throw const FaToRegexManualException(
        FaToRegexManualErrorCode.incompleteConstruction,
        'Every non-protected state must be eliminated first.',
      );
    }
    return gnfa.expressionBetween(gnfa.startStateId, gnfa.finalStateId);
  }

  static void _verifyInspection(
    FaToRegexGnfa gnfa,
    FaToRegexEliminationInspection inspection,
  ) {
    if (inspection.gnfaId != gnfa.id ||
        inspection.gnfaRevision != gnfa.revision) {
      throw const FaToRegexManualException(
        FaToRegexManualErrorCode.staleInspection,
        'The elimination inspection belongs to another GNFA revision.',
      );
    }
    final state = _stateById(gnfa, inspection.stateId);
    if (state.isProtected) {
      throw FaToRegexManualException(
        FaToRegexManualErrorCode.protectedState,
        'State ${inspection.stateId} is a protected GNFA endpoint.',
      );
    }
  }

  static FaToRegexGnfaState _stateById(FaToRegexGnfa gnfa, String stateId) {
    for (final state in gnfa.states) {
      if (state.id == stateId) return state;
    }
    throw FaToRegexManualException(
      FaToRegexManualErrorCode.unknownState,
      'State $stateId does not exist in GNFA ${gnfa.id}.',
    );
  }

  static void _validateSource(FSA source) {
    final stateIds = source.states.map((state) => state.id).toSet();
    if (source.states.isEmpty ||
        source.initialState == null ||
        !stateIds.contains(source.initialState!.id)) {
      throw const FaToRegexManualException(
        FaToRegexManualErrorCode.invalidSource,
        'The source FSA must contain its initial state.',
      );
    }
    if (source.acceptingStates.any((state) => !stateIds.contains(state.id))) {
      throw const FaToRegexManualException(
        FaToRegexManualErrorCode.invalidSource,
        'Every accepting state must belong to the source FSA.',
      );
    }
    if (source.fsaTransitions.any(
      (transition) =>
          !stateIds.contains(transition.fromState.id) ||
          !stateIds.contains(transition.toState.id),
    )) {
      throw const FaToRegexManualException(
        FaToRegexManualErrorCode.invalidSource,
        'Every transition endpoint must belong to the source FSA.',
      );
    }
  }
}

String _uniqueId(Set<String> usedIds, String base) {
  if (!usedIds.contains(base)) return base;
  var suffix = 1;
  while (usedIds.contains('$base$suffix')) {
    suffix++;
  }
  return '$base$suffix';
}

String _transitionSortKey(FSATransition transition) {
  final symbols = transition.acceptedSymbols.toList()..sort();
  return '${transition.fromState.id}\u0000${transition.toState.id}'
      '\u0000${transition.id}\u0000${symbols.join('\u0001')}'
      '\u0000${transition.label}';
}

Iterable<String> _sourceTransitionExpressions(FSATransition transition) {
  final symbols = transition.acceptedSymbols.toList()..sort();
  if (symbols.isNotEmpty) {
    return symbols.map(
      (symbol) => symbol == _epsilon ? _epsilon : _escapeLiteral(symbol),
    );
  }
  final fallback = transition.label.trim();
  return [if (fallback.isEmpty) _emptySet else fallback];
}

String _escapeLiteral(String symbol) {
  final buffer = StringBuffer();
  for (final rune in symbol.runes) {
    final character = String.fromCharCode(rune);
    if (r'\.^$|?*+()[]{}'.contains(character)) buffer.write(r'\');
    buffer.write(character);
  }
  return buffer.toString();
}

String _union(Iterable<String> expressions) {
  final parts = <String>[];
  for (final expression in expressions) {
    final value = expression.trim();
    if (value.isEmpty || value == _emptySet || parts.contains(value)) continue;
    parts.add(value);
  }
  if (parts.isEmpty) return _emptySet;
  if (parts.length == 1) return parts.single;
  return '(${parts.join('|')})';
}

String _concatenate(Iterable<String> expressions) {
  final parts = expressions.map((expression) => expression.trim()).toList();
  if (parts.any((expression) => expression == _emptySet)) return _emptySet;
  final factors = parts
      .where((expression) => expression.isNotEmpty && expression != _epsilon)
      .toList(growable: false);
  return factors.isEmpty ? _epsilon : factors.join();
}

String _star(String expression) {
  final value = expression.trim();
  if (value.isEmpty || value == _emptySet || value == _epsilon) return _epsilon;
  return '($value)*';
}

String _formulaId(
  int revision,
  String eliminatedStateId,
  FaToRegexStatePair pair,
) {
  String segment(String value) => '${value.length}:$value';
  return 'r$revision:${segment(eliminatedStateId)}:'
      '${segment(pair.fromStateId)}:${segment(pair.toStateId)}';
}

String _sourceRevision(FSA source) {
  final states = source.states
      .map(
        (state) =>
            '${state.id}\u0001${state.label}\u0001${state.isInitial}\u0001${state.isAccepting}',
      )
      .toList()
    ..sort();
  final transitions = source.fsaTransitions.map(_transitionSortKey).toList()
    ..sort();
  final accepting = source.acceptingStates.map((state) => state.id).toList()
    ..sort();
  final alphabet = source.alphabet.toList()..sort();
  final canonical = <String>[
    source.id,
    source.initialState?.id ?? '',
    states.join('\u0002'),
    transitions.join('\u0002'),
    accepting.join('\u0001'),
    alphabet.join('\u0001'),
  ].join('\u0003');
  return '${source.id}@${_fnv1a32(canonical)}';
}

String _fnv1a32(String value) {
  var hash = 0x811c9dc5;
  for (final byte in value.codeUnits) {
    hash ^= byte;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}
