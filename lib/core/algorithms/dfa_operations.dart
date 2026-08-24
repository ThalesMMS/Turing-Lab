//
//  dfa_operations.dart
//  Turing Lab
//
//  Consolidates high-level operations on deterministic automata, covering
//  complementation, product constructions for union/intersection/difference, and
//  prefix and suffix closures. Includes detailed validation, normalizes
//  alphabets via completeness, and delegates determinization when needed to
//  preserve the formal correctness of returned results.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'dart:collection';

import 'package:vector_math/vector_math_64.dart';

import '../models/fsa.dart';
import '../models/state.dart';
import '../models/fsa_transition.dart';
import '../models/transition.dart';
import '../result.dart';
import '../utils/epsilon_utils.dart';
import 'dfa_completer.dart';
import 'nfa_to_dfa_converter.dart';

/// Algorithms for high-level DFA and FSA manipulations used by the repository.
class DFAOperations {
  /// Validates that the provided automaton is a proper DFA for operations
  /// that assume determinism and no epsilon transitions.
  static Result<void> _validateDfa(FSA dfa, {String context = 'DFA'}) {
    if (dfa.initialState == null) {
      return ResultFactory.failure(
        '$context deve possuir estado inicial definido.',
      );
    }
    if (!dfa.isDeterministic) {
      return ResultFactory.failure(
        '$context deve ser determinístico (sem transições não determinísticas).',
      );
    }
    if (dfa.hasEpsilonTransitions) {
      return ResultFactory.failure(
        '$context não pode conter transições ε (epsilon).',
      );
    }
    // Validate transitions symbols are part of alphabet
    for (final t in dfa.fsaTransitions) {
      if (t.isEpsilonTransition) continue;
      for (final s in t.inputSymbols) {
        if (!dfa.alphabet.contains(s)) {
          return ResultFactory.failure(
            '$context possui transição com símbolo fora do alfabeto: "$s".',
          );
        }
      }
    }
    return ResultFactory.success(null);
  }

  static Result<void> _validateBinaryOperands(FSA a, FSA b, String opLabel) {
    final va = _validateDfa(a, context: 'Operando A');
    if (va.isFailure) return va;
    final vb = _validateDfa(b, context: 'Operando B');
    if (vb.isFailure) return vb;
    // Alphabets may differ; we normalize via completion on the union, but we still
    // validate that no operand has empty alphabet while having labeled transitions.
    if (a.alphabet.isEmpty &&
        a.fsaTransitions.any((t) => !t.isEpsilonTransition)) {
      return ResultFactory.failure(
        'Operando A possui transições rotuladas, mas alfabeto está vazio.',
      );
    }
    if (b.alphabet.isEmpty &&
        b.fsaTransitions.any((t) => !t.isEpsilonTransition)) {
      return ResultFactory.failure(
        'Operando B possui transições rotuladas, mas alfabeto está vazio.',
      );
    }
    return ResultFactory.success(null);
  }

  /// Computes the complement of a DFA by completing it and toggling final states.
  static Result<FSA> complement(FSA dfa) {
    try {
      final valid = _validateDfa(dfa, context: 'DFA para complemento');
      if (valid.isFailure) return ResultFactory.failure(valid.error!);
      final completed = _completeWithAlphabet(dfa, dfa.alphabet);
      final updated = _rebuildWithStateUpdate(
        completed,
        acceptingPredicate: (state) =>
            !completed.acceptingStates.contains(state),
      );
      return ResultFactory.success(updated);
    } catch (e) {
      return ResultFactory.failure('Erro ao calcular complemento do DFA: $e');
    }
  }

  /// Computes the union of two DFAs using the standard product construction.
  static Result<FSA> union(FSA a, FSA b) {
    final valid = _validateBinaryOperands(a, b, 'união');
    if (valid.isFailure) return ResultFactory.failure(valid.error!);
    return _productConstruction(
      a,
      b,
      '∪',
      (aAccepts, bAccepts) => aAccepts || bAccepts,
    );
  }

  /// Computes the intersection of two DFAs.
  static Result<FSA> intersection(FSA a, FSA b) {
    final valid = _validateBinaryOperands(a, b, 'interseção');
    if (valid.isFailure) return ResultFactory.failure(valid.error!);
    return _productConstruction(
      a,
      b,
      '∩',
      (aAccepts, bAccepts) => aAccepts && bAccepts,
    );
  }

