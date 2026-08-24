//
//  pda_simulator.dart
//  Turing Lab
//
//  Houses the pushdown-automaton simulation engine, supporting
//  deterministic and nondeterministic modes and acceptance by final state,
//  empty stack, or both.
//  Performs validation, traces steps for visualization, administers timeout,
//  and offers detailed result structures for UI and tests.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'dart:collection';

import '../models/pda.dart';
import '../models/pda_acceptance_mode.dart';
import '../models/state.dart';
import '../models/pda_transition.dart';
import '../models/fsa_transition.dart';
import '../models/simulation_step.dart';
import '../models/step_explanation.dart';
import '../models/transition.dart';
import '../result.dart';
import '../simulation_cancelled_exception.dart';

export '../models/pda_acceptance_mode.dart';

part 'pda_simulator_validation.dart';
part 'pda_simulator_search.dart';
part 'pda_simulator_generation.dart';
part 'pda_simulator_analysis.dart';
part 'pda_simulation_result.dart';
part 'pda_analysis_models.dart';

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
