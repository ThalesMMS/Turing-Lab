part of graphview;

enum EdgePathKind { direct, curved, selfLoop }

enum LoopHeading {
  north(-pi / 2),
  northEast(-pi / 4),
  east(0),
  southEast(pi / 4),
  south(pi / 2),
  southWest(3 * pi / 4),
  west(pi),
  northWest(-3 * pi / 4);

  const LoopHeading(this.angle);

  final double angle;
}

Offset resolveCircularConnectionPoint({
  required Offset center,
  required double radius,
  required Offset toward,
  required Offset fallbackDirection,
}) {
  var direction = toward - center;
  if (!direction.dx.isFinite ||
      !direction.dy.isFinite ||
      direction.distance < VectorUtils.epsilon) {
    direction = fallbackDirection;
  }
  if (!direction.dx.isFinite ||
      !direction.dy.isFinite ||
      direction.distance < VectorUtils.epsilon) {
    direction = const Offset(1, 0);
  }
  return center + direction / direction.distance * max(radius, 0.001);
}

class EdgePathGeometry {
  const EdgePathGeometry({
    required this.path,
    required this.start,
    required this.end,
    required this.arrowBase,
    required this.arrowTip,
    required this.bounds,
    required this.kind,
  });

  factory EdgePathGeometry.fromPath(
    Path candidate, {
    required Offset fallbackStart,
    required Offset fallbackEnd,
    required double arrowLength,
    required EdgePathKind kind,
  }) {
    var path = candidate;
    var metrics = path.computeMetrics().toList(growable: false);
    if (metrics.isEmpty) {
      final finiteStart = _finiteOffset(fallbackStart, Offset.zero);
      var finiteEnd = _finiteOffset(fallbackEnd, finiteStart);
      if ((finiteEnd - finiteStart).distance < VectorUtils.epsilon) {
        finiteEnd = finiteStart + const Offset(0.001, 0);
      }
      path = Path()
        ..moveTo(finiteStart.dx, finiteStart.dy)
        ..lineTo(finiteEnd.dx, finiteEnd.dy);
      metrics = path.computeMetrics().toList(growable: false);
    }

    final metric = metrics.first;
    final start = metric.getTangentForOffset(0)?.position ?? Offset.zero;
    final end = metric.getTangentForOffset(metric.length)?.position ?? start;
    final effectiveArrowLength = min(
      max(arrowLength, 0),
      metric.length * 0.3,
    );
    final arrowBase = metric
            .getTangentForOffset(max(0, metric.length - effectiveArrowLength))
            ?.position ??
        end;

    return EdgePathGeometry(
      path: path,
      start: start,
      end: end,
      arrowBase: arrowBase,
      arrowTip: end,
      bounds: path.getBounds(),
      kind: kind,
    );
  }

  final Path path;
  final Offset start;
  final Offset end;
  final Offset arrowBase;
  final Offset arrowTip;
  final Rect bounds;
  final EdgePathKind kind;

  bool get isSelfLoop => kind == EdgePathKind.selfLoop;

  EdgePathGeometry withPath(Path replacement) => EdgePathGeometry(
        path: replacement,
        start: start,
        end: end,
        arrowBase: arrowBase,
        arrowTip: arrowTip,
        bounds: replacement.getBounds(),
        kind: kind,
      );

  Offset pointAt(double fraction) {
    final metric = path.computeMetrics().first;
    final clamped = fraction.clamp(0.0, 1.0).toDouble();
    return metric.getTangentForOffset(metric.length * clamped)!.position;
  }

  double distanceTo(Offset point, {double sampleSpacing = 8}) {
    final metric = path.computeMetrics().first;
    final finiteSpacing =
        sampleSpacing.isFinite && sampleSpacing > 0 ? sampleSpacing : 8.0;
    final samples = max(1, (metric.length / finiteSpacing).ceil());
    var minimum = double.infinity;
    var previous = pointAt(0);
    for (var index = 1; index <= samples; index++) {
      final current = pointAt(index / samples);
      minimum = min(
        minimum,
        VectorUtils.distanceToLineSegment(point, previous, current),
      );
      previous = current;
    }
    return minimum;
  }

  static Offset _finiteOffset(Offset value, Offset fallback) =>
      value.dx.isFinite && value.dy.isFinite ? value : fallback;
}
