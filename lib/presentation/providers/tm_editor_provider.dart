//
//  tm_editor_provider.dart
//  Turing Lab
//
//  Manages Turing-machine editor state on the canvas, converting user
//  interactions into immutable structures that preserve states,
//  transitions, tape symbols, and movement directions while providing
//  supporting metadata for simulators, exporters, and visual highlights.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector_math/vector_math_64.dart';

import '../../core/models/state.dart';
import '../../core/models/tm.dart';
import '../../core/models/tm_acceptance.dart';
import '../../core/models/tm_transition.dart';
import '../../core/models/transition.dart';
import 'editor_state_helpers.dart';

/// Holds the current TM being edited in the canvas together with metadata
/// that other widgets might be interested in (like tape symbol usage and
/// highlighting information).
class TMEditorState {
  /// The TM built from the canvas contents.
  final TM? tm;

  /// Unique tape symbols discovered while building the TM.
  final Set<String> tapeSymbols;

  /// Directions that appear in transitions.
  final Set<String> moveDirections;

  /// Identifiers of transitions that participate in nondeterministic choices.
  final Set<String> nondeterministicTransitionIds;

  /// States currently rendered on the canvas.
  final List<State> states;

  /// TM transitions currently rendered on the canvas.
  final List<TMTransition> transitions;

  /// Monotonic identity for interoperability sidecars and import rollback.
  final int documentGeneration;

  const TMEditorState({
    this.tm,
    this.tapeSymbols = const {},
    this.moveDirections = const {},
    this.nondeterministicTransitionIds = const {},
    this.states = const [],
    this.transitions = const [],
    this.documentGeneration = 0,
  });

  TMEditorState copyWith({
    TM? tm,
    Set<String>? tapeSymbols,
    Set<String>? moveDirections,
    Set<String>? nondeterministicTransitionIds,
    List<State>? states,
    List<TMTransition>? transitions,
    int? documentGeneration,
  }) {
    return TMEditorState(
      tm: tm ?? this.tm,
      tapeSymbols: tapeSymbols ?? this.tapeSymbols,
      moveDirections: moveDirections ?? this.moveDirections,
      nondeterministicTransitionIds:
          nondeterministicTransitionIds ?? this.nondeterministicTransitionIds,
      states: states ?? this.states,
      transitions: transitions ?? this.transitions,
      documentGeneration: documentGeneration ?? this.documentGeneration,
    );
  }
}

/// Riverpod notifier responsible for maintaining the TM that is edited on the canvas.
class TMEditorNotifier extends StateNotifier<TMEditorState> {
  TMEditorNotifier() : super(const TMEditorState());

  final List<State> _states = [];
  final List<TMTransition> _transitions = [];

  /// Current TM snapshot for collaborators that should not read the protected
  /// StateNotifier state directly.
  TM? get currentTm => state.tm;

  /// Restores an exact editor snapshot after a failed document replacement.
  void restoreDocumentCheckpoint(TMEditorState checkpoint) {
    final tm = checkpoint.tm;
    if (tm == null) {
      _states.clear();
      _transitions.clear();
    } else {
      _replaceCollections(tm);
    }
    state = checkpoint;
  }

  /// Updates the notifier using the raw state and transition collections
  /// maintained by the canvas and returns the resulting TM.
  TM? updateFromCanvas({
    required List<State> states,
    required List<TMTransition> transitions,
  }) {
    _states
      ..clear()
      ..addAll(states.map((state) => state.copyWith()));
    _transitions
      ..clear()
      ..addAll(transitions.map((transition) => transition.copyWith()));

    return _rebuildState();
  }

  /// Adds a new state or updates an existing one using the provided data.
  TM? upsertState({
    required String id,
    required String label,
    required double x,
    required double y,
    bool? isInitial,
    bool? isAccepting,
  }) {
    final update = upsertEditorState(
      states: _states,
      id: id,
      label: label,
      position: Vector2(x, y),
      isInitial: isInitial,
      isAccepting: isAccepting,
      normalizeInitial: true,
    );
    _applyStateMutation(update);

    return _rebuildState();
  }

