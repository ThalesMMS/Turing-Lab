//
//  fa_to_regex_converter.dart
//  Turing Lab
//
//  Implements the state-elimination method to convert finite automata into
//  equivalent regular expressions. Normalizes the structure so that there
//  are unique initial and final states, validates automaton integrity, and
//  iteratively rewrites transitions to produce the resulting expression
//  wrapped in `Result`.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:vector_math/vector_math_64.dart';
import '../models/fsa.dart';
import '../models/state.dart';
import '../models/fsa_transition.dart';
import '../models/fa_to_regex_step.dart';
import '../result.dart';
import 'regex_simplifier.dart';

/// Converts Finite Automata (FA) to Regular Expressions using the state elimination method
class FAToRegexConverter {
  static const String _epsilonRegex = '\u03B5';
  static const String _lambdaRegex = '\u03BB';

  /// Converts a Finite Automaton to an equivalent regular expression
  ///
  /// If [simplify] is true, applies algebraic simplification to produce
  /// a more readable regex. Defaults to false for backward compatibility.
  static Result<String> convert(FSA fa, {bool simplify = false}) {
    try {
      // Validate input
      final validationResult = _validateInput(fa);
      if (!validationResult.isSuccess) {
        return ResultFactory.failure(validationResult.error!);
      }

      // Handle empty automaton
      if (fa.states.isEmpty) {
        return ResultFactory.failure('Cannot convert empty automaton to regex');
      }

      // Handle automaton with no initial state
      if (fa.initialState == null) {
        return ResultFactory.failure('Automaton must have an initial state');
      }

      // Step 1: Ensure single initial and final states
      final faWithSingleStates = _ensureSingleInitialAndFinalStates(fa);

      // Step 2: Apply state elimination algorithm
      final regex = _stateElimination(faWithSingleStates);

      // Step 3: Apply simplification if requested
      if (simplify) {
        final simplificationResult = RegexSimplifier.simplify(regex);
        if (!simplificationResult.isSuccess) {
          return ResultFactory.failure(
            'FA conversion succeeded but simplification failed: ${simplificationResult.error}',
          );
        }
        return ResultFactory.success(simplificationResult.data!);
      }

      return ResultFactory.success(regex);
    } catch (e) {
      return ResultFactory.failure('Error converting FA to regex: $e');
    }
  }

  /// Validates the input FA
  static Result<void> _validateInput(FSA fa) {
    if (fa.states.isEmpty) {
      return ResultFactory.failure('FA must have at least one state');
    }

    if (fa.initialState == null) {
      return ResultFactory.failure('FA must have an initial state');
    }

    if (!fa.states.contains(fa.initialState)) {
      return ResultFactory.failure('Initial state must be in the states set');
    }

    for (final acceptingState in fa.acceptingStates) {
      if (!fa.states.contains(acceptingState)) {
        return ResultFactory.failure(
          'Accepting state must be in the states set',
        );
      }
    }

    return ResultFactory.success(null);
  }

  static String _uniqueStateId(Set<State> states, String baseId) {
    if (!states.any((state) => state.id == baseId)) {
      return baseId;
    }

    var suffix = 1;
    var candidate = '${baseId}_$suffix';
    while (states.any((state) => state.id == candidate)) {
      suffix++;
      candidate = '${baseId}_$suffix';
    }
    return candidate;
  }

  static bool _isEpsilonRegex(String regex) {
    return regex == _epsilonRegex || regex == _lambdaRegex;
  }

  static String _transitionRegex(FSATransition transition) {
    if (transition.isEpsilonTransition) {
      return _epsilonRegex;
    }
    if (transition.label.isNotEmpty) {
      return transition.label;
    }
    return _unionRegex(transition.inputSymbols);
  }

  static String _unionRegex(Iterable<String> regexes) {
    final parts = <String>[];
    for (final regex in regexes) {
      if (regex.isEmpty || parts.contains(regex)) {
        continue;
      }
      parts.add(regex);
    }

    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.single;
    return '(${parts.join('|')})';
  }

  static String _starRegex(String regex) {
    if (regex.isEmpty) return '';
    if (_isEpsilonRegex(regex)) return _epsilonRegex;
    return '($regex)*';
  }

