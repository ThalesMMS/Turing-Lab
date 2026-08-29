import 'pumping_lemma_content_migration_result.dart';
import 'pumping_lemma_progress.dart';

abstract final class PumpingLemmaContentMigration {
  static PumpingLemmaContentMigrationResult reconcile({
    required PumpingLemmaEnvironmentProgress progress,
    required Map<String, int> currentContentVersions,
  }) {
    final retainedIds = <String>{};
    final discardedIds = <String>[];
    final persistedIds = <String>{
      ...progress.challengeScores.keys,
      ...progress.completedChallengeIds,
    };
    for (final id in persistedIds) {
      final currentVersion = currentContentVersions[id];
      if (currentVersion != null &&
          progress.challengeContentVersions[id] == currentVersion) {
        retainedIds.add(id);
      } else {
        discardedIds.add(id);
      }
    }
    discardedIds.sort();

    return PumpingLemmaContentMigrationResult(
      progress: PumpingLemmaEnvironmentProgress(
        challengeScores: <String, int>{
          for (final entry in progress.challengeScores.entries)
            if (retainedIds.contains(entry.key)) entry.key: entry.value,
        },
        completedChallengeIds: progress.completedChallengeIds
            .where(retainedIds.contains)
            .toSet(),
        challengeContentVersions: <String, int>{
          for (final id in retainedIds) id: currentContentVersions[id]!,
        },
      ),
      discardedChallengeIds: discardedIds,
    );
  }
}
