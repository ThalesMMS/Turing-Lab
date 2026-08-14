//
//  simulation_highlight_service_test.dart
//  Turing Lab
//
//  Testes que exercitam o SimulationHighlightService, certificando a emissão de
//  destaques durante a simulação passo a passo e a limpeza adequada por meio do
//  canal GraphView ao finalizar ou reiniciar execuções no canvas.
//
//  Thales Matheus Mendonça Santos - October 2025
//

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/simulation_highlight.dart';
import 'package:turing_lab/core/models/simulation_step.dart';
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
          usedTransition: 't0',
          stepNumber: 0,
          nextState: 'q1',
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
      expect(highlight.transitionIds, equals({'t0'}));
    });

    test('falls back to subsequent step when nextState is missing', () {
      final controller = _FakeHighlightController();
      final channel = GraphViewSimulationHighlightChannel(controller);
      final service = SimulationHighlightService(channel: channel);

      final steps = [
        const SimulationStep(
          currentState: 'q0',
          remainingInput: 'a',
          usedTransition: 't0',
          stepNumber: 0,
          nextState: '',
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
      expect(highlight.transitionIds, equals({'t0'}));
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
