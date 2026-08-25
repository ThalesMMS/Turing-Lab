part of 'turing_lab_adaptive_edge_renderer.dart';

extension _TuringLabAdaptiveEdgeRendererGroupedRendering
    on TuringLabAdaptiveEdgeRenderer {
  void _renderGroupedFsaEdge(Canvas canvas, Edge edge) {
    final groupedEdges = _groupedEdges(edge);
    if (groupedEdges.isEmpty || !identical(groupedEdges.first, edge)) {
      return;
    }

    final anyHighlighted = groupedEdges.any(
      (candidate) => _isHighlighted(_edgeId(candidate)),
    );
    final anySelected = groupedEdges.any(
      (candidate) => _isSelected(_edgeId(candidate)),
    );

    final groupedGeometry = edge.source == edge.destination
        ? _buildGroupedSelfLoopGeometry(edge, groupedEdges)
        : _buildGroupedNormalGeometry(edge);
    if (groupedGeometry == null) {
      return;
    }

    final strokePaint = _buildStrokePaint(
      highlighted: anyHighlighted,
      selected: anySelected,
    );

    paintEdgeGeometry(
      canvas,
      edge,
      strokePaint,
      _dashGeometryForEpsilonEdges(groupedGeometry.geometry, groupedEdges),
    );

    if (!noArrow) {
      paintEdgeArrow(
        canvas,
        edge,
        _buildFillPaint(highlighted: anyHighlighted),
        groupedGeometry.geometry,
      );
    }

    if (anyHighlighted) {
      renderAnimatedParticlesOnPath(
        canvas,
        edge,
        _buildFillPaint(highlighted: true),
        groupedGeometry.geometry.path,
      );
    }

    final labeledEdges = groupedEdges
        .where((candidate) => (candidate.label ?? '').trim().isNotEmpty)
        .toList(growable: false);
    if (labeledEdges.isEmpty) {
      return;
    }

    _paintGroupedEdgeLabels(
      canvas,
      edge,
      groupedGeometry,
      labeledEdges,
      anyHighlighted: anyHighlighted,
      anySelected: anySelected,
    );
  }

  void _renderSelfLoopCluster(Canvas canvas, Edge edge) {
    final group = <Edge>[edge];

    final renderGeometry = _preparedGeometryForEdge(edge);
    if (renderGeometry == null) {
      return;
    }
    final geometry = renderGeometry.pathGeometry;

    final anyHighlighted = group.any(
      (candidate) => _isHighlighted(_edgeId(candidate)),
    );
    final anySelected = group.any(
      (candidate) => _isSelected(_edgeId(candidate)),
    );
    final strokePaint = _buildStrokePaint(
      highlighted: anyHighlighted,
      selected: anySelected,
    );

    paintEdgeGeometry(
      canvas,
      edge,
      strokePaint,
      _dashGeometryForEpsilonEdges(geometry, group),
    );

    if (!noArrow) {
      paintEdgeArrow(
        canvas,
        edge,
        _buildFillPaint(highlighted: anyHighlighted),
        geometry,
      );
    }

    if (anyHighlighted) {
      renderAnimatedParticlesOnPath(
        canvas,
        edge,
        _buildFillPaint(highlighted: true),
        geometry.path,
      );
    }

    // Labels stack outwards along the loop's own heading, so they stay clear
    // of the state wherever the loop settled on its border.
    final bounds = geometry.path.getBounds();
    var normal = renderGeometry.labelNormal;
    if (normal.distanceSquared < 0.0001) {
      normal = const Offset(0, -1);
    }
    final anchor = bounds.center +
        normal * (_projectedHalfExtent(normal, bounds.size) + _loopLabelOffset);

    var reach = 0.0;
    for (final loopEdge in group) {
      if ((loopEdge.label ?? '').isEmpty) {
        continue;
      }

      final isHighlighted = _isHighlighted(_edgeId(loopEdge));
      final textPainter = _buildLabelPainter(
        loopEdge,
        selectedOverride: false,
        highlightedOverride: isHighlighted,
      );
      try {
        final halfExtent = _projectedHalfExtent(
          normal,
          Size(textPainter.width, textPainter.height),
        );
        final center = anchor + normal * (reach + halfExtent);
        reach += (halfExtent * 2) + 2.0;
        textPainter.paint(
          canvas,
          Offset(
            center.dx - (textPainter.width / 2),
            center.dy - (textPainter.height / 2),
          ),
        );
      } finally {
        _releaseLabelPainter(textPainter);
      }
    }
  }

  double _projectedHalfExtent(Offset normal, Size size) =>
      ((normal.dx.abs() * size.width) + (normal.dy.abs() * size.height)) / 2;
}
