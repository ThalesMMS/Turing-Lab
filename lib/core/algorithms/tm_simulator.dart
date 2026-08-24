//
//  tm_simulator.dart
//  Turing Lab
//
//  Simulation logic for deterministic and nondeterministic Turing machines,
//  covering validation, step-by-step execution, and analysis metrics.
//  Manages explored configurations, tape movement, and detection of
//  accept or reject conditions.
//
//  Thales Matheus Mendonça Santos - October 2025
//

import 'dart:collection';

import '../models/fsa_transition.dart';
import '../models/simulation_step.dart';
import '../models/state.dart';
import '../models/step_explanation.dart';
import '../models/tm.dart';
import '../models/tm_analysis.dart';
import '../models/tm_execution_analysis.dart';
import '../models/tm_transition.dart';
import '../result.dart';
import '../simulation_cancelled_exception.dart';

String _ntmConfigurationKey(State state, List<String> tape, int head) =>
    '${state.id}\u0001$head\u0001${tape.join('\u0000')}';

String _dtmConfigurationKey(
  State state,
  List<String> tape,
  int head,
  int tapeOrigin,
  String blankSymbol,
) {
  return TMConfigurationSnapshot.canonical(
    stateId: state.id,
    headPosition: tapeOrigin + head,
    tape: {
      for (var index = 0; index < tape.length; index++)
        tapeOrigin + index: tape[index],
    },
    blankSymbol: blankSymbol,
  ).key;
}

/// Simulates Turing Machines (TM) with input strings
class TMSimulator {
  static StepExplanation _buildTmStepExplanation({
    required String fromStateId,
    required String toStateId,
    required String transitionId,
    required String readSymbol,
    required String writeSymbol,
    required TapeDirection moveDirection,
    required int headBefore,
    required int headAfter,
  }) {
    final bullets = <String>[
      'Read "$readSymbol" at tape position $headBefore in state $fromStateId.',
      'Applied rule: $fromStateId,$readSymbol → $toStateId,$writeSymbol,${moveDirection.symbol}.',
      'Wrote "$writeSymbol" at position $headBefore.',
    ];

    final moveText = switch (moveDirection) {
      TapeDirection.left => 'Moved head left to position $headAfter.',
      TapeDirection.right => 'Moved head right to position $headAfter.',
      TapeDirection.stay => 'Head stayed at position $headAfter.',
    };
    bullets.add(moveText);

    final highlights = <HighlightTarget>[
      HighlightTarget(
        type: HighlightTargetType.state,
        id: toStateId,
      ),
      HighlightTarget(
        type: HighlightTargetType.transition,
        id: transitionId,
      ),
      HighlightTarget(
        type: HighlightTargetType.tapeCell,
        data: {
          'index': headBefore,
          'read': readSymbol,
          'write': writeSymbol,
        },
      ),
    ];

    if (headAfter != headBefore) {
      highlights.add(
        HighlightTarget(
          type: HighlightTargetType.tapeCell,
          data: {
            'index': headAfter,
          },
        ),
      );
    }

    return StepExplanation(
      title: 'Turing machine transition',
      bullets: bullets,
      categories: const [ExplanationCategory.tapeOperation],
      highlights: highlights,
      suggestedFixes: const [],
    );
  }

  /// Deterministic simulation (DTM) stepwise semantics similar to the references.
  /// Always uses the deterministic path — errors on nondeterministic conflicts.
  static Result<TMSimulationResult> simulateDTM(
    TM tm,
    String inputString, {
    bool stepByStep = false,
    Duration timeout = const Duration(seconds: 5),
  }) {
    try {
      final stopwatch = Stopwatch()..start();

      final validationResult = _validateInput(tm, inputString);
      if (!validationResult.isSuccess) {
        return Failure(validationResult.error!);
      }

      if (tm.states.isEmpty) {
        return const Failure('Cannot simulate empty Turing machine');
      }

      if (tm.initialState == null) {
        return const Failure('Turing machine must have an initial state');
      }

      final result = _simulateTM(tm, inputString, stepByStep, timeout);
      stopwatch.stop();

      final finalResult = result.copyWith(executionTime: stopwatch.elapsed);
      return Success(finalResult);
    } catch (e) {
      return Failure('Error simulating DTM: $e');
    }
  }

