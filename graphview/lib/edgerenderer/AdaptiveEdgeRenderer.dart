part of graphview;

/// An edge renderer that implements adaptive connection points and intelligent routing.
///
/// This renderer calculates optimal connection points on node boundaries based on
/// edge direction and the configured [AnchorMode]. It supports cardinal, octagonal,
/// and dynamic anchor modes for precise edge positioning.
///
/// Example usage:
/// ```dart
/// final config = EdgeRoutingConfig(
///   anchorMode: AnchorMode.cardinal,
///   routingMode: RoutingMode.direct,
/// );
/// final renderer = AdaptiveEdgeRenderer(config: config);
/// final algorithm = SugiyamaAlgorithm(SugiyamaConfiguration())
///   ..renderer = renderer;
/// final view = GraphView(
///   graph: graph,
///   algorithm: algorithm,
///   builder: (node) => Text('${node.key?.value}'),
/// );
/// ```
class AdaptiveEdgeRenderer extends EdgeRenderer implements RenderCycleAware {
  final EdgeRoutingConfig config;
  final bool noArrow;

  /// Solver for calculating edge-to-edge repulsion forces.
  final EdgeRepulsionSolver _repulsionSolver = EdgeRepulsionSolver();

  /// Cache for repulsion offsets calculated for each edge.
  /// Geometry stamps invalidate it when edges, nodes, or solver settings change.
  Map<Edge, Offset> _repulsionOffsets = {};

  /// Flag to track if repulsion has been calculated for the current render cycle.
  bool _repulsionCalculated = false;
  Graph? _repulsionCacheGraph;
  int _repulsionCacheEdgeSignature = 0;
  int _repulsionCacheConfigSignature = 0;
  Map<Node, Offset> _repulsionCacheNodeCenters = <Node, Offset>{};
  bool _warnedBundlingFallback = false;

  AdaptiveEdgeRenderer({
    required this.config,
    this.noArrow = false,
  });

  @override
  void setGraph(Graph graph) {
    super.setGraph(graph);
    _repulsionCalculated = false;
  }

  @override
  void prepareForRenderCycle() {
    _repulsionCalculated = false;
    _ensureRepulsionPrepared();
  }

  void _ensureRepulsionPrepared() {
    if (_repulsionCalculated) {
      return;
    }
    if (!config.enableRepulsion || _graph == null) {
      _repulsionOffsets = <Edge, Offset>{};
      _repulsionCalculated = true;
      return;
    }

    final edgeSignature = Object.hashAll(
      _graph!.edges.map(identityHashCode),
    );
    final nodeCenters = <Node, Offset>{
      for (final node in _graph!.nodes) node: getNodeCenter(node),
    };
    final configSignature = Object.hash(
      config.enableRepulsion,
      config.repulsionStrength,
      config.minEdgeDistance,
      config.maxRepulsionIterations,
    );
    if (identical(_repulsionCacheGraph, _graph) &&
        _repulsionCacheEdgeSignature == edgeSignature &&
        _repulsionCacheConfigSignature == configSignature &&
        mapEquals(_repulsionCacheNodeCenters, nodeCenters)) {
      _repulsionCalculated = true;
      return;
    }

    _calculateRepulsionForAllEdges();
    _repulsionCacheGraph = _graph;
    _repulsionCacheEdgeSignature = edgeSignature;
    _repulsionCacheConfigSignature = configSignature;
    _repulsionCacheNodeCenters = nodeCenters;
    _repulsionCalculated = true;
  }

  @visibleForTesting
  int get debugRepulsionGeneration =>
      _repulsionSolver.getStatistics()['generation'] as int;

  @protected
  Offset preparedRepulsionOffsetFor(Edge edge) {
    _ensureRepulsionPrepared();
    return _repulsionOffsets[edge] ?? Offset.zero;
  }

