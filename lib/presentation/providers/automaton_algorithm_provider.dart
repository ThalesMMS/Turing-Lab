//
//  automaton_algorithm_provider.dart
//  Turing Lab
//
//  Manages formal algorithm execution (conversions, minimization,
//  equivalence) on automata, exposing reactive operations that invoke
//  core algorithms and update result state while keeping CRUD operations
//  separated in AutomatonStateProvider.
//
//  Thales Matheus Mendonça Santos - January 2026
//
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/messages/structured_message.dart';
import '../../core/algorithms/dfa_completer.dart';
import '../../core/algorithms/dfa_minimizer.dart';
import '../../core/algorithms/dfa_operations.dart';
import '../../core/algorithms/equivalence_checker.dart';
import '../../core/algorithms/fa_to_regex_converter.dart';
import '../../core/algorithms/fsa_concatenator.dart';
import '../../core/algorithms/fsa_kleene_star.dart';
import '../../core/algorithms/fsa_reverser.dart';
import '../../core/algorithms/fsa_to_grammar_converter.dart';
import '../../core/algorithms/nfa_to_dfa_converter.dart';
import '../../core/algorithms/regex_simplifier.dart';
import '../../core/algorithms/regex_to_nfa_converter.dart';
import '../../core/models/algorithm_step.dart';
import '../../core/models/fsa.dart';
import '../../core/models/grammar.dart';
import 'algorithm_step_provider.dart';
import 'conversion_history_provider.dart';
import 'automaton_state_provider.dart';

/// State for algorithm operations
class AlgorithmOperationState {
  final String? regexResult;
  final String? rawRegexResult;
  final String? simplifiedRegexResult;
  final Grammar? grammarResult;
  final bool? equivalenceResult;
  final String? equivalenceDetails;
  final bool isLoading;
  final String? error;
  final StructuredMessage? structuredError;

  // Step-by-step execution results
  final NFAToDFAConversionResult? nfaToDfaStepResult;
  final DFAMinimizationResult? dfaMinimizationStepResult;
  final FAToRegexConversionResult? faToRegexStepResult;
  final RegexToNFAConversionResult? regexToNfaStepResult;
  final FSAConcatenationResult? fsaConcatenationResult;
  final FSAKleeneStarResult? fsaKleeneStarResult;
  final FSAReversalResult? fsaReversalResult;

  const AlgorithmOperationState({
    this.regexResult,
    this.rawRegexResult,
    this.simplifiedRegexResult,
    this.grammarResult,
    this.equivalenceResult,
    this.equivalenceDetails,
    this.isLoading = false,
    this.error,
    this.structuredError,
    this.nfaToDfaStepResult,
    this.dfaMinimizationStepResult,
    this.faToRegexStepResult,
    this.regexToNfaStepResult,
    this.fsaConcatenationResult,
    this.fsaKleeneStarResult,
    this.fsaReversalResult,
  });

  static const _unset = Object();

