//
//  svg_transition_renderer.dart
//  Turing Lab
//
//  Draws transitions through the same route planner the canvas uses, so an
//  exported diagram carries the canvas lanes, curves and loop placements.
//  Shared by the automaton diagram and Turing machine renderers.
//

import 'dart:math' as math;

import 'package:flutter/material.dart' hide Colors;
import 'package:graphview/graphview_turing_lab.dart'
    show resolveCircularConnectionPoint, resolveSelfLoopArc;
import 'package:vector_math/vector_math_64.dart';

import '../../../../features/canvas/graphview/automatic_transition_route_planner.dart';
import '../../../empty_string_notation.dart';
import 'svg_primitives.dart';

/// Every transition running between one ordered pair of states, merged into
/// the single path the canvas draws for them.
class SvgEdgeGroup {
  SvgEdgeGroup({required this.fromId, required this.toId});

  final String fromId;
  final String toId;
  final List<String> labels = <String>[];

  bool get isSelfLoop => fromId == toId;
}

abstract final class SvgTransitionRenderer {
  /// Merges every transition running between the same ordered pair of states
  /// into one drawn path, the way the canvas does, so parallel symbols share
  /// a curve instead of stacking identical lines on top of each other.
  static List<SvgEdgeGroup> groupEdges(
    Iterable<(String, String, String)> edges,
  ) {
    final grouped = <String, SvgEdgeGroup>{};
    for (final (fromId, toId, label) in edges) {
      final group = grouped.putIfAbsent(
        '$fromId->$toId',
        () => SvgEdgeGroup(fromId: fromId, toId: toId),
      );
      if (label.isNotEmpty && !group.labels.contains(label)) {
        group.labels.add(label);
      }
    }
    return grouped.values.toList(growable: false);
  }

  /// Draws every transition through the planner the canvas routes with, so an
  /// exported diagram carries the same lanes, curves and loop placements.
  static void writeRouted(
    StringBuffer buffer, {
    required List<SvgEdgeGroup> groups,
    required Map<String, Vector2> positions,
    required Set<String> initialStateIds,
    required String indent,
    required String strokeColor,
    required String textColor,
    required String emptyStringSymbol,
  }) {
    if (groups.isEmpty) {
      return;
    }

    final directed = <String>{
      for (final group in groups) '${group.fromId}->${group.toId}',
    };
    final borderTraffic = <String, List<double>>{};
    for (final group in groups) {
      if (group.isSelfLoop) {
        continue;
      }
      final delta = positions[group.toId]! - positions[group.fromId]!;
      if (delta.length < 0.001) {
        continue;
      }
      final outgoing = math.atan2(delta.y, delta.x);
      (borderTraffic[group.fromId] ??= <double>[]).add(outgoing);
      (borderTraffic[group.toId] ??= <double>[]).add(outgoing + math.pi);
    }

    final requests = <AutomaticTransitionRouteRequest>[
      for (var index = 0; index < groups.length; index++)
        _routeRequestFor(
          groups[index],
          index: index,
          positions: positions,
          initialStateIds: initialStateIds,
          borderTraffic: borderTraffic,
          directedPairs: directed,
        ),
    ];
    final plans = const AutomaticTransitionRoutePlanner().plan(
      requests: requests,
      obstacles: <AutomaticTransitionObstacle>[
        for (final entry in positions.entries)
          AutomaticTransitionObstacle(
            id: entry.key,
            center: SvgPrimitives.toOffset(entry.value),
            radius: SvgPrimitives.stateRadius,
          ),
      ],
    );

    for (var index = 0; index < groups.length; index++) {
      final group = groups[index];
      final plan = plans[requests[index].stableId];
      if (plan == null) {
        continue;
      }
      final label = formatEmptyStringMarkers(
        group.labels.join(', '),
        emptyStringSymbol,
      );
      if (group.isSelfLoop) {
        _writeSelfLoop(
          buffer,
          center: requests[index].sourceCenter,
          angle: plan.loopAngle ?? -math.pi / 2,
          padding: plan.loopPadding,
          label: label,
          indent: indent,
          strokeColor: strokeColor,
          textColor: textColor,
        );
      } else {
        _writeCurvedTransition(
          buffer,
          source: requests[index].sourceCenter,
          destination: requests[index].destinationCenter,
          plan: plan,
          label: label,
          indent: indent,
          strokeColor: strokeColor,
          textColor: textColor,
        );
      }
    }
  }

  static AutomaticTransitionRouteRequest _routeRequestFor(
    SvgEdgeGroup group, {
    required int index,
    required Map<String, Vector2> positions,
    required Set<String> initialStateIds,
    required Map<String, List<double>> borderTraffic,
    required Set<String> directedPairs,
  }) {
    // Opposing traffic takes one lane each side of the straight line, the
    // same split the canvas applies to a two-way pair.
    final hasOpposing = directedPairs.contains(
      '${group.toId}->${group.fromId}',
    );
    final laneOffset = !hasOpposing || group.isSelfLoop
        ? 0.0
        : (group.fromId.compareTo(group.toId) <= 0 ? -1 : 1) *
              (SvgPrimitives.stateRadius * SvgPrimitives.laneSpacingFactor / 2);

    return AutomaticTransitionRouteRequest(
      // Index-keyed so the planner's ordering follows the drawing order.
      stableId:
          '${index.toString().padLeft(4, '0')}:'
          '${group.fromId}->${group.toId}',
      sourceId: group.fromId,
      destinationId: group.toId,
      sourceCenter: SvgPrimitives.toOffset(positions[group.fromId]!),
      destinationCenter: SvgPrimitives.toOffset(positions[group.toId]!),
      sourceRadius: SvgPrimitives.stateRadius,
      destinationRadius: SvgPrimitives.stateRadius,
      laneOffset: laneOffset,
      repulsionOffset: Offset.zero,
      loopRepulsors: group.isSelfLoop
          ? buildSelfLoopRepulsors(
              hasInitialMarker: initialStateIds.contains(group.fromId),
              borderTrafficDirections:
                  borderTraffic[group.fromId] ?? const <double>[],
            )
          : const <AutomaticTransitionLoopRepulsor>[],
    );
  }

