import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/automaton_simulator.dart';
import 'package:turing_lab/core/algorithms/equivalence_checker.dart';
import 'package:turing_lab/core/algorithms/regex_to_nfa_converter.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  test('finite-language analysis includes mixed epsilon and symbol cycles', () {
    final q0 = _state('q0', initial: true);
    final q1 = _state('q1', accepting: true);
    final q2 = _state('q2');
    final automaton = _fsa(
      states: {q0, q1, q2},
      initial: q0,
      accepting: {q1},
      alphabet: {'a'},
      transitions: {
        FSATransition.epsilon(id: 'e0', fromState: q0, toState: q1),
        FSATransition.deterministic(
          id: 'a0',
          fromState: q1,
          toState: q2,
          symbol: 'a',
        ),
        FSATransition.epsilon(id: 'e1', fromState: q2, toState: q1),
      },
    );

    expect(automaton.isFiniteLanguage, isFalse);
  });

  test('mixed epsilon-symbol transition remains consuming for finiteness', () {
    final q0 = _state('q0', initial: true);
    final q1 = _state('q1', accepting: true);
    final automaton = _fsa(
      states: {q0, q1},
      initial: q0,
      accepting: {q1},
      alphabet: {'a'},
      transitions: {
        FSATransition(
          id: 'mixed',
          fromState: q0,
          toState: q1,
          inputSymbols: const {'ε', 'a'},
        ),
        FSATransition.epsilon(id: 'back', fromState: q1, toState: q0),
      },
    );

    expect(automaton.isFiniteLanguage, isFalse);
  });

  test('regex conversion produces stable state and transition identities', () {
    final first = RegexToNFAConverter.convert('a').data!;
    final second = RegexToNFAConverter.convert('a').data!;

    expect(
      first.states.map((state) => state.id).toSet(),
      second.states.map((state) => state.id).toSet(),
    );
    expect(
      first.fsaTransitions.map((transition) => transition.id).toSet(),
      second.fsaTransitions.map((transition) => transition.id).toSet(),
    );
    expect(
      first.states.map((state) => state.id),
      everyElement(isNot(matches(RegExp(r'\d{13,}')))),
    );
  });

  test('deterministic fragment identities stay distinct in repeated branches',
      () {
    final converted = RegexToNFAConverter.convert('(ab)|(ab)');

    expect(converted.isSuccess, isTrue);
    final automaton = converted.data!;
    expect(
      automaton.states.map((state) => state.id).toSet(),
      hasLength(automaton.states.length),
    );
    expect(
      automaton.fsaTransitions.map((transition) => transition.id).toSet(),
      hasLength(automaton.fsaTransitions.length),
    );
    expect(
        EquivalenceChecker.areEquivalent(
          automaton,
          RegexToNFAConverter.convert('ab').data!,
        ),
        isTrue);
  });

  test('Unicode scalar ranges validate and expand by scalar value', () {
    final validation = RegexToNFAConverter.validate('[😀-😁]');
    final conversion = RegexToNFAConverter.convert('[😀-😁]');

    expect(validation.isValid, isTrue);
    expect(conversion.isSuccess, isTrue);
    expect(conversion.data!.alphabet, {'😀', '😁'});
  });

  test('escaped dash in character class stays literal', () {
    final parsed = RegexToNFAConverter.parse(r'[a\-z]');
    final converted = RegexToNFAConverter.convert(r'[a\-z]');
    final supplementary = RegexToNFAConverter.parse(r'[😀\-😁]');

    expect(parsed, isA<SetNode>());
    expect((parsed! as SetNode).symbols, {'a', '-', 'z'});
    expect(converted.isSuccess, isTrue, reason: converted.error);
    final symbols = converted.data!.fsaTransitions
        .expand((transition) => transition.inputSymbols)
        .toSet();
    expect(symbols, {'a', '-', 'z'});
    expect(supplementary, isA<SetNode>());
    expect((supplementary! as SetNode).symbols, {'😀', '-', '😁'});
  });

  test('zero DFA timeout is an immediate typed timeout', () async {
    final automaton = RegexToNFAConverter.convert('a').data!;

    final result = await AutomatonSimulator.simulateDFA(
      automaton,
      'a',
      timeout: Duration.zero,
    );

    expect(result.isSuccess, isTrue);
    expect(result.data!.isTimeout, isTrue);
  });
}

State _state(
  String id, {
  bool initial = false,
  bool accepting = false,
}) =>
    State(
      id: id,
      label: id,
      position: Vector2.zero(),
      isInitial: initial,
      isAccepting: accepting,
    );

FSA _fsa({
  required Set<State> states,
  required State initial,
  required Set<State> accepting,
  required Set<String> alphabet,
  required Set<FSATransition> transitions,
}) =>
    FSA(
      id: 'regular-regression',
      name: 'Regular regression',
      states: states,
      transitions: transitions,
      alphabet: alphabet,
      initialState: initial,
      acceptingStates: accepting,
      created: DateTime.utc(2026),
      modified: DateTime.utc(2026),
      bounds: const math.Rectangle(0, 0, 100, 100),
    );
