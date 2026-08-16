//
//  automaton_graphview_canvas.dart
//  Turing Lab
//
//  Implementa o canvas interativo baseado em GraphView responsável por editar e
//  visualizar autômatos nos diferentes modos do aplicativo, coordenando
//  ferramentas, arrastos de estados, criação de transições e emissão de destaques
//  durante simulações.
//  Orquestra controladores especializados para FSA, PDA e TM, integra editores de
//  rótulos, sobreposições contextuais e sincronização com providers Riverpod para
//  manter o modelo consistente mesmo em autômatos de grande porte.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'dart:developer' show Timeline;
import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphview/graphview_turing_lab.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;

import '../../core/constants/automaton_canvas_constants.dart';
import '../../core/models/automaton.dart';
import '../../core/models/simulation_highlight.dart';
import '../../core/services/highlight_channel.dart';
import '../../core/services/simulation_highlight_service.dart';
import '../../core/models/tm_transition.dart' show TapeDirection;
import '../../features/canvas/graphview/base_graphview_canvas_controller.dart';
import '../../features/canvas/graphview/graphview_canvas_controller.dart';
import '../../features/canvas/graphview/graphview_canvas_models.dart';
import '../../features/canvas/graphview/graphview_highlight_channel.dart';
import '../../features/canvas/graphview/turing_lab_adaptive_edge_renderer.dart';
import '../../features/canvas/graphview/graphview_label_field_editor.dart';
import '../../features/canvas/graphview/grouped_fsa_geometry.dart';
import '../../features/canvas/graphview/graphview_link_overlay_utils.dart';
import '../../features/canvas/graphview/graphview_pda_canvas_controller.dart';
import '../../features/canvas/graphview/graphview_tm_canvas_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/app_localizations_resolver.dart';
import '../providers/automaton_state_provider.dart';
import 'automaton_canvas_tool.dart';
import 'pda/stack_drawer.dart';
import 'transition_editors/pda_transition_editor.dart';
import 'transition_editors/tm_transition_operations_editor.dart';

part 'automaton_graphview_canvas_models.dart';
part 'automaton_graphview_canvas_overlay.dart';
part 'automaton_graphview_canvas_rendering.dart';
part 'automaton_graphview_canvas_interactions.dart';

