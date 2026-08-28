//
//  nfa_to_dfa_converter.dart
//  Turing Lab
//
//  Converts nondeterministic finite automata into deterministic automata
//  using subset construction with ε-closures. Includes validation,
//  lambda-transition cleanup, and creation of the deterministic structures
//  while preserving states, symbols, and acceptance.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'dart:collection';

import 'package:vector_math/vector_math_64.dart';
import '../models/fsa.dart';
import '../models/state.dart';
import '../models/fsa_transition.dart';
import '../models/nfa_to_dfa_step.dart';
import '../messages/structured_message.dart';
import '../result.dart';
import '../utils/epsilon_utils.dart';
import 'nfa_to_dfa_messages.dart';
import 'state_renamer.dart';

/// Converts Non-deterministic Finite Automata (NFA) to Deterministic Finite Automata (DFA)
class NFAToDFAConverter {
  /// Converts an NFA to an equivalent DFA
  static Result<FSA> convert(FSA nfa) {
    try {
      // Validate input
      final validationResult = _validateInput(nfa);
      if (!validationResult.isSuccess) {
        return Failure(
          validationResult.error!,
          structuredMessage: validationResult.structuredError,
        );
      }

      // Handle empty NFA
      if (nfa.states.isEmpty) {
        return _failure(
          'Cannot convert empty NFA to DFA',
          NfaToDfaMessages.emptyAutomaton(),
        );
      }

      // Handle NFA with no initial state
      if (nfa.initialState == null) {
        return _failure(
          'NFA must have an initial state',
          NfaToDfaMessages.missingInitialState(),
        );
      }

      // Build DFA directly from NFA using epsilon-closures in subset construction
      var dfa = _buildDFAWithEpsilon(nfa);

      // Rename labels to q0, q1, q2... and apply circular layout
      dfa = StateRenamer.renameAndLayout(dfa);

      return ResultFactory.success(dfa);
    } catch (e) {
      return _conversionFailure(e, withSteps: false);
    }
  }

  /// Validates the input NFA
  static Result<void> _validateInput(FSA nfa) {
    if (nfa.states.isEmpty) {
      return Failure(
        'NFA must have at least one state',
        structuredMessage: NfaToDfaMessages.emptyAutomaton(),
      );
    }

    if (nfa.initialState == null) {
      return Failure(
        'NFA must have an initial state',
        structuredMessage: NfaToDfaMessages.missingInitialState(),
      );
    }

    if (!nfa.states.contains(nfa.initialState)) {
      return Failure(
        'Initial state must be in the states set',
        structuredMessage: NfaToDfaMessages.initialStateOutsideSet(),
      );
    }

    for (final acceptingState in nfa.acceptingStates) {
      if (!nfa.states.contains(acceptingState)) {
        return Failure(
          'Accepting state must be in the states set',
          structuredMessage: NfaToDfaMessages.acceptingStateOutsideSet(),
        );
      }
    }

    return ResultFactory.success(null);
  }

