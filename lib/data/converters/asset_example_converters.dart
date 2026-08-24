import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart';

import '../../core/models/fsa.dart';
import '../../core/models/fsa_transition.dart';
import '../../core/models/grammar.dart';
import '../../core/models/pda.dart';
import '../../core/models/pda_transition.dart';
import '../../core/models/production.dart';
import '../../core/models/regex_preset.dart';
import '../../core/models/state.dart';
import '../../core/models/tm.dart';
import '../../core/models/tm_transition.dart';
import '../../core/models/transition.dart';
import '../../core/result.dart';

Result<RegexPreset> convertAssetJsonToRegexPreset(
  Map<String, dynamic> json,
  String exampleName,
) {
  final expression = json['expression'];
  if (expression is! String || expression.isEmpty) {
    return Failure('Example "$exampleName" must define expression.');
  }

  final alphabetResult = _parseStringList(
    json['alphabet'],
    'alphabet',
    exampleName,
    requiredField: true,
  );
  if (alphabetResult.isFailure) return Failure(alphabetResult.error!);
  if (alphabetResult.data!.any((symbol) => symbol.runes.length != 1)) {
    return Failure(
      'Example "$exampleName" alphabet must contain single-character symbols.',
    );
  }

  return Success(
    RegexPreset(
      id: _stringOr(json['id'], 'example_${_slug(exampleName)}'),
      name: _stringOr(json['name'], exampleName),
      expression: expression,
      alphabet: alphabetResult.data!.join(),
    ),
  );
}

Result<FSA> convertAssetJsonToFsa(
  Map<String, dynamic> json,
  String exampleName,
) {
  final statesResult = _parseStates(json, exampleName);
  if (statesResult.isFailure) return Failure(statesResult.error!);

  final alphabetResult = _parseStringSet(
    json['alphabet'],
    'alphabet',
    exampleName,
  );
  if (alphabetResult.isFailure) return Failure(alphabetResult.error!);

  final transitionsResult = _parseFsaTransitions(
    json['transitions'],
    statesResult.data!,
    exampleName,
  );
  if (transitionsResult.isFailure) return Failure(transitionsResult.error!);

  final states = statesResult.data!;
  final now = DateTime.now();

  return Success(
    FSA(
      id: _stringOr(json['id'], 'example_${_slug(exampleName)}'),
      name: _stringOr(json['name'], exampleName),
      states: states.values.toSet(),
      transitions: transitionsResult.data!,
      alphabet: alphabetResult.data!,
      initialState: states[_stringOr(json['initialId'], '')],
      acceptingStates:
          states.values.where((state) => state.isAccepting).toSet(),
      created: now,
      modified: now,
      bounds: _boundsFor(states.values),
      zoomLevel: 1.0,
      panOffset: Vector2.zero(),
    ),
  );
}

