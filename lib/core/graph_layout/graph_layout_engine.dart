import 'dart:math' as math;

import 'graph_layout_models.dart';

typedef GraphLayoutProgressCallback =
    void Function(GraphLayoutProgress progress);

abstract final class GraphLayoutEngine {
  static const double maximumCoordinateMagnitude = 1000000;

  static GraphLayoutResult compute(
    GraphLayoutRequest request, {
    GraphLayoutProgressCallback? onProgress,
  }) {
    final graph = request.graph;
    final settings = request.settings;
    final diagnostics = <GraphLayoutDiagnostic>[];
    onProgress?.call(
      const GraphLayoutProgress(
        fraction: 0.02,
        stage: GraphLayoutProgressStage.validatingGraph,
      ),
    );
    if (request.algorithmVersion != 1) {
      diagnostics.add(
        GraphLayoutDiagnostic(
          code: GraphLayoutDiagnosticCode.unsupportedAlgorithmVersion,
          severity: GraphLayoutDiagnosticSeverity.blocking,
          message:
              'Layout algorithm version ${request.algorithmVersion} is '
              'not supported.',
          algorithmVersion: request.algorithmVersion,
        ),
      );
      return _result(
        request,
        _safeOriginalPositions(graph, settings.targetBounds.center),
        diagnostics,
        const {},
        iterations: 0,
      );
    }
    if (graph.nodes.isEmpty) {
      diagnostics.add(
        const GraphLayoutDiagnostic(
          code: GraphLayoutDiagnosticCode.emptyGraph,
          severity: GraphLayoutDiagnosticSeverity.information,
          message: 'The graph has no nodes to lay out.',
        ),
      );
      return _result(request, const {}, diagnostics, const {}, iterations: 0);
    }
    final nodeIds = graph.nodes.map((node) => node.id).toList(growable: false);
    final edgeIds = graph.edges.map((edge) => edge.id).toList(growable: false);
    final nodeIdSet = nodeIds.toSet();
    final invalidTopology =
        nodeIds.any((id) => id.trim().isEmpty) ||
        edgeIds.any((id) => id.trim().isEmpty) ||
        nodeIdSet.length != nodeIds.length ||
        edgeIds.toSet().length != edgeIds.length ||
        graph.edges.any(
          (edge) =>
              !nodeIdSet.contains(edge.fromNodeId) ||
              !nodeIdSet.contains(edge.toNodeId),
        );
    if (invalidTopology) {
      diagnostics.add(
        const GraphLayoutDiagnostic(
          code: GraphLayoutDiagnosticCode.invalidTopology,
          severity: GraphLayoutDiagnosticSeverity.blocking,
          message:
              'Node and edge IDs must be non-empty and unique, and every '
              'edge endpoint must reference a node.',
        ),
      );
      return _result(
        request,
        _safeOriginalPositions(graph, settings.targetBounds.center),
        diagnostics,
        const {},
        iterations: 0,
      );
    }
    if (graph.nodes.any((node) => !node.position.isFinite)) {
      diagnostics.add(
        const GraphLayoutDiagnostic(
          code: GraphLayoutDiagnosticCode.invalidInputCoordinate,
          severity: GraphLayoutDiagnosticSeverity.blocking,
          message: 'Every input node position must be finite.',
        ),
      );
      return _result(
        request,
        _safeOriginalPositions(graph, settings.targetBounds.center),
        diagnostics,
        const {},
        iterations: 0,
      );
    }
    if (graph.nodes.length > settings.maximumNodes ||
        graph.edges.length > settings.maximumEdges) {
      diagnostics.add(
        GraphLayoutDiagnostic(
          code: GraphLayoutDiagnosticCode.resourceLimit,
          severity: GraphLayoutDiagnosticSeverity.blocking,
          message:
              'The graph exceeds the configured layout limit '
              '(${graph.nodes.length}/${settings.maximumNodes} nodes, '
              '${graph.edges.length}/${settings.maximumEdges} edges).',
          nodeCount: graph.nodes.length,
          maximumNodes: settings.maximumNodes,
          edgeCount: graph.edges.length,
          maximumEdges: settings.maximumEdges,
        ),
      );
      return _result(
        request,
        _safeOriginalPositions(graph, settings.targetBounds.center),
        diagnostics,
        const {},
        iterations: 0,
      );
    }
    if (!settings.targetBounds.isFinite ||
        !settings.nodeSpacing.isFinite ||
        settings.nodeSpacing <= 0 ||
        !settings.layerSpacing.isFinite ||
        settings.layerSpacing <= 0) {
      diagnostics.add(
        const GraphLayoutDiagnostic(
          code: GraphLayoutDiagnosticCode.invalidBounds,
          severity: GraphLayoutDiagnosticSeverity.blocking,
          message: 'Layout bounds and spacing must be finite and positive.',
        ),
      );
      return _result(
        request,
        _safeOriginalPositions(graph, settings.targetBounds.center),
        diagnostics,
        const {},
        iterations: 0,
      );
    }

    final scope = _resolveScope(graph, settings, diagnostics);
    if (diagnostics.any((item) => item.isBlocking)) {
      return _result(
        request,
        _safeOriginalPositions(graph, settings.targetBounds.center),
        diagnostics,
        const {},
        iterations: 0,
      );
    }
    final scopedNodes =
        graph.nodes
            .where((node) => scope.contains(node.id))
            .toList(growable: false)
          ..sort((left, right) => left.id.compareTo(right.id));
    final scopedEdges =
        graph.edges
            .where(
              (edge) =>
                  scope.contains(edge.fromNodeId) &&
                  scope.contains(edge.toNodeId),
            )
            .toList(growable: false)
          ..sort((left, right) => left.id.compareTo(right.id));
    final pinned = settings.pinnedNodeIds.intersection(scope);
    onProgress?.call(
      const GraphLayoutProgress(
        fraction: 0.08,
        stage: GraphLayoutProgressStage.computingLayout,
      ),
    );

    var computation = switch (request.algorithmId) {
      GraphLayoutAlgorithmId.circle => _circle(scopedNodes, settings),
      GraphLayoutAlgorithmId.twoCircle => _twoCircle(scopedNodes, settings),
      GraphLayoutAlgorithmId.spiral => _spiral(scopedNodes, settings),
      GraphLayoutAlgorithmId.hierarchical => _hierarchical(
        scopedNodes,
        scopedEdges,
        settings,
        reduceCrossings: false,
      ),
      GraphLayoutAlgorithmId.sugiyama => _hierarchical(
        scopedNodes,
        scopedEdges,
        settings,
        reduceCrossings: true,
      ),
      GraphLayoutAlgorithmId.componentPacking => _componentPacking(
        scopedNodes,
        scopedEdges,
        settings,
      ),
      GraphLayoutAlgorithmId.seededForce => _seededForce(
        scopedNodes,
        scopedEdges,
        settings,
        pinned,
        onProgress,
      ),
      GraphLayoutAlgorithmId.seededRandom => _seededRandom(
        scopedNodes,
        settings,
      ),
      GraphLayoutAlgorithmId.reflectHorizontal => _transform(
        scopedNodes,
        _reflection(scopedNodes, horizontal: true),
      ),
      GraphLayoutAlgorithmId.reflectVertical => _transform(
        scopedNodes,
        _reflection(scopedNodes, horizontal: false),
      ),
      GraphLayoutAlgorithmId.rotate90 => _transform(
        scopedNodes,
        _rotation(scopedNodes, 90),
      ),
      GraphLayoutAlgorithmId.rotate180 => _transform(
        scopedNodes,
        _rotation(scopedNodes, 180),
      ),
      GraphLayoutAlgorithmId.rotate270 => _transform(
        scopedNodes,
        _rotation(scopedNodes, 270),
      ),
      GraphLayoutAlgorithmId.fit => _transform(
        scopedNodes,
        _fitTransform(scopedNodes, settings.targetBounds, fill: false),
      ),
      GraphLayoutAlgorithmId.fill => _transform(
        scopedNodes,
        _fitTransform(scopedNodes, settings.targetBounds, fill: true),
      ),
      GraphLayoutAlgorithmId.restore => _restore(
        scopedNodes,
        settings,
        diagnostics,
      ),
    };

    if (_mustRemainInsideTarget(request.algorithmId)) {
      computation = _keepInsideTarget(computation, settings.targetBounds);
    }

    final positions = _safeOriginalPositions(
      graph,
      settings.targetBounds.center,
    )..addAll(computation.positions);
    for (final node in scopedNodes) {
      if (pinned.contains(node.id)) positions[node.id] = node.position;
    }
    var clamped = false;
    for (final entry in positions.entries.toList(growable: false)) {
      var point = entry.value;
      if (!point.isFinite) {
        diagnostics.add(
          GraphLayoutDiagnostic(
            code: GraphLayoutDiagnosticCode.nonFiniteResultCoordinate,
            severity: GraphLayoutDiagnosticSeverity.blocking,
            message:
                'Layout produced a non-finite coordinate for ${entry.key}.',
            nodeId: entry.key,
          ),
        );
        point = settings.targetBounds.center;
      }
      final x = point.x.clamp(
        -maximumCoordinateMagnitude,
        maximumCoordinateMagnitude,
      );
      final y = point.y.clamp(
        -maximumCoordinateMagnitude,
        maximumCoordinateMagnitude,
      );
      if (x != point.x || y != point.y) clamped = true;
      positions[entry.key] = GraphLayoutPoint(x.toDouble(), y.toDouble());
    }
    if (clamped) {
      diagnostics.add(
        const GraphLayoutDiagnostic(
          code: GraphLayoutDiagnosticCode.coordinateClamped,
          severity: GraphLayoutDiagnosticSeverity.warning,
          message: 'Extreme layout coordinates were clamped to safe bounds.',
        ),
      );
    }
    if (scopedEdges.length > scopedNodes.length * 4) {
      diagnostics.add(
        const GraphLayoutDiagnostic(
          code: GraphLayoutDiagnosticCode.denseGraph,
          severity: GraphLayoutDiagnosticSeverity.information,
          message: 'This is a dense graph; crossing metrics are heuristic.',
        ),
      );
    }
    onProgress?.call(
      const GraphLayoutProgress(
        fraction: 0.92,
        stage: GraphLayoutProgressStage.measuringResult,
      ),
    );
    final result = _result(
      request,
      positions,
      diagnostics,
      scope,
      iterations: computation.iterations,
      transform: scope.length == graph.nodes.length && pinned.isEmpty
          ? computation.transform
          : null,
    );
    if (result.metrics.overlapCount > 0) {
      diagnostics.add(
        GraphLayoutDiagnostic(
          code: GraphLayoutDiagnosticCode.overlapsRemain,
          severity: GraphLayoutDiagnosticSeverity.warning,
          message:
              '${result.metrics.overlapCount} possible node overlap(s) '
              'remain; review the preview before applying.',
          overlapCount: result.metrics.overlapCount,
        ),
      );
    }
    onProgress?.call(
      const GraphLayoutProgress(
        fraction: 1,
        stage: GraphLayoutProgressStage.complete,
      ),
    );
    return GraphLayoutResult(
      algorithmId: result.algorithmId,
      algorithmVersion: result.algorithmVersion,
      positions: result.positions,
      diagnostics: diagnostics,
      metrics: result.metrics,
      affectedNodeIds: result.affectedNodeIds,
      transform: result.transform,
    );
  }
}

