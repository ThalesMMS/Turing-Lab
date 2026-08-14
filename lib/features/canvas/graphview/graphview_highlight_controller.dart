//
//  graphview_highlight_controller.dart
//  Turing Lab
//
//  Contrato compartilhado pelos controladores GraphView que lidam com
//  destaques de simulação, padronizando a aplicação de realces vindos dos
//  serviços de execução e a remoção segura desses efeitos do canvas.
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
