import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/tm_execution_kernel.dart';
import 'package:turing_lab/core/algorithms/tm_execution_analyzer.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/core/models/tm.dart';
import 'package:turing_lab/core/models/tm_execution_analysis.dart';
import 'package:turing_lab/core/models/tm_transition.dart';
import 'package:turing_lab/core/models/transition.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  test('k-tape transition snapshots operation vectors', () {
    final reads = ['a', 'B'];
    final writes = ['B', 'a'];
    final moves = [TapeDirection.right, TapeDirection.left];
    final transition = _transition(reads, writes, moves);

    reads[0] = 'changed';
    writes[1] = 'changed';
    moves[0] = TapeDirection.stay;

    expect(transition.readSymbols, ['a', 'B']);
    expect(transition.writeSymbols, ['B', 'a']);
    expect(transition.directions, [TapeDirection.right, TapeDirection.left]);
    expect(() => transition.readSymbols[0] = 'x', throwsUnsupportedError);
  });

  test('atomic kernel matches every read and updates all tapes together', () {
    final machine = _machine(
      tapeCount: 2,
      transition: _transition(
        ['a', 'B'],
        ['B', 'a'],
        [TapeDirection.right, TapeDirection.left],
      ),
    );
    final tapes = TMExecutionKernel.initialTapes('a', 'B', 2);
    final heads = [0, 0];
    final reads = TMExecutionKernel.readVector(tapes, heads, 'B');

    expect(
      TMExecutionKernel.transitionsForVector(
        machine,
        machine.initialState!,
        reads,
      ).single.id,
      'move',
    );
    expect(
      TMExecutionKernel.transitionsForVector(
        machine,
        machine.initialState!,
        ['a', 'a'],
      ),
      isEmpty,
    );

    final next = TMExecutionKernel.applyTransition(
      sourceTapes: tapes,
      sourceHeads: heads,
      transition: machine.tmTransitions.single,
      blankSymbol: 'B',
    );
    expect(tapes[0], {0: 'a'}, reason: 'source tape stays immutable');
    expect(tapes[1], isEmpty);
    expect(next.tapes[0], isEmpty);
    expect(next.tapes[1], {0: 'a'});
    expect(next.heads, [1, -1]);
  });

  test('configuration identity includes every tape and head', () {
    final baseline = TMConfigurationSnapshot.canonicalMulti(
      stateId: 'q0',
      headPositions: [0, 0],
      tapes: [
        {0: 'a'},
        <int, String>{},
      ],
      blankSymbol: 'B',
    );
    final secondTapeChanged = TMConfigurationSnapshot.canonicalMulti(
      stateId: 'q0',
      headPositions: [0, 0],
      tapes: [
        {0: 'a'},
        {0: 'a'},
      ],
      blankSymbol: 'B',
    );
    final secondHeadChanged = TMConfigurationSnapshot.canonicalMulti(
      stateId: 'q0',
      headPositions: [0, -1],
      tapes: [
        {0: 'a'},
        <int, String>{},
      ],
      blankSymbol: 'B',
    );

    expect(baseline.key, isNot(secondTapeChanged.key));
    expect(baseline.key, isNot(secondHeadChanged.key));
  });

  test('single-tape JSON migrates to one-element vectors without loss', () {
    final transition = _transition(
      ['a'],
      ['b'],
      [TapeDirection.stay],
    );
    final legacy = transition.toJson()
      ..remove('readSymbols')
      ..remove('writeSymbols')
      ..remove('directions');

    final restored = TMTransition.fromJson(
      legacy,
      statesById: {'q0': transition.fromState, 'q1': transition.toState},
    );

    expect(restored.readSymbols, ['a']);
    expect(restored.writeSymbols, ['b']);
    expect(restored.directions, [TapeDirection.stay]);
    expect(restored.readSymbol, 'a');
  });

  test('machine validation rejects vector length and unknown tape symbols', () {
    final mismatch = _machine(
      tapeCount: 2,
      transition: _transition(
        ['a', 'B', 'B'],
        ['B', 'a', 'B'],
        [TapeDirection.right, TapeDirection.stay, TapeDirection.left],
      ),
    );
    expect(
      mismatch.validate(),
      contains(contains('does not match tape count 2')),
    );

    final unknown = _machine(
      tapeCount: 2,
      transition: _transition(
        ['a', 'outside'],
        ['B', 'a'],
        [TapeDirection.right, TapeDirection.stay],
      ),
    );
    expect(
      unknown.validate(),
      contains(contains('invalid read symbol on tape 1')),
    );
  });

  test('bounded analyzer executes a two-tape transition atomically', () async {
    final machine = _machine(
      tapeCount: 2,
      transition: _transition(
        ['a', 'B'],
        ['B', 'a'],
        [TapeDirection.right, TapeDirection.left],
      ),
    );

    final result = await TMExecutionAnalyzer.analyze(machine, 'a');

    expect(result.outcome, TMExecutionOutcome.accepted);
    expect(result.multiTapeTrace, hasLength(1));
    final step = result.multiTapeTrace.single;
    expect(step.readSymbols, ['a', 'B']);
    expect(step.configuration.headPositions, [1, -1]);
    expect(step.configuration.nonBlankCellsByTape[0], isEmpty);
    expect(step.configuration.nonBlankCellsByTape[1], {0: 'a'});
    expect(result.traceMetrics, isNull);
    expect(result.multiTapeMetrics!.maximumVisitedSpanByTape, [2, 2]);
    expect(result.multiTapeMetrics!.maximumTotalNonBlankCells, 1);
  });

  test('analyzer does not enable a partially matching read vector', () async {
    final machine = _machine(
      tapeCount: 2,
      transition: _transition(
        ['a', 'a'],
        ['B', 'B'],
        [TapeDirection.stay, TapeDirection.stay],
      ),
    );

    final result = await TMExecutionAnalyzer.analyze(machine, 'a');

    expect(result.outcome, TMExecutionOutcome.haltedRejected);
    expect(result.stepsExecuted, 0);
  });

  test('three tapes handle empty input, simultaneous writes, left, and stay',
      () async {
    final from = _state('q0', initial: true);
    final to = _state('q1', accepting: true);
    final transition = TMTransition(
      id: 'three-way',
      fromState: from,
      toState: to,
      label: 'three-way',
      readSymbols: const ['B', 'B', 'B'],
      writeSymbols: const ['x', 'y', 'z'],
      directions: const [
        TapeDirection.left,
        TapeDirection.stay,
        TapeDirection.right,
      ],
    );
    final machine = _machineFrom(
      tapeCount: 3,
      states: {from, to},
      transitions: {transition},
      acceptingStates: {to},
      tapeAlphabet: const {'B', 'x', 'y', 'z'},
      alphabet: const {},
    );

    final result = await TMExecutionAnalyzer.analyze(machine, '');

    expect(result.outcome, TMExecutionOutcome.accepted);
    expect(
        result.multiTapeTrace.single.configuration.headPositions, [-1, 0, 1]);
    expect(result.multiTapeTrace.single.configuration.nonBlankCellsByTape, [
      {0: 'x'},
      {0: 'y'},
      {0: 'z'},
    ]);
  });

  test('nondeterministic multi-tape BFS accepts when one branch accepts',
      () async {
    final from = _state('q0', initial: true);
    final reject = _state('qr');
    final accept = _state('qa', accepting: true);
    TMTransition branch(String id, State target) => TMTransition(
          id: id,
          fromState: from,
          toState: target,
          label: id,
          type: TransitionType.nondeterministic,
          readSymbols: const ['a', 'B'],
          writeSymbols: const ['a', 'B'],
          directions: const [TapeDirection.stay, TapeDirection.stay],
        );
    final machine = _machineFrom(
      tapeCount: 2,
      states: {from, reject, accept},
      transitions: {branch('reject', reject), branch('accept', accept)},
      acceptingStates: {accept},
      tapeAlphabet: const {'a', 'B'},
      alphabet: const {'a'},
    );

    final result = await TMExecutionAnalyzer.analyze(machine, 'a');

    expect(machine.isNondeterministic, isTrue);
    expect(result.outcome, TMExecutionOutcome.accepted);
    expect(result.multiTapeTrace.single.transitionId, 'accept');
  });

  test('repeated full multi-tape configuration proves deterministic cycle',
      () async {
    final state = _state('q0', initial: true);
    final loop = TMTransition(
      id: 'loop',
      fromState: state,
      toState: state,
      label: 'loop',
      controlPoint: Vector2(20, -20),
      readSymbols: const ['B', 'B'],
      writeSymbols: const ['B', 'B'],
      directions: const [TapeDirection.stay, TapeDirection.stay],
    );
    final machine = _machineFrom(
      tapeCount: 2,
      states: {state},
      transitions: {loop},
      acceptingStates: const {},
      tapeAlphabet: const {'B'},
      alphabet: const {},
    );

    final result = await TMExecutionAnalyzer.analyze(machine, '');

    expect(result.outcome, TMExecutionOutcome.provenCycle);
    expect(result.cycle?.period, 1);
    expect(result.cycle?.configuration.headPositions, [0, 0]);
  });

  test('long moving run remains bounded unknown and trace can be disabled',
      () async {
    final state = _state('q0', initial: true);
    final loop = TMTransition(
      id: 'move-forever',
      fromState: state,
      toState: state,
      label: 'move-forever',
      controlPoint: Vector2(20, -20),
      readSymbols: const ['B', 'B'],
      writeSymbols: const ['B', 'B'],
      directions: const [TapeDirection.right, TapeDirection.left],
    );
    final machine = _machineFrom(
      tapeCount: 2,
      states: {state},
      transitions: {loop},
      acceptingStates: const {},
      tapeAlphabet: const {'B'},
      alphabet: const {},
    );

    final result = await TMExecutionAnalyzer.analyze(
      machine,
      '',
      maxSteps: 25,
      includeTrace: false,
    );

    expect(result.outcome, TMExecutionOutcome.boundedUnknown);
    expect(result.limit, TMExecutionLimit.steps);
    expect(result.multiTapeTrace, isEmpty);
    expect(result.multiTapeMetrics!.maximumVisitedSpanByTape, [26, 26]);
  });
}

