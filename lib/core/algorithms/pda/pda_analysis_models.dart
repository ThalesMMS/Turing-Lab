part of 'pda_simulator.dart';

/// Analysis result of a PDA
class PDAAnalysis {
  final PDAStateAnalysis stateAnalysis;
  final PDATransitionAnalysis transitionAnalysis;
  final StackAnalysis stackAnalysis;
  final PDAReachabilityAnalysis reachabilityAnalysis;
  final Duration executionTime;

  const PDAAnalysis({
    required this.stateAnalysis,
    required this.transitionAnalysis,
    required this.stackAnalysis,
    required this.reachabilityAnalysis,
    required this.executionTime,
  });

  PDAAnalysis copyWith({
    PDAStateAnalysis? stateAnalysis,
    PDATransitionAnalysis? transitionAnalysis,
    StackAnalysis? stackAnalysis,
    PDAReachabilityAnalysis? reachabilityAnalysis,
    Duration? executionTime,
  }) {
    return PDAAnalysis(
      stateAnalysis: stateAnalysis ?? this.stateAnalysis,
      transitionAnalysis: transitionAnalysis ?? this.transitionAnalysis,
      stackAnalysis: stackAnalysis ?? this.stackAnalysis,
      reachabilityAnalysis: reachabilityAnalysis ?? this.reachabilityAnalysis,
      executionTime: executionTime ?? this.executionTime,
    );
  }
}

/// Analysis of states
class PDAStateAnalysis {
  final int totalStates;
  final int acceptingStates;
  final int nonAcceptingStates;

  const PDAStateAnalysis({
    required this.totalStates,
    required this.acceptingStates,
    required this.nonAcceptingStates,
  });
}

/// Analysis of transitions
class PDATransitionAnalysis {
  final int totalTransitions;
  final int pdaTransitions;
  final int fsaTransitions;

  const PDATransitionAnalysis({
    required this.totalTransitions,
    required this.pdaTransitions,
    required this.fsaTransitions,
  });
}

/// Analysis of stack operations
class StackAnalysis {
  final Set<String> pushOperations;
  final Set<String> popOperations;
  final Set<String> stackSymbols;

  StackAnalysis({
    required Set<String> pushOperations,
    required Set<String> popOperations,
    required Set<String> stackSymbols,
  }) : pushOperations = Set.unmodifiable(pushOperations),
       popOperations = Set.unmodifiable(popOperations),
       stackSymbols = Set.unmodifiable(stackSymbols);
}

/// Analysis of reachability
class PDAReachabilityAnalysis {
  final Set<State> reachableStates;
  final Set<State> unreachableStates;

  PDAReachabilityAnalysis({
    required Set<State> reachableStates,
    required Set<State> unreachableStates,
  }) : reachableStates = Set.unmodifiable(reachableStates),
       unreachableStates = Set.unmodifiable(unreachableStates);
}
