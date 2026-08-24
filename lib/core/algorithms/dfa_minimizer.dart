//
//  dfa_minimizer.dart
//  Turing Lab
//
//  Contains the full Hopcroft minimization implementation for deterministic
//  finite automata, including validation, unreachable-state removal, and
//  geometric reconstruction to preserve metadata. Provides helpers for
//  epsilon symbols and Result-wrapped responses with clear error messages.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'dart:collection';

import 'package:vector_math/vector_math_64.dart';
import '../models/fsa.dart';
import '../models/state.dart';
import '../models/fsa_transition.dart';
import '../models/dfa_minimization_step.dart';
import '../result.dart';
import '../utils/epsilon_utils.dart';
import 'state_renamer.dart';

/// Minimizes a Deterministic Finite Automaton (DFA) using the Hopcroft algorithm
class DFAMinimizer {
  /// Minimizes a DFA to an equivalent minimal DFA
  static Result<FSA> minimize(FSA dfa) {
    try {
      // Validate input
      final validationResult = _validateInput(dfa);
      if (!validationResult.isSuccess) {
        return ResultFactory.failure(validationResult.error!);
      }

      // Handle empty DFA
      if (dfa.states.isEmpty) {
        return ResultFactory.failure('Cannot minimize empty DFA');
      }

      // Handle DFA with no initial state
      if (dfa.initialState == null) {
        return ResultFactory.failure('DFA must have an initial state');
      }

      // Step 1: Remove unreachable states
      final dfaWithoutUnreachable = _removeUnreachableStates(dfa);

      // Step 2: Minimize using Hopcroft algorithm
      var minimizedDFA = _minimizeWithHopcroft(dfaWithoutUnreachable);

      // Rename labels to q0, q1, q2... and apply circular layout
      minimizedDFA = StateRenamer.renameAndLayout(minimizedDFA);

      return ResultFactory.success(minimizedDFA);
    } catch (e) {
      return ResultFactory.failure('Error minimizing DFA: $e');
    }
  }

  /// Validates the input DFA
  static Result<void> _validateInput(FSA dfa) {
    if (dfa.states.isEmpty) {
      return ResultFactory.failure('DFA must have at least one state');
    }

    if (dfa.initialState == null) {
      return ResultFactory.failure('DFA must have an initial state');
    }

    if (!dfa.states.contains(dfa.initialState)) {
      return ResultFactory.failure('Initial state must be in the states set');
    }

    for (final acceptingState in dfa.acceptingStates) {
      if (!dfa.states.contains(acceptingState)) {
        return ResultFactory.failure(
          'Accepting state must be in the states set',
        );
      }
    }

    // Check if DFA is deterministic
    if (!dfa.isDeterministic) {
      return ResultFactory.failure('Input must be a deterministic automaton');
    }

    return ResultFactory.success(null);
  }

  /// Removes unreachable states from the DFA
  static FSA _removeUnreachableStates(FSA dfa) {
    final reachableStates = dfa.getReachableStates(dfa.initialState!);
    final unreachableStates = dfa.states.difference(reachableStates);

    if (unreachableStates.isEmpty) {
      return dfa;
    }

    // Remove transitions involving unreachable states
    final newTransitions = dfa.transitions
        .where(
          (transition) =>
              reachableStates.contains(transition.fromState) &&
              reachableStates.contains(transition.toState),
        )
        .toSet();

    // Remove unreachable states from accepting states
    final newAcceptingStates = dfa.acceptingStates.intersection(
      reachableStates,
    );

    return FSA(
      id: '${dfa.id}_no_unreachable',
      name: '${dfa.name} (No Unreachable)',
      states: reachableStates,
      transitions: newTransitions,
      alphabet: dfa.alphabet,
      initialState: dfa.initialState,
      acceptingStates: newAcceptingStates,
      created: dfa.created,
      modified: DateTime.now(),
      bounds: dfa.bounds,
      zoomLevel: dfa.zoomLevel,
      panOffset: dfa.panOffset,
    );
  }