  @override
  void renderEdge(Canvas canvas, Edge edge, Paint paint) {
    // Check if edge has a custom renderer - if so, delegate to it
    if (edge.renderer != null) {
      edge.renderer!.renderEdge(canvas, edge, paint);
      return;
    }

    _ensureRepulsionPrepared();

    var source = edge.source;
    var destination = edge.destination;

    final currentPaint = (edge.paint ?? paint)..style = PaintingStyle.stroke;

    // Handle self-loops
    if (source == destination) {
      final loopResult = buildSelfLoopPath(
        edge,
        arrowLength: noArrow ? 0.0 : 10.0,
      );

      if (loopResult != null) {
        canvas.drawPath(loopResult.path, currentPaint);

        if (!noArrow) {
          final trianglePaint = Paint()
            ..color = edge.paint?.color ?? paint.color
            ..style = PaintingStyle.fill;
          drawTriangle(
            canvas,
            trianglePaint,
            loopResult.arrowBase.dx,
            loopResult.arrowBase.dy,
            loopResult.arrowTip.dx,
            loopResult.arrowTip.dy,
          );
        }

        return;
      }
    }

    // Calculate connection points based on anchor mode
    final destCenter = getNodeCenter(destination);
    final sourceCenter = getNodeCenter(source);

    // Calculate edge index for parallel edge distribution
    final edgeIndex = _calculateEdgeIndex(edge);

    final sourcePoint =
        calculateSourceConnectionPoint(edge, destCenter, edgeIndex);
    final destPoint =
        calculateDestinationConnectionPoint(edge, sourceCenter, edgeIndex);

    // Route the edge path based on routing mode
    var path = routeEdgePath(sourcePoint, destPoint, edge);

    // Apply edge repulsion if enabled
    if (config.enableRepulsion && _graph != null) {
      path = _applyRepulsionToPath(edge, path, sourcePoint, destPoint);
    }

    // Draw the path
    canvas.drawPath(path, currentPaint);

    // Draw arrow if not disabled
    if (!noArrow) {
      final trianglePaint = Paint()
        ..color = edge.paint?.color ?? paint.color
        ..style = PaintingStyle.fill;
      final arrowSegment =
          _finalPathSegment(path) ?? _PathSegment(sourcePoint, destPoint);

      drawTriangle(
        canvas,
        trianglePaint,
        arrowSegment.start.dx,
        arrowSegment.start.dy,
        arrowSegment.end.dx,
        arrowSegment.end.dy,
      );
    }
  }

  @override
  Offset calculateSourceConnectionPoint(
      Edge edge, Offset destinationCenter, int edgeIndex) {
    final sourceCenter = getNodeCenter(edge.source);

    Offset baseAnchor;
    switch (config.anchorMode) {
      case AnchorMode.center:
        baseAnchor = sourceCenter;
        break;

      case AnchorMode.cardinal:
        baseAnchor = _calculateCardinalAnchor(
          edge.source,
          sourceCenter,
          destinationCenter,
        );
        break;

      case AnchorMode.octagonal:
        baseAnchor = _calculateOctagonalAnchor(
          edge.source,
          sourceCenter,
          destinationCenter,
        );
        break;

      case AnchorMode.dynamic:
        baseAnchor = _calculateDynamicAnchor(
          edge.source,
          sourceCenter,
          destinationCenter,
        );
        break;
    }

    // Apply perpendicular offset for parallel edges
    return _applyParallelEdgeOffset(
        edge, baseAnchor, sourceCenter, destinationCenter);
  }

  @override
  Offset calculateDestinationConnectionPoint(
      Edge edge, Offset sourceCenter, int edgeIndex) {
    final destCenter = getNodeCenter(edge.destination);

    Offset baseAnchor;
    switch (config.anchorMode) {
      case AnchorMode.center:
        baseAnchor = destCenter;
        break;

      case AnchorMode.cardinal:
        baseAnchor = _calculateCardinalAnchor(
          edge.destination,
          destCenter,
          sourceCenter,
        );
        break;

      case AnchorMode.octagonal:
        baseAnchor = _calculateOctagonalAnchor(
          edge.destination,
          destCenter,
          sourceCenter,
        );
        break;

      case AnchorMode.dynamic:
        baseAnchor = _calculateDynamicAnchor(
          edge.destination,
          destCenter,
          sourceCenter,
        );
        break;
    }

    // Apply perpendicular offset for parallel edges
    return _applyParallelEdgeOffset(edge, baseAnchor, destCenter, sourceCenter);
  }

