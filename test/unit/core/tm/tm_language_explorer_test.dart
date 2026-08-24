import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/tm_language_explorer.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/core/models/tm.dart';
import 'package:turing_lab/core/models/tm_execution_analysis.dart';
import 'package:turing_lab/core/models/tm_language_explorer_models.dart';
import 'package:turing_lab/core/models/tm_transition.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  group('TMLanguageExplorer', () {
    test(
      'classifies accept, halt rejection, cycle, and bounded unknown',
      () async {
        final result = await TMLanguageExplorer.explore(
          _mixedMachine(),
          limits: const TMLanguageExplorerLimits(
            maxInputLength: 1,
            maxCandidates: 10,
            maxStepsPerInput: 3,
            maxConfigurationsPerInput: 20,
          ),
        );

        expect(result.isSuccess, isTrue, reason: result.error);
        final report = result.data!;
        expect(report.results.map((result) => result.input), [
          '',
          'a',
          'b',
          'c',
          'd',
        ]);
        expect(report.count(TMLanguageOutcome.accepted), 2);
        expect(report.count(TMLanguageOutcome.rejected), 1);
        expect(report.count(TMLanguageOutcome.provenCycle), 1);
        expect(report.count(TMLanguageOutcome.inconclusive), 1);
        expect(
          report.results
              .singleWhere((result) => result.input == 'd')
              .analysis
              .limit,
          TMExecutionLimit.steps,
        );
      },
    );

    test(
      'keeps standalone acceptor, rejector, cycle, and unknown distinct',
      () async {
        final cases = <(TM, TMLanguageOutcome)>[
          (_acceptor(), TMLanguageOutcome.accepted),
          (_totalRejector(), TMLanguageOutcome.rejected),
          (_cycleMachine(), TMLanguageOutcome.provenCycle),
          (_movingMachine(), TMLanguageOutcome.inconclusive),
        ];

        for (final (machine, expected) in cases) {
          final result = await TMLanguageExplorer.explore(
            machine,
            limits: const TMLanguageExplorerLimits(
              maxInputLength: 0,
              maxCandidates: 1,
              maxStepsPerInput: 4,
              maxConfigurationsPerInput: 20,
            ),
            includeTrace: true,
          );

          expect(result.isSuccess, isTrue, reason: result.error);
          expect(result.data!.results.single.outcome, expected);
          expect(result.data!.results.single.analysis.trace, isNotEmpty);
        }
      },
    );

    test(
      'uses deterministic shortlex order and enforces the candidate cap',
      () async {
        final machine = _totalRejector(alphabet: const {'b', 'a'});
        final progress = <TMLanguageExplorerProgress>[];

        final result = await TMLanguageExplorer.explore(
          machine,
          limits: const TMLanguageExplorerLimits(
            maxInputLength: 2,
            maxCandidates: 4,
          ),
          onProgress: progress.add,
        );

        expect(result.isSuccess, isTrue, reason: result.error);
        final report = result.data!;
        expect(report.requestedCandidates, BigInt.from(7));
        expect(report.plannedCandidates, 4);
        expect(report.truncatedByCandidateCap, isTrue);
        expect(report.isPartial, isTrue);
        expect(report.results.map((result) => result.input), [
          '',
          'a',
          'b',
          'aa',
        ]);
        expect(progress.first.evaluatedCandidates, 0);
        expect(progress.last.evaluatedCandidates, 4);
        expect(progress.last.fraction, 1);
      },
    );

    test('an empty alphabet still includes exactly the empty word', () async {
      final result = await TMLanguageExplorer.explore(
        _acceptor(),
        limits: const TMLanguageExplorerLimits(
          maxInputLength: 8,
          maxCandidates: 10,
        ),
      );

      expect(result.isSuccess, isTrue, reason: result.error);
      expect(result.data!.requestedCandidates, BigInt.one);
      expect(result.data!.results.map((result) => result.input), ['']);
      expect(result.data!.results.single.outcome, TMLanguageOutcome.accepted);
    });

    test('an NTM accepts when another branch is cyclic', () async {
      final result = await TMLanguageExplorer.explore(
        _acceptingAndCyclicNtm(),
        limits: const TMLanguageExplorerLimits(
          maxInputLength: 1,
          maxCandidates: 2,
        ),
      );

      expect(result.isSuccess, isTrue, reason: result.error);
      final word = result.data!.results.singleWhere(
        (result) => result.input == 'a',
      );
      expect(word.outcome, TMLanguageOutcome.accepted);
      expect(word.analysis.outcome, TMExecutionOutcome.accepted);
      expect(word.analysis.repeatedConfigurationsObserved, greaterThan(0));
    });

    test('cancellation returns the deterministic evaluated prefix', () async {
      final cancellation = TMLanguageExplorerCancellationToken();

      final result = await TMLanguageExplorer.explore(
        _totalRejector(alphabet: const {'a', 'b'}),
        limits: const TMLanguageExplorerLimits(
          maxInputLength: 3,
          maxCandidates: 15,
        ),
        cancellationToken: cancellation,
        onProgress: (progress) {
          if (progress.evaluatedCandidates == 2) cancellation.cancel();
        },
      );

      expect(result.isSuccess, isTrue, reason: result.error);
      final report = result.data!;
      expect(report.cancelled, isTrue);
      expect(report.isPartial, isTrue);
      expect(report.results.map((result) => result.input), ['', 'a']);
    });

    test(
      'timeout is inconclusive and never enters the rejected group',
      () async {
        final result = await TMLanguageExplorer.explore(
          _movingMachine(),
          limits: const TMLanguageExplorerLimits(
            maxInputLength: 0,
            maxCandidates: 1,
            maxStepsPerInput: 100000,
            maxConfigurationsPerInput: 100000,
            timeoutPerInput: Duration(microseconds: 1),
          ),
        );

        expect(result.isSuccess, isTrue, reason: result.error);
        final report = result.data!;
        expect(report.count(TMLanguageOutcome.rejected), 0);
        expect(report.count(TMLanguageOutcome.inconclusive), 1);
        expect(report.isPartial, isTrue);
        expect(report.results.single.analysis.limit, TMExecutionLimit.timeout);
      },
    );

    test(
      'rejects invalid explorer limits before evaluating candidates',
      () async {
        final result = await TMLanguageExplorer.explore(
          _acceptor(),
          limits: const TMLanguageExplorerLimits(maxCandidates: 0),
        );

        expect(result.isFailure, isTrue);
        expect(result.error, contains('Candidate cap'));
      },
    );
  });
}

