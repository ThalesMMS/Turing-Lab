part of 'regex_to_nfa_converter.dart';

FSA _buildEpsilonNFA() {
  final now = DateTime.now();
  final q0 = State(
    id: _newStateId('q'),
    label: 'q0',
    position: Vector2(100, 100),
    isInitial: true,
    isAccepting: false,
  );
  final q1 = State(
    id: _newStateId('q'),
    label: 'q1',
    position: Vector2(200, 100),
    isInitial: false,
    isAccepting: true,
  );
  final t = FSATransition.epsilon(
    id: _newTransId('t'),
    fromState: q0,
    toState: q1,
  );
  return FSA(
    id: _newAutomatonId('epsilon'),
    name: 'Epsilon',
    states: {q0, q1},
    transitions: {t},
    alphabet: {},
    initialState: q0,
    acceptingStates: {q1},
    created: now,
    modified: now,
    bounds: const math.Rectangle(0, 0, 800, 600),
  );
}

FSA _buildEmptyLanguageNFA() {
  final now = DateTime.now();
  final q0 = State(
    id: _newStateId('q'),
    label: 'q0',
    position: Vector2(100, 100),
    isInitial: true,
    isAccepting: false,
  );
  return FSA(
    id: _newAutomatonId('empty'),
    name: 'Empty language',
    states: {q0},
    transitions: const {},
    alphabet: const {},
    initialState: q0,
    acceptingStates: const {},
    created: now,
    modified: now,
    bounds: const math.Rectangle(0, 0, 800, 600),
  );
}

/// Builds NFA for a single symbol
FSA _buildSymbolNFA(String symbol) {
  final now = DateTime.now();
  final q0 = State(
    id: _newStateId('q'),
    label: 'q0',
    position: Vector2(100, 100),
    isInitial: true,
    isAccepting: false,
  );
  final q1 = State(
    id: _newStateId('q'),
    label: 'q1',
    position: Vector2(200, 100),
    isInitial: false,
    isAccepting: true,
  );

  final transition = FSATransition.deterministic(
    id: _newTransId('t'),
    fromState: q0,
    toState: q1,
    symbol: symbol,
  );

  return FSA(
    id: _newAutomatonId(
      'symbol_${symbol.runes.map((rune) => rune.toRadixString(16)).join('_')}',
    ),
    name: 'Symbol $symbol',
    states: {q0, q1},
    transitions: {transition},
    alphabet: {symbol},
    initialState: q0,
    acceptingStates: {q1},
    created: now,
    modified: now,
    bounds: const math.Rectangle(0, 0, 800, 600),
  );
}

/// Builds NFA for dot (any symbol)
FSA _buildDotNFA({Set<String>? contextAlphabet}) {
  if (contextAlphabet == null || contextAlphabet.isEmpty) {
    throw StateError('Dot requires a non-empty alphabet universe');
  }
  final now = DateTime.now();
  final q0 = State(
    id: _newStateId('q'),
    label: 'q0',
    position: Vector2(100, 100),
    isInitial: true,
    isAccepting: false,
  );
  final q1 = State(
    id: _newStateId('q'),
    label: 'q1',
    position: Vector2(200, 100),
    isInitial: false,
    isAccepting: true,
  );

  final transition = FSATransition(
    id: _newTransId('t'),
    fromState: q0,
    toState: q1,
    label: '.',
    inputSymbols: contextAlphabet,
  );

  return FSA(
    id: _newAutomatonId('dot'),
    name: 'Dot (Any Symbol)',
    states: {q0, q1},
    transitions: {transition},
    alphabet: contextAlphabet,
    initialState: q0,
    acceptingStates: {q1},
    created: now,
    modified: now,
    bounds: const math.Rectangle(0, 0, 800, 600),
  );
}

/// Builds NFA for union (|)
FSA _buildUnionNFA(
  RegexNode left,
  RegexNode right, {
  Set<String>? contextAlphabet,
}) {
  final leftNFA = _buildNFA(left, contextAlphabet: contextAlphabet);
  final rightNFA = _buildNFA(right, contextAlphabet: contextAlphabet);

  return _buildUnionFromFragments(leftNFA, rightNFA);
}

