part of graphview;

/// Data structure representing an edge segment for spatial partitioning.
///
/// An edge segment is defined by two endpoints and includes a reference to
/// the original edge for applying repulsion forces.
class EdgeSegment {
  /// Start point of the segment.
  final Offset start;

  /// End point of the segment.
  final Offset end;

  /// The edge this segment belongs to.
  final Edge edge;

  /// Index of this segment within the edge path (for multi-segment edges).
  final int segmentIndex;

  EdgeSegment(this.start, this.end, this.edge, this.segmentIndex);

  /// Returns the bounding box of this segment.
  Rect getBounds() {
    final minX = min(start.dx, end.dx);
    final maxX = max(start.dx, end.dx);
    final minY = min(start.dy, end.dy);
    final maxY = max(start.dy, end.dy);
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  /// Returns the midpoint of this segment.
  Offset get midpoint => Offset(
        (start.dx + end.dx) / 2,
        (start.dy + end.dy) / 2,
      );

  /// Returns the direction vector of this segment.
  Offset get direction => end - start;

  /// Returns the length of this segment.
  double get length => (end - start).distance;
}

/// Spatial grid for efficient O(n log n) edge intersection detection.
///
/// This class implements a uniform spatial grid that partitions the 2D space
/// into cells. Edge segments are bucketed into cells based on their position,
/// allowing for efficient intersection detection by only checking segments
/// in nearby cells rather than checking all pairs of segments.
class EdgeRepulsionSolver {
  /// Default cell size for the spatial grid (in pixels).
  static const double DEFAULT_CELL_SIZE = 50.0;

  /// The cell size for the spatial grid.
  final double cellSize;

  /// The spatial grid storing edge segments.
  /// Key: cell coordinate (row, col), Value: list of edge segments in that cell.
  final Map<String, List<EdgeSegment>> _grid = {};

  /// Cache of edge segments for reuse.
  final List<EdgeSegment> _segments = [];

  /// Generation counter to track when grid needs rebuilding.
  int _generation = 0;

  /// Creates a new EdgeRepulsionSolver with the specified cell size.
  ///
  /// [cellSize] determines the granularity of the spatial grid. Smaller values
  /// provide more precise bucketing but increase memory usage. Default is 50px.
  EdgeRepulsionSolver({this.cellSize = DEFAULT_CELL_SIZE});

  /// Clears the spatial grid and segment cache.
  void clear() {
    _grid.clear();
    _segments.clear();
    _generation++;
  }

  /// Adds an edge segment to the spatial grid.
  ///
  /// The segment is added to all cells that its bounding box overlaps.
  void addSegment(EdgeSegment segment) {
    _segments.add(segment);

    final bounds = segment.getBounds();

    // Calculate cell range for this segment's bounding box
    final minRow = _getCellRow(bounds.top);
    final maxRow = _getCellRow(bounds.bottom);
    final minCol = _getCellCol(bounds.left);
    final maxCol = _getCellCol(bounds.right);

    // Add segment to all cells it overlaps
    for (var row = minRow; row <= maxRow; row++) {
      for (var col = minCol; col <= maxCol; col++) {
        final cellKey = _getCellKey(row, col);
        _grid.putIfAbsent(cellKey, () => []).add(segment);
      }
    }
  }

  /// Builds the spatial grid from a list of edges.
  ///
  /// Each edge is broken down into one or more segments based on its path.
  /// For simple edges, this creates a single segment from source to destination.
  /// For complex paths (orthogonal, bezier), multiple segments may be created.
  void buildGrid(List<Edge> edges, EdgeRenderer renderer) {
    clear();

    final sortedEdges = [...edges]..sort(
        (left, right) => _stableEdgeKey(left).compareTo(_stableEdgeKey(right)),
      );

    for (final edge in sortedEdges) {
      final sourcePos = renderer.getNodeCenter(edge.source);
      final destPos = renderer.getNodeCenter(edge.destination);

      // For now, create a single segment from source to destination.
      // This can be extended to handle multi-segment paths in the future.
      final segment = EdgeSegment(
        sourcePos,
        destPos,
        edge,
        0,
      );

      addSegment(segment);
    }
  }

