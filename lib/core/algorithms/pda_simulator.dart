//
//  pda_simulator.dart
//  Turing Lab
//
//  Reúne o motor de simulação de autômatos de pilha, suportando modos
//  determinísticos e não determinísticos, aceitação por estado final, pilha
//  vazia ou ambos.
//  Executa validações, rastreia passos para visualização, administra timeout e
//  oferece estruturas de resultado detalhadas para consumo em interfaces e
//  testes.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'dart:collection';

import '../models/pda.dart';
import '../models/state.dart';
import '../models/pda_transition.dart';
import '../models/fsa_transition.dart';
import '../models/simulation_step.dart';
import '../models/step_explanation.dart';
import '../models/transition.dart';
import '../result.dart';
import '../simulation_cancelled_exception.dart';

part 'pda_simulator_validation.dart';
part 'pda_simulator_search.dart';
part 'pda_simulator_generation.dart';
part 'pda_simulator_analysis.dart';
part 'pda_simulation_result.dart';
part 'pda_analysis_models.dart';
part 'pda_simplification_summary.dart';

/// Acceptance modes for NPDA simulation
enum PDAAcceptanceMode { finalState, emptyStack, both }

/// Simulates Pushdown Automata (PDA) with input strings
class PDASimulator {
  /// Simulates a DPDA (deterministic) with an input string.
  /// Use [simulateNPDA] for non-deterministic behavior with ε-moves.
  static Result<PDASimulationResult> simulate(
    PDA pda,
    String inputString, {
    bool stepByStep = false,
    Duration timeout = const Duration(seconds: 5),
  }) {
    try {
      // Delegate to epsilon-aware NPDA search with final-state acceptance.
      return simulateNPDA(
        pda,
        inputString,
        stepByStep: stepByStep,
        timeout: timeout,
        mode: PDAAcceptanceMode.finalState,
      );
    } catch (e) {
      return Failure('Error simulating PDA: $e');
    }
  }

  /// Configuration for NPDA simulation
  static const int defaultMaxBranchingDepth = 1000;
  static const int defaultMaxConfigurations = 100000;

  /// Simulates a (N)PDA with ε-moves and branching. Acceptance modes:
  /// - by final state
  /// - by empty stack
  /// - by both
  static Result<PDASimulationResult> simulateNPDA(
    PDA pda,
    String inputString, {
    bool stepByStep = false,
    Duration timeout = const Duration(seconds: 5),
    PDAAcceptanceMode mode = PDAAcceptanceMode.finalState,
    int maxDepth = defaultMaxBranchingDepth,
    int maxConfigurations = defaultMaxConfigurations,
  }) {
    try {
      final stopwatch = Stopwatch()..start();
      final validationResult = _validateInput(pda, inputString);
      if (!validationResult.isSuccess) {
        return Failure(validationResult.error!);
      }
      if (pda.initialState == null) {
        return const Failure('PDA must have an initial state');
      }
      final result = _simulateSearch(
        pda,
        inputString,
        stepByStep,
        timeout,
        mode,
        maxDepth,
        maxConfigurations,
      );
      stopwatch.stop();
      return Success(result.copyWith(executionTime: stopwatch.elapsed));
    } catch (e) {
      return Failure('Error simulating NPDA: $e');
    }
  }

