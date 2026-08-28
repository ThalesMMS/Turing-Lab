import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:graphview/graphview_turing_lab.dart';

import '../../../core/constants/automaton_canvas_constants.dart';
import '../../../features/canvas/graphview/base_graphview_canvas_controller.dart';
import '../../../features/canvas/graphview/graphview_canvas_models.dart';
import '../automaton_canvas_tool.dart';

typedef AutomatonGraphNodeBuilder = Widget Function(
  BuildContext context,
  GraphViewCanvasNode node,
  Map<String, int> outgoingCounts,
  Map<String, int> incomingCounts,
);

class _AddStateAtCenterIntent extends Intent {
  const _AddStateAtCenterIntent();
}

class _DeleteSelectionIntent extends Intent {
  const _DeleteSelectionIntent();
}

class _RedoCanvasIntent extends Intent {
  const _RedoCanvasIntent();
}

class _SetCanvasToolIntent extends Intent {
  const _SetCanvasToolIntent(this.tool);

  final AutomatonCanvasTool tool;
}

class _UndoCanvasIntent extends Intent {
  const _UndoCanvasIntent();
}

const Map<ShortcutActivator, Intent> _keyboardShortcuts = {
  SingleActivator(LogicalKeyboardKey.keyA): _AddStateAtCenterIntent(),
  SingleActivator(LogicalKeyboardKey.keyT):
      _SetCanvasToolIntent(AutomatonCanvasTool.transition),
  SingleActivator(LogicalKeyboardKey.keyV):
      _SetCanvasToolIntent(AutomatonCanvasTool.selection),
  SingleActivator(LogicalKeyboardKey.escape):
      _SetCanvasToolIntent(AutomatonCanvasTool.selection),
  SingleActivator(LogicalKeyboardKey.delete): _DeleteSelectionIntent(),
  SingleActivator(LogicalKeyboardKey.backspace): _DeleteSelectionIntent(),
  SingleActivator(LogicalKeyboardKey.keyZ, control: true): _UndoCanvasIntent(),
  SingleActivator(LogicalKeyboardKey.keyZ, meta: true): _UndoCanvasIntent(),
  SingleActivator(LogicalKeyboardKey.keyY, control: true): _RedoCanvasIntent(),
  SingleActivator(LogicalKeyboardKey.keyY, meta: true): _RedoCanvasIntent(),
  SingleActivator(LogicalKeyboardKey.keyZ, control: true, shift: true):
      _RedoCanvasIntent(),
  SingleActivator(LogicalKeyboardKey.keyZ, meta: true, shift: true):
      _RedoCanvasIntent(),
};

const double _kTransitionModeIndicatorTop = 76.0;

/// Rendering boundary for the automaton canvas.
///
/// This widget owns no domain or controller lifecycle. It renders a supplied
/// revision and reports user/viewport events to the coordinator above it.
class AutomatonGraphViewCanvasSurface extends StatelessWidget {
  const AutomatonGraphViewCanvasSurface({
    super.key,
    required this.canvasKey,
    required this.controller,
    required this.focusNode,
    required this.nodeDraggingConfiguration,
    required this.algorithm,
    required this.activeTool,
    required this.suppressCanvasPan,
    required this.isDraggingNode,
    required this.graphAnimationEnabled,
    required this.viewportAnimationDuration,
    required this.nodeAnimationDuration,
    required this.canvasSemanticsLabel,
    required this.canvasSemanticsHint,
    required this.transitionPrompt,
    required this.chooseTargetPrompt,
    required this.hasTransitionSource,
    required this.transitionSemanticsLayer,
    required this.transitionPreview,
    required this.nodeBuilder,
    required this.onViewportChanged,
    required this.onPointerDown,
    required this.onPointerHover,
    required this.onTapDown,
    required this.onTapUp,
    required this.onLongPressStart,
    required this.onSecondaryTapUp,
    required this.onAddStateAtCenter,
    required this.onDeleteSelection,
    required this.onUndo,
    required this.onRedo,
    required this.onActivateTool,
  });

