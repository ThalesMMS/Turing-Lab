import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/manual_conversions/fa_grammar_manual.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/production.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/core/models/transition.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  group('FaGrammarManualOracle.fromFa', () {
    test('creates deterministic obligations with source provenance', () {
      final fsa = _sampleFsa(withEpsilonTransition: true);

      final first = FaGrammarManualOracle.fromFa(fsa);
      final second = FaGrammarManualOracle.fromFa(fsa);

      expect(first.isSuccess, isTrue, reason: first.error);
      expect(second.isSuccess, isTrue, reason: second.error);
      final plan = first.data!;
      expect(plan.orientation, FaGrammarManualOrientation.rightLinear);
      expect(plan.source.revision, second.data!.source.revision);
      expect(
        plan.obligations.map((obligation) => obligation.id),
        orderedEquals(
          second.data!.obligations.map((obligation) => obligation.id),
        ),
      );
      expect(plan.obligations.map((item) => item.id).toSet(), hasLength(5));
      expect(
        plan.obligations.every(
          (obligation) =>
              obligation.provenance.sourceDocumentId == fsa.id &&
              obligation.provenance.sourceIds.isNotEmpty &&
              obligation.provenance.canonicalTargetIds.isNotEmpty,
        ),
        isTrue,
      );

      final epsilonEdge = plan.obligations.singleWhere(
        (obligation) => obligation.provenance.sourceIds.contains('epsilon'),
      );
      expect(
        epsilonEdge.kind,
        FaGrammarManualActionKind.mapTransitionToProduction,
      );
      expect(epsilonEdge.production!.rightSide, ['A1']);
      expect(epsilonEdge.production!.isEpsilon, isFalse);
    });

    test('keeps the source snapshot independent from later source mutation',
        () {
      final fsa = _sampleFsa();
      final plan = FaGrammarManualOracle.fromFa(fsa).data!;
      final revision = plan.source.revision;
      final snapshot = plan.source.canonicalJson;

      fsa.states.first.position.setValues(999, 999);

      expect(plan.source.revision, revision);
      expect(plan.source.canonicalJson, snapshot);
      expect(plan.source.canonicalJson, isNot(contains('999.0')));
    });

    test('round-trips an epsilon edge through its unit production', () {
      final plan = FaGrammarManualOracle.fromFa(
        _sampleFsa(withEpsilonTransition: true),
      ).data!;

      final comparison = plan.compare(learnerGrammar: plan.canonicalGrammar);

      expect(
        comparison.equivalenceStatus,
        FaGrammarManualEquivalenceStatus.equivalent,
      );
    });

    test('returns defensive copies of the canonical target', () {
      final plan = FaGrammarManualOracle.fromFa(_sampleFsa()).data!;
      final first = plan.canonicalGrammar!;

      first.productions.clear();

      expect(plan.canonicalGrammar!.productions, isNotEmpty);
    });

    test('returns a typed failure instead of dereferencing a missing initial',
        () {
      final q0 = State(id: 'q0', label: 'q0', position: Vector2.zero());
      final now = DateTime.utc(2026);
      final fsa = FSA(
        id: 'no-start',
        name: 'No start',
        states: {q0},
        transitions: const <Transition>{},
        alphabet: const {},
        acceptingStates: const {},
        created: now,
        modified: now,
        bounds: const math.Rectangle(0, 0, 100, 100),
      );

      final result = FaGrammarManualOracle.fromFa(fsa);

      expect(result.isFailure, isTrue);
      expect(result.error, contains('initial state'));
    });
  });

  group('immutable action progress', () {
    test('accepts each canonical mapping once and preserves the prior plan',
        () {
      final initial = FaGrammarManualOracle.fromFa(_sampleFsa()).data!;
      final firstObligation = initial.obligations.first;
      final correct = _actionFor(firstObligation, 'action-1');

      final applied = initial.apply(correct);

      expect(applied.isSuccess, isTrue);
      expect(initial.completedObligationIds, isEmpty);
      expect(applied.plan.completedObligationIds, {firstObligation.id});

      final duplicateId = applied.plan.apply(correct);
      expect(duplicateId.isSuccess, isFalse);
      expect(
        duplicateId.diagnostic!.code,
        FaGrammarManualDiagnosticCode.duplicateActionId,
      );

      final alreadyDone = applied.plan.apply(
        _actionFor(firstObligation, 'action-2'),
      );
      expect(
        alreadyDone.diagnostic!.code,
        FaGrammarManualDiagnosticCode.alreadyCompleted,
      );
    });

    test('rejects an incorrect correspondence without changing progress', () {
      final plan = FaGrammarManualOracle.fromFa(_sampleFsa()).data!;

      final result = plan.apply(
        FaGrammarManualAction.mapStateToNonterminal(
          id: 'wrong',
          stateId: 'q0',
          nonterminal: 'WRONG',
        ),
      );

      expect(result.isSuccess, isFalse);
      expect(
        result.diagnostic!.code,
        FaGrammarManualDiagnosticCode.incorrectMapping,
      );
      expect(identical(result.plan, plan), isTrue);
    });

    test('materializes and compares the learner grammar from accepted actions',
        () {
      var plan = FaGrammarManualOracle.fromFa(_sampleFsa()).data!;

      expect(plan.learnerArtifact.document, isNull);
      for (var index = 0; index < plan.obligations.length; index++) {
        final obligation = plan.pendingObligations.first;
        plan = plan.apply(_actionFor(obligation, 'learner-$index')).plan;
      }

      final artifact = plan.learnerArtifact;
      final document = artifact.document!;
      expect(artifact.stateToNonterminal, {'q0': 'A0', 'q1': 'A1'});
      expect((document['productions'] as List), hasLength(2));
      expect(
        plan.compareLearnerConstruction().equivalenceStatus,
        FaGrammarManualEquivalenceStatus.equivalent,
      );
      expect(
        document,
        isNot(equals(plan.canonicalGrammar!.toJson())),
        reason: 'The learner document must be reconstructed, not copied.',
      );
    });
  });

  group('FaGrammarManualOracle.fromRightLinearGrammar', () {
    test('separates nonterminal, transition, and epsilon obligations', () {
      final result = FaGrammarManualOracle.fromRightLinearGrammar(
        _rightLinearGrammar(),
      );

      expect(result.isSuccess, isTrue, reason: result.error);
      final plan = result.data!;
      expect(plan.canonicalFsa, isNotNull);
      expect(
        plan.obligations
            .where(
              (item) =>
                  item.kind == FaGrammarManualActionKind.mapNonterminalToState,
            )
            .length,
        2,
      );
      expect(
        plan.obligations
            .where(
              (item) =>
                  item.kind ==
                  FaGrammarManualActionKind.mapProductionToTransition,
            )
            .length,
        2,
      );
      final epsilon = plan.obligations.singleWhere(
        (item) =>
            item.kind ==
            FaGrammarManualActionKind.mapEpsilonProductionToAcceptingState,
      );
      expect(epsilon.stateId, 'S');
      expect(epsilon.provenance.sourceIds, ['epsilon']);
    });

    test('reports structural completion separately from exact equivalence', () {
      var plan = FaGrammarManualOracle.fromRightLinearGrammar(
        _rightLinearGrammar(),
      ).data!;
      for (var index = 0; index < plan.obligations.length; index++) {
        final obligation = plan.pendingObligations.first;
        final applied = plan.apply(_actionFor(obligation, 'action-$index'));
        expect(applied.isSuccess, isTrue);
        plan = applied.plan;
      }

      final exact = plan.compare(learnerFsa: plan.canonicalFsa);
      expect(exact.structurallyComplete, isTrue);
      expect(
        exact.equivalenceStatus,
        FaGrammarManualEquivalenceStatus.equivalent,
      );

      final rejecting = plan.canonicalFsa!.copyWith(acceptingStates: const {});
      final mismatch = plan.compare(learnerFsa: rejecting);
      expect(
        mismatch.equivalenceStatus,
        FaGrammarManualEquivalenceStatus.notEquivalent,
      );
      expect(mismatch.distinguishingString, '');
    });

    test('materializes and compares the learner FSA from accepted actions', () {
      var plan = FaGrammarManualOracle.fromRightLinearGrammar(
        _rightLinearGrammar(),
      ).data!;

      for (var index = 0; index < plan.obligations.length; index++) {
        final obligation = plan.pendingObligations.first;
        plan = plan.apply(_actionFor(obligation, 'learner-$index')).plan;
      }

      final artifact = plan.learnerArtifact;
      final document = artifact.document!;
      expect(artifact.nonterminalToState, {'A': 'A', 'S': 'S'});
      expect((document['transitions'] as List), hasLength(2));
      expect(
        plan.compareLearnerConstruction().equivalenceStatus,
        FaGrammarManualEquivalenceStatus.equivalent,
      );
      expect(
        document,
        isNot(equals(plan.canonicalFsa!.toJson())),
        reason: 'The learner document must be reconstructed, not copied.',
      );
    });

    test('uses the canonical converter to reject a left-linear source', () {
      final now = DateTime.utc(2026);
      final grammar = Grammar(
        id: 'left-linear',
        name: 'Left linear',
        terminals: const {'a'},
        nonterminals: const {'S', 'A'},
        startSymbol: 'S',
        productions: {
          const Production(
            id: 'p0',
            leftSide: ['S'],
            rightSide: ['A', 'a'],
          ),
        },
        type: GrammarType.regular,
        created: now,
        modified: now,
      );

      final result = FaGrammarManualOracle.fromRightLinearGrammar(grammar);

      expect(result.isFailure, isTrue);
      expect(result.error, contains('terminal'));
    });

    test('maps a unit production to an epsilon transition', () {
      final now = DateTime.utc(2026);
      final grammar = Grammar(
        id: 'unit',
        name: 'Unit production',
        terminals: const {'a'},
        nonterminals: const {'S', 'A'},
        startSymbol: 'S',
        productions: {
          const Production(
            id: 'unit-edge',
            leftSide: ['S'],
            rightSide: ['A'],
          ),
          const Production(
            id: 'terminal',
            leftSide: ['A'],
            rightSide: ['a'],
            order: 1,
          ),
        },
        type: GrammarType.regular,
        created: now,
        modified: now,
      );

      final result = FaGrammarManualOracle.fromRightLinearGrammar(grammar);

      expect(result.isSuccess, isTrue, reason: result.error);
      final obligation = result.data!.obligations.singleWhere(
        (item) => item.provenance.sourceIds.contains('unit-edge'),
      );
      expect(obligation.transition!.fromStateId, 'S');
      expect(obligation.transition!.toStateId, 'A');
      expect(obligation.transition!.isEpsilon, isTrue);
      expect(obligation.transition!.inputSymbol, isEmpty);
      expect(obligation.provenance.canonicalTargetIds, isNotEmpty);
    });
  });

  test('FA to grammar comparison can prove equivalence before all steps', () {
    final plan = FaGrammarManualOracle.fromFa(_sampleFsa()).data!;

    final comparison = plan.compare(learnerGrammar: plan.canonicalGrammar);

    expect(comparison.structurallyComplete, isFalse);
    expect(
      comparison.equivalenceStatus,
      FaGrammarManualEquivalenceStatus.equivalent,
    );
  });

  test('FA plan creates epsilon and symbol obligations for a mixed edge', () {
    final q0 = State(
      id: 'q0',
      label: 'q0',
      position: Vector2.zero(),
      isInitial: true,
    );
    final q1 = State(
      id: 'q1',
      label: 'q1',
      position: Vector2(100, 0),
      isAccepting: true,
    );
    final now = DateTime.utc(2026);
    final source = FSA(
      id: 'mixed',
      name: 'Mixed',
      states: {q0, q1},
      transitions: {
        FSATransition(
          id: 'mixed-edge',
          fromState: q0,
          toState: q1,
          inputSymbols: const {'lambda', 'a'},
        ),
      },
      alphabet: const {'a'},
      initialState: q0,
      acceptingStates: {q1},
      created: now,
      modified: now,
      bounds: const math.Rectangle(0, 0, 200, 100),
    );

    final plan = FaGrammarManualOracle.fromFa(source).data!;
    final edgeObligations = plan.obligations.where(
      (obligation) => obligation.provenance.sourceIds.contains('mixed-edge'),
    );

    expect(edgeObligations, hasLength(2));
    expect(
      edgeObligations.any(
        (obligation) => obligation.production!.rightSide.length == 1,
      ),
      isTrue,
    );
    expect(
      edgeObligations.any(
        (obligation) => obligation.production!.rightSide.first == 'a',
      ),
      isTrue,
    );
  });
}

