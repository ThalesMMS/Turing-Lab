import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:graphview/graphview_turing_lab.dart';

class AutomaticTransitionObstacle {
  const AutomaticTransitionObstacle({
    required this.id,
    required this.center,
    required this.radius,
  });

  final String id;
  final Offset center;
  final double radius;
}

/// Angular region a self-loop is pushed away from, measured around the state
/// the loop belongs to. Callers describe whatever the planner cannot see on
/// its own: the initial-state marker, the transitions leaving the state, and
/// anything else already occupying part of the border.
class AutomaticTransitionLoopRepulsor {
  const AutomaticTransitionLoopRepulsor({
    required this.direction,
    required this.halfWidth,
    required this.weight,
  });

  /// Direction to keep clear, in radians, from the state's center.
  final double direction;

  /// Angular reach of the repulsion on each side of [direction].
  final double halfWidth;

  /// Relative strength. Weights are only compared against each other and
  /// against [AutomaticTransitionRoutePlanner._loopAngleStickiness].
  final double weight;
}

/// How hard a self-loop is pushed off the border stretch the initial-state
/// marker occupies, and how wide that stretch is. The marker points into the
/// state from the west, so the loop only has to clear that side.
const double kInitialMarkerLoopRepulsion = 2.5;
const double kInitialMarkerLoopHalfWidth = 5 * math.pi / 18;

/// The same, for every transition attached to the state.
const double kBorderTrafficLoopRepulsion = 2.0;
const double kBorderTrafficLoopHalfWidth = 7 * math.pi / 36;

/// Builds the repulsion a self-loop on a state has to respect: the
/// initial-state marker entering from the west, plus one entry per
/// [borderTrafficDirections] — the direction of each transition attached to
/// the state, in radians.
///
/// Every surface that places a loop (the canvas renderer, the SVG exporter)
/// goes through here, so a loop lands on the same side wherever it is drawn.
List<AutomaticTransitionLoopRepulsor> buildSelfLoopRepulsors({
  required bool hasInitialMarker,
  Iterable<double> borderTrafficDirections = const <double>[],
}) {
  return <AutomaticTransitionLoopRepulsor>[
    if (hasInitialMarker)
      const AutomaticTransitionLoopRepulsor(
        direction: math.pi,
        halfWidth: kInitialMarkerLoopHalfWidth,
        weight: kInitialMarkerLoopRepulsion,
      ),
    for (final direction in borderTrafficDirections)
      AutomaticTransitionLoopRepulsor(
        direction: direction,
        halfWidth: kBorderTrafficLoopHalfWidth,
        weight: kBorderTrafficLoopRepulsion,
      ),
  ];
}

class AutomaticTransitionRouteRequest {
  const AutomaticTransitionRouteRequest({
    required this.stableId,
    required this.sourceId,
    required this.destinationId,
    required this.sourceCenter,
    required this.destinationCenter,
    required this.sourceRadius,
    required this.destinationRadius,
    required this.laneOffset,
    required this.repulsionOffset,
    this.previousLoopAngle,
    this.loopRepulsors = const <AutomaticTransitionLoopRepulsor>[],
  });

  final String stableId;
  final String sourceId;
  final String destinationId;
  final Offset sourceCenter;
  final Offset destinationCenter;
  final double sourceRadius;
  final double destinationRadius;
  final double laneOffset;
  final Offset repulsionOffset;

  /// Outward direction this self-loop was given on the previous plan, in
  /// radians. The planner slides it along the state's border instead of
  /// re-deriving it from scratch, so loops track their surroundings smoothly
  /// rather than flicking between near-tie placements on every replan.
  final double? previousLoopAngle;

  /// Angular regions this self-loop should avoid.
  final List<AutomaticTransitionLoopRepulsor> loopRepulsors;

  bool get isSelfLoop => sourceId == destinationId;
}

class AutomaticTransitionRoutePlan {
  const AutomaticTransitionRoutePlan({
    required this.controlPoint,
    required this.labelNormal,
    this.loopAngle,
    this.loopPadding = 16,
  });

  final Offset controlPoint;
  final Offset labelNormal;

  /// Outward direction of a self-loop, in radians. Null for regular edges.
  final double? loopAngle;
  final double loopPadding;
}

class AutomaticTransitionRoutePlanner {
  const AutomaticTransitionRoutePlanner({
    this.routeClearance = 24,
    this.gridCellSize = 64,
  });

