//
//  graphview_highlight_controller.dart
//  Turing Lab
//
//  Shared contract for GraphView controllers that handle simulation
//  highlights, standardizing application of highlights from execution
//  services and safe removal of those effects from the canvas.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import '../../../core/models/simulation_highlight.dart';

/// Common contract exposed by GraphView canvas controllers that support
/// simulation highlights.
abstract class GraphViewHighlightController {
  /// Applies the provided [highlight] to the canvas.
  void applyHighlight(SimulationHighlight highlight);

  /// Clears any active highlight from the canvas.
  void clearHighlight();
}
