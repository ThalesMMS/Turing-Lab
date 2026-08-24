import 'dart:async';
import 'dart:collection';

import '../models/simulation_step.dart';
import '../models/state.dart';
import '../models/tm.dart';
import '../models/tm_execution_analysis.dart';
import 'tm_execution_kernel.dart';

typedef TMExecutionProgressCallback = void Function(
    int transitionSteps, int configurationsExplored);

/// Executes one TM/input pair without making global halting claims.
class TMExecutionAnalyzer {
  const TMExecutionAnalyzer._();

  static Future<TMExecutionAnalysis> analyze(
    TM tm,
    String input, {
    int maxSteps = 10000,
    int maxConfigurations = 100000,
    Duration timeout = const Duration(seconds: 5),
    int operationsPerBatch = 250,
    bool includeTrace = true,
    bool Function()? isCancelled,
    TMExecutionProgressCallback? onProgress,
  }) async {
    final invalid = _validate(
      tm,
      input,
      maxSteps: maxSteps,
      maxConfigurations: maxConfigurations,
      timeout: timeout,
      operationsPerBatch: operationsPerBatch,
    );
    if (invalid != null) return invalid;

    final search = tm.isNondeterministic
        ? _NtmExecutionSearch(
            tm,
            input,
            maxSteps: maxSteps,
            maxConfigurations: maxConfigurations,
            timeout: timeout,
            includeTrace: includeTrace,
          )
        : _DtmExecutionSearch(
            tm,
            input,
            maxSteps: maxSteps,
            maxConfigurations: maxConfigurations,
            timeout: timeout,
            includeTrace: includeTrace,
          );

    while (true) {
      if (isCancelled?.call() == true) return search.cancelled();
      final result = search.runBatch(operationsPerBatch);
      onProgress?.call(search.stepsExecuted, search.configurationsExplored);
      if (result != null) return result;
      await Future<void>.delayed(Duration.zero);
    }
  }

  static TMExecutionAnalysis? _validate(
    TM tm,
    String input, {
    required int maxSteps,
    required int maxConfigurations,
    required Duration timeout,
    required int operationsPerBatch,
  }) {
    String? message;
    if (tm.states.isEmpty) {
      message = 'Turing machine must have at least one state.';
    } else if (tm.initialState == null ||
        !tm.states.contains(tm.initialState)) {
      message = 'Turing machine must define a valid initial state.';
    } else if (maxSteps <= 0) {
      message = 'Step limit must be greater than zero.';
    } else if (maxConfigurations <= 0) {
      message = 'Configuration limit must be greater than zero.';
    } else if (timeout <= Duration.zero) {
      message = 'Timeout must be greater than zero.';
    } else if (operationsPerBatch <= 0) {
      message = 'Operations per batch must be greater than zero.';
    } else {
      for (final symbol in input.split('')) {
        if (!tm.alphabet.contains(symbol)) {
          message = 'Input contains symbol outside the TM alphabet: $symbol';
          break;
        }
      }
    }
    if (message == null) return null;
    return TMExecutionAnalysis(
      input: input,
      outcome: TMExecutionOutcome.invalidMachine,
      message: message,
      stepsExecuted: 0,
      configurationsExplored: 0,
      maxSteps: maxSteps,
      maxConfigurations: maxConfigurations,
      timeout: timeout,
      executionTime: Duration.zero,
    );
  }
}

abstract class _ExecutionSearch {
  _ExecutionSearch(
    this.tm,
    this.input, {
    required this.maxSteps,
    required this.maxConfigurations,
    required this.timeout,
    required this.includeTrace,
  }) : stopwatch = Stopwatch()..start();

  final TM tm;
  final String input;
  final int maxSteps;
  final int maxConfigurations;
  final Duration timeout;
  final bool includeTrace;
  final Stopwatch stopwatch;

  TMExecutionAnalysis? runBatch(int operations);

  int get stepsExecuted;
  int get configurationsExplored;
  List<SimulationStep> get trace;
  int get repeatedConfigurationsObserved;
  TMTraceMetrics buildTraceMetrics(TMExecutionOutcome outcome);
  TMExecutionSpaceMetrics buildSpaceMetrics();

  TMExecutionAnalysis cancelled() =>
      _result(TMExecutionOutcome.cancelled, 'Analysis cancelled.');

