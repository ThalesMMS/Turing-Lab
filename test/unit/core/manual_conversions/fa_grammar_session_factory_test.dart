import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/manual_conversions/fa_grammar_manual.dart';
import 'package:turing_lab/core/manual_conversions/fa_grammar_session_factory.dart';
import 'package:turing_lab/core/manual_conversions/manual_conversion_session.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/production.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  group('FaGrammarSessionFactory.fromFa', () {
    test('adapts every oracle obligation and exact grammar artifact', () {
      final oracle = FaGrammarManualOracle.fromFa(_sampleFsa()).data!;

      final result = FaGrammarSessionFactory.fromFa(
        sessionId: 'fa-to-grammar',
        source: _sampleFsa(),
      );

      expect(result.isSuccess, isTrue, reason: result.error);
      final session = result.data!;
      expect(
        session.direction,
        ManualConversionDirection.faToRegularGrammar,
      );
      expect(session.source.documentId, 'source-fa');
      expect(session.source.snapshot['id'], 'source-fa');
      expect(
        session.source.revision,
        FaGrammarSessionFactory.sourceRevisionFor(oracle),
      );
      expect(
        session.requirements.map((requirement) => requirement.id),
        orderedEquals(oracle.obligations.map((obligation) => obligation.id)),
      );
      expect(
        session.requirements.map((requirement) => requirement.type),
        containsAll(<ManualConversionActionType>{
          ManualConversionActionType.mapState,
          ManualConversionActionType.addProduction,
          ManualConversionActionType.markEpsilon,
        }),
      );
      _expectRequirementEvidence(session);

      final transitionStep = session.requirements.singleWhere(
        (requirement) =>
            requirement.type == ManualConversionActionType.addProduction,
      );
      expect(transitionStep.provenanceIds, ['a-edge']);
      expect(
        transitionStep.expectedPayload['production'],
        {
          'leftSide': ['A1'],
          'rightSide': ['a', 'A0'],
          'isEpsilon': false,
        },
      );
      expect(session.canonicalArtifact['kind'], 'grammar');
      expect(session.canonicalArtifact['format'], 'turing-lab.grammar');
      expect(session.canonicalArtifact['orientation'], 'rightLinear');
      expect(session.canonicalArtifact['document'], isA<Map>());
      expect(
        session.completionEvidence.certainty,
        ManualConversionCertainty.exact,
      );
      expect(session.completionEvidence.provenanceIds, isNotEmpty);

      final completed = _complete(session);
      expect(completed.isComplete, isTrue);
      expect(completed.actions, hasLength(completed.requirements.length));

      final restored = ManualConversionSession.restore(
        completed.toJson(),
        documentId: completed.source.documentId,
        revision: completed.source.revision,
      );
      expect(restored.isSuccess, isTrue);
      expect(restored.session!.canonicalArtifact, completed.canonicalArtifact);
    });

    test('records the learner grammar and exact comparison evidence', () {
      final initial = FaGrammarSessionFactory.fromFa(
        sessionId: 'fa-learner',
        source: _sampleFsa(),
        sourceRevision: 12,
      ).data!;

      final completed = _completeValidated(initial);

      expect(completed.isComplete, isTrue);
      expect(completed.actions, everyElement(_isExternallyValidated));
      expect(completed.learnerArtifact?['kind'], 'grammar');
      expect(completed.learnerArtifact?['document'], isA<Map>());
      expect(
        completed.learnerArtifact?['document'],
        isNot(equals(completed.canonicalArtifact['document'])),
      );
      expect(
        completed.latestEvidence?.certainty,
        ManualConversionCertainty.exact,
      );
      final comparison = FaGrammarSessionFactory.compareLearnerArtifact(
        session: completed,
        learnerArtifact: completed.learnerArtifact!,
      );
      expect(comparison.isSuccess, isTrue, reason: comparison.error);
      expect(
        comparison.data!.equivalenceStatus,
        FaGrammarManualEquivalenceStatus.equivalent,
      );

      final restored = ManualConversionSession.restore(
        completed.toJson(),
        documentId: completed.source.documentId,
        revision: completed.source.revision,
      );
      expect(restored.session!.learnerArtifact, completed.learnerArtifact);
      expect(restored.session!.latestEvidence?.certainty,
          ManualConversionCertainty.exact);
    });

    test('rejects an incorrect learner mapping without advancing', () {
      final session = FaGrammarSessionFactory.fromFa(
        sessionId: 'fa-wrong',
        source: _sampleFsa(),
      ).data!;
      final payload = Map<String, Object?>.from(
        session.currentRequirement!.expectedPayload,
      )..['nonterminal'] = 'WRONG';

      final result = FaGrammarSessionFactory.applyLearnerAction(
        session: session,
        payload: payload,
      );

      expect(result.isSuccess, isFalse);
      expect(result.session.cursor, 0);
      expect(result.session.learnerArtifact, isNull);
    });

    test('rejects a valid future correspondence submitted out of order', () {
      final session = FaGrammarSessionFactory.fromFa(
        sessionId: 'fa-out-of-order',
        source: _sampleFsa(),
      ).data!;
      final futurePayload = session.requirements[1].expectedPayload;

      final result = FaGrammarSessionFactory.applyLearnerAction(
        session: session,
        payload: futurePayload,
      );

      expect(result.isSuccess, isFalse);
      expect(result.session.cursor, 0);
      expect(result.diagnostics.single.code,
          ManualConversionDiagnosticCode.invalidPayload);
    });
  });

  group('FaGrammarSessionFactory.fromRightLinearGrammar', () {
    test('preserves unit, terminal, and epsilon production evidence', () {
      final result = FaGrammarSessionFactory.fromRightLinearGrammar(
        sessionId: 'grammar-to-fa',
        source: _rightLinearGrammar(),
      );

      expect(result.isSuccess, isTrue, reason: result.error);
      final session = result.data!;
      expect(
        session.direction,
        ManualConversionDirection.regularGrammarToFa,
      );
      expect(
        session.requirements.map((requirement) => requirement.type),
        containsAll(<ManualConversionActionType>{
          ManualConversionActionType.mapNonterminal,
          ManualConversionActionType.addTransition,
          ManualConversionActionType.markAccepting,
        }),
      );
      _expectRequirementEvidence(session);

      final unitStep = session.requirements.singleWhere(
        (requirement) => requirement.provenanceIds.contains('unit-edge'),
      );
      expect(unitStep.type, ManualConversionActionType.addTransition);
      expect(
        unitStep.expectedPayload['transition'],
        {
          'fromStateId': 'S',
          'toStateId': 'A',
          'inputSymbol': '',
          'isEpsilon': true,
          'toStateIsAccepting': false,
        },
      );

      final epsilonStep = session.requirements.singleWhere(
        (requirement) => requirement.provenanceIds.contains('epsilon'),
      );
      expect(epsilonStep.type, ManualConversionActionType.markAccepting);
      expect(epsilonStep.expectedPayload['isAccepting'], isTrue);
      expect(session.canonicalArtifact['kind'], 'fsa');
      expect(session.canonicalArtifact['format'], 'turing-lab.fsa');
      expect(session.canonicalArtifact['document'], isA<Map>());
      expect(
        session.completionEvidence.certainty,
        ManualConversionCertainty.exact,
      );
      expect(_complete(session).isComplete, isTrue);
    });

    test('records the learner FSA rather than copying the canonical target',
        () {
      final initial = FaGrammarSessionFactory.fromRightLinearGrammar(
        sessionId: 'grammar-learner',
        source: _rightLinearGrammar(),
        sourceRevision: 22,
      ).data!;

      final completed = _completeValidated(initial);

      expect(completed.isComplete, isTrue);
      expect(completed.learnerArtifact?['kind'], 'fsa');
      expect(
        completed.learnerArtifact?['document'],
        isNot(equals(completed.canonicalArtifact['document'])),
      );
      expect(
        FaGrammarSessionFactory.compareLearnerArtifact(
          session: completed,
          learnerArtifact: completed.learnerArtifact!,
        ).data!.equivalenceStatus,
        FaGrammarManualEquivalenceStatus.equivalent,
      );
    });
  });

  test('rejects an empty session ID and an already progressed oracle plan', () {
    final emptyId = FaGrammarSessionFactory.fromFa(
      sessionId: '',
      source: _sampleFsa(),
    );
    expect(emptyId.isFailure, isTrue);
    expect(emptyId.error, contains('session needs an ID'));

    final plan = FaGrammarManualOracle.fromFa(_sampleFsa()).data!;
    final obligation = plan.obligations.first;
    final progressed = plan.apply(
      FaGrammarManualAction.mapStateToNonterminal(
        id: 'already-applied',
        stateId: obligation.stateId!,
        nonterminal: obligation.nonterminal!,
      ),
    );
    expect(progressed.isSuccess, isTrue);

    final result = FaGrammarSessionFactory.fromPlan(
      sessionId: 'progressed',
      plan: progressed.plan,
    );
    expect(result.isFailure, isTrue);
    expect(result.error, contains('fresh'));
  });

  test('uses an explicit document generation as the source revision', () {
    final fromFa = FaGrammarSessionFactory.fromFa(
      sessionId: 'fa-revision',
      source: _sampleFsa(),
      sourceRevision: 41,
    );
    final fromGrammar = FaGrammarSessionFactory.fromRightLinearGrammar(
      sessionId: 'grammar-revision',
      source: _rightLinearGrammar(),
      sourceRevision: 73,
    );

    expect(fromFa.data!.source.revision, 41);
    expect(fromGrammar.data!.source.revision, 73);
    expect(
      FaGrammarSessionFactory.fromFa(
        sessionId: 'bad-revision',
        source: _sampleFsa(),
        sourceRevision: -1,
      ).error,
      contains('cannot be negative'),
    );
  });
}

