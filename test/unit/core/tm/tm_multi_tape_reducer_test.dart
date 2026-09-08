import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/tm/tm_execution_analyzer.dart';
import 'package:turing_lab/core/algorithms/tm/tm_multi_tape_reducer.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/core/models/tm.dart';
import 'package:turing_lab/core/models/tm_acceptance.dart';
import 'package:turing_lab/core/models/tm_building_blocks.dart';
import 'package:turing_lab/core/models/tm_execution_analysis.dart';
import 'package:turing_lab/core/models/tm_transition.dart';
import 'package:vector_math/vector_math_64.dart';

State _state(String id, {bool initial = false, bool accepting = false}) =>
    State(
      id: id,
      label: id,
      position: Vector2.zero(),
      isInitial: initial,
      isAccepting: accepting,
    );

TMTransition _t(
  String id,
  State from,
  State to,
  List<String> reads,
  List<String> writes,
  List<TapeDirection> moves,
) => TMTransition(
  id: id,
  fromState: from,
  toState: to,
  label: TMTransition.formatVectorLabel(
    readSymbols: reads,
    writeSymbols: writes,
    directions: moves,
  ),
  controlPoint: identical(from, to) ? Vector2(40, -40) : Vector2.zero(),
  readSymbols: reads,
  writeSymbols: writes,
  directions: moves,
);

TM _tm({
  required Set<State> states,
  required Set<TMTransition> transitions,
  required Set<String> alphabet,
  required Set<String> tapeAlphabet,
  required int tapeCount,
  TMAcceptancePolicy acceptancePolicy = TMAcceptancePolicy.finalState,
  Map<String, TMBlockDefinition> blockDefinitions = const {},
}) => TM(
  id: 'source',
  name: 'Source',
  states: states,
  transitions: transitions,
  alphabet: alphabet,
  initialState: states.firstWhere((state) => state.isInitial),
  acceptingStates: states.where((state) => state.isAccepting).toSet(),
  created: DateTime.utc(2026),
  modified: DateTime.utc(2026),
  bounds: const math.Rectangle(0, 0, 400, 300),
  tapeAlphabet: tapeAlphabet,
  blankSymbol: 'B',
  tapeCount: tapeCount,
  acceptancePolicy: acceptancePolicy,
  blockDefinitions: blockDefinitions,
);

const L = TapeDirection.left;
const R = TapeDirection.right;
const S = TapeDirection.stay;

/// Deterministic 2-tape acceptor for a^n b^n (n ≥ 1): copies the a's to
/// tape 2, then walks tape 2 back while consuming b's.
TM _anbn() {
  final q0 = _state('q0', initial: true);
  final q1 = _state('q1');
  final q2 = _state('q2');
  final qa = _state('qa', accepting: true);
  return _tm(
    states: {q0, q1, q2, qa},
    tapeCount: 2,
    alphabet: {'a', 'b'},
    tapeAlphabet: {'a', 'b', 'X', 'B'},
    transitions: {
      _t('copy', q0, q0, ['a', 'B'], ['a', 'X'], [R, R]),
      _t('turn', q0, q1, ['b', 'B'], ['b', 'B'], [S, L]),
      _t('match', q1, q1, ['b', 'X'], ['b', 'X'], [R, L]),
      _t('done', q1, q2, ['B', 'B'], ['B', 'B'], [S, S]),
      _t('accept', q2, qa, ['B', 'B'], ['B', 'B'], [S, S]),
    },
  );
}

/// Nondeterministic 3-tape machine: guesses whether to mark the first symbol
/// on tape 2 or tape 3, and accepts only through the tape-3 branch after
/// moving tape 1 left and right.
TM _guessing() {
  final q0 = _state('q0', initial: true);
  final q1 = _state('q1');
  final q2 = _state('q2');
  final qa = _state('qa', accepting: true);
  return _tm(
    states: {q0, q1, q2, qa},
    tapeCount: 3,
    alphabet: {'a'},
    tapeAlphabet: {'a', 'B'},
    transitions: {
      _t('guess2', q0, q1, ['a', 'B', 'B'], ['a', 'a', 'B'], [R, S, S]),
      _t('guess3', q0, q2, ['a', 'B', 'B'], ['a', 'B', 'a'], [R, S, S]),
      _t('dead', q1, q1, ['B', 'a', 'B'], ['B', 'a', 'B'], [S, S, S]),
      _t('back', q2, q2, ['a', 'B', 'a'], ['a', 'B', 'a'], [R, S, S]),
      _t('win', q2, qa, ['B', 'B', 'a'], ['B', 'B', 'a'], [L, S, L]),
    },
  );
}

Future<bool?> _accepts(TM tm, String input) async {
  final analysis = await TMExecutionAnalyzer.analyzeTokens(
    tm,
    input.split('').where((c) => c.isNotEmpty).toList(),
    maxSteps: 5000,
    maxConfigurations: 20000,
    includeTrace: false,
  );
  return switch (analysis.outcome) {
    TMExecutionOutcome.accepted => true,
    TMExecutionOutcome.haltedRejected ||
    TMExecutionOutcome.provenCycle => false,
    _ => null,
  };
}

