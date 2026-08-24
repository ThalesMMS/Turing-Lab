//
//  dfa_completer.dart
//  Turing Lab
//
//  Completes deterministic finite automata so that every state has a
//  defined transition for every alphabet symbol. Creates a trap state when
//  needed and copies relevant metadata, preserving visual and temporal
//  coherence when producing a fully defined DFA.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart';

import '../models/fsa.dart';
import '../models/fsa_transition.dart';
import '../models/state.dart';

class DFACompleter {
  static const double _stateSpacing = 120;
  static const double _stateExtent = 60;

  static FSA complete(FSA dfa) {
    final alphabet = dfa.alphabet.toList()..sort();
    final originalStates = dfa.states.toList()
      ..sort((first, second) => first.id.compareTo(second.id));
    final originalTransitions = dfa.fsaTransitions;
    final missingTransitions = _missingTransitions(
      originalStates,
      originalTransitions,
      alphabet,
    );

    if (missingTransitions.isEmpty) {
      return dfa;
    }

    final states = Set<State>.from(dfa.states);
    final transitions = Set<FSATransition>.from(originalTransitions);
    final usedStateIds = states.map((state) => state.id).toSet();
    final usedTransitionIds =
        transitions.map((transition) => transition.id).toSet();
    var trapState = _findCompatibleSink(
      originalStates,
      originalTransitions,
      alphabet,
      dfa.acceptingStates,
    );
    var bounds = dfa.bounds;

    if (trapState == null) {
      final position = _trapPosition(originalStates, dfa.bounds);
      trapState = State(
        id: _nextAvailableId('q_trap', usedStateIds),
        label: 'Trap',
        position: position,
        type: StateType.trap,
      );
      states.add(trapState);
      bounds = _boundsIncluding(dfa.bounds, position);
    }

    for (final missing in missingTransitions) {
      transitions.add(
        FSATransition.deterministic(
          id: _nextAvailableId('t_complete', usedTransitionIds),
          fromState: missing.state,
          toState: trapState,
          symbol: missing.symbol,
        ),
      );
    }

    final trapSymbols = _outgoingSymbols(trapState, transitions);
    for (final symbol in alphabet) {
      if (trapSymbols.contains(symbol)) {
        continue;
      }
      transitions.add(
        FSATransition.deterministic(
          id: _nextAvailableId('t_complete', usedTransitionIds),
          fromState: trapState,
          toState: trapState,
          symbol: symbol,
          controlPoint: trapState.position + Vector2(60, -60),
        ),
      );
    }

    return FSA(
      id: dfa.id,
      name: dfa.name,
      states: states,
      transitions: transitions,
      alphabet: dfa.alphabet,
      initialState: dfa.initialState,
      acceptingStates: dfa.acceptingStates,
      created: dfa.created,
      modified: DateTime.now(),
      bounds: bounds,
      zoomLevel: dfa.zoomLevel,
      panOffset: dfa.panOffset,
    );
  }

  static List<_MissingTransition> _missingTransitions(
    List<State> states,
    Set<FSATransition> transitions,
    List<String> alphabet,
  ) {
    return [
      for (final state in states)
        for (final symbol in alphabet)
          if (!transitions.any(
            (transition) =>
                transition.fromState.id == state.id &&
                transition.inputSymbols.contains(symbol),
          ))
            _MissingTransition(state, symbol),
    ];
  }

  static State? _findCompatibleSink(
    List<State> states,
    Set<FSATransition> transitions,
    List<String> alphabet,
    Set<State> acceptingStates,
  ) {
    for (final state in states) {
      if (state.isAccepting ||
          acceptingStates.any((accepting) => accepting.id == state.id)) {
        continue;
      }

      final isSink = alphabet.every((symbol) {
        final matching = transitions.where(
          (transition) =>
              transition.fromState.id == state.id &&
              transition.inputSymbols.contains(symbol),
        );
        return matching.length == 1 && matching.single.toState.id == state.id;
      });
      if (isSink) {
        return state;
      }
    }
    return null;
  }

  static Set<String> _outgoingSymbols(
    State state,
    Set<FSATransition> transitions,
  ) {
    return {
      for (final transition in transitions)
        if (transition.fromState.id == state.id) ...transition.inputSymbols,
    };
  }

  static String _nextAvailableId(String base, Set<String> usedIds) {
    var candidate = base;
    var suffix = 1;
    while (usedIds.contains(candidate)) {
      candidate = '${base}_${suffix++}';
    }
    usedIds.add(candidate);
    return candidate;
  }

  static Vector2 _trapPosition(
    List<State> states,
    math.Rectangle<num> bounds,
  ) {
    if (states.isEmpty) {
      return Vector2(
          bounds.left + bounds.width / 2, bounds.top + bounds.height / 2);
    }
    final rightmostX = states.map((state) => state.position.x).reduce(math.max);
    final averageY = states
            .map((state) => state.position.y)
            .reduce((first, second) => first + second) /
        states.length;
    return Vector2(rightmostX + _stateSpacing, averageY);
  }

  static math.Rectangle<double> _boundsIncluding(
    math.Rectangle<num> bounds,
    Vector2 position,
  ) {
    final left = math.min(bounds.left, position.x - _stateExtent).toDouble();
    final top = math.min(bounds.top, position.y - _stateExtent).toDouble();
    final right = math.max(bounds.right, position.x + _stateExtent).toDouble();
    final bottom =
        math.max(bounds.bottom, position.y + _stateExtent).toDouble();
    return math.Rectangle(left, top, right - left, bottom - top);
  }
}

class _MissingTransition {
  const _MissingTransition(this.state, this.symbol);

  final State state;
  final String symbol;
}