  @override
  Path routeEdgePath(Offset sourcePoint, Offset destinationPoint, Edge edge) {
    // Routing must never crash paint. If a routing implementation throws for a
    // particular edge geometry, degrade gracefully to a direct line.
    try {
      switch (config.routingMode) {
        case RoutingMode.direct:
          return _buildDirectPath(sourcePoint, destinationPoint);

        case RoutingMode.orthogonal:
          return _buildOrthogonalPath(sourcePoint, destinationPoint);

        case RoutingMode.bezier:
          return _buildBezierPath(sourcePoint, destinationPoint, edge);

        case RoutingMode.bundling:
          // Bundling can be expensive and is not currently implemented in this fork.
          // It previously fell back to bezier which can be visually misleading (it
          // suggests an intentional curved route). For correctness and predictable
          // behavior, we degrade to a direct line.
          if (!_warnedBundlingFallback) {
            assert(() {
              debugPrint(
                'RoutingMode.bundling is not implemented; falling back to RoutingMode.direct.',
              );
              return true;
            }());
            _warnedBundlingFallback = true;
          }
          return _buildDirectPath(sourcePoint, destinationPoint);
      }
    } catch (e, st) {
      assert(() {
        debugPrint(
          'AdaptiveEdgeRenderer: routing failed for ${config.routingMode} (falling back to direct). Error: $e\n$st',
        );
        return true;
      }());
      return _buildDirectPath(sourcePoint, destinationPoint);
    }
  }

  @override
  Path applyEdgeRepulsion(List<Edge> edges, Edge currentEdge, Path path) {
    // If repulsion is disabled, return the original path
    if (!config.enableRepulsion) {
      return path;
    }

    _ensureRepulsionPrepared();

    // Get the repulsion offset for the current edge
    final repulsionOffset = _repulsionOffsets[currentEdge] ?? Offset.zero;

    // If no repulsion offset, return original path
    if (repulsionOffset.distance < VectorUtils.epsilon) {
      return path;
    }

    // Get connection points for the edge
    final sourceCenter = getNodeCenter(currentEdge.source);
    final destCenter = getNodeCenter(currentEdge.destination);
    final edgeIndex = _calculateEdgeIndex(currentEdge);
    final sourcePoint =
        calculateSourceConnectionPoint(currentEdge, destCenter, edgeIndex);
    final destPoint = calculateDestinationConnectionPoint(
        currentEdge, sourceCenter, edgeIndex);

    // Apply repulsion to the path
    return _applyRepulsionToPath(currentEdge, path, sourcePoint, destPoint);
  }

  /// Builds a direct straight-line path between source and destination.
  Path _buildDirectPath(Offset sourcePoint, Offset destinationPoint) {
    return Path()
      ..moveTo(sourcePoint.dx, sourcePoint.dy)
      ..lineTo(destinationPoint.dx, destinationPoint.dy);
  }

  /// Builds an orthogonal L-shaped path between source and destination.
  ///
  /// Creates Manhattan-style paths with right angles, choosing between
  /// horizontal-first or vertical-first routing based on the distance ratio.
  Path _buildOrthogonalPath(Offset sourcePoint, Offset destinationPoint) {
    final path = Path();
    path.moveTo(sourcePoint.dx, sourcePoint.dy);

    final dx = destinationPoint.dx - sourcePoint.dx;
    final dy = destinationPoint.dy - sourcePoint.dy;

    // Handle collinear nodes by adding a small offset for visibility
    if (dx.abs() < VectorUtils.epsilon) {
      // Vertical line - add horizontal offset
      final offset = 10.0;
      path.lineTo(sourcePoint.dx + offset, sourcePoint.dy);
      path.lineTo(sourcePoint.dx + offset, destinationPoint.dy);
      path.lineTo(destinationPoint.dx, destinationPoint.dy);
      return path;
    }

    if (dy.abs() < VectorUtils.epsilon) {
      // Horizontal line - add vertical offset
      final offset = 10.0;
      path.lineTo(sourcePoint.dx, sourcePoint.dy + offset);
      path.lineTo(destinationPoint.dx, sourcePoint.dy + offset);
      path.lineTo(destinationPoint.dx, destinationPoint.dy);
      return path;
    }

    // Choose routing direction based on distance ratio
    // Horizontal-first if horizontal distance >= vertical distance
    if (dx.abs() >= dy.abs()) {
      final midX = sourcePoint.dx + dx * 0.5;
      path.lineTo(midX, sourcePoint.dy);
      path.lineTo(midX, destinationPoint.dy);
    } else {
      // Vertical-first if vertical distance > horizontal distance
      final midY = sourcePoint.dy + dy * 0.5;
      path.lineTo(sourcePoint.dx, midY);
      path.lineTo(destinationPoint.dx, midY);
    }

    path.lineTo(destinationPoint.dx, destinationPoint.dy);
    return path;
  }

