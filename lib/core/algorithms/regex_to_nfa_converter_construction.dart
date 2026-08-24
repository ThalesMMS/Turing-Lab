part of 'regex_to_nfa_converter.dart';

FSA _thompsonConstruction(RegexNode node, {Set<String>? contextAlphabet}) {
  final nfa = _buildNFA(node, contextAlphabet: contextAlphabet);
  return nfa;
}

/// Converts regex node to NFA using Thompson's construction with step capture
FSA _thompsonConstructionWithSteps(
  RegexNode node,
  List<RegexToNFAStep> steps,
  int stepCounter, {
  Set<String>? contextAlphabet,
}) {
  final stepContext = _RegexToNfaStepContext(
    steps: steps,
    stepCounter: stepCounter,
  );
  final nfa = _buildNFAWithSteps(
    node,
    steps,
    stepCounter,
    contextAlphabet: contextAlphabet,
    stepContext: stepContext,
  );
  return nfa;
}

/// Builds NFA from regex node
FSA _buildNFA(RegexNode node, {Set<String>? contextAlphabet}) {
  return _buildNFAInternal(node, contextAlphabet: contextAlphabet);
}

int _nextRegexToNfaStepNumber(
  List<RegexToNFAStep> steps,
  int stepCounter,
) {
  return steps.isNotEmpty
      ? steps.last.baseStep.stepNumber + 1
      : stepCounter + steps.length;
}

class _RegexToNfaStepContext {
  _RegexToNfaStepContext({
    required this.steps,
    required this.stepCounter,
  });

  final List<RegexToNFAStep> steps;
  final int stepCounter;
  int fragmentStackDepth = 0;

  int nextStepNumber() => _nextRegexToNfaStepNumber(steps, stepCounter);

  int pushFragment() {
    fragmentStackDepth++;
    return fragmentStackDepth;
  }

  int applyUnaryOperator() => fragmentStackDepth;

  int applyBinaryOperator() {
    if (fragmentStackDepth < 2) {
      throw StateError(
        'Cannot apply binary regex operator with fragmentStackDepth '
        '$fragmentStackDepth; expected at least 2 fragments.',
      );
    }
    fragmentStackDepth--;
    return fragmentStackDepth;
  }
}

/// Builds NFA from regex node with step capture
FSA _buildNFAWithSteps(
  RegexNode node,
  List<RegexToNFAStep> steps,
  int stepCounter, {
  Set<String>? contextAlphabet,
  _RegexToNfaStepContext? stepContext,
}) {
  final context = stepContext ??
      _RegexToNfaStepContext(steps: steps, stepCounter: stepCounter);
  return _buildNFAInternal(
    node,
    contextAlphabet: contextAlphabet,
    stepContext: context,
  );
}

FSA _buildNFAInternal(
  RegexNode node, {
  Set<String>? contextAlphabet,
  _RegexToNfaStepContext? stepContext,
}) {
  switch (node) {
    case EpsilonNode():
      return _handleEpsilonNode(
        position: node.position,
        stepContext: stepContext,
      );
    case SymbolNode(:final symbol):
      return _handleSymbolNode(
        symbol,
        position: node.position,
        stepContext: stepContext,
      );
    case DotNode():
      return _handleDotNode(
        position: node.position,
        contextAlphabet: contextAlphabet,
        stepContext: stepContext,
      );
    case UnionNode(:final left, :final right):
      return _handleUnionNode(
        left,
        right,
        position: node.position,
        contextAlphabet: contextAlphabet,
        stepContext: stepContext,
      );
    case ConcatenationNode(:final left, :final right):
      return _handleConcatenationNode(
        left,
        right,
        position: node.position,
        contextAlphabet: contextAlphabet,
        stepContext: stepContext,
      );
    case KleeneStarNode(:final child):
      return _handleKleeneStarNode(
        child,
        position: node.position,
        contextAlphabet: contextAlphabet,
        stepContext: stepContext,
      );
    case PlusNode(:final child):
      return _handlePlusNode(
        child,
        position: node.position,
        contextAlphabet: contextAlphabet,
        stepContext: stepContext,
      );
    case QuestionNode(:final child):
      return _handleQuestionNode(
        child,
        position: node.position,
        contextAlphabet: contextAlphabet,
        stepContext: stepContext,
      );
    case SetNode(:final symbols):
      return _handleSetNode(
        symbols,
        position: node.position,
        stepContext: stepContext,
      );
    case ShortcutNode(:final code):
      return _handleShortcutNode(
        code,
        position: node.position,
        contextAlphabet: contextAlphabet,
        stepContext: stepContext,
      );
    case _:
      throw ArgumentError('Unknown regex node type: ${node.runtimeType}');
  }
}