  TMExecutionAnalysis _result(
    TMExecutionOutcome outcome,
    String message, {
    TMExecutionLimit? limit,
    TMCycleWitness? cycle,
  }) {
    stopwatch.stop();
    return TMExecutionAnalysis(
      input: input,
      outcome: outcome,
      message: message,
      stepsExecuted: stepsExecuted,
      configurationsExplored: configurationsExplored,
      maxSteps: maxSteps,
      maxConfigurations: maxConfigurations,
      timeout: timeout,
      executionTime: stopwatch.elapsed,
      limit: limit,
      cycle: cycle,
      repeatedConfigurationsObserved: repeatedConfigurationsObserved,
      trace: trace,
      traceMetrics: buildTraceMetrics(outcome),
      spaceMetrics: buildSpaceMetrics(),
    );
  }

  TMExecutionAnalysis? resourceLimit() {
    if (stopwatch.elapsed >= timeout) {
      return _result(
        TMExecutionOutcome.boundedUnknown,
        'The timeout was reached before the execution was resolved.',
        limit: TMExecutionLimit.timeout,
      );
    }
    return null;
  }
}

class _DtmExecutionSearch extends _ExecutionSearch {
  _DtmExecutionSearch(
    super.tm,
    super.input, {
    required super.maxSteps,
    required super.maxConfigurations,
    required super.timeout,
    required super.includeTrace,
  })  : state = tm.initialState!,
        tape = TMExecutionKernel.initialTape(input, tm.blankSymbol) {
    metrics = TMTraceMetricsAccumulator(
      blankSymbol: tm.blankSymbol,
      initialTape: tape,
    );
    _tapeKey = _canonicalTapeKey(tape);
    firstSeenAt[configurationKey] = 0;
    if (includeTrace) {
      _trace.add(
        SimulationStep.tm(
          currentState: state.id,
          remainingInput: input,
          tapeContents: input,
          stepNumber: 0,
          headPosition: 0,
        ),
      );
    }
  }

  State state;
  final Map<int, String> tape;
  late final TMTraceMetricsAccumulator metrics;
  int head = 0;
  int _stepsExecuted = 0;
  late String _tapeKey;
  final Map<String, int> firstSeenAt = {};
  final List<SimulationStep> _trace = [];

  static String _canonicalTapeKey(Map<int, String> tape) {
    final entries = tape.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return entries
        .map((entry) => '${entry.key}:${entry.value.length}:${entry.value}')
        .join('|');
  }

  String get configurationKey =>
      '${state.id.length}:${state.id}|$head|$_tapeKey';

  TMConfigurationSnapshot get snapshot => TMExecutionKernel.snapshot(
        stateId: state.id,
        headPosition: head,
        tape: tape,
        blankSymbol: tm.blankSymbol,
      );

  @override
  int get stepsExecuted => _stepsExecuted;

  @override
  int get configurationsExplored => firstSeenAt.length;

  @override
  List<SimulationStep> get trace => _trace;

  @override
  int get repeatedConfigurationsObserved => 0;

  @override
  TMTraceMetrics buildTraceMetrics(TMExecutionOutcome outcome) =>
      metrics.finish(
        tm: tm,
        branchSelection: TMExecutionBranchSelection.deterministic,
        retainedTraceSnapshots: _trace.length,
      );

  @override
  TMExecutionSpaceMetrics buildSpaceMetrics() => TMExecutionSpaceMetrics(
        maximumVisitedSpan: metrics.visitedSpan,
        maximumNonBlankCells: metrics.maximumSimultaneousNonBlankCells,
        aggregatesNondeterministicBranches: false,
      );

