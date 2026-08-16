part of 'pda_simulator.dart';

StepExplanation _buildPdaStepExplanation({
  required PDATransition transition,
  required String consumedInput,
  required List<String> priorStack,
  required List<String> nextStack,
}) {
  final lambdaInput =
      transition.isLambdaInput || transition.inputSymbol.isEmpty;
  final lambdaPop = transition.isLambdaPop || transition.popSymbol.isEmpty;
  final lambdaPush = transition.isLambdaPush || transition.pushSymbol.isEmpty;

  final readSymbol = lambdaInput ? 'ε' : consumedInput;
  final popSymbol = lambdaPop ? 'ε' : transition.popSymbol;
  final pushSymbol = lambdaPush ? 'ε' : transition.pushSymbol;

  final beforeTop = priorStack.isEmpty ? '∅' : priorStack.last;
  final afterTop = nextStack.isEmpty ? '∅' : nextStack.last;

  final bullets = <String>[
    'Read input: $readSymbol',
    'Stack action: pop $popSymbol, push $pushSymbol',
    'Top of stack before: $beforeTop → after: $afterTop',
  ];

  if (!lambdaPop) {
    bullets.add(
      'Pop is allowed because the top of stack matches "${transition.popSymbol}".',
    );
  } else {
    bullets.add('No stack symbol was required (ε-pop).');
  }

  if (!lambdaPush && transition.pushSymbol.isNotEmpty) {
    bullets.add('Pushed "${transition.pushSymbol}" onto the stack.');
  } else {
    bullets.add('No symbols were pushed (ε-push).');
  }

  if (lambdaInput) {
    bullets.add(
      'This is an ε-move: it changes the stack/state without consuming input.',
    );
  }

  return StepExplanation(
    title: 'Applied PDA transition',
    bullets: bullets,
    categories: const [
      ExplanationCategory.info,
      ExplanationCategory.stackOperation,
    ],
    highlights: [
      HighlightTarget(
        type: HighlightTargetType.state,
        id: transition.toState.id,
      ),
      HighlightTarget(
        type: HighlightTargetType.transition,
        id: transition.id,
      ),
      if (nextStack.isNotEmpty)
        HighlightTarget(
          type: HighlightTargetType.pdaStack,
          data: {'index': nextStack.length - 1},
        ),
    ],
  );
}

/// Applies a PDA transition's stack operations to a copy of [stack].
///
/// Returns the updated stack, or `null` if the pop operation cannot be applied.
List<String>? _applyTransitionStack(
  PDATransition t,
  List<String> stack,
) {
  final lambdaPop = t.isLambdaPop || t.popSymbol.isEmpty;
  final lambdaPush = t.isLambdaPush || t.pushSymbol.isEmpty;
  final canPop = lambdaPop || (stack.isNotEmpty && stack.last == t.popSymbol);
  if (!canPop) return null;

  final newStack = List<String>.from(stack);
  if (!lambdaPop && newStack.isNotEmpty) {
    newStack.removeLast();
  }
  if (!lambdaPush && t.pushSymbol.isNotEmpty) {
    for (final symbol in t.pushSymbols.reversed) {
      newStack.add(symbol);
    }
  }
  return newStack;
}

/// Returns a human-readable label for a PDA transition.
String _transitionLabel(PDATransition t, String input) {
  final lambdaPop = t.isLambdaPop || t.popSymbol.isEmpty;
  final lambdaPush = t.isLambdaPush || t.pushSymbol.isEmpty;
  return '$input,${lambdaPop ? 'ε' : t.popSymbol}→${lambdaPush ? 'ε' : t.pushSymbol}';
}

String _configurationKey(State state, String remaining, List<String> stack) {
  return '${state.id}\u0000$remaining\u0000${stack.join('\u0001')}';
}

List<SimulationStep> _appendStep(
  List<SimulationStep> steps,
  SimulationStep step,
  bool stepByStep,
) {
  return stepByStep ? [...steps, step] : <SimulationStep>[step];
}

/// Internal NPDA search using BFS over configurations, applying ε-closure.
PDASimulationResult _simulateSearch(
  PDA pda,
  String inputString,
  bool stepByStep,
  Duration timeout,
  PDAAcceptanceMode mode,
  int maxDepth,
  int maxConfigurations,
) {
  final search = _PdaSearch(
    pda,
    inputString,
    stepByStep,
    timeout,
    mode,
    maxDepth,
    maxConfigurations,
  );
  PDASimulationResult? result;
  while (result == null) {
    result = search.runBatch(maxConfigurations + 1);
  }
  return result;
}

typedef _PdaConfiguration = (
  State,
  String,
  List<String>,
  List<SimulationStep>,
  int,
);

class _PdaSearch {
  _PdaSearch(
    this.pda,
    this.inputString,
    this.stepByStep,
    this.timeout,
    this.mode,
    this.maxDepth,
    this.maxConfigurations,
  ) : startTime = DateTime.now() {
    final initialStack = <String>[pda.initialStackSymbol];
    final initialSteps = stepByStep
        ? <SimulationStep>[
            SimulationStep.pda(
              currentState: pda.initialState!.id,
              remainingInput: inputString,
              stackContents: pda.initialStackSymbol,
              stepNumber: 0,
            ),
          ]
        : <SimulationStep>[];
    queue.add(
      (pda.initialState!, inputString, initialStack, initialSteps, 0),
    );
    seenConfigs.add(
      _configurationKey(pda.initialState!, inputString, initialStack),
    );
  }