FSA _handleEpsilonNode({
  int? position,
  _RegexToNfaStepContext? stepContext,
}) {
  final nfa = _buildEpsilonNFA();
  _recordFragmentStep(
    stepContext,
    nfa: nfa,
    symbol: 'ε',
    position: position,
    title: 'Create NFA for epsilon',
    explanation: 'Creating an NFA fragment that accepts the empty string.',
  );
  return nfa;
}

FSA _handleSymbolNode(
  String symbol, {
  int? position,
  _RegexToNfaStepContext? stepContext,
}) {
  final nfa = _buildSymbolNFA(symbol);
  _recordFragmentStep(
    stepContext,
    nfa: nfa,
    symbol: symbol,
    position: position,
    title: 'Create NFA for symbol \'$symbol\'',
    explanation: 'Creating an NFA fragment for symbol \'$symbol\'.',
  );
  return nfa;
}

FSA _handleDotNode({
  int? position,
  Set<String>? contextAlphabet,
  _RegexToNfaStepContext? stepContext,
}) {
  final nfa = _buildDotNFA(contextAlphabet: contextAlphabet);
  final symbols = _formatSymbolSet(nfa.alphabet);
  _recordFragmentStep(
    stepContext,
    nfa: nfa,
    symbol: '.',
    position: position,
    title: 'Create NFA for wildcard',
    explanation:
        'Creating an NFA fragment for wildcard "." over alphabet $symbols.',
  );
  return nfa;
}

FSA _handleSetNode(
  Set<String> symbols, {
  int? position,
  _RegexToNfaStepContext? stepContext,
}) {
  final nfa = _buildSetNFA(symbols);
  final display = '[${_formatSymbolSet(symbols)}]';
  _recordFragmentStep(
    stepContext,
    nfa: nfa,
    symbol: display,
    position: position,
    title: 'Create NFA for character class',
    explanation:
        'Creating an NFA fragment for character class $display with one '
        'transition per accepted symbol.',
  );
  return nfa;
}

FSA _handleShortcutNode(
  String code, {
  int? position,
  Set<String>? contextAlphabet,
  _RegexToNfaStepContext? stepContext,
}) {
  final symbols = _expandShortcut(code, contextAlphabet);
  final nfa = _buildSetNFA(symbols);
  final display = '\\$code';
  _recordFragmentStep(
    stepContext,
    nfa: nfa,
    symbol: display,
    position: position,
    title: 'Create NFA for shortcut $display',
    explanation: 'Creating an NFA fragment for shortcut $display expanded to '
        '${_formatSymbolSet(symbols)}.',
  );
  return nfa;
}

FSA _handleUnionNode(
  RegexNode left,
  RegexNode right, {
  int? position,
  Set<String>? contextAlphabet,
  _RegexToNfaStepContext? stepContext,
}) {
  if (stepContext == null) {
    return _buildUnionNFA(left, right, contextAlphabet: contextAlphabet);
  }

  final leftNFA = _buildNFAInternal(
    left,
    contextAlphabet: contextAlphabet,
    stepContext: stepContext,
  );
  final rightNFA = _buildNFAInternal(
    right,
    contextAlphabet: contextAlphabet,
    stepContext: stepContext,
  );

  final nfa = _buildUnionFromFragments(leftNFA, rightNFA);
  final newStart = nfa.initialState!;
  final newAccept = nfa.acceptingStates.first;
  final newTransitions = nfa.fsaTransitions
      .where(
        (t) => t.fromState == newStart || t.toState == newAccept,
      )
      .toSet();
  final nextStepNumber = stepContext.nextStepNumber();
  final stackSize = stepContext.applyBinaryOperator();

  stepContext.steps.add(
    RegexToNFAStep.union(
      id: 'step_$nextStepNumber',
      stepNumber: nextStepNumber,
      position: position,
      firstFragmentLabel: leftNFA.name,
      secondFragmentLabel: rightNFA.name,
      newStart: newStart,
      newAccept: newAccept,
      firstStart: leftNFA.initialState!,
      firstAcceptStates: leftNFA.acceptingStates,
      secondStart: rightNFA.initialState!,
      secondAcceptStates: rightNFA.acceptingStates,
      newTransitions: newTransitions,
      stackSize: stackSize,
    ),
  );
  return nfa;
}