  static String _concatRegex(Iterable<String> regexes) {
    final parts = <String>[];
    for (final regex in regexes) {
      if (regex.isEmpty || _isEpsilonRegex(regex)) {
        continue;
      }
      parts.add(regex);
    }
    return parts.isEmpty ? _epsilonRegex : parts.join();
  }

  static String _regexBetween(
    Iterable<FSATransition> transitions,
    State fromState,
    State toState,
  ) {
    return _unionRegex(
      transitions
          .where(
            (transition) =>
                transition.fromState == fromState &&
                transition.toState == toState,
          )
          .map(_transitionRegex),
    );
  }

  static FSATransition _addOrUnionTransition(
    Set<FSATransition> transitions, {
    required State fromState,
    required State toState,
    required String regex,
    required String id,
  }) {
    final existingTransitions = transitions
        .where(
          (transition) =>
              transition.fromState == fromState &&
              transition.toState == toState,
        )
        .toList();
    final combinedRegex = _unionRegex([
      ...existingTransitions.map(_transitionRegex),
      regex,
    ]);

    for (final transition in existingTransitions) {
      transitions.remove(transition);
    }

    final combinedTransition = FSATransition(
      id: id,
      fromState: fromState,
      toState: toState,
      label: combinedRegex,
      inputSymbols: {combinedRegex},
    );
    transitions.add(combinedTransition);
    return combinedTransition;
  }

  /// Ensures the FA has a single initial state and a single final state
  static FSA _ensureSingleInitialAndFinalStates(FSA fa) {
    return _buildSingleInitialAndFinalStates(fa);
  }

  static FSA _buildSingleInitialAndFinalStates(
    FSA fa, {
    List<FAToRegexStep>? steps,
  }) {
    final now = DateTime.now();

    // JFLAP-style state elimination always normalizes through fresh synthetic
    // endpoints so self-loops and accepting initial states behave uniformly.
    final newInitialState = State(
      id: _uniqueStateId(fa.states, 'q_initial'),
      label: 'q_initial',
      position: Vector2(50, 100),
      isInitial: true,
      isAccepting: false,
    );
    final statesWithInitial = {...fa.states, newInitialState};
    final newFinalState = State(
      id: _uniqueStateId(statesWithInitial, 'q_final'),
      label: 'q_final',
      position: Vector2(350, 100),
      isInitial: false,
      isAccepting: true,
    );

    final newStates = Set<State>.from(fa.states)
      ..add(newInitialState)
      ..add(newFinalState);
    final newTransitions = Set<FSATransition>.from(fa.fsaTransitions);

    if (steps != null) {
      steps.add(
        FAToRegexStep.addInitialState(
          id: 'step_${steps.length + 1}',
          stepNumber: steps.length + 1,
          oldInitialState: fa.initialState!,
          newInitialState: newInitialState,
        ),
      );
    }

    newTransitions.add(
      FSATransition.epsilon(
        id: 't_eps_${newInitialState.id}_${fa.initialState!.id}',
        fromState: newInitialState,
        toState: fa.initialState!,
        label: _epsilonRegex,
      ),
    );

    if (steps != null) {
      steps.add(
        FAToRegexStep.addFinalState(
          id: 'step_${steps.length + 1}',
          stepNumber: steps.length + 1,
          oldAcceptingStates: fa.acceptingStates,
          newFinalState: newFinalState,
        ),
      );
    }

    for (final acceptingState in fa.acceptingStates) {
      newTransitions.add(
        FSATransition.epsilon(
          id: 't_eps_${acceptingState.id}_${newFinalState.id}',
          fromState: acceptingState,
          toState: newFinalState,
          label: _epsilonRegex,
        ),
      );
    }

    return FSA(
      id: '${fa.id}_single_states',
      name: '${fa.name} (Single States)',
      states: newStates,
      transitions: newTransitions,
      alphabet: fa.alphabet,
      initialState: newInitialState,
      acceptingStates: {newFinalState},
      created: fa.created,
      modified: now,
      bounds: fa.bounds,
      zoomLevel: fa.zoomLevel,
      panOffset: fa.panOffset,
    );
  }

  /// Applies the state elimination algorithm
  static String _stateElimination(FSA fa) {
    // Create a copy of the FA for modification
    var currentFA = fa;

    // Get all non-initial, non-final states
    final statesToEliminate = currentFA.states
        .where(
          (state) =>
              state != currentFA.initialState &&
              !currentFA.acceptingStates.contains(state),
        )
        .toList();

    // Eliminate states one by one
    for (final stateToEliminate in statesToEliminate) {
      currentFA = _eliminateState(currentFA, stateToEliminate);
    }

    // Extract regex from the final automaton
    return _extractRegexFromFinalFA(currentFA);
  }

