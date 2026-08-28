import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/pumping_lemma/pumping_lemma.dart';
import 'package:turing_lab/presentation/providers/pumping_lemma_progress_provider.dart';

void main() {
  test('regular and context-free progress never share score or history', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container
        .read(regularPumpingLemmaProgressProvider.notifier)
        .startNewGame(totalChallenges: 2);
    container
        .read(contextFreePumpingLemmaProgressProvider.notifier)
        .startNewGame(totalChallenges: 3);
    container
        .read(regularPumpingLemmaProgressProvider.notifier)
        .recordAnswer(
          challengeId: 1,
          challengeContentId: 'regular.equal-blocks',
          challengeContentVersion: 2,
          language: 'a*',
          isCorrect: true,
        );

    final regular = container.read(regularPumpingLemmaProgressProvider);
    final contextFree = container.read(contextFreePumpingLemmaProgressProvider);

    expect(regular.theorem, PumpingLemmaTheorem.regular);
    expect(regular.score, 1);
    expect(regular.challengeContentVersions, {'regular.equal-blocks': 2});
    expect(regular.history, hasLength(1));
    expect(contextFree.theorem, PumpingLemmaTheorem.contextFree);
    expect(contextFree.score, 0);
    expect(contextFree.history, isEmpty);
    expect(container.read(pumpingLemmaProgressProvider), same(regular));
  });

  test('completion and restored scores use stable content identifiers', () {
    final notifier = PumpingLemmaProgressNotifier();

    notifier.startNewGame(totalChallenges: 2);
    notifier.markChallengeCompleted(
      'regular.equal-blocks',
      challengeContentVersion: 2,
    );

    expect(notifier.state.completedChallengeIds, {'regular.equal-blocks'});

    notifier.restoreProgress(
      totalChallenges: 2,
      challengeScores: const {
        'regular.equal-blocks': 1,
        'regular.unary-square': 2,
      },
      completedChallengeIds: const {'regular.equal-blocks'},
      challengeContentVersions: const {
        'regular.equal-blocks': 2,
        'regular.unary-square': 1,
      },
    );

    expect(notifier.state.completedChallengeIds, {'regular.equal-blocks'});
    expect(notifier.state.score, 3);
    expect(notifier.state.challengeScores, {
      'regular.equal-blocks': 1,
      'regular.unary-square': 2,
    });
    expect(notifier.state.challengeContentVersions, {
      'regular.equal-blocks': 2,
      'regular.unary-square': 1,
    });
  });

  test(
    'persisted progress round-trips scores and completion independently',
    () {
      final progress = PumpingLemmaEnvironmentProgress(
        challengeScores: const {
          'regular.equal-blocks': 0,
          'regular.unary-square': 2,
        },
        completedChallengeIds: const {'regular.unary-square'},
      );

      final restored = PumpingLemmaEnvironmentProgress.fromJson(
        progress.toJson(),
      );

      expect(restored, progress);
      expect(
        restored.completedChallengeIds,
        isNot(contains('regular.equal-blocks')),
      );
    },
  );
}