FSA _handleConcatenationNode(
  RegexNode left,
  RegexNode right, {
  int? position,
  Set<String>? contextAlphabet,
  _RegexToNfaStepContext? stepContext,
}) {
  if (stepContext == null) {
    return _buildConcatenationNFA(
      left,
      right,
      contextAlphabet: contextAlphabet,
    );
  }

  final leftNFA = _buildNFAInternal(
    left,
    contextAlphabet: contextAlphabet,
    stepContext: stepContext,
  );
  final rightNFA = _buildNFAInternal(
    right,
    contextAlphabet: contextAlphabet,
    stepContext: stepContext,
  );

  final concatenation = _concatenateFragments(leftNFA, rightNFA);
  final nfa = concatenation.resultNFA;
  final epsilonTransitions = concatenation.epsilonBridges;
  final leftClones = {
    for (final clone in concatenation.clonesFor(FSAConcatenationOperand.left))
      clone.originalStateId: clone.clonedState,
  };
  final rightClones = {
    for (final clone in concatenation.clonesFor(FSAConcatenationOperand.right))
      clone.originalStateId: clone.clonedState,
  };
  if (epsilonTransitions.isEmpty) {
    throw StateError(
      'Expected concatenation epsilon transition was not found '
      'from left accepting states ${leftNFA.acceptingStates} '
      'to right initial state ${rightNFA.initialState}.',
    );
  }
  final nextStepNumber = stepContext.nextStepNumber();
  final stackSize = stepContext.applyBinaryOperator();

  stepContext.steps.add(
    RegexToNFAStep.concatenation(
      id: 'step_$nextStepNumber',
      stepNumber: nextStepNumber,
      position: position,
      firstFragmentLabel: leftNFA.name,
      secondFragmentLabel: rightNFA.name,
      firstStart: leftClones[leftNFA.initialState!.id]!,
      firstAcceptStates:
          leftNFA.acceptingStates.map((state) => leftClones[state.id]!).toSet(),
      secondStart: rightClones[rightNFA.initialState!.id]!,
      secondAcceptStates: rightNFA.acceptingStates
          .map((state) => rightClones[state.id]!)
          .toSet(),
      epsilonTransitions: epsilonTransitions,
      stackSize: stackSize,
    ),
  );
  return nfa;
}

FSA _handleKleeneStarNode(
  RegexNode child, {
  int? position,
  Set<String>? contextAlphabet,
  _RegexToNfaStepContext? stepContext,
}) {
  if (stepContext == null) {
    return _buildKleeneStarNFA(child, contextAlphabet: contextAlphabet);
  }

  final childNFA = _buildNFAInternal(
    child,
    contextAlphabet: contextAlphabet,
    stepContext: stepContext,
  );
  final star = _applyKleeneStarToFragment(childNFA);
  final nfa = star.resultNFA;
  final newStart = star.newInitialState;
  final newAccept = star.newAcceptingState;
  final newTransitions = {
    star.entryTransition,
    ...star.repeatTransitions,
    ...star.exitTransitions,
  };
  final nextStepNumber = stepContext.nextStepNumber();
  final stackSize = stepContext.applyUnaryOperator();

  stepContext.steps.add(
    RegexToNFAStep.kleeneStar(
      id: 'step_$nextStepNumber',
      stepNumber: nextStepNumber,
      position: position,
      fragmentLabel: childNFA.name,
      newStart: newStart,
      newAccept: newAccept,
      oldStart: star.stateClones[childNFA.initialState!.id]!,
      oldAcceptStates: childNFA.acceptingStates
          .map((state) => star.stateClones[state.id]!)
          .toSet(),
      newTransitions: newTransitions,
      stackSize: stackSize,
    ),
  );
  return nfa;
}