  /// Finds all edge segments that potentially intersect with the given segment.
  ///
  /// Returns a list of segments from neighboring cells that might intersect.
  /// The caller should perform actual intersection tests using VectorUtils.
  List<EdgeSegment> findCandidateIntersections(EdgeSegment segment) {
    final candidates = <EdgeSegment>{};

    final bounds = segment.getBounds();

    // Calculate cell range for this segment's bounding box
    final minRow = _getCellRow(bounds.top);
    final maxRow = _getCellRow(bounds.bottom);
    final minCol = _getCellCol(bounds.left);
    final maxCol = _getCellCol(bounds.right);

    // Query all cells that this segment overlaps, plus neighboring cells
    // to account for segments that span multiple cells
    for (var row = minRow - 1; row <= maxRow + 1; row++) {
      for (var col = minCol - 1; col <= maxCol + 1; col++) {
        final cellKey = _getCellKey(row, col);
        final cellSegments = _grid[cellKey];

        if (cellSegments != null) {
          candidates.addAll(cellSegments);
        }
      }
    }

    // Remove the segment itself from candidates
    candidates.remove(segment);

    return candidates.toList();
  }

  /// Detects all intersecting edge segment pairs in the grid.
  ///
  /// Returns a list of pairs of segments that intersect. Each pair is
  /// represented as a list of two EdgeSegment objects.
  ///
  /// This method uses the spatial grid to achieve O(n log n) performance
  /// by only checking segments in nearby cells rather than all pairs.
  List<List<EdgeSegment>> detectIntersections() {
    final intersections = <List<EdgeSegment>>[];
    final checkedPairs = <String>{};

    for (final segment in _segments) {
      final candidates = findCandidateIntersections(segment);

      for (final candidate in candidates) {
        // Create a unique pair key to avoid checking the same pair twice
        final pairKey = _getPairKey(segment, candidate);

        if (checkedPairs.contains(pairKey)) {
          continue;
        }

        checkedPairs.add(pairKey);

        // Skip segments from the same edge
        if (segment.edge == candidate.edge) {
          continue;
        }

        // Perform actual intersection test using VectorUtils
        final intersection = VectorUtils.lineIntersection(
          segment.start,
          segment.end,
          candidate.start,
          candidate.end,
        );

        if (intersection != null) {
          intersections.add([segment, candidate]);
        }
      }
    }

    return intersections;
  }

  /// Detects all edge pairs that are too close to each other.
  ///
  /// Returns a list of segment pairs where the minimum distance between
  /// the segments is less than [minDistance].
  ///
  /// This is useful for applying repulsion forces to edges that don't
  /// necessarily intersect but are visually too close together.
  List<List<EdgeSegment>> detectProximity(double minDistance) {
    final proximities = <List<EdgeSegment>>[];
    final checkedPairs = <String>{};

    for (final segment in _segments) {
      final candidates = findCandidateIntersections(segment);

      for (final candidate in candidates) {
        // Create a unique pair key to avoid checking the same pair twice
        final pairKey = _getPairKey(segment, candidate);

        if (checkedPairs.contains(pairKey)) {
          continue;
        }

        checkedPairs.add(pairKey);

        // Skip segments from the same edge
        if (segment.edge == candidate.edge) {
          continue;
        }

        // Calculate minimum distance between segments
        final distance = _segmentDistance(segment, candidate);

        if (distance < minDistance) {
          proximities.add([segment, candidate]);
        }
      }
    }

    return proximities;
  }

  /// Gets the row index for a y-coordinate.
  int _getCellRow(double y) {
    return (y / cellSize).floor();
  }

  /// Gets the column index for an x-coordinate.
  int _getCellCol(double x) {
    return (x / cellSize).floor();
  }

  /// Gets a unique key for a grid cell.
  String _getCellKey(int row, int col) {
    return '$row,$col';
  }

  /// Gets a unique key for a pair of segments.
  ///
  /// The key is order-independent so (A, B) and (B, A) produce the same key.
  String _getPairKey(EdgeSegment a, EdgeSegment b) {
    final hashA = a.hashCode;
    final hashB = b.hashCode;

    // Ensure consistent ordering
    if (hashA < hashB) {
      return '$hashA,$hashB';
    } else {
      return '$hashB,$hashA';
    }
  }

