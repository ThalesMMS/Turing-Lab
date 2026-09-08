//
//  dfa_completion_practice.dart
//  Turing Lab
//
//  Audits how far a learner is from a complete DFA: which (state, symbol)
//  pairs still lack a transition, whether a trap (non-accepting sink) state
//  exists, and which hint applies next. The audit is pure and reads the same
//  transition rule DFACompleter uses, so practicing by hand and completing
//  automatically agree on when the DFA is complete.
//

import '../../models/fsa.dart';
import '../../models/fsa_transition.dart';
import '../../models/state.dart';

/// A state that still lacks a transition on [symbol].
class MissingDfaTransition {
  const MissingDfaTransition({required this.state, required this.symbol});

  final State state;
  final String symbol;
}

enum DfaCompletionPracticeStatus {
  /// No automaton is loaded.
  noAutomaton,

  /// The automaton has no input alphabet, so there is nothing to complete.
  emptyAlphabet,

  /// Epsilon or duplicate-symbol transitions make the automaton an NFA.
  notDeterministic,

  /// At least one (state, symbol) pair has no transition.
  incomplete,

  /// Every state has exactly one transition per alphabet symbol.
  complete,
}

/// Next guidance for the learner, ordered by the construction JFLAP teaches:
/// create the trap state, route every missing pair to it, then loop it.
enum DfaCompletionHint {
  createTrapState,
  routeMissingToTrap,
  loopTrapOnEverySymbol,
}

class DfaCompletionAudit {
  const DfaCompletionAudit({
    required this.status,
    required this.alphabet,
    required this.missing,
    required this.trapCandidates,
    required this.hint,
  });

  final DfaCompletionPracticeStatus status;

  /// Sorted input alphabet.
  final List<String> alphabet;

  /// Missing pairs sorted by state id, then symbol.
  final List<MissingDfaTransition> missing;

  /// Non-initial, non-accepting states whose defined transitions all return
  /// to themselves: the states a learner can use as the trap.
  final List<State> trapCandidates;

  final DfaCompletionHint? hint;

  bool get isComplete => status == DfaCompletionPracticeStatus.complete;
}

abstract final class DfaCompletionPractice {
  static DfaCompletionAudit audit(FSA? dfa) {
    if (dfa == null) {
      return const DfaCompletionAudit(
        status: DfaCompletionPracticeStatus.noAutomaton,
        alphabet: [],
        missing: [],
        trapCandidates: [],
        hint: null,
      );
    }
    final alphabet = dfa.alphabet.where((s) => s.isNotEmpty).toList()..sort();
    if (alphabet.isEmpty) {
      return DfaCompletionAudit(
        status: DfaCompletionPracticeStatus.emptyAlphabet,
        alphabet: alphabet,
        missing: const [],
        trapCandidates: const [],
        hint: null,
      );
    }
    final states = dfa.states.toList()..sort((a, b) => a.id.compareTo(b.id));
    final transitions = dfa.fsaTransitions;
    if (!dfa.isDeterministic) {
      return DfaCompletionAudit(
        status: DfaCompletionPracticeStatus.notDeterministic,
        alphabet: alphabet,
        missing: const [],
        trapCandidates: const [],
        hint: null,
      );
    }

    final missing = <MissingDfaTransition>[
      for (final state in states)
        for (final symbol in alphabet)
          if (!_hasTransition(transitions, state, symbol))
            MissingDfaTransition(state: state, symbol: symbol),
    ];
    final initialId = dfa.initialState?.id;
    final trapCandidates = <State>[
      for (final state in states)
        if (state.id != initialId &&
            !dfa.acceptingStates.any((s) => s.id == state.id) &&
            _isSink(transitions, state))
          state,
    ];

    if (missing.isEmpty) {
      return DfaCompletionAudit(
        status: DfaCompletionPracticeStatus.complete,
        alphabet: alphabet,
        missing: missing,
        trapCandidates: trapCandidates,
        hint: null,
      );
    }

    final DfaCompletionHint hint;
    if (trapCandidates.isEmpty) {
      hint = DfaCompletionHint.createTrapState;
    } else {
      final trapIds = trapCandidates.map((s) => s.id).toSet();
      final missingOutsideTrap = missing.any(
        (entry) => !trapIds.contains(entry.state.id),
      );
      hint = missingOutsideTrap
          ? DfaCompletionHint.routeMissingToTrap
          : DfaCompletionHint.loopTrapOnEverySymbol;
    }
    return DfaCompletionAudit(
      status: DfaCompletionPracticeStatus.incomplete,
      alphabet: alphabet,
      missing: missing,
      trapCandidates: trapCandidates,
      hint: hint,
    );
  }

  static bool _hasTransition(
    Set<FSATransition> transitions,
    State state,
    String symbol,
  ) {
    return transitions.any(
      (transition) =>
          transition.fromState.id == state.id &&
          transition.inputSymbols.contains(symbol),
    );
  }

  /// A sink keeps every defined transition on itself. A state with no
  /// outgoing transitions also qualifies: it is the natural trap in progress.
  static bool _isSink(Set<FSATransition> transitions, State state) {
    return transitions
        .where((transition) => transition.fromState.id == state.id)
        .every((transition) => transition.toState.id == state.id);
  }
}
