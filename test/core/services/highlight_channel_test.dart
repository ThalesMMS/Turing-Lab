import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/simulation_highlight.dart';
import 'package:turing_lab/core/services/algorithm_step_highlight_service.dart';
import 'package:turing_lab/core/services/highlight_channel.dart';
import 'package:turing_lab/core/services/simulation_highlight_service.dart';

void main() {
  group('HighlightDispatchController', () {
    test('function-backed channel sends highlights and clears with empty', () {
      final received = <SimulationHighlight>[];
      final channel = FunctionHighlightChannel(received.add);
      final highlight = SimulationHighlight(stateIds: {'q0'});

      channel.send(highlight);
      channel.clear();

      expect(received, equals([highlight, SimulationHighlight.empty]));
    });

    test('tracks dispatch count, last highlight, and clear state', () {
      final received = <SimulationHighlight>[];
      final controller = HighlightDispatchController<HighlightChannel>(
        debugLabel: 'TestHighlightService',
        dispatcher: received.add,
        channelFromDispatcher: FunctionHighlightChannel.new,
      );
      final highlight = SimulationHighlight(
        stateIds: {'q0'},
        transitionIds: {'t0'},
      );

      controller.dispatch(highlight);
      controller.clear();

      expect(controller.dispatchCount, equals(1));
      expect(controller.lastHighlight, isNull);
      expect(received, equals([highlight, SimulationHighlight.empty]));
    });

    test('interceptor resets related state before send and clear', () {
      final events = <String>[];
      final received = <SimulationHighlight>[];
      final channel = InterceptingHighlightChannel(
        delegate: FunctionHighlightChannel((highlight) {
          events.add('forward');
          received.add(highlight);
        }),
        beforeActivity: () => events.add('reset'),
      );
      final highlight = SimulationHighlight(transitionIds: {'t0'});

      channel.send(highlight);
      channel.clear();

      expect(events, ['reset', 'forward', 'reset', 'forward']);
      expect(received, [highlight, SimulationHighlight.empty]);
    });

    test('rejects simultaneous channel and dispatcher', () {
      final channel = FunctionHighlightChannel((_) {});

      expect(
        () => HighlightDispatchController<HighlightChannel>(
          debugLabel: 'TestHighlightService',
          channel: channel,
          dispatcher: (_) {},
          channelFromDispatcher: FunctionHighlightChannel.new,
        ),
        throwsAssertionError,
      );
    });
  });

  group('domain highlight services', () {
    test('simulation service keeps legacy dispatcher constructor behavior', () {
      final received = <SimulationHighlight>[];
      final service = SimulationHighlightService(dispatcher: received.add);
      final highlight = SimulationHighlight(stateIds: {'q0'});

      service.dispatch(highlight);
      service.clear();

      expect(service.dispatchCount, equals(1));
      expect(service.lastHighlight, isNull);
      expect(received, equals([highlight, SimulationHighlight.empty]));
    });

    test('algorithm service keeps legacy dispatcher constructor behavior', () {
      final received = <SimulationHighlight>[];
      final service = AlgorithmStepHighlightService(dispatcher: received.add);
      final highlight = SimulationHighlight(transitionIds: {'t0'});

      service.dispatch(highlight);
      service.clear();

      expect(service.dispatchCount, equals(1));
      expect(service.lastHighlight, isNull);
      expect(received, equals([highlight, SimulationHighlight.empty]));
    });
  });
}
