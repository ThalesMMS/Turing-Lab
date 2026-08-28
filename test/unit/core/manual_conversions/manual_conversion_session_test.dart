import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/manual_conversions/manual_conversion_content.dart';
import 'package:turing_lab/core/manual_conversions/manual_conversion_session.dart';

void main() {
  group('ManualConversionSession', () {
    late ManualConversionSession session;

    setUp(() {
      session = ManualConversionSession.start(
        id: 'manual-1',
        direction: ManualConversionDirection.faToRegex,
        source: ManualConversionSource(
          documentId: 'fa-1',
          revision: 7,
          snapshot: const {
            'states': ['q0', 'q1'],
          },
        ),
        requirements: [
          ManualConversionRequirement(
            id: 'normalize',
            contentReference: ManualConversionContent.faToRegexNormalize,
            type: ManualConversionActionType.normalizeEndpoints,
            title: 'Normalize endpoints',
            instruction: 'Add a unique start and final state.',
            expectedPayload: const {'initial': 'qi', 'final': 'qf'},
            allowedPayloadKeys: const {'initial', 'final'},
            provenanceIds: const ['q0', 'q1'],
            hint: 'The old initial state needs an incoming epsilon edge.',
            revealExplanation: 'Fresh endpoints protect both boundary states.',
            evidence: ManualConversionEvidence(
              summary: 'The GNFA has protected endpoints.',
            ),
          ),
          ManualConversionRequirement(
            id: 'eliminate-q0',
            contentReference: ManualConversionContent.faToRegexSelectState,
            type: ManualConversionActionType.selectState,
            title: 'Select a state',
            instruction: 'Select an internal state to eliminate.',
            expectedPayload: const {'stateId': 'q0'},
            acceptedPayloads: const [
              {'stateId': 'q1'},
            ],
            allowedPayloadKeys: const {'stateId'},
            provenanceIds: const ['q0'],
            hint: 'Start or final states cannot be eliminated.',
            revealExplanation: 'q0 is a valid internal state.',
            evidence: ManualConversionEvidence(
              summary: 'The selected state is eliminable.',
            ),
          ),
        ],
        canonicalArtifact: const {'regex': 'a*'},
        completionEvidence: ManualConversionEvidence(
          summary: 'The resulting regex is exactly equivalent.',
          certainty: ManualConversionCertainty.exact,
        ),
      );
    });

    test(
      'validates ordering, type and payload without mutating on failure',
      () {
        final outOfOrder = session.apply(
          requirementId: 'eliminate-q0',
          type: ManualConversionActionType.selectState,
          payload: const {'stateId': 'q0'},
        );
        expect(outOfOrder.isSuccess, isFalse);
        expect(outOfOrder.session, same(session));
        expect(
          outOfOrder.diagnostics.single.code,
          ManualConversionDiagnosticCode.actionOutOfOrder,
        );

        final invalid = session.apply(
          requirementId: 'normalize',
          type: ManualConversionActionType.normalizeEndpoints,
          payload: const {'initial': 'q0', 'final': 'q1'},
        );
        expect(invalid.isSuccess, isFalse);
        expect(invalid.session.cursor, 0);
      },
    );

    test('supports accepted alternatives, undo, redo and redo truncation', () {
      var current = session
          .apply(
            requirementId: 'normalize',
            type: ManualConversionActionType.normalizeEndpoints,
            payload: const {'initial': 'qi', 'final': 'qf'},
          )
          .session;
      current = current
          .apply(
            requirementId: 'eliminate-q0',
            type: ManualConversionActionType.selectState,
            payload: const {'stateId': 'q1'},
          )
          .session;
      expect(current.isComplete, isTrue);

      current = current.undo().session;
      expect(current.canRedo, isTrue);
      current = current
          .apply(
            requirementId: 'eliminate-q0',
            type: ManualConversionActionType.selectState,
            payload: const {'stateId': 'q0'},
          )
          .session;
      expect(current.isComplete, isTrue);
      expect(current.canRedo, isFalse);
      expect(current.actions.last.payload, {'stateId': 'q0'});
    });

    test('hint is read-only and reveal is explicit evidence', () {
      final hint = session.currentRequirement!.hint;
      expect(hint, contains('epsilon'));
      expect(session.cursor, 0);

      final revealed = session.revealCurrent();
      expect(revealed.isSuccess, isTrue);
      expect(revealed.session.cursor, 1);
      expect(revealed.session.revealedCount, 1);
      expect(revealed.session.actions.single.revealed, isTrue);
    });

    test('branches at the cursor and records lineage', () {
      final applied = session
          .apply(
            requirementId: 'normalize',
            type: ManualConversionActionType.normalizeEndpoints,
            payload: const {'initial': 'qi', 'final': 'qf'},
          )
          .session;
      final branch = applied.branch(branchId: 'manual-1-branch');

      expect(branch.id, 'manual-1-branch');
      expect(branch.parentSessionId, 'manual-1');
      expect(branch.parentCursor, 1);
      expect(branch.appliedActions, hasLength(1));
    });

    test('round-trips and rejects another source revision', () {
      final applied = session.revealCurrent().session;
      final restored = ManualConversionSession.restore(
        applied.toJson(),
        documentId: 'fa-1',
        revision: 7,
      );
      expect(restored.isSuccess, isTrue);
      expect(restored.session!.toJson(), applied.toJson());

      final stale = ManualConversionSession.restore(
        applied.toJson(),
        documentId: 'fa-1',
        revision: 8,
      );
      expect(stale.isSuccess, isFalse);
      expect(
        stale.diagnostics.single.code,
        ManualConversionDiagnosticCode.sourceChanged,
      );
    });

    test('migrates missing content references and rejects contract drift', () {
      final legacyJson = Map<String, Object?>.from(session.toJson());
      final legacyRequirements = (legacyJson['requirements'] as List)
          .map((value) => Map<String, Object?>.from(value as Map))
          .toList();
      legacyRequirements.first.remove('content');
      legacyJson['requirements'] = legacyRequirements;

      final migrated = ManualConversionSession.restore(
        legacyJson,
        documentId: 'fa-1',
        revision: 7,
      );

      expect(migrated.isSuccess, isTrue);
      expect(
        migrated.session!.requirements.first.contentReference,
        ManualConversionContent.legacy,
      );

      final driftedJson = Map<String, Object?>.from(session.toJson());
      final driftedRequirements = (driftedJson['requirements'] as List)
          .map((value) => Map<String, Object?>.from(value as Map))
          .toList();
      final content = Map<String, Object?>.from(
        driftedRequirements.first['content'] as Map,
      );
      content['version'] = 2;
      driftedRequirements.first['content'] = content;
      driftedJson['requirements'] = driftedRequirements;

      final drifted = ManualConversionSession.restore(
        driftedJson,
        documentId: 'fa-1',
        revision: 7,
      );
      expect(drifted.isSuccess, isFalse);
      expect(
        drifted.diagnostics.single.code,
        ManualConversionDiagnosticCode.malformedPayload,
      );
    });

    test('source invalidation blocks further construction', () {
      final invalidated = session.checkSource(documentId: 'fa-1', revision: 8);
      expect(invalidated.status, ManualConversionStatus.invalidated);
      expect(
        invalidated.revealCurrent().diagnostics.single.code,
        ManualConversionDiagnosticCode.sourceChanged,
      );
    });

    test('source invalidation cannot be cleared by undo, redo, or restart', () {
      final applied = session
          .apply(
            requirementId: 'normalize',
            type: ManualConversionActionType.normalizeEndpoints,
            payload: const {'initial': 'qi', 'final': 'qf'},
          )
          .session;
      final invalidated = applied.checkSource(documentId: 'fa-1', revision: 8);

      expect(invalidated.canUndo, isFalse);
      final undo = invalidated.undo();
      expect(undo.isSuccess, isFalse);
      expect(undo.session, same(invalidated));
      expect(
        undo.diagnostics.single.code,
        ManualConversionDiagnosticCode.sourceChanged,
      );
      expect(invalidated.restart(), same(invalidated));

      final withRedo = applied.undo().session.checkSource(
        documentId: 'fa-1',
        revision: 8,
      );
      expect(withRedo.canRedo, isFalse);
      final redo = withRedo.redo();
      expect(redo.isSuccess, isFalse);
      expect(redo.session.status, ManualConversionStatus.invalidated);
      expect(
        redo.diagnostics.single.code,
        ManualConversionDiagnosticCode.sourceChanged,
      );
    });

    test('restarts or branches immutably from a fresh source contract', () {
      final applied = session.revealCurrent().session;
      final invalidated = applied.checkSource(documentId: 'fa-1', revision: 8);
      final fresh = _freshReplacement(session, revision: 8);

      final restarted = invalidated.restartFromNewSource(freshSession: fresh);
      expect(restarted.id, invalidated.id);
      expect(restarted.source.revision, 8);
      expect(restarted.status, ManualConversionStatus.active);
      expect(restarted.actions, isEmpty);
      expect(restarted.parentSessionId, isNull);

      final branch = invalidated.branchFromNewSource(
        branchId: 'manual-1-new-source',
        freshSession: fresh,
      );
      expect(branch.id, 'manual-1-new-source');
      expect(branch.source.revision, 8);
      expect(branch.status, ManualConversionStatus.active);
      expect(branch.actions, isEmpty);
      expect(branch.parentSessionId, invalidated.id);
      expect(branch.parentCursor, invalidated.cursor);
      expect(invalidated.status, ManualConversionStatus.invalidated);
      expect(invalidated.source.revision, 7);
    });

    test('stores externally validated learner evidence and artifact', () {
      const learnerPayload = {
        'initial': 'learner-start',
        'final': 'learner-final',
        'layout': 'custom',
      };
      final evidence = ManualConversionEvidence(
        summary: 'The oracle accepted the learner construction.',
        certainty: ManualConversionCertainty.exact,
        provenanceIds: const ['q0', 'q1'],
      );

      final ordinary = session.apply(
        requirementId: 'normalize',
        type: ManualConversionActionType.normalizeEndpoints,
        payload: learnerPayload,
      );
      expect(ordinary.isSuccess, isFalse);

      final validated = session.applyValidated(
        requirementId: 'normalize',
        type: ManualConversionActionType.normalizeEndpoints,
        payload: learnerPayload,
        validationEvidence: evidence,
        learnerArtifact: const {
          'kind': 'fsa',
          'states': ['learner-start'],
        },
      );

      expect(validated.isSuccess, isTrue);
      final current = validated.session;
      final action = current.appliedActions.single;
      expect(action.validatedExternally, isTrue);
      expect(action.payload, learnerPayload);
      expect(action.validationEvidence!.summary, evidence.summary);
      expect(action.learnerArtifact, {
        'kind': 'fsa',
        'states': ['learner-start'],
      });
      expect(current.latestEvidence!.summary, evidence.summary);
      expect(current.learnerArtifact, action.learnerArtifact);

      final undone = current.undo().session;
      expect(undone.latestEvidence, isNull);
      expect(undone.learnerArtifact, isNull);
      final redone = undone.redo().session;
      expect(redone.latestEvidence!.summary, evidence.summary);
      expect(redone.learnerArtifact, action.learnerArtifact);

      final restored = ManualConversionSession.restore(
        redone.toJson(),
        documentId: 'fa-1',
        revision: 7,
      );
      expect(restored.isSuccess, isTrue);
      expect(restored.session!.toJson(), redone.toJson());
      expect(restored.session!.latestEvidence!.summary, evidence.summary);

      final revealed = current.markLatestActionRevealed();
      expect(revealed.appliedActions.single.revealed, isTrue);
      expect(revealed.learnerArtifact, current.learnerArtifact);
      expect(revealed.latestEvidence!.summary, evidence.summary);
      expect(current.appliedActions.single.revealed, isFalse);
    });

    test('external validation keeps status, ordering, and type checks', () {
      final evidence = ManualConversionEvidence(summary: 'Oracle accepted.');
      final outOfOrder = session.applyValidated(
        requirementId: 'eliminate-q0',
        type: ManualConversionActionType.selectState,
        payload: const {'stateId': 'custom'},
        validationEvidence: evidence,
        learnerArtifact: const {'regex': 'custom'},
      );
      expect(
        outOfOrder.diagnostics.single.code,
        ManualConversionDiagnosticCode.actionOutOfOrder,
      );

      final wrongType = session.applyValidated(
        requirementId: 'normalize',
        type: ManualConversionActionType.complete,
        payload: const {'custom': true},
        validationEvidence: evidence,
        learnerArtifact: const {'regex': 'custom'},
      );
      expect(
        wrongType.diagnostics.single.code,
        ManualConversionDiagnosticCode.actionTypeMismatch,
      );

      final invalidated = session.checkSource(documentId: 'fa-1', revision: 8);
      final stale = invalidated.applyValidated(
        requirementId: 'normalize',
        type: ManualConversionActionType.normalizeEndpoints,
        payload: const {'custom': true},
        validationEvidence: evidence,
        learnerArtifact: const {'regex': 'custom'},
      );
      expect(
        stale.diagnostics.single.code,
        ManualConversionDiagnosticCode.sourceChanged,
      );
    });

    test(
      'malformed restored actions return diagnostics instead of throwing',
      () {
        final encoded = session.toJson();
        encoded['actions'] = [
          {
            'id': 'bad-action',
            'requirementId': 'normalize',
            'type': ManualConversionActionType.normalizeEndpoints.name,
            'payload': const {'unexpected': true},
            'revealed': false,
            'validatedExternally': true,
            'validationEvidence': null,
            'learnerArtifact': null,
          },
        ];
        encoded['cursor'] = 1;

        final restored = ManualConversionSession.restore(
          encoded,
          documentId: 'fa-1',
          revision: 7,
        );

        expect(restored.isSuccess, isFalse);
        expect(
          restored.diagnostics.single.code,
          ManualConversionDiagnosticCode.malformedPayload,
        );

        final partial = session.toJson();
        partial['actions'] = [
          {
            'id': 'partial-action',
            'requirementId': 'normalize',
            'type': ManualConversionActionType.normalizeEndpoints.name,
            'payload': const {'initial': 'qi', 'final': 'qf'},
            'revealed': false,
            'validatedExternally': false,
            'validationEvidence': ManualConversionEvidence(
              summary: 'Unexpected evidence.',
            ).toJson(),
            'learnerArtifact': null,
          },
        ];
        partial['cursor'] = 1;

        final partialRestore = ManualConversionSession.restore(
          partial,
          documentId: 'fa-1',
          revision: 7,
        );
        expect(partialRestore.isSuccess, isFalse);
        expect(
          partialRestore.diagnostics.single.code,
          ManualConversionDiagnosticCode.malformedPayload,
        );
      },
    );
  });
}

ManualConversionSession _freshReplacement(
  ManualConversionSession template, {
  required int revision,
}) {
  return ManualConversionSession.start(
    id: 'fresh-contract',
    direction: template.direction,
    source: ManualConversionSource(
      documentId: template.source.documentId,
      revision: revision,
      snapshot: const {
        'states': ['new-q0'],
      },
    ),
    requirements: template.requirements,
    canonicalArtifact: const {'regex': 'b*'},
    completionEvidence: ManualConversionEvidence(
      summary: 'The replacement contract is exactly equivalent.',
      certainty: ManualConversionCertainty.exact,
    ),
  );
}