  /// Builds a bezier path with control points for smooth curves.
  ///
  /// Creates cubic bezier curves with control points offset from the
  /// source-destination axis so bezier routing produces a visible curve.
  Path _buildBezierPath(
      Offset sourcePoint, Offset destinationPoint, Edge edge) {
    final path = Path();
    path.moveTo(sourcePoint.dx, sourcePoint.dy);

    // Calculate direction vector from source to destination
    final direction = destinationPoint - sourcePoint;
    final distance = direction.distance;

    // Handle zero-distance edges (nodes at same position)
    if (distance < VectorUtils.epsilon) {
      path.lineTo(destinationPoint.dx, destinationPoint.dy);
      return path;
    }

    final controlPoints = _calculateBezierControlPoints(
      sourcePoint,
      destinationPoint,
      edge,
    );
    if (controlPoints == null) {
      path.lineTo(destinationPoint.dx, destinationPoint.dy);
      return path;
    }

    // Create cubic bezier curve
    path.cubicTo(
      controlPoints.first.dx,
      controlPoints.first.dy,
      controlPoints.second.dx,
      controlPoints.second.dy,
      destinationPoint.dx,
      destinationPoint.dy,
    );

    return path;
  }

  _BezierControlPoints? _calculateBezierControlPoints(
    Offset sourcePoint,
    Offset destinationPoint,
    Edge edge,
  ) {
    final direction = destinationPoint - sourcePoint;
    final distance = direction.distance;
    if (distance < VectorUtils.epsilon) {
      return null;
    }

    final normalized = VectorUtils.normalize(direction);
    final controlPointDistance = distance / 3.0;
    final perpendicular = Offset(-normalized.dy, normalized.dx);
    final parallelCount = _parallelEdgesFor(edge).length;
    final edgeIndex = _calculateEdgeIndex(edge);
    final centeredIndex = edgeIndex - (parallelCount - 1) / 2.0;
    final bendIndex = parallelCount <= 1 ? 1.0 : centeredIndex;
    final bendDirection = bendIndex.sign;
    final bendMagnitude = controlPointDistance * bendIndex.abs() * 0.5;
    final bendOffset = perpendicular * (bendMagnitude * bendDirection);

    final controlPoint1 = Offset(
          sourcePoint.dx + normalized.dx * controlPointDistance,
          sourcePoint.dy + normalized.dy * controlPointDistance,
        ) +
        bendOffset;
    final controlPoint2 = Offset(
          destinationPoint.dx - normalized.dx * controlPointDistance,
          destinationPoint.dy - normalized.dy * controlPointDistance,
        ) -
        bendOffset;

    return _BezierControlPoints(controlPoint1, controlPoint2);
  }

  _PathSegment? _finalPathSegment(Path path) {
    for (final metric in path.computeMetrics().toList().reversed) {
      if (metric.length < VectorUtils.epsilon) continue;

      final tangent = metric.getTangentForOffset(metric.length);
      if (tangent == null || tangent.vector.distance < VectorUtils.epsilon) {
        continue;
      }

      return _PathSegment(tangent.position - tangent.vector, tangent.position);
    }

    return null;
  }

