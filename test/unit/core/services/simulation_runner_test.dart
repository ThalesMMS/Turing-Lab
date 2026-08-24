import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/pda_simulator.dart';
import 'package:turing_lab/core/algorithms/tm_simulator.dart';
import 'package:turing_lab/core/models/pda.dart';
import 'package:turing_lab/core/models/pda_transition.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/core/models/tm.dart';
import 'package:turing_lab/core/models/tm_transition.dart';
import 'package:turing_lab/core/services/simulation_runner.dart';
import 'package:turing_lab/core/services/simulation_runner_backend_web.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  group('simulation outcome classification', () {
    test('keeps accept, reject, timeout, and proven cycles distinct', () {
      const elapsed = Duration.zero;
      expect(
        classifyPdaResult(
          PDASimulationResult.success(
            inputString: '',
            steps: const [],
            executionTime: elapsed,
          ),
        ).kind,
        SimulationOutcomeKind.accepted,
      );
      expect(
        classifyPdaResult(
          PDASimulationResult.failure(
            inputString: '',
            steps: const [],
            errorMessage: 'Rejected',
            executionTime: elapsed,
          ),
        ).kind,
        SimulationOutcomeKind.rejected,
      );
      expect(
        classifyPdaResult(
          PDASimulationResult.timeout(
            inputString: '',
            steps: const [],
            executionTime: elapsed,
          ),
        ).kind,
        SimulationOutcomeKind.timeout,
      );
      expect(
        classifyTmResult(
          TMSimulationResult.infiniteLoop(
            inputString: '',
            steps: const [],
            executionTime: elapsed,
          ),
        ).kind,
        SimulationOutcomeKind.provenCycle,
      );
      expect(
        classifyTmResult(
          TMSimulationResult.failure(
            inputString: '',
            steps: const [],
            errorMessage: 'Rejected: no accepting configuration found',
            executionTime: elapsed,
          ),
        ).kind,
        SimulationOutcomeKind.rejected,
      );
      expect(
        classifyTmResult(
          TMSimulationResult.timeout(
            inputString: '',
            steps: const [],
            executionTime: elapsed,
          ),
        ).kind,
        SimulationOutcomeKind.timeout,
      );
      expect(
        classifyTmResult(
          TMSimulationResult.configurationLimit(
            inputString: '',
            steps: const [],
            executionTime: elapsed,
          ),
        ).kind,
        SimulationOutcomeKind.configurationLimit,
      );
      expect(
        classifyTmResult(
          TMSimulationResult.stepLimit(
            inputString: '',
            steps: const [],
            executionTime: elapsed,
          ),
        ).kind,
        SimulationOutcomeKind.boundedUnknown,
      );
    });
  });

  group('native simulation runner', () {
    test('returns a successful worker result before the exit signal', () async {
      final outcome = await SimulationRunner()
          .runTm(
            _acceptingTm(),
            '',
            stepByStep: false,
          )
          .outcome;

      expect(outcome.kind, SimulationOutcomeKind.accepted);
    });

    test('runs on a worker and cancels a branching NTM', () async {
      final task = SimulationRunner().runTm(
        _branchingNtm(),
        '',
        stepByStep: false,
        timeout: const Duration(minutes: 1),
      );
      var eventProcessed = false;
      final cancellationReady = Completer<void>();
      Timer.run(() {
        eventProcessed = true;
        cancellationReady.complete();
      });

      await cancellationReady.future;
      task.cancel();

      expect(eventProcessed, isTrue);
      expect((await task.outcome).kind, SimulationOutcomeKind.cancelled);
    });
  });

  group('web cooperative simulation runner', () {
    test('yields and cancels a branching PDA near its search limit', () async {
      final task = createWebSimulationRunnerBackend().runPda(
        _branchingPda(),
        '',
        stepByStep: false,
        timeout: const Duration(minutes: 1),
      );
      var eventProcessed = false;
      final cancellationReady = Completer<void>();
      Timer.run(() {
        eventProcessed = true;
        cancellationReady.complete();
      });

      await cancellationReady.future;
      task.cancel();

      expect(eventProcessed, isTrue);
      expect((await task.outcome).kind, SimulationOutcomeKind.cancelled);
    });

    test('yields and cancels a branching NTM near its search limit', () async {
      final task = createWebSimulationRunnerBackend().runTm(
        _branchingNtm(),
        '',
        stepByStep: false,
        timeout: const Duration(minutes: 1),
      );
      var eventProcessed = false;
      final cancellationReady = Completer<void>();
      Timer.run(() {
        eventProcessed = true;
        cancellationReady.complete();
      });

      await cancellationReady.future;
      task.cancel();

      expect(eventProcessed, isTrue);
      expect((await task.outcome).kind, SimulationOutcomeKind.cancelled);
    });
  });
}

TM _acceptingTm() {
  final state = State(
    id: 'q0',
    label: 'q0',
    position: Vector2.zero(),
    isInitial: true,
    isAccepting: true,
  );
  return TM(
    id: 'accepting-tm',
    name: 'Accepting TM',
    states: {state},
    transitions: const {},
    alphabet: const {},
    initialState: state,
    acceptingStates: {state},
    created: DateTime.utc(2026),
    modified: DateTime.utc(2026),
    bounds: const math.Rectangle(0, 0, 400, 300),
    tapeAlphabet: const {'B'},
    blankSymbol: 'B',
    tapeCount: 1,
  );
}

PDA _branchingPda() {
  final state = State(
    id: 'q0',
    label: 'q0',
    position: Vector2.zero(),
    isInitial: true,
  );
  return PDA(
    id: 'branching-pda',
    name: 'Branching PDA',
    states: {state},
    transitions: {
      PDATransition(
        id: 'push-a',
        fromState: state,
        toState: state,
        inputSymbol: '',
        popSymbol: '',
        pushSymbol: 'A',
        label: 'ε,ε/A',
      ),
      PDATransition(
        id: 'push-b',
        fromState: state,
        toState: state,
        inputSymbol: '',
        popSymbol: '',
        pushSymbol: 'B',
        label: 'ε,ε/B',
      ),
    },
    alphabet: const {},
    initialState: state,
    acceptingStates: const {},
    stackAlphabet: const {'Z', 'A', 'B'},
    initialStackSymbol: 'Z',
    created: DateTime(2026),
    modified: DateTime(2026),
    bounds: const math.Rectangle(0, 0, 400, 300),
  );
}

TM _branchingNtm() {
  final state = State(
    id: 'q0',
    label: 'q0',
    position: Vector2.zero(),
    isInitial: true,
  );
  return TM(
    id: 'branching-ntm',
    name: 'Branching NTM',
    states: {state},
    transitions: {
      TMTransition(
        id: 'keep-blank',
        fromState: state,
        toState: state,
        label: 'B/B,R',
        readSymbol: 'B',
        writeSymbol: 'B',
        direction: TapeDirection.right,
        tapeNumber: 0,
      ),
      TMTransition(
        id: 'write-x',
        fromState: state,
        toState: state,
        label: 'B/X,R',
        readSymbol: 'B',
        writeSymbol: 'X',
        direction: TapeDirection.right,
        tapeNumber: 0,
      ),
    },
    alphabet: const {},
    initialState: state,
    acceptingStates: const {},
    created: DateTime(2026),
    modified: DateTime(2026),
    bounds: const math.Rectangle(0, 0, 400, 300),
    tapeAlphabet: const {'B', 'X'},
    blankSymbol: 'B',
    tapeCount: 1,
  );
}
