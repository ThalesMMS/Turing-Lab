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

/// Loop radius as a fraction of the state's radius. Keeping it near half the
/// state makes a self-loop read as a compact ring instead of a long arc.
const double kSelfLoopRadiusFactor = 0.5;

/// Fraction of the loop's own radius that sits behind the state's border. It
/// fixes how much of the loop circle stays visible (~255 degrees).
const double kSelfLoopSinkFactor = 0.55;

/// Padding a loop is built with when nothing asks it to grow. Anything above
/// it nests the loop outwards for stacked self-transitions.
const double kSelfLoopBasePadding = 16.0;

/// A self-loop drawn as a circular arc perched on a state's border: a ring of
/// [radius] around [center], entered at [start], left at [end], and swept the
/// way that stays outside the state.
///
/// Renderers that cannot use [Path] — the SVG exporter, for one — rebuild the
/// same curve from these fields, so every surface draws the loop alike.
class SelfLoopArc {
  const SelfLoopArc({
    required this.center,
    required this.radius,
    required this.start,
    required this.end,
    required this.startAngle,
    required this.sweep,
  });

  final Offset center;
  final double radius;
  final Offset start;
  final Offset end;

  /// Angle of [start] around [center], in radians.
  final double startAngle;

  /// Signed sweep from [startAngle] to [end], in radians. Negative sweeps run
  /// counter-clockwise on screen.
  final double sweep;

  /// Whether the arc covers more than half of its circle. SVG needs it as the
  /// `large-arc-flag` of an `A` command.
  bool get isLargeArc => sweep.abs() > pi;
}

/// Resolves the arc a self-loop on [nodeCenter] traces when it leaves the
/// state's border at outward direction [angle].
///
/// [padding] above [kSelfLoopBasePadding] nests the loop outwards, growing its
/// own radius first so stacked loops stay round.
SelfLoopArc resolveSelfLoopArc({
  required Offset nodeCenter,
  required double nodeRadius,
  required double angle,
  double padding = kSelfLoopBasePadding,
}) {
  final anchorRadius = max(nodeRadius, 1.0);
  final outward = Offset(cos(angle), sin(angle));
  final tangent = Offset(-outward.dy, outward.dx);

  final extraPadding = max(0.0, padding - kSelfLoopBasePadding);
  final loopRadius = anchorRadius * kSelfLoopRadiusFactor + extraPadding * 0.85;
  final centerDistance = anchorRadius +
      loopRadius * (1 - kSelfLoopSinkFactor) +
      extraPadding * 0.15;
  final loopCenter = nodeCenter + outward * centerDistance;

  // Where the loop circle crosses the state's border. `chordDistance` is
  // measured from the state's center along `outward`, `chordHalfWidth`
  // sideways from there.
  final chordDistance = (centerDistance * centerDistance +
          anchorRadius * anchorRadius -
          loopRadius * loopRadius) /
      (2 * centerDistance);
  final chordHalfWidthSquared =
      anchorRadius * anchorRadius - chordDistance * chordDistance;
  final chordHalfWidth =
      chordHalfWidthSquared > 0 ? sqrt(chordHalfWidthSquared) : 0.0;

  final chordCenter = nodeCenter + outward * chordDistance;
  final start = chordCenter + tangent * chordHalfWidth;
  final end = chordCenter - tangent * chordHalfWidth;

  final startAngle = atan2(start.dy - loopCenter.dy, start.dx - loopCenter.dx);
  final endAngle = atan2(end.dy - loopCenter.dy, end.dx - loopCenter.dx);
  // Sweep the way that passes the apex, which is the half of the loop circle
  // lying outside the state.
  var sweep = _positiveSweep(endAngle - startAngle);
  if (_positiveSweep(angle - startAngle) > sweep) {
    sweep -= 2 * pi;
  }

  return SelfLoopArc(
    center: loopCenter,
    radius: loopRadius,
    start: start,
    end: end,
    startAngle: startAngle,
    sweep: sweep,
  );
}

double _positiveSweep(double value) {
  final sweep = value % (2 * pi);
  return sweep <= 0 ? sweep + 2 * pi : sweep;
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
