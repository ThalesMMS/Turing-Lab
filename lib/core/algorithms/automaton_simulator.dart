//
//  automaton_simulator.dart
//  Turing Lab
//
//  Implements the core simulation engine for finite automata, covering
//  deterministic and nondeterministic executions with step-by-step tracing.
//  Performs structural validation, enforces a time limit, compiles step
//  lists, and produces rich results including execution statistics.
//  Serves as the basis for higher-level facades in the automata domain.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'dart:collection';

import '../models/fsa.dart';
import '../models/state.dart';
import '../models/fsa_transition.dart';
import '../models/simulation_result.dart';
import '../models/simulation_step.dart';
import '../models/step_explanation.dart';
import '../models/nfa_path_node.dart';
import '../models/nfa_computation_tree.dart';
import '../result.dart';
import '../utils/epsilon_utils.dart';
import 'automaton_simulation_messages.dart';

/// Simulates Finite Automata (FA) with input strings
class AutomatonSimulator {
  static const _epsilonClosureTransition = 'ε-closure';
  static const int defaultMaxNfaTraceNodes = 10000;
  static const int defaultMaxNfaEpsilonPathEdges = 256;

  /// Simulates a DFA with an input string (deterministic, no epsilon)
  static Future<Result<SimulationResult>> simulateDFA(
    FSA automaton,
    String inputString, {
    bool stepByStep = false,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      final stopwatch = Stopwatch()..start();

      // Validate input (generic checks)
      final validationResult = _validateInput(automaton, inputString);
      if (!validationResult.isSuccess) {
        return Failure(
          validationResult.error!,
          structuredMessage: validationResult.structuredError,
        );
      }

      // Validate DFA constraints
      if (automaton.isNondeterministic || automaton.hasEpsilonTransitions) {
        final message = AutomatonSimulationMessages.dfaRequired();
        return Failure(message.stableCode, structuredMessage: message);
      }

      // Handle empty automaton
      if (automaton.states.isEmpty) {
        final message = AutomatonSimulationMessages.emptyAutomaton();
        return Failure(message.stableCode, structuredMessage: message);
      }

      // Handle automaton with no initial state
      if (automaton.initialState == null) {
        final message = AutomatonSimulationMessages.missingInitialState();
        return Failure(message.stableCode, structuredMessage: message);
      }

      final transitionIndex = _FsaTransitionIndex(automaton);

      // Simulate as DFA
      final result = await _simulateDFA(
        automaton,
        transitionIndex,
        inputString,
        stepByStep,
        timeout,
      );
      stopwatch.stop();

      // Update execution time
      final finalResult = result.copyWith(executionTime: stopwatch.elapsed);

      return Success(finalResult);
    } catch (e) {
      final message = AutomatonSimulationMessages.dfaFailure(e);
      return Failure(message.stableCode, structuredMessage: message);
    }
  }

