import 'pumping_lemma_progress_snapshot.dart';

final class PumpingLemmaProgressMigrationResult {
  PumpingLemmaProgressMigrationResult({
    required this.snapshot,
    required List<String> discardedChallengeIds,
  }) : discardedChallengeIds = List<String>.unmodifiable(discardedChallengeIds);

  final PumpingLemmaProgressSnapshot snapshot;
  final List<String> discardedChallengeIds;

  bool get requiresUserNotice => discardedChallengeIds.isNotEmpty;
}