Result<PDA> convertAssetJsonToPda(
  Map<String, dynamic> json,
  String exampleName,
) {
  final finalStatesResult = _parseStringSet(
    json['finalStates'],
    'finalStates',
    exampleName,
  );
  if (finalStatesResult.isFailure) return Failure(finalStatesResult.error!);

  final statesResult = _parseStates(
    json,
    exampleName,
    acceptingStateIds: finalStatesResult.data!,
  );
  if (statesResult.isFailure) return Failure(statesResult.error!);

  final alphabetResult = _parseStringSet(
    json['alphabet'],
    'alphabet',
    exampleName,
  );
  if (alphabetResult.isFailure) return Failure(alphabetResult.error!);

  final stackAlphabetResult = _parseStringSet(
    json['stackAlphabet'],
    'stackAlphabet',
    exampleName,
    requiredField: true,
  );
  if (stackAlphabetResult.isFailure) {
    return Failure(stackAlphabetResult.error!);
  }

  final transitionsResult = _parsePdaTransitions(
    json['transitions'],
    statesResult.data!,
    exampleName,
  );
  if (transitionsResult.isFailure) return Failure(transitionsResult.error!);

  final initialStackResult = _parseStringList(
    json['initialStack'],
    'initialStack',
    exampleName,
    requiredField: true,
  );
  if (initialStackResult.isFailure) return Failure(initialStackResult.error!);
  final initialStack = initialStackResult.data!;
  if (initialStack.length != 1) {
    return Failure(
      'Example "$exampleName" must define initialStack with exactly one symbol.',
    );
  }
  final initialStackSymbol = initialStack.single;
  if (!stackAlphabetResult.data!.contains(initialStackSymbol)) {
    return Failure(
      'Example "$exampleName" initial stack symbol "$initialStackSymbol" must be in stackAlphabet.',
    );
  }

  final states = statesResult.data!;
  final now = DateTime.now();

  return Success(
    PDA(
      id: _stringOr(json['id'], 'example_${_slug(exampleName)}'),
      name: _stringOr(json['name'], exampleName),
      states: states.values.toSet(),
      transitions: transitionsResult.data!,
      alphabet: alphabetResult.data!,
      initialState: states[_stringOr(json['initialId'], '')],
      acceptingStates: finalStatesResult.data!
          .map((id) => states[id])
          .whereType<State>()
          .toSet(),
      created: now,
      modified: now,
      bounds: _boundsFor(states.values),
      zoomLevel: 1.0,
      panOffset: Vector2.zero(),
      stackAlphabet: stackAlphabetResult.data!,
      initialStackSymbol: initialStackSymbol,
    ),
  );
}

Result<TM> convertAssetJsonToTm(
  Map<String, dynamic> json,
  String exampleName,
) {
  final finalStatesResult = _parseStringSet(
    json['finalStates'],
    'finalStates',
    exampleName,
  );
  if (finalStatesResult.isFailure) return Failure(finalStatesResult.error!);

  final statesResult = _parseStates(
    json,
    exampleName,
    acceptingStateIds: finalStatesResult.data!,
  );
  if (statesResult.isFailure) return Failure(statesResult.error!);

  final alphabetResult = _parseStringSet(
    json['alphabet'],
    'alphabet',
    exampleName,
  );
  if (alphabetResult.isFailure) return Failure(alphabetResult.error!);

  final tapeAlphabetResult = _parseStringSet(
    json['tapeAlphabet'],
    'tapeAlphabet',
    exampleName,
    requiredField: true,
  );
  if (tapeAlphabetResult.isFailure) return Failure(tapeAlphabetResult.error!);

  final transitionsResult = _parseTmTransitions(
    json['transitions'],
    statesResult.data!,
    exampleName,
  );
  if (transitionsResult.isFailure) return Failure(transitionsResult.error!);

  final states = statesResult.data!;
  final tapeAlphabet = tapeAlphabetResult.data!;
  final now = DateTime.now();

  return Success(
    TM(
      id: _stringOr(json['id'], 'example_${_slug(exampleName)}'),
      name: _stringOr(json['name'], exampleName),
      states: states.values.toSet(),
      transitions: transitionsResult.data!,
      alphabet: alphabetResult.data!,
      initialState: states[_stringOr(json['initialId'], '')],
      acceptingStates: finalStatesResult.data!
          .map((id) => states[id])
          .whereType<State>()
          .toSet(),
      created: now,
      modified: now,
      bounds: _boundsFor(states.values),
      zoomLevel: 1.0,
      panOffset: Vector2.zero(),
      tapeAlphabet: tapeAlphabet,
      blankSymbol: _blankSymbolFor(tapeAlphabet),
    ),
  );
}

