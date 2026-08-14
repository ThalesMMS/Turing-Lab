//
//  equivalence_checker.dart
//  Turing Lab
//
//  Implementa verificação de equivalência entre dois autômatos finitos,
//  normalizando alfabetos, convertendo NFAs para DFAs e completando transições
//  antes de percorrer o produto cartesiano. Utiliza busca em largura para
//  detectar divergências de aceitação e retorna rapidamente quando linguagens
//  diferem.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'dart:collection';

import '../models/fsa.dart';
import '../models/state.dart';
import '../result.dart';
import 'dfa_completer.dart';
import 'fsa_determinizer.dart';

class EquivalenceChecker {
  /// Legacy boolean API.
  ///
  /// Returns false for both real non-equivalence and comparison failures to
  /// preserve existing callers. Use [areEquivalentResult] when failure details
  /// such as determinization errors must be distinguished from non-equivalence.
  static bool areEquivalent(FSA a, FSA b) {
    return areEquivalentResult(a, b).data ?? false;
  }

  /// Compares two automata and preserves validation/conversion failures.
  static Result<bool> areEquivalentResult(FSA a, FSA b) {
    // If either has no initial state, not equivalent per tests
    if (a.initialState == null || b.initialState == null) {
      return ResultFactory.success(false);
    }

    // Enforce alphabet equality per tests (explicit requirement in suite)
    if (a.alphabet.isEmpty && b.alphabet.isEmpty) {
      // fall through; empty but equal
    } else if (a.alphabet.length != b.alphabet.length ||
        !a.alphabet.containsAll(b.alphabet)) {
      return ResultFactory.success(false);
    }

    // Convert NFAs to DFAs if necessary
    final dfaAResult = FSADeterminizer.determinizeIfNeeded(a, 'A');
    if (dfaAResult.isFailure) {
      return ResultFactory.failure(dfaAResult.error!);
    }
    final dfaBResult = FSADeterminizer.determinizeIfNeeded(b, 'B');
    if (dfaBResult.isFailure) {
      return ResultFactory.failure(dfaBResult.error!);
    }
    final dfaA = dfaAResult.data!;
    final dfaB = dfaBResult.data!;

    // Use shared alphabet (after conversion) and complete both DFAs
    final sharedAlphabet = dfaA.alphabet.union(dfaB.alphabet);
    final completedA = DFACompleter.complete(
      dfaA.copyWith(alphabet: sharedAlphabet),
    );
    final completedB = DFACompleter.complete(
      dfaB.copyWith(alphabet: sharedAlphabet),
    );

    final initialA = completedA.initialState!;
    final initialB = completedB.initialState!;

    // BFS over product automaton; early-exit on differing acceptance
    final visited = <String>{'${initialA.id},${initialB.id}'};
    final queue = Queue<List<State>>()..add([initialA, initialB]);

    while (queue.isNotEmpty) {
      final pair = queue.removeFirst();
      final sA = pair[0];
      final sB = pair[1];

      final accA = completedA.acceptingStates.contains(sA);
      final accB = completedB.acceptingStates.contains(sB);
      if (accA != accB) return ResultFactory.success(false);

      for (final symbol in sharedAlphabet) {
        final nextASet = completedA.getTransitionsFromStateOnSymbol(sA, symbol);
        final nextBSet = completedB.getTransitionsFromStateOnSymbol(sB, symbol);

        // DFAs completed → exactly one transition per symbol
        final nextA = nextASet.isNotEmpty ? nextASet.first.toState : null;
        final nextB = nextBSet.isNotEmpty ? nextBSet.first.toState : null;

        if (nextA == null || nextB == null) {
          return ResultFactory.success(false); // completion invariant broken
        }
        final key = '${nextA.id},${nextB.id}';
        if (visited.add(key)) {
          queue.add([nextA, nextB]);
        }
      }
    }

    return ResultFactory.success(true);
  }
}
