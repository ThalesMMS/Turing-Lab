part of 'turing_lab_adaptive_edge_renderer.dart';

extension _TuringLabAdaptiveEdgeRendererCache on TuringLabAdaptiveEdgeRenderer {
  String _nodeId(Node node) {
    final key = node.key;
    if (key is ValueKey) {
      return key.value.toString();
    }
    return node.hashCode.toString();
  }

  String _edgeLabel(Edge edge) => (edge.label ?? '').trim();

  double get _continuousAnimationValue => _animationTurnCount + animationValue;

  String _edgeId(Edge edge) {
    final key = edge.key;
    if (key is ValueKey) {
      return key.value.toString();
    }
    return edge.hashCode.toString();
  }

  bool _isHighlighted(String edgeId) => _highlightedEdgeIds.contains(edgeId);

  bool _isSelected(String edgeId) => _selectedEdgeIds.contains(edgeId);

  Paint _buildStrokePaint({required bool highlighted, required bool selected}) {
    return Paint()
      ..color = _colorFor(highlighted: highlighted)
      ..style = PaintingStyle.stroke
      ..strokeWidth = selected ? _selectedStrokeWidth : _normalStrokeWidth
      ..strokeCap = StrokeCap.round;
  }

  Paint _buildFillPaint({required bool highlighted}) {
    return Paint()
      ..color = _colorFor(highlighted: highlighted)
      ..style = PaintingStyle.fill;
  }

  Color _colorFor({required bool highlighted}) {
    return highlighted ? highlightColor : baseColor;
  }

  void _ensureEdgeCaches() {
    final currentGraph = graph;
    if (currentGraph == null) {
      _clearEdgeCaches();
      return;
    }

    if (_edgeCachesDirty ||
        _edgeCacheGraph != currentGraph ||
        _edgeCacheCount != currentGraph.edges.length) {
      _rebuildEdgeCaches();
    }
  }

  void _rebuildEdgeCaches() {
    final currentGraph = graph;
    if (currentGraph == null) {
      _clearEdgeCaches();
      return;
    }

    _groupedEdgeCache.clear();
    _opposingTrafficCache.clear();

    for (final edge in currentGraph.edges) {
      _groupedEdgeCache
          .putIfAbsent(_pairForEdge(edge), () => <Edge>[])
          .add(edge);
    }

    for (final edges in _groupedEdgeCache.values) {
      edges.sort((left, right) {
        final labelCompare = _edgeLabel(left).compareTo(_edgeLabel(right));
        if (labelCompare != 0) {
          return labelCompare;
        }
        return _edgeId(left).compareTo(_edgeId(right));
      });
    }

    for (final pair in _groupedEdgeCache.keys) {
      if (_groupedEdgeCache.containsKey(pair.reversed)) {
        _opposingTrafficCache.add(pair);
      }
    }

    _edgeCacheGraph = currentGraph;
    _edgeCacheCount = currentGraph.edges.length;
    _edgeCachesDirty = false;
  }

  void _invalidateEdgeCaches() {
    _edgeCachesDirty = true;
    _clearEdgeCaches();
  }

  void _clearEdgeCaches() {
    _groupedEdgeCache.clear();
    _opposingTrafficCache.clear();
    _edgeCacheGraph = null;
    _edgeCacheCount = -1;
  }

  void _clearLabelPainterCache() {
    for (final painter in _labelPainterCache.values) {
      _activeLabelPainters.remove(painter);
      _usedLabelPaintersInRenderCycle.remove(painter);
      _transientLabelPainters.remove(painter);
      painter.dispose();
    }
    _labelPainterCache.clear();
  }

  _DirectedEdgePair _pairForEdge(Edge edge) => _DirectedEdgePair(
        sourceId: _nodeId(edge.source),
        destinationId: _nodeId(edge.destination),
      );
}
