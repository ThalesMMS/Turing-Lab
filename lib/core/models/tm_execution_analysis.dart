import 'dart:collection';
import 'dart:convert';

import 'simulation_step.dart';

/// Semantic outcome of a bounded Turing machine execution analysis.
enum TMExecutionOutcome {
  accepted,
  haltedRejected,
  provenCycle,
  boundedUnknown,
  cancelled,
  invalidMachine,
}

/// Resource bound that stopped an otherwise inconclusive analysis.
enum TMExecutionLimit { steps, configurations, timeout }

/// How the concrete branch represented by [TMTraceMetrics] was selected.
enum TMExecutionBranchSelection {
  deterministic,
  acceptingBranch,
  rejectingBranch,
  cyclicBranch,
  longestBoundedBranch,
}

/// Peak tape-space measures observed while bounded execution was explored.
///
/// Unlike [TMTraceMetrics], this summary may aggregate multiple NTM branches.
/// It deliberately keeps only maxima, so operation counts from unrelated
/// branches remain separate.
class TMExecutionSpaceMetrics {
  const TMExecutionSpaceMetrics({
    required this.maximumVisitedSpan,
    required this.maximumNonBlankCells,
    required this.aggregatesNondeterministicBranches,
  });

  final int maximumVisitedSpan;
  final int maximumNonBlankCells;
  final bool aggregatesNondeterministicBranches;
}

/// First and last execution steps at which the head touched one logical cell.
class TMTapeCellTouchRange {
  const TMTapeCellTouchRange({
    required this.firstStep,
    required this.lastStep,
  });

  final int firstStep;
  final int lastStep;
}

/// One sparse difference between the initial and selected final tape.
class TMTapeCellChange {
  const TMTapeCellChange({
    required this.position,
    required this.initialSymbol,
    required this.finalSymbol,
  });

  final int position;
  final String initialSymbol;
  final String finalSymbol;
}

/// Streaming metrics for one real execution branch.
class TMTraceMetrics {
  TMTraceMetrics({
    required this.branchSelection,
    required Map<String, int> readCounts,
    required Map<String, int> writeCountsByOldSymbol,
    required Map<String, int> writeCountsByNewSymbol,
    required this.changedWrites,
    required Map<String, int> movementCounts,
    required this.headReversals,
    required this.minimumHeadPosition,
    required this.maximumHeadPosition,
    required Set<int> visitedCells,
    required this.maximumSimultaneousNonBlankCells,
    required Map<String, int> transitionExecutionCounts,
    required Map<int, TMTapeCellTouchRange> cellTouchRanges,
    required Map<int, TMTapeCellChange> tapeDiff,
    required Set<String> definedButNotExecutedTransitionIds,
    required this.retainedTraceSnapshots,
  })  : readCounts = UnmodifiableMapView(Map<String, int>.from(readCounts)),
        writeCountsByOldSymbol = UnmodifiableMapView(
          Map<String, int>.from(writeCountsByOldSymbol),
        ),
        writeCountsByNewSymbol = UnmodifiableMapView(
          Map<String, int>.from(writeCountsByNewSymbol),
        ),
        movementCounts = UnmodifiableMapView(
          Map<String, int>.from(movementCounts),
        ),
        visitedCells = Set<int>.unmodifiable(visitedCells),
        transitionExecutionCounts = UnmodifiableMapView(
          Map<String, int>.from(transitionExecutionCounts),
        ),
        cellTouchRanges = UnmodifiableMapView(
          Map<int, TMTapeCellTouchRange>.from(cellTouchRanges),
        ),
        tapeDiff =
            UnmodifiableMapView(Map<int, TMTapeCellChange>.from(tapeDiff)),
        definedButNotExecutedTransitionIds =
            Set<String>.unmodifiable(definedButNotExecutedTransitionIds);

  final TMExecutionBranchSelection branchSelection;
  final Map<String, int> readCounts;
  final Map<String, int> writeCountsByOldSymbol;
  final Map<String, int> writeCountsByNewSymbol;
  final int changedWrites;
  final Map<String, int> movementCounts;
  final int headReversals;
  final int minimumHeadPosition;
  final int maximumHeadPosition;
  final Set<int> visitedCells;
  final int maximumSimultaneousNonBlankCells;
  final Map<String, int> transitionExecutionCounts;
  final Map<int, TMTapeCellTouchRange> cellTouchRanges;
  final Map<int, TMTapeCellChange> tapeDiff;
  final Set<String> definedButNotExecutedTransitionIds;
  final int retainedTraceSnapshots;

  int get distinctCellsVisited => visitedCells.length;
}

/// Canonical single-tape configuration used for exact cycle detection.
class TMConfigurationSnapshot {
  TMConfigurationSnapshot({
    required this.stateId,
    required this.headPosition,
    required Map<int, String> nonBlankCells,
  }) : nonBlankCells = UnmodifiableMapView(
          Map<int, String>.fromEntries(
            nonBlankCells.entries.toList()
              ..sort((a, b) => a.key.compareTo(b.key)),
          ),
        );

  factory TMConfigurationSnapshot.canonical({
    required String stateId,
    required int headPosition,
    required Map<int, String> tape,
    required String blankSymbol,
  }) {
    return TMConfigurationSnapshot(
      stateId: stateId,
      headPosition: headPosition,
      nonBlankCells: Map<int, String>.fromEntries(
        tape.entries.where((entry) => entry.value != blankSymbol),
      ),
    );
  }

  final String stateId;
  final int headPosition;
  final Map<int, String> nonBlankCells;

  /// Stable key that does not depend on redundant blank cells or map order.
  String get key => jsonEncode([
        stateId,
        headPosition,
        for (final entry in nonBlankCells.entries) [entry.key, entry.value],
      ]);
}

/// Exact repeated-configuration witness for a deterministic cycle.
class TMCycleWitness {
  const TMCycleWitness({
    required this.startStep,
    required this.period,
    required this.configuration,
  });

  final int startStep;
  final int period;
  final TMConfigurationSnapshot configuration;
}

/// Result of executing one TM/input pair under explicit resource bounds.
class TMExecutionAnalysis {
  TMExecutionAnalysis({
    required this.input,
    required this.outcome,
    required this.message,
    required this.stepsExecuted,
    required this.configurationsExplored,
    required this.maxSteps,
    required this.maxConfigurations,
    required this.timeout,
    required this.executionTime,
    this.limit,
    this.cycle,
    this.repeatedConfigurationsObserved = 0,
    List<SimulationStep> trace = const [],
    this.traceMetrics,
    this.spaceMetrics,
  }) : trace = List.unmodifiable(trace);

  final String input;
  final TMExecutionOutcome outcome;
  final String message;
  final int stepsExecuted;
  final int configurationsExplored;
  final int maxSteps;
  final int maxConfigurations;
  final Duration timeout;
  final Duration executionTime;
  final TMExecutionLimit? limit;
  final TMCycleWitness? cycle;
  final int repeatedConfigurationsObserved;
  final List<SimulationStep> trace;
  final TMTraceMetrics? traceMetrics;
  final TMExecutionSpaceMetrics? spaceMetrics;

  bool get isExact => switch (outcome) {
        TMExecutionOutcome.accepted ||
        TMExecutionOutcome.haltedRejected ||
        TMExecutionOutcome.provenCycle ||
        TMExecutionOutcome.invalidMachine =>
          true,
        TMExecutionOutcome.boundedUnknown ||
        TMExecutionOutcome.cancelled =>
          false,
      };
}