  /// Calculates a cardinal anchor point (N, E, S, W) on the node boundary.
  ///
  /// The direction is determined by the angle from [nodeCenter] to [targetCenter].
  /// The angle is binned into 4 sectors (90 degrees each):
  /// - East: [-45°, 45°)
  /// - South: [45°, 135°)
  /// - West: [135°, 225°) or [-180°, -135°)
  /// - North: [-135°, -45°)
  ///
  /// Note: In Flutter's coordinate system, positive Y is down, so:
  /// - North (up) has angle around -90°
  /// - South (down) has angle around 90°
  Offset _calculateCardinalAnchor(
      Node node, Offset nodeCenter, Offset targetCenter) {
    final nodePosition = getNodePosition(node);

    // Calculate direction vector from node center to target center
    final direction = targetCenter - nodeCenter;

    // Calculate angle in radians (-π to π)
    final angle = VectorUtils.angle(direction);

    // Convert to degrees for easier binning
    final degrees = angle * 180 / pi;

    // Bin into 4 cardinal directions (90-degree sectors)
    // Note: In Flutter, +Y is down, so angle interpretations:
    // East (right): -45 to 45 degrees
    // South (down): 45 to 135 degrees
    // West (left): 135 to 180 or -180 to -135 degrees
    // North (up): -135 to -45 degrees

    if (degrees >= -45 && degrees < 45) {
      // East - right edge
      return Offset(
        nodePosition.dx + node.width,
        nodePosition.dy + node.height * 0.5,
      );
    } else if (degrees >= 45 && degrees < 135) {
      // South - bottom edge (positive Y is down)
      return Offset(
        nodePosition.dx + node.width * 0.5,
        nodePosition.dy + node.height,
      );
    } else if (degrees >= -135 && degrees < -45) {
      // North - top edge (negative Y is up)
      return Offset(
        nodePosition.dx + node.width * 0.5,
        nodePosition.dy,
      );
    } else {
      // West - left edge (135 to 180 or -180 to -135)
      return Offset(
        nodePosition.dx,
        nodePosition.dy + node.height * 0.5,
      );
    }
  }

  /// Calculates an octagonal anchor point (8 compass points) on the node boundary.
  ///
  /// The direction is determined by the angle from [nodeCenter] to [targetCenter].
  /// The angle is binned into 8 sectors (45 degrees each):
  /// - East (E): [-22.5°, 22.5°)
  /// - Southeast (SE): [22.5°, 67.5°)
  /// - South (S): [67.5°, 112.5°)
  /// - Southwest (SW): [112.5°, 157.5°)
  /// - West (W): [157.5°, 180°] or [-180°, -157.5°]
  /// - Northwest (NW): [-157.5°, -112.5°)
  /// - North (N): [-112.5°, -67.5°)
  /// - Northeast (NE): [-67.5°, -22.5°)
  ///
  /// Note: In Flutter's coordinate system, positive Y is down, so:
  /// - North (up) has angle around -90°
  /// - South (down) has angle around 90°
  /// - Diagonal directions use corner points
  Offset _calculateOctagonalAnchor(
      Node node, Offset nodeCenter, Offset targetCenter) {
    final nodePosition = getNodePosition(node);

    // Calculate direction vector from node center to target center
    final direction = targetCenter - nodeCenter;

    // Calculate angle in radians (-π to π)
    final angle = VectorUtils.angle(direction);

    // Convert to degrees for easier binning
    final degrees = angle * 180 / pi;

    // Bin into 8 octagonal directions (45-degree sectors)
    // Note: In Flutter, +Y is down, so angle interpretations:
    // East (right): -22.5 to 22.5 degrees
    // Southeast (bottom-right): 22.5 to 67.5 degrees
    // South (down): 67.5 to 112.5 degrees
    // Southwest (bottom-left): 112.5 to 157.5 degrees
    // West (left): 157.5 to 180 or -180 to -157.5 degrees
    // Northwest (top-left): -157.5 to -112.5 degrees
    // North (up): -112.5 to -67.5 degrees
    // Northeast (top-right): -67.5 to -22.5 degrees

    if (degrees >= -22.5 && degrees < 22.5) {
      // East - right edge, center height
      return Offset(
        nodePosition.dx + node.width,
        nodePosition.dy + node.height * 0.5,
      );
    } else if (degrees >= 22.5 && degrees < 67.5) {
      // Southeast - bottom-right corner
      return Offset(
        nodePosition.dx + node.width,
        nodePosition.dy + node.height,
      );
    } else if (degrees >= 67.5 && degrees < 112.5) {
      // South - bottom edge, center width
      return Offset(
        nodePosition.dx + node.width * 0.5,
        nodePosition.dy + node.height,
      );
    } else if (degrees >= 112.5 && degrees < 157.5) {
      // Southwest - bottom-left corner
      return Offset(
        nodePosition.dx,
        nodePosition.dy + node.height,
      );
    } else if (degrees >= -157.5 && degrees < -112.5) {
      // Northwest - top-left corner
      return Offset(
        nodePosition.dx,
        nodePosition.dy,
      );
    } else if (degrees >= -112.5 && degrees < -67.5) {
      // North - top edge, center width
      return Offset(
        nodePosition.dx + node.width * 0.5,
        nodePosition.dy,
      );
    } else if (degrees >= -67.5 && degrees < -22.5) {
      // Northeast - top-right corner
      return Offset(
        nodePosition.dx + node.width,
        nodePosition.dy,
      );
    } else {
      // West - left edge, center height (157.5 to 180 or -180 to -157.5)
      return Offset(
        nodePosition.dx,
        nodePosition.dy + node.height * 0.5,
      );
    }
  }

