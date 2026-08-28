import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;

import '../../../features/canvas/graphview/base_graphview_canvas_controller.dart';
import '../../../features/canvas/graphview/turing_lab_adaptive_edge_renderer.dart';

/// Keeps viewport matrix access and screen/world conversion in one place.
class AutomatonGraphViewViewportAdapter {
  AutomatonGraphViewViewportAdapter({required this.controller});

  BaseGraphViewCanvasController<dynamic, dynamic> controller;

  Offset screenToWorld(Offset viewportPosition) =>
      controller.toWorldOffset(viewportPosition);

  Offset worldToScreen(Offset worldPosition) {
    final transformation =
        controller.graphController.transformationController?.value;
    if (transformation == null) {
      return worldPosition;
    }
    final inverseProbe = vmath.Matrix4.copy(transformation);
    final determinant = inverseProbe.invert();
    if (determinant == 0 || !determinant.isFinite) {
      return worldPosition;
    }
    final vector = transformation.transform3(
      vmath.Vector3(worldPosition.dx, worldPosition.dy, 0),
    );
    if (!vector.x.isFinite || !vector.y.isFinite) {
      return worldPosition;
    }
    return Offset(vector.x, vector.y);
  }

  Offset globalToLocal(GlobalKey canvasKey, Offset globalPosition) {
    final renderBox =
        canvasKey.currentContext?.findRenderObject() as RenderBox?;
    return renderBox?.globalToLocal(globalPosition) ?? globalPosition;
  }

  void updateViewport(
    Size viewport,
    TuringLabAdaptiveEdgeRenderer edgeRenderer,
  ) {
    if (!viewport.width.isFinite || !viewport.height.isFinite) {
      return;
    }
    controller.updateViewportSize(viewport);
    edgeRenderer.updateViewportWorldBounds(
      Rect.fromPoints(
        screenToWorld(Offset.zero),
        screenToWorld(Offset(viewport.width, viewport.height)),
      ),
    );
  }
}
