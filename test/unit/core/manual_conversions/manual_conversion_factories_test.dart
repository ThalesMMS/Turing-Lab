import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:turing_lab/core/manual_conversions/manual_conversion_factories.dart';
import 'package:turing_lab/core/manual_conversions/manual_conversion_session.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/state.dart';

void main() {
  group('ManualConversionFactories.faToRegex', () {
    test('builds a complete canonical trace with exact evidence', () {
      final session = ManualConversionFactories.faToRegex(
        source: _chainFsa(),
        sourceRevision: 12,
      );

      expect(session.direction, ManualConversionDirection.faToRegex);
      expect(session.source.documentId, 'factory-source');
      expect(session.source.revision, 12);
      expect(session.status, ManualConversionStatus.active);
      expect(session.currentRequirement!.type,
          ManualConversionActionType.normalizeEndpoints);
      expect(session.canonicalArtifact['regex'], 'ab');
      expect(session.canonicalArtifact['exactEquivalent'], isTrue);
      expect(
        session.canonicalArtifact['eliminationOrder'],
        ['q0', 'q1', 'q2'],
      );
      expect(
        session.completionEvidence.certainty,
        ManualConversionCertainty.exact,
      );

      var completed = session;
      while (!completed.isComplete) {
        final result = completed.revealCurrent();
        expect(result.isSuccess, isTrue);
        completed = result.session;
      }
      expect(completed.cursor, completed.requirements.length);
      expect(completed.revealedCount, completed.requirements.length);
      expect(
        completed.actions.last.payload,
        {'regex': 'ab'},
      );
    });

    test('carries formula provenance and keeps hints read-only', () {
      final session = ManualConversionFactories.faToRegex(
        source: _parallelFsa(),
        sourceRevision: 3,
      );
      final pairRequirement = session.requirements.firstWhere(
        (requirement) =>
            requirement.type == ManualConversionActionType.submitPairExpression,
      );

      expect(pairRequirement.expectedPayload['expression'], '(a|b)');
      expect(
        pairRequirement.provenanceIds,
        containsAll(['q0', 'q1']),
      );
      expect(
        pairRequirement.provenanceIds.any((id) => id.startsWith('r0:')),
        isTrue,
      );
      expect(pairRequirement.hint, isNot(contains('(a|b)')));
      expect(pairRequirement.supportingData, {
        'selectedStateId': 'q0',
        'fromStateId': '__gnfa_start__',
        'toStateId': 'q1',
        'directExpression': '∅',
        'incomingExpression': 'ε',
        'loopExpression': '∅',
        'outgoingExpression': '(a|b)',
        'formula': 'R_ij ∪ R_ik(R_kk)*R_kj',
      });
      expect(
        () => pairRequirement.supportingData['formula'] = 'wrong',
        throwsUnsupportedError,
      );
      expect(pairRequirement.revealExplanation, contains('(a|b)'));
      expect(
        pairRequirement.evidence.certainty,
        ManualConversionCertainty.exact,
      );
    });

    test('rebases the trace when the learner chooses another state', () {
      final source = _chainFsa();
      var session = ManualConversionFactories.faToRegex(
        source: source,
        sourceRevision: 4,
      );
      session = session.revealCurrent().session;

      final selection = ManualConversionFactories.applyFaToRegexLearnerStep(
        source: source,
        session: session,
        payload: const {'stateId': 'q2'},
      );
      expect(selection.isSuccess, isTrue);
      expect(selection.session.appliedActions.last.validatedExternally, isTrue);

      session = ManualConversionFactories.rebaseFaToRegexSelection(
        source: source,
        sourceRevision: 4,
        acceptedSession: selection.session,
      );

      expect(session.appliedActions.last.payload, const {'stateId': 'q2'});
      expect(
        session.canonicalArtifact['eliminationOrder'],
        ['q2', 'q0', 'q1'],
      );
      expect(
        session.currentRequirement!.provenanceIds,
        contains('q2'),
      );
      expect(session.revealedCount, 1);
    });

    test('accepts an equivalent learner pair label and keeps its syntax', () {
      final source = _parallelFsa();
      var session = ManualConversionFactories.faToRegex(
        source: source,
        sourceRevision: 8,
      );
      for (var index = 0; index < 2; index++) {
        final requirement = session.currentRequirement!;
        final result = ManualConversionFactories.applyFaToRegexLearnerStep(
          source: source,
          session: session,
          payload: requirement.expectedPayload,
        );
        expect(result.isSuccess, isTrue);
        session = result.session;
      }
      final pairRequirement = session.currentRequirement!;
      expect(pairRequirement.type,
          ManualConversionActionType.submitPairExpression);
      final payload = Map<String, Object?>.from(
        pairRequirement.expectedPayload,
      )..['expression'] = '(b|a)';

      final result = ManualConversionFactories.applyFaToRegexLearnerStep(
        source: source,
        session: session,
        payload: payload,
      );

      expect(result.isSuccess, isTrue);
      expect(result.session.appliedActions.last.payload['expression'], '(b|a)');
      expect(
        result.session.latestEvidence!.summary,
        contains('language-equivalent'),
      );
      expect(
        result.session.learnerArtifact!['pairLabels'],
        contains(
          containsPair('expression', '(b|a)'),
        ),
      );
    });

    test('keeps an equivalent learner regex as the completed result', () {
      final source = _chainFsa();
      var session = ManualConversionFactories.faToRegex(
        source: source,
        sourceRevision: 10,
      );
      while (session.currentRequirement!.type !=
          ManualConversionActionType.complete) {
        session = session.revealCurrent().session;
      }

      final result = ManualConversionFactories.applyFaToRegexLearnerStep(
        source: source,
        session: session,
        payload: const {'regex': '(ab)'},
      );

      expect(result.isSuccess, isTrue);
      expect(result.session.isComplete, isTrue);
      expect(result.session.learnerArtifact!['regex'], '(ab)');
      expect(
        result.session.latestEvidence!.certainty,
        ManualConversionCertainty.exact,
      );
    });

    test('is deterministic across source set insertion order', () {
      final first = ManualConversionFactories.faToRegex(
        source: _chainFsa(reverseInsertion: false),
        sourceRevision: 5,
      );
      final second = ManualConversionFactories.faToRegex(
        source: _chainFsa(reverseInsertion: true),
        sourceRevision: 5,
      );

      expect(first.id, second.id);
      expect(first.source.toJson(), second.source.toJson());
      expect(first.canonicalArtifact, second.canonicalArtifact);
      expect(
        first.requirements.map((requirement) => requirement.toJson()),
        second.requirements.map((requirement) => requirement.toJson()),
      );
    });

    test('persists and restores the generated session', () {
      var session = ManualConversionFactories.faToRegex(
        source: _chainFsa(),
        sourceRevision: 9,
        sessionId: 'practice-fa-regex',
      );
      session = session.revealCurrent().session;
      session = session.revealCurrent().session;

      final restored = ManualConversionSession.restore(
        session.toJson(),
        documentId: 'factory-source',
        revision: 9,
      );

      expect(restored.isSuccess, isTrue);
      expect(restored.session!.toJson(), session.toJson());
      expect(restored.session!.id, 'practice-fa-regex');
      expect(
        restored.session!.requirements
            .firstWhere(
              (requirement) =>
                  requirement.type ==
                  ManualConversionActionType.submitPairExpression,
            )
            .supportingData['formula'],
        'R_ij ∪ R_ik(R_kk)*R_kj',
      );
    });

    test('freezes the source snapshot and canonical artifact', () {
      final session = ManualConversionFactories.faToRegex(
        source: _chainFsa(),
        sourceRevision: 1,
      );

      expect(
        () => session.source.snapshot['extra'] = true,
        throwsUnsupportedError,
      );
      final artifact = session.canonicalArtifact;
      expect(
        () => artifact['regex'] = 'wrong',
        throwsUnsupportedError,
      );
      final normalized = artifact['normalizedGnfa']! as Map<String, Object?>;
      expect(
        () => normalized['revision'] = 999,
        throwsUnsupportedError,
      );
    });

    test('rejects a negative source revision', () {
      expect(
        () => ManualConversionFactories.faToRegex(
          source: _chainFsa(),
          sourceRevision: -1,
        ),
        throwsArgumentError,
      );
    });
  });
}

