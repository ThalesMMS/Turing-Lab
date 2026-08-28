import 'package:collection/collection.dart';

final class PumpingLemmaEnvironmentProgress {
  PumpingLemmaEnvironmentProgress({
    Map<String, int> challengeScores = const {},
    Set<String> completedChallengeIds = const {},
    Map<String, int> challengeContentVersions = const {},
  }) : challengeScores = Map<String, int>.unmodifiable(challengeScores),
       completedChallengeIds = Set<String>.unmodifiable(completedChallengeIds),
       challengeContentVersions = Map<String, int>.unmodifiable(
         _normalizeContentVersions(
           challengeScores: challengeScores,
           completedChallengeIds: completedChallengeIds,
           challengeContentVersions: challengeContentVersions,
         ),
       );

  factory PumpingLemmaEnvironmentProgress.fromJson(Map<String, Object?> json) =>
      _fromJson(json);

  final Map<String, int> challengeScores;
  final Set<String> completedChallengeIds;
  final Map<String, int> challengeContentVersions;

  Map<String, Object?> toJson() => {
    'challengeScores': challengeScores,
    'completedChallengeIds': completedChallengeIds.toList()..sort(),
    'challengeContentVersions': challengeContentVersions,
  };

  @override
  bool operator ==(Object other) =>
      other is PumpingLemmaEnvironmentProgress &&
      const MapEquality<String, int>().equals(
        challengeScores,
        other.challengeScores,
      ) &&
      const SetEquality<String>().equals(
        completedChallengeIds,
        other.completedChallengeIds,
      ) &&
      const MapEquality<String, int>().equals(
        challengeContentVersions,
        other.challengeContentVersions,
      );

  @override
  int get hashCode => Object.hash(
    const MapEquality<String, int>().hash(challengeScores),
    const SetEquality<String>().hash(completedChallengeIds),
    const MapEquality<String, int>().hash(challengeContentVersions),
  );
}

PumpingLemmaEnvironmentProgress _fromJson(Map<String, Object?> json) {
  final scores =
      (json['challengeScores'] as Map<Object?, Object?>?)?.map(
        (key, value) => MapEntry(key as String, value as int),
      ) ??
      const <String, int>{};
  final encodedCompleted = json['completedChallengeIds'] as List<Object?>?;
  final encodedVersions =
      (json['challengeContentVersions'] as Map<Object?, Object?>?)?.map(
        (key, value) => MapEntry(key as String, value as int),
      ) ??
      const <String, int>{};
  return PumpingLemmaEnvironmentProgress(
    challengeScores: scores,
    completedChallengeIds: encodedCompleted == null
        ? scores.entries
              .where((entry) => entry.value > 0)
              .map((entry) => entry.key)
              .toSet()
        : encodedCompleted.cast<String>().toSet(),
    challengeContentVersions: encodedVersions,
  );
}

Map<String, int> _normalizeContentVersions({
  required Map<String, int> challengeScores,
  required Set<String> completedChallengeIds,
  required Map<String, int> challengeContentVersions,
}) {
  final challengeIds = <String>{
    ...challengeScores.keys,
    ...completedChallengeIds,
  };
  return <String, int>{
    for (final id in challengeIds) id: challengeContentVersions[id] ?? 1,
  };
}

final class PumpingLemmaContentMigrationResult {
  PumpingLemmaContentMigrationResult({
    required this.progress,
    required List<String> discardedChallengeIds,
  }) : discardedChallengeIds = List<String>.unmodifiable(discardedChallengeIds);

  final PumpingLemmaEnvironmentProgress progress;
  final List<String> discardedChallengeIds;

  bool get changed => discardedChallengeIds.isNotEmpty;
}

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

final class PumpingLemmaProgressSnapshot {
  PumpingLemmaProgressSnapshot({
    PumpingLemmaEnvironmentProgress? regular,
    PumpingLemmaEnvironmentProgress? contextFree,
  }) : regular = regular ?? PumpingLemmaEnvironmentProgress(),
       contextFree = contextFree ?? PumpingLemmaEnvironmentProgress();

  factory PumpingLemmaProgressSnapshot.fromJson(Map<String, Object?> json) {
    if (json['version'] != schemaVersion) {
      throw const FormatException('Unsupported pumping progress version.');
    }
    return PumpingLemmaProgressSnapshot(
      regular: PumpingLemmaEnvironmentProgress.fromJson(
        Map<String, Object?>.from(json['regular']! as Map),
      ),
      contextFree: PumpingLemmaEnvironmentProgress.fromJson(
        Map<String, Object?>.from(json['contextFree']! as Map),
      ),
    );
  }

  static const schemaVersion = 2;

  final PumpingLemmaEnvironmentProgress regular;
  final PumpingLemmaEnvironmentProgress contextFree;

  Map<String, Object?> toJson() => {
    'version': schemaVersion,
    'regular': regular.toJson(),
    'contextFree': contextFree.toJson(),
  };

  @override
  bool operator ==(Object other) =>
      other is PumpingLemmaProgressSnapshot &&
      regular == other.regular &&
      contextFree == other.contextFree;

  @override
  int get hashCode => Object.hash(regular, contextFree);
}

final class PumpingLemmaProgressMigrationResult {
  PumpingLemmaProgressMigrationResult({
    required this.snapshot,
    required List<String> discardedChallengeIds,
  }) : discardedChallengeIds = List<String>.unmodifiable(discardedChallengeIds);

  final PumpingLemmaProgressSnapshot snapshot;
  final List<String> discardedChallengeIds;

  bool get requiresUserNotice => discardedChallengeIds.isNotEmpty;
}

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
      throw const FormatException('Unsupported pumping progress version.');
    }

    final regular = <String, int>{};
    final contextFree = <String, int>{};
    final discarded = <String>[];
    final challenges = encoded['challenges'] as List<Object?>? ?? const [];
    for (final value in challenges) {
      final challenge = Map<String, Object?>.from(value! as Map);
      final id = challenge['id'] as String;
      final score = challenge['score'] as int? ?? 0;
      switch (challenge['theorem']) {
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
          completedChallengeIds: regular.keys.toSet(),
          challengeContentVersions: {for (final id in regular.keys) id: 1},
        ),
        contextFree: PumpingLemmaEnvironmentProgress(
          challengeScores: contextFree,
          completedChallengeIds: contextFree.keys.toSet(),
          challengeContentVersions: {for (final id in contextFree.keys) id: 1},
        ),
      ),
      discardedChallengeIds: discarded,
    );
  }
}