  AlgorithmOperationState copyWith({
    Object? regexResult = _unset,
    Object? rawRegexResult = _unset,
    Object? simplifiedRegexResult = _unset,
    Object? grammarResult = _unset,
    Object? equivalenceResult = _unset,
    Object? equivalenceDetails = _unset,
    bool? isLoading,
    Object? error = _unset,
    Object? structuredError = _unset,
    Object? nfaToDfaStepResult = _unset,
    Object? dfaMinimizationStepResult = _unset,
    Object? faToRegexStepResult = _unset,
    Object? regexToNfaStepResult = _unset,
    Object? fsaConcatenationResult = _unset,
    Object? fsaKleeneStarResult = _unset,
    Object? fsaReversalResult = _unset,
  }) {
    final nextError = error == _unset ? this.error : error as String?;
    final nextStructuredError = structuredError == _unset
        ? (error == _unset ? this.structuredError : null)
        : structuredError as StructuredMessage?;
    return AlgorithmOperationState(
      regexResult: regexResult == _unset
          ? this.regexResult
          : regexResult as String?,
      rawRegexResult: rawRegexResult == _unset
          ? this.rawRegexResult
          : rawRegexResult as String?,
      simplifiedRegexResult: simplifiedRegexResult == _unset
          ? this.simplifiedRegexResult
          : simplifiedRegexResult as String?,
      grammarResult: grammarResult == _unset
          ? this.grammarResult
          : grammarResult as Grammar?,
      equivalenceResult: equivalenceResult == _unset
          ? this.equivalenceResult
          : equivalenceResult as bool?,
      equivalenceDetails: equivalenceDetails == _unset
          ? this.equivalenceDetails
          : equivalenceDetails as String?,
      isLoading: isLoading ?? this.isLoading,
      error: nextError,
      structuredError: nextStructuredError,
      nfaToDfaStepResult: nfaToDfaStepResult == _unset
          ? this.nfaToDfaStepResult
          : nfaToDfaStepResult as NFAToDFAConversionResult?,
      dfaMinimizationStepResult: dfaMinimizationStepResult == _unset
          ? this.dfaMinimizationStepResult
          : dfaMinimizationStepResult as DFAMinimizationResult?,
      faToRegexStepResult: faToRegexStepResult == _unset
          ? this.faToRegexStepResult
          : faToRegexStepResult as FAToRegexConversionResult?,
      regexToNfaStepResult: regexToNfaStepResult == _unset
          ? this.regexToNfaStepResult
          : regexToNfaStepResult as RegexToNFAConversionResult?,
      fsaConcatenationResult: fsaConcatenationResult == _unset
          ? this.fsaConcatenationResult
          : fsaConcatenationResult as FSAConcatenationResult?,
      fsaKleeneStarResult: fsaKleeneStarResult == _unset
          ? this.fsaKleeneStarResult
          : fsaKleeneStarResult as FSAKleeneStarResult?,
      fsaReversalResult: fsaReversalResult == _unset
          ? this.fsaReversalResult
          : fsaReversalResult as FSAReversalResult?,
    );
  }

  /// Clear all algorithm results
  AlgorithmOperationState clear() {
    return const AlgorithmOperationState();
  }

  /// Clear only error state
  AlgorithmOperationState clearError() {
    return copyWith(error: null, structuredError: null);
  }
}

