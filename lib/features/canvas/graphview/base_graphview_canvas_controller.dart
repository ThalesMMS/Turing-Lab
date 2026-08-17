//
//  base_graphview_canvas_controller.dart
//  Turing Lab
//
//  Classe base que centraliza infraestrutura comum aos controladores GraphView,
//  incluindo caches de nós e arestas, histórico para undo/redo, animações de
//  viewport e conversões entre coordenadas de tela e mundo. Também integra o
//  suporte a destaques de simulação e garante descarte adequado dos recursos de
//  transformação.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:graphview/graphview_turing_lab.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;

import '../../../core/constants/automaton_canvas_constants.dart';
import '../../../core/models/simulation_highlight.dart';
import 'graphview_canvas_models.dart';
import 'graphview_highlight_controller.dart';
import 'graphview_state_notifier_adapter.dart';
import 'turing_lab_adaptive_edge_renderer.dart';
import 'graphview_viewport_highlight_mixin.dart';
import 'graphview_snapshot_codec.dart';

void _logGraphViewBase(String message) {
  if (kDebugMode) {
    debugPrint('[GraphViewBase] $message');
  }
}

/// Shared state CRUD and ID allocation for domain-specific GraphView controllers.
mixin SharedGraphViewStateController<TNotifier, TSnapshot>
    on BaseGraphViewCanvasController<TNotifier, TSnapshot> {
  @protected
  GraphViewStateNotifierAdapter<TSnapshot> get stateNotifierAdapter;

  @override
  TSnapshot? get currentDomainData => stateNotifierAdapter.currentData();

  @protected
  Iterable<String> get domainStateIds {
    final data = currentDomainData;
    return data == null
        ? const <String>[]
        : stateNotifierAdapter.stateIdsOf(data);
  }

  @protected
  Iterable<String> get domainStateLabels {
    final data = currentDomainData;
    return data == null
        ? const <String>[]
        : stateNotifierAdapter.stateLabelsOf(data);
  }

  @protected
  Iterable<String> get domainTransitionIds {
    final data = currentDomainData;
    return data == null
        ? const <String>[]
        : stateNotifierAdapter.transitionIdsOf(data);
  }

  @protected
  void addDomainState({
    required String id,
    required String label,
    required Offset position,
  }) {
    stateNotifierAdapter.addState(id: id, label: label, position: position);
  }

  @protected
  void moveDomainState({required String id, required Offset position}) {
    stateNotifierAdapter.moveState(id: id, position: position);
  }

  @protected
  void updateDomainStateLabel({
    required String id,
    required String label,
  }) {
    stateNotifierAdapter.updateStateLabel(id: id, label: label);
  }

  @protected
  void updateDomainStateFlags({
    required String id,
    bool? isInitial,
    bool? isAccepting,
  }) {
    stateNotifierAdapter.updateStateFlags(
      id: id,
      isInitial: isInitial,
      isAccepting: isAccepting,
    );
  }

  @protected
  void removeDomainState(String id) {
    stateNotifierAdapter.removeState(id);
  }

  @protected
  void logCanvasStateMutation(String message) {
    stateNotifierAdapter.logMutation(message);
  }

  @protected
  String generateNodeId() {
    return _nextAvailableSequentialId(
      prefix: 'state',
      reservedIds: <String>{...nodesCache.keys, ...domainStateIds},
    );
  }

  @protected
  String generateEdgeId() {
    return _nextAvailableSequentialId(
      prefix: 'transition',
      reservedIds: <String>{...edgesCache.keys, ...domainTransitionIds},
    );
  }

  @protected
  String nextAvailableStateLabel() {
    final reservedLabels = <String>{};

    for (final label in domainStateLabels) {
      final trimmed = label.trim();
      if (trimmed.isNotEmpty) {
        reservedLabels.add(trimmed);
      }
    }

    for (final node in nodesCache.values) {
      final trimmed = node.label.trim();
      if (trimmed.isNotEmpty) {
        reservedLabels.add(trimmed);
      }
    }

    var index = 0;
    while (reservedLabels.contains('q$index')) {
      index++;
    }
    return 'q$index';
  }

  /// Adds a new state centred in the current viewport.
  @override
  void addStateAtCenter() {
    logCanvasStateMutation('addStateAtCenter requested');
    final worldCenter = resolveViewportCenterWorld();
    addStateAt(worldCenter);
  }

  /// Adds a new state centred on the provided [worldCenter].
  @override
  void addStateAt(Offset worldCenter) {
    final nodeId = generateNodeId();
    final label = nextAvailableStateLabel();
    const nodeRadius = kAutomatonStateDiameter / 2;
    final topLeft = worldCenter - const Offset(nodeRadius, nodeRadius);
    logCanvasStateMutation(
      'addStateAt -> id=$nodeId label=$label center=(${worldCenter.dx.toStringAsFixed(2)}, ${worldCenter.dy.toStringAsFixed(2)})',
    );
    performMutation(() {
      addDomainState(id: nodeId, label: label, position: topLeft);
    });
  }

  /// Moves an existing state to a new [position].
  @override
  void moveState(String id, Offset position) {
    logCanvasStateMutation(
      'moveState -> id=$id position=(${position.dx.toStringAsFixed(2)}, ${position.dy.toStringAsFixed(2)})',
    );
    performMutation(() {
      moveDomainState(id: id, position: position);
    });
  }

  /// Updates the label displayed for the state identified by [id].
  @override
  void updateStateLabel(String id, String label) {
    final resolvedLabel = label.isEmpty ? id : label;
    logCanvasStateMutation('updateStateLabel -> id=$id label=$resolvedLabel');
    performMutation(() {
      updateDomainStateLabel(id: id, label: resolvedLabel);
    });
  }

  /// Updates the flag metadata for the state identified by [id].
  @override
  void updateStateFlags(String id, {bool? isInitial, bool? isAccepting}) {
    logCanvasStateMutation(
      'updateStateFlags -> id=$id isInitial=$isInitial isAccepting=$isAccepting',
    );
    if (isInitial == null && isAccepting == null) {
      return;
    }
    performMutation(() {
      updateDomainStateFlags(
        id: id,
        isInitial: isInitial,
        isAccepting: isAccepting,
      );
    });
  }

  /// Removes the state identified by [id] from the domain.
  @override
  void removeState(String id) {
    logCanvasStateMutation('removeState -> id=$id');
    performMutation(() {
      removeDomainState(id);
    });
  }

  String _nextAvailableSequentialId({
    required String prefix,
    required Set<String> reservedIds,
  }) {
    var index = 0;
    while (true) {
      final candidate = '${prefix}_$index';
      if (!reservedIds.contains(candidate)) {
        return candidate;
      }
      index++;
    }
  }
}

