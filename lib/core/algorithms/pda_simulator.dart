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
import 'dart:convert';

import 'package:meta/meta.dart';

import '../models/pda.dart';
import '../models/pda_acceptance_mode.dart';
import '../models/state.dart';
import '../models/pda_transition.dart';
import '../models/fsa_transition.dart';
import '../models/simulation_step.dart';
import '../models/step_explanation.dart';
import '../models/transition.dart';
import '../messages/structured_message.dart';
import '../result.dart';
import '../simulation_cancelled_exception.dart';
import 'pda_simulation_semantic_variant.dart';
import 'pda_simulation_messages.dart';
import 'pda_simulator_analysis_messages.dart';

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
      // Delegate to the epsilon-aware NPDA search using the document policy.
      return simulateNPDA(
        pda,
        inputString,
        stepByStep: stepByStep,
        timeout: timeout,
        mode: pda.acceptanceMode,
      );
    } catch (e) {
      return Failure(
        'Error simulating PDA: $e',
        structuredMessage: PDASimulationMessages.simulationFailure(
          operation: 'simulate',
          error: e,
        ),
      );
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
    int? maxMemoryBytes,
    bool Function()? isStale,
  }) => _simulateNPDA(
    pda,
    inputString,
    stepByStep: stepByStep,
    timeout: timeout,
    mode: mode,
    maxDepth: maxDepth,
    maxConfigurations: maxConfigurations,
    maxMemoryBytes: maxMemoryBytes,
    isStale: isStale,
    semanticVariant: PDASimulationSemanticVariant.canonical,
  );

  /// Runs a deliberately non-canonical search for certification mutation tests.
  @visibleForTesting
  static Result<PDASimulationResult> simulateNPDAForCertification(
    PDA pda,
    String inputString, {
    required PDASimulationSemanticVariant semanticVariant,
    bool stepByStep = false,
    Duration timeout = const Duration(seconds: 5),
    PDAAcceptanceMode mode = PDAAcceptanceMode.finalState,
    int maxDepth = defaultMaxBranchingDepth,
    int maxConfigurations = defaultMaxConfigurations,
    int? maxMemoryBytes,
    bool Function()? isStale,
  }) => _simulateNPDA(
    pda,
    inputString,
    stepByStep: stepByStep,
    timeout: timeout,
    mode: mode,
    maxDepth: maxDepth,
    maxConfigurations: maxConfigurations,
    maxMemoryBytes: maxMemoryBytes,
    isStale: isStale,
    semanticVariant: semanticVariant,
  );

  static Result<PDASimulationResult> _simulateNPDA(
    PDA pda,
    String inputString, {
    required bool stepByStep,
    required Duration timeout,
    required PDAAcceptanceMode mode,
    required int maxDepth,
    required int maxConfigurations,
    required int? maxMemoryBytes,
    required bool Function()? isStale,
    required PDASimulationSemanticVariant semanticVariant,
  }) {
    try {
      final stopwatch = Stopwatch()..start();
      final validationResult = _validateInput(pda, inputString);
      if (!validationResult.isSuccess) {
        return Failure(
          validationResult.error!,
          structuredMessage: validationResult.structuredError,
        );
      }
      if (pda.initialState == null) {
        return Failure(
          'PDA must have an initial state',
          structuredMessage: PDASimulationMessages.missingInitialState(),
        );
      }
      if (maxDepth < 0 || maxConfigurations < 0) {
        return Failure(
          'PDA search limits must not be negative',
          structuredMessage: PDASimulationMessages.searchLimitsNegative(),
        );
      }
      if (maxMemoryBytes != null && maxMemoryBytes < 0) {
        return Failure(
          'PDA memory limit must not be negative',
          structuredMessage: PDASimulationMessages.memoryLimitNegative(),
        );
      }
      final result = _simulateSearch(
        pda,
        inputString,
        stepByStep,
        timeout,
        mode,
        maxDepth,
        maxConfigurations,
        maxMemoryBytes,
        isStale,
        semanticVariant,
      );
      stopwatch.stop();
      return Success(result.copyWith(executionTime: stopwatch.elapsed));
    } catch (e) {
      return Failure(
        'Error simulating NPDA: $e',
        structuredMessage: PDASimulationMessages.simulationFailure(
          operation: 'simulate-npda',
          error: e,
        ),
      );
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
    int? maxMemoryBytes,
    int configurationsPerBatch = 250,
    bool Function()? isCancelled,
    bool Function()? isStale,
  }) async {
    try {
      final validationResult = _validateInput(pda, inputString);
      if (!validationResult.isSuccess) {
        return Failure(
          validationResult.error!,
          structuredMessage: validationResult.structuredError,
        );
      }
      if (pda.initialState == null) {
        return Failure(
          'PDA must have an initial state',
          structuredMessage: PDASimulationMessages.missingInitialState(),
        );
      }
      if (configurationsPerBatch <= 0) {
        return Failure(
          'Configurations per batch must be greater than zero',
          structuredMessage:
              PDASimulationMessages.configurationsPerBatchInvalid(),
        );
      }
      if (maxDepth < 0 || maxConfigurations < 0) {
        return Failure(
          'PDA search limits must not be negative',
          structuredMessage: PDASimulationMessages.searchLimitsNegative(),
        );
      }
      if (maxMemoryBytes != null && maxMemoryBytes < 0) {
        return Failure(
          'PDA memory limit must not be negative',
          structuredMessage: PDASimulationMessages.memoryLimitNegative(),
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
        maxMemoryBytes,
        isStale,
        PDASimulationSemanticVariant.canonical,
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
      return Failure(
        'Error simulating PDA: $e',
        structuredMessage: PDASimulationMessages.simulationFailure(
          operation: 'simulate-cooperative',
          error: e,
        ),
      );
    }
  }

  /// Tests if a PDA accepts a specific string
  static Result<bool> accepts(PDA pda, String inputString) {
    final simulationResult = simulate(pda, inputString);
    if (!simulationResult.isSuccess) {
      return Failure(
        simulationResult.error!,
        structuredMessage: simulationResult.structuredError,
      );
    }

    final result = simulationResult.data!;
    if (result.isInconclusive ||
        result.outcome == PDASimulationOutcome.provenCycle) {
      return Failure(
        result.errorMessage!,
        structuredMessage: result.structuredMessage,
      );
    }

    return Success(result.accepted);
  }

  /// Tests if a PDA rejects a specific string
  static Result<bool> rejects(PDA pda, String inputString) {
    final acceptsResult = accepts(pda, inputString);
    if (!acceptsResult.isSuccess) {
      return Failure(
        acceptsResult.error!,
        structuredMessage: acceptsResult.structuredError,
      );
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
      for (
        int length = 0;
        length <= maxLength && acceptedStrings.length < maxResults;
        length++
      ) {
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
      return Failure(
        'Error finding accepted strings: $e',
        structuredMessage: PDASimulationMessages.acceptedStringsFailure(e),
      );
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
      for (
        int length = 0;
        length <= maxLength && rejectedStrings.length < maxResults;
        length++
      ) {
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
      return Failure(
        'Error finding rejected strings: $e',
        structuredMessage: PDASimulationMessages.rejectedStringsFailure(e),
      );
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
        return Failure(
          validationResult.error!,
          structuredMessage: validationResult.structuredError,
        );
      }

      // Handle empty PDA
      if (pda.states.isEmpty) {
        return Failure(
          'Cannot analyze empty PDA',
          structuredMessage: PdaAnalysisMessages.emptyPda(),
        );
      }

      // Handle PDA with no initial state
      if (pda.initialState == null) {
        return Failure(
          'PDA must have an initial state',
          structuredMessage: PDASimulationMessages.missingInitialState(),
        );
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
    } on ArgumentError catch (e) {
      final structuredMessage = maxInputLength < 0
          ? PdaAnalysisMessages.invalidMaxInputLength()
          : timeout <= Duration.zero
          ? PdaAnalysisMessages.invalidTimeout()
          : PdaAnalysisMessages.failure(e);
      return Failure(
        'Error analyzing PDA: $e',
        structuredMessage: structuredMessage,
      );
    } on StateError catch (e) {
      final structuredMessage = e.message == 'PDA analysis timed out'
          ? PdaAnalysisMessages.timedOut()
          : PdaAnalysisMessages.failure(e);
      return Failure(
        'Error analyzing PDA: $e',
        structuredMessage: structuredMessage,
      );
    } catch (e) {
      return Failure(
        'Error analyzing PDA: $e',
        structuredMessage: PdaAnalysisMessages.failure(e),
      );
    }
  }
}
