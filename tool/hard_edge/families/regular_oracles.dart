import 'dart:convert';

import 'package:turing_lab/core/algorithms/regex_to_nfa_converter.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/core/utils/epsilon_utils.dart';

import '../oracles.dart';
import '../resources.dart';

final class RegularOracleBudget {
  const RegularOracleBudget({
    this.maximumWordLength = 4,
    this.maximumWords = 512,
    this.maximumConfigurations = 4096,
  });

  final int maximumWordLength;
  final int maximumWords;
  final int maximumConfigurations;

  void validate() {
    if (maximumWordLength < 0) {
      throw ArgumentError.value(
        maximumWordLength,
        'maximumWordLength',
        'must not be negative',
      );
    }
    if (maximumWords <= 0) {
      throw ArgumentError.value(
        maximumWords,
        'maximumWords',
        'must be positive',
      );
    }
    if (maximumConfigurations <= 0) {
      throw ArgumentError.value(
        maximumConfigurations,
        'maximumConfigurations',
        'must be positive',
      );
    }
  }
}

final class RegularOracleEvidence {
  const RegularOracleEvidence({
    required this.visitedConfigurations,
    required this.evaluatedWords,
    this.message,
  });

  final int visitedConfigurations;
  final int evaluatedWords;
  final String? message;
}

OracleResult<bool, RegularOracleEvidence> regularOracleAccepts(
  FSA automaton,
  List<String> word, {
  int maximumConfigurations = 4096,
}) {
  if (maximumConfigurations <= 0) {
    throw ArgumentError.value(
      maximumConfigurations,
      'maximumConfigurations',
      'must be positive',
    );
  }
  final initial = automaton.initialState;
  if (initial == null ||
      !automaton.states.contains(initial) ||
      word.any((symbol) => symbol.isEmpty)) {
    return const OracleNotApplicable(
      reason: OracleInapplicability.preconditionFailed,
      evidence: RegularOracleEvidence(
        visitedConfigurations: 0,
        evaluatedWords: 0,
        message: 'The automaton or token word is malformed.',
      ),
    );
  }
  if (automaton.fsaTransitions.any(
    (transition) =>
        !automaton.states.contains(transition.fromState) ||
        !automaton.states.contains(transition.toState),
  )) {
    return const OracleNotApplicable(
      reason: OracleInapplicability.preconditionFailed,
      evidence: RegularOracleEvidence(
        visitedConfigurations: 0,
        evaluatedWords: 0,
        message: 'A transition endpoint is not declared.',
      ),
    );
  }

  var visitedConfigurations = 0;
  Set<State>? closure(Set<State> seeds) {
    final reached = <State>{...seeds};
    final pending = <State>[...seeds];
    while (pending.isNotEmpty) {
      final state = pending.removeLast();
      visitedConfigurations++;
      if (visitedConfigurations > maximumConfigurations) return null;
      for (final transition in automaton.fsaTransitions) {
        if (transition.fromState == state &&
            transition.isEpsilonTransition &&
            reached.add(transition.toState)) {
          pending.add(transition.toState);
        }
      }
    }
    return reached;
  }

  var current = closure({initial});
  if (current == null) {
    return _regularBounded(
      visitedConfigurations,
      maximumConfigurations,
    );
  }
  for (final symbol in word) {
    final moved = <State>{};
    for (final state in current!) {
      visitedConfigurations++;
      if (visitedConfigurations > maximumConfigurations) {
        return _regularBounded(
          visitedConfigurations,
          maximumConfigurations,
        );
      }
      for (final transition in automaton.fsaTransitions) {
        if (transition.fromState == state &&
            !isEpsilonSymbol(symbol) &&
            transition.inputSymbols.contains(symbol)) {
          moved.add(transition.toState);
        }
      }
    }
    current = closure(moved);
    if (current == null) {
      return _regularBounded(
        visitedConfigurations,
        maximumConfigurations,
      );
    }
  }

  return OracleDefinitive(
    value: current!.any(automaton.acceptingStates.contains),
    evidence: RegularOracleEvidence(
      visitedConfigurations: visitedConfigurations,
      evaluatedWords: 1,
    ),
  );
}

OracleResult<bool, RegularOracleEvidence> _regularBounded(
  int observed,
  int maximum,
) =>
    OracleBoundedUnknown(
      limit: ResourceLimitEvidence(
        kind: ResourceLimitKind.configurations,
        observed: observed,
        maximum: maximum,
        unit: 'configurations',
      ),
      evidence: RegularOracleEvidence(
        visitedConfigurations: observed,
        evaluatedWords: 0,
      ),
    );

