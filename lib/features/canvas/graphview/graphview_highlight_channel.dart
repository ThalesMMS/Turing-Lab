//
//  graphview_highlight_channel.dart
//  Turing Lab
//
//  Canal que recebe realces do SimulationHighlightService e os encaminha para o
//  controlador GraphView responsável pelo canvas, garantindo que o estado
//  visual acompanhe cada etapa da simulação e permitindo limpar o destaque
//  ativo quando necessário.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import '../../../core/models/simulation_highlight.dart';
import '../../../core/services/highlight_channel.dart';
import 'graphview_highlight_controller.dart';

/// Highlight channel that bridges simulation highlight payloads to a
/// GraphView canvas controller.
class GraphViewSimulationHighlightChannel implements HighlightChannel {
  GraphViewSimulationHighlightChannel(this._controller);

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
