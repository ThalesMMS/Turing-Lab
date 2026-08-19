import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:graphview/graphview_turing_lab.dart';

void main() {
  test('circular anchor lies on the requested circumference', () {
    final anchor = resolveCircularConnectionPoint(
      center: const Offset(100, 100),
      radius: 48,
      toward: const Offset(160, 160),
      fallbackDirection: const Offset(1, 0),
    );

    expect((anchor - const Offset(100, 100)).distance, closeTo(48, 0.001));
    expect(anchor.dx, greaterThan(100));
    expect(anchor.dy, greaterThan(100));
  });

  test('empty input path becomes finite and paintable', () {
    final geometry = EdgePathGeometry.fromPath(
      Path(),
      fallbackStart: const Offset(20, 20),
      fallbackEnd: const Offset(20, 20),
      arrowLength: 10,
      kind: EdgePathKind.curved,
    );

    expect(geometry.path.computeMetrics(), isNotEmpty);
    expect(geometry.start.dx.isFinite, isTrue);
    expect(geometry.end.dy.isFinite, isTrue);
    expect(geometry.distanceTo(const Offset(20, 20)), lessThan(0.01));
  });

  test('self-loop headings create different finite bounds', () {
    final graph = Graph();
    final node = Node.Id('q0')
      ..position = const Offset(100, 100)
      ..size = const Size.square(96);
    graph.addNode(node);
    final edge = Edge(node, node);
    final renderer = ArrowEdgeRenderer();

    final north = renderer.buildSelfLoopPath(
      edge,
      heading: LoopHeading.north,
    )!;
    final east = renderer.buildSelfLoopPath(
      edge,
      heading: LoopHeading.east,
    )!;

    expect(north.path.getBounds(), isNot(equals(east.path.getBounds())));
    expect(north.path.computeMetrics().first.length, greaterThan(0));
    expect(east.path.computeMetrics().first.length, greaterThan(0));
    expect(LoopHeading.values, hasLength(8));
    expect(math.pi.isFinite, isTrue);
  });
}
