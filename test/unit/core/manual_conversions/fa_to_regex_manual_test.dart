import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:turing_lab/core/manual_conversions/fa_to_regex_manual.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/state.dart';

void main() {
  group('FaToRegexManualOracle.normalize', () {
    test('is deterministic, collision-safe, and preserves transition semantics',
        () {
      final first = _parallelFsa(reverseInsertion: false, collideIds: true);
      final second = _parallelFsa(reverseInsertion: true, collideIds: true);

      final normalizedFirst = FaToRegexManualOracle.normalize(first);
      final normalizedSecond = FaToRegexManualOracle.normalize(second);

      expect(normalizedFirst.startStateId, '__gnfa_start__1');
      expect(normalizedFirst.finalStateId, '__gnfa_final__1');
      expect(normalizedFirst.sourceRevision, normalizedSecond.sourceRevision);
      expect(
        normalizedFirst.states.map((state) => state.id),
        normalizedSecond.states.map((state) => state.id),
      );
      expect(normalizedFirst.labels, normalizedSecond.labels);
      expect(
        normalizedFirst.expressionBetween('__gnfa_start__', '__gnfa_final__'),
        '(a|b|ε)',
      );
      expect(
        normalizedFirst.expressionBetween('__gnfa_final__', '__gnfa_final__'),
        r'\|',
      );
      expect(
        normalizedFirst.expressionBetween(
          normalizedFirst.startStateId,
          '__gnfa_start__',
        ),
        'ε',
      );
      expect(
        normalizedFirst.expressionBetween(
          '__gnfa_final__',
          normalizedFirst.finalStateId,
        ),
        'ε',
      );
      expect(
        () => normalizedFirst.labels.clear(),
        throwsUnsupportedError,
      );
    });

    test('rejects a source with transition endpoints outside its state set',
        () {
      final q0 = _state('q0', initial: true);
      final external = _state('external');
      final source = _fsa(
        states: {q0},
        transitions: {
          FSATransition.deterministic(
            id: 'bad',
            fromState: q0,
            toState: external,
            symbol: 'a',
          ),
        },
        initial: q0,
      );

      expect(
        () => FaToRegexManualOracle.normalize(source),
        throwsA(
          isA<FaToRegexManualException>().having(
            (error) => error.code,
            'code',
            FaToRegexManualErrorCode.invalidSource,
          ),
        ),
      );
    });
  });

  group('FaToRegexManualOracle elimination', () {
    test('exposes the complete pair formula for an arbitrary state', () {
      final q0 = _state('q0', initial: true);
      final q1 = _state('q1');
      final q2 = _state('q2', accepting: true);
      final source = _fsa(
        states: {q2, q0, q1},
        transitions: {
          _transition('direct', q0, q2, 'd'),
          _transition('incoming', q0, q1, 'a'),
          _transition('loop', q1, q1, 'b'),
          _transition('outgoing', q1, q2, 'c'),
        },
        initial: q0,
        accepting: {q2},
        alphabet: {'a', 'b', 'c', 'd'},
      );
      final gnfa = FaToRegexManualOracle.normalize(source);

      final inspection = FaToRegexManualOracle.inspectElimination(gnfa, 'q1');

      expect(inspection.incomingStateIds, ['q0']);
      expect(inspection.outgoingStateIds, ['q2']);
      expect(inspection.loopExpression, 'b');
      expect(inspection.formulas, hasLength(1));
      final formula = inspection.formulas.single;
      expect(formula.directExpression, 'd');
      expect(formula.incomingExpression, 'a');
      expect(formula.loopExpression, 'b');
      expect(formula.outgoingExpression, 'c');
      expect(formula.bypassExpression, 'a(b)*c');
      expect(formula.expectedExpression, '(d|a(b)*c)');
      expect(formula.id, 'r0:2:q1:2:q0:2:q2');
    });

    test('protects synthetic start and final states', () {
      final q0 = _state('q0', initial: true, accepting: true);
      final gnfa = FaToRegexManualOracle.normalize(
        _fsa(states: {q0}, initial: q0, accepting: {q0}),
      );

      for (final stateId in [gnfa.startStateId, gnfa.finalStateId]) {
        expect(
          () => FaToRegexManualOracle.inspectElimination(gnfa, stateId),
          throwsA(
            isA<FaToRegexManualException>().having(
              (error) => error.code,
              'code',
              FaToRegexManualErrorCode.protectedState,
            ),
          ),
        );
      }
    });

    test('validates equivalent syntax and rejects a wrong learner label', () {
      final source = _twoSymbolFsa();
      final gnfa = FaToRegexManualOracle.normalize(source);
      final inspection = FaToRegexManualOracle.inspectElimination(gnfa, 'q0');
      final formula = inspection.formulas.single;

      final equivalent = FaToRegexManualOracle.validatePairLabel(
        gnfa: gnfa,
        inspection: inspection,
        pair: formula.pair,
        learnerExpression: '(b|a)',
      );
      final wrong = FaToRegexManualOracle.validatePairLabel(
        gnfa: gnfa,
        inspection: inspection,
        pair: formula.pair,
        learnerExpression: 'c',
      );

      expect(formula.expectedExpression, '(a|b)');
      expect(equivalent.isValid, isTrue);
      expect(equivalent.isExactTextMatch, isFalse);
      expect(wrong.isValid, isFalse);
      expect(wrong.message, isNotEmpty);
    });

    test('applies a validated elimination without mutating the prior GNFA', () {
      final q0 = _state('q0', initial: true, accepting: true);
      final source = _fsa(
        states: {q0},
        transitions: {_transition('loop', q0, q0, 'a')},
        initial: q0,
        accepting: {q0},
        alphabet: {'a'},
      );
      final gnfa = FaToRegexManualOracle.normalize(source);
      final inspection = FaToRegexManualOracle.inspectElimination(gnfa, 'q0');
      final formula = inspection.formulas.single;

      final result = FaToRegexManualOracle.applyElimination(
        gnfa: gnfa,
        inspection: inspection,
        pairLabels: {formula.pair: 'a*'},
      );

      expect(gnfa.revision, 0);
      expect(gnfa.states.map((state) => state.id), contains('q0'));
      expect(result.revision, 1);
      expect(result.states.map((state) => state.id), isNot(contains('q0')));
      expect(FaToRegexManualOracle.finalRegex(result), '(a)*');
    });

    test('requires every affected pair label and rejects stale inspections',
        () {
      final gnfa = FaToRegexManualOracle.normalize(_twoSymbolFsa());
      final inspection = FaToRegexManualOracle.inspectElimination(gnfa, 'q0');
      final formula = inspection.formulas.single;

      expect(
        () => FaToRegexManualOracle.applyElimination(
          gnfa: gnfa,
          inspection: inspection,
          pairLabels: const {},
        ),
        throwsA(
          isA<FaToRegexManualException>().having(
            (error) => error.code,
            'code',
            FaToRegexManualErrorCode.missingPairLabel,
          ),
        ),
      );

      final next = FaToRegexManualOracle.applyElimination(
        gnfa: gnfa,
        inspection: inspection,
        pairLabels: {formula.pair: formula.expectedExpression},
      );
      expect(
        () => FaToRegexManualOracle.validatePairLabel(
          gnfa: next,
          inspection: inspection,
          pair: formula.pair,
          learnerExpression: formula.expectedExpression,
        ),
        throwsA(
          isA<FaToRegexManualException>().having(
            (error) => error.code,
            'code',
            FaToRegexManualErrorCode.staleInspection,
          ),
        ),
      );
    });

    test('handles empty language when an eliminated state has no successors',
        () {
      final q0 = _state('q0', initial: true);
      final gnfa = FaToRegexManualOracle.normalize(
        _fsa(states: {q0}, initial: q0),
      );
      final inspection = FaToRegexManualOracle.inspectElimination(gnfa, 'q0');

      expect(inspection.formulas, isEmpty);
      final result = FaToRegexManualOracle.applyElimination(
        gnfa: gnfa,
        inspection: inspection,
        pairLabels: const {},
      );
      expect(FaToRegexManualOracle.finalRegex(result), '∅');
    });

    test('finalRegex rejects an incomplete construction', () {
      final gnfa = FaToRegexManualOracle.normalize(_twoSymbolFsa());

      expect(
        () => FaToRegexManualOracle.finalRegex(gnfa),
        throwsA(
          isA<FaToRegexManualException>().having(
            (error) => error.code,
            'code',
            FaToRegexManualErrorCode.incompleteConstruction,
          ),
        ),
      );
    });
  });
}

