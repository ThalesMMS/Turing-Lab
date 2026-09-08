import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/tm/tm_to_grammar_messages.dart';
import 'package:turing_lab/core/algorithms/tm_to_unrestricted_grammar/tm_to_unrestricted_grammar.dart';
import 'package:turing_lab/core/grammar/phrase_structure/phrase_structure.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/core/models/tm.dart';
import 'package:turing_lab/core/models/tm_acceptance.dart';
import 'package:turing_lab/core/models/tm_transition.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  group('TM to unrestricted grammar', () {
    test('serializes structured diagnostic messages', () {
      final message = TmToGrammarMessages.fromDiagnostic(
        code: TMToGrammarDiagnosticCode.missingInitialState,
      );
      final report = TMToGrammarConstructionReport(
        sourceTmId: 'tm',
        sourceRevision: 1,
        outcome: TMToGrammarOutcome.invalidMachine,
        assumptions: const [],
        diagnostics: [
          TMToGrammarDiagnostic(
            code: TMToGrammarDiagnosticCode.missingInitialState,
            severity: TMToGrammarDiagnosticSeverity.error,
            structuredMessage: message,
          ),
        ],
      );

      final diagnostics =
          report.toStructuredJson()['diagnostics']! as List<Object?>;
      final diagnostic = diagnostics.single! as Map<String, Object?>;

      expect(diagnostic['structuredMessage'], message.toJson());
    });

    test(
      'builds a valid token-preserving grammar with complete provenance',
      () {
        final tm = _immediateAcceptor(alphabet: {'token', 'Ω'});
        final sourceSnapshot = tm.toJson();

        final report = TMToGrammarConverter.build(tm, sourceRevision: 7);

        expect(report.outcome, TMToGrammarOutcome.completed);
        expect(report.sourceRevision, 7);
        expect(report.grammar, isNotNull);
        expect(
          PhraseGrammarClassifier.classify(report.grammar!).isValid,
          isTrue,
        );
        expect(report.grammar!.terminals.map((symbol) => symbol.value), {
          'token',
          'Ω',
        });
        expect(
          report.productionProvenance.map((item) => item.productionId).toSet(),
          report.grammar!.productions.map((item) => item.id).toSet(),
        );
        expect(
          report.symbolDescriptions.values,
          contains('cell(output=token,tape=token)'),
        );
        expect(tm.tapeAlphabet, {'token', 'Ω', 'B'});
        expect(tm.toJson(), sourceSnapshot);
        expect(
          report.toStructuredJson()['schema'],
          'turing-lab.tm-to-unrestricted-grammar-report.v1',
        );
        expect(
          (report.toStructuredJson()['counts']!
              as Map<String, Object?>)['productions'],
          report.grammar!.productions.length,
        );
      },
    );

    test(
      'emits distinct right, left, stay, blank, and acceptance families',
      () {
        final q0 = _state('q0', initial: true);
        final q1 = _state('q1');
        final q2 = _state('q2');
        final qa = _state('qa', accepting: true);
        final tm = _tm(
          states: {q0, q1, q2, qa},
          initial: q0,
          accepting: {qa},
          alphabet: {'a'},
          tapeAlphabet: {'a', 'B'},
          transitions: {
            _transition('right', q0, q1, 'a', 'a', TapeDirection.right),
            _transition('left', q1, q2, 'B', 'B', TapeDirection.left),
            _transition('stay', q2, qa, 'a', 'a', TapeDirection.stay),
          },
        );

        final report = TMToGrammarConverter.build(tm, sourceRevision: 1);
        final families = report.productionProvenance.map((item) => item.family);

        expect(report.outcome, TMToGrammarOutcome.completed);
        expect(
          families,
          containsAll({
            TMToGrammarProductionFamily.moveRight,
            TMToGrammarProductionFamily.moveLeft,
            TMToGrammarProductionFamily.stay,
            TMToGrammarProductionFamily.boundaryBlank,
            TMToGrammarProductionFamily.acceptingState,
            TMToGrammarProductionFamily.cleanupLeft,
            TMToGrammarProductionFamily.cleanupRight,
          }),
        );
        for (final transition in tm.tmTransitions) {
          expect(
            report.productionProvenance.any(
              (item) => item.sources.any(
                (source) => source.transitionId == transition.id,
              ),
            ),
            isTrue,
            reason: transition.id,
          );
        }
      },
    );

    test('bounded differential evidence finds immediate acceptance', () async {
      final tm = _immediateAcceptor(alphabet: {'a'});
      final report = TMToGrammarConverter.build(tm, sourceRevision: 1);

      final evidence = await TMToGrammarDifferentialChecker.check(
        tm,
        report,
        const [
          [],
          ['a'],
        ],
        grammarMaxExpandedForms: 10000,
        grammarMaxVisitedForms: 20000,
      );

      expect(evidence.isProof, isFalse);
      expect(evidence.hasMismatch, isFalse);
      expect(
        evidence.samples.map((sample) => sample.outcome),
        everyElement(TMToGrammarSampleOutcome.matchingAcceptance),
      );
    });

    test('bounded differential evidence preserves token boundaries', () async {
      final tm = _immediateAcceptor(alphabet: {'token', 'Ω'});
      final report = TMToGrammarConverter.build(tm, sourceRevision: 1);

      final evidence = await TMToGrammarDifferentialChecker.check(
        tm,
        report,
        const [
          ['token'],
          ['Ω'],
        ],
        grammarMaxExpandedForms: 10000,
        grammarMaxVisitedForms: 20000,
      );

      expect(evidence.hasMismatch, isFalse);
      expect(
        evidence.samples.map((sample) => sample.outcome),
        everyElement(TMToGrammarSampleOutcome.matchingAcceptance),
      );
    });

    test(
      'keeps halted TM rejection distinct from bounded grammar search',
      () async {
        final q0 = _state('q0', initial: true);
        final tm = _tm(states: {q0}, initial: q0);
        final report = TMToGrammarConverter.build(tm, sourceRevision: 1);

        final evidence = await TMToGrammarDifferentialChecker.check(
          tm,
          report,
          const [[]],
          grammarMaxExpandedForms: 5,
          grammarMaxVisitedForms: 10,
        );

        expect(evidence.samples.single.tmAccepted, isFalse);
        expect(
          evidence.samples.single.outcome,
          TMToGrammarSampleOutcome.boundedUnknown,
        );
      },
    );

    test('reports a looping TM sample as bounded unknown', () async {
      final q0 = _state('q0', initial: true);
      final tm = _tm(
        states: {q0},
        initial: q0,
        transitions: {
          _transition('loop', q0, q0, 'B', 'B', TapeDirection.right),
        },
      );
      final report = TMToGrammarConverter.build(tm, sourceRevision: 1);

      final evidence = await TMToGrammarDifferentialChecker.check(
        tm,
        report,
        const [[]],
        tmMaxSteps: 3,
      );

      expect(
        evidence.samples.single.outcome,
        TMToGrammarSampleOutcome.boundedUnknown,
      );
      expect(evidence.samples.single.detailCode, 'tm-boundedUnknown');
    });

    test('tracks erasure, blank traversal, writes, and return movement', () {
      final q0 = _state('q0', initial: true);
      final q1 = _state('q1');
      final q2 = _state('q2');
      final qa = _state('qa', accepting: true);
      final tm = _tm(
        states: {q0, q1, q2, qa},
        initial: q0,
        accepting: {qa},
        alphabet: {'a'},
        tapeAlphabet: {'a', 'x', 'B'},
        transitions: {
          _transition('erase', q0, q1, 'a', 'B', TapeDirection.right),
          _transition('write-blank', q1, q2, 'B', 'x', TapeDirection.left),
          _transition('accept', q2, qa, 'B', 'B', TapeDirection.stay),
        },
      );

      final report = TMToGrammarConverter.build(tm, sourceRevision: 1);
      final sources = report.productionProvenance
          .expand((provenance) => provenance.sources)
          .toList();

      expect(report.outcome, TMToGrammarOutcome.completed);
      expect(
        sources.any(
          (source) =>
              source.transitionId == 'erase' &&
              source.readSymbol == 'a' &&
              source.writeSymbol == 'B' &&
              source.direction == TapeDirection.right,
        ),
        isTrue,
      );
      expect(
        sources.any(
          (source) =>
              source.transitionId == 'write-blank' &&
              source.readSymbol == 'B' &&
              source.writeSymbol == 'x' &&
              source.direction == TapeDirection.left,
        ),
        isTrue,
      );
    });

    test(
      'preserves nondeterministic alternatives and merges exact duplicates',
      () {
        final q0 = _state('q0', initial: true);
        final qa = _state('qa', accepting: true);
        final duplicateA = _transition(
          'a',
          q0,
          qa,
          'B',
          'B',
          TapeDirection.stay,
        );
        final duplicateB = _transition(
          'b',
          q0,
          qa,
          'B',
          'B',
          TapeDirection.stay,
        );
        final tm = _tm(
          states: {q0, qa},
          initial: q0,
          accepting: {qa},
          transitions: {duplicateA, duplicateB},
        );

        final report = TMToGrammarConverter.build(tm, sourceRevision: 1);
        final merged = report.productionProvenance.where(
          (item) =>
              item.family == TMToGrammarProductionFamily.stay &&
              item.sources
                  .map((source) => source.transitionId)
                  .toSet()
                  .containsAll({'a', 'b'}),
        );

        expect(report.outcome, TMToGrammarOutcome.completed);
        expect(tm.isNondeterministic, isTrue);
        expect(merged, isNotEmpty);
        expect(
          PhraseGrammarClassifier.classify(report.grammar!).isValid,
          isTrue,
        );
      },
    );

    test('reports unsupported multi-tape and building-block machines', () {
      final multi = _immediateAcceptor(alphabet: {'a'}).copyWith(tapeCount: 2);
      final result = TMToGrammarConverter.build(
        multi,
        sourceRevision: 1,
        reduceMultiTape: false,
      );

      expect(result.outcome, TMToGrammarOutcome.unsupportedMachine);
      expect(
        result.diagnostics.map((item) => item.code),
        contains(TMToGrammarDiagnosticCode.multiTapeUnsupported),
      );
      expect(result.grammar, isNull);
    });

    test('preserves reduction-like text inside the original machine name', () {
      const name = 'Source (single-tape reduction) copy';
      final multiTape = _twoTapeCopier().copyWith(name: name);
      final singleTape = _tm(
        states: {_state('q0', initial: true)},
        initial: _state('q0', initial: true),
      ).copyWith(name: name);

      for (final tm in [singleTape, multiTape]) {
        final report = TMToGrammarConverter.build(tm, sourceRevision: 5);
        expect(report.outcome, TMToGrammarOutcome.completed);
        expect(report.grammar!.name, '$name — unrestricted grammar');
      }
    });

    test('reduces a multi-tape machine before building the grammar', () async {
      final tm = _twoTapeCopier();
      final report = TMToGrammarConverter.build(tm, sourceRevision: 5);

      expect(report.outcome, TMToGrammarOutcome.completed);
      expect(report.sourceTmId, tm.id);
      expect(report.sourceRevision, 5);
      expect(report.reduction, isNotNull);
      expect(report.reduction!.tapeCount, 2);
      expect(
        report.assumptions,
        contains(TMToGrammarAssumption.multiTapeReducedToSingleTape),
      );
      expect(report.grammar!.name, '${tm.name} — unrestricted grammar');
      expect(PhraseGrammarClassifier.classify(report.grammar!).isValid, isTrue);
      expect(
        report.toStructuredJson()['reduction'],
        isA<Map<String, Object?>>(),
      );

      // Provenance maps back to the original states and transitions.
      final originalIds = {
        for (final provenance in report.productionProvenance)
          for (final source in report.sourceReferencesForOriginal(provenance))
            source.transitionId ?? source.stateId,
      }..remove(null);
      expect(originalIds, containsAll({'first', 'more', 'done', 'q0', 'qa'}));
      expect(
        originalIds.every(
          (id) =>
              tm.states.any((state) => state.id == id) ||
              tm.tmTransitions.any((transition) => transition.id == id),
        ),
        isTrue,
      );

      // Explicit, small limits: the multi-tape source is decided by the
      // multi-tape analyzer, and a derivation search that stops at its
      // bounds is reported as unknown, never as a rejection or a proof.
      final evidence = await TMToGrammarDifferentialChecker.check(
        tm,
        report,
        [
          for (final word in ['', 'a'])
            word.split('').where((c) => c.isNotEmpty).toList(),
        ],
        tmMaxSteps: 50,
        grammarMaxExpandedForms: 20000,
        grammarMaxVisitedForms: 40000,
        grammarMaxFrontierSize: 10000,
        grammarMaxSymbolCount: 48,
        perSampleTimeout: const Duration(seconds: 2),
      );
      expect(evidence.isProof, isFalse);
      expect(evidence.hasMismatch, isFalse);
      expect(evidence.samples, hasLength(2));
      for (final sample in evidence.samples) {
        expect(sample.tmAccepted, sample.inputTokens.isNotEmpty);
        expect(
          sample.outcome,
          isIn({
            TMToGrammarSampleOutcome.matchingAcceptance,
            TMToGrammarSampleOutcome.matchingRejection,
            TMToGrammarSampleOutcome.boundedUnknown,
          }),
        );
      }
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('multi-tape reduction budgets surface as construction limits', () {
      final report = TMToGrammarConverter.build(
        _twoTapeCopier(),
        sourceRevision: 1,
        reductionLimits: const TMMultiTapeReductionLimits(maxStates: 3),
      );
      expect(report.outcome, TMToGrammarOutcome.constructionLimit);
      expect(report.grammar, isNull);
      expect(report.reduction, isNotNull);
      final limit = report.diagnostics.singleWhere(
        (d) => d.code == TMToGrammarDiagnosticCode.constructionLimit,
      );
      expect(limit.detailCode, 'multi-tape-reduction-state-budget');
      expect(
        limit.structuredMessage?.stableCode,
        'tm.multi-tape-reduction.state-budget',
      );
    });

    test('multi-tape machines with halting acceptance stay unsupported', () {
      final report = TMToGrammarConverter.build(
        _twoTapeCopier().copyWith(acceptancePolicy: TMAcceptancePolicy.halting),
        sourceRevision: 1,
      );
      expect(report.outcome, TMToGrammarOutcome.unsupportedMachine);
      expect(
        report.diagnostics
            .map((d) => d.structuredMessage?.stableCode)
            .whereType<String>(),
        contains('tm.multi-tape-reduction.acceptance-policy-unsupported'),
      );
    });

    test('reports malformed symbols and a missing initial state', () {
      final invalid = _immediateAcceptor(alphabet: {'a'}).copyWith(
        initialState: null,
        alphabet: const {'a', 'B', 'outside'},
        tapeAlphabet: const {'a', 'B'},
      );

      final result = TMToGrammarConverter.build(invalid, sourceRevision: 1);
      final codes = result.diagnostics.map((item) => item.code);

      expect(result.outcome, TMToGrammarOutcome.invalidMachine);
      expect(result.grammar, isNull);
      expect(codes, contains(TMToGrammarDiagnosticCode.missingInitialState));
      expect(codes, contains(TMToGrammarDiagnosticCode.blankInInputAlphabet));
      expect(
        codes,
        contains(TMToGrammarDiagnosticCode.inputOutsideTapeAlphabet),
      );
    });

    test('preserves and reports unreachable source states', () {
      final source = _immediateAcceptor(alphabet: {'a'});
      final unreachable = _state('unreachable');
      final tm = source.copyWith(states: {...source.states, unreachable});

      final report = TMToGrammarConverter.build(tm, sourceRevision: 1);

      expect(report.outcome, TMToGrammarOutcome.completed);
      expect(
        report.diagnostics.where(
          (item) =>
              item.code == TMToGrammarDiagnosticCode.unreachableState &&
              item.stateId == unreachable.id,
        ),
        hasLength(1),
      );
    });

    test(
      'keeps no-final-state machines valid with an empty-language warning',
      () {
        final q0 = _state('q0', initial: true);
        final tm = _tm(states: {q0}, initial: q0);

        final report = TMToGrammarConverter.build(tm, sourceRevision: 1);

        expect(report.outcome, TMToGrammarOutcome.completed);
        expect(
          report.diagnostics.map((item) => item.code),
          contains(TMToGrammarDiagnosticCode.noAcceptingState),
        );
        expect(
          PhraseGrammarClassifier.classify(report.grammar!).isValid,
          isTrue,
        );
      },
    );

    test(
      'is deterministic across transition insertion order and collisions',
      () {
        final q0 = _state('q0', initial: true);
        final qa = _state('qa', accepting: true);
        final transitions = [
          _transition('z', q0, qa, 'B', 'B', TapeDirection.stay),
          _transition('a', q0, q0, 'x', 'x', TapeDirection.right),
        ];
        final signatures = <String>{};
        for (var seed = 0; seed < 10; seed++) {
          final shuffled = [...transitions]..shuffle(math.Random(seed));
          final tm = _tm(
            states: {qa, q0},
            initial: q0,
            accepting: {qa},
            alphabet: {'TMV000000', 'x'},
            tapeAlphabet: {'TMV000000', 'x', 'B'},
            transitions: shuffled.toSet(),
          );
          final report = TMToGrammarConverter.build(tm, sourceRevision: 1);
          expect(
            report.outcome,
            TMToGrammarOutcome.completed,
            reason: report.diagnostics
                .map((item) => '${item.code.name}:${item.detailCode}')
                .join(', '),
          );
          signatures.add(_signature(report));
          expect(
            report.grammar!.nonterminals.map((symbol) => symbol.value),
            isNot(contains('TMV000000')),
          );
        }
        expect(signatures, hasLength(1));
      },
    );

    test('fails closed when the production construction limit is reached', () {
      final report = TMToGrammarConverter.build(
        _immediateAcceptor(alphabet: {'a'}),
        sourceRevision: 1,
        maxProductions: 2,
      );

      expect(report.outcome, TMToGrammarOutcome.constructionLimit);
      expect(report.grammar, isNull);
      expect(
        report.diagnostics.map((item) => item.code),
        contains(TMToGrammarDiagnosticCode.constructionLimit),
      );
    });
  });
}

