import 'dart:collection';

import '../messages/structured_message.dart';
import '../models/state.dart';
import '../models/tm.dart';
import '../models/tm_acceptance.dart';
import '../models/tm_execution_analysis.dart';
import 'tm_multi_tape_messages.dart';
import 'tm_execution_kernel.dart';

/// Bounded BFS over the canonical k-tape configuration graph.
abstract final class TMMultiTapeExecutionAnalyzer {
  static Future<TMExecutionAnalysis> analyze(
    TM tm,
    String input, {
    required int maxSteps,
    required int maxConfigurations,
    required Duration timeout,
    required int operationsPerBatch,
    required bool includeTrace,
    bool Function()? isCancelled,
    void Function(int transitionSteps, int configurationsExplored)? onProgress,
  }) => analyzeTokens(
    tm,
    input,
    input.split(''),
    maxSteps: maxSteps,
    maxConfigurations: maxConfigurations,
    timeout: timeout,
    operationsPerBatch: operationsPerBatch,
    includeTrace: includeTrace,
    isCancelled: isCancelled,
    onProgress: onProgress,
  );

  static Future<TMExecutionAnalysis> analyzeTokens(
    TM tm,
    String input,
    List<String> inputTokens, {
    required int maxSteps,
    required int maxConfigurations,
    required Duration timeout,
    required int operationsPerBatch,
    required bool includeTrace,
    bool Function()? isCancelled,
    void Function(int transitionSteps, int configurationsExplored)? onProgress,
  }) async {
    final stopwatch = Stopwatch()..start();
    final initialTapes = TMExecutionKernel.initialTapesTokens(
      inputTokens,
      tm.blankSymbol,
      tm.tapeCount,
    );
    final initialHeads = List<int>.filled(tm.tapeCount, 0);
    final initial = _Node(
      state: tm.initialState!,
      tapes: initialTapes,
      heads: initialHeads,
      depth: 0,
      trace: const [],
    );
    final queue = Queue<_Node>()..add(initial);
    final initialSnapshot = _snapshot(tm, initial);
    final seenAt = <String, int>{initialSnapshot.key: 0};
    final metrics = _Metrics(tm.tapeCount)..observe(initial);
    var explored = 0;
    var maxDepth = 0;
    var repeated = 0;
    var truncatedBySteps = false;
    var haltedOutsideFinalState = false;
    _Node selected = initial;

    TMExecutionAnalysis result(
      TMExecutionOutcome outcome,
      String message, {
      required StructuredMessage structuredMessage,
      TMExecutionLimit? limit,
      TMCycleWitness? cycle,
      TMAcceptanceReason? acceptanceReason,
    }) {
      stopwatch.stop();
      return TMExecutionAnalysis(
        input: input,
        outcome: outcome,
        message: message,
        stepsExecuted: maxDepth,
        configurationsExplored: explored,
        maxSteps: maxSteps,
        maxConfigurations: maxConfigurations,
        timeout: timeout,
        executionTime: stopwatch.elapsed,
        limit: limit,
        cycle: cycle,
        repeatedConfigurationsObserved: repeated,
        multiTapeTrace: selected.trace,
        multiTapeMetrics: metrics.finish(),
        acceptancePolicy: tm.acceptancePolicy,
        acceptanceReason: acceptanceReason,
        structuredMessage: structuredMessage,
      );
    }

    while (queue.isNotEmpty) {
      for (var operation = 0; operation < operationsPerBatch; operation++) {
        if (isCancelled?.call() == true) {
          return result(
            TMExecutionOutcome.cancelled,
            'Analysis cancelled.',
            structuredMessage: TmMultiTapeMessages.cancelled(),
          );
        }
        if (stopwatch.elapsed >= timeout) {
          return result(
            TMExecutionOutcome.boundedUnknown,
            'The timeout was reached before the execution was resolved.',
            structuredMessage: TmMultiTapeMessages.timeout(),
            limit: TMExecutionLimit.timeout,
          );
        }
        if (queue.isEmpty) break;
        if (explored >= maxConfigurations) {
          return result(
            TMExecutionOutcome.boundedUnknown,
            'The configuration limit stopped exploration.',
            structuredMessage: TmMultiTapeMessages.configurationLimit(),
            limit: TMExecutionLimit.configurations,
          );
        }

        final node = queue.removeFirst();
        selected = node;
        explored++;
        metrics.observe(node);
        if (node.depth > maxDepth) maxDepth = node.depth;
        if (tm.acceptingStates.contains(node.state)) {
          final decision = TMAcceptancePolicyEvaluator.evaluate(
            policy: tm.acceptancePolicy,
            isFinalState: true,
            isHalted: false,
          );
          if (decision != null) {
            return result(
              TMExecutionOutcome.accepted,
              tm.isDeterministic
                  ? 'The machine entered a final state under the ${tm.acceptancePolicy.name} policy.'
                  : 'A branch entered a final state under the ${tm.acceptancePolicy.name} policy.',
              structuredMessage: tm.isDeterministic
                  ? TmMultiTapeMessages.enteredFinalState(
                      tm.acceptancePolicy.name,
                    )
                  : TmMultiTapeMessages.branchEnteredFinalState(
                      tm.acceptancePolicy.name,
                    ),
              acceptanceReason: decision.reason,
            );
          }
        }

        final reads = TMExecutionKernel.readVector(
          node.tapes,
          node.heads,
          tm.blankSymbol,
        );
        final transitions = TMExecutionKernel.transitionsForVector(
          tm,
          node.state,
          reads,
        );
        if (transitions.isEmpty) {
          final decision = TMAcceptancePolicyEvaluator.evaluate(
            policy: tm.acceptancePolicy,
            isFinalState: tm.acceptingStates.contains(node.state),
            isHalted: true,
          )!;
          if (decision.accepted) {
            return result(
              TMExecutionOutcome.accepted,
              tm.isDeterministic
                  ? 'The machine halted under the ${tm.acceptancePolicy.name} policy.'
                  : 'A branch halted under the ${tm.acceptancePolicy.name} policy.',
              structuredMessage: tm.isDeterministic
                  ? TmMultiTapeMessages.haltedAccepted(tm.acceptancePolicy.name)
                  : TmMultiTapeMessages.branchHaltedAccepted(
                      tm.acceptancePolicy.name,
                    ),
              acceptanceReason: decision.reason,
            );
          }
          haltedOutsideFinalState =
              decision.reason == TMAcceptanceReason.haltedOutsideFinalState;
          continue;
        }
        if (tm.isDeterministic && transitions.length > 1) {
          return result(
            TMExecutionOutcome.invalidMachine,
            'The deterministic machine has multiple transitions for the same read vector.',
            structuredMessage: TmMultiTapeMessages.deterministicConflict(),
          );
        }
        if (node.depth >= maxSteps) {
          truncatedBySteps = true;
          continue;
        }

        for (final transition in transitions) {
          final operations = transition.operationsForTapeCount(
            tm.tapeCount,
            tm.blankSymbol,
          );
          final applied = TMExecutionKernel.applyTransition(
            sourceTapes: node.tapes,
            sourceHeads: node.heads,
            transition: transition,
            blankSymbol: tm.blankSymbol,
          );
          final snapshot = TMExecutionKernel.snapshotMulti(
            stateId: transition.toState.id,
            headPositions: applied.heads,
            tapes: applied.tapes,
            blankSymbol: tm.blankSymbol,
          );
          final trace = includeTrace
              ? <TMMultiTapeTraceStep>[
                  ...node.trace,
                  TMMultiTapeTraceStep(
                    step: node.depth + 1,
                    fromStateId: node.state.id,
                    toStateId: transition.toState.id,
                    transitionId: transition.id,
                    readSymbols: reads,
                    writeSymbols: operations.writeSymbols,
                    directions: operations.directions,
                    configuration: snapshot,
                  ),
                ]
              : const <TMMultiTapeTraceStep>[];
          final next = _Node(
            state: transition.toState,
            tapes: applied.tapes,
            heads: applied.heads,
            depth: node.depth + 1,
            trace: trace,
          );
          metrics.observe(next);
          final previousDepth = seenAt[snapshot.key];
          if (previousDepth != null) {
            repeated++;
            if (tm.isDeterministic) {
              selected = next;
              maxDepth = next.depth;
              return result(
                TMExecutionOutcome.provenCycle,
                'A deterministic multi-tape configuration repeated.',
                structuredMessage: TmMultiTapeMessages.deterministicCycle(),
                cycle: TMCycleWitness(
                  startStep: previousDepth,
                  period: next.depth - previousDepth,
                  configuration: snapshot,
                ),
                acceptanceReason: TMAcceptanceReason.deterministicCycle,
              );
            }
            continue;
          }
          seenAt[snapshot.key] = next.depth;
          queue.add(next);
        }
      }
      onProgress?.call(maxDepth, explored);
      await Future<void>.delayed(Duration.zero);
    }

    if (truncatedBySteps) {
      return result(
        TMExecutionOutcome.boundedUnknown,
        'At least one branch reached the step limit.',
        structuredMessage: TmMultiTapeMessages.stepLimit(),
        limit: TMExecutionLimit.steps,
        acceptanceReason: TMAcceptanceReason.stepLimit,
      );
    }
    return result(
      TMExecutionOutcome.haltedRejected,
      tm.isDeterministic
          ? 'The machine halted outside an accepting state.'
          : 'Every reachable branch halted without acceptance.',
      structuredMessage: tm.isDeterministic
          ? TmMultiTapeMessages.haltedRejected()
          : TmMultiTapeMessages.everyBranchRejected(),
      acceptanceReason: haltedOutsideFinalState
          ? TMAcceptanceReason.haltedOutsideFinalState
          : TMAcceptanceReason.reachableConfigurationsExhausted,
    );
  }

