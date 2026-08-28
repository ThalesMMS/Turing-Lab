import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/data/services/trace_persistence_service.dart';
import 'package:turing_lab/presentation/providers/automaton_simulation_provider.dart';
import 'package:turing_lab/presentation/providers/automaton_state_provider.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  test('simulation completion cannot publish after document replacement',
      () async {
    SharedPreferences.setMockInitialValues({});
    final repository = TracePersistenceService(
      await SharedPreferences.getInstance(),
    );
    final container = ProviderContainer(
      overrides: [
        automatonStateProvider.overrideWith((ref) => AutomatonStateNotifier()),
        automatonSimulationProvider.overrideWith(
          (ref) => AutomatonSimulationNotifier(
            ref: ref,
            tracePersistenceService: repository,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    final state = container.read(automatonStateProvider.notifier);
    state.replaceAutomaton(_loopingDfa('source'));

    final pending = container
        .read(automatonSimulationProvider.notifier)
        .simulateAutomaton('a' * 3000);
    await Future<void>.delayed(Duration.zero);
    state.replaceAutomaton(_loopingDfa('replacement'));
    await pending;

    final result = container.read(automatonSimulationProvider);
    expect(result.simulationResult, isNull);
    expect(result.simulationHistory, isEmpty);
    expect(result.isLoading, isFalse);
  });
}

FSA _loopingDfa(String id) {
  final state = State(
    id: 'q0',
    label: 'q0',
    position: Vector2.zero(),
    isInitial: true,
    isAccepting: true,
  );
  return FSA(
    id: id,
    name: id,
    states: {state},
    transitions: {
      FSATransition.deterministic(
        id: 'loop',
        fromState: state,
        toState: state,
        symbol: 'a',
      ),
    },
    alphabet: {'a'},
    initialState: state,
    acceptingStates: {state},
    created: DateTime.utc(2026),
    modified: DateTime.utc(2026),
    bounds: const math.Rectangle(0, 0, 100, 100),
  );
}
