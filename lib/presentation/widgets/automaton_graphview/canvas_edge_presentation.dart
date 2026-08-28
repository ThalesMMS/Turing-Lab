import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:graphview/graphview_turing_lab.dart';

import '../../../core/models/simulation_highlight.dart';
import '../../../features/canvas/graphview/base_graphview_canvas_controller.dart';
import '../../../features/canvas/graphview/turing_lab_adaptive_edge_renderer.dart';

/// Owns edge rendering, animation and rendering-only cache signatures.
class AutomatonGraphViewEdgePresentation {
  AutomatonGraphViewEdgePresentation({
    required TickerProvider vsync,
    required BaseGraphViewCanvasController<dynamic, dynamic> controller,
    required TuringLabEdgeRenderMode renderMode,
  }) : _controller = controller {
    renderer = TuringLabAdaptiveEdgeRenderer(
      config: EdgeRoutingConfig(
        anchorMode: AnchorMode.dynamic,
        routingMode: RoutingMode.bezier,
        enableRepulsion: true,
      ),
      animationConfig: const AnimatedEdgeConfiguration(
        animationSpeed: 1.0,
        particleCount: 3,
        particleSize: 3.0,
      ),
      renderMode: renderMode,
    );
    animationController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 1400),
    )..addListener(_handleAnimationTick);
    renderer.setAnimationValue(animationController.value);
  }

  late final TuringLabAdaptiveEdgeRenderer renderer;
  late final AnimationController animationController;
  BaseGraphViewCanvasController<dynamic, dynamic> _controller;
  String? _lastStructureSignature;
  Color? _baseColor;
  Color? _highlightColor;
  Color? _labelSurfaceColor;
  String? _labelFontFamily;
  List<String>? _labelFontFamilyFallback;

  void replaceController(
    BaseGraphViewCanvasController<dynamic, dynamic> controller,
  ) {
    _controller = controller;
    _lastStructureSignature = null;
  }

  void updateTheme(ThemeData theme) {
    _baseColor = theme.colorScheme.outline;
    _highlightColor = theme.colorScheme.primary;
    _labelSurfaceColor = theme.colorScheme.surfaceContainerHighest;
    final labelStyle = theme.textTheme.labelLarge;
    _labelFontFamily = labelStyle?.fontFamily;
    _labelFontFamilyFallback = labelStyle?.fontFamilyFallback;
  }

  void updateHighlight(
    SimulationHighlight highlight,
    Set<String> selectedTransitionIds,
  ) {
    final baseColor = _baseColor;
    final highlightColor = _highlightColor;
    final labelSurfaceColor = _labelSurfaceColor;
    if (baseColor != null &&
        highlightColor != null &&
        labelSurfaceColor != null) {
      renderer.updateAppearance(
        highlightedEdgeIds: highlight.transitionIds,
        selectedEdgeIds: selectedTransitionIds,
        baseColor: baseColor,
        highlightColor: highlightColor,
        labelSurfaceColor: labelSurfaceColor,
        labelFontFamily: _labelFontFamily,
        labelFontFamilyFallback: _labelFontFamilyFallback,
      );
    }

    if (highlight.transitionIds.isNotEmpty) {
      if (!animationController.isAnimating) {
        animationController.repeat();
      }
      return;
    }
    if (animationController.isAnimating) {
      animationController.stop();
    }
    if (animationController.value != 0) {
      animationController.value = 0;
      renderer.setAnimationValue(0);
    }
  }

  void synchronizeStructure() {
    final signature = _structureSignature();
    if (signature != _lastStructureSignature) {
      _lastStructureSignature = signature;
      renderer.invalidateEdgeCaches();
    }
    renderer.updateInitialStateIds(<String>{
      for (final node in _controller.nodes)
        if (node.isInitial) node.id,
    });
  }

  void dispose() {
    animationController
      ..removeListener(_handleAnimationTick)
      ..dispose();
  }

  void _handleAnimationTick() {
    renderer.setAnimationValue(animationController.value);
    _controller.graph.notifyGraphObserver();
  }

  String _structureSignature() {
    final edges = _controller.edges.sortedBy((edge) => edge.id);
    final buffer = StringBuffer()..write(edges.length);
    for (final edge in edges) {
      buffer
        ..write('|')
        ..write(edge.id)
        ..write(':')
        ..write(edge.fromStateId)
        ..write('->')
        ..write(edge.toStateId)
        ..write(':')
        ..write(edge.label);
    }
    return buffer.toString();
  }
}