  final GlobalKey canvasKey;
  final BaseGraphViewCanvasController<dynamic, dynamic> controller;
  final FocusNode focusNode;
  final NodeDraggingConfiguration nodeDraggingConfiguration;
  final Algorithm algorithm;
  final AutomatonCanvasTool activeTool;
  final bool suppressCanvasPan;
  final bool isDraggingNode;
  final bool graphAnimationEnabled;
  final Duration viewportAnimationDuration;
  final Duration nodeAnimationDuration;
  final String Function() canvasSemanticsLabel;
  final String canvasSemanticsHint;
  final String transitionPrompt;
  final String chooseTargetPrompt;
  final bool hasTransitionSource;
  final Widget transitionSemanticsLayer;
  final Widget transitionPreview;
  final AutomatonGraphNodeBuilder nodeBuilder;
  final ValueChanged<Size> onViewportChanged;
  final ValueChanged<PointerDownEvent> onPointerDown;
  final ValueChanged<PointerHoverEvent> onPointerHover;
  final ValueChanged<TapDownDetails> onTapDown;
  final ValueChanged<TapUpDetails> onTapUp;
  final ValueChanged<LongPressStartDetails> onLongPressStart;
  final ValueChanged<TapUpDetails> onSecondaryTapUp;
  final VoidCallback onAddStateAtCenter;
  final VoidCallback onDeleteSelection;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final ValueChanged<AutomatonCanvasTool> onActivateTool;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canvas = Shortcuts(
      shortcuts: _keyboardShortcuts,
      child: Actions(
        actions: <Type, Action<Intent>>{
          _AddStateAtCenterIntent: CallbackAction<_AddStateAtCenterIntent>(
            onInvoke: (_) => _invoke(onAddStateAtCenter),
          ),
          _DeleteSelectionIntent: CallbackAction<_DeleteSelectionIntent>(
            onInvoke: (_) => _invoke(onDeleteSelection),
          ),
          _RedoCanvasIntent: CallbackAction<_RedoCanvasIntent>(
            onInvoke: (_) => _invoke(onRedo),
          ),
          _SetCanvasToolIntent: CallbackAction<_SetCanvasToolIntent>(
            onInvoke: (intent) => _invoke(
              () => onActivateTool(intent.tool),
            ),
          ),
          _UndoCanvasIntent: CallbackAction<_UndoCanvasIntent>(
            onInvoke: (_) => _invoke(onUndo),
          ),
        },
        child: Focus(
          focusNode: focusNode,
          autofocus: true,
          child: Listener(
            key: canvasKey,
            behavior: HitTestBehavior.translucent,
            onPointerDown: onPointerDown,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapDown: onTapDown,
              onTapUp: onTapUp,
              onLongPressStart: onLongPressStart,
              onSecondaryTapUp: onSecondaryTapUp,
              child: ValueListenableBuilder<int>(
                valueListenable: controller.graphRevision,
                builder: (context, _, __) => _buildRevision(context, theme),
              ),
            ),
          ),
        ),
      ),
    );
    return MouseRegion(
      key: const ValueKey('automaton-canvas-pointer-region'),
      cursor: activeTool == AutomatonCanvasTool.transition
          ? SystemMouseCursors.precise
          : MouseCursor.defer,
      onHover: onPointerHover,
      child: canvas,
    );
  }

  Object? _invoke(VoidCallback callback) {
    callback();
    return null;
  }

  Widget _buildRevision(BuildContext context, ThemeData theme) {
    final outgoingCounts = <String, int>{};
    final incomingCounts = <String, int>{};
    for (final edge in controller.edges) {
      outgoingCounts.update(
        edge.fromStateId,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
      incomingCounts.update(
        edge.toStateId,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }
    return Stack(
      children: [
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) {
              onViewportChanged(constraints.biggest);
              return RepaintBoundary(
                child: AbsorbPointer(
                  // Pan and pinch-zoom stay live in every tool; only an
                  // in-flight node drag suppresses the viewport gestures.
                  absorbing: suppressCanvasPan,
                  child: Semantics(
                    key: const ValueKey(
                      'automaton-canvas-viewport-semantics',
                    ),
                    container: true,
                    explicitChildNodes: true,
                    label: canvasSemanticsLabel(),
                    hint: canvasSemanticsHint,
                    child: GraphView.builder(
                      graph: controller.graph,
                      controller: controller.graphController,
                      nodeDraggingConfig: nodeDraggingConfiguration,
                      minScale: kAutomatonCanvasMinScale,
                      maxScale: kAutomatonCanvasMaxScale,
                      algorithm: algorithm,
                      animated: graphAnimationEnabled && !isDraggingNode,
                      panAnimationDuration: viewportAnimationDuration,
                      toggleAnimationDuration: nodeAnimationDuration,
                      paint: Paint()
                        ..color = theme.colorScheme.outline
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = 2
                        ..strokeCap = StrokeCap.round,
                      builder: (node) {
                        final nodeId = node.key?.value?.toString();
                        if (nodeId == null) {
                          return const SizedBox.shrink();
                        }
                        final canvasNode = controller.nodeById(nodeId) ??
                            GraphViewCanvasNode(
                              id: nodeId,
                              label: nodeId,
                              x: node.position.dx,
                              y: node.position.dy,
                              isInitial: false,
                              isAccepting: false,
                            );
                        return nodeBuilder(
                          context,
                          canvasNode,
                          outgoingCounts,
                          incomingCounts,
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Positioned.fill(child: transitionSemanticsLayer),
        if (activeTool == AutomatonCanvasTool.transition && hasTransitionSource)
          Positioned.fill(child: transitionPreview),
        if (activeTool == AutomatonCanvasTool.transition)
          Positioned(
            top: _kTransitionModeIndicatorTop,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(
                child: DecoratedBox(
                  key: const ValueKey(
                    'automaton-transition-mode-indicator',
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.link,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          hasTransitionSource
                              ? chooseTargetPrompt
                              : transitionPrompt,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