  /// Moves a state to a new position on the canvas.
  TM? moveState({required String id, required double x, required double y}) {
    final update = updateEditorStateById(
      states: _states,
      id: id,
      update: (state) => state.copyWith(position: Vector2(x, y)),
    );
    if (!update.targetFound) {
      return state.tm;
    }

    _applyStateMutation(update);

    return _rebuildState();
  }

  /// Updates the label of the state matching [id].
  TM? updateStateLabel({required String id, required String label}) {
    final update = updateEditorStateById(
      states: _states,
      id: id,
      update: (state) => state.copyWith(label: label),
    );
    if (!update.targetFound) {
      return state.tm;
    }

    _applyStateMutation(update);

    return _rebuildState();
  }

  TM? updateStateFlags({
    required String id,
    bool? isInitial,
    bool? isAccepting,
  }) {
    if (isInitial == null && isAccepting == null) {
      return state.tm;
    }

    final update = updateEditorStateFlags(
      states: _states,
      id: id,
      isInitial: isInitial,
      isAccepting: isAccepting,
      fallbackInitial: true,
    );
    if (!update.targetFound || !update.hasChanges) {
      return state.tm;
    }

    _applyStateMutation(update);

    return _rebuildState();
  }

  TM? removeState({required String id}) {
    final removal = removeEditorStateById(
      states: _states,
      id: id,
      fallbackInitial: true,
    );
    if (!removal.targetFound) {
      return state.tm;
    }

    _states
      ..clear()
      ..addAll(removal.states);
    _transitions.removeWhere(
      (transition) => transitionTouchesState(
        stateId: id,
        fromStateId: transition.fromState.id,
        toStateId: transition.toState.id,
      ),
    );

    for (final changedState in removal.changedStates) {
      _rebindTransitionsForState(changedState);
    }

    return _rebuildState();
  }

  /// Adds or updates a TM transition using the supplied values.
  TM? addOrUpdateTransition({
    required String id,
    required String fromStateId,
    required String toStateId,
    String? readSymbol,
    String? writeSymbol,
    TapeDirection? direction,
    List<String>? readSymbols,
    List<String>? writeSymbols,
    List<TapeDirection>? directions,
    int? tapeNumber,
    Vector2? controlPoint,
  }) {
    final fromIndex = _states.indexWhere((state) => state.id == fromStateId);
    final toIndex = _states.indexWhere((state) => state.id == toStateId);
    if (fromIndex == -1 || toIndex == -1) {
      return state.tm;
    }

    final existingIndex = _transitions.indexWhere(
      (transition) => transition.id == id,
    );
    final existing = existingIndex != -1 ? _transitions[existingIndex] : null;

    final resolvedRead = readSymbol ?? existing?.readSymbol ?? '';
    final resolvedWrite = writeSymbol ?? existing?.writeSymbol ?? '';
    final resolvedDirection =
        direction ?? existing?.direction ?? TapeDirection.right;
    final resolvedTapeNumber = tapeNumber ?? existing?.tapeNumber ?? 0;
    final currentTapeCount =
        state.tm?.tapeCount ?? existing?.operationCount ?? 1;
    final tapeCount =
        readSymbols == null && writeSymbols == null && directions == null
            ? math.max(currentTapeCount, resolvedTapeNumber + 1)
            : currentTapeCount;
    final resolvedReads = readSymbols ??
        existing?.readSymbols ??
        List<String>.filled(tapeCount, state.tm?.blankSymbol ?? 'B');
    final resolvedWrites = writeSymbols ??
        existing?.writeSymbols ??
        List<String>.filled(tapeCount, state.tm?.blankSymbol ?? 'B');
    final resolvedDirections = directions ??
        existing?.directions ??
        List<TapeDirection>.filled(tapeCount, TapeDirection.stay);
    if (resolvedTapeNumber < 0 || resolvedTapeNumber >= tapeCount) {
      return state.tm;
    }
    final nextReads = List<String>.of(resolvedReads)
      ..addAll(
        List<String>.filled(
          tapeCount - resolvedReads.length,
          state.tm?.blankSymbol ?? 'B',
        ),
      );
    final nextWrites = List<String>.of(resolvedWrites)
      ..addAll(
        List<String>.filled(
          tapeCount - resolvedWrites.length,
          state.tm?.blankSymbol ?? 'B',
        ),
      );
    final nextDirections = List<TapeDirection>.of(resolvedDirections)
      ..addAll(
        List<TapeDirection>.filled(
          tapeCount - resolvedDirections.length,
          TapeDirection.stay,
        ),
      );
    nextReads[resolvedTapeNumber] = resolvedRead;
    nextWrites[resolvedTapeNumber] = resolvedWrite;
    nextDirections[resolvedTapeNumber] = resolvedDirection;
    final resolvedControlPoint =
        controlPoint ?? existing?.controlPoint ?? Vector2.zero();

    final base = existing ??
        TMTransition(
          id: id,
          fromState: _states[fromIndex],
          toState: _states[toIndex],
          label: '',
          controlPoint: resolvedControlPoint,
          readSymbol: resolvedRead,
          writeSymbol: resolvedWrite,
          direction: resolvedDirection,
          readSymbols: nextReads,
          writeSymbols: nextWrites,
          directions: nextDirections,
          tapeNumber: resolvedTapeNumber,
        );

    final updated = base.copyWith(
      fromState: _states[fromIndex],
      toState: _states[toIndex],
      controlPoint: resolvedControlPoint,
      readSymbol: resolvedRead,
      writeSymbol: resolvedWrite,
      direction: resolvedDirection,
      readSymbols: nextReads,
      writeSymbols: nextWrites,
      directions: nextDirections,
      tapeNumber: resolvedTapeNumber,
      label: TMTransition.formatVectorLabel(
        readSymbols: nextReads,
        writeSymbols: nextWrites,
        directions: nextDirections,
      ),
    );
    if (updated.validate().isNotEmpty) {
      return state.tm;
    }

    if (existingIndex == -1) {
      _transitions.add(updated);
    } else {
      _transitions[existingIndex] = updated;
    }

    return _rebuildState();
  }