  /// Emits the quadratic the canvas routes a transition along, trimmed to
  /// both states' borders.
  static void _writeCurvedTransition(
    StringBuffer buffer, {
    required Offset source,
    required Offset destination,
    required AutomaticTransitionRoutePlan plan,
    required String label,
    required String indent,
    required String strokeColor,
    required String textColor,
  }) {
    final start = resolveCircularConnectionPoint(
      center: source,
      radius: SvgPrimitives.stateRadius,
      toward: plan.controlPoint,
      fallbackDirection: destination - source,
    );
    final end = resolveCircularConnectionPoint(
      center: destination,
      radius: SvgPrimitives.stateRadius,
      toward: plan.controlPoint,
      fallbackDirection: source - destination,
    );

    buffer.writeln('$indent<g class="transition">');
    buffer.writeln(
      '$indent  <path d="M ${SvgPrimitives.formatDimension(start.dx)} '
      '${SvgPrimitives.formatDimension(start.dy)} '
      'Q ${SvgPrimitives.formatDimension(plan.controlPoint.dx)} '
      '${SvgPrimitives.formatDimension(plan.controlPoint.dy)} '
      '${SvgPrimitives.formatDimension(end.dx)} ${SvgPrimitives.formatDimension(end.dy)}"',
    );
    buffer.writeln(
      '$indent    fill="none" stroke="$strokeColor" '
      'stroke-width="${SvgPrimitives.formatDimension(SvgPrimitives.strokeWidth)}"',
    );
    buffer.writeln(
      '$indent    marker-end="url(#${SvgPrimitives.arrowMarkerId(strokeColor)})"/>',
    );

    if (label.isEmpty) {
      buffer.writeln('$indent</g>');
      return;
    }
    // Midpoint of the quadratic, pushed clear of the curve along the same
    // normal the canvas offsets the label card by.
    final midpoint = (start * 0.25) + (plan.controlPoint * 0.5) + (end * 0.25);
    _writeTransitionLabel(
      buffer,
      anchor: midpoint + plan.labelNormal * SvgPrimitives.transitionLabelGap,
      normal: plan.labelNormal,
      label: label,
      indent: indent,
      textColor: textColor,
    );
    buffer.writeln('$indent</g>');
  }

  /// Emits the compact circular loop the canvas draws, plus its label just
  /// outside the ring, along the loop's own heading.
  static void _writeSelfLoop(
    StringBuffer buffer, {
    required Offset center,
    required double angle,
    required double padding,
    required String label,
    required String indent,
    required String strokeColor,
    required String textColor,
  }) {
    final arc = resolveSelfLoopArc(
      nodeCenter: center,
      nodeRadius: SvgPrimitives.stateRadius,
      angle: angle,
      padding: padding,
    );
    final outward = Offset(math.cos(angle), math.sin(angle));

    buffer.writeln('$indent<g class="transition">');
    buffer.writeln(
      '$indent  <path d="M ${SvgPrimitives.formatDimension(arc.start.dx)} '
      '${SvgPrimitives.formatDimension(arc.start.dy)} '
      'A ${SvgPrimitives.formatDimension(arc.radius)} ${SvgPrimitives.formatDimension(arc.radius)} '
      '0 ${arc.isLargeArc ? 1 : 0} ${arc.sweep > 0 ? 1 : 0} '
      '${SvgPrimitives.formatDimension(arc.end.dx)} ${SvgPrimitives.formatDimension(arc.end.dy)}"',
    );
    buffer.writeln(
      '$indent    fill="none" stroke="$strokeColor" '
      'stroke-width="${SvgPrimitives.formatDimension(SvgPrimitives.strokeWidth)}"',
    );
    buffer.writeln(
      '$indent    marker-end="url(#${SvgPrimitives.loopArrowMarkerId(strokeColor)})"/>',
    );
    if (label.isNotEmpty) {
      _writeTransitionLabel(
        buffer,
        anchor:
            arc.center +
            outward * (arc.radius + SvgPrimitives.selfLoopLabelGap),
        normal: outward,
        label: label,
        indent: indent,
        textColor: textColor,
      );
    }
    buffer.writeln('$indent</g>');
  }

  static void _writeTransitionLabel(
    StringBuffer buffer, {
    required Offset anchor,
    required Offset normal,
    required String label,
    required String indent,
    required String textColor,
  }) {
    // SVG text grows upwards from its baseline: centre it on the anchor, and
    // drop it a full line more when the anchor sits below what it labels, so
    // the text never prints back over the path.
    final baselineY =
        anchor.dy +
        SvgPrimitives.transitionFontSize *
            (0.36 + 0.44 * math.max(0.0, normal.dy));
    buffer.writeln(
      '$indent  <text x="${SvgPrimitives.formatDimension(anchor.dx)}" '
      'y="${SvgPrimitives.formatDimension(baselineY)}" class="transition" '
      'fill="$textColor">${SvgPrimitives.escapeXml(label)}</text>',
    );
  }
}
