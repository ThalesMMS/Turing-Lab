//
//  state_renamer.dart
//  Turing Lab
//
//  Utilitário para renomear rótulos de estados em autômatos finitos após
//  conversões algorítmicas, substituindo IDs internos por nomes legíveis
//  como q0, q1, q2... e aplicando layout circular para evitar sobreposição.
//
//  Thales Matheus Mendonça Santos - February 2026
//
import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart';
import '../models/fsa.dart';
import '../models/state.dart';
import '../models/fsa_transition.dart';

/// Renames state labels in an FSA to clean q0, q1, q2... format
/// and optionally applies circular layout to avoid overlap.
class StateRenamer {
  /// Renames all state labels to q0, q1, q2... (initial state = q0).
  /// Also applies circular positioning to prevent overlap.
  static FSA renameAndLayout(FSA fsa) {
    if (fsa.states.isEmpty) return fsa;

    // Determine label assignment order: initial state gets q0
    final orderedStates = <State>[];
    if (fsa.initialState != null) {
      orderedStates.add(fsa.initialState!);
    }
    for (final state in fsa.states) {
      if (state != fsa.initialState) {
        orderedStates.add(state);
      }
    }

    // Build old-id -> new-state mapping
    final stateMap = <String, State>{};
    final n = orderedStates.length;
    final radius = math.max(120.0, n * 40.0);
    const centerX = 400.0;
    const centerY = 300.0;
    final initialStateId = fsa.initialState?.id;
    final acceptingStateIds = fsa.acceptingStates.map((s) => s.id).toSet();

    for (int i = 0; i < n; i++) {
      final oldState = orderedStates[i];
      final angle = (2 * math.pi * i) / n;
      final position = Vector2(
        centerX + radius * math.cos(angle),
        centerY + radius * math.sin(angle),
      );
      stateMap[oldState.id] = oldState.copyWith(
        label: 'q$i',
        position: position,
        isInitial: oldState.id == initialStateId,
        isAccepting: acceptingStateIds.contains(oldState.id),
      );
    }

    // Remap states
    final newStates = stateMap.values.toSet();

    // Remap transitions
    final newTransitions = fsa.transitions.map((t) {
      if (t is FSATransition) {
        return t.copyWith(
          fromState: stateMap[t.fromState.id] ?? t.fromState,
          toState: stateMap[t.toState.id] ?? t.toState,
        );
      }
      return t;
    }).toSet();

    // Remap initial and accepting states
    final newInitialState =
        fsa.initialState != null ? stateMap[fsa.initialState!.id] : null;
    final newAcceptingStates =
        fsa.acceptingStates.map((s) => stateMap[s.id] ?? s).toSet();

    return fsa.copyWith(
      states: newStates,
      transitions: newTransitions,
      initialState: newInitialState,
      acceptingStates: newAcceptingStates,
    );
  }
}
