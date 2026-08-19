part of 'turing_lab_adaptive_edge_renderer.dart';

extension _TuringLabAdaptiveEdgeRendererRouteLayout
    on TuringLabAdaptiveEdgeRenderer {
  void _ensureAutomaticRouteGeometry() {
    final currentGraph = graph;
    if (currentGraph == null) {
      _clearAutomaticRouteGeometry();
      return;
    }

    _ensureEdgeCaches();
    final edgeSignature =
        Object.hashAll(currentGraph.edges.map(identityHashCode));
    final currentNodeStamps = <String, _NodeGeometryStamp>{
      for (final node in currentGraph.nodes)
        _nodeId(node): _NodeGeometryStamp.quantized(
          position: getNodePosition(node),
          size: node.size,
        ),
    };
    // Structure and geometry are compared by content, never by the identity
    // of the Graph container: GraphView re-derives an equivalent visible
    // graph on every rebuild and a full identity-based replan makes edges
    // flicker.
    if (_automaticRouteEdgeSignature == edgeSignature &&
        _automaticRouteRenderMode == renderMode &&
        mapEquals(_automaticRouteNodeStamps, currentNodeStamps)) {
      return;
    }

    final groups = _visibleRouteGroups();
    final structureChanged = _automaticRouteEdgeSignature != edgeSignature ||
        _automaticRouteRenderMode != renderMode;
    final affectedGroups = structureChanged
        ? groups.toSet()
        : _affectedRouteGroups(groups, currentNodeStamps);

    if (structureChanged) {
      _automaticRouteGeometry.clear();
    } else {
      for (final group in affectedGroups) {
        for (final member in group.members) {
          _automaticRouteGeometry.remove(member);
        }
      }
    }

    final unaffectedPaths = <EdgePathGeometry>[
      for (final group in groups)
        if (!affectedGroups.contains(group) &&
            _automaticRouteGeometry[group.representative] != null)
          _automaticRouteGeometry[group.representative]!.pathGeometry,
    ];
    final laneOffsets = _laneOffsetsForGroups(groups);
    final requests = <AutomaticTransitionRouteRequest>[
      for (final group in affectedGroups)
        AutomaticTransitionRouteRequest(
          stableId: group.stableId,
          sourceId: group.sourceId,
          destinationId: group.destinationId,
          sourceCenter: getNodeCenter(group.representative.source),
          destinationCenter: getNodeCenter(group.representative.destination),
          sourceRadius: _nodeRadius(group.representative.source),
          destinationRadius: _nodeRadius(group.representative.destination),
          laneOffset: laneOffsets[group.stableId] ?? 0,
          repulsionOffset: renderMode == TuringLabEdgeRenderMode.groupedFsa
              ? Offset.zero
              : _preparedRepulsionOffsetFor(group.representative),
          previousLoopHeading: _lastLoopHeadings[group.stableId],
        ),
    ];
    final obstacles = <AutomaticTransitionObstacle>[
      for (final node in currentGraph.nodes)
        AutomaticTransitionObstacle(
          id: _nodeId(node),
          center: getNodeCenter(node),
          radius: _nodeRadius(node),
        ),
    ];
    final plans = _routePlanner.plan(
      requests: requests,
      obstacles: obstacles,
      existingPaths: unaffectedPaths,
    );

    for (final group in affectedGroups) {
      final plan = plans[group.stableId];
      if (plan?.loopHeading case final heading?) {
        _lastLoopHeadings[group.stableId] = heading;
      }
      final geometry = group.isSelfLoop
          ? _buildAutomaticLoopGeometry(group, plan)
          : _buildAutomaticNormalGeometry(group, plan);
      if (geometry == null) {
        continue;
      }
      for (final member in group.members) {
        _automaticRouteGeometry[member] = geometry;
      }
    }

    _automaticRouteEdgeSignature = edgeSignature;
    _automaticRouteRenderMode = renderMode;
    _automaticRouteNodeStamps = currentNodeStamps;
  }

  Set<_VisibleRouteGroup> _affectedRouteGroups(
    List<_VisibleRouteGroup> groups,
    Map<String, _NodeGeometryStamp> currentNodeStamps,
  ) {
    final movedNodeIds = <String>{
      ..._automaticRouteNodeStamps.keys.where(
        (id) => _automaticRouteNodeStamps[id] != currentNodeStamps[id],
      ),
      ...currentNodeStamps.keys.where(
        (id) => currentNodeStamps[id] != _automaticRouteNodeStamps[id],
      ),
    };
    if (movedNodeIds.isEmpty) {
      return <_VisibleRouteGroup>{};
    }

    final sweptBounds = <Rect>[
      for (final id in movedNodeIds)
        if (_automaticRouteNodeStamps[id] != null &&
            currentNodeStamps[id] != null)
          _automaticRouteNodeStamps[id]!
              .bounds
              .expandToInclude(currentNodeStamps[id]!.bounds)
              .inflate(_routePlanner.routeClearance),
    ];
    return groups.where((group) {
      if (movedNodeIds.contains(group.sourceId) ||
          movedNodeIds.contains(group.destinationId)) {
        return true;
      }
      final cached = _automaticRouteGeometry[group.representative];
      return cached == null ||
          sweptBounds.any(
            (bounds) => bounds.overlaps(
              cached.pathGeometry.bounds.inflate(
                _routePlanner.routeClearance,
              ),
            ),
          );
    }).toSet();
  }

  List<_VisibleRouteGroup> _visibleRouteGroups() {
    final currentGraph = graph;
    if (currentGraph == null) {
      return const <_VisibleRouteGroup>[];
    }

    final groups = <_VisibleRouteGroup>[];
    if (renderMode == TuringLabEdgeRenderMode.groupedFsa) {
      for (final entry in _groupedEdgeCache.entries) {
        final members = List<Edge>.unmodifiable(entry.value);
        if (members.isEmpty) {
          continue;
        }
        groups.add(
          _VisibleRouteGroup(
            stableId: 'group:${entry.key.sourceId}->${entry.key.destinationId}',
            sourceId: entry.key.sourceId,
            destinationId: entry.key.destinationId,
            representative: members.first,
            members: members,
          ),
        );
      }
    } else {
      for (final edge in currentGraph.edges) {
        groups.add(
          _VisibleRouteGroup(
            stableId: _edgeId(edge),
            sourceId: _nodeId(edge.source),
            destinationId: _nodeId(edge.destination),
            representative: edge,
            members: <Edge>[edge],
          ),
        );
      }
    }
    groups.sort((left, right) => left.stableId.compareTo(right.stableId));
    return groups;
  }

  Map<String, double> _laneOffsetsForGroups(
    List<_VisibleRouteGroup> groups,
  ) {
    final byUnorderedPair = <String, List<_VisibleRouteGroup>>{};
    for (final group in groups.where((group) => !group.isSelfLoop)) {
      final orderedIds = <String>[group.sourceId, group.destinationId]..sort();
      byUnorderedPair
          .putIfAbsent('${orderedIds.first}|${orderedIds.last}', () => [])
          .add(group);
    }

    final result = <String, double>{};
    for (final pairGroups in byUnorderedPair.values) {
      pairGroups.sort((left, right) => left.stableId.compareTo(right.stableId));
      for (var index = 0; index < pairGroups.length; index++) {
        final group = pairGroups[index];
        final physicalOffset =
            (index - (pairGroups.length - 1) / 2) * _groupLaneSpacing;
        result[group.stableId] =
            group.sourceId.compareTo(group.destinationId) <= 0
                ? physicalOffset
                : -physicalOffset;
      }
    }
    return result;
  }

  TuringLabEdgeRenderGeometry? _buildAutomaticNormalGeometry(
    _VisibleRouteGroup group,
    AutomaticTransitionRoutePlan? plan,
  ) {
    if (plan == null) {
      return null;
    }
    final edge = group.representative;
    final sourceCenter = getNodeCenter(edge.source);
    final destinationCenter = getNodeCenter(edge.destination);
    final source = resolveCircularConnectionPoint(
      center: sourceCenter,
      radius: _nodeRadius(edge.source),
      toward: plan.controlPoint,
      fallbackDirection: destinationCenter - sourceCenter,
    );
    final destination = resolveCircularConnectionPoint(
      center: destinationCenter,
      radius: _nodeRadius(edge.destination),
      toward: plan.controlPoint,
      fallbackDirection: sourceCenter - destinationCenter,
    );
    final path = Path()
      ..moveTo(source.dx, source.dy)
      ..quadraticBezierTo(
        plan.controlPoint.dx,
        plan.controlPoint.dy,
        destination.dx,
        destination.dy,
      );
    return TuringLabEdgeRenderGeometry(
      pathGeometry: EdgePathGeometry.fromPath(
        path,
        fallbackStart: source,
        fallbackEnd: destination,
        arrowLength: noArrow ? 0 : ARROW_LENGTH,
        kind: EdgePathKind.curved,
      ),
      labelNormal: plan.labelNormal,
    );
  }

  TuringLabEdgeRenderGeometry? _buildAutomaticLoopGeometry(
    _VisibleRouteGroup group,
    AutomaticTransitionRoutePlan? plan,
  ) {
    if (plan?.loopHeading == null) {
      return null;
    }
    final groupedExtra = renderMode == TuringLabEdgeRenderMode.groupedFsa
        ? resolveGroupedFsaLoopExtraOffset(group.members.length)
        : 0.0;
    final loop = buildSelfLoopPath(
      group.representative,
      heading: plan!.loopHeading!,
      loopPadding: plan.loopPadding + groupedExtra,
      arrowLength: noArrow ? 0 : ARROW_LENGTH,
    );
    if (loop == null) {
      return null;
    }
    return TuringLabEdgeRenderGeometry(
      pathGeometry: EdgePathGeometry.fromPath(
        loop.path,
        fallbackStart: loop.arrowBase,
        fallbackEnd: loop.arrowTip,
        arrowLength: noArrow ? 0 : ARROW_LENGTH,
        kind: EdgePathKind.selfLoop,
      ),
      labelNormal: plan.labelNormal,
    );
  }

  double _nodeRadius(Node node) {
    final radius = node.size.shortestSide * 0.5;
    return radius.isFinite && radius > 0 ? radius : 48;
  }

  void _clearAutomaticRouteGeometry() {
    _automaticRouteGeometry.clear();
    _automaticRouteNodeStamps = <String, _NodeGeometryStamp>{};
    _automaticRouteEdgeSignature = 0;
    _automaticRouteRenderMode = null;
  }
}
