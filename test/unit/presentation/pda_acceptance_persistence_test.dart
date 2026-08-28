import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turing_lab/core/models/pda.dart';
import 'package:turing_lab/core/models/pda_acceptance_mode.dart';
import 'package:turing_lab/core/models/state.dart' as automaton_state;
import 'package:turing_lab/data/services/active_session_persistence_service.dart';
import 'package:turing_lab/injection/data_providers.dart';
import 'package:turing_lab/presentation/providers/active_session_provider.dart';
import 'package:turing_lab/presentation/providers/pda_editor_provider.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  test('PDA acceptance mode persists and restores with the active session',
      () async {
    SharedPreferences.setMockInitialValues(const {});
    final preferences = await SharedPreferences.getInstance();
    final service = ActiveSessionPersistenceService(preferences);
    final first = _container(preferences);
    await first.read(activeSessionPersistenceProvider).restoreComplete;

    first.read(pdaEditorProvider.notifier)
      ..setPda(_pda())
      ..setAcceptanceMode(PDAAcceptanceMode.both);
    await first.read(activeSessionPersistenceProvider.notifier).flush();

    expect((await service.loadSession())!.pda!.acceptanceMode,
        PDAAcceptanceMode.both);
    first.dispose();

    final restored = _container(preferences);
    addTearDown(restored.dispose);
    await restored.read(activeSessionPersistenceProvider).restoreComplete;

    expect(
      restored.read(pdaEditorProvider).pda?.acceptanceMode,
      PDAAcceptanceMode.both,
    );
  });
}

ProviderContainer _container(SharedPreferences preferences) {
  return ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
  );
}

PDA _pda() {
  final state = automaton_state.State(
    id: 'q0',
    label: 'q0',
    position: Vector2.zero(),
    isInitial: true,
  );
  return PDA(
    id: 'persisted-policy',
    name: 'Persisted policy',
    states: {state},
    transitions: const {},
    alphabet: const {},
    initialState: state,
    acceptingStates: const {},
    created: DateTime.utc(2026),
    modified: DateTime.utc(2026),
    bounds: const math.Rectangle<double>(0, 0, 400, 300),
    stackAlphabet: const {'Z'},
  );
}