FSA _parallelFsa({
  required bool reverseInsertion,
  required bool collideIds,
}) {
  final q0 = _state(collideIds ? '__gnfa_start__' : 'q0', initial: true);
  final q1 = _state(collideIds ? '__gnfa_final__' : 'q1', accepting: true);
  final transitions = <FSATransition>[
    _transition('t1', q0, q1, 'a'),
    _transition('t2', q0, q1, 'b'),
    FSATransition(
      id: 't3',
      fromState: q0,
      toState: q1,
      label: 'grouped',
      inputSymbols: const {'ε', 'a'},
    ),
    _transition('t4', q1, q1, '|'),
  ];
  if (reverseInsertion) {
    transitions.setAll(0, transitions.reversed.toList());
  }
  return _fsa(
    states: reverseInsertion ? {q1, q0} : {q0, q1},
    transitions: transitions.toSet(),
    initial: q0,
    accepting: {q1},
    alphabet: {'a', 'b', '|'},
  );
}

FSA _twoSymbolFsa() {
  final q0 = _state('q0', initial: true);
  final q1 = _state('q1', accepting: true);
  return _fsa(
    states: {q0, q1},
    transitions: {
      _transition('a', q0, q1, 'a'),
      _transition('b', q0, q1, 'b'),
    },
    initial: q0,
    accepting: {q1},
    alphabet: {'a', 'b'},
  );
}

State _state(
  String id, {
  bool initial = false,
  bool accepting = false,
}) {
  return State(
    id: id,
    label: id,
    position: Vector2.zero(),
    isInitial: initial,
    isAccepting: accepting,
  );
}

FSATransition _transition(
  String id,
  State from,
  State to,
  String symbol,
) {
  return FSATransition.deterministic(
    id: id,
    fromState: from,
    toState: to,
    symbol: symbol,
  );
}

FSA _fsa({
  required Set<State> states,
  Set<FSATransition> transitions = const {},
  required State? initial,
  Set<State> accepting = const {},
  Set<String> alphabet = const {},
}) {
  final timestamp = DateTime.utc(2026, 8, 25);
  return FSA(
    id: 'manual-source',
    name: 'Manual source',
    states: states,
    transitions: transitions,
    alphabet: alphabet,
    initialState: initial,
    acceptingStates: accepting,
    created: timestamp,
    modified: timestamp,
    bounds: const math.Rectangle<double>(0, 0, 800, 600),
  );
}
