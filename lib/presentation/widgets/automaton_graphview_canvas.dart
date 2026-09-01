//
//  automaton_graphview_canvas.dart
//  Turing Lab
//
//  Implements the GraphView-based interactive canvas for editing and
//  viewing automata in the app's different modes, coordinating tools,
//  state dragging, transition creation, and highlight emission during
//  simulations.
//  Orchestrates specialized FSA, PDA, and TM controllers, integrates
//  label editors, contextual overlays, and Riverpod provider sync to keep
//  the model consistent even for large automata.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'dart:async' show unawaited;
import 'dart:developer' show Timeline;
import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphview/graphview_turing_lab.dart';

import '../../core/constants/automaton_canvas_constants.dart';
import '../../core/annotations/annotations.dart';
import '../../core/automaton_fragments/automaton_fragments.dart';
import '../../core/formal_systems/formal_system_ids.dart';
import '../../core/graph_layout/graph_layout.dart';
import '../../core/models/automaton.dart';
import '../../core/models/simulation_highlight.dart';
import '../../core/services/simulation_highlight_service.dart';
import '../../core/models/tm_transition.dart' show TapeDirection;
import '../../features/canvas/graphview/base_graphview_canvas_controller.dart';
import '../../features/canvas/graphview/graphview_canvas_controller.dart';
import '../../features/canvas/graphview/graphview_canvas_models.dart';
import '../../features/canvas/graphview/turing_lab_adaptive_edge_renderer.dart';
import '../../features/canvas/graphview/graphview_label_field_editor.dart';
import '../../features/canvas/graphview/grouped_fsa_geometry.dart';
import '../../features/canvas/graphview/graphview_link_overlay_utils.dart';
import '../../features/canvas/graphview/graphview_pda_canvas_controller.dart';
import '../../features/canvas/graphview/graphview_tm_canvas_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/app_localizations_resolver.dart';
import '../empty_string_notation.dart';
import '../platform/canvas_context_menu_policy.dart';
import '../providers/automaton_state_provider.dart';
import '../providers/document_annotations_provider.dart';
import 'automaton_canvas_tool.dart';
import 'automaton_canvas_document_actions.dart';
import 'automaton_graphview/canvas_controller_lifecycle.dart';
import 'automaton_graphview/canvas_domain_sync_coordinator.dart';
import 'automaton_graphview/canvas_edge_presentation.dart';
import 'automaton_graphview/canvas_interaction_coordinator.dart';
import 'automaton_graphview/canvas_semantics_adapter.dart';
import 'automaton_graphview/canvas_surface.dart';
import 'automaton_graphview/canvas_viewport_adapter.dart';
import 'pda/stack_drawer.dart';
import 'transition_editors/pda_transition_editor.dart';
import 'transition_editors/tm_transition_operations_editor.dart';
import 'document_annotations.dart';
import 'automaton_fragment_import.dart';
import 'automaton_layout.dart';

part 'automaton_graphview_canvas_models.dart';
part 'automaton_graphview_canvas_overlay.dart';
part 'automaton_graphview_canvas_rendering.dart';
part 'automaton_graphview_canvas_interactions.dart';

enum _AnnotationDeletionTarget { stateWithTransitions, transition }

