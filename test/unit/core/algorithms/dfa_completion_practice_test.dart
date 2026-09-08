import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/fsa/dfa_completer.dart';
import 'package:turing_lab/core/algorithms/fsa/dfa_completion_practice.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  group('DfaCompletionPractice.audit', () {
    test('reports no automaton and empty alphabet explicitly', () {
      expect(
        DfaCompletionPractice.audit(null).status,
        DfaCompletionPracticeStatus.noAutomaton,
      );
      final q0 = _state('q0', 0, isInitial: true);
      final audit = DfaCompletionPractice.audit(
        _dfa(states: {q0}, alphabet: {}, transitions: {}, initialState: q0),
      );
      expect(audit.status, DfaCompletionPracticeStatus.emptyAlphabet);
      expect(audit.hint, isNull);
    });

    test('lists every missing pair sorted by state then symbol', () {
      final q0 = _state('q0', 0, isInitial: true);
      final q1 = _state('q1', 120, isAccepting: true);
      final audit = DfaCompletionPractice.audit(
        _dfa(
          states: {q1, q0},
          alphabet: {'b', 'a'},
          transitions: {_transition('t0', q0, q1, 'a')},
          initialState: q0,
          acceptingStates: {q1},
        ),
      );

      expect(audit.status, DfaCompletionPracticeStatus.incomplete);
      expect(audit.alphabet, ['a', 'b']);
      expect(audit.missing.map((m) => '${m.state.id}/${m.symbol}'), [
        'q0/b',
        'q1/a',
        'q1/b',
      ]);
      expect(audit.trapCandidates, isEmpty);
      expect(audit.hint, DfaCompletionHint.createTrapState);
    });

    test('recognizes a trap candidate and asks to route pairs to it', () {
      final q0 = _state('q0', 0, isInitial: true);
      final trap = _state('trap', 120);
      final audit = DfaCompletionPractice.audit(
        _dfa(
          states: {q0, trap},
          alphabet: {'a', 'b'},
          transitions: {
            _transition('t0', q0, q0, 'a'),
            _transition('t1', trap, trap, 'a'),
          },
          initialState: q0,
        ),
      );

      expect(audit.trapCandidates.map((s) => s.id), ['trap']);
      expect(audit.hint, DfaCompletionHint.routeMissingToTrap);
    });

    test('asks to loop the trap when only it misses transitions', () {
      final q0 = _state('q0', 0, isInitial: true);
      final trap = _state('trap', 120);
      final audit = DfaCompletionPractice.audit(
        _dfa(
          states: {q0, trap},
          alphabet: {'a', 'b'},
          transitions: {
            _transition('t0', q0, q0, 'a'),
            _transition('t1', q0, trap, 'b'),
            _transition('t2', trap, trap, 'a'),
          },
          initialState: q0,
        ),
      );

      expect(audit.missing.map((m) => '${m.state.id}/${m.symbol}'), ['trap/b']);
      expect(audit.hint, DfaCompletionHint.loopTrapOnEverySymbol);
    });

    test('an accepting sink is not a trap candidate', () {
      final q0 = _state('q0', 0, isInitial: true);
      final sink = _state('sink', 120, isAccepting: true);
      final audit = DfaCompletionPractice.audit(
        _dfa(
          states: {q0, sink},
          alphabet: {'a'},
          transitions: {_transition('t0', sink, sink, 'a')},
          initialState: q0,
          acceptingStates: {sink},
        ),
      );
      expect(audit.trapCandidates, isEmpty);
      expect(audit.hint, DfaCompletionHint.createTrapState);
    });

    test('rejects nondeterministic automata instead of auditing them', () {
      final q0 = _state('q0', 0, isInitial: true);
      final q1 = _state('q1', 120);
      final audit = DfaCompletionPractice.audit(
        _dfa(
          states: {q0, q1},
          alphabet: {'a'},
          transitions: {
            _transition('t0', q0, q0, 'a'),
            _transition('t1', q0, q1, 'a'),
          },
          initialState: q0,
        ),
      );
      expect(audit.status, DfaCompletionPracticeStatus.notDeterministic);
      expect(audit.missing, isEmpty);
    });

    test('agrees with DFACompleter about completeness', () {
      final q0 = _state('q0', 0, isInitial: true);
      final q1 = _state('q1', 120, isAccepting: true);
      final partial = _dfa(
        states: {q0, q1},
        alphabet: {'a', 'b'},
        transitions: {_transition('t0', q0, q1, 'a')},
        initialState: q0,
        acceptingStates: {q1},
      );
      expect(DfaCompletionPractice.audit(partial).isComplete, isFalse);

      final completed = DfaCompletionPractice.audit(
        DFACompleter.complete(partial),
      );
      expect(completed.status, DfaCompletionPracticeStatus.complete);
      expect(completed.missing, isEmpty);
      expect(completed.hint, isNull);
      expect(completed.trapCandidates.map((s) => s.type), [StateType.trap]);
    });
  });
}

State _state(
  String id,
  double x, {
  bool isInitial = false,
  bool isAccepting = false,
}) {
  return State(
    id: id,
    label: id,
    position: Vector2(x, 100),
    isInitial: isInitial,
    isAccepting: isAccepting,
  );
}

FSATransition _transition(String id, State from, State to, String symbol) {
  return FSATransition.deterministic(
    id: id,
    fromState: from,
    toState: to,
    symbol: symbol,
    controlPoint: identical(from, to) ? from.position + Vector2(40, -40) : null,
  );
}

FSA _dfa({
  required Set<State> states,
  required Set<String> alphabet,
  required Set<FSATransition> transitions,
  required State initialState,
  Set<State> acceptingStates = const {},
}) {
  return FSA(
    id: 'dfa',
    name: 'DFA',
    states: states,
    transitions: transitions,
    alphabet: alphabet,
    initialState: initialState,
    acceptingStates: acceptingStates,
    created: DateTime.utc(2026),
    modified: DateTime.utc(2026),
    bounds: const math.Rectangle(0, 0, 200, 200),
  );
}
