import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/language_comparator.dart';
import 'package:turing_lab/core/algorithms/regex_to_nfa_converter.dart';
import 'package:turing_lab/core/manual_conversions/manual_conversion_session.dart';
import 'package:turing_lab/core/manual_conversions/regex_to_fa_session_factory.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/regex_document.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  group('RegexToFaSessionFactory', () {
    test('creates postorder requirements with AST spans and preconditions', () {
      final session = RegexToFaSessionFactory.create(
        source: _document('(a|b)*'),
        sourceRevision: 7,
      );

      expect(session.direction, ManualConversionDirection.regexToFa);
      expect(
        session.requirements.map((requirement) => requirement.type),
        [
          ManualConversionActionType.createBaseFragment,
          ManualConversionActionType.createBaseFragment,
          ManualConversionActionType.combineUnion,
          ManualConversionActionType.applyKleeneStar,
        ],
      );
      expect(
        session.requirements.map(
          (requirement) => requirement.expectedPayload['nodeId'],
        ),
        ['ast_root_0_0', 'ast_root_0_1', 'ast_root_0', 'ast_root'],
      );

      final union = session.requirements[2];
      expect(union.expectedPayload['sourceSpan'], {'start': 0, 'end': 5});
      expect(
        union.expectedPayload['preconditions'],
        {
          'postorderChildNodeIds': ['ast_root_0_0', 'ast_root_0_1'],
          'childrenComplete': true,
        },
      );
      expect(
        union.provenanceIds,
        containsAll(['ast_root_0', 'source:0-5']),
      );
      expect(union.hint, contains('does not change the learner artifact'));
      expect(union.evidence.certainty, ManualConversionCertainty.structural);
    });

    test('enforces order, action type, and canonical structural payload', () {
      var session = RegexToFaSessionFactory.create(
        source: _document('a|b'),
        sourceRevision: 1,
      );

      final later = session.requirements.last;
      final outOfOrder = session.apply(
        requirementId: later.id,
        type: later.type,
        payload: later.expectedPayload,
      );
      expect(outOfOrder.isSuccess, isFalse);
      expect(
        outOfOrder.diagnostics.single.code,
        ManualConversionDiagnosticCode.actionOutOfOrder,
      );

      final first = session.currentRequirement!;
      final wrongType = session.apply(
        requirementId: first.id,
        type: ManualConversionActionType.combineUnion,
        payload: first.expectedPayload,
      );
      expect(wrongType.isSuccess, isFalse);
      expect(
        wrongType.diagnostics.single.code,
        ManualConversionDiagnosticCode.actionTypeMismatch,
      );

      final invalidPayload = Map<String, Object?>.from(first.expectedPayload);
      invalidPayload['nodeId'] = 'another-node';
      final invalid = session.apply(
        requirementId: first.id,
        type: first.type,
        payload: invalidPayload,
      );
      expect(invalid.isSuccess, isFalse);
      expect(
        invalid.diagnostics.single.code,
        ManualConversionDiagnosticCode.invalidPayload,
      );

      for (final requirement in session.requirements) {
        final result = session.apply(
          requirementId: requirement.id,
          type: requirement.type,
          payload: requirement.expectedPayload,
        );
        expect(result.isSuccess, isTrue, reason: requirement.id);
        session = result.session;
      }
      expect(session.isComplete, isTrue);
    });

    test('publishes canonical FSA JSON and exact completion evidence', () {
      final document = _document('(a|b)*');
      final session = RegexToFaSessionFactory.create(
        source: document,
        sourceRevision: 2,
      );
      final artifact = session.canonicalArtifact;

      expect(artifact['schema'], 'turing-lab.regex-to-fa-canonical');
      expect(artifact['version'], 1);
      expect(
        artifact['postorderNodeIds'],
        ['ast_root_0_0', 'ast_root_0_1', 'ast_root_0', 'ast_root'],
      );
      expect(
        (artifact['structuralEvidence'] as List).length,
        session.requirements.length,
      );
      final exactCompletion = artifact['exactCompletion'] as Map;
      expect(exactCompletion['isEquivalent'], isTrue);
      expect(exactCompletion['counterexample'], isNull);
      expect(
        exactCompletion['oracle'],
        'LanguageComparator.compareLanguages',
      );

      final canonical = FSA.fromJson(
        Map<String, dynamic>.from(artifact['fsa']! as Map),
      );
      final automatic = RegexToNFAConverter.convert(
        document.source,
        contextAlphabet: document.alphabet.toSet(),
      );
      expect(automatic.isSuccess, isTrue);
      final comparison = LanguageComparator.compareLanguages(
        canonical,
        automatic.data!,
      );
      expect(comparison.isSuccess, isTrue);
      expect(comparison.data!.isEquivalent, isTrue);
      expect(comparison.data!.distinguishingString, isNull);
      expect(
        session.completionEvidence.certainty,
        ManualConversionCertainty.exact,
      );
      expect(session.completionEvidence.counterexample, isNull);
    });

    test('accepts and persists isomorphic learner fragments with real evidence',
        () {
      final document = _document('(a|b)*');
      var session = RegexToFaSessionFactory.create(
        source: document,
        sourceRevision: 4,
      );

      for (var index = 0; index < session.requirements.length; index++) {
        final requirement = session.currentRequirement!;
        final canonical = FSA.fromJson(
          Map<String, dynamic>.from(
            requirement.expectedPayload['fragment']! as Map,
          ),
        );
        final learner = _rename(canonical, 'learner_$index');
        final result = RegexToFaSessionFactory.applyLearnerFragment(
          session: session,
          fragment: learner,
        );

        expect(result.isSuccess, isTrue, reason: requirement.id);
        session = result.session;
        final action = session.appliedActions.last;
        expect(action.validatedExternally, isTrue);
        expect(action.payload['fragment'], learner.toJson());
        expect(action.validationEvidence, isNotNull);
        expect(action.learnerArtifact!['fsa'], learner.toJson());
      }

      expect(session.isComplete, isTrue);
      expect(
          session.latestEvidence!.certainty, ManualConversionCertainty.exact);
      expect(session.latestEvidence!.counterexample, isNull);
      final finalLearner = session.learnerArtifact!;
      expect(
        (finalLearner['exactCompletion'] as Map)['isEquivalent'],
        isTrue,
      );
      expect(
        finalLearner['fsa'],
        session.appliedActions.last.payload['fragment'],
      );
      expect(
        finalLearner['fsa'],
        isNot(session.canonicalArtifact['fsa']),
      );

      final restored = ManualConversionSession.restore(
        session.toJson(),
        documentId: document.id,
        revision: 4,
      );
      expect(restored.isSuccess, isTrue);
      expect(restored.session!.learnerArtifact, finalLearner);
      expect(
        restored.session!.latestEvidence!.certainty,
        ManualConversionCertainty.exact,
      );
    });

    test('rejects a non-isomorphic learner fragment without recording it', () {
      final session = RegexToFaSessionFactory.create(
        source: _document('a'),
        sourceRevision: 1,
      );
      final expected = FSA.fromJson(
        Map<String, dynamic>.from(
          session.currentRequirement!.expectedPayload['fragment']! as Map,
        ),
      );
      final invalid = expected.copyWith(transitions: <FSATransition>{});

      final result = RegexToFaSessionFactory.applyLearnerFragment(
        session: session,
        fragment: invalid,
      );

      expect(result.isSuccess, isFalse);
      expect(
        result.diagnostics.single.code,
        ManualConversionDiagnosticCode.invalidPayload,
      );
      expect(result.session.actions, isEmpty);
      expect(result.session.learnerArtifact, isNull);
    });

    test('is deterministic and round-trips through the shared session JSON',
        () {
      final document = _document(r'([a-c]|\d).+ε?');
      final first = RegexToFaSessionFactory.create(
        source: document,
        sourceRevision: 3,
      );
      final second = RegexToFaSessionFactory.create(
        source: document,
        sourceRevision: 3,
      );

      expect(second.toJson(), first.toJson());
      final restored = ManualConversionSession.restore(
        first.toJson(),
        documentId: document.id,
        revision: 3,
      );
      expect(restored.isSuccess, isTrue);
      expect(restored.session!.toJson(), first.toJson());
    });

    test('maps the supported regex dialect to shared action types', () {
      final cases = <String, ManualConversionActionType>{
        '[a-c]': ManualConversionActionType.createBaseFragment,
        r'\d': ManualConversionActionType.createBaseFragment,
        '.': ManualConversionActionType.createBaseFragment,
        'ab': ManualConversionActionType.combineConcatenation,
        'a*': ManualConversionActionType.applyKleeneStar,
        'a+': ManualConversionActionType.applyPlus,
        'a?': ManualConversionActionType.applyOptional,
      };

      for (final entry in cases.entries) {
        final session = RegexToFaSessionFactory.create(
          source: _document(entry.key),
          sourceRevision: 1,
        );
        expect(
          session.requirements.last.type,
          entry.value,
          reason: entry.key,
        );
      }
    });

    test('rejects invalid source and revision', () {
      expect(
        () => RegexToFaSessionFactory.create(
          source: _document('('),
          sourceRevision: 0,
        ),
        throwsArgumentError,
      );
      expect(
        () => RegexToFaSessionFactory.create(
          source: _document('a'),
          sourceRevision: -1,
        ),
        throwsArgumentError,
      );
    });
  });
}

