import 'dart:collection';
import 'dart:convert';

import '../messages/structured_message.dart';
import '../models/state.dart';
import '../models/tm.dart';
import '../models/tm_acceptance.dart';
import '../models/tm_block_execution.dart';
import '../models/tm_building_blocks.dart';
import '../models/tm_execution_analysis.dart';
import 'tm_block_dependency_analyzer.dart';
import 'tm_building_block_messages.dart';
import 'tm_execution_kernel.dart';

/// Bounded compositional TM executor with an explicit, canonical call stack.
class TMBlockExecutionEngine {
  const TMBlockExecutionEngine._();

  static TMBlockExecutionResult execute(
    TMBlockProject project,
    String input, {
    int maxSteps = 10000,
    int maxConfigurations = 50000,
    Duration timeout = const Duration(seconds: 5),
    bool includeTrace = true,
    bool Function()? isCancelled,
  }) {
    if (maxSteps < 1 || maxConfigurations < 1) {
      throw ArgumentError('Execution bounds must be positive.');
    }
    final dependencyReport = TMBlockDependencyAnalyzer.analyze(project);
    final diagnostics = [...dependencyReport.diagnostics];
    if (project.rootMachine.initialState == null) {
      diagnostics.add(
        TMBlockDiagnostic(
          code: TMBlockDiagnosticCode.missingInitialState,
          severity: TMBlockDiagnosticSeverity.error,
          message: 'The root machine has no initial state.',
          machineId: project.rootMachine.id,
          structuredMessage: TmBuildingBlockMessages.missingRootInitialState(),
        ),
      );
    }
    if (diagnostics.any(
      (diagnostic) => diagnostic.severity == TMBlockDiagnosticSeverity.error,
    )) {
      return _invalidResult(project, diagnostics);
    }

    final root = project.rootMachine;
    final tapes = TMExecutionKernel.initialTapes(
      input,
      root.blankSymbol,
      root.tapeCount,
    );
    final initial = _Configuration(
      machineId: root.id,
      stateId: root.initialState!.id,
      tapes: tapes,
      heads: List<int>.filled(root.tapeCount, 0),
      callStack: const [],
      trace: const [],
      transitionSteps: 0,
      blockEntries: 0,
      blockReturns: 0,
      maximumCallDepth: 0,
      maximumTotalNonBlankCells: _nonBlankCount(tapes),
    );
    final queue = Queue<_Configuration>()..add(initial);
    final visited = <String>{initial.key(root.blankSymbol)};
    final stopwatch = Stopwatch()..start();
    var explored = 0;
    var repeated = 0;
    var truncatedBySteps = false;
    var deepest = initial;
    _Configuration? deepestHalted;

    TMBlockExecutionResult finish(
      TMExecutionOutcome outcome,
      String message,
      _Configuration selected, {
      required StructuredMessage structuredMessage,
      TMExecutionLimit? limit,
      TMAcceptanceReason? acceptanceReason,
    }) {
      stopwatch.stop();
      return _result(
        outcome: outcome,
        message: message,
        selected: selected,
        explored: explored,
        limit: limit,
        acceptancePolicy: root.acceptancePolicy,
        acceptanceReason: acceptanceReason,
        structuredMessage: structuredMessage,
      );
    }

    while (queue.isNotEmpty) {
      if (isCancelled?.call() ?? false) {
        return finish(
          TMExecutionOutcome.cancelled,
          'Nested execution was cancelled.',
          deepest,
          structuredMessage: TmBuildingBlockMessages.cancelled(),
        );
      }
      if (stopwatch.elapsed >= timeout) {
        return finish(
          TMExecutionOutcome.boundedUnknown,
          'The timeout stopped nested execution.',
          deepest,
          structuredMessage: TmBuildingBlockMessages.timeout(),
          limit: TMExecutionLimit.timeout,
        );
      }
      if (explored >= maxConfigurations) {
        return finish(
          TMExecutionOutcome.boundedUnknown,
          'The configuration limit stopped nested execution.',
          deepest,
          structuredMessage: TmBuildingBlockMessages.configurationLimit(),
          limit: TMExecutionLimit.configurations,
        );
      }

      final current = queue.removeFirst();
      explored++;
      if (current.totalSteps > deepest.totalSteps) deepest = current;
      final machine = project.machineFor(current.machineId)!;
      final state = _stateById(machine, current.stateId)!;

      if (current.callStack.isEmpty &&
          machine.acceptingStates.contains(state)) {
        final decision = TMAcceptancePolicyEvaluator.evaluate(
          policy: root.acceptancePolicy,
          isFinalState: true,
          isHalted: false,
        );
        if (decision != null) {
          return finish(
            TMExecutionOutcome.accepted,
            'The root machine entered a final state under the ${root.acceptancePolicy.name} policy.',
            current,
            structuredMessage: TmBuildingBlockMessages.enteredFinalState(
              root.acceptancePolicy.name,
            ),
            acceptanceReason: decision.reason,
          );
        }
      }

      final invocation = project.invocationForState(
        current.machineId,
        current.stateId,
      );
      if (invocation != null &&
          current.resumedInvocationNodeId != invocation.id) {
        if (current.totalSteps >= maxSteps) {
          truncatedBySteps = true;
          continue;
        }
        if (current.callStack.length >= project.maximumCallDepth) {
          return finish(
            TMExecutionOutcome.boundedUnknown,
            'The explicit call-depth limit stopped nested execution.',
            current,
            structuredMessage: TmBuildingBlockMessages.callDepthLimit(),
            limit: TMExecutionLimit.steps,
          );
        }
        final definition = project.definitions[invocation.reference.blockId]!;
        final frame = TMBlockCallFrame(
          parentMachineId: current.machineId,
          invocationNodeId: invocation.id,
          returnStateId: invocation.stateId,
        );
        final nextStack = [...current.callStack, frame];
        final next = current.next(
          machineId: definition.id,
          stateId: definition.machine.initialState!.id,
          callStack: nextStack,
          resumedInvocationNodeId: null,
          blockEntries: current.blockEntries + 1,
          maximumCallDepth: nextStack.length > current.maximumCallDepth
              ? nextStack.length
              : current.maximumCallDepth,
          traceStep: includeTrace
              ? _traceStep(
                  current: current,
                  action: TMBlockTraceAction.enterBlock,
                  machineId: current.machineId,
                  stateId: current.stateId,
                  invocationNodeId: invocation.id,
                  targetMachineId: definition.id,
                  callStack: nextStack,
                )
              : null,
        );
        _enqueue(next, root.blankSymbol, queue, visited, () => repeated++);
        continue;
      }

      final symbols = TMExecutionKernel.readVector(
        current.tapes,
        current.heads,
        machine.blankSymbol,
      );
      final transitions = TMExecutionKernel.transitionsForVector(
        machine,
        state,
        symbols,
      );
      if (transitions.isNotEmpty) {
        if (current.totalSteps >= maxSteps) {
          truncatedBySteps = true;
          continue;
        }
        for (final transition in transitions) {
          final applied = TMExecutionKernel.applyTransition(
            sourceTapes: current.tapes,
            sourceHeads: current.heads,
            transition: transition,
            blankSymbol: machine.blankSymbol,
          );
          final next = current.next(
            stateId: transition.toState.id,
            tapes: applied.tapes,
            heads: applied.heads,
            resumedInvocationNodeId: null,
            transitionSteps: current.transitionSteps + 1,
            maximumTotalNonBlankCells: _maximum(
              current.maximumTotalNonBlankCells,
              _nonBlankCount(applied.tapes),
            ),
            traceStep: includeTrace
                ? _traceStep(
                    current: current,
                    action: TMBlockTraceAction.transition,
                    machineId: current.machineId,
                    stateId: transition.toState.id,
                    transitionId: transition.id,
                    tapes: applied.tapes,
                    heads: applied.heads,
                  )
                : null,
          );
          _enqueue(next, root.blankSymbol, queue, visited, () => repeated++);
        }
        continue;
      }

      if (current.callStack.isEmpty) {
        final decision = TMAcceptancePolicyEvaluator.evaluate(
          policy: root.acceptancePolicy,
          isFinalState: machine.acceptingStates.contains(state),
          isHalted: true,
        )!;
        if (decision.accepted) {
          return finish(
            TMExecutionOutcome.accepted,
            'The root machine halted under the ${root.acceptancePolicy.name} policy.',
            current,
            structuredMessage: TmBuildingBlockMessages.haltedAccepted(
              root.acceptancePolicy.name,
            ),
            acceptanceReason: decision.reason,
          );
        }
      }

      if (current.callStack.isNotEmpty) {
        if (current.totalSteps >= maxSteps) {
          truncatedBySteps = true;
          continue;
        }
        final frame = current.callStack.last;
        final nextStack = current.callStack.sublist(
          0,
          current.callStack.length - 1,
        );
        final next = current.next(
          machineId: frame.parentMachineId,
          stateId: frame.returnStateId,
          callStack: nextStack,
          resumedInvocationNodeId: frame.invocationNodeId,
          blockReturns: current.blockReturns + 1,
          traceStep: includeTrace
              ? _traceStep(
                  current: current,
                  action: TMBlockTraceAction.returnFromBlock,
                  machineId: frame.parentMachineId,
                  stateId: frame.returnStateId,
                  invocationNodeId: frame.invocationNodeId,
                  targetMachineId: frame.parentMachineId,
                  callStack: nextStack,
                )
              : null,
        );
        _enqueue(next, root.blankSymbol, queue, visited, () => repeated++);
        continue;
      }

      if (deepestHalted == null ||
          current.totalSteps > deepestHalted.totalSteps) {
        deepestHalted = current;
      }
    }

    if (truncatedBySteps) {
      return finish(
        TMExecutionOutcome.boundedUnknown,
        'The step limit stopped nested execution.',
        deepest,
        structuredMessage: TmBuildingBlockMessages.stepLimit(),
        limit: TMExecutionLimit.steps,
        acceptanceReason: TMAcceptanceReason.stepLimit,
      );
    }
    if (deepestHalted != null) {
      return finish(
        TMExecutionOutcome.haltedRejected,
        repeated == 0
            ? 'Every reachable branch halted without root acceptance.'
            : 'The finite nested configuration graph has no accepting configuration.',
        deepestHalted,
        structuredMessage: repeated == 0
            ? TmBuildingBlockMessages.haltedRejected()
            : TmBuildingBlockMessages.finiteGraphRejected(),
        acceptanceReason: TMAcceptanceReason.haltedOutsideFinalState,
      );
    }
    return finish(
      TMExecutionOutcome.provenCycle,
      'Every reachable branch repeats an exact nested configuration.',
      deepest,
      structuredMessage: TmBuildingBlockMessages.repeatedConfiguration(),
      acceptanceReason: TMAcceptanceReason.deterministicCycle,
    );
  }

