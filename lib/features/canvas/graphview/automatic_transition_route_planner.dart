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
    this.previousLoopHeading,
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

  /// Heading chosen for this self-loop on the previous plan, if any. The
  /// planner keeps it unless another heading is meaningfully better, so
  /// loops don't flip between near-tie headings across replans.
  final LoopHeading? previousLoopHeading;

  bool get isSelfLoop => sourceId == destinationId;
}

class AutomaticTransitionRoutePlan {
  const AutomaticTransitionRoutePlan({
    required this.controlPoint,
    required this.labelNormal,
    this.loopHeading,
    this.loopPadding = 16,
  });

  final Offset controlPoint;
  final Offset labelNormal;
  final LoopHeading? loopHeading;
  final double loopPadding;
}

class AutomaticTransitionRoutePlanner {
  const AutomaticTransitionRoutePlanner({
    this.routeClearance = 24,
    this.gridCellSize = 64,
  });

  final double routeClearance;
  final double gridCellSize;

  /// Score bonus applied to a self-loop's previous heading. Large enough to
  /// absorb tie-breaking noise and grazing path-segment overlaps, small
  /// enough that a heading colliding with a node (100000) still loses.
  static const double _loopHeadingStickiness = 250.0;

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
      var selectedScore = double.infinity;
      var selectedHeading = LoopHeading.north;
      var selectedPadding = 16.0;
      var selectedApex = request.sourceCenter;
      var selectedOutward = const Offset(0, -1);
      var selectedBounds = Rect.zero;

      for (final heading in LoopHeading.values) {
        final outward = Offset(
          math.cos(heading.angle),
          math.sin(heading.angle),
        );
        final padding = 16.0 + visibleLoopIndex * 12.0;
        final apex = request.sourceCenter +
            outward * (request.sourceRadius * 1.5 + padding);
        final candidateBounds = Rect.fromCircle(
          center: apex,
          radius: request.sourceRadius + padding,
        );
        var score = _loopCollisionScore(
          request,
          heading,
          candidateBounds,
          obstacles,
          grid,
        );
        if (heading == request.previousLoopHeading) {
          score -= _loopHeadingStickiness;
        }
        if (score < selectedScore) {
          selectedScore = score;
          selectedHeading = heading;
          selectedPadding = padding;
          selectedApex = apex;
          selectedOutward = outward;
          selectedBounds = candidateBounds;
        }
      }

      result[request.stableId] = AutomaticTransitionRoutePlan(
        controlPoint: selectedApex,
        labelNormal: selectedOutward,
        loopHeading: selectedHeading,
        loopPadding: selectedPadding,
      );
      grid.addBounds(selectedBounds);
    }

    return result;
  }

  double _loopCollisionScore(
    AutomaticTransitionRouteRequest request,
    LoopHeading heading,
    Rect candidateBounds,
    List<AutomaticTransitionObstacle> obstacles,
    _RouteSpatialGrid grid,
  ) {
    var score = heading.index * 0.001;
    for (final obstacle in obstacles) {
      if (obstacle.id == request.sourceId) {
        continue;
      }
      final closest = Offset(
        obstacle.center.dx
            .clamp(candidateBounds.left, candidateBounds.right)
            .toDouble(),
        obstacle.center.dy
            .clamp(candidateBounds.top, candidateBounds.bottom)
            .toDouble(),
      );
      if ((closest - obstacle.center).distance < obstacle.radius) {
        score += 100000;
      }
    }
    final probe = candidateBounds.inflate(routeClearance);
    for (final segment in grid.nearby(probe)) {
      if (probe.overlaps(segment.bounds)) {
        score += 1000;
      }
    }
    return score;
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

  void addBounds(Rect bounds) {
    for (final segment in <_RouteSegment>[
      _RouteSegment(bounds.topLeft, bounds.topRight),
      _RouteSegment(bounds.topRight, bounds.bottomRight),
      _RouteSegment(bounds.bottomRight, bounds.bottomLeft),
      _RouteSegment(bounds.bottomLeft, bounds.topLeft),
    ]) {
      _insert(segment);
    }
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