  /// Non-deterministic simulation (NTM) via BFS over configurations; accepts if any branch accepts.
  static Result<TMSimulationResult> simulateNTM(
    TM tm,
    String inputString, {
    bool stepByStep = false,
    Duration timeout = const Duration(seconds: 5),
    int maxConfigurations = 100000,
  }) {
    try {
      final validationResult = _validateInput(tm, inputString);
      if (!validationResult.isSuccess) return Failure(validationResult.error!);
      if (tm.initialState == null) {
        return const Failure('Turing machine must have an initial state');
      }

      final startTime = DateTime.now();
      int explored = 0;

      // Configuration: (state, tapeList, head, steps)
      final initialTape = inputString.split('').toList();
      final initial = (
        tm.initialState!,
        initialTape,
        0,
        <SimulationStep>[
          SimulationStep.tm(
            currentState: tm.initialState!.id,
            remainingInput: inputString,
            tapeContents: inputString,
            stepNumber: 0,
            headPosition: 0,
          ),
        ],
      );
      final queue = Queue<(State, List<String>, int, List<SimulationStep>)>()
        ..add(initial);
      final seenConfigurations = <String>{
        _ntmConfigurationKey(tm.initialState!, initialTape, 0),
      };
      // Track the longest branch for trace preservation on failure
      var longestBranch = <SimulationStep>[];

      while (queue.isNotEmpty) {
        if (DateTime.now().difference(startTime) > timeout) {
          return Success(
            TMSimulationResult.timeout(
              inputString: inputString,
              steps: longestBranch,
              executionTime: DateTime.now().difference(startTime),
            ),
          );
        }
        if (explored++ > maxConfigurations) {
          return Success(
            TMSimulationResult.configurationLimit(
              inputString: inputString,
              steps: longestBranch,
              executionTime: DateTime.now().difference(startTime),
            ),
          );
        }

        final (state, tape, head, steps) = queue.removeFirst();
        // Track the longest branch explored for failure reporting
        if (steps.length > longestBranch.length) {
          longestBranch = steps;
        }
        if (tm.acceptingStates.contains(state)) {
          final finalSteps = List<SimulationStep>.from(steps)
            ..add(
              SimulationStep.finalStep(
                finalState: state.id,
                remainingInput: '',
                stackContents: '',
                tapeContents: tape.join(''),
                stepNumber: (steps.isNotEmpty ? steps.last.stepNumber : 0) + 1,
                headPosition: head,
              ),
            );
          return Success(
            TMSimulationResult.success(
              inputString: inputString,
              steps: finalSteps,
              executionTime: DateTime.now().difference(startTime),
            ),
          );
        }

        final read = head < tape.length ? tape[head] : tm.blankSymbol;
        // Expand all possible transitions from state on read symbol
        final transitions = tm.getTransitionsFromStateOnSymbol(state, read);
        for (final tr in transitions) {
          final newTape = List<String>.from(tape);
          if (head < newTape.length) {
            newTape[head] = tr.writeSymbol;
          } else {
            newTape.add(tr.writeSymbol);
          }
          int newHead = head;
          switch (tr.moveDirection) {
            case TapeDirection.left:
              newHead -= 1;
              if (newHead < 0) {
                newHead = 0;
                newTape.insert(0, tm.blankSymbol);
              }
              break;
            case TapeDirection.right:
              newHead += 1;
              if (newHead >= newTape.length) newTape.add(tm.blankSymbol);
              break;
            case TapeDirection.stay:
              break;
          }
          final nextStep = stepByStep
              ? SimulationStep.tm(
                  currentState: tr.toState.id,
                  remainingInput: '',
                  tapeContents: newTape.join(''),
                  usedTransition: '${state.id},$read → '
                      '${tr.toState.id},${tr.writeSymbol},${tr.moveDirection.symbol}',
                  stepNumber:
                      (steps.isNotEmpty ? steps.last.stepNumber : 0) + 1,
                  headPosition: newHead,
                  consumedInput: read,
                  explanation: _buildTmStepExplanation(
                    fromStateId: state.id,
                    toStateId: tr.toState.id,
                    transitionId: tr.id,
                    readSymbol: read,
                    writeSymbol: tr.writeSymbol,
                    moveDirection: tr.moveDirection,
                    headBefore: head,
                    headAfter: newHead,
                  ),
                )
              : null;
          final nextSteps = nextStep == null ? steps : [...steps, nextStep];
          final configurationKey =
              _ntmConfigurationKey(tr.toState, newTape, newHead);
          if (seenConfigurations.add(configurationKey)) {
            queue.add((tr.toState, newTape, newHead, nextSteps));
          }
        }
      }

      return Success(
        TMSimulationResult.failure(
          inputString: inputString,
          steps: longestBranch,
          errorMessage: 'Rejected: no accepting configuration found',
          executionTime: DateTime.now().difference(startTime),
        ),
      );
    } catch (e) {
      return Failure('Error simulating NTM: $e');
    }
  }

  /// Simulates a TM with an input string
  static Result<TMSimulationResult> simulate(
    TM tm,
    String inputString, {
    bool stepByStep = true,
    Duration timeout = const Duration(seconds: 5),
  }) {
    try {
      final stopwatch = Stopwatch()..start();

      // Validate input
      final validationResult = _validateInput(tm, inputString);
      if (!validationResult.isSuccess) {
        return Failure(validationResult.error!);
      }

      // Handle empty TM
      if (tm.states.isEmpty) {
        return const Failure('Cannot simulate empty Turing machine');
      }

      // Handle TM with no initial state
      if (tm.initialState == null) {
        return const Failure('Turing machine must have an initial state');
      }

      // Route to NTM simulation when the TM is non-deterministic
      if (tm.isNondeterministic) {
        return simulateNTM(
          tm,
          inputString,
          stepByStep: stepByStep,
          timeout: timeout,
        );
      }

      // Simulate the DTM
      final result = _simulateTM(tm, inputString, stepByStep, timeout);
      stopwatch.stop();

      // Update execution time
      final finalResult = result.copyWith(executionTime: stopwatch.elapsed);

      return Success(finalResult);
    } catch (e) {
      return Failure('Error simulating Turing machine: $e');
    }
  }