  static TMBlockTraceStep _traceStep({
    required _Configuration current,
    required TMBlockTraceAction action,
    required String machineId,
    required String stateId,
    String? transitionId,
    String? invocationNodeId,
    String? targetMachineId,
    List<TMBlockCallFrame>? callStack,
    List<Map<int, String>>? tapes,
    List<int>? heads,
  }) {
    return TMBlockTraceStep(
      step: current.totalSteps + 1,
      action: action,
      machineId: machineId,
      stateId: stateId,
      transitionId: transitionId,
      invocationNodeId: invocationNodeId,
      targetMachineId: targetMachineId,
      structuredMessage: switch (action) {
        TMBlockTraceAction.enterBlock when targetMachineId != null =>
          TmBuildingBlockMessages.enterBlock(targetMachineId),
        TMBlockTraceAction.transition when transitionId != null =>
          TmBuildingBlockMessages.transition(transitionId),
        TMBlockTraceAction.returnFromBlock when targetMachineId != null =>
          TmBuildingBlockMessages.returnFromBlock(targetMachineId),
        _ => null,
      },
      callStack: callStack ?? current.callStack,
      headPositions: heads ?? current.heads,
      tapes: tapes ?? current.tapes,
    );
  }

  static void _enqueue(
    _Configuration configuration,
    String blankSymbol,
    Queue<_Configuration> queue,
    Set<String> visited,
    void Function() onRepeated,
  ) {
    if (visited.add(configuration.key(blankSymbol))) {
      queue.add(configuration);
    } else {
      onRepeated();
    }
  }

