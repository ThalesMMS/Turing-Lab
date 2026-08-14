import 'dart:math' as math;

import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:vector_math/vector_math_64.dart';

FSA createNFAWithInvalidAcceptingState() {
  final q0 = State(
    id: 'q0',
    label: 'q0',
    position: Vector2(0, 0),
    isInitial: true,
  );
  final q1 = State(
    id: 'q1',
    label: 'q1',
    position: Vector2(100, 0),
  );
  final missingAccept = State(
    id: 'missing',
    label: 'missing',
    position: Vector2(200, 0),
    isAccepting: true,
  );

  return FSA(
    id: 'invalid_nfa',
    name: 'Invalid NFA',
    states: {q0, q1},
    transitions: {
      FSATransition.epsilon(
        id: 'eps_q0_q1',
        fromState: q0,
        toState: q1,
      ),
    },
    alphabet: {'a'},
    initialState: q0,
    acceptingStates: {missingAccept},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 200, 100),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}
