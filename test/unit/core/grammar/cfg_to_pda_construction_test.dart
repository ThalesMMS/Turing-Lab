import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/grammar_to_pda/cfg_to_pda.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/pda_transition.dart';
import 'package:turing_lab/core/models/production.dart';

void main() {
  group('typed CFG to PDA constructions', () {
    test('builds a predictive LL PDA with exact token provenance', () {
      final grammar = _llGrammar();
      final before = grammar.toJson();

      final report = CfgToPdaConverter.buildLl(
        grammar,
        sourceRevision: 7,
      );

      expect(report.outcome, CfgToPdaConstructionOutcome.completed);
      expect(report.pda!.validate(), isEmpty);
      expect(report.pda!.states, hasLength(3));
      expect(report.pda!.pdaTransitions, hasLength(7));
      expect(report.acceptanceMode.name, 'finalState');
      expect(grammar.toJson(), before);
      final expansion = report.transitionProvenance.singleWhere(
        (item) => item.sources.any(
          (source) => source.productionId == 'tail-more',
        ),
      );
      final transition = report.pda!.pdaTransitions.singleWhere(
        (item) => item.id == expansion.transitionId,
      );
      expect(transition.popSymbol, 'Tail');
      expect(transition.pushSymbols, ['plus', 'identifier', 'Tail']);
      expect(
        expansion.sources
            .where((source) => source.side == CfgToPdaSourceSide.right)
            .map((source) => source.symbolPosition),
        [0, 1, 2],
      );
    });

    test('builds a distinct bottom-up LR PDA using atomic reduction chains',
        () {
      final grammar = _lrGrammar();
      final report = CfgToPdaConverter.buildLr(
        grammar,
        sourceRevision: 3,
      );

      expect(report.outcome, CfgToPdaConstructionOutcome.completed);
      expect(report.pda!.validate(), isEmpty);
      expect(
        report.assumptions,
        contains(CfgToPdaAssumption.lrCanonicalConflictFree),
      );
      expect(
        report.steps.where(
          (step) => step.kind == CfgToPdaStepKind.reduceProduction,
        ),
        hasLength(3),
      );
      final startReduction = report.steps.singleWhere(
        (step) =>
            step.kind == CfgToPdaStepKind.reduceProduction &&
            step.sources.any((source) => source.productionId == 's-cc'),
      );
      expect(startReduction.transitionIds, hasLength(2));
      expect(
        startReduction.sources.any(
          (source) => source.lrState != null && source.lrItemKeys.isNotEmpty,
        ),
        isTrue,
      );
      final reductionTransitions = [
        for (final id in startReduction.transitionIds)
          report.pda!.pdaTransitions.singleWhere((item) => item.id == id),
      ];
      expect(reductionTransitions.map((item) => item.popSymbol), ['C', 'C']);
      expect(reductionTransitions.last.pushSymbols, ['S']);
      expect(
        report.steps.any((step) => step.kind == CfgToPdaStepKind.shiftTerminal),
        isTrue,
      );
      expect(
        report.steps
            .any((step) => step.kind == CfgToPdaStepKind.expandVariable),
        isFalse,
      );
    });

    test('supports epsilon and collision-safe bottom stack symbols', () {
      final grammar = _grammar(
        terminals: {'__TL_BOTTOM__'},
        nonterminals: {'S'},
        productions: {
          const Production(
            id: 'empty',
            leftSide: ['S'],
            rightSide: [],
            isLambda: true,
          ),
        },
      );

      final ll = CfgToPdaConverter.buildLl(grammar, sourceRevision: 1);
      final lr = CfgToPdaConverter.buildLr(grammar, sourceRevision: 1);

      expect(ll.pda!.initialStackSymbol, '__TL_BOTTOM___1');
      expect(lr.pda!.initialStackSymbol, '__TL_BOTTOM___1');
      expect(
        ll.pda!.pdaTransitions
            .singleWhere(
              (transition) =>
                  reportKind(ll, transition) == CfgToPdaStepKind.expandVariable,
            )
            .isLambdaPush,
        isTrue,
      );
      expect(
        lr.pda!.pdaTransitions
            .singleWhere(
              (transition) =>
                  reportKind(lr, transition) ==
                  CfgToPdaStepKind.reduceProduction,
            )
            .pushSymbols,
        ['S'],
      );
    });

    test('normalizes legacy epsilon aliases through canonical PDA flags', () {
      final grammar = _grammar(
        terminals: const {},
        nonterminals: {'S'},
        productions: {
          const Production(
            id: 'legacy-empty',
            leftSide: ['S'],
            rightSide: ['epsilon'],
          ),
        },
      );

      final ll = CfgToPdaConverter.buildLl(grammar, sourceRevision: 1);
      final lr = CfgToPdaConverter.buildLr(grammar, sourceRevision: 1);

      for (final report in [ll, lr]) {
        expect(report.outcome, CfgToPdaConstructionOutcome.completed);
        expect(report.pda!.alphabet, isEmpty);
        expect(report.pda!.stackAlphabet, isNot(contains('epsilon')));
        final productionTransition = report.pda!.pdaTransitions.singleWhere(
          (transition) => report
              .provenanceFor(transition.id)!
              .sources
              .any((source) => source.productionId == 'legacy-empty'),
        );
        expect(productionTransition.isLambdaInput, isTrue);
        if (report.orientation == CfgToPdaOrientation.ll) {
          expect(productionTransition.isLambdaPush, isTrue);
        } else {
          expect(productionTransition.isLambdaPop, isTrue);
        }
      }
    });

    test('surfaces LL and LR conflicts without constructing a PDA', () {
      final llConflict = _grammar(
        terminals: {'a'},
        nonterminals: {'S'},
        productions: {
          const Production(id: 'p1', leftSide: ['S'], rightSide: ['a']),
          const Production(
            id: 'p2',
            leftSide: ['S'],
            rightSide: ['a', 'S'],
            order: 1,
          ),
        },
      );
      final lrConflict = _grammar(
        terminals: {'id', 'plus'},
        nonterminals: {'E'},
        start: 'E',
        productions: {
          const Production(
            id: 'binary',
            leftSide: ['E'],
            rightSide: ['E', 'plus', 'E'],
          ),
          const Production(
            id: 'id',
            leftSide: ['E'],
            rightSide: ['id'],
            order: 1,
          ),
        },
      );

      final ll = CfgToPdaConverter.buildLl(llConflict, sourceRevision: 1);
      final lr = CfgToPdaConverter.buildLr(lrConflict, sourceRevision: 1);

      expect(ll.outcome, CfgToPdaConstructionOutcome.llConflict);
      expect(ll.pda, isNull);
      expect(ll.diagnostics.single.relatedProductionIds, ['p1', 'p2']);
      expect(lr.outcome, CfgToPdaConstructionOutcome.lrConflict);
      expect(lr.pda, isNull);
      expect(lr.diagnostics, isNotEmpty);
      expect(lr.diagnostics.first.lrState, isNotNull);
      expect(lr.diagnostics.first.lookahead, isNotEmpty);
    });

    test('rejects malformed and duplicate source identities with typed codes',
        () {
      final grammar = _grammar(
        terminals: {'a'},
        nonterminals: {'S'},
        productions: {
          const Production(id: 'same', leftSide: ['S'], rightSide: ['a']),
          const Production(
            id: 'same',
            leftSide: ['S'],
            rightSide: ['missing'],
            order: 1,
          ),
        },
      );

      final report = CfgToPdaConverter.buildLl(grammar, sourceRevision: 1);

      expect(report.outcome, CfgToPdaConstructionOutcome.invalidGrammar);
      expect(
        report.diagnostics.map((diagnostic) => diagnostic.code),
        containsAll({
          CfgToPdaDiagnosticCode.duplicateProductionId,
          CfgToPdaDiagnosticCode.undeclaredSymbol,
        }),
      );
    });

    test('rejects epsilon aliases mixed with concrete production symbols', () {
      final grammar = _grammar(
        terminals: {'a'},
        nonterminals: {'S'},
        productions: {
          const Production(
            id: 'mixed-empty',
            leftSide: ['S'],
            rightSide: ['a', 'epsilon'],
          ),
        },
      );

      final report = CfgToPdaConverter.buildLl(grammar, sourceRevision: 1);

      expect(report.outcome, CfgToPdaConstructionOutcome.invalidGrammar);
      expect(
        report.diagnostics.map((diagnostic) => diagnostic.code),
        contains(CfgToPdaDiagnosticCode.malformedProduction),
      );
    });

    test('constructs an LL PDA for a valid grammar with an empty language', () {
      final grammar = _grammar(
        terminals: {'a'},
        nonterminals: {'S', 'A'},
        productions: {
          const Production(
              id: 'unproductive', leftSide: ['S'], rightSide: ['A']),
        },
      );

      final report = CfgToPdaConverter.buildLl(grammar, sourceRevision: 1);
      final evidence = CfgToPdaDifferentialChecker.check(
        grammar,
        report,
        ['', 'a', 'aa'],
      );

      expect(report.outcome, CfgToPdaConstructionOutcome.completed);
      expect(report.pda!.validate(), isEmpty);
      expect(evidence.hasMismatch, isFalse);
      expect(
        evidence.samples.map((sample) => sample.outcome),
        everyElement(CfgToPdaSampleOutcome.matchingRejection),
      );
    });

    test('accepts a conflict-free left-recursive grammar only in LR mode', () {
      final grammar = _grammar(
        terminals: {'identifier', 'plus'},
        nonterminals: {'E', 'T'},
        start: 'E',
        productions: {
          const Production(
            id: 'sum',
            leftSide: ['E'],
            rightSide: ['E', 'plus', 'T'],
          ),
          const Production(
            id: 'term',
            leftSide: ['E'],
            rightSide: ['T'],
            order: 1,
          ),
          const Production(
            id: 'identifier',
            leftSide: ['T'],
            rightSide: ['identifier'],
            order: 2,
          ),
        },
      );

      final ll = CfgToPdaConverter.buildLl(grammar, sourceRevision: 1);
      final lr = CfgToPdaConverter.buildLr(grammar, sourceRevision: 1);

      expect(ll.outcome, CfgToPdaConstructionOutcome.llConflict);
      expect(lr.outcome, CfgToPdaConstructionOutcome.completed);
      expect(lr.pda!.validate(), isEmpty);
      expect(
        lr.transitionProvenance
            .where((source) => source.kind == CfgToPdaStepKind.reduceProduction)
            .any((source) =>
                source.sources.any((item) => item.productionId == 'sum')),
        isTrue,
      );
    });

    test('is deterministic across randomized production insertion order', () {
      final productions = _lrGrammar().productions.toList();
      final expected = _signature(
        CfgToPdaConverter.buildLr(_lrGrammar(), sourceRevision: 1),
      );

      for (var seed = 0; seed < 12; seed++) {
        final shuffled = [...productions]..shuffle(math.Random(seed));
        final grammar = _grammar(
          terminals: {'c', 'd'},
          nonterminals: {'S', 'C'},
          productions: shuffled.toSet(),
        );
        expect(
          _signature(CfgToPdaConverter.buildLr(grammar, sourceRevision: 1)),
          expected,
          reason: 'seed $seed',
        );
      }
    });

    test('bounded differential evidence matches representative LL and LR words',
        () {
      final llGrammar = _llGrammar();
      final lrGrammar = _lrGrammar();
      final ll = CfgToPdaConverter.buildLl(llGrammar, sourceRevision: 1);
      final lr = CfgToPdaConverter.buildLr(lrGrammar, sourceRevision: 1);

      final llEvidence = CfgToPdaDifferentialChecker.check(
        llGrammar,
        ll,
        ['', 'identifier', 'identifierplusidentifier', 'plus'],
      );
      final lrEvidence = CfgToPdaDifferentialChecker.check(
        lrGrammar,
        lr,
        ['', 'dd', 'cddd', 'c'],
      );

      expect(llEvidence.isProof, isFalse);
      expect(llEvidence.hasMismatch, isFalse);
      expect(lrEvidence.hasMismatch, isFalse);
      expect(
        llEvidence.samples.map((sample) => sample.outcome),
        contains(CfgToPdaSampleOutcome.matchingAcceptance),
      );
      expect(
        lrEvidence.samples.map((sample) => sample.outcome),
        contains(CfgToPdaSampleOutcome.matchingRejection),
      );
    });
  });
}