const Map<ShortcutActivator, Intent> _canvasKeyboardShortcuts = {
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

const DeepCollectionEquality _automatonContentEquality =
    DeepCollectionEquality();

bool _hasCanvasAutomatonContentChanged(Object? previous, Object? next) {
  if (identical(previous, next)) {
    return false;
  }
  return !_automatonContentEquality.equals(
    _automatonContentSignature(previous),
    _automatonContentSignature(next),
  );
}

Object? _automatonContentSignature(Object? data) {
  if (data is! Automaton) {
    return data;
  }

  final json = Map<String, dynamic>.from(data.toJson())
    ..remove('created')
    ..remove('modified');
  return _canonicalSignatureValue(json);
}

Object? _canonicalSignatureValue(Object? value) {
  if (value is Map) {
    final entries = value.entries.toList()
      ..sort(
        (left, right) => left.key.toString().compareTo(
              right.key.toString(),
            ),
      );
    return {
      for (final entry in entries)
        entry.key.toString(): _canonicalSignatureValue(entry.value),
    };
  }

  if (value is Iterable && value is! String) {
    final items = value.map(_canonicalSignatureValue).toList()
      ..sort(
        (left, right) => _canonicalSignatureSortKey(left).compareTo(
          _canonicalSignatureSortKey(right),
        ),
      );
    return items;
  }

  if (value is math.Rectangle) {
    return {
      'left': value.left,
      'top': value.top,
      'width': value.width,
      'height': value.height,
    };
  }

  if (value is vmath.Vector2) {
    return {'x': value.x, 'y': value.y};
  }

  return value;
}

String _canonicalSignatureSortKey(Object? value) {
  if (value is Map) {
    final entries = value.entries.toList()
      ..sort(
        (left, right) => left.key.toString().compareTo(
              right.key.toString(),
            ),
      );
    return entries
        .map(
          (entry) => '${entry.key}:${_canonicalSignatureSortKey(entry.value)}',
        )
        .join('|');
  }

  if (value is Iterable && value is! String) {
    return value.map(_canonicalSignatureSortKey).join(',');
  }

  return value?.toString() ?? 'null';
}

class AutomatonGraphViewCanvas extends ConsumerStatefulWidget {
  const AutomatonGraphViewCanvas({
    super.key,
    required this.automaton,
    required this.canvasKey,
    this.controller,
    this.toolController,
    this.customization,
  })  : assert(
          customization is! _ReadOnlyAutomatonGraphViewCanvasCustomization ||
              controller != null,
          'Read-only canvases require an external controller.',
        ),
        assert(
          controller == null ||
              controller is GraphViewCanvasController ||
              customization != null,
          'Non-FSA external controllers require explicit customization.',
        );

  final Object? automaton;
  final GlobalKey canvasKey;
  final BaseGraphViewCanvasController<dynamic, dynamic>? controller;
  final AutomatonCanvasToolController? toolController;
  final AutomatonGraphViewCanvasCustomization? customization;

  @override
  ConsumerState<AutomatonGraphViewCanvas> createState() =>
      _AutomatonGraphViewCanvasState();
}

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

class _AutomatonGraphViewCanvasState
    extends ConsumerState<AutomatonGraphViewCanvas>
    with TickerProviderStateMixin {
  late BaseGraphViewCanvasController<dynamic, dynamic> _controller;
  late bool _ownsController;
  late AutomatonCanvasToolController _toolController;
  late bool _ownsToolController;
  AutomatonCanvasTool _activeTool = AutomatonCanvasTool.selection;
  SimulationHighlightService? _highlightService;
  HighlightChannel? _previousHighlightChannel;
  late _AutomatonGraphSugiyamaAlgorithm _algorithm;
  final Set<String> _selectedTransitions = <String>{};
  String? _selectedNodeId;
  String? _transitionSourceId;
  Offset? _transitionPointerLocalPosition;
  OverlayEntry? _transitionOverlayEntry;
  final ValueNotifier<_GraphViewTransitionOverlayState?>
      _transitionOverlayState =
      ValueNotifier<_GraphViewTransitionOverlayState?>(
    null,
  );
  Object? _pendingSyncAutomaton;
  bool _syncScheduled = false;
  String? _draggingNodeId;
  Offset? _dragStartWorldPosition;
  Offset? _dragStartNodePosition;
  Offset? _dragCurrentNodePosition;
  Offset? _dragPointerStartLocalPosition;
  Offset? _dragPointerCurrentLocalPosition;
  double? _dragHitSlop;
  late final _NodePanGestureRecognizer _nodePanGestureRecognizer;
  late final NodeDraggingConfiguration _nodePointerConfiguration;
  bool _suppressCanvasPan = false;
  bool _isDisposing = false;
  String? _lastTapNodeId;
  Duration? _lastTapTimestamp;
  String? _doubleTapCandidateNodeId;
  final Stopwatch _monotonicStopwatch = Stopwatch()..start();
  bool _isDraggingNode = false;
  bool _didMoveDraggedNode = false;
  late AutomatonGraphViewCanvasCustomization _customization;
  late AutomatonGraphViewTransitionConfig _transitionConfig;
  late final AnimationController _edgeAnimationController;
  late final TuringLabAdaptiveEdgeRenderer _edgeRenderer;
  late final FocusNode _canvasFocusNode;
  bool _hasEdgeRenderer = false;
  String? _lastEdgeStructureSignature;
  Color? _edgeBaseColor;
  Color? _edgeHighlightColor;
  Color? _edgeLabelSurfaceColor;

  void _setCanvasPanSuppressed(bool value, {String reason = ''}) {
    if (!mounted || _isDisposing) {
      return;
    }
    if (_suppressCanvasPan == value) {
      return;
    }
    if (kDebugMode) {
      debugPrint(
        '[AutomatonGraphViewCanvas] suppressPan=$value reason=$reason',
      );
    }
    setState(() {
      _suppressCanvasPan = value;
    });
  }

  void _setTransitionSourceId(String? nodeId) {
    if (!mounted) {
      return;
    }
    final sourceNode = nodeId == null ? null : _controller.nodeById(nodeId);
    final fallbackPointer = sourceNode == null
        ? null
        : _worldToCanvasLocal(resolveNodeCenter(sourceNode));
    setState(() {
      _transitionSourceId = nodeId;
      _transitionPointerLocalPosition = nodeId == null
          ? null
          : _transitionPointerLocalPosition ?? fallbackPointer;
    });
  }

  Offset _worldToCanvasLocal(Offset worldPosition) {
    final transformation =
        _controller.graphController.transformationController?.value;
    if (transformation == null) {
      return worldPosition;
    }
    final vector = transformation.transform3(
      vmath.Vector3(worldPosition.dx, worldPosition.dy, 0),
    );
    return Offset(vector.x, vector.y);
  }

  void _updateTransitionPointerLocal(Offset localPosition) {
    if (!mounted ||
        _activeTool != AutomatonCanvasTool.transition ||
        _transitionPointerLocalPosition == localPosition) {
      return;
    }
    if (_transitionSourceId == null) {
      _transitionPointerLocalPosition = localPosition;
      return;
    }
    setState(() {
      _transitionPointerLocalPosition = localPosition;
    });
  }

  void _setSelectedNodeId(String? nodeId) {
    if (!mounted || _selectedNodeId == nodeId) {
      return;
    }
    setState(() {
      _selectedNodeId = nodeId;
      if (nodeId != null) {
        _selectedTransitions.clear();
      }
    });
  }

  void _updateCanvasState(VoidCallback callback) {
    if (!mounted) {
      return;
    }
    setState(callback);
  }

  @override
  void initState() {
    super.initState();
    final externalToolController = widget.toolController;
    if (externalToolController != null) {
      _toolController = externalToolController;
      _ownsToolController = false;
    } else {
      _toolController = AutomatonCanvasToolController();
      _ownsToolController = true;
    }
    _activeTool = _toolController.activeTool;
    _toolController.addListener(_handleActiveToolChanged);
    _canvasFocusNode = FocusNode(debugLabel: 'Automaton graph canvas');

    final externalController = widget.controller;
    if (externalController != null) {
      _controller = externalController;
      _ownsController = false;
    } else {
      final notifier = ref.read(automatonStateProvider.notifier);
      _controller = GraphViewCanvasController(automatonStateNotifier: notifier);
      _ownsController = true;
      final highlightService = ref.read(canvasHighlightServiceProvider);
      _highlightService = highlightService;
      _previousHighlightChannel = highlightService.channel;
      final highlightChannel = GraphViewSimulationHighlightChannel(_controller);
      highlightService.channel = highlightChannel;
    }

    _applyCustomization(widget.customization);
    _nodePanGestureRecognizer = _NodePanGestureRecognizer(
      hitTester: (global) => _customization.enableStateDrag
          ? _hitTestNode(
              _globalToCanvasLocal(global),
              logDetails: false,
            )
          : null,
      toolResolver: () => _activeTool,
      onDragReleased: () => _setCanvasPanSuppressed(
        false,
        reason: 'node pointer released',
      ),
    )
      ..onStart = _handleNodePanStart
      ..onUpdate = _handleNodePanUpdate
      ..onEnd = _handleNodePanEnd
      ..onCancel = _handleNodePanCancel
      ..dragStartBehavior = DragStartBehavior.down
      ..onlyAcceptDragOnThreshold = true;
    _nodePointerConfiguration = NodeDraggingConfiguration(
      enabled: false,
      onNodePointerDown: (_, event) {
        _nodePanGestureRecognizer.addPointer(event);
      },
    );
    _edgeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..addListener(_handleEdgeAnimationTick);
    _edgeRenderer = TuringLabAdaptiveEdgeRenderer(
      config: EdgeRoutingConfig(
        anchorMode: AnchorMode.dynamic,
        routingMode: RoutingMode.bezier,
        enableRepulsion: true,
      ),
      animationConfig: const AnimatedEdgeConfiguration(
        animationSpeed: 1.0,
        particleCount: 3,
        particleSize: 3.0,
      ),
      renderMode: _customization.edgeRenderMode,
    );
    _hasEdgeRenderer = true;
    _edgeRenderer.setAnimationValue(_edgeAnimationController.value);
    _algorithm = _AutomatonGraphSugiyamaAlgorithm(
      configuration: _buildConfiguration(),
    );
    _algorithm.renderer = _edgeRenderer;
    _scheduleControllerSync(widget.automaton);
    _controller.graphRevision.addListener(_handleGraphRevisionChanged);
    _controller.highlightNotifier.addListener(_handleHighlightChanged);
    _handleHighlightChanged();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_controller.graph.nodes.isNotEmpty) {
        _controller.fitToContent();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _nodePanGestureRecognizer.gestureSettings =
        MediaQuery.maybeGestureSettingsOf(context);
  }

  @override
  void didUpdateWidget(covariant AutomatonGraphViewCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    var shouldReapplyCustomization = false;
    if (oldWidget.toolController != widget.toolController) {
      _toolController.removeListener(_handleActiveToolChanged);
      if (_ownsToolController) {
        _toolController.dispose();
      }
      final nextController =
          widget.toolController ?? AutomatonCanvasToolController();
      _toolController = nextController;
      _ownsToolController = widget.toolController == null;
      _toolController.addListener(_handleActiveToolChanged);
      _activeTool = _toolController.activeTool;
      shouldReapplyCustomization = true;
    }

    if (oldWidget.controller != widget.controller) {
      _controller.graphRevision.removeListener(_handleGraphRevisionChanged);
      _controller.highlightNotifier.removeListener(_handleHighlightChanged);
      if (_ownsController) {
        if (_highlightService != null) {
          _highlightService!.channel = _previousHighlightChannel;
        }
        _controller.dispose();
      }
      final externalController = widget.controller;
      if (externalController != null) {
        _controller = externalController;
        _ownsController = false;
        _highlightService = null;
        _previousHighlightChannel = null;
      } else {
        final notifier = ref.read(automatonStateProvider.notifier);
        _controller = GraphViewCanvasController(
          automatonStateNotifier: notifier,
        );
        _ownsController = true;
        final highlightService = ref.read(canvasHighlightServiceProvider);
        _highlightService = highlightService;
        _previousHighlightChannel = highlightService.channel;
        final highlightChannel = GraphViewSimulationHighlightChannel(
          _controller,
        );
        highlightService.channel = highlightChannel;
      }
      _algorithm = _AutomatonGraphSugiyamaAlgorithm(
        configuration: _buildConfiguration(),
      );
      _algorithm.renderer = _edgeRenderer;
      _scheduleControllerSync(widget.automaton);
      _lastEdgeStructureSignature = null;
      _controller.graphRevision.addListener(_handleGraphRevisionChanged);
      _controller.highlightNotifier.addListener(_handleHighlightChanged);
      _handleHighlightChanged();
      _hideTransitionOverlay();
      shouldReapplyCustomization = true;
    } else if (_hasCanvasAutomatonContentChanged(
      oldWidget.automaton,
      widget.automaton,
    )) {
      _scheduleControllerSync(widget.automaton);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _refreshTransitionOverlayFromGraph();
      });
    }

    if (shouldReapplyCustomization ||
        oldWidget.customization != widget.customization) {
      _applyCustomization(widget.customization);
    }
  }

  @override
  void dispose() {
    _isDisposing = true;
    _controller.graphRevision.removeListener(_handleGraphRevisionChanged);
    _controller.highlightNotifier.removeListener(_handleHighlightChanged);
    _toolController.removeListener(_handleActiveToolChanged);
    _nodePanGestureRecognizer.dispose();
    _canvasFocusNode.dispose();
    _edgeAnimationController
      ..removeListener(_handleEdgeAnimationTick)
      ..dispose();
    if (_ownsToolController) {
      _toolController.dispose();
    }
    if (_ownsController) {
      _controller.dispose();
    }
    if (_highlightService != null) {
      _highlightService!.channel = _previousHighlightChannel;
    }
    _transitionOverlayEntry?.remove();
    _transitionOverlayEntry = null;
    _transitionOverlayState.dispose();
    super.dispose();
  }

  void _handleActiveToolChanged() {
    final nextTool = _toolController.activeTool;
    if (!_customization.enableToolSelection &&
        nextTool != AutomatonCanvasTool.selection) {
      _toolController.setActiveTool(AutomatonCanvasTool.selection);
      return;
    }
    if (nextTool == _activeTool) {
      return;
    }
    setState(() {
      _activeTool = nextTool;
      if (_activeTool != AutomatonCanvasTool.transition) {
        _transitionSourceId = null;
        _transitionPointerLocalPosition = null;
      }
      if (_activeTool != AutomatonCanvasTool.selection) {
        _selectedNodeId = null;
        _lastTapNodeId = null;
        _lastTapTimestamp = null;
        _doubleTapCandidateNodeId = null;
      }
    });
    debugPrint(
      '[AutomatonGraphViewCanvas] Active tool set to '
      '${nextTool.name}',
    );
    if (nextTool != AutomatonCanvasTool.transition) {
      _hideTransitionOverlay();
    }
  }

  void _handleEdgeAnimationTick() {
    _edgeRenderer.setAnimationValue(_edgeAnimationController.value);
    _controller.graph.notifyGraphObserver();
  }

  void _handleHighlightChanged() {
    _updateEdgeAppearance(_controller.highlightNotifier.value);
    _controller.graph.notifyGraphObserver();
    final hasHighlightedTransitions =
        _controller.highlightNotifier.value.transitionIds.isNotEmpty;
    if (hasHighlightedTransitions) {
      if (!_edgeAnimationController.isAnimating) {
        _edgeAnimationController.repeat();
      }
      return;
    }

    if (_edgeAnimationController.isAnimating) {
      _edgeAnimationController.stop();
    }
    if (_edgeAnimationController.value != 0) {
      _edgeAnimationController.value = 0;
      _edgeRenderer.setAnimationValue(0);
    }
  }

  void _updateEdgeAppearance(SimulationHighlight highlight) {
    final baseColor = _edgeBaseColor;
    final highlightColor = _edgeHighlightColor;
    final labelSurfaceColor = _edgeLabelSurfaceColor;
    if (baseColor == null ||
        highlightColor == null ||
        labelSurfaceColor == null) {
      return;
    }
    _edgeRenderer.updateAppearance(
      highlightedEdgeIds: highlight.transitionIds,
      selectedEdgeIds: _selectedTransitions,
      baseColor: baseColor,
      highlightColor: highlightColor,
      labelSurfaceColor: labelSurfaceColor,
    );
  }

  void _applyCustomization(
    AutomatonGraphViewCanvasCustomization? customization,
  ) {
    final resolved =
        customization ?? AutomatonGraphViewCanvasCustomization.fsa();
    _customization = resolved;
    _transitionConfig = resolved.transitionConfigBuilder(_controller);
    if (_hasEdgeRenderer) {
      _edgeRenderer.renderMode = resolved.edgeRenderMode;
    }
    if (!_customization.enableToolSelection &&
        _toolController.activeTool != AutomatonCanvasTool.selection) {
      _toolController.setActiveTool(AutomatonCanvasTool.selection);
    }
    _activeTool = _toolController.activeTool;
  }

  void _scheduleControllerSync(Object? data) {
    _pendingSyncAutomaton = data;
    if (_syncScheduled) {
      return;
    }
    _syncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncScheduled = false;
      if (!mounted) {
        _pendingSyncAutomaton = null;
        return;
      }
      final target = _pendingSyncAutomaton;
      _pendingSyncAutomaton = null;
      try {
        _controller.synchronize(target);
      } catch (error, stackTrace) {
        if (kDebugMode) {
          debugPrint(
            '[AutomatonGraphViewCanvas] Failed to synchronize controller: '
            '$error',
          );
          debugPrint(stackTrace.toString());
        }
      }
    });
  }

  SugiyamaConfiguration _buildConfiguration() {
    final configuration = SugiyamaConfiguration()
      ..orientation = SugiyamaConfiguration.ORIENTATION_LEFT_RIGHT
      ..nodeSeparation = 160
      ..levelSeparation = 160
      ..bendPointShape = CurvedBendPointShape(curveLength: 40);
    return configuration;
  }

  Offset _screenToWorld(Offset localPosition) =>
      _screenToWorldExtracted(localPosition);

  GraphViewCanvasNode? _hitTestNode(
    Offset localPosition, {
    bool logDetails = true,
  }) =>
      _hitTestNodeExtracted(localPosition, logDetails: logDetails);

  Offset _globalToCanvasLocal(Offset globalPosition) =>
      _globalToCanvasLocalExtracted(globalPosition);

  void _logCanvasTapFromLocal({
    required String source,
    required Offset localPosition,
  }) =>
      _logCanvasTapFromLocalExtracted(
        source: source,
        localPosition: localPosition,
      );

  void _logCanvasTapFromGlobal({
    required String source,
    required Offset globalPosition,
  }) =>
      _logCanvasTapFromGlobalExtracted(
        source: source,
        globalPosition: globalPosition,
      );

  void _handleCanvasTapDown(TapDownDetails details) =>
      _handleCanvasTapDownExtracted(details);

  void _handleCanvasTapDownWithFocus(TapDownDetails details) {
    _canvasFocusNode.requestFocus();
    _updateTransitionPointerLocal(details.localPosition);
    _handleCanvasTapDown(details);
  }

  void _handleCanvasPointerHover(PointerHoverEvent event) {
    _updateTransitionPointerLocal(event.localPosition);
  }

  void _handleCanvasLongPressStart(LongPressStartDetails details) =>
      _handleCanvasLongPressStartExtracted(details);

  void _handleCanvasSecondaryTapUp(TapUpDetails details) =>
      _handleCanvasSecondaryTapUpExtracted(details);

  void _handleNodePointerDown(Offset globalPosition) =>
      _handleNodePointerDownExtracted(globalPosition);

  void _beginNodeDrag(GraphViewCanvasNode node, Offset localPosition) =>
      _beginNodeDragExtracted(node, localPosition);

  void _updateNodeDrag(Offset localPosition) =>
      _updateNodeDragExtracted(localPosition);

  void _endNodeDrag() => _endNodeDragExtracted();

  Future<void> _handleCanvasTapUp(TapUpDetails details) =>
      _handleCanvasTapUpExtracted(details);

  void _handleNodePanStart(DragStartDetails details) =>
      _handleNodePanStartExtracted(details);

  void _handleNodePanUpdate(DragUpdateDetails details) =>
      _handleNodePanUpdateExtracted(details);

  void _handleNodePanEnd(DragEndDetails details) =>
      _handleNodePanEndExtracted(details);

  void _handleNodePanCancel() => _handleNodePanCancelExtracted();

  void _handleNodeTap(String nodeId) => _handleNodeTapExtracted(nodeId);

  void _handleNodeContextTap(String nodeId) =>
      _handleNodeContextTapExtracted(nodeId);

  void _registerNodeTap(String nodeId) => _registerNodeTapExtracted(nodeId);

  Future<void> _showStateOptions(GraphViewCanvasNode node) =>
      _showStateOptionsExtracted(node);

  List<GraphViewCanvasEdge> _findExistingEdges(String fromId, String toId) =>
      _findExistingEdgesExtracted(fromId, toId);

  Future<void> _showTransitionEditor(String fromId, String toId) =>
      _showTransitionEditorExtracted(fromId, toId);

  Future<_TransitionEditChoice?> _promptTransitionEditChoice(
    List<GraphViewCanvasEdge> edges,
  ) =>
      _promptTransitionEditChoiceExtracted(edges);

  Offset _deriveControlPoint(String fromId, String toId) =>
      _deriveControlPointExtracted(fromId, toId);

  void _handleGraphRevisionChanged() => _handleGraphRevisionChangedExtracted();

  void _invalidateEdgeRendererCachesIfNeeded() {
    final signature = _computeEdgeStructureSignature();
    if (signature == _lastEdgeStructureSignature) {
      return;
    }
    _lastEdgeStructureSignature = signature;
    if (_hasEdgeRenderer) {
      _edgeRenderer.invalidateEdgeCaches();
    }
  }

  String _computeEdgeStructureSignature() {
    final edges = _controller.edges.sortedBy((edge) => edge.id);
    final buffer = StringBuffer()..write(edges.length);
    for (final edge in edges) {
      buffer
        ..write('|')
        ..write(edge.id)
        ..write(':')
        ..write(edge.fromStateId)
        ..write('->')
        ..write(edge.toStateId)
        ..write(':')
        ..write(edge.label);
    }
    return buffer.toString();
  }

  void _refreshTransitionOverlayFromGraph() =>
      _refreshTransitionOverlayFromGraphExtracted();

  bool _showTransitionOverlay(AutomatonTransitionOverlayData data) =>
      _showTransitionOverlayExtracted(data);

  void _ensureTransitionOverlay(OverlayState overlayState) =>
      _ensureTransitionOverlayExtracted(overlayState);

  void _handleOverlaySubmit(
    _GraphViewTransitionOverlayState state,
    AutomatonTransitionPayload payload,
  ) =>
      _handleOverlaySubmitExtracted(state, payload);

  void _hideTransitionOverlay() => _hideTransitionOverlayExtracted();

  bool _hasEditableTextFocus() {
    final focusContext = FocusManager.instance.primaryFocus?.context;
    if (focusContext == null) {
      return false;
    }
    return focusContext.widget is EditableText ||
        focusContext.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  void _activateKeyboardTool(AutomatonCanvasTool tool) {
    if (_hasEditableTextFocus() ||
        (tool != AutomatonCanvasTool.selection &&
            !_customization.enableToolSelection)) {
      return;
    }
    if (tool == AutomatonCanvasTool.selection) {
      _setTransitionSourceId(null);
    }
    _toolController.setActiveTool(tool);
  }

  void _addStateAtCenterFromKeyboard() {
    if (_hasEditableTextFocus() || !_customization.enableToolSelection) {
      return;
    }
    _controller.addStateAtCenter();
  }

  void _deleteSelection() {
    if (_hasEditableTextFocus() || !_customization.enableToolSelection) {
      return;
    }
    final selectedNodeId = _selectedNodeId;
    if (selectedNodeId != null) {
      _controller.removeState(selectedNodeId);
      _setSelectedNodeId(null);
      return;
    }
    if (_selectedTransitions.isEmpty) {
      return;
    }
    final selectedTransitionIds = _selectedTransitions.toList(growable: false);
    for (final transitionId in selectedTransitionIds) {
      _removeTransitionById(transitionId);
    }
    _updateCanvasState(() {
      _selectedTransitions.removeAll(selectedTransitionIds);
    });
  }

  void _removeTransitionById(String transitionId) {
    _controller.removeTransition(transitionId);
  }

  void _redoCanvasFromKeyboard() {
    if (_hasEditableTextFocus() ||
        !_customization.enableToolSelection ||
        !_controller.canRedo) {
      return;
    }
    _controller.redo();
  }

  void _undoCanvasFromKeyboard() {
    if (_hasEditableTextFocus() ||
        !_customization.enableToolSelection ||
        !_controller.canUndo) {
      return;
    }
    _controller.undo();
  }

  String _canvasSemanticsLabel() {
    final l10n = appLocalizationsOf(context);
    return l10n.canvasViewportSemantics(
      l10n.canvasViewportStateCount(_controller.nodes.length),
      l10n.canvasViewportTransitionCount(_controller.edges.length),
    );
  }

  String _nodeSemanticsLabel(GraphViewCanvasNode node) {
    final l10n = appLocalizationsOf(context);
    final outgoingCount =
        _controller.edges.where((edge) => edge.fromStateId == node.id).length;
    final incomingCount =
        _controller.edges.where((edge) => edge.toStateId == node.id).length;
    final parts = <String>[
      l10n.canvasStateSemantics(node.label.isEmpty ? node.id : node.label),
      if (node.isInitial) l10n.canvasInitialStateSemantics,
      if (node.isAccepting) l10n.canvasAcceptingStateSemantics,
      l10n.canvasOutgoingTransitionCount(outgoingCount),
      l10n.canvasIncomingTransitionCount(incomingCount),
    ];
    return parts.join(' ');
  }

  String _edgeSemanticsLabel(GraphViewCanvasEdge edge) {
    final l10n = appLocalizationsOf(context);
    final fromLabel = _controller.nodeById(edge.fromStateId)?.label;
    final toLabel = _controller.nodeById(edge.toStateId)?.label;
    final from =
        (fromLabel?.isNotEmpty == true) ? fromLabel! : edge.fromStateId;
    final to = (toLabel?.isNotEmpty == true) ? toLabel! : edge.toStateId;
    final label =
        edge.label.isEmpty ? l10n.canvasUnlabeledTransition : edge.label;
    final parts = <String>[
      l10n.canvasTransitionSemantics(edge.id, from, to, label),
      if (_selectedTransitions.contains(edge.id))
        l10n.canvasSelectedTransitionSemantics,
    ];
    return parts.join(' ');
  }

  Widget _buildTransitionSemanticsLayer() {
    final edges = _controller.edges.sortedBy((edge) => edge.id);
    if (edges.isEmpty) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      child: Opacity(
        opacity: 0,
        alwaysIncludeSemantics: true,
        child: Column(
          children: [
            for (final edge in edges)
              Semantics(
                label: _edgeSemanticsLabel(edge),
                child: const SizedBox(width: 1, height: 1),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransitionPreview(Color color) {
    final sourceId = _transitionSourceId;
    final pointer = _transitionPointerLocalPosition;
    final sourceNode = sourceId == null ? null : _controller.nodeById(sourceId);
    if (sourceNode == null || pointer == null) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      child: CustomPaint(
        key: const ValueKey('automaton-transition-preview'),
        painter: _TransitionPreviewPainter(
          start: _worldToCanvasLocal(resolveNodeCenter(sourceNode)),
          end: pointer,
          color: color,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = appLocalizationsOf(context);
    _edgeBaseColor = theme.colorScheme.outline;
    _edgeHighlightColor = theme.colorScheme.primary;
    _edgeLabelSurfaceColor = theme.colorScheme.surfaceContainerHighest;
    _updateEdgeAppearance(_controller.highlightNotifier.value);
    final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ??
        WidgetsBinding.instance.platformDispatcher.accessibilityFeatures
            .disableAnimations;
    final motionPreset = disableAnimations
        ? _CanvasMotionPreset.reduced
        : _CanvasMotionPreset.organic;
    final canvas = Shortcuts(
      shortcuts: _canvasKeyboardShortcuts,
      child: Actions(
        actions: <Type, Action<Intent>>{
          _AddStateAtCenterIntent: CallbackAction<_AddStateAtCenterIntent>(
            onInvoke: (_) {
              _addStateAtCenterFromKeyboard();
              return null;
            },
          ),
          _DeleteSelectionIntent: CallbackAction<_DeleteSelectionIntent>(
            onInvoke: (_) {
              _deleteSelection();
              return null;
            },
          ),
          _RedoCanvasIntent: CallbackAction<_RedoCanvasIntent>(
            onInvoke: (_) {
              _redoCanvasFromKeyboard();
              return null;
            },
          ),
          _SetCanvasToolIntent: CallbackAction<_SetCanvasToolIntent>(
            onInvoke: (intent) {
              _activateKeyboardTool(intent.tool);
              return null;
            },
          ),
          _UndoCanvasIntent: CallbackAction<_UndoCanvasIntent>(
            onInvoke: (_) {
              _undoCanvasFromKeyboard();
              return null;
            },
          ),
        },
        child: Focus(
          focusNode: _canvasFocusNode,
          autofocus: true,
          child: Listener(
            key: widget.canvasKey,
            behavior: HitTestBehavior.translucent,
            onPointerDown: (event) {
              _handleNodePointerDown(event.position);
              _nodePanGestureRecognizer.cancelForAdditionalPointer(
                event.pointer,
              );
            },
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapDown: _handleCanvasTapDownWithFocus,
              onTapUp: _handleCanvasTapUp,
              onLongPressStart: _handleCanvasLongPressStart,
              onSecondaryTapUp: _handleCanvasSecondaryTapUp,
              child: ValueListenableBuilder<int>(
                valueListenable: _controller.graphRevision,
                builder: (context, _, __) {
                  return Builder(
                    builder: (context) {
                      return Stack(
                        children: [
                          Positioned.fill(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final viewport = constraints.biggest;
                                if (viewport.width.isFinite &&
                                    viewport.height.isFinite) {
                                  _controller.updateViewportSize(viewport);
                                }
                                return RepaintBoundary(
                                  child: AbsorbPointer(
                                    // Suppress GraphView's own pan handling whenever
                                    // a node drag or tool-specific gesture owns the
                                    // interaction, avoiding mixed canvas/node motion.
                                    absorbing: _suppressCanvasPan ||
                                        _activeTool ==
                                            AutomatonCanvasTool.addState ||
                                        _activeTool ==
                                            AutomatonCanvasTool.transition,
                                    child: Semantics(
                                      container: true,
                                      explicitChildNodes: true,
                                      label: _canvasSemanticsLabel(),
                                      hint: l10n.canvasViewportEditHint,
                                      child: GraphView.builder(
                                        graph: _controller.graph,
                                        controller: _controller.graphController,
                                        nodeDraggingConfig:
                                            _nodePointerConfiguration,
                                        minScale: kAutomatonCanvasMinScale,
                                        maxScale: kAutomatonCanvasMaxScale,
                                        algorithm: _algorithm,
                                        animated: motionPreset
                                                .graphAnimationEnabled &&
                                            !_isDraggingNode,
                                        panAnimationDuration:
                                            motionPreset.viewportDuration,
                                        toggleAnimationDuration:
                                            motionPreset.nodeDuration,
                                        paint: Paint()
                                          ..color = theme.colorScheme.outline
                                          ..style = PaintingStyle.stroke
                                          ..strokeWidth = 2
                                          ..strokeCap = StrokeCap.round,
                                        builder: (node) {
                                          final nodeId =
                                              node.key?.value?.toString();
                                          if (nodeId == null) {
                                            return const SizedBox.shrink();
                                          }
                                          final canvasNode =
                                              _controller.nodeById(nodeId) ??
                                                  GraphViewCanvasNode(
                                                    id: nodeId,
                                                    label: nodeId,
                                                    x: node.position.dx,
                                                    y: node.position.dy,
                                                    isInitial: false,
                                                    isAccepting: false,
                                                  );
                                          return Semantics(
                                            container: true,
                                            excludeSemantics: true,
                                            button: _customization
                                                .enableToolSelection,
                                            onTap: _customization
                                                    .enableToolSelection
                                                ? () => _handleNodeContextTap(
                                                      canvasNode.id,
                                                    )
                                                : null,
                                            selected: canvasNode.id ==
                                                _selectedNodeId,
                                            label:
                                                _nodeSemanticsLabel(canvasNode),
                                            hint: _customization
                                                    .enableToolSelection
                                                ? l10n.canvasStateEditHint
                                                : l10n.canvasStateReadOnlyHint,
                                            child: RepaintBoundary(
                                              child: _AutomatonGraphNode(
                                                nodeId: canvasNode.id,
                                                label: canvasNode.label,
                                                isInitial: canvasNode.isInitial,
                                                isAccepting:
                                                    canvasNode.isAccepting,
                                                highlightListenable: _controller
                                                    .highlightNotifier,
                                                isTransitionSource:
                                                    canvasNode.id ==
                                                        _transitionSourceId,
                                                isSelected: canvasNode.id ==
                                                    _selectedNodeId,
                                                motionPreset: motionPreset,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          Positioned.fill(
                            child: _buildTransitionSemanticsLayer(),
                          ),
                          if (_activeTool == AutomatonCanvasTool.transition &&
                              _transitionSourceId != null)
                            Positioned.fill(
                              child: _buildTransitionPreview(
                                theme.colorScheme.tertiary,
                              ),
                            ),
                          if (_activeTool == AutomatonCanvasTool.transition)
                            Positioned(
                              top: 16,
                              left: 0,
                              right: 0,
                              child: IgnorePointer(
                                child: Center(
                                  child: DecoratedBox(
                                    key: const ValueKey(
                                      'automaton-transition-mode-indicator',
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          theme.colorScheme.surface.withValues(
                                        alpha: 0.9,
                                      ),
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
                                            _transitionSourceId == null
                                                ? l10n.canvasAddTransitionPrompt
                                                : l10n.canvasChooseTargetState,
                                            style: theme.textTheme.labelMedium
                                                ?.copyWith(
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
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    return MouseRegion(
      key: const ValueKey('automaton-canvas-pointer-region'),
      cursor: _activeTool == AutomatonCanvasTool.transition
          ? SystemMouseCursors.precise
          : MouseCursor.defer,
      onHover: _handleCanvasPointerHover,
      child: canvas,
    );
  }
}