  /// Eliminates a single state from the FA
  static FSA _eliminateState(FSA fa, State stateToEliminate) {
    final newTransitions = <FSATransition>{};
    final newStates = fa.states.where((s) => s != stateToEliminate).toSet();

    // Keep all transitions not involving the state to eliminate
    for (final transition in fa.fsaTransitions) {
      if (transition.fromState != stateToEliminate &&
          transition.toState != stateToEliminate) {
        newTransitions.add(transition);
      }
    }

    // Find all states that have transitions to the state to eliminate
    final incomingStates = <State>{};
    final incomingTransitions = <FSATransition>[];
    for (final transition in fa.fsaTransitions) {
      if (transition.toState == stateToEliminate &&
          transition.fromState != stateToEliminate) {
        incomingStates.add(transition.fromState);
        incomingTransitions.add(transition);
      }
    }

    // Find all states that have transitions from the state to eliminate
    final outgoingStates = <State>{};
    final outgoingTransitions = <FSATransition>[];
    for (final transition in fa.fsaTransitions) {
      if (transition.fromState == stateToEliminate &&
          transition.toState != stateToEliminate) {
        outgoingStates.add(transition.toState);
        outgoingTransitions.add(transition);
      }
    }

    final selfLoopRegex = _starRegex(
      _regexBetween(fa.fsaTransitions, stateToEliminate, stateToEliminate),
    );

    // Create new transitions for all combinations of incoming and outgoing states
    for (final incomingState in incomingStates) {
      for (final outgoingState in outgoingStates) {
        final incomingRegex = _regexBetween(
          incomingTransitions,
          incomingState,
          stateToEliminate,
        );
        final outgoingRegex = _regexBetween(
          outgoingTransitions,
          stateToEliminate,
          outgoingState,
        );
        if (incomingRegex.isEmpty || outgoingRegex.isEmpty) {
          continue;
        }

        final pathRegex = _concatRegex([
          incomingRegex,
          selfLoopRegex,
          outgoingRegex,
        ]);

        _addOrUnionTransition(
          newTransitions,
          fromState: incomingState,
          toState: outgoingState,
          regex: pathRegex,
          id: 't_combined_${incomingState.id}_${outgoingState.id}',
        );
      }
    }

    return FSA(
      id: '${fa.id}_eliminated_${stateToEliminate.id}',
      name: '${fa.name} (Eliminated ${stateToEliminate.id})',
      states: newStates,
      transitions: newTransitions,
      alphabet: fa.alphabet,
      initialState: fa.initialState,
      acceptingStates: fa.acceptingStates,
      created: fa.created,
      modified: DateTime.now(),
      bounds: fa.bounds,
      zoomLevel: fa.zoomLevel,
      panOffset: fa.panOffset,
    );
  }

  /// Extracts the regex from the final FA (with only initial and final states)
  static String _extractRegexFromFinalFA(FSA fa) {
    final initialState = fa.initialState!;
    final finalState = fa.acceptingStates.first;

    // Find all transitions from initial to final state
    final transitions = fa.fsaTransitions
        .where((t) => t.fromState == initialState && t.toState == finalState)
        .toList();

    if (transitions.isEmpty) {
      return '∅'; // Empty language
    }

    return _unionRegex(transitions.map(_transitionRegex));
  }

  /// Ensures single initial and final states with detailed step capture
  static FSA _ensureSingleInitialAndFinalStatesWithSteps(
    FSA fa,
    List<FAToRegexStep> steps,
  ) {
    return _buildSingleInitialAndFinalStates(fa, steps: steps);
  }

