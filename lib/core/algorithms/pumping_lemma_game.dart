//
//  pumping_lemma_game.dart
//  Turing Lab
//
//  Implementa o jogo interativo do lema do bombeamento para linguagens
//  regulares, cuidando de validações, geração de desafios e acompanhamento de
//  tentativas dos usuários. Coordena cálculos de comprimento de bombeamento,
//  simulações de cadeias e pontuação para guiar a experiência educativa no
//  aplicativo.
//
//  Thales Matheus Mendonça Santos - October 2025
//

import '../models/fsa.dart';
import '../models/state.dart';
import '../models/pumping_lemma_game.dart' as models;
import '../models/pumping_attempt.dart';
import '../result.dart';
import 'dart:math' as math;

/// Implements the pumping lemma game for regular languages
class PumpingLemmaGame {
  /// Creates a new pumping lemma game
  static Result<models.PumpingLemmaGame> createGame(
    FSA automaton, {
    int maxPumpingLength = 100,
    Duration timeout = const Duration(seconds: 10),
  }) {
    try {
      final stopwatch = Stopwatch()..start();

      // Validate input
      final validationResult = _validateInput(automaton);
      if (!validationResult.isSuccess) {
        return Failure(validationResult.error!);
      }

      // Handle empty automaton
      if (automaton.states.isEmpty) {
        return const Failure('Cannot create game with empty automaton');
      }

      // Handle automaton with no initial state
      if (automaton.initialState == null) {
        return const Failure('Automaton must have an initial state');
      }

      // Create the game
      final result = _createGame(automaton, maxPumpingLength, timeout);
      stopwatch.stop();

      return Success(result);
    } catch (e) {
      return Failure('Error creating pumping lemma game: $e');
    }
  }

  /// Validates the input automaton
  static Result<void> _validateInput(FSA automaton) {
    if (automaton.states.isEmpty) {
      return const Failure('Automaton must have at least one state');
    }

    if (automaton.initialState == null) {
      return const Failure('Automaton must have an initial state');
    }

    if (!automaton.states.contains(automaton.initialState)) {
      return const Failure('Initial state must be in the states set');
    }

    for (final acceptingState in automaton.acceptingStates) {
      if (!automaton.states.contains(acceptingState)) {
        return const Failure('Accepting state must be in the states set');
      }
    }

    return const Success(null);
  }

  /// Creates the game
  static models.PumpingLemmaGame _createGame(
    FSA automaton,
    int maxPumpingLength,
    Duration timeout,
  ) {
    // Find the pumping length
    final pumpingLength = _findPumpingLength(
      automaton,
      maxPumpingLength,
      timeout,
    );

    // Generate a challenge string
    final challengeString = _generateChallengeString(
      automaton,
      pumpingLength,
      timeout,
    );

    // Create the game
    return models.PumpingLemmaGame(
      automaton: automaton,
      pumpingLength: pumpingLength,
      challengeString: challengeString,
      attempts: [],
      isCompleted: false,
      score: 0,
      maxScore: 100,
    );
  }

  /// Finds the pumping length for the automaton
  static int _findPumpingLength(
    FSA automaton,
    int maxPumpingLength,
    Duration timeout,
  ) {
    final startTime = DateTime.now();

    // The pumping length is at most the number of states
    final numStates = automaton.states.length;
    final pumpingLength =
        numStates < maxPumpingLength ? numStates : maxPumpingLength;

    // Check timeout
    if (DateTime.now().difference(startTime) > timeout) {
      return pumpingLength;
    }

    return pumpingLength;
  }

  /// Generates a challenge string for the game
  static String _generateChallengeString(
    FSA automaton,
    int pumpingLength,
    Duration timeout,
  ) {
    final startTime = DateTime.now();

    // Generate a string that can be pumped
    final alphabet = automaton.alphabet.toList();
    final random = math.Random();

    // Try to generate a string of length >= pumpingLength
    for (int attempt = 0; attempt < 100; attempt++) {
      if (DateTime.now().difference(startTime) > timeout) {
        break;
      }

      final length = pumpingLength + random.nextInt(10);
      var string = '';

      for (int i = 0; i < length; i++) {
        string += alphabet[random.nextInt(alphabet.length)];
      }

      // Check if string can be pumped
      if (_canStringBePumped(automaton, string, pumpingLength)) {
        return string;
      }
    }

    // Fallback: return a simple string
    return 'a' * pumpingLength;
  }