  /// Builds DFA using subset construction with epsilon-closures over the original NFA.
  /// Optionally records the educational steps produced by the same construction.
  static FSA _buildDFAWithEpsilon(FSA nfa, {List<NFAToDFAStep>? steps}) {
    final dfaStates = <String, State>{};
    final dfaTransitions = <FSATransition>{};
    final dfaAcceptingStates = <State>{};
    final queue = Queue<String>();
    final processed = <String>{};
    final stateSetMap = <String, Set<State>>{};
    var stepCounter = 1;

    // Start with the epsilon-closure of the initial state
    final initialStateSet = nfa.getEpsilonClosure(nfa.initialState!);
    final initialStateKey = _getStateSetKey(initialStateSet);
    final initialState = _createDFAState(initialStateSet, 0);
    dfaStates[initialStateKey] = initialState;
    stateSetMap[initialStateKey] = initialStateSet;
    queue.add(initialStateKey);

    if (steps != null) {
      steps.add(
        NFAToDFAStep.initialEpsilonClosure(
          id: 'step_$stepCounter',
          stepNumber: stepCounter++,
          initialState: nfa.initialState!,
          epsilonClosure: initialStateSet,
          containsAcceptingState: initialStateSet
              .intersection(nfa.acceptingStates)
              .isNotEmpty,
        ),
      );
    }

    // Process each state set
    int stateCounter = 1;
    // Keep this hard ceiling in sync with docs/reference-deviations.md.
    // Mobile profiles start thrashing well before the theoretical 2^n bound;
    // clamping at 1 000 states prevents OOM freezes during subset expansion.
    const int maxStates = 1000;
    while (queue.isNotEmpty) {
      final currentStateKey = queue.removeFirst();
      if (processed.contains(currentStateKey)) continue;
      processed.add(currentStateKey);

      final currentStateSet = stateSetMap[currentStateKey]!;

      final currentDFAState = dfaStates[currentStateKey]!;

      // Check if this state set contains any accepting states
      if (currentStateSet.intersection(nfa.acceptingStates).isNotEmpty) {
        dfaAcceptingStates.add(currentDFAState);
      }

      // For each symbol in the alphabet (excluding epsilon-like markers)
      final workingAlphabet = nfa.alphabet
          .where((s) => !isEpsilonSymbol(s))
          .toSet();
      for (final symbol in workingAlphabet) {
        final reachableBeforeEpsilon = <State>{};

        // Move on symbol.
        for (final state in currentStateSet) {
          final transitions = nfa
              .getTransitionsFromStateOnSymbol(state, symbol)
              .toList();
          for (final transition in transitions) {
            reachableBeforeEpsilon.add(transition.toState);
          }
        }

        if (steps != null && reachableBeforeEpsilon.isNotEmpty) {
          steps.add(
            NFAToDFAStep.processSymbol(
              id: 'step_$stepCounter',
              stepNumber: stepCounter++,
              currentStateSet: currentStateSet,
              symbol: symbol,
              reachableStates: reachableBeforeEpsilon,
            ),
          );
        }

        final nextStateSet = <State>{};
        for (final state in reachableBeforeEpsilon) {
          nextStateSet.addAll(nfa.getEpsilonClosure(state));
        }

        if (nextStateSet.isNotEmpty) {
          final nextStateKey = _getStateSetKey(nextStateSet);
          final isNewState = !dfaStates.containsKey(nextStateKey);
          final containsAcceptingState = nextStateSet
              .intersection(nfa.acceptingStates)
              .isNotEmpty;

          if (steps != null) {
            steps.add(
              NFAToDFAStep.epsilonClosureOfReachable(
                id: 'step_$stepCounter',
                stepNumber: stepCounter++,
                reachableStates: reachableBeforeEpsilon,
                epsilonClosure: nextStateSet,
                containsAcceptingState: containsAcceptingState,
                isNewState: isNewState,
              ),
            );
          }

          // Create or get the DFA state for this set
          State nextDFAState;
          if (dfaStates.containsKey(nextStateKey)) {
            nextDFAState = dfaStates[nextStateKey]!;
          } else {
            if (stateCounter >= maxStates) {
              throw StateError(
                'Exceeded maximum number of DFA states ($maxStates) during subset construction.',
              );
            }
            nextDFAState = _createDFAState(nextStateSet, stateCounter);
            dfaStates[nextStateKey] = nextDFAState;
            stateSetMap[nextStateKey] = nextStateSet;
            queue.add(nextStateKey);

            if (steps != null) {
              steps.add(
                NFAToDFAStep.createDFAState(
                  id: 'step_$stepCounter',
                  stepNumber: stepCounter++,
                  nfaStateSet: nextStateSet,
                  dfaStateId: nextDFAState.id,
                  dfaStateLabel: nextDFAState.label,
                  isAccepting: containsAcceptingState,
                ),
              );
            }
            stateCounter++;
          }

          // Add transition
          final transition = FSATransition.deterministic(
            id: 't_${currentDFAState.id}_${symbol}_${nextDFAState.id}',
            fromState: currentDFAState,
            toState: nextDFAState,
            symbol: symbol,
          );
          dfaTransitions.add(transition);

          if (steps != null) {
            steps.add(
              NFAToDFAStep.createDFATransition(
                id: 'step_$stepCounter',
                stepNumber: stepCounter++,
                fromStateSet: currentStateSet,
                fromDfaStateId: currentDFAState.id,
                symbol: symbol,
                toStateSet: nextStateSet,
                toDfaStateId: nextDFAState.id,
              ),
            );
          }
        }
      }
    }

    if (steps != null) {
      steps.add(
        NFAToDFAStep.completion(
          id: 'step_$stepCounter',
          stepNumber: stepCounter,
          totalStates: dfaStates.length,
          totalTransitions: dfaTransitions.length,
          totalAcceptingStates: dfaAcceptingStates.length,
        ),
      );
    }

    // Fix: set isAccepting on state objects so that downstream code
    // (e.g. auto-layout, export) that inspects State.isAccepting stays
    // consistent with the FSA acceptingStates set.
    final acceptingIds = dfaAcceptingStates.map((s) => s.id).toSet();
    final fixedStates = <String, State>{};
    for (final entry in dfaStates.entries) {
      final s = entry.value;
      fixedStates[entry.key] = acceptingIds.contains(s.id)
          ? s.copyWith(isAccepting: true)
          : s;
    }
    final fixedInitialState = fixedStates.values.firstWhere(
      (s) => s.isInitial,
      orElse: () => initialState,
    );
    final fixedAcceptingStates = fixedStates.values
        .where((s) => s.isAccepting)
        .toSet();
    final statesById = <String, State>{
      for (final s in fixedStates.values) s.id: s,
    };
    final fixedTransitions = dfaTransitions.map((t) {
      return t.copyWith(
        fromState: statesById[t.fromState.id] ?? t.fromState,
        toState: statesById[t.toState.id] ?? t.toState,
      );
    }).toSet();

    // Create the DFA
    return FSA(
      id: '${nfa.id}_dfa',
      name: '${nfa.name} (DFA)',
      states: fixedStates.values.toSet(),
      transitions: fixedTransitions,
      alphabet: nfa.alphabet.where((s) => !isEpsilonSymbol(s)).toSet(),
      initialState: fixedInitialState,
      acceptingStates: fixedAcceptingStates,
      created: nfa.created,
      modified: DateTime.now(),
      bounds: nfa.bounds,
      zoomLevel: nfa.zoomLevel,
      panOffset: nfa.panOffset,
    );
  }