final class _LayoutComputation {
  const _LayoutComputation({
    required this.positions,
    this.iterations = 0,
    this.transform,
  });

  final Map<String, GraphLayoutPoint> positions;
  final int iterations;
  final GraphLayoutTransform? transform;
}

Map<String, GraphLayoutPoint> _safeOriginalPositions(
  GraphLayoutGraph graph,
  GraphLayoutPoint fallback,
) {
  final safeFallback = fallback.isFinite
      ? fallback
      : const GraphLayoutPoint(0, 0);
  return {
    for (final node in graph.nodes)
      node.id: node.position.isFinite
          ? GraphLayoutPoint(
              node.position.x
                  .clamp(
                    -GraphLayoutEngine.maximumCoordinateMagnitude,
                    GraphLayoutEngine.maximumCoordinateMagnitude,
                  )
                  .toDouble(),
              node.position.y
                  .clamp(
                    -GraphLayoutEngine.maximumCoordinateMagnitude,
                    GraphLayoutEngine.maximumCoordinateMagnitude,
                  )
                  .toDouble(),
            )
          : safeFallback,
  };
}

bool _mustRemainInsideTarget(GraphLayoutAlgorithmId algorithm) =>
    switch (algorithm) {
      GraphLayoutAlgorithmId.circle ||
      GraphLayoutAlgorithmId.twoCircle ||
      GraphLayoutAlgorithmId.spiral ||
      GraphLayoutAlgorithmId.hierarchical ||
      GraphLayoutAlgorithmId.sugiyama ||
      GraphLayoutAlgorithmId.componentPacking ||
      GraphLayoutAlgorithmId.seededRandom => true,
      _ => false,
    };