  /// Simulates a TM in bounded batches so web builds can yield to the UI
  /// between groups of configurations.
  static Future<Result<TMSimulationResult>> simulateCooperative(
    TM tm,
    String inputString, {
    bool stepByStep = true,
    Duration timeout = const Duration(seconds: 5),
    int operationsPerBatch = 250,
    bool Function()? isCancelled,
  }) async {
    try {
      final validationResult = _validateInput(tm, inputString);
      if (!validationResult.isSuccess) {
        return Failure(validationResult.error!);
      }
      if (operationsPerBatch <= 0) {
        return const Failure('Operations per batch must be greater than zero');
      }

      final search = tm.isNondeterministic
          ? _NtmSearch(tm, inputString, stepByStep, timeout)
          : _DtmSearch(tm, inputString, stepByStep, timeout);
      while (true) {
        if (isCancelled?.call() == true) {
          throw const SimulationCancelledException();
        }
        final result = search.runBatch(operationsPerBatch);
        if (result != null) return Success(result);
        await Future<void>.delayed(Duration.zero);
      }
    } on SimulationCancelledException {
      rethrow;
    } catch (e) {
      return Failure('Error simulating Turing machine: $e');
    }
  }

  /// Validates the input TM and string
  static Result<void> _validateInput(TM tm, String inputString) {
    if (tm.states.isEmpty) {
      return const Failure('Turing machine must have at least one state');
    }

    if (tm.initialState == null) {
      return const Failure('Turing machine must have an initial state');
    }

    if (!tm.states.contains(tm.initialState)) {
      return const Failure('Initial state must be in the states set');
    }

    for (final acceptingState in tm.acceptingStates) {
      if (!tm.states.contains(acceptingState)) {
        return const Failure('Accepting state must be in the states set');
      }
    }

    // Validate input string symbols
    for (int i = 0; i < inputString.length; i++) {
      final symbol = inputString[i];
      if (!tm.alphabet.contains(symbol)) {
        return Failure('Input string contains invalid symbol: $symbol');
      }
    }

    return const Success(null);
  }