  /// Applies state elimination algorithm with detailed step capture
  static String _stateEliminationWithSteps(FSA fa, List<FAToRegexStep> steps) {
    // Create a copy of the FA for modification
    var currentFA = fa;

    // Get all non-initial, non-final states
    final statesToEliminate = currentFA.states
        .where(
          (state) =>
              state != currentFA.initialState &&
              !currentFA.acceptingStates.contains(state),
        )
        .toList();

    // Eliminate states one by one
    for (final stateToEliminate in statesToEliminate) {
      currentFA = _eliminateStateWithSteps(currentFA, stateToEliminate, steps);
    }

    // Extract regex from the final automaton
    final regex = _extractRegexFromFinalFA(currentFA);

    // Add regex extraction step
    steps.add(
      FAToRegexStep.extractRegex(
        id: 'step_${steps.length + 1}',
        stepNumber: steps.length + 1,
        regex: regex,
        initialState: currentFA.initialState!,
        finalState: currentFA.acceptingStates.first,
      ),
    );

    return regex;
  }

  /// Eliminates a single state with detailed step capture
  static FSA _eliminateStateWithSteps(
    FSA fa,
    State stateToEliminate,
    List<FAToRegexStep> steps,
  ) {
    final newTransitions = <FSATransition>{};
    final newStates = fa.states.where((s) => s != stateToEliminate).toSet();

    // Step 1: Select state to eliminate
    steps.add(
      FAToRegexStep.selectStateToEliminate(
        id: 'step_${steps.length + 1}',
        stepNumber: steps.length + 1,
        state: stateToEliminate,
        remainingStates: newStates.length,
      ),
    );

    // Keep all transitions not involving the state to eliminate
    for (final transition in fa.fsaTransitions) {
      if (transition.fromState != stateToEliminate &&
          transition.toState != stateToEliminate) {
        newTransitions.add(transition);
      }
    }

    // Step 2: Find all states that have transitions to the state to eliminate
    final incomingStates = <State>{};
    final incomingTransitions = <FSATransition>[];
    for (final transition in fa.fsaTransitions) {
      if (transition.toState == stateToEliminate &&
          transition.fromState != stateToEliminate) {
        incomingStates.add(transition.fromState);
        incomingTransitions.add(transition);
      }
    }

    steps.add(
      FAToRegexStep.findIncomingTransitions(
        id: 'step_${steps.length + 1}',
        stepNumber: steps.length + 1,
        eliminatedState: stateToEliminate,
        incomingStates: incomingStates,
        incomingTransitions: incomingTransitions.toSet(),
      ),
    );

    // Step 3: Find all states that have transitions from the state to eliminate
    final outgoingStates = <State>{};
    final outgoingTransitions = <FSATransition>[];
    for (final transition in fa.fsaTransitions) {
      if (transition.fromState == stateToEliminate &&
          transition.toState != stateToEliminate) {
        outgoingStates.add(transition.toState);
        outgoingTransitions.add(transition);
      }
    }

    steps.add(
      FAToRegexStep.findOutgoingTransitions(
        id: 'step_${steps.length + 1}',
        stepNumber: steps.length + 1,
        eliminatedState: stateToEliminate,
        outgoingStates: outgoingStates,
        outgoingTransitions: outgoingTransitions.toSet(),
      ),
    );

    // Step 4: Find self-loop on the state to eliminate
    final selfLoopTransitions = fa.fsaTransitions
        .where(
          (transition) =>
              transition.fromState == stateToEliminate &&
              transition.toState == stateToEliminate,
        )
        .toList();
    final selfLoopRegex = _starRegex(
      _unionRegex(selfLoopTransitions.map(_transitionRegex)),
    );

    steps.add(
      FAToRegexStep.findSelfLoop(
        id: 'step_${steps.length + 1}',
        stepNumber: steps.length + 1,
        eliminatedState: stateToEliminate,
        selfLoopTransitions: selfLoopTransitions.toSet(),
        selfLoopRegex: selfLoopRegex.isNotEmpty ? selfLoopRegex : _epsilonRegex,
      ),
    );

    // Step 5: Create new transitions for all combinations of incoming and outgoing states
    final createdTransitions = <FSATransition>[];
    for (final incomingState in incomingStates) {
      for (final outgoingState in outgoingStates) {
        final incomingRegex = _regexBetween(
          incomingTransitions,
          incomingState,
          stateToEliminate,
        );
        final outgoingRegex = _regexBetween(
          outgoingTransitions,
          stateToEliminate,
          outgoingState,
        );
        if (incomingRegex.isEmpty || outgoingRegex.isEmpty) {
          continue;
        }

        final pathRegex = _concatRegex([
          incomingRegex,
          selfLoopRegex,
          outgoingRegex,
        ]);
        final newTransition = _addOrUnionTransition(
          newTransitions,
          fromState: incomingState,
          toState: outgoingState,
          regex: pathRegex,
          id: 't_combined_${incomingState.id}_${outgoingState.id}',
        );
        createdTransitions.add(newTransition);
      }
    }

    if (createdTransitions.isNotEmpty) {
      steps.add(
        FAToRegexStep.createBypassTransitions(
          id: 'step_${steps.length + 1}',
          stepNumber: steps.length + 1,
          eliminatedState: stateToEliminate,
          newTransitions: createdTransitions.toSet(),
          pathRegexExample: createdTransitions.first.label,
        ),
      );
    }

    // Step 6: Complete elimination
    steps.add(
      FAToRegexStep.completeElimination(
        id: 'step_${steps.length + 1}',
        stepNumber: steps.length + 1,
        eliminatedState: stateToEliminate,
        remainingStates: newStates.length,
      ),
    );

    return FSA(
      id: '${fa.id}_eliminated_${stateToEliminate.id}',
      name: '${fa.name} (Eliminated ${stateToEliminate.id})',
      states: newStates,
      transitions: newTransitions,
      alphabet: fa.alphabet,
      initialState: fa.initialState,
      acceptingStates: fa.acceptingStates,
      created: fa.created,
      modified: DateTime.now(),
      bounds: fa.bounds,
      zoomLevel: fa.zoomLevel,
      panOffset: fa.panOffset,
    );
  }