_LayoutComputation _keepInsideTarget(
  _LayoutComputation computation,
  GraphLayoutBounds target,
) {
  if (computation.positions.isEmpty) return computation;
  final source = GraphLayoutBounds.fromPoints(computation.positions.values);
  final alreadyInside =
      source.left >= target.left &&
      source.top >= target.top &&
      source.right <= target.right &&
      source.bottom <= target.bottom;
  if (alreadyInside) return computation;
  final horizontalScale = source.width == 0 ? 1.0 : target.width / source.width;
  final verticalScale = source.height == 0
      ? 1.0
      : target.height / source.height;
  final scale = math.min(1.0, math.min(horizontalScale, verticalScale));
  final transform = GraphLayoutTransform(
    a: scale,
    b: 0,
    c: 0,
    d: scale,
    tx: target.center.x - source.center.x * scale,
    ty: target.center.y - source.center.y * scale,
  );
  return _LayoutComputation(
    positions: {
      for (final entry in computation.positions.entries)
        entry.key: transform.apply(entry.value),
    },
    iterations: computation.iterations,
  );
}

Set<String> _resolveScope(
  GraphLayoutGraph graph,
  GraphLayoutSettings settings,
  List<GraphLayoutDiagnostic> diagnostics,
) {
  final all = graph.nodes.map((node) => node.id).toSet();
  switch (settings.scope) {
    case GraphLayoutScope.all:
      return all;
    case GraphLayoutScope.selectedNodes:
      final selected = settings.selectedNodeIds.intersection(all);
      if (selected.isEmpty) {
        diagnostics.add(
          const GraphLayoutDiagnostic(
            code: GraphLayoutDiagnosticCode.missingSelection,
            severity: GraphLayoutDiagnosticSeverity.blocking,
            message: 'Select at least one node for selected-node layout.',
            scope: GraphLayoutScope.selectedNodes,
          ),
        );
      }
      return selected;
    case GraphLayoutScope.selectedComponent:
      final selected = settings.selectedNodeIds.intersection(all).toList()
        ..sort();
      if (selected.isEmpty) {
        diagnostics.add(
          const GraphLayoutDiagnostic(
            code: GraphLayoutDiagnosticCode.missingSelection,
            severity: GraphLayoutDiagnosticSeverity.blocking,
            message:
                'Select a node whose connected component will be laid out.',
            scope: GraphLayoutScope.selectedComponent,
          ),
        );
        return const {};
      }
      final adjacency = _undirectedAdjacency(graph.nodes, graph.edges);
      final visited = <String>{selected.first};
      final pending = <String>[selected.first];
      while (pending.isNotEmpty) {
        final id = pending.removeLast();
        final neighbors = adjacency[id]?.toList() ?? const <String>[];
        neighbors.sort();
        for (final neighbor in neighbors) {
          if (visited.add(neighbor)) pending.add(neighbor);
        }
      }
      return visited;
  }
}

