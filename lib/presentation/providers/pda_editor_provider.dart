//
//  pda_editor_provider.dart
//  Turing Lab
//
//  Declara o estado e o StateNotifier responsáveis por controlar o autômato de
//  pilha editado no canvas, mantendo transições lambda, escolhas
//  não determinísticas e sincronizando as mutações de estados com estruturas
//  imutáveis usadas por simuladores, exportadores e destaques visuais.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector_math/vector_math_64.dart';

import '../../core/models/pda.dart';
import '../../core/models/pda_transition.dart';
import '../../core/models/state.dart';
import '../../core/models/transition.dart';
import 'editor_state_helpers.dart';

/// Holds the current PDA being edited in the canvas together with
/// metadata used by other widgets (e.g. highlighting information).
class PDAEditorState {
  /// The PDA built from the canvas contents.
  final PDA? pda;

  /// Identifiers of transitions that participate in nondeterministic choices.
  final Set<String> nondeterministicTransitionIds;

  /// Identifiers of transitions that involve at least one lambda operation.
  final Set<String> lambdaTransitionIds;

  const PDAEditorState({
    this.pda,
    this.nondeterministicTransitionIds = const {},
    this.lambdaTransitionIds = const {},
  });

  PDAEditorState copyWith({
    PDA? pda,
    Set<String>? nondeterministicTransitionIds,
    Set<String>? lambdaTransitionIds,
  }) {
    return PDAEditorState(
      pda: pda ?? this.pda,
      nondeterministicTransitionIds:
          nondeterministicTransitionIds ?? this.nondeterministicTransitionIds,
      lambdaTransitionIds: lambdaTransitionIds ?? this.lambdaTransitionIds,
    );
  }
}

/// Riverpod notifier responsible for maintaining the PDA that is edited by
/// the PDA canvas.
class PDAEditorNotifier extends StateNotifier<PDAEditorState> {
  PDAEditorNotifier() : super(const PDAEditorState());

  /// Current PDA snapshot for collaborators that should not read the protected
  /// StateNotifier state directly.
  PDA? get currentPda => state.pda;

  PDA _createEmptyPda() {
    final now = DateTime.now();
    return PDA(
      id: 'editor-pda',
      name: 'Canvas PDA',
      states: {},
      transitions: {},
      alphabet: {},
      initialState: null,
      acceptingStates: {},
      created: now,
      modified: now,
      bounds: const math.Rectangle(0, 0, 800, 600),
      stackAlphabet: const {'Z'},
      initialStackSymbol: 'Z',
      zoomLevel: 1,
      panOffset: Vector2.zero(),
    );
  }

  PDA? _mutatePda(PDA Function(PDA current) transform) {
    final current = state.pda ?? _createEmptyPda();
    final updated = transform(current);
    if (identical(updated, current)) {
      return state.pda;
    }
    _updateStateWithPda(updated);
    return updated;
  }

  PDA? addOrUpdateState({
    required String id,
    required String label,
    required double x,
    required double y,
  }) {
    return _mutatePda((current) {
      final update = upsertEditorState(
        states: current.states,
        id: id,
        label: label,
        position: Vector2(x, y),
      );

      final updated = _finalisePda(
        base: current,
        statesById: update.statesById,
        transitions: current.pdaTransitions,
      );

      return updated;
    });
  }

  PDA? moveState({required String id, required double x, required double y}) {
    return _mutatePda((current) {
      final update = updateEditorStateById(
        states: current.states,
        id: id,
        update: (state) => state.copyWith(position: Vector2(x, y)),
      );

      return _finalisePda(
        base: current,
        statesById: update.statesById,
        transitions: current.pdaTransitions,
      );
    });
  }

  PDA? updateStateLabel({required String id, required String label}) {
    return _mutatePda((current) {
      final update = updateEditorStateById(
        states: current.states,
        id: id,
        update: (state) => state.copyWith(label: label),
      );

      return _finalisePda(
        base: current,
        statesById: update.statesById,
        transitions: current.pdaTransitions,
      );
    });
  }

  PDA? updateStateFlags({
    required String id,
    bool? isInitial,
    bool? isAccepting,
  }) {
    if (isInitial == null && isAccepting == null) {
      return state.pda;
    }

    return _mutatePda((current) {
      final update = updateEditorStateFlags(
        states: current.states,
        id: id,
        isInitial: isInitial,
        isAccepting: isAccepting,
      );
      if (!update.targetFound) {
        return current;
      }

      return _finalisePda(
        base: current,
        statesById: update.statesById,
        transitions: current.pdaTransitions,
      );
    });
  }

