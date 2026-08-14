//
//  conversion_step_history.dart
//  Turing Lab
//
//  Model to preserve conversion history with before/after snapshots.
//
//  This intentionally keeps snapshots generic (JSON-like) so different
//  conversion workflows can persist their artifacts without introducing
//  deep coupling between algorithm panels and specific automaton models.
//
//  Added as part of richer visual explanations & diagnostic overlays.
//

import 'algorithm_step.dart';

const Object _unset = Object();

/// Represents a single step in a conversion workflow, including snapshots
/// of the artifacts before/after this step is applied.
class ConversionHistoryStep {
  /// Unique identifier for this history entry.
  final String id;

  /// 0-indexed position in the conversion history.
  final int stepNumber;

  /// The algorithm step description associated with this history entry.
  ///
  /// This carries title/explanation and optional structured stepExplanation.
  final AlgorithmStep algorithmStep;

  /// Snapshot of the input artifact before applying this step.
  ///
  /// Stored as JSON-like data to allow persistence across sessions.
  final Map<String, dynamic>? beforeSnapshot;

  /// Snapshot of the output artifact after applying this step.
  ///
  /// Stored as JSON-like data to allow persistence across sessions.
  final Map<String, dynamic>? afterSnapshot;

  /// Optional extra snapshots relevant to the conversion (e.g. intermediate
  /// tables, partitions, parse charts).
  final Map<String, Map<String, dynamic>> auxiliarySnapshots;

  /// When this entry was created.
  final DateTime timestamp;

  const ConversionHistoryStep({
    required this.id,
    required this.stepNumber,
    required this.algorithmStep,
    this.beforeSnapshot,
    this.afterSnapshot,
    this.auxiliarySnapshots = const {},
    required this.timestamp,
  });

  ConversionHistoryStep copyWith({
    String? id,
    int? stepNumber,
    AlgorithmStep? algorithmStep,
    Object? beforeSnapshot = _unset,
    Object? afterSnapshot = _unset,
    Map<String, Map<String, dynamic>>? auxiliarySnapshots,
    DateTime? timestamp,
  }) {
    return ConversionHistoryStep(
      id: id ?? this.id,
      stepNumber: stepNumber ?? this.stepNumber,
      algorithmStep: algorithmStep ?? this.algorithmStep,
      beforeSnapshot: beforeSnapshot == _unset
          ? this.beforeSnapshot
          : beforeSnapshot as Map<String, dynamic>?,
      afterSnapshot: afterSnapshot == _unset
          ? this.afterSnapshot
          : afterSnapshot as Map<String, dynamic>?,
      auxiliarySnapshots: auxiliarySnapshots ?? this.auxiliarySnapshots,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stepNumber': stepNumber,
      'algorithmStep': algorithmStep.toJson(),
      'beforeSnapshot': beforeSnapshot,
      'afterSnapshot': afterSnapshot,
      'auxiliarySnapshots': auxiliarySnapshots,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ConversionHistoryStep.fromJson(Map<String, dynamic> json) {
    return ConversionHistoryStep(
      id: json['id'] as String,
      stepNumber: json['stepNumber'] as int,
      algorithmStep: AlgorithmStep.fromJson(
        Map<String, dynamic>.from(json['algorithmStep'] as Map),
      ),
      beforeSnapshot: json['beforeSnapshot'] is Map
          ? Map<String, dynamic>.from(json['beforeSnapshot'] as Map)
          : null,
      afterSnapshot: json['afterSnapshot'] is Map
          ? Map<String, dynamic>.from(json['afterSnapshot'] as Map)
          : null,
      auxiliarySnapshots: _parseAuxSnapshots(json['auxiliarySnapshots']),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  static Map<String, Map<String, dynamic>> _parseAuxSnapshots(dynamic raw) {
    if (raw is! Map) return const {};
    final out = <String, Map<String, dynamic>>{};
    for (final entry in raw.entries) {
      final key = entry.key?.toString();
      if (key == null) continue;
      final value = entry.value;
      if (value is Map) {
        out[key] = Map<String, dynamic>.from(value);
      }
    }
    return Map.unmodifiable(out);
  }
}

/// Represents the full conversion history for a workflow.
class ConversionHistory {
  /// Stable identifier for the conversion session.
  final String id;

  /// What type of algorithm created this history.
  final AlgorithmType algorithmType;

  /// Ordered list of steps.
  final List<ConversionHistoryStep> steps;

  /// Base snapshot of the original input artifact.
  final Map<String, dynamic>? initialSnapshot;

  /// Snapshot of the final artifact.
  final Map<String, dynamic>? finalSnapshot;

  const ConversionHistory({
    required this.id,
    required this.algorithmType,
    this.steps = const [],
    this.initialSnapshot,
    this.finalSnapshot,
  });

  ConversionHistory copyWith({
    String? id,
    AlgorithmType? algorithmType,
    List<ConversionHistoryStep>? steps,
    Object? initialSnapshot = _unset,
    Object? finalSnapshot = _unset,
  }) {
    return ConversionHistory(
      id: id ?? this.id,
      algorithmType: algorithmType ?? this.algorithmType,
      steps: steps ?? this.steps,
      initialSnapshot: initialSnapshot == _unset
          ? this.initialSnapshot
          : initialSnapshot as Map<String, dynamic>?,
      finalSnapshot: finalSnapshot == _unset
          ? this.finalSnapshot
          : finalSnapshot as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'algorithmType': algorithmType.name,
      'steps': steps.map((s) => s.toJson()).toList(growable: false),
      'initialSnapshot': initialSnapshot,
      'finalSnapshot': finalSnapshot,
    };
  }

  factory ConversionHistory.fromJson(Map<String, dynamic> json) {
    final rawSteps = json['steps'];
    return ConversionHistory(
      id: json['id'] as String,
      algorithmType: AlgorithmType.values.firstWhere(
        (e) => e.name == json['algorithmType'],
        orElse: () => AlgorithmType.nfaToDfa,
      ),
      steps: rawSteps is List
          ? rawSteps
              .whereType<Map>()
              .map((e) => ConversionHistoryStep.fromJson(
                    Map<String, dynamic>.from(e),
                  ))
              .toList(growable: false)
          : const [],
      initialSnapshot: json['initialSnapshot'] is Map
          ? Map<String, dynamic>.from(json['initialSnapshot'] as Map)
          : null,
      finalSnapshot: json['finalSnapshot'] is Map
          ? Map<String, dynamic>.from(json['finalSnapshot'] as Map)
          : null,
    );
  }
}
