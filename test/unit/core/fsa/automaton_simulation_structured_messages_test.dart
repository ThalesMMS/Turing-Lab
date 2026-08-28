import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/automaton_simulation_messages.dart';
import 'package:turing_lab/core/algorithms/automaton_simulator.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/l10n/app_localizations_en.dart';
import 'package:turing_lab/l10n/app_localizations_pt.dart';
import 'package:turing_lab/l10n/app_localizations_structured_messages.dart';
import 'package:vector_math/vector_math_64.dart';

FSA _dfa() {
  final initial = State(
    id: 'q0-id',
    label: 'q0',
    position: Vector2.zero(),
    isInitial: true,
  );
  final accepting = State(
    id: 'q1-id',
    label: 'q1',
    position: Vector2(100, 0),
    isAccepting: true,
  );
  return FSA(
    id: 'structured-dfa',
    name: 'Structured DFA',
    states: {initial, accepting},
    transitions: {
      FSATransition(
        id: 'q0-q1-a',
        fromState: initial,
        toState: accepting,
        inputSymbols: {'a'},
        label: 'a',
      ),
    },
    alphabet: {'a'},
    initialState: initial,
    acceptingStates: {accepting},
    created: DateTime.utc(2026),
    modified: DateTime.utc(2026),
    bounds: const math.Rectangle(0, 0, 200, 100),
  );
}

void main() {
  test('DFA validation and rejection expose structured messages', () async {
    final invalid = await AutomatonSimulator.simulateDFA(_dfa(), 'b');
    expect(invalid.isFailure, isTrue);
    expect(invalid.structuredError, isNotNull);
    expect(
      invalid.structuredError!.stableCode,
      'automaton.simulation.invalid-input-symbol',
    );
    expect(invalid.structuredError!.arguments['symbol']!.value, 'b');

    final rejected = await AutomatonSimulator.simulateDFA(_dfa(), '');
    expect(rejected.isSuccess, isTrue);
    expect(rejected.data!.message, isNotNull);
    expect(
      rejected.data!.message!.stableCode,
      'automaton.simulation.rejected-no-accepting-state',
    );
    final accepted = await AutomatonSimulator.simulateDFA(_dfa(), 'a');
    expect(accepted.isSuccess, isTrue);
    final noTransition = await AutomatonSimulator.simulateDFA(_dfa(), 'aa');
    expect(noTransition.isSuccess, isTrue);
    expect(noTransition.data!.message, isNotNull);
    expect(
      noTransition.data!.message!.stableCode,
      'automaton.simulation.no-dfa-transition',
    );
    expect(
      AutomatonSimulationMessages.nfaNotAccepted().stableCode,
      'automaton.simulation.nfa-not-accepted',
    );
  });

  test('step explanations carry locale-neutral trace messages', () async {
    final result = await AutomatonSimulator.simulateDFA(
      _dfa(),
      'a',
      stepByStep: true,
    );
    expect(result.isSuccess, isTrue);
    final explanation = result.data!.steps.last.explanation;
    expect(explanation, isNotNull);
    expect(explanation!.usesLegacyText, isFalse);
    expect(
      explanation.titleMessage!.stableCode,
      'automaton.simulation.transition-applied-title',
    );
    expect(explanation.bulletMessages.map((message) => message.stableCode), [
      'automaton.simulation.read-symbol',
      'automaton.simulation.transition-detail',
    ]);
  });

  test('English and Brazilian Portuguese resolve the same message payload', () {
    final message = AutomatonSimulationMessages.noDfaTransition(
      state: 'q0',
      symbol: 'b',
    );
    final english = AppLocalizationsEn().resolveStructuredMessage(message);
    final portuguese = AppLocalizationsPt().resolveStructuredMessage(message);

    expect(english, 'No transition from state q0 on symbol b.');
    expect(portuguese, 'Não há transição do estado q0 com o símbolo b.');
  });
}