FSA _buildUnionFromFragments(FSA leftNFA, FSA rightNFA) {
  // Structural helpers such as concatenation intentionally use local clone
  // identifiers. Re-identify both operands before combining them so repeated
  // subexpressions cannot publish duplicate state or transition IDs.
  leftNFA = _reidentifyFragment(leftNFA, _newAutomatonId('union_left'));
  rightNFA = _reidentifyFragment(rightNFA, _newAutomatonId('union_right'));
  // Create new initial and final states
  final now = DateTime.now();
  final newInitial = State(
    id: _newStateId('q_init'),
    label: 'q_initial',
    position: Vector2(50, 100),
    isInitial: true,
    isAccepting: false,
  );
  final newFinal = State(
    id: _newStateId('q_final'),
    label: 'q_final',
    position: Vector2(350, 100),
    isInitial: false,
    isAccepting: true,
  );

  // Combine states and transitions
  final allStates = {newInitial, newFinal};
  allStates.addAll(leftNFA.states);
  allStates.addAll(rightNFA.states);

  final allTransitions = <FSATransition>{};
  allTransitions.addAll(leftNFA.fsaTransitions);
  allTransitions.addAll(rightNFA.fsaTransitions);

  // Add epsilon transitions
  allTransitions.add(
    FSATransition.epsilon(
      id: _newTransId('t_eps'),
      fromState: newInitial,
      toState: leftNFA.initialState!,
    ),
  );
  allTransitions.add(
    FSATransition.epsilon(
      id: _newTransId('t_eps'),
      fromState: newInitial,
      toState: rightNFA.initialState!,
    ),
  );

  for (final acceptingState in leftNFA.acceptingStates) {
    allTransitions.add(
      FSATransition.epsilon(
        id: _newTransId('t_eps'),
        fromState: acceptingState,
        toState: newFinal,
      ),
    );
  }

  for (final acceptingState in rightNFA.acceptingStates) {
    allTransitions.add(
      FSATransition.epsilon(
        id: _newTransId('t_eps'),
        fromState: acceptingState,
        toState: newFinal,
      ),
    );
  }

  return FSA(
    id: _newAutomatonId('union'),
    name: 'Union',
    states: allStates,
    transitions: allTransitions,
    alphabet: leftNFA.alphabet.union(rightNFA.alphabet),
    initialState: newInitial,
    acceptingStates: {newFinal},
    created: now,
    modified: now,
    bounds: const math.Rectangle(0, 0, 800, 600),
  );
}

FSA _reidentifyFragment(FSA source, String namespace) {
  final sortedStates = [...source.states]
    ..sort((left, right) => left.id.compareTo(right.id));
  final statesById = <String, State>{
    for (var index = 0; index < sortedStates.length; index++)
      sortedStates[index].id: sortedStates[index].copyWith(
        id: '${namespace}_s$index',
      ),
  };
  final sortedTransitions = [...source.fsaTransitions]
    ..sort((left, right) => left.id.compareTo(right.id));
  final transitions = <FSATransition>{
    for (var index = 0; index < sortedTransitions.length; index++)
      sortedTransitions[index].copyWith(
        id: '${namespace}_t$index',
        fromState: statesById[sortedTransitions[index].fromState.id],
        toState: statesById[sortedTransitions[index].toState.id],
      ),
  };
  return FSA(
    id: namespace,
    name: source.name,
    states: statesById.values.toSet(),
    transitions: transitions,
    alphabet: source.alphabet,
    initialState: statesById[source.initialState!.id],
    acceptingStates:
        source.acceptingStates.map((state) => statesById[state.id]!).toSet(),
    created: source.created,
    modified: source.modified,
    bounds: source.bounds,
  );
}

/// Builds NFA for concatenation
FSA _buildConcatenationNFA(
  RegexNode left,
  RegexNode right, {
  Set<String>? contextAlphabet,
}) {
  final leftNFA = _buildNFA(left, contextAlphabet: contextAlphabet);
  final rightNFA = _buildNFA(right, contextAlphabet: contextAlphabet);

  return _concatenateFragments(leftNFA, rightNFA).resultNFA;
}