FaGrammarManualAction _actionFor(
  FaGrammarManualObligation obligation,
  String actionId,
) =>
    switch (obligation.kind) {
      FaGrammarManualActionKind.mapStateToNonterminal =>
        FaGrammarManualAction.mapStateToNonterminal(
          id: actionId,
          stateId: obligation.stateId!,
          nonterminal: obligation.nonterminal!,
        ),
      FaGrammarManualActionKind.mapNonterminalToState =>
        FaGrammarManualAction.mapNonterminalToState(
          id: actionId,
          nonterminal: obligation.nonterminal!,
          stateId: obligation.stateId!,
        ),
      FaGrammarManualActionKind.mapTransitionToProduction =>
        FaGrammarManualAction.mapTransitionToProduction(
          id: actionId,
          production: obligation.production!,
        ),
      FaGrammarManualActionKind.mapProductionToTransition =>
        FaGrammarManualAction.mapProductionToTransition(
          id: actionId,
          transition: obligation.transition!,
        ),
      FaGrammarManualActionKind.mapAcceptingStateToEpsilon =>
        FaGrammarManualAction.mapAcceptingStateToEpsilon(
          id: actionId,
          stateId: obligation.stateId!,
          production: obligation.production!,
        ),
      FaGrammarManualActionKind.mapEpsilonProductionToAcceptingState =>
        FaGrammarManualAction.mapEpsilonProductionToAcceptingState(
          id: actionId,
          stateId: obligation.stateId!,
        ),
    };

