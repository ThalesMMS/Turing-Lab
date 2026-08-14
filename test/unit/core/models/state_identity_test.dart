import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  group('State identity', () {
    test('uses the automaton-local id for equality and hashing', () {
      final original = State(
        id: 'q0',
        label: 'q0',
        position: Vector2.zero(),
      );
      final edited = original.copyWith(
        label: 'start',
        position: Vector2(120, 80),
        isInitial: true,
        isAccepting: true,
      );

      expect(edited, original);
      expect(edited.hashCode, original.hashCode);
      expect({original, edited}, hasLength(1));
    });

    test('finds transitions when given a presentation-only state copy', () {
      final source = State(
        id: 'q0',
        label: 'q0',
        position: Vector2.zero(),
        isInitial: true,
      );
      final destination = State(
        id: 'q1',
        label: 'q1',
        position: Vector2(120, 0),
        isAccepting: true,
      );
      final transition = FSATransition.deterministic(
        id: 't0',
        fromState: source,
        toState: destination,
        symbol: 'a',
      );
      final automaton = FSA(
        id: 'fsa',
        name: 'FSA',
        states: {source, destination},
        transitions: {transition},
        alphabet: const {'a'},
        initialState: source,
        acceptingStates: {destination},
        created: DateTime.utc(2026, 1, 1),
        modified: DateTime.utc(2026, 1, 1),
        bounds: const math.Rectangle(0, 0, 400, 300),
      );

      final editedSource = source.copyWith(
        label: 'start',
        position: Vector2(80, 80),
      );

      expect(
        automaton.getTransitionsFromStateOnSymbol(editedSource, 'a'),
        {transition},
      );
    });
  });

  test('FSA transitions preserve concrete symbols alongside epsilon', () {
    final state = State(
      id: 'q0',
      label: 'q0',
      position: Vector2.zero(),
    );
    final transition = FSATransition(
      id: 'mixed',
      fromState: state,
      toState: state,
      inputSymbols: const {'ε', 'a'},
      controlPoint: Vector2(20, 20),
    );

    expect(transition.validate(), isEmpty);
    expect(transition.isEpsilonTransition, isTrue);
    expect(transition.acceptsSymbol('ε'), isTrue);
    expect(transition.acceptsSymbol('a'), isTrue);
    expect(transition.acceptsAnySymbol({'a'}), isTrue);
    expect(transition.acceptedSymbols, {'ε', 'a'});

    final restored = FSATransition.fromJson(
      transition.toJson(),
      statesById: {'q0': state},
    );
    expect(restored.acceptedSymbols, {'ε', 'a'});
  });
}