  @override
  TMExecutionAnalysis? runBatch(int operations) {
    for (var operation = 0; operation < operations; operation++) {
      final limit = resourceLimit();
      if (limit != null) return limit;
      if (tm.acceptingStates.contains(state)) {
        return _result(
          TMExecutionOutcome.accepted,
          'The machine entered an accepting state.',
        );
      }
      final readSymbol = tape[head] ?? tm.blankSymbol;
      final transitions = TMExecutionKernel.transitionsFor(
        tm,
        state,
        readSymbol,
      );
      if (transitions.isEmpty) {
        return _result(
          TMExecutionOutcome.haltedRejected,
          'The machine halted outside an accepting state.',
        );
      }
      if (transitions.length > 1) {
        return _result(
          TMExecutionOutcome.invalidMachine,
          'The deterministic machine has multiple transitions for '
          '${state.id} on $readSymbol.',
        );
      }
      if (_stepsExecuted >= maxSteps) {
        return _result(
          TMExecutionOutcome.boundedUnknown,
          'The step limit was reached without a halting or repeated configuration.',
          limit: TMExecutionLimit.steps,
        );
      }

      final transition = transitions.single;
      final previousState = state;
      final previousSymbol = tape[head] ?? tm.blankSymbol;
      final previousHead = head;
      TMExecutionKernel.write(
        tape,
        head,
        transition.writeSymbol,
        tm.blankSymbol,
      );
      if (previousSymbol != transition.writeSymbol) {
        _tapeKey = _canonicalTapeKey(tape);
      }
      head = TMExecutionKernel.moveHead(head, transition.direction);
      metrics.record(
        transition: transition,
        oldSymbol: previousSymbol,
        headBefore: previousHead,
        headAfter: head,
        step: _stepsExecuted + 1,
      );
      state = transition.toState;
      _stepsExecuted++;
      if (includeTrace) {
        _trace.add(
          TMExecutionKernel.simulationStep(
            fromState: previousState,
            transition: transition,
            readSymbol: readSymbol,
            tape: tape,
            step: _stepsExecuted,
            head: head,
          ),
        );
      }

      final firstStep = firstSeenAt[configurationKey];
      if (firstStep != null) {
        final current = snapshot;
        return _result(
          TMExecutionOutcome.provenCycle,
          'A deterministic configuration repeated.',
          cycle: TMCycleWitness(
            startStep: firstStep,
            period: _stepsExecuted - firstStep,
            configuration: current,
          ),
        );
      }
      if (firstSeenAt.length >= maxConfigurations) {
        return _result(
          TMExecutionOutcome.boundedUnknown,
          'The configuration limit was reached without a resolved outcome.',
          limit: TMExecutionLimit.configurations,
        );
      }
      firstSeenAt[configurationKey] = _stepsExecuted;
    }
    return null;
  }
}

class _NtmNode {
  _NtmNode({
    required this.state,
    required this.tape,
    required this.head,
    required this.depth,
    required this.trace,
    required this.metrics,
  });

  final State state;
  final Map<int, String> tape;
  final int head;
  final int depth;
  final List<SimulationStep> trace;
  final TMTraceMetricsAccumulator metrics;
}

class _NtmExecutionSearch extends _ExecutionSearch {
  _NtmExecutionSearch(
    super.tm,
    super.input, {
    required super.maxSteps,
    required super.maxConfigurations,
    required super.timeout,
    required super.includeTrace,
  }) {
    final tape = TMExecutionKernel.initialTape(input, tm.blankSymbol);
    final initialTrace = includeTrace
        ? [
            SimulationStep.tm(
              currentState: tm.initialState!.id,
              remainingInput: input,
              tapeContents: input,
              stepNumber: 0,
              headPosition: 0,
            ),
          ]
        : <SimulationStep>[];
    final node = _NtmNode(
      state: tm.initialState!,
      tape: tape,
      head: 0,
      depth: 0,
      trace: initialTrace,
      metrics: TMTraceMetricsAccumulator(
        blankSymbol: tm.blankSymbol,
        initialTape: tape,
      ),
    );
    queue.add(node);
    seen.add(_snapshot(node).key);
    selectedNode = node;
    _observeSpace(node.metrics);
  }

  final Queue<_NtmNode> queue = Queue();
  final Set<String> seen = {};
  List<SimulationStep> longestTrace = [];
  int explored = 0;
  int maxDepth = 0;
  int revisited = 0;
  bool truncatedBySteps = false;
  late _NtmNode selectedNode;
  _NtmNode? deepestHaltedNode;
  _NtmNode? cyclicNode;
  TMExecutionBranchSelection selection =
      TMExecutionBranchSelection.longestBoundedBranch;
  int maximumVisitedSpan = 1;
  int maximumNonBlankCells = 0;

  void _observeSpace(TMTraceMetricsAccumulator metrics) {
    if (metrics.visitedSpan > maximumVisitedSpan) {
      maximumVisitedSpan = metrics.visitedSpan;
    }
    if (metrics.maximumSimultaneousNonBlankCells > maximumNonBlankCells) {
      maximumNonBlankCells = metrics.maximumSimultaneousNonBlankCells;
    }
  }

  TMConfigurationSnapshot _snapshot(_NtmNode node) =>
      TMExecutionKernel.snapshot(
        stateId: node.state.id,
        headPosition: node.head,
        tape: node.tape,
        blankSymbol: tm.blankSymbol,
      );

  @override
  int get stepsExecuted => maxDepth;

  @override
  int get configurationsExplored => explored;

  @override
  List<SimulationStep> get trace => selectedNode.trace;

  @override
  int get repeatedConfigurationsObserved => revisited;