TM _mixedMachine() {
  final q0 = _state('q0', initial: true);
  final qa = _state('qa', accepting: true);
  final qc = _state('qc');
  final qu = _state('qu');
  return _tm(
    states: {q0, qa, qc, qu},
    initial: q0,
    accepting: {qa},
    alphabet: const {'d', 'c', 'b', 'a'},
    tapeAlphabet: const {'a', 'b', 'c', 'd', 'B'},
    transitions: {
      _transition('empty', q0, qa, 'B', 'B', TapeDirection.stay),
      _transition('accept-a', q0, qa, 'a', 'a', TapeDirection.stay),
      _transition('enter-cycle', q0, qc, 'c', 'c', TapeDirection.stay),
      _transition('cycle', qc, qc, 'c', 'c', TapeDirection.stay),
      _transition('enter-unknown', q0, qu, 'd', 'd', TapeDirection.right),
      _transition('move', qu, qu, 'B', 'B', TapeDirection.right),
    },
  );
}

TM _acceptor() {
  final qa = _state('qa', initial: true, accepting: true);
  return _tm(states: {qa}, initial: qa, accepting: {qa});
}

TM _totalRejector({Set<String> alphabet = const {}}) {
  final q0 = _state('q0', initial: true);
  return _tm(
    states: {q0},
    initial: q0,
    alphabet: alphabet,
    tapeAlphabet: {...alphabet, 'B'},
  );
}

TM _cycleMachine() {
  final q0 = _state('q0', initial: true);
  return _tm(
    states: {q0},
    initial: q0,
    transitions: {_transition('cycle', q0, q0, 'B', 'B', TapeDirection.stay)},
  );
}

TM _movingMachine() {
  final q0 = _state('q0', initial: true);
  return _tm(
    states: {q0},
    initial: q0,
    transitions: {_transition('move', q0, q0, 'B', 'B', TapeDirection.right)},
  );
}

TM _acceptingAndCyclicNtm() {
  final q0 = _state('q0', initial: true);
  final qa = _state('qa', accepting: true);
  return _tm(
    states: {q0, qa},
    initial: q0,
    accepting: {qa},
    alphabet: const {'a'},
    tapeAlphabet: const {'a', 'B'},
    transitions: {
      _transition('a-cycle', q0, q0, 'a', 'a', TapeDirection.stay),
      _transition('z-accept', q0, qa, 'a', 'a', TapeDirection.stay),
    },
  );
}

State _state(String id, {bool initial = false, bool accepting = false}) {
  return State(
    id: id,
    label: id,
    position: Vector2.zero(),
    isInitial: initial,
    isAccepting: accepting,
  );
}

TMTransition _transition(
  String id,
  State from,
  State to,
  String read,
  String write,
  TapeDirection direction,
) {
  return TMTransition(
    id: id,
    fromState: from,
    toState: to,
    label: TMTransition.formatLabel(
      readSymbol: read,
      writeSymbol: write,
      direction: direction,
    ),
    readSymbol: read,
    writeSymbol: write,
    direction: direction,
  );
}

TM _tm({
  required Set<State> states,
  required State initial,
  Set<TMTransition> transitions = const {},
  Set<State> accepting = const {},
  Set<String> alphabet = const {},
  Set<String> tapeAlphabet = const {'B'},
}) {
  return TM(
    id: 'tm',
    name: 'TM',
    states: states,
    transitions: transitions,
    alphabet: alphabet,
    initialState: initial,
    acceptingStates: accepting,
    created: DateTime(2026),
    modified: DateTime(2026),
    bounds: const math.Rectangle(0, 0, 400, 300),
    tapeAlphabet: tapeAlphabet,
    blankSymbol: 'B',
    tapeCount: 1,
  );
}
