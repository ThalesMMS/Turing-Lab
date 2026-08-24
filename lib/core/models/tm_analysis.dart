//
//  tm_analysis.dart
//  Turing Lab
//
//  Immutable structures that store Turing-machine analysis metrics, separating
//  state, transition, tape-operation, and reachability statistics. The set is
//  the standardized return type for diagnostic routines, keeping execution
//  duration and computed sets ready for visualization.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'state.dart';

/// Analysis result of a TM
class TMAnalysis {
  final TMStateAnalysis stateAnalysis;
  final TMTransitionAnalysis transitionAnalysis;
  final TapeAnalysis tapeAnalysis;
  final TMReachabilityAnalysis reachabilityAnalysis;
  final Duration executionTime;

  const TMAnalysis({
    required this.stateAnalysis,
    required this.transitionAnalysis,
    required this.tapeAnalysis,
    required this.reachabilityAnalysis,
    required this.executionTime,
  });

  TMAnalysis copyWith({
    TMStateAnalysis? stateAnalysis,
    TMTransitionAnalysis? transitionAnalysis,
    TapeAnalysis? tapeAnalysis,
    TMReachabilityAnalysis? reachabilityAnalysis,
    Duration? executionTime,
  }) {
    return TMAnalysis(
      stateAnalysis: stateAnalysis ?? this.stateAnalysis,
      transitionAnalysis: transitionAnalysis ?? this.transitionAnalysis,
      tapeAnalysis: tapeAnalysis ?? this.tapeAnalysis,
      reachabilityAnalysis: reachabilityAnalysis ?? this.reachabilityAnalysis,
      executionTime: executionTime ?? this.executionTime,
    );
  }
}

/// Analysis of states
class TMStateAnalysis {
  final int totalStates;
  final int acceptingStates;
  final int nonAcceptingStates;

  const TMStateAnalysis({
    required this.totalStates,
    required this.acceptingStates,
    required this.nonAcceptingStates,
  });
}

/// Analysis of transitions
class TMTransitionAnalysis {
  final int totalTransitions;
  final int tmTransitions;
  final int fsaTransitions;

  const TMTransitionAnalysis({
    required this.totalTransitions,
    required this.tmTransitions,
    required this.fsaTransitions,
  });
}

/// Analysis of tape operations
class TapeAnalysis {
  final Set<String> writeOperations;
  final Set<String> readOperations;
  final Set<String> moveDirections;
  final Set<String> tapeSymbols;

  const TapeAnalysis({
    required this.writeOperations,
    required this.readOperations,
    required this.moveDirections,
    required this.tapeSymbols,
  });
}

/// Analysis of reachability
class TMReachabilityAnalysis {
  final Set<State> reachableStates;
  final Set<State> unreachableStates;

  const TMReachabilityAnalysis({
    required this.reachableStates,
    required this.unreachableStates,
  });
}