_LayoutComputation _circle(
  List<GraphLayoutNode> nodes,
  GraphLayoutSettings settings,
) {
  if (nodes.length == 1) {
    return _LayoutComputation(
      positions: {nodes.single.id: settings.targetBounds.center},
    );
  }
  final radius = math.max(
    settings.nodeSpacing,
    nodes.length * settings.nodeSpacing / (2 * math.pi),
  );
  final center = settings.targetBounds.center;
  return _LayoutComputation(
    positions: {
      for (var index = 0; index < nodes.length; index++)
        nodes[index].id: GraphLayoutPoint(
          center.x +
              radius *
                  math.cos(-math.pi / 2 + 2 * math.pi * index / nodes.length),
          center.y +
              radius *
                  math.sin(-math.pi / 2 + 2 * math.pi * index / nodes.length),
        ),
    },
  );
}

_LayoutComputation _twoCircle(
  List<GraphLayoutNode> nodes,
  GraphLayoutSettings settings,
) {
  if (nodes.length < 7) return _circle(nodes, settings);
  final innerCount = (nodes.length / 3).ceil();
  final inner = nodes.take(innerCount).toList(growable: false);
  final outer = nodes.skip(innerCount).toList(growable: false);
  final center = settings.targetBounds.center;
  final innerRadius = math.max(settings.nodeSpacing, inner.length * 24.0);
  final outerRadius = math.max(
    innerRadius + settings.nodeSpacing * 1.5,
    outer.length * settings.nodeSpacing / (2 * math.pi),
  );
  final positions = <String, GraphLayoutPoint>{};
  void place(List<GraphLayoutNode> values, double radius) {
    for (var index = 0; index < values.length; index++) {
      final angle = -math.pi / 2 + 2 * math.pi * index / values.length;
      positions[values[index].id] = GraphLayoutPoint(
        center.x + radius * math.cos(angle),
        center.y + radius * math.sin(angle),
      );
    }
  }

  place(inner, innerRadius);
  place(outer, outerRadius);
  return _LayoutComputation(positions: positions);
}