  /// Calculates a dynamic anchor point using exact ray-rectangle intersection.
  ///
  /// This method calculates the precise point where the ray from [nodeCenter]
  /// to [targetCenter] intersects the rectangular boundary of the node.
  /// Unlike cardinal and octagonal modes which snap to fixed directions,
  /// dynamic mode provides pixel-perfect intersection calculation.
  ///
  /// The algorithm:
  /// 1. Calculate the direction ray from node center to target center
  /// 2. Compute slope of the ray
  /// 3. Test intersection with vertical edges (left/right)
  /// 4. Test intersection with horizontal edges (top/bottom)
  /// 5. Return the intersection point on the node's perimeter
  ///
  /// This is based on the `clipLineEnd` algorithm from ArrowEdgeRenderer,
  /// but adapted to work with node boundaries in the adaptive rendering context.
  Offset _calculateDynamicAnchor(
      Node node, Offset nodeCenter, Offset targetCenter) {
    final nodePosition = getNodePosition(node);

    // If source and target are at the same position, return the center
    if ((nodeCenter - targetCenter).distance < VectorUtils.epsilon) {
      return nodeCenter;
    }

    final halfWidth = node.width * 0.5;
    final halfHeight = node.height * 0.5;

    // Calculate the slope of the ray from node center to target center
    final dx = targetCenter.dx - nodeCenter.dx;
    final dy = targetCenter.dy - nodeCenter.dy;

    // Handle vertical line (infinite slope)
    if (dx.abs() < VectorUtils.epsilon) {
      if (dy > 0) {
        // Ray points downward - intersect bottom edge
        return Offset(
          nodeCenter.dx,
          nodePosition.dy + node.height,
        );
      } else {
        // Ray points upward - intersect top edge
        return Offset(
          nodeCenter.dx,
          nodePosition.dy,
        );
      }
    }

    final slope = dy / dx;

    // Check vertical edge intersections (left/right edges)
    final halfSlopeWidth = slope * halfWidth;
    if (halfSlopeWidth.abs() <= halfHeight) {
      if (dx > 0) {
        // Ray points right - intersect right edge
        return Offset(
          nodePosition.dx + node.width,
          nodeCenter.dy + halfSlopeWidth,
        );
      } else {
        // Ray points left - intersect left edge
        return Offset(
          nodePosition.dx,
          nodeCenter.dy - halfSlopeWidth,
        );
      }
    }

    // Check horizontal edge intersections (top/bottom edges)
    if (slope != 0) {
      final halfSlopeHeight = halfHeight / slope;
      if (halfSlopeHeight.abs() <= halfWidth) {
        if (dy > 0) {
          // Ray points downward - intersect bottom edge
          return Offset(
            nodeCenter.dx + halfSlopeHeight,
            nodePosition.dy + node.height,
          );
        } else {
          // Ray points upward - intersect top edge
          return Offset(
            nodeCenter.dx - halfSlopeHeight,
            nodePosition.dy,
          );
        }
      }
    }

    // Fallback to center if no intersection found (should not happen in practice)
    return nodeCenter;
  }

  /// Calculates the index of this edge among parallel edges between the same nodes.
  /// Returns 0 if there are no parallel edges, or the index (0, 1, 2, ...) for distribution.
  int _calculateEdgeIndex(Edge edge) {
    final parallelEdges = _parallelEdgesFor(edge);
    if (parallelEdges.length <= 1) return 0;

    final index = parallelEdges
        .indexWhere((parallelEdge) => identical(parallelEdge, edge));
    return index < 0 ? 0 : index;
  }

  double _calculateCenteredEdgeIndex(Edge edge) {
    final parallelEdges = _parallelEdgesFor(edge);
    if (parallelEdges.length <= 1) return 0;

    final index = parallelEdges
        .indexWhere((parallelEdge) => identical(parallelEdge, edge));
    if (index < 0) return 0;

    return index - (parallelEdges.length - 1) / 2.0;
  }

