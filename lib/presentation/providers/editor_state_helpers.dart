//
//  editor_state_helpers.dart
//  Turing Lab
//
//  Funções puras compartilhadas por editores baseados em estados de autômatos.
//  Mantêm as regras comuns de mutação de State fora dos notifiers PDA/TM sem
//  esconder as diferenças de transições de pilha e fita.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:vector_math/vector_math_64.dart';
import 'package:collection/collection.dart';

import '../../core/models/state.dart';

const DeepCollectionEquality _stateValueEquality = DeepCollectionEquality();

bool _hasStateValueChanged(State previous, State next) {
  return !_stateValueEquality.equals(previous.toJson(), next.toJson());
}

class EditorStateMutation {
  const EditorStateMutation({
    required this.states,
    required this.targetFound,
    required this.changedStates,
  });

  final List<State> states;
  final bool targetFound;
  final List<State> changedStates;

  bool get hasChanges => changedStates.isNotEmpty;

  Map<String, State> get statesById => statesByIdFrom(states);
}

Map<String, State> statesByIdFrom(Iterable<State> states) {
  return {for (final state in states) state.id: state};
}

EditorStateMutation upsertEditorState({
  required Iterable<State> states,
  required String id,
  required String label,
  required Vector2 position,
  bool? isInitial,
  bool? isAccepting,
  bool initialWhenEmpty = true,
  bool normalizeInitial = false,
}) {
  final nextStates = states.toList();
  final index = nextStates.indexWhere((state) => state.id == id);
  final existing = index >= 0 ? nextStates[index] : null;
  final hadInitial = nextStates.any((state) => state.isInitial);
  final resolvedInitial = isInitial ??
      existing?.isInitial ??
      (initialWhenEmpty && !hadInitial && index == -1);
  final resolvedAccepting = isAccepting ?? existing?.isAccepting ?? false;

  final updated = (existing ??
          State(
            id: id,
            label: label,
            position: position,
            isInitial: resolvedInitial,
            isAccepting: resolvedAccepting,
          ))
      .copyWith(
    label: label,
    position: position,
    isInitial: resolvedInitial,
    isAccepting: resolvedAccepting,
  );

  if (index >= 0) {
    nextStates[index] = updated;
  } else {
    nextStates.add(updated);
  }

  return _normalizeInitialState(
    states: nextStates,
    targetFound: index >= 0,
    changedStateIds: {id},
    normalizeInitial: normalizeInitial,
    fallbackInitial: normalizeInitial,
  );
}

EditorStateMutation updateEditorStateById({
  required Iterable<State> states,
  required String id,
  required State Function(State state) update,
}) {
  var targetFound = false;
  final changedStateIds = <String>{};
  final nextStates = [
    for (final state in states)
      if (state.id == id)
        () {
          targetFound = true;
          final updated = update(state);
          if (_hasStateValueChanged(state, updated)) {
            changedStateIds.add(updated.id);
          }
          return updated;
        }()
      else
        state,
  ];

  return EditorStateMutation(
    states: nextStates,
    targetFound: targetFound,
    changedStates: [
      for (final state in nextStates)
        if (changedStateIds.contains(state.id)) state,
    ],
  );
}

EditorStateMutation updateEditorStateFlags({
  required Iterable<State> states,
  required String id,
  bool? isInitial,
  bool? isAccepting,
  bool fallbackInitial = false,
}) {
  final source = states.toList();
  final targetFound = source.any((state) => state.id == id);
  if (isInitial == null && isAccepting == null) {
    return EditorStateMutation(
      states: source,
      targetFound: targetFound,
      changedStates: const [],
    );
  }

  final changedStateIds = <String>{};
  final nextStates = <State>[];

  for (final state in source) {
    var newInitial = state.isInitial;
    var newAccepting = state.isAccepting;

    if (state.id == id) {
      newInitial = isInitial ?? state.isInitial;
      newAccepting = isAccepting ?? state.isAccepting;
    } else if (isInitial == true) {
      newInitial = false;
    }

    final updated = state.copyWith(
      isInitial: newInitial,
      isAccepting: newAccepting,
    );
    if (_hasStateValueChanged(state, updated)) {
      changedStateIds.add(updated.id);
    }
    nextStates.add(updated);
  }

  final normalized = _normalizeInitialState(
    states: nextStates,
    targetFound: targetFound,
    changedStateIds: changedStateIds,
    normalizeInitial: false,
    fallbackInitial: fallbackInitial,
  );

  return normalized;
}

EditorStateMutation removeEditorStateById({
  required Iterable<State> states,
  required String id,
  bool fallbackInitial = false,
}) {
  var targetFound = false;
  final remaining = <State>[];
  for (final state in states) {
    if (state.id == id) {
      targetFound = true;
    } else {
      remaining.add(state);
    }
  }

  return _normalizeInitialState(
    states: remaining,
    targetFound: targetFound,
    changedStateIds: const {},
    normalizeInitial: false,
    fallbackInitial: fallbackInitial,
  );
}

List<State> ensureInitialState(Iterable<State> states) {
  return _normalizeInitialState(
    states: states.toList(),
    targetFound: true,
    changedStateIds: const {},
    normalizeInitial: false,
    fallbackInitial: true,
  ).states;
}

bool transitionTouchesState({
  required String stateId,
  required String fromStateId,
  required String toStateId,
}) {
  return fromStateId == stateId || toStateId == stateId;
}

EditorStateMutation _normalizeInitialState({
  required List<State> states,
  required bool targetFound,
  required Set<String> changedStateIds,
  required bool normalizeInitial,
  required bool fallbackInitial,
}) {
  final nextStates = states.toList();
  final changedIds = {...changedStateIds};

  if (normalizeInitial) {
    final initialIds = nextStates
        .where((state) => state.isInitial)
        .map((state) => state.id)
        .toList(growable: false);
    if (initialIds.length > 1) {
      final retainedInitialId = initialIds.last;
      for (var i = 0; i < nextStates.length; i++) {
        final state = nextStates[i];
        if (state.isInitial && state.id != retainedInitialId) {
          final updated = state.copyWith(isInitial: false);
          nextStates[i] = updated;
          changedIds.add(updated.id);
        }
      }
    }
  }

  if (fallbackInitial &&
      nextStates.isNotEmpty &&
      !nextStates.any((state) => state.isInitial)) {
    final updated = nextStates.first.copyWith(isInitial: true);
    nextStates[0] = updated;
    changedIds.add(updated.id);
  }

  return EditorStateMutation(
    states: nextStates,
    targetFound: targetFound,
    changedStates: [
      for (final state in nextStates)
        if (changedIds.contains(state.id)) state,
    ],
  );
}
