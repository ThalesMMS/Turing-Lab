import 'pumping_lemma_progress.dart';

final class PumpingLemmaProgressSnapshot {
  PumpingLemmaProgressSnapshot({
    PumpingLemmaEnvironmentProgress? regular,
    PumpingLemmaEnvironmentProgress? contextFree,
  }) : regular = regular ?? PumpingLemmaEnvironmentProgress(),
       contextFree = contextFree ?? PumpingLemmaEnvironmentProgress();

  factory PumpingLemmaProgressSnapshot.fromJson(Map<String, Object?> json) {
    if (json['version'] != schemaVersion) {
      _throwInvalidProgress();
    }
    final regular = _progressMap(json['regular']);
    final contextFree = _progressMap(json['contextFree']);
    return PumpingLemmaProgressSnapshot(
      regular: PumpingLemmaEnvironmentProgress.fromJson(regular),
      contextFree: PumpingLemmaEnvironmentProgress.fromJson(contextFree),
    );
  }

  static Map<String, Object?> _progressMap(Object? value) {
    if (value is! Map) {
      _throwInvalidProgress();
    }
    try {
      return Map<String, Object?>.from(value);
    } on TypeError {
      _throwInvalidProgress();
    }
  }

  static const schemaVersion = 2;

  static Never _throwInvalidProgress() =>
      throw const FormatException('Unsupported pumping progress version.');

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