  final double routeClearance;
  final double gridCellSize;

  /// Cost a self-loop may give up to stay near its previous direction. It
  /// absorbs the small landscape wobble a moving neighbour produces, while
  /// any real obstruction (weight >= 1) still wins and moves the loop.
  static const double _loopAngleStickiness = 0.6;

  /// Angular resolution of the coarse sweep that seeds the loop search.
  static const double _loopSampleStep = math.pi / 36;

  /// The search stops refining once it is this close to a local minimum, or
  /// after [_loopRefineIterations] descent steps, whichever comes first.
  static const double _loopRefineLimit = math.pi / 720;
  static const int _loopRefineIterations = 64;

  /// Pull towards an upward loop, so an unobstructed state keeps the
  /// familiar heading instead of settling wherever the search started.
  static const double _loopUpwardBias = 0.35;

  /// Strength and reach of the repulsion a neighbouring state exerts on a
  /// loop. The weight fades linearly to zero across [_loopObstacleFalloff]
  /// so a state drifting away never steps the cost landscape.
  static const double _loopObstacleWeight = 6.0;
  static const double _loopObstacleFalloff = 96.0;
  static const double _loopObstacleMargin = math.pi / 9;

  Map<String, AutomaticTransitionRoutePlan> plan({
    required List<AutomaticTransitionRouteRequest> requests,
    required List<AutomaticTransitionObstacle> obstacles,
    Iterable<EdgePathGeometry> existingPaths = const <EdgePathGeometry>[],
  }) {
    final sorted = [...requests]
      ..sort((left, right) => left.stableId.compareTo(right.stableId));
    final grid = _RouteSpatialGrid(cellSize: gridCellSize)
      ..addExistingPaths(existingPaths);
    final result = <String, AutomaticTransitionRoutePlan>{};

    for (final request in sorted.where((request) => !request.isSelfLoop)) {
      final delta = request.destinationCenter - request.sourceCenter;
      final axis =
          delta.distance < 0.001 ? _stableAxis(request.stableId) : delta;
      final normal = Offset(-axis.dy, axis.dx) / axis.distance;
      final midpoint = (request.sourceCenter + request.destinationCenter) / 2;
      final base =
          midpoint + normal * request.laneOffset + request.repulsionOffset;
      final candidates = <Offset>[
        for (final displacement in const [0.0, 24.0, -24.0, 48.0, -48.0])
          base + normal * displacement,
      ];
      final control = _lowestScoreCandidate(
        request,
        candidates,
        obstacles,
        grid,
      );
      result[request.stableId] = AutomaticTransitionRoutePlan(
        controlPoint: control,
        labelNormal: _dot(control - midpoint, normal) < 0 ? -normal : normal,
      );
      grid.addQuadratic(request, control);
    }

    final loopIndexes = <String, int>{};
    for (final request in sorted.where((request) => request.isSelfLoop)) {
      final visibleLoopIndex = loopIndexes.update(
        request.sourceId,
        (value) => value + 1,
        ifAbsent: () => 0,
      );
      final padding = 16.0 + visibleLoopIndex * 12.0;
      final repulsors = <AutomaticTransitionLoopRepulsor>[
        ...request.loopRepulsors,
        ..._obstacleLoopRepulsors(request, obstacles, padding),
      ];
      final angle = _selectLoopAngle(repulsors, request.previousLoopAngle);
      final outward = Offset(math.cos(angle), math.sin(angle));
      final apex =
          request.sourceCenter + outward * (request.sourceRadius + padding);

      result[request.stableId] = AutomaticTransitionRoutePlan(
        controlPoint: apex,
        labelNormal: outward,
        loopAngle: angle,
        loopPadding: padding,
      );
    }

    return result;
  }