class _InvisibleGraphEdgeRenderer extends EdgeRenderer {
  @override
  void renderEdge(Canvas canvas, Edge edge, Paint paint) {}
}

class _GraphHistoryEntry {
  const _GraphHistoryEntry({
    required this.serializedSnapshot,
    required this.highlight,
  });

  final Uint8List serializedSnapshot;
  final SimulationHighlight highlight;

  GraphViewAutomatonSnapshot? decodeSnapshot(
    Codec<List<int>, List<int>> codec,
  ) {
    try {
      final decompressed = codec.decode(serializedSnapshot);
      final decoded = utf8.decode(decompressed);
      final Map<String, dynamic> json =
          jsonDecode(decoded) as Map<String, dynamic>;
      return GraphViewAutomatonSnapshot.fromJson(json);
    } catch (_) {
      return null;
    }
  }
}

/// Base controller that coordinates GraphView interactions with domain notifiers.
abstract class BaseGraphViewCanvasController<TNotifier, TSnapshot>
    extends GraphViewHighlightController with GraphViewViewportHighlightMixin {
  static const int kDefaultHistoryLimit = 20;
  static const int kDefaultCacheEvictionThreshold = 250;
  static final EdgeRenderer _invisibleNodeAnchorRenderer =
      _InvisibleGraphEdgeRenderer();
  static final Codec<List<int>, List<int>> _historyCodec =
      createGraphHistoryCodec();

  BaseGraphViewCanvasController({
    required this.notifier,
    Graph? graph,
    GraphViewController? viewController,
    TransformationController? transformationController,
    int historyLimit = kDefaultHistoryLimit,
    int cacheEvictionThreshold = kDefaultCacheEvictionThreshold,
  })  : assert(historyLimit > 0),
        assert(cacheEvictionThreshold > 0),
        assert(
          viewController == null || transformationController == null,
          'viewController and transformationController cannot both be provided.',
        ),
        historyLimit = historyLimit,
        cacheEvictionThreshold = cacheEvictionThreshold,
        graph = graph ?? Graph(),
        graphController = viewController ??
            GraphViewController(
              transformationController:
                  transformationController ?? TransformationController(),
              ownsTransformationController: transformationController == null,
            ),
        _ownsTransformationController =
            viewController == null && transformationController == null;

  @protected
  final TNotifier notifier;

  @override
  final Graph graph;

  @override
  final GraphViewController graphController;

  final bool _ownsTransformationController;

  final Map<String, GraphViewCanvasNode> _nodes = {};
  final Map<String, GraphViewCanvasEdge> _edges = {};
  final Map<String, Node> _graphNodes = {};
  final Map<String, Edge> _graphEdges = {};
  final Map<String, Edge> _graphNodeAnchors = {};

  final int historyLimit;
  final int cacheEvictionThreshold;

  bool _isSynchronizing = false;
  bool _isApplyingInternalSnapshot = false;
  bool _isDisposed = false;
  String? _pendingDomainEchoSignature;

  final List<_GraphHistoryEntry> _undoHistory = [];
  final List<_GraphHistoryEntry> _redoHistory = [];

  Size? _viewportSize;

  @protected
  Map<String, Node> get graphNodes => _graphNodes;

  @protected
  Map<String, Edge> get graphEdges => _graphEdges;

  @override
  Map<String, GraphViewCanvasNode> get nodesCache => _nodes;

  @override
  Map<String, GraphViewCanvasEdge> get edgesCache => _edges;

  @override
  Size? get currentViewportSize => _viewportSize;

  Iterable<GraphViewCanvasNode> get nodes => _nodes.values;
  Iterable<GraphViewCanvasEdge> get edges => _edges.values;

  GraphViewCanvasNode? nodeById(String id) => _nodes[id];
  GraphViewCanvasEdge? edgeById(String id) => _edges[id];
  Edge? graphEdgeById(String id) => _graphEdges[id];

  /// Adds a new state at the centre of the current viewport.
  void addStateAtCenter();

  /// Adds a new state centred on the provided [worldCenter].
  void addStateAt(Offset worldCenter);

  /// Moves an existing state to a new [position].
  void moveState(String id, Offset position);

  /// Moves a state locally while a drag gesture is active.
  ///
  /// This deliberately avoids mutating the domain or recording undo history;
  /// callers must finish the gesture with [moveState].
  void previewStatePosition(String id, Offset position) {
    final node = _nodes[id];
    final graphNode = _graphNodes[id];
    if (node == null || graphNode == null) {
      return;
    }
    if (node.x == position.dx && node.y == position.dy) {
      return;
    }

    _nodes[id] = node.copyWith(x: position.dx, y: position.dy);
    graphNode.position = position;
    graph.markModified();
    graph.notifyGraphObserver();
  }

  /// Updates the human-readable label associated with the state [id].
  void updateStateLabel(String id, String label);

  /// Updates the state flags for [id], such as initial/final markers.
  void updateStateFlags(String id, {bool? isInitial, bool? isAccepting});

  /// Removes the state identified by [id] from the canvas/domain.
  void removeState(String id);

  /// Removes the transition identified by [id] from the canvas/domain.
  void removeTransition(String id);

  /// Clears all states and transitions while preserving automaton metadata.
  ///
  /// The previous snapshot is recorded as one undoable mutation. Clearing an
  /// already-empty canvas is a no-op and does not alter either history stack.
  bool clearCanvas() {
    late final GraphViewAutomatonSnapshot currentSnapshot;
    try {
      currentSnapshot = toSnapshot(currentDomainData);
    } catch (error) {
      _logGraphViewBase('Clear skipped (snapshot failed): $error');
      return false;
    }
    if (currentSnapshot.nodes.isEmpty && currentSnapshot.edges.isEmpty) {
      _logGraphViewBase('Clear skipped (canvas already empty)');
      return false;
    }

    final historyEntry = _captureHistoryEntry();
    if (historyEntry == null) {
      _logGraphViewBase('Clear skipped (history snapshot failed)');
      return false;
    }

    final emptySnapshot = currentSnapshot.copyWith(
      nodes: const <GraphViewCanvasNode>[],
      edges: const <GraphViewCanvasEdge>[],
    );
    _isApplyingInternalSnapshot = true;
    try {
      applySnapshotToDomain(emptySnapshot);
    } catch (error) {
      _logGraphViewBase('Clear failed while applying empty snapshot: $error');
      return false;
    } finally {
      _isApplyingInternalSnapshot = false;
    }

    _updateHistory(_undoHistory, historyEntry, clearRedo: true);
    _logGraphViewBase(
      'Canvas cleared (#undo=${_undoHistory.length}, #redo=${_redoHistory.length})',
    );
    return true;
  }

  /// Returns the world position of the graph node with the provided [id].
  @visibleForTesting
  Offset? nodePosition(String id) => _graphNodes[id]?.position;

  bool get canUndo => _undoHistory.isNotEmpty;
  bool get canRedo => _redoHistory.isNotEmpty;

  /// Returns the last viewport size observed by the controller.
  @visibleForTesting
  Size? get viewportSize => _viewportSize;

  /// Updates the cached viewport [size] used when translating screen
  /// coordinates into world coordinates.
  void updateViewportSize(Size size) {
    if (!size.width.isFinite || !size.height.isFinite) {
      return;
    }
    if (_viewportSize == size) {
      return;
    }
    _viewportSize = size;
    _logGraphViewBase(
      'Viewport size updated (${size.width.toStringAsFixed(1)} x ${size.height.toStringAsFixed(1)})',
    );
  }

  /// Converts the provided [viewportOffset] from viewport space into world
  /// coordinates based on the current transformation matrix.
  Offset toWorldOffset(Offset viewportOffset) {
    final transformation = graphController.transformationController;
    if (transformation == null) {
      return viewportOffset;
    }

    final matrix = Matrix4.copy(transformation.value);
    final determinant = matrix.invert();
    if (determinant == 0) {
      return viewportOffset;
    }

    final vector = matrix.transform3(
      vmath.Vector3(viewportOffset.dx, viewportOffset.dy, 0),
    );
    return Offset(vector.x, vector.y);
  }

  /// Returns the world-space coordinates corresponding to the visual centre of
  /// the viewport. When the viewport dimensions are unknown the origin is
  /// returned.
  @protected
  Offset resolveViewportCenterWorld() {
    final size = _viewportSize;
    final viewportCenter =
        size != null ? Offset(size.width / 2, size.height / 2) : Offset.zero;
    final world = toWorldOffset(viewportCenter);
    _logGraphViewBase(
      'Viewport centre resolved to (${world.dx.toStringAsFixed(2)}, ${world.dy.toStringAsFixed(2)})',
    );
    return world;
  }

  /// Releases the resources owned by the controller. Safe to call twice.
  void dispose() {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    _logGraphViewBase(
      'Disposing controller '
      '(ownsTransformation=$_ownsTransformationController, '
      'graphViewAttached=${graphController.hasAttachedView})',
    );
    _undoHistory.clear();
    _redoHistory.clear();
    _pendingDomainEchoSignature = null;
    highlightedTransitionIds.clear();
    _evictGraphCaches(notifyGraph: false);
    disposeViewportHighlight();
    // The GraphViewController owns its TransformationController; it disposes
    // it exactly once (deferred while a view is still attached).
    if (_ownsTransformationController) {
      graphController.dispose();
    }
  }

  /// Synchronises the canvas with the provided domain [data].
  void synchronize(TSnapshot? data) {
    synchronizeGraph(data);
  }

  /// Converts domain state into a snapshot consumed by the canvas.
  @protected
  GraphViewAutomatonSnapshot toSnapshot(TSnapshot? data);

  /// Returns the current domain entity rendered on the canvas.
  @protected
  TSnapshot? get currentDomainData;

  /// Applies a [snapshot] to the underlying domain notifier and synchronises
  /// the canvas state accordingly.
  @protected
  void applySnapshotToDomain(GraphViewAutomatonSnapshot snapshot);

  /// Creates a GraphView node for the provided canvas [node].
  @protected
  Node buildGraphNode(GraphViewCanvasNode node) {
    final instance = Node.Id(node.id);
    instance.position = Offset(node.x, node.y);
    return instance;
  }

  /// Creates a GraphView edge for the provided canvas [edge].
  @protected
  Edge buildGraphEdge(GraphViewCanvasEdge edge, Node from, Node to) {
    final graphEdge = Edge(
      from,
      to,
      key: ValueKey(edge.id),
      label: edge.label,
      labelFollowsEdgeDirection: false,
    );
    _syncGraphEdgeControlPoint(graphEdge, edge);
    return graphEdge;
  }

  @protected
  void updateGraphEdgeInstance(Edge target, GraphViewCanvasEdge edge) {
    target.label = edge.label;
    target.labelFollowsEdgeDirection = false;
    _syncGraphEdgeControlPoint(target, edge);
  }

  /// Records the current canvas state before invoking [mutation].
  @protected
  void performMutation(VoidCallback mutation) {
    if (_isSynchronizing) {
      _logGraphViewBase('performMutation invoked during synchronization');
      mutation();
      return;
    }

    final entry = _captureHistoryEntry();
    if (entry != null) {
      _updateHistory(_undoHistory, entry, clearRedo: true);
      _logGraphViewBase(
        'History snapshot captured (#undo=${_undoHistory.length}, #redo=${_redoHistory.length})',
      );
    } else {
      _logGraphViewBase('History snapshot skipped (serialization failed)');
    }

    mutation();
    _logGraphViewBase(
      'Mutation executed, synchronizing graph with domain data',
    );
    synchronizeGraph(currentDomainData, fromMutation: true);
  }

  /// Restores the previous canvas snapshot if available.
  bool undo() {
    if (_undoHistory.isEmpty) {
      _logGraphViewBase('Undo requested with empty history');
      return false;
    }

    final currentEntry = _captureHistoryEntry();
    if (currentEntry == null) {
      _logGraphViewBase('Undo skipped (current history snapshot failed)');
      return false;
    }

    final entry = _undoHistory.removeLast();
    final restored = _restoreHistoryEntry(entry);
    if (!restored) {
      graphRevision.value++;
      _logGraphViewBase(
        'Undo discarded invalid history entry (#undo=${_undoHistory.length}, #redo=${_redoHistory.length})',
      );
      return false;
    }
    _updateHistory(_redoHistory, currentEntry);
    _logGraphViewBase(
      'Undo applied (#undo=${_undoHistory.length}, #redo=${_redoHistory.length})',
    );
    return true;
  }

  /// Reapplies the most recently undone canvas snapshot if available.
  bool redo() {
    if (_redoHistory.isEmpty) {
      _logGraphViewBase('Redo requested with empty history');
      return false;
    }

    final currentEntry = _captureHistoryEntry();
    if (currentEntry == null) {
      _logGraphViewBase('Redo skipped (current history snapshot failed)');
      return false;
    }

    final entry = _redoHistory.removeLast();
    final restored = _restoreHistoryEntry(entry);
    if (!restored) {
      graphRevision.value++;
      _logGraphViewBase(
        'Redo discarded invalid history entry (#undo=${_undoHistory.length}, #redo=${_redoHistory.length})',
      );
      return false;
    }
    _updateHistory(_undoHistory, currentEntry);
    _logGraphViewBase(
      'Redo applied (#undo=${_undoHistory.length}, #redo=${_redoHistory.length})',
    );
    return true;
  }

  void _updateHistory(
    List<_GraphHistoryEntry> history,
    _GraphHistoryEntry entry, {
    bool clearRedo = false,
  }) {
    history.add(entry);
    _trimHistory(history);
    if (clearRedo) {
      _redoHistory.clear();
    }
  }

  /// Synchronises the canvas with the provided domain [data].
  @protected
  void synchronizeGraph(TSnapshot? data, {bool fromMutation = false}) {
    final snapshot = toSnapshot(data);
    final incomingSignature = _snapshotContentSignature(snapshot);
    final isDomainEcho = !fromMutation &&
        !_isApplyingInternalSnapshot &&
        incomingSignature == _pendingDomainEchoSignature;

    if (fromMutation || _isApplyingInternalSnapshot) {
      _pendingDomainEchoSignature = incomingSignature;
    } else if (isDomainEcho) {
      _pendingDomainEchoSignature = null;
      _logGraphViewBase('Acknowledged domain echo without clearing history');
    } else {
      _pendingDomainEchoSignature = null;
    }

    final isExternalSync = !fromMutation && !_isApplyingInternalSnapshot;
    if (isExternalSync &&
        !isDomainEcho &&
        (_undoHistory.isNotEmpty || _redoHistory.isNotEmpty)) {
      _undoHistory.clear();
      _redoHistory.clear();
      graphRevision.value++;
      _logGraphViewBase(
        'History cleared due to external synchronization (revision=${graphRevision.value})',
      );
    }

    final incomingNodes = {for (final node in snapshot.nodes) node.id: node};
    final incomingEdges = {for (final edge in snapshot.edges) edge.id: edge};
    _logGraphViewBase(
      'Synchronizing graph (incomingNodes=${incomingNodes.length}, incomingEdges=${incomingEdges.length})',
    );

    final shouldEvictCaches = incomingNodes.length > cacheEvictionThreshold ||
        incomingEdges.length > cacheEvictionThreshold;
    if (shouldEvictCaches) {
      _logGraphViewBase(
        'Evicting caches due to threshold (limit=$cacheEvictionThreshold)',
      );
      _evictGraphCaches(notifyGraph: false);
    }

    final previousHighlight = SimulationHighlight(
      stateIds: Set<String>.from(highlightNotifier.value.stateIds),
      transitionIds: Set<String>.from(highlightNotifier.value.transitionIds),
    );

    _isSynchronizing = true;

    var nodesDirty = false;
    var edgesDirty = false;

    try {
      final removedNodeIds =
          _nodes.keys.where((id) => !incomingNodes.containsKey(id)).toList();
      for (final nodeId in removedNodeIds) {
        _nodes.remove(nodeId);
        final anchorEdge = _graphNodeAnchors.remove(nodeId);
        if (anchorEdge != null) {
          graph.removeEdge(anchorEdge);
        }
        final nodeInstance = _graphNodes.remove(nodeId);
        if (nodeInstance != null) {
          graph.removeNode(nodeInstance);
          nodesDirty = true;
        }

        final affectedEdges = _edges.values
            .where(
              (edge) => edge.fromStateId == nodeId || edge.toStateId == nodeId,
            )
            .map((edge) => edge.id)
            .toList();
        for (final edgeId in affectedEdges) {
          _edges.remove(edgeId);
          final edgeInstance = _graphEdges.remove(edgeId);
          if (edgeInstance != null) {
            graph.removeEdge(edgeInstance);
            edgesDirty = true;
          }
          pruneLinkHighlight(edgeId);
        }
      }

      final removedEdgeIds =
          _edges.keys.where((id) => !incomingEdges.containsKey(id)).toList();
      for (final edgeId in removedEdgeIds) {
        _edges.remove(edgeId);
        final edgeInstance = _graphEdges.remove(edgeId);
        if (edgeInstance != null) {
          graph.removeEdge(edgeInstance);
          edgesDirty = true;
        }
        pruneLinkHighlight(edgeId);
      }

      for (final entry in incomingNodes.entries) {
        final nodeId = entry.key;
        final incomingNode = entry.value;
        final existingNode = _nodes[nodeId];
        final nodeInstance = _graphNodes[nodeId];

        if (existingNode == null || nodeInstance == null) {
          final createdNode = buildGraphNode(incomingNode);
          _nodes[nodeId] = incomingNode;
          _graphNodes[nodeId] = createdNode;
          graph.addNode(createdNode);
          nodesDirty = true;
          continue;
        }

        final hasPositionChanged = existingNode.x != incomingNode.x ||
            existingNode.y != incomingNode.y;
        final hasMetadataChanged = existingNode.label != incomingNode.label ||
            existingNode.isInitial != incomingNode.isInitial ||
            existingNode.isAccepting != incomingNode.isAccepting;

        if (hasPositionChanged || hasMetadataChanged) {
          nodeInstance.position = Offset(incomingNode.x, incomingNode.y);
          graph.markModified();
          nodesDirty = true;
        }

        _nodes[nodeId] = incomingNode;
      }

      for (final entry in incomingEdges.entries) {
        final edgeId = entry.key;
        final incomingEdge = entry.value;
        final existingEdge = _edges[edgeId];
        final edgeInstance = _graphEdges[edgeId];

        if (existingEdge == null || edgeInstance == null) {
          final fromNode = _graphNodes[incomingEdge.fromStateId];
          final toNode = _graphNodes[incomingEdge.toStateId];
          if (fromNode == null || toNode == null) {
            continue;
          }
          final createdEdge = buildGraphEdge(incomingEdge, fromNode, toNode);
          _edges[edgeId] = incomingEdge;
          _graphEdges[edgeId] = createdEdge;
          graph.addEdgeS(createdEdge);
          edgesDirty = true;
          continue;
        }

        if (existingEdge != incomingEdge) {
          final endpointsChanged =
              existingEdge.fromStateId != incomingEdge.fromStateId ||
                  existingEdge.toStateId != incomingEdge.toStateId;

          if (endpointsChanged) {
            graph.removeEdge(edgeInstance);
            final fromNode = _graphNodes[incomingEdge.fromStateId];
            final toNode = _graphNodes[incomingEdge.toStateId];
            if (fromNode == null || toNode == null) {
              _graphEdges.remove(edgeId);
              _edges[edgeId] = incomingEdge;
              edgesDirty = true;
              continue;
            }

            final recreatedEdge =
                buildGraphEdge(incomingEdge, fromNode, toNode);
            _graphEdges[edgeId] = recreatedEdge;
            graph.addEdgeS(recreatedEdge);
          } else {
            updateGraphEdgeInstance(edgeInstance, incomingEdge);
            graph.markModified();
          }
          _edges[edgeId] = incomingEdge;
          edgesDirty = true;
        }
      }

      final anchorsDirty = _syncGraphNodeAnchors();

      final sanitizedHighlight = SimulationHighlight(
        stateIds: previousHighlight.stateIds
            .where((id) => incomingNodes.containsKey(id))
            .toSet(),
        transitionIds: previousHighlight.transitionIds
            .where((id) => incomingEdges.containsKey(id))
            .toSet(),
      );

      updateLinkHighlights(sanitizedHighlight.transitionIds);
      highlightNotifier.value = sanitizedHighlight;
      _logGraphViewBase(
        'Highlight updated (states=${sanitizedHighlight.stateIds.length}, transitions=${sanitizedHighlight.transitionIds.length})',
      );

      if (nodesDirty || edgesDirty || anchorsDirty) {
        graph.notifyGraphObserver();
        graphRevision.value++;
        _logGraphViewBase(
          'Graph refreshed (nodes=${_nodes.length}, edges=${_edges.length}, revision=${graphRevision.value})',
        );
      } else {
        _logGraphViewBase(
          'Graph synchronization completed without structural changes',
        );
      }
    } finally {
      _isSynchronizing = false;
    }
  }

  @visibleForTesting
  void pruneLinkHighlight(String edgeId) {
    if (!highlightedTransitionIds.contains(edgeId)) {
      return;
    }

    _logGraphViewBase('Pruning highlight for $edgeId');
    final updatedHighlighted = Set<String>.from(highlightedTransitionIds)
      ..remove(edgeId);
    updateLinkHighlights(updatedHighlighted);

    final currentHighlight = highlightNotifier.value;
    if (currentHighlight.transitionIds.contains(edgeId)) {
      final remaining = Set<String>.from(currentHighlight.transitionIds)
        ..remove(edgeId);
      if (remaining.isEmpty && currentHighlight.stateIds.isEmpty) {
        highlightNotifier.value = SimulationHighlight.empty;
      } else {
        highlightNotifier.value = currentHighlight.copyWith(
          transitionIds: remaining,
        );
      }
    } else if (updatedHighlighted.isEmpty &&
        currentHighlight.transitionIds.isEmpty &&
        currentHighlight.stateIds.isEmpty) {
      highlightNotifier.value = SimulationHighlight.empty;
    }
  }

  _GraphHistoryEntry? _captureHistoryEntry() {
    try {
      final snapshot = toSnapshot(currentDomainData);
      final serialized = jsonEncode(snapshot.toJson());
      final compressed = Uint8List.fromList(
        _historyCodec.encode(utf8.encode(serialized)),
      );
      final highlight = SimulationHighlight(
        stateIds: Set<String>.from(highlightNotifier.value.stateIds),
        transitionIds: Set<String>.from(highlightNotifier.value.transitionIds),
      );
      return _GraphHistoryEntry(
        serializedSnapshot: compressed,
        highlight: highlight,
      );
    } catch (_) {
      return null;
    }
  }

  String _snapshotContentSignature(GraphViewAutomatonSnapshot snapshot) {
    final nodes = [...snapshot.nodes]..sort((a, b) => a.id.compareTo(b.id));
    final edges = [...snapshot.edges]..sort((a, b) => a.id.compareTo(b.id));
    final metadata = Map<String, dynamic>.from(snapshot.metadata.toJson());
    for (final key in const ['alphabet', 'stackAlphabet', 'tapeAlphabet']) {
      final values = (metadata[key] as List?)?.cast<String>();
      if (values != null) {
        metadata[key] = [...values]..sort();
      }
    }

    return jsonEncode({
      'nodes': [for (final node in nodes) node.toJson()],
      'edges': [
        for (final edge in edges)
          {
            ...edge.toJson(),
            'symbols': [...edge.symbols]..sort(),
          },
      ],
      'metadata': metadata,
    });
  }

  bool _restoreHistoryEntry(_GraphHistoryEntry entry) {
    _isApplyingInternalSnapshot = true;
    try {
      return _applyHistoryEntry(entry);
    } finally {
      _isApplyingInternalSnapshot = false;
    }
  }

  bool _applyHistoryEntry(_GraphHistoryEntry entry) {
    final snapshot = entry.decodeSnapshot(_historyCodec);
    if (snapshot == null) {
      _logGraphViewBase('Failed to decode history entry');
      return false;
    }
    final stateIds = snapshot.nodes.map((node) => node.id).toSet();
    GraphViewCanvasEdge? danglingEdge;
    for (final edge in snapshot.edges) {
      if (!stateIds.contains(edge.fromStateId) ||
          !stateIds.contains(edge.toStateId)) {
        danglingEdge = edge;
        break;
      }
    }
    if (danglingEdge != null) {
      _logGraphViewBase(
        'History entry references missing state (edge=${danglingEdge.id})',
      );
      return false;
    }
    try {
      applySnapshotToDomain(snapshot);
    } catch (error) {
      _logGraphViewBase('Failed to apply history entry: $error');
      return false;
    }

    final highlight = SimulationHighlight(
      stateIds: Set<String>.from(entry.highlight.stateIds),
      transitionIds: Set<String>.from(entry.highlight.transitionIds),
    );

    updateLinkHighlights(highlight.transitionIds);
    highlightNotifier.value = highlight;
    _logGraphViewBase(
      'History entry applied (states=${highlight.stateIds.length}, transitions=${highlight.transitionIds.length})',
    );
    return true;
  }

  void _trimHistory(List<_GraphHistoryEntry> history) {
    final excess = history.length - historyLimit;
    if (excess > 0) {
      history.removeRange(0, excess);
    }
  }

  bool _syncGraphNodeAnchors() {
    var anchorsDirty = false;
    final connectedNodeIds = <String>{};
    for (final edge in _edges.values) {
      connectedNodeIds
        ..add(edge.fromStateId)
        ..add(edge.toStateId);
    }

    final staleAnchorIds = _graphNodeAnchors.keys
        .where(
          (id) => !_graphNodes.containsKey(id) || connectedNodeIds.contains(id),
        )
        .toList(growable: false);
    for (final nodeId in staleAnchorIds) {
      final anchor = _graphNodeAnchors.remove(nodeId);
      if (anchor != null) {
        graph.removeEdge(anchor);
        anchorsDirty = true;
      }
    }

    for (final entry in _graphNodes.entries) {
      final nodeId = entry.key;
      if (connectedNodeIds.contains(nodeId) ||
          _graphNodeAnchors.containsKey(nodeId)) {
        continue;
      }

      final node = entry.value;
      final anchor = Edge(
        node,
        node,
        key: ValueKey('__node_anchor_$nodeId'),
        renderer: _invisibleNodeAnchorRenderer,
      );
      _graphNodeAnchors[nodeId] = anchor;
      graph.addEdgeS(anchor);
      anchorsDirty = true;
    }

    return anchorsDirty;
  }

  void _syncGraphEdgeControlPoint(
    Edge target,
    GraphViewCanvasEdge edge,
  ) {
    final controlPoint =
        edge.controlPointX != null && edge.controlPointY != null
            ? Offset(edge.controlPointX!, edge.controlPointY!)
            : null;
    setTuringLabEdgeControlPoint(target, controlPoint);
  }

  void _evictGraphCaches({required bool notifyGraph}) {
    if (_graphEdges.isEmpty &&
        _graphNodes.isEmpty &&
        _graphNodeAnchors.isEmpty) {
      _nodes.clear();
      _edges.clear();
      return;
    }

    for (final edge in List<Edge>.from(_graphNodeAnchors.values)) {
      graph.removeEdge(edge);
    }
    for (final edge in List<Edge>.from(_graphEdges.values)) {
      graph.removeEdge(edge);
    }
    for (final node in List<Node>.from(_graphNodes.values)) {
      graph.removeNode(node);
    }

    _graphEdges.clear();
    _graphNodeAnchors.clear();
    _graphNodes.clear();
    _edges.clear();
    _nodes.clear();

    if (notifyGraph) {
      graph.notifyGraphObserver();
    }
  }
}
