import 'dart:async';
import 'dart:collection';

import '../messages/structured_message.dart';
import '../models/state.dart';
import '../models/tm.dart';
import '../models/tm_execution_analysis.dart';
import '../models/tm_reachability_report.dart';
import '../models/tm_transition.dart';
import 'tm_execution_kernel.dart';
import 'tm_messages.dart';

typedef TMReachabilityProgressCallback =
    void Function(int transitionsExplored, int configurationsExplored);

/// Compares exact control-graph reachability with bounded concrete execution.
class TMReachabilityAnalyzer {
  const TMReachabilityAnalyzer._();

  static Future<TMReachabilityReport> analyze(
    TM tm, {
    required List<String> inputs,
    int maxSteps = 10000,
    int maxConfigurations = 100000,
    Duration timeout = const Duration(seconds: 5),
    int operationsPerBatch = 250,
    bool Function()? isCancelled,
    TMReachabilityProgressCallback? onProgress,
  }) async {
    final stopwatch = Stopwatch()..start();
    final scope = inputs.toSet().toList()..sort();
    final structural = _structuralReachability(tm);
    final invalidMessage = _validate(
      tm,
      scope,
      maxSteps: maxSteps,
      maxConfigurations: maxConfigurations,
      timeout: timeout,
      operationsPerBatch: operationsPerBatch,
    );
    if (invalidMessage != null) {
      stopwatch.stop();
      return _report(
        tm: tm,
        inputs: scope,
        structural: structural,
        status: TMReachabilityStatus.invalidMachine,
        message: invalidMessage.legacy,
        witnesses: const {},
        configurationsExplored: 0,
        transitionsExplored: 0,
        maxSteps: maxSteps,
        maxConfigurations: maxConfigurations,
        timeout: timeout,
        executionTime: stopwatch.elapsed,
        structuredMessage: invalidMessage.structured,
      );
    }

    final search = _SemanticReachabilitySearch(
      tm,
      scope,
      structural,
      maxSteps: maxSteps,
      maxConfigurations: maxConfigurations,
      timeout: timeout,
      stopwatch: stopwatch,
    );
    while (true) {
      if (isCancelled?.call() == true) {
        return search.finish(
          TMReachabilityStatus.cancelled,
          'Reachability analysis cancelled.',
          structuredMessage: TmReachabilityMessages.cancelled(),
        );
      }
      final result = search.runBatch(operationsPerBatch);
      onProgress?.call(
        search.transitionsExplored,
        search.configurationsExplored,
      );
      if (result != null) return result;
      await Future<void>.delayed(Duration.zero);
    }
  }

  static Set<String> structurallyReachableStateIds(TM tm) =>
      Set<String>.unmodifiable(_structuralReachability(tm));

  static Set<String> _structuralReachability(TM tm) {
    final initial = tm.initialState;
    if (initial == null || !tm.states.contains(initial)) return const {};
    final outgoing = <String, List<String>>{};
    final transitions = tm.tmTransitions.toList()
      ..sort((left, right) => left.id.compareTo(right.id));
    for (final transition in transitions) {
      outgoing
          .putIfAbsent(transition.fromState.id, () => <String>[])
          .add(transition.toState.id);
    }
    final reached = <String>{initial.id};
    final pending = Queue<String>()..add(initial.id);
    while (pending.isNotEmpty) {
      final stateId = pending.removeFirst();
      for (final nextId in outgoing[stateId] ?? const <String>[]) {
        if (reached.add(nextId)) pending.add(nextId);
      }
    }
    return reached;
  }

