import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turing_lab/core/models/pda.dart';
import 'package:turing_lab/core/models/simulation_step.dart';
import 'package:turing_lab/core/models/state.dart' as automaton_state;
import 'package:turing_lab/presentation/providers/pda_editor_provider.dart';
import 'package:turing_lab/presentation/providers/pda_simulation_provider.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  group('PDASimulationState copyWith', () {
    test('can clear nullable PDA and result fields', () {
      final state = PDASimulationState(
        pda: _pda('old'),
        result: _result(),
        currentStepIndex: 1,
      );

      final cleared = state.copyWith(
        pda: null,
        result: null,
        currentStepIndex: 0,
      );

      expect(cleared.pda, isNull);
      expect(cleared.result, isNull);
      expect(cleared.currentStepIndex, equals(0));
    });
  });

  group('PDASimulationNotifier', () {
    test('setPda clears stale simulation result and step index', () {
      final notifier = PDASimulationNotifier();
      addTearDown(notifier.dispose);

      notifier.setPda(_pda('old'));
      notifier.setResult(_result(), currentStepIndex: 1);

      notifier.setPda(_pda('new'));

      expect(notifier.state.pda!.id, equals('new'));
      expect(notifier.state.result, isNull);
      expect(notifier.state.currentStepIndex, equals(0));
    });

    test('clear drops the PDA and stale simulation cursor', () {
      final notifier = PDASimulationNotifier();
      addTearDown(notifier.dispose);
      notifier.setPda(_pda('old'));
      notifier.setResult(_result(), currentStepIndex: 1);

      notifier.clear();

      expect(notifier.state.pda, isNull);
      expect(notifier.state.result, isNull);
      expect(notifier.state.currentStepIndex, 0);
    });

    test('acceptance mode stays synchronized with the editor document', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final source = _pda('mode');
      container.read(pdaEditorProvider.notifier).setPda(source);
      final notifier = container.read(pdaSimulationProvider.notifier)
        ..setPda(source)
        ..setAcceptanceMode(PDAAcceptanceMode.emptyStack);

      expect(notifier.state.mode, PDAAcceptanceMode.emptyStack);
      expect(notifier.state.pda?.acceptanceMode, PDAAcceptanceMode.emptyStack);
      expect(
        container.read(pdaEditorProvider).pda?.acceptanceMode,
        PDAAcceptanceMode.emptyStack,
      );
      expect(
        container
            .read(pdaEditorProvider)
            .pda!
            .modified
            .isAfter(source.modified),
        isTrue,
      );
      final changed = container.read(pdaEditorProvider).pda!;
      expect(changed.created, source.created);

      notifier.setAcceptanceMode(PDAAcceptanceMode.emptyStack);

      expect(container.read(pdaEditorProvider).pda!.modified, changed.modified);
      expect(notifier.state.result, isNull);
    });

    test('canvas updates preserve document stack and acceptance settings', () {
      final source = _pda('canvas').copyWith(
        stackAlphabet: const {'BOTTOM'},
        initialStackSymbol: 'BOTTOM',
        acceptanceMode: PDAAcceptanceMode.both,
      );
      final notifier = PDAEditorNotifier()..setPda(source);
      addTearDown(notifier.dispose);

      notifier.updateFromCanvas(
        states: source.states.toList(),
        transitions: source.pdaTransitions.toList(),
      );

      expect(notifier.currentPda?.initialStackSymbol, 'BOTTOM');
      expect(notifier.currentPda?.stackAlphabet, contains('BOTTOM'));
      expect(notifier.currentPda?.acceptanceMode, PDAAcceptanceMode.both);
    });

    test('canvas updates preserve a document with no final states', () {
      final original = _pda('empty-stack-only');
      final state = original.states.single.copyWith(isAccepting: false);
      final source = original.copyWith(
        states: {state},
        initialState: state,
        acceptingStates: const {},
        acceptanceMode: PDAAcceptanceMode.emptyStack,
      );
      final notifier = PDAEditorNotifier()..setPda(source);
      addTearDown(notifier.dispose);

      notifier.updateFromCanvas(
        states: source.states.toList(),
        transitions: source.pdaTransitions.toList(),
      );

      expect(notifier.currentPda?.acceptingStates, isEmpty);
      expect(
        notifier.currentPda?.acceptanceMode,
        PDAAcceptanceMode.emptyStack,
      );
    });

    test('fresh canvas state does not invent a final state', () {
      final canvasState = automaton_state.State(
        id: 'fresh',
        label: 'fresh',
        position: Vector2.zero(),
        isInitial: true,
      );
      final notifier = PDAEditorNotifier();
      addTearDown(notifier.dispose);

      notifier.updateFromCanvas(
        states: [canvasState],
        transitions: const [],
      );

      expect(notifier.currentPda?.acceptingStates, isEmpty);
      expect(
        notifier.currentPda?.acceptanceMode,
        PDAAcceptanceMode.finalState,
      );
    });

    test('empty canvas clears the document without inventing states', () {
      final notifier = PDAEditorNotifier()..setPda(_pda('existing'));
      addTearDown(notifier.dispose);

      notifier.updateFromCanvas(states: const [], transitions: const []);

      expect(notifier.currentPda, isNull);
    });
  });
}

PDA _pda(String id) {
  final now = DateTime(2026, 1, 1);
  final state = automaton_state.State(
    id: 'q0',
    label: 'q0',
    position: Vector2.zero(),
    isInitial: true,
    isAccepting: true,
  );

  return PDA(
    id: id,
    name: 'PDA $id',
    states: {state},
    transitions: const {},
    alphabet: const {'a'},
    initialState: state,
    acceptingStates: {state},
    created: now,
    modified: now,
    bounds: const math.Rectangle<double>(0, 0, 400, 300),
    stackAlphabet: const {'Z'},
  );
}

PDASimulationResult _result() {
  return PDASimulationResult.success(
    inputString: 'a',
    steps: const [
      SimulationStep(currentState: 'q0', remainingInput: 'a', stepNumber: 0),
      SimulationStep(currentState: 'q0', remainingInput: '', stepNumber: 1),
    ],
    executionTime: const Duration(milliseconds: 1),
  );
}