  /// Simulates the TM with the input string
  static TMSimulationResult _simulateTM(
    TM tm,
    String inputString,
    bool stepByStep,
    Duration timeout,
  ) {
    final steps = <SimulationStep>[];
    final startTime = DateTime.now();

    // Initialize simulation
    var currentState = tm.initialState!;
    final tape = inputString.split('').toList();
    var headPosition = 0;
    var tapeOrigin = 0;
    int stepNumber = 0;
    final seenConfigurations = <String>{
      _dtmConfigurationKey(
        currentState,
        tape,
        headPosition,
        tapeOrigin,
        tm.blankSymbol,
      ),
    };

    // Add initial step with tape data and head position
    steps.add(
      SimulationStep.tm(
        currentState: currentState.id,
        remainingInput: inputString,
        tapeContents: tape.join(''),
        stepNumber: 0,
        headPosition: 0,
      ),
    );

    // Process until halting
    while (true) {
      // Accept immediately when entering an accepting state, including the
      // initial configuration, matching the NTM path and JFLAP semantics.
      if (tm.acceptingStates.contains(currentState)) {
        break;
      }

      stepNumber++;

      // Check timeout
      if (DateTime.now().difference(startTime) > timeout) {
        return TMSimulationResult.timeout(
          inputString: inputString,
          steps: steps,
          executionTime: DateTime.now().difference(startTime),
        );
      }

      if (stepNumber > 10000) {
        return TMSimulationResult.stepLimit(
          inputString: inputString,
          steps: steps,
          executionTime: DateTime.now().difference(startTime),
        );
      }

      // Get current tape symbol
      final currentSymbol =
          headPosition < tape.length ? tape[headPosition] : tm.blankSymbol;

      // Find transitions using the same method as NTM for consistency
      final transitions = tm.getTransitionsFromStateOnSymbol(
        currentState,
        currentSymbol,
      );
      if (transitions.isEmpty) {
        // No transition found, halt
        break;
      }
      if (transitions.length > 1) {
        // Ambiguous: a DTM should have exactly one transition per state/symbol
        return TMSimulationResult.failure(
          inputString: inputString,
          steps: steps,
          errorMessage:
              'Nondeterministic conflict: ${transitions.length} transitions '
              'found for state ${currentState.id} on symbol "$currentSymbol"',
          executionTime: DateTime.now().difference(startTime),
        );
      }
      final transition = transitions.first;

      final headBefore = headPosition;

      // Write to tape
      if (headPosition < tape.length) {
        tape[headPosition] = transition.writeSymbol;
      } else {
        tape.add(transition.writeSymbol);
      }

      // Move head
      switch (transition.moveDirection) {
        case TapeDirection.left:
          headPosition--;
          if (headPosition < 0) {
            headPosition = 0;
            tape.insert(0, tm.blankSymbol);
            tapeOrigin--;
          }
          break;
        case TapeDirection.right:
          headPosition++;
          if (headPosition >= tape.length) {
            tape.add(tm.blankSymbol);
          }
          break;
        case TapeDirection.stay:
          // Stay
          break;
      }

      // Move to next state BEFORE recording the step (Bug 2 fix)
      final previousStateId = currentState.id;
      currentState = transition.toState;
      final headAfter = headPosition;

      final configurationKey = _dtmConfigurationKey(
        currentState,
        tape,
        headPosition,
        tapeOrigin,
        tm.blankSymbol,
      );
      final repeatedConfiguration = !seenConfigurations.add(configurationKey);

      // Add step
      if (stepByStep) {
        final transitionRule = '$previousStateId,$currentSymbol → '
            '${transition.toState.id},${transition.writeSymbol},'
            '${transition.moveDirection.symbol}';
        steps.add(
          SimulationStep.tm(
            currentState: currentState.id,
            remainingInput: '',
            tapeContents: tape.join(''),
            usedTransition: transitionRule,
            stepNumber: stepNumber,
            headPosition: headPosition,
            consumedInput: currentSymbol,
            explanation: _buildTmStepExplanation(
              fromStateId: previousStateId,
              toStateId: currentState.id,
              transitionId: transition.id,
              readSymbol: currentSymbol,
              writeSymbol: transition.writeSymbol,
              moveDirection: transition.moveDirection,
              headBefore: headBefore,
              headAfter: headAfter,
            ),
          ),
        );
      }
      if (repeatedConfiguration) {
        return TMSimulationResult.infiniteLoop(
          inputString: inputString,
          steps: steps,
          executionTime: DateTime.now().difference(startTime),
        );
      }
    }

    // Add final step
    steps.add(
      SimulationStep.finalStep(
        finalState: currentState.id,
        remainingInput: '',
        stackContents: '',
        tapeContents: tape.join(''),
        stepNumber: stepNumber + 1,
        headPosition: headPosition,
      ),
    );

    // Check if final state is accepting
    final isAccepted = tm.acceptingStates.contains(currentState);

    if (isAccepted) {
      return TMSimulationResult.success(
        inputString: inputString,
        steps: steps,
        executionTime: DateTime.now().difference(startTime),
      );
    } else {
      return TMSimulationResult.failure(
        inputString: inputString,
        steps: steps,
        errorMessage: 'Input not accepted - final state is not accepting',
        executionTime: DateTime.now().difference(startTime),
      );
    }
  }

  /// Tests if a TM accepts a specific string
  static Result<bool> accepts(TM tm, String inputString) {
    final simulationResult = simulate(tm, inputString);
    if (!simulationResult.isSuccess) {
      return Failure(simulationResult.error!);
    }

    final simulation = simulationResult.data!;
    return switch (simulation.outcome) {
      TMExecutionOutcome.accepted => const Success(true),
      TMExecutionOutcome.haltedRejected => const Success(false),
      TMExecutionOutcome.provenCycle ||
      TMExecutionOutcome.boundedUnknown ||
      TMExecutionOutcome.cancelled ||
      TMExecutionOutcome.invalidMachine =>
        Failure(
          simulation.errorMessage ??
              'The bounded simulation did not resolve acceptance.',
        ),
    };
  }

  /// Tests if a TM rejects a specific string
  static Result<bool> rejects(TM tm, String inputString) {
    final acceptsResult = accepts(tm, inputString);
    if (!acceptsResult.isSuccess) {
      return Failure(acceptsResult.error!);
    }

    return Success(!acceptsResult.data!);
  }

  /// Finds all strings of a given length that the TM accepts
  @Deprecated('Use TMLanguageExplorer.explore for bounded four-way outcomes.')
  static Result<Set<String>> findAcceptedStrings(
    TM tm,
    int maxLength, {
    int maxResults = 100,
  }) {
    try {
      final acceptedStrings = <String>{};
      final alphabet = tm.alphabet.toList();

      // Generate all possible strings up to maxLength
      for (int length = 0;
          length <= maxLength && acceptedStrings.length < maxResults;
          length++) {
        _generateStrings(tm, alphabet, '', length, acceptedStrings, maxResults);
      }

      return Success(acceptedStrings);
    } catch (e) {
      return Failure('Error finding accepted strings: $e');
    }
  }

