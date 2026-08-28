//
//  automaton_state_provider.dart
//  Turing Lab
//
//  Manages state CRUD operations for automata including states, transitions,
//  and history tracking. Replaces the legacy combined automaton provider with
//  a focused state notifier.
//
//  Thales Matheus Mendonça Santos - January 2026
//
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector_math/vector_math_64.dart';

import '../../core/constants/automaton_canvas_constants.dart';
import '../../core/models/fsa.dart';
import '../../core/models/fsa_transition.dart';
import '../../core/models/state.dart';
import '../../core/models/transition.dart';
import '../../core/utils/epsilon_utils.dart';
import 'editor_state_helpers.dart';

/// State for automaton CRUD operations
class AutomatonStateProviderState {
  final FSA? currentAutomaton;
  final List<FSA> automatonHistory;
  final bool isLoading;
  final String? error;
  final int documentGeneration;

  const AutomatonStateProviderState({
    this.currentAutomaton,
    this.automatonHistory = const [],
    this.isLoading = false,
    this.error,
    this.documentGeneration = 0,
  });

  static const _unset = Object();

  AutomatonStateProviderState copyWith({
    Object? currentAutomaton = _unset,
    List<FSA>? automatonHistory,
    bool? isLoading,
    Object? error = _unset,
    int? documentGeneration,
  }) {
    return AutomatonStateProviderState(
      currentAutomaton: currentAutomaton == _unset
          ? this.currentAutomaton
          : currentAutomaton as FSA?,
      automatonHistory: automatonHistory ?? this.automatonHistory,
      isLoading: isLoading ?? this.isLoading,
      error: error == _unset ? this.error : error as String?,
      documentGeneration: documentGeneration ?? this.documentGeneration,
    );
  }

  /// Clear all state and reset to initial
  AutomatonStateProviderState clear() {
    return AutomatonStateProviderState(
      documentGeneration: documentGeneration + 1,
    );
  }

  /// Clear only error state
  AutomatonStateProviderState clearError() {
    return copyWith(error: null);
  }
}