_LayoutComputation _spiral(
  List<GraphLayoutNode> nodes,
  GraphLayoutSettings settings,
) {
  final center = settings.targetBounds.center;
  final positions = <String, GraphLayoutPoint>{};
  for (var index = 0; index < nodes.length; index++) {
    final angle = index * 0.82;
    final radius = settings.nodeSpacing * 0.45 * math.sqrt(index.toDouble());
    positions[nodes[index].id] = GraphLayoutPoint(
      center.x + radius * math.cos(angle),
      center.y + radius * math.sin(angle),
    );
  }
  return _LayoutComputation(positions: positions);
}

_LayoutComputation _hierarchical(
  List<GraphLayoutNode> nodes,
  List<GraphLayoutEdge> edges,
  GraphLayoutSettings settings, {
  required bool reduceCrossings,
}) {
  if (nodes.length <= 1) return _circle(nodes, settings);
  final ids = nodes.map((node) => node.id).toSet();
  final outgoing = <String, List<String>>{for (final id in ids) id: <String>[]};
  final incoming = <String, List<String>>{for (final id in ids) id: <String>[]};
  for (final edge in edges) {
    if (edge.fromNodeId == edge.toNodeId) continue;
    outgoing[edge.fromNodeId]?.add(edge.toNodeId);
    incoming[edge.toNodeId]?.add(edge.fromNodeId);
  }
  for (final values in [...outgoing.values, ...incoming.values]) {
    values.sort();
  }
  final preferredRoot = settings.rootNodeId;
  final initial = nodes.where((node) => node.isInitial).map((node) => node.id);
  final rootCandidates = <String>[
    if (preferredRoot != null && ids.contains(preferredRoot)) preferredRoot,
    ...initial,
    ...nodes.map((node) => node.id),
  ];
  final levelById = <String, int>{};
  for (final root in rootCandidates) {
    if (levelById.containsKey(root)) continue;
    levelById[root] = 0;
    final queue = <String>[root];
    var cursor = 0;
    while (cursor < queue.length) {
      final id = queue[cursor++];
      final level = levelById[id]!;
      for (final target in outgoing[id]!) {
        if (levelById.containsKey(target)) continue;
        levelById[target] = level + 1;
        queue.add(target);
      }
      for (final neighbor in incoming[id]!) {
        if (levelById.containsKey(neighbor)) continue;
        levelById[neighbor] = level + 1;
        queue.add(neighbor);
      }
    }
  }
  final layers = <int, List<String>>{};
  for (final entry in levelById.entries) {
    layers.putIfAbsent(entry.value, () => []).add(entry.key);
  }
  for (final layer in layers.values) {
    layer.sort();
  }
  if (reduceCrossings) {
    final maxLevel = layers.keys.reduce(math.max);
    for (var pass = 0; pass < 4; pass++) {
      for (var level = 1; level <= maxLevel; level++) {
        final previous = layers[level - 1] ?? const <String>[];
        final order = {
          for (var index = 0; index < previous.length; index++)
            previous[index]: index,
        };
        layers[level]?.sort((left, right) {
          final leftScore = _barycenter(incoming[left]!, order);
          final rightScore = _barycenter(incoming[right]!, order);
          final comparison = leftScore.compareTo(rightScore);
          return comparison != 0 ? comparison : left.compareTo(right);
        });
      }
    }
  }
  final bounds = settings.targetBounds.deflate(settings.nodeSpacing / 2);
  final maxLevel = layers.keys.reduce(math.max);
  final positions = <String, GraphLayoutPoint>{};
  for (var level = 0; level <= maxLevel; level++) {
    final layer = layers[level] ?? const <String>[];
    final totalWidth = math.max(0, layer.length - 1) * settings.nodeSpacing;
    final startX = bounds.center.x - totalWidth / 2;
    final y = maxLevel == 0
        ? bounds.center.y
        : bounds.top + bounds.height * level / maxLevel;
    for (var index = 0; index < layer.length; index++) {
      positions[layer[index]] = GraphLayoutPoint(
        startX + index * settings.nodeSpacing,
        y,
      );
    }
  }
  return _LayoutComputation(
    positions: positions,
    iterations: reduceCrossings ? 4 : 1,
  );
}

double _barycenter(List<String> neighbors, Map<String, int> order) {
  final values = neighbors
      .where(order.containsKey)
      .map((id) => order[id]!)
      .toList();
  if (values.isEmpty) return double.infinity;
  return values.reduce((left, right) => left + right) / values.length;
}