  /// Computes the language difference a \ b for two DFAs.
  static Result<FSA> difference(FSA a, FSA b) {
    final valid = _validateBinaryOperands(a, b, 'diferença');
    if (valid.isFailure) return ResultFactory.failure(valid.error!);
    return _productConstruction(
      a,
      b,
      '\\',
      (aAccepts, bAccepts) => aAccepts && !bAccepts,
    );
  }

  /// Computes the prefix-closure of a DFA by marking every state that can
  /// reach an accepting state as accepting.
  static Result<FSA> prefixClosure(FSA dfa) {
    try {
      final valid = _validateDfa(dfa, context: 'DFA para fecho por prefixos');
      if (valid.isFailure) return ResultFactory.failure(valid.error!);
      final completed = _completeWithAlphabet(dfa, dfa.alphabet);
      final reachable = _statesThatReachAccepting(completed);
      final updated = _rebuildWithStateUpdate(
        completed,
        acceptingPredicate: reachable.contains,
      );
      return ResultFactory.success(updated);
    } catch (e) {
      return ResultFactory.failure('Erro ao calcular fecho por prefixos: $e');
    }
  }

  /// Computes the suffix-closure of a DFA.
  ///
  /// This is achieved by adding a fresh initial state with ε-transitions to all
  /// states reachable from the original initial state and determinising the
  /// resulting NFA.
  static Result<FSA> suffixClosure(FSA dfa) {
    try {
      final valid = _validateDfa(dfa, context: 'DFA para fecho por sufixos');
      if (valid.isFailure) return ResultFactory.failure(valid.error!);
      if (dfa.initialState == null) {
        return ResultFactory.failure(
          'Automato não possui estado inicial definido.',
        );
      }

      final completed = _completeWithAlphabet(dfa, dfa.alphabet);
      final reachable = _statesReachableFromInitial(completed);
      final stateCopies = <String, State>{
        for (final state in completed.states)
          state.id: state.copyWith(
            isInitial: false,
            isAccepting: completed.acceptingStates.contains(state),
          ),
      };

      final newInitial = State(
        id: '${completed.initialState!.id}_suffix_start',
        label: 'start',
        position: completed.initialState!.position + Vector2(40, -40),
        isInitial: true,
        isAccepting: reachable.any(
          (state) => completed.acceptingStates.contains(state),
        ),
      );

      final transitions = <FSATransition>{
        for (final transition in completed.fsaTransitions)
          transition.copyWith(
            fromState: stateCopies[transition.fromState.id],
            toState: stateCopies[transition.toState.id],
          ),
      };

      for (final state in reachable) {
        final target = stateCopies[state.id];
        if (target != null) {
          transitions.add(
            FSATransition.epsilon(
              id: 't_suffix_${newInitial.id}_${target.id}',
              fromState: newInitial,
              toState: target,
            ),
          );
        }
      }

      final nfaStates = stateCopies.values.toSet()..add(newInitial);
      final nfa = FSA(
        id: '${dfa.id}_suffix_nfa',
        name: '${dfa.name} (Suffix Closure NFA)',
        states: nfaStates,
        transitions: transitions,
        alphabet: completed.alphabet,
        initialState: newInitial,
        acceptingStates: nfaStates.where((s) => s.isAccepting).toSet(),
        created: completed.created,
        modified: DateTime.now(),
        bounds: completed.bounds,
        zoomLevel: completed.zoomLevel,
        panOffset: completed.panOffset,
      );

      final determinised = NFAToDFAConverter.convert(nfa);
      if (determinised.isFailure) {
        return ResultFactory.failure(determinised.error!);
      }

      final dfaResult = determinised.data!;
      final renamed = dfaResult.copyWith(
        id: '${dfa.id}_suffix_closure',
        name: '${dfa.name} (Suffix Closure)',
        modified: DateTime.now(),
      );

      return ResultFactory.success(renamed);
    } catch (e) {
      return ResultFactory.failure('Erro ao calcular fecho por sufixos: $e');
    }
  }

