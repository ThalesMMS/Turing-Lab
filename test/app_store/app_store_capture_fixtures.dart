//
//  app_store_capture_fixtures.dart
//  Turing Lab
//
//  Offline fixtures rendered by the App Store captures. Timestamps are frozen
//  so a rerun of the same slot produces the same model and therefore the same
//  pixels.
//
//  Thales Matheus Mendonça Santos - August 2026
//
import 'dart:math' as math;

import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/state.dart' as automaton_state;
import 'package:vector_math/vector_math_64.dart';

/// Deterministic models used by the screenshot matrix.
class AppStoreCaptureFixtures {
  const AppStoreCaptureFixtures._();

  /// Frozen clock shared by every fixture so captures never embed run time.
  static final DateTime clock = DateTime.utc(2026, 1, 1, 12);

  /// Two-state DFA accepting strings that end with `a`.
  static FSA endsWithA() {
    final q0 = automaton_state.State(
      id: 'q0',
      label: 'q0',
      position: Vector2(180, 220),
      isInitial: true,
    );
    final q1 = automaton_state.State(
      id: 'q1',
      label: 'q1',
      position: Vector2(560, 220),
      isAccepting: true,
    );

    return FSA(
      id: 'app_store_fsa',
      name: 'Ends with a',
      states: {q0, q1},
      transitions: {
        FSATransition.deterministic(
          id: 't0',
          fromState: q0,
          toState: q1,
          symbol: 'a',
        ),
        FSATransition.deterministic(
          id: 't1',
          fromState: q0,
          toState: q0,
          symbol: 'b',
        ),
        FSATransition.deterministic(
          id: 't2',
          fromState: q1,
          toState: q1,
          symbol: 'a',
        ),
        FSATransition.deterministic(
          id: 't3',
          fromState: q1,
          toState: q0,
          symbol: 'b',
        ),
      },
      alphabet: {'a', 'b'},
      initialState: q0,
      acceptingStates: {q1},
      created: clock,
      modified: clock,
      bounds: const math.Rectangle<double>(0, 0, 900, 520),
    );
  }
}
