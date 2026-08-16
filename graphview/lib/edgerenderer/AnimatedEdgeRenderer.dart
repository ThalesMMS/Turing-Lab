part of graphview;

/// Configuration for animated edge rendering
class AnimatedEdgeConfiguration {
  /// Speed multiplier for the animation (higher = faster)
  final double animationSpeed;

  /// Number of particles to render along each edge
  final int particleCount;

  /// Size (radius) of each particle in pixels
  final double particleSize;

  /// Color of the particles (defaults to edge color)
  final Color? particleColor;

  const AnimatedEdgeConfiguration({
    this.animationSpeed = 1.0,
    this.particleCount = 3,
    this.particleSize = 3.0,
    this.particleColor,
  });
}

/// Edge renderer that displays animated flow indicators (particles) moving along edges
/// to visualize direction of flow. Extends ArrowEdgeRenderer to preserve arrow functionality.
class AnimatedEdgeRenderer extends ArrowEdgeRenderer {
  /// Configuration for animation appearance
  final AnimatedEdgeConfiguration animationConfig;

  /// Animation value that drives particle movement (0.0 to 1.0)
  /// Should be updated externally via AnimationController
  double animationValue;

  AnimatedEdgeRenderer({
    this.animationConfig = const AnimatedEdgeConfiguration(),
    this.animationValue = 0.0,
    bool noArrow = false,
  }) : super(noArrow: noArrow);

  /// Updates the animation value (typically called from animation listener)
  void setAnimationValue(double value) {
    animationValue = value;
  }

  @override
  void renderEdge(Canvas canvas, Edge edge, Paint paint) {
    // First render the base edge with arrow using parent implementation
    super.renderEdge(canvas, edge, paint);

    // Then render animated particles on top
    _renderAnimatedParticles(canvas, edge, paint);
  }

  /// Renders animated particles flowing along the edge
  void _renderAnimatedParticles(Canvas canvas, Edge edge, Paint paint) {
    var source = edge.source;
    var destination = edge.destination;

    final particlePaint = Paint()
      ..color =
          animationConfig.particleColor ?? edge.paint?.color ?? paint.color
      ..style = PaintingStyle.fill;

    Path edgePath;

    if (source == destination) {
      // Handle self-loop
      final loopResult =
          buildSelfLoopPath(edge, arrowLength: noArrow ? 0.0 : ARROW_LENGTH);
      if (loopResult == null) return;
      edgePath = loopResult.path;
    } else {
      // Handle regular edge - create path from source to destination
      var sourceOffset = getNodePosition(source);
      var destinationOffset = getNodePosition(destination);

      var startX = sourceOffset.dx + source.width * 0.5;
      var startY = sourceOffset.dy + source.height * 0.5;
      var stopX = destinationOffset.dx + destination.width * 0.5;
      var stopY = destinationOffset.dy + destination.height * 0.5;

      // Create a simple path for the edge
      edgePath = Path()
        ..moveTo(startX, startY)
        ..lineTo(stopX, stopY);
    }

    // Compute metrics to get positions along the path
    final metrics = edgePath.computeMetrics().toList();
    if (metrics.isEmpty) return;

    final metric = metrics.first;
    final pathLength = metric.length;

    // Render particles at different positions along the path
    for (var i = 0; i < animationConfig.particleCount; i++) {
      // Distribute particles evenly along the path
      final basePosition = i / animationConfig.particleCount;

      // Add animation offset (with speed multiplier)
      final animatedPosition =
          (basePosition + animationValue * animationConfig.animationSpeed) %
              1.0;

      // Convert to actual path offset
      final offset = animatedPosition * pathLength;

      // Get the tangent at this position
      final tangent = metric.getTangentForOffset(offset);
      if (tangent != null) {
        // Draw particle as a circle
        canvas.drawCircle(
          tangent.position,
          animationConfig.particleSize,
          particlePaint,
        );
      }
    }
  }
}
