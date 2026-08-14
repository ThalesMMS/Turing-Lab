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
    final group = _groupedEdges(edge);
    if (group.isEmpty || !identical(group.first, edge)) {
      return;
    }

    final geometry = buildEdgeGeometry(
      edge,
      arrowLength: noArrow ? 0.0 : ARROW_LENGTH,
    );
    if (geometry == null) {
      return;
    }

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

    final bounds = geometry.path.getBounds();
    final anchor = Offset(bounds.center.dx, bounds.top - _loopLabelOffset);

    var previousTopFromAnchor = 0.0;
    for (var i = 0; i < group.length; i++) {
      final loopEdge = group[i];
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
        double centerFromAnchor;
        if (i == 0) {
          centerFromAnchor = 0.0;
          previousTopFromAnchor = textPainter.height / 2;
        } else {
          centerFromAnchor =
              previousTopFromAnchor + 2.0 + textPainter.height / 2;
          previousTopFromAnchor = centerFromAnchor + textPainter.height / 2;
        }

        final drawOffset = Offset(
          anchor.dx - textPainter.width / 2,
          anchor.dy - centerFromAnchor - textPainter.height / 2,
        );
        textPainter.paint(canvas, drawOffset);
      } finally {
        _releaseLabelPainter(textPainter);
      }
    }
  }
}