  /// Turns the states around a looping state into angular repulsion. The
  /// weight only depends on the states' own geometry, never on the order the
  /// planner visits requests in, so a partial replan lands on the same angle
  /// a full replan would.
  Iterable<AutomaticTransitionLoopRepulsor> _obstacleLoopRepulsors(
    AutomaticTransitionRouteRequest request,
    List<AutomaticTransitionObstacle> obstacles,
    double padding,
  ) sync* {
    final reach = request.sourceRadius + padding + routeClearance;
    for (final obstacle in obstacles) {
      if (obstacle.id == request.sourceId) {
        continue;
      }
      final delta = obstacle.center - request.sourceCenter;
      final distance = delta.distance;
      if (distance < 0.001) {
        continue;
      }
      final gap = distance - obstacle.radius - reach;
      if (gap >= _loopObstacleFalloff) {
        continue;
      }
      final fade = 1 - (math.max(gap, 0.0) / _loopObstacleFalloff);
      yield AutomaticTransitionLoopRepulsor(
        direction: math.atan2(delta.dy, delta.dx),
        halfWidth: math.asin((obstacle.radius / distance).clamp(0.0, 0.999)) +
            _loopObstacleMargin,
        weight: _loopObstacleWeight * fade,
      );
    }
  }

  /// Picks where a loop sits on its state's border. The cost landscape is
  /// smooth, so the chosen angle slides as neighbours move; the previous
  /// angle is only abandoned when another basin is clearly cheaper.
  double _selectLoopAngle(
    List<AutomaticTransitionLoopRepulsor> repulsors,
    double? previousAngle,
  ) {
    // The sweep starts upward and only accepts strict improvements, so a
    // state with nothing around it always resolves to the same angle.
    const upward = -math.pi / 2;
    var seed = upward;
    var seedCost = _loopCost(seed, repulsors);
    final samples = (2 * math.pi / _loopSampleStep).round();
    for (var index = 1; index < samples; index++) {
      final candidate = upward + index * _loopSampleStep;
      final cost = _loopCost(candidate, repulsors);
      if (cost < seedCost - 1e-9) {
        seedCost = cost;
        seed = candidate;
      }
    }

    final global = _refineLoopAngle(seed, repulsors);
    if (previousAngle == null) {
      return global;
    }
    final sticky = _refineLoopAngle(previousAngle, repulsors);
    return _loopCost(sticky, repulsors) <=
            _loopCost(global, repulsors) + _loopAngleStickiness
        ? sticky
        : global;
  }

  double _refineLoopAngle(
    double seed,
    List<AutomaticTransitionLoopRepulsor> repulsors,
  ) {
    var best = seed;
    var bestCost = _loopCost(best, repulsors);
    var step = _loopSampleStep;
    for (var iteration = 0;
        iteration < _loopRefineIterations && step > _loopRefineLimit;
        iteration++) {
      var improved = false;
      for (final candidate in <double>[best - step, best + step]) {
        final cost = _loopCost(candidate, repulsors);
        if (cost < bestCost - 1e-9) {
          bestCost = cost;
          best = candidate;
          improved = true;
        }
      }
      if (!improved) {
        step /= 2;
      }
    }
    return _normalizeAngle(best);
  }

  double _loopCost(
    double angle,
    List<AutomaticTransitionLoopRepulsor> repulsors,
  ) {
    var cost = _loopUpwardBias * 0.5 * (1 - math.cos(angle + math.pi / 2));
    for (final repulsor in repulsors) {
      if (repulsor.weight <= 0 || repulsor.halfWidth <= 0) {
        continue;
      }
      final delta = _angleDifference(angle, repulsor.direction).abs();
      if (delta >= repulsor.halfWidth) {
        continue;
      }
      cost += repulsor.weight *
          0.5 *
          (1 + math.cos(math.pi * delta / repulsor.halfWidth));
    }
    return cost;
  }

  Offset _lowestScoreCandidate(
    AutomaticTransitionRouteRequest request,
    List<Offset> candidates,
    List<AutomaticTransitionObstacle> obstacles,
    _RouteSpatialGrid grid,
  ) {
    var best = candidates.first;
    var bestScore = double.infinity;
    for (var candidateIndex = 0;
        candidateIndex < candidates.length;
        candidateIndex++) {
      final control = candidates[candidateIndex];
      final path = Path()
        ..moveTo(request.sourceCenter.dx, request.sourceCenter.dy)
        ..quadraticBezierTo(
          control.dx,
          control.dy,
          request.destinationCenter.dx,
          request.destinationCenter.dy,
        );
      final metrics = path.computeMetrics().toList(growable: false);
      if (metrics.isEmpty) {
        if (candidateIndex == 0) {
          bestScore = 0;
          best = control;
        }
        continue;
      }
      final metric = metrics.first;
      final samples = math.max(1, (metric.length / 12).ceil());
      var score = candidateIndex * 0.001;
      for (var index = 1; index < samples; index++) {
        final point = metric
            .getTangentForOffset(metric.length * index / samples)!
            .position;
        for (final obstacle in obstacles) {
          if (obstacle.id == request.sourceId ||
              obstacle.id == request.destinationId) {
            continue;
          }
          final clearance =
              (point - obstacle.center).distance - obstacle.radius;
          if (clearance < routeClearance) {
            score +=
                clearance <= 0 ? 100000 : (routeClearance - clearance) * 100;
          }
        }
        final probe = Rect.fromCircle(center: point, radius: routeClearance);
        for (final segment in grid.nearby(probe)) {
          final distance =
              _distanceToSegment(point, segment.start, segment.end);
          if (distance < routeClearance) {
            score += (routeClearance - distance) * 10;
          }
        }
      }
      if (score < bestScore) {
        bestScore = score;
        best = control;
      }
    }
    return best;
  }
}

