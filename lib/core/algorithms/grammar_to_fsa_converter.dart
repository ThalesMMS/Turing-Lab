//
//  grammar_to_fsa_converter.dart
//  Turing Lab
//
//  Converte gramáticas lineares à direita em autômatos finitos equivalentes,
//  validando restrições das produções e gerando estados com posicionamento
//  calculado. Cria transições consistentes, estados finais quando necessário e
//  retorna resultados padronizados com mensagens de erro amigáveis.
//
//  Thales Matheus Mendonça Santos - October 2025
//

import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart';

import '../models/fsa.dart';
import '../models/fsa_transition.dart';
import '../models/grammar.dart';
import '../models/state.dart';
import '../result.dart';
import '../utils/epsilon_utils.dart';

/// Converter that builds a finite automaton from a right-linear grammar.
class GrammarToFSAConverter {
  /// Converts a right-linear grammar into an equivalent FSA.
  ///
  /// The converter supports productions of the form A → aB, A → a and
  /// A → ε. It validates that the grammar respects these constraints and
  /// emits a descriptive error otherwise.
  static Result<FSA> convert(Grammar grammar) {
    final validationError = _validateGrammar(grammar);
    if (validationError != null) {
      return ResultFactory.failure(validationError);
    }

    final nonTerminalList = grammar.nonterminals.toList();
    final statePositions = _computeStatePositions(
      nonTerminalList.length + (_needsFinalState(grammar) ? 1 : 0),
    );

    final stateMap = <String, State>{};
    final states = <State>{};

    for (var i = 0; i < nonTerminalList.length; i++) {
      final symbol = nonTerminalList[i];
      final isStart = symbol == grammar.startSymbol;
      final state = State(
        id: symbol,
        label: symbol,
        position: statePositions[i],
        isInitial: isStart,
        isAccepting: false,
      );
      stateMap[symbol] = state;
      states.add(state);
    }

    final transitions = <FSATransition>{};
    final requiresFinalState = _needsFinalState(grammar);
    State? finalState;
    if (requiresFinalState) {
      final finalPosition =
          statePositions.isEmpty ? Vector2.zero() : statePositions.last;
      finalState = State(
        id: '${grammar.id}_ACCEPT',
        label: 'F',
        position: finalPosition,
        isAccepting: true,
      );
      states.add(finalState);
    }

    var transitionCounter = 0;

    for (final production in grammar.productions) {
      final fromSymbol = production.leftSide.first;
      final originalFromState = stateMap[fromSymbol];
      if (originalFromState == null) {
        continue;
      }

      // Handle lambda/epsilon productions by marking the source state as
      // accepting.
      if (production.isLambda || production.rightSide.isEmpty) {
        final acceptingState = originalFromState.copyWith(isAccepting: true);
        states
          ..remove(originalFromState)
          ..add(acceptingState);
        stateMap[fromSymbol] = acceptingState;
        continue;
      }

      final rightSide = production.rightSide;
      final inputSymbol = rightSide.first;
      if (isEpsilonSymbol(inputSymbol)) {
        final acceptingState = originalFromState.copyWith(isAccepting: true);
        states
          ..remove(originalFromState)
          ..add(acceptingState);
        stateMap[fromSymbol] = acceptingState;
        continue;
      }

      State targetState;
      if (rightSide.length == 1) {
        if (finalState != null) {
          targetState = finalState;
        } else {
          final acceptingState = originalFromState.copyWith(isAccepting: true);
          states
            ..remove(originalFromState)
            ..add(acceptingState);
          stateMap[fromSymbol] = acceptingState;
          targetState = acceptingState;
        }
      } else {
        final nextSymbol = rightSide.last;
        final mappedTarget = stateMap[nextSymbol];
        if (mappedTarget == null) {
          return ResultFactory.failure(
            'Production ${production.id} references undefined non-terminal $nextSymbol.',
          );
        }
        targetState = mappedTarget;
      }

      final updatedFromState = stateMap[fromSymbol]!;
      transitionCounter += 1;
      transitions.add(
        FSATransition(
          id: 't$transitionCounter',
          fromState: updatedFromState,
          toState: targetState,
          label: inputSymbol,
          inputSymbols: {inputSymbol},
        ),
      );
    }

    final acceptingStates = states.where((s) => s.isAccepting).toSet();
    final alphabet =
        grammar.terminals.where((symbol) => !isEpsilonSymbol(symbol)).toSet();
    final canonicalTransitions = transitions
        .map(
          (transition) => transition.copyWith(
            fromState:
                stateMap[transition.fromState.id] ?? transition.fromState,
            toState: stateMap[transition.toState.id] ?? transition.toState,
          ),
        )
        .toSet();

    final now = DateTime.now();
    final automaton = FSA(
      id: 'fsa_from_${grammar.id}',
      name: '${grammar.name} (Automaton)',
      states: states,
      transitions: canonicalTransitions,
      alphabet: alphabet,
      initialState: stateMap[grammar.startSymbol],
      acceptingStates: acceptingStates,
      created: now,
      modified: now,
      bounds: const math.Rectangle(0, 0, 800, 600),
    );

    return ResultFactory.success(automaton);
  }