OracleResult<Map<String, bool>, RegularOracleEvidence> regularLanguageSignature(
  FSA automaton,
  Iterable<String> alphabet,
  RegularOracleBudget budget,
) {
  budget.validate();
  final symbols = alphabet.toList(growable: false);
  if (symbols.any((symbol) => symbol.isEmpty) ||
      symbols.toSet().length != symbols.length) {
    return const OracleNotApplicable(
      reason: OracleInapplicability.preconditionFailed,
      evidence: RegularOracleEvidence(
        visitedConfigurations: 0,
        evaluatedWords: 0,
        message: 'Alphabet tokens must be unique and non-empty.',
      ),
    );
  }

  final signature = <String, bool>{};
  var visitedConfigurations = 0;
  for (final word in regularTokenWords(symbols, budget.maximumWordLength)) {
    if (signature.length >= budget.maximumWords) {
      return OracleBoundedUnknown(
        limit: ResourceLimitEvidence(
          kind: ResourceLimitKind.frontier,
          observed: signature.length + 1,
          maximum: budget.maximumWords,
          unit: 'words',
          partialEvidence: Map<String, bool>.unmodifiable(signature),
        ),
        evidence: RegularOracleEvidence(
          visitedConfigurations: visitedConfigurations,
          evaluatedWords: signature.length,
        ),
      );
    }
    final result = regularOracleAccepts(
      automaton,
      word,
      maximumConfigurations: budget.maximumConfigurations,
    );
    switch (result) {
      case OracleDefinitive<bool, RegularOracleEvidence>(
          :final value,
          :final evidence,
        ):
        visitedConfigurations += evidence.visitedConfigurations;
        signature[jsonEncode(word)] = value;
      case OracleNotApplicable<bool, RegularOracleEvidence>():
        return OracleNotApplicable(
          reason: OracleInapplicability.preconditionFailed,
          evidence: RegularOracleEvidence(
            visitedConfigurations: visitedConfigurations,
            evaluatedWords: signature.length,
            message: 'A generated word was not applicable.',
          ),
        );
      case OracleBoundedUnknown<bool, RegularOracleEvidence>(
          :final limit,
        ):
        return OracleBoundedUnknown(
          limit: limit,
          evidence: RegularOracleEvidence(
            visitedConfigurations: visitedConfigurations + limit.observed,
            evaluatedWords: signature.length,
          ),
        );
    }
  }
  return OracleDefinitive(
    value: Map<String, bool>.unmodifiable(signature),
    evidence: RegularOracleEvidence(
      visitedConfigurations: visitedConfigurations,
      evaluatedWords: signature.length,
    ),
  );
}

Iterable<List<String>> regularTokenWords(
  List<String> alphabet,
  int maximumLength,
) sync* {
  var frontier = <List<String>>[const []];
  for (var length = 0; length <= maximumLength; length++) {
    yield* frontier;
    if (length == maximumLength || alphabet.isEmpty) return;
    frontier = [
      for (final prefix in frontier)
        for (final symbol in alphabet)
          List<String>.unmodifiable([...prefix, symbol]),
    ];
  }
}

/// Clarity-first subset construction used only as a differential reference.
final class RegularReferenceDfa {
  RegularReferenceDfa({
    required this.initialState,
    required Iterable<String> acceptingStates,
    required Map<String, Map<String, String>> transitions,
  })  : acceptingStates = Set<String>.unmodifiable(acceptingStates),
        transitions = Map<String, Map<String, String>>.unmodifiable({
          for (final entry in transitions.entries)
            entry.key: Map<String, String>.unmodifiable(entry.value),
        });

  final String initialState;
  final Set<String> acceptingStates;
  final Map<String, Map<String, String>> transitions;

  bool accepts(List<String> word) {
    var current = initialState;
    for (final symbol in word) {
      final next = transitions[current]?[symbol];
      if (next == null) return false;
      current = next;
    }
    return acceptingStates.contains(current);
  }
}

RegularReferenceDfa regularReferenceSubsetConstruction(FSA automaton) {
  final initial = automaton.initialState;
  if (initial == null) {
    throw ArgumentError(
        'Reference subset construction needs an initial state.');
  }
  final alphabet = automaton.alphabet
      .where((symbol) => !isEpsilonSymbol(symbol))
      .toList()
    ..sort();

  Set<State> closure(Set<State> seeds) {
    final result = <State>{...seeds};
    final pending = <State>[...seeds];
    while (pending.isNotEmpty) {
      final state = pending.removeLast();
      for (final transition in automaton.fsaTransitions) {
        if (transition.fromState == state &&
            transition.isEpsilonTransition &&
            result.add(transition.toState)) {
          pending.add(transition.toState);
        }
      }
    }
    return result;
  }

  String key(Set<State> states) {
    final ids = states.map((state) => state.id).toList()..sort();
    return jsonEncode(ids);
  }

  final initialSubset = closure({initial});
  final subsets = <String, Set<State>>{key(initialSubset): initialSubset};
  final pending = <String>[key(initialSubset)];
  final transitions = <String, Map<String, String>>{};
  final accepting = <String>{};
  while (pending.isNotEmpty) {
    final currentKey = pending.removeAt(0);
    final current = subsets[currentKey]!;
    if (current.any(automaton.acceptingStates.contains)) {
      accepting.add(currentKey);
    }
    final outgoing = transitions[currentKey] = <String, String>{};
    for (final symbol in alphabet) {
      final moved = <State>{};
      for (final state in current) {
        for (final transition in automaton.fsaTransitions) {
          if (transition.fromState == state &&
              !isEpsilonSymbol(symbol) &&
              transition.inputSymbols.contains(symbol)) {
            moved.add(transition.toState);
          }
        }
      }
      final destination = closure(moved);
      final destinationKey = key(destination);
      outgoing[symbol] = destinationKey;
      if (!subsets.containsKey(destinationKey)) {
        subsets[destinationKey] = destination;
        pending.add(destinationKey);
      }
    }
  }
  return RegularReferenceDfa(
    initialState: key(initialSubset),
    acceptingStates: accepting,
    transitions: transitions,
  );
}

