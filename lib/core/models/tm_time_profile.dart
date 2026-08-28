import 'dart:collection';

import 'tm_execution_analysis.dart';
import '../messages/structured_message.dart';

/// Explicit resource and input-scope bounds for one empirical TM profile.
class TMTimeProfileBounds {
  const TMTimeProfileBounds({
    this.maxLength = 4,
    this.maxCandidatesPerLength = 64,
    this.maxStepsPerCandidate = 50000,
    this.maxConfigurationsPerCandidate = 100000,
    this.timeoutPerCandidate = const Duration(seconds: 5),
    this.operationsPerBatch = 250,
  });

  final int maxLength;
  final int maxCandidatesPerLength;
  final int maxStepsPerCandidate;
  final int maxConfigurationsPerCandidate;
  final Duration timeoutPerCandidate;
  final int operationsPerBatch;
}

/// Whether a profile reports DTM time or NTM exploration metrics.
enum TMTimeProfileKind { deterministicTime, nondeterministicExploration }

/// Overall completion state of a bounded profile.
enum TMTimeProfileStatus { complete, incomplete, cancelled, invalid }

/// Candidate scope planned for one input length.
class TMTimeProfilePlannedRow {
  const TMTimeProfilePlannedRow({
    required this.inputLength,
    required this.possibleCandidateCount,
    required this.candidateCount,
    required this.isSampled,
  });

  final int inputLength;
  final BigInt possibleCandidateCount;
  final int candidateCount;
  final bool isSampled;
}

/// Input scope and execution budget visible before profiling begins.
class TMTimeProfilePlan {
  TMTimeProfilePlan({
    required this.bounds,
    required List<String> alphabet,
    required List<TMTimeProfilePlannedRow> rows,
    required this.plannedCandidateCount,
    this.validationError,
    this.validationMessage,
  }) : alphabet = List<String>.unmodifiable(alphabet),
       rows = List<TMTimeProfilePlannedRow>.unmodifiable(rows);

  final TMTimeProfileBounds bounds;
  final List<String> alphabet;
  final List<TMTimeProfilePlannedRow> rows;
  final int plannedCandidateCount;
  final String? validationError;

  /// Locale-neutral semantic payload for [validationError], when available.
  final StructuredMessage? validationMessage;

  bool get hasSampledRows => rows.any((row) => row.isSampled);
  bool get isValid => validationError == null;
}

/// Progress emitted between execution batches so native and web UIs can cancel.
class TMTimeProfileProgress {
  const TMTimeProfileProgress({
    required this.completedCandidates,
    required this.totalCandidates,
    required this.inputLength,
    required this.input,
    this.isWitnessReplay = false,
  });

  final int completedCandidates;
  final int totalCandidates;
  final int inputLength;
  final String input;
  final bool isWitnessReplay;

  double get fraction =>
      totalCandidates == 0 ? 1 : completedCandidates / totalCandidates;
}

/// Input and retained trace witnessing one observed row maximum.
class TMTimeProfileWitness {
  const TMTimeProfileWitness({required this.input, required this.execution});

  final String input;
  final TMExecutionAnalysis execution;
}

/// Empirical measurements for all profiled candidates of one input length.
class TMTimeProfileRow {
  const TMTimeProfileRow({
    required this.inputLength,
    required this.possibleCandidateCount,
    required this.candidateCount,
    required this.evaluatedCandidateCount,
    required this.completedCount,
    required this.provenCycleCount,
    required this.unknownCount,
    required this.cancelledCount,
    required this.invalidCount,
    required this.isSampled,
    required this.isComplete,
    this.minimumTransitionSteps,
    this.maximumTransitionSteps,
    this.maximumTransitionWitness,
    this.minimumExplorationDepth,
    this.maximumExplorationDepth,
    this.maximumDepthWitness,
    this.minimumConfigurationsExplored,
    this.maximumConfigurationsExplored,
    this.maximumConfigurationsWitness,
  });

  final int inputLength;
  final BigInt possibleCandidateCount;
  final int candidateCount;
  final int evaluatedCandidateCount;
  final int completedCount;
  final int provenCycleCount;
  final int unknownCount;
  final int cancelledCount;
  final int invalidCount;
  final bool isSampled;
  final bool isComplete;

  /// DTM-only transition counts from runs that halted.
  final int? minimumTransitionSteps;
  final int? maximumTransitionSteps;
  final TMTimeProfileWitness? maximumTransitionWitness;

  /// NTM-only operational metrics. They are not deterministic running time.
  final int? minimumExplorationDepth;
  final int? maximumExplorationDepth;
  final TMTimeProfileWitness? maximumDepthWitness;
  final int? minimumConfigurationsExplored;
  final int? maximumConfigurationsExplored;
  final TMTimeProfileWitness? maximumConfigurationsWitness;
}

/// Bounded empirical profile grouped by input length.
class TMTimeProfileReport {
  TMTimeProfileReport({
    required this.kind,
    required this.status,
    required this.message,
    required this.plan,
    required List<TMTimeProfileRow> rows,
    required this.profilingWallClockTime,
    this.structuredMessage,
  }) : rows = UnmodifiableListView<TMTimeProfileRow>(rows);

  final TMTimeProfileKind kind;
  final TMTimeProfileStatus status;
  final String message;
  final TMTimeProfilePlan plan;
  final List<TMTimeProfileRow> rows;

  /// Device/runtime diagnostic only; never a TM time-complexity measurement.
  final Duration profilingWallClockTime;

  /// Locale-neutral semantic payload for [message], when available.
  final StructuredMessage? structuredMessage;

  bool get isComplete => status == TMTimeProfileStatus.complete;
}