  final PDA pda;
  final String inputString;
  final bool stepByStep;
  final Duration timeout;
  final PDAAcceptanceMode mode;
  final int maxDepth;
  final int maxConfigurations;
  final DateTime startTime;
  final Queue<_PdaConfiguration> queue = Queue();
  final Set<String> seenConfigs = <String>{};
  var explored = 0;
  var longestBranch = <SimulationStep>[];
  var depthLimitReached = false;

  PDASimulationResult? runBatch(int batchSize) {
    for (var processed = 0;
        processed < batchSize && queue.isNotEmpty;
        processed++) {
      final terminal = _processNext();
      if (terminal != null) return terminal;
    }
    if (queue.isNotEmpty) return null;
    if (depthLimitReached) {
      return PDASimulationResult.limitReached(
        inputString: inputString,
        steps: longestBranch,
        executionTime: DateTime.now().difference(startTime),
      );
    }
    return PDASimulationResult.failure(
      inputString: inputString,
      steps: longestBranch,
      errorMessage: 'Rejected: no accepting configuration found',
      executionTime: DateTime.now().difference(startTime),
    );
  }

  PDASimulationResult? _processNext() {
    if (DateTime.now().difference(startTime) > timeout) {
      return PDASimulationResult.timeout(
        inputString: inputString,
        steps: longestBranch,
        executionTime: DateTime.now().difference(startTime),
      );
    }
    if (explored++ > maxConfigurations) {
      return PDASimulationResult.infiniteLoop(
        inputString: inputString,
        steps: longestBranch,
        executionTime: DateTime.now().difference(startTime),
      );
    }

    final (state, remaining, stack, steps, depth) = queue.removeFirst();
    if (stepByStep && steps.length > longestBranch.length) {
      longestBranch = steps;
    }

    final inputConsumed = remaining.isEmpty;
    final accepted = switch (mode) {
      PDAAcceptanceMode.finalState =>
        inputConsumed && pda.acceptingStates.contains(state),
      PDAAcceptanceMode.emptyStack => inputConsumed &&
          (stack.isEmpty || (stack.length == 1 && stack.last.isEmpty)),
      PDAAcceptanceMode.both => inputConsumed &&
          pda.acceptingStates.contains(state) &&
          (stack.isEmpty || (stack.length == 1 && stack.last.isEmpty)),
    };
    if (accepted) {
      final finalStep = SimulationStep.finalStep(
        finalState: state.id,
        remainingInput: remaining,
        stackContents: stack.join(''),
        tapeContents: '',
        stepNumber: (steps.isNotEmpty ? steps.last.stepNumber : 0) + 1,
      );
      return PDASimulationResult.success(
        inputString: inputString,
        steps: stepByStep
            ? (List<SimulationStep>.from(steps)..add(finalStep))
            : <SimulationStep>[finalStep],
        executionTime: DateTime.now().difference(startTime),
      );
    }

    if (depth >= maxDepth) {
      depthLimitReached = true;
      return null;
    }

    void enqueue(
      State nextState,
      String nextRemaining,
      List<String> nextStack,
      SimulationStep step,
    ) {
      final key = _configurationKey(nextState, nextRemaining, nextStack);
      if (!seenConfigs.add(key)) return;
      queue.add(
        (
          nextState,
          nextRemaining,
          nextStack,
          _appendStep(steps, step, stepByStep),
          depth + 1,
        ),
      );
    }

    final nextStepNumber = (steps.isNotEmpty ? steps.last.stepNumber : 0) + 1;
    for (final transition in pda.pdaTransitions.where(
      (transition) =>
          transition.fromState == state &&
          (transition.isLambdaInput || transition.inputSymbol.isEmpty),
    )) {
      final nextStack = _applyTransitionStack(transition, stack);
      if (nextStack == null) continue;
      enqueue(
        transition.toState,
        remaining,
        nextStack,
        SimulationStep.pda(
          currentState: transition.toState.id,
          remainingInput: remaining,
          stackContents: nextStack.join(''),
          usedTransition: _transitionLabel(transition, 'ε'),
          stepNumber: nextStepNumber,
          consumedInput: '',
          explanation: _buildPdaStepExplanation(
            transition: transition,
            consumedInput: '',
            priorStack: stack,
            nextStack: nextStack,
          ),
        ),
      );
    }

    if (remaining.isNotEmpty) {
      for (final transition in pda.pdaTransitions.where(
        (transition) =>
            transition.fromState == state &&
            !transition.isLambdaInput &&
            transition.inputSymbol.isNotEmpty &&
            remaining.startsWith(transition.inputSymbol),
      )) {
        final symbol = transition.inputSymbol;
        final nextRemaining = remaining.substring(symbol.length);
        final nextStack = _applyTransitionStack(transition, stack);
        if (nextStack == null) continue;
        enqueue(
          transition.toState,
          nextRemaining,
          nextStack,
          SimulationStep.pda(
            currentState: transition.toState.id,
            remainingInput: nextRemaining,
            stackContents: nextStack.join(''),
            usedTransition: _transitionLabel(transition, symbol),
            stepNumber: nextStepNumber,
            consumedInput: symbol,
            explanation: _buildPdaStepExplanation(
              transition: transition,
              consumedInput: symbol,
              priorStack: stack,
              nextStack: nextStack,
            ),
          ),
        );
      }
    }
    return null;
  }
}