Result<Grammar> convertAssetJsonToGrammar(
  Map<String, dynamic> json,
  String exampleName,
) {
  final terminalsResult = _parseStringSet(
    json['alphabet'],
    'alphabet',
    exampleName,
  );
  if (terminalsResult.isFailure) return Failure(terminalsResult.error!);

  final nonterminalsResult = _parseStringSet(
    json['variables'],
    'variables',
    exampleName,
    requiredField: true,
  );
  if (nonterminalsResult.isFailure) return Failure(nonterminalsResult.error!);

  final startSymbol = json['initialSymbol'];
  if (startSymbol is! String || startSymbol.isEmpty) {
    return Failure('Example "$exampleName" must define initialSymbol.');
  }

  final productionsResult = _parseProductions(
    json['productions'],
    terminalsResult.data!,
    nonterminalsResult.data!,
    exampleName,
  );
  if (productionsResult.isFailure) return Failure(productionsResult.error!);

  final now = DateTime.now();

  return Success(
    Grammar(
      id: _stringOr(json['id'], 'example_${_slug(exampleName)}'),
      name: _stringOr(json['name'], exampleName),
      terminals: terminalsResult.data!,
      nonterminals: nonterminalsResult.data!,
      startSymbol: startSymbol,
      productions: productionsResult.data!,
      type: GrammarType.contextFree,
      created: now,
      modified: now,
    ),
  );
}

Result<Map<String, State>> _parseStates(
  Map<String, dynamic> json,
  String exampleName, {
  Set<String> acceptingStateIds = const {},
}) {
  final statesRaw = json['states'];
  if (statesRaw is! List) {
    return Failure('Example "$exampleName" must define states as a list.');
  }

  final initialId = _stringOr(json['initialId'], '');
  final states = <String, State>{};
  for (final rawState in statesRaw) {
    if (rawState is! Map) {
      return Failure('Example "$exampleName" contains an invalid state.');
    }

    final stateJson = Map<String, dynamic>.from(rawState);
    final id = _stringOr(stateJson['id'], '');
    if (id.isEmpty) {
      return Failure('Example "$exampleName" contains a state without id.');
    }

    final isAccepting = stateJson['isFinal'] == true ||
        stateJson['isAccepting'] == true ||
        acceptingStateIds.contains(id);
    final isInitial = stateJson['isInitial'] == true || id == initialId;

    states[id] = State(
      id: id,
      label: _stringOr(stateJson['name'], id),
      position: Vector2(
        _numberOr(stateJson['x'], 0),
        _numberOr(stateJson['y'], 0),
      ),
      isInitial: isInitial,
      isAccepting: isAccepting,
      type: isAccepting
          ? StateType.accepting
          : isInitial
              ? StateType.initial
              : StateType.normal,
    );
  }

  return Success(states);
}

Result<Set<FSATransition>> _parseFsaTransitions(
  dynamic transitionsRaw,
  Map<String, State> states,
  String exampleName,
) {
  final mapResult = _parseTransitionMap(transitionsRaw, exampleName);
  if (mapResult.isFailure) return Failure(mapResult.error!);

  final transitions = <FSATransition>{};
  var index = 0;
  for (final entry in mapResult.data!.entries) {
    final parts = entry.key.split('|');
    if (parts.length != 2) {
      return Failure('Invalid FSA transition key "${entry.key}".');
    }

    final fromState = states[parts[0]];
    if (fromState == null) {
      return Failure('Transition "${entry.key}" references an unknown state.');
    }

    for (final targetId in entry.value) {
      final toState = states[targetId];
      if (toState == null) {
        return Failure('Transition "${entry.key}" targets unknown $targetId.');
      }

      final symbol = parts[1];
      final isLambda = _isLambda(symbol);
      final label = isLambda ? _lambdaLabel(symbol) : symbol;
      transitions.add(
        FSATransition(
          id: 't${index++}',
          fromState: fromState,
          toState: toState,
          label: label,
          controlPoint: _controlPointFor(fromState, toState),
          type:
              isLambda ? TransitionType.epsilon : TransitionType.deterministic,
          inputSymbols: isLambda ? const {} : {symbol},
          lambdaSymbol: isLambda ? label : null,
        ),
      );
    }
  }

  return Success(transitions);
}

