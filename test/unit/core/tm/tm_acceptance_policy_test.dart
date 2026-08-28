import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/tm_block_execution_engine.dart';
import 'package:turing_lab/core/algorithms/tm_execution_analyzer.dart';
import 'package:turing_lab/core/algorithms/tm_simulator.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/core/models/tm.dart';
import 'package:turing_lab/core/models/tm_acceptance.dart';
import 'package:turing_lab/core/models/tm_building_blocks.dart';
import 'package:turing_lab/core/models/tm_execution_analysis.dart';
import 'package:turing_lab/core/models/tm_transition.dart';
import 'package:turing_lab/core/validators/input_validators.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  group('TM acceptance policy', () {
    test('policy evaluator satisfies the complete final/halted truth table',
        () {
      for (final policy in TMAcceptancePolicy.values) {
        for (final isFinal in [false, true]) {
          for (final isHalted in [false, true]) {
            final decision = TMAcceptancePolicyEvaluator.evaluate(
              policy: policy,
              isFinalState: isFinal,
              isHalted: isHalted,
            );
            final expectedAcceptance = isFinal && policy.acceptsFinalState ||
                isHalted && policy.acceptsHalting;
            final expectedDecision = expectedAcceptance || isHalted;

            expect(
              decision != null,
              expectedDecision,
              reason: '$policy final=$isFinal halted=$isHalted',
            );
            expect(
              decision?.accepted ?? false,
              expectedAcceptance,
              reason: '$policy final=$isFinal halted=$isHalted',
            );
          }
        }
      }
    });

    test('final-state and halting policies disagree on a dead non-final state',
        () async {
      final finalState = _machine(policy: TMAcceptancePolicy.finalState);
      final halting = finalState.copyWith(
        acceptancePolicy: TMAcceptancePolicy.halting,
      );

      final rejected = await TMExecutionAnalyzer.analyze(finalState, '');
      final accepted = await TMExecutionAnalyzer.analyze(halting, '');

      expect(rejected.outcome, TMExecutionOutcome.haltedRejected);
      expect(
        rejected.acceptanceReason,
        TMAcceptanceReason.haltedOutsideFinalState,
      );
      expect(accepted.outcome, TMExecutionOutcome.accepted);
      expect(accepted.acceptancePolicy, TMAcceptancePolicy.halting);
      expect(
        accepted.acceptanceReason,
        TMAcceptanceReason.haltedOutsideFinalState,
      );
    });

    test('halting does not accept a final state until its branch stops',
        () async {
      final start = _state('start', initial: true, accepting: true);
      final dead = _state('dead');
      final transition = _transition(start, dead, TapeDirection.stay);
      final base = _machine(
        states: {start, dead},
        initial: start,
        accepting: {start},
        transitions: {transition},
      );

      final byFinal = await TMExecutionAnalyzer.analyze(base, '');
      final byHalt = await TMExecutionAnalyzer.analyze(
        base.copyWith(acceptancePolicy: TMAcceptancePolicy.halting),
        '',
      );

      expect(byFinal.stepsExecuted, 0);
      expect(byFinal.acceptanceReason, TMAcceptanceReason.enteredFinalState);
      expect(byHalt.stepsExecuted, 1);
      expect(byHalt.outcome, TMExecutionOutcome.accepted);
      expect(
        byHalt.acceptanceReason,
        TMAcceptanceReason.haltedOutsideFinalState,
      );
    });

    test('combined policy accepts either final entry or halting', () async {
      final byHalting = await TMExecutionAnalyzer.analyze(
        _machine(policy: TMAcceptancePolicy.finalStateOrHalting),
        '',
      );
      final finalStart = _state('final-start', initial: true, accepting: true);
      final dead = _state('dead');
      final byFinalState = await TMExecutionAnalyzer.analyze(
        _machine(
          states: {finalStart, dead},
          initial: finalStart,
          accepting: {finalStart},
          transitions: {
            _transition(finalStart, dead, TapeDirection.stay),
          },
          policy: TMAcceptancePolicy.finalStateOrHalting,
        ),
        '',
      );

      expect(byHalting.outcome, TMExecutionOutcome.accepted);
      expect(
        byHalting.acceptanceReason,
        TMAcceptanceReason.haltedOutsideFinalState,
      );
      expect(byFinalState.outcome, TMExecutionOutcome.accepted);
      expect(byFinalState.stepsExecuted, 0);
      expect(
        byFinalState.acceptanceReason,
        TMAcceptanceReason.enteredFinalState,
      );
    });

    test('halting-capable policies do not require final states', () {
      expect(
        InputValidators.validateTM(_machine()).map((issue) => issue.code),
        contains('TM_NO_ACCEPTING'),
      );
      for (final policy in const [
        TMAcceptancePolicy.halting,
        TMAcceptancePolicy.finalStateOrHalting,
      ]) {
        final issues = InputValidators.validateTM(_machine(policy: policy));
        expect(
          issues.map((issue) => issue.code),
          isNot(contains('TM_NO_ACCEPTING')),
        );
      }
    });

    test('changing configurations remain bounded unknown, not rejected',
        () async {
      final start = _state('start', initial: true);
      final machine = _machine(
        states: {start},
        initial: start,
        policy: TMAcceptancePolicy.halting,
        transitions: {_transition(start, start, TapeDirection.right)},
      );

      final result = await TMExecutionAnalyzer.analyze(
        machine,
        '',
        maxSteps: 3,
        maxConfigurations: 20,
      );

      expect(result.outcome, TMExecutionOutcome.boundedUnknown);
      expect(result.limit, TMExecutionLimit.steps);
      expect(result.acceptanceReason, TMAcceptanceReason.stepLimit);
    });

    test('analyzer reports typed reasons for cancellation and every bound',
        () async {
      final start = _state('start', initial: true);
      final moving = _machine(
        states: {start},
        initial: start,
        policy: TMAcceptancePolicy.halting,
        transitions: {_transition(start, start, TapeDirection.right)},
      );

      final cancelled = await TMExecutionAnalyzer.analyze(
        moving,
        '',
        isCancelled: () => true,
      );
      final timedOut = await TMExecutionAnalyzer.analyze(
        moving,
        '',
        timeout: const Duration(microseconds: 1),
      );
      final configurationBound = await TMExecutionAnalyzer.analyze(
        _machine(
          states: {start},
          initial: start,
          policy: TMAcceptancePolicy.halting,
          tapeCount: 2,
          transitions: {_multiTransition(start, start, TapeDirection.right)},
        ),
        '',
        maxConfigurations: 1,
      );

      expect(cancelled.outcome, TMExecutionOutcome.cancelled);
      expect(cancelled.acceptanceReason, TMAcceptanceReason.cancelled);
      expect(timedOut.limit, TMExecutionLimit.timeout);
      expect(timedOut.acceptanceReason, TMAcceptanceReason.timeout);
      expect(
        configurationBound.limit,
        TMExecutionLimit.configurations,
        reason: configurationBound.message,
      );
      expect(
        configurationBound.acceptanceReason,
        TMAcceptanceReason.configurationLimit,
      );
    });

    test('deterministic halt exactly at the step bound is resolved', () async {
      final start = _state('start', initial: true);
      final dead = _state('dead');

      for (final tapeCount in const [1, 2]) {
        final transition = tapeCount == 1
            ? _transition(start, dead, TapeDirection.stay)
            : _multiTransition(start, dead, TapeDirection.stay);
        final result = await TMExecutionAnalyzer.analyze(
          _machine(
            states: {start, dead},
            initial: start,
            transitions: {transition},
            policy: TMAcceptancePolicy.halting,
            tapeCount: tapeCount,
          ),
          '',
          maxSteps: 1,
        );

        expect(
          result.outcome,
          TMExecutionOutcome.accepted,
          reason: 'tapes=$tapeCount: ${result.message}',
        );
        expect(result.stepsExecuted, 1);
        expect(
          result.acceptanceReason,
          TMAcceptanceReason.haltedOutsideFinalState,
        );
      }
    });

    test('nondeterministic mixed branches preserve existential semantics',
        () async {
      final start = _state('start', initial: true);
      final dead = _state('dead');
      final moving = _state('moving');
      final transitions = {
        _transition(start, dead, TapeDirection.stay),
        _transition(start, moving, TapeDirection.right),
        _transition(moving, moving, TapeDirection.right),
      };
      final base = _machine(
        states: {start, dead, moving},
        initial: start,
        transitions: transitions,
      );

      final finalState = await TMExecutionAnalyzer.analyze(
        base,
        '',
        maxSteps: 2,
      );
      final halting = await TMExecutionAnalyzer.analyze(
        base.copyWith(acceptancePolicy: TMAcceptancePolicy.halting),
        '',
        maxSteps: 2,
      );

      expect(finalState.outcome, TMExecutionOutcome.boundedUnknown);
      expect(finalState.acceptanceReason, TMAcceptanceReason.stepLimit);
      expect(halting.outcome, TMExecutionOutcome.accepted);
      expect(
        halting.acceptanceReason,
        TMAcceptanceReason.haltedOutsideFinalState,
      );
    });

    test('multi-tape execution uses the document policy', () async {
      final result = await TMExecutionAnalyzer.analyze(
        _machine(
          policy: TMAcceptancePolicy.halting,
          tapeCount: 2,
        ),
        '',
      );

      expect(result.outcome, TMExecutionOutcome.accepted);
      expect(result.multiTapeMetrics, isNotNull);
      expect(
        result.acceptanceReason,
        TMAcceptanceReason.haltedOutsideFinalState,
      );
    });

    test('building-block root halting uses the root document policy', () {
      final root = _machine(policy: TMAcceptancePolicy.halting);

      final result = TMBlockExecutionEngine.execute(
        TMBlockProject(rootMachine: root),
        '',
      );

      expect(result.outcome, TMExecutionOutcome.accepted);
      expect(result.acceptancePolicy, TMAcceptancePolicy.halting);
      expect(
        result.acceptanceReason,
        TMAcceptanceReason.haltedOutsideFinalState,
      );
    });

    test('building-block execution resolves a halt exactly at the step bound',
        () {
      final start = _state('start', initial: true);
      final dead = _state('dead');
      final root = _machine(
        states: {start, dead},
        initial: start,
        transitions: {_transition(start, dead, TapeDirection.stay)},
        policy: TMAcceptancePolicy.halting,
      );

      final result = TMBlockExecutionEngine.execute(
        TMBlockProject(rootMachine: root),
        '',
        maxSteps: 1,
      );

      expect(result.outcome, TMExecutionOutcome.accepted);
      expect(result.stepsExecuted, 1);
      expect(
        result.acceptanceReason,
        TMAcceptanceReason.haltedOutsideFinalState,
      );
    });

    test('legacy simulator reports the same halting reason', () {
      final result = TMSimulator.simulate(
        _machine(policy: TMAcceptancePolicy.halting),
        '',
      );

      expect(result.isSuccess, isTrue);
      expect(result.data?.accepted, isTrue);
      expect(result.data?.acceptancePolicy, TMAcceptancePolicy.halting);
      expect(
        result.data?.acceptanceReason,
        TMAcceptanceReason.haltedOutsideFinalState,
      );
    });

    test('cooperative simulator reports the same halting reason', () async {
      final result = await TMSimulator.simulateCooperative(
        _machine(policy: TMAcceptancePolicy.halting),
        '',
      );

      expect(result.isSuccess, isTrue);
      expect(result.data?.outcome, TMExecutionOutcome.accepted);
      expect(result.data?.acceptancePolicy, TMAcceptancePolicy.halting);
      expect(
        result.data?.acceptanceReason,
        TMAcceptanceReason.haltedOutsideFinalState,
      );
    });
  });
}

