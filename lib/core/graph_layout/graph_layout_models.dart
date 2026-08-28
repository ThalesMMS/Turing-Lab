import 'dart:collection';

enum GraphLayoutAlgorithmId {
  circle,
  twoCircle,
  spiral,
  hierarchical,
  sugiyama,
  componentPacking,
  seededForce,
  seededRandom,
  reflectHorizontal,
  reflectVertical,
  rotate90,
  rotate180,
  rotate270,
  fit,
  fill,
  restore,
}

enum GraphLayoutScope { all, selectedComponent, selectedNodes }

enum GraphLayoutDiagnosticSeverity { information, warning, blocking }

enum GraphLayoutDiagnosticCode {
  emptyGraph,
  unsupportedAlgorithmVersion,
  invalidTopology,
  missingSelection,
  missingRestoreSnapshot,
  resourceLimit,
  invalidInputCoordinate,
  invalidBounds,
  nonFiniteResultCoordinate,
  coordinateClamped,
  overlapsRemain,
  denseGraph,
  cancelled,
}

enum GraphLayoutProgressStage {
  preparingPreview,
  validatingGraph,
  computingLayout,
  forceIteration,
  measuringResult,
  complete,
}

final class GraphLayoutPoint {
  const GraphLayoutPoint(this.x, this.y);

  final double x;
  final double y;

  bool get isFinite => x.isFinite && y.isFinite;

  GraphLayoutPoint translate(double dx, double dy) =>
      GraphLayoutPoint(x + dx, y + dy);

  double distanceSquaredTo(GraphLayoutPoint other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return dx * dx + dy * dy;
  }

  @override
  bool operator ==(Object other) =>
      other is GraphLayoutPoint && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}

