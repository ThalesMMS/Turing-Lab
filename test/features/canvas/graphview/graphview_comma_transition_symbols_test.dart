import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/state.dart' as automaton_state;
import 'package:turing_lab/features/canvas/graphview/graphview_canvas_controller.dart';
import 'package:turing_lab/presentation/providers/automaton_state_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('comma-separated FSA labels persist as independent transitions', () {
    final q0 = automaton_state.State(
      id: 'q0',
      label: 'q0',
      position: Vector2.zero(),
      isInitial: true,
      isAccepting: false,
    );
    final q1 = automaton_state.State(
      id: 'q1',
      label: 'q1',
      position: Vector2(160, 0),
      isInitial: false,
      isAccepting: true,
    );
    final notifier = AutomatonStateNotifier()
      ..updateAutomaton(
        FSA(
          id: 'comma-transition-regression',
          name: 'Comma transition regression',
          states: {q0, q1},
          transitions: const {},
          alphabet: const {},
          initialState: q0,
          acceptingStates: {q1},
          created: DateTime.utc(2026, 9, 1),
          modified: DateTime.utc(2026, 9, 1),
          bounds: const math.Rectangle<double>(0, 0, 400, 300),
          panOffset: Vector2.zero(),
          zoomLevel: 1,
        ),
      );
    final controller = GraphViewCanvasController(
      automatonStateNotifier: notifier,
    );
    addTearDown(controller.dispose);

    controller.addOrUpdateTransition(
      fromStateId: 'q0',
      toStateId: 'q1',
      label: ' a, b ',
      transitionId: 'transition_0',
    );

    final automaton = notifier.currentAutomaton!;
    final transitions = automaton.transitions.whereType<FSATransition>().toList();

    expect(transitions, hasLength(2));
    expect(transitions.map((transition) => transition.id).toSet(), hasLength(2));
    expect(
      transitions.map((transition) => transition.inputSymbols),
      unorderedEquals([
        {'a'},
        {'b'},
      ]),
    );
    expect(
      transitions.every((transition) => transition.inputSymbols.length == 1),
      isTrue,
    );
    expect(
      transitions.any((transition) => transition.inputSymbols.contains('a,b')),
      isFalse,
    );
    expect(automaton.alphabet, {'a', 'b'});
  });
}
