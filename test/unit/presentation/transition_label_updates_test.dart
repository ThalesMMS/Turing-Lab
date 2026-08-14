//
//  transition_label_updates_test.dart
//  Turing Lab
//
//  Testes voltados aos providers de edição de transições, assegurando que
//  autômatos finitos, PDAs e máquinas de Turing recebam atualizações consistentes
//  de rótulos, símbolos e parâmetros específicos de cada modelo durante as
//  operações de edição em tempo real.
//
//  Thales Matheus Mendonça Santos - October 2025
//

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/state.dart' as automaton_state;
import 'package:turing_lab/core/models/tm_transition.dart';
import 'package:turing_lab/presentation/providers/automaton_state_provider.dart';
import 'package:turing_lab/presentation/providers/pda_editor_provider.dart';
import 'package:turing_lab/presentation/providers/tm_editor_provider.dart';

void main() {
  group('Transition updates', () {
    test(
      'AutomatonStateNotifier.updateTransitionLabel updates labels and symbols',
      () {
        final provider = AutomatonStateNotifier();

        final stateA = automaton_state.State(
          id: 'q0',
          label: 'q0',
          position: Vector2.zero(),
          isInitial: true,
          isAccepting: false,
        );
        final stateB = automaton_state.State(
          id: 'q1',
          label: 'q1',
          position: Vector2(100, 0),
          isInitial: false,
          isAccepting: true,
        );
        final transition = FSATransition(
          id: 't0',
          fromState: stateA,
          toState: stateB,
          inputSymbols: const {'a'},
          label: 'a',
        );
        final automaton = FSA(
          id: 'fa',
          name: 'test',
          states: {stateA, stateB},
          transitions: {transition},
          alphabet: {'a'},
          initialState: stateA,
          acceptingStates: {stateB},
          created: DateTime.now(),
          modified: DateTime.now(),
          bounds: const math.Rectangle(0, 0, 400, 300),
        );

        provider.updateAutomaton(automaton);
        provider.updateTransitionLabel(id: 't0', label: 'b,c');

        final updated = provider.state.currentAutomaton!;
        final updatedTransition = updated.transitions
            .whereType<FSATransition>()
            .firstWhere((element) => element.id == 't0');

        expect(updatedTransition.label, 'b,c');
        expect(updatedTransition.inputSymbols, {'b', 'c'});
        expect(updated.alphabet.containsAll({'a', 'b', 'c'}), isTrue);
      },
    );

    test('TMEditorNotifier.updateTransitionOperations rewrites operations', () {
      final notifier = TMEditorNotifier();

      notifier.upsertState(id: 'q0', label: 'q0', x: 0, y: 0);
      notifier.upsertState(id: 'q1', label: 'q1', x: 100, y: 0);
      notifier.addOrUpdateTransition(
        id: 't0',
        fromStateId: 'q0',
        toStateId: 'q1',
        readSymbol: 'a',
        writeSymbol: 'b',
        direction: TapeDirection.right,
      );

      notifier.updateTransitionOperations(
        id: 't0',
        readSymbol: 'x',
        writeSymbol: 'y',
        direction: TapeDirection.left,
      );

      final tm = notifier.state.tm!;
      final transition = tm.transitions.whereType<TMTransition>().firstWhere(
            (element) => element.id == 't0',
          );

      expect(transition.readSymbol, 'x');
      expect(transition.writeSymbol, 'y');
      expect(transition.direction, TapeDirection.left);
      expect(transition.label, 'x/y,L');
    });

    test('PDAEditorNotifier.upsertTransition updates stack operations', () {
      final notifier = PDAEditorNotifier();

      notifier.addOrUpdateState(id: 'q0', label: 'q0', x: 0, y: 0);
      notifier.addOrUpdateState(id: 'q1', label: 'q1', x: 100, y: 0);
      notifier.upsertTransition(
        id: 't0',
        fromStateId: 'q0',
        toStateId: 'q1',
        readSymbol: 'a',
        popSymbol: 'Z',
        pushSymbol: 'AZ',
        isLambdaInput: false,
        isLambdaPop: false,
        isLambdaPush: false,
      );

      notifier.upsertTransition(
        id: 't0',
        readSymbol: '',
        popSymbol: '',
        pushSymbol: '',
        isLambdaInput: true,
        isLambdaPop: true,
        isLambdaPush: true,
      );

      final pda = notifier.state.pda!;
      final transition = pda.pdaTransitions.firstWhere(
        (element) => element.id == 't0',
      );

      expect(transition.isLambdaInput, isTrue);
      expect(transition.isLambdaPop, isTrue);
      expect(transition.isLambdaPush, isTrue);
      expect(transition.label, 'λ, λ/λ');
    });
  });
}
