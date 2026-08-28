import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/pda_simulator.dart';
import 'package:turing_lab/core/batch_execution/batch_execution.dart';
import 'package:turing_lab/core/models/pda.dart';
import 'package:turing_lab/core/models/pda_transition.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/core/models/step_explanation.dart';
import 'package:turing_lab/core/validators/input_validators.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  group('PDA document acceptance policy', () {
    test('distinguishes empty-input final-state and empty-stack rules', () {
      final pda = _emptyInputFinalStatePda();

      expect(_accepts(pda, PDAAcceptanceMode.finalState, ''), isTrue);
      expect(_accepts(pda, PDAAcceptanceMode.emptyStack, ''), isFalse);
      expect(_accepts(pda, PDAAcceptanceMode.both, ''), isFalse);
    });

    test('accepts by empty stack with no final states', () {
      final pda = _consumingPda(
        acceptingDestination: false,
        emptyDestinationStack: true,
      );

      expect(_accepts(pda, PDAAcceptanceMode.finalState, 'a'), isFalse);
      expect(_accepts(pda, PDAAcceptanceMode.emptyStack, 'a'), isTrue);
      expect(_accepts(pda, PDAAcceptanceMode.both, 'a'), isFalse);
    });

    test('validation allows no final states only for empty-stack mode', () {
      final pda = _deadPda();

      expect(
        _validationCodes(
          pda.copyWith(acceptanceMode: PDAAcceptanceMode.emptyStack),
        ),
        isNot(contains('PDA_NO_ACCEPTING')),
      );
      expect(
        _validationCodes(
          pda.copyWith(acceptanceMode: PDAAcceptanceMode.finalState),
        ),
        contains('PDA_NO_ACCEPTING'),
      );
      expect(
        _validationCodes(
          pda.copyWith(acceptanceMode: PDAAcceptanceMode.both),
        ),
        contains('PDA_NO_ACCEPTING'),
      );
    });

    test('requires both conditions when final state and stack conflict', () {
      final finalOnly = _consumingPda(
        acceptingDestination: true,
        emptyDestinationStack: false,
      );
      final both = _consumingPda(
        acceptingDestination: true,
        emptyDestinationStack: true,
      );

      expect(_accepts(finalOnly, PDAAcceptanceMode.finalState, 'a'), isTrue);
      expect(_accepts(finalOnly, PDAAcceptanceMode.emptyStack, 'a'), isFalse);
      expect(_accepts(finalOnly, PDAAcceptanceMode.both, 'a'), isFalse);
      expect(_accepts(both, PDAAcceptanceMode.both, 'a'), isTrue);
    });

    test('rejects a dead configuration under every rule', () {
      final pda = _deadPda();

      for (final mode in PDAAcceptanceMode.values) {
        expect(_accepts(pda, mode, ''), isFalse, reason: mode.name);
      }
    });

    test('single and batch execution both honor the stored rule', () async {
      final source = _consumingPda(
        acceptingDestination: true,
        emptyDestinationStack: false,
      );
      final finalState = source.copyWith(
        acceptanceMode: PDAAcceptanceMode.finalState,
      );
      final both = source.copyWith(acceptanceMode: PDAAcceptanceMode.both);

      expect(PDASimulator.simulate(finalState, 'a').data!.accepted, isTrue);
      expect(PDASimulator.simulate(both, 'a').data!.accepted, isFalse);
      expect(await _batchOutcome(finalState, 'a'), BatchOutcomeCode.accepted);
      expect(await _batchOutcome(both, 'a'), BatchOutcomeCode.rejected);
    });

    test('accepted trace explains the active rule', () {
      final pda = _consumingPda(
        acceptingDestination: true,
        emptyDestinationStack: true,
      ).copyWith(acceptanceMode: PDAAcceptanceMode.both);

      final result = PDASimulator.simulate(pda, 'a', stepByStep: true).data!;
      final explanation = result.steps.last.explanation!;

      expect(explanation.title, 'Accepted by final state and empty stack');
      expect(explanation.categories, contains(ExplanationCategory.acceptance));
      expect(explanation.bullets.join(' '), contains('both acceptance'));
    });
  });
}

Set<String> _validationCodes(PDA pda) =>
    InputValidators.validatePDA(pda).map((issue) => issue.code).toSet();

bool _accepts(PDA pda, PDAAcceptanceMode mode, String input) {
  final result = PDASimulator.simulateNPDA(pda, input, mode: mode);
  expect(result.isSuccess, isTrue);
  return result.data!.accepted;
}

Future<BatchOutcomeCode> _batchOutcome(PDA pda, String input) async {
  final report = await const BatchExecutionRunner()
      .start(
        BatchExecutionRequest(
          modelId: pda.id,
          modelRevision: pda.modified.toIso8601String(),
          strategyId: 'simulate',
          tokenizationMode: BatchTokenizationMode.rawString,
          cases: [BatchInputCase(id: 'case', input: input)],
        ),
        PdaBatchExecutor(pda),
      )
      .report;
  return report.results.single.outcome;
}

PDA _emptyInputFinalStatePda() {
  final q0 = _state('q0', initial: true, accepting: true);
  return _pda(states: {q0}, initial: q0, accepting: {q0});
}

PDA _deadPda() {
  final q0 = _state('q0', initial: true);
  return _pda(states: {q0}, initial: q0);
}

PDA _consumingPda({
  required bool acceptingDestination,
  required bool emptyDestinationStack,
}) {
  final q0 = _state('q0', initial: true);
  final q1 = _state('q1', accepting: acceptingDestination);
  final transition = PDATransition(
    id: 'consume-a',
    fromState: q0,
    toState: q1,
    label: emptyDestinationStack ? 'a, Z/ε' : 'a, Z/Z',
    inputSymbol: 'a',
    popSymbol: 'Z',
    pushSymbol: emptyDestinationStack ? '' : 'Z',
    isLambdaPush: emptyDestinationStack,
  );
  return _pda(
    states: {q0, q1},
    initial: q0,
    accepting: acceptingDestination ? {q1} : const {},
    transitions: {transition},
    alphabet: const {'a'},
  );
}

State _state(
  String id, {
  bool initial = false,
  bool accepting = false,
}) {
  return State(
    id: id,
    label: id,
    position: Vector2.zero(),
    isInitial: initial,
    isAccepting: accepting,
  );
}

PDA _pda({
  required Set<State> states,
  required State initial,
  Set<State> accepting = const {},
  Set<PDATransition> transitions = const {},
  Set<String> alphabet = const {},
}) {
  return PDA(
    id: 'acceptance-policy',
    name: 'Acceptance policy',
    states: states,
    transitions: transitions,
    alphabet: alphabet,
    initialState: initial,
    acceptingStates: accepting,
    created: DateTime.utc(2026),
    modified: DateTime.utc(2026),
    bounds: const math.Rectangle<double>(0, 0, 400, 300),
    stackAlphabet: const {'Z'},
  );
}