/// Independent Moore-style partition refinement for a complete DFA.
int regularReferenceMinimumStateCount(FSA automaton) {
  final initial = automaton.initialState;
  if (initial == null || !automaton.isDeterministic) {
    throw ArgumentError('Reference minimization needs a deterministic DFA.');
  }
  final alphabet = automaton.alphabet.toList()..sort();
  final reachable = <State>{initial};
  final pending = <State>[initial];
  while (pending.isNotEmpty) {
    final state = pending.removeLast();
    for (final symbol in alphabet) {
      final targets = automaton
          .getTransitionsFromStateOnSymbol(state, symbol)
          .map((transition) => transition.toState)
          .toSet();
      if (targets.length != 1) {
        throw ArgumentError('Reference minimization needs a complete DFA.');
      }
      if (reachable.add(targets.single)) pending.add(targets.single);
    }
  }
  var partitions = <Set<State>>[
    reachable.intersection(automaton.acceptingStates),
    reachable.difference(automaton.acceptingStates),
  ].where((partition) => partition.isNotEmpty).toList();
  while (true) {
    final groupByState = <State, int>{
      for (var group = 0; group < partitions.length; group++)
        for (final state in partitions[group]) state: group,
    };
    final refined = <Set<State>>[];
    for (final partition in partitions) {
      final buckets = <String, Set<State>>{};
      for (final state in partition) {
        final signature = <int>[];
        for (final symbol in alphabet) {
          final target = automaton
              .getTransitionsFromStateOnSymbol(state, symbol)
              .single
              .toState;
          signature.add(groupByState[target]!);
        }
        buckets.putIfAbsent(jsonEncode(signature), () => <State>{}).add(state);
      }
      refined.addAll(buckets.values);
    }
    if (refined.length == partitions.length) return refined.length;
    partitions = refined;
  }
}

bool regularRegexOracleAccepts(
  RegexNode node,
  List<String> word, {
  required Set<String> contextAlphabet,
}) {
  Set<int> match(RegexNode current, int offset) {
    if (offset > word.length) return const {};
    return switch (current) {
      EpsilonNode() => {offset},
      EmptyLanguageNode() => const {},
      SymbolNode(:final symbol) =>
        offset < word.length && word[offset] == symbol
            ? {offset + 1}
            : const {},
      DotNode() =>
        offset < word.length && contextAlphabet.contains(word[offset])
            ? {offset + 1}
            : const {},
      SetNode(:final symbols) =>
        offset < word.length && symbols.contains(word[offset])
            ? {offset + 1}
            : const {},
      ShortcutNode(:final code) => offset < word.length &&
              _shortcutMatches(code, word[offset], contextAlphabet)
          ? {offset + 1}
          : const {},
      UnionNode(:final left, :final right) => {
          ...match(left, offset),
          ...match(right, offset),
        },
      ConcatenationNode(:final left, :final right) => {
          for (final middle in match(left, offset)) ...match(right, middle),
        },
      KleeneStarNode(:final child) => _starEnds(child, offset, match),
      PlusNode(:final child) => {
          for (final middle in match(child, offset))
            ..._starEnds(child, middle, match),
        },
      QuestionNode(:final child) => {offset, ...match(child, offset)},
      _ => const {},
    };
  }

  return match(node, 0).contains(word.length);
}

Set<int> _starEnds(
  RegexNode child,
  int offset,
  Set<int> Function(RegexNode node, int offset) match,
) {
  final reached = <int>{offset};
  final pending = <int>[offset];
  while (pending.isNotEmpty) {
    final current = pending.removeLast();
    for (final next in match(child, current)) {
      if (reached.add(next)) pending.add(next);
    }
  }
  return reached;
}

bool _shortcutMatches(
  String code,
  String symbol,
  Set<String> contextAlphabet,
) {
  final digits = RegExp(r'^[0-9]$').hasMatch(symbol);
  final word = RegExp(r'^[A-Za-z0-9_]$').hasMatch(symbol);
  final whitespace = symbol == ' ';
  return switch (code) {
    'd' => digits,
    'D' => contextAlphabet.contains(symbol) && !digits,
    'w' => word,
    'W' => contextAlphabet.contains(symbol) && !word,
    's' => whitespace,
    'S' => contextAlphabet.contains(symbol) && !whitespace,
    _ => false,
  };
}