  PDA? removeState({required String id}) {
    return _mutatePda((current) {
      final removal = removeEditorStateById(states: current.states, id: id);
      if (!removal.targetFound) {
        return current;
      }

      final remainingTransitions = current.pdaTransitions
          .where(
            (transition) => !transitionTouchesState(
              stateId: id,
              fromStateId: transition.fromState.id,
              toStateId: transition.toState.id,
            ),
          )
          .toList();

      return _finalisePda(
        base: current,
        statesById: removal.statesById,
        transitions: remainingTransitions,
      );
    });
  }

  PDA? upsertTransition({
    required String id,
    String? fromStateId,
    String? toStateId,
    String? label,
    String? readSymbol,
    String? popSymbol,
    String? pushSymbol,
    List<String>? pushSymbols,
    bool? isLambdaInput,
    bool? isLambdaPop,
    bool? isLambdaPush,
    Vector2? controlPoint,
  }) {
    return _mutatePda((current) {
      final statesById = {for (final state in current.states) state.id: state};
      final transitions = current.pdaTransitions.toList();
      final index = transitions.indexWhere((transition) => transition.id == id);

      PDATransition base;
      if (index >= 0) {
        base = transitions[index];
      } else {
        if (fromStateId == null || toStateId == null) {
          return current;
        }
        final fromState = statesById[fromStateId];
        final toState = statesById[toStateId];
        if (fromState == null || toState == null) {
          return current;
        }
        base = PDATransition(
          id: id,
          fromState: fromState,
          toState: toState,
          label: '',
          controlPoint: (controlPoint ?? Vector2.zero()).clone(),
          type: TransitionType.deterministic,
          inputSymbol: '',
          popSymbol: '',
          pushSymbol: '',
          isLambdaInput: true,
          isLambdaPop: true,
          isLambdaPush: true,
        );
        transitions.add(base);
      }

      final effectiveFrom =
          fromStateId != null && statesById.containsKey(fromStateId)
              ? statesById[fromStateId]!
              : base.fromState;
      final effectiveTo = toStateId != null && statesById.containsKey(toStateId)
          ? statesById[toStateId]!
          : base.toState;

      final lambdaInput = isLambdaInput ?? base.isLambdaInput;
      final lambdaPop = isLambdaPop ?? base.isLambdaPop;
      final lambdaPush = isLambdaPush ?? base.isLambdaPush;
      final effectivePushSymbol =
          lambdaPush ? '' : (pushSymbol ?? base.pushSymbol);
      final List<String>? effectivePushSymbols = lambdaPush
          ? const <String>[]
          : pushSymbols ?? (pushSymbol == null ? base.pushSymbols : null);

      final updatedTransition = base.copyWith(
        fromState: effectiveFrom,
        toState: effectiveTo,
        inputSymbol: lambdaInput ? '' : (readSymbol ?? base.inputSymbol),
        popSymbol: lambdaPop ? '' : (popSymbol ?? base.popSymbol),
        pushSymbol: effectivePushSymbol,
        pushSymbols: effectivePushSymbols,
        isLambdaInput: lambdaInput,
        isLambdaPop: lambdaPop,
        isLambdaPush: lambdaPush,
        controlPoint: (controlPoint ?? base.controlPoint).clone(),
      );

      final resolvedLabel = label ??
          PDATransition.formatLabel(
            inputSymbol: updatedTransition.inputSymbol,
            popSymbol: updatedTransition.popSymbol,
            pushSymbol: updatedTransition.pushSymbol,
            isLambdaInput: updatedTransition.isLambdaInput,
            isLambdaPop: updatedTransition.isLambdaPop,
            isLambdaPush: updatedTransition.isLambdaPush,
          );
      final finalTransition = updatedTransition.copyWith(
        label: resolvedLabel.trim(),
      );
      if (finalTransition.validate().isNotEmpty) {
        return current;
      }

      if (index >= 0) {
        transitions[index] = finalTransition;
      } else {
        transitions[transitions.length - 1] = finalTransition;
      }

      return _finalisePda(
        base: current,
        statesById: statesById,
        transitions: transitions,
      );
    });
  }

  PDA? removeTransition({required String id}) {
    return _mutatePda((current) {
      final transitions = current.pdaTransitions
          .where((transition) => transition.id != id)
          .toList(growable: false);
      if (transitions.length == current.pdaTransitions.length) {
        return current;
      }

      final statesById = {for (final state in current.states) state.id: state};

      return _finalisePda(
        base: current,
        statesById: statesById,
        transitions: transitions,
      );
    });
  }

