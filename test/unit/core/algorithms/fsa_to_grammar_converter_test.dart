import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/fsa_to_grammar_converter.dart';
import 'package:turing_lab/core/algorithms/grammar_parser.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/production.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  test('preserves an epsilon path when converting an NFA to a grammar', () {
    final q0 = State(
      id: 'q0',
      label: 'q0',
      position: Vector2.zero(),
      isInitial: true,
    );
    final q1 = State(
      id: 'q1',
      label: 'q1',
      position: Vector2(100, 0),
    );
    final q2 = State(
      id: 'q2',
      label: 'q2',
      position: Vector2(200, 0),
      isAccepting: true,
    );
    final timestamp = DateTime.utc(2026);
    final fsa = FSA(
      id: 'epsilon-path',
      name: 'Epsilon path',
      states: {q0, q1, q2},
      transitions: {
        FSATransition.epsilon(id: 'e0', fromState: q0, toState: q1),
        FSATransition.deterministic(
          id: 't0',
          fromState: q1,
          toState: q2,
          symbol: 'a',
        ),
      },
      alphabet: const {'a'},
      initialState: q0,
      acceptingStates: {q2},
      created: timestamp,
      modified: timestamp,
      bounds: const math.Rectangle(0, 0, 300, 100),
    );

    final grammar = FSAToGrammarConverter.convert(fsa);

    expect(
      grammar.productions,
      contains(
        isA<Production>().having(
            (production) => production.leftSide, 'leftSide', [
          'A0'
        ]).having((production) => production.rightSide, 'rightSide', ['A1']),
      ),
    );
    final parseResult = GrammarParser.parse(grammar, 'a');
    expect(parseResult.isSuccess, isTrue);
    expect(parseResult.data!.accepted, isTrue);
  });

  test('preserves epsilon and consumed symbols stored on the same edge', () {
    final q0 = State(
      id: 'q0',
      label: 'q0',
      position: Vector2.zero(),
      isInitial: true,
    );
    final q1 = State(
      id: 'q1',
      label: 'q1',
      position: Vector2(100, 0),
      isAccepting: true,
    );
    final timestamp = DateTime.utc(2026);
    final fsa = FSA(
      id: 'mixed-edge',
      name: 'Mixed edge',
      states: {q0, q1},
      transitions: {
        FSATransition(
          id: 'mixed',
          fromState: q0,
          toState: q1,
          inputSymbols: const {'lambda', 'a'},
        ),
      },
      alphabet: const {'a'},
      initialState: q0,
      acceptingStates: {q1},
      created: timestamp,
      modified: timestamp,
      bounds: const math.Rectangle(0, 0, 200, 100),
    );

    final grammar = FSAToGrammarConverter.convert(fsa);

    expect(GrammarParser.parse(grammar, '').data!.accepted, isTrue);
    expect(GrammarParser.parse(grammar, 'a').data!.accepted, isTrue);
    expect(
      grammar.productions.any(
        (production) =>
            production.rightSide.length == 2 &&
            production.rightSide.first == 'a',
      ),
      isTrue,
    );
    expect(
      grammar.productions.any(
        (production) => production.rightSide.contains('lambda'),
      ),
      isFalse,
    );
  });

  test('reports a missing initial state without a null-check crash', () {
    final state = State(
      id: 'q0',
      label: 'q0',
      position: Vector2.zero(),
    );
    final timestamp = DateTime.utc(2026);
    final fsa = FSA(
      id: 'missing-initial',
      name: 'Missing initial',
      states: {state},
      transitions: const {},
      alphabet: const {},
      initialState: null,
      acceptingStates: const {},
      created: timestamp,
      modified: timestamp,
      bounds: const math.Rectangle(0, 0, 100, 100),
    );

    final result = FSAToGrammarConverter.tryConvert(fsa);

    expect(result.isSuccess, isFalse);
    expect(result.error, 'Automaton must have an initial state.');
  });

  test('assigns nonterminals deterministically regardless of Set order', () {
    final q0 = State(
      id: 'q0',
      label: 'q0',
      position: Vector2.zero(),
      isInitial: true,
    );
    final q1 = State(
      id: 'q1',
      label: 'q1',
      position: Vector2(100, 0),
      isAccepting: true,
    );
    final transition = FSATransition.deterministic(
      id: 't0',
      fromState: q0,
      toState: q1,
      symbol: 'a',
    );
    final timestamp = DateTime.utc(2026);

    FSA automaton(Set<State> states) => FSA(
          id: 'stable',
          name: 'Stable',
          states: states,
          transitions: {transition},
          alphabet: const {'a'},
          initialState: q0,
          acceptingStates: {q1},
          created: timestamp,
          modified: timestamp,
          bounds: const math.Rectangle(0, 0, 200, 100),
        );

    final first = FSAToGrammarConverter.convert(automaton({q0, q1}));
    final second = FSAToGrammarConverter.convert(automaton({q1, q0}));
    final firstRules = first.productions
        .map((value) => '${value.id}:${value.leftSide}->${value.rightSide}')
        .toList()
      ..sort();
    final secondRules = second.productions
        .map((value) => '${value.id}:${value.leftSide}->${value.rightSide}')
        .toList()
      ..sort();

    expect(first.startSymbol, 'A0');
    expect(second.startSymbol, 'A0');
    expect(firstRules, secondRules);
  });
}
