import 'pumping_decomposition.dart';
import 'pumping_lemma_evidence.dart';
import 'pumping_lemma_session.dart';

final class StalePumpingLemmaSessionException implements Exception {
  const StalePumpingLemmaSessionException({
    required this.expectedSessionId,
    required this.actualSessionId,
  });

  final String expectedSessionId;
  final String actualSessionId;
}

enum PumpingLemmaTransitionViolation {
  wrongStage,
  wrongPlayer,
  invalidPumpingLength,
  witnessTooShort,
  witnessOutsideLanguage,
  decompositionMismatch,
  decompositionConstraint,
  invalidExponent,
}

final class PumpingLemmaTransitionException implements Exception {
  const PumpingLemmaTransitionException(this.violation);

  final PumpingLemmaTransitionViolation violation;
}

final class PumpingLemmaSessionController<
    TDecomposition extends PumpingDecomposition> {
  PumpingLemmaSessionController._({
    required PumpingLemmaSession<TDecomposition> initialSession,
    required String Function() sessionIdFactory,
  })  : state = initialSession,
        _sessionIdFactory = sessionIdFactory;

  factory PumpingLemmaSessionController.regular({
    required PumpingLemmaSession<TDecomposition> initialSession,
    required String Function() sessionIdFactory,
  }) {
    if (initialSession.theorem != PumpingLemmaTheorem.regular) {
      throw ArgumentError('A regular controller requires a regular session.');
    }
    return PumpingLemmaSessionController._(
      initialSession: initialSession,
      sessionIdFactory: sessionIdFactory,
    );
  }

  factory PumpingLemmaSessionController.contextFree({
    required PumpingLemmaSession<TDecomposition> initialSession,
    required String Function() sessionIdFactory,
  }) {
    if (initialSession.theorem != PumpingLemmaTheorem.contextFree) {
      throw ArgumentError(
        'A context-free controller requires a context-free session.',
      );
    }
    return PumpingLemmaSessionController._(
      initialSession: initialSession,
      sessionIdFactory: sessionIdFactory,
    );
  }

  final String Function() _sessionIdFactory;

  PumpingLemmaSession<TDecomposition> state;

  void choosePumpingLength({
    required String expectedSessionId,
    required PumpingLemmaPlayer player,
    required int pumpingLength,
  }) {
    _requireTurn(
      expectedSessionId: expectedSessionId,
      stage: PumpingLemmaStage.awaitingPumpingLength,
      player: player,
    );
    if (pumpingLength < 1) {
      throw const PumpingLemmaTransitionException(
        PumpingLemmaTransitionViolation.invalidPumpingLength,
      );
    }
    _replace(
      pumpingLength: pumpingLength,
      stage: PumpingLemmaStage.awaitingWitness,
      turn: PumpingLemmaTurnKind.pumpingLengthChosen,
      turnData: {'pumpingLength': pumpingLength},
    );
  }

  void chooseWitness({
    required String expectedSessionId,
    required PumpingLemmaPlayer player,
    required List<String> witness,
    required bool isInLanguage,
  }) {
    _requireTurn(
      expectedSessionId: expectedSessionId,
      stage: PumpingLemmaStage.awaitingWitness,
      player: player,
    );
    if (witness.length < state.pumpingLength!) {
      throw const PumpingLemmaTransitionException(
        PumpingLemmaTransitionViolation.witnessTooShort,
      );
    }
    if (!isInLanguage) {
      throw const PumpingLemmaTransitionException(
        PumpingLemmaTransitionViolation.witnessOutsideLanguage,
      );
    }
    _replace(
      witness: witness,
      stage: PumpingLemmaStage.awaitingDecomposition,
      turn: PumpingLemmaTurnKind.witnessChosen,
      turnData: {'witness': witness},
    );
  }

  void chooseDecomposition({
    required String expectedSessionId,
    required PumpingLemmaPlayer player,
    required TDecomposition decomposition,
  }) {
    _requireTurn(
      expectedSessionId: expectedSessionId,
      stage: PumpingLemmaStage.awaitingDecomposition,
      player: player,
    );
    if (decomposition.theorem != state.theorem ||
        !_sameTokens(decomposition.word, state.witness)) {
      throw const PumpingLemmaTransitionException(
        PumpingLemmaTransitionViolation.decompositionMismatch,
      );
    }
    if (decomposition
        .validate(pumpingLength: state.pumpingLength!)
        .isNotEmpty) {
      throw const PumpingLemmaTransitionException(
        PumpingLemmaTransitionViolation.decompositionConstraint,
      );
    }
    _replace(
      decomposition: decomposition,
      stage: PumpingLemmaStage.awaitingExponent,
      turn: PumpingLemmaTurnKind.decompositionChosen,
      turnData: {'decomposition': decomposition.toJson()},
    );
  }

  PumpingWordOutcome chooseExponent({
    required String expectedSessionId,
    required PumpingLemmaPlayer player,
    required int exponent,
  }) {
    _requireTurn(
      expectedSessionId: expectedSessionId,
      stage: PumpingLemmaStage.awaitingExponent,
      player: player,
    );
    if (exponent < 0) {
      throw const PumpingLemmaTransitionException(
        PumpingLemmaTransitionViolation.invalidExponent,
      );
    }
    final pumped = state.decomposition!.pumpBounded(exponent);
    if (pumped case PumpingWordBounded()) return pumped;
    final completed = pumped as PumpingWordCompleted;
    _replace(
      pumpExponent: exponent,
      stage: PumpingLemmaStage.awaitingEvidence,
      turn: PumpingLemmaTurnKind.exponentChosen,
      turnData: {
        'exponent': exponent,
        'pumpedWord': completed.tokens,
      },
    );
    return completed;
  }

  void recordEvidence({
    required String expectedSessionId,
    required PumpingLemmaPlayer player,
    required PumpingLemmaEvidence evidence,
  }) {
    _requireTurn(
      expectedSessionId: expectedSessionId,
      stage: PumpingLemmaStage.awaitingEvidence,
      player: player,
    );
    _replace(
      evidence: evidence,
      stage: PumpingLemmaStage.awaitingEvidence,
      turn: PumpingLemmaTurnKind.evidenceRecorded,
      turnData: {'evidence': evidence.toJson()},
    );
  }

  void complete({
    required String expectedSessionId,
    required int scoreDelta,
  }) {
    _requireCurrent(expectedSessionId);
    if (state.stage != PumpingLemmaStage.awaitingEvidence ||
        state.evidence == null) {
      throw const PumpingLemmaTransitionException(
        PumpingLemmaTransitionViolation.wrongStage,
      );
    }
    _replace(
      score: state.score + scoreDelta,
      outcome: PumpingLemmaSessionOutcome.completed,
      stage: PumpingLemmaStage.completed,
      turn: PumpingLemmaTurnKind.completed,
      turnData: {'scoreDelta': scoreDelta},
    );
  }

  void recordRetry({required String expectedSessionId}) {
    _requireCurrent(expectedSessionId);
    final nextRevision = state.revision + 1;
    state = PumpingLemmaSession<TDecomposition>(
      sessionId: state.sessionId,
      challengeId: state.challengeId,
      sourceRevision: state.sourceRevision,
      theorem: state.theorem,
      mode: state.mode,
      role: state.role,
      targetLanguage: state.targetLanguage,
      pumpingLength: state.pumpingLength,
      witness: state.witness,
      score: state.score,
      revision: nextRevision,
      stage: state.witness.isEmpty
          ? PumpingLemmaStage.awaitingWitness
          : PumpingLemmaStage.awaitingDecomposition,
      history: [
        ...state.history,
        PumpingLemmaTurn(
          kind: PumpingLemmaTurnKind.retry,
          revision: nextRevision,
          data: const {},
        ),
      ],
    );
  }

  void restart() {
    state = PumpingLemmaSession<TDecomposition>(
      sessionId: _sessionIdFactory(),
      challengeId: state.challengeId,
      sourceRevision: state.sourceRevision,
      theorem: state.theorem,
      mode: state.mode,
      role: state.role,
      targetLanguage: state.targetLanguage,
      score: 0,
    );
  }

  void _replace({
    int? pumpingLength,
    List<String>? witness,
    TDecomposition? decomposition,
    int? pumpExponent,
    PumpingLemmaEvidence? evidence,
    int? score,
    PumpingLemmaSessionOutcome? outcome,
    required PumpingLemmaStage stage,
    required PumpingLemmaTurnKind turn,
    required Map<String, Object?> turnData,
  }) {
    final nextRevision = state.revision + 1;
    state = PumpingLemmaSession<TDecomposition>(
      sessionId: state.sessionId,
      challengeId: state.challengeId,
      sourceRevision: state.sourceRevision,
      theorem: state.theorem,
      mode: state.mode,
      role: state.role,
      targetLanguage: state.targetLanguage,
      pumpingLength: pumpingLength ?? state.pumpingLength,
      witness: witness ?? state.witness,
      decomposition: decomposition ?? state.decomposition,
      pumpExponent: pumpExponent ?? state.pumpExponent,
      evidence: evidence ?? state.evidence,
      score: score ?? state.score,
      revision: nextRevision,
      outcome: outcome ?? state.outcome,
      stage: stage,
      history: [
        ...state.history,
        PumpingLemmaTurn(
          kind: turn,
          revision: nextRevision,
          data: turnData,
        ),
      ],
    );
  }

  void _requireTurn({
    required String expectedSessionId,
    required PumpingLemmaStage stage,
    required PumpingLemmaPlayer player,
  }) {
    _requireCurrent(expectedSessionId);
    if (state.stage != stage) {
      throw const PumpingLemmaTransitionException(
        PumpingLemmaTransitionViolation.wrongStage,
      );
    }
    if (state.currentPlayer != player) {
      throw const PumpingLemmaTransitionException(
        PumpingLemmaTransitionViolation.wrongPlayer,
      );
    }
  }

  void _requireCurrent(String expectedSessionId) {
    if (state.sessionId == expectedSessionId) return;
    throw StalePumpingLemmaSessionException(
      expectedSessionId: expectedSessionId,
      actualSessionId: state.sessionId,
    );
  }
}

bool _sameTokens(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