void main() {
  group('TMMultiTapeReducer', () {
    test(
      'reduces a deterministic 2-tape acceptor and preserves the language',
      () async {
        final tm = _anbn();
        final report = TMMultiTapeReducer.reduce(tm, sourceRevision: 3);

        expect(report.outcome, TMMultiTapeReductionOutcome.completed);
        expect(report.sourceTmId, 'source');
        expect(report.sourceRevision, 3);
        expect(report.tapeCount, 2);
        final reduced = report.machine!;
        expect(reduced.tapeCount, 1);
        expect(reduced.validate(), isEmpty);
        expect(reduced.alphabet, {'a', 'b'});
        expect(reduced.blankSymbol, '⟨B,B|00⟩');
        expect(reduced.tapeAlphabet, containsAll({'a', 'b', '⟨a,X|11⟩'}));
        expect(report.cells.length, 4 * 4 * 4);
        expect(report.cells['⟨a,X|10⟩']!.symbols, ['a', 'X']);
        expect(report.cells['⟨a,X|10⟩']!.heads, [true, false]);

        for (final (input, expected) in [
          ('ab', true),
          ('aabb', true),
          ('aaabbb', true),
          ('', false),
          ('a', false),
          ('b', false),
          ('aab', false),
          ('abb', false),
          ('ba', false),
        ]) {
          expect(await _accepts(reduced, input), expected, reason: input);
        }
      },
    );

    test('keeps nondeterministic branching across three tapes', () async {
      final report = TMMultiTapeReducer.reduce(_guessing(), sourceRevision: 1);
      expect(report.outcome, TMMultiTapeReductionOutcome.completed);
      final reduced = report.machine!;
      expect(await _accepts(reduced, 'a'), isTrue);
      expect(await _accepts(reduced, 'aaa'), isTrue);
      expect(await _accepts(reduced, ''), isFalse);
      // Two source transitions share (q0, [a,B,B]); the read state fans out.
      final fanOut = reduced.tmTransitions.where(
        (transition) =>
            report.transitionProvenance[transition.id]!.sourceTransitionId ==
                'guess2' ||
            report.transitionProvenance[transition.id]!.sourceTransitionId ==
                'guess3',
      );
      expect(fanOut, isNotEmpty);
    });

    test(
      'provenance links every reduced state and transition to its source',
      () {
        final tm = _anbn();
        final report = TMMultiTapeReducer.reduce(tm, sourceRevision: 1);
        final reduced = report.machine!;
        expect(report.stateProvenance.keys, reduced.states.map((s) => s.id));
        expect(
          report.transitionProvenance.keys,
          reduced.transitions.map((t) => t.id),
        );
        final phases = report.stateProvenance.values
            .map((p) => p.phase)
            .toSet();
        expect(phases, containsAll(TMMultiTapePhase.values));
        final applied = report.transitionProvenance.values.where(
          (p) => p.sourceTransitionId == 'copy' && p.appliedTapes.isNotEmpty,
        );
        expect(applied, isNotEmpty);
        expect(
          report.stateProvenance.values
              .where((p) => p.phase == TMMultiTapePhase.read)
              .map((p) => p.sourceStateId)
              .toSet(),
          containsAll({'q0', 'q1', 'q2', 'qa'}),
        );
        final accepting = reduced.acceptingStates.map(
          (state) => report.stateProvenance[state.id]!,
        );
        expect(accepting, isNotEmpty);
        expect(accepting.every((p) => p.sourceStateId == 'qa'), isTrue);
        final json = report.toStructuredJson();
        expect(json['schema'], TMMultiTapeReductionReport.schema);
        expect((json['counts']! as Map)['states'], reduced.states.length);
      },
    );

    test(
      'differential evidence matches the source on sampled inputs',
      () async {
        final tm = _anbn();
        final report = TMMultiTapeReducer.reduce(tm, sourceRevision: 1);
        final evidence = await TMMultiTapeReductionChecker.check(tm, report, [
          for (final word in ['', 'a', 'ab', 'aabb', 'aab', 'ba', 'aaabbb'])
            word.split('').where((c) => c.isNotEmpty).toList(),
          ['c'],
        ]);
        expect(evidence.isProof, isFalse);
        expect(evidence.hasMismatch, isFalse);
        expect(
          evidence.countOf(
            TMMultiTapeReductionSampleOutcome.matchingAcceptance,
          ),
          3,
        );
        expect(
          evidence.countOf(TMMultiTapeReductionSampleOutcome.matchingRejection),
          4,
        );
        expect(evidence.countOf(TMMultiTapeReductionSampleOutcome.invalid), 1);
      },
    );

    test('bounded runs are reported as unknown, never as rejection', () async {
      final tm = _anbn();
      final report = TMMultiTapeReducer.reduce(tm, sourceRevision: 1);
      final evidence = await TMMultiTapeReductionChecker.check(
        tm,
        report,
        [
          ['a', 'a', 'b', 'b'],
        ],
        sourceMaxSteps: 2,
        reducedStepFactor: 1,
      );
      expect(
        evidence.samples.single.outcome,
        TMMultiTapeReductionSampleOutcome.boundedUnknown,
      );
      expect(evidence.hasMismatch, isFalse);
    });

    test('composite cells stay distinct for symbols with separators', () {
      expect(
        TMMultiTapeCell.encode(['a,b', 'c'], [true, false]),
        isNot(TMMultiTapeCell.encode(['a', 'b,c'], [true, false])),
      );
      expect(
        TMMultiTapeCell.encode(['x|1', 'B'], [false, false]),
        isNot(TMMultiTapeCell.encode(['x', '1|B'], [false, false])),
      );
      final q0 = _state('q0', initial: true);
      final qa = _state('qa', accepting: true);
      final report = TMMultiTapeReducer.reduce(
        _tm(
          states: {q0, qa},
          tapeCount: 2,
          alphabet: {'ab', 'a'},
          tapeAlphabet: {'ab', 'a', 'b', 'B'},
          transitions: {
            _t('go', q0, qa, ['ab', 'B'], ['a', 'b'], [R, R]),
          },
        ),
        sourceRevision: 1,
      );
      expect(report.outcome, TMMultiTapeReductionOutcome.completed);
      // 4 symbols per track squared, times 4 head combinations, all distinct.
      expect(report.cells.length, 4 * 4 * 4);
      expect(report.machine!.tapeAlphabet.length, 2 + 4 * 4 * 4);
    });

    test('single-tape machines are not applicable', () {
      final q0 = _state('q0', initial: true, accepting: true);
      final report = TMMultiTapeReducer.reduce(
        _tm(
          states: {q0},
          transitions: {},
          alphabet: {'a'},
          tapeAlphabet: {'a', 'B'},
          tapeCount: 1,
        ),
        sourceRevision: 1,
      );
      expect(report.outcome, TMMultiTapeReductionOutcome.notApplicable);
      expect(report.machine, isNull);
      expect(
        report.diagnostics.single.code,
        TMMultiTapeReductionDiagnosticCode.alreadySingleTape,
      );
    });

    test('building blocks and halting acceptance stay unsupported', () {
      final tm = _anbn();
      final withPolicy = tm.copyWith(
        acceptancePolicy: TMAcceptancePolicy.halting,
      );
      final report = TMMultiTapeReducer.reduce(withPolicy, sourceRevision: 1);
      expect(report.outcome, TMMultiTapeReductionOutcome.unsupportedMachine);
      expect(
        report.diagnostics.map((d) => d.code),
        contains(
          TMMultiTapeReductionDiagnosticCode.acceptancePolicyUnsupported,
        ),
      );
      expect(
        report.diagnostics.first.structuredMessage!.namespace,
        'tm.multi-tape-reduction',
      );
    });

    test('an oversized tape count fails the symbol budget instead of '
        'overflowing', () {
      const tapeCount = 70;
      final q0 = _state('q0', initial: true);
      final qa = _state('qa', accepting: true);
      final vector = List.filled(tapeCount, 'B');
      final report = TMMultiTapeReducer.reduce(
        _tm(
          states: {q0, qa},
          tapeCount: tapeCount,
          alphabet: {'a'},
          tapeAlphabet: {'a', 'B'},
          transitions: {
            _t('halt', q0, qa, vector, vector, List.filled(tapeCount, S)),
          },
        ),
        sourceRevision: 1,
      );
      expect(report.outcome, TMMultiTapeReductionOutcome.budgetExceeded);
      expect(
        report.diagnostics.single.code,
        TMMultiTapeReductionDiagnosticCode.tapeSymbolBudget,
      );
      expect(report.diagnostics.single.count, greaterThan(0));
    });

    test('budgets fail closed with structured counts', () {
      final tm = _anbn();
      final symbols = TMMultiTapeReducer.reduce(
        tm,
        sourceRevision: 1,
        limits: const TMMultiTapeReductionLimits(maxTapeSymbols: 10),
      );
      expect(symbols.outcome, TMMultiTapeReductionOutcome.budgetExceeded);
      expect(
        symbols.diagnostics.single.code,
        TMMultiTapeReductionDiagnosticCode.tapeSymbolBudget,
      );
      expect(symbols.diagnostics.single.count, 64);
      expect(symbols.diagnostics.single.limit, 10);

      final states = TMMultiTapeReducer.reduce(
        tm,
        sourceRevision: 1,
        limits: const TMMultiTapeReductionLimits(maxStates: 5),
      );
      expect(states.outcome, TMMultiTapeReductionOutcome.budgetExceeded);
      expect(
        states.diagnostics.single.code,
        TMMultiTapeReductionDiagnosticCode.stateBudget,
      );

      final transitions = TMMultiTapeReducer.reduce(
        tm,
        sourceRevision: 1,
        limits: const TMMultiTapeReductionLimits(maxTransitions: 50),
      );
      expect(transitions.outcome, TMMultiTapeReductionOutcome.budgetExceeded);
      expect(
        transitions.diagnostics.single.code,
        TMMultiTapeReductionDiagnosticCode.transitionBudget,
      );
      expect(transitions.diagnostics.single.limit, 50);
    });
  });
}