CfgToPdaStepKind? reportKind(
  CfgToPdaConstructionReport report,
  PDATransition transition,
) =>
    report.provenanceFor(transition.id)?.kind;

String _signature(CfgToPdaConstructionReport report) {
  final transitions = report.pda!.pdaTransitions.toList()
    ..sort((left, right) => left.id.compareTo(right.id));
  return [
    report.outcome.name,
    report.pda!.states.map((state) => state.id).toList()..sort(),
    [
      for (final transition in transitions)
        [
          transition.id,
          transition.fromState.id,
          transition.toState.id,
          transition.inputSymbol,
          transition.popSymbol,
          transition.pushSymbols.join('|'),
        ].join(':'),
    ],
    [
      for (final provenance in report.transitionProvenance)
        [
          provenance.transitionId,
          provenance.kind.name,
          provenance.sources
              .map(
                (source) =>
                    '${source.productionId}:${source.lrState}:${source.lookahead}',
              )
              .join('|'),
        ].join(':'),
    ],
  ].toString();
}

Grammar _llGrammar() => _grammar(
      terminals: {'identifier', 'plus'},
      nonterminals: {'S', 'Tail'},
      productions: {
        const Production(
          id: 'start',
          leftSide: ['S'],
          rightSide: ['identifier', 'Tail'],
        ),
        const Production(
          id: 'tail-more',
          leftSide: ['Tail'],
          rightSide: ['plus', 'identifier', 'Tail'],
          order: 1,
        ),
        const Production(
          id: 'tail-empty',
          leftSide: ['Tail'],
          rightSide: [],
          isLambda: true,
          order: 2,
        ),
      },
    );

Grammar _lrGrammar() => _grammar(
      terminals: {'c', 'd'},
      nonterminals: {'S', 'C'},
      productions: {
        const Production(
          id: 's-cc',
          leftSide: ['S'],
          rightSide: ['C', 'C'],
        ),
        const Production(
          id: 'c-c',
          leftSide: ['C'],
          rightSide: ['c', 'C'],
          order: 1,
        ),
        const Production(
          id: 'c-d',
          leftSide: ['C'],
          rightSide: ['d'],
          order: 2,
        ),
      },
    );

Grammar _grammar({
  required Set<String> terminals,
  required Set<String> nonterminals,
  required Set<Production> productions,
  String start = 'S',
}) =>
    Grammar(
      id: 'cfg-pda-source',
      name: 'CFG to PDA source',
      terminals: terminals,
      nonterminals: nonterminals,
      startSymbol: start,
      productions: productions,
      type: GrammarType.contextFree,
      created: DateTime.utc(2026),
      modified: DateTime.utc(2026),
    );
