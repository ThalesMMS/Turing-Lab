//
//  epsilon_utils.dart
//  Turing Lab
//
//  Utility helpers for working with epsilon (empty string) symbols across the
//  application layers. Centralises the canonical representation and the set of
//  recognised aliases so persistence, services and UI components stay in sync.
//

import 'dart:collection';

const String kEpsilonSymbol = 'ε';

/// Normalised aliases that should be treated as epsilon/empty-string symbols.
const Set<String> _epsilonAliases = {
  'ε',
  'lambda',
  'λ',
  'epsilon',
  'varepsilon',
  'eps',
  'empty',
  'vazio',
  '∅',
  'ø',
};

/// Returns `true` when [symbol] represents an epsilon (empty string) value.
bool isEpsilonSymbol(String? symbol) {
  final trimmed = symbol?.trim() ?? '';
  if (trimmed.isEmpty) {
    return true;
  }

  final normalised = trimmed.toLowerCase();
  return _epsilonAliases.contains(normalised);
}

/// Normalises [symbol] to the canonical epsilon representation when needed.
String normalizeToEpsilon(String? symbol) {
  if (isEpsilonSymbol(symbol)) {
    return kEpsilonSymbol;
  }
  return symbol?.trim() ?? '';
}

/// Computes the transitive epsilon closure of [seeds].
///
/// Callers provide epsilon-only destinations so the traversal stays shared
/// while adjacency storage remains specific to each algorithm.
Set<T> computeEpsilonClosure<T>(
  Iterable<T> seeds,
  Iterable<T> Function(T state) epsilonDestinations,
) {
  final closure = <T>{...seeds};
  final queue = Queue<T>.of(closure);

  while (queue.isNotEmpty) {
    final state = queue.removeFirst();
    for (final destination in epsilonDestinations(state)) {
      if (closure.add(destination)) {
        queue.add(destination);
      }
    }
  }

  return closure;
}

/// Extracts the state identifier portion from a transition key formatted as
/// `stateId|symbol`. Keys without the separator are returned as-is.
String extractStateIdFromTransitionKey(String key) {
  final separatorIndex = key.indexOf('|');
  if (separatorIndex == -1) {
    return key.trim();
  }
  return key.substring(0, separatorIndex).trim();
}

/// Extracts the symbol portion from a transition key formatted as
/// `stateId|symbol`. Empty or missing symbols are preserved as empty strings so
/// callers can decide how to normalise them.
String extractSymbolFromTransitionKey(String key) {
  final separatorIndex = key.indexOf('|');
  if (separatorIndex == -1 || separatorIndex + 1 >= key.length) {
    return '';
  }
  return key.substring(separatorIndex + 1);
}
