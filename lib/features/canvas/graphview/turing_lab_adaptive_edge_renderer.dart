import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:graphview/graphview_turing_lab.dart';

import 'automatic_transition_route_planner.dart';
import 'grouped_fsa_geometry.dart';

part 'turing_lab_adaptive_edge_renderer_compat.dart';
part 'turing_lab_adaptive_edge_renderer_grouped_rendering.dart';
part 'turing_lab_adaptive_edge_renderer_grouped_geometry.dart';
part 'turing_lab_adaptive_edge_renderer_label_layout.dart';
part 'turing_lab_adaptive_edge_renderer_cache.dart';
part 'turing_lab_adaptive_edge_renderer_models.dart';
part 'turing_lab_adaptive_edge_renderer_route_layout.dart';

enum TuringLabEdgeRenderMode { standard, groupedFsa }

const double _selectedStrokeWidth = 4.0;
const double _normalStrokeWidth = 2.0;
const double _loopLabelOffset = 10.0;
const double _groupLaneSpacing = 34.0;
const double _labelPaddingHorizontal = 10.0;
const double _labelPaddingVertical = 8.0;
const double _labelLineSpacing = 4.0;
const double _labelPathGap = 14.0;
const double _groupedLoopLabelGap = 6.0;
const double _labelScrollGap = 14.0;
const double _labelScrollPixelsPerTurn = 8.0;
const double _labelCollisionStep = 14.0;
const double _labelPathClearance = 10.0;
const double _labelNodeClearance = 12.0;
const double _labelCardSpacing = 12.0;
const double _epsilonDashLength = 8.0;
const double _epsilonDashGap = 4.0;
const int _maxVisibleGroupedLabels = 5;
const int _labelCollisionAttempts = 6;
const int _maxCachedLabelPainters = 200;

bool _isEpsilonEdge(Edge edge) {
  final label = (edge.label ?? '').trim().toLowerCase();
  return label == 'ε' ||
      label == 'λ' ||
      label == 'epsilon' ||
      label == 'lambda';
}

EdgePathGeometry _dashGeometryForEpsilonEdges(
  EdgePathGeometry geometry,
  Iterable<Edge> edges,
) {
  if (!edges.any(_isEpsilonEdge)) {
    return geometry;
  }

  return geometry.withPath(_createDashedPath(geometry.path));
}

Path _createDashedPath(Path source) {
  final dashedPath = Path();

  for (final metric in source.computeMetrics()) {
    var distance = 0.0;
    while (distance < metric.length) {
      final end = math.min(distance + _epsilonDashLength, metric.length);
      if (end > distance) {
        dashedPath.addPath(metric.extractPath(distance, end), Offset.zero);
      }
      distance = end + _epsilonDashGap;
    }
  }

  return dashedPath;
}

/// Thin Turing Lab-specific edge renderer layered on top of GraphView's adaptive
/// routing and animation primitives.
class TuringLabAdaptiveEdgeRenderer extends AnimatedAdaptiveEdgeRenderer {
  TuringLabAdaptiveEdgeRenderer({
    required super.config,
    super.animationConfig,
    this.baseColor = Colors.black,
    this.highlightColor = Colors.blue,
    this.labelSurfaceColor = Colors.white,
    this.labelFontSize = 14.0,
    this.renderMode = TuringLabEdgeRenderMode.standard,
  });

