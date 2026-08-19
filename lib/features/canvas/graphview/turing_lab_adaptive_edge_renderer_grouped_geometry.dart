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
    final geometry = _preparedGeometryForEdge(edge)?.pathGeometry;
    if (geometry == null) {
      return null;
    }

    return _GroupedFsaRenderGeometry(
      geometry: geometry,
      laneOffset: laneOffset,
    );
  }

  _GroupedFsaRenderGeometry? _buildGroupedSelfLoopGeometry(
    Edge edge,
    List<Edge> groupedEdges,
  ) {
    final geometry = _preparedGeometryForEdge(edge)?.pathGeometry;
    if (geometry == null) {
      return null;
    }
    return _GroupedFsaRenderGeometry(
      geometry: geometry,
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