  /// Creates a string key for a set of states
  static String _getStateSetKey(Set<State> stateSet) {
    final stateIds = stateSet.map((s) => s.id).toList()..sort();
    return stateIds.join(',');
  }

  /// Creates a DFA state from a set of NFA states
  static State _createDFAState(Set<State> stateSet, int counter) {
    final stateIds = stateSet.map((s) => s.id).toList()..sort();
    final stateId = 'q${counter}_${stateIds.join('_')}';
    final stateLabel = '{${stateIds.join(',')}}';

    // Calculate position as center of the states
    double sumX = 0;
    double sumY = 0;
    for (final state in stateSet) {
      sumX += state.position.x;
      sumY += state.position.y;
    }
    final position = Vector2(sumX / stateSet.length, sumY / stateSet.length);

    return State(
      id: stateId,
      label: stateLabel,
      position: position,
      isInitial: counter == 0,
      isAccepting: false, // Will be set later
    );
  }

  /// Converts an NFA to DFA with step-by-step information
  static Result<NFAToDFAConversionResult> convertWithSteps(FSA nfa) {
    try {
      final stopwatch = Stopwatch()..start();
      final steps = <NFAToDFAStep>[];

      // Validate input
      final validationResult = _validateInput(nfa);
      if (!validationResult.isSuccess) {
        return Failure(
          validationResult.error!,
          structuredMessage: validationResult.structuredError,
        );
      }

      // Handle empty NFA
      if (nfa.states.isEmpty) {
        return _failure(
          'Cannot convert empty NFA to DFA',
          NfaToDfaMessages.emptyAutomaton(),
        );
      }

      // Handle NFA with no initial state
      if (nfa.initialState == null) {
        return _failure(
          'NFA must have an initial state',
          NfaToDfaMessages.missingInitialState(),
        );
      }

      // Build DFA with detailed step capture
      var dfa = _buildDFAWithEpsilon(nfa, steps: steps);

      // Rename labels to q0, q1, q2... and apply circular layout
      dfa = StateRenamer.renameAndLayout(dfa);

      stopwatch.stop();

      final result = NFAToDFAConversionResult(
        originalNFA: nfa,
        resultDFA: dfa,
        steps: steps,
        executionTime: stopwatch.elapsed,
      );

      return ResultFactory.success(result);
    } catch (e) {
      return _conversionFailure(e, withSteps: true);
    }
  }

  static Result<T> _failure<T>(
    String legacyMessage,
    StructuredMessage message,
  ) => Failure(legacyMessage, structuredMessage: message);

  static Result<T> _conversionFailure<T>(
    Object error, {
    required bool withSteps,
  }) {
    final errorText = error.toString();
    final stateLimit = RegExp(
      r'Exceeded maximum number of DFA states \((\d+)\)',
    ).firstMatch(errorText);
    final limit = stateLimit == null
        ? null
        : int.tryParse(stateLimit.group(1)!);
    final legacyMessage = withSteps
        ? 'Error converting NFA to DFA with steps: $error'
        : 'Error converting NFA to DFA: $error';
    if (limit != null) {
      return _failure(
        legacyMessage,
        NfaToDfaMessages.stateLimitExceeded(limit),
      );
    }
    return _failure(
      legacyMessage,
      NfaToDfaMessages.conversionFailed(error: error, withSteps: withSteps),
    );
  }
}

/// Result of NFA to DFA conversion with step-by-step information
class NFAToDFAConversionResult {
  /// Original NFA
  final FSA originalNFA;

  /// Resulting DFA
  final FSA resultDFA;

  /// Detailed conversion steps
  final List<NFAToDFAStep> steps;

  /// Execution time
  final Duration executionTime;

  const NFAToDFAConversionResult({
    required this.originalNFA,
    required this.resultDFA,
    required this.steps,
    required this.executionTime,
  });

  /// Gets the number of steps
  int get stepCount => steps.length;

  /// Gets the first step
  NFAToDFAStep? get firstStep => steps.isNotEmpty ? steps.first : null;

  /// Gets the last step
  NFAToDFAStep? get lastStep => steps.isNotEmpty ? steps.last : null;

  /// Gets the execution time in milliseconds
  int get executionTimeMs => executionTime.inMilliseconds;

  /// Gets the execution time in seconds
  double get executionTimeSeconds => executionTime.inMicroseconds / 1000000.0;
}