  Set<String> _highlightedEdgeIds = const <String>{};
  Set<String> _selectedEdgeIds = const <String>{};
  double _animationTurnCount = 0.0;
  double _lastAnimationValue = 0.0;
  final Map<_DirectedEdgePair, List<Edge>> _groupedEdgeCache =
      <_DirectedEdgePair, List<Edge>>{};
  final Set<_DirectedEdgePair> _opposingTrafficCache = <_DirectedEdgePair>{};
  final LinkedHashMap<_LabelPainterCacheKey, TextPainter> _labelPainterCache =
      LinkedHashMap<_LabelPainterCacheKey, TextPainter>();
  final Set<TextPainter> _activeLabelPainters = HashSet<TextPainter>.identity();
  final Set<TextPainter> _usedLabelPaintersInRenderCycle =
      HashSet<TextPainter>.identity();
  final Set<TextPainter> _transientLabelPainters =
      HashSet<TextPainter>.identity();
  Graph? _edgeCacheGraph;
  int _edgeCacheCount = -1;
  bool _edgeCachesDirty = true;
  final AutomaticTransitionRoutePlanner _routePlanner =
      const AutomaticTransitionRoutePlanner();
  final Map<Edge, TuringLabEdgeRenderGeometry> _automaticRouteGeometry =
      <Edge, TuringLabEdgeRenderGeometry>{};
  Map<String, _NodeGeometryStamp> _automaticRouteNodeStamps =
      <String, _NodeGeometryStamp>{};
  Graph? _automaticRouteGraph;
  int _automaticRouteGeneration = -1;
  int _automaticRouteEdgeSignature = 0;
  TuringLabEdgeRenderMode? _automaticRouteRenderMode;
  Rect? _viewportWorldBounds;

  Color baseColor;
  Color highlightColor;
  Color labelSurfaceColor;
  double labelFontSize;
  TuringLabEdgeRenderMode renderMode;

  @override
  void setGraph(Graph graph) {
    if (identical(graph, this.graph)) {
      return;
    }
    super.setGraph(graph);
    _invalidateEdgeCaches();
    invalidatePathGeometryCache();
    _clearAutomaticRouteGeometry();
  }

  @override
  void setAnimationValue(double value) {
    if (value + 0.05 < _lastAnimationValue) {
      _animationTurnCount += 1.0;
    }
    _lastAnimationValue = value;
    super.setAnimationValue(value);
  }

  void updateAppearance({
    required Set<String> highlightedEdgeIds,
    required Set<String> selectedEdgeIds,
    required Color baseColor,
    required Color highlightColor,
    required Color labelSurfaceColor,
  }) {
    final labelStyleChanged =
        this.baseColor != baseColor || this.highlightColor != highlightColor;
    final labelLayoutChanged = !setEquals(
      _selectedEdgeIds,
      selectedEdgeIds,
    );
    _highlightedEdgeIds = Set<String>.from(highlightedEdgeIds);
    _selectedEdgeIds = Set<String>.from(selectedEdgeIds);
    this.baseColor = baseColor;
    this.highlightColor = highlightColor;
    this.labelSurfaceColor = labelSurfaceColor;
    if (labelStyleChanged) {
      _clearLabelPainterCache();
    }
    if (labelLayoutChanged &&
        renderMode == TuringLabEdgeRenderMode.groupedFsa) {
      _clearGroupedLabelRects();
    }
  }

  @override
  void prepareForRenderCycle() {
    super.prepareForRenderCycle();
    _ensureEdgeCaches();
    _ensureAutomaticRouteGeometry();
    _ensureStandardLabelRects();
    _ensureGroupedLabelRects();
    _pruneCachedLabelPainters();
    _usedLabelPaintersInRenderCycle.clear();
  }

  void invalidateEdgeCaches() {
    _invalidateEdgeCaches();
    invalidatePathGeometryCache();
    _clearAutomaticRouteGeometry();
  }

  TuringLabEdgeRenderGeometry? geometryForEdge(Edge edge) {
    _ensureAutomaticRouteGeometry();
    _ensureStandardLabelRects();
    _ensureGroupedLabelRects();
    return _automaticRouteGeometry[edge];
  }

  TuringLabEdgeRenderGeometry? _preparedGeometryForEdge(Edge edge) {
    final prepared = _automaticRouteGeometry[edge];
    if (prepared != null) {
      return prepared;
    }
    return geometryForEdge(edge);
  }

  Offset _preparedRepulsionOffsetFor(Edge edge) =>
      preparedRepulsionOffsetFor(edge);

  void updateViewportWorldBounds(Rect? bounds) {
    if (_viewportWorldBounds == bounds) {
      return;
    }
    _viewportWorldBounds = bounds;
    if (renderMode != TuringLabEdgeRenderMode.standard) {
      return;
    }
    for (final edge in _automaticRouteGeometry.keys.toList(growable: false)) {
      _automaticRouteGeometry[edge] =
          _automaticRouteGeometry[edge]!.withLabelRect(null);
    }
  }