_LayoutComputation _componentPacking(
  List<GraphLayoutNode> nodes,
  List<GraphLayoutEdge> edges,
  GraphLayoutSettings settings,
) {
  final components = _components(nodes, edges);
  final columns = math.max(1, math.sqrt(components.length).ceil());
  final cellWidth = math.max(
    settings.nodeSpacing * 2,
    settings.targetBounds.width / columns,
  );
  final rows = (components.length / columns).ceil();
  final cellHeight = math.max(
    settings.nodeSpacing * 2,
    settings.targetBounds.height / math.max(1, rows),
  );
  final positions = <String, GraphLayoutPoint>{};
  for (var index = 0; index < components.length; index++) {
    final component = components[index];
    final originalBounds = GraphLayoutBounds.fromPoints(
      component.map((node) => node.position),
    );
    final column = index % columns;
    final row = index ~/ columns;
    final targetCenter = GraphLayoutPoint(
      settings.targetBounds.left + cellWidth * (column + 0.5),
      settings.targetBounds.top + cellHeight * (row + 0.5),
    );
    final dx = targetCenter.x - originalBounds.center.x;
    final dy = targetCenter.y - originalBounds.center.y;
    if (component.length == 1) {
      positions[component.single.id] = targetCenter;
      continue;
    }
    for (final node in component) {
      positions[node.id] = node.position.translate(dx, dy);
    }
  }
  return _LayoutComputation(positions: positions);
}

_LayoutComputation _seededRandom(
  List<GraphLayoutNode> nodes,
  GraphLayoutSettings settings,
) {
  final random = _StableRandom(settings.seed);
  final bounds = settings.targetBounds.deflate(settings.nodeSpacing / 2);
  return _LayoutComputation(
    positions: {
      for (final node in nodes)
        node.id: GraphLayoutPoint(
          bounds.left + random.nextDouble() * bounds.width,
          bounds.top + random.nextDouble() * bounds.height,
        ),
    },
  );
}

_LayoutComputation _seededForce(
  List<GraphLayoutNode> nodes,
  List<GraphLayoutEdge> edges,
  GraphLayoutSettings settings,
  Set<String> pinned,
  GraphLayoutProgressCallback? onProgress,
) {
  if (nodes.length <= 1) return _circle(nodes, settings);
  final positions = Map<String, GraphLayoutPoint>.from(
    _seededRandom(nodes, settings).positions,
  );
  for (final node in nodes) {
    if (pinned.contains(node.id) && node.position.isFinite) {
      positions[node.id] = node.position;
    }
  }
  final area = math.max(
    1.0,
    settings.targetBounds.width * settings.targetBounds.height,
  );
  final ideal = math
      .sqrt(area / nodes.length)
      .clamp(40.0, settings.nodeSpacing * 1.5);
  final iterations = settings.maximumIterations.clamp(1, 500);
  final temperatureStart = math.max(settings.nodeSpacing, 40.0);
  final ids = nodes.map((node) => node.id).toList(growable: false);
  for (var iteration = 0; iteration < iterations; iteration++) {
    final displacement = {
      for (final id in ids) id: const GraphLayoutPoint(0, 0),
    };
    for (var leftIndex = 0; leftIndex < ids.length; leftIndex++) {
      for (
        var rightIndex = leftIndex + 1;
        rightIndex < ids.length;
        rightIndex++
      ) {
        final leftId = ids[leftIndex];
        final rightId = ids[rightIndex];
        final left = positions[leftId]!;
        final right = positions[rightId]!;
        var dx = left.x - right.x;
        var dy = left.y - right.y;
        var distance = math.sqrt(dx * dx + dy * dy);
        if (distance < 0.001) {
          dx = (leftIndex + 1) * 0.01;
          dy = (rightIndex + 1) * 0.01;
          distance = math.sqrt(dx * dx + dy * dy);
        }
        final force = ideal * ideal / distance;
        final fx = dx / distance * force;
        final fy = dy / distance * force;
        displacement[leftId] = displacement[leftId]!.translate(fx, fy);
        displacement[rightId] = displacement[rightId]!.translate(-fx, -fy);
      }
    }
    for (final edge in edges) {
      if (edge.fromNodeId == edge.toNodeId) continue;
      final from = positions[edge.fromNodeId];
      final to = positions[edge.toNodeId];
      if (from == null || to == null) continue;
      final dx = from.x - to.x;
      final dy = from.y - to.y;
      final distance = math.max(0.001, math.sqrt(dx * dx + dy * dy));
      final force = distance * distance / ideal;
      final fx = dx / distance * force;
      final fy = dy / distance * force;
      displacement[edge.fromNodeId] = displacement[edge.fromNodeId]!.translate(
        -fx,
        -fy,
      );
      displacement[edge.toNodeId] = displacement[edge.toNodeId]!.translate(
        fx,
        fy,
      );
    }
    final temperature = temperatureStart * (1 - iteration / iterations);
    for (final id in ids) {
      if (pinned.contains(id)) continue;
      final delta = displacement[id]!;
      final length = math.sqrt(delta.x * delta.x + delta.y * delta.y);
      if (length == 0) continue;
      final step = math.min(length, temperature);
      final current = positions[id]!;
      positions[id] = GraphLayoutPoint(
        (current.x + delta.x / length * step)
            .clamp(settings.targetBounds.left, settings.targetBounds.right)
            .toDouble(),
        (current.y + delta.y / length * step)
            .clamp(settings.targetBounds.top, settings.targetBounds.bottom)
            .toDouble(),
      );
    }
    if (iteration % 12 == 0) {
      onProgress?.call(
        GraphLayoutProgress(
          fraction: 0.1 + 0.78 * iteration / iterations,
          stage: GraphLayoutProgressStage.forceIteration,
          current: iteration + 1,
          total: iterations,
        ),
      );
    }
  }
  return _LayoutComputation(positions: positions, iterations: iterations);
}

