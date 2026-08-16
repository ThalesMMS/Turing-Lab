//
//  automaton_canvas_tool.dart
//  Turing Lab
//
//  Definição dos modos de edição disponíveis no canvas de autômatos e de um
//  controlador baseado em ChangeNotifier que propaga alterações da ferramenta
//  ativa. O módulo oferece integração simples com toolbars e componentes que
//  reagem às trocas de modo, mantendo estado enxuto e extensível para futuros
//  tipos de interação.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/foundation.dart';

/// Editing tools supported by the automaton canvas.
enum AutomatonCanvasTool { selection, addState, transition }

/// Controller that tracks and broadcasts the active canvas tool.
class AutomatonCanvasToolController extends ChangeNotifier {
  AutomatonCanvasToolController([
    this._activeTool = AutomatonCanvasTool.selection,
  ]);

  AutomatonCanvasTool _activeTool;

  AutomatonCanvasTool get activeTool => _activeTool;

  /// Sets the current tool, notifying listeners when it changes.
  void setActiveTool(AutomatonCanvasTool tool) {
    if (_activeTool == tool) {
      return;
    }
    _activeTool = tool;
    notifyListeners();
  }

  /// Selects [tool], or returns to selection when it is already active.
  void toggleTool(AutomatonCanvasTool tool) {
    setActiveTool(
      _activeTool == tool ? AutomatonCanvasTool.selection : tool,
    );
  }
}