double _dot(Offset left, Offset right) =>
    left.dx * right.dx + left.dy * right.dy;

/// Folds an angle into (-pi, pi]. Dart's `%` already returns a non-negative
/// remainder, so only the upper half needs shifting.
double _normalizeAngle(double angle) {
  final normalized = angle % (2 * math.pi);
  return normalized > math.pi ? normalized - (2 * math.pi) : normalized;
}

double _angleDifference(double left, double right) =>
    _normalizeAngle(left - right);

Offset _stableAxis(String stableId) {
  final checksum = stableId.codeUnits.fold<int>(0, (sum, unit) => sum + unit);
  final angle = (checksum % 8) * (math.pi / 4);
  return Offset(math.cos(angle), math.sin(angle));
}

double _distanceToSegment(Offset point, Offset start, Offset end) {
  final segment = end - start;
  if (segment.distanceSquared == 0) {
    return (point - start).distance;
  }
  final relative = point - start;
  final projection = (_dot(relative, segment) / segment.distanceSquared)
      .clamp(0.0, 1.0)
      .toDouble();
  return (point - (start + segment * projection)).distance;
}

class _RouteSegment {
  const _RouteSegment(this.start, this.end);

  final Offset start;
  final Offset end;

  Rect get bounds => Rect.fromPoints(start, end);
}

class _RouteSpatialGrid {
  _RouteSpatialGrid({required this.cellSize});

  final double cellSize;
  final Map<(int, int), List<_RouteSegment>> _cells = {};

  void addExistingPaths(Iterable<EdgePathGeometry> paths) {
    for (final geometry in paths) {
      _addPath(geometry.path);
    }
  }

  void addQuadratic(
    AutomaticTransitionRouteRequest request,
    Offset control,
  ) {
    final path = Path()
      ..moveTo(request.sourceCenter.dx, request.sourceCenter.dy)
      ..quadraticBezierTo(
        control.dx,
        control.dy,
        request.destinationCenter.dx,
        request.destinationCenter.dy,
      );
    _addPath(path);
  }

  Iterable<_RouteSegment> nearby(Rect bounds) sync* {
    final seen = <_RouteSegment>{};
    final left = (bounds.left / cellSize).floor() - 1;
    final right = (bounds.right / cellSize).floor() + 1;
    final top = (bounds.top / cellSize).floor() - 1;
    final bottom = (bounds.bottom / cellSize).floor() + 1;
    for (var row = top; row <= bottom; row++) {
      for (var column = left; column <= right; column++) {
        for (final segment
            in _cells[(row, column)] ?? const <_RouteSegment>[]) {
          if (seen.add(segment)) {
            yield segment;
          }
        }
      }
    }
  }

  void _addPath(Path path) {
    for (final metric in path.computeMetrics()) {
      final samples = math.max(1, (metric.length / 12).ceil());
      var previous = metric.getTangentForOffset(0)!.position;
      for (var index = 1; index <= samples; index++) {
        final current = metric
            .getTangentForOffset(metric.length * index / samples)!
            .position;
        _insert(_RouteSegment(previous, current));
        previous = current;
      }
    }
  }

  void _insert(_RouteSegment segment) {
    final bounds = segment.bounds;
    for (var row = (bounds.top / cellSize).floor();
        row <= (bounds.bottom / cellSize).floor();
        row++) {
      for (var column = (bounds.left / cellSize).floor();
          column <= (bounds.right / cellSize).floor();
          column++) {
        _cells.putIfAbsent((row, column), () => []).add(segment);
      }
    }
  }
}
