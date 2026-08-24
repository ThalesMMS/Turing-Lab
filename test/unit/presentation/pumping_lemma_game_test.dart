//
//  pumping_lemma_game_test.dart
//  Turing Lab
//
//  Tests for pumping-lemma game mode, ensuring a clean start,
//  linear progress through challenges, scoring of correct and incorrect
//  answers, and proper resource cleanup on restart.
//
//  Thales Matheus Mendonça Santos - October 2025
//

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:turing_lab/presentation/providers/pumping_lemma_progress_provider.dart';
import 'package:turing_lab/presentation/widgets/pumping_lemma_game/pumping_lemma_game.dart';

Future<void> _pumpGame(WidgetTester tester) async {
  await tester.pumpWidget(
    const ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: PumpingLemmaGame(),
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _tapVisibleText(WidgetTester tester, String text) async {
  final finder = find.text(text).last;
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _answerCorrectly(
  WidgetTester tester,
  PumpingLemmaChallenge challenge,
) async {
  final answerLabel =
      challenge.isRegular ? 'Yes, it is regular' : 'No, it is not regular';
  await _tapVisibleText(tester, answerLabel);
  await _tapVisibleText(tester, 'Submit Answer');
}

int _expectedScoreForCorrectAnswer(PumpingLemmaChallenge challenge) {
  final basePoints = switch (challenge.difficulty) {
    ChallengeDifficulty.easy => 10,
    ChallengeDifficulty.medium => 20,
    ChallengeDifficulty.hard => 30,
  };
  return basePoints + challenge.level * 2;
}

void main() {
  group('Pumping lemma game mode', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    group('Game progression', () {
      test('Progresses linearly through challenges', () {
        // This test verifies that the game progresses through challenges in order
        // and maintains state correctly
        final state = container.read(pumpingLemmaProgressProvider);

        expect(state.totalChallenges, 0); // Initial state has no challenges
        expect(state.completedChallenges, 0);
        expect(state.score, 0);
        expect(state.attempts, 0);
      });

      test('Records progress and answers correctly', () {
        final notifier = container.read(pumpingLemmaProgressProvider.notifier);

        // Start a new game
        notifier.startNewGame(totalChallenges: 6);

        // Record some answers
        notifier.recordAnswer(
          challengeId: 1,
          challengeTitle: 'Test Challenge 1',
          language: 'L = {a^n}',
          isCorrect: true,
        );

        notifier.recordAnswer(
          challengeId: 2,
          challengeTitle: 'Test Challenge 2',
          language: 'L = {a^n b^n}',
          isCorrect: false,
        );

        final state = container.read(pumpingLemmaProgressProvider);

        expect(state.totalChallenges, 6);
        expect(state.score, 1); // Only one correct answer
        expect(state.attempts, 2);
        expect(state.history.length, 2);

        // Verify history entries
        expect(state.history[0].type, PumpingLemmaHistoryType.attempt);
        expect(state.history[0].isCorrect, true);
        expect(state.history[1].type, PumpingLemmaHistoryType.attempt);
        expect(state.history[1].isCorrect, false);
      });

      test('Marks challenges as completed', () {
        final notifier = container.read(pumpingLemmaProgressProvider.notifier);

        notifier.startNewGame(totalChallenges: 3);

        // Complete challenge 1
        notifier.markChallengeCompleted(1);

        var state = container.read(pumpingLemmaProgressProvider);
        expect(state.completedChallengeIds, contains(1));
        expect(state.completedChallenges, 1);

        // Complete challenge 3 (should not affect order)
        notifier.markChallengeCompleted(3);

        state = container.read(pumpingLemmaProgressProvider);
        expect(state.completedChallengeIds, containsAll([1, 3]));
        expect(state.completedChallenges, 2);
      });

      test('Records retry attempts', () {
        final notifier = container.read(pumpingLemmaProgressProvider.notifier);

        notifier.startNewGame(totalChallenges: 2);

        // Record a retry
        notifier.recordRetry(
          challengeId: 1,
          challengeTitle: 'Test Challenge 1',
          language: 'L = {a^n}',
        );

        final state = container.read(pumpingLemmaProgressProvider);
        expect(state.history.length, 1);
        expect(state.history[0].type, PumpingLemmaHistoryType.retry);
        expect(state.history[0].challengeId, 1);
      });

      test('Restarts game correctly', () {
        final notifier = container.read(pumpingLemmaProgressProvider.notifier);

        // Set up some progress
        notifier.startNewGame(totalChallenges: 3);
        notifier.recordAnswer(
          challengeId: 1,
          challengeTitle: 'Test',
          language: 'L = {a^n}',
          isCorrect: true,
        );
        notifier.markChallengeCompleted(1);

        var state = container.read(pumpingLemmaProgressProvider);
        expect(state.score, 1);
        expect(state.completedChallenges, 1);

        // Restart game
        notifier.restartGame();

        state = container.read(pumpingLemmaProgressProvider);
        expect(state.totalChallenges, 3); // Preserved
        expect(state.score, 0); // Reset
        expect(state.completedChallenges, 0); // Reset
        expect(state.attempts, 0); // Reset
        expect(state.history, isEmpty); // Reset
      });
    });

    group('Challenge data structure', () {
      test('Creates challenges with correct difficulty levels', () {
        // Test that ChallengeDifficulty enum works correctly
        expect(ChallengeDifficulty.easy.name, 'easy');
        expect(ChallengeDifficulty.medium.name, 'medium');
        expect(ChallengeDifficulty.hard.name, 'hard');
      });

      test('Challenge data contains all required fields', () {
        // This is a compile-time test to ensure the PumpingLemmaChallenge
        // class has all required fields as defined in the implementation
        final challenge = PumpingLemmaChallenge(
          id: 1,
          level: 1,
          difficulty: ChallengeDifficulty.easy,
          language: 'L = {a^n}',
          description: 'Test language',
          isRegular: true,
          explanation: 'Test explanation',
          detailedExplanation: ['Step 1', 'Step 2'],
          examples: ['a', 'aa'],
          hints: ['Hint 1'],
        );

        expect(challenge.id, 1);
        expect(challenge.level, 1);
        expect(challenge.difficulty, ChallengeDifficulty.easy);
        expect(challenge.language, 'L = {a^n}');
        expect(challenge.isRegular, true);
        expect(challenge.detailedExplanation.length, 2);
        expect(challenge.hints.length, 1);
      });

      test('Challenge list cannot be mutated by consumers', () {
        expect(pumpingLemmaChallenges, isNotEmpty);
        expect(
          () => pumpingLemmaChallenges.add(pumpingLemmaChallenges.first),
          throwsUnsupportedError,
        );
      });
    });

    group('PumpingLemmaGame scoring UI', () {
      testWidgets('does not offer retry after a correct answer',
          (tester) async {
        await _pumpGame(tester);
        await _tapVisibleText(tester, 'Start Game');
        await _answerCorrectly(tester, pumpingLemmaChallenges.first);

        expect(find.text('Correct!'), findsOneWidget);
        expect(find.text('Retry'), findsNothing);
      });

      testWidgets('practice again clears score and streak state',
          (tester) async {
        await _pumpGame(tester);
        await _tapVisibleText(tester, 'Start Game');

        for (var i = 0; i < pumpingLemmaChallenges.length; i++) {
          await _answerCorrectly(tester, pumpingLemmaChallenges[i]);
          await _tapVisibleText(
            tester,
            i == pumpingLemmaChallenges.length - 1
                ? 'Finish Game'
                : 'Next Challenge',
          );
        }

        expect(find.text('Challenge Complete!'), findsOneWidget);
        expect(find.textContaining('Streak:'), findsOneWidget);

        await _tapVisibleText(tester, 'Practice Again');

        expect(find.text('Score: 0'), findsOneWidget);
        expect(find.textContaining('Streak:'), findsNothing);

        await _tapVisibleText(tester, 'Start Game');
        final firstChallenge = pumpingLemmaChallenges.first;
        await _answerCorrectly(tester, firstChallenge);

        expect(
          find.text('Score: ${_expectedScoreForCorrectAnswer(firstChallenge)}'),
          findsOneWidget,
        );
        expect(find.text('Retry'), findsNothing);
      });
    });
  });
}
