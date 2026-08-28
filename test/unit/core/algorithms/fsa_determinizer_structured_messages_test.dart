import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/fsa_determinizer.dart';
import 'package:turing_lab/core/algorithms/fsa_determinizer_messages.dart';
import 'package:turing_lab/core/messages/structured_message.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  test('determinization failure preserves its structured contract', () {
    final message = FsaDeterminizerMessages.failed('A');

    expect(message.stableCode, 'algorithm.fsa-determinizer.failed');
    expect(message.category, StructuredMessageCategory.conversion);
    expect(message.severity, StructuredMessageSeverity.error);
    expect(message.arguments, hasLength(1));
    final automaton = message.arguments['automaton']!;
    expect(automaton.kind, StructuredMessageArgumentKind.literal);
    expect(automaton.role, 'automaton-label');
    expect(automaton.value, 'A');
  });

  test('determinizer returns the same locale-neutral failure payload', () {
    final initial = State(
      id: 'q0',
      label: 'q0',
      position: Vector2.zero(),
      isInitial: true,
    );
    final acceptingOutside = State(
      id: 'q1',
      label: 'q1',
      position: Vector2(40, 0),
      isAccepting: true,
    );
    final otherBranch = State(id: 'q2', label: 'q2', position: Vector2(40, 40));
    final result = FSADeterminizer.determinizeIfNeeded(
      FSA(
        id: 'invalid-nfa',
        name: 'Invalid NFA',
        states: {initial, otherBranch},
        transitions: {
          FSATransition.deterministic(
            id: 't0',
            fromState: initial,
            toState: acceptingOutside,
            symbol: 'a',
          ),
          FSATransition.deterministic(
            id: 't1',
            fromState: initial,
            toState: otherBranch,
            symbol: 'a',
          ),
        },
        alphabet: {'a'},
        initialState: initial,
        acceptingStates: {acceptingOutside},
        created: DateTime.utc(2026),
        modified: DateTime.utc(2026),
        bounds: const math.Rectangle(0, 0, 100, 100),
      ),
      'A',
    );

    expect(result.isFailure, isTrue);
    expect(result.error, 'algorithm.fsa-determinizer.failed');
    expect(result.structuredError, FsaDeterminizerMessages.failed('A'));
  });
}
