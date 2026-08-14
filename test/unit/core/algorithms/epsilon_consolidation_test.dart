import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/automaton_simulator.dart';
import 'package:turing_lab/core/algorithms/dfa_operations.dart';
import 'package:turing_lab/core/algorithms/nfa_to_dfa_converter.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  for (final alias in ['ε', 'λ', 'eps', 'vazio']) {
    test('treats symbol-encoded $alias consistently as epsilon', () async {
      final nfa = _epsilonPath(alias);
      final epsilonTransition = nfa.fsaTransitions.firstWhere(
        (transition) => transition.id == 'epsilon',
      );

      expect(epsilonTransition.isEpsilonTransition, isTrue);
      expect(nfa.getEpsilonClosure(nfa.initialState!), hasLength(2));

      final simulation = await AutomatonSimulator.simulateNFA(nfa, 'a');
      expect(simulation.isSuccess, isTrue);
      expect(simulation.data!.accepted, isTrue);

      final determinized = NFAToDFAConverter.convert(nfa);
      expect(determinized.isSuccess, isTrue);
      final deterministicSimulation = await AutomatonSimulator.simulateDFA(
        determinized.data!,
        'a',
      );
      expect(deterministicSimulation.isSuccess, isTrue);
      expect(deterministicSimulation.data!.accepted, isTrue);

      final removed = FSAOperations.removeLambdaTransitions(nfa);
      expect(removed.isSuccess, isTrue);
      expect(removed.data!.hasEpsilonTransitions, isFalse);
      expect(removed.data!.alphabet, {'a'});
      final removedSimulation = await AutomatonSimulator.simulateNFA(
        removed.data!,
        'a',
      );
      expect(removedSimulation.isSuccess, isTrue);
      expect(removedSimulation.data!.accepted, isTrue);
    });
  }

  test('algorithm files do not define private epsilon predicates', () {
    final privatePredicate = RegExp(
      r'(?:bool|static bool)\s+_(?:isEpsilonSymbol|isLambdaSymbol|isEpsilon)\s*\(',
    );
    final offenders = Directory('lib/core/algorithms')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where((file) => privatePredicate.hasMatch(file.readAsStringSync()))
        .map((file) => file.path)
        .toList();

    expect(offenders, isEmpty);
  });
}

FSA _epsilonPath(String alias) {
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

  return FSA(
    id: 'symbol-epsilon-$alias',
    name: 'Symbol epsilon $alias',
    states: {q0, q1, q2},
    transitions: {
      FSATransition.deterministic(
        id: 'epsilon',
        fromState: q0,
        toState: q1,
        symbol: alias,
      ),
      FSATransition.deterministic(
        id: 'a',
        fromState: q1,
        toState: q2,
        symbol: 'a',
      ),
    },
    alphabet: {alias, 'a'},
    initialState: q0,
    acceptingStates: {q2},
    created: timestamp,
    modified: timestamp,
    bounds: const math.Rectangle(0, 0, 300, 100),
  );
}
