import 'package:flutter/material.dart';

import '../../../features/canvas/graphview/base_graphview_canvas_controller.dart';
import '../automaton_canvas_tool.dart';

/// Executes keyboard interaction through the same controller mutation path as
/// pointer interaction. Read-only canvases short-circuit before any mutation.
class AutomatonGraphViewInteractionCoordinator {
  AutomatonGraphViewInteractionCoordinator({
    required this.controller,
    required this.toolController,
    required this.editingEnabled,
    required this.selectedNodeId,
    required this.selectedTransitionIds,
    required this.clearTransitionSource,
    required this.clearSelectedNode,
    required this.notifySelectionChanged,
    this.beforeRemoveState,
    this.beforeRemoveTransition,
  });

  final BaseGraphViewCanvasController<dynamic, dynamic> Function() controller;
  final AutomatonCanvasToolController Function() toolController;
  final bool Function() editingEnabled;
  final String? Function() selectedNodeId;
  final Set<String> Function() selectedTransitionIds;
  final VoidCallback clearTransitionSource;
  final VoidCallback clearSelectedNode;
  final VoidCallback notifySelectionChanged;
  final Future<bool> Function(String id)? beforeRemoveState;
  final Future<bool> Function(String id)? beforeRemoveTransition;

  void activateTool(AutomatonCanvasTool tool) {
    if (_hasEditableTextFocus() ||
        (tool != AutomatonCanvasTool.selection && !editingEnabled())) {
      return;
    }
    if (tool == AutomatonCanvasTool.selection) {
      clearTransitionSource();
    }
    toolController().setActiveTool(tool);
  }

  void addStateAtCenter() {
    if (_hasEditableTextFocus() || !editingEnabled()) {
      return;
    }
    toolController().setActiveTool(AutomatonCanvasTool.addState);
    controller().addStateAtCenter();
  }

  Future<void> deleteSelection() async {
    if (_hasEditableTextFocus() || !editingEnabled()) {
      return;
    }
    final nodeId = selectedNodeId();
    if (nodeId != null) {
      if (beforeRemoveState != null && !await beforeRemoveState!(nodeId)) {
        return;
      }
      if (!editingEnabled() || selectedNodeId() != nodeId) return;
      controller().removeState(nodeId);
      clearSelectedNode();
      return;
    }
    final transitions = selectedTransitionIds();
    if (transitions.isEmpty) {
      return;
    }
    final ids = transitions.toList(growable: false);
    for (final id in ids) {
      if (beforeRemoveTransition != null &&
          !await beforeRemoveTransition!(id)) {
        continue;
      }
      if (!editingEnabled() || !selectedTransitionIds().contains(id)) {
        continue;
      }
      controller().removeTransition(id);
      transitions.remove(id);
    }
    notifySelectionChanged();
  }

  void redo() {
    final target = controller();
    if (!_hasEditableTextFocus() && editingEnabled() && target.canRedo) {
      target.redo();
    }
  }

  void undo() {
    final target = controller();
    if (!_hasEditableTextFocus() && editingEnabled() && target.canUndo) {
      target.undo();
    }
  }

  bool _hasEditableTextFocus() {
    final focusContext = FocusManager.instance.primaryFocus?.context;
    if (focusContext == null) {
      return false;
    }
    return focusContext.widget is EditableText ||
        focusContext.findAncestorWidgetOfExactType<EditableText>() != null;
  }
}