  List<Edge> _parallelEdgesFor(Edge edge) {
    if (_graph == null) return [edge];

    final parallelEdges = _graph!
        .getOutEdges(edge.source)
        .where((e) => e.destination == edge.destination)
        .toList();
    parallelEdges
        .sort((a, b) => _stableEdgeSortKey(a).compareTo(_stableEdgeSortKey(b)));
    return parallelEdges;
  }

  String _stableEdgeSortKey(Edge edge) {
    final graphIndex =
        _graph?.edges.indexWhere((candidate) => identical(candidate, edge)) ??
            -1;
    return [
      edge.key?.toString() ?? '',
      edge.source.key?.value?.toString() ?? '',
      edge.destination.key?.value?.toString() ?? '',
      edge.label ?? '',
      graphIndex.toString().padLeft(8, '0'),
    ].join('|');
  }

  /// Applies a perpendicular offset to the anchor point for parallel edge distribution.
  /// The offset is perpendicular to the edge direction, scaled by edgeIndex * minEdgeDistance.
  Offset _applyParallelEdgeOffset(
    Edge edge,
    Offset anchor,
    Offset nodeCenter,
    Offset targetCenter,
  ) {
    final centeredIndex = _calculateCenteredEdgeIndex(edge);

    // If centeredIndex is 0, no offset needed
    if (centeredIndex == 0) {
      return anchor;
    }

    // Calculate direction vector from node to target
    final direction = targetCenter - nodeCenter;

    // If nodes are at same position, no offset possible
    if (direction.distance < VectorUtils.epsilon) {
      return anchor;
    }

    // Calculate perpendicular vector (rotated 90 degrees)
    final perpendicular = VectorUtils.perpendicular(direction);

    // Normalize and scale by the centered index * minEdgeDistance
    final normalized = VectorUtils.normalize(perpendicular);
    final offset = normalized * (centeredIndex * config.minEdgeDistance);

    // Apply offset to anchor point
    return anchor + offset;
  }

  /// Calculates repulsion forces for all edges in the graph.
  ///
  /// This method is called once per render cycle before rendering individual edges.
  /// It uses the EdgeRepulsionSolver to calculate repulsion offsets for all edges
  /// and caches the results for use during rendering.
  void _calculateRepulsionForAllEdges() {
    if (_graph == null) {
      _repulsionOffsets = {};
      return;
    }

    // Calculate repulsion offsets for all edges using the solver
    _repulsionOffsets = _repulsionSolver.applyRepulsionForces(
      _graph!.edges.toList(),
      this,
      config,
    );
  }

  /// Applies repulsion offset to an edge path by modifying its control points.
  ///
  /// For bezier paths, the offset is applied to the control points.
  /// For orthogonal paths, the offset is applied to the midpoint.
  /// For direct paths, the offset creates a slight curve.
  Path _applyRepulsionToPath(
    Edge edge,
    Path originalPath,
    Offset sourcePoint,
    Offset destPoint,
  ) {
    // Get the repulsion offset for this edge
    final repulsionOffset = _repulsionOffsets[edge] ?? Offset.zero;

    // If no repulsion offset, return original path
    if (repulsionOffset.distance < VectorUtils.epsilon) {
      return originalPath;
    }

    // Apply repulsion based on routing mode
    switch (config.routingMode) {
      case RoutingMode.bezier:
      case RoutingMode.bundling:
        return _applyRepulsionToBezierPath(
            edge, sourcePoint, destPoint, repulsionOffset);

      case RoutingMode.orthogonal:
        return _applyRepulsionToOrthogonalPath(
            sourcePoint, destPoint, repulsionOffset);

      case RoutingMode.direct:
        // Convert direct path to bezier with repulsion offset
        return _applyRepulsionToDirectPath(
            sourcePoint, destPoint, repulsionOffset);
    }
  }

