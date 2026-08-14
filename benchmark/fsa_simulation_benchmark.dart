import 'dart:math' as math;

import 'package:turing_lab/core/algorithms/automaton_simulator.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:vector_math/vector_math_64.dart';

const _stateCount = 1000;
const _inputLength = 10000;

Future<void> main() async {
  final automaton = _largeDfa();
  final input = List.filled(_inputLength, 'a').join();

  await _measure(automaton, input, stepByStep: false);
  await _measure(automaton, input, stepByStep: true);
}

Future<void> _measure(
  FSA automaton,
  String input, {
  required bool stepByStep,
}) async {
  final stopwatch = Stopwatch()..start();
  final result = await AutomatonSimulator.simulateDFA(
    automaton,
    input,
    stepByStep: stepByStep,
    timeout: const Duration(minutes: 1),
  );
  stopwatch.stop();
  if (!result.isSuccess || !result.data!.accepted) {
    throw StateError(
      result.error ?? result.data?.errorMessage ?? 'Simulation failed',
    );
  }
  print(
    '${stepByStep ? 'trace' : 'non-trace'}: '
    '$_stateCount transitions, $_inputLength symbols, '
    '${result.data!.steps.length} stored steps, '
    '${stopwatch.elapsedMilliseconds}ms',
  );
}

FSA _largeDfa() {
  final states = List<State>.generate(
    _stateCount,
    (index) => State(
      id: 'q$index',
      label: 'q$index',
      position: Vector2(index.toDouble(), 0),
      isInitial: index == 0,
      isAccepting: index == 0,
    ),
  );
  final transitions = <FSATransition>{
    for (var index = 0; index < states.length; index++)
      FSATransition(
        id: 't$index',
        fromState: states[index],
        toState: states[(index + 1) % states.length],
        inputSymbols: const {'a'},
        label: 'a',
      ),
  };
  return FSA(
    id: 'large-dfa',
    name: 'Large DFA benchmark',
    states: states.toSet(),
    transitions: transitions,
    alphabet: const {'a'},
    initialState: states.first,
    acceptingStates: {states.first},
    created: DateTime(2026),
    modified: DateTime(2026),
    bounds: const math.Rectangle(0, 0, 1000, 1000),
  );
}