  /// Calculates the minimum distance between two line segments.
  ///
  /// Checks endpoint-to-segment distances and also detects actual
  /// intersections (distance = 0) for crossing segments.
  double _segmentDistance(EdgeSegment a, EdgeSegment b) {
    // Check for actual intersection first - crossing segments have distance 0
    final intersection = VectorUtils.lineIntersection(
      a.start,
      a.end,
      b.start,
      b.end,
    );
    if (intersection != null) {
      return 0.0;
    }

    var minDist = double.infinity;

    // Distance from a's endpoints to segment b
    minDist = min(
        minDist, VectorUtils.distanceToLineSegment(a.start, b.start, b.end));
    minDist =
        min(minDist, VectorUtils.distanceToLineSegment(a.end, b.start, b.end));

    // Distance from b's endpoints to segment a
    minDist = min(
        minDist, VectorUtils.distanceToLineSegment(b.start, a.start, a.end));
    minDist =
        min(minDist, VectorUtils.distanceToLineSegment(b.end, a.start, a.end));

    return minDist;
  }

  /// Gets statistics about the spatial grid for debugging/optimization.
  Map<String, dynamic> getStatistics() {
    final cellCounts = <int>[];

    for (final segments in _grid.values) {
      cellCounts.add(segments.length);
    }

    cellCounts.sort();

    final totalSegments = _segments.length;
    final totalCells = _grid.length;
    final avgSegmentsPerCell =
        totalCells > 0 ? totalSegments / totalCells : 0.0;
    final medianSegmentsPerCell = cellCounts.isNotEmpty
        ? cellCounts[cellCounts.length ~/ 2].toDouble()
        : 0.0;
    final maxSegmentsPerCell = cellCounts.isNotEmpty ? cellCounts.last : 0;

    return {
      'totalSegments': totalSegments,
      'totalCells': totalCells,
      'avgSegmentsPerCell': avgSegmentsPerCell,
      'medianSegmentsPerCell': medianSegmentsPerCell,
      'maxSegmentsPerCell': maxSegmentsPerCell,
      'generation': _generation,
    };
  }

  /// Applies repulsion forces to separate overlapping or nearby edges.
  ///
  /// This method detects edges that are too close together and calculates
  /// perpendicular repulsion forces to push them apart. The forces are applied
  /// iteratively until convergence or max iterations is reached.
  ///
  /// Parameters:
  /// - [edges]: List of edges to process
  /// - [renderer]: EdgeRenderer for getting node positions
  /// - [config]: EdgeRoutingConfig containing repulsion settings
  ///
  /// Returns a Map<Edge, Offset> containing the repulsion offset for each edge.
  /// The offset should be applied perpendicular to the edge direction.
  Map<Edge, Offset> applyRepulsionForces(
    List<Edge> edges,
    EdgeRenderer renderer,
    EdgeRoutingConfig config,
  ) {
    // Return empty map if repulsion is disabled
    if (!config.enableRepulsion) {
      return {};
    }

    // Initialize repulsion offsets for all edges
    final repulsionOffsets = <Edge, Offset>{};
    for (final edge in edges) {
      repulsionOffsets[edge] = Offset.zero;
    }

    buildGrid(edges, renderer);

    // Iterate to apply forces until convergence or max iterations
    for (var iteration = 0;
        iteration < config.maxRepulsionIterations;
        iteration++) {
      // Track total movement in this iteration for convergence check
      var totalMovement = 0.0;

      // Detect edges that are too close together
      final proximities = detectProximity(config.minEdgeDistance);

      // Calculate and accumulate forces for each pair of nearby edges
      final forces = <Edge, Offset>{};

      for (final pair in proximities) {
        final segment1 = pair[0];
        final segment2 = pair[1];

        // Calculate repulsion force between the two segments
        final force = _calculateRepulsionForce(
          segment1,
          segment2,
          config,
        );

        // Accumulate force for each edge (apply half to each edge)
        forces[segment1.edge] = (forces[segment1.edge] ?? Offset.zero) + force;
        forces[segment2.edge] = (forces[segment2.edge] ?? Offset.zero) - force;
      }

      // Apply forces to repulsion offsets
      for (final entry in forces.entries) {
        final edge = entry.key;
        final force = entry.value;

        // Apply force with strength scaling
        final scaledForce = force * config.repulsionStrength;
        final accumulated =
            (repulsionOffsets[edge] ?? Offset.zero) + scaledForce;
        final maximumOffset = config.minEdgeDistance * 2;
        repulsionOffsets[edge] = accumulated.distance > maximumOffset &&
                accumulated.distance > VectorUtils.epsilon
            ? VectorUtils.normalize(accumulated) * maximumOffset
            : accumulated;

        totalMovement += scaledForce.distance;
      }

      // Check for convergence (movements are very small)
      if (totalMovement < VectorUtils.epsilon * edges.length) {
        break;
      }
    }

    return repulsionOffsets;
  }

