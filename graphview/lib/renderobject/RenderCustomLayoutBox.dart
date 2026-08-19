part of graphview;

class RenderCustomLayoutBox extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, NodeBoxData>,
        RenderBoxContainerDefaultsMixin<RenderBox, NodeBoxData>
    implements GraphObserver {
  late Paint _paint;
  late AnimationController _nodeAnimationController;
  late GraphChildDelegate _delegate;
  late GraphChildManager childManager;

  Size? _cachedSize;
  bool _isInitialized = false;
  bool _needsFullRecalculation = false;
  Graph? _observedGraph;
  late bool enableAnimation;
  final opacityPaint = Paint();

  final animatedPositions = <Node, Offset>{};
  final _children = <Node, RenderBox>{};
  final _activeChildrenForLayoutPass = <Node, RenderBox>{};

  // Dirty edge tracking for performance optimization
  final dirtyEdges = <Edge>{};

  // Path caching system for performance optimization
  final _pathCache = <Edge, Path>{};

  // Previous node positions for distance threshold tracking
  final _previousNodePositions = <Node, Offset>{};

  // Distance threshold for dirty tracking (movements smaller than this are ignored)
  static const double _movementThreshold = 1.0;

  // Drag gesture state
  Node? _draggedNode;
  Offset? _dragStartLocalPosition;
  Offset? _dragStartNodePosition;
  int? _activePointerId;
  bool _isDragging = false;
  NodeDraggingConfiguration? _nodeDraggingConfiguration;

  RenderCustomLayoutBox(
    GraphChildDelegate delegate,
    Paint? paint,
    bool enableAnimation, {
    required AnimationController nodeAnimationController,
    required this.childManager,
  }) {
    _nodeAnimationController = nodeAnimationController;
    _delegate = delegate;
    edgePaint = paint;
    this.enableAnimation = enableAnimation;
  }

  RenderBox? buildOrObtainChildFor(Node node) {
    assert(debugDoingThisLayout);

    if (_needsFullRecalculation || !_children.containsKey(node)) {
      invokeLayoutCallback<BoxConstraints>((BoxConstraints _) {
        childManager.buildChild(node);
      });
    } else {
      childManager.reuseChild(node);
    }

    if (!_children.containsKey(node)) {
      // There is no child for this node, the delegate may not provide one
      return null;
    }

    assert(_children.containsKey(node));
    final child = _children[node]!;
    _activeChildrenForLayoutPass[node] = child;
    return child;
  }

  GraphChildDelegate get delegate => _delegate;

  Graph get graph => _delegate.getVisibleGraph();

  Algorithm get algorithm => _delegate.algorithm;

  set delegate(GraphChildDelegate value) {
    // if (value != _delegate) {
    _needsFullRecalculation = true;
    _isInitialized = false;
    _delegate = value;
    if (attached) {
      _observeSourceGraph(value.graph);
    }
    markNeedsLayout();
    // }
  }

  // Observes the delegate's source graph (not the derived visible graph) so
  // in-place position updates followed by Graph.notifyGraphObserver() trigger
  // a repaint, e.g. live node-drag previews driven by the host app.
  void _observeSourceGraph(Graph? value) {
    if (identical(_observedGraph, value)) return;
    _observedGraph?.graphObserver.remove(this);
    _observedGraph = value;
    value?.graphObserver.add(this);
  }

  @override
  void notifyGraphInvalidated() {
    markNeedsPaint();
  }

  void markNeedsRecalculation() {
    _needsFullRecalculation = false;
    _isInitialized = false;
    markNeedsLayout();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _nodeAnimationController.addListener(_onAnimationTick);
    _observeSourceGraph(_delegate.graph);
  }

  @override
  void detach() {
    _observeSourceGraph(null);
    _nodeAnimationController.removeListener(_onAnimationTick);
    super.detach();
  }

  void forceRecalculation() {
    _needsFullRecalculation = true;
    _isInitialized = false;
    markNeedsLayout();
  }

  Paint get edgePaint => _paint;

  set edgePaint(Paint? value) {
    final newPaint = value ??
        (Paint()
          ..color = Colors.black
          ..strokeWidth = 3)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt;

    _paint = newPaint;
    markNeedsPaint();
  }

  AnimationController get nodeAnimationController => _nodeAnimationController;

  set nodeAnimationController(AnimationController value) {
    if (identical(_nodeAnimationController, value)) return;
    _nodeAnimationController.removeListener(_onAnimationTick);
    _nodeAnimationController = value;
    _nodeAnimationController.addListener(_onAnimationTick);
    markNeedsLayout();
  }

  NodeDraggingConfiguration? get nodeDraggingConfiguration =>
      _nodeDraggingConfiguration;

  set nodeDraggingConfiguration(NodeDraggingConfiguration? value) {
    _nodeDraggingConfiguration = value;
  }

  /// Returns a copy of the dirty edges set for read-only access.
  Set<Edge> getDirtyEdges() => Set<Edge>.from(dirtyEdges);

  /// Returns cached path for edge if available and edge is not dirty.
  /// Returns null if edge is dirty or not in cache.
  Path? getCachedPath(Edge edge) {
    if (dirtyEdges.contains(edge)) {
      return null; // Don't use cache for dirty edges
    }
    return _pathCache[edge];
  }

  /// Stores computed path in cache for reuse when nodes are static.
  void cachePath(Edge edge, Path path) {
    _pathCache[edge] = path;
  }

  /// Clears all cached paths. Useful when forcing full recalculation.
  void clearPathCache() {
    _pathCache.clear();
  }

  void _onAnimationTick() {
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_children.isEmpty) return;

    if (enableAnimation) {
      final t = _nodeAnimationController.value;
      animatedPositions.clear();

      for (final entry in _children.entries) {
        final node = entry.key;
        final child = entry.value;
        final nodeData = child.parentData as NodeBoxData;
        final pos =
            Offset.lerp(nodeData.startOffset, nodeData.targetOffset, t)!;
        animatedPositions[node] = pos;
      }

      context.canvas.save();
      context.canvas.translate(offset.dx, offset.dy);
      algorithm.renderer?.setGraph(graph);
      algorithm.renderer?.setAnimatedPositions(animatedPositions);
      _prepareRendererForEdgePass();

      final collapsingEdges =
          _delegate.controller?.getCollapsingEdges(graph).toSet() ?? {};
      final expandingEdges =
          _delegate.controller?.getExpandingEdges(graph).toSet() ?? {};

      for (final edge in graph.edges) {
        var edgePaintWithOpacity = Paint.from(edge.paint ?? edgePaint);

        // Apply fade effect for collapsing edges (fade out)
        if (collapsingEdges.contains(edge)) {
          edgePaintWithOpacity.color =
              edgePaintWithOpacity.color.withValues(alpha: 1.0 - t);
        }
        // Apply fade effect for expanding edges (fade in)
        else if (expandingEdges.contains(edge)) {
          edgePaintWithOpacity.color =
              edgePaintWithOpacity.color.withValues(alpha: t);
        }

        algorithm.renderer?.renderEdge(
          context.canvas,
          edge,
          edgePaintWithOpacity,
        );
      }

      // Invalidate cached paths for dirty edges before clearing
      for (final edge in dirtyEdges) {
        _pathCache.remove(edge);
      }

      // Clear dirty edges after rendering
      dirtyEdges.clear();

      context.canvas.restore();

      _paintNodes(context, offset, t);
    } else {
      context.canvas.save();
      context.canvas.translate(offset.dx, offset.dy);
      algorithm.renderer?.setGraph(graph);
      algorithm.renderer?.setAnimatedPositions(const <Node, Offset>{});
      _prepareRendererForEdgePass();
      graph.edges.forEach((edge) {
        algorithm.renderer?.renderEdge(context.canvas, edge, edgePaint);
      });

      // Invalidate cached paths for dirty edges before clearing
      for (final edge in dirtyEdges) {
        _pathCache.remove(edge);
      }

      // Clear dirty edges after rendering
      dirtyEdges.clear();

      context.canvas.restore();

      for (final entry in _children.entries) {
        final node = entry.key;
        final child = entry.value;

        if (_delegate.isNodeVisible(node)) {
          // Keep hit-test offsets and animation anchors in sync with the live
          // position so re-enabling animation later doesn't replay a move that
          // was already painted (e.g. after a live drag preview).
          final nodeData = child.parentData as NodeBoxData;
          nodeData.offset = node.position;
          nodeData.startOffset = node.position;
          nodeData.targetOffset = node.position;
          context.paintChild(child, offset + node.position);
        }
      }
    }
  }

  @override
  void performLayout() {
    _activeChildrenForLayoutPass.clear();
    childManager.startLayout();

    final looseConstraints = BoxConstraints.loose(constraints.biggest);

    if (_needsFullRecalculation || !_isInitialized) {
      _layoutNodesLazily(looseConstraints);
      _cachedSize = _delegate.runAlgorithm();
      _isInitialized = true;
      _needsFullRecalculation = false;
    }

    size = _cachedSize ?? Size.zero;

    invokeLayoutCallback<BoxConstraints>((BoxConstraints _) {
      childManager.endLayout();
    });

    if (enableAnimation) {
      _updateAnimationStates();
    } else {
      _updateNodePositions();
    }
  }

  void _paintNodes(PaintingContext context, Offset offset, double t) {
    for (final entry in _children.entries) {
      final node = entry.key;
      final child = entry.value;
      final nodeData = child.parentData as NodeBoxData;
      final pos = animatedPositions[node]!;

      final isVisible = _delegate.isNodeVisible(node);
      if (isVisible) {
        final isExpanding =
            _delegate.controller?.isNodeExpanding(node) ?? false;
        if (_nodeAnimationController.isAnimating && isExpanding) {
          _paintExpandingNode(context, child, offset, pos, t);
        } else {
          context.paintChild(child, offset + pos);
        }
      } else {
        if (_nodeAnimationController.isAnimating &&
            nodeData.startOffset != nodeData.targetOffset) {
          _paintCollapsingNode(context, child, offset, pos, t);
        } else if (_nodeAnimationController.isCompleted) {
          nodeData.startOffset = nodeData.targetOffset;
        }
      }

      if (_nodeAnimationController.isCompleted) {
        nodeData.offset = node.position;
      }
    }

    if (_nodeAnimationController.isCompleted) {
      _delegate.controller?.removeCollapsingNodes();
    }
  }

  void _prepareRendererForEdgePass() {
    final renderer = algorithm.renderer;
    if (renderer == null) {
      return;
    }
    if (renderer is RenderCycleAware) {
      (renderer as RenderCycleAware).prepareForRenderCycle();
    }
  }

  void _paintExpandingNode(PaintingContext context, RenderBox child,
      Offset offset, Offset pos, double t) {
    final center =
        pos + offset + Offset(child.size.width * 0.5, child.size.height * 0.5);

    context.canvas.save();

    // Apply scaling from center
    context.canvas.translate(center.dx, center.dy);
    context.canvas.scale(t, t);
    context.canvas.translate(-center.dx, -center.dy);

    // Paint with opacity using saveLayer
    opacityPaint
      ..color = Color.fromRGBO(255, 255, 255, t)
      ..colorFilter = ColorFilter.mode(
          Colors.white.withValues(alpha: t), BlendMode.modulate);

    context.canvas.saveLayer(
        Rect.fromLTWH(pos.dx + offset.dx - 20, pos.dy + offset.dy - 20,
            child.size.width + 40, child.size.height + 40),
        opacityPaint);

    context.paintChild(child, offset + pos);

    context.canvas.restore(); // Restore saveLayer
    context.canvas.restore(); // Restore main save
  }

  void _paintCollapsingNode(PaintingContext context, RenderBox child,
      Offset offset, Offset pos, double t) {
    final progress = (1.0 - t);
    final center =
        pos + offset + Offset(child.size.width * 0.5, child.size.height * 0.5);

    context.canvas.save();

    // Apply scaling from center
    context.canvas.translate(center.dx, center.dy);
    context.canvas.scale(progress, progress);
    context.canvas.translate(-center.dx, -center.dy);

    // Paint with opacity using saveLayer
    opacityPaint
      ..color = Color.fromRGBO(255, 255, 255, progress)
      ..colorFilter = ColorFilter.mode(
          Colors.white.withValues(alpha: progress), BlendMode.modulate);

    context.canvas.saveLayer(
        Rect.fromLTWH(pos.dx + offset.dx - 20, pos.dy + offset.dy - 20,
            child.size.width + 40, child.size.height + 40),
        opacityPaint);

    context.paintChild(child, offset + pos);

    context.canvas.restore(); // Restore saveLayer
    context.canvas.restore(); // Restore main save
  }

  void _updateNodePositions() {
    for (final entry in _children.entries) {
      final node = entry.key;
      final child = entry.value;
      final nodeData = child.parentData as NodeBoxData;

      if (_delegate.isNodeVisible(node)) {
        nodeData.offset = node.position;
      } else {
        final parent = delegate.findClosestVisibleAncestor(node);
        nodeData.offset = parent?.position ?? node.position;
      }
    }
  }

  void _layoutNodesLazily(BoxConstraints constraints) {
    for (final node in graph.nodes) {
      final child = buildOrObtainChildFor(node);
      if (child != null) {
        child.layout(constraints, parentUsesSize: true);
        node.size = Size(child.size.width.ceilToDouble(), child.size.height);
      }
    }
  }

  void _updateAnimationStates() {
    for (final entry in _children.entries) {
      final node = entry.key;
      final child = entry.value;
      final nodeData = child.parentData as NodeBoxData;
      final isVisible = _delegate.isNodeVisible(node);

      if (isVisible) {
        _updateVisibleNodeAnimation(nodeData, node);
      } else {
        _updateCollapsedNodeAnimation(nodeData, node);
      }
    }

    _nodeAnimationController.reset();
    _nodeAnimationController.forward();
  }

  void _updateVisibleNodeAnimation(NodeBoxData nodeData, Node graphNode) {
    final prevTarget = nodeData.targetOffset;
    var newPos = graphNode.position;

    if (prevTarget == null) {
      final parent = graph.predecessorsOf(graphNode).firstOrNull;
      final pastParentPosition = animatedPositions[parent];
      nodeData.startOffset = pastParentPosition ?? parent?.position ?? newPos;
      nodeData.targetOffset = newPos;
    } else if (prevTarget != newPos) {
      nodeData.startOffset = prevTarget;
      nodeData.targetOffset = newPos;
    } else {
      nodeData.startOffset = newPos;
      nodeData.targetOffset = newPos;
    }
  }

  void _updateCollapsedNodeAnimation(NodeBoxData nodeData, Node graphNode) {
    final parent = delegate.findClosestVisibleAncestor(graphNode);
    final parentPos = parent?.position ?? Offset.zero;

    final prevTarget = nodeData.targetOffset;

    if (nodeData.startOffset == nodeData.targetOffset) {
      nodeData.targetOffset = parentPos;
    } else if (prevTarget != null && prevTarget != parentPos) {
      // Just collapsed now → animate toward parent
      nodeData.startOffset = graphNode.position;
      nodeData.targetOffset = parentPos;
    } else {
      // animation finished → lock to parent
      nodeData.startOffset = parentPos;
      nodeData.targetOffset = parentPos;
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    if (enableAnimation && !_nodeAnimationController.isCompleted) return false;

    for (final entry in _children.entries) {
      final node = entry.key;

      if (delegate.isNodeVisible(node)) {
        final child = entry.value;

        final childParentData = child.parentData as BoxParentData;
        final isHit = result.addWithPaintOffset(
          offset: childParentData.offset,
          position: position,
          hitTest: (BoxHitTestResult result, Offset transformed) {
            return child.hitTest(result, position: transformed);
          },
        );
        if (isHit) return true;
      }
    }
    return false;
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! NodeBoxData) {
      child.parentData = NodeBoxData();
    }
  }

  // ---- Called from GraphViewElement ----
  void _insertChild(RenderBox child, Node slot) {
    _children[slot] = child;
    insert(child, after: lastChild);
  }

  void _moveChild(RenderBox child, {required Node from, required Node to}) {
    if (_children[from] == child) {
      _children.remove(from);
    }
    _children[to] = child;
  }

  void _removeChild(RenderBox child, Node slot) {
    if (_children[slot] == child) {
      _children.remove(slot);
    }
    remove(child);
  }

  @override
  void visitChildren(RenderObjectVisitor visitor) {
    for (final child in _children.values) {
      visitor(child);
    }
  }

  /// Find the node at the given local position.
  Node? _findNodeAt(Offset localPosition) {
    for (final entry in _children.entries.toList().reversed) {
      final node = entry.key;
      final child = entry.value;

      if (!delegate.isNodeVisible(node)) continue;

      final nodePosition = node.position;
      final nodeRect = Rect.fromLTWH(
        nodePosition.dx,
        nodePosition.dy,
        child.size.width,
        child.size.height,
      );

      if (nodeRect.contains(localPosition)) {
        return node;
      }
    }
    return null;
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (size.contains(position)) {
      return super.hitTest(result, position: position);
    }
    if (hitTestChildren(result, position: position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    assert(debugHandleEvent(event, entry));

    if (event is PointerDownEvent) {
      _handlePointerDown(event);
    } else if (event is PointerMoveEvent) {
      _handlePointerMove(event);
    } else if (event is PointerUpEvent) {
      _handlePointerUp(event);
    } else if (event is PointerCancelEvent) {
      _handlePointerCancel(event);
    }
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (_activePointerId != null) return;
    if (enableAnimation && !_nodeAnimationController.isCompleted) return;

    final localPosition = event.localPosition;
    final node = _findNodeAt(localPosition);

    if (node == null) return;
    if (node.locked) return;

    // Check canDragPredicate if configuration is available
    final predicate = _nodeDraggingConfiguration?.canDragPredicate;
    if (predicate != null && !predicate(node)) return;

    _nodeDraggingConfiguration?.onNodePointerDown?.call(node, event);

    // External recognizers can observe the pointer without enabling
    // GraphView's built-in node movement.
    if (_nodeDraggingConfiguration?.enabled == false) return;

    _activePointerId = event.pointer;
    _draggedNode = node;
    _dragStartLocalPosition = localPosition;
    _dragStartNodePosition = node.position;
    _previousNodePositions[node] =
        node.position; // Initialize previous position
    _isDragging = false;
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (_activePointerId != event.pointer || _draggedNode == null) return;

    final draggedNode = _draggedNode!;
    final startPosition = _dragStartLocalPosition!;
    final startNodePosition = _dragStartNodePosition!;

    final delta = event.localPosition - startPosition;

    // Start dragging if moved more than a threshold
    if (!_isDragging && delta.distance > 5.0) {
      _isDragging = true;
      _nodeDraggingConfiguration?.onNodeDragStart?.call(draggedNode);
    }

    if (_isDragging) {
      final newPosition = startNodePosition + delta;

      // Calculate distance moved from previous position
      final previousPosition =
          _previousNodePositions[draggedNode] ?? startNodePosition;
      final distanceMoved = (newPosition - previousPosition).distance;

      // Only update and mark dirty if movement exceeds threshold (skip sub-pixel updates)
      if (distanceMoved >= _movementThreshold) {
        draggedNode.position = newPosition;
        final child = _children[draggedNode];
        if (child != null) {
          final nodeData = child.parentData as NodeBoxData;
          nodeData.offset = newPosition;
        }

        // Mark all edges connected to this node as dirty
        dirtyEdges.addAll(graph.getOutEdges(draggedNode));
        dirtyEdges.addAll(graph.getInEdges(draggedNode));

        // Store current position for next comparison
        _previousNodePositions[draggedNode] = newPosition;

        graph.markModified();
        markNeedsPaint();
        _nodeDraggingConfiguration?.onNodeDragUpdate
            ?.call(draggedNode, newPosition);
      }
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (_activePointerId != event.pointer) return;

    // Invoke onNodeDragEnd callback before resetting state
    if (_isDragging && _draggedNode != null) {
      _nodeDraggingConfiguration?.onNodeDragEnd
          ?.call(_draggedNode!, _draggedNode!.position);
      // Clean up previous position tracking
      _previousNodePositions.remove(_draggedNode);
    }

    _activePointerId = null;
    _draggedNode = null;
    _dragStartLocalPosition = null;
    _dragStartNodePosition = null;
    _isDragging = false;
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    if (_activePointerId != event.pointer) return;

    // Restore node position on cancel
    if (_draggedNode != null && _dragStartNodePosition != null) {
      _draggedNode!.position = _dragStartNodePosition!;
      final child = _children[_draggedNode];
      if (child != null) {
        final nodeData = child.parentData as NodeBoxData;
        nodeData.offset = _dragStartNodePosition!;
      }
      // Clean up previous position tracking
      _previousNodePositions.remove(_draggedNode);
      markNeedsPaint();
    }

    _activePointerId = null;
    _draggedNode = null;
    _dragStartLocalPosition = null;
    _dragStartNodePosition = null;
    _isDragging = false;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Graph>('graph', graph));
    properties.add(DiagnosticsProperty<Algorithm>('algorithm', algorithm));
    properties.add(DiagnosticsProperty<Paint>('paint', edgePaint));
  }
}