  /// Recursively generates strings and tests them
  static void _generateStrings(
    TM tm,
    List<String> alphabet,
    String currentString,
    int remainingLength,
    Set<String> acceptedStrings,
    int maxResults,
  ) {
    if (acceptedStrings.length >= maxResults) return;

    if (remainingLength == 0) {
      final acceptsResult = accepts(tm, currentString);
      if (acceptsResult.isSuccess && acceptsResult.data!) {
        acceptedStrings.add(currentString);
      }
      return;
    }

    for (final symbol in alphabet) {
      _generateStrings(
        tm,
        alphabet,
        currentString + symbol,
        remainingLength - 1,
        acceptedStrings,
        maxResults,
      );
    }
  }

  /// Finds all strings of a given length that the TM rejects
  @Deprecated('Use TMLanguageExplorer.explore for bounded four-way outcomes.')
  static Result<Set<String>> findRejectedStrings(
    TM tm,
    int maxLength, {
    int maxResults = 100,
  }) {
    try {
      final rejectedStrings = <String>{};
      final alphabet = tm.alphabet.toList();

      // Generate all possible strings up to maxLength
      for (int length = 0;
          length <= maxLength && rejectedStrings.length < maxResults;
          length++) {
        _generateRejectedStrings(
          tm,
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

  /// Recursively generates strings and tests them for rejection
  static void _generateRejectedStrings(
    TM tm,
    List<String> alphabet,
    String currentString,
    int remainingLength,
    Set<String> rejectedStrings,
    int maxResults,
  ) {
    if (rejectedStrings.length >= maxResults) return;

    if (remainingLength == 0) {
      final acceptsResult = accepts(tm, currentString);
      if (acceptsResult.isSuccess && !acceptsResult.data!) {
        rejectedStrings.add(currentString);
      }
      return;
    }

    for (final symbol in alphabet) {
      _generateRejectedStrings(
        tm,
        alphabet,
        currentString + symbol,
        remainingLength - 1,
        rejectedStrings,
        maxResults,
      );
    }
  }

  /// Analyzes the behavior of a TM
  static Result<TMAnalysis> analyzeTM(
    TM tm, {
    int maxInputLength = 10,
    Duration timeout = const Duration(seconds: 10),
  }) {
    try {
      final stopwatch = Stopwatch()..start();

      // Validate input
      final validationResult = _validateInput(tm, '');
      if (!validationResult.isSuccess) {
        return Failure(validationResult.error!);
      }

      // Handle empty TM
      if (tm.states.isEmpty) {
        return const Failure('Cannot analyze empty Turing machine');
      }

      // Handle TM with no initial state
      if (tm.initialState == null) {
        return const Failure('Turing machine must have an initial state');
      }

      // Analyze the TM
      final result = _analyzeTM(tm, maxInputLength, timeout);
      stopwatch.stop();

      // Update execution time
      final finalResult = result.copyWith(executionTime: stopwatch.elapsed);

      return Success(finalResult);
    } catch (e) {
      return Failure('Error analyzing Turing machine: $e');
    }
  }

  /// Analyzes the TM
  static TMAnalysis _analyzeTM(TM tm, int maxInputLength, Duration timeout) {
    final startTime = DateTime.now();

    // Analyze states
    final stateAnalysis = _analyzeStates(tm);

    // Analyze transitions
    final transitionAnalysis = _analyzeTransitions(tm);

    // Analyze tape operations
    final tapeAnalysis = _analyzeTapeOperations(tm);

    // Analyze reachability
    final reachabilityAnalysis = _analyzeReachability(tm);

    return TMAnalysis(
      stateAnalysis: stateAnalysis,
      transitionAnalysis: transitionAnalysis,
      tapeAnalysis: tapeAnalysis,
      reachabilityAnalysis: reachabilityAnalysis,
      executionTime: DateTime.now().difference(startTime),
    );
  }

  /// Analyzes the states of the TM
  static TMStateAnalysis _analyzeStates(TM tm) {
    final totalStates = tm.states.length;
    final acceptingStates = tm.acceptingStates.length;
    final nonAcceptingStates = totalStates - acceptingStates;

    return TMStateAnalysis(
      totalStates: totalStates,
      acceptingStates: acceptingStates,
      nonAcceptingStates: nonAcceptingStates,
    );
  }

  /// Analyzes the transitions of the TM
  static TMTransitionAnalysis _analyzeTransitions(TM tm) {
    final totalTransitions = tm.transitions.length;
    final tmTransitions = tm.transitions.whereType<TMTransition>().length;
    final fsaTransitions = tm.transitions.whereType<FSATransition>().length;

    return TMTransitionAnalysis(
      totalTransitions: totalTransitions,
      tmTransitions: tmTransitions,
      fsaTransitions: fsaTransitions,
    );
  }

  /// Analyzes the tape operations of the TM
  static TapeAnalysis _analyzeTapeOperations(TM tm) {
    final writeOperations = <String>{};
    final readOperations = <String>{};
    final moveDirections = <String>{};
    final tapeSymbols = <String>{};

    for (final transition in tm.transitions) {
      if (transition is TMTransition) {
        writeOperations.add(transition.writeSymbol);
        readOperations.add(transition.readSymbol);
        moveDirections.add(transition.moveDirection.name);
        tapeSymbols.add(transition.readSymbol);
        tapeSymbols.add(transition.writeSymbol);
      }
    }

    return TapeAnalysis(
      writeOperations: writeOperations,
      readOperations: readOperations,
      moveDirections: moveDirections,
      tapeSymbols: tapeSymbols,
    );
  }

  /// Analyzes the reachability of the TM
  static TMReachabilityAnalysis _analyzeReachability(TM tm) {
    final reachableStates = <State>{};
    final unreachableStates = <State>{};

    // Find reachable states from initial state
    if (tm.initialState != null) {
      _findReachableStates(tm, tm.initialState!, reachableStates);
    }

    // Find unreachable states
    for (final state in tm.states) {
      if (!reachableStates.contains(state)) {
        unreachableStates.add(state);
      }
    }

    return TMReachabilityAnalysis(
      reachableStates: reachableStates,
      unreachableStates: unreachableStates,
    );
  }

  /// Recursively finds reachable states
  static void _findReachableStates(
    TM tm,
    State currentState,
    Set<State> reachableStates,
  ) {
    if (reachableStates.contains(currentState)) {
      return; // Already visited
    }

    reachableStates.add(currentState);

    // Find all states reachable from current state
    for (final transition in tm.transitions) {
      if (transition.fromState == currentState) {
        _findReachableStates(tm, transition.toState, reachableStates);
      }
    }
  }
}

abstract class _CooperativeTmSearch {
  TMSimulationResult? runBatch(int batchSize);
}

class _DtmSearch implements _CooperativeTmSearch {
  _DtmSearch(this.tm, this.inputString, this.stepByStep, this.timeout)
      : currentState = tm.initialState!,
        tape = inputString.split('').toList(),
        startTime = DateTime.now() {
    seenConfigurations.add(
      _dtmConfigurationKey(
        currentState,
        tape,
        headPosition,
        tapeOrigin,
        tm.blankSymbol,
      ),
    );
    steps.add(
      SimulationStep.tm(
        currentState: currentState.id,
        remainingInput: inputString,
        tapeContents: tape.join(''),
        stepNumber: 0,
        headPosition: 0,
      ),
    );
  }

  final TM tm;
  final String inputString;
  final bool stepByStep;
  final Duration timeout;
  final DateTime startTime;
  final List<String> tape;
  final List<SimulationStep> steps = [];
  State currentState;
  var headPosition = 0;
  var tapeOrigin = 0;
  var stepNumber = 0;
  final Set<String> seenConfigurations = {};

  @override
  TMSimulationResult? runBatch(int batchSize) {
    for (var processed = 0; processed < batchSize; processed++) {
      final result = _step();
      if (result != null) return result;
    }
    return null;
  }

  TMSimulationResult? _step() {
    if (tm.acceptingStates.contains(currentState)) return _halt();
    stepNumber++;
    final elapsed = DateTime.now().difference(startTime);
    if (elapsed > timeout) {
      return TMSimulationResult.timeout(
        inputString: inputString,
        steps: steps,
        executionTime: elapsed,
      );
    }
    if (stepNumber > 10000) {
      return TMSimulationResult.stepLimit(
        inputString: inputString,
        steps: steps,
        executionTime: elapsed,
      );
    }

    final currentSymbol =
        headPosition < tape.length ? tape[headPosition] : tm.blankSymbol;
    final transitions = tm.getTransitionsFromStateOnSymbol(
      currentState,
      currentSymbol,
    );
    if (transitions.isEmpty) return _halt();
    if (transitions.length > 1) {
      return TMSimulationResult.failure(
        inputString: inputString,
        steps: steps,
        errorMessage:
            'Nondeterministic conflict: ${transitions.length} transitions '
            'found for state ${currentState.id} on symbol "$currentSymbol"',
        executionTime: elapsed,
      );
    }

    final transition = transitions.first;
    final previousStateId = currentState.id;
    final headBefore = headPosition;
    if (headPosition < tape.length) {
      tape[headPosition] = transition.writeSymbol;
    } else {
      tape.add(transition.writeSymbol);
    }
    switch (transition.moveDirection) {
      case TapeDirection.left:
        headPosition--;
        if (headPosition < 0) {
          headPosition = 0;
          tape.insert(0, tm.blankSymbol);
          tapeOrigin--;
        }
      case TapeDirection.right:
        headPosition++;
        if (headPosition >= tape.length) tape.add(tm.blankSymbol);
      case TapeDirection.stay:
        break;
    }
    currentState = transition.toState;
    final configurationKey = _dtmConfigurationKey(
      currentState,
      tape,
      headPosition,
      tapeOrigin,
      tm.blankSymbol,
    );
    final repeatedConfiguration = !seenConfigurations.add(configurationKey);
    if (stepByStep) {
      steps.add(
        SimulationStep.tm(
          currentState: currentState.id,
          remainingInput: '',
          tapeContents: tape.join(''),
          usedTransition: '$previousStateId,$currentSymbol → '
              '${transition.toState.id},${transition.writeSymbol},'
              '${transition.moveDirection.symbol}',
          stepNumber: stepNumber,
          headPosition: headPosition,
          consumedInput: currentSymbol,
          explanation: TMSimulator._buildTmStepExplanation(
            fromStateId: previousStateId,
            toStateId: currentState.id,
            transitionId: transition.id,
            readSymbol: currentSymbol,
            writeSymbol: transition.writeSymbol,
            moveDirection: transition.moveDirection,
            headBefore: headBefore,
            headAfter: headPosition,
          ),
        ),
      );
    }
    if (repeatedConfiguration) {
      return TMSimulationResult.infiniteLoop(
        inputString: inputString,
        steps: steps,
        executionTime: elapsed,
      );
    }
    return null;
  }

  TMSimulationResult _halt() {
    steps.add(
      SimulationStep.finalStep(
        finalState: currentState.id,
        remainingInput: '',
        stackContents: '',
        tapeContents: tape.join(''),
        stepNumber: stepNumber + 1,
        headPosition: headPosition,
      ),
    );
    final elapsed = DateTime.now().difference(startTime);
    return tm.acceptingStates.contains(currentState)
        ? TMSimulationResult.success(
            inputString: inputString,
            steps: steps,
            executionTime: elapsed,
          )
        : TMSimulationResult.failure(
            inputString: inputString,
            steps: steps,
            errorMessage: 'Input not accepted - final state is not accepting',
            executionTime: elapsed,
          );
  }
}

typedef _NtmConfiguration = (State, List<String>, int, List<SimulationStep>);

class _NtmSearch implements _CooperativeTmSearch {
  _NtmSearch(this.tm, this.inputString, this.stepByStep, this.timeout)
      : startTime = DateTime.now() {
    final initialTape = inputString.split('').toList();
    queue.add((
      tm.initialState!,
      initialTape,
      0,
      <SimulationStep>[
        SimulationStep.tm(
          currentState: tm.initialState!.id,
          remainingInput: inputString,
          tapeContents: inputString,
          stepNumber: 0,
          headPosition: 0,
        ),
      ],
    ));
    seenConfigurations.add(
      _ntmConfigurationKey(tm.initialState!, initialTape, 0),
    );
  }

  final TM tm;
  final String inputString;
  final bool stepByStep;
  final Duration timeout;
  final DateTime startTime;
  final Queue<_NtmConfiguration> queue = Queue();
  final Set<String> seenConfigurations = {};
  var longestBranch = <SimulationStep>[];
  var explored = 0;

  @override
  TMSimulationResult? runBatch(int batchSize) {
    for (var processed = 0;
        processed < batchSize && queue.isNotEmpty;
        processed++) {
      final terminal = _processNext();
      if (terminal != null) return terminal;
    }
    if (queue.isNotEmpty) return null;
    return TMSimulationResult.failure(
      inputString: inputString,
      steps: longestBranch,
      errorMessage: 'Rejected: no accepting configuration found',
      executionTime: DateTime.now().difference(startTime),
    );
  }

  TMSimulationResult? _processNext() {
    final elapsed = DateTime.now().difference(startTime);
    if (elapsed > timeout) {
      return TMSimulationResult.timeout(
        inputString: inputString,
        steps: longestBranch,
        executionTime: elapsed,
      );
    }
    if (explored++ > 100000) {
      return TMSimulationResult.configurationLimit(
        inputString: inputString,
        steps: longestBranch,
        executionTime: elapsed,
      );
    }

    final (state, tape, head, steps) = queue.removeFirst();
    if (steps.length > longestBranch.length) longestBranch = steps;
    if (tm.acceptingStates.contains(state)) {
      final finalSteps = List<SimulationStep>.from(steps)
        ..add(
          SimulationStep.finalStep(
            finalState: state.id,
            remainingInput: '',
            stackContents: '',
            tapeContents: tape.join(''),
            stepNumber: (steps.isNotEmpty ? steps.last.stepNumber : 0) + 1,
            headPosition: head,
          ),
        );
      return TMSimulationResult.success(
        inputString: inputString,
        steps: finalSteps,
        executionTime: elapsed,
      );
    }

    final read = head < tape.length ? tape[head] : tm.blankSymbol;
    for (final transition in tm.getTransitionsFromStateOnSymbol(state, read)) {
      final newTape = List<String>.from(tape);
      if (head < newTape.length) {
        newTape[head] = transition.writeSymbol;
      } else {
        newTape.add(transition.writeSymbol);
      }
      var newHead = head;
      switch (transition.moveDirection) {
        case TapeDirection.left:
          newHead--;
          if (newHead < 0) {
            newHead = 0;
            newTape.insert(0, tm.blankSymbol);
          }
        case TapeDirection.right:
          newHead++;
          if (newHead >= newTape.length) newTape.add(tm.blankSymbol);
        case TapeDirection.stay:
          break;
      }
      final nextStep = stepByStep
          ? SimulationStep.tm(
              currentState: transition.toState.id,
              remainingInput: '',
              tapeContents: newTape.join(''),
              usedTransition: '${state.id},$read → '
                  '${transition.toState.id},${transition.writeSymbol},'
                  '${transition.moveDirection.symbol}',
              stepNumber: (steps.isNotEmpty ? steps.last.stepNumber : 0) + 1,
              headPosition: newHead,
              consumedInput: read,
              explanation: TMSimulator._buildTmStepExplanation(
                fromStateId: state.id,
                toStateId: transition.toState.id,
                transitionId: transition.id,
                readSymbol: read,
                writeSymbol: transition.writeSymbol,
                moveDirection: transition.moveDirection,
                headBefore: head,
                headAfter: newHead,
              ),
            )
          : null;
      final configurationKey =
          _ntmConfigurationKey(transition.toState, newTape, newHead);
      if (seenConfigurations.add(configurationKey)) {
        queue.add((
          transition.toState,
          newTape,
          newHead,
          nextStep == null ? steps : [...steps, nextStep],
        ));
      }
    }
    return null;
  }
}

/// Result of simulating a TM
class TMSimulationResult {
  final String inputString;
  final bool accepted;
  final TMExecutionOutcome outcome;
  final TMExecutionLimit? limit;
  final List<SimulationStep> steps;
  final String? errorMessage;
  final Duration executionTime;

  const TMSimulationResult._({
    required this.inputString,
    required this.accepted,
    required this.outcome,
    this.limit,
    required this.steps,
    this.errorMessage,
    required this.executionTime,
  });

  factory TMSimulationResult.success({
    required String inputString,
    required List<SimulationStep> steps,
    required Duration executionTime,
  }) {
    return TMSimulationResult._(
      inputString: inputString,
      accepted: true,
      outcome: TMExecutionOutcome.accepted,
      steps: steps,
      executionTime: executionTime,
    );
  }

  factory TMSimulationResult.failure({
    required String inputString,
    required List<SimulationStep> steps,
    required String errorMessage,
    required Duration executionTime,
  }) {
    return TMSimulationResult._(
      inputString: inputString,
      accepted: false,
      outcome: TMExecutionOutcome.haltedRejected,
      steps: steps,
      errorMessage: errorMessage,
      executionTime: executionTime,
    );
  }

  factory TMSimulationResult.timeout({
    required String inputString,
    required List<SimulationStep> steps,
    required Duration executionTime,
  }) {
    return TMSimulationResult._(
      inputString: inputString,
      accepted: false,
      outcome: TMExecutionOutcome.boundedUnknown,
      limit: TMExecutionLimit.timeout,
      steps: steps,
      errorMessage: 'Simulation timed out',
      executionTime: executionTime,
    );
  }

  factory TMSimulationResult.infiniteLoop({
    required String inputString,
    required List<SimulationStep> steps,
    required Duration executionTime,
  }) {
    return TMSimulationResult._(
      inputString: inputString,
      accepted: false,
      outcome: TMExecutionOutcome.provenCycle,
      steps: steps,
      errorMessage: 'Infinite loop detected',
      executionTime: executionTime,
    );
  }

  factory TMSimulationResult.stepLimit({
    required String inputString,
    required List<SimulationStep> steps,
    required Duration executionTime,
  }) {
    return TMSimulationResult._(
      inputString: inputString,
      accepted: false,
      outcome: TMExecutionOutcome.boundedUnknown,
      limit: TMExecutionLimit.steps,
      steps: steps,
      errorMessage: 'Step limit reached; the result is inconclusive',
      executionTime: executionTime,
    );
  }

  factory TMSimulationResult.configurationLimit({
    required String inputString,
    required List<SimulationStep> steps,
    required Duration executionTime,
  }) {
    return TMSimulationResult._(
      inputString: inputString,
      accepted: false,
      outcome: TMExecutionOutcome.boundedUnknown,
      limit: TMExecutionLimit.configurations,
      steps: steps,
      errorMessage: 'Configuration limit reached; the result is inconclusive',
      executionTime: executionTime,
    );
  }

  TMSimulationResult copyWith({
    String? inputString,
    bool? accepted,
    TMExecutionOutcome? outcome,
    TMExecutionLimit? limit,
    List<SimulationStep>? steps,
    String? errorMessage,
    Duration? executionTime,
  }) {
    return TMSimulationResult._(
      inputString: inputString ?? this.inputString,
      accepted: accepted ?? this.accepted,
      outcome: outcome ?? this.outcome,
      limit: limit ?? this.limit,
      steps: steps ?? this.steps,
      errorMessage: errorMessage ?? this.errorMessage,
      executionTime: executionTime ?? this.executionTime,
    );
  }
}