  /// Calculates the repulsion force between two edge segments.
  ///
  /// The force is applied perpendicular to the first segment's direction,
  /// pushing the segments apart. The magnitude is inversely proportional
  /// to the distance between the segments.
  ///
  /// Parameters:
  /// - [segment1]: The first edge segment
  /// - [segment2]: The second edge segment
  /// - [config]: EdgeRoutingConfig containing repulsion settings
  ///
  /// Returns an Offset representing the force vector to apply to segment1.
  Offset _calculateRepulsionForce(
    EdgeSegment segment1,
    EdgeSegment segment2,
    EdgeRoutingConfig config,
  ) {
    // Calculate the minimum distance between the two segments
    final distance = _segmentDistance(segment1, segment2);

    // If segments are exactly at the target distance, no force needed
    if ((distance - config.minEdgeDistance).abs() < VectorUtils.epsilon) {
      return Offset.zero;
    }

    // Calculate the direction perpendicular to segment1
    final segment1Direction = segment1.direction;
    final segment1Perpendicular = VectorUtils.perpendicular(segment1Direction);

    // Normalize the perpendicular vector
    final normalizedPerpendicular =
        VectorUtils.normalize(segment1Perpendicular);

    // If normalization failed (zero-length segment), return no force
    if (normalizedPerpendicular == Offset.zero) {
      return Offset.zero;
    }

    // Determine the direction of the force by checking which side segment2 is on
    // Use the midpoint of segment2 relative to segment1
    final midpoint1 = segment1.midpoint;
    final midpoint2 = segment2.midpoint;
    final toSegment2 = midpoint2 - midpoint1;

    // Use cross product to determine which side segment2 is on
    // If positive, segment2 is on the left (counter-clockwise)
    // If negative, segment2 is on the right (clockwise)
    final cross = VectorUtils.crossProduct(segment1Direction, toSegment2);

    // Force direction: perpendicular to segment1, pointing away from segment2
    final stableCompare =
        _stableEdgeKey(segment1.edge).compareTo(_stableEdgeKey(segment2.edge));
    final forceDirection = cross.abs() < VectorUtils.epsilon
        ? (stableCompare <= 0
            ? -normalizedPerpendicular
            : normalizedPerpendicular)
        : (cross > 0 ? normalizedPerpendicular : -normalizedPerpendicular);

    // Calculate force magnitude based on distance
    // Use inverse relationship: closer segments get stronger forces
    // Add epsilon to avoid division by zero
    final targetDistance = config.minEdgeDistance;
    final distanceError = targetDistance - distance;

    // Only apply force if segments are too close (distance < targetDistance)
    if (distanceError <= 0) {
      return Offset.zero;
    }

    // Force magnitude is proportional to distance error
    // Scale by a factor to make forces reasonable (e.g., 0.1 for smooth movement)
    final forceMagnitude = distanceError * 0.1;

    return forceDirection * forceMagnitude;
  }

  /// Calculates the repulsion offset to apply to an edge's control points.
  ///
  /// For bezier curves, this offset is applied to the control points.
  /// For orthogonal paths, this offset is applied to the midpoint.
  ///
  /// Parameters:
  /// - [edge]: The edge to calculate offset for
  /// - [repulsionOffsets]: Map of repulsion offsets from applyRepulsionForces
  ///
  /// Returns the offset to apply, or Offset.zero if no repulsion is needed.
  Offset getRepulsionOffset(Edge edge, Map<Edge, Offset> repulsionOffsets) {
    return repulsionOffsets[edge] ?? Offset.zero;
  }

  String _stableEdgeKey(Edge edge) => <String>[
        edge.key is ValueKey ? (edge.key as ValueKey).value.toString() : '',
        edge.source.key?.value?.toString() ?? '',
        edge.destination.key?.value?.toString() ?? '',
        edge.label ?? '',
      ].join('|');
}
