import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/pda.dart';
import 'package:turing_lab/core/models/simulation_step.dart';
import 'package:turing_lab/core/models/state.dart' as automaton_state;
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
