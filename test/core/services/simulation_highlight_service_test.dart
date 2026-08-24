//
//  simulation_highlight_service_test.dart
//  Turing Lab
//
//  Tests that exercise SimulationHighlightService, confirming highlight emission
//  during step-by-step simulation and proper cleanup through the GraphView
//  channel when executions on the canvas finish or restart.
//
//  Thales Matheus Mendonça Santos - October 2025
//

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/simulation_highlight.dart';
import 'package:turing_lab/core/models/simulation_step.dart';
import 'package:turing_lab/core/models/step_explanation.dart';
import 'package:turing_lab/core/services/simulation_highlight_service.dart';
import 'package:turing_lab/features/canvas/graphview/graphview_highlight_channel.dart';
import 'package:turing_lab/features/canvas/graphview/graphview_highlight_controller.dart';

class _FakeHighlightController implements GraphViewHighlightController {
  SimulationHighlight? lastHighlight;
  int clearCount = 0;

  @override
  void applyHighlight(SimulationHighlight highlight) {
    lastHighlight = highlight;
  }

  @override
  void clearHighlight() {
    clearCount++;
  }
}

void main() {
  group('SimulationHighlightService', () {
    test('emits highlight payload to GraphView controller', () {
      final controller = _FakeHighlightController();
      final channel = GraphViewSimulationHighlightChannel(controller);
      final service = SimulationHighlightService(channel: channel);

      final steps = [
        const SimulationStep(
          currentState: 'q0',
          remainingInput: 'ab',
          usedTransition: 'δ(q0, a) = q1',
          stepNumber: 0,
          nextState: 'q1',
          explanation: StepExplanation(
            highlights: [
              HighlightTarget(
                type: HighlightTargetType.transition,
                id: 'stable-edge-0',
              ),
            ],
          ),
        ),
        const SimulationStep(
          currentState: 'q1',
          remainingInput: 'b',
          usedTransition: 't1',
          stepNumber: 1,
          nextState: 'q2',
        ),
      ];

      final highlight = service.emitFromSteps(steps, 0);

      expect(controller.lastHighlight, equals(highlight));
      expect(highlight.stateIds, equals({'q0', 'q1'}));
      expect(highlight.transitionIds, equals({'stable-edge-0'}));
    });

    test('falls back to subsequent step when nextState is missing', () {
      final controller = _FakeHighlightController();
      final channel = GraphViewSimulationHighlightChannel(controller);
      final service = SimulationHighlightService(channel: channel);

      final steps = [
        const SimulationStep(
          currentState: 'q0',
          remainingInput: 'a',
          usedTransition: 'q0 --a--> q1',
          stepNumber: 0,
          nextState: '',
          explanation: StepExplanation(
            highlights: [
              HighlightTarget(
                type: HighlightTargetType.transition,
                id: 'stable-edge-0',
              ),
            ],
          ),
        ),
        const SimulationStep(
          currentState: 'q1',
          remainingInput: '',
          usedTransition: null,
          stepNumber: 1,
        ),
      ];

      final highlight = service.emitFromSteps(steps, 0);

      expect(controller.lastHighlight, equals(highlight));
      expect(highlight.stateIds, equals({'q0', 'q1'}));
      expect(highlight.transitionIds, equals({'stable-edge-0'}));
    });

    test('uses explicit transition targets instead of displayed trace text',
        () {
      final service = SimulationHighlightService();

      final highlight = service.computeFromSteps([
        const SimulationStep(
          currentState: 'q0',
          remainingInput: 'a',
          usedTransition: 'human-readable transition',
          stepNumber: 0,
          explanation: StepExplanation(
            highlights: [
              HighlightTarget(
                type: HighlightTargetType.transition,
                id: 'opaque-transition-id',
              ),
            ],
          ),
        ),
      ], 0);

      expect(highlight.transitionIds, equals({'opaque-transition-id'}));
    });

    test('deduplicates transition targets without modifying opaque ids', () {
      final service = SimulationHighlightService();

      final highlight = service.computeFromSteps([
        const SimulationStep(
          currentState: 'q0',
          remainingInput: 'a',
          stepNumber: 0,
          explanation: StepExplanation(
            highlights: [
              HighlightTarget(
                type: HighlightTargetType.transition,
                id: ' edge/id ',
              ),
              HighlightTarget(
                type: HighlightTargetType.transition,
                id: 'edge/id',
              ),
              HighlightTarget(
                type: HighlightTargetType.transition,
                id: ' edge/id ',
              ),
              HighlightTarget(
                type: HighlightTargetType.transition,
                id: '',
              ),
              HighlightTarget(type: HighlightTargetType.transition),
              HighlightTarget(type: HighlightTargetType.state, id: 'q1'),
            ],
          ),
        ),
      ], 0);

      expect(highlight.transitionIds, equals({' edge/id ', 'edge/id'}));
    });

    test('explicit active ids override display and explanation state values',
        () {
      final service = SimulationHighlightService();

      final highlight = service.computeFromSteps([
        const SimulationStep(
          currentState: 'Destination label',
          nextState: 'Conflicting next label',
          remainingInput: '',
          stepNumber: 1,
          activeStateIds: {'destination-node-id'},
          explanation: StepExplanation(
            highlights: [
              HighlightTarget(
                type: HighlightTargetType.state,
                id: 'source-node-id',
              ),
              HighlightTarget(
                type: HighlightTargetType.state,
                id: 'destination-node-id',
              ),
              HighlightTarget(
                type: HighlightTargetType.transition,
                id: 'stable-edge-id',
              ),
            ],
          ),
        ),
        const SimulationStep(
          currentState: 'Following label',
          remainingInput: '',
          stepNumber: 2,
        ),
      ], 0);

      expect(highlight.stateIds, {'destination-node-id'});
      expect(highlight.transitionIds, {'stable-edge-id'});
    });

    test('explicit empty active ids suppress legacy display fallback', () {
      final service = SimulationHighlightService();

      final highlight = service.computeFromSteps([
        const SimulationStep(
          currentState: '{}',
          nextState: 'Conflicting next label',
          remainingInput: '',
          stepNumber: 1,
          activeStateIds: <String>{},
        ),
        const SimulationStep(
          currentState: 'Following label',
          remainingInput: '',
          stepNumber: 2,
        ),
      ], 0);

      expect(highlight.stateIds, isEmpty);
    });

    test('null active ids retain the legacy display fallback', () {
      final service = SimulationHighlightService();

      final highlight = service.computeFromSteps([
        const SimulationStep(
          currentState: ' Current label ',
          nextState: '',
          remainingInput: 'a',
          stepNumber: 0,
        ),
        const SimulationStep(
          currentState: ' Following label ',
          remainingInput: '',
          stepNumber: 1,
        ),
      ], 0);

      expect(highlight.stateIds, {'Current label', 'Following label'});
    });

    test('plural active ids preserve opaque non-empty values byte-for-byte',
        () {
      final service = SimulationHighlightService();

      final highlight = service.computeFromSteps([
        const SimulationStep(
          currentState: 'Display set',
          remainingInput: '',
          stepNumber: 1,
          activeStateIds: {' node/id ', 'node/id', ''},
        ),
      ], 0);

      expect(highlight.stateIds, {' node/id ', 'node/id'});
    });

    test('clear delegates to the channel controller', () {
      final controller = _FakeHighlightController();
      final channel = GraphViewSimulationHighlightChannel(controller);
      final service = SimulationHighlightService(channel: channel);

      service.clear();

      expect(controller.clearCount, equals(1));
      expect(controller.lastHighlight, isNull);
    });
  });
}
