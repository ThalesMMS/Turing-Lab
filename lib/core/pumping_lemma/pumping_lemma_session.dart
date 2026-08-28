import 'package:collection/collection.dart';

import 'pumping_decomposition.dart';
import 'pumping_lemma_evidence.dart';
import 'pumping_lemma_messages.dart';

enum PumpingLemmaMode { challenge, guidedPractice, freeForm }

enum PumpingLemmaRole { learner, adversary }

enum PumpingLemmaPlayer { opponent, learner }

enum PumpingLemmaStage {
  awaitingPumpingLength,
  awaitingWitness,
  awaitingDecomposition,
  awaitingExponent,
  awaitingEvidence,
  completed,
}

enum PumpingLemmaSessionOutcome { inProgress, completed, invalid, cancelled }

enum PumpingLemmaTurnKind {
  pumpingLengthChosen,
  witnessChosen,
  decompositionChosen,
  exponentChosen,
  evidenceRecorded,
  completed,
  retry,
  restarted,
}

final class PumpingLemmaTurn {
  PumpingLemmaTurn({
    required this.kind,
    required this.revision,
    required Map<String, Object?> data,
  }) : data = Map<String, Object?>.unmodifiable(data);

  factory PumpingLemmaTurn.fromJson(Map<String, Object?> json) =>
      PumpingLemmaTurn(
        kind: PumpingLemmaTurnKind.values.byName(json['kind']! as String),
        revision: json['revision']! as int,
        data: Map<String, Object?>.from(json['data']! as Map),
      );

  final PumpingLemmaTurnKind kind;
  final int revision;
  final Map<String, Object?> data;

  Map<String, Object?> toJson() => {
    'kind': kind.name,
    'revision': revision,
    'data': data,
  };
}

final class PumpingLemmaSession<TDecomposition extends PumpingDecomposition> {
  PumpingLemmaSession({
    required this.sessionId,
    required this.challengeId,
    required this.sourceRevision,
    required this.theorem,
    required this.mode,
    required this.role,
    required this.targetLanguage,
    this.pumpingLength,
    List<String> witness = const [],
    this.decomposition,
    this.pumpExponent,
    this.evidence,
    List<PumpingLemmaTurn> history = const [],
    this.outcome = PumpingLemmaSessionOutcome.inProgress,
    this.score = 0,
    this.revision = 0,
    PumpingLemmaStage? stage,
  }) : witness = List<String>.unmodifiable(witness),
       history = List<PumpingLemmaTurn>.unmodifiable(history),
       stage =
           stage ??
           _deriveStage(
             pumpingLength: pumpingLength,
             witness: witness,
             decomposition: decomposition,
             pumpExponent: pumpExponent,
             evidence: evidence,
             outcome: outcome,
           ) {
    if (pumpingLength != null && pumpingLength! < 1) {
      throw PumpingLemmaArgumentError.value(
        pumpingLength,
        'pumpingLength',
        PumpingLemmaMessages.pumpingLengthPositive(),
      );
    }
    if (pumpingLength == null && this.witness.isNotEmpty) {
      throw PumpingLemmaArgumentError.message(
        PumpingLemmaMessages.witnessRequiresPumpingLength(),
      );
    }
    if (pumpingLength != null &&
        this.witness.isNotEmpty &&
        this.witness.length < pumpingLength!) {
      throw PumpingLemmaArgumentError.message(
        PumpingLemmaMessages.witnessMinimumTokens(pumpingLength!),
      );
    }
    if (decomposition != null && decomposition!.theorem != theorem) {
      throw PumpingLemmaArgumentError.message(
        PumpingLemmaMessages.decompositionTheoremMismatch(
          actual: decomposition!.theorem.name,
          expected: theorem.name,
        ),
      );
    }
    if (decomposition != null &&
        !const ListEquality<String>().equals(
          decomposition!.word,
          this.witness,
        )) {
      throw PumpingLemmaArgumentError.message(
        PumpingLemmaMessages.decompositionWitnessMismatch(),
      );
    }
    if (decomposition != null &&
        decomposition!.validate(pumpingLength: pumpingLength!).isNotEmpty) {
      throw PumpingLemmaArgumentError.message(
        PumpingLemmaMessages.decompositionConstraintViolation(),
      );
    }
    if (pumpExponent != null && pumpExponent! < 0) {
      throw PumpingLemmaArgumentError.value(
        pumpExponent,
        'pumpExponent',
        PumpingLemmaMessages.exponentNonNegative(),
      );
    }
  }

