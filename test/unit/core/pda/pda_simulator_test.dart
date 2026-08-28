//
//  pda_simulator_test.dart
//  Turing Lab
//
//  Tests for the PDA simulator, covering acceptance by
//  final state and by empty stack, initial-symbol handling, and
//  push/pop operations for classic balanced languages, plus
//  rejection handling and nondeterministic branches.
//
//  Thales Matheus Mendonça Santos - October 2025
//

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/pda_simulator.dart';
import 'package:turing_lab/core/models/pda.dart';
import 'package:turing_lab/core/models/pda_transition.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/core/models/step_explanation.dart';
import 'package:vector_math/vector_math_64.dart';
import 'dart:math' as math;

PDA _pdaAcceptsAByFinal() {
  final q0 = State(
    id: 'q0',
    label: 'q0',
    position: Vector2(0, 0),
    isInitial: true,
  );
  final q1 = State(
    id: 'q1',
    label: 'q1',
    position: Vector2(100, 0),
    isAccepting: true,
  );
  final Set<State> states = {q0, q1};
  final alphabet = {'a'};
  final stackAlphabet = {'Z', 'A'};
  final transitions = <PDATransition>{
    // Initialize stack with Z
    PDATransition(
      id: 't0',
      fromState: q0,
      toState: q0,
      inputSymbol: '', // ε
      popSymbol: '',
      pushSymbol: 'Z',
      label: 'ε,ε/Z',
    ),
    // Read 'a' and move to accepting state (final-state acceptance)
    PDATransition(
      id: 't1',
      fromState: q0,
      toState: q1,
      inputSymbol: 'a',
      popSymbol: 'Z',
      pushSymbol: 'Z',
      label: 'a,Z/Z',
    ),
  };
  return PDA(
    id: 'pfa',
    name: 'Accept a by final',
    states: states,
    transitions: transitions,
    alphabet: alphabet,
    initialState: q0,
    acceptingStates: {q1},
    stackAlphabet: stackAlphabet,
    initialStackSymbol: 'Z',
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 400, 300),
  );
}

PDA _pdaAcceptsEmptyByEmptyStack() {
  final q0 = State(
    id: 'q0',
    label: 'q0',
    position: Vector2(0, 0),
    isInitial: true,
  );
  final Set<State> states = {q0};
  final alphabet = <String>{};
  final stackAlphabet = {'Z'};
  final transitions = <PDATransition>{
    // push Z then pop Z via epsilon to empty the stack
    PDATransition(
      id: 't0',
      fromState: q0,
      toState: q0,
      inputSymbol: '',
      popSymbol: '',
      pushSymbol: 'Z',
      label: 'ε,ε/Z',
    ),
    PDATransition(
      id: 't1',
      fromState: q0,
      toState: q0,
      inputSymbol: '',
      popSymbol: 'Z',
      pushSymbol: '',
      label: 'ε,Z/ε',
    ),
  };
  return PDA(
    id: 'pempty',
    name: 'Accept empty by empty stack',
    states: states,
    transitions: transitions,
    alphabet: alphabet,
    initialState: q0,
    acceptingStates: const {},
    stackAlphabet: stackAlphabet,
    initialStackSymbol: 'Z',
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 400, 300),
  );
}

PDA _pdaAcceptsABoth() {
  final q0 = State(
    id: 'q0',
    label: 'q0',
    position: Vector2(0, 0),
    isInitial: true,
  );
  final qf = State(
    id: 'qf',
    label: 'qf',
    position: Vector2(100, 0),
    isAccepting: true,
  );
  final Set<State> states = {q0, qf};
  final alphabet = {'a'};
  final stackAlphabet = {'Z'};
  final transitions = <PDATransition>{
    // init Z
    PDATransition(
      id: 't0',
      fromState: q0,
      toState: q0,
      inputSymbol: '',
      popSymbol: '',
      pushSymbol: 'Z',
      label: 'ε,ε/Z',
    ),
    // consume 'a' without changing stack
    PDATransition(
      id: 'pda-opaque-consuming-edge',
      fromState: q0,
      toState: q0,
      inputSymbol: 'a',
      popSymbol: 'Z',
      pushSymbol: 'Z',
      label: 'a,Z/Z',
    ),
    // epsilon to final state (final-state acceptance)
    PDATransition(
      id: 'pda-opaque-epsilon-edge',
      fromState: q0,
      toState: qf,
      inputSymbol: '',
      popSymbol: '',
      pushSymbol: '',
      label: 'ε,ε/ε',
    ),
    // epsilon pop to empty stack in q0
    PDATransition(
      id: 't3',
      fromState: q0,
      toState: q0,
      inputSymbol: '',
      popSymbol: 'Z',
      pushSymbol: '',
      label: 'ε,Z/ε',
    ),
  };
  return PDA(
    id: 'pboth',
    name: 'Accept both',
    states: states,
    transitions: transitions,
    alphabet: alphabet,
    initialState: q0,
    acceptingStates: {qf},
    stackAlphabet: stackAlphabet,
    initialStackSymbol: 'Z',
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 400, 300),
  );
}