  static ({String legacy, StructuredMessage structured})? _validate(
    TM tm,
    List<String> inputs, {
    required int maxSteps,
    required int maxConfigurations,
    required Duration timeout,
    required int operationsPerBatch,
  }) {
    if (tm.states.isEmpty) {
      return (
        legacy: 'Turing machine must have at least one state.',
        structured: TmReachabilityMessages.emptyMachine(),
      );
    }
    if (tm.initialState == null || !tm.states.contains(tm.initialState)) {
      return (
        legacy: 'Turing machine must define a valid initial state.',
        structured: TmReachabilityMessages.invalidInitialState(),
      );
    }
    if (inputs.isEmpty) {
      return (
        legacy: 'At least one explicit input is required.',
        structured: TmReachabilityMessages.inputsRequired(),
      );
    }
    if (maxSteps <= 0) {
      return (
        legacy: 'Step limit must be greater than zero.',
        structured: TmReachabilityMessages.stepLimitInvalid(),
      );
    }
    if (maxConfigurations <= 0) {
      return (
        legacy: 'Configuration limit must be greater than zero.',
        structured: TmReachabilityMessages.configurationLimitInvalid(),
      );
    }
    if (timeout <= Duration.zero) {
      return (
        legacy: 'Timeout must be greater than zero.',
        structured: TmReachabilityMessages.timeoutInvalid(),
      );
    }
    if (operationsPerBatch <= 0) {
      return (
        legacy: 'Operations per batch must be greater than zero.',
        structured: TmReachabilityMessages.operationsPerBatchInvalid(),
      );
    }
    for (final transition in tm.transitions) {
      if (transition is! TMTransition) {
        return (
          legacy: 'Turing machine contains a non-TM transition.',
          structured: TmReachabilityMessages.nonTmTransition(),
        );
      }
      if (!tm.states.contains(transition.fromState) ||
          !tm.states.contains(transition.toState)) {
        return (
          legacy:
              'Transition ${transition.id} references a state outside the machine.',
          structured: TmReachabilityMessages.transitionEndpointOutsideSet(
            transition.id,
          ),
        );
      }
    }
    for (final input in inputs) {
      for (final symbol in input.split('')) {
        if (!tm.alphabet.contains(symbol)) {
          return (
            legacy:
                'Input "$input" contains symbol outside the TM alphabet: $symbol',
            structured: TmReachabilityMessages.inputSymbolOutsideAlphabet(
              input: input,
              symbol: symbol,
            ),
          );
        }
      }
    }
    return null;
  }

  static TMReachabilityReport _report({
    required TM tm,
    required List<String> inputs,
    required Set<String> structural,
    required TMReachabilityStatus status,
    required String message,
    required Map<String, TMReachabilityWitness> witnesses,
    required int configurationsExplored,
    required int transitionsExplored,
    required int maxSteps,
    required int maxConfigurations,
    required Duration timeout,
    required Duration executionTime,
    TMExecutionLimit? limit,
    StructuredMessage? structuredMessage,
  }) {
    final allStateIds = tm.states.map((state) => state.id).toSet();
    return TMReachabilityReport(
      inputs: inputs,
      status: status,
      message: message,
      structurallyReachableStateIds: structural,
      structurallyUnreachableStateIds: allStateIds.difference(structural),
      witnessesByStateId: witnesses,
      configurationsExplored: configurationsExplored,
      transitionsExplored: transitionsExplored,
      maxSteps: maxSteps,
      maxConfigurations: maxConfigurations,
      timeout: timeout,
      executionTime: executionTime,
      limit: limit,
      structuredMessage: structuredMessage,
    );
  }
}

class _ReachabilityNode {
  const _ReachabilityNode({
    required this.input,
    required this.inputIndex,
    required this.state,
    required this.tape,
    required this.head,
    required this.depth,
    required this.readSymbol,
    this.parent,
    this.incomingTransition,
  });

  final String input;
  final int inputIndex;
  final State state;
  final Map<int, String> tape;
  final int head;
  final int depth;
  final String readSymbol;
  final _ReachabilityNode? parent;
  final TMTransition? incomingTransition;

  String configurationKey(String blankSymbol) =>
      '$inputIndex\u0000${TMExecutionKernel.snapshot(stateId: state.id, headPosition: head, tape: tape, blankSymbol: blankSymbol).key}';

  TMReachabilityWitness witness() {
    final states = <String>[];
    final transitions = <String>[];
    _ReachabilityNode? cursor = this;
    while (cursor != null) {
      states.add(cursor.state.id);
      final incoming = cursor.incomingTransition;
      if (incoming != null) transitions.add(incoming.id);
      cursor = cursor.parent;
    }
    return TMReachabilityWitness(
      stateId: state.id,
      input: input,
      step: depth,
      headPosition: head,
      readSymbol: readSymbol,
      incomingTransitionId: incomingTransition?.id,
      stateIds: states.reversed.toList(growable: false),
      transitionIds: transitions.reversed.toList(growable: false),
    );
  }
}

class _SemanticReachabilitySearch {
  _SemanticReachabilitySearch(
    this.tm,
    this.inputs,
    this.structural, {
    required this.maxSteps,
    required this.maxConfigurations,
    required this.timeout,
    required this.stopwatch,
  }) {
    for (var index = 0; index < inputs.length; index++) {
      final input = inputs[index];
      final tape = TMExecutionKernel.initialTape(input, tm.blankSymbol);
      final readSymbol = tape[0] ?? tm.blankSymbol;
      final root = _ReachabilityNode(
        input: input,
        inputIndex: index,
        state: tm.initialState!,
        tape: tape,
        head: 0,
        depth: 0,
        readSymbol: readSymbol,
      );
      queue.add(root);
      seen.add(root.configurationKey(tm.blankSymbol));
      witnesses.putIfAbsent(root.state.id, root.witness);
      if (seen.length >= maxConfigurations && index < inputs.length - 1) {
        seedLimitReached = true;
        break;
      }
    }
  }

