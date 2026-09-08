//
//  canvas_tool_dispatcher.dart
//  Turing Lab
//
//  Pure tool dispatch for the automaton canvas interactions layer. The
//  dispatcher owns the transient interaction state that is not rendered
//  (the active tool, the pending transition source and the double-tap
//  tracking) and turns hit-test results into outcomes. The widget applies the
//  outcomes: it keeps selection and overlay state, and every domain mutation
//  and undo/redo entry still goes through the canvas controller.
//

import '../automaton_canvas_tool.dart';

/// Outcome of a primary tap on the canvas body.
sealed class CanvasTapOutcome {
  const CanvasTapOutcome();
}

/// Nothing to do (for example, a tap that ended a drag).
class CanvasTapIgnored extends CanvasTapOutcome {
  const CanvasTapIgnored();
}

/// Add a state where the tap landed.
class CanvasTapAddState extends CanvasTapOutcome {
  const CanvasTapAddState();
}

/// Open the editor for the edges under the tap.
class CanvasTapEditEdges extends CanvasTapOutcome {
  const CanvasTapEditEdges();
}

/// Clear the current selection.
class CanvasTapClearSelection extends CanvasTapOutcome {
  const CanvasTapClearSelection();
}

/// Select [nodeId]; [openContext] is true on a double tap.
class CanvasTapSelectNode extends CanvasTapOutcome {
  const CanvasTapSelectNode(this.nodeId, {required this.openContext});

  final String nodeId;
  final bool openContext;
}

/// Remember [nodeId] as the pending source of a transition.
class CanvasTapBeginTransition extends CanvasTapOutcome {
  const CanvasTapBeginTransition(this.nodeId);

  final String nodeId;
}

/// Open the transition editor from [sourceId] to [targetId].
class CanvasTapCompleteTransition extends CanvasTapOutcome {
  const CanvasTapCompleteTransition({
    required this.sourceId,
    required this.targetId,
  });

  final String sourceId;
  final String targetId;
}

/// What a tool change invalidated, so the widget can update rendered state.
class CanvasToolChange {
  const CanvasToolChange({
    required this.tool,
    required this.clearedTransitionSource,
    required this.clearedSelection,
  });

  final AutomatonCanvasTool tool;
  final bool clearedTransitionSource;
  final bool clearedSelection;
}

class CanvasToolDispatcher {
  CanvasToolDispatcher({
    AutomatonCanvasTool initialTool = AutomatonCanvasTool.selection,
    Duration doubleTapMinTime = const Duration(milliseconds: 40),
    Duration doubleTapTimeout = const Duration(milliseconds: 300),
  }) : _activeTool = initialTool,
       _doubleTapMinTime = doubleTapMinTime,
       _doubleTapTimeout = doubleTapTimeout;

  final Duration _doubleTapMinTime;
  final Duration _doubleTapTimeout;

  AutomatonCanvasTool _activeTool;
  String? _transitionSourceId;
  String? _lastTapNodeId;
  Duration? _lastTapTimestamp;
  String? _doubleTapCandidateNodeId;

  AutomatonCanvasTool get activeTool => _activeTool;
  String? get transitionSourceId => _transitionSourceId;

  /// Switches tools. Leaving the transition tool drops the pending source and
  /// leaving the selection tool forgets the tap history, so a later tap never
  /// resumes an operation started under another tool.
  CanvasToolChange? setActiveTool(AutomatonCanvasTool tool) {
    if (tool == _activeTool) {
      return null;
    }
    _activeTool = tool;
    final clearedTransition =
        tool != AutomatonCanvasTool.transition && _transitionSourceId != null;
    if (tool != AutomatonCanvasTool.transition) {
      _transitionSourceId = null;
    }
    final clearedSelection = tool != AutomatonCanvasTool.selection;
    if (clearedSelection) {
      resetTapTracking();
    }
    return CanvasToolChange(
      tool: tool,
      clearedTransitionSource: clearedTransition,
      clearedSelection: clearedSelection,
    );
  }

  /// Forgets the pending transition source; returns whether one was pending.
  bool clearTransitionSource() {
    if (_transitionSourceId == null) {
      return false;
    }
    _transitionSourceId = null;
    return true;
  }

  /// Forgets the pending source only when it is [nodeId], for example when the
  /// node is deleted or its options sheet opens.
  bool clearTransitionSourceIf(String nodeId) {
    if (_transitionSourceId != nodeId) {
      return false;
    }
    _transitionSourceId = null;
    return true;
  }

  void resetTapTracking() {
    _lastTapNodeId = null;
    _lastTapTimestamp = null;
    _doubleTapCandidateNodeId = null;
  }

  /// Records a pointer down over [nodeId] (null when the pointer missed every
  /// node) at monotonic time [now]; a second press on the last tapped node
  /// inside the double-tap window arms the double-tap candidate.
  void registerPointerDown(String? nodeId, Duration now) {
    _doubleTapCandidateNodeId = null;
    if (_activeTool != AutomatonCanvasTool.selection) {
      return;
    }
    final previousTap = _lastTapTimestamp;
    if (nodeId == null || nodeId != _lastTapNodeId || previousTap == null) {
      return;
    }
    final elapsed = now - previousTap;
    if (elapsed >= _doubleTapMinTime && elapsed <= _doubleTapTimeout) {
      _doubleTapCandidateNodeId = nodeId;
    }
  }

  /// Resolves a tap that ended on the canvas body.
  CanvasTapOutcome resolveCanvasTap({
    required String? nodeId,
    required bool hasEdgeHits,
    required bool isDragging,
    required Duration now,
  }) {
    switch (_activeTool) {
      case AutomatonCanvasTool.addState:
        if (isDragging || nodeId != null) {
          return const CanvasTapIgnored();
        }
        return const CanvasTapAddState();
      case AutomatonCanvasTool.transition:
        if (nodeId == null) {
          return const CanvasTapIgnored();
        }
        return resolveNodeTap(nodeId, now: now);
      case AutomatonCanvasTool.selection:
        if (isDragging) {
          resetTapTracking();
          return const CanvasTapIgnored();
        }
        if (nodeId == null) {
          resetTapTracking();
          return hasEdgeHits
              ? const CanvasTapEditEdges()
              : const CanvasTapClearSelection();
        }
        return resolveNodeTap(nodeId, now: now);
    }
  }

  /// Resolves a tap on [nodeId] under the active tool.
  CanvasTapOutcome resolveNodeTap(String nodeId, {required Duration now}) {
    switch (_activeTool) {
      case AutomatonCanvasTool.selection:
        if (_doubleTapCandidateNodeId == nodeId) {
          resetTapTracking();
          return CanvasTapSelectNode(nodeId, openContext: true);
        }
        _lastTapNodeId = nodeId;
        _lastTapTimestamp = now;
        _doubleTapCandidateNodeId = null;
        return CanvasTapSelectNode(nodeId, openContext: false);
      case AutomatonCanvasTool.transition:
        final sourceId = _transitionSourceId;
        if (sourceId == null) {
          _transitionSourceId = nodeId;
          return CanvasTapBeginTransition(nodeId);
        }
        _transitionSourceId = null;
        return CanvasTapCompleteTransition(
          sourceId: sourceId,
          targetId: nodeId,
        );
      case AutomatonCanvasTool.addState:
        return const CanvasTapIgnored();
    }
  }
}