  static Future<Result<PDASimulationResult>> simulateCooperative(
    PDA pda,
    String inputString, {
    bool stepByStep = false,
    Duration timeout = const Duration(seconds: 5),
    PDAAcceptanceMode mode = PDAAcceptanceMode.finalState,
    int maxDepth = defaultMaxBranchingDepth,
    int maxConfigurations = defaultMaxConfigurations,
    int configurationsPerBatch = 250,
    bool Function()? isCancelled,
  }) async {
    try {
      final validationResult = _validateInput(pda, inputString);
      if (!validationResult.isSuccess) {
        return Failure(validationResult.error!);
      }
      if (pda.initialState == null) {
        return const Failure('PDA must have an initial state');
      }
      if (configurationsPerBatch <= 0) {
        return const Failure(
          'Configurations per batch must be greater than zero',
        );
      }

      final search = _PdaSearch(
        pda,
        inputString,
        stepByStep,
        timeout,
        mode,
        maxDepth,
        maxConfigurations,
      );
      while (true) {
        if (isCancelled?.call() == true) {
          throw const SimulationCancelledException();
        }
        final result = search.runBatch(configurationsPerBatch);
        if (result != null) return Success(result);
        await Future<void>.delayed(Duration.zero);
      }
    } on SimulationCancelledException {
      rethrow;
    } catch (e) {
      return Failure('Error simulating PDA: $e');
    }
  }