  @override
  TMTraceMetrics buildTraceMetrics(TMExecutionOutcome outcome) {
    final branchSelection = switch (outcome) {
      TMExecutionOutcome.accepted => TMExecutionBranchSelection.acceptingBranch,
      TMExecutionOutcome.boundedUnknown ||
      TMExecutionOutcome.cancelled =>
        TMExecutionBranchSelection.longestBoundedBranch,
      _ => selection,
    };
    return selectedNode.metrics.finish(
      tm: tm,
      branchSelection: branchSelection,
      retainedTraceSnapshots: selectedNode.trace.length,
    );
  }

  @override
  TMExecutionSpaceMetrics buildSpaceMetrics() => TMExecutionSpaceMetrics(
        maximumVisitedSpan: maximumVisitedSpan,
        maximumNonBlankCells: maximumNonBlankCells,
        aggregatesNondeterministicBranches: true,
      );

  @override
  TMExecutionAnalysis? runBatch(int operations) {
    for (var operation = 0; operation < operations; operation++) {
      final limit = resourceLimit();
      if (limit != null) return limit;
      if (queue.isEmpty) {
        if (truncatedBySteps) {
          return _result(
            TMExecutionOutcome.boundedUnknown,
            'At least one branch reached the step limit.',
            limit: TMExecutionLimit.steps,
          );
        }
        if (deepestHaltedNode != null) {
          selectedNode = deepestHaltedNode!;
          selection = TMExecutionBranchSelection.rejectingBranch;
        } else if (cyclicNode != null) {
          selectedNode = cyclicNode!;
          selection = TMExecutionBranchSelection.cyclicBranch;
        }
        return _result(
          TMExecutionOutcome.haltedRejected,
          revisited == 0
              ? 'Every reachable branch halted without acceptance.'
              : 'The finite explored configuration graph contains no accepting configuration.',
        );
      }
      if (explored >= maxConfigurations) {
        return _result(
          TMExecutionOutcome.boundedUnknown,
          'The configuration limit stopped exploration.',
          limit: TMExecutionLimit.configurations,
        );
      }

      final node = queue.removeFirst();
      explored++;
      _observeSpace(node.metrics);
      if (node.depth > selectedNode.depth) selectedNode = node;
      if (node.trace.length > longestTrace.length) longestTrace = node.trace;
      if (node.depth > maxDepth) maxDepth = node.depth;
      if (tm.acceptingStates.contains(node.state)) {
        selectedNode = node;
        selection = TMExecutionBranchSelection.acceptingBranch;
        longestTrace = node.trace;
        return _result(
          TMExecutionOutcome.accepted,
          'An accepting branch was found.',
        );
      }

      final readSymbol = node.tape[node.head] ?? tm.blankSymbol;
      final transitions = TMExecutionKernel.transitionsFor(
        tm,
        node.state,
        readSymbol,
      );
      if (transitions.isEmpty &&
          (deepestHaltedNode == null ||
              node.depth > deepestHaltedNode!.depth)) {
        deepestHaltedNode = node;
      }
      for (final transition in transitions) {
        if (node.depth >= maxSteps) {
          truncatedBySteps = true;
          continue;
        }
        final nextTape = Map<int, String>.from(node.tape);
        TMExecutionKernel.write(
          nextTape,
          node.head,
          transition.writeSymbol,
          tm.blankSymbol,
        );
        final nextHead = TMExecutionKernel.moveHead(
          node.head,
          transition.direction,
        );
        final nextMetrics = node.metrics.copy()
          ..record(
            transition: transition,
            oldSymbol: readSymbol,
            headBefore: node.head,
            headAfter: nextHead,
            step: node.depth + 1,
          );
        final nextTrace = includeTrace
            ? [
                ...node.trace,
                TMExecutionKernel.simulationStep(
                  fromState: node.state,
                  transition: transition,
                  readSymbol: readSymbol,
                  tape: nextTape,
                  step: node.depth + 1,
                  head: nextHead,
                ),
              ]
            : node.trace;
        final next = _NtmNode(
          state: transition.toState,
          tape: nextTape,
          head: nextHead,
          depth: node.depth + 1,
          trace: nextTrace,
          metrics: nextMetrics,
        );
        final key = _snapshot(next).key;
        if (seen.add(key)) {
          queue.add(next);
          if (next.depth > selectedNode.depth) selectedNode = next;
        } else {
          revisited++;
          if (cyclicNode == null || next.depth > cyclicNode!.depth) {
            cyclicNode = next;
          }
        }
      }
    }
    return null;
  }
}
