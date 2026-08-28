@TestOn('browser')
library;

import 'dart:math' as math;

import 'package:test/test.dart';
import 'package:turing_lab/core/algorithms/tm_execution_analyzer.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/core/models/tm.dart';
import 'package:turing_lab/core/models/tm_execution_analysis.dart';
import 'package:turing_lab/core/models/tm_transition.dart';
import 'package:turing_lab/core/models/transition.dart';
import 'package:turing_lab/core/services/simulation_runner_backend_web.dart';
import 'package:turing_lab/core/services/simulation_runner_models.dart';
import 'package:vector_math/vector_math_64.dart';

import '../../../tool/hard_edge/families/tm_runtime_parity.dart';

void main() {
  test('web runtime matches canonical native acceptance and typed limits',
      () async {
    final serialized = TM.fromJson(_singleSymbolAcceptor().toJson());
    final outcome = await createWebSimulationRunnerBackend()
        .runTm(
          serialized,
          'a',
          stepByStep: true,
          timeout: const Duration(seconds: 5),
        )
        .outcome;

    expect(outcome.kind, SimulationOutcomeKind.accepted);
    expect(outcome.result?.outcome, TMExecutionOutcome.accepted);
    expect(outcome.result?.accepted, isTrue);
    expect(outcome.result?.inputString, 'a');
    expect(outcome.result?.limit, isNull);
    expect(
      outcome.result?.steps.map((step) => step.currentState),
      orderedEquals(const ['q0', 'accept', 'accept']),
    );

    final stepLimit = await TMExecutionAnalyzer.analyze(
      _movingForever(),
      '',
      maxSteps: 3,
    );
    final configurationLimit = await TMExecutionAnalyzer.analyze(
      _movingForever(),
      '',
      maxSteps: 100,
      maxConfigurations: 2,
    );
    final typedTimeout = await TMExecutionAnalyzer.analyze(
      _movingForever(),
      '',
      maxSteps: 10000,
      timeout: const Duration(microseconds: 1),
    );
    final timeout = await createWebSimulationRunnerBackend()
        .runTm(
          _movingForever(),
          '',
          stepByStep: false,
          timeout: const Duration(microseconds: 1),
        )
        .outcome;
    final cancellation = createWebSimulationRunnerBackend().runTm(
      _movingForever(),
      '',
      stepByStep: false,
      timeout: const Duration(seconds: 5),
    )..cancel();
    final cancelled = await cancellation.outcome;

    expect(
      <String, String>{
        'accepted.kind': outcome.kind.name,
        'accepted.outcome': outcome.result!.outcome.name,
        'step.outcome': stepLimit.outcome.name,
        'step.limit': stepLimit.limit!.name,
        'configuration.outcome': configurationLimit.outcome.name,
        'configuration.limit': configurationLimit.limit!.name,
        'timeout.kind': timeout.kind.name,
        'timeout.outcome': typedTimeout.outcome.name,
        'timeout.limit': typedTimeout.limit!.name,
        'cancel.kind': cancelled.kind.name,
      },
      tmCanonicalRuntimeSnapshot,
    );
  });
}

TM _movingForever() {
  final q0 = State(
    id: 'moving-q0',
    label: 'moving-q0',
    position: Vector2.zero(),
    isInitial: true,
  );
  final transition = TMTransition(
    id: 'move-right',
    fromState: q0,
    toState: q0,
    label: 'B/B,R',
    readSymbol: 'B',
    writeSymbol: 'B',
    direction: TapeDirection.right,
    controlPoint: Vector2(20, -20),
  );
  final now = DateTime.utc(2026, 8, 26);
  return TM(
    id: 'web-moving-forever',
    name: 'Web moving forever',
    states: {q0},
    transitions: <Transition>{transition},
    alphabet: const {},
    initialState: q0,
    acceptingStates: const {},
    created: now,
    modified: now,
    bounds: const math.Rectangle<double>(0, 0, 200, 100),
    tapeAlphabet: const {'B'},
  );
}

TM _singleSymbolAcceptor() {
  final q0 = State(
    id: 'q0',
    label: 'q0',
    position: Vector2.zero(),
    isInitial: true,
  );
  final accept = State(
    id: 'accept',
    label: 'accept',
    position: Vector2(100, 0),
    isAccepting: true,
  );
  final transition = TMTransition(
    id: 'accept-a',
    fromState: q0,
    toState: accept,
    label: 'a/a,S',
    readSymbol: 'a',
    writeSymbol: 'a',
    direction: TapeDirection.stay,
  );
  final now = DateTime.utc(2026, 8, 26);
  return TM(
    id: 'web-parity',
    name: 'Web parity fixture',
    states: {q0, accept},
    transitions: <Transition>{transition},
    alphabet: const {'a'},
    initialState: q0,
    acceptingStates: {accept},
    created: now,
    modified: now,
    bounds: const math.Rectangle<double>(0, 0, 200, 100),
    tapeAlphabet: const {'a', 'B'},
  );
}