/// Provider for automaton algorithm operations
class AutomatonAlgorithmNotifier
    extends StateNotifier<AlgorithmOperationState> {
  final Ref ref;

  AutomatonAlgorithmNotifier(this.ref)
    : super(const AlgorithmOperationState()) {
    // Listen to automaton state changes and clear results when automaton changes
    ref.listen<AutomatonStateProviderState>(automatonStateProvider, (
      previous,
      next,
    ) {
      // Clear algorithm results when the automaton changes
      final previousAutomaton = previous?.currentAutomaton;
      final nextAutomaton = next.currentAutomaton;
      if (!identical(previousAutomaton, nextAutomaton)) {
        state = state.clear();
      }
    });
  }

  /// Converts NFA to DFA
  Future<void> convertNfaToDfa() async {
    final currentAutomaton = ref.read(automatonStateProvider).currentAutomaton;
    if (currentAutomaton == null) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
      structuredError: null,
      equivalenceResult: null,
      equivalenceDetails: null,
    );

    try {
      // Use the core algorithm directly
      final result = NFAToDFAConverter.convert(currentAutomaton);

      if (result.isSuccess) {
        _recordConversionHistory(
          initialAutomaton: currentAutomaton,
          finalAutomaton: result.data!,
        );
        // Update the automaton in the state provider
        ref
            .read(automatonStateProvider.notifier)
            .replaceAutomaton(result.data!);
        state = state.copyWith(isLoading: false);
      } else {
        state = state.copyWith(isLoading: false, error: result.error);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error converting NFA to DFA: $e',
      );
    }
  }

  /// Converts NFA to DFA with step-by-step execution
  Future<void> convertNfaToDfaWithSteps() async {
    final currentAutomaton = ref.read(automatonStateProvider).currentAutomaton;
    if (currentAutomaton == null) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
      structuredError: null,
      equivalenceResult: null,
      equivalenceDetails: null,
      nfaToDfaStepResult: null,
    );

    try {
      // Use the core algorithm with steps
      final result = NFAToDFAConverter.convertWithSteps(currentAutomaton);

      if (result.isSuccess && result.data != null) {
        final conversionResult = result.data!;

        // Update the automaton in the state provider
        ref
            .read(automatonStateProvider.notifier)
            .replaceAutomaton(conversionResult.resultDFA);

        // Store the step result in state
        state = state.copyWith(
          isLoading: false,
          nfaToDfaStepResult: conversionResult,
        );

        // Initialize step provider with algorithm steps
        final algorithmSteps = conversionResult.steps
            .map(
              (step) => step.baseStep.copyWith(properties: step.toProperties()),
            )
            .toList();

        ref
            .read(algorithmStepProvider.notifier)
            .initializeSteps(algorithmSteps);

        _recordConversionHistory(
          initialAutomaton: currentAutomaton,
          finalAutomaton: conversionResult.resultDFA,
          steps: algorithmSteps,
        );
      } else {
        state = state.copyWith(isLoading: false, error: result.error);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error converting NFA to DFA with steps: $e',
      );
    }
  }

  void _recordConversionHistory({
    required FSA initialAutomaton,
    required FSA finalAutomaton,
    List<AlgorithmStep> steps = const [],
  }) {
    final historyNotifier = ref.read(conversionHistoryProvider.notifier);
    historyNotifier.startNewSession(
      algorithmType: AlgorithmType.nfaToDfa,
      initialSnapshot: initialAutomaton.toJson(),
    );
    for (final step in steps) {
      historyNotifier.addStep(algorithmStep: step);
    }
    historyNotifier.setFinalSnapshot(finalAutomaton.toJson());
  }

  /// Minimizes DFA
  Future<void> minimizeDfa() async {
    final currentAutomaton = ref.read(automatonStateProvider).currentAutomaton;
    if (currentAutomaton == null) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
      equivalenceResult: null,
      equivalenceDetails: null,
    );

    try {
      // Use the core algorithm directly
      final result = DFAMinimizer.minimize(currentAutomaton);

      if (result.isSuccess) {
        // Update the automaton in the state provider
        ref
            .read(automatonStateProvider.notifier)
            .replaceAutomaton(result.data!);
        state = state.copyWith(isLoading: false);
      } else {
        state = state.copyWith(isLoading: false, error: result.error);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error minimizing DFA: $e',
      );
    }
  }

  /// Removes lambda transitions from the current FSA.
  Future<void> removeLambdaTransitions() async {
    final currentAutomaton = ref.read(automatonStateProvider).currentAutomaton;
    if (currentAutomaton == null || !currentAutomaton.hasEpsilonTransitions) {
      return;
    }

    state = state.copyWith(
      isLoading: true,
      error: null,
      equivalenceResult: null,
      equivalenceDetails: null,
    );

    try {
      final result = FSAOperations.removeLambdaTransitions(currentAutomaton);

      if (result.isSuccess) {
        ref
            .read(automatonStateProvider.notifier)
            .replaceAutomaton(result.data!);
        state = state.copyWith(isLoading: false);
      } else {
        state = state.copyWith(isLoading: false, error: result.error);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error removing ε-transitions: $e',
      );
    }
  }

  /// Computes the complement of the current DFA.
  Future<void> complementDfa() async {
    final currentAutomaton = ref.read(automatonStateProvider).currentAutomaton;
    if (currentAutomaton == null) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
      equivalenceResult: null,
      equivalenceDetails: null,
    );

    try {
      final result = DFAOperations.complement(currentAutomaton);

      if (result.isSuccess) {
        ref
            .read(automatonStateProvider.notifier)
            .replaceAutomaton(result.data!);
        state = state.copyWith(isLoading: false);
      } else {
        state = state.copyWith(isLoading: false, error: result.error);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error computing DFA complement: $e',
      );
    }
  }

  /// Computes the union of the current DFA and another DFA.
  Future<void> unionDfa(FSA other) async {
    final currentAutomaton = ref.read(automatonStateProvider).currentAutomaton;
    if (currentAutomaton == null) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
      equivalenceResult: null,
      equivalenceDetails: null,
    );

    try {
      final result = DFAOperations.union(currentAutomaton, other);

      if (result.isSuccess) {
        ref
            .read(automatonStateProvider.notifier)
            .replaceAutomaton(result.data!);
        state = state.copyWith(isLoading: false);
      } else {
        state = state.copyWith(isLoading: false, error: result.error);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error computing DFA union: $e',
      );
    }
  }

  /// Concatenates the current FSA language with another FSA language.
  Future<void> concatenateFsa(FSA other, {bool withSteps = false}) async {
    final currentAutomaton = ref.read(automatonStateProvider).currentAutomaton;
    if (currentAutomaton == null) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
      structuredError: null,
      equivalenceResult: null,
      equivalenceDetails: null,
      fsaConcatenationResult: null,
    );

    try {
      final result = FSAConcatenator.concatenate(currentAutomaton, other);

      if (result.isSuccess) {
        final concatenation = result.data!;
        ref
            .read(automatonStateProvider.notifier)
            .replaceAutomaton(concatenation.resultNFA);
        if (withSteps) {
          ref
              .read(algorithmStepProvider.notifier)
              .initializeSteps(concatenation.steps);
        }
        state = state.copyWith(
          isLoading: false,
          fsaConcatenationResult: concatenation,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.error,
          structuredError: result.structuredError,
        );
      }
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error concatenating FSAs: $error',
        structuredError: null,
      );
    }
  }

  /// Applies Kleene star to the current FSA language.
  Future<void> kleeneStarFsa({bool withSteps = false}) async {
    final currentAutomaton = ref.read(automatonStateProvider).currentAutomaton;
    if (currentAutomaton == null) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
      structuredError: null,
      equivalenceResult: null,
      equivalenceDetails: null,
      fsaKleeneStarResult: null,
    );

    try {
      final result = FSAKleeneStar.apply(currentAutomaton);

      if (result.isSuccess) {
        final star = result.data!;
        ref
            .read(automatonStateProvider.notifier)
            .replaceAutomaton(star.resultNFA);
        if (withSteps) {
          ref.read(algorithmStepProvider.notifier).initializeSteps(star.steps);
        }
        state = state.copyWith(isLoading: false, fsaKleeneStarResult: star);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.error,
          structuredError: result.structuredError,
        );
      }
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error applying Kleene star: $error',
        structuredError: null,
      );
    }
  }

  /// Reverses the language of the current FSA.
  Future<void> reverseFsa({bool withSteps = false}) async {
    final currentAutomaton = ref.read(automatonStateProvider).currentAutomaton;
    if (currentAutomaton == null) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
      structuredError: null,
      equivalenceResult: null,
      equivalenceDetails: null,
      fsaReversalResult: null,
    );

    try {
      final result = FSAReverser.reverse(currentAutomaton);

      if (result.isSuccess) {
        final reversal = result.data!;
        ref
            .read(automatonStateProvider.notifier)
            .replaceAutomaton(reversal.resultNFA);
        if (withSteps) {
          ref
              .read(algorithmStepProvider.notifier)
              .initializeSteps(reversal.steps);
        }
        state = state.copyWith(isLoading: false, fsaReversalResult: reversal);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.error,
          structuredError: result.structuredError,
        );
      }
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error reversing FSA: $error',
        structuredError: null,
      );
    }
  }

  /// Computes the intersection of the current DFA and another DFA.
  Future<void> intersectionDfa(FSA other) async {
    final currentAutomaton = ref.read(automatonStateProvider).currentAutomaton;
    if (currentAutomaton == null) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
      equivalenceResult: null,
      equivalenceDetails: null,
    );

    try {
      final result = DFAOperations.intersection(currentAutomaton, other);

      if (result.isSuccess) {
        ref
            .read(automatonStateProvider.notifier)
            .replaceAutomaton(result.data!);
        state = state.copyWith(isLoading: false);
      } else {
        state = state.copyWith(isLoading: false, error: result.error);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error computing DFA intersection: $e',
      );
    }
  }

  /// Computes the language difference between the current DFA and another DFA.
  Future<void> differenceDfa(FSA other) async {
    final currentAutomaton = ref.read(automatonStateProvider).currentAutomaton;
    if (currentAutomaton == null) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
      equivalenceResult: null,
      equivalenceDetails: null,
    );

    try {
      final result = DFAOperations.difference(currentAutomaton, other);

      if (result.isSuccess) {
        ref
            .read(automatonStateProvider.notifier)
            .replaceAutomaton(result.data!);
        state = state.copyWith(isLoading: false);
      } else {
        state = state.copyWith(isLoading: false, error: result.error);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error computing DFA difference: $e',
      );
    }
  }

  /// Computes the prefix closure of the current DFA.
  Future<void> prefixClosureDfa() async {
    final currentAutomaton = ref.read(automatonStateProvider).currentAutomaton;
    if (currentAutomaton == null) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
      equivalenceResult: null,
      equivalenceDetails: null,
    );

    try {
      final result = DFAOperations.prefixClosure(currentAutomaton);

      if (result.isSuccess) {
        ref
            .read(automatonStateProvider.notifier)
            .replaceAutomaton(result.data!);
        state = state.copyWith(isLoading: false);
      } else {
        state = state.copyWith(isLoading: false, error: result.error);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error computing DFA prefix closure: $e',
      );
    }
  }

  /// Computes the suffix closure of the current DFA.
  Future<void> suffixClosureDfa() async {
    final currentAutomaton = ref.read(automatonStateProvider).currentAutomaton;
    if (currentAutomaton == null) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
      equivalenceResult: null,
      equivalenceDetails: null,
    );

    try {
      final result = DFAOperations.suffixClosure(currentAutomaton);

      if (result.isSuccess) {
        ref
            .read(automatonStateProvider.notifier)
            .replaceAutomaton(result.data!);
        state = state.copyWith(isLoading: false);
      } else {
        state = state.copyWith(isLoading: false, error: result.error);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error computing DFA suffix closure: $e',
      );
    }
  }

  /// Minimizes DFA with step-by-step execution
  Future<void> minimizeDfaWithSteps() async {
    final currentAutomaton = ref.read(automatonStateProvider).currentAutomaton;
    if (currentAutomaton == null) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
      equivalenceResult: null,
      equivalenceDetails: null,
      dfaMinimizationStepResult: null,
    );

    try {
      // Use the core algorithm with steps
      final result = DFAMinimizer.minimizeWithSteps(currentAutomaton);

      if (result.isSuccess && result.data != null) {
        final minimizationResult = result.data!;

        // Update the automaton in the state provider
        ref
            .read(automatonStateProvider.notifier)
            .replaceAutomaton(minimizationResult.resultDFA);

        // Store the step result in state
        state = state.copyWith(
          isLoading: false,
          dfaMinimizationStepResult: minimizationResult,
        );

        // Initialize step provider with algorithm steps
        final algorithmSteps = minimizationResult.steps
            .map(
              (step) => step.baseStep.copyWith(properties: step.toProperties()),
            )
            .toList();

        ref
            .read(algorithmStepProvider.notifier)
            .initializeSteps(algorithmSteps);
      } else {
        state = state.copyWith(isLoading: false, error: result.error);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error minimizing DFA with steps: $e',
      );
    }
  }

  /// Completes DFA
  Future<void> completeDfa() async {
    final currentAutomaton = ref.read(automatonStateProvider).currentAutomaton;
    if (currentAutomaton == null) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
      equivalenceResult: null,
      equivalenceDetails: null,
    );

    try {
      final result = DFACompleter.complete(currentAutomaton);
      // Update the automaton in the state provider
      ref.read(automatonStateProvider.notifier).replaceAutomaton(result);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error completing DFA: $e',
      );
    }
  }

  /// Converts FSA to Grammar
  Future<Grammar?> convertFsaToGrammar() async {
    final currentAutomaton = ref.read(automatonStateProvider).currentAutomaton;
    if (currentAutomaton == null) return null;

    state = state.copyWith(isLoading: true, error: null, structuredError: null);

    try {
      final result = FSAToGrammarConverter.tryConvert(currentAutomaton);
      if (!result.isSuccess) {
        state = state.copyWith(
          isLoading: false,
          error: result.error,
          structuredError: result.structuredError,
        );
        return null;
      }
      state = state.copyWith(isLoading: false, grammarResult: result.data);
      return result.data;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error converting FSA to Grammar: $e',
        structuredError: null,
      );
      return null;
    }
  }

  /// Converts regex to NFA
  Future<void> convertRegexToNfa(String regex) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      equivalenceResult: null,
      equivalenceDetails: null,
    );

    try {
      // Use the core algorithm directly
      final result = RegexToNFAConverter.convert(regex);

      if (result.isSuccess) {
        // Update the automaton in the state provider
        ref
            .read(automatonStateProvider.notifier)
            .replaceAutomaton(result.data!);
        state = state.copyWith(isLoading: false);
      } else {
        state = state.copyWith(isLoading: false, error: result.error);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error converting regex to NFA: $e',
      );
    }
  }

  /// Converts regex to NFA with step-by-step execution
  Future<void> convertRegexToNfaWithSteps(String regex) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      equivalenceResult: null,
      equivalenceDetails: null,
      regexToNfaStepResult: null,
    );

    try {
      // Use the core algorithm with steps
      final result = RegexToNFAConverter.convertWithSteps(regex);

      if (result.isSuccess && result.data != null) {
        final conversionResult = result.data!;

        // Update the automaton in the state provider
        ref
            .read(automatonStateProvider.notifier)
            .replaceAutomaton(conversionResult.resultNFA);

        // Store the step result in state
        state = state.copyWith(
          isLoading: false,
          regexToNfaStepResult: conversionResult,
        );

        // Initialize step provider with algorithm steps
        final algorithmSteps = conversionResult.steps
            .map(
              (step) => step.baseStep.copyWith(properties: step.toProperties()),
            )
            .toList();

        ref
            .read(algorithmStepProvider.notifier)
            .initializeSteps(algorithmSteps);
      } else {
        state = state.copyWith(isLoading: false, error: result.error);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error converting regex to NFA with steps: $e',
      );
    }
  }

  /// Converts FA to regex
  Future<String?> convertFaToRegex() async {
    final currentAutomaton = ref.read(automatonStateProvider).currentAutomaton;
    if (currentAutomaton == null) return null;

    state = state.copyWith(isLoading: true, error: null, structuredError: null);

    try {
      // Generate raw regex (without simplification)
      final rawResult = FAToRegexConverter.convert(currentAutomaton);

      if (!rawResult.isSuccess || rawResult.data == null) {
        state = state.copyWith(
          isLoading: false,
          error: rawResult.error,
          structuredError: rawResult.structuredError,
        );
        return null;
      }

      final rawRegex = rawResult.data!;

      // Generate simplified regex
      final simplifyResult = RegexSimplifier.simplify(rawRegex);
      final simplifiedRegex =
          simplifyResult.isSuccess && simplifyResult.data != null
          ? simplifyResult.data!
          : rawRegex; // Fall back to raw if simplification fails

      // Store both versions in state
      state = state.copyWith(
        regexResult:
            simplifiedRegex, // Default to simplified for backward compatibility
        rawRegexResult: rawRegex,
        simplifiedRegexResult: simplifiedRegex,
        isLoading: false,
      );
      return simplifiedRegex;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error converting FA to regex: $e',
        structuredError: null,
      );
      return null;
    }
  }

  /// Converts FA to regex with step-by-step execution
  Future<String?> convertFaToRegexWithSteps() async {
    final currentAutomaton = ref.read(automatonStateProvider).currentAutomaton;
    if (currentAutomaton == null) return null;

    state = state.copyWith(
      isLoading: true,
      error: null,
      structuredError: null,
      faToRegexStepResult: null,
    );

    try {
      // Use the core algorithm with steps
      final result = FAToRegexConverter.convertWithSteps(currentAutomaton);

      if (result.isSuccess && result.data != null) {
        final conversionResult = result.data!;

        // Store both the regex result and step result in state
        state = state.copyWith(
          regexResult: conversionResult.resultRegex,
          isLoading: false,
          faToRegexStepResult: conversionResult,
        );

        // Initialize step provider with algorithm steps
        final algorithmSteps = conversionResult.steps
            .map((step) => step.baseStep)
            .toList();

        ref
            .read(algorithmStepProvider.notifier)
            .initializeSteps(algorithmSteps);

        return conversionResult.resultRegex;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.error,
          structuredError: result.structuredError,
        );
        return null;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error converting FA to regex with steps: $e',
        structuredError: null,
      );
      return null;
    }
  }

  /// Compares the current automaton with another automaton for equivalence
  Future<bool?> compareEquivalence(FSA other) async {
    final currentAutomaton = ref.read(automatonStateProvider).currentAutomaton;
    if (currentAutomaton == null) return null;

    state = state.copyWith(
      isLoading: true,
      error: null,
      equivalenceResult: null,
      equivalenceDetails: null,
    );

    try {
      final equivalenceResult = EquivalenceChecker.areEquivalentResult(
        currentAutomaton,
        other,
      );
      if (equivalenceResult.isFailure) {
        final message = equivalenceResult.error!;
        state = state.copyWith(
          isLoading: false,
          equivalenceResult: null,
          equivalenceDetails: message,
          error: message,
        );
        return null;
      }

      final areEquivalent = equivalenceResult.data!;
      state = state.copyWith(
        isLoading: false,
        equivalenceResult: areEquivalent,
        equivalenceDetails: areEquivalent
            ? 'The automata accept the same language.'
            : 'A distinguishing string was found between the automata.',
      );
      return areEquivalent;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        equivalenceResult: null,
        equivalenceDetails: 'Error comparing automata: $e',
        error: 'Error comparing automata: $e',
      );
      return null;
    }
  }

  /// Clear algorithm results
  void clearAlgorithmResults() {
    state = state.clear();
  }

  /// Clears any error messages
  void clearError() {
    state = state.clearError();
  }

  // Step-by-step navigation methods (delegate to AlgorithmStepProvider)

  /// Navigate to the next step
  void nextStep() {
    ref.read(algorithmStepProvider.notifier).nextStep();
  }

  /// Navigate to the previous step
  void previousStep() {
    ref.read(algorithmStepProvider.notifier).previousStep();
  }

  /// Jump to a specific step by index
  void setCurrentStep(int index) {
    ref.read(algorithmStepProvider.notifier).jumpToStep(index);
  }

  /// Toggle play/pause for auto-stepping
  void togglePlayPause() {
    ref.read(algorithmStepProvider.notifier).togglePlayPause();
  }

  /// Reset step navigation to the beginning
  void resetSteps() {
    ref.read(algorithmStepProvider.notifier).reset();
  }

  /// Clear all steps
  void clearSteps() {
    ref.read(algorithmStepProvider.notifier).clearSteps();
  }
}

/// Provider registration for automaton algorithm operations
final automatonAlgorithmProvider =
    StateNotifierProvider<AutomatonAlgorithmNotifier, AlgorithmOperationState>(
      (ref) => AutomatonAlgorithmNotifier(ref),
    );