  @visibleForTesting
  Rect? debugLabelRectForEdge(Edge edge) => geometryForEdge(edge)?.labelRect;

  @visibleForTesting
  double debugLaneOffsetForEdge(Edge edge) => _laneOffsetForDirectedPair(edge);

  @visibleForTesting
  Path? debugGroupedPathForEdge(Edge edge) {
    if (renderMode != TuringLabEdgeRenderMode.groupedFsa) {
      return null;
    }
    return geometryForEdge(edge)?.pathGeometry.path;
  }

  @visibleForTesting
  Rect? debugGroupedLabelRectForEdge(Edge edge) {
    if (renderMode != TuringLabEdgeRenderMode.groupedFsa) {
      return null;
    }
    final representative = _groupRepresentative(edge);
    geometryForEdge(representative);
    final groupedGeometry = _representativeGroupedGeometry(representative);
    if (groupedGeometry == null) {
      return null;
    }
    final groupedEdges = _groupedEdges(representative)
        .where((candidate) => (candidate.label ?? '').trim().isNotEmpty)
        .toList(growable: false);
    if (groupedEdges.isEmpty) {
      return null;
    }
    final labelEntries = groupedEdges
        .map(
          (groupedEdge) =>
              _GroupedLabelEntry(painter: _buildLabelPainter(groupedEdge)),
        )
        .toList(growable: false);
    try {
      return _resolveGroupedLabelRect(
        representative,
        groupedGeometry,
        labelEntries,
      );
    } finally {
      _releaseLabelEntries(labelEntries);
    }
  }

  @visibleForTesting
  String debugGroupRepresentativeId(Edge edge) =>
      _edgeId(_groupRepresentative(edge));

  @visibleForTesting
  int get debugLabelPainterCacheSize => _labelPainterCache.length;

  @visibleForTesting
  int get debugGroupedEdgeCacheSize => _groupedEdgeCache.length;

  @visibleForTesting
  int get debugOpposingTrafficCacheSize => _opposingTrafficCache.length;

  @override
  void renderEdge(Canvas canvas, Edge edge, Paint paint) {
    if (edge.renderer != null) {
      edge.renderer!.renderEdge(canvas, edge, paint);
      return;
    }

    if (renderMode == TuringLabEdgeRenderMode.groupedFsa) {
      _renderGroupedFsaEdge(canvas, edge);
      return;
    }

    if (edge.source == edge.destination) {
      _renderSelfLoopCluster(canvas, edge);
      return;
    }

    final renderGeometry = _preparedGeometryForEdge(edge);
    if (renderGeometry == null) {
      return;
    }
    final geometry = renderGeometry.pathGeometry;

    final edgeId = _edgeId(edge);
    final strokePaint = _buildStrokePaint(
      highlighted: _isHighlighted(edgeId),
      selected: _isSelected(edgeId),
    );

    paintEdgeGeometry(
      canvas,
      edge,
      strokePaint,
      _dashGeometryForEpsilonEdges(geometry, [edge]),
    );

    if (!noArrow) {
      paintEdgeArrow(
        canvas,
        edge,
        _buildFillPaint(highlighted: _isHighlighted(edgeId)),
        geometry,
      );
    }

    if (_isHighlighted(edgeId)) {
      renderAnimatedParticlesOnPath(
        canvas,
        edge,
        _buildFillPaint(highlighted: true),
        geometry.path,
      );
    }

    if ((edge.label ?? '').trim().isEmpty || renderGeometry.labelRect == null) {
      return;
    }

    final labelEntries = <_GroupedLabelEntry>[
      _GroupedLabelEntry(painter: _buildLabelPainter(edge)),
    ];
    try {
      _paintLabelCard(
        canvas,
        rect: renderGeometry.labelRect!,
        entries: labelEntries,
        highlighted: _isHighlighted(edgeId),
        selected: _isSelected(edgeId),
      );
    } finally {
      _releaseLabelEntries(labelEntries);
    }
  }
}