Result<Set<PDATransition>> _parsePdaTransitions(
  dynamic transitionsRaw,
  Map<String, State> states,
  String exampleName,
) {
  final mapResult = _parseTransitionMap(transitionsRaw, exampleName);
  if (mapResult.isFailure) return Failure(mapResult.error!);

  final transitions = <PDATransition>{};
  var index = 0;
  for (final entry in mapResult.data!.entries) {
    final parts = entry.key.split('|');
    if (parts.length != 3) {
      return Failure('Invalid PDA transition key "${entry.key}".');
    }

    final fromState = states[parts[0]];
    if (fromState == null) {
      return Failure('Transition "${entry.key}" references an unknown state.');
    }

    for (final rawTarget in entry.value) {
      final targetParts = rawTarget.split('|');
      if (targetParts.length != 2) {
        return Failure('Invalid PDA transition target "$rawTarget".');
      }

      final toState = states[targetParts[0]];
      if (toState == null) {
        return Failure('Transition "$rawTarget" targets an unknown state.');
      }

      final input = parts[1];
      final pop = parts[2];
      final push = targetParts[1];
      final lambdaInput = _isLambda(input);
      final lambdaPop = _isLambda(pop);
      final lambdaPush = _isLambda(push);

      transitions.add(
        PDATransition(
          id: 't${index++}',
          fromState: fromState,
          toState: toState,
          label:
              '${_lambdaLabel(input)},${_lambdaLabel(pop)}→${_lambdaLabel(push)}',
          controlPoint: _controlPointFor(fromState, toState),
          type: lambdaInput
              ? TransitionType.epsilon
              : TransitionType.deterministic,
          inputSymbol: lambdaInput ? '' : input,
          popSymbol: lambdaPop ? '' : pop,
          pushSymbol: lambdaPush ? '' : push,
          isLambdaInput: lambdaInput,
          isLambdaPop: lambdaPop,
          isLambdaPush: lambdaPush,
        ),
      );
    }
  }

  return Success(transitions);
}

Result<Set<TMTransition>> _parseTmTransitions(
  dynamic transitionsRaw,
  Map<String, State> states,
  String exampleName,
) {
  final mapResult = _parseTransitionMap(transitionsRaw, exampleName);
  if (mapResult.isFailure) return Failure(mapResult.error!);

  final transitions = <TMTransition>{};
  var index = 0;
  for (final entry in mapResult.data!.entries) {
    final parts = entry.key.split('|');
    if (parts.length != 3) {
      return Failure('Invalid TM transition key "${entry.key}".');
    }

    final fromState = states[parts[0]];
    if (fromState == null) {
      return Failure('Transition "${entry.key}" references an unknown state.');
    }

    for (final rawTarget in entry.value) {
      final targetParts = rawTarget.split('|');
      if (targetParts.length != 3) {
        return Failure('Invalid TM transition target "$rawTarget".');
      }

      final toState = states[targetParts[0]];
      if (toState == null) {
        return Failure('Transition "$rawTarget" targets an unknown state.');
      }

      final directionResult = _parseDirection(targetParts[2]);
      if (directionResult.isFailure) return Failure(directionResult.error!);

      transitions.add(
        TMTransition(
          id: 't${index++}',
          fromState: fromState,
          toState: toState,
          label: '${parts[1]}→${targetParts[1]},${targetParts[2]}',
          controlPoint: _controlPointFor(fromState, toState),
          type: TransitionType.deterministic,
          readSymbol: parts[1],
          writeSymbol: targetParts[1],
          direction: directionResult.data!,
        ),
      );
    }
  }

  return Success(transitions);
}

Result<Set<Production>> _parseProductions(
  dynamic productionsRaw,
  Set<String> terminals,
  Set<String> nonterminals,
  String exampleName,
) {
  if (productionsRaw is! Map) {
    return Failure('Example "$exampleName" must define productions as a map.');
  }

  final productions = <Production>{};
  final symbols = {...terminals, ...nonterminals};
  var index = 0;

  for (final entry in Map<dynamic, dynamic>.from(productionsRaw).entries) {
    final left = entry.key.toString();
    final alternatives = entry.value;
    if (alternatives is! List) {
      return Failure('Production "$left" must be a list.');
    }

    for (final alternative in alternatives) {
      final right = alternative.toString();
      final isLambda = _isLambda(right);
      final rightSideResult = isLambda
          ? const Success(<String>[])
          : _splitSymbols(right, symbols, exampleName);
      if (rightSideResult.isFailure) return Failure(rightSideResult.error!);

      productions.add(
        Production(
          id: 'p${index + 1}',
          leftSide: [left],
          rightSide: rightSideResult.data!,
          isLambda: isLambda,
          order: index,
        ),
      );
      index++;
    }
  }

  return Success(productions);
}

