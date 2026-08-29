import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:turing_lab/core/algorithms/dfa_minimizer.dart';
import 'package:turing_lab/core/algorithms/dfa_minimizer_messages.dart';
import 'package:turing_lab/core/algorithms/dfa_operations.dart';
import 'package:turing_lab/core/algorithms/dfa_operations_messages.dart';
import 'package:turing_lab/core/messages/structured_message.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/state.dart';

void main() {
  State state(String id, {bool isInitial = false, bool isAccepting = false}) =>
      State(
        id: id,
        label: id,
        position: Vector2.zero(),
        isInitial: isInitial,
        isAccepting: isAccepting,
      );

  FSATransition transition(String id, State from, State to, String symbol) =>
      FSATransition.deterministic(
        id: id,
        fromState: from,
        toState: to,
        symbol: symbol,
        controlPoint: identical(from, to)
            ? from.position + Vector2(20, -20)
            : null,
      );

  FSA automaton({
    Set<State>? states,
    Set<String> alphabet = const {},
    Set<FSATransition> transitions = const {},
    State? initialState,
    Set<State> acceptingStates = const {},
  }) {
    final resolvedStates = states ?? {state('q0')};
    return FSA(
      id: 'dfa',
      name: 'DFA',
      states: resolvedStates,
      transitions: transitions,
      alphabet: alphabet,
      initialState: initialState,
      acceptingStates: acceptingStates,
      created: DateTime.utc(2026),
      modified: DateTime.utc(2026),
      bounds: const math.Rectangle(0, 0, 200, 200),
    );
  }

  group('DFA operation structured diagnostics', () {
    test('keeps the legacy validation text and adds a typed message', () {
      final result = DFAOperations.complement(automaton(initialState: null));

      expect(result.isFailure, isTrue);
      expect(
        result.error,
        'DFA for complement must have a defined initial state.',
      );
      final message = result.structuredError!;
      expect(
        message.stableCode,
        'automaton.dfa-operations.missing-initial-state',
      );
      final context = message.arguments['context']!;
      expect(context.kind, StructuredMessageArgumentKind.outcome);
      expect(context.role, 'dfa-context');
      expect(context.value, 'complement');
    });

    test('attaches context and symbol arguments to validation failures', () {
      final q0 = state('q0', isInitial: true);
      final invalidTransition = transition('t0', q0, q0, 'b');
      final result = DFAOperations.prefixClosure(
        automaton(
          states: {q0},
          transitions: {invalidTransition},
          alphabet: {'a'},
          initialState: q0,
        ),
      );

      expect(result.isFailure, isTrue);
      expect(
        result.error,
        'DFA for prefix closure has a transition with a symbol outside the alphabet: "b".',
      );
      final message = result.structuredError!;
      expect(
        message.stableCode,
        'automaton.dfa-operations.symbol-outside-alphabet',
      );
      final context = message.arguments['context']!;
      expect(context.kind, StructuredMessageArgumentKind.outcome);
      expect(context.role, 'dfa-context');
      expect(context.value, 'prefix-closure');
      final symbol = message.arguments['symbol']!;
      expect(symbol.kind, StructuredMessageArgumentKind.symbol);
      expect(symbol.role, 'input-symbol');
      expect(symbol.value, 'b');
    });

    test('prioritizes empty alphabets for labeled binary operands', () {
      final a0 = state('a0', isInitial: true);
      final b0 = state('b0', isInitial: true);
      final result = DFAOperations.union(
        automaton(
          states: {a0},
          transitions: {transition('a-loop', a0, a0, 'a')},
          initialState: a0,
        ),
        automaton(states: {b0}, initialState: b0),
      );

      expect(result.isFailure, isTrue);
      expect(
        result.structuredError?.stableCode,
        'automaton.dfa-operations.empty-alphabet-with-labeled-transitions',
      );
      expect(result.structuredError?.arguments['operand']?.value, 'a');
    });

    test('uses an operation outcome for internal failures', () {
      final message = DfaOperationsMessages.operationFailed('∪');

      expect(message.stableCode, 'automaton.dfa-operations.operation-failed');
      expect(
        message.arguments['operation']?.kind,
        StructuredMessageArgumentKind.outcome,
      );
      expect(message.arguments['operation']?.role, 'dfa-operation');
      expect(message.arguments['operation']?.value, 'union');
    });
  });

  group('DFA minimization structured diagnostics', () {
    test('preserves validation failures from minimize', () {
      final result = DFAMinimizer.minimize(automaton(initialState: null));

      expect(result.isFailure, isTrue);
      expect(result.error, 'DFA must have an initial state');
      expect(
        result.structuredError?.stableCode,
        'automaton.dfa-minimization.missing-initial-state',
      );
    });

    test('classifies structural and determinism validation failures', () {
      final q0 = state('q0', isInitial: true);
      final outside = state('outside');
      final acceptingOutside = state('accepting-outside', isAccepting: true);

      final initialOutsideResult = DFAMinimizer.minimize(
        automaton(states: {q0}, initialState: outside),
      );
      expect(
        initialOutsideResult.structuredError?.stableCode,
        'automaton.dfa-minimization.initial-state-outside-set',
      );

      final acceptingOutsideResult = DFAMinimizer.minimize(
        automaton(
          states: {q0},
          initialState: q0,
          acceptingStates: {acceptingOutside},
        ),
      );
      expect(
        acceptingOutsideResult.structuredError?.stableCode,
        'automaton.dfa-minimization.accepting-state-outside-set',
      );

      final q1 = state('q1');
      final q2 = state('q2');
      final nondeterministicResult = DFAMinimizer.minimize(
        automaton(
          states: {q0, q1, q2},
          initialState: q0,
          alphabet: {'a'},
          transitions: {
            transition('t1', q0, q1, 'a'),
            transition('t2', q0, q2, 'a'),
          },
        ),
      );
      expect(
        nondeterministicResult.structuredError?.stableCode,
        'automaton.dfa-minimization.nondeterministic-input',
      );
      expect(
        nondeterministicResult.error,
        'Input must be a deterministic automaton',
      );
    });

    test('message factories expose stable categories and codes', () {
      final validation = [
        DfaMinimizerMessages.emptyDfa(),
        DfaMinimizerMessages.missingInitialState(),
        DfaMinimizerMessages.initialStateOutsideSet(),
        DfaMinimizerMessages.acceptingStateOutsideSet(),
        DfaMinimizerMessages.nondeterministicInput(),
      ];
      final analysis = [
        DfaMinimizerMessages.minimizationFailed(),
        DfaMinimizerMessages.minimizationWithStepsFailed(),
      ];

      expect(
        validation.every(
          (message) =>
              message.namespace == 'automaton.dfa-minimization' &&
              message.category == StructuredMessageCategory.validation &&
              message.severity == StructuredMessageSeverity.error,
        ),
        isTrue,
      );
      expect(
        analysis.every(
          (message) =>
              message.namespace == 'automaton.dfa-minimization' &&
              message.category == StructuredMessageCategory.analysis &&
              message.severity == StructuredMessageSeverity.error,
        ),
        isTrue,
      );
      expect(
        validation.map((message) => message.code),
        containsAll(<String>[
          'empty-dfa',
          'missing-initial-state',
          'initial-state-outside-set',
          'accepting-state-outside-set',
          'nondeterministic-input',
        ]),
      );
    });
  });
}