FSA _chainFsa({bool reverseInsertion = false}) {
  final q0 = _state('q0', initial: true);
  final q1 = _state('q1');
  final q2 = _state('q2', accepting: true);
  final states = reverseInsertion ? {q2, q1, q0} : {q0, q1, q2};
  final transitions = reverseInsertion
      ? {
          _transition('t1', q1, q2, 'b'),
          _transition('t0', q0, q1, 'a'),
        }
      : {
          _transition('t0', q0, q1, 'a'),
          _transition('t1', q1, q2, 'b'),
        };
  return _fsa(
    states: states,
    transitions: transitions,
    initial: q0,
    accepting: {q2},
    alphabet: {'a', 'b'},
  );
}

FSA _parallelFsa() {
  final q0 = _state('q0', initial: true);
  final q1 = _state('q1', accepting: true);
  return _fsa(
    states: {q0, q1},
    transitions: {
      _transition('a', q0, q1, 'a'),
      _transition('b', q0, q1, 'b'),
    },
    initial: q0,
    accepting: {q1},
    alphabet: {'a', 'b'},
  );
}

State _state(
  String id, {
  bool initial = false,
  bool accepting = false,
}) {
  return State(
    id: id,
    label: id,
    position: Vector2.zero(),
    isInitial: initial,
    isAccepting: accepting,
  );
}

FSATransition _transition(
  String id,
  State from,
  State to,
  String symbol,
) {
  return FSATransition.deterministic(
    id: id,
    fromState: from,
    toState: to,
    symbol: symbol,
  );
}

FSA _fsa({
  required Set<State> states,
  required Set<FSATransition> transitions,
  required State initial,
  required Set<State> accepting,
  required Set<String> alphabet,
}) {
  final timestamp = DateTime.utc(2026, 8, 25);
  return FSA(
    id: 'factory-source',
    name: 'Factory source',
    states: states,
    transitions: transitions,
    alphabet: alphabet,
    initialState: initial,
    acceptingStates: accepting,
    created: timestamp,
    modified: timestamp,
    bounds: const math.Rectangle<double>(0, 0, 800, 600),
  );
}