Result<Map<String, List<String>>> _parseTransitionMap(
  dynamic transitionsRaw,
  String exampleName,
) {
  if (transitionsRaw is! Map) {
    return Failure('Example "$exampleName" must define transitions as a map.');
  }

  final transitions = <String, List<String>>{};
  for (final entry in Map<dynamic, dynamic>.from(transitionsRaw).entries) {
    final key = entry.key;
    if (key is! String) {
      return Failure('Example "$exampleName" has a non-string transition key.');
    }

    final value = entry.value;
    if (value is List) {
      transitions[key] = value.map((item) => item.toString()).toList();
    } else if (value == null) {
      transitions[key] = const <String>[];
    } else {
      transitions[key] = [value.toString()];
    }
  }

  return Success(transitions);
}

Result<Set<String>> _parseStringSet(
  dynamic raw,
  String field,
  String exampleName, {
  bool requiredField = false,
}) {
  final listResult = _parseStringList(
    raw,
    field,
    exampleName,
    requiredField: requiredField,
  );
  if (listResult.isFailure) return Failure(listResult.error!);
  return Success(listResult.data!.toSet());
}

Result<List<String>> _parseStringList(
  dynamic raw,
  String field,
  String exampleName, {
  bool requiredField = false,
}) {
  if (raw == null) {
    return requiredField
        ? Failure('Example "$exampleName" must define $field.')
        : const Success(<String>[]);
  }

  if (raw is! List) {
    return Failure('Example "$exampleName" must define $field as a list.');
  }

  if (requiredField && raw.isEmpty) {
    return Failure('Example "$exampleName" must define a non-empty $field.');
  }

  return Success(raw.map((item) => item.toString()).toList());
}

Result<List<String>> _splitSymbols(
  String value,
  Set<String> symbols,
  String exampleName,
) {
  final orderedSymbols = symbols.toList()
    ..sort((a, b) => b.length.compareTo(a.length));
  final result = <String>[];
  var index = 0;

  while (index < value.length) {
    String? match;
    for (final symbol in orderedSymbols) {
      if (symbol.isNotEmpty && value.startsWith(symbol, index)) {
        match = symbol;
        break;
      }
    }

    if (match == null) {
      return Failure(
        'Example "$exampleName" contains unknown grammar symbol in "$value".',
      );
    }

    result.add(match);
    index += match.length;
  }

  return Success(result);
}

Result<TapeDirection> _parseDirection(String value) {
  switch (value) {
    case 'L':
      return const Success(TapeDirection.left);
    case 'R':
      return const Success(TapeDirection.right);
    case 'S':
      return const Success(TapeDirection.stay);
    default:
      return Failure('Invalid TM direction "$value".');
  }
}

math.Rectangle<double> _boundsFor(Iterable<State> states) {
  var maxX = 600.0;
  var maxY = 400.0;
  for (final state in states) {
    maxX = math.max(maxX, state.position.x + 150);
    maxY = math.max(maxY, state.position.y + 150);
  }
  return math.Rectangle<double>(0, 0, maxX, maxY);
}

Vector2? _controlPointFor(State from, State to) {
  return from.id == to.id
      ? Vector2(from.position.x, from.position.y - 60)
      : null;
}

String _blankSymbolFor(Set<String> tapeAlphabet) {
  if (tapeAlphabet.contains('B')) return 'B';
  if (tapeAlphabet.contains('_')) return '_';
  return tapeAlphabet.isEmpty ? 'B' : tapeAlphabet.last;
}

bool _isLambda(String value) {
  return value.isEmpty || value == 'ε' || value == 'λ';
}

String _lambdaLabel(String value) {
  return _isLambda(value) ? 'ε' : value;
}

String _stringOr(dynamic value, String fallback) {
  return value is String && value.isNotEmpty ? value : fallback;
}

double _numberOr(dynamic value, double fallback) {
  return value is num ? value.toDouble() : fallback;
}

String _slug(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
}
