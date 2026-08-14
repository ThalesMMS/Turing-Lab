import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/automaton_simulator.dart';
import 'package:turing_lab/core/algorithms/pda_simulator.dart';
import 'package:turing_lab/core/algorithms/tm_simulator.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/pda.dart';
import 'package:turing_lab/core/models/pda_transition.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/core/models/step_explanation.dart';
import 'package:turing_lab/core/models/tm.dart';
import 'package:turing_lab/core/models/tm_transition.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  group('Explanation generation (structure, not prose)', () {
    test('NFA epsilon-move/closure step includes explanation + highlights',
        () async {
      final q0 = State(id: 'q0', label: 'q0', position: Vector2.zero());
      final q1 = State(id: 'q1', label: 'q1', position: Vector2(100, 0));

      final nfa = FSA(
        id: 'nfa',
        name: 'nfa',
        states: {q0, q1},
        alphabet: {'a'},
        transitions: {
          FSATransition(
            id: 't0',
            fromState: q0,
            toState: q1,
            lambdaSymbol: 'ε',
          ),
        },
        initialState: q0,
        acceptingStates: {q1},
        created: DateTime(2025, 1, 1),
        modified: DateTime(2025, 1, 1),
        bounds: const math.Rectangle<double>(0, 0, 200, 200),
      );

      final wrapped = await AutomatonSimulator.simulateNFA(
        nfa,
        'a',
        stepByStep: true,
      );
      expect(wrapped.isSuccess, isTrue);
      final result = wrapped.data!;

      expect(result.steps, isNotEmpty);

      final epsilonSteps = result.steps
          .where((s) =>
              s.explanation?.categories
                  .contains(ExplanationCategory.epsilonMove) ??
              false)
          .toList();
      expect(epsilonSteps, isNotEmpty);

      final explanation = epsilonSteps.first.explanation!;
      expect(explanation.title, isNotEmpty);
      expect(explanation.bullets, isNotEmpty);
      expect(explanation.highlights, isNotEmpty);
      expect(
        explanation.highlights.any((h) => h.type == HighlightTargetType.state),
        isTrue,
      );
    });

    test('PDA push/pop step includes stack highlight + suggested fix', () {
      final q0 = State(id: 'q0', label: 'q0', position: Vector2.zero());
      final q1 = State(id: 'q1', label: 'q1', position: Vector2(100, 0));

      final pda = PDA(
        id: 'pda',
        name: 'pda',
        states: {q0, q1},
        alphabet: const {'a'},
        stackAlphabet: const {'Z', 'A'},
        transitions: {
          PDATransition(
            id: 't0',
            fromState: q0,
            toState: q1,
            label: 'a, Z → AZ',
            inputSymbol: 'a',
            popSymbol: 'Z',
            pushSymbol: 'AZ',
          ),
        },
        initialState: q0,
        acceptingStates: {q1},
        created: DateTime(2025, 1, 1),
        modified: DateTime(2025, 1, 1),
        bounds: const math.Rectangle<double>(0, 0, 200, 200),
      );

      final wrapped = PDASimulator.simulate(
        pda,
        'a',
        stepByStep: true,
      );
      expect(wrapped.isSuccess, isTrue);

      final sim = wrapped.data!;
      expect(sim.steps, isNotEmpty);

      final stepWithExplanation = sim.steps.firstWhere(
        (s) =>
            s.explanation?.categories
                .contains(ExplanationCategory.stackOperation) ??
            false,
        orElse: () => throw TestFailure(
            'No step had a stackOperation explanation category'),
      );

      final explanation = stepWithExplanation.explanation!;
      expect(explanation.bullets, isNotEmpty);
      expect(
        explanation.highlights
            .any((h) => h.type == HighlightTargetType.pdaStack),
        isTrue,
      );
    });

    test('TM step includes tape-cell highlight', () {
      final q0 = State(id: 'q0', label: 'q0', position: Vector2.zero());
      final q1 = State(id: 'q1', label: 'q1', position: Vector2(100, 0));

      final tm = TM(
        id: 'tm',
        name: 'tm',
        states: {q0, q1},
        alphabet: const {'1'},
        tapeAlphabet: const {'1', '_'},
        blankSymbol: '_',
        initialState: q0,
        acceptingStates: {q1},
        transitions: {
          TMTransition(
            id: 't0',
            fromState: q0,
            toState: q1,
            label: '1 → 1, R',
            readSymbol: '1',
            writeSymbol: '1',
            direction: TapeDirection.right,
          ),
        },
        created: DateTime(2025, 1, 1),
        modified: DateTime(2025, 1, 1),
        bounds: const math.Rectangle<double>(0, 0, 200, 200),
      );

      final wrapped = TMSimulator.simulate(
        tm,
        '1',
        stepByStep: true,
      );
      expect(wrapped.isSuccess, isTrue);
      final result = wrapped.data!;

      expect(result.steps, isNotEmpty);

      final stepWithTapeHighlight = result.steps.firstWhere(
        (s) =>
            s.explanation?.highlights
                .any((h) => h.type == HighlightTargetType.tapeCell) ??
            false,
        orElse: () =>
            throw TestFailure('No step had a tapeCell highlight target'),
      );

      expect(stepWithTapeHighlight.explanation?.bullets, isNotEmpty);
    });
  });
}
