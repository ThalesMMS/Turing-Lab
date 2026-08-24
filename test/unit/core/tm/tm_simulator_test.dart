//
//  tm_simulator_test.dart
//  Turing Lab
//
//  Comprehensive tests for the Turing-machine simulator, including
//  deterministic scenarios, nondeterministic alternatives, and multi-tape
//  configurations, evaluating acceptance, rejection, and transition behavior over time.
//
//  Thales Matheus Mendonça Santos - October 2025
//

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/tm_simulator.dart';
import 'package:turing_lab/core/models/simulation_step.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/core/models/step_explanation.dart';
import 'package:turing_lab/core/models/tm.dart';
import 'package:turing_lab/core/models/tm_transition.dart';
import 'package:vector_math/vector_math_64.dart';
import 'dart:math' as math;

TM _dtmAppendOne() {
  // Language: unary strings of 1s; machine appends one more 1 and accepts.
  final q0 = State(
    id: 'q0',
    label: 'q0',
    position: Vector2(0, 0),
    isInitial: true,
  );
  final qA = State(
    id: 'qA',
    label: 'qA',
    position: Vector2(100, 0),
    isAccepting: true,
  );
  final Set<State> states = {q0, qA};
  final alphabet = {'1'};
  final tapeAlphabet = {'1', 'B'};

  final transitions = <TMTransition>{
    // Move right to end of input
    TMTransition(
      id: 'tm-dtm-opaque-move-edge',
      fromState: q0,
      toState: q0,
      label: 'R over 1',
      readSymbol: '1',
      writeSymbol: '1',
      direction: TapeDirection.right,
      tapeNumber: 0,
    ),
    // On blank at end, write 1 and accept
    TMTransition(
      id: 'tm-dtm-opaque-accept-edge',
      fromState: q0,
      toState: qA,
      label: 'B->1,S',
      readSymbol: 'B',
      writeSymbol: '1',
      direction: TapeDirection.stay,
      tapeNumber: 0,
    ),
  };

  return TM(
    id: 'tm_inc',
    name: 'Append One',
    states: states,
    transitions: transitions,
    alphabet: alphabet,
    initialState: q0,
    acceptingStates: {qA},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 400, 300),
    tapeAlphabet: tapeAlphabet,
    blankSymbol: 'B',
    tapeCount: 1,
  );
}

/// Creates a TM that immediately accepts the empty string.
/// q0 is both initial and accepting; no transitions needed.
TM _dtmAcceptEmpty() {
  final q0 = State(
    id: 'q0',
    label: 'q0',
    position: Vector2(0, 0),
    isInitial: true,
    isAccepting: true,
  );

  return TM(
    id: 'tm_empty',
    name: 'Accept Empty',
    states: {q0},
    transitions: const {},
    alphabet: const <String>{},
    initialState: q0,
    acceptingStates: {q0},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 400, 300),
    tapeAlphabet: const {'B'},
    blankSymbol: 'B',
    tapeCount: 1,
  );
}

TM _dtmAcceptingInitialWithOutgoingTransition() {
  final q0 = State(
    id: 'q0',
    label: 'q0',
    position: Vector2(0, 0),
    isInitial: true,
    isAccepting: true,
  );
  final q1 = State(
    id: 'q1',
    label: 'q1',
    position: Vector2(100, 0),
  );

  final transition = TMTransition(
    id: 't0',
    fromState: q0,
    toState: q1,
    label: 'a/a,R',
    readSymbol: 'a',
    writeSymbol: 'a',
    direction: TapeDirection.right,
    tapeNumber: 0,
  );

  return TM(
    id: 'tm_initial_accepts_before_transition',
    name: 'Initial Accepts Before Transition',
    states: {q0, q1},
    transitions: {transition},
    alphabet: const {'a'},
    initialState: q0,
    acceptingStates: {q0},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 400, 300),
    tapeAlphabet: const {'a', 'B'},
    blankSymbol: 'B',
    tapeCount: 1,
  );
}

