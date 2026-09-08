import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/core/models/language_comparison_outcome.dart';
import 'package:turing_lab/presentation/widgets/language_comparison/language_comparison_controller.dart';

void main() {
  test(
    'subset construction exhaustion remains an inconclusive state limit',
    () async {
      // The tenth symbol from the end is 1: eleven NFA states require 1024 DFA states.
      final states = List.generate(
        11,
        (i) => State(
          id: 'q$i',
          label: 'q$i',
          position: Vector2.zero(),
          isInitial: i == 0,
          isAccepting: i == 10,
        ),
      );
      final transitions = <FSATransition>{};
      void edge(int from, int to, String symbol) => transitions.add(
        FSATransition.deterministic(
          id: '$from-$to-$symbol',
          fromState: states[from],
          toState: states[to],
          symbol: symbol,
        ),
      );
      edge(0, 0, '0');
      edge(0, 0, '1');
      edge(0, 1, '1');
      for (var i = 1; i < 10; i++) {
        edge(i, i + 1, '0');
        edge(i, i + 1, '1');
      }
      final machine = FSA(
        id: 'nth-symbol',
        name: 'Nth symbol',
        states: states.toSet(),
        transitions: transitions,
        alphabet: {'0', '1'},
        initialState: states.first,
        acceptingStates: {states.last},
        created: DateTime(2026),
        modified: DateTime(2026),
        bounds: const math.Rectangle(0, 0, 400, 300),
      );
      final outcome = await runLanguageComparison(
        LanguageComparisonRequest(automatonA: machine, automatonB: machine),
      );
      expect(outcome, isA<LanguageComparisonFailure>());
      final failure = outcome as LanguageComparisonFailure;
      expect(failure.reason, LanguageComparisonFailureReason.stateLimit);
      expect(
        failure.structuredMessage!.stableCode,
        'automaton.nfa-to-dfa.state-limit-exceeded',
      );
    },
  );
}