  static TMConfigurationSnapshot _snapshot(TM tm, _Node node) =>
      TMExecutionKernel.snapshotMulti(
        stateId: node.state.id,
        headPositions: node.heads,
        tapes: node.tapes,
        blankSymbol: tm.blankSymbol,
      );
}

final class _Node {
  const _Node({
    required this.state,
    required this.tapes,
    required this.heads,
    required this.depth,
    required this.trace,
  });

  final State state;
  final List<Map<int, String>> tapes;
  final List<int> heads;
  final int depth;
  final List<TMMultiTapeTraceStep> trace;
}

final class _Metrics {
  _Metrics(int tapeCount)
    : minimumHeads = List<int>.filled(tapeCount, 0),
      maximumHeads = List<int>.filled(tapeCount, 0),
      maximumNonBlank = List<int>.filled(tapeCount, 0);

  final List<int> minimumHeads;
  final List<int> maximumHeads;
  final List<int> maximumNonBlank;
  int maximumTotalNonBlank = 0;

  void observe(_Node node) {
    var total = 0;
    for (var tape = 0; tape < node.tapes.length; tape++) {
      final head = node.heads[tape];
      if (head < minimumHeads[tape]) minimumHeads[tape] = head;
      if (head > maximumHeads[tape]) maximumHeads[tape] = head;
      final nonBlank = node.tapes[tape].length;
      if (nonBlank > maximumNonBlank[tape]) {
        maximumNonBlank[tape] = nonBlank;
      }
      total += nonBlank;
    }
    if (total > maximumTotalNonBlank) maximumTotalNonBlank = total;
  }

  TMMultiTapeMetrics finish() => TMMultiTapeMetrics(
    maximumVisitedSpanByTape: List<int>.generate(
      minimumHeads.length,
      (index) => maximumHeads[index] - minimumHeads[index] + 1,
    ),
    maximumNonBlankCellsByTape: maximumNonBlank,
    maximumTotalNonBlankCells: maximumTotalNonBlank,
  );
}
