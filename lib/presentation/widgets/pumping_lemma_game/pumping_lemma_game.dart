//
//  pumping_lemma_game.dart
//  Turing Lab
//
//  Entrega o jogo interativo do Lema do Bombeamento com níveis, pontuação e feedback imediato aos estudantes. Orquestra desafios locais, controla estados de rodada e conversa com o provedor de progresso para persistir conquistas e estatísticas.
//
//  Thales Matheus Mendonça Santos - October 2025
//

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/pumping_lemma_progress_provider.dart';
import 'challenge_difficulty.dart';
import 'pumping_lemma_challenge_model.dart';
import 'pumping_lemma_challenges_data.dart';

export 'challenge_difficulty.dart';
export 'pumping_lemma_challenge_model.dart';
export 'pumping_lemma_challenges_data.dart';

/// Interactive Pumping Lemma Game widget with progressive difficulty and immediate feedback
class PumpingLemmaGame extends ConsumerStatefulWidget {
  const PumpingLemmaGame({super.key});

  @override
  ConsumerState<PumpingLemmaGame> createState() => _PumpingLemmaGameState();
}

class _PumpingLemmaGameState extends ConsumerState<PumpingLemmaGame> {
  int _currentLevel = 0;
  int _score = 0;
  int _streakCount = 0; // Track consecutive correct answers
  bool _isPlaying = false;
  String? _selectedAnswer;
  String? _gameResult;
  bool? _isLastAnswerCorrect;
  int _lastPointsEarned = 0;

