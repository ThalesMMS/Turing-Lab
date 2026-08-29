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

  static PumpingLemmaEnvironmentProgress _fromJson(Map<String, Object?> json) {
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

  static Map<String, int> _normalizeContentVersions({
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
}
