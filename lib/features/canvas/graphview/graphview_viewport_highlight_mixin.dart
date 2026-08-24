//
//  graphview_viewport_highlight_mixin.dart
//  Turing Lab
//
//  Mixin that gathers viewport and highlight helpers for GraphView
//  controllers, providing zoom animations, centering, auto-fit, and tracking
//  of active highlights. It also exposes reusable notifiers that trigger
//  repaints and let callers observe highlighted-transition changes.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:graphview/graphview_turing_lab.dart';

import '../../../core/constants/automaton_canvas_constants.dart';
import '../../../core/models/simulation_highlight.dart';
import 'graphview_canvas_models.dart';
import 'graphview_highlight_controller.dart';

void _logViewportEvent(String message) {
  if (kDebugMode) {
    debugPrint('[GraphViewViewport] $message');
  }
}

const double _kFitToContentFallbackExtent = 160.0;

/// Shared viewport and highlight helpers for GraphView canvas controllers.
mixin GraphViewViewportHighlightMixin on GraphViewHighlightController {
  /// Exposes the underlying graph structure managed by the controller.
  Graph get graph;

  /// Provides access to the GraphView controller responsible for viewport
  /// operations.
  GraphViewController get graphController;

  /// Provides access to the cached canvas nodes.
  Map<String, GraphViewCanvasNode> get nodesCache;

  /// Provides access to the cached canvas edges.
  Map<String, GraphViewCanvasEdge> get edgesCache;

  /// Maximum zoom applied when fitting the viewport to the current content.
  @protected
  double get fitToContentMaxScale => kAutomatonCanvasFitMaxScale;

  /// Returns the most recent viewport size reported by the hosting widget.
  @protected
  Size? get currentViewportSize;

  /// Returns the portion of the viewport not covered by canvas chrome.
  @protected
  Rect? get currentSafeViewportRect;

  /// Notifier used to broadcast highlight updates to listeners.
  final ValueNotifier<SimulationHighlight> highlightNotifier = ValueNotifier(
    SimulationHighlight.empty,
  );

  /// Notifier that indicates when the rendered graph structure has changed.
  final ValueNotifier<int> graphRevision = ValueNotifier<int>(0);

  /// Tracks the ids of the transitions currently highlighted.
  final Set<String> highlightedTransitionIds = <String>{};

  /// Releases the resources owned by the mixin.
  void disposeViewportHighlight() {
    highlightNotifier.dispose();
    graphRevision.dispose();
  }

  /// Hook invoked whenever the highlighted transitions change.
  @protected
  void onHighlightedTransitionsChanged(Set<String> transitionIds) {}

  double _extractScale(Matrix4 matrix) {
    final storage = matrix.storage;
    final scaleX = math.sqrt(
      storage[0] * storage[0] +
          storage[1] * storage[1] +
          storage[2] * storage[2],
    );
    final scaleY = math.sqrt(
      storage[4] * storage[4] +
          storage[5] * storage[5] +
          storage[6] * storage[6],
    );
    if (scaleX == 0 && scaleY == 0) {
      return 1.0;
    }
    if (scaleX == 0) {
      return scaleY.abs();
    }
    if (scaleY == 0) {
      return scaleX.abs();
    }
    return (scaleX.abs() + scaleY.abs()) / 2;
  }

  /// Returns the scale currently rendered by the canvas viewport.
  double get currentScale {
    final transformation = graphController.transformationController;
    if (transformation == null) {
      return 1;
    }
    return _extractScale(transformation.value);
  }

  /// Whether a zoom-in command can change the current viewport scale.
  bool get canZoomIn =>
      currentScale < kAutomatonCanvasMaxScale - precisionErrorTolerance;

  /// Whether a zoom-out command can change the current viewport scale.
  bool get canZoomOut =>
      currentScale > kAutomatonCanvasMinScale + precisionErrorTolerance;

  void _applyScale(double factor) {
    final transformation = graphController.transformationController;
    if (transformation == null) {
      _logViewportEvent('Ignored scale request (no transformation controller)');
      return;
    }

    final matrix = Matrix4.copy(transformation.value);
    final currentScale = _extractScale(matrix);
    final safeCurrent = currentScale == 0 ? 1.0 : currentScale;
    final targetScale = (safeCurrent * factor).clamp(
      kAutomatonCanvasMinScale,
      kAutomatonCanvasMaxScale,
    );
    final relativeScale = targetScale / safeCurrent;
    final safeViewport = currentSafeViewportRect;
    late final Matrix4 target;
    if (safeViewport == null) {
      target = Matrix4.copy(matrix)
        ..scaleByDouble(relativeScale, relativeScale, relativeScale, 1.0);
    } else {
      final viewportCenter = safeViewport.center;
      target = Matrix4.identity()
        ..translateByDouble(
          viewportCenter.dx,
          viewportCenter.dy,
          0.0,
          1.0,
        )
        ..scaleByDouble(relativeScale, relativeScale, relativeScale, 1.0)
        ..translateByDouble(
          -viewportCenter.dx,
          -viewportCenter.dy,
          0.0,
          1.0,
        )
        ..multiply(matrix);
    }
    graphController.animateToMatrix(target);
    _logViewportEvent(
      'Applied scale factor $relativeScale (target=$targetScale)',
    );
  }

  /// Increases the viewport zoom while respecting reasonable bounds.
  void zoomIn() {
    _logViewportEvent('zoomIn requested');
    _applyScale(1.2);
  }

  /// Decreases the viewport zoom while respecting reasonable bounds.
  void zoomOut() {
    _logViewportEvent('zoomOut requested');
    _applyScale(1 / 1.2);
  }

  /// Resets the viewport offset and zoom to their defaults.
  void resetView() {
    graphController.animateToMatrix(Matrix4.identity());
    _logViewportEvent('Viewport reset');
  }

  /// Adjusts the viewport to focus on the available nodes.
  void fitToContent() {
    if (graph.nodes.isEmpty) {
      _logViewportEvent(
        'fitToContent requested with empty graph, resetting view',
      );
      resetView();
      return;
    }
    final transformation = graphController.transformationController;
    final safeViewport = currentSafeViewportRect;
    if (safeViewport == null || transformation == null) {
      resetView();
      _logViewportEvent('fitToContent reset before viewport was available');
      return;
    }

    final bounds = graph.calculateGraphBounds();
    final contentWidth = math.max(bounds.width, _kFitToContentFallbackExtent);
    final contentHeight = math.max(bounds.height, _kFitToContentFallbackExtent);

    final scaleX = safeViewport.width / contentWidth;
    final scaleY = safeViewport.height / contentHeight;
    final rawScale = math.min(scaleX, scaleY) * 0.9;
    final targetScale = rawScale.clamp(
      kAutomatonCanvasMinScale,
      fitToContentMaxScale,
    );

    final contentCenterX = bounds.left + bounds.width / 2;
    final contentCenterY = bounds.top + bounds.height / 2;
    final targetCenterX = safeViewport.center.dx;
    final targetCenterY = safeViewport.center.dy;

    final matrix = Matrix4.identity()
      ..translateByDouble(
        targetCenterX - contentCenterX * targetScale,
        targetCenterY - contentCenterY * targetScale,
        0.0,
        1.0,
      )
      ..scaleByDouble(targetScale, targetScale, targetScale, 1.0);

    graphController.animateToMatrix(matrix);
    _logViewportEvent(
      'fitToContent applied (scale=${targetScale.toStringAsFixed(2)}, content=${contentWidth.toStringAsFixed(1)}x${contentHeight.toStringAsFixed(1)})',
    );
  }

  @override
  void applyHighlight(SimulationHighlight highlight) {
    updateLinkHighlights(highlight.transitionIds);
    highlightNotifier.value = highlight;
    _logViewportEvent(
      'Highlight applied (states=${highlight.stateIds.length}, transitions=${highlight.transitionIds.length})',
    );
  }

  @override
  void clearHighlight() {
    updateLinkHighlights(const <String>{});
    highlightNotifier.value = SimulationHighlight.empty;
    _logViewportEvent('Highlight cleared');
  }

  /// Updates the edge highlight set to match the provided ids.
  void updateLinkHighlights(Set<String> transitionIds) {
    final desiredIds = Set<String>.from(transitionIds);
    if (setEquals(desiredIds, highlightedTransitionIds)) {
      _logViewportEvent('Skipped highlight update (no changes)');
      return;
    }

    highlightedTransitionIds
      ..clear()
      ..addAll(desiredIds);

    onHighlightedTransitionsChanged(highlightedTransitionIds);
    _logViewportEvent(
      'Highlight set updated (transitions=${highlightedTransitionIds.length})',
    );
  }
}