  /// Minimizes DFA using Hopcroft algorithm
  static FSA _minimizeWithHopcroft(FSA dfa) {
    // Filter alphabet to exclude epsilon-like symbols if present
    final workingAlphabet =
        dfa.alphabet.where((s) => !isEpsilonSymbol(s)).toSet();

    // Initialize partition with accepting and non-accepting states
    final partition = <Set<State>>[
      dfa.acceptingStates.toSet(),
      dfa.nonAcceptingStates.toSet(),
    ];

    // Remove empty sets
    partition.removeWhere((set) => set.isEmpty);

    // Worklist for processing
    final worklist = Queue<Set<State>>();
    for (final set in partition) {
      if (set.isNotEmpty) {
        worklist.add(set);
      }
    }

    // Process worklist
    while (worklist.isNotEmpty) {
      final currentSet = worklist.removeFirst();

      // For each symbol in the (filtered) alphabet
      for (final symbol in workingAlphabet) {
        final predecessors = <State>{};

        // Find all states that transition to current set on this symbol
        for (final transition in dfa.transitions) {
          if (transition is FSATransition &&
              transition.inputSymbols.contains(symbol) &&
              currentSet.contains(transition.toState)) {
            predecessors.add(transition.fromState);
          }
        }

        if (predecessors.isNotEmpty) {
          // Split each set in the partition
          final newPartition = <Set<State>>[];
          for (final set in partition) {
            final intersection = set.intersection(predecessors);
            final difference = set.difference(predecessors);

            if (intersection.isNotEmpty && difference.isNotEmpty) {
              newPartition.add(intersection);
              newPartition.add(difference);

              // Add smaller set to worklist
              if (intersection.length <= difference.length) {
                worklist.add(intersection);
              } else {
                worklist.add(difference);
              }
            } else {
              newPartition.add(set);
            }
          }
          partition.clear();
          partition.addAll(newPartition);
        }
      }
    }

    // Create minimized DFA
    return _createMinimizedDFA(dfa, partition);
  }

  /// Creates the minimized DFA from the partition
  static FSA _createMinimizedDFA(FSA originalDFA, List<Set<State>> partition) {
    final stateMap = <State, State>{};
    final newStates = <State>{};
    final newTransitions = <FSATransition>{};
    final newAcceptingStates = <State>{};
    State? newInitialState;

    // Create new states for each equivalence class
    int stateCounter = 0;
    for (final equivalenceClass in partition) {
      final newState = _createMinimizedState(equivalenceClass, stateCounter++);
      newStates.add(newState);

      // Map original states to new state
      for (final originalState in equivalenceClass) {
        stateMap[originalState] = newState;
      }

      // Check if this is the initial state
      if (equivalenceClass.contains(originalDFA.initialState)) {
        newInitialState = newState;
      }

      // Check if this is an accepting state
      if (equivalenceClass
          .intersection(originalDFA.acceptingStates)
          .isNotEmpty) {
        newAcceptingStates.add(newState);
      }
    }

    // Fix: set isAccepting and isInitial on state objects so they stay
    // consistent with the FSA-level acceptingStates and initialState fields.
    final acceptingIds = newAcceptingStates.map((s) => s.id).toSet();
    final initialId = newInitialState?.id;
    final fixedStates = <State>{};
    for (final s in newStates) {
      fixedStates.add(s.copyWith(
        isAccepting: acceptingIds.contains(s.id),
        isInitial: s.id == initialId,
      ));
    }
    final statesById = <String, State>{
      for (final s in fixedStates) s.id: s,
    };
    final fixedInitialState = initialId != null ? statesById[initialId] : null;
    final fixedAcceptingStates =
        fixedStates.where((s) => s.isAccepting).toSet();

    // Update stateMap to point to fixed state objects
    for (final entry in stateMap.entries) {
      final fixed = statesById[entry.value.id];
      if (fixed != null) stateMap[entry.key] = fixed;
    }

    // Create transitions
    for (final originalTransition in originalDFA.transitions) {
      if (originalTransition is FSATransition) {
        // Skip epsilon-like transitions if any slipped through
        if (originalTransition.lambdaSymbol != null ||
            originalTransition.inputSymbols.any(isEpsilonSymbol)) {
          continue;
        }
        final fromState = stateMap[originalTransition.fromState]!;
        final toState = stateMap[originalTransition.toState]!;

        // Check if an equivalent transition already exists (by endpoints and symbol set contents)
        final exists = newTransitions.any(
          (t) =>
              t.fromState == fromState &&
              t.toState == toState &&
              t.inputSymbols.length == originalTransition.inputSymbols.length &&
              t.inputSymbols.containsAll(originalTransition.inputSymbols),
        );

        if (!exists) {
          final newTransition = FSATransition(
            id: 't_${fromState.id}_${toState.id}_${originalTransition.inputSymbols.join('_')}',
            fromState: fromState,
            toState: toState,
            label: originalTransition.label,
            inputSymbols: originalTransition.inputSymbols,
          );
          newTransitions.add(newTransition);
        }
      }
    }

    return FSA(
      id: '${originalDFA.id}_minimized',
      name: '${originalDFA.name} (Minimized)',
      states: fixedStates,
      transitions: newTransitions,
      alphabet: originalDFA.alphabet,
      initialState: fixedInitialState,
      acceptingStates: fixedAcceptingStates,
      created: originalDFA.created,
      modified: DateTime.now(),
      bounds: originalDFA.bounds,
      zoomLevel: originalDFA.zoomLevel,
      panOffset: originalDFA.panOffset,
    );
  }