  static String? _validateGrammar(Grammar grammar) {
    if (grammar.productions.isEmpty) {
      return 'Grammar must contain at least one production rule.';
    }

    for (final production in grammar.productions) {
      if (production.leftSide.length != 1) {
        return 'Production ${production.id} must have exactly one non-terminal on the left side.';
      }

      final leftSymbol = production.leftSide.first;
      if (!grammar.nonterminals.contains(leftSymbol)) {
        return 'Production ${production.id} uses unknown non-terminal $leftSymbol.';
      }

      if (production.isLambda || production.rightSide.isEmpty) {
        continue;
      }

      if (production.rightSide.length > 2) {
        return 'Production ${production.id} is not right-linear (too many symbols on the right side).';
      }

      final firstSymbol = production.rightSide.first;
      if (isEpsilonSymbol(firstSymbol)) {
        continue;
      }

      if (!_isTerminalSymbol(firstSymbol, grammar)) {
        return 'Production ${production.id} must start with a terminal symbol.';
      }

      if (production.rightSide.length == 2) {
        final secondSymbol = production.rightSide.last;
        if (!grammar.nonterminals.contains(secondSymbol)) {
          return 'Production ${production.id} must end with a non-terminal symbol.';
        }
      } else if (grammar.nonterminals.contains(firstSymbol)) {
        return 'Production ${production.id} cannot produce only a non-terminal in a right-linear grammar.';
      }
    }

    return null;
  }

  static bool _needsFinalState(Grammar grammar) {
    return grammar.productions.any((production) {
      if (production.isLambda || production.rightSide.isEmpty) {
        return false;
      }
      if (production.rightSide.length == 1) {
        final symbol = production.rightSide.first;
        return !isEpsilonSymbol(symbol) &&
            !grammar.nonterminals.contains(symbol);
      }
      return false;
    });
  }

  static bool _isTerminalSymbol(String symbol, Grammar grammar) {
    if (isEpsilonSymbol(symbol)) {
      return false;
    }
    if (grammar.terminals.contains(symbol)) {
      return true;
    }
    // Fallback heuristic: uppercase denotes non-terminals.
    final uppercaseRegex = RegExp(r'^[A-Z]$');
    return !uppercaseRegex.hasMatch(symbol);
  }

  static List<Vector2> _computeStatePositions(int count) {
    if (count <= 0) {
      return const [];
    }

    if (count == 1) {
      return [Vector2(400, 300)];
    }

    final positions = <Vector2>[];
    const radius = 180.0;
    const centerX = 400.0;
    const centerY = 300.0;

    for (var i = 0; i < count; i++) {
      final angle = (2 * math.pi * i) / count;
      positions.add(
        Vector2(
          centerX + radius * math.cos(angle),
          centerY + radius * math.sin(angle),
        ),
      );
    }

    return positions;
  }
}
