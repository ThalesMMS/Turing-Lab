import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/messages/structured_message.dart';
import 'package:turing_lab/core/models/simulation_result.dart';
import 'package:turing_lab/core/models/simulation_step.dart';
import 'package:turing_lab/core/models/step_explanation.dart';

void main() {
  group('StepExplanation persistence', () {
    test('legacy prose round-trips through the legacy schema unchanged', () {
      const explanation = StepExplanation(
        title: 'Applied transition',
        bullets: ['Read the next symbol.'],
        categories: [ExplanationCategory.stackOperation],
        highlights: [
          HighlightTarget(type: HighlightTargetType.stackSpan, id: 'top'),
        ],
        suggestedFixes: [
          SuggestedFix(
            label: 'Inspect transition',
            details: 'Check the stack operation.',
            actionId: 'open-transition',
          ),
        ],
      );

      final encoded = explanation.toJson();
      final restored = StepExplanation.fromJson(encoded);

      expect(encoded, isNot(contains('schemaVersion')));
      expect(encoded['title'], 'Applied transition');
      expect(encoded['bullets'], ['Read the next symbol.']);
      expect(encoded['categories'], ['stackOperation']);
      expect((encoded['highlights'] as List).single['type'], 'stackSpan');
      expect(restored, explanation);
      expect(restored.toJson(), encoded);
    });

    test('structured v2 has explicit wire codes and no translatable prose', () {
      final explanation = StepExplanation(
        titleMessage: _message('transition-applied'),
        bulletMessages: [_message('input-consumed')],
        categories: const [ExplanationCategory.stackOperation],
        highlights: const [
          HighlightTarget(type: HighlightTargetType.stackSpan, id: 'top'),
        ],
        suggestedFixes: [
          SuggestedFix.structured(
            labelMessage: _message('inspect-transition'),
            actionId: 'open-transition',
          ),
        ],
      );

      final encoded = explanation.toJson();
      final serialized = jsonEncode(encoded);
      final restored = StepExplanation.fromJson(encoded);

      expect(encoded['schemaVersion'], StepExplanation.schemaVersion);
      expect(encoded['categories'], ['stack-operation']);
      expect((encoded['highlights'] as List).single['type'], 'stack-span');
      expect(serialized, isNot(contains('Applied transition')));
      expect(serialized, isNot(contains('Read the next symbol')));
      expect(restored, explanation);
    });

    test('structured explanation keeps a nested legacy suggested fix', () {
      final explanation = StepExplanation(
        titleMessage: _message('transition-applied'),
        suggestedFixes: const [
          SuggestedFix(label: 'Inspect the legacy transition'),
        ],
      );

      final encoded = explanation.toJson();
      final restored = StepExplanation.fromJson(encoded);

      expect(encoded['schemaVersion'], StepExplanation.schemaVersion);
      expect(encoded['titleMessage'], isA<Map>());
      expect(
        (encoded['suggestedFixes'] as List).single,
        containsPair('label', 'Inspect the legacy transition'),
      );
      expect(restored, explanation);
    });

    test('future category wire codes survive a structured round-trip', () {
      final explanation = StepExplanation.fromJson({
        'schemaVersion': StepExplanation.schemaVersion,
        'titleMessage': _message('future-category').toJson(),
        'bulletMessages': const <Object>[],
        'categories': const ['future-proof-category'],
        'highlights': const <Object>[],
        'suggestedFixes': const <Object>[],
      });

      expect(explanation.categories, [ExplanationCategory.unknown]);
      expect(explanation.toJson()['categories'], ['future-proof-category']);
    });

    test('distinct future highlight wire codes survive and stay distinct', () {
      StepExplanation decode(String type) => StepExplanation.fromJson({
        'schemaVersion': StepExplanation.schemaVersion,
        'titleMessage': _message('future-highlight').toJson(),
        'bulletMessages': const <Object>[],
        'categories': const <Object>[],
        'highlights': [
          {'type': type, 'id': 'target', 'data': const <String, Object>{}},
        ],
        'suggestedFixes': const <Object>[],
      });

      final first = decode('future-highlight-a');
      final second = decode('future-highlight-b');

      expect(first.highlights.single.type, HighlightTargetType.unknown);
      expect(
        (first.toJson()['highlights'] as List).single['type'],
        'future-highlight-a',
      );
      expect(first, isNot(second));
      expect({first, second}, hasLength(2));
    });

    test('ambiguous legacy and structured fields are rejected', () {
      expect(
        () => StepExplanation(
          title: 'Legacy title',
          titleMessage: _message('structured-title'),
        ),
        throwsAssertionError,
      );
      expect(
        () => StepExplanation(
          bullets: const ['Legacy bullet'],
          bulletMessages: [_message('structured-bullet')],
        ).toJson(),
        throwsStateError,
      );
      expect(
        () => SuggestedFix(
          label: 'Legacy label',
          detailsMessage: _message('structured-details'),
        ),
        throwsAssertionError,
      );
    });

    test(
      'legacy and structured representations have distinct value identity',
      () {
        const legacyA = StepExplanation(
          title: 'Legacy A',
          suggestedFixes: [SuggestedFix(label: 'Legacy fix A')],
        );
        const legacyB = StepExplanation(
          title: 'Legacy B',
          suggestedFixes: [SuggestedFix(label: 'Legacy fix B')],
        );
        final structured = StepExplanation(
          titleMessage: _message('legacy-title'),
          suggestedFixes: [
            SuggestedFix.structured(labelMessage: _message('legacy-fix')),
          ],
        );

        expect(legacyA, isNot(legacyB));
        expect(legacyA, isNot(structured));
        expect(legacyB, isNot(structured));
        expect({legacyA, legacyB, structured}, hasLength(3));
        expect({
          legacyA: 'a',
          legacyB: 'b',
          structured: 'structured',
        }, hasLength(3));
      },
    );

    test(
      'highlight parser accepts legacy aliases without enum-name coupling',
      () {
        final legacy = StepExplanation.fromJson({
          'title': 'Legacy',
          'bullets': const <String>[],
          'categories': const ['epsilonMove'],
          'highlights': const [
            {'type': 'sententialFormSpan', 'id': 'derivation', 'data': {}},
          ],
          'suggestedFixes': const <Object>[],
        });

        expect(legacy.categories, [ExplanationCategory.epsilonMove]);
        expect(
          legacy.highlights.single.type,
          HighlightTargetType.sententialFormSpan,
        );
        expect(
          (legacy.toJson()['highlights'] as List).single['type'],
          'sententialFormSpan',
        );
      },
    );
  });

  group('SimulationStep persistence', () {
    test('legacy description and explanation retain their display text', () {
      const step = SimulationStep(
        currentState: 'q0',
        remainingInput: 'a',
        stepNumber: 0,
        description: 'Reading input',
        explanation: StepExplanation(
          title: 'Current move',
          bullets: ['Read a.'],
        ),
      );

      final encoded = step.toJson();
      final restored = SimulationStep.fromJson(encoded);

      expect(encoded, isNot(contains('schemaVersion')));
      expect(encoded['description'], 'Reading input');
      expect(restored.description, 'Reading input');
      expect(restored.explanation?.title, 'Current move');
      expect(restored.explanation?.bullets, ['Read a.']);
      expect(restored.toJson(), encoded);
    });

    test('structured step round-trips without explanatory prose', () {
      final step = SimulationStep(
        currentState: 'q0',
        remainingInput: 'a',
        stepNumber: 0,
        descriptionMessage: _message('configuration-entered'),
        explanation: StepExplanation(
          titleMessage: _message('current-move'),
          bulletMessages: [_message('symbol-read')],
        ),
      );

      final encoded = step.toJson();
      final serialized = jsonEncode(encoded);
      final restored = SimulationStep.fromJson(encoded);

      expect(encoded['schemaVersion'], SimulationStep.schemaVersion);
      expect(encoded, isNot(contains('description')));
      expect(serialized, isNot(contains('Reading input')));
      expect(restored, step);
    });

    test('structured step keeps a nested legacy explanation', () {
      final step = SimulationStep(
        currentState: 'q0',
        remainingInput: 'a',
        stepNumber: 0,
        descriptionMessage: _message('configuration-entered'),
        explanation: const StepExplanation(
          title: 'Legacy explanation',
          bullets: ['Legacy detail.'],
        ),
      );

      final encoded = step.toJson();
      final restored = SimulationStep.fromJson(encoded);

      expect(encoded['schemaVersion'], SimulationStep.schemaVersion);
      expect(encoded['descriptionMessage'], isA<Map>());
      expect((encoded['explanation'] as Map)['title'], 'Legacy explanation');
      expect(restored, step);
    });

    test('step decoder rejects ambiguous description fields', () {
      expect(
        () => SimulationStep.fromJson({
          'schemaVersion': SimulationStep.schemaVersion,
          'currentState': 'q0',
          'remainingInput': '',
          'stepNumber': 0,
          'description': 'Legacy description',
          'descriptionMessage': _message('structured-description').toJson(),
        }),
        throwsFormatException,
      );
    });
  });

  group('SimulationResult persistence', () {
    test('timeout persists stable semantics instead of localized prose', () {
      final result = SimulationResult.timeout(
        inputString: 'a',
        steps: [_structuredStep()],
        executionTime: const Duration(milliseconds: 2500),
      );

      final encoded = result.toPersistedJson();
      final serialized = jsonEncode(encoded);
      final restored = SimulationResult.fromPersistedJson(encoded);

      expect(encoded['schemaVersion'], SimulationResult.schemaVersion);
      expect(encoded, isNot(contains('errorMessage')));
      expect(serialized, isNot(contains('Simulation timed out')));
      expect(result.message?.stableCode, 'simulation.timeout');
      expect(
        result.message?.arguments['elapsed']?.kind.wireCode,
        'duration-ms',
      );
      expect(restored.isTimeout, isTrue);
      expect(restored.message, result.message);
      expect(restored.toPersistedJson(), encoded);
    });

    test('timeout keeps stable semantics when a child step is legacy', () {
      final result = SimulationResult.timeout(
        inputString: 'a',
        steps: const [
          SimulationStep(
            currentState: 'q0',
            remainingInput: 'a',
            stepNumber: 0,
            explanation: StepExplanation(title: 'Legacy child explanation'),
          ),
        ],
        executionTime: const Duration(milliseconds: 2500),
      );

      final encoded = result.toPersistedJson();
      final restored = SimulationResult.fromPersistedJson(encoded);

      expect(encoded['schemaVersion'], SimulationResult.schemaVersion);
      expect(encoded, isNot(contains('errorMessage')));
      final encodedStep = (encoded['steps'] as List).single as Map;
      expect(encodedStep['schemaVersion'], SimulationStep.schemaVersion);
      expect(encodedStep['explanation'], isNot(contains('schemaVersion')));
      expect(restored.message?.stableCode, 'simulation.timeout');
      expect(restored, result);
      expect(restored.hashCode, result.hashCode);
    });

    test('generic legacy failure keeps exact error text and schema', () {
      final result = SimulationResult.failure(
        inputString: 'a',
        steps: const [],
        errorMessage: 'Previously persisted failure text',
        executionTime: const Duration(milliseconds: 3),
      );

      final encoded = result.toPersistedJson();
      final restored = SimulationResult.fromPersistedJson(encoded);

      expect(encoded, isNot(contains('schemaVersion')));
      expect(encoded['errorMessage'], 'Previously persisted failure text');
      expect(restored.errorMessage, 'Previously persisted failure text');
      expect(restored.toPersistedJson(), encoded);
    });

    test('structured failure omits compatibility display text', () {
      final result = SimulationResult.structuredFailure(
        inputString: 'a',
        steps: [_structuredStep()],
        message: _message(
          'no-transition',
          severity: StructuredMessageSeverity.error,
        ),
        compatibilityErrorMessage: 'No transition is available.',
        executionTime: const Duration(milliseconds: 3),
      );

      final encoded = result.toPersistedJson();
      final serialized = jsonEncode(encoded);
      final restored = SimulationResult.fromPersistedJson(encoded);

      expect(encoded['schemaVersion'], SimulationResult.schemaVersion);
      expect(encoded, isNot(contains('errorMessage')));
      expect(serialized, isNot(contains('No transition is available')));
      expect(restored.message?.stableCode, 'trace.test.no-transition');
      expect(restored.errorMessage, 'trace.test.no-transition');
      expect(restored, result);
      expect(restored.hashCode, result.hashCode);
    });

    test('legacy failure prose remains part of value identity', () {
      SimulationResult legacy(String errorMessage) => SimulationResult.failure(
        inputString: 'a',
        steps: const [],
        errorMessage: errorMessage,
        executionTime: const Duration(milliseconds: 3),
      );
      final first = legacy('Legacy failure A');
      final second = legacy('Legacy failure B');
      final structured = SimulationResult.structuredFailure(
        inputString: 'a',
        steps: const [],
        message: StructuredMessage(
          namespace: 'simulation',
          code: 'legacy-failure',
          category: StructuredMessageCategory.simulation,
          severity: StructuredMessageSeverity.error,
        ),
        compatibilityErrorMessage: 'Legacy failure A',
        executionTime: const Duration(milliseconds: 3),
      );

      expect(first, isNot(second));
      expect(first, isNot(structured));
      expect({first, second, structured}, hasLength(3));
    });
  });
}

SimulationStep _structuredStep() => SimulationStep(
  currentState: 'q0',
  remainingInput: '',
  stepNumber: 0,
  descriptionMessage: _message('configuration-entered'),
);

StructuredMessage _message(
  String code, {
  StructuredMessageSeverity severity = StructuredMessageSeverity.information,
}) => StructuredMessage(
  namespace: 'trace.test',
  code: code,
  category: StructuredMessageCategory.trace,
  severity: severity,
);