  factory PumpingLemmaSession.fromJson(Map<String, Object?> json) {
    final theorem = PumpingLemmaTheorem.values.byName(
      json['theorem']! as String,
    );
    final decompositionJson = json['decomposition'];
    final decomposition = decompositionJson == null
        ? null
        : PumpingDecomposition.fromJson(
                Map<String, Object?>.from(decompositionJson as Map),
              )
              as TDecomposition;
    var pumpExponent = json['pumpExponent'] as int?;
    var evidence = json['evidence'] == null
        ? null
        : PumpingLemmaEvidence.fromJson(
            Map<String, Object?>.from(json['evidence']! as Map),
          );
    var history = (json['history']! as List<Object?>)
        .map(
          (value) => PumpingLemmaTurn.fromJson(
            Map<String, Object?>.from(value! as Map),
          ),
        )
        .toList(growable: false);
    var outcome = PumpingLemmaSessionOutcome.values.byName(
      json['outcome']! as String,
    );
    var score = json['score']! as int;
    var stage = PumpingLemmaStage.values.byName(json['stage']! as String);
    if (decomposition != null &&
        pumpExponent != null &&
        decomposition.pumpBounded(pumpExponent) is PumpingWordBounded) {
      final exponentTurn = history.lastIndexWhere(
        (turn) => turn.kind == PumpingLemmaTurnKind.exponentChosen,
      );
      if (exponentTurn >= 0) {
        for (final turn in history.skip(exponentTurn)) {
          if (turn.kind == PumpingLemmaTurnKind.completed &&
              turn.data['scoreDelta'] is int) {
            score -= turn.data['scoreDelta']! as int;
          }
        }
        history = history.take(exponentTurn).toList(growable: false);
      }
      pumpExponent = null;
      evidence = null;
      outcome = PumpingLemmaSessionOutcome.inProgress;
      stage = PumpingLemmaStage.awaitingExponent;
    }
    return PumpingLemmaSession<TDecomposition>(
      sessionId: json['sessionId']! as String,
      challengeId: json['challengeId']! as String,
      sourceRevision: json['sourceRevision']! as String,
      theorem: theorem,
      mode: PumpingLemmaMode.values.byName(json['mode']! as String),
      role: PumpingLemmaRole.values.byName(json['role']! as String),
      targetLanguage: json['targetLanguage']! as String,
      pumpingLength: json['pumpingLength'] as int?,
      witness: (json['witness']! as List<Object?>).cast<String>(),
      decomposition: decomposition,
      pumpExponent: pumpExponent,
      evidence: evidence,
      history: history,
      outcome: outcome,
      score: score,
      revision: json['revision']! as int,
      stage: stage,
    );
  }

  final String sessionId;
  final String challengeId;
  final String sourceRevision;
  final PumpingLemmaTheorem theorem;
  final PumpingLemmaMode mode;
  final PumpingLemmaRole role;
  final String targetLanguage;
  final int? pumpingLength;
  final List<String> witness;
  final TDecomposition? decomposition;
  final int? pumpExponent;
  final PumpingLemmaEvidence? evidence;
  final List<PumpingLemmaTurn> history;
  final PumpingLemmaSessionOutcome outcome;
  final int score;
  final int revision;
  final PumpingLemmaStage stage;

  PumpingLemmaPlayer? get currentPlayer => switch (stage) {
    PumpingLemmaStage.awaitingPumpingLength => PumpingLemmaPlayer.opponent,
    PumpingLemmaStage.awaitingWitness => PumpingLemmaPlayer.learner,
    PumpingLemmaStage.awaitingDecomposition => PumpingLemmaPlayer.opponent,
    PumpingLemmaStage.awaitingExponent => PumpingLemmaPlayer.learner,
    PumpingLemmaStage.awaitingEvidence => PumpingLemmaPlayer.learner,
    PumpingLemmaStage.completed => null,
  };

  PumpingWordOutcome? get pumpedWordOutcome =>
      decomposition == null || pumpExponent == null
      ? null
      : decomposition!.pumpBounded(pumpExponent!);

  List<String>? get pumpedWord => switch (pumpedWordOutcome) {
    PumpingWordCompleted(:final tokens) => tokens,
    PumpingWordBounded() || null => null,
  };

  Map<String, Object?> toJson() => {
    'sessionId': sessionId,
    'challengeId': challengeId,
    'sourceRevision': sourceRevision,
    'theorem': theorem.name,
    'mode': mode.name,
    'role': role.name,
    'targetLanguage': targetLanguage,
    'pumpingLength': pumpingLength,
    'witness': witness,
    'decomposition': decomposition?.toJson(),
    'pumpExponent': pumpExponent,
    'evidence': evidence?.toJson(),
    'history': history.map((turn) => turn.toJson()).toList(),
    'outcome': outcome.name,
    'score': score,
    'revision': revision,
    'stage': stage.name,
  };
}

PumpingLemmaStage _deriveStage({
  required int? pumpingLength,
  required List<String> witness,
  required PumpingDecomposition? decomposition,
  required int? pumpExponent,
  required PumpingLemmaEvidence? evidence,
  required PumpingLemmaSessionOutcome outcome,
}) {
  if (outcome == PumpingLemmaSessionOutcome.completed) {
    return PumpingLemmaStage.completed;
  }
  if (pumpingLength == null) return PumpingLemmaStage.awaitingPumpingLength;
  if (witness.isEmpty) return PumpingLemmaStage.awaitingWitness;
  if (decomposition == null) {
    return PumpingLemmaStage.awaitingDecomposition;
  }
  if (pumpExponent == null) return PumpingLemmaStage.awaitingExponent;
  if (evidence == null) return PumpingLemmaStage.awaitingEvidence;
  return PumpingLemmaStage.awaitingEvidence;
}
