import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/pumping_lemma/pumping_lemma.dart';

void main() {
  group('theorem-specific decompositions', () {
    test('regular decomposition enforces xyz constraints over tokens', () {
      final decomposition = RegularPumpingDecomposition(
        x: const ['a'],
        y: const ['a', 'b'],
        z: const ['b'],
      );

      expect(decomposition.word, ['a', 'a', 'b', 'b']);
      expect(decomposition.validate(pumpingLength: 3), isEmpty);
      expect(decomposition.pump(0), ['a', 'b']);
      expect(decomposition.pump(1), decomposition.word);
      expect(decomposition.pump(2), ['a', 'a', 'b', 'a', 'b', 'b']);
      expect(decomposition.pump(20), hasLength(42));
      expect(
        decomposition.segments.map(
          (segment) =>
              (segment.label, segment.start, segment.end, segment.pumped),
        ),
        [('x', 0, 1, false), ('y', 1, 3, true), ('z', 3, 4, false)],
      );
    });

    test('context-free decomposition enforces uvxyz constraints', () {
      final decomposition = ContextFreePumpingDecomposition(
        u: const ['a'],
        v: const ['a'],
        x: const ['b'],
        y: const ['c'],
        z: const ['c'],
      );

      expect(decomposition.word, ['a', 'a', 'b', 'c', 'c']);
      expect(decomposition.validate(pumpingLength: 3), isEmpty);
      expect(decomposition.pump(0), ['a', 'b', 'c']);
      expect(decomposition.pump(1), decomposition.word);
      expect(decomposition.pump(2), ['a', 'a', 'a', 'b', 'c', 'c', 'c']);
    });

    test('enumerates every token-index decomposition without duplicates', () {
      final regular = PumpingDecompositionEnumerator.regular(
        witness: const ['multi', '🙂', 'z'],
        pumpingLength: 2,
      );
      final contextFree = PumpingDecompositionEnumerator.contextFree(
        witness: const ['multi', '🙂'],
        pumpingLength: 2,
      );

      expect(regular, hasLength(3));
      expect(contextFree, hasLength(9));
      expect(
        regular.map((item) => item.toJson().toString()).toSet(),
        hasLength(regular.length),
      );
      expect(
        contextFree.map((item) => item.toJson().toString()).toSet(),
        hasLength(contextFree.length),
      );
      expect(
        [
          ...regular,
          ...contextFree,
        ].every((item) => item.validate(pumpingLength: 2).isEmpty),
        isTrue,
      );
    });

    test('empty pumping portions and length violations are typed', () {
      final regular = RegularPumpingDecomposition(
        x: const ['a', 'a'],
        y: const [],
        z: const ['b'],
      );
      final contextFree = ContextFreePumpingDecomposition(
        u: const [],
        v: const [],
        x: const ['a', 'b', 'c'],
        y: const [],
        z: const [],
      );

      expect(
        regular.validate(pumpingLength: 1),
        containsAll([
          PumpingDecompositionViolation.emptyPumpedSection,
          PumpingDecompositionViolation.windowExceedsPumpingLength,
        ]),
      );
      expect(
        contextFree.validate(pumpingLength: 2),
        containsAll([
          PumpingDecompositionViolation.emptyPumpedSection,
          PumpingDecompositionViolation.windowExceedsPumpingLength,
        ]),
      );
    });
  });

  group('bounded evidence', () {
    test('finite samples can never be serialized as a proof', () {
      final evidence = PumpingLemmaEvidence.bounded(
        observations: const [
          PumpingExponentObservation(exponent: 0, remainsInLanguage: true),
          PumpingExponentObservation(exponent: 1, remainsInLanguage: true),
          PumpingExponentObservation(exponent: 2, remainsInLanguage: true),
          PumpingExponentObservation(exponent: 3, remainsInLanguage: true),
        ],
      );

      expect(evidence.certainty, PumpingEvidenceCertainty.boundedEvidence);
      expect(evidence.provesUniversalClaim, isFalse);
      expect(
        evidence.disclosureCode,
        'pumping.evidence.finite-sample-not-proof',
      );
      expect(
        PumpingLemmaEvidence.fromJson(evidence.toJson()).provesUniversalClaim,
        isFalse,
      );
    });

    test('a failing exponent is explicit counterexample evidence', () {
      final evidence = PumpingLemmaEvidence.bounded(
        observations: const [
          PumpingExponentObservation(exponent: 0, remainsInLanguage: true),
          PumpingExponentObservation(exponent: 5, remainsInLanguage: false),
        ],
      );

      expect(evidence.certainty, PumpingEvidenceCertainty.counterexample);
      expect(evidence.counterexampleExponent, 5);
    });
  });

  group('problem documents and membership boundary', () {
    test(
      'curated checks stay concrete evidence and examples are separated',
      () {
        final regular = PumpingLemmaProblemCatalog.regular.first;
        final cfl = PumpingLemmaProblemCatalog.contextFree.first;

        expect(regular.theorem, PumpingLemmaTheorem.regular);
        expect(cfl.theorem, PumpingLemmaTheorem.contextFree);
        final accepted = PumpingLemmaProblemCatalog.evaluateCurated(
          regular,
          const ['a', 'a', 'b', 'b'],
        );
        final rejected = PumpingLemmaProblemCatalog.evaluateCurated(
          regular,
          const ['a', 'b', 'b'],
        );
        expect(accepted.isInLanguage, isTrue);
        expect(rejected.isInLanguage, isFalse);
        expect(accepted.isComputationalEvidenceOnly, isTrue);
        expect(accepted.provesUniversalClaim, isFalse);
      },
    );

    test('regular and CFL documents round-trip as distinct runtime types', () {
      final regularProblem = PumpingLemmaProblemCatalog.regular.first;
      final cflProblem = PumpingLemmaProblemCatalog.contextFree.first;
      final regular = RegularPumpingLemmaDocument(
        problem: regularProblem,
        session: PumpingLemmaSession<RegularPumpingDecomposition>(
          sessionId: 'regular',
          challengeId: regularProblem.id,
          sourceRevision: regularProblem.sourceRevision,
          theorem: PumpingLemmaTheorem.regular,
          mode: PumpingLemmaMode.guidedPractice,
          role: PumpingLemmaRole.learner,
          targetLanguage: regularProblem.languageDescription,
        ),
        progress: PumpingLemmaEnvironmentProgress(
          challengeScores: {regularProblem.id: 1},
        ),
      );
      final cfl = ContextFreePumpingLemmaDocument(
        problem: cflProblem,
        session: PumpingLemmaSession<ContextFreePumpingDecomposition>(
          sessionId: 'cfl',
          challengeId: cflProblem.id,
          sourceRevision: cflProblem.sourceRevision,
          theorem: PumpingLemmaTheorem.contextFree,
          mode: PumpingLemmaMode.freeForm,
          role: PumpingLemmaRole.learner,
          targetLanguage: cflProblem.languageDescription,
        ),
        progress: PumpingLemmaEnvironmentProgress(),
      );

      expect(
        PumpingLemmaDocument.fromJson(regular.toJson()),
        isA<RegularPumpingLemmaDocument>(),
      );
      expect(
        PumpingLemmaDocument.fromJson(cfl.toJson()),
        isA<ContextFreePumpingLemmaDocument>(),
      );
    });
  });

  group('session isolation and migration', () {
    test('regular sessions reject context-free decompositions at runtime', () {
      expect(
        () => PumpingLemmaSession<PumpingDecomposition>(
          sessionId: 'regular-session',
          challengeId: 'regular-challenge',
          sourceRevision: 'r1',
          theorem: PumpingLemmaTheorem.regular,
          mode: PumpingLemmaMode.challenge,
          role: PumpingLemmaRole.learner,
          targetLanguage: 'a^n b^n',
          pumpingLength: 2,
          witness: const ['a', 'a', 'b', 'b'],
          decomposition: ContextFreePumpingDecomposition(
            u: const ['a'],
            v: const ['a'],
            x: const [],
            y: const ['b'],
            z: const ['b'],
          ),
        ),
        throwsArgumentError,
      );
    });

    test('stale session updates are rejected and restart clears score', () {
      var nextId = 0;
      final controller = PumpingLemmaSessionController.regular(
        initialSession: PumpingLemmaSession<RegularPumpingDecomposition>(
          sessionId: 'session-0',
          challengeId: 'challenge-0',
          sourceRevision: 'r1',
          theorem: PumpingLemmaTheorem.regular,
          mode: PumpingLemmaMode.challenge,
          role: PumpingLemmaRole.learner,
          targetLanguage: 'a*',
          pumpingLength: 1,
          witness: const ['a'],
          score: 3,
        ),
        sessionIdFactory: () => 'session-${++nextId}',
      );

      expect(
        () => controller.recordRetry(expectedSessionId: 'stale'),
        throwsA(isA<StalePumpingLemmaSessionException>()),
      );

      controller.restart();
      expect(controller.state.sessionId, 'session-1');
      expect(controller.state.score, 0);
      expect(controller.state.history, isEmpty);
    });

    test('quantifier turns cannot be bypassed and scoring happens once', () {
      final controller = PumpingLemmaSessionController.regular(
        initialSession: PumpingLemmaSession<RegularPumpingDecomposition>(
          sessionId: 'turns',
          challengeId: 'equal-blocks',
          sourceRevision: 'r1',
          theorem: PumpingLemmaTheorem.regular,
          mode: PumpingLemmaMode.challenge,
          role: PumpingLemmaRole.learner,
          targetLanguage: 'a^n b^n',
        ),
        sessionIdFactory: () => 'restarted',
      );

      expect(controller.state.currentPlayer, PumpingLemmaPlayer.opponent);
      expect(
        () => controller.chooseWitness(
          expectedSessionId: 'turns',
          player: PumpingLemmaPlayer.learner,
          witness: const ['a'],
          isInLanguage: true,
        ),
        throwsA(isA<PumpingLemmaTransitionException>()),
      );
      controller.choosePumpingLength(
        expectedSessionId: 'turns',
        player: PumpingLemmaPlayer.opponent,
        pumpingLength: 2,
      );
      controller.chooseWitness(
        expectedSessionId: 'turns',
        player: PumpingLemmaPlayer.learner,
        witness: const ['a', 'a', 'b', 'b'],
        isInLanguage: true,
      );
      controller.chooseDecomposition(
        expectedSessionId: 'turns',
        player: PumpingLemmaPlayer.opponent,
        decomposition: RegularPumpingDecomposition(
          x: const [],
          y: const ['a'],
          z: const ['a', 'b', 'b'],
        ),
      );
      controller.chooseExponent(
        expectedSessionId: 'turns',
        player: PumpingLemmaPlayer.learner,
        exponent: 0,
      );
      controller.recordEvidence(
        expectedSessionId: 'turns',
        player: PumpingLemmaPlayer.learner,
        evidence: PumpingLemmaEvidence.bounded(
          observations: const [
            PumpingExponentObservation(exponent: 0, remainsInLanguage: false),
          ],
        ),
      );
      controller.complete(expectedSessionId: 'turns', scoreDelta: 1);

      expect(controller.state.score, 1);
      expect(controller.state.stage, PumpingLemmaStage.completed);
      expect(
        () => controller.complete(expectedSessionId: 'turns', scoreDelta: 1),
        throwsA(isA<PumpingLemmaTransitionException>()),
      );
      expect(controller.state.score, 1);
      final decoded = PumpingLemmaSession<RegularPumpingDecomposition>.fromJson(
        controller.state.toJson(),
      );
      expect(decoded.stage, PumpingLemmaStage.completed);
      expect(decoded.pumpedWord, ['a', 'b', 'b']);
      expect(decoded.history.map((turn) => turn.kind), [
        PumpingLemmaTurnKind.pumpingLengthChosen,
        PumpingLemmaTurnKind.witnessChosen,
        PumpingLemmaTurnKind.decompositionChosen,
        PumpingLemmaTurnKind.exponentChosen,
        PumpingLemmaTurnKind.evidenceRecorded,
        PumpingLemmaTurnKind.completed,
      ]);
    });

    test('legacy migration keeps only theorem-tagged challenges', () {
      final result = PumpingLemmaProgressMigration.migrate({
        'version': 1,
        'challenges': [
          {'id': 'regular-1', 'theorem': 'regular', 'score': 2},
          {'id': 'cfl-1', 'theorem': 'contextFree', 'score': 4},
          {'id': 'unknown-1', 'score': 99},
        ],
      });

      expect(result.snapshot.regular.challengeScores, {'regular-1': 2});
      expect(result.snapshot.contextFree.challengeScores, {'cfl-1': 4});
      expect(result.discardedChallengeIds, ['unknown-1']);
      expect(result.requiresUserNotice, isTrue);
      expect(
        PumpingLemmaProgressSnapshot.fromJson(result.snapshot.toJson()),
        result.snapshot,
      );
    });

    test('content migration keeps only progress for the current version', () {
      final progress = PumpingLemmaEnvironmentProgress(
        challengeScores: const {
          'regular.current': 2,
          'regular.changed': 3,
          'regular.removed': 5,
        },
        completedChallengeIds: const {
          'regular.current',
          'regular.changed',
          'regular.removed',
        },
        challengeContentVersions: const {
          'regular.current': 1,
          'regular.changed': 1,
          'regular.removed': 1,
        },
      );

      final result = PumpingLemmaContentMigration.reconcile(
        progress: progress,
        currentContentVersions: const {
          'regular.current': 1,
          'regular.changed': 2,
        },
      );

      expect(result.progress.challengeScores, {'regular.current': 2});
      expect(result.progress.completedChallengeIds, {'regular.current'});
      expect(result.progress.challengeContentVersions, {'regular.current': 1});
      expect(result.discardedChallengeIds, [
        'regular.changed',
        'regular.removed',
      ]);
      expect(result.changed, isTrue);
    });

    test(
      'legacy progress without content versions migrates as version one',
      () {
        final legacy = PumpingLemmaEnvironmentProgress.fromJson({
          'challengeScores': {'regular.current': 2},
          'completedChallengeIds': ['regular.current'],
        });

        expect(legacy.challengeContentVersions, {'regular.current': 1});
        final result = PumpingLemmaContentMigration.reconcile(
          progress: legacy,
          currentContentVersions: const {'regular.current': 1},
        );
        expect(result.changed, isFalse);
        expect(result.progress, legacy);
      },
    );
  });
}
