import 'dart:math' as math;

import 'package:turing_lab/core/algorithms/pda_simulator.dart';
import 'package:turing_lab/core/models/pda.dart';
import 'package:turing_lab/core/models/pda_transition.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:test/test.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  test('PDA synchronous and cooperative paths agree on current platform',
      () async {
    final pda = _balancedPda();
    for (final input in const ['', 'ab', 'aabb', 'aaabbb', 'aab']) {
      final synchronous = PDASimulator.simulateNPDA(
        pda,
        input,
        mode: PDAAcceptanceMode.both,
      );
      final cooperative = await PDASimulator.simulateCooperative(
        pda,
        input,
        mode: PDAAcceptanceMode.both,
        configurationsPerBatch: 1,
      );

      expect(synchronous.isSuccess, isTrue, reason: synchronous.error);
      expect(cooperative.isSuccess, isTrue, reason: cooperative.error);
      expect(
        cooperative.data!.accepted,
        synchronous.data!.accepted,
        reason: input,
      );
      expect(
        synchronous.data!.accepted,
        input == 'ab' || input == 'aabb' || input == 'aaabbb',
      );
    }
  });
}

PDA _balancedPda() {
  final q0 = _state('q0', initial: true, x: 0);
  final q1 = _state('q1', x: 120);
  final q2 = _state('q2', accepting: true, x: 240);
  return PDA(
    id: 'web-parity-pda',
    name: 'Web parity PDA',
    states: {q0, q1, q2},
    transitions: {
      _transition(
        id: 'push-a',
        from: q0,
        to: q0,
        input: 'a',
        push: const ['stack-token'],
        controlPoint: Vector2(30, -30),
      ),
      _transition(
        id: 'first-b',
        from: q0,
        to: q1,
        input: 'b',
        pop: 'stack-token',
      ),
      _transition(
        id: 'more-b',
        from: q1,
        to: q1,
        input: 'b',
        pop: 'stack-token',
        controlPoint: Vector2(30, -30),
      ),
      _transition(id: 'finish', from: q1, to: q2, pop: 'bottom'),
    },
    alphabet: const {'a', 'b'},
    initialState: q0,
    acceptingStates: {q2},
    created: DateTime.utc(2026, 8, 26),
    modified: DateTime.utc(2026, 8, 26),
    bounds: const math.Rectangle(0.0, 0.0, 400.0, 300.0),
    stackAlphabet: const {'bottom', 'stack-token'},
    initialStackSymbol: 'bottom',
    acceptanceMode: PDAAcceptanceMode.both,
  );
}

PDATransition _transition({
  required String id,
  required State from,
  required State to,
  String input = '',
  String pop = '',
  List<String> push = const [],
  Vector2? controlPoint,
}) =>
    PDATransition(
      id: id,
      fromState: from,
      toState: to,
      label: id,
      controlPoint: controlPoint,
      inputSymbol: input,
      popSymbol: pop,
      pushSymbol: push.join(),
      pushSymbols: push,
      isLambdaInput: input.isEmpty,
      isLambdaPop: pop.isEmpty,
      isLambdaPush: push.isEmpty,
    );

State _state(
  String id, {
  required double x,
  bool initial = false,
  bool accepting = false,
}) =>
    State(
      id: id,
      label: id,
      position: Vector2(x, 0),
      isInitial: initial,
      isAccepting: accepting,
    );