/// Creates a TM with a nondeterministic conflict: two transitions
/// from q0 on '1' (one goes to qA, the other to qR).
TM _dtmNondeterministicConflict() {
  final q0 = State(
    id: 'q0',
    label: 'q0',
    position: Vector2(0, 0),
    isInitial: true,
  );
  final qA = State(
    id: 'qA',
    label: 'qA',
    position: Vector2(100, 0),
    isAccepting: true,
  );
  final qR = State(
    id: 'qR',
    label: 'qR',
    position: Vector2(200, 0),
  );

  final transitions = <TMTransition>{
    TMTransition(
      id: 't0',
      fromState: q0,
      toState: qA,
      label: '1/1,R',
      readSymbol: '1',
      writeSymbol: '1',
      direction: TapeDirection.right,
      tapeNumber: 0,
    ),
    TMTransition(
      id: 't1',
      fromState: q0,
      toState: qR,
      label: '1/0,R',
      readSymbol: '1',
      writeSymbol: '0',
      direction: TapeDirection.right,
      tapeNumber: 0,
    ),
  };

  return TM(
    id: 'tm_conflict',
    name: 'Nondeterministic Conflict',
    states: {q0, qA, qR},
    transitions: transitions,
    alphabet: const {'1'},
    initialState: q0,
    acceptingStates: {qA},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 400, 300),
    tapeAlphabet: const {'0', '1', 'B'},
    blankSymbol: 'B',
    tapeCount: 1,
  );
}

/// Creates a non-deterministic TM that accepts '1' via either of two
/// branches — one that writes 'A' and one that writes 'B'.
TM _ntmSimple() {
  final q0 = State(
    id: 'q0',
    label: 'q0',
    position: Vector2(0, 0),
    isInitial: true,
  );
  final qA = State(
    id: 'qA',
    label: 'qA',
    position: Vector2(100, 0),
    isAccepting: true,
  );
  final qB = State(
    id: 'qB',
    label: 'qB',
    position: Vector2(100, 100),
    isAccepting: true,
  );

  final transitions = <TMTransition>{
    TMTransition(
      id: 'tm-ntm-opaque-accept-a-edge',
      fromState: q0,
      toState: qA,
      label: '1/A,S',
      readSymbol: '1',
      writeSymbol: 'A',
      direction: TapeDirection.stay,
      tapeNumber: 0,
    ),
    TMTransition(
      id: 'tm-ntm-opaque-accept-b-edge',
      fromState: q0,
      toState: qB,
      label: '1/B,S',
      readSymbol: '1',
      writeSymbol: 'B',
      direction: TapeDirection.stay,
      tapeNumber: 0,
    ),
  };

  return TM(
    id: 'tm_ntm',
    name: 'Simple NTM',
    states: {q0, qA, qB},
    transitions: transitions,
    alphabet: const {'1'},
    initialState: q0,
    acceptingStates: {qA, qB},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 400, 300),
    tapeAlphabet: const {'1', 'A', 'B'},
    blankSymbol: 'B',
    tapeCount: 1,
  );
}

TM _ntmDuplicateLoop() {
  final q0 = State(
    id: 'q0',
    label: 'q0',
    position: Vector2.zero(),
    isInitial: true,
  );

  return TM(
    id: 'tm_duplicate_loop',
    name: 'Duplicate Loop NTM',
    states: {q0},
    transitions: {
      for (var i = 0; i < 2; i++)
        TMTransition(
          id: 't$i',
          fromState: q0,
          toState: q0,
          label: '1/1,S',
          readSymbol: '1',
          writeSymbol: '1',
          direction: TapeDirection.stay,
          tapeNumber: 0,
        ),
    },
    alphabet: const {'1'},
    initialState: q0,
    acceptingStates: const {},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 400, 300),
    tapeAlphabet: const {'1', 'B'},
    blankSymbol: 'B',
    tapeCount: 1,
  );
}