  /// Updates the notifier using the raw state and transition collections
  /// maintained by the canvas.
  void updateFromCanvas({
    required List<State> states,
    required List<PDATransition> transitions,
  }) {
    if (states.isEmpty) {
      state = const PDAEditorState(pda: null);
      return;
    }

    final stateSet = states.toSet();
    final transitionSet = transitions.toSet();

    final initialState = states.firstWhere(
      (s) => s.isInitial,
      orElse: () => states.first,
    );

    final acceptingStates = states.where((s) => s.isAccepting).toSet();

    final alphabet = <String>{};
    final stackAlphabet = <String>{'Z'};

    for (final transition in transitionSet) {
      if (!transition.isLambdaInput && transition.inputSymbol.isNotEmpty) {
        alphabet.add(transition.inputSymbol);
      }

      if (!transition.isLambdaPop && transition.popSymbol.isNotEmpty) {
        stackAlphabet.add(transition.popSymbol);
      }

      if (!transition.isLambdaPush && transition.pushSymbol.isNotEmpty) {
        stackAlphabet.addAll(transition.pushSymbols);
      }
    }

    if (stackAlphabet.isEmpty) {
      stackAlphabet.add('Z');
    }

    final now = DateTime.now();

    final pda = PDA(
      id: 'editor-pda',
      name: 'Canvas PDA',
      states: stateSet,
      transitions: transitionSet.map<Transition>((t) => t).toSet(),
      alphabet: alphabet,
      initialState: initialState,
      acceptingStates: {
        if (acceptingStates.isEmpty) states.last else ...acceptingStates,
      },
      created: now,
      modified: now,
      bounds: const math.Rectangle(0, 0, 800, 600),
      stackAlphabet: stackAlphabet,
      initialStackSymbol: stackAlphabet.first,
      zoomLevel: 1,
      panOffset: Vector2.zero(),
    );

    _updateStateWithPda(pda);
  }

  Set<String> _findNondeterministicTransitions(Set<PDATransition> transitions) {
    final grouped = <String, List<PDATransition>>{};

    for (final transition in transitions) {
      final key = [
        transition.fromState.id,
        if (transition.isLambdaInput) 'λ' else transition.inputSymbol,
        if (transition.isLambdaPop) 'λ' else transition.popSymbol,
      ].join('|');

      grouped.putIfAbsent(key, () => []).add(transition);
    }

    return grouped.values
        .where((list) => list.length > 1)
        .expand((list) => list.map((transition) => transition.id))
        .toSet();
  }

  /// Replaces the current PDA with a new instance, recalculating metadata.
  void setPda(PDA pda) {
    _updateStateWithPda(pda);
  }

  /// Clears the editor state, removing any PDA currently rendered on the canvas.
  void clear() {
    state = const PDAEditorState();
  }

  void _updateStateWithPda(PDA pda) {
    final transitions = pda.pdaTransitions;
    final nondeterministicTransitionIds = _findNondeterministicTransitions(
      transitions,
    );
    final lambdaTransitionIds = transitions
        .where((t) => t.isLambdaInput || t.isLambdaPop || t.isLambdaPush)
        .map((t) => t.id)
        .toSet();

    state = state.copyWith(
      pda: pda,
      nondeterministicTransitionIds: nondeterministicTransitionIds,
      lambdaTransitionIds: lambdaTransitionIds,
    );
  }

  PDA _finalisePda({
    required PDA base,
    required Map<String, State> statesById,
    required Iterable<PDATransition> transitions,
  }) {
    final normalizedStates = ensureInitialState(statesById.values);
    final normalizedStatesById = statesByIdFrom(normalizedStates);
    final reboundTransitions = transitions
        .map(
          (transition) => transition.copyWith(
            fromState: normalizedStatesById[transition.fromState.id] ??
                transition.fromState,
            toState: normalizedStatesById[transition.toState.id] ??
                transition.toState,
          ),
        )
        .toSet();

    State? initialState;
    for (final state in normalizedStates) {
      if (state.isInitial) {
        initialState = state;
        break;
      }
    }
    final acceptingStates =
        normalizedStates.where((state) => state.isAccepting).toSet();

    final alphabet = <String>{...base.alphabet};
    final stackAlphabet = <String>{
      base.initialStackSymbol,
      ...base.stackAlphabet,
    };

    for (final transition in reboundTransitions) {
      if (!transition.isLambdaInput && transition.inputSymbol.isNotEmpty) {
        alphabet.add(transition.inputSymbol);
      }
      if (!transition.isLambdaPop && transition.popSymbol.isNotEmpty) {
        stackAlphabet.add(transition.popSymbol);
      }
      if (!transition.isLambdaPush && transition.pushSymbol.isNotEmpty) {
        stackAlphabet.addAll(transition.pushSymbols);
      }
    }

    return base.copyWith(
      states: normalizedStates.toSet(),
      transitions: reboundTransitions.map<Transition>((t) => t).toSet(),
      initialState: initialState,
      acceptingStates: acceptingStates,
      alphabet: alphabet,
      stackAlphabet: stackAlphabet,
      modified: DateTime.now(),
    );
  }
}

/// Provider exposing the current PDA editor state.
final pdaEditorProvider =
    StateNotifierProvider<PDAEditorNotifier, PDAEditorState>(
  (ref) => PDAEditorNotifier(),
);