_LayoutComputation _restore(
  List<GraphLayoutNode> nodes,
  GraphLayoutSettings settings,
  List<GraphLayoutDiagnostic> diagnostics,
) {
  final positions = <String, GraphLayoutPoint>{};
  for (final node in nodes) {
    final restored = settings.restorePositions[node.id];
    if (restored != null) positions[node.id] = restored;
  }
  if (positions.isEmpty) {
    diagnostics.add(
      const GraphLayoutDiagnostic(
        code: GraphLayoutDiagnosticCode.missingRestoreSnapshot,
        severity: GraphLayoutDiagnosticSeverity.blocking,
        message: 'No saved manual or previous layout is available to restore.',
      ),
    );
  }
  return _LayoutComputation(positions: positions);
}

_LayoutComputation _transform(
  List<GraphLayoutNode> nodes,
  GraphLayoutTransform transform,
) => _LayoutComputation(
  positions: {
    for (final node in nodes) node.id: transform.apply(node.position),
  },
  transform: transform,
);

GraphLayoutTransform _reflection(
  List<GraphLayoutNode> nodes, {
  required bool horizontal,
}) {
  final center = GraphLayoutBounds.fromPoints(
    nodes.map((node) => node.position),
  ).center;
  return horizontal
      ? GraphLayoutTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: center.y * 2)
      : GraphLayoutTransform(a: -1, b: 0, c: 0, d: 1, tx: center.x * 2, ty: 0);
}

GraphLayoutTransform _rotation(List<GraphLayoutNode> nodes, int degrees) {
  final center = GraphLayoutBounds.fromPoints(
    nodes.map((node) => node.position),
  ).center;
  final angle = degrees * math.pi / 180;
  final cosine = math.cos(angle);
  final sine = math.sin(angle);
  return GraphLayoutTransform(
    a: cosine,
    b: sine,
    c: -sine,
    d: cosine,
    tx: center.x - cosine * center.x + sine * center.y,
    ty: center.y - sine * center.x - cosine * center.y,
  );
}

GraphLayoutTransform _fitTransform(
  List<GraphLayoutNode> nodes,
  GraphLayoutBounds target, {
  required bool fill,
}) {
  final source = GraphLayoutBounds.fromPoints(
    nodes.map((node) => node.position),
  );
  if (source.width == 0 && source.height == 0) {
    return GraphLayoutTransform(
      a: 1,
      b: 0,
      c: 0,
      d: 1,
      tx: target.center.x - source.center.x,
      ty: target.center.y - source.center.y,
    );
  }
  var scaleX = source.width == 0 ? 1.0 : target.width / source.width;
  var scaleY = source.height == 0 ? 1.0 : target.height / source.height;
  if (!fill) {
    final scale = source.width == 0
        ? scaleY
        : source.height == 0
        ? scaleX
        : math.min(scaleX, scaleY);
    scaleX = scale;
    scaleY = scale;
  }
  return GraphLayoutTransform(
    a: scaleX,
    b: 0,
    c: 0,
    d: scaleY,
    tx: target.center.x - source.center.x * scaleX,
    ty: target.center.y - source.center.y * scaleY,
  );
}

Map<String, Set<String>> _undirectedAdjacency(
  Iterable<GraphLayoutNode> nodes,
  Iterable<GraphLayoutEdge> edges,
) {
  final adjacency = <String, Set<String>>{
    for (final node in nodes) node.id: <String>{},
  };
  for (final edge in edges) {
    if (!adjacency.containsKey(edge.fromNodeId) ||
        !adjacency.containsKey(edge.toNodeId)) {
      continue;
    }
    adjacency[edge.fromNodeId]!.add(edge.toNodeId);
    adjacency[edge.toNodeId]!.add(edge.fromNodeId);
  }
  return adjacency;
}