  /// Converts FA to regex with step-by-step information
  static Result<FAToRegexConversionResult> convertWithSteps(FSA fa) {
    try {
      final stopwatch = Stopwatch()..start();
      final steps = <FAToRegexStep>[];

      // Validate input
      final validationResult = _validateInput(fa);
      if (!validationResult.isSuccess) {
        return ResultFactory.failure(validationResult.error!);
      }

      // Handle empty automaton
      if (fa.states.isEmpty) {
        return ResultFactory.failure('Cannot convert empty automaton to regex');
      }

      // Handle automaton with no initial state
      if (fa.initialState == null) {
        return ResultFactory.failure('Automaton must have an initial state');
      }

      // Capture validation step
      steps.add(
        FAToRegexStep.validation(
          id: 'step_${steps.length + 1}',
          stepNumber: steps.length + 1,
          stateCount: fa.states.length,
          transitionCount: fa.fsaTransitions.length,
          hasInitialState: fa.initialState != null,
          hasAcceptingStates: fa.acceptingStates.isNotEmpty,
        ),
      );

      // Ensure single initial and final states with step capture
      final faWithSingleStates = _ensureSingleInitialAndFinalStatesWithSteps(
        fa,
        steps,
      );

      // Apply state elimination with detailed step capture
      final regex = _stateEliminationWithSteps(faWithSingleStates, steps);

      // Add completion step
      steps.add(
        FAToRegexStep.completion(
          id: 'step_${steps.length + 1}',
          stepNumber: steps.length + 1,
          finalRegex: regex,
          originalStates: fa.states.length,
          stepsExecuted: steps.length,
        ),
      );

      stopwatch.stop();

      final result = FAToRegexConversionResult(
        originalFA: fa,
        resultRegex: regex,
        steps: steps,
        executionTime: stopwatch.elapsed,
      );

      return ResultFactory.success(result);
    } catch (e) {
      return ResultFactory.failure(
        'Error converting FA to regex with steps: $e',
      );
    }
  }
}

/// Result of FA to regex conversion with step-by-step information
class FAToRegexConversionResult {
  /// Original FA
  final FSA originalFA;

  /// Resulting regex
  final String resultRegex;

  /// Detailed conversion steps
  final List<FAToRegexStep> steps;

  /// Execution time
  final Duration executionTime;

  const FAToRegexConversionResult({
    required this.originalFA,
    required this.resultRegex,
    required this.steps,
    required this.executionTime,
  });

  /// Gets the number of steps
  int get stepCount => steps.length;

  /// Gets the first step
  FAToRegexStep? get firstStep => steps.isNotEmpty ? steps.first : null;

  /// Gets the last step
  FAToRegexStep? get lastStep => steps.isNotEmpty ? steps.last : null;

  /// Gets the execution time in milliseconds
  int get executionTimeMs => executionTime.inMilliseconds;

  /// Gets the execution time in seconds
  double get executionTimeSeconds => executionTime.inMicroseconds / 1000000.0;
}