  TM? addOrUpdateTransitionVectors({
    required String id,
    required String fromStateId,
    required String toStateId,
    required List<String> readSymbols,
    required List<String> writeSymbols,
    required List<TapeDirection> directions,
    Vector2? controlPoint,
  }) {
    if (readSymbols.length != (state.tm?.tapeCount ?? readSymbols.length) ||
        readSymbols.length != writeSymbols.length ||
        readSymbols.length != directions.length ||
        readSymbols.isEmpty) {
      return state.tm;
    }
    return addOrUpdateTransition(
      id: id,
      fromStateId: fromStateId,
      toStateId: toStateId,
      readSymbol: readSymbols.first,
      writeSymbol: writeSymbols.first,
      direction: directions.first,
      readSymbols: readSymbols,
      writeSymbols: writeSymbols,
      directions: directions,
      controlPoint: controlPoint,
    );
  }

  bool setTapeCount(int tapeCount) {
    final current = state.tm;
    if (current == null || tapeCount < 1 || tapeCount == current.tapeCount) {
      return tapeCount == current?.tapeCount;
    }
    if (tapeCount < current.tapeCount) {
      for (final transition in _transitions) {
        for (var tape = tapeCount; tape < transition.operationCount; tape++) {
          if (transition.readSymbols[tape] != current.blankSymbol ||
              transition.writeSymbols[tape] != current.blankSymbol ||
              transition.directions[tape] != TapeDirection.stay) {
            return false;
          }
        }
      }
    }
    for (var index = 0; index < _transitions.length; index++) {
      final transition = _transitions[index];
      final reads = List<String>.of(transition.readSymbols);
      final writes = List<String>.of(transition.writeSymbols);
      final moves = List<TapeDirection>.of(transition.directions);
      if (tapeCount > current.tapeCount) {
        reads.addAll(
          List<String>.filled(tapeCount - reads.length, current.blankSymbol),
        );
        writes.addAll(
          List<String>.filled(tapeCount - writes.length, current.blankSymbol),
        );
        moves.addAll(
          List<TapeDirection>.filled(
            tapeCount - moves.length,
            TapeDirection.stay,
          ),
        );
      } else {
        reads.removeRange(tapeCount, reads.length);
        writes.removeRange(tapeCount, writes.length);
        moves.removeRange(tapeCount, moves.length);
      }
      _transitions[index] = transition.copyWith(
        tapeNumber: 0,
        readSymbols: reads,
        writeSymbols: writes,
        directions: moves,
        label: TMTransition.formatVectorLabel(
          readSymbols: reads,
          writeSymbols: writes,
          directions: moves,
        ),
      );
    }
    state = state.copyWith(tm: current.copyWith(tapeCount: tapeCount));
    _rebuildState();
    return true;
  }