String _signature(TMToGrammarConstructionReport report) => [
  report.grammar!.terminals.map((item) => item.value).toList()..sort(),
  report.grammar!.nonterminals.map((item) => item.value).toList()..sort(),
  [
    for (final production in report.grammar!.productions)
      '${production.id}:${production.structuralKey}',
  ],
  [
    for (final provenance in report.productionProvenance)
      '${provenance.productionId}:${provenance.family.name}:${provenance.sources.map((source) => source.transitionId).join(',')}',
  ],
].toString();

TM _immediateAcceptor({required Set<String> alphabet}) {
  final q0 = _state('q0', initial: true, accepting: true);
  return _tm(
    states: {q0},
    initial: q0,
    accepting: {q0},
    alphabet: alphabet,
    tapeAlphabet: {...alphabet, 'B'},
  );
}

State _state(String id, {bool initial = false, bool accepting = false}) =>
    State(
      id: id,
      label: id,
      position: Vector2.zero(),
      isInitial: initial,
      isAccepting: accepting,
    );

TMTransition _transition(
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
  label: id,
  controlPoint: from == to ? Vector2(0, -80) : Vector2.zero(),
  readSymbol: read,
  writeSymbol: write,
  direction: direction,
);

TM _tm({
  required Set<State> states,
  required State initial,
  Set<State> accepting = const {},
  Set<String> alphabet = const {},
  Set<String> tapeAlphabet = const {'B'},
  Set<TMTransition> transitions = const {},
}) => TM(
  id: 'tm-source',
  name: 'TM source',
  states: states,
  transitions: transitions,
  alphabet: alphabet,
  initialState: initial,
  acceptingStates: accepting,
  created: DateTime.utc(2026),
  modified: DateTime.utc(2026),
  bounds: const math.Rectangle(0, 0, 800, 600),
  tapeAlphabet: tapeAlphabet,
);

/// Deterministic 2-tape acceptor for a⁺ that copies the input to tape 2.
/// Small on purpose: the reduction squares the tape alphabet, and the
/// grammar grows with every reduced transition and tape symbol.
TM _twoTapeCopier() {
  final q0 = _state('q0', initial: true);
  final q1 = _state('q1');
  final qa = _state('qa', accepting: true);
  TMTransition vector(
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
    label: id,
    controlPoint: identical(from, to) ? Vector2(30, -30) : Vector2.zero(),
    readSymbols: reads,
    writeSymbols: writes,
    directions: moves,
  );
  const r = TapeDirection.right;
  const s = TapeDirection.stay;
  return _tm(
    states: {q0, q1, qa},
    initial: q0,
    accepting: {qa},
    alphabet: {'a'},
    tapeAlphabet: {'a', 'B'},
    transitions: {
      vector('first', q0, q1, ['a', 'B'], ['a', 'a'], [r, r]),
      vector('more', q1, q1, ['a', 'B'], ['a', 'a'], [r, r]),
      vector('done', q1, qa, ['B', 'B'], ['B', 'B'], [s, s]),
    },
  ).copyWith(tapeCount: 2);
}