RegexDocument _document(String source) => RegexDocument(
      id: 'regex-doc',
      name: 'Regex',
      source: source,
      alphabet: const ['a', 'b', 'c', '0', '1'],
    );

FSA _rename(FSA source, String prefix) {
  final oldStates = source.states.toList()
    ..sort((first, second) => first.id.compareTo(second.id));
  final states = <String, State>{};
  for (var index = 0; index < oldStates.length; index++) {
    final old = oldStates[index];
    states[old.id] = old.copyWith(
      id: '${prefix}_s$index',
      position: Vector2(index * 19, index * 31),
    );
  }
  final oldTransitions = source.fsaTransitions.toList()
    ..sort((first, second) => first.id.compareTo(second.id));
  final transitions = <FSATransition>{};
  for (var index = 0; index < oldTransitions.length; index++) {
    final old = oldTransitions[index];
    transitions.add(
      old.copyWith(
        id: '${prefix}_t$index',
        fromState: states[old.fromState.id],
        toState: states[old.toState.id],
      ),
    );
  }
  return FSA(
    id: '${prefix}_fsa',
    name: source.name,
    states: states.values.toSet(),
    transitions: transitions,
    alphabet: source.alphabet,
    initialState:
        source.initialState == null ? null : states[source.initialState!.id],
    acceptingStates:
        source.acceptingStates.map((state) => states[state.id]!).toSet(),
    created: source.created,
    modified: source.modified,
    bounds: const math.Rectangle<double>(0, 0, 800, 600),
  );
}