void main() {
  group('PDA simulator acceptance modes', () {
    test('Accept by final state', () {
      final pda = _pdaAcceptsAByFinal();
      final ok = PDASimulator.simulateNPDA(
        pda,
        'a',
        mode: PDAAcceptanceMode.finalState,
      );
      expect(ok.isSuccess, true);
      expect(ok.data!.accepted, true);
    });

    test('Accept by empty stack', () {
      final pda = _pdaAcceptsEmptyByEmptyStack();
      final ok = PDASimulator.simulateNPDA(
        pda,
        '',
        mode: PDAAcceptanceMode.emptyStack,
      );
      expect(ok.isSuccess, true);
      expect(ok.data!.accepted, true);
    });

    test('Accept by both conditions', () {
      final pda = _pdaAcceptsABoth();
      final okFinal = PDASimulator.simulateNPDA(
        pda,
        'a',
        mode: PDAAcceptanceMode.finalState,
      );
      final okEmpty = PDASimulator.simulateNPDA(
        pda,
        '',
        mode: PDAAcceptanceMode.emptyStack,
      );
      expect(okFinal.isSuccess && okFinal.data!.accepted, true);
      expect(okEmpty.isSuccess && okEmpty.data!.accepted, true);
    });
  });

  group('NPDA step recording', () {
    test('synchronous trace preserves PDA display text and stable edge IDs',
        () {
      final result = PDASimulator.simulateNPDA(
        _pdaAcceptsABoth(),
        'a',
        stepByStep: true,
        mode: PDAAcceptanceMode.finalState,
      );

      expect(result.isSuccess, isTrue);
      final steps = result.data!.steps;
      expect(steps.first.explanation, isNull);
      expect(steps.last.explanation?.title, 'Accepted by final state');

      final epsilonStep = steps.firstWhere(
        (step) =>
            step.explanation?.highlights.any(
              (target) =>
                  target.type == HighlightTargetType.transition &&
                  target.id == 'pda-opaque-epsilon-edge',
            ) ??
            false,
      );
      final consumingStep = steps.firstWhere(
        (step) => step.consumedInput == 'a',
      );
      expect(epsilonStep.usedTransition, '\u03b5,\u03b5\u2192\u03b5');
      expect(consumingStep.usedTransition, 'a,Z\u2192Z');
      expect(
        epsilonStep.explanation!.highlights
            .where((target) => target.type == HighlightTargetType.transition)
            .map((target) => target.id),
        ['pda-opaque-epsilon-edge'],
      );
      expect(
        consumingStep.explanation!.highlights
            .where((target) => target.type == HighlightTargetType.transition)
            .map((target) => target.id),
        ['pda-opaque-consuming-edge'],
      );
    });

    test('cooperative trace preserves PDA display text and stable edge IDs',
        () async {
      final result = await PDASimulator.simulateCooperative(
        _pdaAcceptsABoth(),
        'a',
        stepByStep: true,
        mode: PDAAcceptanceMode.finalState,
        configurationsPerBatch: 1,
      );

      expect(result.isSuccess, isTrue);
      final steps = result.data!.steps;
      expect(steps.first.explanation, isNull);
      expect(steps.last.explanation?.title, 'Accepted by final state');

      final epsilonStep = steps.firstWhere(
        (step) =>
            step.explanation?.highlights.any(
              (target) =>
                  target.type == HighlightTargetType.transition &&
                  target.id == 'pda-opaque-epsilon-edge',
            ) ??
            false,
      );
      final consumingStep = steps.firstWhere(
        (step) => step.consumedInput == 'a',
      );
      expect(epsilonStep.usedTransition, '\u03b5,\u03b5\u2192\u03b5');
      expect(consumingStep.usedTransition, 'a,Z\u2192Z');
      expect(
        epsilonStep.explanation!.highlights
            .where((target) => target.type == HighlightTargetType.transition)
            .map((target) => target.id),
        ['pda-opaque-epsilon-edge'],
      );
      expect(
        consumingStep.explanation!.highlights
            .where((target) => target.type == HighlightTargetType.transition)
            .map((target) => target.id),
        ['pda-opaque-consuming-edge'],
      );
    });

    test('Step records destination state, not source', () {
      final pda = _pdaAcceptsAByFinal();
      final result = PDASimulator.simulateNPDA(
        pda,
        'a',
        stepByStep: true,
        mode: PDAAcceptanceMode.finalState,
      );
      expect(result.isSuccess, true);
      final steps = result.data!.steps;

      // Find intermediate steps (not initial step 0, not final step)
      final intermediateSteps = steps
          .where(
              (s) => s.stepNumber > 0 && s.stepNumber < steps.last.stepNumber)
          .toList();
      expect(intermediateSteps, isNotEmpty);

      // Intermediate steps should show destination states (q1 or qf), not
      // always the source (q0)
      final hasDestination =
          intermediateSteps.any((s) => s.currentState != 'q0');
      expect(hasDestination, true);
    });

    test('Initial step includes stack contents', () {
      final pda = _pdaAcceptsAByFinal();
      final result = PDASimulator.simulateNPDA(
        pda,
        'a',
        stepByStep: true,
        mode: PDAAcceptanceMode.finalState,
      );
      expect(result.isSuccess, true);

      // Initial step (stepNumber 0) should have stack contents
      final initialStep = result.data!.steps.first;
      expect(initialStep.stepNumber, 0);
      expect(initialStep.stackContents, isNotEmpty);
    });

    test('Rejection preserves non-empty trace', () {
      final pda = _pdaAcceptsAByFinal();
      final result = PDASimulator.simulateNPDA(
        pda,
        'b', // not in alphabet, should reject
        stepByStep: true,
        mode: PDAAcceptanceMode.finalState,
      );
      expect(result.isSuccess, true);
      expect(result.data!.accepted, false);

      // Steps should be non-empty even on rejection
      expect(result.data!.steps, isNotEmpty);
    });
  });

  group('cooperative simulation batching', () {
    test('rejects a non-positive configurations-per-batch value', () async {
      final result = await PDASimulator.simulateCooperative(
        _pdaAcceptsAByFinal(),
        'a',
        configurationsPerBatch: 0,
      );

      expect(result.isFailure, isTrue);
      expect(result.error, contains('greater than zero'));
    });
  });
}