TMTransition _transition(
  Iterable<String> reads,
  Iterable<String> writes,
  Iterable<TapeDirection> moves,
) {
  final from = _state('q0', initial: true);
  final to = _state('q1', accepting: true);
  return TMTransition(
    id: 'move',
    fromState: from,
    toState: to,
    label: 'move',
    type: TransitionType.deterministic,
    readSymbols: reads,
    writeSymbols: writes,
    directions: moves,
  );
}

TM _machine({required int tapeCount, required TMTransition transition}) => TM(
      id: 'multi',
      name: 'Multi-tape',
      states: {transition.fromState, transition.toState},
      transitions: {transition},
      alphabet: {'a'},
      initialState: transition.fromState,
      acceptingStates: {transition.toState},
      created: DateTime.utc(2026),
      modified: DateTime.utc(2026),
      bounds: const math.Rectangle(0, 0, 400, 300),
      tapeAlphabet: {'a', 'B'},
      blankSymbol: 'B',
      tapeCount: tapeCount,
    );

TM _machineFrom({
  required int tapeCount,
  required Set<State> states,
  required Set<TMTransition> transitions,
  required Set<State> acceptingStates,
  required Set<String> tapeAlphabet,
  required Set<String> alphabet,
}) =>
    TM(
      id: 'multi-custom',
      name: 'Multi-tape custom',
      states: states,
      transitions: transitions,
      alphabet: alphabet,
      initialState: states.singleWhere((state) => state.isInitial),
      acceptingStates: acceptingStates,
      created: DateTime.utc(2026),
      modified: DateTime.utc(2026),
      bounds: const math.Rectangle(0, 0, 400, 300),
      tapeAlphabet: tapeAlphabet,
      blankSymbol: 'B',
      tapeCount: tapeCount,
    );

State _state(String id, {bool initial = false, bool accepting = false}) =>
    State(
      id: id,
      label: id,
      position: Vector2.zero(),
      isInitial: initial,
      isAccepting: accepting,
    );
