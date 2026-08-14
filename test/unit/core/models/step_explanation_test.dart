import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/simulation_step.dart';
import 'package:turing_lab/core/models/step_explanation.dart';

void main() {
  group('StepExplanation equality', () {
    test('compares nested highlight and suggested fix values', () {
      const first = StepExplanation(
        title: 'Applied transition',
        bullets: ['Read a', 'Move right'],
        categories: [ExplanationCategory.tapeOperation],
        highlights: [
          HighlightTarget(
            type: HighlightTargetType.tapeCell,
            id: 'cell-1',
            data: {
              'index': 1,
              'metadata': {
                'labels': ['head', 'read'],
              },
            },
          ),
        ],
        suggestedFixes: [
          SuggestedFix(
            label: 'Check transition',
            details: 'Verify the symbol under the head.',
            actionId: 'openTransitions',
          ),
        ],
      );

      const second = StepExplanation(
        title: 'Applied transition',
        bullets: ['Read a', 'Move right'],
        categories: [ExplanationCategory.tapeOperation],
        highlights: [
          HighlightTarget(
            type: HighlightTargetType.tapeCell,
            id: 'cell-1',
            data: {
              'index': 1,
              'metadata': {
                'labels': ['head', 'read'],
              },
            },
          ),
        ],
        suggestedFixes: [
          SuggestedFix(
            label: 'Check transition',
            details: 'Verify the symbol under the head.',
            actionId: 'openTransitions',
          ),
        ],
      );

      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });

    test('makes SimulationStep equality compare explanation contents', () {
      const first = SimulationStep(
        currentState: 'q0',
        remainingInput: 'a',
        stepNumber: 1,
        explanation: StepExplanation(
          bullets: ['Read a'],
          highlights: [
            HighlightTarget(
              type: HighlightTargetType.state,
              id: 'q0',
            ),
          ],
        ),
      );

      const second = SimulationStep(
        currentState: 'q0',
        remainingInput: 'a',
        stepNumber: 1,
        explanation: StepExplanation(
          bullets: ['Read a'],
          highlights: [
            HighlightTarget(
              type: HighlightTargetType.state,
              id: 'q0',
            ),
          ],
        ),
      );

      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });
  });
}