/// State notifier for automaton CRUD operations
class AutomatonStateNotifier
    extends StateNotifier<AutomatonStateProviderState> {
  int _nextId = 1;
  int _graphViewMutationCounter = 0;

  AutomatonStateNotifier() : super(const AutomatonStateProviderState());

  /// Current automaton snapshot for collaborators that should not read the
  /// protected StateNotifier state directly.
  FSA? get currentAutomaton => state.currentAutomaton;

  /// Restores an exact editor snapshot after a failed document replacement.
  void restoreDocumentCheckpoint(AutomatonStateProviderState checkpoint) {
    state = checkpoint;
  }

  void _traceGraphView(String operation, [Map<String, Object?>? metadata]) {
    if (!kDebugMode) {
      return;
    }

    final buffer = StringBuffer('[AutomatonStateProvider] $operation');
    if (metadata != null && metadata.isNotEmpty) {
      final formatted = metadata.entries
          .map((entry) => '${entry.key}=${entry.value}')
          .join(', ');
      buffer.write(' {$formatted}');
    }

    debugPrint(buffer.toString());
  }

  /// Creates a new automaton
  Future<void> createAutomaton({
    required String name,
    String? description,
    required List<String> alphabet,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      if (name.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          error:
              'Error creating automaton: ${ArgumentError('Automaton name cannot be empty')}',
        );
        return;
      }

      final now = DateTime.now();
      final q0 = State(
        id: 'q0',
        label: 'q0',
        position: Vector2(100, 100),
        isInitial: true,
        isAccepting: false,
      );

      final automaton = FSA(
        id: (_nextId++).toString(),
        name: name,
        states: {q0},
        transitions: const <Transition>{},
        alphabet: alphabet.toSet(),
        initialState: q0,
        acceptingStates: const <State>{},
        created: now,
        modified: now,
        bounds: const Rectangle<double>(0, 0, 400, 300),
      );

      state = state.copyWith(
        currentAutomaton: automaton,
        isLoading: false,
        documentGeneration: state.documentGeneration + 1,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error creating automaton: $e',
      );
    }
  }

  /// Updates the current automaton
  void updateAutomaton(FSA automaton) {
    state = state.copyWith(currentAutomaton: automaton);
  }

  /// Replaces the current document with an automaton from another origin.
  ///
  /// Editor and layout updates must use [updateAutomaton] so interoperability
  /// metadata remains attached to the active document.
  void replaceAutomaton(FSA automaton) {
    state = state.copyWith(
      currentAutomaton: automaton,
      documentGeneration: state.documentGeneration + 1,
    );
  }

  /// Adds a new state or updates an existing one using coordinates supplied by
  /// the GraphView canvas controllers.
  void addState({
    required String id,
    required String label,
    required double x,
    required double y,
    bool? isInitial,
    bool? isAccepting,
  }) {
    _traceGraphView('addState', {
      'id': id,
      'label': label,
      'x': x.toStringAsFixed(2),
      'y': y.toStringAsFixed(2),
      'initial': isInitial,
      'accepting': isAccepting,
    });
    _mutateAutomaton((current) {
      final update = upsertEditorState(
        states: current.states,
        id: id,
        label: label,
        position: Vector2(x, y),
        isInitial: isInitial,
        isAccepting: isAccepting,
        normalizeInitial: isInitial == true,
      );
      final statesById = update.statesById;
      final updatedTransitions = _rebindTransitions(
        current.transitions.whereType<FSATransition>(),
        statesById,
      );

      final initialState =
          update.states.firstWhereOrNull((state) => state.isInitial);

      final acceptingStates =
          statesById.values.where((state) => state.isAccepting).toSet();

      return current.copyWith(
        states: statesById.values.toSet(),
        transitions: updatedTransitions.map<Transition>((t) => t).toSet(),
        initialState: initialState,
        acceptingStates: acceptingStates,
        modified: DateTime.now(),
      );
    });
  }

  /// Moves a state to a new position on the canvas.
  void moveState({required String id, required double x, required double y}) {
    _traceGraphView('moveState', {
      'id': id,
      'x': x.toStringAsFixed(2),
      'y': y.toStringAsFixed(2),
    });
    _mutateAutomaton((current) {
      final updatedStates = current.states
          .map(
            (state) => state.id == id
                ? state.copyWith(position: Vector2(x, y))
                : state,
          )
          .toList();
      final statesById = {for (final state in updatedStates) state.id: state};
      final updatedTransitions = _rebindTransitions(
        current.transitions.whereType<FSATransition>(),
        statesById,
      );

      final initialStateId = current.initialState?.id;
      final acceptingStates =
          statesById.values.where((state) => state.isAccepting).toSet();

      return current.copyWith(
        states: statesById.values.toSet(),
        transitions: updatedTransitions.map<Transition>((t) => t).toSet(),
        initialState:
            initialStateId != null ? statesById[initialStateId] : null,
        acceptingStates: acceptingStates,
        modified: DateTime.now(),
      );
    });
  }

  /// Removes the state identified by [id] along with connected transitions.
  void removeState({required String id}) {
    _traceGraphView('removeState', {'id': id});
    _mutateAutomaton((current) {
      if (current.states.every((state) => state.id != id)) {
        _traceGraphView('removeState skipped', {
          'id': id,
          'reason': 'not-found',
        });
        return current;
      }

      final remainingStates = current.states
          .where((state) => state.id != id)
          .toList(growable: false);

      if (remainingStates.isEmpty) {
        return current.copyWith(
          states: <State>{},
          transitions: <Transition>{},
          initialState: null,
          acceptingStates: <State>{},
          modified: DateTime.now(),
        );
      }

      final initialCandidate = remainingStates.firstWhereOrNull(
        (state) => state.id == current.initialState?.id,
      );
      final resolvedInitial = initialCandidate ?? remainingStates.first;

      final normalizedStates = remainingStates
          .map(
            (state) => state.copyWith(
              isInitial: state.id == resolvedInitial.id,
              isAccepting: current.acceptingStates.any(
                (accepting) => accepting.id == state.id,
              ),
            ),
          )
          .toList();

      State? updatedInitial = normalizedStates.firstWhereOrNull(
        (state) => state.isInitial,
      );
      if (updatedInitial == null && normalizedStates.isNotEmpty) {
        final fallback = normalizedStates.first.copyWith(isInitial: true);
        normalizedStates[0] = fallback;
        updatedInitial = fallback;
      }

      final statesById = {
        for (final state in normalizedStates) state.id: state,
      };
      final filteredTransitions = current.transitions
          .whereType<FSATransition>()
          .where(
            (transition) =>
                transition.fromState.id != id && transition.toState.id != id,
          )
          .toList();

      final reboundTransitions = _rebindTransitions(
        filteredTransitions,
        statesById,
      );
      final acceptingStates =
          statesById.values.where((state) => state.isAccepting).toSet();

      return current.copyWith(
        states: statesById.values.toSet(),
        transitions: reboundTransitions.map<Transition>((t) => t).toSet(),
        initialState: updatedInitial,
        acceptingStates: acceptingStates,
        modified: DateTime.now(),
      );
    });
  }

  /// Adds or updates a transition in the automaton.
  void addOrUpdateTransition({
    required String id,
    required String fromStateId,
    required String toStateId,
    required String label,
    double? controlPointX,
    double? controlPointY,
  }) {
    _traceGraphView('addOrUpdateTransition', {
      'id': id,
      'from': fromStateId,
      'to': toStateId,
      'label': label,
      'cpX': controlPointX?.toStringAsFixed(2),
      'cpY': controlPointY?.toStringAsFixed(2),
    });
    _mutateAutomaton((current) {
      final statesById = {for (final state in current.states) state.id: state};
      final fromState = statesById[fromStateId];
      final toState = statesById[toStateId];
      if (fromState == null || toState == null) {
        _traceGraphView('addOrUpdateTransition skipped', {
          'id': id,
          'missingFrom': fromState == null,
          'missingTo': toState == null,
        });
        return current;
      }

      final parsedLabel = _parseTransitionLabel(label);
      final resolvedLabel = _formatTransitionLabel(label, parsedLabel);
      final transitions =
          current.transitions.whereType<FSATransition>().toList();
      final existingIndex = transitions.indexWhere(
        (transition) => transition.id == id,
      );

      Vector2? controlPoint;
      if (controlPointX != null && controlPointY != null) {
        controlPoint = Vector2(controlPointX, controlPointY);
      }

      final isSelfLoop = fromState.id == toState.id;
      if (controlPoint == null && isSelfLoop) {
        controlPoint = _defaultLoopControlPoint(fromState);
      }

      if (existingIndex >= 0) {
        final existing = transitions[existingIndex];
        final existingControl = controlPoint ?? existing.controlPoint;
        final resolvedControlPoint =
            isSelfLoop && _isZeroVector(existingControl)
                ? _defaultLoopControlPoint(fromState)
                : existingControl;
        transitions[existingIndex] = existing.copyWith(
          fromState: fromState,
          toState: toState,
          label: resolvedLabel,
          controlPoint: resolvedControlPoint,
          inputSymbols: parsedLabel.symbols,
          lambdaSymbol: parsedLabel.lambdaSymbol,
        );
      } else {
        transitions.add(
          FSATransition(
            id: id,
            fromState: fromState,
            toState: toState,
            label: resolvedLabel,
            controlPoint: controlPoint,
            inputSymbols: parsedLabel.symbols,
            lambdaSymbol: parsedLabel.lambdaSymbol,
          ),
        );
      }

      final updatedAlphabet = _mergeAlphabet(
        current.alphabet,
        parsedLabel.symbols,
      );

      return current.copyWith(
        transitions: transitions.map<Transition>((t) => t).toSet(),
        alphabet: updatedAlphabet,
        modified: DateTime.now(),
      );
    });
  }

  /// Removes the transition identified by [id] from the automaton.
  void removeTransition({required String id}) {
    _traceGraphView('removeTransition', {'id': id});
    _mutateAutomaton((current) {
      final transitions =
          current.transitions.whereType<FSATransition>().toList();
      final index = transitions.indexWhere((transition) => transition.id == id);
      if (index < 0) {
        _traceGraphView('removeTransition skipped', {
          'id': id,
          'reason': 'not-found',
        });
        return current;
      }

      transitions.removeAt(index);

      return current.copyWith(
        transitions: transitions.map<Transition>((t) => t).toSet(),
        modified: DateTime.now(),
      );
    });
  }

  /// Updates the label of an existing state.
  void updateStateLabel({required String id, required String label}) {
    _traceGraphView('updateStateLabel', {'id': id, 'label': label});
    _mutateAutomaton((current) {
      final updatedStates = current.states
          .map((state) => state.id == id ? state.copyWith(label: label) : state)
          .toList();
      final statesById = {for (final state in updatedStates) state.id: state};
      final updatedTransitions = _rebindTransitions(
        current.transitions.whereType<FSATransition>(),
        statesById,
      );

      final initialStateId = current.initialState?.id;
      final acceptingStates =
          statesById.values.where((state) => state.isAccepting).toSet();

      return current.copyWith(
        states: statesById.values.toSet(),
        transitions: updatedTransitions.map<Transition>((t) => t).toSet(),
        initialState:
            initialStateId != null ? statesById[initialStateId] : null,
        acceptingStates: acceptingStates,
        modified: DateTime.now(),
      );
    });
  }

  /// Updates the flag metadata for the state matching [id].
  void updateStateFlags({
    required String id,
    bool? isInitial,
    bool? isAccepting,
  }) {
    if (isInitial == null && isAccepting == null) {
      return;
    }

    _traceGraphView('updateStateFlags', {
      'id': id,
      'isInitial': isInitial,
      'isAccepting': isAccepting,
    });
    _mutateAutomaton((current) {
      if (current.states.every((state) => state.id != id)) {
        _traceGraphView('updateStateFlags skipped', {
          'id': id,
          'reason': 'not-found',
        });
        return current;
      }

      final updatedStates = current.states.map((state) {
        var newInitial = state.isInitial;
        var newAccepting = state.isAccepting;

        if (state.id == id) {
          newInitial = isInitial ?? state.isInitial;
          newAccepting = isAccepting ?? state.isAccepting;
        } else if (isInitial == true) {
          newInitial = false;
        }

        return state.copyWith(isInitial: newInitial, isAccepting: newAccepting);
      }).toList();

      if (!updatedStates.any((state) => state.isInitial) &&
          updatedStates.isNotEmpty) {
        updatedStates[0] = updatedStates[0].copyWith(isInitial: true);
      }

      final statesById = {for (final state in updatedStates) state.id: state};
      final updatedTransitions = _rebindTransitions(
        current.transitions.whereType<FSATransition>(),
        statesById,
      );

      final initialState = updatedStates.firstWhereOrNull(
        (state) => state.isInitial,
      );
      final acceptingStates =
          statesById.values.where((state) => state.isAccepting).toSet();

      return current.copyWith(
        states: statesById.values.toSet(),
        transitions: updatedTransitions.map<Transition>((t) => t).toSet(),
        initialState: initialState,
        acceptingStates: acceptingStates,
        modified: DateTime.now(),
      );
    });
  }

  /// Updates the label (and symbol set) of an existing transition.
  void updateTransitionLabel({required String id, required String label}) {
    _traceGraphView('updateTransitionLabel', {'id': id, 'label': label});
    _mutateAutomaton((current) {
      final transitions =
          current.transitions.whereType<FSATransition>().toList();
      final index = transitions.indexWhere((transition) => transition.id == id);
      if (index < 0) {
        _traceGraphView('updateTransitionLabel skipped', {
          'id': id,
          'reason': 'not-found',
        });
        return current;
      }

      final parsedLabel = _parseTransitionLabel(label);
      final resolvedLabel = _formatTransitionLabel(label, parsedLabel);
      final existing = transitions[index];
      final isSelfLoop = existing.fromState.id == existing.toState.id;
      final resolvedControlPoint =
          isSelfLoop && _isZeroVector(existing.controlPoint)
              ? _defaultLoopControlPoint(existing.fromState)
              : existing.controlPoint;
      transitions[index] = existing.copyWith(
        label: resolvedLabel,
        inputSymbols: parsedLabel.symbols,
        lambdaSymbol: parsedLabel.lambdaSymbol,
        controlPoint: resolvedControlPoint,
      );

      final updatedAlphabet = _mergeAlphabet(
        current.alphabet,
        parsedLabel.symbols,
      );

      return current.copyWith(
        transitions: transitions.map<Transition>((t) => t).toSet(),
        alphabet: updatedAlphabet,
        modified: DateTime.now(),
      );
    });
  }

  /// Clears the current automaton
  void clearAutomaton() {
    state = state.copyWith(
      currentAutomaton: null,
      error: null,
      documentGeneration: state.documentGeneration + 1,
    );
  }

  /// Clears any error messages
  void clearError() {
    state = state.clearError();
  }

  /// Clear all state and reset to initial
  void clearAll() {
    state = state.clear();
  }

  /// Get automaton from history
  FSA? getAutomatonFromHistory(int index) {
    if (index < 0 || index >= state.automatonHistory.length) return null;
    return state.automatonHistory[index];
  }

  // Private helper methods

  void _mutateAutomaton(FSA Function(FSA current) transform) {
    final current = state.currentAutomaton ?? _createEmptyAutomaton();
    final updated = transform(current);
    if (identical(updated, state.currentAutomaton)) {
      _traceGraphView('mutation skipped', {'reason': 'identical-snapshot'});
      return;
    }

    _graphViewMutationCounter++;
    _traceGraphView('mutation applied', {
      'seq': _graphViewMutationCounter,
      'states': updated.states.length,
      'transitions': updated.transitions.length,
      'initial': updated.initialState?.id,
      'accepting': updated.acceptingStates.length,
      'alphabet': updated.alphabet.length,
    });

    state = state.copyWith(currentAutomaton: updated, error: null);
  }

  Set<FSATransition> _rebindTransitions(
    Iterable<FSATransition> transitions,
    Map<String, State> statesById,
  ) {
    return transitions
        .map(
          (transition) => transition.copyWith(
            fromState:
                statesById[transition.fromState.id] ?? transition.fromState,
            toState: statesById[transition.toState.id] ?? transition.toState,
          ),
        )
        .toSet();
  }

  ({Set<String> symbols, String? lambdaSymbol}) _parseTransitionLabel(
    String label,
  ) {
    final trimmed = label.trim();
    if (isEpsilonSymbol(trimmed)) {
      return (symbols: <String>{}, lambdaSymbol: kEpsilonSymbol);
    }

    final normalized = trimmed.replaceAll(RegExp(r'\s+'), '');
    if (isEpsilonSymbol(normalized)) {
      return (symbols: <String>{}, lambdaSymbol: kEpsilonSymbol);
    }

    final parts = normalized
        .split(',')
        .map((symbol) => symbol.trim())
        .where((symbol) => symbol.isNotEmpty)
        .toSet();
    return (symbols: parts, lambdaSymbol: null);
  }

  String _formatTransitionLabel(
    String rawLabel,
    ({Set<String> symbols, String? lambdaSymbol}) metadata,
  ) {
    if (metadata.lambdaSymbol != null) {
      return kEpsilonSymbol;
    }

    final collapsed = rawLabel.trim().replaceAll(RegExp(r'\s+'), '');
    if (collapsed.isNotEmpty) {
      final normalized = normalizeToEpsilon(collapsed);
      return normalized;
    }

    if (metadata.symbols.isNotEmpty) {
      final parts = metadata.symbols
          .map((symbol) => normalizeToEpsilon(symbol))
          .where((symbol) => symbol.isNotEmpty && !isEpsilonSymbol(symbol))
          .toList();
      if (parts.isNotEmpty) {
        return parts.join(',');
      }
    }

    return kEpsilonSymbol;
  }

  Vector2 _defaultLoopControlPoint(State state) {
    const radius = kAutomatonStateDiameter / 2;
    return Vector2(state.position.x + radius, state.position.y - radius);
  }

  bool _isZeroVector(Vector2 vector) {
    const epsilon = 1e-3;
    return vector.x.abs() < epsilon && vector.y.abs() < epsilon;
  }

  Set<String> _mergeAlphabet(Set<String> alphabet, Set<String> additions) {
    final filtered = additions
        .map((symbol) => symbol.trim())
        .where((symbol) => symbol.isNotEmpty && !isEpsilonSymbol(symbol))
        .toSet();
    return {...alphabet, ...filtered};
  }

  FSA _createEmptyAutomaton() {
    final now = DateTime.now();
    return FSA(
      id: 'automaton_${now.microsecondsSinceEpoch}',
      name: 'Untitled Automaton',
      states: <State>{},
      transitions: <Transition>{},
      alphabet: <String>{},
      initialState: null,
      acceptingStates: <State>{},
      created: now,
      modified: now,
      bounds: const Rectangle<double>(0, 0, 800, 600),
      panOffset: Vector2.zero(),
      zoomLevel: 1.0,
    );
  }
}

/// Provider for automaton state management
final automatonStateProvider =
    StateNotifierProvider<AutomatonStateNotifier, AutomatonStateProviderState>((
  ref,
) {
  return AutomatonStateNotifier();
});