  final List<PumpingLemmaChallenge> _challenges = pumpingLemmaChallenges;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(pumpingLemmaProgressProvider.notifier)
          .startNewGame(totalChallenges: _challenges.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            if (!_isPlaying) _buildStartScreen(context),
            if (_isPlaying) _buildGameScreen(context),
            if (_gameResult != null) _buildResultScreen(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final challengeIndex = _currentLevel < _challenges.length
        ? _currentLevel
        : _challenges.length - 1;
    final currentChallenge = _challenges[challengeIndex];
    final difficultyColor = switch (currentChallenge.difficulty) {
      ChallengeDifficulty.easy => Colors.green,
      ChallengeDifficulty.medium => Colors.orange,
      ChallengeDifficulty.hard => Colors.red,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.games, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Pumping Lemma Game',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: difficultyColor.withValues(alpha: 0.1),
                border: Border.all(color: difficultyColor),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Level ${currentChallenge.level} - ${currentChallenge.difficulty.name.toUpperCase()}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: difficultyColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'Challenge ${_currentLevel + 1}/${_challenges.length}',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              'Score: $_score',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(width: 16),
            if (_streakCount > 0) ...[
              const Icon(
                Icons.local_fire_department,
                color: Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 4),
              Text(
                'Streak: $_streakCount',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildStartScreen(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 200),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.psychology,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Welcome to the Pumping Lemma Game!',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Test your understanding of the pumping lemma by determining whether given languages are regular or not.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _startGame,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Game'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameScreen(BuildContext context) {
    if (_currentLevel >= _challenges.length) {
      return _buildGameComplete(context);
    }

    final challenge = _challenges[_currentLevel];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChallengeCard(context, challenge),
          const SizedBox(height: 16),
          _buildAnswerOptions(context),
          const SizedBox(height: 16),
          _buildSubmitButton(context),
        ],
      ),
    );
  }

  Widget _buildChallengeCard(
    BuildContext context,
    PumpingLemmaChallenge challenge,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Challenge ${_currentLevel + 1}',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Language: ${challenge.language}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            challenge.description,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          Text(
            'Examples:',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            challenge.examples.join(', '),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerOptions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Is this language regular?',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          _buildAnswerOption(
            context,
            label: 'Yes, it is regular',
            value: 'regular',
            icon: Icons.check_circle,
            color: Colors.green,
          ),
          const SizedBox(height: 8),
          _buildAnswerOption(
            context,
            label: 'No, it is not regular',
            value: 'not_regular',
            icon: Icons.cancel,
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerOption(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedAnswer == value;

    return InkWell(
      onTap: () => setState(() => _selectedAnswer = value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : null,
          border: Border.all(
            color: isSelected
                ? color
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? color
                  : Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: isSelected ? color : null,
                    fontWeight: isSelected ? FontWeight.w600 : null,
                  ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(Icons.radio_button_checked, color: color)
            else
              Icon(
                Icons.radio_button_unchecked,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _selectedAnswer != null ? _submitAnswer : null,
        icon: const Icon(Icons.send),
        label: const Text('Submit Answer'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildResultScreen(BuildContext context) {
    final challenge = _challenges[_currentLevel];
    final isCorrect = _isLastAnswerCorrect ?? false;
    final color = isCorrect ? Colors.green : Colors.red;

    return Container(
      constraints: const BoxConstraints(minHeight: 200),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                color: color,
                size: 32,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCorrect ? 'Correct!' : 'Incorrect',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(color: color, fontWeight: FontWeight.bold),
                    ),
                    if (isCorrect && _streakCount > 1) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Streak bonus! +${(_lastPointsEarned * 0.5).toInt()} points',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Explanation:',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ...challenge.detailedExplanation.map(
            (explanation) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '• $explanation',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
          if (!isCorrect && challenge.hints.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Hint for next time:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
            ),
            const SizedBox(height: 8),
            ...challenge.hints.map(
              (hint) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '💡 $hint',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.blue),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _nextChallenge,
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(
                    _currentLevel < _challenges.length - 1
                        ? 'Next Challenge'
                        : 'Finish Game',
                  ),
                ),
              ),
              if (!isCorrect && _currentLevel < _challenges.length - 1) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _retryChallenge,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGameComplete(BuildContext context) {
    final maxPossibleScore = _maxPossibleScore();
    final percentage = (_score / maxPossibleScore) * 100;

    final performanceLevel = percentage >= 90
        ? 'Expert'
        : percentage >= 75
            ? 'Advanced'
            : percentage >= 60
                ? 'Intermediate'
                : 'Beginner';

    final performanceColor = percentage >= 90
        ? Colors.green
        : percentage >= 75
            ? Colors.blue
            : percentage >= 60
                ? Colors.orange
                : Colors.red;

    return Container(
      constraints: const BoxConstraints(minHeight: 400),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: performanceColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: performanceColor, width: 3),
            ),
            child: Icon(
              percentage >= 90
                  ? Icons.workspace_premium
                  : percentage >= 75
                      ? Icons.school
                      : percentage >= 60
                          ? Icons.trending_up
                          : Icons.psychology,
              size: 48,
              color: performanceColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Challenge Complete!',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Level: $performanceLevel',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: performanceColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Final Score',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '$_score / $maxPossibleScore',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                const SizedBox(height: 8),
                Text(
                  '${percentage.toStringAsFixed(1)}% - $performanceLevel',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: performanceColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _getPerformanceMessage(percentage),
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Learning Progress:',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                _buildProgressItem(
                  context,
                  'Regular Languages',
                  'You understand basic regular language patterns',
                  Icons.check_circle,
                  Colors.green,
                ),
                _buildProgressItem(
                  context,
                  'Pumping Lemma Application',
                  'You can identify when languages are not regular',
                  Icons.psychology,
                  percentage >= 60 ? Colors.blue : Colors.grey,
                ),
                _buildProgressItem(
                  context,
                  'Advanced Patterns',
                  'You recognize complex non-regular languages',
                  Icons.trending_up,
                  percentage >= 80 ? Colors.orange : Colors.grey,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _restartGame,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Practice Again'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressItem(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getPerformanceMessage(double percentage) {
    if (percentage >= 90) {
      return 'Outstanding! You have mastered the pumping lemma and can identify regular and non-regular languages with confidence. You understand the theoretical foundations and can apply the lemma correctly to prove non-regularity.';
    } else if (percentage >= 75) {
      return 'Excellent work! You have a strong understanding of the pumping lemma. You can correctly identify most regular and non-regular languages, and your application of the lemma is generally sound.';
    } else if (percentage >= 60) {
      return 'Good progress! You\'re developing a solid foundation in the pumping lemma. You can identify basic patterns and are learning to apply the lemma systematically. Keep practicing to strengthen your skills.';
    } else {
      return 'You\'re taking the first steps in understanding the pumping lemma. This is a challenging concept that requires practice. Focus on understanding the basic proof technique and identifying when languages require unbounded memory.';
    }
  }

  void _startGame() {
    setState(() {
      _isPlaying = true;
      _currentLevel = 0;
      _resetScoringState();
      _selectedAnswer = null;
      _gameResult = null;
    });
  }

  void _submitAnswer() {
    if (_selectedAnswer == null) return;

    final challenge = _challenges[_currentLevel];
    final isCorrect =
        _selectedAnswer == (challenge.isRegular ? 'regular' : 'not_regular');

    // Calculate score based on difficulty and streak with educational focus
    int pointsEarned = 0;
    if (isCorrect) {
      pointsEarned = _scoreForCorrectAnswer(challenge, _streakCount);

      _score += pointsEarned;
      _lastPointsEarned = pointsEarned;
      _streakCount++;
    } else {
      _streakCount = 0; // Reset streak on wrong answer

      // Learning opportunity - provide partial credit for attempting challenging questions
      if (challenge.difficulty == ChallengeDifficulty.hard) {
        pointsEarned = 5; // Partial credit for attempting hard questions
        _score += pointsEarned;
        _lastPointsEarned = pointsEarned;
      } else {
        _lastPointsEarned = 0;
      }
    }

    _isLastAnswerCorrect = isCorrect;

    ref.read(pumpingLemmaProgressProvider.notifier).recordAnswer(
          challengeId: challenge.id,
          challengeTitle: 'Challenge ${challenge.id}: ${challenge.description}',
          language: challenge.language,
          isCorrect: isCorrect,
        );

    setState(() {
      _gameResult = isCorrect ? 'correct' : 'incorrect';
    });
  }

  int _maxPossibleScore() {
    var streakCount = 0;
    var total = 0;
    for (final challenge in _challenges) {
      total += _scoreForCorrectAnswer(challenge, streakCount);
      streakCount++;
    }
    return total;
  }

  int _scoreForCorrectAnswer(
    PumpingLemmaChallenge challenge,
    int streakCount,
  ) {
    final basePoints = switch (challenge.difficulty) {
      ChallengeDifficulty.easy => 10,
      ChallengeDifficulty.medium => 20,
      ChallengeDifficulty.hard => 30,
    };
    final streakBonus = streakCount >= 2 ? (basePoints * 0.5).toInt() : 0;
    final levelBonus = challenge.level * 2;
    return basePoints + streakBonus + levelBonus;
  }

  void _nextChallenge() {
    final challenge = _challenges[_currentLevel];
    ref
        .read(pumpingLemmaProgressProvider.notifier)
        .markChallengeCompleted(challenge.id);

    setState(() {
      _currentLevel++;
      _selectedAnswer = null;
      _gameResult = null;
      _isLastAnswerCorrect = null;
    });
  }

  void _retryChallenge() {
    final challenge = _challenges[_currentLevel];
    ref.read(pumpingLemmaProgressProvider.notifier).recordRetry(
          challengeId: challenge.id,
          challengeTitle: 'Challenge ${challenge.id}: ${challenge.description}',
          language: challenge.language,
        );

    setState(() {
      _selectedAnswer = null;
      _gameResult = null;
      _isLastAnswerCorrect = null;
      _lastPointsEarned = 0;
    });
  }

  void _restartGame() {
    ref.read(pumpingLemmaProgressProvider.notifier).restartGame();

    setState(() {
      _isPlaying = false;
      _currentLevel = 0;
      _resetScoringState();
      _selectedAnswer = null;
      _gameResult = null;
    });
  }

  void _resetScoringState() {
    _score = 0;
    _streakCount = 0;
    _isLastAnswerCorrect = null;
    _lastPointsEarned = 0;
  }
}
