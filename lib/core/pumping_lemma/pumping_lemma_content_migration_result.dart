import 'pumping_lemma_progress.dart';

final class PumpingLemmaContentMigrationResult {
  PumpingLemmaContentMigrationResult({
    required this.progress,
    required List<String> discardedChallengeIds,
  }) : discardedChallengeIds = List<String>.unmodifiable(discardedChallengeIds);

  final PumpingLemmaEnvironmentProgress progress;
  final List<String> discardedChallengeIds;

  bool get changed => discardedChallengeIds.isNotEmpty;
}
