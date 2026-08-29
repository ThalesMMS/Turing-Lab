import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/tm_execution_analyzer.dart';
import 'package:turing_lab/core/algorithms/tm_language_explorer.dart';
import 'package:turing_lab/core/algorithms/tm_messages.dart';
import 'package:turing_lab/core/algorithms/tm_reachability_analyzer.dart';
import 'package:turing_lab/core/algorithms/tm_simulator.dart';
import 'package:turing_lab/core/algorithms/tm_space_profiler.dart';
import 'package:turing_lab/core/algorithms/tm_time_profiler.dart';
import 'package:turing_lab/core/messages/structured_message.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/core/models/tm.dart';
import 'package:turing_lab/core/models/tm_execution_analysis.dart';
import 'package:turing_lab/core/models/tm_language_explorer_models.dart';
import 'package:turing_lab/core/models/tm_reachability_report.dart';
import 'package:turing_lab/core/models/tm_space_profile.dart';
import 'package:turing_lab/core/models/tm_time_profile.dart';
import 'package:turing_lab/core/models/tm_transition.dart';
import 'package:turing_lab/core/result.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  State testState(String id, {bool initial = false, bool accepting = false}) =>
      State(
        id: id,
        label: id,
        position: Vector2.zero(),
        isInitial: initial,
        isAccepting: accepting,
      );

  TMTransition testTransition(
    String id,
    State from,
    State to,
    String read,
    String write,
    TapeDirection direction,
  ) => TMTransition(
    id: id,
    fromState: from,
    toState: to,
    label: '$read/$write,${direction.symbol}',
    readSymbol: read,
    writeSymbol: write,
    direction: direction,
  );

  TM testMachine({
    required Set<State> states,
    required State initial,
    Set<State> accepting = const {},
    Set<String> alphabet = const {},
    Set<String> tapeAlphabet = const {'B'},
    Set<TMTransition> transitions = const {},
  }) => TM(
    id: 'structured-test-tm',
    name: 'Structured test TM',
    states: states,
    transitions: transitions,
    alphabet: alphabet,
    initialState: initial,
    acceptingStates: accepting,
    created: DateTime(2025),
    modified: DateTime(2025),
    bounds: const math.Rectangle(0, 0, 100, 100),
    tapeAlphabet: tapeAlphabet,
    blankSymbol: 'B',
  );

  TM acceptingMachine() {
    final q0 = testState('q0', initial: true);
    final qa = testState('qa', accepting: true);
    return testMachine(
      states: {q0, qa},
      initial: q0,
      accepting: {qa},
      alphabet: const {'a'},
      tapeAlphabet: const {'a', 'B'},
      transitions: {
        testTransition('accept', q0, qa, 'a', 'a', TapeDirection.stay),
      },
    );
  }

  TM conflictingMachine() {
    final q0 = testState('q0', initial: true);
    final qa = testState('qa', accepting: true);
    final qr = testState('qr');
    return testMachine(
      states: {q0, qa, qr},
      initial: q0,
      accepting: {qa},
      alphabet: const {'1'},
      tapeAlphabet: const {'1', 'B'},
      transitions: {
        testTransition('accept', q0, qa, '1', '1', TapeDirection.stay),
        testTransition('reject', q0, qr, '1', '1', TapeDirection.stay),
      },
    );
  }

  group('TM structured diagnostics', () {
    test(
      'factories expose stable identity, typed arguments, and JSON round trip',
      () {
        final message = TmSimulationMessages.nondeterministicConflict(
          count: 2,
          state: 'q0',
          symbol: '1',
        );

        expect(message.stableCode, 'tm.simulation.nondeterministic-conflict');
        expect(message.category, StructuredMessageCategory.simulation);
        expect(message.severity, StructuredMessageSeverity.error);
        expect(
          message.arguments['count']?.kind,
          StructuredMessageArgumentKind.count,
        );
        expect(message.arguments['count']?.value, 2);
        expect(message.arguments['count']?.role, 'transition-count');
        expect(
          message.arguments['state']?.kind,
          StructuredMessageArgumentKind.identifier,
        );
        expect(message.arguments['state']?.role, 'state-id');
        expect(
          message.arguments['symbol']?.kind,
          StructuredMessageArgumentKind.symbol,
        );
        expect(StructuredMessage.fromJson(message.toJson()), message);
      },
    );

    test('unresolved acceptance has a distinct fallback code', () {
      final message = TmSimulationMessages.acceptanceUnresolved();

      expect(message.stableCode, 'tm.simulation.acceptance-unresolved');
      expect(message.severity, StructuredMessageSeverity.warning);
    });

    test('simulator keeps legacy conflict prose beside structured payload', () {
      final result = TMSimulator.simulateDTM(conflictingMachine(), '1');

      expect(result, isA<Success<TMSimulationResult>>());
      final simulation = result.data!;
      expect(simulation.outcome, TMExecutionOutcome.haltedRejected);
      expect(simulation.errorMessage, contains('Nondeterministic conflict'));
      expect(
        simulation.structuredMessage?.stableCode,
        'tm.simulation.nondeterministic-conflict',
      );
      expect(simulation.structuredMessage?.arguments['count']?.value, 2);
    });

    test('step explanations use locale-neutral trace messages', () {
      final result = TMSimulator.simulate(
        acceptingMachine(),
        'a',
        stepByStep: true,
      );

      expect(result.isSuccess, isTrue, reason: result.error);
      final explanation = result.data!.steps[1].explanation!;
      expect(
        explanation.titleMessage?.stableCode,
        'tm.simulation.transition-title',
      );
      expect(explanation.bulletMessages.map((message) => message.stableCode), [
        'tm.simulation.read-symbol',
        'tm.simulation.applied-rule',
        'tm.simulation.wrote-symbol',
        'tm.simulation.moved-head',
      ]);
    });

    test('bounded analysis traces carry structured TM explanations', () async {
      final result = await TMExecutionAnalyzer.analyze(
        acceptingMachine(),
        'a',
        includeTrace: true,
      );

      expect(result.outcome, TMExecutionOutcome.accepted);
      final step = result.trace.firstWhere(
        (candidate) => candidate.usedTransition != null,
      );
      final explanation = step.explanation;
      expect(explanation, isNotNull);
      expect(
        explanation!.titleMessage?.stableCode,
        'tm.simulation.transition-title',
      );
      expect(explanation.bulletMessages.map((message) => message.stableCode), [
        'tm.simulation.read-symbol',
        'tm.simulation.applied-rule',
        'tm.simulation.wrote-symbol',
        'tm.simulation.moved-head',
      ]);
      expect(explanation.bulletMessages[0].arguments['position']?.value, 0);
      expect(
        StructuredMessage.fromJson(explanation.bulletMessages.first.toJson()),
        explanation.bulletMessages.first,
      );
    });

    test(
      'execution analyzer preserves invalid-input prose and payload',
      () async {
        final analysis = await TMExecutionAnalyzer.analyze(
          acceptingMachine(),
          'b',
        );

        expect(analysis.outcome, TMExecutionOutcome.invalidMachine);
        expect(analysis.message, contains('outside the TM alphabet'));
        expect(
          analysis.structuredMessage?.stableCode,
          'tm.execution.invalid-input-symbol',
        );
        expect(analysis.structuredMessage?.arguments['symbol']?.value, 'b');
      },
    );

    test('space profiler attaches payload to validation failures', () async {
      final result = await TMSpaceProfiler.profile(
        acceptingMachine(),
        limits: const TMSpaceProfileLimits(maxInputLength: -1),
      );

      expect(result, isA<Failure<TMSpaceProfileReport>>());
      expect(result.error, contains('Maximum input length'));
      expect(
        result.structuredError?.stableCode,
        'tm.space-profile.max-input-length-invalid',
      );
    });

    test(
      'time profiler exposes structured plan and report validation',
      () async {
        final machine = acceptingMachine();
        final plan = TMTimeProfiler.plan(
          machine,
          bounds: const TMTimeProfileBounds(maxLength: -1),
        );
        expect(plan.validationError, contains('Maximum input length'));
        expect(
          plan.validationMessage?.stableCode,
          'tm.time-profile.max-length-invalid',
        );

        final report = await TMTimeProfiler.profile(
          machine,
          bounds: const TMTimeProfileBounds(maxLength: -1),
        );
        expect(report.status, TMTimeProfileStatus.invalid);
        expect(report.message, plan.validationError);
        expect(
          report.structuredMessage?.stableCode,
          'tm.time-profile.max-length-invalid',
        );
      },
    );

    test(
      'reachability analyzer localizes invalid input through payload',
      () async {
        final report = await TMReachabilityAnalyzer.analyze(
          acceptingMachine(),
          inputs: const ['b'],
        );

        expect(report.status, TMReachabilityStatus.invalidMachine);
        expect(report.message, contains('outside the TM alphabet'));
        expect(
          report.structuredMessage?.stableCode,
          'tm.reachability.input-symbol-outside-alphabet',
        );
        expect(report.structuredMessage?.arguments['input']?.value, 'b');
        expect(report.structuredMessage?.arguments['symbol']?.value, 'b');
      },
    );

    test('language explorer exposes structured limit validation', () async {
      final result = await TMLanguageExplorer.explore(
        acceptingMachine(),
        limits: const TMLanguageExplorerLimits(maxCandidates: 0),
      );

      expect(result, isA<Failure<TMLanguageExplorerReport>>());
      expect(result.error, contains('Candidate cap'));
      expect(
        result.structuredError?.stableCode,
        'tm.language-explorer.candidate-cap-invalid',
      );
    });
  });
}