class AutomatonGraphViewCanvas extends ConsumerStatefulWidget {
  const AutomatonGraphViewCanvas({
    super.key,
    required this.automaton,
    required this.canvasKey,
    this.controller,
    this.toolController,
    this.customization,
    this.annotationConfig,
    this.fragmentImportSystemKey,
    this.fragmentImportDocumentId,
    this.fragmentImportDocumentRevision,
    this.documentActionsController,
  }) : assert(
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
  final AutomatonCanvasAnnotationConfig? annotationConfig;
  final FormalSystemKey? fragmentImportSystemKey;
  final String? fragmentImportDocumentId;
  final String? fragmentImportDocumentRevision;
  final AutomatonCanvasDocumentActionsController? documentActionsController;

  @override
  ConsumerState<AutomatonGraphViewCanvas> createState() =>
      _AutomatonGraphViewCanvasState();
}

class _AutomatonGraphViewCanvasState
    extends ConsumerState<AutomatonGraphViewCanvas>
    with TickerProviderStateMixin {
  late final AutomatonGraphViewControllerLifecycle _lifecycle;
  late final AutomatonGraphViewDomainSyncCoordinator _syncCoordinator;
  late final AutomatonGraphViewViewportAdapter _viewportAdapter;
  late final AutomatonGraphViewEdgePresentation _edgePresentation;
  late final AutomatonGraphViewInteractionCoordinator _interactionCoordinator;
  bool _hasEdgePresentation = false;
  BaseGraphViewCanvasController<dynamic, dynamic> get _controller =>
      _lifecycle.controller;
  AutomatonCanvasToolController get _toolController =>
      _lifecycle.toolController;
  AutomatonCanvasTool _activeTool = AutomatonCanvasTool.selection;
  late _AutomatonGraphSugiyamaAlgorithm _algorithm;
  final Set<String> _selectedTransitions = <String>{};
  String? _selectedNodeId;
  Map<String, GraphLayoutPoint>? _savedLayoutPositions;
  String? _transitionSourceId;
  Offset? _transitionPointerLocalPosition;
  OverlayEntry? _transitionOverlayEntry;
  final ValueNotifier<_GraphViewTransitionOverlayState?>
  _transitionOverlayState = ValueNotifier<_GraphViewTransitionOverlayState?>(
    null,
  );
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
  TuringLabAdaptiveEdgeRenderer get _edgeRenderer => _edgePresentation.renderer;
  late final FocusNode _canvasFocusNode;
  final Object _contextMenuOwner = Object();
  bool _contextMenuPointerInside = false;

  @visibleForTesting
  TuringLabEdgeRenderGeometry? debugGeometryForTransition(String id) {
    final edge = _controller.graphEdgeById(id);
    return edge == null ? null : _edgeRenderer.geometryForEdge(edge);
  }

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
    if (mounted) {
      setState(callback);
    }
  }

