import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/simulation_step.dart';

void main() {
  group('SimulationStep active state ids', () {
    test('distinguishes legacy null metadata from an explicit empty set', () {
      const legacy = SimulationStep(
        currentState: 'Display state',
        remainingInput: '',
        stepNumber: 0,
      );
      const explicitEmpty = SimulationStep(
        currentState: '{}',
        remainingInput: '',
        stepNumber: 0,
        activeStateIds: <String>{},
      );

      expect(legacy, isNot(explicitEmpty));
      expect(legacy.activeStateIds, isNull);
      expect(explicitEmpty.activeStateIds, isEmpty);
      expect(
        SimulationStep.fromJson(legacy.toJson()).activeStateIds,
        isNull,
      );
      expect(
        SimulationStep.fromJson(explicitEmpty.toJson()).activeStateIds,
        isEmpty,
      );
    });

    test('compares and hashes plural active ids by set contents', () {
      const first = SimulationStep(
        currentState: '{First,Second}',
        remainingInput: 'a',
        stepNumber: 1,
        activeStateIds: {'state-id-1', 'state-id-2'},
      );
      const second = SimulationStep(
        currentState: '{First,Second}',
        remainingInput: 'a',
        stepNumber: 1,
        activeStateIds: {'state-id-2', 'state-id-1'},
      );

      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });

    test('copyWith and JSON preserve plural opaque ids', () {
      const original = SimulationStep(
        currentState: 'Display state',
        remainingInput: 'a',
        stepNumber: 1,
      );

      final copied = original.copyWith(
        activeStateIds: {' node/id ', 'node/id'},
      );
      final restored = SimulationStep.fromJson(copied.toJson());

      expect(copied.activeStateIds, {' node/id ', 'node/id'});
      expect(restored, copied);
      expect(restored.activeStateIds, {' node/id ', 'node/id'});
    });

    test('copyWith without active ids retains the existing set', () {
      const original = SimulationStep(
        currentState: 'Display state',
        remainingInput: 'a',
        stepNumber: 1,
        activeStateIds: {'kept-id'},
      );

      // copyWith cannot express "clear this field"; omission always retains.
      // Build a fresh step when a trace must drop its authoritative ids.
      expect(original.copyWith(stepNumber: 2).activeStateIds, {'kept-id'});
      expect(original.copyWith(activeStateIds: null).activeStateIds, {
        'kept-id',
      });
      expect(
          original.copyWith(activeStateIds: const {}).activeStateIds, isEmpty);
    });

    test('missing legacy JSON metadata restores null', () {
      final restored = SimulationStep.fromJson({
        'currentState': 'Legacy label',
        'remainingInput': 'a',
        'stepNumber': 0,
      });

      expect(restored.activeStateIds, isNull);
    });

    test('every factory forwards active state ids', () {
      final steps = <SimulationStep>[
        SimulationStep.fsa(
          currentState: 'FSA label',
          remainingInput: '',
          stepNumber: 1,
          activeStateIds: {'fsa-id'},
        ),
        SimulationStep.pda(
          currentState: 'PDA label',
          remainingInput: '',
          stackContents: 'Z',
          stepNumber: 1,
          activeStateIds: {'pda-id'},
        ),
        SimulationStep.tm(
          currentState: 'TM label',
          remainingInput: '',
          tapeContents: 'a',
          stepNumber: 1,
          activeStateIds: {'tm-id'},
        ),
        SimulationStep.initial(
          initialState: 'Initial label',
          inputString: 'a',
          activeStateIds: {'initial-id'},
        ),
        SimulationStep.finalStep(
          finalState: 'Final label',
          remainingInput: '',
          stackContents: '',
          tapeContents: '',
          stepNumber: 2,
          activeStateIds: {'final-id'},
        ),
      ];

      expect(
        steps.map((step) => step.activeStateIds),
        [
          {'fsa-id'},
          {'pda-id'},
          {'tm-id'},
          {'initial-id'},
          {'final-id'},
        ],
      );
    });
  });

  test('preserves atomic PDA stack tokens through copy and JSON', () {
    const step = SimulationStep(
      currentState: 'q1',
      remainingInput: '',
      stackContents: 'bottom🧪x🧪αβα',
      stackTokens: ['bottom', '🧪x', '🧪', 'αβ', 'α'],
      stepNumber: 1,
    );

    expect(step.effectiveStackTokens, ['bottom', '🧪x', '🧪', 'αβ', 'α']);
    expect(step.stackTop, 'α');
    expect(step.stackLength, 5);
    expect(step.copyWith(stepNumber: 2).stackTokens, step.stackTokens);
    expect(SimulationStep.fromJson(step.toJson()), step);
  });

  test('rejects non-string atomic PDA stack tokens in JSON', () {
    expect(
      () => SimulationStep.fromJson({
        'currentState': 'q1',
        'remainingInput': '',
        'stackTokens': ['bottom', 1],
        'stepNumber': 1,
      }),
      throwsA(isA<TypeError>()),
    );
  });
}
