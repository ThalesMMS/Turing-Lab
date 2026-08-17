import 'package:flutter_test/flutter_test.dart';

import 'package:turing_lab/core/models/tm_transition.dart';
import 'package:turing_lab/presentation/providers/pda_editor_provider.dart';
import 'package:turing_lab/presentation/providers/tm_editor_provider.dart';

void main() {
  group('PDAEditorNotifier state mutations', () {
    test('updateStateFlags makes the selected state initial and accepting', () {
      final notifier = PDAEditorNotifier()
        ..addOrUpdateState(id: 'state_0', label: 'q0', x: 0, y: 0)
        ..addOrUpdateState(id: 'state_1', label: 'q1', x: 100, y: 0);

      notifier.updateStateFlags(
        id: 'state_1',
        isInitial: true,
        isAccepting: true,
      );

      final pda = notifier.state.pda!;
      final statesById = {for (final state in pda.states) state.id: state};
      expect(pda.initialState!.id, equals('state_1'));
      expect(statesById['state_0']!.isInitial, isFalse);
      expect(statesById['state_1']!.isInitial, isTrue);
      expect(statesById['state_1']!.isAccepting, isTrue);
      expect(pda.acceptingStates.map((state) => state.id), ['state_1']);
    });

    test('removeState drops attached transitions and preserves an initial', () {
      final notifier = PDAEditorNotifier()
        ..addOrUpdateState(id: 'state_0', label: 'q0', x: 0, y: 0)
        ..addOrUpdateState(id: 'state_1', label: 'q1', x: 100, y: 0)
        ..upsertTransition(
          id: 'transition_0',
          fromStateId: 'state_0',
          toStateId: 'state_1',
          readSymbol: 'a',
          popSymbol: 'Z',
          pushSymbol: 'Z',
          isLambdaInput: false,
          isLambdaPop: false,
          isLambdaPush: false,
        );

      notifier.removeState(id: 'state_0');

      final pda = notifier.state.pda!;
      expect(pda.states.map((state) => state.id), ['state_1']);
      expect(pda.pdaTransitions, isEmpty);
      expect(pda.initialState!.id, equals('state_1'));
    });

    test('moveState rebinds transition endpoints to updated states', () {
      final notifier = PDAEditorNotifier()
        ..addOrUpdateState(id: 'state_0', label: 'q0', x: 0, y: 0)
        ..addOrUpdateState(id: 'state_1', label: 'q1', x: 100, y: 0)
        ..upsertTransition(
          id: 'transition_0',
          fromStateId: 'state_0',
          toStateId: 'state_1',
          readSymbol: 'a',
          popSymbol: 'Z',
          pushSymbol: 'Z',
          isLambdaInput: false,
          isLambdaPop: false,
          isLambdaPush: false,
        );

      notifier.moveState(id: 'state_0', x: 40, y: 80);

      final transition = notifier.state.pda!.pdaTransitions.single;
      expect(transition.fromState.position.x, closeTo(40, 0.0001));
      expect(transition.fromState.position.y, closeTo(80, 0.0001));
    });

    test('rejects invalid transition insertions', () {
      final notifier = PDAEditorNotifier()
        ..addOrUpdateState(id: 'state_0', label: 'q0', x: 0, y: 0)
        ..addOrUpdateState(id: 'state_1', label: 'q1', x: 100, y: 0);

      notifier.upsertTransition(
        id: 'invalid',
        fromStateId: 'state_0',
        toStateId: 'state_1',
        readSymbol: '',
        popSymbol: '',
        pushSymbol: '',
        isLambdaInput: false,
        isLambdaPop: false,
        isLambdaPush: false,
      );

      expect(notifier.state.pda!.pdaTransitions, isEmpty);
    });

    test('preserves an existing transition when an update is invalid', () {
      final notifier = PDAEditorNotifier()
        ..addOrUpdateState(id: 'state_0', label: 'q0', x: 0, y: 0)
        ..addOrUpdateState(id: 'state_1', label: 'q1', x: 100, y: 0)
        ..upsertTransition(
          id: 'transition_0',
          fromStateId: 'state_0',
          toStateId: 'state_1',
          readSymbol: 'a',
          popSymbol: 'Z',
          pushSymbol: 'AZ',
          isLambdaInput: false,
          isLambdaPop: false,
          isLambdaPush: false,
        );

      notifier.upsertTransition(
        id: 'transition_0',
        readSymbol: '',
        isLambdaInput: false,
      );

      final transition = notifier.state.pda!.pdaTransitions.single;
      expect(transition.inputSymbol, 'a');
      expect(transition.label, 'a, Z/AZ');
    });
  });

  group('TMEditorNotifier state mutations', () {
    test('updateStateFlags makes the selected state initial and accepting', () {
      final notifier = TMEditorNotifier()
        ..upsertState(id: 'state_0', label: 'q0', x: 0, y: 0)
        ..upsertState(id: 'state_1', label: 'q1', x: 100, y: 0);

      notifier.updateStateFlags(
        id: 'state_1',
        isInitial: true,
        isAccepting: true,
      );

      final tm = notifier.state.tm!;
      final statesById = {for (final state in tm.states) state.id: state};
      expect(tm.initialState!.id, equals('state_1'));
      expect(statesById['state_0']!.isInitial, isFalse);
      expect(statesById['state_1']!.isInitial, isTrue);
      expect(statesById['state_1']!.isAccepting, isTrue);
      expect(tm.acceptingStates.map((state) => state.id), ['state_1']);
    });

    test('removeState drops attached transitions and preserves an initial', () {
      final notifier = TMEditorNotifier()
        ..upsertState(id: 'state_0', label: 'q0', x: 0, y: 0)
        ..upsertState(id: 'state_1', label: 'q1', x: 100, y: 0)
        ..addOrUpdateTransition(
          id: 'transition_0',
          fromStateId: 'state_0',
          toStateId: 'state_1',
          readSymbol: 'a',
          writeSymbol: 'b',
          direction: TapeDirection.right,
        );

      notifier.removeState(id: 'state_0');

      final tm = notifier.state.tm!;
      expect(tm.states.map((state) => state.id), ['state_1']);
      expect(tm.tmTransitions, isEmpty);
      expect(tm.initialState!.id, equals('state_1'));
    });

    test('removeState retains configured TM after the final state is removed',
        () {
      final notifier = TMEditorNotifier()
        ..upsertState(id: 'state_0', label: 'q0', x: 0, y: 0);
      final configured = notifier.state.tm!.copyWith(
        id: 'configured-tm',
        name: 'Configured TM',
        alphabet: {'a'},
        tapeAlphabet: {'a', '_', 'unused'},
        blankSymbol: '_',
        tapeCount: 3,
      );
      notifier.setTm(configured);

      notifier.removeState(id: 'state_0');

      final tm = notifier.state.tm;
      expect(tm, isNotNull);
      expect(tm!.id, 'configured-tm');
      expect(tm.name, 'Configured TM');
      expect(tm.alphabet, {'a'});
      expect(tm.tapeAlphabet, {'a', '_', 'unused'});
      expect(tm.blankSymbol, '_');
      expect(tm.tapeCount, 3);
      expect(tm.states, isEmpty);
      expect(tm.transitions, isEmpty);
      expect(tm.initialState, isNull);
      expect(tm.acceptingStates, isEmpty);
      expect(notifier.state.states, isEmpty);
      expect(notifier.state.transitions, isEmpty);
    });

    test('moveState rebinds transition endpoints to updated states', () {
      final notifier = TMEditorNotifier()
        ..upsertState(id: 'state_0', label: 'q0', x: 0, y: 0)
        ..upsertState(id: 'state_1', label: 'q1', x: 100, y: 0)
        ..addOrUpdateTransition(
          id: 'transition_0',
          fromStateId: 'state_0',
          toStateId: 'state_1',
          readSymbol: 'a',
          writeSymbol: 'b',
          direction: TapeDirection.right,
        );

      notifier.moveState(id: 'state_0', x: 40, y: 80);

      final transition = notifier.state.tm!.tmTransitions.single;
      expect(transition.fromState.position.x, closeTo(40, 0.0001));
      expect(transition.fromState.position.y, closeTo(80, 0.0001));
    });

    test('rejects invalid transition insertions', () {
      final notifier = TMEditorNotifier()
        ..upsertState(id: 'state_0', label: 'q0', x: 0, y: 0)
        ..upsertState(id: 'state_1', label: 'q1', x: 100, y: 0);

      notifier.addOrUpdateTransition(
        id: 'invalid',
        fromStateId: 'state_0',
        toStateId: 'state_1',
        readSymbol: '',
        writeSymbol: '',
        direction: TapeDirection.right,
      );

      expect(notifier.state.tm!.tmTransitions, isEmpty);
    });

    test('preserves an existing transition when an update is invalid', () {
      final notifier = TMEditorNotifier()
        ..upsertState(id: 'state_0', label: 'q0', x: 0, y: 0)
        ..upsertState(id: 'state_1', label: 'q1', x: 100, y: 0)
        ..addOrUpdateTransition(
          id: 'transition_0',
          fromStateId: 'state_0',
          toStateId: 'state_1',
          readSymbol: 'a',
          writeSymbol: 'b',
          direction: TapeDirection.right,
        );

      notifier.addOrUpdateTransition(
        id: 'transition_0',
        fromStateId: 'state_0',
        toStateId: 'state_1',
        readSymbol: '',
        writeSymbol: 'b',
        direction: TapeDirection.right,
      );

      final transition = notifier.state.tm!.tmTransitions.single;
      expect(transition.readSymbol, 'a');
      expect(transition.label, 'a/b,R');
    });
  });
}