void _expectRequirementEvidence(ManualConversionSession session) {
  expect(session.requirements, isNotEmpty);
  for (final requirement in session.requirements) {
    expect(requirement.expectedPayload, isNotEmpty);
    expect(requirement.allowedPayloadKeys, requirement.expectedPayload.keys);
    expect(requirement.provenanceIds, isNotEmpty);
    expect(requirement.hint, isNotEmpty);
    expect(requirement.revealExplanation, isNotEmpty);
    expect(
      requirement.evidence.certainty,
      ManualConversionCertainty.structural,
    );
    expect(requirement.evidence.summary, isNotEmpty);
    expect(requirement.evidence.provenanceIds, isNotEmpty);
  }
}

ManualConversionSession _complete(ManualConversionSession initial) {
  var session = initial;
  while (!session.isComplete) {
    final requirement = session.currentRequirement!;
    final result = session.apply(
      requirementId: requirement.id,
      type: requirement.type,
      payload: requirement.expectedPayload,
    );
    expect(result.isSuccess, isTrue);
    session = result.session;
  }
  return session;
}

ManualConversionSession _completeValidated(ManualConversionSession initial) {
  var session = initial;
  while (!session.isComplete) {
    final result = FaGrammarSessionFactory.applyLearnerAction(
      session: session,
      payload: session.currentRequirement!.expectedPayload,
    );
    expect(
      result.isSuccess,
      isTrue,
      reason:
          result.diagnostics.isEmpty ? null : result.diagnostics.first.message,
    );
    session = result.session;
  }
  return session;
}

final Matcher _isExternallyValidated = isA<ManualConversionAction>()
    .having(
        (action) => action.validatedExternally, 'validatedExternally', isTrue)
    .having((action) => action.learnerArtifact, 'learnerArtifact', isNotNull)
    .having((action) => action.validationEvidence, 'evidence', isNotNull);

FSA _sampleFsa() {
  final q0 = State(
    id: 'q0',
    label: 'q0',
    position: Vector2.zero(),
    isInitial: true,
    isAccepting: true,
  );
  final q1 = State(id: 'q1', label: 'q1', position: Vector2(100, 0));
  final now = DateTime.utc(2026);
  return FSA(
    id: 'source-fa',
    name: 'Source FA',
    states: {q0, q1},
    transitions: {
      FSATransition.deterministic(
        id: 'a-edge',
        fromState: q1,
        toState: q0,
        symbol: 'a',
      ),
    },
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