  static Result<FSA> _productConstruction(
    FSA a,
    FSA b,
    String operation,
    bool Function(bool, bool) acceptancePredicate,
  ) {
    try {
      if (a.initialState == null || b.initialState == null) {
        return ResultFactory.failure(
          'Ambos DFAs precisam ter estado inicial definido.',
        );
      }

      final combinedAlphabet = {...a.alphabet, ...b.alphabet};
      final completedA = _completeWithAlphabet(a, combinedAlphabet);
      final completedB = _completeWithAlphabet(b, combinedAlphabet);

      final queue = Queue<(State, State)>();
      final visited = <String, State>{};
      final transitions = <FSATransition>{};

      State createState(State first, State second, {required bool isInitial}) {
        final isAccepting = acceptancePredicate(
          completedA.acceptingStates.contains(first),
          completedB.acceptingStates.contains(second),
        );

        final state = State(
          id: '${first.id}_${second.id}',
          label: '(${first.label},${second.label})',
          position: (first.position + second.position) / 2,
          isInitial: isInitial,
          isAccepting: isAccepting,
        );
        return state;
      }

      State getOrCreate(State first, State second, {required bool isInitial}) {
        final key = '${first.id}|${second.id}';
        final existing = visited[key];
        if (existing != null) {
          return existing;
        }
        final created = createState(first, second, isInitial: isInitial);
        visited[key] = created;
        queue.add((first, second));
        return created;
      }

      State nextState(FSA dfa, State state, String symbol) {
        final transitionsForSymbol = dfa
            .getTransitionsFromStateOnSymbol(state, symbol)
            .whereType<FSATransition>()
            .toList();
        if (transitionsForSymbol.isEmpty) {
          throw StateError(
            'Deterministic automaton expected transition for $symbol',
          );
        }
        return transitionsForSymbol.first.toState;
      }

      final initialState = getOrCreate(
        completedA.initialState!,
        completedB.initialState!,
        isInitial: true,
      );

      while (queue.isNotEmpty) {
        final (stateA, stateB) = queue.removeFirst();
        final currentKey = '${stateA.id}|${stateB.id}';
        final currentState = visited[currentKey]!;

        for (final symbol in combinedAlphabet) {
          final nextA = nextState(completedA, stateA, symbol);
          final nextB = nextState(completedB, stateB, symbol);
          final targetState = getOrCreate(nextA, nextB, isInitial: false);
          transitions.add(
            FSATransition.deterministic(
              id: 't_${currentState.id}_${symbol}_${targetState.id}',
              fromState: currentState,
              toState: targetState,
              symbol: symbol,
            ),
          );
        }
      }

      final states = visited.values.toSet();
      final acceptingStates = states.where((s) => s.isAccepting).toSet();

      final product = FSA(
        id: '${a.id}_${operation}_${b.id}',
        name: '${a.name} $operation ${b.name}',
        states: states,
        transitions: transitions,
        alphabet: combinedAlphabet,
        initialState: initialState,
        acceptingStates: acceptingStates,
        created: a.created,
        modified: DateTime.now(),
        bounds: a.bounds,
        zoomLevel: a.zoomLevel,
        panOffset: a.panOffset,
      );

      return ResultFactory.success(product);
    } catch (e) {
      return ResultFactory.failure('Erro ao combinar DFAs ($operation): $e');
    }
  }

  static FSA _completeWithAlphabet(FSA dfa, Set<String> alphabet) {
    final updated = dfa.copyWith(alphabet: alphabet);
    return DFACompleter.complete(updated);
  }

  static FSA _rebuildWithStateUpdate(
    FSA base, {
    required bool Function(State) acceptingPredicate,
  }) {
    final stateCopies = <String, State>{};
    for (final state in base.states) {
      final newState = state.copyWith(
        isInitial: base.initialState?.id == state.id,
        isAccepting: acceptingPredicate(state),
      );
      stateCopies[state.id] = newState;
    }

    final transitions = <FSATransition>{};
    for (final transition in base.fsaTransitions) {
      final fromState = stateCopies[transition.fromState.id]!;
      final toState = stateCopies[transition.toState.id]!;
      transitions.add(
        transition.copyWith(fromState: fromState, toState: toState),
      );
    }

    final states = stateCopies.values.toSet();
    final acceptingStates = states.where((s) => s.isAccepting).toSet();

    return FSA(
      id: base.id,
      name: base.name,
      states: states,
      transitions: transitions,
      alphabet: base.alphabet,
      initialState: stateCopies[base.initialState?.id],
      acceptingStates: acceptingStates,
      created: base.created,
      modified: DateTime.now(),
      bounds: base.bounds,
      zoomLevel: base.zoomLevel,
      panOffset: base.panOffset,
    );
  }