final class GraphLayoutBounds {
  const GraphLayoutBounds({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final double left;
  final double top;
  final double width;
  final double height;

  double get right => left + width;
  double get bottom => top + height;
  GraphLayoutPoint get center =>
      GraphLayoutPoint(left + width / 2, top + height / 2);
  bool get isFinite =>
      left.isFinite &&
      top.isFinite &&
      width.isFinite &&
      height.isFinite &&
      width >= 0 &&
      height >= 0;

  GraphLayoutBounds deflate(double value) {
    final amount = value.clamp(0, width / 2).toDouble();
    final vertical = value.clamp(0, height / 2).toDouble();
    return GraphLayoutBounds(
      left: left + amount,
      top: top + vertical,
      width: width - amount * 2,
      height: height - vertical * 2,
    );
  }

  static GraphLayoutBounds fromPoints(Iterable<GraphLayoutPoint> points) {
    final values = points.toList(growable: false);
    if (values.isEmpty) {
      return const GraphLayoutBounds(left: 0, top: 0, width: 0, height: 0);
    }
    var minX = values.first.x;
    var minY = values.first.y;
    var maxX = values.first.x;
    var maxY = values.first.y;
    for (final point in values.skip(1)) {
      if (point.x < minX) minX = point.x;
      if (point.y < minY) minY = point.y;
      if (point.x > maxX) maxX = point.x;
      if (point.y > maxY) maxY = point.y;
    }
    return GraphLayoutBounds(
      left: minX,
      top: minY,
      width: maxX - minX,
      height: maxY - minY,
    );
  }
}

final class GraphLayoutNode {
  const GraphLayoutNode({
    required this.id,
    required this.label,
    required this.position,
    this.isInitial = false,
  });

  final String id;
  final String label;
  final GraphLayoutPoint position;
  final bool isInitial;
}

final class GraphLayoutEdge {
  const GraphLayoutEdge({
    required this.id,
    required this.fromNodeId,
    required this.toNodeId,
  });

  final String id;
  final String fromNodeId;
  final String toNodeId;
}

final class GraphLayoutGraph {
  GraphLayoutGraph({
    required Iterable<GraphLayoutNode> nodes,
    required Iterable<GraphLayoutEdge> edges,
    this.revision = '',
  }) : nodes = List<GraphLayoutNode>.unmodifiable(nodes),
       edges = List<GraphLayoutEdge>.unmodifiable(edges);

  final List<GraphLayoutNode> nodes;
  final List<GraphLayoutEdge> edges;
  final String revision;
}

final class GraphLayoutSettings {
  GraphLayoutSettings({
    this.scope = GraphLayoutScope.all,
    Iterable<String> selectedNodeIds = const [],
    Iterable<String> pinnedNodeIds = const [],
    this.rootNodeId,
    this.seed = 0,
    this.nodeSpacing = 120,
    this.layerSpacing = 160,
    this.maximumIterations = 160,
    this.maximumNodes = 1000,
    this.maximumEdges = 5000,
    this.targetBounds = const GraphLayoutBounds(
      left: 40,
      top: 40,
      width: 720,
      height: 520,
    ),
    Map<String, GraphLayoutPoint> restorePositions = const {},
  }) : selectedNodeIds = Set<String>.unmodifiable(selectedNodeIds),
       pinnedNodeIds = Set<String>.unmodifiable(pinnedNodeIds),
       restorePositions = Map<String, GraphLayoutPoint>.unmodifiable(
         restorePositions,
       );

  final GraphLayoutScope scope;
  final Set<String> selectedNodeIds;
  final Set<String> pinnedNodeIds;
  final String? rootNodeId;
  final int seed;
  final double nodeSpacing;
  final double layerSpacing;
  final int maximumIterations;
  final int maximumNodes;
  final int maximumEdges;
  final GraphLayoutBounds targetBounds;
  final Map<String, GraphLayoutPoint> restorePositions;

  GraphLayoutSettings copyWith({
    GraphLayoutScope? scope,
    Iterable<String>? selectedNodeIds,
    Iterable<String>? pinnedNodeIds,
    String? rootNodeId,
    bool clearRootNodeId = false,
    int? seed,
    double? nodeSpacing,
    double? layerSpacing,
    int? maximumIterations,
    int? maximumNodes,
    int? maximumEdges,
    GraphLayoutBounds? targetBounds,
    Map<String, GraphLayoutPoint>? restorePositions,
  }) {
    return GraphLayoutSettings(
      scope: scope ?? this.scope,
      selectedNodeIds: selectedNodeIds ?? this.selectedNodeIds,
      pinnedNodeIds: pinnedNodeIds ?? this.pinnedNodeIds,
      rootNodeId: clearRootNodeId ? null : rootNodeId ?? this.rootNodeId,
      seed: seed ?? this.seed,
      nodeSpacing: nodeSpacing ?? this.nodeSpacing,
      layerSpacing: layerSpacing ?? this.layerSpacing,
      maximumIterations: maximumIterations ?? this.maximumIterations,
      maximumNodes: maximumNodes ?? this.maximumNodes,
      maximumEdges: maximumEdges ?? this.maximumEdges,
      targetBounds: targetBounds ?? this.targetBounds,
      restorePositions: restorePositions ?? this.restorePositions,
    );
  }
}

final class GraphLayoutRequest {
  const GraphLayoutRequest({
    required this.algorithmId,
    required this.graph,
    required this.settings,
    this.algorithmVersion = 1,
  });

  final GraphLayoutAlgorithmId algorithmId;
  final int algorithmVersion;
  final GraphLayoutGraph graph;
  final GraphLayoutSettings settings;
}

final class GraphLayoutDiagnostic {
  const GraphLayoutDiagnostic({
    required this.code,
    required this.severity,
    required this.message,
    this.algorithmVersion,
    this.nodeCount,
    this.maximumNodes,
    this.edgeCount,
    this.maximumEdges,
    this.nodeId,
    this.overlapCount,
    this.scope,
  });

  final GraphLayoutDiagnosticCode code;
  final GraphLayoutDiagnosticSeverity severity;
  final String message;
  final int? algorithmVersion;
  final int? nodeCount;
  final int? maximumNodes;
  final int? edgeCount;
  final int? maximumEdges;
  final String? nodeId;
  final int? overlapCount;
  final GraphLayoutScope? scope;

  bool get isBlocking => severity == GraphLayoutDiagnosticSeverity.blocking;
}

final class GraphLayoutMetrics {
  const GraphLayoutMetrics({
    required this.nodeCount,
    required this.edgeCount,
    required this.componentCount,
    required this.overlapCount,
    required this.edgeCrossingCount,
    required this.bounds,
    required this.iterations,
  });

  final int nodeCount;
  final int edgeCount;
  final int componentCount;
  final int overlapCount;
  final int edgeCrossingCount;
  final GraphLayoutBounds bounds;
  final int iterations;
}

final class GraphLayoutTransform {
  const GraphLayoutTransform({
    required this.a,
    required this.b,
    required this.c,
    required this.d,
    required this.tx,
    required this.ty,
  });

  final double a;
  final double b;
  final double c;
  final double d;
  final double tx;
  final double ty;

  GraphLayoutPoint apply(GraphLayoutPoint point) => GraphLayoutPoint(
    a * point.x + c * point.y + tx,
    b * point.x + d * point.y + ty,
  );
}

final class GraphLayoutResult {
  GraphLayoutResult({
    required this.algorithmId,
    required this.algorithmVersion,
    required Map<String, GraphLayoutPoint> positions,
    required Iterable<GraphLayoutDiagnostic> diagnostics,
    required this.metrics,
    required Iterable<String> affectedNodeIds,
    this.transform,
  }) : positions = UnmodifiableMapView(Map.of(positions)),
       diagnostics = List<GraphLayoutDiagnostic>.unmodifiable(diagnostics),
       affectedNodeIds = Set<String>.unmodifiable(affectedNodeIds);

  final GraphLayoutAlgorithmId algorithmId;
  final int algorithmVersion;
  final Map<String, GraphLayoutPoint> positions;
  final List<GraphLayoutDiagnostic> diagnostics;
  final GraphLayoutMetrics metrics;
  final Set<String> affectedNodeIds;
  final GraphLayoutTransform? transform;

  bool get canApply =>
      positions.isNotEmpty && diagnostics.every((item) => !item.isBlocking);
}

final class GraphLayoutProgress {
  const GraphLayoutProgress({
    required this.fraction,
    required this.stage,
    this.current,
    this.total,
  });

  final double fraction;
  final GraphLayoutProgressStage stage;
  final int? current;
  final int? total;
}
