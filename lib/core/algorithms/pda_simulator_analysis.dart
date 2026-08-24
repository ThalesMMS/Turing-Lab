part of 'pda_simulator.dart';

/// Analyzes the PDA
PDAAnalysis _analyzePDA(
  PDA pda, {
  required int maxInputLength,
  required Duration timeout,
}) {
  if (maxInputLength < 0) {
    throw ArgumentError.value(
      maxInputLength,
      'maxInputLength',
      'must be non-negative',
    );
  }
  if (timeout <= Duration.zero) {
    throw ArgumentError.value(timeout, 'timeout', 'must be positive');
  }

  final deadline = _PDAAnalysisDeadline(timeout);

  // Analyze states
  final stateAnalysis = _analyzeStates(pda);
  deadline.check();

  // Analyze transitions
  final transitionAnalysis = _analyzeTransitions(pda);
  deadline.check();

  // Analyze stack operations
  final stackAnalysis = _analyzeStackOperations(pda);
  deadline.check();

  // Analyze reachability
  final reachabilityAnalysis = _analyzeReachability(
    pda,
    maxInputLength: maxInputLength,
    deadline: deadline,
  );
  deadline.check();

  return PDAAnalysis(
    stateAnalysis: stateAnalysis,
    transitionAnalysis: transitionAnalysis,
    stackAnalysis: stackAnalysis,
    reachabilityAnalysis: reachabilityAnalysis,
    executionTime: deadline.elapsed,
  );
}

class _PDAAnalysisDeadline {
  _PDAAnalysisDeadline(this.timeout) : _stopwatch = Stopwatch()..start();

  final Duration timeout;
  final Stopwatch _stopwatch;

  Duration get elapsed => _stopwatch.elapsed;

  void check() {
    if (_stopwatch.elapsed >= timeout) {
      throw StateError('PDA analysis timed out');
    }
  }
}

/// Analyzes the states of the PDA
PDAStateAnalysis _analyzeStates(PDA pda) {
  final totalStates = pda.states.length;
  final acceptingStates = pda.acceptingStates.length;
  final nonAcceptingStates = totalStates - acceptingStates;

  return PDAStateAnalysis(
    totalStates: totalStates,
    acceptingStates: acceptingStates,
    nonAcceptingStates: nonAcceptingStates,
  );
}

/// Analyzes the transitions of the PDA
PDATransitionAnalysis _analyzeTransitions(PDA pda) {
  final totalTransitions = pda.transitions.length;
  final pdaTransitions = pda.transitions.whereType<PDATransition>().length;
  final fsaTransitions = pda.transitions.whereType<FSATransition>().length;

  return PDATransitionAnalysis(
    totalTransitions: totalTransitions,
    pdaTransitions: pdaTransitions,
    fsaTransitions: fsaTransitions,
  );
}

/// Analyzes the stack operations of the PDA
StackAnalysis _analyzeStackOperations(PDA pda) {
  final pushOperations = <String>{};
  final popOperations = <String>{};
  final stackSymbols = <String>{};

  for (final transition in pda.transitions) {
    if (transition is PDATransition) {
      if (transition.stackPush.isNotEmpty) {
        pushOperations.add(transition.stackPush);
      }
      if (transition.stackPop.isNotEmpty) {
        popOperations.add(transition.stackPop);
      }
    }
  }

  stackSymbols
    ..addAll(pushOperations)
    ..addAll(popOperations);

  return StackAnalysis(
    pushOperations: pushOperations,
    popOperations: popOperations,
    stackSymbols: stackSymbols,
  );
}

/// Analyzes the reachability of the PDA
PDAReachabilityAnalysis _analyzeReachability(
  PDA pda, {
  required int maxInputLength,
  required _PDAAnalysisDeadline deadline,
}) {
  final reachableStates = <State>{};
  final unreachableStates = <State>{};

  // Find reachable states from initial state
  if (pda.initialState != null) {
    _findReachableStates(
      pda,
      pda.initialState!,
      reachableStates,
      maxInputLength: maxInputLength,
      deadline: deadline,
    );
  }

  // Find unreachable states
  for (final state in pda.states) {
    if (!reachableStates.contains(state)) {
      unreachableStates.add(state);
    }
  }

  return PDAReachabilityAnalysis(
    reachableStates: reachableStates,
    unreachableStates: unreachableStates,
  );
}

/// Finds states reachable within the configured input-length bound.
void _findReachableStates(
  PDA pda,
  State currentState,
  Set<State> reachableStates, {
  required int maxInputLength,
  required _PDAAnalysisDeadline deadline,
}) {
  final queue = Queue<({State state, int inputLength})>()
    ..add((state: currentState, inputLength: 0));
  final seen = <String>{};

  while (queue.isNotEmpty) {
    deadline.check();
    final current = queue.removeFirst();
    final key = '${current.state.id}|${current.inputLength}';
    if (!seen.add(key)) {
      continue;
    }

    reachableStates.add(current.state);

    for (final transition in pda.transitions) {
      if (transition.fromState != current.state) {
        continue;
      }
      final nextInputLength =
          current.inputLength + _transitionInputLength(transition);
      if (nextInputLength > maxInputLength) {
        continue;
      }
      queue.add((state: transition.toState, inputLength: nextInputLength));
    }
  }
}

int _transitionInputLength(Transition transition) {
  if (transition is PDATransition) {
    return transition.isLambdaInput ? 0 : transition.inputSymbol.length;
  }
  if (transition is FSATransition) {
    if (transition.lambdaSymbol != null || transition.inputSymbols.isEmpty) {
      return 0;
    }
    return transition.inputSymbols
        .map((symbol) => symbol.length)
        .reduce((a, b) => a < b ? a : b);
  }
  return transition.label.length;
}