  /// Checks if a string can be pumped
  static bool _canStringBePumped(
    FSA automaton,
    String string,
    int pumpingLength,
  ) {
    // Check if string is accepted by automaton
    if (!_isStringAccepted(automaton, string)) {
      return false;
    }

    // Check if string length >= pumpingLength
    if (string.length < pumpingLength) {
      return false;
    }

    // Try all possible decompositions xyz where |xy| <= pumpingLength and |y| > 0
    for (int i = 0; i <= pumpingLength; i++) {
      for (int j = i + 1; j <= pumpingLength; j++) {
        if (j > string.length) break;

        final x = string.substring(0, i);
        final y = string.substring(i, j);
        final z = string.substring(j);

        // Check if y is not empty
        if (y.isEmpty) continue;

        // Check if xy^i z is accepted for all i >= 0
        bool canPump = true;
        for (int k = 0; k <= 3; k++) {
          // Test i = 0, 1, 2, 3
          final pumpedString = x + (y * k) + z;
          if (!_isStringAccepted(automaton, pumpedString)) {
            canPump = false;
            break;
          }
        }

        if (canPump) {
          return true;
        }
      }
    }

    return false;
  }

  /// Checks if a string is accepted by the automaton
  static bool _isStringAccepted(FSA automaton, String string) {
    var currentStates = {automaton.initialState!};

    for (int i = 0; i < string.length; i++) {
      final symbol = string[i];
      final nextStates = <State>{};

      for (final state in currentStates) {
        final transitions = automaton.getTransitionsFromStateOnSymbol(
          state,
          symbol,
        );
        for (final transition in transitions) {
          nextStates.add(transition.toState);
        }
      }

      currentStates = nextStates;

      if (currentStates.isEmpty) {
        return false;
      }
    }

    return currentStates.intersection(automaton.acceptingStates).isNotEmpty;
  }

  /// Validates a pumping attempt
  static Result<PumpingAttemptResult> validateAttempt(
    models.PumpingLemmaGame game,
    PumpingAttempt attempt, {
    Duration timeout = const Duration(seconds: 5),
  }) {
    try {
      final stopwatch = Stopwatch()..start();

      // Validate input
      final validationResult = _validateAttemptInput(game, attempt);
      if (!validationResult.isSuccess) {
        return Failure(validationResult.error!);
      }

      // Validate the attempt
      final result = _validateAttempt(game, attempt, timeout);
      stopwatch.stop();

      // Update execution time
      final finalResult = result.copyWith(executionTime: stopwatch.elapsed);

      return Success(finalResult);
    } catch (e) {
      return Failure('Error validating pumping attempt: $e');
    }
  }

  /// Validates the attempt input
  static Result<void> _validateAttemptInput(
    models.PumpingLemmaGame game,
    PumpingAttempt attempt,
  ) {
    if (attempt.x == null || attempt.y == null || attempt.z == null) {
      return const Failure('Attempt must have x, y, and z components');
    }

    if (attempt.y!.isEmpty) {
      return const Failure('y component cannot be empty');
    }

    if (attempt.x!.length + attempt.y!.length > game.pumpingLength) {
      return const Failure('|xy| must be <= pumping length');
    }

    return const Success(null);
  }

