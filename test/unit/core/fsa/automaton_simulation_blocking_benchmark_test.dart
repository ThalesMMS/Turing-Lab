//
//  automaton_simulation_blocking_benchmark_test.dart
//  Turing Lab
//
//  Measures how long `AutomatonSimulator.simulate` keeps the calling isolate
//  busy without yielding (the longest gap between 1 ms heartbeat ticks) and
//  the wall time of the same run inside a worker isolate, including the cost
//  of transferring the automaton and the trace back. The numbers are printed
//  for #432; assertions only guard semantic equivalence because timings are
//  load-sensitive.
//

import 'dart:async';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/fsa/automaton_simulator.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/simulation_result.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:vector_math/vector_math_64.dart';

State _state(int index, {bool initial = false, bool accepting = false}) {
  return State(
    id: 'q$index',
    label: 'q$index',
    position: Vector2(index * 40.0, 100),
    isInitial: initial,
    isAccepting: accepting,
  );
}

FSA _fsa(Set<State> states, Set<FSATransition> transitions, State initial) {
  return FSA(
    id: 'bench',
    name: 'Benchmark',
    states: states,
    transitions: transitions,
    alphabet: const {'a', 'b'},
    initialState: initial,
    acceptingStates: states.where((s) => s.isAccepting).toSet(),
    created: DateTime.utc(2026),
    modified: DateTime.utc(2026),
    bounds: const math.Rectangle(0, 0, 4000, 200),
  );
}

/// Ring DFA over {a, b}: `a` advances, `b` stays; accepts in the last state.
FSA _ringDfa(int size) {
  final states = [
    for (var i = 0; i < size; i++)
      _state(i, initial: i == 0, accepting: i == size - 1),
  ];
  final transitions = <FSATransition>{
    for (var i = 0; i < size; i++) ...[
      FSATransition.deterministic(
        id: 'a$i',
        fromState: states[i],
        toState: states[(i + 1) % size],
        symbol: 'a',
      ),
      FSATransition.deterministic(
        id: 'b$i',
        fromState: states[i],
        toState: states[i],
        symbol: 'b',
      ),
    ],
  };
  return _fsa(states.toSet(), transitions, states.first);
}

/// NFA with an ε-chain feeding [width] parallel branches that each loop on
/// `a` and `b`; every branch stays alive on every symbol, so the active set
/// and ε-closures are wide for the whole input.
FSA _wideEpsilonNfa(int width) {
  final start = _state(0, initial: true);
  final branches = [
    for (var i = 1; i <= width; i++) _state(i, accepting: i == width),
  ];
  final transitions = <FSATransition>{
    for (final branch in branches)
      FSATransition.epsilon(
        id: 'e${branch.id}',
        fromState: start,
        toState: branch,
      ),
    for (final branch in branches) ...[
      FSATransition.deterministic(
        id: 'a${branch.id}',
        fromState: branch,
        toState: branch,
        symbol: 'a',
      ),
      FSATransition.deterministic(
        id: 'b${branch.id}',
        fromState: branch,
        toState: start,
        symbol: 'b',
      ),
    ],
  };
  return _fsa({start, ...branches}, transitions, start);
}

String _input(int length) =>
    List.generate(length, (index) => index % 7 == 6 ? 'b' : 'a').join();

class _Sample {
  const _Sample({
    required this.label,
    required this.wall,
    required this.longestStall,
    required this.accepted,
    required this.steps,
  });

  final String label;
  final Duration wall;
  final Duration longestStall;
  final bool accepted;
  final int steps;

  @override
  String toString() =>
      '$label: wall=${wall.inMilliseconds}ms '
      'longestStall=${longestStall.inMilliseconds}ms '
      'accepted=$accepted steps=$steps';
}

/// Runs [body] while a 1 ms heartbeat records the longest gap between ticks,
/// which is the longest span the isolate could not process events.
Future<_Sample> _measure(
  String label,
  Future<SimulationResult> Function() body,
) async {
  var last = DateTime.now();
  var longest = Duration.zero;
  final heartbeat = Timer.periodic(const Duration(milliseconds: 1), (_) {
    final now = DateTime.now();
    final gap = now.difference(last);
    if (gap > longest) longest = gap;
    last = now;
  });
  final stopwatch = Stopwatch()..start();
  final SimulationResult result;
  try {
    result = await body();
  } finally {
    stopwatch.stop();
    heartbeat.cancel();
  }
  // A body that never yields prevents every tick, so the gap since the last
  // tick is the stall in that case.
  final trailingGap = DateTime.now().difference(last);
  if (trailingGap > longest) longest = trailingGap;
  return _Sample(
    label: label,
    wall: stopwatch.elapsed,
    longestStall: longest,
    accepted: result.accepted,
    steps: result.steps.length,
  );
}

Future<SimulationResult> _cooperative(FSA fsa, String input) async {
  final result = await AutomatonSimulator.simulate(
    fsa,
    input,
    stepByStep: true,
    timeout: const Duration(seconds: 30),
  );
  return result.data!;
}

Future<SimulationResult> _inIsolate(FSA fsa, String input) async {
  final result = await Isolate.run(() async {
    final inner = await AutomatonSimulator.simulate(
      fsa,
      input,
      stepByStep: true,
      timeout: const Duration(seconds: 30),
    );
    return inner.data!;
  });
  return result;
}

void main() {
  test('DFA and NFA simulations: cooperative versus isolate', () async {
    final scenarios = <(String, FSA, String)>[
      ('DFA 50 states, 5000 symbols', _ringDfa(50), _input(5000)),
      ('DFA 50 states, 50000 symbols', _ringDfa(50), _input(50000)),
      ('NFA 6 ε-branches, 2000 symbols', _wideEpsilonNfa(6), _input(2000)),
      (
        'NFA 40 ε-branches, 500 symbols (hits trace budget)',
        _wideEpsilonNfa(40),
        _input(500),
      ),
    ];

    final report = StringBuffer('\n#432 simulation blocking benchmark\n');
    for (final (label, fsa, input) in scenarios) {
      final cooperative = await _measure(
        '$label | cooperative',
        () => _cooperative(fsa, input),
      );
      final isolate = await _measure(
        '$label | isolate',
        () => _inIsolate(fsa, input),
      );
      report
        ..writeln(cooperative)
        ..writeln(isolate);
      expect(isolate.accepted, cooperative.accepted, reason: label);
      expect(isolate.steps, cooperative.steps, reason: label);
    }
    // Printed so the numbers land in the test log for the issue record.
    // ignore: avoid_print
    print(report);
  }, timeout: const Timeout(Duration(minutes: 5)));
}
