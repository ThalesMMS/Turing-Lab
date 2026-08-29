import 'pumping_lemma_progress.dart';
import 'pumping_lemma_progress_migration_result.dart';
import 'pumping_lemma_progress_snapshot.dart';

abstract final class PumpingLemmaProgressMigration {
  static PumpingLemmaProgressMigrationResult migrate(
    Map<String, Object?> encoded,
  ) {
    if (encoded['version'] == PumpingLemmaProgressSnapshot.schemaVersion) {
      return PumpingLemmaProgressMigrationResult(
        snapshot: PumpingLemmaProgressSnapshot.fromJson(encoded),
        discardedChallengeIds: const [],
      );
    }
    if (encoded['version'] != 1) {
      _throwInvalidProgress();
    }

    final regular = <String, int>{};
    final contextFree = <String, int>{};
    final discarded = <String>[];
    final encodedChallenges = encoded['challenges'];
    if (encodedChallenges != null && encodedChallenges is! List) {
      _throwInvalidProgress();
    }
    final challenges = encodedChallenges as List? ?? const [];
    for (final value in challenges) {
      if (value is! Map || value['id'] is! String) {
        _throwInvalidProgress();
      }
      final id = value['id']! as String;
      final encodedScore = value['score'];
      if (encodedScore != null && encodedScore is! int) {
        _throwInvalidProgress();
      }
      final score = encodedScore as int? ?? 0;
      switch (value['theorem']) {
        case 'regular':
          regular[id] = score;
        case 'contextFree':
          contextFree[id] = score;
        default:
          discarded.add(id);
      }
    }

    return PumpingLemmaProgressMigrationResult(
      snapshot: PumpingLemmaProgressSnapshot(
        regular: PumpingLemmaEnvironmentProgress(
          challengeScores: regular,
          completedChallengeIds: regular.entries
              .where((entry) => entry.value > 0)
              .map((entry) => entry.key)
              .toSet(),
          challengeContentVersions: {for (final id in regular.keys) id: 1},
        ),
        contextFree: PumpingLemmaEnvironmentProgress(
          challengeScores: contextFree,
          completedChallengeIds: contextFree.entries
              .where((entry) => entry.value > 0)
              .map((entry) => entry.key)
              .toSet(),
          challengeContentVersions: {for (final id in contextFree.keys) id: 1},
        ),
      ),
      discardedChallengeIds: discarded,
    );
  }

  static Never _throwInvalidProgress() =>
      throw const FormatException('Unsupported pumping progress version.');
}