  /// Backwards-compatible generic simulate: routes to DFA simulation.
  static Future<Result<SimulationResult>> simulate(
    FSA automaton,
    String inputString, {
    bool stepByStep = false,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    // Route to NFA simulator when nondeterminism or epsilon transitions exist
    if (automaton.isNondeterministic || automaton.hasEpsilonTransitions) {
      return await simulateNFA(
        automaton,
        inputString,
        stepByStep: stepByStep,
        timeout: timeout,
      );
    }
    return await simulateDFA(
      automaton,
      inputString,
      stepByStep: stepByStep,
      timeout: timeout,
    );
  }

  /// Validates the input automaton and string
  static Result<void> _validateInput(
    FSA automaton,
    String inputString, {
    bool strictAlphabet = true,
  }) {
    if (automaton.states.isEmpty) {
      final message = AutomatonSimulationMessages.emptyAutomaton();
      return Failure(message.stableCode, structuredMessage: message);
    }

    if (automaton.initialState == null) {
      final message = AutomatonSimulationMessages.missingInitialState();
      return Failure(message.stableCode, structuredMessage: message);
    }

    if (!automaton.states.contains(automaton.initialState)) {
      final message = AutomatonSimulationMessages.initialStateOutsideSet();
      return Failure(message.stableCode, structuredMessage: message);
    }

    for (final acceptingState in automaton.acceptingStates) {
      if (!automaton.states.contains(acceptingState)) {
        final message = AutomatonSimulationMessages.acceptingStateOutsideSet();
        return Failure(message.stableCode, structuredMessage: message);
      }
    }

    // Validate input string symbols
    if (strictAlphabet) {
      for (final input in _unicodeScalars(inputString)) {
        final symbol = input.symbol;
        if (!automaton.alphabet.contains(symbol)) {
          final message = AutomatonSimulationMessages.invalidInputSymbol(
            symbol,
          );
          return Failure(message.stableCode, structuredMessage: message);
        }
      }
    }

    return const Success(null);
  }

  /// Simulates a DFA step-by-step
  static Future<SimulationResult> _simulateDFA(
    FSA automaton,
    _FsaTransitionIndex transitionIndex,
    String inputString,
    bool stepByStep,
    Duration timeout,
  ) async {
    final steps = <SimulationStep>[];
    final startTime = DateTime.now();

    // Initialize simulation with a single current state
    var currentState = automaton.initialState!;
    int stepNumber = 0;

    // Add initial step
    steps.add(
      SimulationStep.initial(
        initialState: automaton.initialState!.label,
        activeStateIds: {automaton.initialState!.id},
        inputString: inputString,
      ),
    );

    // Process each input symbol with batching for large inputs.
    final inputScalars = _unicodeScalars(inputString);
    for (
      var inputOffset = 0;
      inputOffset < inputScalars.length;
      inputOffset++
    ) {
      final input = inputScalars[inputOffset];
      final symbol = input.symbol;
      stepNumber++;

      // Check timeout
      if (DateTime.now().difference(startTime) >= timeout) {
        return SimulationResult.timeout(
          inputString: inputString,
          steps: steps,
          executionTime: DateTime.now().difference(startTime),
        );
      }

      // Find next state deterministically
      final transitions = transitionIndex.transitionsFor(currentState, symbol);
      if (transitions.isEmpty) {
        final message = AutomatonSimulationMessages.noDfaTransition(
          state: currentState.label,
          symbol: symbol,
        );
        return SimulationResult.structuredFailure(
          inputString: inputString,
          steps: steps,
          message: message,
          executionTime: DateTime.now().difference(startTime),
        );
      }
      final transition = transitions.first;
      final nextState = transition.toState;

      // Add step (record destination state, consistent with TM simulator)
      if (stepByStep) {
        final fromStateLabel = currentState.label;
        steps.add(
          SimulationStep.fsa(
            currentState: nextState.label,
            activeStateIds: {nextState.id},
            remainingInput: inputString.substring(input.end),
            usedTransition: 'δ($fromStateLabel, $symbol) = ${nextState.label}',
            stepNumber: stepNumber,
            consumedInput: symbol,
            explanation: StepExplanation(
              titleMessage:
                  AutomatonSimulationMessages.transitionAppliedTitle(),
              bulletMessages: [
                AutomatonSimulationMessages.readSymbol(symbol),
                AutomatonSimulationMessages.transitionDetail(
                  fromState: currentState.label,
                  symbol: symbol,
                  toState: nextState.label,
                ),
              ],
              categories: const [ExplanationCategory.info],
              highlights: [
                HighlightTarget(
                  type: HighlightTargetType.state,
                  id: currentState.id,
                ),
                HighlightTarget(
                  type: HighlightTargetType.state,
                  id: nextState.id,
                ),
                HighlightTarget(
                  type: HighlightTargetType.transition,
                  id: transition.id,
                ),
              ],
            ),
          ),
        );
      }

      currentState = nextState;

      // Batch processing for large simulations (>1000 steps)
      final processedCount = inputOffset + 1;
      if (processedCount > 1000 && processedCount % 500 == 0) {
        // Yield to prevent UI blocking
        await Future.delayed(Duration.zero);
      }
    }

    // Check if any current state is accepting
    final isAccepted = automaton.acceptingStates.contains(currentState);

    // Add final step only in step-by-step mode (guard against duplicate
    // when input was already fully consumed in the last transition step)
    if (stepByStep && (steps.isEmpty || steps.last.remainingInput.isNotEmpty)) {
      steps.add(
        SimulationStep.finalStep(
          finalState: currentState.label,
          activeStateIds: {currentState.id},
          remainingInput: '',
          stackContents: '',
          tapeContents: '',
          stepNumber: stepNumber,
        ),
      );
    }

    if (isAccepted) {
      return SimulationResult.success(
        inputString: inputString,
        steps: steps,
        executionTime: DateTime.now().difference(startTime),
      );
    } else {
      return SimulationResult.structuredFailure(
        inputString: inputString,
        steps: steps,
        message: AutomatonSimulationMessages.rejectedNoAcceptingState(),
        executionTime: DateTime.now().difference(startTime),
      );
    }
  }

  /// Simulates an NFA with epsilon transitions
  static Future<Result<SimulationResult>> simulateNFA(
    FSA nfa,
    String inputString, {
    bool stepByStep = false,
    Duration timeout = const Duration(seconds: 5),
    int maxTraceNodes = defaultMaxNfaTraceNodes,
  }) async {
    try {
      final stopwatch = Stopwatch()..start();

      // Validate input
      // For NFAs, don't fail early on symbols outside the alphabet; reject via simulation.
      final validationResult = _validateInput(
        nfa,
        inputString,
        strictAlphabet: false,
      );
      if (!validationResult.isSuccess) {
        return Failure(
          validationResult.error!,
          structuredMessage: validationResult.structuredError,
        );
      }

      // Handle empty automaton
      if (nfa.states.isEmpty) {
        final message = AutomatonSimulationMessages.emptyAutomaton();
        return Failure(message.stableCode, structuredMessage: message);
      }

      // Handle automaton with no initial state
      if (nfa.initialState == null) {
        final message = AutomatonSimulationMessages.missingInitialState();
        return Failure(message.stableCode, structuredMessage: message);
      }

      final transitionIndex = _FsaTransitionIndex(nfa);

      // Simulate the NFA
      final result = await _simulateNFA(
        nfa,
        transitionIndex,
        inputString,
        stepByStep,
        timeout,
        maxTraceNodes,
      );
      stopwatch.stop();

      // Update execution time
      final finalResult = result.copyWith(executionTime: stopwatch.elapsed);

      return Success(finalResult);
    } catch (e) {
      final message = AutomatonSimulationMessages.nfaFailure(e);
      return Failure(message.stableCode, structuredMessage: message);
    }
  }

  /// Simulates an NFA with epsilon transitions
  static Future<SimulationResult> _simulateNFA(
    FSA nfa,
    _FsaTransitionIndex transitionIndex,
    String inputString,
    bool stepByStep,
    Duration timeout,
    int maxTraceNodes,
  ) async {
    if (!stepByStep) {
      return _recognizeNFA(nfa, transitionIndex, inputString, timeout);
    }

    final steps = <SimulationStep>[];
    final startTime = DateTime.now();

    // Initialize simulation with epsilon closure of initial state
    final initialClosure = transitionIndex.epsilonClosureWithTransitionIds({
      nfa.initialState!,
    });
    var currentStates = initialClosure.states;
    var remainingInput = inputString;
    final inputScalars = _unicodeScalars(inputString);
    int stepNumber = 0;
    int nextStepNumber() => ++stepNumber;

    String stateSetLabel(Set<State> states) {
      if (states.isEmpty) return '{}';
      if (states.length == 1) return states.first.label;
      return '{${states.map((s) => s.label).join(',')}}';
    }

    // Add initial step
    final initialStateLabel = stateSetLabel(currentStates);

    steps.add(
      SimulationStep.initial(
        initialState: initialStateLabel,
        activeStateIds: {for (final state in currentStates) state.id},
        inputString: inputString,
      ),
    );

    // Optional: make the initial ε-closure explicit in step-by-step mode.
    if (stepByStep && initialClosure.states.length > 1) {
      steps.add(
        SimulationStep.fsa(
          currentState: initialStateLabel,
          activeStateIds: {for (final state in currentStates) state.id},
          remainingInput: inputString,
          usedTransition: _epsilonClosureTransition,
          stepNumber: nextStepNumber(),
          consumedInput: '',
          explanation: StepExplanation(
            titleMessage:
                AutomatonSimulationMessages.computedEpsilonClosureTitle(),
            bulletMessages: [
              AutomatonSimulationMessages.epsilonClosureBeforeReading(),
              AutomatonSimulationMessages.epsilonClosureReached(
                initialState: nfa.initialState!.label,
                stateSet: initialStateLabel,
              ),
            ],
            categories: const [ExplanationCategory.epsilonMove],
            highlights: [
              for (final s in initialClosure.states)
                HighlightTarget(type: HighlightTargetType.state, id: s.id),
              for (final transitionId in initialClosure.transitionIds)
                HighlightTarget(
                  type: HighlightTargetType.transition,
                  id: transitionId,
                ),
            ],
          ),
        ),
      );
    }

    // Build computation tree - start with root nodes for each state in epsilon closure
    final initialPathExpansion = transitionIndex.epsilonPathsFrom(
      nfa.initialState!,
      maximumPaths: maxTraceNodes,
      maximumPathLength: defaultMaxNfaEpsilonPathEdges,
      shouldStop: () => DateTime.now().difference(startTime) >= timeout,
    );
    final rootNodes = <NFAPathNode>[];
    for (final path in initialPathExpansion.paths) {
      final state = path.state;
      rootNodes.add(
        NFAPathNode(
          currentState: state.id,
          remainingInput: inputString,
          stepNumber: 0,
          transitionUsed: path.transitions.isEmpty
              ? 'Initial state'
              : 'ε: ${nfa.initialState!.label} → '
                    '${path.transitions.map((transition) => transition.toState.label).join(' → ε → ')}',
          transitionIds: [
            for (final transition in path.transitions) transition.id,
          ],
          isCycle: path.closesCycle,
          descriptionMessage:
              AutomatonSimulationMessages.initialStateDescription(state.id),
        ),
      );
    }
    var traceNodeCount = rootNodes.length;

    if (initialPathExpansion.timedOut) {
      final tree = NFAComputationTree.timeout(
        root: _buildTreeRoot(rootNodes),
        inputString: inputString,
        totalSteps: stepNumber,
      );
      return SimulationResult.timeout(
        inputString: inputString,
        steps: steps,
        executionTime: DateTime.now().difference(startTime),
        computationTree: tree,
      );
    }

    if (initialPathExpansion.truncated) {
      final legacyMessage = _nfaTraceTruncationMessage(
        maxTraceNodes,
        epsilonPathLimited: initialPathExpansion.depthLimited,
      );
      final message = AutomatonSimulationMessages.nfaTraceTruncated(
        maximumNodes: maxTraceNodes,
        epsilonPathLimited: initialPathExpansion.depthLimited,
        epsilonPathLimit: defaultMaxNfaEpsilonPathEdges,
      );
      final tree = NFAComputationTree.rejected(
        root: _buildTreeRoot(rootNodes),
        inputString: inputString,
        totalSteps: stepNumber,
        errorMessage: legacyMessage,
        structuredMessage: message,
      );
      return SimulationResult.structuredFailure(
        inputString: inputString,
        steps: steps,
        message: message,
        executionTime: DateTime.now().difference(startTime),
        compatibilityErrorMessage: legacyMessage,
        computationTree: tree,
      );
    }

    // Maintain a queue of active path nodes to expand
    var activeLeaves = rootNodes.where((node) => !node.isCycle).toList();
    final allLeaves = <NFAPathNode>[];
    int totalSteps = 0;

    // Process each input symbol
    for (final input in inputScalars) {
      final symbolStepNumber = nextStepNumber();
      totalSteps = stepNumber;

      // Check timeout
      if (DateTime.now().difference(startTime) > timeout) {
        // Build partial tree with current progress
        final partialRoot = _buildTreeRoot(rootNodes);
        final tree = NFAComputationTree.timeout(
          root: partialRoot,
          inputString: inputString,
          totalSteps: totalSteps,
        );
        return SimulationResult.timeout(
          inputString: inputString,
          steps: steps,
          executionTime: DateTime.now().difference(startTime),
          computationTree: tree,
        );
      }

      final symbol = input.symbol;
      remainingInput = inputString.substring(input.end);

      // Find next states by symbol, exploring all transitions
      var nextStates = <State>{};
      final transitionIds = <String>{};
      for (final state in currentStates) {
        final transitions = transitionIndex.transitionsFor(state, symbol);
        nextStates.addAll(transitions.map((t) => t.toState));
        transitionIds.addAll(transitions.map((t) => t.id));
      }

      // Apply epsilon closure to next states (flexible)
      final closureBefore = nextStates;
      final epsilonClosure = transitionIndex.epsilonClosureWithTransitionIds(
        nextStates,
      );
      nextStates = epsilonClosure.states;
      final beforeLabel = stateSetLabel(closureBefore);
      final afterLabel = stateSetLabel(nextStates);

      if (stepByStep) {
        steps.add(
          SimulationStep.fsa(
            currentState: beforeLabel,
            activeStateIds: {for (final state in closureBefore) state.id},
            remainingInput: remainingInput,
            usedTransition: symbol,
            stepNumber: symbolStepNumber,
            consumedInput: symbol,
            explanation: StepExplanation(
              titleMessage: AutomatonSimulationMessages.symbolConsumedTitle(),
              bulletMessages: [
                AutomatonSimulationMessages.readSymbol(symbol),
                if (closureBefore.length > 1)
                  AutomatonSimulationMessages.nondeterministicStep(),
                AutomatonSimulationMessages.activeSetAfterTransitions(
                  symbol: symbol,
                  stateSet: beforeLabel,
                ),
              ],
              categories: [
                ExplanationCategory.info,
                if (closureBefore.length > 1)
                  ExplanationCategory.nondeterminism,
              ],
              highlights: [
                for (final s in closureBefore)
                  HighlightTarget(type: HighlightTargetType.state, id: s.id),
                for (final transitionId in transitionIds)
                  HighlightTarget(
                    type: HighlightTargetType.transition,
                    id: transitionId,
                  ),
              ],
            ),
          ),
        );
      }

      // If ε-closure expanded the set, attach an explicit explanation step.
      if (stepByStep && nextStates.length != closureBefore.length) {
        steps.add(
          SimulationStep.fsa(
            currentState: afterLabel,
            activeStateIds: {for (final state in nextStates) state.id},
            remainingInput: remainingInput,
            usedTransition: _epsilonClosureTransition,
            stepNumber: nextStepNumber(),
            consumedInput: '',
            explanation: StepExplanation(
              titleMessage:
                  AutomatonSimulationMessages.expandedViaEpsilonTitle(),
              bulletMessages: [
                AutomatonSimulationMessages.epsilonAfterConsuming(symbol),
                AutomatonSimulationMessages.epsilonClosureExpanded(
                  before: beforeLabel,
                  after: afterLabel,
                ),
              ],
              categories: const [ExplanationCategory.epsilonMove],
              highlights: [
                for (final s in nextStates)
                  HighlightTarget(type: HighlightTargetType.state, id: s.id),
                for (final transitionId in epsilonClosure.transitionIds)
                  HighlightTarget(
                    type: HighlightTargetType.transition,
                    id: transitionId,
                  ),
              ],
            ),
          ),
        );
        totalSteps = stepNumber;
      }

      // Expand each active leaf node in the computation tree
      final newActiveLeaves = <NFAPathNode>[];
      for (final leaf in activeLeaves) {
        if (DateTime.now().difference(startTime) > timeout) {
          final tree = NFAComputationTree.timeout(
            root: _buildTreeRoot(rootNodes),
            inputString: inputString,
            totalSteps: totalSteps,
          );
          return SimulationResult.timeout(
            inputString: inputString,
            steps: steps,
            executionTime: DateTime.now().difference(startTime),
            computationTree: tree,
          );
        }

        // Find which state this leaf represents
        final leafState = nfa.states.firstWhere(
          (s) => s.id == leaf.currentState,
          orElse: () => nfa.initialState!,
        );

        // Get transitions from this state on the current symbol
        final transitions = transitionIndex.transitionsFor(leafState, symbol);

        // Keep one child per concrete symbol transition and epsilon path.
        // This preserves parallel-edge identity and avoids inventing a direct
        // symbol transition to states reached only through epsilon closure.
        final destinations = <_FsaRecordedPath>[];
        var epsilonPathsTruncated = false;
        var epsilonPathDepthLimited = false;
        var epsilonPathsTimedOut = false;
        for (final t in transitions) {
          final remainingSlots =
              maxTraceNodes - traceNodeCount - destinations.length;
          if (remainingSlots <= 0) {
            epsilonPathsTruncated = true;
            break;
          }
          final expansion = transitionIndex.epsilonPathsFrom(
            t.toState,
            maximumPaths: remainingSlots,
            maximumPathLength: defaultMaxNfaEpsilonPathEdges,
            shouldStop: () => DateTime.now().difference(startTime) >= timeout,
          );
          for (final epsilonPath in expansion.paths) {
            destinations.add(
              _FsaRecordedPath(
                state: epsilonPath.state,
                symbolTransition: t,
                epsilonTransitions: epsilonPath.transitions,
                closesEpsilonCycle: epsilonPath.closesCycle,
              ),
            );
          }
          if (expansion.timedOut) {
            epsilonPathsTimedOut = true;
            break;
          }
          if (expansion.truncated) {
            epsilonPathsTruncated = true;
            epsilonPathDepthLimited = expansion.depthLimited;
            break;
          }
        }

        if (epsilonPathsTimedOut) {
          final tree = NFAComputationTree.timeout(
            root: _buildTreeRoot(rootNodes),
            inputString: inputString,
            totalSteps: totalSteps,
          );
          return SimulationResult.timeout(
            inputString: inputString,
            steps: steps,
            executionTime: DateTime.now().difference(startTime),
            computationTree: tree,
          );
        }

        if (epsilonPathsTruncated && destinations.isEmpty) {
          final legacyMessage = _nfaTraceTruncationMessage(
            maxTraceNodes,
            epsilonPathLimited: epsilonPathDepthLimited,
          );
          final message = AutomatonSimulationMessages.nfaTraceTruncated(
            maximumNodes: maxTraceNodes,
            epsilonPathLimited: epsilonPathDepthLimited,
            epsilonPathLimit: defaultMaxNfaEpsilonPathEdges,
          );
          final tree = NFAComputationTree.rejected(
            root: _buildTreeRoot(rootNodes),
            inputString: inputString,
            totalSteps: totalSteps,
            errorMessage: legacyMessage,
            structuredMessage: message,
          );
          return SimulationResult.structuredFailure(
            inputString: inputString,
            steps: steps,
            message: message,
            executionTime: DateTime.now().difference(startTime),
            compatibilityErrorMessage: legacyMessage,
            computationTree: tree,
          );
        }

        if (destinations.isEmpty) {
          // Dead end - mark the leaf as dead-end and update it in the tree
          final deadEndLeaf = leaf.copyWith(isDeadEnd: true);
          _replaceNodeInTree(rootNodes, leaf, deadEndLeaf);
          allLeaves.add(deadEndLeaf);
        } else {
          // Create child nodes for each destination state
          final children = <NFAPathNode>[];
          for (final destination in destinations) {
            if (traceNodeCount >= maxTraceNodes) {
              final legacyMessage = _nfaTraceTruncationMessage(maxTraceNodes);
              final message = AutomatonSimulationMessages.nfaTraceTruncated(
                maximumNodes: maxTraceNodes,
                epsilonPathLimited: false,
                epsilonPathLimit: defaultMaxNfaEpsilonPathEdges,
              );
              final tree = NFAComputationTree.rejected(
                root: _buildTreeRoot(rootNodes),
                inputString: inputString,
                totalSteps: totalSteps,
                errorMessage: legacyMessage,
                structuredMessage: message,
              );
              return SimulationResult.structuredFailure(
                inputString: inputString,
                steps: steps,
                message: message,
                executionTime: DateTime.now().difference(startTime),
                compatibilityErrorMessage: legacyMessage,
                computationTree: tree,
              );
            }
            final destState = destination.state;
            final epsilonTransitions = destination.epsilonTransitions;
            final transitionSummary = epsilonTransitions.isEmpty
                ? 'δ(${leafState.label}, $symbol) → '
                      '${destination.symbolTransition.toState.label}'
                : 'δ(${leafState.label}, $symbol) → '
                      '${destination.symbolTransition.toState.label}; '
                      'ε → ${epsilonTransitions.map((transition) => transition.toState.label).join(' → ε → ')}';
            final childNode = NFAPathNode(
              currentState: destState.id,
              remainingInput: remainingInput,
              inputSymbol: symbol,
              transitionUsed: transitionSummary,
              transitionIds: [
                destination.symbolTransition.id,
                for (final transition in epsilonTransitions) transition.id,
              ],
              stepNumber: symbolStepNumber,
              isCycle: destination.closesEpsilonCycle,
              descriptionMessage:
                  AutomatonSimulationMessages.consumedSymbolDescription(
                    symbol: symbol,
                    stateId: destState.id,
                  ),
            );
            children.add(childNode);
            if (!childNode.isCycle) {
              newActiveLeaves.add(childNode);
            }
            traceNodeCount++;
          }
          // Update the leaf with its children (create a new node)
          final updatedLeaf = leaf.copyWith(children: children);
          // Replace the old leaf in rootNodes
          _replaceNodeInTree(rootNodes, leaf, updatedLeaf);
          if (epsilonPathsTruncated) {
            final legacyMessage = _nfaTraceTruncationMessage(
              maxTraceNodes,
              epsilonPathLimited: epsilonPathDepthLimited,
            );
            final message = AutomatonSimulationMessages.nfaTraceTruncated(
              maximumNodes: maxTraceNodes,
              epsilonPathLimited: epsilonPathDepthLimited,
              epsilonPathLimit: defaultMaxNfaEpsilonPathEdges,
            );
            final tree = NFAComputationTree.rejected(
              root: _buildTreeRoot(rootNodes),
              inputString: inputString,
              totalSteps: totalSteps,
              errorMessage: legacyMessage,
              structuredMessage: message,
            );
            return SimulationResult.structuredFailure(
              inputString: inputString,
              steps: steps,
              message: message,
              executionTime: DateTime.now().difference(startTime),
              compatibilityErrorMessage: legacyMessage,
              computationTree: tree,
            );
          }
        }
      }

      currentStates = nextStates;
      activeLeaves = newActiveLeaves;

      // If no next states, early reject
      if (currentStates.isEmpty) {
        final message = AutomatonSimulationMessages.noNfaTransition(symbol);
        final legacyMessage = 'No transition found for symbol $symbol';
        final treeRoot = _buildTreeRoot(rootNodes);
        final tree = NFAComputationTree.rejected(
          root: treeRoot,
          inputString: inputString,
          totalSteps: totalSteps,
          errorMessage: legacyMessage,
          structuredMessage: message,
        );
        return SimulationResult.structuredFailure(
          inputString: inputString,
          steps: steps,
          message: message,
          executionTime: DateTime.now().difference(startTime),
          compatibilityErrorMessage: legacyMessage,
          computationTree: tree,
        );
      }
    }

    // Mark final leaf nodes as accepting or dead-end
    for (final leaf in activeLeaves) {
      final leafState = nfa.states.firstWhere(
        (s) => s.id == leaf.currentState,
        orElse: () => nfa.initialState!,
      );
      final isAccepting = nfa.acceptingStates.contains(leafState);
      final updatedLeaf = leaf.copyWith(
        isAccepting: isAccepting,
        isDeadEnd: !isAccepting,
      );
      _replaceNodeInTree(rootNodes, leaf, updatedLeaf);
      allLeaves.add(updatedLeaf);
    }

    // Check if any current state is accepting
    final isAccepted = currentStates
        .intersection(nfa.acceptingStates)
        .isNotEmpty;

    final finalStateLabel = currentStates.length == 1
        ? currentStates.first.label
        : '{${currentStates.map((s) => s.label).join(',')}}';
    final shouldAddFinalStep =
        steps.isEmpty ||
        steps.last.remainingInput.isNotEmpty ||
        steps.last.usedTransition == _epsilonClosureTransition ||
        steps.last.currentState != finalStateLabel;
    final finalStepNumber = shouldAddFinalStep ? nextStepNumber() : stepNumber;
    totalSteps = stepNumber;

    if (shouldAddFinalStep) {
      steps.add(
        SimulationStep.finalStep(
          finalState: finalStateLabel,
          activeStateIds: {for (final state in currentStates) state.id},
          remainingInput: remainingInput,
          stackContents: '',
          tapeContents: '',
          stepNumber: finalStepNumber,
        ),
      );
    }

    // Build final computation tree
    final treeRoot = _buildTreeRoot(rootNodes);
    final tree = isAccepted
        ? NFAComputationTree.accepted(
            root: treeRoot,
            inputString: inputString,
            totalSteps: totalSteps,
          )
        : NFAComputationTree.rejected(
            root: treeRoot,
            inputString: inputString,
            totalSteps: totalSteps,
            errorMessage: 'Input not accepted - no accepting state reached',
            structuredMessage: AutomatonSimulationMessages.nfaNotAccepted(),
          );

    if (isAccepted) {
      return SimulationResult.success(
        inputString: inputString,
        steps: steps,
        executionTime: DateTime.now().difference(startTime),
        computationTree: tree,
      );
    } else {
      return SimulationResult.structuredFailure(
        inputString: inputString,
        steps: steps,
        message: AutomatonSimulationMessages.nfaNotAccepted(),
        executionTime: DateTime.now().difference(startTime),
        compatibilityErrorMessage:
            'Input not accepted - no accepting state reached',
        computationTree: tree,
      );
    }
  }

  static SimulationResult _recognizeNFA(
    FSA nfa,
    _FsaTransitionIndex transitionIndex,
    String inputString,
    Duration timeout,
  ) {
    final stopwatch = Stopwatch()..start();
    var currentStates = transitionIndex.epsilonClosure({nfa.initialState!});
    for (final input in _unicodeScalars(inputString)) {
      final symbol = input.symbol;
      if (stopwatch.elapsed > timeout) {
        return SimulationResult.timeout(
          inputString: inputString,
          steps: const [],
          executionTime: stopwatch.elapsed,
        );
      }

      final destinations = <State>{};
      for (final state in currentStates) {
        destinations.addAll(
          transitionIndex
              .transitionsFor(state, symbol)
              .map((transition) => transition.toState),
        );
      }
      currentStates = transitionIndex.epsilonClosure(destinations);
      if (currentStates.isEmpty) {
        return SimulationResult.structuredFailure(
          inputString: inputString,
          steps: const [],
          message: AutomatonSimulationMessages.noNfaTransition(symbol),
          executionTime: stopwatch.elapsed,
        );
      }
    }

    final accepted = currentStates.intersection(nfa.acceptingStates).isNotEmpty;
    if (accepted) {
      return SimulationResult.success(
        inputString: inputString,
        steps: const [],
        executionTime: stopwatch.elapsed,
      );
    }
    return SimulationResult.structuredFailure(
      inputString: inputString,
      steps: const [],
      message: AutomatonSimulationMessages.nfaNotAccepted(),
      executionTime: stopwatch.elapsed,
    );
  }

  static List<({String symbol, int start, int end})> _unicodeScalars(
    String input,
  ) {
    final scalars = <({String symbol, int start, int end})>[];
    var offset = 0;
    for (final rune in input.runes) {
      final symbol = String.fromCharCode(rune);
      scalars.add((symbol: symbol, start: offset, end: offset + symbol.length));
      offset += symbol.length;
    }
    return scalars;
  }

  static String _nfaTraceTruncationMessage(
    int maximumNodes, {
    bool epsilonPathLimited = false,
  }) {
    final bound = epsilonPathLimited
        ? 'at the $defaultMaxNfaEpsilonPathEdges-edge epsilon-path limit'
        : 'after $maximumNodes nodes';
    return 'NFA trace truncated $bound. '
        'Rerun without step-by-step tracing to check acceptance.';
  }

  /// Builds a single root node from multiple root nodes (for epsilon closure)
  static NFAPathNode _buildTreeRoot(List<NFAPathNode> rootNodes) {
    if (rootNodes.isEmpty) {
      return const NFAPathNode(
        currentState: 'empty',
        remainingInput: '',
        stepNumber: 0,
        isDeadEnd: true,
      );
    }
    if (rootNodes.length == 1) {
      return rootNodes.first;
    }
    // Create a virtual root node that branches to all epsilon-closure states
    return NFAPathNode(
      currentState: '{${rootNodes.map((n) => n.currentState).join(',')}}',
      remainingInput: rootNodes.first.remainingInput,
      stepNumber: 0,
      children: rootNodes,
      transitionUsed: 'ε-closure of initial state',
      descriptionMessage:
          AutomatonSimulationMessages.initialEpsilonClosureDescription(),
    );
  }

  /// Replaces a node in the tree (recursive helper)
  static void _replaceNodeInTree(
    List<NFAPathNode> rootNodes,
    NFAPathNode oldNode,
    NFAPathNode newNode,
  ) {
    for (int i = 0; i < rootNodes.length; i++) {
      if (rootNodes[i] == oldNode) {
        rootNodes[i] = newNode;
        return;
      }
      if (rootNodes[i].children.isNotEmpty) {
        final childrenList = rootNodes[i].children.toList();
        _replaceNodeInList(childrenList, oldNode, newNode);
        if (childrenList != rootNodes[i].children) {
          rootNodes[i] = rootNodes[i].copyWith(children: childrenList);
        }
      }
    }
  }

  /// Helper to replace a node in a list of children
  static void _replaceNodeInList(
    List<NFAPathNode> nodes,
    NFAPathNode oldNode,
    NFAPathNode newNode,
  ) {
    for (int i = 0; i < nodes.length; i++) {
      if (nodes[i] == oldNode) {
        nodes[i] = newNode;
        return;
      }
      if (nodes[i].children.isNotEmpty) {
        final childrenList = nodes[i].children.toList();
        _replaceNodeInList(childrenList, oldNode, newNode);
        if (childrenList != nodes[i].children) {
          nodes[i] = nodes[i].copyWith(children: childrenList);
        }
      }
    }
  }

  /// Tests if an automaton accepts a specific string
  static Future<Result<bool>> accepts(FSA automaton, String inputString) async {
    final simulationResult = await simulate(automaton, inputString);
    if (!simulationResult.isSuccess) {
      return Failure(
        simulationResult.error!,
        structuredMessage: simulationResult.structuredError,
      );
    }

    return Success(simulationResult.data!.accepted);
  }

  /// Tests if an automaton rejects a specific string
  static Future<Result<bool>> rejects(FSA automaton, String inputString) async {
    final acceptsResult = await accepts(automaton, inputString);
    if (!acceptsResult.isSuccess) {
      return Failure(
        acceptsResult.error!,
        structuredMessage: acceptsResult.structuredError,
      );
    }

    return Success(!acceptsResult.data!);
  }

  /// Finds all strings of a given length that the automaton accepts
  static Future<Result<Set<String>>> findAcceptedStrings(
    FSA automaton,
    int maxLength, {
    int maxResults = 100,
  }) async {
    try {
      final acceptedStrings = <String>{};
      final alphabet = automaton.alphabet.toList();

      // Generate all possible strings up to maxLength
      for (
        int length = 0;
        length <= maxLength && acceptedStrings.length < maxResults;
        length++
      ) {
        await _generateStrings(
          automaton,
          alphabet,
          '',
          length,
          acceptedStrings,
          maxResults,
        );
      }

      return Success(acceptedStrings);
    } catch (e) {
      final message = AutomatonSimulationMessages.acceptedStringsFailure(e);
      return Failure(message.stableCode, structuredMessage: message);
    }
  }

  /// Recursively generates strings and tests them
  static Future<void> _generateStrings(
    FSA automaton,
    List<String> alphabet,
    String currentString,
    int remainingLength,
    Set<String> acceptedStrings,
    int maxResults,
  ) async {
    if (acceptedStrings.length >= maxResults) return;

    if (remainingLength == 0) {
      final acceptsResult = await accepts(automaton, currentString);
      if (acceptsResult.isSuccess && acceptsResult.data!) {
        acceptedStrings.add(currentString);
      }
      return;
    }

    for (final symbol in alphabet) {
      await _generateStrings(
        automaton,
        alphabet,
        currentString + symbol,
        remainingLength - 1,
        acceptedStrings,
        maxResults,
      );
    }
  }

  /// Finds all strings of a given length that the automaton rejects
  static Future<Result<Set<String>>> findRejectedStrings(
    FSA automaton,
    int maxLength, {
    int maxResults = 100,
  }) async {
    try {
      final rejectedStrings = <String>{};
      final alphabet = automaton.alphabet.toList();

      // Generate all possible strings up to maxLength
      for (
        int length = 0;
        length <= maxLength && rejectedStrings.length < maxResults;
        length++
      ) {
        await _generateRejectedStrings(
          automaton,
          alphabet,
          '',
          length,
          rejectedStrings,
          maxResults,
        );
      }

      return Success(rejectedStrings);
    } catch (e) {
      final message = AutomatonSimulationMessages.rejectedStringsFailure(e);
      return Failure(message.stableCode, structuredMessage: message);
    }
  }

  /// Recursively generates strings and tests them for rejection
  static Future<void> _generateRejectedStrings(
    FSA automaton,
    List<String> alphabet,
    String currentString,
    int remainingLength,
    Set<String> rejectedStrings,
    int maxResults,
  ) async {
    if (rejectedStrings.length >= maxResults) return;

    if (remainingLength == 0) {
      final acceptsResult = await accepts(automaton, currentString);
      if (acceptsResult.isSuccess && !acceptsResult.data!) {
        rejectedStrings.add(currentString);
      }
      return;
    }

    for (final symbol in alphabet) {
      await _generateRejectedStrings(
        automaton,
        alphabet,
        currentString + symbol,
        remainingLength - 1,
        rejectedStrings,
        maxResults,
      );
    }
  }
}

/// Immutable transition adjacency built once for a single simulation request.
class _FsaTransitionIndex {
  _FsaTransitionIndex(FSA automaton) {
    for (final transition in automaton.transitions.whereType<FSATransition>()) {
      final bySymbol = _transitionsByStateAndSymbol[transition.fromState] ??=
          <String, List<FSATransition>>{};
      for (final symbol in transition.inputSymbols) {
        (bySymbol[symbol] ??= <FSATransition>[]).add(transition);
      }
      if (transition.isEpsilonTransition) {
        (_epsilonDestinations[transition.fromState] ??= <State>{}).add(
          transition.toState,
        );
        (_epsilonTransitions[transition.fromState] ??= <FSATransition>[]).add(
          transition,
        );
      }
    }
  }