TM _machine({
  Set<State>? states,
  State? initial,
  Set<State> accepting = const {},
  Set<TMTransition> transitions = const {},
  TMAcceptancePolicy policy = TMAcceptancePolicy.finalState,
  int tapeCount = 1,
}) {
  final start = initial ?? _state('start', initial: true);
  return TM(
    id: 'policy-machine',
    name: 'Policy machine',
    states: states ?? {start},
    transitions: transitions,
    alphabet: const {},
    initialState: start,
    acceptingStates: accepting,
    created: DateTime.utc(2026),
    modified: DateTime.utc(2026),
    bounds: const math.Rectangle(0, 0, 200, 100),
    tapeAlphabet: const {'B'},
    blankSymbol: 'B',
    tapeCount: tapeCount,
    acceptancePolicy: policy,
  );
}

State _state(
  String id, {
  bool initial = false,
  bool accepting = false,
}) =>
    State(
      id: id,
      label: id,
      position: Vector2.zero(),
      isInitial: initial,
      isAccepting: accepting,
    );

TMTransition _transition(
  State from,
  State to,
  TapeDirection direction,
) =>
    TMTransition(
      id: '${from.id}-${to.id}-${direction.name}',
      fromState: from,
      toState: to,
      label: '',
      readSymbol: 'B',
      writeSymbol: 'B',
      direction: direction,
    );

TMTransition _multiTransition(
  State from,
  State to,
  TapeDirection firstDirection,
) =>
    TMTransition(
      id: '${from.id}-${to.id}-multi-${firstDirection.name}',
      fromState: from,
      toState: to,
      controlPoint: from == to ? Vector2(20, -20) : null,
      label: TMTransition.formatVectorLabel(
        readSymbols: const ['B', 'B'],
        writeSymbols: const ['B', 'B'],
        directions: [firstDirection, TapeDirection.stay],
      ),
      readSymbols: const ['B', 'B'],
      writeSymbols: const ['B', 'B'],
      directions: [firstDirection, TapeDirection.stay],
    );
