part of 'turing_lab_adaptive_edge_renderer.dart';

extension _TuringLabAdaptiveEdgeRendererLabelLayout
    on TuringLabAdaptiveEdgeRenderer {
  void _ensureGroupedLabelRects() {
    if (renderMode != TuringLabEdgeRenderMode.groupedFsa ||
        _automaticRouteGeometry.isEmpty) {
      return;
    }

    _ensureEdgeCaches();
    for (final groupedEdges in _groupedEdgeCache.values) {
      if (groupedEdges.isEmpty) {
        continue;
      }
      final representative = groupedEdges.first;
      final geometry = _automaticRouteGeometry[representative];
      if (geometry == null || geometry.labelRect != null) {
        continue;
      }
      final labeledEdges = groupedEdges
          .where((candidate) => (candidate.label ?? '').trim().isNotEmpty)
          .toList(growable: false);
      if (labeledEdges.isEmpty) {
        continue;
      }
      final groupedGeometry =
          representative.source == representative.destination
              ? _buildGroupedSelfLoopGeometry(representative, groupedEdges)
              : _buildGroupedNormalGeometry(representative);
      if (groupedGeometry == null) {
        continue;
      }
      final labelEntries = labeledEdges
          .map(
            (edge) => _GroupedLabelEntry(painter: _buildLabelPainter(edge)),
          )
          .toList(growable: false);
      try {
        final labelRect = _resolveGroupedLabelRect(
          representative,
          groupedGeometry,
          labelEntries,
        );
        for (final member in groupedEdges) {
          final memberGeometry = _automaticRouteGeometry[member];
          if (memberGeometry != null) {
            _automaticRouteGeometry[member] =
                memberGeometry.withLabelRect(labelRect);
          }
        }
      } finally {
        _releaseLabelEntries(labelEntries);
      }
    }
  }

  void _clearGroupedLabelRects() {
    for (final edge in _automaticRouteGeometry.keys.toList(growable: false)) {
      _automaticRouteGeometry[edge] =
          _automaticRouteGeometry[edge]!.withLabelRect(null);
    }
  }

  void _paintGroupedEdgeLabels(
    Canvas canvas,
    Edge edge,
    _GroupedFsaRenderGeometry groupedGeometry,
    List<Edge> groupedEdges, {
    required bool anyHighlighted,
    required bool anySelected,
  }) {
    final labelEntries = groupedEdges
        .map((edge) => _GroupedLabelEntry(painter: _buildLabelPainter(edge)))
        .toList(growable: false);
    try {
      final maxVisible = math.min(
        _maxVisibleGroupedLabels,
        labelEntries.length,
      );
      final totalHeight = _sumLabelHeights(labelEntries);
      final visibleHeight = _sumLabelHeights(labelEntries.take(maxVisible));
      final cardRect = _automaticRouteGeometry[edge]?.labelRect ??
          _resolveGroupedLabelRect(edge, groupedGeometry, labelEntries);
      _paintLabelCard(
        canvas,
        rect: cardRect,
        entries: labelEntries,
        highlighted: anyHighlighted,
        selected: anySelected,
        paintEntries: false,
      );

      final overflowHeight = math.max(0.0, totalHeight - visibleHeight);
      final cycleDistance = overflowHeight + _labelScrollGap;
      final scrollOffset =
          labelEntries.length > _maxVisibleGroupedLabels && cycleDistance > 0
              ? (_continuousAnimationValue * _labelScrollPixelsPerTurn) %
                  cycleDistance
              : 0.0;

      canvas.save();
      canvas.clipRect(
        Rect.fromLTWH(
          cardRect.left + 1,
          cardRect.top + 1,
          cardRect.width - 2,
          cardRect.height - 2,
        ),
      );

      final contentLeft = cardRect.left + _labelPaddingHorizontal;
      final contentTop = cardRect.top + _labelPaddingVertical - scrollOffset;
      _paintLabelColumn(canvas, labelEntries, contentLeft, contentTop);
      if (scrollOffset > 0) {
        _paintLabelColumn(
          canvas,
          labelEntries,
          contentLeft,
          contentTop + totalHeight + _labelScrollGap,
        );
      }
      canvas.restore();
    } finally {
      _releaseLabelEntries(labelEntries);
    }
  }

  void _paintLabelCard(
    Canvas canvas, {
    required Rect rect,
    required List<_GroupedLabelEntry> entries,
    required bool highlighted,
    required bool selected,
    bool paintEntries = true,
  }) {
    final borderColor = _colorFor(highlighted: highlighted).withValues(
      alpha: highlighted || selected ? 0.55 : 0.22,
    );
    final card = RRect.fromRectAndRadius(rect, const Radius.circular(12));
    canvas.drawShadow(
      Path()..addRRect(card),
      Colors.black.withValues(alpha: 0.16),
      4,
      false,
    );
    canvas.drawRRect(
      card,
      Paint()
        ..color = labelSurfaceColor.withValues(alpha: 0.96)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      card,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    if (paintEntries) {
      _paintLabelColumn(
        canvas,
        entries,
        rect.left + _labelPaddingHorizontal,
        rect.top + _labelPaddingVertical,
      );
    }
  }

  void _ensureStandardLabelRects() {
    if (renderMode != TuringLabEdgeRenderMode.standard ||
        _automaticRouteGeometry.isEmpty) {
      return;
    }

    final placedRects = <Rect>[
      for (final geometry in _automaticRouteGeometry.values)
        if (geometry.labelRect != null) geometry.labelRect!,
    ];
    final edges = _automaticRouteGeometry.keys.toList(growable: false)
      ..sort((left, right) => _edgeId(left).compareTo(_edgeId(right)));
    for (final edge in edges) {
      final geometry = _automaticRouteGeometry[edge];
      if (geometry == null ||
          geometry.labelRect != null ||
          (edge.label ?? '').trim().isEmpty) {
        continue;
      }

      final labelEntries = <_GroupedLabelEntry>[
        _GroupedLabelEntry(painter: _buildLabelPainter(edge)),
      ];
      try {
        final (:width, :height) = _computeCardSize(labelEntries);
        var normal = geometry.labelNormal;
        if (!normal.dx.isFinite ||
            !normal.dy.isFinite ||
            normal.distanceSquared < 0.0001) {
          normal = const Offset(0, -1);
        } else {
          normal /= normal.distance;
        }
        final anchor = geometry.pathGeometry.pointAt(0.5);
        final baseRect = Rect.fromCenter(
          center: anchor + normal * (_labelPathGap + height / 2),
          width: width,
          height: height,
        );
        final labelRect = _resolveStandardLabelRect(
          baseRect,
          normal,
          anchor,
          edge,
          geometry,
          placedRects,
        );
        _automaticRouteGeometry[edge] = geometry.withLabelRect(labelRect);
        placedRects.add(labelRect);
      } finally {
        _releaseLabelEntries(labelEntries);
      }
    }
  }

  Rect _resolveStandardLabelRect(
    Rect baseRect,
    Offset normal,
    Offset pathAnchor,
    Edge edge,
    TuringLabEdgeRenderGeometry geometry,
    List<Rect> placedRects,
  ) {
    var resolved = baseRect;
    for (var attempt = 0; attempt < _labelCollisionAttempts; attempt++) {
      if (!_standardLabelRectCollides(
        resolved,
        pathAnchor,
        edge,
        geometry,
        placedRects,
      )) {
        return resolved;
      }
      resolved = resolved.shift(
        normal * (_labelCollisionStep + attempt * 4.0),
      );
    }
    return resolved;
  }

  bool _standardLabelRectCollides(
    Rect rect,
    Offset pathAnchor,
    Edge edge,
    TuringLabEdgeRenderGeometry geometry,
    List<Rect> placedRects,
  ) {
    final arrowBounds = Rect.fromPoints(
      geometry.pathGeometry.arrowBase,
      geometry.pathGeometry.arrowTip,
    ).inflate(ARROW_LENGTH);
    if (rect.overlaps(arrowBounds) ||
        placedRects.any(
          (placed) => rect.inflate(_labelCardSpacing).overlaps(placed),
        )) {
      return true;
    }
    final viewport = _viewportWorldBounds?.deflate(12);
    if (viewport != null &&
        viewport.contains(pathAnchor) &&
        (!viewport.contains(rect.topLeft) ||
            !viewport.contains(rect.bottomRight))) {
      return true;
    }
    return _labelRectCollides(
      rect,
      geometry.pathGeometry.path,
      edge,
      null,
    );
  }

  TextPainter _buildLabelPainter(
    Edge edge, {
    bool? highlightedOverride,
    bool? selectedOverride,
  }) {
    final edgeId = _edgeId(edge);
    return _buildLabelPainterForText(
      text: edge.label ?? '',
      highlighted: highlightedOverride ?? _isHighlighted(edgeId),
      selected: selectedOverride ?? _isSelected(edgeId),
    );
  }

  TextPainter _buildLabelPainterForText({
    required String text,
    required bool highlighted,
    required bool selected,
  }) {
    final style = TextStyle(
      color: _colorFor(highlighted: highlighted),
      fontSize: labelFontSize,
      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
    );
    final cacheKey = _LabelPainterCacheKey(text: text, style: style);
    final cached = _labelPainterCache.remove(cacheKey);
    if (cached != null) {
      _labelPainterCache[cacheKey] = cached;
      _activeLabelPainters.add(cached);
      _usedLabelPaintersInRenderCycle.add(cached);
      return cached;
    }

    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();

    _activeLabelPainters.add(painter);
    _usedLabelPaintersInRenderCycle.add(painter);
    _labelPainterCache[cacheKey] = painter;
    while (_labelPainterCache.length > _maxCachedLabelPainters) {
      _LabelPainterCacheKey? evictableKey;
      for (final candidateKey in _labelPainterCache.keys) {
        final candidatePainter = _labelPainterCache[candidateKey];
        if (candidatePainter != null &&
            !_activeLabelPainters.contains(candidatePainter)) {
          evictableKey = candidateKey;
          break;
        }
      }

      if (evictableKey == null) {
        final transientPainter = _labelPainterCache.remove(cacheKey);
        if (transientPainter != null) {
          _transientLabelPainters.add(transientPainter);
        }
        break;
      }

      final evicted = _labelPainterCache.remove(evictableKey);
      evicted?.dispose();
    }
    return painter;
  }

  void _releaseLabelPainter(TextPainter painter) {
    _activeLabelPainters.remove(painter);
    if (_transientLabelPainters.remove(painter)) {
      _usedLabelPaintersInRenderCycle.remove(painter);
      painter.dispose();
    }
  }

  void _pruneCachedLabelPainters() {
    if (_labelPainterCache.isEmpty) {
      return;
    }

    final keysToRemove = <_LabelPainterCacheKey>[];
    for (final entry in _labelPainterCache.entries) {
      final painter = entry.value;
      if (!_activeLabelPainters.contains(painter) &&
          !_usedLabelPaintersInRenderCycle.contains(painter)) {
        keysToRemove.add(entry.key);
      }
    }

    for (final key in keysToRemove) {
      final painter = _labelPainterCache.remove(key);
      painter?.dispose();
    }
  }

  void _releaseLabelEntries(List<_GroupedLabelEntry> entries) {
    for (final entry in entries) {
      _releaseLabelPainter(entry.painter);
    }
  }

  double _sumLabelHeights(Iterable<_GroupedLabelEntry> entries) {
    var totalHeight = 0.0;
    var isFirst = true;
    for (final entry in entries) {
      if (!isFirst) totalHeight += _labelLineSpacing;
      totalHeight += entry.painter.height;
      isFirst = false;
    }
    return totalHeight;
  }

  void _paintLabelColumn(
    Canvas canvas,
    List<_GroupedLabelEntry> entries,
    double left,
    double top,
  ) {
    var y = top;
    for (final entry in entries) {
      entry.painter.paint(canvas, Offset(left, y));
      y += entry.painter.height + _labelLineSpacing;
    }
  }

  ({double width, double height}) _computeCardSize(
    List<_GroupedLabelEntry> labelEntries,
  ) {
    final maxVisible = math.min(_maxVisibleGroupedLabels, labelEntries.length);
    final maxWidth = labelEntries.fold<double>(
      0.0,
      (current, entry) => math.max(current, entry.painter.width),
    );
    final visibleHeight = _sumLabelHeights(labelEntries.take(maxVisible));
    return (
      width: maxWidth + (_labelPaddingHorizontal * 2),
      height: visibleHeight + (_labelPaddingVertical * 2),
    );
  }

  Rect _resolveGroupedLabelRect(
    Edge edge,
    _GroupedFsaRenderGeometry groupedGeometry,
    List<_GroupedLabelEntry> labelEntries,
  ) {
    final (:width, :height) = _computeCardSize(labelEntries);

    return groupedGeometry.geometry.isSelfLoop
        ? _resolveSelfLoopLabelRect(
            edge,
            groupedGeometry.geometry,
            width,
            height,
          )
        : _resolveNormalLabelRect(edge, groupedGeometry, width, height);
  }

  Rect _resolveNormalLabelRect(
    Edge edge,
    _GroupedFsaRenderGeometry groupedGeometry,
    double cardWidth,
    double cardHeight,
  ) {
    final metric = groupedGeometry.geometry.path.computeMetrics().firstOrNull;
    final anchor = metric?.getTangentForOffset(metric.length * 0.5)?.position ??
        groupedGeometry.geometry.path.getBounds().center;
    final sourceCenter = getNodeCenter(edge.source);
    final destinationCenter = getNodeCenter(edge.destination);
    final normal = resolveGroupedFsaLabelNormal(
      fromId: _nodeId(edge.source),
      toId: _nodeId(edge.destination),
      fromCenter: sourceCenter,
      toCenter: destinationCenter,
      laneOffset: groupedGeometry.laneOffset,
    );
    final baseRect = Rect.fromCenter(
      center: anchor + (normal * (_labelPathGap + (cardHeight / 2))),
      width: cardWidth,
      height: cardHeight,
    );
    final opposingRect = _buildOpposingBaseLabelRect(edge);
    return _resolveLabelRectCollision(
      baseRect,
      normal,
      groupedGeometry.geometry.path,
      edge,
      opposingRect,
    );
  }

  Rect _resolveSelfLoopLabelRect(
    Edge edge,
    EdgePathGeometry geometry,
    double cardWidth,
    double cardHeight,
  ) {
    final metric = geometry.path.computeMetrics().firstOrNull;
    final nodeCenter = getNodeCenter(edge.source);
    final anchorOffset =
        metric != null ? math.min(metric.length * 0.42, metric.length) : 0.0;
    final anchor = metric?.getTangentForOffset(anchorOffset)?.position ??
        geometry.path.getBounds().topRight;

    var radial = anchor - nodeCenter;
    if (radial.distanceSquared < 0.0001) {
      radial = const Offset(1, -1);
    }
    radial = radial / radial.distance;

    final projectedHalfExtent = (radial.dx.abs() * (cardWidth / 2)) +
        (radial.dy.abs() * (cardHeight / 2));

    var rect = Rect.fromCenter(
      center: anchor + (radial * (projectedHalfExtent + _groupedLoopLabelGap)),
      width: cardWidth,
      height: cardHeight,
    );

    for (var attempt = 0; attempt < _labelCollisionAttempts; attempt++) {
      if (!_labelRectCollides(rect, geometry.path, edge, null)) {
        return rect;
      }
      rect = rect.shift(radial * (_labelCollisionStep + (attempt * 4.0)));
    }

    return rect;
  }

  Rect? _buildOpposingBaseLabelRect(Edge edge) {
    final currentGraph = graph;
    if (currentGraph == null || edge.source == edge.destination) {
      return null;
    }

    final opposingGroup = _groupedEdgeCache[_DirectedEdgePair(
          sourceId: _nodeId(edge.destination),
          destinationId: _nodeId(edge.source),
        )] ??
        const <Edge>[];
    if (opposingGroup.isEmpty) {
      return null;
    }

    final opposingRepresentative = opposingGroup.first;
    final labeledEdges = opposingGroup
        .where((candidate) => (candidate.label ?? '').trim().isNotEmpty)
        .toList(growable: false);
    if (labeledEdges.isEmpty) {
      return null;
    }

    final groupedGeometry = _buildGroupedNormalGeometry(opposingRepresentative);
    if (groupedGeometry == null) {
      return null;
    }

    final labelEntries = labeledEdges
        .map(
          (groupedEdge) =>
              _GroupedLabelEntry(painter: _buildLabelPainter(groupedEdge)),
        )
        .toList(growable: false);
    try {
      final (:width, :height) = _computeCardSize(labelEntries);
      final metric = groupedGeometry.geometry.path.computeMetrics().firstOrNull;
      final anchor =
          metric?.getTangentForOffset(metric.length * 0.5)?.position ??
              groupedGeometry.geometry.path.getBounds().center;
      final normal = resolveGroupedFsaLabelNormal(
        fromId: _nodeId(opposingRepresentative.source),
        toId: _nodeId(opposingRepresentative.destination),
        fromCenter: getNodeCenter(opposingRepresentative.source),
        toCenter: getNodeCenter(opposingRepresentative.destination),
        laneOffset: groupedGeometry.laneOffset,
      );
      return Rect.fromCenter(
        center: anchor + (normal * (_labelPathGap + (height / 2))),
        width: width,
        height: height,
      );
    } finally {
      _releaseLabelEntries(labelEntries);
    }
  }

  Rect _resolveLabelRectCollision(
    Rect rect,
    Offset normal,
    Path path,
    Edge edge,
    Rect? opposingRect,
  ) {
    var resolved = rect;
    for (var attempt = 0; attempt < _labelCollisionAttempts; attempt++) {
      if (!_labelRectCollides(resolved, path, edge, opposingRect)) {
        return resolved;
      }
      resolved = resolved.shift(
        normal * (_labelCollisionStep + (attempt * 4.0)),
      );
    }
    return resolved;
  }

  bool _labelRectCollides(Rect rect, Path path, Edge edge, Rect? opposingRect) {
    if (opposingRect != null &&
        rect.inflate(_labelCardSpacing).overlaps(opposingRect)) {
      return true;
    }
    if (_rectTooCloseToNode(rect, edge.source) ||
        _rectTooCloseToNode(rect, edge.destination)) {
      return true;
    }
    return _rectTooCloseToPath(rect, path);
  }

  bool _rectTooCloseToNode(Rect rect, Node node) {
    final nodeRect = Rect.fromLTWH(
      node.position.dx,
      node.position.dy,
      node.width,
      node.height,
    );
    return rect.inflate(_labelNodeClearance).overlaps(nodeRect);
  }

  bool _rectTooCloseToPath(Rect rect, Path path) {
    final metric = path.computeMetrics().firstOrNull;
    if (metric == null) {
      return false;
    }

    final probe = rect.inflate(_labelPathClearance);
    const samples = 24;
    for (var index = 0; index <= samples; index++) {
      final tangent = metric.getTangentForOffset(
        metric.length * (index / samples),
      );
      if (tangent != null && probe.contains(tangent.position)) {
        return true;
      }
    }
    return false;
  }
}