/// Builds NFA for Kleene star (*)
FSA _buildKleeneStarNFA(RegexNode child, {Set<String>? contextAlphabet}) {
  final childNFA = _buildNFA(child, contextAlphabet: contextAlphabet);

  return _applyKleeneStarToFragment(childNFA).resultNFA;
}

FSAKleeneStarResult _applyKleeneStarToFragment(FSA childNFA) {
  final result = FSAKleeneStar.apply(childNFA);
  if (result.isFailure) {
    throw StateError(result.error ?? 'FSA Kleene-star construction failed.');
  }
  return result.data!;
}

/// Builds NFA for plus (+)
FSA _buildPlusNFA(RegexNode child, {Set<String>? contextAlphabet}) {
  final childNFA = _buildNFA(child, contextAlphabet: contextAlphabet);

  return _buildPlusFromFragment(childNFA);
}

FSA _buildPlusFromFragment(FSA childNFA) {
  final now = DateTime.now();
  final newInitial = State(
    id: _newStateId('q_init'),
    label: 'q_initial',
    position: Vector2(50, 100),
    isInitial: true,
    isAccepting: false,
  );
  final newFinal = State(
    id: _newStateId('q_final'),
    label: 'q_final',
    position: Vector2(350, 100),
    isInitial: false,
    isAccepting: true,
  );

  final allStates = {newInitial, newFinal, ...childNFA.states};
  final allTransitions = <FSATransition>{...childNFA.fsaTransitions};

  allTransitions.add(
    FSATransition.epsilon(
      id: _newTransId('t_eps'),
      fromState: newInitial,
      toState: childNFA.initialState!,
    ),
  );

  for (final acceptingState in childNFA.acceptingStates) {
    allTransitions.add(
      FSATransition.epsilon(
        id: _newTransId('t_eps'),
        fromState: acceptingState,
        toState: childNFA.initialState!,
      ),
    );
    allTransitions.add(
      FSATransition.epsilon(
        id: _newTransId('t_eps'),
        fromState: acceptingState,
        toState: newFinal,
      ),
    );
  }

  return FSA(
    id: _newAutomatonId('plus'),
    name: 'Plus',
    states: allStates,
    transitions: allTransitions,
    alphabet: childNFA.alphabet,
    initialState: newInitial,
    acceptingStates: {newFinal},
    created: now,
    modified: now,
    bounds: const math.Rectangle(0, 0, 800, 600),
  );
}

FSAConcatenationResult _concatenateFragments(FSA leftNFA, FSA rightNFA) {
  final result = FSAConcatenator.concatenate(leftNFA, rightNFA);
  if (result.isFailure) {
    throw StateError(result.error ?? 'FSA concatenation failed.');
  }
  return result.data!;
}

/// Builds NFA for question (?)
FSA _buildQuestionNFA(RegexNode child, {Set<String>? contextAlphabet}) {
  final childNFA = _buildNFA(child, contextAlphabet: contextAlphabet);

  return _buildQuestionFromFragment(childNFA);
}

FSA _buildQuestionFromFragment(FSA childNFA) {
  // Create new initial and final states
  final now = DateTime.now();
  final newInitial = State(
    id: _newStateId('q_init'),
    label: 'q_initial',
    position: Vector2(50, 100),
    isInitial: true,
    isAccepting: true, // Accept empty string
  );
  final newFinal = State(
    id: _newStateId('q_final'),
    label: 'q_final',
    position: Vector2(350, 100),
    isInitial: false,
    isAccepting: true,
  );

  // Combine states and transitions
  final allStates = {newInitial, newFinal};
  allStates.addAll(childNFA.states);

  final allTransitions = <FSATransition>{};
  allTransitions.addAll(childNFA.fsaTransitions);

  // Add epsilon transitions
  allTransitions.add(
    FSATransition.epsilon(
      id: _newTransId('t_eps'),
      fromState: newInitial,
      toState: childNFA.initialState!,
    ),
  );
  allTransitions.add(
    FSATransition.epsilon(
      id: _newTransId('t_eps'),
      fromState: newInitial,
      toState: newFinal,
    ),
  );

  for (final acceptingState in childNFA.acceptingStates) {
    allTransitions.add(
      FSATransition.epsilon(
        id: _newTransId('t_eps'),
        fromState: acceptingState,
        toState: newFinal,
      ),
    );
  }

  return FSA(
    id: _newAutomatonId('question'),
    name: 'Question',
    states: allStates,
    transitions: allTransitions,
    alphabet: childNFA.alphabet,
    initialState: newInitial,
    acceptingStates: {newFinal, newInitial},
    created: now,
    modified: now,
    bounds: const math.Rectangle(0, 0, 800, 600),
  );
}

