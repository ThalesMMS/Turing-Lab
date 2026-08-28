import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:turing_lab/core/formal_systems/formal_systems.dart';
import 'package:turing_lab/core/transducers/transducers.dart';
import 'package:turing_lab/data/services/active_session_persistence_service.dart';

void main() {
  test('active-session persistence round trips an external transducer module',
      () async {
    SharedPreferences.setMockInitialValues(const {});
    final preferences = await SharedPreferences.getInstance();
    final registry = FormalSystemRegistry(
      modules: <FormalSystemModule<Object>>[
        TransducerFormalSystemModules.mealy,
      ],
      formats: FormalSystemRegistry.defaultRegistry.formats.formats,
    );
    final service = ActiveSessionPersistenceService(
      preferences,
      registry: registry,
    );
    final machine = _machine();

    await service.saveSession(ActiveSessionSnapshot(
      activeWorkspaceKey: TransducerFormalSystemIds.mealy,
      savedAt: DateTime.utc(2026, 8, 25),
      documents: {TransducerFormalSystemIds.mealy: machine},
    ));
    final restored = await service.loadSession();

    expect(restored?.activeWorkspaceKey, TransducerFormalSystemIds.mealy);
    expect(
      restored
          ?.documentFor<MealyMachine>(TransducerFormalSystemIds.mealy)
          ?.toJson(),
      machine.toJson(),
    );
  });
}

MealyMachine _machine() => MealyMachine(
      id: const TransducerMachineId('session-mealy'),
      name: 'Session Mealy',
      revision: const TransducerRevision(1),
      inputAlphabet: {const TransducerInputSymbol('a')},
      outputAlphabet: {const TransducerOutputSymbol('x')},
      states: const [
        MealyState(
          id: TransducerStateId('q0'),
          label: 'zero',
          position: TransducerPoint(0, 0),
          isInitial: true,
        ),
      ],
      transitions: [
        MealyTransition(
          id: const TransducerTransitionId('t0'),
          from: const TransducerStateId('q0'),
          to: const TransducerStateId('q0'),
          input: const TransducerInputSymbol('a'),
          output: TransducerOutputWord([
            const TransducerOutputSymbol('x'),
          ]),
        ),
      ],
    );
