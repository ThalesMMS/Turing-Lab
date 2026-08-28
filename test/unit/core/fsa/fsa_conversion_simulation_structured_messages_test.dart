import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/automaton_simulation_messages.dart';
import 'package:turing_lab/core/algorithms/automaton_simulator.dart';
import 'package:turing_lab/core/algorithms/nfa_to_dfa_converter.dart';
import 'package:turing_lab/core/algorithms/nfa_to_dfa_messages.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  group('NFA-to-DFA structured diagnostics', () {
    test('validation failures preserve legacy text and expose payloads', () {
      final empty = _automaton(states: const {});
      final emptyResult = NFAToDFAConverter.convert(empty);
      expect(emptyResult.error, 'NFA must have at least one state');
      expect(emptyResult.structuredError, NfaToDfaMessages.emptyAutomaton());

      final state = _state('q0', isInitial: true);
      final noInitial = _automaton(states: {state});
      final noInitialResult = NFAToDFAConverter.convert(noInitial);
      expect(noInitialResult.error, 'NFA must have an initial state');
      expect(
        noInitialResult.structuredError,
        NfaToDfaMessages.missingInitialState(),
      );

      final outside = _state('outside', isInitial: true);
      final initialOutside = _automaton(states: {state}, initialState: outside);
      final initialOutsideResult = NFAToDFAConverter.convert(initialOutside);
      expect(
        initialOutsideResult.error,
        'Initial state must be in the states set',
      );
      expect(
        initialOutsideResult.structuredError,
        NfaToDfaMessages.initialStateOutsideSet(),
      );

      final acceptingOutside = _automaton(
        states: {state},
        initialState: state,
        acceptingStates: {outside},
      );
      final acceptingOutsideResult = NFAToDFAConverter.convert(
        acceptingOutside,
      );
      expect(
        acceptingOutsideResult.error,
        'Accepting state must be in the states set',
      );
      expect(
        acceptingOutsideResult.structuredError,
        NfaToDfaMessages.acceptingStateOutsideSet(),
      );
    });

    test('convertWithSteps carries the same validation contract', () {
      final result = NFAToDFAConverter.convertWithSteps(
        _automaton(states: const {}),
      );

      expect(result.error, 'NFA must have at least one state');
      expect(result.structuredError, NfaToDfaMessages.emptyAutomaton());
    });

    test('conversion error payloads keep step-capture context typed', () {
      final message = NfaToDfaMessages.conversionFailed(
        error: StateError('conversion failed'),
        withSteps: true,
      );

      expect(message.stableCode, 'automaton.nfa-to-dfa.conversion-failed');
      expect(message.arguments['error']?.value, 'Bad state: conversion failed');
      expect(message.arguments['error']?.role, 'error-detail');
      expect(message.arguments['with-steps']?.value, isTrue);
      expect(message.arguments['with-steps']?.role, 'step-capture');
    });
  });

  group('NFA simulation structured diagnostics', () {
    test('trace truncation preserves the compatibility explanation', () async {
      final initial = _state('q0', isInitial: true);
      final accepting = _state('q1', isAccepting: true);
      final nfa = _automaton(
        states: {initial, accepting},
        initialState: initial,
        acceptingStates: {accepting},
        alphabet: {'a'},
        transitions: {
          FSATransition(
            id: 'q0-q1-a',
            fromState: initial,
            toState: accepting,
            inputSymbols: {'a'},
            label: 'a',
          ),
        },
      );

      final result = await AutomatonSimulator.simulateNFA(
        nfa,
        'a',
        stepByStep: true,
        maxTraceNodes: 1,
      );

      expect(result.isSuccess, isTrue);
      expect(
        result.data!.message?.stableCode,
        'automaton.simulation.nfa-trace-truncated',
      );
      expect(result.data!.message?.arguments['limit']?.value, 1);
      expect(
        result.data!.message?.arguments['epsilon-path-limited']?.value,
        isFalse,
      );
      expect(
        result.data!.errorMessage,
        'NFA trace truncated after 1 nodes. '
        'Rerun without step-by-step tracing to check acceptance.',
      );
    });

    test(
      'NFA rejection keeps structured error through accepts and rejects',
      () async {
        final initial = _state('q0', isInitial: true);
        final nfa = _automaton(
          states: {initial},
          initialState: initial,
          alphabet: {'a', 'ε'},
          transitions: {
            FSATransition(
              id: 'q0-q0-epsilon',
              fromState: initial,
              toState: initial,
              inputSymbols: {'ε'},
              label: 'ε',
            ),
          },
        );

        final direct = await AutomatonSimulator.simulateNFA(nfa, 'b');
        expect(direct.isSuccess, isTrue);
        expect(
          direct.data!.message?.stableCode,
          'automaton.simulation.no-nfa-transition',
        );

        final invalid = _automaton(states: {initial});
        final accepted = await AutomatonSimulator.accepts(invalid, 'b');
        expect(accepted.isFailure, isTrue);
        expect(
          accepted.structuredError?.stableCode,
          'automaton.simulation.missing-initial-state',
        );

        final rejected = await AutomatonSimulator.rejects(invalid, 'b');
        expect(rejected.isFailure, isTrue);
        expect(
          rejected.structuredError?.stableCode,
          'automaton.simulation.missing-initial-state',
        );
      },
    );

    test(
      'final NFA rejection keeps its legacy tree text and payload',
      () async {
        final initial = _state('q0', isInitial: true);
        final nfa = _automaton(states: {initial}, initialState: initial);

        final result = await AutomatonSimulator.simulateNFA(
          nfa,
          '',
          stepByStep: true,
        );

        expect(result.isSuccess, isTrue);
        expect(
          result.data!.message?.stableCode,
          'automaton.simulation.nfa-not-accepted',
        );
        expect(
          result.data!.errorMessage,
          'Input not accepted - no accepting state reached',
        );
        expect(
          result.data!.computationTree?.errorMessage,
          'Input not accepted - no accepting state reached',
        );
      },
    );

    test('trace truncation message encodes the epsilon path limit', () {
      final message = AutomatonSimulationMessages.nfaTraceTruncated(
        maximumNodes: 10,
        epsilonPathLimited: true,
        epsilonPathLimit: AutomatonSimulator.defaultMaxNfaEpsilonPathEdges,
      );

      expect(message.stableCode, 'automaton.simulation.nfa-trace-truncated');
      expect(message.arguments['limit']?.value, 256);
      expect(message.arguments['limit']?.kind.name, 'bound');
      expect(message.arguments['epsilon-path-limited']?.value, isTrue);
    });
  });
}

State _state(String id, {bool isInitial = false, bool isAccepting = false}) =>
    State(
      id: id,
      label: id,
      position: Vector2.zero(),
      isInitial: isInitial,
      isAccepting: isAccepting,
    );

FSA _automaton({
  required Set<State> states,
  State? initialState,
  Set<State> acceptingStates = const {},
  Set<String> alphabet = const {},
  Set<FSATransition> transitions = const {},
}) => FSA(
  id: 'structured-nfa',
  name: 'Structured NFA',
  states: states,
  transitions: transitions,
  alphabet: alphabet,
  initialState: initialState,
  acceptingStates: acceptingStates,
  created: DateTime.utc(2026),
  modified: DateTime.utc(2026),
  bounds: const math.Rectangle(0, 0, 200, 100),
);