  /// Persists the acceptance criterion with the active TM document.
  void setAcceptancePolicy(TMAcceptancePolicy policy) {
    final current = state.tm;
    if (current == null || current.acceptancePolicy == policy) return;
    state = state.copyWith(
      tm: current.copyWith(
        acceptancePolicy: policy,
        modified: DateTime.now(),
      ),
      documentGeneration: state.documentGeneration + 1,
    );
  }

  /// Updates the tape operations for an existing transition.
  TM? updateTransitionOperations({
    required String id,
    String? readSymbol,
    String? writeSymbol,
    TapeDirection? direction,
    int? tapeNumber,
  }) {
    final index = _transitions.indexWhere((transition) => transition.id == id);
    if (index == -1) {
      return state.tm;
    }

    final transition = _transitions[index];
    return addOrUpdateTransition(
      id: id,
      fromStateId: transition.fromState.id,
      toStateId: transition.toState.id,
      readSymbol: readSymbol ?? transition.readSymbol,
      writeSymbol: writeSymbol ?? transition.writeSymbol,
      direction: direction ?? transition.direction,
      tapeNumber: tapeNumber ?? transition.tapeNumber,
      controlPoint: transition.controlPoint,
    );
  }

  TM? removeTransition({required String id}) {
    final initialLength = _transitions.length;
    _transitions.removeWhere((transition) => transition.id == id);
    if (_transitions.length == initialLength) {
      return state.tm;
    }

    return _rebuildState();
  }

  /// Replaces the current TM with [tm], recalculating derived metadata.
  void setTm(TM tm) {
    _replaceCollections(tm);

    final transitionSet = _transitions.toSet();
    final moveDirections = transitionSet
        .expand((transition) => transition.directions)
        .map((direction) => direction.name)
        .toSet();
    final nondeterministicTransitionIds = _findNondeterministicTransitions(
      transitionSet,
    );

    state = state.copyWith(
      tm: tm,
      tapeSymbols: tm.tapeAlphabet,
      moveDirections: moveDirections,
      nondeterministicTransitionIds: nondeterministicTransitionIds,
      states: List<State>.unmodifiable(_states),
      transitions: List<TMTransition>.unmodifiable(_transitions),
      documentGeneration: state.documentGeneration + 1,
    );
  }

  void _replaceCollections(TM tm) {
    final clonedStates = tm.states
        .map((state) => state.copyWith(position: state.position.clone()))
        .toList(growable: false);
    _states
      ..clear()
      ..addAll(clonedStates);

    final stateById = {for (final state in _states) state.id: state};

    final clonedTransitions =
        tm.transitions.whereType<TMTransition>().map((transition) {
      final fromState =
          stateById[transition.fromState.id] ?? transition.fromState;
      final toState = stateById[transition.toState.id] ?? transition.toState;
      return transition.copyWith(
        fromState: fromState,
        toState: toState,
        controlPoint: transition.controlPoint.clone(),
        readSymbols: transition.readSymbols,
        writeSymbols: transition.writeSymbols,
        directions: transition.directions,
        tapeNumber: transition.tapeNumber,
      );
    }).toList(growable: false);

    _transitions
      ..clear()
      ..addAll(clonedTransitions);
  }

  Set<String> _findNondeterministicTransitions(Set<TMTransition> transitions) {
    final grouped = <String, List<TMTransition>>{};

    for (final transition in transitions) {
      final key = [
        transition.fromState.id,
        ...transition.readSymbols,
      ].join('|');

      grouped.putIfAbsent(key, () => []).add(transition);
    }

    return grouped.values
        .where((list) => list.length > 1)
        .expand((list) => list.map((transition) => transition.id))
        .toSet();
  }

