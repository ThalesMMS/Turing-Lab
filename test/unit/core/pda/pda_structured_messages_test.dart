import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/pda_simulator.dart';
import 'package:turing_lab/core/messages/structured_message.dart';
import 'package:turing_lab/core/models/pda.dart';
import 'package:turing_lab/core/models/pda_transition.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/core/models/transition.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  final pda = _acceptsA();

  test('resource outcomes carry stable structured messages', () {
    final timeout = PDASimulator.simulateNPDA(pda, 'a', timeout: Duration.zero);
    final depth = PDASimulator.simulateNPDA(pda, 'a', maxDepth: 0);
    final memory = PDASimulator.simulateNPDA(pda, 'a', maxMemoryBytes: 0);
    final configurations = PDASimulator.simulateNPDA(
      pda,
      'a',
      maxConfigurations: 0,
    );
    final stale = PDASimulator.simulateNPDA(pda, 'a', isStale: () => true);

    expect(
      timeout.data!.structuredMessage?.stableCode,
      'pda.simulation.timeout',
    );
    expect(
      depth.data!.structuredMessage?.stableCode,
      'pda.simulation.depth-limit',
    );
    expect(
      memory.data!.structuredMessage?.stableCode,
      'pda.simulation.memory-limit',
    );
    expect(
      configurations.data!.structuredMessage?.stableCode,
      'pda.simulation.configuration-limit',
    );
    expect(
      stale.data!.structuredMessage?.stableCode,
      'pda.simulation.stale-request',
    );

    final rejected = PDASimulator.simulateNPDA(pda, 'aa');
    expect(
      rejected.data!.structuredMessage?.stableCode,
      'pda.simulation.rejected-no-accepting-configuration',
    );
  });

  test(
    'invalid simulator options retain legacy errors and typed payloads',
    () async {
      final search = PDASimulator.simulateNPDA(pda, 'a', maxDepth: -1);
      expect(search.error, 'PDA search limits must not be negative');
      expect(
        search.structuredError?.stableCode,
        'pda.simulation.search-limits-negative',
      );

      final memory = PDASimulator.simulateNPDA(pda, 'a', maxMemoryBytes: -1);
      expect(memory.error, 'PDA memory limit must not be negative');
      expect(
        memory.structuredError?.stableCode,
        'pda.simulation.memory-limit-negative',
      );

      final batch = await PDASimulator.simulateCooperative(
        pda,
        'a',
        configurationsPerBatch: 0,
      );
      expect(batch.error, 'Configurations per batch must be greater than zero');
      expect(
        batch.structuredError?.stableCode,
        'pda.simulation.configurations-per-batch-invalid',
      );
    },
  );

  test('PDA transition explanations use locale-neutral trace payloads', () {
    final result = PDASimulator.simulateNPDA(pda, 'a', stepByStep: true);
    expect(result.isSuccess, isTrue, reason: result.error);
    final transition = result.data!.steps.firstWhere(
      (step) => step.consumedInput == 'a',
    );
    final explanation = transition.explanation!;

    expect(explanation.usesLegacyText, isFalse);
    expect(
      explanation.titleMessage?.stableCode,
      'pda.simulation.transition-title',
    );
    expect(explanation.bulletMessages.map((message) => message.stableCode), [
      'pda.simulation.read-input',
      'pda.simulation.stack-action',
      'pda.simulation.stack-top-change',
      'pda.simulation.pop-matches',
      'pda.simulation.pushed',
    ]);
    expect(explanation.bulletMessages[0].arguments['symbol']!.value, 'a');
    expect(
      StructuredMessage.fromJson(explanation.titleMessage!.toJson()),
      explanation.titleMessage,
    );
  });

  test('accepts and string generation preserve structured failures', () {
    final invalid = _acceptsA(states: const {});
    final accepted = PDASimulator.findAcceptedStrings(invalid, 0);
    final rejected = PDASimulator.findRejectedStrings(invalid, 0);

    expect(accepted.isFailure, isTrue);
    expect(
      accepted.structuredError?.stableCode,
      'pda.simulation.accepted-strings-failure',
    );
    expect(rejected.isFailure, isTrue);
    expect(
      rejected.structuredError?.stableCode,
      'pda.simulation.rejected-strings-failure',
    );
  });
}

PDA _acceptsA({Set<State>? states}) {
  final q0 = State(
    id: 'q0',
    label: 'q0',
    position: Vector2.zero(),
    isInitial: true,
  );
  final q1 = State(
    id: 'q1',
    label: 'q1',
    position: Vector2(100, 0),
    isAccepting: true,
  );
  final transition = PDATransition(
    id: 't0',
    fromState: q0,
    toState: q1,
    inputSymbol: 'a',
    popSymbol: 'Z',
    pushSymbol: 'Z',
    label: 'a,Z/Z',
  );
  return PDA(
    id: 'accepts-a',
    name: 'Accepts a',
    states: states ?? {q0, q1},
    transitions: <Transition>{transition},
    alphabet: const {'a'},
    initialState: q0,
    acceptingStates: {q1},
    stackAlphabet: const {'Z'},
    initialStackSymbol: 'Z',
    created: DateTime.utc(2026),
    modified: DateTime.utc(2026),
    bounds: const math.Rectangle(0, 0, 300, 200),
  );
}
