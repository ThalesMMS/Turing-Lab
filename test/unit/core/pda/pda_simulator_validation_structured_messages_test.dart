import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/pda_simulation_messages.dart';
import 'package:turing_lab/core/algorithms/pda_simulator.dart';
import 'package:turing_lab/core/models/pda.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/l10n/app_localizations_en.dart';
import 'package:turing_lab/l10n/app_localizations_pt.dart';
import 'package:turing_lab/l10n/app_localizations_structured_messages.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  final initial = State(
    id: 'q0',
    label: 'q0',
    position: Vector2.zero(),
    isInitial: true,
  );
  final accepting = State(
    id: 'q1',
    label: 'q1',
    position: Vector2(100, 0),
    isAccepting: true,
  );

  PDA pda({
    Set<State>? states,
    Object? initialState = _unset,
    Set<State>? acceptingStates,
  }) => PDA(
    id: 'validation-test',
    name: 'Validation test PDA',
    states: states ?? {initial},
    transitions: const {},
    alphabet: const {},
    initialState: identical(initialState, _unset)
        ? initial
        : initialState as State?,
    acceptingStates: acceptingStates ?? const {},
    stackAlphabet: const {'Z'},
    initialStackSymbol: 'Z',
    created: DateTime.utc(2026),
    modified: DateTime.utc(2026),
    bounds: const math.Rectangle(0, 0, 200, 100),
  );

  test('validation messages expose stable PDA simulation identities', () {
    expect(
      PDASimulationMessages.emptyStateSet().stableCode,
      'pda.simulation.empty-state-set',
    );
    expect(
      PDASimulationMessages.missingInitialState().stableCode,
      'pda.simulation.missing-initial-state',
    );
    expect(
      PDASimulationMessages.initialStateOutsideSet().stableCode,
      'pda.simulation.initial-state-outside-set',
    );
    expect(
      PDASimulationMessages.acceptingStateOutsideSet().stableCode,
      'pda.simulation.accepting-state-outside-set',
    );
  });

  test('simulateNPDA preserves the structured validation contract', () {
    final cases = <(PDA, String)>[
      (pda(states: const {}), 'pda.simulation.empty-state-set'),
      (pda(initialState: null), 'pda.simulation.missing-initial-state'),
      (
        pda(states: {accepting}, initialState: initial),
        'pda.simulation.initial-state-outside-set',
      ),
      (
        pda(acceptingStates: {accepting}),
        'pda.simulation.accepting-state-outside-set',
      ),
    ];

    for (final entry in cases) {
      final result = PDASimulator.simulateNPDA(entry.$1, '');
      expect(result.isFailure, isTrue);
      expect(result.error, entry.$2);
      expect(result.structuredError?.stableCode, entry.$2);
    }
  });

  test(
    'cooperative simulation and analysis preserve validation messages',
    () async {
      final invalid = pda(states: const {});

      final cooperative = await PDASimulator.simulateCooperative(invalid, '');
      expect(
        cooperative.structuredError?.stableCode,
        'pda.simulation.empty-state-set',
      );

      final analysis = PDASimulator.analyzePDA(invalid);
      expect(
        analysis.structuredError?.stableCode,
        'pda.simulation.empty-state-set',
      );

      final accepts = PDASimulator.accepts(invalid, '');
      expect(
        accepts.structuredError?.stableCode,
        'pda.simulation.empty-state-set',
      );

      final rejects = PDASimulator.rejects(invalid, '');
      expect(
        rejects.structuredError?.stableCode,
        'pda.simulation.empty-state-set',
      );
    },
  );

  test('PDA validation messages resolve in English and Portuguese', () {
    final messages = [
      (
        PDASimulationMessages.emptyStateSet(),
        'A PDA must have at least one state.',
        'Um AP deve ter pelo menos um estado.',
      ),
      (
        PDASimulationMessages.missingInitialState(),
        'A PDA must have an initial state.',
        'Um AP deve ter um estado inicial.',
      ),
      (
        PDASimulationMessages.initialStateOutsideSet(),
        'The initial state must belong to the PDA state set.',
        'O estado inicial deve pertencer ao conjunto de estados do AP.',
      ),
      (
        PDASimulationMessages.acceptingStateOutsideSet(),
        'Every accepting state must belong to the PDA state set.',
        'Todo estado de aceitação deve pertencer ao conjunto de estados do AP.',
      ),
    ];

    final en = AppLocalizationsEn();
    final pt = AppLocalizationsPt();
    for (final (message, expectedEnglish, expectedPortuguese) in messages) {
      expect(en.resolveStructuredMessage(message), expectedEnglish);
      expect(pt.resolveStructuredMessage(message), expectedPortuguese);
    }
  });
}

const Object _unset = Object();