  static TMBlockExecutionResult _invalidResult(
    TMBlockProject project,
    List<TMBlockDiagnostic> diagnostics,
  ) {
    return TMBlockExecutionResult(
      outcome: TMExecutionOutcome.invalidMachine,
      message: 'The building-block project is invalid.',
      structuredMessage: TmBuildingBlockMessages.invalidProject(),
      stepsExecuted: 0,
      configurationsExplored: 0,
      metrics: const TMBlockExecutionMetrics(
        transitionSteps: 0,
        blockEntries: 0,
        blockReturns: 0,
        maximumCallDepth: 0,
        maximumTotalNonBlankCells: 0,
      ),
      finalTapes: List.generate(
        project.rootMachine.tapeCount,
        (_) => <int, String>{},
      ),
      finalHeadPositions: List<int>.filled(project.rootMachine.tapeCount, 0),
      finalCallStack: const [],
      diagnostics: diagnostics,
      acceptancePolicy: project.rootMachine.acceptancePolicy,
      acceptanceReason: TMAcceptanceReason.invalidMachine,
    );
  }

  static TMBlockExecutionResult _result({
    required TMExecutionOutcome outcome,
    required String message,
    required StructuredMessage structuredMessage,
    required _Configuration selected,
    required int explored,
    TMExecutionLimit? limit,
    required TMAcceptancePolicy acceptancePolicy,
    TMAcceptanceReason? acceptanceReason,
  }) {
    return TMBlockExecutionResult(
      outcome: outcome,
      limit: limit,
      message: message,
      structuredMessage: structuredMessage,
      stepsExecuted: selected.totalSteps,
      configurationsExplored: explored,
      metrics: TMBlockExecutionMetrics(
        transitionSteps: selected.transitionSteps,
        blockEntries: selected.blockEntries,
        blockReturns: selected.blockReturns,
        maximumCallDepth: selected.maximumCallDepth,
        maximumTotalNonBlankCells: selected.maximumTotalNonBlankCells,
      ),
      finalTapes: selected.tapes,
      finalHeadPositions: selected.heads,
      finalCallStack: selected.callStack,
      trace: selected.trace,
      acceptancePolicy: acceptancePolicy,
      acceptanceReason:
          acceptanceReason ??
          switch (outcome) {
            TMExecutionOutcome.accepted => TMAcceptanceReason.enteredFinalState,
            TMExecutionOutcome.haltedRejected =>
              TMAcceptanceReason.reachableConfigurationsExhausted,
            TMExecutionOutcome.provenCycle =>
              TMAcceptanceReason.deterministicCycle,
            TMExecutionOutcome.boundedUnknown => switch (limit) {
              TMExecutionLimit.timeout => TMAcceptanceReason.timeout,
              TMExecutionLimit.configurations =>
                TMAcceptanceReason.configurationLimit,
              TMExecutionLimit.steps || null => TMAcceptanceReason.stepLimit,
            },
            TMExecutionOutcome.cancelled => TMAcceptanceReason.cancelled,
            TMExecutionOutcome.invalidMachine =>
              TMAcceptanceReason.invalidMachine,
          },
    );
  }