  @override
  void initState() {
    super.initState();
    _lifecycle = AutomatonGraphViewControllerLifecycle(
      externalController: widget.controller,
      externalToolController: widget.toolController,
      createInternalController: () => GraphViewCanvasController(
        automatonStateNotifier: ref.read(automatonStateProvider.notifier),
      ),
      readHighlightService: () => ref.read(canvasHighlightServiceProvider),
      onGraphRevision: _handleGraphRevisionChanged,
      onHighlight: _handleHighlightChanged,
      onToolChanged: _handleActiveToolChanged,
    );
    _activeTool = _toolController.activeTool;
    _canvasFocusNode = FocusNode(debugLabel: 'Automaton graph canvas');
    _viewportAdapter = AutomatonGraphViewViewportAdapter(
      controller: _controller,
    );
    _syncCoordinator = AutomatonGraphViewDomainSyncCoordinator(
      synchronize: _synchronizeController,
      isMounted: () => mounted,
      onError: (error, stackTrace) {
        if (kDebugMode) {
          debugPrint(
            '[AutomatonGraphViewCanvas] Failed to synchronize controller: '
            '$error',
          );
          debugPrint(stackTrace.toString());
        }
      },
    );
    _interactionCoordinator = AutomatonGraphViewInteractionCoordinator(
      controller: () => _controller,
      toolController: () => _toolController,
      editingEnabled: () => _customization.enableToolSelection,
      selectedNodeId: () => _selectedNodeId,
      selectedTransitionIds: () => _selectedTransitions,
      clearTransitionSource: () => _setTransitionSourceId(null),
      clearSelectedNode: () => _setSelectedNodeId(null),
      notifySelectionChanged: () => _updateCanvasState(() {}),
      beforeRemoveState: _confirmStateAnnotationDeletion,
      beforeRemoveTransition: _confirmTransitionAnnotationDeletion,
    );
    _applyCustomization(widget.customization);
    _nodePanGestureRecognizer =
        _NodePanGestureRecognizer(
            hitTester: (global) => _customization.enableStateDrag
                ? _hitTestNode(_globalToCanvasLocal(global), logDetails: false)
                : null,
            toolResolver: () => _activeTool,
            onDragReleased: () =>
                _setCanvasPanSuppressed(false, reason: 'node pointer released'),
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
    _edgePresentation = AutomatonGraphViewEdgePresentation(
      vsync: this,
      controller: _controller,
      renderMode: _customization.edgeRenderMode,
    );
    _hasEdgePresentation = true;
    _algorithm = _AutomatonGraphSugiyamaAlgorithm(
      configuration: _buildConfiguration(),
    );
    _algorithm.renderer = _edgeRenderer;
    _syncCoordinator.schedule(widget.automaton);
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
      _lifecycle.replaceToolController(widget.toolController);
      _activeTool = _toolController.activeTool;
      shouldReapplyCustomization = true;
    }

    if (oldWidget.controller != widget.controller) {
      _savedLayoutPositions = null;
      _lifecycle.replaceController(widget.controller);
      _viewportAdapter.controller = _controller;
      _edgePresentation.replaceController(_controller);
      _syncCoordinator.replaceTarget(_synchronizeController);
      _algorithm = _AutomatonGraphSugiyamaAlgorithm(
        configuration: _buildConfiguration(),
      );
      _algorithm.renderer = _edgeRenderer;
      _syncCoordinator.schedule(widget.automaton);
      _handleHighlightChanged();
      _hideTransitionOverlay();
      shouldReapplyCustomization = true;
    } else if (_syncCoordinator.contentChanged(
      oldWidget.automaton,
      widget.automaton,
    )) {
      final documentIdChanged =
          GraphLayoutDocumentAdapter.documentId(oldWidget.automaton) !=
          GraphLayoutDocumentAdapter.documentId(widget.automaton);
      final shouldRefitViewport =
          documentIdChanged ||
          _hasStructuralGraphChange(oldWidget.automaton, widget.automaton);
      if (documentIdChanged) {
        _savedLayoutPositions = null;
      }
      _syncCoordinator.schedule(widget.automaton);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        if (shouldRefitViewport && _controller.graph.nodes.isNotEmpty) {
          _controller.fitToContent();
        }
        _refreshTransitionOverlayFromGraph();
      });
    }

    if (shouldReapplyCustomization ||
        oldWidget.customization != widget.customization) {
      _applyCustomization(widget.customization);
      _synchronizeContextMenuOwnership();
    }
  }

  bool _hasStructuralGraphChange(Object? previous, Object? next) {
    if (previous is! Automaton || next is! Automaton) {
      return false;
    }

    final previousStateIds = previous.states.map((state) => state.id).toSet();
    final nextStateIds = next.states.map((state) => state.id).toSet();
    if (previousStateIds.length != nextStateIds.length ||
        !previousStateIds.containsAll(nextStateIds)) {
      return true;
    }

    final previousTransitionIds = previous.transitions
        .map((transition) => transition.id)
        .toSet();
    final nextTransitionIds = next.transitions
        .map((transition) => transition.id)
        .toSet();
    return previousTransitionIds.length != nextTransitionIds.length ||
        !previousTransitionIds.containsAll(nextTransitionIds);
  }

  void _handleContextMenuPointerEnter(PointerEnterEvent event) {
    _contextMenuPointerInside = true;
    _synchronizeContextMenuOwnership();
  }

  void _handleContextMenuPointerExit(PointerExitEvent event) {
    _contextMenuPointerInside = false;
    _synchronizeContextMenuOwnership();
  }

  void _synchronizeContextMenuOwnership() {
    final shouldOwn =
        _contextMenuPointerInside && _customization.enableToolSelection;
    if (shouldOwn) {
      unawaited(CanvasContextMenuPolicy.instance.acquire(_contextMenuOwner));
    } else {
      unawaited(CanvasContextMenuPolicy.instance.release(_contextMenuOwner));
    }
  }

  @override
  void dispose() {
    _isDisposing = true;
    unawaited(CanvasContextMenuPolicy.instance.release(_contextMenuOwner));
    _syncCoordinator.dispose();
    _nodePanGestureRecognizer.dispose();
    _canvasFocusNode.dispose();
    _edgePresentation.dispose();
    _lifecycle.dispose();
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

  void _handleHighlightChanged() {
    _edgePresentation.updateHighlight(
      _controller.highlightNotifier.value,
      _selectedTransitions,
    );
    _controller.graph.notifyGraphObserver();
  }

  void _applyCustomization(
    AutomatonGraphViewCanvasCustomization? customization,
  ) {
    final resolved =
        customization ?? AutomatonGraphViewCanvasCustomization.fsa();
    _customization = resolved;
    _transitionConfig = resolved.transitionConfigBuilder(_controller);
    if (_hasEdgePresentation) {
      _edgeRenderer.renderMode = resolved.edgeRenderMode;
    }
    if (!_customization.enableToolSelection &&
        _toolController.activeTool != AutomatonCanvasTool.selection) {
      _toolController.setActiveTool(AutomatonCanvasTool.selection);
    }
    _activeTool = _toolController.activeTool;
  }

  void _synchronizeController(Object? data) {
    _controller.synchronize(data);
    _syncInitialStateIds();
  }

  SugiyamaConfiguration _buildConfiguration() {
    final configuration = SugiyamaConfiguration()
      ..orientation = SugiyamaConfiguration.ORIENTATION_LEFT_RIGHT
      ..nodeSeparation = 160
      ..levelSeparation = 160
      ..bendPointShape = CurvedBendPointShape(curveLength: 40);
    return configuration;
  }

  void _handleCanvasTapDownWithFocus(TapDownDetails details) {
    _canvasFocusNode.requestFocus();
    _updateTransitionPointerLocal(details.localPosition);
    _handleCanvasTapDown(details);
  }

  void _handleCanvasPointerHover(PointerHoverEvent event) {
    _updateTransitionPointerLocal(event.localPosition);
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
    final emptyStringSymbol = EmptyStringNotation.symbolOf(context);
    final semantics = AutomatonGraphViewSemanticsAdapter(
      controller: _controller,
      localizations: l10n,
      selectedTransitionIds: _selectedTransitions,
      emptyStringSymbol: emptyStringSymbol,
      nodeSemanticsDetails: (node) =>
          _customization.nodeSemanticsDetails?.call(l10n, node),
      edgeSemanticsDetails: (edge) =>
          _customization.edgeSemanticsDetails?.call(l10n, edge),
    );
    _edgePresentation.updateTheme(theme, emptyStringSymbol: emptyStringSymbol);
    _edgePresentation.updateHighlight(
      _controller.highlightNotifier.value,
      _selectedTransitions,
    );
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ??
        WidgetsBinding
            .instance
            .platformDispatcher
            .accessibilityFeatures
            .disableAnimations;
    final motionPreset = disableAnimations
        ? _CanvasMotionPreset.reduced
        : _CanvasMotionPreset.organic;
    final canvas = AutomatonGraphViewCanvasSurface(
      canvasKey: widget.canvasKey,
      controller: _controller,
      focusNode: _canvasFocusNode,
      nodeDraggingConfiguration: _nodePointerConfiguration,
      algorithm: _algorithm,
      activeTool: _activeTool,
      suppressCanvasPan: _suppressCanvasPan,
      isDraggingNode: _isDraggingNode,
      graphAnimationEnabled: motionPreset.graphAnimationEnabled,
      viewportAnimationDuration: motionPreset.viewportDuration,
      nodeAnimationDuration: motionPreset.nodeDuration,
      canvasSemanticsLabel: semantics.viewportLabel,
      canvasSemanticsHint: _customization.enableToolSelection
          ? l10n.canvasViewportEditHint
          : l10n.canvasViewportReadOnlyHint,
      transitionPrompt: EmptyStringNotation.format(
        context,
        l10n.canvasAddTransitionPrompt,
      ),
      chooseTargetPrompt: EmptyStringNotation.format(
        context,
        l10n.canvasChooseTargetState,
      ),
      hasTransitionSource: _transitionSourceId != null,
      transitionSemanticsLayer: semantics.transitionLayer(),
      transitionPreview: _buildTransitionPreview(theme.colorScheme.tertiary),
      nodeBuilder: (context, canvasNode, outgoingCounts, incomingCounts) {
        return Semantics(
          container: true,
          excludeSemantics: true,
          button: _customization.enableToolSelection,
          onTap: _customization.enableToolSelection
              ? () => _handleNodeContextTap(canvasNode.id)
              : null,
          selected: canvasNode.id == _selectedNodeId,
          label: semantics.nodeLabel(
            canvasNode,
            outgoingCounts,
            incomingCounts,
          ),
          hint: _customization.enableToolSelection
              ? l10n.canvasStateEditHint
              : l10n.canvasStateReadOnlyHint,
          child: RepaintBoundary(
            child: _AutomatonGraphNode(
              nodeId: canvasNode.id,
              label: EmptyStringNotation.format(context, canvasNode.label),
              secondaryLabel: canvasNode.secondaryLabel == null
                  ? null
                  : EmptyStringNotation.format(
                      context,
                      canvasNode.secondaryLabel!,
                    ),
              isInitial: canvasNode.isInitial,
              isAccepting: canvasNode.isAccepting,
              highlightListenable: _controller.highlightNotifier,
              isTransitionSource: canvasNode.id == _transitionSourceId,
              isSelected: canvasNode.id == _selectedNodeId,
              motionPreset: motionPreset,
            ),
          ),
        );
      },
      onViewportChanged: (viewport) {
        _viewportAdapter.updateViewport(viewport, _edgeRenderer);
      },
      onPointerDown: (event) {
        _handleNodePointerDown(event.position);
        _nodePanGestureRecognizer.cancelForAdditionalPointer(event.pointer);
      },
      onPointerEnter: _handleContextMenuPointerEnter,
      onPointerExit: _handleContextMenuPointerExit,
      onPointerHover: _handleCanvasPointerHover,
      onTapDown: _handleCanvasTapDownWithFocus,
      onTapUp: _handleCanvasTapUp,
      onLongPressStart: _handleCanvasLongPressStart,
      onSecondaryTapUp: _handleCanvasSecondaryTapUp,
      onAddStateAtCenter: _interactionCoordinator.addStateAtCenter,
      onDeleteSelection: _interactionCoordinator.deleteSelection,
      onOpenSelectionContext: _handleSelectedStateContextAction,
      onUndo: _interactionCoordinator.undo,
      onRedo: _interactionCoordinator.redo,
      onActivateTool: _interactionCoordinator.activateTool,
    );
    final annotationConfig = widget.annotationConfig;
    final fragmentSystemKey =
        widget.fragmentImportSystemKey ?? annotationConfig?.systemKey;
    final fragmentDocumentId =
        widget.fragmentImportDocumentId ?? annotationConfig?.documentId;
    final fragmentDocumentRevision =
        widget.fragmentImportDocumentRevision ??
        annotationConfig?.documentRevision;
    final showFragmentImport =
        _customization.enableToolSelection &&
        widget.automaton != null &&
        fragmentSystemKey != null &&
        fragmentDocumentId != null &&
        fragmentDocumentRevision != null;
    final showLayout =
        _customization.enableToolSelection && widget.automaton != null;
    if (annotationConfig == null && !showFragmentImport && !showLayout) {
      return canvas;
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(child: canvas),
        if (annotationConfig != null)
          Positioned.fill(
            child: CanvasDocumentAnnotationsLayer(
              systemKey: annotationConfig.systemKey,
              documentId: annotationConfig.documentId,
              documentRevision: annotationConfig.documentRevision,
              worldToScreen: _worldToCanvasLocal,
              screenToWorld: _screenToWorld,
              viewportListenable: Listenable.merge([
                _controller.graphController.transformationController,
                _controller.graphRevision,
              ]),
              resolveAttachmentPosition: _resolveAnnotationAttachment,
            ),
          ),
        if (showLayout)
          AutomatonLayoutButton(
            destination: widget.automaton!,
            controller: _controller,
            selectedNodeIds: {
              if (_selectedNodeId case final selected?) selected,
            },
            restorePositions:
                _savedLayoutPositions ?? const <String, GraphLayoutPoint>{},
            annotationSystemKey: annotationConfig?.systemKey,
            annotationDocumentId: annotationConfig?.documentId,
            documentRevision: fragmentDocumentRevision,
            onCommitted: _handleLayoutCommitted,
            actionsController: widget.documentActionsController,
            showButton: false,
          ),
        if (showFragmentImport)
          AutomatonFragmentImportButton(
            systemKey: fragmentSystemKey,
            destination: widget.automaton!,
            controller: _controller,
            documentId: fragmentDocumentId,
            documentRevision: fragmentDocumentRevision,
            onCommitted: _handleFragmentImported,
            actionsController: widget.documentActionsController,
            showButton: false,
          ),
        if (annotationConfig != null &&
            widget.documentActionsController != null)
          DocumentAnnotationsMenuActionHost(
            actionsController: widget.documentActionsController!,
            systemKey: annotationConfig.systemKey,
            documentId: annotationConfig.documentId,
            documentRevision: annotationConfig.documentRevision,
          ),
      ],
    );
  }

  void _handleLayoutCommitted(AutomatonLayoutCommit commit) {
    if (!mounted) return;
    _controller.applyHighlight(
      SimulationHighlight(stateIds: commit.result.affectedNodeIds),
    );
    setState(() {
      _savedLayoutPositions ??= commit.previousPositions;
    });
  }

  void _handleFragmentImported(AutomatonFragmentPlan plan) {
    if (!mounted) return;
    _controller.applyHighlight(
      SimulationHighlight(
        stateIds: plan.importedStateIds,
        transitionIds: plan.importedTransitionIds,
      ),
    );
    setState(() {
      _selectedNodeId = plan.importedStateIds.firstOrNull;
      _selectedTransitions
        ..clear()
        ..addAll(plan.importedTransitionIds);
    });
  }

  Offset? _resolveAnnotationAttachment(AnnotationAttachment attachment) {
    if (attachment.type == AnnotationTargetType.state) {
      final node = _controller.nodeById(attachment.targetId);
      return node == null ? null : Offset(node.x, node.y);
    }
    if (attachment.type == AnnotationTargetType.transition) {
      final edge = _controller.edgeById(attachment.targetId);
      if (edge == null) return null;
      final from = _controller.nodeById(edge.fromStateId);
      final to = _controller.nodeById(edge.toStateId);
      if (from == null || to == null) return null;
      return Offset((from.x + to.x) / 2, (from.y + to.y) / 2);
    }
    return null;
  }

  Future<bool> _confirmStateAnnotationDeletion(String stateId) {
    final node = _controller.nodeById(stateId);
    final incidentEdges = _controller.edges.where(
      (edge) => edge.fromStateId == stateId || edge.toStateId == stateId,
    );
    return _confirmAnnotationTargetDeletions(
      targets: [
        (
          type: AnnotationTargetType.state,
          targetId: stateId,
          resolvedPosition: node == null ? null : Offset(node.x, node.y),
        ),
        for (final edge in incidentEdges)
          (
            type: AnnotationTargetType.transition,
            targetId: edge.id,
            resolvedPosition: _transitionAnnotationPosition(edge),
          ),
      ],
      target: _AnnotationDeletionTarget.stateWithTransitions,
    );
  }

  Future<bool> _confirmTransitionAnnotationDeletion(String transitionId) {
    final edge = _controller.edgeById(transitionId);
    return _confirmAnnotationTargetDeletions(
      targets: [
        (
          type: AnnotationTargetType.transition,
          targetId: transitionId,
          resolvedPosition: edge == null
              ? null
              : _transitionAnnotationPosition(edge),
        ),
      ],
      target: _AnnotationDeletionTarget.transition,
    );
  }

  Offset? _transitionAnnotationPosition(GraphViewCanvasEdge edge) {
    final from = _controller.nodeById(edge.fromStateId);
    final to = _controller.nodeById(edge.toStateId);
    if (from == null || to == null) return null;
    return Offset((from.x + to.x) / 2, (from.y + to.y) / 2);
  }

  Future<bool> _confirmAnnotationTargetDeletions({
    required List<
      ({AnnotationTargetType type, String targetId, Offset? resolvedPosition})
    >
    targets,
    required _AnnotationDeletionTarget target,
  }) async {
    final config = widget.annotationConfig;
    if (config == null) return true;
    final collection = annotationsForDocument(
      ref.read(documentAnnotationsProvider),
      config.systemKey,
      config.documentId,
    );
    final affected =
        collection?.annotations.where((annotation) {
          final attachment = annotation.attachment;
          return attachment != null &&
              targets.any(
                (target) =>
                    target.type == attachment.type &&
                    target.targetId == attachment.targetId,
              );
        }) ??
        const Iterable<DocumentAnnotation>.empty();
    final count = affected.length;
    if (count == 0 || !mounted) return true;
    final l10n = appLocalizationsOf(context);
    final message = switch (target) {
      _AnnotationDeletionTarget.stateWithTransitions =>
        l10n.attachedNotesStateDeletionMessage(count),
      _AnnotationDeletionTarget.transition =>
        l10n.attachedNotesTransitionDeletionMessage(count),
    };

    final policy = await showDialog<AnnotationTargetDeletionPolicy>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.attachedNotesTitle),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(
              context,
              AnnotationTargetDeletionPolicy.keepUnresolved,
            ),
            child: Text(l10n.keepNotesUnlinked),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, AnnotationTargetDeletionPolicy.detach),
            child: Text(l10n.detachNotes),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, AnnotationTargetDeletionPolicy.delete),
            child: Text(l10n.deleteNotes),
          ),
        ],
      ),
    );
    if (policy == null || !mounted) return false;
    ref
        .read(documentAnnotationsProvider.notifier)
        .resolveTargetDeletions(
          key: config.systemKey,
          targets: [
            for (final target in targets)
              (
                type: target.type,
                targetId: target.targetId,
                resolvedPosition: target.resolvedPosition == null
                    ? null
                    : (
                        x: target.resolvedPosition!.dx,
                        y: target.resolvedPosition!.dy,
                      ),
              ),
          ],
          policy: policy,
        );
    return true;
  }
}

final class AutomatonCanvasAnnotationConfig {
  const AutomatonCanvasAnnotationConfig({
    required this.systemKey,
    required this.documentId,
    required this.documentRevision,
  });

  final FormalSystemKey systemKey;
  final String documentId;
  final String documentRevision;
}