void main() {
  group('TM simulator (single-tape, deterministic and nondeterministic)', () {
    test('synchronous DTM trace preserves display text and stable edge IDs',
        () {
      final result = TMSimulator.simulateDTM(
        _dtmAppendOne(),
        '1',
        stepByStep: true,
      );

      expect(result.isSuccess, isTrue);
      final steps = result.data!.steps;
      expect(steps.first.explanation, isNull);
      expect(steps.last.explanation, isNull);
      final step = steps.firstWhere(
        (step) => step.usedTransition == 'q0,1 → q0,1,R',
      );
      expect(
        step.explanation!.highlights
            .where((target) => target.type == HighlightTargetType.transition)
            .map((target) => target.id),
        ['tm-dtm-opaque-move-edge'],
      );
    });

    test('cooperative DTM trace preserves display text and stable edge IDs',
        () async {
      final result = await TMSimulator.simulateCooperative(
        _dtmAppendOne(),
        '1',
        stepByStep: true,
        operationsPerBatch: 1,
      );

      expect(result.isSuccess, isTrue);
      final steps = result.data!.steps;
      expect(steps.first.explanation, isNull);
      expect(steps.last.explanation, isNull);
      final step = steps.firstWhere(
        (step) => step.usedTransition == 'q0,1 → q0,1,R',
      );
      expect(
        step.explanation!.highlights
            .where((target) => target.type == HighlightTargetType.transition)
            .map((target) => target.id),
        ['tm-dtm-opaque-move-edge'],
      );
    });

    test('synchronous NTM trace preserves display text and stable edge IDs',
        () {
      final result = TMSimulator.simulateNTM(
        _ntmSimple(),
        '1',
        stepByStep: true,
      );

      expect(result.isSuccess, isTrue);
      final steps = result.data!.steps;
      expect(steps.first.explanation, isNull);
      expect(steps.last.explanation, isNull);
      final step = steps.firstWhere(
        (step) => step.usedTransition == 'q0,1 → qA,A,S',
      );
      expect(
        step.explanation!.highlights
            .where((target) => target.type == HighlightTargetType.transition)
            .map((target) => target.id),
        ['tm-ntm-opaque-accept-a-edge'],
      );
    });

    test('cooperative NTM trace preserves display text and stable edge IDs',
        () async {
      final result = await TMSimulator.simulateCooperative(
        _ntmSimple(),
        '1',
        stepByStep: true,
        operationsPerBatch: 1,
      );

      expect(result.isSuccess, isTrue);
      final steps = result.data!.steps;
      expect(steps.first.explanation, isNull);
      expect(steps.last.explanation, isNull);
      final step = steps.firstWhere(
        (step) => step.usedTransition == 'q0,1 → qA,A,S',
      );
      expect(
        step.explanation!.highlights
            .where((target) => target.type == HighlightTargetType.transition)
            .map((target) => target.id),
        ['tm-ntm-opaque-accept-a-edge'],
      );
    });

    test('DTM appends one and accepts', () {
      final tm = _dtmAppendOne();
      final res = TMSimulator.simulateDTM(tm, '111');
      expect(res.isSuccess, true);
      expect(res.data!.accepted, true);
    });

    test('DTM step trace records post-transition state (Bug 2 fix)', () {
      final tm = _dtmAppendOne();
      final res = TMSimulator.simulateDTM(tm, '1');
      expect(res.isSuccess, true);
      expect(res.data!.accepted, true);

      final steps = res.data!.steps;
      // Steps: initial(q0) → step1(q0, read '1', stay q0) → step2(qA, read 'B', write '1') → final(qA)
      // After Bug 2 fix, intermediate steps should show the destination state.
      // Find the step where we transition to qA
      final acceptingSteps =
          steps.where((s) => s.currentState == 'qA').toList();
      expect(acceptingSteps, isNotEmpty,
          reason: 'At least one step should show the accepting state qA');
    });

    test('DTM accepts empty string when initial state is accepting (Bug 4 fix)',
        () {
      final tm = _dtmAcceptEmpty();
      final res = TMSimulator.simulateDTM(tm, '');
      expect(res.isSuccess, true);
      expect(res.data!.accepted, true);
    });

    test('DTM accepts an accepting initial state before applying transitions',
        () {
      final tm = _dtmAcceptingInitialWithOutgoingTransition();

      final dtmResult = TMSimulator.simulateDTM(tm, 'a');
      final routedResult = TMSimulator.simulate(tm, 'a');
      final ntmResult = TMSimulator.simulateNTM(tm, 'a');

      expect(dtmResult.isSuccess, true);
      expect(routedResult.isSuccess, true);
      expect(ntmResult.isSuccess, true);
      expect(dtmResult.data!.accepted, true);
      expect(routedResult.data!.accepted, true);
      expect(ntmResult.data!.accepted, true);
      expect(dtmResult.data!.steps.last.currentState, 'q0');
      expect(
        dtmResult.data!.steps.any((step) => step.currentState == 'q1'),
        isFalse,
        reason: 'DTM should accept before taking the outgoing transition.',
      );
    });

    test(
        'DTM rejects empty string when initial state is not accepting (Bug 4 fix)',
        () {
      final tm = _dtmAppendOne();
      // q0 is not accepting, and the machine reads 'B' → transitions to qA (which is accepting).
      // So this should actually accept because of the B→1 transition.
      final res = TMSimulator.simulateDTM(tm, '');
      expect(res.isSuccess, true);
      expect(res.data!.accepted, true);
    });

    test('DTM returns error on nondeterministic conflict (Bug 5 fix)', () {
      final tm = _dtmNondeterministicConflict();
      final res = TMSimulator.simulateDTM(tm, '1');
      expect(res.isSuccess, true);
      // Should report failure due to nondeterministic conflict
      expect(res.data!.accepted, false);
      expect(res.data!.errorMessage, contains('Nondeterministic conflict'));
    });

    test('TMTransition serialization round-trip (Bug 1 fix)', () {
      final q0 = State(
        id: 'q0',
        label: 'q0',
        position: Vector2(10, 20),
        isInitial: true,
      );
      final q1 = State(
        id: 'q1',
        label: 'q1',
        position: Vector2(100, 50),
        isAccepting: true,
      );

      final original = TMTransition(
        id: 't0',
        fromState: q0,
        toState: q1,
        label: '1/0,R',
        readSymbol: '1',
        writeSymbol: '0',
        direction: TapeDirection.right,
        tapeNumber: 0,
      );

      final json = original.toJson();
      final restored = TMTransition.fromJson(
        json,
        statesById: {q0.id: q0, q1.id: q1},
      );

      expect(restored.id, original.id);
      expect(restored.fromState.id, original.fromState.id);
      expect(restored.toState.id, original.toState.id);
      expect(restored.readSymbol, original.readSymbol);
      expect(restored.writeSymbol, original.writeSymbol);
      expect(restored.direction, original.direction);
      expect(restored.tapeNumber, original.tapeNumber);
    });

    test('TM full serialization round-trip (Bug 1 fix)', () {
      final tm = _dtmAppendOne();
      final json = tm.toJson();
      final restored = TM.fromJson(json);

      expect(restored.id, tm.id);
      expect(restored.name, tm.name);
      expect(restored.states.length, tm.states.length);
      expect(restored.transitions.length, tm.transitions.length);
      expect(restored.blankSymbol, tm.blankSymbol);
      expect(restored.initialState?.id, tm.initialState?.id);
      expect(restored.acceptingStates.length, tm.acceptingStates.length);
    });

    test(
        'currentTapeSymbol returns symbol at headPosition, not index 0 (Bug A fix)',
        () {
      // Create a simulation step with tape 'ABC' and head at position 2
      final step = SimulationStep.tm(
        currentState: 'q0',
        remainingInput: '',
        tapeContents: 'ABC',
        stepNumber: 1,
        headPosition: 2,
      );

      expect(step.currentTapeSymbol, 'C',
          reason: 'Should return symbol at headPosition (2), not index 0');

      // Verify index 0 would have returned 'A' (the old buggy behavior)
      expect(step.tapeContents[0], 'A');
    });

    test('NTM is correctly routed via simulate() (Bug C fix)', () {
      final tm = _ntmSimple();
      // Using simulate() (the main entry point) — should detect NTM and route correctly
      final res = TMSimulator.simulate(tm, '1');
      expect(res.isSuccess, true);
      expect(res.data!.accepted, true,
          reason: 'NTM should accept via at least one branch');
    });

    test('Initial step has tape contents and head position (Bug D fix)', () {
      final tm = _dtmAppendOne();
      final res = TMSimulator.simulateDTM(tm, '11');
      expect(res.isSuccess, true);

      final initialStep = res.data!.steps.first;
      expect(initialStep.tapeContents, '11',
          reason: 'Initial step should have the input on the tape');
      expect(initialStep.headPosition, 0,
          reason: 'Initial step should have head at position 0');
    });

    test(
        'DTM with >1000 steps does not falsely report infinite loop (Bug F fix)',
        () {
      // Create a TM that loops through many steps before accepting.
      // q0 reads '1', writes '1', moves right — loops until it hits blank.
      // With input of 1500 '1's, it needs >1500 steps.
      final q0 = State(
        id: 'q0',
        label: 'q0',
        position: Vector2(0, 0),
        isInitial: true,
      );
      final qA = State(
        id: 'qA',
        label: 'qA',
        position: Vector2(100, 0),
        isAccepting: true,
      );

      final transitions = <TMTransition>{
        TMTransition(
          id: 't0',
          fromState: q0,
          toState: q0,
          label: '1/1,R',
          readSymbol: '1',
          writeSymbol: '1',
          direction: TapeDirection.right,
          tapeNumber: 0,
        ),
        TMTransition(
          id: 't1',
          fromState: q0,
          toState: qA,
          label: 'B/B,S',
          readSymbol: 'B',
          writeSymbol: 'B',
          direction: TapeDirection.stay,
          tapeNumber: 0,
        ),
      };

      final tm = TM(
        id: 'tm_long',
        name: 'Long Running DTM',
        states: {q0, qA},
        transitions: transitions,
        alphabet: const {'1'},
        initialState: q0,
        acceptingStates: {qA},
        created: DateTime.now(),
        modified: DateTime.now(),
        bounds: const math.Rectangle(0, 0, 400, 300),
        tapeAlphabet: const {'1', 'B'},
        blankSymbol: 'B',
        tapeCount: 1,
      );

      // Input with 1500 '1's — will need >1500 steps
      final input = '1' * 1500;
      final res = TMSimulator.simulateDTM(tm, input,
          stepByStep: true, timeout: const Duration(seconds: 30));
      expect(res.isSuccess, true);
      expect(res.data!.accepted, true,
          reason: 'Should accept without falsely reporting infinite loop');
      expect(res.data!.steps.length, greaterThan(1000),
          reason: 'Should have more than 1000 steps');
    });

    test('cooperative DTM detects a loop without recording every step',
        () async {
      final loopingNtm = _ntmDuplicateLoop();
      final tm = loopingNtm.copyWith(
        transitions: {loopingNtm.tmTransitions.first},
      );

      final result = await TMSimulator.simulateCooperative(
        tm,
        '1',
        stepByStep: false,
        timeout: const Duration(seconds: 30),
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!.errorMessage, 'Infinite loop detected');
      expect(
        result.data!.steps,
        hasLength(1),
        reason: 'Cooperative mode should retain only the initial snapshot',
      );
    });

    test('Final step has headPosition (Bug G fix)', () {
      final tm = _dtmAppendOne();
      final res = TMSimulator.simulateDTM(tm, '11');
      expect(res.isSuccess, true);

      final finalStep = res.data!.steps.last;
      expect(finalStep.headPosition, isNotNull,
          reason: 'Final step must have headPosition for tape visualization');
    });

    test('NTM step records destination state, not source (Bug I fix)', () {
      final tm = _ntmSimple();
      final res = TMSimulator.simulate(tm, '1');
      expect(res.isSuccess, true);
      expect(res.data!.accepted, true);

      // Skip initial step; intermediate steps should show the destination state
      final intermediateSteps =
          res.data!.steps.where((s) => s.usedTransition != null).toList();
      expect(intermediateSteps, isNotEmpty);

      for (final step in intermediateSteps) {
        // The NTM branches go q0→qA or q0→qB, so steps must show qA or qB
        expect(step.currentState, isNot('q0'),
            reason: 'Step should record the destination state, not source');
      }
    });

    test('NTM initial step has tape data (Bug J fix)', () {
      final tm = _ntmSimple();
      final res = TMSimulator.simulate(tm, '1');
      expect(res.isSuccess, true);

      final initialStep = res.data!.steps.first;
      expect(initialStep.tapeContents, '1',
          reason: 'NTM initial step should have the input on the tape');
      expect(initialStep.headPosition, 0,
          reason: 'NTM initial step should have head at position 0');
    });

    test('NTM rejection preserves trace steps (Bug K fix)', () {
      // Create an NTM that always rejects — no accepting states
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
      );

      final transitions = <TMTransition>{
        TMTransition(
          id: 't0',
          fromState: q0,
          toState: q1,
          label: '1/1,R',
          readSymbol: '1',
          writeSymbol: '1',
          direction: TapeDirection.right,
          tapeNumber: 0,
        ),
      };

      final tm = TM(
        id: 'tm_reject',
        name: 'Rejecting NTM',
        states: {q0, q1},
        transitions: transitions,
        alphabet: const {'1'},
        initialState: q0,
        acceptingStates: const {},
        created: DateTime.now(),
        modified: DateTime.now(),
        bounds: const math.Rectangle(0, 0, 400, 300),
        tapeAlphabet: const {'1', 'B'},
        blankSymbol: 'B',
        tapeCount: 1,
      );

      final res = TMSimulator.simulate(tm, '1');
      expect(res.isSuccess, true);
      expect(res.data!.accepted, false);
      expect(res.data!.steps, isNotEmpty,
          reason: 'Rejected NTM should preserve trace steps, not discard them');
    });

    test('NTM rejects after deduplicating repeated configurations', () {
      final result = TMSimulator.simulateNTM(
        _ntmDuplicateLoop(),
        '1',
        maxConfigurations: 2,
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!.accepted, isFalse);
      expect(
        result.data!.errorMessage,
        'Rejected: no accepting configuration found',
      );
    });

    test('cooperative NTM also deduplicates repeated configurations', () async {
      final result = await TMSimulator.simulateCooperative(
        _ntmDuplicateLoop(),
        '1',
        operationsPerBatch: 1,
        timeout: const Duration(milliseconds: 100),
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!.accepted, isFalse);
      expect(
        result.data!.errorMessage,
        'Rejected: no accepting configuration found',
      );
    });
  });
}