  static State? _stateById(TM machine, String stateId) {
    for (final state in machine.states) {
      if (state.id == stateId) return state;
    }
    return null;
  }

  static int _nonBlankCount(List<Map<int, String>> tapes) =>
      tapes.fold(0, (total, tape) => total + tape.length);

  static int _maximum(int first, int second) => first > second ? first : second;
}

class _Configuration {
  _Configuration({
    required this.machineId,
    required this.stateId,
    required List<Map<int, String>> tapes,
    required List<int> heads,
    required List<TMBlockCallFrame> callStack,
    required List<TMBlockTraceStep> trace,
    required this.transitionSteps,
    required this.blockEntries,
    required this.blockReturns,
    required this.maximumCallDepth,
    required this.maximumTotalNonBlankCells,
    this.resumedInvocationNodeId,
  }) : tapes = tapes
           .map((tape) => Map<int, String>.from(tape))
           .toList(growable: false),
       heads = List<int>.of(heads, growable: false),
       callStack = List<TMBlockCallFrame>.unmodifiable(callStack),
       trace = List<TMBlockTraceStep>.unmodifiable(trace);

  final String machineId;
  final String stateId;
  final List<Map<int, String>> tapes;
  final List<int> heads;
  final List<TMBlockCallFrame> callStack;
  final String? resumedInvocationNodeId;
  final List<TMBlockTraceStep> trace;
  final int transitionSteps;
  final int blockEntries;
  final int blockReturns;
  final int maximumCallDepth;
  final int maximumTotalNonBlankCells;

  int get totalSteps => transitionSteps + blockEntries + blockReturns;

  _Configuration next({
    String? machineId,
    String? stateId,
    List<Map<int, String>>? tapes,
    List<int>? heads,
    List<TMBlockCallFrame>? callStack,
    Object? resumedInvocationNodeId = _notProvided,
    TMBlockTraceStep? traceStep,
    int? transitionSteps,
    int? blockEntries,
    int? blockReturns,
    int? maximumCallDepth,
    int? maximumTotalNonBlankCells,
  }) {
    return _Configuration(
      machineId: machineId ?? this.machineId,
      stateId: stateId ?? this.stateId,
      tapes: tapes ?? this.tapes,
      heads: heads ?? this.heads,
      callStack: callStack ?? this.callStack,
      resumedInvocationNodeId: identical(resumedInvocationNodeId, _notProvided)
          ? this.resumedInvocationNodeId
          : resumedInvocationNodeId as String?,
      trace: traceStep == null ? trace : [...trace, traceStep],
      transitionSteps: transitionSteps ?? this.transitionSteps,
      blockEntries: blockEntries ?? this.blockEntries,
      blockReturns: blockReturns ?? this.blockReturns,
      maximumCallDepth: maximumCallDepth ?? this.maximumCallDepth,
      maximumTotalNonBlankCells:
          maximumTotalNonBlankCells ?? this.maximumTotalNonBlankCells,
    );
  }

  String key(String blankSymbol) {
    return jsonEncode([
      machineId,
      stateId,
      resumedInvocationNodeId,
      for (final frame in callStack)
        [frame.parentMachineId, frame.invocationNodeId, frame.returnStateId],
      for (var tape = 0; tape < tapes.length; tape++)
        [
          heads[tape],
          for (final entry
              in tapes[tape].entries
                  .where((entry) => entry.value != blankSymbol)
                  .toList()
                ..sort((a, b) => a.key.compareTo(b.key)))
            [entry.key, entry.value],
        ],
    ]);
  }
}

const _notProvided = Object();
