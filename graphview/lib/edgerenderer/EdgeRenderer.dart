part of graphview;

abstract class RenderCycleAware {
  void prepareForRenderCycle();
}

abstract class EdgeRenderer {
  Map<Node, Offset>? _animatedPositions;
  Graph? _graph;

  void setAnimatedPositions(Map<Node, Offset> positions) =>
      _animatedPositions = positions;

  void setGraph(Graph graph) => _graph = graph;

  Offset getNodePosition(Node node) =>
      _animatedPositions?[node] ?? node.position;

  void renderEdge(Canvas canvas, Edge edge, Paint paint);

  /// Calculates the optimal connection point on the source node's boundary.
  /// Default implementation returns the center of the source node for backward compatibility.
  /// Subclasses should override to implement different anchor modes (cardinal, octagonal, dynamic).
  /// @param edge The edge being rendered
  /// @param destinationCenter The center position of the destination node
  /// @param edgeIndex The index of this edge among parallel edges (for distribution)
  /// @return The connection point on the source node's boundary
  Offset calculateSourceConnectionPoint(
      Edge edge, Offset destinationCenter, int edgeIndex) {
    return getNodeCenter(edge.source);
  }

  /// Calculates the optimal connection point on the destination node's boundary.
  /// Default implementation returns the center of the destination node for backward compatibility.
  /// Subclasses should override to implement different anchor modes (cardinal, octagonal, dynamic).
  /// @param edge The edge being rendered
  /// @param sourceCenter The center position of the source node
  /// @param edgeIndex The index of this edge among parallel edges (for distribution)
  /// @return The connection point on the destination node's boundary
  Offset calculateDestinationConnectionPoint(
      Edge edge, Offset sourceCenter, int edgeIndex) {
    return getNodeCenter(edge.destination);
  }

  /// Routes the edge path between source and destination connection points.
  /// Default implementation creates a direct straight line path for backward compatibility.
  /// Subclasses should override to implement different routing algorithms (direct, orthogonal, bezier, spline).
  /// @param sourcePoint The connection point on the source node
  /// @param destinationPoint The connection point on the destination node
  /// @param edge The edge being rendered
  /// @return A Path representing the routed edge
  Path routeEdgePath(Offset sourcePoint, Offset destinationPoint, Edge edge) {
    return Path()
      ..moveTo(sourcePoint.dx, sourcePoint.dy)
      ..lineTo(destinationPoint.dx, destinationPoint.dy);
  }

  /// Applies edge-to-edge repulsion forces to separate overlapping edges.
  /// Default implementation returns the original path without modification.
  /// Subclasses can override to implement repulsion algorithms.
  /// @param edges List of all edges in the graph
  /// @param currentEdge The edge to apply repulsion to
  /// @param path The original path of the current edge
  /// @return A modified path with repulsion applied, or the original path if no repulsion needed
  Path applyEdgeRepulsion(List<Edge> edges, Edge currentEdge, Path path) {
    return path;
  }

  Offset getNodeCenter(Node node) {
    final nodePosition = getNodePosition(node);
    return Offset(
      nodePosition.dx + node.width * 0.5,
      nodePosition.dy + node.height * 0.5,
    );
  }

  /// Draws a line between two points respecting the node's line type
  void drawStyledLine(Canvas canvas, Offset start, Offset end, Paint paint,
      {LineType? lineType}) {
    switch (lineType) {
      case LineType.dashedLine:
        drawDashedLine(canvas, start, end, paint, 0.6);
        break;
      case LineType.dottedLine:
        drawDashedLine(canvas, start, end, paint, 0.0);
        break;
      case LineType.sineLine:
        drawSineLine(canvas, start, end, paint);
        break;
      default:
        canvas.drawLine(start, end, paint);
        break;
    }
  }