  final Map<State, Map<String, List<FSATransition>>>
  _transitionsByStateAndSymbol = {};
  final Map<State, Set<State>> _epsilonDestinations = {};
  final Map<State, List<FSATransition>> _epsilonTransitions = {};

  List<FSATransition> transitionsFor(State state, String symbol) {
    return _transitionsByStateAndSymbol[state]?[symbol] ??
        const <FSATransition>[];
  }

  Set<State> epsilonClosure(Set<State> seeds) {
    return computeEpsilonClosure(
      seeds,
      (state) => _epsilonDestinations[state] ?? const <State>{},
    );
  }

  _FsaEpsilonClosure epsilonClosureWithTransitionIds(Set<State> seeds) {
    final states = epsilonClosure(seeds);
    return _FsaEpsilonClosure(
      states: states,
      transitionIds: {
        for (final state in states)
          for (final transition
              in _epsilonTransitions[state] ?? const <FSATransition>[])
            if (states.contains(transition.toState)) transition.id,
      },
    );
  }

  /// Enumerates distinct epsilon paths without recursively expanding cycles.
  ///
  /// The seed's empty path is included. A transition that closes a cycle is
  /// recorded as the final edge of a path, but that path is not expanded. This
  /// preserves its provenance while keeping the computation trace finite.
  _FsaEpsilonPathExpansion epsilonPathsFrom(
    State seed, {
    required int maximumPaths,
    required int maximumPathLength,
    required bool Function() shouldStop,
  }) {
    if (maximumPaths <= 0) {
      return const _FsaEpsilonPathExpansion(
        paths: [],
        truncated: true,
        depthLimited: false,
        timedOut: false,
      );
    }

    final paths = <_FsaEpsilonPath>[
      _FsaEpsilonPath(state: seed, transitions: const [], closesCycle: false),
    ];
    final queue = Queue<_FsaEpsilonSearchEntry>()
      ..add(
        _FsaEpsilonSearchEntry(
          state: seed,
          transitions: const [],
          visitedStateIds: {seed.id},
        ),
      );
    var truncated = false;
    var depthLimited = false;
    var timedOut = false;

    search:
    while (queue.isNotEmpty) {
      if (shouldStop()) {
        timedOut = true;
        break;
      }
      final current = queue.removeFirst();
      final transitions =
          _epsilonTransitions[current.state] ?? const <FSATransition>[];
      if (current.transitions.length >= maximumPathLength) {
        if (transitions.isNotEmpty) {
          truncated = true;
          depthLimited = true;
        }
        continue;
      }
      for (final transition in transitions) {
        if (shouldStop()) {
          timedOut = true;
          break search;
        }
        if (paths.length >= maximumPaths) {
          truncated = true;
          break search;
        }

        final nextTransitions = [...current.transitions, transition];
        final closesCycle = current.visitedStateIds.contains(
          transition.toState.id,
        );
        paths.add(
          _FsaEpsilonPath(
            state: transition.toState,
            transitions: nextTransitions,
            closesCycle: closesCycle,
          ),
        );

        if (closesCycle) {
          continue;
        }
        queue.add(
          _FsaEpsilonSearchEntry(
            state: transition.toState,
            transitions: nextTransitions,
            visitedStateIds: {
              ...current.visitedStateIds,
              transition.toState.id,
            },
          ),
        );
      }
    }

    return _FsaEpsilonPathExpansion(
      paths: List.unmodifiable(paths),
      truncated: truncated,
      depthLimited: depthLimited,
      timedOut: timedOut,
    );
  }
}

class _FsaEpsilonClosure {
  const _FsaEpsilonClosure({required this.states, required this.transitionIds});

  final Set<State> states;
  final Set<String> transitionIds;
}

class _FsaEpsilonPath {
  const _FsaEpsilonPath({
    required this.state,
    required this.transitions,
    required this.closesCycle,
  });

  final State state;
  final List<FSATransition> transitions;
  final bool closesCycle;
}

class _FsaEpsilonPathExpansion {
  const _FsaEpsilonPathExpansion({
    required this.paths,
    required this.truncated,
    required this.depthLimited,
    required this.timedOut,
  });

  final List<_FsaEpsilonPath> paths;
  final bool truncated;
  final bool depthLimited;
  final bool timedOut;
}

class _FsaEpsilonSearchEntry {
  const _FsaEpsilonSearchEntry({
    required this.state,
    required this.transitions,
    required this.visitedStateIds,
  });

  final State state;
  final List<FSATransition> transitions;
  final Set<String> visitedStateIds;
}

class _FsaRecordedPath {
  const _FsaRecordedPath({
    required this.state,
    required this.symbolTransition,
    required this.epsilonTransitions,
    required this.closesEpsilonCycle,
  });

  final State state;
  final FSATransition symbolTransition;
  final List<FSATransition> epsilonTransitions;
  final bool closesEpsilonCycle;
}