FSA _sampleFsa({bool withEpsilonTransition = false}) {
  final q0 = State(
    id: 'q0',
    label: 'q0',
    position: Vector2.zero(),
    isInitial: true,
    isAccepting: true,
  );
  final q1 = State(id: 'q1', label: 'q1', position: Vector2(100, 0));
  final transitions = <Transition>{
    FSATransition.deterministic(
      id: 'a',
      fromState: q1,
      toState: q0,
      symbol: 'a',
    ),
    if (withEpsilonTransition)
      FSATransition.epsilon(id: 'epsilon', fromState: q0, toState: q1),
  };
  final now = DateTime.utc(2026);
  return FSA(
    id: 'source-fa',
    name: 'Source FA',
    states: {q0, q1},
    transitions: transitions,
    alphabet: const {'a'},
    initialState: q0,
    acceptingStates: {q0},
    created: now,
    modified: now,
    bounds: const math.Rectangle(0, 0, 200, 100),
  );
}

Grammar _rightLinearGrammar() {
  final now = DateTime.utc(2026);
  return Grammar(
    id: 'source-grammar',
    name: 'Source grammar',
    terminals: const {'a', 'b'},
    nonterminals: const {'S', 'A'},
    startSymbol: 'S',
    productions: {
      const Production(
        id: 'to-a',
        leftSide: ['S'],
        rightSide: ['a', 'A'],
        order: 0,
      ),
      const Production(
        id: 'terminal',
        leftSide: ['A'],
        rightSide: ['b'],
        order: 1,
      ),
      const Production(
        id: 'epsilon',
        leftSide: ['S'],
        rightSide: [],
        isLambda: true,
        order: 2,
      ),
    },
    type: GrammarType.regular,
    created: now,
    modified: now,
  );
}