  /// Validates the attempt
  static PumpingAttemptResult _validateAttempt(
    models.PumpingLemmaGame game,
    PumpingAttempt attempt,
    Duration timeout,
  ) {
    final startTime = DateTime.now();

    // Check if the decomposition is correct
    final originalString = attempt.x! + attempt.y! + attempt.z!;
    if (originalString != game.challengeString) {
      return PumpingAttemptResult.failure(
        attempt: attempt,
        errorMessage: 'Decomposition does not match original string',
        executionTime: DateTime.now().difference(startTime),
      );
    }

    // Check if |xy| <= pumping length
    if (attempt.x!.length + attempt.y!.length > game.pumpingLength) {
      return PumpingAttemptResult.failure(
        attempt: attempt,
        errorMessage: '|xy| must be <= pumping length',
        executionTime: DateTime.now().difference(startTime),
      );
    }

    // Check if |y| > 0
    if (attempt.y!.isEmpty) {
      return PumpingAttemptResult.failure(
        attempt: attempt,
        errorMessage: 'y must be non-empty',
        executionTime: DateTime.now().difference(startTime),
      );
    }

    // Check if xy^i z is accepted for all i >= 0
    bool canPump = true;
    for (int i = 0; i <= 3; i++) {
      // Test i = 0, 1, 2, 3
      final pumpedString = attempt.x! + (attempt.y! * i) + attempt.z!;
      if (!_isStringAccepted(game.automaton, pumpedString)) {
        canPump = false;
        break;
      }
    }

    if (canPump) {
      return PumpingAttemptResult.success(
        attempt: attempt,
        executionTime: DateTime.now().difference(startTime),
      );
    } else {
      return PumpingAttemptResult.failure(
        attempt: attempt,
        errorMessage: 'String cannot be pumped',
        executionTime: DateTime.now().difference(startTime),
      );
    }
  }

  /// Updates the game with a new attempt
  static Result<models.PumpingLemmaGame> updateGame(
    models.PumpingLemmaGame game,
    PumpingAttempt attempt, {
    Duration timeout = const Duration(seconds: 5),
  }) {
    try {
      final stopwatch = Stopwatch()..start();

      // Validate the attempt
      final validationResult = validateAttempt(game, attempt, timeout: timeout);
      if (!validationResult.isSuccess) {
        return Failure(validationResult.error!);
      }

      final attemptResult = validationResult.data!;

      // Update the game
      final updatedAttempts = List<PumpingAttempt>.from(game.attempts)
        ..add(attempt);
      final updatedScore = game.score + (attemptResult.isSuccess ? 10 : 0);
      final isCompleted =
          attemptResult.isSuccess || updatedAttempts.length >= 5;

      final updatedGame = models.PumpingLemmaGame(
        automaton: game.automaton,
        pumpingLength: game.pumpingLength,
        challengeString: game.challengeString,
        attempts: updatedAttempts,
        isCompleted: isCompleted,
        score: updatedScore,
        maxScore: game.maxScore,
      );

      stopwatch.stop();

      return Success(updatedGame);
    } catch (e) {
      return Failure('Error updating game: $e');
    }
  }

  /// Generates a hint for the game
  static Result<String> generateHint(
    models.PumpingLemmaGame game, {
    Duration timeout = const Duration(seconds: 5),
  }) {
    try {
      final stopwatch = Stopwatch()..start();

      // Generate a hint
      final hint = _generateHint(game, timeout);
      stopwatch.stop();

      return Success(hint);
    } catch (e) {
      return Failure('Error generating hint: $e');
    }
  }

  /// Generates a hint
  static String _generateHint(models.PumpingLemmaGame game, Duration timeout) {
    // Try to find a valid decomposition
    final string = game.challengeString;
    final pumpingLength = game.pumpingLength;

    for (int i = 0; i <= pumpingLength; i++) {
      for (int j = i + 1; j <= pumpingLength; j++) {
        if (j > string.length) break;

        final x = string.substring(0, i);
        final y = string.substring(i, j);
        final z = string.substring(j);

        if (y.isEmpty) continue;

        // Check if this decomposition works
        bool canPump = true;
        for (int k = 0; k <= 3; k++) {
          final pumpedString = x + (y * k) + z;
          if (!_isStringAccepted(game.automaton, pumpedString)) {
            canPump = false;
            break;
          }
        }

        if (canPump) {
          return 'Try x = "$x", y = "$y", z = "$z"';
        }
      }
    }

    return 'The pumping length is ${game.pumpingLength}. Try to find a decomposition where |xy| <= ${game.pumpingLength} and |y| > 0.';
  }

