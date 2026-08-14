//
//  fsa_layout_service.dart
//  Turing Lab
//
//  Applies layout operations directly to current FSA models.
//
//  Thales Matheus Mendonça Santos - June 2026
//
import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart';

import '../../core/models/fsa.dart';
import '../../core/models/state.dart';

class FsaLayoutService {
  const FsaLayoutService();

  static final Vector2 _canvasSize = Vector2(800, 600);
  static const double _layoutPadding = 50;

  FSA applyAutoLayout(FSA fsa) {
    final states = fsa.states.toList();
    if (states.isEmpty) {
      return fsa;
    }

    final center = Vector2(_canvasSize.x / 2, _canvasSize.y / 2);
    final radius = math.min(center.x, center.y) - _layoutPadding;
    final angleStep = (2 * math.pi) / states.length;

    final updatedStatesById = <String, State>{};
    for (var i = 0; i < states.length; i++) {
      final state = states[i];
      final angle = i * angleStep;
      final position = Vector2(
        center.x + radius * math.cos(angle),
        center.y + radius * math.sin(angle),
      );
      updatedStatesById[state.id] = state.copyWith(position: position);
    }

    final updatedStates = updatedStatesById.values.toSet();
    final updatedTransitions = fsa.transitions.map((transition) {
      final fromState =
          updatedStatesById[transition.fromState.id] ?? transition.fromState;
      final toState =
          updatedStatesById[transition.toState.id] ?? transition.toState;
      return transition.copyWith(fromState: fromState, toState: toState);
    }).toSet();

    final initialStateId = fsa.initialState?.id;
    final updatedInitialState = initialStateId != null
        ? updatedStatesById[initialStateId]
        : updatedStates.where((state) => state.isInitial).firstOrNull;
    final updatedAcceptingStates =
        updatedStates.where((state) => state.isAccepting).toSet();

    return fsa.copyWith(
      states: updatedStates,
      transitions: updatedTransitions,
      initialState: updatedInitialState,
      acceptingStates: updatedAcceptingStates,
      modified: DateTime.now(),
    );
  }
}
