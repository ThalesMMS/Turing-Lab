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

/// Describes the type of a progress history entry for the Pumping Lemma game.
enum PumpingLemmaHistoryType { attempt, retry }

/// Immutable history entry capturing interactions within the Pumping Lemma game.
@immutable
class PumpingLemmaHistoryEntry {
  const PumpingLemmaHistoryEntry._({
    required this.type,
    this.challengeId,
    this.challengeTitle,
    this.language,
    this.isCorrect,
    required this.timestamp,
  });

  /// Creates a history entry for an answered challenge.
  factory PumpingLemmaHistoryEntry.attempt({
    required int challengeId,
    required String challengeTitle,
    required String language,
    required bool isCorrect,
    DateTime? timestamp,
  }) {
    return PumpingLemmaHistoryEntry._(
      type: PumpingLemmaHistoryType.attempt,
      challengeId: challengeId,
      challengeTitle: challengeTitle,
      language: language,
      isCorrect: isCorrect,
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  /// Creates a history entry for a retry request on the current challenge.
  factory PumpingLemmaHistoryEntry.retry({
    required int challengeId,
    required String challengeTitle,
    required String language,
    DateTime? timestamp,
  }) {
    return PumpingLemmaHistoryEntry._(
      type: PumpingLemmaHistoryType.retry,
      challengeId: challengeId,
      challengeTitle: challengeTitle,
      language: language,
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  /// The interaction type that produced this entry.
  final PumpingLemmaHistoryType type;

  /// Identifier of the related challenge when available.
  final int? challengeId;

  /// Title of the related challenge when available.
  final String? challengeTitle;

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
    this.totalChallenges = 0,
    this.completedChallengeIds = const <int>{},
    this.score = 0,
    this.attempts = 0,
    this.history = const <PumpingLemmaHistoryEntry>[],
  });

  /// Total number of challenges available in the game.
  final int totalChallenges;

  /// Set of completed challenge identifiers.
  final Set<int> completedChallengeIds;

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
    int? totalChallenges,
    Set<int>? completedChallengeIds,
    int? score,
    int? attempts,
    List<PumpingLemmaHistoryEntry>? history,
  }) {
    return PumpingLemmaProgressState(
      totalChallenges: totalChallenges ?? this.totalChallenges,
      completedChallengeIds:
          completedChallengeIds ?? this.completedChallengeIds,
      score: score ?? this.score,
      attempts: attempts ?? this.attempts,
      history: history ?? this.history,
    );
  }
}

/// Manages the progress state for the Pumping Lemma game.
class PumpingLemmaProgressNotifier
    extends StateNotifier<PumpingLemmaProgressState> {
  PumpingLemmaProgressNotifier() : super(const PumpingLemmaProgressState());

  /// Starts a fresh session with the provided total number of challenges.
  void startNewGame({required int totalChallenges}) {
    state = PumpingLemmaProgressState(
      totalChallenges: totalChallenges,
      completedChallengeIds: const <int>{},
      score: 0,
      attempts: 0,
      history: const <PumpingLemmaHistoryEntry>[],
    );
  }

  /// Records the result of an answered challenge.
  void recordAnswer({
    required int challengeId,
    required String challengeTitle,
    required String language,
    required bool isCorrect,
  }) {
    final updatedHistory = <PumpingLemmaHistoryEntry>[
      ...state.history,
      PumpingLemmaHistoryEntry.attempt(
        challengeId: challengeId,
        challengeTitle: challengeTitle,
        language: language,
        isCorrect: isCorrect,
      ),
    ];

    state = state.copyWith(
      attempts: state.attempts + 1,
      score: isCorrect ? state.score + 1 : state.score,
      history: updatedHistory,
    );
  }

  /// Marks a challenge as completed if it has not been recorded already.
  void markChallengeCompleted(int challengeId) {
    if (state.completedChallengeIds.contains(challengeId)) {
      return;
    }

    final updatedCompleted = <int>{...state.completedChallengeIds, challengeId};
    state = state.copyWith(completedChallengeIds: updatedCompleted);
  }

  /// Stores that the current challenge has been retried.
  void recordRetry({
    required int challengeId,
    required String challengeTitle,
    required String language,
  }) {
    final updatedHistory = <PumpingLemmaHistoryEntry>[
      ...state.history,
      PumpingLemmaHistoryEntry.retry(
        challengeId: challengeId,
        challengeTitle: challengeTitle,
        language: language,
      ),
    ];

    state = state.copyWith(history: updatedHistory);
  }

  /// Resets the game progress while preserving the total number of challenges.
  void restartGame() {
    final totalChallenges = state.totalChallenges;
    state = PumpingLemmaProgressState(
      totalChallenges: totalChallenges,
      completedChallengeIds: const <int>{},
      score: 0,
      attempts: 0,
      history: const <PumpingLemmaHistoryEntry>[],
    );
  }
}

/// Provider exposing the Pumping Lemma game progress state.
final pumpingLemmaProgressProvider = StateNotifierProvider<
    PumpingLemmaProgressNotifier,
    PumpingLemmaProgressState>((ref) => PumpingLemmaProgressNotifier());