  /// Draws a styled path respecting the node's line type
  void drawStyledPath(Canvas canvas, Path path, Paint paint,
      {LineType? lineType}) {
    switch (lineType) {
      case LineType.dashedLine:
        _drawDashedPath(canvas, path, paint);
        break;
      case LineType.dottedLine:
        _drawDottedPath(canvas, path, paint);
        break;
      case LineType.sineLine:
        _drawSinePath(canvas, path, paint);
        break;
      default:
        canvas.drawPath(path, paint);
        break;
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint,
      {double dashLength = 10.0, double gapLength = 5.0}) {
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      var draw = true;

      while (distance < metric.length) {
        final segmentLength = draw ? dashLength : gapLength;
        final nextDistance = min(distance + segmentLength, metric.length);
        if (draw) {
          canvas.drawPath(metric.extractPath(distance, nextDistance), paint);
        }
        distance = nextDistance;
        draw = !draw;
      }
    }
  }

  void _drawDottedPath(Canvas canvas, Path path, Paint paint) {
    final dotPaint = Paint.from(paint)..style = PaintingStyle.fill;
    final radius = max(1.0, paint.strokeWidth * 0.5);
    final spacing = max(4.0, paint.strokeWidth * 3.0);

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance <= metric.length) {
        final tangent = metric.getTangentForOffset(distance);
        if (tangent != null) {
          canvas.drawCircle(tangent.position, radius, dotPaint);
        }
        distance += spacing;
      }
    }
  }

  void _drawSinePath(Canvas canvas, Path path, Paint paint) {
    final wavePath = Path();
    final amplitude = max(2.0, paint.strokeWidth * 2.0);
    const wavelength = 24.0;
    const sampleDistance = 4.0;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      var started = false;

      while (distance <= metric.length) {
        final tangent = metric.getTangentForOffset(distance);
        if (tangent != null) {
          final vector = tangent.vector;
          final normal = Offset(-vector.dy, vector.dx);
          final phase = (distance / wavelength) * 2 * pi;
          final point = tangent.position + normal * (sin(phase) * amplitude);

          if (started) {
            wavePath.lineTo(point.dx, point.dy);
          } else {
            wavePath.moveTo(point.dx, point.dy);
            started = true;
          }
        }
        distance += sampleDistance;
      }

      final tangent = metric.getTangentForOffset(metric.length);
      if (tangent != null) {
        final vector = tangent.vector;
        final normal = Offset(-vector.dy, vector.dx);
        final phase = (metric.length / wavelength) * 2 * pi;
        final point = tangent.position + normal * (sin(phase) * amplitude);
        if (started) {
          wavePath.lineTo(point.dx, point.dy);
        }
      }
    }

    canvas.drawPath(wavePath, paint);
  }

  /// Draws a dashed line between two points
  void drawDashedLine(Canvas canvas, Offset source, Offset destination,
      Paint paint, double lineLength) {
    final dx = destination.dx - source.dx;
    final dy = destination.dy - source.dy;
    final distance = sqrt(dx * dx + dy * dy);

    if (distance == 0) return;

    final numLines = lineLength == 0.0 ? (distance / 5).ceil() : 14;
    final stepX = dx / numLines;
    final stepY = dy / numLines;

    if (lineLength == 0.0) {
      // Draw dots
      final circleRadius = 1.0;
      final circlePaint = Paint()
        ..color = paint.color
        ..strokeWidth = 1.0
        ..style = PaintingStyle.fill;

      for (var i = 0; i < numLines; i++) {
        final x = source.dx + (i * stepX);
        final y = source.dy + (i * stepY);
        canvas.drawCircle(Offset(x, y), circleRadius, circlePaint);
      }
    } else {
      // Draw dashes
      for (var i = 0; i < numLines; i++) {
        final startX = source.dx + (i * stepX);
        final startY = source.dy + (i * stepY);
        final endX = startX + (stepX * lineLength);
        final endY = startY + (stepY * lineLength);
        canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
      }
    }
  }

  /// Draws a sine wave line between two points
  void drawSineLine(
      Canvas canvas, Offset source, Offset destination, Paint paint) {
    final originalStrokeWidth = paint.strokeWidth;
    paint.strokeWidth = 1.5;

    final dx = destination.dx - source.dx;
    final dy = destination.dy - source.dy;
    final distance = sqrt(dx * dx + dy * dy);

    if (distance == 0 || (dx == 0 && dy == 0)) {
      paint.strokeWidth = originalStrokeWidth;
      return;
    }

    const lineLength = 6.0;
    const phaseOffset = 2.0;
    var distanceTraveled = 0.0;
    var phase = 0.0;

    final path = Path()..moveTo(source.dx, source.dy);

    while (distanceTraveled < distance) {
      final segmentLength = min(lineLength, distance - distanceTraveled);
      final segmentFraction = (distanceTraveled + segmentLength) / distance;
      final segmentDestination = Offset(
        source.dx + dx * segmentFraction,
        source.dy + dy * segmentFraction,
      );

      final waveAmplitude = sin(phase + phaseOffset) * segmentLength;

      double perpX, perpY;
      if ((dx > 0 && dy < 0) || (dx < 0 && dy > 0)) {
        perpX = waveAmplitude;
        perpY = waveAmplitude;
      } else {
        perpX = -waveAmplitude;
        perpY = waveAmplitude;
      }

      path.lineTo(segmentDestination.dx + perpX, segmentDestination.dy + perpY);

      distanceTraveled += segmentLength;
      phase += pi * segmentLength / lineLength;
    }

    canvas.drawPath(path, paint);
    paint.strokeWidth = originalStrokeWidth;
  }

  /// Builds a loop path for self-referential edges and returns geometry
  /// data that renderers can use to draw arrows or style the segment.
  ///
  /// The loop is the circular arc [resolveSelfLoopArc] describes, so it stays
  /// round and compact at every heading and matches what other surfaces (the
  /// SVG exporter) draw. Pass [loopAngle] to place it at an arbitrary outward
  /// direction; [heading] is only the fallback.
  LoopRenderResult? buildSelfLoopPath(
    Edge edge, {
    double loopPadding = kSelfLoopBasePadding,
    double arrowLength = 12.0,
    LoopHeading heading = LoopHeading.northEast,
    double? loopAngle,
  }) {
    if (edge.source != edge.destination) {
      return null;
    }

    final node = edge.source;
    final arc = resolveSelfLoopArc(
      nodeCenter: getNodeCenter(node),
      nodeRadius: node.size.shortestSide * 0.5,
      angle: loopAngle ?? heading.angle,
      padding: loopPadding,
    );

    final path = Path()
      ..arcTo(
        Rect.fromCircle(center: arc.center, radius: arc.radius),
        arc.startAngle,
        arc.sweep,
        true,
      );

    final geometry = EdgePathGeometry.fromPath(
      path,
      fallbackStart: arc.start,
      fallbackEnd: arc.end,
      arrowLength: arrowLength,
      kind: EdgePathKind.selfLoop,
    );

    return LoopRenderResult(
      geometry.path,
      geometry.arrowBase,
      geometry.arrowTip,
    );
  }

  /// Renders a text label for an edge at the specified position and rotation
  void renderEdgeLabel(
    Canvas canvas,
    Edge edge,
    Offset labelPosition,
    double? angle,
  ) {
    if (edge.label == null || edge.label!.isEmpty) {
      return;
    }

    final textStyle = edge.labelStyle ??
        const TextStyle(
          color: Color(0xFF000000),
          fontSize: 12.0,
        );

    final textSpan = TextSpan(
      text: edge.label,
      style: textStyle,
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    canvas.save();

    canvas.translate(labelPosition.dx, labelPosition.dy);

    if (angle != null) {
      canvas.rotate(angle);
    }

    textPainter.paint(
      canvas,
      Offset(-textPainter.width * 0.5, -textPainter.height * 0.5),
    );

    canvas.restore();
  }
}

class LoopRenderResult {
  final Path path;
  final Offset arrowBase;
  final Offset arrowTip;

  const LoopRenderResult(this.path, this.arrowBase, this.arrowTip);
}
