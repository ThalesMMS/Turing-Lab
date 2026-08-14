//
//  pumping_lemma_game.dart
//  Turing Lab
//
//  Estrutura de domínio que modela o minigame do lema do bombeamento,
//  relacionando autômatos finitos, tentativas do usuário, pontuação e estados
//  de progresso. Fornece fábricas para iniciar desafios, métodos para registrar
//  tentativas e utilidades que calculam métricas, status e igualdade profunda.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'fsa.dart';
import 'pumping_attempt.dart';
import 'dart:math' as math;
import 'package:collection/collection.dart';

/// Represents a pumping lemma game for educational purposes
class PumpingLemmaGame {
  final FSA automaton;
  final int pumpingLength;
  final String challengeString;
  final List<PumpingAttempt> attempts;
  final bool isCompleted;
  final int score;
  final int maxScore;

  const PumpingLemmaGame({
    required this.automaton,
    required this.pumpingLength,
    required this.challengeString,
    required this.attempts,
    required this.isCompleted,
    required this.score,
    required this.maxScore,
  });

  /// Creates a new pumping lemma game
  factory PumpingLemmaGame.create({
    required FSA automaton,
    required int pumpingLength,
    required String challengeString,
  }) {
    return PumpingLemmaGame(
      automaton: automaton,
      pumpingLength: pumpingLength,
      challengeString: challengeString,
      attempts: [],
      isCompleted: false,
      score: 0,
      maxScore: 100,
    );
  }

  /// Adds a new attempt to the game
  PumpingLemmaGame addAttempt(PumpingAttempt attempt) {
    final newAttempts = List<PumpingAttempt>.from(attempts)..add(attempt);
    final newScore = score + (attempt.isCorrect ? 10 : 0);
    final newIsCompleted = attempt.isCorrect || newAttempts.length >= 5;

    return PumpingLemmaGame(
      automaton: automaton,
      pumpingLength: pumpingLength,
      challengeString: challengeString,
      attempts: newAttempts,
      isCompleted: newIsCompleted,
      score: newScore,
      maxScore: maxScore,
    );
  }

  /// Gets the current attempt count
  int get attemptCount => attempts.length;

  /// Gets the remaining attempts
  int get remainingAttempts => math.max(0, 5 - attemptCount);

  /// Gets the score percentage
  double get scorePercentage => (score / maxScore) * 100;

  /// Checks if the game is over
  bool get isGameOver => isCompleted || remainingAttempts == 0;

  /// Gets the game status
  GameStatus get status {
    if (isCompleted) {
      return GameStatus.completed;
    } else if (remainingAttempts == 0) {
      return GameStatus.failed;
    } else {
      return GameStatus.inProgress;
    }
  }

  /// Gets the last attempt
  PumpingAttempt? get lastAttempt => attempts.isNotEmpty ? attempts.last : null;

  /// Gets the correct attempts
  List<PumpingAttempt> get correctAttempts =>
      attempts.where((a) => a.isCorrect).toList();

  /// Gets the incorrect attempts
  List<PumpingAttempt> get incorrectAttempts =>
      attempts.where((a) => !a.isCorrect).toList();

  /// Creates a copy with updated properties
  PumpingLemmaGame copyWith({
    FSA? automaton,
    int? pumpingLength,
    String? challengeString,
    List<PumpingAttempt>? attempts,
    bool? isCompleted,
    int? score,
    int? maxScore,
  }) {
    return PumpingLemmaGame(
      automaton: automaton ?? this.automaton,
      pumpingLength: pumpingLength ?? this.pumpingLength,
      challengeString: challengeString ?? this.challengeString,
      attempts: attempts ?? this.attempts,
      isCompleted: isCompleted ?? this.isCompleted,
      score: score ?? this.score,
      maxScore: maxScore ?? this.maxScore,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PumpingLemmaGame &&
        other.automaton == automaton &&
        other.pumpingLength == pumpingLength &&
        other.challengeString == challengeString &&
        const ListEquality().equals(other.attempts, attempts) &&
        other.isCompleted == isCompleted &&
        other.score == score &&
        other.maxScore == maxScore;
  }

  @override
  int get hashCode {
    return Object.hash(
      automaton,
      pumpingLength,
      challengeString,
      const ListEquality().hash(attempts),
      isCompleted,
      score,
      maxScore,
    );
  }

  @override
  String toString() {
    return 'PumpingLemmaGame(pumpingLength: $pumpingLength, challengeString: $challengeString, attempts: ${attempts.length}, score: $score/$maxScore, completed: $isCompleted)';
  }
}

/// Status of a pumping lemma game
enum GameStatus { inProgress, completed, failed }

/// Extension on GameStatus for better usability
extension GameStatusExtension on GameStatus {
  String get displayName {
    switch (this) {
      case GameStatus.inProgress:
        return 'In Progress';
      case GameStatus.completed:
        return 'Completed';
      case GameStatus.failed:
        return 'Failed';
    }
  }

  bool get isFinished =>
      this == GameStatus.completed || this == GameStatus.failed;
}
