//
//  language_comparator.dart
//  Turing Lab
//
//  Implementa a comparação de linguagens entre dois autômatos finitos via
//  construção do autômato produto. Detecta equivalência ou não-equivalência,
//  gerando strings distinguidoras quando as linguagens divergem. Utiliza
//  busca em largura sobre pares de estados para determinar se os autômatos
//  reconhecem o mesmo conjunto de palavras.
//
//  Thales Matheus Mendonça Santos - January 2026
//
import 'dart:collection';

import '../models/fsa.dart';
import '../models/state.dart';
import '../models/fsa_transition.dart';
import '../models/equivalence_comparison_result.dart';
import '../result.dart';
import '../utils/epsilon_utils.dart';
import 'dfa_completer.dart';
import 'fsa_determinizer.dart';

/// Compares two automata to determine if they recognize the same language
class LanguageComparator {
  /// Compares two automata and determines if they recognize the same language
  ///
  /// Returns a Result containing EquivalenceComparisonResult with:
  /// - isEquivalent: whether the automata are equivalent
  /// - distinguishingString: a string accepted by one but not the other (if not equivalent)
  /// - executionTimeMs: time taken to perform the comparison
  static Result<EquivalenceComparisonResult> compareLanguages(
    FSA automatonA,
    FSA automatonB,
  ) {
    try {
      final stopwatch = Stopwatch()..start();
      final steps = <Map<String, dynamic>>[];
      var stepCounter = 0;

      // Validate inputs
      steps.add({
        'stepNumber': stepCounter++,
        'type': 'validation',
        'description': 'Validating input automata',
        'data': {'automatonA': automatonA.name, 'automatonB': automatonB.name},
      });

      final validationResult = _validateInputs(automatonA, automatonB);
      if (!validationResult.isSuccess) {
        return ResultFactory.failure(validationResult.error!);
      }

      // Normalize alphabets - combine both alphabets
      final sharedAlphabet = automatonA.alphabet
          .union(automatonB.alphabet)
          .where((s) => !isEpsilonSymbol(s))
          .toSet();

      steps.add({
        'stepNumber': stepCounter++,
        'type': 'alphabet_normalization',
        'description': 'Combining alphabets from both automata',
        'data': {
          'alphabetA': automatonA.alphabet.toList(),
          'alphabetB': automatonB.alphabet.toList(),
          'sharedAlphabet': sharedAlphabet.toList(),
        },
      });

      // Convert NFAs to DFAs if necessary
      final dfaAResult = FSADeterminizer.determinizeIfNeeded(
        automatonA.copyWith(alphabet: sharedAlphabet),
        'A',
      );
      if (dfaAResult.isFailure) {
        return ResultFactory.failure(dfaAResult.error!);
      }
      final dfaA = dfaAResult.data!;

      if (!automatonA.isDeterministic) {
        steps.add({
          'stepNumber': stepCounter++,
          'type': 'nfa_to_dfa',
          'description': 'Converting automaton A from NFA to DFA',
          'data': {
            'automaton': 'A',
            'statesBefore': automatonA.states.length,
            'statesAfter': dfaA.states.length,
          },
        });
      }

      final dfaBResult = FSADeterminizer.determinizeIfNeeded(
        automatonB.copyWith(alphabet: sharedAlphabet),
        'B',
      );
      if (dfaBResult.isFailure) {
        return ResultFactory.failure(dfaBResult.error!);
      }
      final dfaB = dfaBResult.data!;

      if (!automatonB.isDeterministic) {
        steps.add({
          'stepNumber': stepCounter++,
          'type': 'nfa_to_dfa',
          'description': 'Converting automaton B from NFA to DFA',
          'data': {
            'automaton': 'B',
            'statesBefore': automatonB.states.length,
            'statesAfter': dfaB.states.length,
          },
        });
      }

      // Complete both DFAs to ensure all transitions are defined
      final completedA = DFACompleter.complete(dfaA);
      steps.add({
        'stepNumber': stepCounter++,
        'type': 'dfa_completion',
        'description': 'Completing DFA A with sink state if needed',
        'data': {
          'automaton': 'A',
          'statesBefore': dfaA.states.length,
          'statesAfter': completedA.states.length,
          'wasCompleted': dfaA.states.length != completedA.states.length,
        },
      });

      final completedB = DFACompleter.complete(dfaB);
      steps.add({
        'stepNumber': stepCounter++,
        'type': 'dfa_completion',
        'description': 'Completing DFA B with sink state if needed',
        'data': {
          'automaton': 'B',
          'statesBefore': dfaB.states.length,
          'statesAfter': completedB.states.length,
          'wasCompleted': dfaB.states.length != completedB.states.length,
        },
      });

      // Construct the product automaton
      steps.add({
        'stepNumber': stepCounter++,
        'type': 'product_construction_start',
        'description': 'Starting product automaton construction',
        'data': {'alphabetSize': sharedAlphabet.length},
      });

      final productResult = _constructProductAutomaton(
        completedA,
        completedB,
        sharedAlphabet,
        steps,
        stepCounter,
      );

      stepCounter = steps.length;

      // Perform BFS over product automaton to find distinguishing string
      steps.add({
        'stepNumber': stepCounter++,
        'type': 'bfs_search_start',
        'description': 'Starting BFS search for distinguishing string',
        'data': {
          'initialStateA': completedA.initialState?.label,
          'initialStateB': completedB.initialState?.label,
        },
      });

      final comparisonResult = _performBFSComparison(
        completedA,
        completedB,
        sharedAlphabet,
        steps,
        stepCounter,
      );

      stepCounter = steps.length;

      // Add final result step
      steps.add({
        'stepNumber': stepCounter++,
        'type': 'result',
        'description': comparisonResult.isEquivalent
            ? 'Automata are equivalent - same language recognized'
            : 'Automata are not equivalent - distinguishing string found',
        'data': {
          'isEquivalent': comparisonResult.isEquivalent,
          'distinguishingString': comparisonResult.distinguishingString,
        },
      });

      stopwatch.stop();

      return ResultFactory.success(
        EquivalenceComparisonResult(
          originalAutomaton: automatonA,
          comparedAutomaton: automatonB,
          isEquivalent: comparisonResult.isEquivalent,
          distinguishingString: comparisonResult.distinguishingString,
          productAutomaton: productResult,
          steps: steps,
          executionTimeMs: stopwatch.elapsedMilliseconds,
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      return ResultFactory.failure('Error comparing languages: $e');
    }
  }

  /// Validates the input automata
  static Result<void> _validateInputs(FSA automatonA, FSA automatonB) {
    // Check automaton A
    if (automatonA.states.isEmpty) {
      return ResultFactory.failure('Automaton A must have at least one state');
    }
    if (automatonA.initialState == null) {
      return ResultFactory.failure('Automaton A must have an initial state');
    }
    if (!automatonA.states.contains(automatonA.initialState)) {
      return ResultFactory.failure(
        'Initial state of automaton A must be in the states set',
      );
    }

    // Check automaton B
    if (automatonB.states.isEmpty) {
      return ResultFactory.failure('Automaton B must have at least one state');
    }
    if (automatonB.initialState == null) {
      return ResultFactory.failure('Automaton B must have an initial state');
    }
    if (!automatonB.states.contains(automatonB.initialState)) {
      return ResultFactory.failure(
        'Initial state of automaton B must be in the states set',
      );
    }

    return ResultFactory.success(null);
  }

  /// Constructs the product automaton for two DFAs
  ///
  /// The product automaton has states representing pairs of states from the
  /// input automata. A product state is marked as accepting if and only if
  /// the two component states have different acceptance statuses, which helps
  /// visualize where the languages differ.
  static FSA _constructProductAutomaton(
    FSA dfaA,
    FSA dfaB,
    Set<String> alphabet,
    List<Map<String, dynamic>> steps,
    int stepCounter,
  ) {
    final queue = Queue<(State, State)>();
    final visited = <String, State>{};
    final transitions = <FSATransition>{};

    State createState(State first, State second, {required bool isInitial}) {
      final acceptsA = dfaA.acceptingStates.contains(first);
      final acceptsB = dfaB.acceptingStates.contains(second);

      // Mark as accepting if acceptance statuses differ (indicates non-equivalence)
      final isAccepting = acceptsA != acceptsB;

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
      dfaA.initialState!,
      dfaB.initialState!,
      isInitial: true,
    );

    steps.add({
      'stepNumber': stepCounter++,
      'type': 'product_state_created',
      'description': 'Created initial product state',
      'data': {
        'stateA': dfaA.initialState!.label,
        'stateB': dfaB.initialState!.label,
        'productState': initialState.label,
        'isAccepting': initialState.isAccepting,
      },
    });

    while (queue.isNotEmpty) {
      final (stateA, stateB) = queue.removeFirst();
      final currentKey = '${stateA.id}|${stateB.id}';
      final currentState = visited[currentKey]!;

      for (final symbol in alphabet) {
        final nextA = nextState(dfaA, stateA, symbol);
        final nextB = nextState(dfaB, stateB, symbol);
        final targetState = getOrCreate(nextA, nextB, isInitial: false);
        transitions.add(
          FSATransition.deterministic(
            id: 't_${currentState.id}_${symbol}_${targetState.id}',
            fromState: currentState,
            toState: targetState,
            symbol: symbol,
          ),
        );

        steps.add({
          'stepNumber': stepCounter++,
          'type': 'product_transition_created',
          'description':
              'Created transition on symbol \'$symbol\' in product automaton',
          'data': {
            'fromState': currentState.label,
            'toState': targetState.label,
            'symbol': symbol,
            'targetIsNew': queue.contains((nextA, nextB)),
          },
        });
      }
    }

    final states = visited.values.toSet();
    final acceptingStates = states.where((s) => s.isAccepting).toSet();

    steps.add({
      'stepNumber': stepCounter++,
      'type': 'product_construction_complete',
      'description': 'Product automaton construction complete',
      'data': {
        'totalStates': states.length,
        'totalTransitions': transitions.length,
        'acceptingStates': acceptingStates.length,
      },
    });

    final product = FSA(
      id: '${dfaA.id}_×_${dfaB.id}',
      name: '${dfaA.name} × ${dfaB.name}',
      states: states,
      transitions: transitions,
      alphabet: alphabet,
      initialState: initialState,
      acceptingStates: acceptingStates,
      created: dfaA.created,
      modified: DateTime.now(),
      bounds: dfaA.bounds,
      zoomLevel: dfaA.zoomLevel,
      panOffset: dfaA.panOffset,
    );

    return product;
  }

  /// Performs BFS traversal over the product automaton to check equivalence
  static _ComparisonResult _performBFSComparison(
    FSA dfaA,
    FSA dfaB,
    Set<String> alphabet,
    List<Map<String, dynamic>> steps,
    int stepCounter,
  ) {
    final initialA = dfaA.initialState!;
    final initialB = dfaB.initialState!;

    // Check initial states first - early exit optimization
    final initialAccA = dfaA.acceptingStates.contains(initialA);
    final initialAccB = dfaB.acceptingStates.contains(initialB);
    if (initialAccA != initialAccB) {
      steps.add({
        'stepNumber': stepCounter++,
        'type': 'bfs_initial_check',
        'description':
            'Initial states have different acceptance - empty string distinguishes',
        'data': {
          'stateA': initialA.label,
          'stateB': initialB.label,
          'acceptsA': initialAccA,
          'acceptsB': initialAccB,
        },
      });

      // Empty string is a counterexample
      return _ComparisonResult(isEquivalent: false, distinguishingString: '');
    }

    steps.add({
      'stepNumber': stepCounter++,
      'type': 'bfs_initial_check',
      'description': 'Initial states have same acceptance status',
      'data': {
        'stateA': initialA.label,
        'stateB': initialB.label,
        'acceptsA': initialAccA,
        'acceptsB': initialAccB,
      },
    });

    // BFS queue: each entry is a state pair and the path to reach it
    final queue = Queue<_StatePairWithPath>()
      ..add(
        _StatePairWithPath(stateA: initialA, stateB: initialB, path: []),
      );

    // Track visited state pairs to avoid cycles
    final visited = <String>{'${initialA.id},${initialB.id}'};

    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      final stateA = current.stateA;
      final stateB = current.stateB;
      final path = current.path;

      steps.add({
        'stepNumber': stepCounter++,
        'type': 'bfs_explore_pair',
        'description':
            'Exploring state pair (${stateA.label}, ${stateB.label})',
        'data': {
          'stateA': stateA.label,
          'stateB': stateB.label,
          'pathLength': path.length,
          'currentPath': path.join(''),
        },
      });

      // Explore all transitions on each symbol in the alphabet
      for (final symbol in alphabet) {
        final nextATransitions = dfaA.getTransitionsFromStateOnSymbol(
          stateA,
          symbol,
        );
        final nextBTransitions = dfaB.getTransitionsFromStateOnSymbol(
          stateB,
          symbol,
        );

        // Both DFAs are completed, so there should be exactly one transition
        if (nextATransitions.isEmpty || nextBTransitions.isEmpty) {
          continue; // Should not happen with completed DFAs, but handle gracefully
        }

        final nextA = nextATransitions.first.toState;
        final nextB = nextBTransitions.first.toState;

        final pairKey = '${nextA.id},${nextB.id}';
        if (!visited.contains(pairKey)) {
          visited.add(pairKey);

          // Check if acceptance status differs for this next state pair
          final accA = dfaA.acceptingStates.contains(nextA);
          final accB = dfaB.acceptingStates.contains(nextB);

          if (accA != accB) {
            // Found a distinguishing string - reconstruct the path
            final counterexamplePath = [...path, symbol];
            final distinguishingString = counterexamplePath.join('');

            steps.add({
              'stepNumber': stepCounter++,
              'type': 'bfs_distinguishing_found',
              'description':
                  'Found distinguishing string: \'$distinguishingString\'',
              'data': {
                'stateA': nextA.label,
                'stateB': nextB.label,
                'acceptsA': accA,
                'acceptsB': accB,
                'distinguishingString': distinguishingString,
                'symbol': symbol,
              },
            });

            return _ComparisonResult(
              isEquivalent: false,
              distinguishingString: distinguishingString,
            );
          }

          // Add to queue for further exploration
          queue.add(
            _StatePairWithPath(
              stateA: nextA,
              stateB: nextB,
              path: [...path, symbol],
            ),
          );
        }
      }
    }

    steps.add({
      'stepNumber': stepCounter++,
      'type': 'bfs_complete',
      'description': 'BFS complete - all state pairs explored',
      'data': {'totalPairsExplored': visited.length},
    });

    // No distinguishing string found - automata are equivalent
    return _ComparisonResult(isEquivalent: true, distinguishingString: null);
  }
}

/// Internal helper class to track state pairs with their paths
class _StatePairWithPath {
  final State stateA;
  final State stateB;
  final List<String> path;

  _StatePairWithPath({
    required this.stateA,
    required this.stateB,
    required this.path,
  });
}

/// Internal helper class for comparison results
class _ComparisonResult {
  final bool isEquivalent;
  final String? distinguishingString;

  _ComparisonResult({required this.isEquivalent, this.distinguishingString});
}
