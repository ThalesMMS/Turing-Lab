//
//  pumping_lemma_progress_provider.dart
//  Turing Lab
//
//  Holds immutable Pumping Lemma game state, recording available
//  challenges, attempts, score, and a chronological history of user
//  interactions to feed pedagogical panels and statistics.
//  Exposes a StateNotifier with event factories and operations to start,
//  restart, and track challenges so widgets can sync consistent metrics
//  without talking to external sources directly.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/pumping_lemma/pumping_lemma.dart';

/// Describes the type of a progress history entry for the Pumping Lemma game.
enum PumpingLemmaHistoryType { attempt, retry }

/// Immutable history entry capturing interactions within the Pumping Lemma game.
@immutable
class PumpingLemmaHistoryEntry {
  const PumpingLemmaHistoryEntry._({
    required this.type,
    this.challengeId,
    this.challengeContentId,
    this.language,
    this.isCorrect,
    required this.timestamp,
  });

  /// Creates a history entry for an answered challenge.
  factory PumpingLemmaHistoryEntry.attempt({
    required int challengeId,
    required String challengeContentId,
    required String language,
    required bool isCorrect,
    DateTime? timestamp,
  }) {
    return PumpingLemmaHistoryEntry._(
      type: PumpingLemmaHistoryType.attempt,
      challengeId: challengeId,
      challengeContentId: challengeContentId,
      language: language,
      isCorrect: isCorrect,
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  /// Creates a history entry for a retry request on the current challenge.
  factory PumpingLemmaHistoryEntry.retry({
    required int challengeId,
    required String challengeContentId,
    required String language,
    DateTime? timestamp,
  }) {
    return PumpingLemmaHistoryEntry._(
      type: PumpingLemmaHistoryType.retry,
      challengeId: challengeId,
      challengeContentId: challengeContentId,
      language: language,
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  /// The interaction type that produced this entry.
  final PumpingLemmaHistoryType type;

  /// Identifier of the related challenge when available.
  final int? challengeId;

  /// Locale-neutral educational-content identifier for the challenge.
  final String? challengeContentId;

  /// Formal language description for the challenge when available.
  final String? language;

  /// Outcome of the attempt when [type] is [PumpingLemmaHistoryType.attempt].
  final bool? isCorrect;

  /// Timestamp describing when the entry was produced.
  final DateTime timestamp;
}

/// Aggregated state describing the Pumping Lemma game progress.
@immutable
class PumpingLemmaProgressState {
  const PumpingLemmaProgressState({
    this.theorem = PumpingLemmaTheorem.regular,
    this.totalChallenges = 0,
    this.completedChallengeIds = const <String>{},
    this.challengeScores = const <String, int>{},
    this.challengeContentVersions = const <String, int>{},
    this.score = 0,
    this.attempts = 0,
    this.history = const <PumpingLemmaHistoryEntry>[],
  });

  /// The theorem environment that owns this progress.
  final PumpingLemmaTheorem theorem;

  /// Total number of challenges available in the game.
  final int totalChallenges;

  /// Set of completed challenge identifiers.
  final Set<String> completedChallengeIds;

  /// Scores keyed by stable educational-content identifier.
  final Map<String, int> challengeScores;

  /// Educational-content versions keyed by stable challenge identifier.
  final Map<String, int> challengeContentVersions;

  /// Number of correctly solved challenges.
  final int score;

  /// Total number of submitted answers.
  final int attempts;

  /// Chronological log of relevant player interactions.
  final List<PumpingLemmaHistoryEntry> history;

  /// Count of completed challenges derived from [completedChallengeIds].
  int get completedChallenges => completedChallengeIds.length;

  /// Creates a new state object with updated fields.
  PumpingLemmaProgressState copyWith({
    PumpingLemmaTheorem? theorem,
    int? totalChallenges,
    Set<String>? completedChallengeIds,
    Map<String, int>? challengeScores,
    Map<String, int>? challengeContentVersions,
    int? score,
    int? attempts,
    List<PumpingLemmaHistoryEntry>? history,
  }) {
    return PumpingLemmaProgressState(
      theorem: theorem ?? this.theorem,
      totalChallenges: totalChallenges ?? this.totalChallenges,
      completedChallengeIds:
          completedChallengeIds ?? this.completedChallengeIds,
      challengeScores: challengeScores ?? this.challengeScores,
      challengeContentVersions:
          challengeContentVersions ?? this.challengeContentVersions,
      score: score ?? this.score,
      attempts: attempts ?? this.attempts,
      history: history ?? this.history,
    );
  }
}

/// Manages the progress state for the Pumping Lemma game.
class PumpingLemmaProgressNotifier
    extends StateNotifier<PumpingLemmaProgressState> {
  PumpingLemmaProgressNotifier({
    PumpingLemmaTheorem theorem = PumpingLemmaTheorem.regular,
  }) : super(PumpingLemmaProgressState(theorem: theorem));

  /// Starts a fresh session with the provided total number of challenges.
  void startNewGame({required int totalChallenges}) {
    state = PumpingLemmaProgressState(
      theorem: state.theorem,
      totalChallenges: totalChallenges,
      completedChallengeIds: const <String>{},
      challengeScores: const <String, int>{},
      challengeContentVersions: const <String, int>{},
      score: 0,
      attempts: 0,
      history: const <PumpingLemmaHistoryEntry>[],
    );
  }

  /// Records the result of an answered challenge.
  void recordAnswer({
    required int challengeId,
    required String challengeContentId,
    required String language,
    required bool isCorrect,
    int challengeContentVersion = 1,
  }) {
    final updatedHistory = <PumpingLemmaHistoryEntry>[
      ...state.history,
      PumpingLemmaHistoryEntry.attempt(
        challengeId: challengeId,
        challengeContentId: challengeContentId,
        language: language,
        isCorrect: isCorrect,
      ),
    ];

    final updatedScores = isCorrect
        ? <String, int>{
            ...state.challengeScores,
            challengeContentId:
                (state.challengeScores[challengeContentId] ?? 0) + 1,
          }
        : state.challengeScores;
    state = state.copyWith(
      attempts: state.attempts + 1,
      score: isCorrect ? state.score + 1 : state.score,
      challengeScores: updatedScores,
      challengeContentVersions: isCorrect
          ? <String, int>{
              ...state.challengeContentVersions,
              challengeContentId: challengeContentVersion,
            }
          : state.challengeContentVersions,
      history: updatedHistory,
    );
  }

  /// Marks a challenge as completed if it has not been recorded already.
  void markChallengeCompleted(
    String challengeContentId, {
    int challengeContentVersion = 1,
  }) {
    if (state.completedChallengeIds.contains(challengeContentId)) {
      return;
    }

    final updatedCompleted = <String>{
      ...state.completedChallengeIds,
      challengeContentId,
    };
    state = state.copyWith(
      completedChallengeIds: updatedCompleted,
      challengeContentVersions: <String, int>{
        ...state.challengeContentVersions,
        challengeContentId: challengeContentVersion,
      },
    );
  }

  /// Restores persisted scores using stable educational-content identifiers.
  void restoreProgress({
    required int totalChallenges,
    required Map<String, int> challengeScores,
    required Set<String> completedChallengeIds,
    Map<String, int> challengeContentVersions = const <String, int>{},
  }) {
    state = PumpingLemmaProgressState(
      theorem: state.theorem,
      totalChallenges: totalChallenges,
      completedChallengeIds: completedChallengeIds,
      challengeScores: challengeScores,
      challengeContentVersions: challengeContentVersions,
      score: challengeScores.values.fold(0, (total, value) => total + value),
    );
  }

  /// Stores that the current challenge has been retried.
  void recordRetry({
    required int challengeId,
    required String challengeContentId,
    required String language,
  }) {
    final updatedHistory = <PumpingLemmaHistoryEntry>[
      ...state.history,
      PumpingLemmaHistoryEntry.retry(
        challengeId: challengeId,
        challengeContentId: challengeContentId,
        language: language,
      ),
    ];

    state = state.copyWith(history: updatedHistory);
  }

  /// Resets the game progress while preserving the total number of challenges.
  void restartGame() {
    final totalChallenges = state.totalChallenges;
    state = PumpingLemmaProgressState(
      theorem: state.theorem,
      totalChallenges: totalChallenges,
      completedChallengeIds: const <String>{},
      challengeScores: const <String, int>{},
      score: 0,
      attempts: 0,
      history: const <PumpingLemmaHistoryEntry>[],
    );
  }
}

/// Provider exposing the Pumping Lemma game progress state.
final regularPumpingLemmaProgressProvider =
    StateNotifierProvider<
      PumpingLemmaProgressNotifier,
      PumpingLemmaProgressState
    >((ref) => PumpingLemmaProgressNotifier());

final contextFreePumpingLemmaProgressProvider =
    StateNotifierProvider<
      PumpingLemmaProgressNotifier,
      PumpingLemmaProgressState
    >(
      (ref) => PumpingLemmaProgressNotifier(
        theorem: PumpingLemmaTheorem.contextFree,
      ),
    );

/// Compatibility alias for the legacy regular-language game route.
final pumpingLemmaProgressProvider = regularPumpingLemmaProgressProvider;
