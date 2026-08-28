import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';

void main() {
  group('FSA Determinism Tests', () {
    late State q0;
    late State q1;
    late State q2;

    setUp(() {
      q0 = State(
        id: 'q0',
        label: 'q0',
        position: Vector2.zero(),
        isInitial: true,
      );
      q1 = State(id: 'q1', label: 'q1', position: Vector2.zero());
      q2 = State(id: 'q2', label: 'q2', position: Vector2.zero());
    });

    test('Should be deterministic with unique transitions', () {
      final t1 = FSATransition.deterministic(
        id: 't1',
        fromState: q0,
        toState: q1,
        symbol: 'a',
      );
      final t2 = FSATransition.deterministic(
        id: 't2',
        fromState: q0,
        toState: q2,
        symbol: 'b',
      );

      final fsa = FSA(
        id: 'fsa1',
        name: 'Test FSA',
        states: {q0, q1, q2},
        transitions: {t1, t2},
        alphabet: {'a', 'b'},
        initialState: q0,
        acceptingStates: {},
        created: DateTime.now(),
        modified: DateTime.now(),
        bounds: const Rectangle(0, 0, 100, 100),
      );

      expect(fsa.isDeterministic, isTrue);
    });

    test('Should be non-deterministic with duplicate symbol transitions', () {
      final t1 = FSATransition.deterministic(
        id: 't1',
        fromState: q0,
        toState: q1,
        symbol: 'a',
      );
      // Another transition from q0 with 'a'
      final t2 = FSATransition.deterministic(
        id: 't2',
        fromState: q0,
        toState: q2,
        symbol: 'a',
      );

      final fsa = FSA(
        id: 'fsa2',
        name: 'Test FSA NFA',
        states: {q0, q1, q2},
        transitions: {t1, t2},
        alphabet: {'a'},
        initialState: q0,
        acceptingStates: {},
        created: DateTime.now(),
        modified: DateTime.now(),
        bounds: const Rectangle(0, 0, 100, 100),
      );

      expect(fsa.isDeterministic, isFalse);
      expect(fsa.validate(), isEmpty);
    });

    test('Should be non-deterministic with epsilon transitions', () {
      final t1 = FSATransition.epsilon(id: 't1', fromState: q0, toState: q1);

      final fsa = FSA(
        id: 'fsa3',
        name: 'Test FSA Epsilon',
        states: {q0, q1},
        transitions: {t1},
        alphabet: {},
        initialState: q0,
        acceptingStates: {},
        created: DateTime.now(),
        modified: DateTime.now(),
        bounds: const Rectangle(0, 0, 100, 100),
      );

      expect(fsa.isDeterministic, isFalse);
      expect(fsa.validate(), isEmpty);
    });
  });
}