  /// Analyzes the game performance
  static Result<GameAnalysis> analyzeGame(
    models.PumpingLemmaGame game, {
    Duration timeout = const Duration(seconds: 5),
  }) {
    try {
      final stopwatch = Stopwatch()..start();

      // Analyze the game
      final result = _analyzeGame(game, timeout);
      stopwatch.stop();

      // Update execution time
      final finalResult = result.copyWith(executionTime: stopwatch.elapsed);

      return Success(finalResult);
    } catch (e) {
      return Failure('Error analyzing game: $e');
    }
  }

  /// Analyzes the game
  static GameAnalysis _analyzeGame(
    models.PumpingLemmaGame game,
    Duration timeout,
  ) {
    final startTime = DateTime.now();

    // Analyze attempts
    final totalAttempts = game.attempts.length;
    final successfulAttempts = game.attempts
        .where((a) => _validateAttempt(game, a, timeout).isSuccess)
        .length;
    final failedAttempts = totalAttempts - successfulAttempts;

    // Analyze score
    final scorePercentage = (game.score / game.maxScore) * 100;

    // Analyze difficulty
    final difficulty = _calculateDifficulty(game);

    return GameAnalysis(
      totalAttempts: totalAttempts,
      successfulAttempts: successfulAttempts,
      failedAttempts: failedAttempts,
      scorePercentage: scorePercentage,
      difficulty: difficulty,
      executionTime: DateTime.now().difference(startTime),
    );
  }

  /// Calculates the difficulty of the game
  static double _calculateDifficulty(models.PumpingLemmaGame game) {
    // Difficulty is based on pumping length and string length
    final pumpingLength = game.pumpingLength;
    final stringLength = game.challengeString.length;

    // Higher pumping length and string length = higher difficulty
    return (pumpingLength + stringLength) / 100.0;
  }
}

/// Result of validating a pumping attempt
class PumpingAttemptResult {
  final PumpingAttempt attempt;
  final bool isSuccess;
  final String? errorMessage;
  final Duration executionTime;

  const PumpingAttemptResult._({
    required this.attempt,
    required this.isSuccess,
    this.errorMessage,
    required this.executionTime,
  });

  factory PumpingAttemptResult.success({
    required PumpingAttempt attempt,
    required Duration executionTime,
  }) {
    return PumpingAttemptResult._(
      attempt: attempt,
      isSuccess: true,
      executionTime: executionTime,
    );
  }

  factory PumpingAttemptResult.failure({
    required PumpingAttempt attempt,
    required String errorMessage,
    required Duration executionTime,
  }) {
    return PumpingAttemptResult._(
      attempt: attempt,
      isSuccess: false,
      errorMessage: errorMessage,
      executionTime: executionTime,
    );
  }

  PumpingAttemptResult copyWith({
    PumpingAttempt? attempt,
    bool? isSuccess,
    String? errorMessage,
    Duration? executionTime,
  }) {
    return PumpingAttemptResult._(
      attempt: attempt ?? this.attempt,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage ?? this.errorMessage,
      executionTime: executionTime ?? this.executionTime,
    );
  }
}

/// Analysis result of the game
class GameAnalysis {
  final int totalAttempts;
  final int successfulAttempts;
  final int failedAttempts;
  final double scorePercentage;
  final double difficulty;
  final Duration executionTime;

  const GameAnalysis({
    required this.totalAttempts,
    required this.successfulAttempts,
    required this.failedAttempts,
    required this.scorePercentage,
    required this.difficulty,
    required this.executionTime,
  });

  GameAnalysis copyWith({
    int? totalAttempts,
    int? successfulAttempts,
    int? failedAttempts,
    double? scorePercentage,
    double? difficulty,
    Duration? executionTime,
  }) {
    return GameAnalysis(
      totalAttempts: totalAttempts ?? this.totalAttempts,
      successfulAttempts: successfulAttempts ?? this.successfulAttempts,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      scorePercentage: scorePercentage ?? this.scorePercentage,
      difficulty: difficulty ?? this.difficulty,
      executionTime: executionTime ?? this.executionTime,
    );
  }
}
