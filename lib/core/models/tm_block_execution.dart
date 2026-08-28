import 'dart:collection';

import '../messages/structured_message.dart';
import 'tm_building_blocks.dart';
import 'tm_execution_analysis.dart';
import 'tm_acceptance.dart';

enum TMBlockTraceAction { enterBlock, transition, returnFromBlock }

/// One compositional execution step with stable cross-machine provenance.
class TMBlockTraceStep {
  TMBlockTraceStep({
    required this.step,
    required this.action,
    required this.machineId,
    required this.stateId,
    required Iterable<TMBlockCallFrame> callStack,
    required Iterable<int> headPositions,
    required Iterable<Map<int, String>> tapes,
    this.transitionId,
    this.invocationNodeId,
    this.targetMachineId,
    this.structuredMessage,
  }) : callStack = List<TMBlockCallFrame>.unmodifiable(callStack),
       headPositions = List<int>.unmodifiable(headPositions),
       tapes = List<Map<int, String>>.unmodifiable(
         tapes.map((tape) => UnmodifiableMapView(Map<int, String>.from(tape))),
       );

  final int step;
  final TMBlockTraceAction action;
  final String machineId;
  final String stateId;
  final String? transitionId;
  final String? invocationNodeId;
  final String? targetMachineId;

  /// Locale-neutral semantic payload for this trace label, when available.
  final StructuredMessage? structuredMessage;
  final List<TMBlockCallFrame> callStack;
  final List<int> headPositions;
  final List<Map<int, String>> tapes;

  Map<String, Object?> toJson() => {
    'step': step,
    'action': action.name,
    'machineId': machineId,
    'stateId': stateId,
    if (transitionId != null) 'transitionId': transitionId,
    if (invocationNodeId != null) 'invocationNodeId': invocationNodeId,
    if (targetMachineId != null) 'targetMachineId': targetMachineId,
    if (structuredMessage != null)
      'structuredMessage': structuredMessage!.toJson(),
    'callStack': callStack.map((frame) => frame.toJson()).toList(),
    'headPositions': headPositions,
    'tapes': tapes
        .map(
          (tape) => [
            for (final entry
                in tape.entries.toList()
                  ..sort((a, b) => a.key.compareTo(b.key)))
              {'position': entry.key, 'symbol': entry.value},
          ],
        )
        .toList(),
  };
}

/// Time and space accounting across parent and nested submachines.
class TMBlockExecutionMetrics {
  const TMBlockExecutionMetrics({
    required this.transitionSteps,
    required this.blockEntries,
    required this.blockReturns,
    required this.maximumCallDepth,
    required this.maximumTotalNonBlankCells,
  });

  final int transitionSteps;
  final int blockEntries;
  final int blockReturns;
  final int maximumCallDepth;
  final int maximumTotalNonBlankCells;

  int get totalSteps => transitionSteps + blockEntries + blockReturns;
}

/// Result of bounded deterministic or nondeterministic compositional execution.
class TMBlockExecutionResult {
  TMBlockExecutionResult({
    required this.outcome,
    required this.message,
    required this.stepsExecuted,
    required this.configurationsExplored,
    required this.metrics,
    required Iterable<Map<int, String>> finalTapes,
    required Iterable<int> finalHeadPositions,
    required Iterable<TMBlockCallFrame> finalCallStack,
    Iterable<TMBlockTraceStep> trace = const [],
    Iterable<TMBlockDiagnostic> diagnostics = const [],
    this.limit,
    this.structuredMessage,
    required this.acceptancePolicy,
    required this.acceptanceReason,
  }) : finalTapes = List<Map<int, String>>.unmodifiable(
         finalTapes.map(
           (tape) => UnmodifiableMapView(Map<int, String>.from(tape)),
         ),
       ),
       finalHeadPositions = List<int>.unmodifiable(finalHeadPositions),
       finalCallStack = List<TMBlockCallFrame>.unmodifiable(finalCallStack),
       trace = List<TMBlockTraceStep>.unmodifiable(trace),
       diagnostics = List<TMBlockDiagnostic>.unmodifiable(diagnostics);

  final TMExecutionOutcome outcome;
  final TMExecutionLimit? limit;
  final String message;
  final int stepsExecuted;
  final int configurationsExplored;
  final TMBlockExecutionMetrics metrics;
  final List<Map<int, String>> finalTapes;
  final List<int> finalHeadPositions;
  final List<TMBlockCallFrame> finalCallStack;
  final List<TMBlockTraceStep> trace;
  final List<TMBlockDiagnostic> diagnostics;

  /// Locale-neutral semantic payload for [message], when available.
  final StructuredMessage? structuredMessage;
  final TMAcceptancePolicy acceptancePolicy;
  final TMAcceptanceReason acceptanceReason;
}
