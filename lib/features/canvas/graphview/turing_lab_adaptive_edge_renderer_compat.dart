part of 'turing_lab_adaptive_edge_renderer.dart';

final Expando<Offset> _turingLabEdgeControlPoints = Expando<Offset>(
  'turingLabEdgeControlPoint',
);

void setTuringLabEdgeControlPoint(Edge edge, Offset? controlPoint) {
  edge.controlPoint = controlPoint;
  _turingLabEdgeControlPoints[edge] = controlPoint;
}

Offset? turingLabEdgeControlPoint(Edge edge) {
  return edge.controlPoint ?? _turingLabEdgeControlPoints[edge];
}

class EdgeLabelGeometry {
  const EdgeLabelGeometry({required this.position, this.angle});

  final Offset position;
  final double? angle;
}

class AnimatedAdaptiveEdgeRenderer extends AdaptiveEdgeRenderer
    implements RenderCycleAware {
  final Map<Edge, EdgePathGeometry> _pathGeometryCache =
      <Edge, EdgePathGeometry>{};
  int _pathGeometryCacheCount = -1;
  int _pathGeometryCacheSignature = 0;
  int _pathGeometryCacheGeneration = -1;
  bool _pathGeometryCacheDirty = true;
  AnimatedAdaptiveEdgeRenderer({
    required super.config,
    this.animationConfig = const AnimatedEdgeConfiguration(),
    this.animationValue = 0.0,
    super.noArrow,
  });

  final AnimatedEdgeConfiguration animationConfig;
  double animationValue;
  Graph? _graph;
  final Map<String, List<Edge>> _parallelEdgeCache = <String, List<Edge>>{};
  Graph? _parallelEdgeCacheGraph;
  int _parallelEdgeCacheCount = -1;

  Graph? get graph => _graph;

  @override
  void setGraph(Graph graph) {
    super.setGraph(graph);
    _graph = graph;
    _clearParallelEdgeCache();
    _invalidatePathGeometryCache();
  }

  void setAnimationValue(double value) {
    animationValue = value;
  }

  void invalidatePathGeometryCache() {
    _invalidatePathGeometryCache();
  }

  @override
  void prepareForRenderCycle() {
    super.prepareForRenderCycle();
    _ensureParallelEdgeCache();
    _ensurePathGeometryCache(verifyEdgeSignature: true);
  }

  EdgePathGeometry? buildEdgeGeometry(
    Edge edge, {
    double arrowLength = ARROW_LENGTH,
  }) {
    _ensurePathGeometryCache();
    final cached = _pathGeometryCache[edge];
    if (cached != null) {
      return cached;
    }

    final geometry = _buildEdgeGeometryUncached(edge, arrowLength: arrowLength);
    if (geometry != null) {
      _pathGeometryCache[edge] = geometry;
    }
    return geometry;
  }

  EdgePathGeometry? _buildEdgeGeometryUncached(
    Edge edge, {
    required double arrowLength,
  }) {
    if (edge.source == edge.destination) {
      final loopResult = buildSelfLoopPath(edge, arrowLength: arrowLength);
      if (loopResult == null) {
        return null;
      }
      return buildPathGeometry(
        loopResult.path,
        arrowLength: arrowLength,
        isSelfLoop: true,
      );
    }

    final controlPoint = turingLabEdgeControlPoint(edge);
    if (controlPoint != null) {
      final sourcePoint = calculateSourceConnectionPoint(edge, controlPoint, 0);
      final destinationPoint = calculateDestinationConnectionPoint(
        edge,
        controlPoint,
        0,
      );
      final path = Path()
        ..moveTo(sourcePoint.dx, sourcePoint.dy)
        ..quadraticBezierTo(
          controlPoint.dx,
          controlPoint.dy,
          destinationPoint.dx,
          destinationPoint.dy,
        );
      return buildPathGeometry(path, arrowLength: arrowLength);
    }

    final sourceCenter = getNodeCenter(edge.source);
    final destinationCenter = getNodeCenter(edge.destination);
    final edgeIndex = _edgeIndex(edge);
    final sourcePoint = calculateSourceConnectionPoint(
      edge,
      destinationCenter,
      edgeIndex,
    );
    final destinationPoint = calculateDestinationConnectionPoint(
      edge,
      sourceCenter,
      edgeIndex,
    );
    final path = routeEdgePath(sourcePoint, destinationPoint, edge);
    return buildPathGeometry(path, arrowLength: arrowLength);
  }

  EdgeLabelGeometry? buildLabelGeometry(Edge edge, Path path) {
    final metric = path.computeMetrics().firstOrNull;
    if (metric == null) {
      return null;
    }

    final labelPosition = edge.labelPosition ?? EdgeLabelPosition.middle;
    final positionFactor = switch (labelPosition) {
      EdgeLabelPosition.start => 0.2,
      EdgeLabelPosition.middle => 0.5,
      EdgeLabelPosition.end => 0.8,
    };
    final tangent = metric.getTangentForOffset(metric.length * positionFactor);
    if (tangent == null) {
      return null;
    }

    return EdgeLabelGeometry(
      position: tangent.position,
      angle: (edge.labelFollowsEdgeDirection ?? true) ? tangent.angle : null,
    );
  }

  EdgePathGeometry buildPathGeometry(
    Path path, {
    double arrowLength = ARROW_LENGTH,
    bool isSelfLoop = false,
  }) {
    return EdgePathGeometry.fromPath(
      path,
      fallbackStart: Offset.zero,
      fallbackEnd: Offset.zero,
      arrowLength: arrowLength,
      kind: isSelfLoop ? EdgePathKind.selfLoop : EdgePathKind.curved,
    );
  }

  void paintEdgeGeometry(
    Canvas canvas,
    Edge edge,
    Paint paint,
    EdgePathGeometry geometry,
  ) {
    canvas.drawPath(geometry.path, paint);
  }

  void paintEdgeArrow(
    Canvas canvas,
    Edge edge,
    Paint paint,
    EdgePathGeometry geometry,
  ) {
    if ((geometry.arrowTip - geometry.arrowBase).distance < 0.001) {
      return;
    }
    drawTriangle(
      canvas,
      paint,
      geometry.arrowBase.dx,
      geometry.arrowBase.dy,
      geometry.arrowTip.dx,
      geometry.arrowTip.dy,
    );
  }

  void renderAnimatedParticlesOnPath(
    Canvas canvas,
    Edge edge,
    Paint paint,
    Path path,
  ) {
    final metrics = path.computeMetrics().toList(growable: false);
    if (metrics.isEmpty) {
      return;
    }

    final particlePaint = Paint()
      ..color =
          animationConfig.particleColor ?? edge.paint?.color ?? paint.color
      ..style = PaintingStyle.fill;
    final metric = metrics.first;

    for (var i = 0; i < animationConfig.particleCount; i++) {
      final basePosition = i / animationConfig.particleCount;
      final animatedPosition =
          (basePosition + animationValue * animationConfig.animationSpeed) %
              1.0;
      final tangent = metric.getTangentForOffset(
        animatedPosition * metric.length,
      );
      if (tangent != null) {
        canvas.drawCircle(
          tangent.position,
          animationConfig.particleSize,
          particlePaint,
        );
      }
    }
  }

  int _edgeIndex(Edge edge) {
    _ensureParallelEdgeCache();
    final edges = _parallelEdgeCache[_parallelEdgeKey(edge)];
    if (edges == null) {
      return 0;
    }
    final index = edges.indexOf(edge);
    return index < 0 ? 0 : index;
  }

  void _ensureParallelEdgeCache() {
    final currentGraph = graph;
    if (currentGraph == null) {
      _clearParallelEdgeCache();
      return;
    }
    if (_parallelEdgeCacheGraph != currentGraph ||
        _parallelEdgeCacheCount != currentGraph.edges.length) {
      _rebuildParallelEdgeCache();
    }
  }

  void _rebuildParallelEdgeCache() {
    final currentGraph = graph;
    if (currentGraph == null) {
      _clearParallelEdgeCache();
      return;
    }

    final graphEdges = currentGraph.edges.toList(growable: false);
    _parallelEdgeCache.clear();
    for (final edge in graphEdges) {
      _parallelEdgeCache
          .putIfAbsent(_parallelEdgeKey(edge), () => <Edge>[])
          .add(edge);
    }

    for (final edges in _parallelEdgeCache.values) {
      edges.sort(
        (left, right) => _edgeSortKey(
          left,
          graphEdges,
        ).compareTo(_edgeSortKey(right, graphEdges)),
      );
    }
    _parallelEdgeCacheGraph = currentGraph;
    _parallelEdgeCacheCount = graphEdges.length;
  }

  void _clearParallelEdgeCache() {
    _parallelEdgeCache.clear();
    _parallelEdgeCacheGraph = null;
    _parallelEdgeCacheCount = -1;
  }

  void _ensurePathGeometryCache({bool verifyEdgeSignature = false}) {
    final currentGraph = graph;
    if (currentGraph == null) {
      _clearPathGeometryCache();
      return;
    }

    final graphEdges = currentGraph.edges;
    final countChanged = _pathGeometryCacheCount != graphEdges.length;
    final generationChanged =
        _pathGeometryCacheGeneration != currentGraph.generation;
    int? edgeSignature;
    var signatureChanged = false;
    if (verifyEdgeSignature ||
        _pathGeometryCacheDirty ||
        countChanged ||
        generationChanged) {
      edgeSignature = _edgeIdentitySignature(graphEdges);
      signatureChanged = _pathGeometryCacheSignature != edgeSignature;
    }

    if (_pathGeometryCacheDirty ||
        countChanged ||
        generationChanged ||
        signatureChanged) {
      _clearPathGeometryCache();
      _pathGeometryCacheCount = graphEdges.length;
      _pathGeometryCacheSignature =
          edgeSignature ?? _edgeIdentitySignature(graphEdges);
      _pathGeometryCacheGeneration = currentGraph.generation;
      _pathGeometryCacheDirty = false;
    }
  }

  void _invalidatePathGeometryCache() {
    _pathGeometryCacheDirty = true;
  }

  void _clearPathGeometryCache() {
    _pathGeometryCache.clear();
    _pathGeometryCacheCount = -1;
    _pathGeometryCacheSignature = 0;
    _pathGeometryCacheGeneration = -1;
  }

  int _edgeIdentitySignature(List<Edge> edges) {
    return Object.hashAll(edges.map(identityHashCode));
  }

  String _parallelEdgeKey(Edge edge) {
    return '${_nodeKey(edge.source)}->${_nodeKey(edge.destination)}';
  }

  String _nodeKey(Node node) {
    return node.key?.value.toString() ?? node.hashCode.toString();
  }

  String _edgeSortKey(Edge edge, List<Edge> graphEdges) {
    final key = edge.key;
    if (key is ValueKey) {
      return key.value.toString();
    }
    final graphIndex = graphEdges.indexOf(edge);
    final stableIndex = graphIndex < 0 ? graphEdges.length : graphIndex;
    final padWidth = math.max(8, graphEdges.length.toString().length);
    return stableIndex.toString().padLeft(padWidth, '0');
  }
}
