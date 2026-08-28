import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/automaton_simulator.dart';
import 'package:turing_lab/core/algorithms/fa_to_regex_converter.dart';
import 'package:turing_lab/core/algorithms/regex_to_nfa_converter.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/core/models/transition.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  group('FAToRegexConverter regressions', () {
    test('uses semantic symbols instead of a stale visual label', () async {
      final fsa = _twoStateFsa(
        FSATransition(
          id: 't0',
          fromState: _q0,
          toState: _q1,
          label: 'stale-label',
          inputSymbols: const {'a'},
        ),
      );

      final regex = FAToRegexConverter.convert(fsa);
      final converted = RegexToNFAConverter.convert(regex.data!);
      final acceptsA =
          await AutomatonSimulator.simulateNFA(converted.data!, 'a');
      final acceptsStale =
          await AutomatonSimulator.simulateNFA(converted.data!, 'stale-label');

      expect(regex.isSuccess, isTrue);
      expect(acceptsA.data!.accepted, isTrue);
      expect(acceptsStale.data!.accepted, isFalse);
    });

    test('preserves epsilon and symbols stored on the same edge', () async {
      final fsa = _twoStateFsa(
        FSATransition(
          id: 't0',
          fromState: _q0,
          toState: _q1,
          inputSymbols: const {'a'},
          lambdaSymbol: 'ε',
          type: TransitionType.epsilon,
        ),
      );

      final regex = FAToRegexConverter.convert(fsa);
      final converted = RegexToNFAConverter.convert(regex.data!);
      final empty = await AutomatonSimulator.simulateNFA(converted.data!, '');
      final symbol = await AutomatonSimulator.simulateNFA(converted.data!, 'a');

      expect(empty.data!.accepted, isTrue);
      expect(symbol.data!.accepted, isTrue);
    });

    test('does not reinterpret epsilon aliases as consumed text', () async {
      final fsa = _twoStateFsa(
        FSATransition(
          id: 't0',
          fromState: _q0,
          toState: _q1,
          inputSymbols: const {'lambda', 'a'},
        ),
      );

      final regex = FAToRegexConverter.convert(fsa);
      final converted = RegexToNFAConverter.convert(regex.data!);
      final empty = await AutomatonSimulator.simulateNFA(converted.data!, '');
      final symbol = await AutomatonSimulator.simulateNFA(converted.data!, 'a');
      final alias =
          await AutomatonSimulator.simulateNFA(converted.data!, 'lambda');

      expect(empty.data!.accepted, isTrue);
      expect(symbol.data!.accepted, isTrue);
      expect(alias.data!.accepted, isFalse);
    });

    test('escapes regex metacharacters used as alphabet symbols', () async {
      final fsa = _twoStateFsa(
        FSATransition.deterministic(
          id: 't0',
          fromState: _q0,
          toState: _q1,
          symbol: '+',
        ),
      );

      final regex = FAToRegexConverter.convert(fsa);
      final converted = RegexToNFAConverter.convert(regex.data!);
      final plus = await AutomatonSimulator.simulateNFA(converted.data!, '+');

      expect(regex.data, contains(r'\+'));
      expect(plus.data!.accepted, isTrue);
    });

    test('is deterministic across state and transition Set insertion order',
        () {
      final firstTransition = FSATransition.deterministic(
        id: 'a',
        fromState: _q0,
        toState: _q1,
        symbol: 'b',
      );
      final secondTransition = FSATransition.deterministic(
        id: 'b',
        fromState: _q0,
        toState: _q1,
        symbol: 'a',
      );
      final first = _automaton(
        states: {_q0, _q1},
        transitions: {firstTransition, secondTransition},
      );
      final second = _automaton(
        states: {_q1, _q0},
        transitions: {secondTransition, firstTransition},
      );

      expect(
        FAToRegexConverter.convert(first).data,
        FAToRegexConverter.convert(second).data,
      );
    });
  });
}

final _q0 = State(
  id: 'q0',
  label: 'q0',
  position: Vector2.zero(),
  isInitial: true,
);
final _q1 = State(
  id: 'q1',
  label: 'q1',
  position: Vector2(100, 0),
  isAccepting: true,
);

FSA _twoStateFsa(FSATransition transition) => _automaton(
      states: {_q0, _q1},
      transitions: {transition},
    );

FSA _automaton({
  required Set<State> states,
  required Set<FSATransition> transitions,
}) {
  final timestamp = DateTime.utc(2026);
  return FSA(
    id: 'source',
    name: 'Source',
    states: states,
    transitions: transitions,
    alphabet: const {'a', 'b', '+'},
    initialState: _q0,
    acceptingStates: {_q1},
    created: timestamp,
    modified: timestamp,
    bounds: const math.Rectangle(0, 0, 200, 100),
  );
}