  /// Creates a minimized state from an equivalence class
  static State _createMinimizedState(Set<State> equivalenceClass, int counter) {
    final stateIds = equivalenceClass.map((s) => s.id).toList()..sort();
    final stateId = 'q${counter}_min';
    final stateLabel =
        stateIds.length == 1 ? stateIds.first : '{${stateIds.join(',')}}';

    // Calculate position as center of the states
    double sumX = 0;
    double sumY = 0;
    for (final state in equivalenceClass) {
      sumX += state.position.x;
      sumY += state.position.y;
    }
    final position = Vector2(
      sumX / equivalenceClass.length,
      sumY / equivalenceClass.length,
    );

    return State(
      id: stateId,
      label: stateLabel,
      position: position,
      isInitial: false, // Will be set later
      isAccepting: false, // Will be set later
    );
  }

  /// Minimizes a DFA with step-by-step information
  static Result<DFAMinimizationResult> minimizeWithSteps(FSA dfa) {
    try {
      final startTime = DateTime.now();
      final steps = <DFAMinimizationStep>[];
      int stepCounter = 1;

      // Step 1: Validate input
      final validationResult = _validateInput(dfa);
      if (!validationResult.isSuccess) {
        return ResultFactory.failure(validationResult.error!);
      }

      // Step 2: Remove unreachable states
      final reachableStates = dfa.getReachableStates(dfa.initialState!);
      final unreachableStates = dfa.states.difference(reachableStates);

      if (unreachableStates.isNotEmpty) {
        steps.add(
          DFAMinimizationStep.removeUnreachable(
            id: 'step_$stepCounter',
            stepNumber: stepCounter++,
            unreachableStates: unreachableStates,
            reachableStates: reachableStates,
          ),
        );
      }

      final dfaWithoutUnreachable = _removeUnreachableStates(dfa);

      // Step 3: Run detailed Hopcroft algorithm with step capture
      final hopcroftResult = _minimizeWithHopcroftDetailed(
        dfaWithoutUnreachable,
        steps,
        stepCounter,
      );

      var minimizedDFA = hopcroftResult['dfa'] as FSA;
      final detailedSteps =
          hopcroftResult['steps'] as List<DFAMinimizationStep>;

      // Rename labels to q0, q1, q2... and apply circular layout
      minimizedDFA = StateRenamer.renameAndLayout(minimizedDFA);

      final endTime = DateTime.now();
      final executionTime = endTime.difference(startTime);

      final result = DFAMinimizationResult(
        originalDFA: dfa,
        resultDFA: minimizedDFA,
        steps: detailedSteps,
        executionTime: executionTime,
      );

      return ResultFactory.success(result);
    } catch (e) {
      return ResultFactory.failure('Error minimizing DFA with steps: $e');
    }
  }