FSA _handlePlusNode(
  RegexNode child, {
  int? position,
  Set<String>? contextAlphabet,
  _RegexToNfaStepContext? stepContext,
}) {
  if (stepContext == null) {
    return _buildPlusNFA(child, contextAlphabet: contextAlphabet);
  }

  final childNFA = _buildNFAInternal(
    child,
    contextAlphabet: contextAlphabet,
    stepContext: stepContext,
  );
  final nfa = _buildPlusFromFragment(childNFA);
  final newStart = nfa.initialState!;
  final newAccept = nfa.acceptingStates.first;
  final newTransitions = nfa.fsaTransitions.difference(childNFA.fsaTransitions);
  final nextStepNumber = stepContext.nextStepNumber();
  final stackSize = stepContext.applyUnaryOperator();

  stepContext.steps.add(
    RegexToNFAStep.plus(
      id: 'step_$nextStepNumber',
      stepNumber: nextStepNumber,
      position: position,
      fragmentLabel: childNFA.name,
      newStart: newStart,
      newAccept: newAccept,
      oldStart: childNFA.initialState!,
      oldAcceptStates: childNFA.acceptingStates,
      newTransitions: newTransitions,
      stackSize: stackSize,
    ),
  );
  return nfa;
}

FSA _handleQuestionNode(
  RegexNode child, {
  int? position,
  Set<String>? contextAlphabet,
  _RegexToNfaStepContext? stepContext,
}) {
  if (stepContext == null) {
    return _buildQuestionNFA(child, contextAlphabet: contextAlphabet);
  }

  final childNFA = _buildNFAInternal(
    child,
    contextAlphabet: contextAlphabet,
    stepContext: stepContext,
  );
  final nfa = _buildQuestionFromFragment(childNFA);
  final newStart = nfa.initialState!;
  final newAccept = nfa.acceptingStates.firstWhere(
    (s) => s != newStart,
  );
  final newTransitions = nfa.fsaTransitions.difference(childNFA.fsaTransitions);
  final nextStepNumber = stepContext.nextStepNumber();
  final stackSize = stepContext.applyUnaryOperator();

  stepContext.steps.add(
    RegexToNFAStep.optional(
      id: 'step_$nextStepNumber',
      stepNumber: nextStepNumber,
      position: position,
      fragmentLabel: childNFA.name,
      newStart: newStart,
      newAccept: newAccept,
      oldStart: childNFA.initialState!,
      oldAcceptStates: childNFA.acceptingStates,
      newTransitions: newTransitions,
      stackSize: stackSize,
    ),
  );
  return nfa;
}

void _recordFragmentStep(
  _RegexToNfaStepContext? stepContext, {
  required FSA nfa,
  required String symbol,
  required int? position,
  required String title,
  required String explanation,
}) {
  if (stepContext == null) {
    return;
  }

  final startState = nfa.initialState!;
  final acceptState = nfa.acceptingStates.first;
  final stackSize = stepContext.pushFragment();
  final nextStepNumber = stepContext.nextStepNumber();

  stepContext.steps.add(
    RegexToNFAStep(
      baseStep: AlgorithmStep(
        id: 'step_$nextStepNumber',
        stepNumber: nextStepNumber,
        title: title,
        explanation:
            '$explanation This fragment has ${nfa.states.length} states and '
            '${nfa.fsaTransitions.length} transition(s), then is pushed onto '
            'the NFA fragment stack.',
        type: AlgorithmType.regexToNfa,
      ),
      stepType: RegexToNFAStepType.basicSymbol,
      regexFragment: symbol,
      regexPosition: position,
      processedSymbol: symbol,
      createdStates: nfa.states,
      createdTransitions: nfa.fsaTransitions.cast<Transition>().toSet(),
      fragmentStartState: startState,
      fragmentAcceptState: acceptState,
      stackSize: stackSize,
    ),
  );
}

String _formatSymbolSet(Set<String> symbols) {
  final sorted = symbols.toList()..sort();
  if (sorted.length <= 8) {
    return sorted.join(', ');
  }
  return '${sorted.take(8).join(', ')}, ...';
}
