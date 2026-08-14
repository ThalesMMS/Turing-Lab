import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:turing_lab/core/models/state.dart' as automaton_state;
import 'package:turing_lab/presentation/providers/editor_state_helpers.dart';

automaton_state.State _state(
  String id, {
  String? label,
  bool isInitial = false,
  bool isAccepting = false,
  double x = 0,
  double y = 0,
}) {
  return automaton_state.State(
    id: id,
    label: label ?? id,
    position: Vector2(x, y),
    isInitial: isInitial,
    isAccepting: isAccepting,
  );
}

void main() {
  group('editor state helpers', () {
    test('upsertEditorState inserts new state with first-state initial flag',
        () {
      final update = upsertEditorState(
        states: const [],
        id: 'state_0',
        label: 'q0',
        position: Vector2(12, 24),
      );

      expect(update.targetFound, isFalse);
      expect(update.hasChanges, isTrue);
      expect(update.states, hasLength(1));
      expect(update.states.single.id, equals('state_0'));
      expect(update.states.single.label, equals('q0'));
      expect(update.states.single.isInitial, isTrue);
      expect(update.states.single.isAccepting, isFalse);
      expect(update.states.single.position.x, closeTo(12, 0.0001));
      expect(update.states.single.position.y, closeTo(24, 0.0001));
      expect(update.changedStates, contains(update.states.single));
    });

    test('upsertEditorState normalizes competing initial states', () {
      final update = upsertEditorState(
        states: [
          _state('state_0', isInitial: true),
          _state('state_1'),
        ],
        id: 'state_1',
        label: 'renamed',
        position: Vector2(50, 60),
        isInitial: true,
        isAccepting: true,
        normalizeInitial: true,
      );

      final statesById = update.statesById;
      expect(statesById['state_0']!.isInitial, isFalse);
      expect(statesById['state_1']!.isInitial, isTrue);
      expect(statesById['state_1']!.isAccepting, isTrue);
      expect(statesById['state_1']!.label, equals('renamed'));
      expect(
          update.changedStates.map((state) => state.id),
          unorderedEquals([
            'state_0',
            'state_1',
          ]));
    });

    test('updateEditorStateFlags clears previous initial and keeps acceptance',
        () {
      final update = updateEditorStateFlags(
        states: [
          _state('state_0', isInitial: true),
          _state('state_1', isAccepting: false),
        ],
        id: 'state_1',
        isInitial: true,
        isAccepting: true,
      );

      final statesById = update.statesById;
      expect(update.targetFound, isTrue);
      expect(statesById['state_0']!.isInitial, isFalse);
      expect(statesById['state_1']!.isInitial, isTrue);
      expect(statesById['state_1']!.isAccepting, isTrue);
    });

    test('ensureInitialState marks the first state when none is initial', () {
      final states = ensureInitialState([
        _state('state_0'),
        _state('state_1', isAccepting: true),
      ]);

      expect(states.first.isInitial, isTrue);
      expect(states.last.isInitial, isFalse);
      expect(states.last.isAccepting, isTrue);
    });

    test('removeEditorStateById reports removal and transition references', () {
      final removal = removeEditorStateById(
        states: [
          _state('state_0'),
          _state('state_1'),
        ],
        id: 'state_1',
      );

      expect(removal.targetFound, isTrue);
      expect(removal.states.map((state) => state.id), ['state_0']);
      expect(
        transitionTouchesState(
          stateId: 'state_1',
          fromStateId: 'state_0',
          toStateId: 'state_1',
        ),
        isTrue,
      );
      expect(
        transitionTouchesState(
          stateId: 'state_1',
          fromStateId: 'state_0',
          toStateId: 'state_2',
        ),
        isFalse,
      );
    });
  });
}