/// Builds NFA for a set of symbols (character class)
FSA _buildSetNFA(Set<String> symbols) {
  final now = DateTime.now();
  final q0 = State(
    id: _newStateId('q'),
    label: 'q0',
    position: Vector2(100, 100),
    isInitial: true,
    isAccepting: false,
  );
  final q1 = State(
    id: _newStateId('q'),
    label: 'q1',
    position: Vector2(200, 100),
    isInitial: false,
    isAccepting: true,
  );

  final transitions = <FSATransition>{};
  for (final s in symbols) {
    transitions.add(
      FSATransition.deterministic(
        id: _newTransId('t'),
        fromState: q0,
        toState: q1,
        symbol: s,
      ),
    );
  }

  return FSA(
    id: _newAutomatonId('set'),
    name: 'Class',
    states: {q0, q1},
    transitions: transitions,
    alphabet: symbols,
    initialState: q0,
    acceptingStates: {q1},
    created: now,
    modified: now,
    bounds: const math.Rectangle(0, 0, 800, 600),
  );
}

Set<String> _parseCharClass(String content) {
  final symbols = <String>{};
  final scalars = _regexCharacterClassScalars(content);
  int i = 0;
  while (i < scalars.length) {
    if (i + 2 < scalars.length &&
        scalars[i + 1].value == 0x2d &&
        !scalars[i + 1].escaped) {
      final start = scalars[i].value;
      final end = scalars[i + 2].value;
      for (var scalar = start; scalar <= end; scalar++) {
        if (scalar < 0xd800 || scalar > 0xdfff) {
          symbols.add(String.fromCharCode(scalar));
        }
      }
      i += 3;
      continue;
    }
    symbols.add(String.fromCharCode(scalars[i].value));
    i++;
  }
  return symbols;
}

Set<String> _shortcutDigits() {
  return List.generate(
    10,
    (i) => String.fromCharCode('0'.codeUnitAt(0) + i),
  ).toSet();
}

Set<String> _shortcutWordChars() {
  return {
    '_',
    ...List.generate(26, (i) => String.fromCharCode('a'.codeUnitAt(0) + i)),
    ...List.generate(26, (i) => String.fromCharCode('A'.codeUnitAt(0) + i)),
    ..._shortcutDigits(),
  };
}

Set<String> _shortcutWhitespaceChars() => {' '};

Set<String> _expandShortcut(String code, Set<String>? contextAlphabet) {
  switch (code) {
    case 'd':
      return _shortcutDigits();
    case 'D':
      if (contextAlphabet == null || contextAlphabet.isEmpty) {
        throw StateError('\\D requires a non-empty alphabet universe');
      }
      return contextAlphabet.difference(_shortcutDigits());
    case 'w':
      return _shortcutWordChars();
    case 'W':
      if (contextAlphabet == null || contextAlphabet.isEmpty) {
        throw StateError('\\W requires a non-empty alphabet universe');
      }
      return contextAlphabet.difference(_shortcutWordChars());
    case 's':
      return _shortcutWhitespaceChars();
    case 'S':
      if (contextAlphabet == null || contextAlphabet.isEmpty) {
        throw StateError('\\S requires a non-empty alphabet universe');
      }
      return contextAlphabet.difference(_shortcutWhitespaceChars());
    default:
      throw ArgumentError.value(code, 'code', 'Unrecognized regex shortcut');
  }
}