List<List<GraphLayoutNode>> _components(
  List<GraphLayoutNode> nodes,
  List<GraphLayoutEdge> edges,
) {
  final byId = {for (final node in nodes) node.id: node};
  final adjacency = _undirectedAdjacency(nodes, edges);
  final remaining = byId.keys.toList()..sort();
  final visited = <String>{};
  final result = <List<GraphLayoutNode>>[];
  for (final root in remaining) {
    if (!visited.add(root)) continue;
    final ids = <String>[];
    final pending = <String>[root];
    while (pending.isNotEmpty) {
      final id = pending.removeLast();
      ids.add(id);
      final neighbors = adjacency[id]!.toList()..sort();
      for (final neighbor in neighbors.reversed) {
        if (visited.add(neighbor)) pending.add(neighbor);
      }
    }
    ids.sort();
    result.add(ids.map((id) => byId[id]!).toList(growable: false));
  }
  result.sort((left, right) => left.first.id.compareTo(right.first.id));
  return result;
}

GraphLayoutResult _result(
  GraphLayoutRequest request,
  Map<String, GraphLayoutPoint> positions,
  List<GraphLayoutDiagnostic> diagnostics,
  Set<String> affected, {
  required int iterations,
  GraphLayoutTransform? transform,
}) {
  final graph = request.graph;
  final validPositions = positions.values.where((point) => point.isFinite);
  final bounds = GraphLayoutBounds.fromPoints(validPositions);
  final components = _components(graph.nodes, graph.edges);
  final overlapThreshold = request.settings.nodeSpacing * 0.72;
  var overlaps = 0;
  final values = positions.entries.toList(growable: false)
    ..sort((left, right) => left.key.compareTo(right.key));
  for (var left = 0; left < values.length; left++) {
    for (var right = left + 1; right < values.length; right++) {
      if (values[left].value.distanceSquaredTo(values[right].value) <
          overlapThreshold * overlapThreshold) {
        overlaps++;
      }
    }
  }
  return GraphLayoutResult(
    algorithmId: request.algorithmId,
    algorithmVersion: request.algorithmVersion,
    positions: positions,
    diagnostics: diagnostics,
    metrics: GraphLayoutMetrics(
      nodeCount: graph.nodes.length,
      edgeCount: graph.edges.length,
      componentCount: components.length,
      overlapCount: overlaps,
      edgeCrossingCount: _edgeCrossings(graph.edges, positions),
      bounds: bounds,
      iterations: iterations,
    ),
    affectedNodeIds: affected,
    transform: transform,
  );
}

int _edgeCrossings(
  List<GraphLayoutEdge> edges,
  Map<String, GraphLayoutPoint> positions,
) {
  if (edges.length > 800) return -1;
  var crossings = 0;
  for (var leftIndex = 0; leftIndex < edges.length; leftIndex++) {
    final left = edges[leftIndex];
    if (left.fromNodeId == left.toNodeId) continue;
    final leftStart = positions[left.fromNodeId];
    final leftEnd = positions[left.toNodeId];
    if (leftStart == null || leftEnd == null) continue;
    for (
      var rightIndex = leftIndex + 1;
      rightIndex < edges.length;
      rightIndex++
    ) {
      final right = edges[rightIndex];
      if ({
        left.fromNodeId,
        left.toNodeId,
      }.intersection({right.fromNodeId, right.toNodeId}).isNotEmpty) {
        continue;
      }
      final rightStart = positions[right.fromNodeId];
      final rightEnd = positions[right.toNodeId];
      if (rightStart == null || rightEnd == null) continue;
      if (_segmentsCross(leftStart, leftEnd, rightStart, rightEnd)) crossings++;
    }
  }
  return crossings;
}

bool _segmentsCross(
  GraphLayoutPoint a,
  GraphLayoutPoint b,
  GraphLayoutPoint c,
  GraphLayoutPoint d,
) {
  double orientation(
    GraphLayoutPoint p,
    GraphLayoutPoint q,
    GraphLayoutPoint r,
  ) => (q.y - p.y) * (r.x - q.x) - (q.x - p.x) * (r.y - q.y);
  final first = orientation(a, b, c);
  final second = orientation(a, b, d);
  final third = orientation(c, d, a);
  final fourth = orientation(c, d, b);
  return first * second < 0 && third * fourth < 0;
}

final class _StableRandom {
  _StableRandom(int seed) : _state = (seed ^ 0x9E3779B9) & 0xFFFFFFFF;

  int _state;

  double nextDouble() {
    _state = (1664525 * _state + 1013904223) & 0xFFFFFFFF;
    return _state / 0x100000000;
  }
}
