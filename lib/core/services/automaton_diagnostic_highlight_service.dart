import '../models/fsa.dart';
import '../models/simulation_highlight.dart';

/// Builds read-only canvas highlights for standalone automaton diagnostics.
class AutomatonDiagnosticHighlightService {
  const AutomatonDiagnosticHighlightService();

  /// Finds FSA transitions that compete for the same state and input symbol.
  ///
  /// Epsilon transitions are kept out of this result because they have their
  /// own diagnostic action.
  Set<String> conflictingFsaTransitionIds(FSA? automaton) {
    if (automaton == null) return const <String>{};

    final byStateAndSymbol = <(String, String), Set<String>>{};
    for (final transition in automaton.fsaTransitions) {
      if (transition.isEpsilonTransition) continue;
      for (final symbol in transition.inputSymbols) {
        byStateAndSymbol.putIfAbsent(
          (transition.fromState.id, symbol),
          () => <String>{},
        ).add(transition.id);
      }
    }

    return Set<String>.unmodifiable(
      byStateAndSymbol.values
          .where((transitionIds) => transitionIds.length > 1)
          .expand((transitionIds) => transitionIds),
    );
  }

  Set<String> epsilonFsaTransitionIds(FSA? automaton) {
    if (automaton == null) return const <String>{};
    return Set<String>.unmodifiable(
      automaton.epsilonTransitions.map((transition) => transition.id),
    );
  }

  SimulationHighlight transitionHighlight(Iterable<String> transitionIds) {
    return SimulationHighlight(
      transitionIds: Set<String>.unmodifiable(transitionIds),
    );
  }
}