  final TM tm;
  final List<String> inputs;
  final Set<String> structural;
  final int maxSteps;
  final int maxConfigurations;
  final Duration timeout;
  final Stopwatch stopwatch;
  final Queue<_ReachabilityNode> queue = Queue();
  final Set<String> seen = {};
  final Map<String, TMReachabilityWitness> witnesses = {};
  var configurationsExplored = 0;
  var transitionsExplored = 0;
  var truncatedBySteps = false;
  var seedLimitReached = false;

  TMReachabilityReport? runBatch(int operations) {
    for (var operation = 0; operation < operations; operation++) {
      if (stopwatch.elapsed >= timeout) {
        return finish(
          TMReachabilityStatus.boundedIncomplete,
          'The timeout stopped semantic exploration.',
          limit: TMExecutionLimit.timeout,
          structuredMessage: TmReachabilityMessages.timeout(),
        );
      }
      if (seedLimitReached) {
        return finish(
          TMReachabilityStatus.boundedIncomplete,
          'The configuration limit stopped semantic exploration.',
          limit: TMExecutionLimit.configurations,
          structuredMessage: TmReachabilityMessages.configurationLimit(),
        );
      }
      if (queue.isEmpty) {
        if (truncatedBySteps) {
          return finish(
            TMReachabilityStatus.boundedIncomplete,
            'At least one execution branch reached the step limit.',
            limit: TMExecutionLimit.steps,
            structuredMessage: TmReachabilityMessages.stepLimit(),
          );
        }
        return finish(
          TMReachabilityStatus.complete,
          'All configurations reachable for the selected input scope were explored.',
          structuredMessage: TmReachabilityMessages.complete(),
        );
      }
      if (configurationsExplored >= maxConfigurations) {
        return finish(
          TMReachabilityStatus.boundedIncomplete,
          'The configuration limit stopped semantic exploration.',
          limit: TMExecutionLimit.configurations,
          structuredMessage: TmReachabilityMessages.configurationLimit(),
        );
      }

      final node = queue.removeFirst();
      configurationsExplored++;
      final transitions = TMExecutionKernel.transitionsFor(
        tm,
        node.state,
        node.readSymbol,
      );
      if (node.depth >= maxSteps && transitions.isNotEmpty) {
        truncatedBySteps = true;
        continue;
      }
      for (final transition in transitions) {
        transitionsExplored++;
        final nextTape = TMExecutionKernel.applyTransitionTape(
          node.tape,
          node.head,
          transition,
          tm.blankSymbol,
        );
        final nextHead = TMExecutionKernel.moveHead(
          node.head,
          transition.direction,
        );
        final nextRead = nextTape[nextHead] ?? tm.blankSymbol;
        final next = _ReachabilityNode(
          input: node.input,
          inputIndex: node.inputIndex,
          state: transition.toState,
          tape: nextTape,
          head: nextHead,
          depth: node.depth + 1,
          readSymbol: nextRead,
          parent: node,
          incomingTransition: transition,
        );
        final key = next.configurationKey(tm.blankSymbol);
        if (seen.contains(key)) continue;
        if (seen.length >= maxConfigurations) {
          return finish(
            TMReachabilityStatus.boundedIncomplete,
            'The configuration limit stopped semantic exploration.',
            limit: TMExecutionLimit.configurations,
            structuredMessage: TmReachabilityMessages.configurationLimit(),
          );
        }
        seen.add(key);
        witnesses.putIfAbsent(next.state.id, next.witness);
        queue.add(next);
      }
    }
    return null;
  }

  TMReachabilityReport finish(
    TMReachabilityStatus status,
    String message, {
    TMExecutionLimit? limit,
    StructuredMessage? structuredMessage,
  }) {
    stopwatch.stop();
    return TMReachabilityAnalyzer._report(
      tm: tm,
      inputs: inputs,
      structural: structural,
      status: status,
      message: message,
      witnesses: witnesses,
      configurationsExplored: configurationsExplored,
      transitionsExplored: transitionsExplored,
      maxSteps: maxSteps,
      maxConfigurations: maxConfigurations,
      timeout: timeout,
      executionTime: stopwatch.elapsed,
      limit: limit,
      structuredMessage: structuredMessage,
    );
  }
}