  /// Produces a simplified PDA by pruning unreachable/nonproductive states
  /// and merging obviously equivalent configurations.
  static Result<PDASimplificationSummary> simplify(PDA pda) {
    if (pda.states.isEmpty) {
      return const Failure('Cannot minimize an empty PDA.');
    }

    final initialState = pda.initialState;
    if (initialState == null) {
      return const Failure(
        'PDA must define an initial state before minimization.',
      );
    }

    if (pda.acceptingStates.isEmpty) {
      return const Failure('PDA must define at least one accepting state.');
    }

    final reachableStates = <State>{};
    _findReachableStates(pda, initialState, reachableStates);

    final productiveStates = _findProductiveStates(pda);

    final usefulStates = reachableStates.intersection(productiveStates);
    if (usefulStates.isEmpty) {
      return const Failure(
        'Initial state cannot reach any accepting configuration. '
        'Add transitions that lead to an accepting state before minimization.',
      );
    }

    final unreachableStates = pda.states.difference(reachableStates);
    final nonProductiveStates = pda.states.difference(productiveStates);

    final usefulStateIds = usefulStates.map((s) => s.id).toSet();

    final filteredStates =
        pda.states.where((s) => usefulStateIds.contains(s.id)).toSet();
    final prunedStates = pda.states.difference(filteredStates);

    final filteredTransitions = pda.transitions
        .where(
          (transition) =>
              usefulStateIds.contains(transition.fromState.id) &&
              usefulStateIds.contains(transition.toState.id),
        )
        .toList();

    final removedTransitionsFromPruning = pda.transitions
        .where(
          (transition) =>
              !usefulStateIds.contains(transition.fromState.id) ||
              !usefulStateIds.contains(transition.toState.id),
        )
        .map((transition) => transition.id)
        .toSet();

    final canonicalStateMap = {
      for (final state in filteredStates) state.id: state,
    };

    final mergeTargets = <String, String>{};
    final signatureOwners = <String, String>{};
    final sortedStates = filteredStates.toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    for (final state in sortedStates) {
      final signature = _stateSignature(
        state,
        filteredTransitions,
        mergeTargets,
        canonicalStateMap,
      );
      final owner = signatureOwners[signature];
      if (owner != null && owner != state.id) {
        mergeTargets[state.id] = owner;
      } else {
        signatureOwners[signature] = state.id;
      }
    }

    final mergeGroups = <PDAMergeGroup>[];
    final removedStatesFromMerging = <State>{};

    final groupedMerges = <String, Set<State>>{};
    mergeTargets.forEach((stateId, targetId) {
      final mergedState = canonicalStateMap[stateId];
      final targetState = canonicalStateMap[targetId];
      if (mergedState == null || targetState == null) {
        return;
      }
      groupedMerges.putIfAbsent(targetId, () => <State>{}).add(mergedState);
      removedStatesFromMerging.add(mergedState);
    });

    groupedMerges.forEach((targetId, mergedStates) {
      final representative = canonicalStateMap[targetId];
      if (representative != null) {
        mergeGroups.add(
          PDAMergeGroup(
            representative: representative,
            mergedStates: mergedStates,
          ),
        );
      }
    });

    final canonicalStates = <String, State>{};
    for (final state in sortedStates) {
      final targetId = mergeTargets[state.id] ?? state.id;
      final representative = canonicalStateMap[targetId];
      if (representative != null) {
        canonicalStates[targetId] = representative;
      }
    }

    final canonicalTransitions = <String, Transition>{};
    final duplicateTransitionIds = <String>{};

    for (final transition in filteredTransitions) {
      final canonicalFromId =
          mergeTargets[transition.fromState.id] ?? transition.fromState.id;
      final canonicalToId =
          mergeTargets[transition.toState.id] ?? transition.toState.id;

      final canonicalFrom = canonicalStates[canonicalFromId];
      final canonicalTo = canonicalStates[canonicalToId];
      if (canonicalFrom == null || canonicalTo == null) {
        continue;
      }

      final canonicalTransition = transition.copyWith(
        fromState: canonicalFrom,
        toState: canonicalTo,
      );

      final key = _transitionKey(canonicalTransition);
      if (canonicalTransitions.containsKey(key)) {
        duplicateTransitionIds.add(transition.id);
      } else {
        canonicalTransitions[key] = canonicalTransition;
      }
    }

    final finalTransitions = canonicalTransitions.values.toSet();
    final removedTransitions = <String>{}
      ..addAll(removedTransitionsFromPruning)
      ..addAll(duplicateTransitionIds);

    final finalStates = canonicalStates.values.toSet();
    final finalAcceptingStates =
        finalStates.where((state) => state.isAccepting).toSet();
    if (finalAcceptingStates.isEmpty) {
      return const Failure(
        'Minimization removed all accepting states. Ensure at least one accepting state is reachable before retrying.',
      );
    }

    final canonicalInitialId = mergeTargets[initialState.id] ?? initialState.id;
    final finalInitialState = canonicalStates[canonicalInitialId];
    if (finalInitialState == null) {
      return const Failure(
        'Initial state became invalid after simplification.',
      );
    }

    final recomputedAlphabet = <String>{};
    final recomputedStackAlphabet = <String>{};
    for (final transition in finalTransitions) {
      // Simplification can leave a mixed transition set: FSA transitions only
      // contribute input symbols, while PDA transitions also contribute stack
      // symbols from pop/push operations, so recompute both alphabets here.
      if (transition is PDATransition) {
        if (!transition.isLambdaInput && transition.inputSymbol.isNotEmpty) {
          recomputedAlphabet.add(transition.inputSymbol);
        }
        if (!transition.isLambdaPop && transition.popSymbol.isNotEmpty) {
          recomputedStackAlphabet.add(transition.popSymbol);
        }
        if (!transition.isLambdaPush) {
          recomputedStackAlphabet.addAll(
            transition.pushSymbols.where((symbol) => symbol.isNotEmpty),
          );
        }
      } else if (transition is FSATransition) {
        recomputedAlphabet.addAll(
          transition.inputSymbols.where((symbol) => symbol.isNotEmpty),
        );
      }
    }

    if (recomputedStackAlphabet.isEmpty) {
      recomputedStackAlphabet.add(pda.initialStackSymbol);
    } else if (!recomputedStackAlphabet.contains(pda.initialStackSymbol)) {
      recomputedStackAlphabet.add(pda.initialStackSymbol);
    }

    final minimizedPda = pda.copyWith(
      states: finalStates,
      transitions: finalTransitions.toSet(),
      alphabet: recomputedAlphabet.isEmpty ? pda.alphabet : recomputedAlphabet,
      initialState: finalInitialState,
      acceptingStates: finalAcceptingStates,
      stackAlphabet: recomputedStackAlphabet,
      modified: DateTime.now(),
    );

    final removedStates = <State>{}
      ..addAll(prunedStates)
      ..addAll(removedStatesFromMerging);

    final summary = PDASimplificationSummary(
      minimizedPda: minimizedPda,
      removedStates: removedStates,
      unreachableStates: unreachableStates,
      nonProductiveStates: nonProductiveStates,
      removedTransitionIds: removedTransitions,
      mergeGroups: mergeGroups,
      changed: removedStates.isNotEmpty || removedTransitions.isNotEmpty,
      warnings: const [],
    );

    return Success(summary);
  }

