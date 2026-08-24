//
//  automaton_canvas_tool.dart
//  Turing Lab
//
//  Defines the editing modes available on the automaton canvas and a
//  ChangeNotifier controller that broadcasts the active tool. The module
//  integrates simply with toolbars and components that react to mode
//  changes, keeping lean, extensible state for future interaction types.
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