  /// Applies repulsion to a bezier path by offsetting the control points.
  Path _applyRepulsionToBezierPath(
      Edge edge, Offset sourcePoint, Offset destPoint, Offset repulsionOffset) {
    final path = Path();
    path.moveTo(sourcePoint.dx, sourcePoint.dy);

    final controlPoints = _calculateBezierControlPoints(
      sourcePoint,
      destPoint,
      edge,
    );
    if (controlPoints == null) {
      path.lineTo(destPoint.dx, destPoint.dy);
      return path;
    }

    final controlPoint1 = controlPoints.first + repulsionOffset;
    final controlPoint2 = controlPoints.second + repulsionOffset;

    path.cubicTo(
      controlPoint1.dx,
      controlPoint1.dy,
      controlPoint2.dx,
      controlPoint2.dy,
      destPoint.dx,
      destPoint.dy,
    );

    return path;
  }

  /// Applies repulsion to an orthogonal path by offsetting the midpoint.
  Path _applyRepulsionToOrthogonalPath(
      Offset sourcePoint, Offset destPoint, Offset repulsionOffset) {
    final path = Path();
    path.moveTo(sourcePoint.dx, sourcePoint.dy);

    final dx = destPoint.dx - sourcePoint.dx;
    final dy = destPoint.dy - sourcePoint.dy;

    // Apply repulsion offset to midpoint
    if (dx.abs() >= dy.abs()) {
      // Horizontal-first routing
      final midX = sourcePoint.dx + dx * 0.5 + repulsionOffset.dx;
      final midY = sourcePoint.dy + repulsionOffset.dy;
      path.lineTo(midX, midY);
      path.lineTo(midX, destPoint.dy);
    } else {
      // Vertical-first routing
      final midX = sourcePoint.dx + repulsionOffset.dx;
      final midY = sourcePoint.dy + dy * 0.5 + repulsionOffset.dy;
      path.lineTo(midX, midY);
      path.lineTo(destPoint.dx, midY);
    }

    path.lineTo(destPoint.dx, destPoint.dy);
    return path;
  }

  /// Applies repulsion to a direct path by converting it to a bezier with offset.
  Path _applyRepulsionToDirectPath(
      Offset sourcePoint, Offset destPoint, Offset repulsionOffset) {
    final path = Path();
    path.moveTo(sourcePoint.dx, sourcePoint.dy);

    // Calculate midpoint with repulsion offset
    final midpoint = Offset(
      (sourcePoint.dx + destPoint.dx) / 2 + repulsionOffset.dx,
      (sourcePoint.dy + destPoint.dy) / 2 + repulsionOffset.dy,
    );

    // Use quadratic bezier for simpler curved path
    path.quadraticBezierTo(
      midpoint.dx,
      midpoint.dy,
      destPoint.dx,
      destPoint.dy,
    );

    return path;
  }

  /// Resets the repulsion calculation flag to allow recalculation in the next render cycle.
  ///
  /// This should be called by the render system when starting a new frame.
  void resetRepulsionCalculation() {
    _repulsionCalculated = false;
  }

  /// Draws a triangle (arrow head) at the end of an edge.
  ///
  /// Returns the centroid of the triangle for connecting the edge line.
  Offset drawTriangle(Canvas canvas, Paint paint, double startX, double startY,
      double stopX, double stopY) {
    const arrowDegrees = 0.5;
    const arrowLength = 10.0;

    var angle = atan2(stopY - startY, stopX - startX);

    var path = Path();
    path.moveTo(stopX, stopY);
    path.lineTo(
      stopX - arrowLength * cos(angle - arrowDegrees),
      stopY - arrowLength * sin(angle - arrowDegrees),
    );
    path.lineTo(
      stopX - arrowLength * cos(angle + arrowDegrees),
      stopY - arrowLength * sin(angle + arrowDegrees),
    );
    path.close();

    canvas.drawPath(path, paint);

    // Calculate centroid of the triangle
    var x1 = stopX;
    var y1 = stopY;
    var x2 = stopX - arrowLength * cos(angle - arrowDegrees);
    var y2 = stopY - arrowLength * sin(angle - arrowDegrees);
    var x3 = stopX - arrowLength * cos(angle + arrowDegrees);
    var y3 = stopY - arrowLength * sin(angle + arrowDegrees);

    var centroidX = (x1 + x2 + x3) / 3;
    var centroidY = (y1 + y2 + y3) / 3;

    return Offset(centroidX, centroidY);
  }
}

class _BezierControlPoints {
  final Offset first;
  final Offset second;

  const _BezierControlPoints(this.first, this.second);
}

class _PathSegment {
  final Offset start;
  final Offset end;

  const _PathSegment(this.start, this.end);
}