  /// Tests if a PDA accepts a specific string
  static Result<bool> accepts(PDA pda, String inputString) {
    final simulationResult = simulate(pda, inputString);
    if (!simulationResult.isSuccess) {
      return Failure(simulationResult.error!);
    }

    final result = simulationResult.data!;
    final errorMessage = result.errorMessage;
    if (errorMessage == PDA_SIMULATION_TIMEOUT_ERROR ||
        errorMessage == PDA_SIMULATION_INFINITE_LOOP_ERROR ||
        errorMessage == PDA_SIMULATION_LIMIT_REACHED_ERROR) {
      return Failure(errorMessage!);
    }

    return Success(result.accepted);
  }

  /// Tests if a PDA rejects a specific string
  static Result<bool> rejects(PDA pda, String inputString) {
    final acceptsResult = accepts(pda, inputString);
    if (!acceptsResult.isSuccess) {
      return Failure(acceptsResult.error!);
    }

    return Success(!acceptsResult.data!);
  }

  /// Finds all strings of a given length that the PDA accepts
  static Result<Set<String>> findAcceptedStrings(
    PDA pda,
    int maxLength, {
    int maxResults = 100,
  }) {
    try {
      final acceptedStrings = <String>{};
      final alphabet = pda.alphabet.toList();

      // Generate all possible strings up to maxLength
      for (int length = 0;
          length <= maxLength && acceptedStrings.length < maxResults;
          length++) {
        _generateStrings(
          pda,
          alphabet,
          '',
          length,
          acceptedStrings,
          maxResults,
        );
      }

      return Success(acceptedStrings);
    } catch (e) {
      return Failure('Error finding accepted strings: $e');
    }
  }

  /// Finds all strings of a given length that the PDA rejects
  static Result<Set<String>> findRejectedStrings(
    PDA pda,
    int maxLength, {
    int maxResults = 100,
  }) {
    try {
      final rejectedStrings = <String>{};
      final alphabet = pda.alphabet.toList();

      // Generate all possible strings up to maxLength
      for (int length = 0;
          length <= maxLength && rejectedStrings.length < maxResults;
          length++) {
        _generateRejectedStrings(
          pda,
          alphabet,
          '',
          length,
          rejectedStrings,
          maxResults,
        );
      }

      return Success(rejectedStrings);
    } catch (e) {
      return Failure('Error finding rejected strings: $e');
    }
  }

  /// Analyzes the behavior of a PDA
  static Result<PDAAnalysis> analyzePDA(
    PDA pda, {
    int maxInputLength = 10,
    Duration timeout = const Duration(seconds: 10),
  }) {
    try {
      final stopwatch = Stopwatch()..start();

      // Validate input
      final validationResult = _validateInput(pda, '');
      if (!validationResult.isSuccess) {
        return Failure(validationResult.error!);
      }

      // Handle empty PDA
      if (pda.states.isEmpty) {
        return const Failure('Cannot analyze empty PDA');
      }

      // Handle PDA with no initial state
      if (pda.initialState == null) {
        return const Failure('PDA must have an initial state');
      }

      // Analyze the PDA
      final result = _analyzePDA(
        pda,
        maxInputLength: maxInputLength,
        timeout: timeout,
      );
      stopwatch.stop();

      // Update execution time
      final finalResult = result.copyWith(executionTime: stopwatch.elapsed);

      return Success(finalResult);
    } catch (e) {
      return Failure('Error analyzing PDA: $e');
    }
  }
}