  TM? _rebuildState() {
    final current = state.tm;
    if (_states.isEmpty) {
      if (current == null) {
        state = TMEditorState(
          documentGeneration: state.documentGeneration + 1,
        );
        return null;
      }
      final emptyTm = current.copyWith(
        states: <State>{},
        transitions: <Transition>{},
        initialState: null,
        acceptingStates: <State>{},
        blockInvocations: const [],
        modified: DateTime.now(),
      );
      state = TMEditorState(
        tm: emptyTm,
        tapeSymbols: emptyTm.tapeAlphabet,
        documentGeneration: state.documentGeneration + 1,
      );
      return emptyTm;
    }

    final stateSet = _states.toSet();
    final stateIds = stateSet.map((state) => state.id).toSet();
    final transitionSet = _transitions.toSet();

    final initialState = _states.firstWhere(
      (state) => state.isInitial,
      orElse: () => _states.first,
    );

    final acceptingStates = _states.where((state) => state.isAccepting).toSet();

    final blankSymbol = current?.blankSymbol ?? 'B';
    final alphabet = <String>{...?current?.alphabet};
    final tapeAlphabet = <String>{
      ...?current?.tapeAlphabet,
      blankSymbol,
    };
    final moveDirections = <String>{};
    var tapeCount = current?.tapeCount ?? 1;

    for (final transition in transitionSet) {
      for (final symbol in transition.readSymbols) {
        if (symbol.isNotEmpty) {
          if (symbol != blankSymbol) alphabet.add(symbol);
          tapeAlphabet.add(symbol);
        }
      }
      for (final symbol in transition.writeSymbols) {
        if (symbol.isNotEmpty) tapeAlphabet.add(symbol);
      }
      moveDirections.addAll(transition.directions.map((value) => value.name));
      tapeCount = math.max(tapeCount, transition.operationCount);
    }

    final now = DateTime.now();

    final transitions = transitionSet.map<Transition>((t) => t).toSet();
    final tm = current == null
        ? TM(
            id: 'editor-tm',
            name: 'Canvas TM',
            states: stateSet,
            transitions: transitions,
            alphabet: alphabet,
            initialState: initialState,
            acceptingStates: acceptingStates,
            created: now,
            modified: now,
            bounds: const math.Rectangle(0, 0, 800, 600),
            tapeAlphabet: tapeAlphabet,
            blankSymbol: blankSymbol,
            tapeCount: tapeCount,
            zoomLevel: 1,
            panOffset: Vector2.zero(),
          )
        : current.copyWith(
            states: stateSet,
            transitions: transitions,
            alphabet: alphabet,
            initialState: initialState,
            acceptingStates: acceptingStates,
            modified: now,
            tapeAlphabet: tapeAlphabet,
            tapeCount: tapeCount,
            blockInvocations: current.blockInvocations
                .where((invocation) => stateIds.contains(invocation.stateId)),
          );

    final nondeterministicTransitionIds = _findNondeterministicTransitions(
      transitionSet,
    );

    state = state.copyWith(
      tm: tm,
      tapeSymbols: tapeAlphabet,
      moveDirections: moveDirections,
      nondeterministicTransitionIds: nondeterministicTransitionIds,
      states: List<State>.unmodifiable(_states),
      transitions: List<TMTransition>.unmodifiable(_transitions),
      documentGeneration: state.documentGeneration + 1,
    );

    return tm;
  }

  void _rebindTransitionsForState(State updatedState) {
    for (var i = 0; i < _transitions.length; i++) {
      final transition = _transitions[i];
      if (transition.fromState.id == updatedState.id ||
          transition.toState.id == updatedState.id) {
        _transitions[i] = transition.copyWith(
          fromState: transition.fromState.id == updatedState.id
              ? updatedState
              : transition.fromState,
          toState: transition.toState.id == updatedState.id
              ? updatedState
              : transition.toState,
        );
      }
    }
  }

  void _applyStateMutation(EditorStateMutation update) {
    _states
      ..clear()
      ..addAll(update.states);

    for (final changedState in update.changedStates) {
      _rebindTransitionsForState(changedState);
    }
  }
}

/// Provider exposing the current TM editor state.
final tmEditorProvider = StateNotifierProvider<TMEditorNotifier, TMEditorState>(
  (ref) => TMEditorNotifier(),
);