  static Set<State> _statesThatReachAccepting(FSA dfa) {
    final reverseMap = <String, Set<State>>{};
    for (final transition in dfa.fsaTransitions) {
      reverseMap.putIfAbsent(transition.toState.id, () => <State>{});
      reverseMap[transition.toState.id]!.add(transition.fromState);
    }

    final stack = List<State>.from(dfa.acceptingStates);
    final reachable = <State>{...dfa.acceptingStates};

    while (stack.isNotEmpty) {
      final state = stack.removeLast();
      for (final predecessor in reverseMap[state.id] ?? const <State>{}) {
        if (reachable.add(predecessor)) {
          stack.add(predecessor);
        }
      }
    }

    return reachable;
  }

  static Set<State> _statesReachableFromInitial(FSA dfa) {
    if (dfa.initialState == null) {
      return const <State>{};
    }

    final visited = <State>{};
    final queue = Queue<State>()..add(dfa.initialState!);
    visited.add(dfa.initialState!);

    while (queue.isNotEmpty) {
      final state = queue.removeFirst();
      for (final transition
          in dfa.getTransitionsFrom(state).whereType<FSATransition>()) {
        if (visited.add(transition.toState)) {
          queue.add(transition.toState);
        }
      }
    }

    return visited;
  }
}

/// Algorithms for NFA manipulation.
class FSAOperations {
  /// Removes lambda (epsilon) transitions from an FSA, producing an equivalent
  /// automaton without lambda transitions.
  static Result<FSA> removeLambdaTransitions(FSA automaton) {
    try {
      final stateCopies = <String, State>{
        for (final state in automaton.states)
          state.id: state.copyWith(
            isInitial: automaton.initialState?.id == state.id,
            isAccepting: false,
          ),
      };

      final epsilonClosures = <String, Set<State>>{
        for (final state in automaton.states)
          state.id: automaton.getEpsilonClosure(state),
      };

      final acceptingStates = <State>{};
      stateCopies.updateAll((id, state) {
        final closure = epsilonClosures[id]!;
        final isAccepting = closure.any(automaton.acceptingStates.contains);
        final updated = state.copyWith(isAccepting: isAccepting);
        if (isAccepting) {
          acceptingStates.add(updated);
        }
        return updated;
      });

      final alphabet = automaton.alphabet
          .where((symbol) => !isEpsilonSymbol(symbol))
          .toSet();
      final newTransitions = <FSATransition>{};

      for (final state in automaton.states) {
        final closure = epsilonClosures[state.id]!;
        for (final symbol in alphabet) {
          final destinations = <State>{};
          for (final closureState in closure) {
            final outgoing = automaton
                .getTransitionsFromStateOnSymbol(closureState, symbol)
                .whereType<FSATransition>();
            for (final transition in outgoing) {
              destinations.addAll(epsilonClosures[transition.toState.id]!);
            }
          }

          if (destinations.isNotEmpty) {
            final fromState = stateCopies[state.id]!;
            final transitionType = destinations.length > 1
                ? TransitionType.nondeterministic
                : TransitionType.deterministic;
            for (final destination in destinations) {
              final toState = stateCopies[destination.id]!;
              newTransitions.add(
                FSATransition(
                  id: 't_${fromState.id}_${symbol}_${toState.id}',
                  fromState: fromState,
                  toState: toState,
                  label: symbol,
                  inputSymbols: {symbol},
                  lambdaSymbol: null,
                  type: transitionType,
                ),
              );
            }
          }
        }
      }

      final initialState = automaton.initialState != null
          ? stateCopies[automaton.initialState!.id]
          : null;

      final resultingFsa = FSA(
        id: '${automaton.id}_no_lambda',
        name: '${automaton.name} (λ-removed)',
        states: stateCopies.values.toSet(),
        transitions: newTransitions,
        alphabet: alphabet,
        initialState: initialState,
        acceptingStates: stateCopies.values.where((s) => s.isAccepting).toSet(),
        created: automaton.created,
        modified: DateTime.now(),
        bounds: automaton.bounds,
        zoomLevel: automaton.zoomLevel,
        panOffset: automaton.panOffset,
      );

      return ResultFactory.success(resultingFsa);
    } catch (e) {
      return ResultFactory.failure('Erro ao remover transições lambda: $e');
    }
  }
}
