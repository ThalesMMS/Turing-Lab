//
//  automaton_simulator.dart
//  Turing Lab
//
//  Implementa o motor central de simulação para autômatos finitos, cobrindo
//  execuções determinísticas e não determinísticas com suporte a rastreamento
//  passo a passo. Realiza validações estruturais, controla tempo limite,
//  compila listas de etapas e produz resultados ricos que incluem estatísticas
//  de execução. Serve como base para fachadas de nível superior no domínio de
//  autômatos.
//
//  Thales Matheus Mendonça Santos - October 2025
//
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

/// Simulates Finite Automata (FA) with input strings
class AutomatonSimulator {
  static const _epsilonClosureTransition = 'ε-closure';
  static const int defaultMaxNfaTraceNodes = 10000;

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
        return Failure(validationResult.error!);
      }

      // Validate DFA constraints
      if (automaton.isNondeterministic || automaton.hasEpsilonTransitions) {
        return const Failure(
          'DFA required: automaton must be deterministic and epsilon-free',
        );
      }

      // Handle empty automaton
      if (automaton.states.isEmpty) {
        return const Failure('Cannot simulate empty automaton');
      }

      // Handle automaton with no initial state
      if (automaton.initialState == null) {
        return const Failure('Automaton must have an initial state');
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
      return Failure('Error simulating DFA: $e');
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
      return const Failure('Automaton must have at least one state');
    }

    if (automaton.initialState == null) {
      return const Failure('Automaton must have an initial state');
    }

    if (!automaton.states.contains(automaton.initialState)) {
      return const Failure('Initial state must be in the states set');
    }

    for (final acceptingState in automaton.acceptingStates) {
      if (!automaton.states.contains(acceptingState)) {
        return const Failure('Accepting state must be in the states set');
      }
    }

    // Validate input string symbols
    if (strictAlphabet) {
      for (int i = 0; i < inputString.length; i++) {
        final symbol = inputString[i];
        if (!automaton.alphabet.contains(symbol)) {
          return Failure('Input string contains invalid symbol: $symbol');
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
        inputString: inputString,
      ),
    );

    // Process each input symbol with batching for large inputs.
    for (var inputOffset = 0; inputOffset < inputString.length; inputOffset++) {
      final symbol = inputString[inputOffset];
      stepNumber++;

      // Check timeout
      if (DateTime.now().difference(startTime) > timeout) {
        return SimulationResult.timeout(
          inputString: inputString,
          steps: steps,
          executionTime: DateTime.now().difference(startTime),
        );
      }

      // Find next state deterministically
      final transitions = transitionIndex.transitionsFor(currentState, symbol);
      if (transitions.isEmpty) {
        return SimulationResult.failure(
          inputString: inputString,
          steps: steps,
          errorMessage:
              'No transition from state ${currentState.label} on symbol $symbol',
          executionTime: DateTime.now().difference(startTime),
        );
      }
      final transition = transitions.first;
      final nextState = transition.toState;

      // Check for infinite loop (simplified)
      if (steps.length > 10000) {
        return SimulationResult.infiniteLoop(
          inputString: inputString,
          steps: steps,
          executionTime: DateTime.now().difference(startTime),
        );
      }

      // Add step (record destination state, consistent with TM simulator)
      if (stepByStep) {
        final fromStateLabel = currentState.label;
        steps.add(
          SimulationStep.fsa(
            currentState: nextState.label,
            remainingInput: inputString.substring(inputOffset + 1),
            usedTransition: 'δ($fromStateLabel, $symbol) = ${nextState.label}',
            stepNumber: stepNumber,
            consumedInput: symbol,
            explanation: StepExplanation(
              title: 'Transition applied',
              bullets: [
                'Read symbol "$symbol" from the input.',
                'From state ${currentState.label}, the transition on "$symbol" leads to ${nextState.label}.',
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
      return SimulationResult.failure(
        inputString: inputString,
        steps: steps,
        errorMessage: 'Rejected: no accepting state reached',
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
        return Failure(validationResult.error!);
      }

      // Handle empty automaton
      if (nfa.states.isEmpty) {
        return const Failure('Cannot simulate empty automaton');
      }

      // Handle automaton with no initial state
      if (nfa.initialState == null) {
        return const Failure('Automaton must have an initial state');
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
      return Failure('Error simulating NFA: $e');
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
    final initialClosure = transitionIndex.epsilonClosure({nfa.initialState!});
    var currentStates = initialClosure;
    var remainingInput = inputString;
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
        inputString: inputString,
      ),
    );

    // Optional: make the initial ε-closure explicit in step-by-step mode.
    if (stepByStep && initialClosure.length > 1) {
      steps.add(
        SimulationStep.fsa(
          currentState: initialStateLabel,
          remainingInput: inputString,
          usedTransition: _epsilonClosureTransition,
          stepNumber: nextStepNumber(),
          consumedInput: '',
          explanation: StepExplanation(
            title: 'Computed ε-closure',
            bullets: [
              'Before reading any input, an NFA may take ε-transitions (moves that consume no input).',
              'Starting from ${nfa.initialState!.label}, ε-transitions reach: $initialStateLabel.',
            ],
            categories: const [ExplanationCategory.epsilonMove],
            highlights: [
              for (final s in initialClosure)
                HighlightTarget(type: HighlightTargetType.state, id: s.id),
            ],
          ),
        ),
      );
    }

    // Build computation tree - start with root nodes for each state in epsilon closure
    final rootNodes = <NFAPathNode>[];
    for (final state in currentStates) {
      rootNodes.add(
        NFAPathNode(
          currentState: state.id,
          remainingInput: inputString,
          stepNumber: 0,
          transitionUsed: 'Initial state (with ε-closure)',
          description: 'Initial state ${state.id}',
        ),
      );
    }
    var traceNodeCount = rootNodes.length;

    // Maintain a queue of active path nodes to expand
    var activeLeaves = rootNodes.toList();
    final allLeaves = <NFAPathNode>[];
    int totalSteps = 0;

    // Process each input symbol
    while (remainingInput.isNotEmpty) {
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

      final symbol = remainingInput[0];
      remainingInput = remainingInput.substring(1);

      // Find next states by symbol, exploring all transitions
      var nextStates = <State>{};
      for (final state in currentStates) {
        final transitions = transitionIndex.transitionsFor(state, symbol);
        nextStates.addAll(transitions.map((t) => t.toState));
      }

      // Apply epsilon closure to next states (flexible)
      final closureBefore = nextStates;
      nextStates = transitionIndex.epsilonClosure(nextStates);
      final beforeLabel = stateSetLabel(closureBefore);
      final afterLabel = stateSetLabel(nextStates);

      if (stepByStep) {
        steps.add(
          SimulationStep.fsa(
            currentState: beforeLabel,
            remainingInput: remainingInput,
            usedTransition: symbol,
            stepNumber: symbolStepNumber,
            consumedInput: symbol,
            explanation: StepExplanation(
              title: 'Symbol consumed',
              bullets: [
                'Read symbol "$symbol" from the input.',
                if (closureBefore.length > 1)
                  'This is an NFA step: multiple states may be active at once (nondeterminism).',
                'After taking all possible transitions on "$symbol", the active state set is $beforeLabel.',
              ],
              categories: [
                ExplanationCategory.info,
                if (closureBefore.length > 1)
                  ExplanationCategory.nondeterminism,
              ],
              highlights: [
                for (final s in closureBefore)
                  HighlightTarget(
                    type: HighlightTargetType.state,
                    id: s.id,
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
            remainingInput: remainingInput,
            usedTransition: _epsilonClosureTransition,
            stepNumber: nextStepNumber(),
            consumedInput: '',
            explanation: StepExplanation(
              title: 'Expanded via ε-transitions',
              bullets: [
                'After consuming "$symbol", we also follow any ε-transitions (moves that consume no input).',
                'ε-closure expanded the active state set from $beforeLabel to $afterLabel.',
              ],
              categories: const [ExplanationCategory.epsilonMove],
              highlights: [
                for (final s in nextStates)
                  HighlightTarget(type: HighlightTargetType.state, id: s.id),
              ],
            ),
          ),
        );
        totalSteps = stepNumber;
      }

      // Check for infinite loop (simplified)
      if (steps.length > 1000) {
        final partialRoot = _buildTreeRoot(rootNodes);
        final tree = NFAComputationTree.infiniteLoop(
          root: partialRoot,
          inputString: inputString,
          totalSteps: totalSteps,
        );
        return SimulationResult.infiniteLoop(
          inputString: inputString,
          steps: steps,
          executionTime: DateTime.now().difference(startTime),
          computationTree: tree,
        );
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
        final transitions = transitionIndex.transitionsFor(
          leafState,
          symbol,
        );

        // Get epsilon closure destinations
        final destStates = <State>{};
        for (final t in transitions) {
          destStates.addAll(transitionIndex.epsilonClosure({t.toState}));
        }

        if (destStates.isEmpty) {
          // Dead end - mark the leaf as dead-end and update it in the tree
          final deadEndLeaf = leaf.copyWith(isDeadEnd: true);
          _replaceNodeInTree(rootNodes, leaf, deadEndLeaf);
          allLeaves.add(deadEndLeaf);
        } else {
          // Create child nodes for each destination state
          final children = <NFAPathNode>[];
          for (final destState in destStates) {
            if (traceNodeCount >= maxTraceNodes) {
              const messagePrefix = 'NFA trace truncated';
              final message =
                  '$messagePrefix after $maxTraceNodes nodes. Rerun without step-by-step tracing to check acceptance.';
              final tree = NFAComputationTree.rejected(
                root: _buildTreeRoot(rootNodes),
                inputString: inputString,
                totalSteps: totalSteps,
                errorMessage: message,
              );
              return SimulationResult.failure(
                inputString: inputString,
                steps: steps,
                errorMessage: message,
                executionTime: DateTime.now().difference(startTime),
                computationTree: tree,
              );
            }
            final childNode = NFAPathNode(
              currentState: destState.id,
              remainingInput: remainingInput,
              inputSymbol: symbol,
              transitionUsed:
                  'δ(${leaf.currentState}, $symbol) → ${destState.id}',
              stepNumber: symbolStepNumber,
              description: 'Consumed $symbol, now at ${destState.id}',
            );
            children.add(childNode);
            newActiveLeaves.add(childNode);
            traceNodeCount++;
          }
          // Update the leaf with its children (create a new node)
          final updatedLeaf = leaf.copyWith(children: children);
          // Replace the old leaf in rootNodes
          _replaceNodeInTree(rootNodes, leaf, updatedLeaf);
        }
      }

      currentStates = nextStates;
      activeLeaves = newActiveLeaves;

      // If no next states, early reject
      if (currentStates.isEmpty) {
        final treeRoot = _buildTreeRoot(rootNodes);
        final tree = NFAComputationTree.rejected(
          root: treeRoot,
          inputString: inputString,
          totalSteps: totalSteps,
          errorMessage: 'No transition found for symbol $symbol',
        );
        return SimulationResult.failure(
          inputString: inputString,
          steps: steps,
          errorMessage: 'No transition found for symbol $symbol',
          executionTime: DateTime.now().difference(startTime),
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
    final isAccepted =
        currentStates.intersection(nfa.acceptingStates).isNotEmpty;

    final finalStateLabel = currentStates.length == 1
        ? currentStates.first.label
        : '{${currentStates.map((s) => s.label).join(',')}}';
    final shouldAddFinalStep = steps.isEmpty ||
        steps.last.remainingInput.isNotEmpty ||
        steps.last.usedTransition == _epsilonClosureTransition ||
        steps.last.currentState != finalStateLabel;
    final finalStepNumber = shouldAddFinalStep ? nextStepNumber() : stepNumber;
    totalSteps = stepNumber;

    if (shouldAddFinalStep) {
      steps.add(
        SimulationStep.finalStep(
          finalState: finalStateLabel,
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
          );

    if (isAccepted) {
      return SimulationResult.success(
        inputString: inputString,
        steps: steps,
        executionTime: DateTime.now().difference(startTime),
        computationTree: tree,
      );
    } else {
      return SimulationResult.failure(
        inputString: inputString,
        steps: steps,
        errorMessage: 'Input not accepted - no accepting state reached',
        executionTime: DateTime.now().difference(startTime),
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
    for (var inputOffset = 0; inputOffset < inputString.length; inputOffset++) {
      final symbol = inputString[inputOffset];
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
        return SimulationResult.failure(
          inputString: inputString,
          steps: const [],
          errorMessage: 'No transition found for symbol $symbol',
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
    return SimulationResult.failure(
      inputString: inputString,
      steps: const [],
      errorMessage: 'Input not accepted - no accepting state reached',
      executionTime: stopwatch.elapsed,
    );
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
      description: 'Initial ε-closure',
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
      return Failure(simulationResult.error!);
    }

    return Success(simulationResult.data!.accepted);
  }

  /// Tests if an automaton rejects a specific string
  static Future<Result<bool>> rejects(FSA automaton, String inputString) async {
    final acceptsResult = await accepts(automaton, inputString);
    if (!acceptsResult.isSuccess) {
      return Failure(acceptsResult.error!);
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
      for (int length = 0;
          length <= maxLength && acceptedStrings.length < maxResults;
          length++) {
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
      return Failure('Error finding accepted strings: $e');
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
      for (int length = 0;
          length <= maxLength && rejectedStrings.length < maxResults;
          length++) {
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
      return Failure('Error finding rejected strings: $e');
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
        (_epsilonDestinations[transition.fromState] ??= <State>{})
            .add(transition.toState);
      }
    }
  }

  final Map<State, Map<String, List<FSATransition>>>
      _transitionsByStateAndSymbol = {};
  final Map<State, Set<State>> _epsilonDestinations = {};

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
}
