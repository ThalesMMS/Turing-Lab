//
//  graphview_algorithm_step_highlight_channel.dart
//  Turing Lab
//
//  Channel that receives highlights from AlgorithmStepHighlightService and
//  forwards them to the GraphView canvas controller, keeping visual state in
//  sync with each algorithm step and allowing the active highlight to be
//  cleared when needed.
//
//  Thales Matheus Mendonça Santos - January 2026
//
import '../../../core/models/simulation_highlight.dart';
import '../../../core/services/highlight_channel.dart';
import 'graphview_highlight_controller.dart';

/// Highlight channel that bridges algorithm step highlight payloads to a
/// GraphView canvas controller.
class GraphViewAlgorithmStepHighlightChannel implements HighlightChannel {
  GraphViewAlgorithmStepHighlightChannel(this._controller);

  final GraphViewHighlightController _controller;

  @override
  void clear() {
    _controller.clearHighlight();
  }

  @override
  void send(SimulationHighlight highlight) {
    _controller.applyHighlight(highlight);
  }
}
