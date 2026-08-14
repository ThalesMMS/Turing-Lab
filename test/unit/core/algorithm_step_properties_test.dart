import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/dfa_minimization_step.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/nfa_to_dfa_step.dart';
import 'package:turing_lab/core/models/regex_to_nfa_step.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/core/services/algorithm_step_highlight_extractor.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  group('generic algorithm step properties', () {
    test('NFAToDFAStep serializes display fields and state IDs', () {
      final q0 = _state('q0');
      final q1 = _state('q1');
      final step = NFAToDFAStep.initialEpsilonClosure(
        id: 'nfa-0',
        stepNumber: 0,
        initialState: q0,
        epsilonClosure: {q0, q1},
        containsAcceptingState: true,
      );

      final properties = step.toProperties();

      expect(properties['stepType'], 'Epsilon Closure');
      expect(properties['currentStateIds'], ['q0']);
      expect(properties['epsilonClosureIds'], unorderedEquals(['q0', 'q1']));
      expect(properties['isAcceptingState'], true);
      expect(properties['isNewState'], true);
      expect(properties['dfaStateId'], 'q0');
      expect(() => jsonEncode(properties), returnsNormally);
    });

    test('DFAMinimizationStep serializes partition and split IDs', () {
      final q0 = _state('q0');
      final q1 = _state('q1');
      final q2 = _state('q2');
      final step = DFAMinimizationStep.splitClass(
        id: 'dfa-0',
        stepNumber: 0,
        currentPartition: [
          {q0, q1, q2},
        ],
        splitSet: {q0, q1, q2},
        intersection: {q0},
        difference: {q1, q2},
        symbol: 'a',
        newPartition: [
          {q0},
          {q1, q2},
        ],
      );

      final properties = step.toProperties();

      expect(properties['stepType'], 'Split Class');
      expect(properties['currentPartitionIds'], [
        ['q0', 'q1', 'q2'],
      ]);
      expect(properties['splitSetIds'], ['q0', 'q1', 'q2']);
      expect(properties['splitIntersectionIds'], ['q0']);
      expect(properties['splitDifferenceIds'], ['q1', 'q2']);
      expect(properties['distinguishingSymbol'], 'a');
      expect(properties['causedSplit'], true);
      expect(() => jsonEncode(properties), returnsNormally);
    });

    test('RegexToNFAStep serializes created state and transition IDs', () {
      final q0 = _state('q0');
      final q1 = _state('q1');
      final transition = FSATransition(
        id: 't0',
        fromState: q0,
        toState: q1,
        symbol: 'a',
      );
      final step = RegexToNFAStep.basicSymbol(
        id: 'regex-0',
        stepNumber: 0,
        symbol: 'a',
        position: 0,
        startState: q0,
        acceptState: q1,
        transition: transition,
        stackSize: 1,
      );

      final properties = step.toProperties();

      expect(properties['stepType'], 'Basic Symbol');
      expect(properties['createdStateIds'], unorderedEquals(['q0', 'q1']));
      expect(properties['createdTransitionIds'], ['t0']);
      expect(properties['fragmentStartStateId'], 'q0');
      expect(properties['fragmentAcceptStateId'], 'q1');
      expect(properties['regexFragment'], 'a');
      expect(properties['processedSymbol'], 'a');
      expect(properties['stackSize'], 1);
      expect(() => jsonEncode(properties), returnsNormally);
    });

    test('extractAlgorithmStepHighlight reads primitive ID keys', () {
      final highlight = extractAlgorithmStepHighlight({
        'currentStateIds': [' q0 ', ''],
        'epsilonClosureIds': ['q1'],
        'fragmentStartStateId': 'q2',
        'createdTransitionIds': ['t0', ' '],
        'currentPartitionIds': [
          ['q3'],
        ],
      });

      expect(highlight.stateIds, {'q0', 'q1', 'q2'});
      expect(highlight.transitionIds, {'t0'});
    });
  });
}

State _state(String id) {
  return State(id: id, label: id, position: Vector2.zero());
}