  /// Minimizes DFA using Hopcroft algorithm with detailed step capture
  static Map<String, dynamic> _minimizeWithHopcroftDetailed(
    FSA dfa,
    List<DFAMinimizationStep> steps,
    int initialStepCounter,
  ) {
    int stepCounter = initialStepCounter;

    // Filter alphabet to exclude epsilon-like symbols if present
    final workingAlphabet =
        dfa.alphabet.where((s) => !isEpsilonSymbol(s)).toSet();

    // Initialize partition with accepting and non-accepting states
    final partition = <Set<State>>[
      dfa.acceptingStates.toSet(),
      dfa.nonAcceptingStates.toSet(),
    ];
    partition.removeWhere((set) => set.isEmpty);

    // Capture initial partition step
    steps.add(
      DFAMinimizationStep.initialPartition(
        id: 'step_$stepCounter',
        stepNumber: stepCounter++,
        acceptingStates: dfa.acceptingStates.toSet(),
        nonAcceptingStates: dfa.nonAcceptingStates.toSet(),
      ),
    );

    // Worklist for processing
    final worklist = Queue<Set<State>>();
    for (final set in partition) {
      if (set.isNotEmpty) {
        worklist.add(set);
      }
    }

    // Process worklist
    while (worklist.isNotEmpty) {
      final currentSet = worklist.removeFirst();

      // Capture set selection step
      steps.add(
        DFAMinimizationStep.selectProcessingSet(
          id: 'step_$stepCounter',
          stepNumber: stepCounter++,
          currentPartition: List.from(partition),
          processingSet: currentSet,
        ),
      );

      // For each symbol in the (filtered) alphabet
      for (final symbol in workingAlphabet) {
        final predecessors = <State>{};

        // Find all states that transition to current set on this symbol
        for (final transition in dfa.transitions) {
          if (transition is FSATransition &&
              transition.inputSymbols.contains(symbol) &&
              currentSet.contains(transition.toState)) {
            predecessors.add(transition.fromState);
          }
        }

        // Capture predecessor finding step
        steps.add(
          DFAMinimizationStep.findPredecessors(
            id: 'step_$stepCounter',
            stepNumber: stepCounter++,
            currentPartition: List.from(partition),
            processingSet: currentSet,
            symbol: symbol,
            predecessors: predecessors,
          ),
        );

        if (predecessors.isNotEmpty) {
          // Split each set in the partition
          final newPartition = <Set<State>>[];

          for (final set in partition) {
            final intersection = set.intersection(predecessors);
            final difference = set.difference(predecessors);

            if (intersection.isNotEmpty && difference.isNotEmpty) {
              // Split occurred
              newPartition.add(intersection);
              newPartition.add(difference);

              // Capture split step
              steps.add(
                DFAMinimizationStep.splitClass(
                  id: 'step_$stepCounter',
                  stepNumber: stepCounter++,
                  currentPartition: List.from(partition),
                  splitSet: set,
                  intersection: intersection,
                  difference: difference,
                  symbol: symbol,
                  newPartition: List.from(newPartition),
                ),
              );

              // Add smaller set to worklist
              if (intersection.length <= difference.length) {
                worklist.add(intersection);
              } else {
                worklist.add(difference);
              }
            } else {
              // No split
              newPartition.add(set);
              if (set.isNotEmpty &&
                  (intersection.isNotEmpty || difference.isNotEmpty)) {
                steps.add(
                  DFAMinimizationStep.noSplit(
                    id: 'step_$stepCounter',
                    stepNumber: stepCounter++,
                    currentPartition: List.from(partition),
                    checkedSet: set,
                    symbol: symbol,
                  ),
                );
              }
            }
          }

          partition.clear();
          partition.addAll(newPartition);
        }
      }
    }

    // Capture partition stabilization step
    steps.add(
      DFAMinimizationStep.partitionStable(
        id: 'step_$stepCounter',
        stepNumber: stepCounter++,
        finalPartition: List.from(partition),
      ),
    );

    // Create minimized DFA
    final minimizedDFA = _createMinimizedDFA(dfa, partition);

    // Capture state creation steps
    int stateIndex = 0;
    for (final equivalenceClass in partition) {
      final isAccepting =
          equivalenceClass.intersection(dfa.acceptingStates).isNotEmpty;
      final isInitial = equivalenceClass.contains(dfa.initialState);
      final stateId = 'q${stateIndex}_min';

      steps.add(
        DFAMinimizationStep.createMinimizedState(
          id: 'step_$stepCounter',
          stepNumber: stepCounter++,
          stateId: stateId,
          equivalenceClass: equivalenceClass,
          isAccepting: isAccepting,
          isInitial: isInitial,
        ),
      );
      stateIndex++;
    }

    // Capture completion step
    steps.add(
      DFAMinimizationStep.completion(
        id: 'step_$stepCounter',
        stepNumber: stepCounter++,
        originalStates: dfa.states.length,
        minimizedStates: minimizedDFA.states.length,
        totalTransitions: minimizedDFA.transitions.length,
      ),
    );

    return {'dfa': minimizedDFA, 'steps': steps};
  }
}

/// Result of DFA minimization with step-by-step information
class DFAMinimizationResult {
  /// Original DFA
  final FSA originalDFA;

  /// Resulting minimized DFA
  final FSA resultDFA;

  /// Minimization steps
  final List<DFAMinimizationStep> steps;

  /// Execution time
  final Duration executionTime;

  const DFAMinimizationResult({
    required this.originalDFA,
    required this.resultDFA,
    required this.steps,
    required this.executionTime,
  });

  /// Gets the number of steps
  int get stepCount => steps.length;

  /// Gets the first step
  DFAMinimizationStep? get firstStep => steps.isNotEmpty ? steps.first : null;

  /// Gets the last step
  DFAMinimizationStep? get lastStep => steps.isNotEmpty ? steps.last : null;

  /// Gets the execution time in milliseconds
  int get executionTimeMs => executionTime.inMilliseconds;

  /// Gets the execution time in seconds
  double get executionTimeSeconds => executionTime.inMicroseconds / 1000000.0;

  /// Gets the reduction in number of states
  int get stateReduction => originalDFA.stateCount - resultDFA.stateCount;

  /// Gets the reduction percentage
  double get reductionPercentage {
    if (originalDFA.stateCount == 0) return 0.0;
    return (stateReduction / originalDFA.stateCount) * 100.0;
  }
}

/// Single step in DFA minimization
class MinimizationStep {
  /// Step number
  final int stepNumber;

  /// Description of the step
  final String description;

  /// DFA at this step
  final FSA? dfa;

  /// Partition at this step
  final List<Set<State>>? partition;

  const MinimizationStep({
    required this.stepNumber,
    required this.description,
    this.dfa,
    this.partition,
  });

  @override
  String toString() {
    return 'MinimizationStep(stepNumber: $stepNumber, description: $description)';
  }
}
