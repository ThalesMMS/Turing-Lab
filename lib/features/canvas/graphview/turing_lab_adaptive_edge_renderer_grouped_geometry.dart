part of 'turing_lab_adaptive_edge_renderer.dart';

extension _TuringLabAdaptiveEdgeRendererGroupedGeometry
    on TuringLabAdaptiveEdgeRenderer {
  List<Edge> _groupedEdges(Edge edge) {
    _ensureEdgeCaches();
    return _groupedEdgeCache[_pairForEdge(edge)] ?? <Edge>[edge];
  }

  Edge _groupRepresentative(Edge edge) {
    final grouped = _groupedEdges(edge);
    return grouped.first;
  }

  _GroupedFsaRenderGeometry? _buildGroupedNormalGeometry(Edge edge) {
    final hasOpposingTraffic = _hasOpposingTraffic(edge);
    final laneOffset = _laneOffsetForDirectedPair(
      edge,
      hasOpposingTraffic: hasOpposingTraffic,
    );
    final manualControlPoint = turingLabEdgeControlPoint(edge);
    if (manualControlPoint != null) {
      final sourcePoint = calculateSourceConnectionPoint(
        edge,
        manualControlPoint,
        0,
      );
      final destinationPoint = calculateDestinationConnectionPoint(
        edge,
        manualControlPoint,
        0,
      );
      final path = Path()
        ..moveTo(sourcePoint.dx, sourcePoint.dy)
        ..quadraticBezierTo(
          manualControlPoint.dx,
          manualControlPoint.dy,
          destinationPoint.dx,
          destinationPoint.dy,
        );
      return _GroupedFsaRenderGeometry(
        geometry: buildPathGeometry(
          path,
          arrowLength: noArrow ? 0.0 : ARROW_LENGTH,
        ),
        laneOffset: laneOffset,
      );
    }

    final sourceCenter = getNodeCenter(edge.source);
    final destinationCenter = getNodeCenter(edge.destination);
    final controlPoint = resolveGroupedFsaControlPoint(
      fromId: _nodeId(edge.source),
      toId: _nodeId(edge.destination),
      fromCenter: sourceCenter,
      toCenter: destinationCenter,
      hasOpposingTraffic: hasOpposingTraffic,
      spacing: _groupLaneSpacing,
    );
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

    return _GroupedFsaRenderGeometry(
      geometry: buildPathGeometry(
        path,
        arrowLength: noArrow ? 0.0 : ARROW_LENGTH,
      ),
      laneOffset: laneOffset,
    );
  }

  _GroupedFsaRenderGeometry? _buildGroupedSelfLoopGeometry(
    Edge edge,
    List<Edge> groupedEdges,
  ) {
    final loopPadding =
        16.0 + resolveGroupedFsaLoopExtraOffset(groupedEdges.length);
    final loopResult = buildSelfLoopPath(
      edge,
      loopPadding: loopPadding,
      arrowLength: noArrow ? 0.0 : ARROW_LENGTH,
    );
    if (loopResult == null) {
      return null;
    }

    final geometry = buildPathGeometry(
      loopResult.path,
      arrowLength: noArrow ? 0.0 : ARROW_LENGTH,
      isSelfLoop: true,
    );
    return _GroupedFsaRenderGeometry(
      geometry: EdgePathGeometry(
        path: geometry.path,
        start: geometry.start,
        end: geometry.end,
        arrowBase: loopResult.arrowBase,
        arrowTip: loopResult.arrowTip,
        isSelfLoop: true,
      ),
      laneOffset: 0.0,
    );
  }

  _GroupedFsaRenderGeometry? _representativeGroupedGeometry(Edge edge) {
    final representative = _groupRepresentative(edge);
    final finalGrouped = _groupedEdges(representative);
    return representative.source == representative.destination
        ? _buildGroupedSelfLoopGeometry(representative, finalGrouped)
        : _buildGroupedNormalGeometry(representative);
  }

  bool _hasOpposingTraffic(Edge edge) {
    _ensureEdgeCaches();
    return _opposingTrafficCache.contains(_pairForEdge(edge));
  }

  double _laneOffsetForDirectedPair(Edge edge, {bool? hasOpposingTraffic}) {
    return resolveGroupedFsaLaneOffset(
      fromId: _nodeId(edge.source),
      toId: _nodeId(edge.destination),
      hasOpposingTraffic: hasOpposingTraffic ?? _hasOpposingTraffic(edge),
      spacing: _groupLaneSpacing,
    );
  }
}
