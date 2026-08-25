import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:graphview/GraphView.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:math';

void main() {
  group('CurvedEdgeRenderer', () {
    test('CurvedEdgeRenderer initializes with default curvature', () {
      final renderer = CurvedEdgeRenderer();
      expect(renderer.curvature, 0.5);
    });

    test('CurvedEdgeRenderer initializes with custom curvature', () {
      final renderer = CurvedEdgeRenderer(curvature: 0.8);
      expect(renderer.curvature, 0.8);
    });

    test('buildCurvedPath creates valid curved path', () {
      final renderer = CurvedEdgeRenderer();

      // Build a curved path from point A to point B
      renderer.buildCurvedPath(0, 0, 100, 100);

      final metrics = renderer.curvePath.computeMetrics().toList();
      expect(metrics, isNotEmpty);
      expect(metrics.first.length, greaterThan(0));
    });

    test('buildCurvedPath handles zero-length edge', () {
      final renderer = CurvedEdgeRenderer();

      // Build a path from a point to itself
      renderer.buildCurvedPath(50, 50, 50, 50);

      // Flutter's computeMetrics skips zero-length contours,
      // so a moveTo+lineTo with same coordinates produces no metrics
      final metrics = renderer.curvePath.computeMetrics().toList();
      expect(metrics, isEmpty);
    });

    test('buildCurvedPath creates more pronounced curve with higher curvature',
        () {
      final renderer1 = CurvedEdgeRenderer(curvature: 0.2);
      final renderer2 = CurvedEdgeRenderer(curvature: 0.8);

      // Build the same path with different curvatures
      renderer1.buildCurvedPath(0, 0, 100, 0);
      renderer2.buildCurvedPath(0, 0, 100, 0);

      final length1 = renderer1.curvePath.computeMetrics().first.length;
      final length2 = renderer2.curvePath.computeMetrics().first.length;

      // Higher curvature should create a longer path
      expect(length2, greaterThan(length1));
    });

    test('buildSelfLoopPath creates valid self-loop for curved edges', () {
      final renderer = CurvedEdgeRenderer();
      final node = Node.Id('self')
        ..size = const Size(40, 40)
        ..position = const Offset(100, 100);

      final edge = Edge(node, node);
      final result = renderer.buildSelfLoopPath(edge, arrowLength: 0.0);

      expect(result, isNotNull);

      final metrics = result!.path.computeMetrics().toList();
      expect(metrics, isNotEmpty);
      final metric = metrics.first;
      expect(metric.length, greaterThan(0));
      expect(result.arrowTip, isNot(equals(const Offset(0, 0))));

      const center = Offset(120, 120);
      const radius = 20.0;

      final tangentStart = metric.getTangentForOffset(0);
      final tangentEnd = metric.getTangentForOffset(metric.length);
      expect(tangentStart, isNotNull);
      expect(tangentEnd, isNotNull);

      // Both ends are anchored on the state's border, on the default
      // north-east side, and the loop leaves outwards before coming back in.
      expect((tangentStart!.position - center).distance, closeTo(radius, 0.5));
      expect((tangentEnd!.position - center).distance, closeTo(radius, 0.5));
      expect(tangentStart.position.dx, greaterThan(center.dx));
      expect(tangentEnd.position.dy, lessThan(center.dy));
      expect(
        _radialComponent(tangentStart.vector, tangentStart.position - center),
        greaterThan(0),
      );
      expect(
        _radialComponent(tangentEnd.vector, tangentEnd.position - center),
        lessThan(0),
      );

      // The loop is a compact ring perched on the state: it never cuts
      // through it, and it does not sprawl wider than the state itself.
      for (var sample = 0; sample <= 40; sample++) {
        final point =
            metric.getTangentForOffset(metric.length * sample / 40)!.position;
        expect((point - center).distance, greaterThan(radius - 0.5));
      }
      expect(result.path.getBounds().longestSide, lessThan(radius * 2));
    });

    test('CurvedEdgeRenderer handles graph with self-loop edge', () {
      final graph = Graph();
      final node = Node.Id('self')
        ..size = const Size(40, 40)
        ..position = const Offset(100, 100);

      graph.addEdge(node, node);

      final renderer = CurvedEdgeRenderer();

      // This should not throw
      expect(() {
        // We can't actually render without a canvas, but we can verify
        // that the renderer is properly configured
        final edge = graph.edges.first;
        expect(edge.source, edge.destination);

        // Verify buildSelfLoopPath works for this edge
        final result = renderer.buildSelfLoopPath(edge);
        expect(result, isNotNull);
      }, returnsNormally);
    });

    test('CurvedEdgeRenderer handles multiple edges correctly', () {
      final graph = Graph();
      var node1 = Node.Id('One')
        ..size = const Size(40, 40)
        ..position = const Offset(0, 0);
      var node2 = Node.Id('Two')
        ..size = const Size(40, 40)
        ..position = const Offset(100, 0);
      var node3 = Node.Id('Three')
        ..size = const Size(40, 40)
        ..position = const Offset(50, 100);

      graph.addEdge(node1, node2);
      graph.addEdge(node2, node3);
      graph.addEdge(node3, node1);

      final renderer = CurvedEdgeRenderer();

      expect(graph.edges.length, 3);

      // Verify we can build paths for all edges
      for (var edge in graph.edges) {
        final source = edge.source;
        final destination = edge.destination;

        var startX = source.position.dx + source.width * 0.5;
        var startY = source.position.dy + source.height * 0.5;
        var stopX = destination.position.dx + destination.width * 0.5;
        var stopY = destination.position.dy + destination.height * 0.5;

        renderer.buildCurvedPath(startX, startY, stopX, stopY);

        final metrics = renderer.curvePath.computeMetrics().toList();
        expect(metrics, isNotEmpty);
        expect(metrics.first.length, greaterThan(0));
      }
    });

    test('buildCurvedPath creates perpendicular control point', () {
      final renderer = CurvedEdgeRenderer(curvature: 0.5);

      // Build a horizontal path
      renderer.buildCurvedPath(0, 50, 100, 50);

      final metrics = renderer.curvePath.computeMetrics().first;
      // Sample the middle of the curve
      final midTangent = metrics.getTangentForOffset(metrics.length * 0.5);

      expect(midTangent, isNotNull);

      // At the middle of the curve, the path should be curved (not perfectly horizontal)
      // The Y position should differ from the start/end Y position
      final midY = midTangent!.position.dy;
      expect(midY, isNot(equals(50.0)));
    });

    test('renderEdge honors explicit edge control point', () {
      final source = Node.Id('source')
        ..size = Size.zero
        ..position = Offset.zero;
      final destination = Node.Id('destination')
        ..size = Size.zero
        ..position = const Offset(100, 0);
      final edge = Edge(
        source,
        destination,
        controlPoint: const Offset(50, -80),
      );
      final renderer = CurvedEdgeRenderer();
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      renderer.renderEdge(canvas, edge, Paint());
      final picture = recorder.endRecording();

      addTearDown(picture.dispose);
      final metric = renderer.curvePath.computeMetrics().first;
      final midTangent = metric.getTangentForOffset(metric.length * 0.5);

      expect(midTangent, isNotNull);
      expect(midTangent!.position.dy, lessThan(-20));
    });

    test('buildCurvedPath with negative curvature curves opposite direction',
        () {
      final renderer1 = CurvedEdgeRenderer(curvature: 0.5);
      final renderer2 = CurvedEdgeRenderer(curvature: -0.5);

      // Build a horizontal path with positive curvature
      renderer1.buildCurvedPath(0, 50, 100, 50);
      final metrics1 = renderer1.curvePath.computeMetrics().first;
      final midTangent1 = metrics1.getTangentForOffset(metrics1.length * 0.5);

      // Build the same path with negative curvature
      renderer2.buildCurvedPath(0, 50, 100, 50);
      final metrics2 = renderer2.curvePath.computeMetrics().first;
      final midTangent2 = metrics2.getTangentForOffset(metrics2.length * 0.5);

      expect(midTangent1, isNotNull);
      expect(midTangent2, isNotNull);

      // The Y positions should be on opposite sides of the baseline
      final midY1 = midTangent1!.position.dy;
      final midY2 = midTangent2!.position.dy;

      expect((midY1 - 50) * (midY2 - 50), lessThan(0)); // Opposite signs
    });

    test('buildCurvedPath with zero curvature approaches straight line', () {
      final renderer = CurvedEdgeRenderer(curvature: 0.0);

      // Build a path with zero curvature
      renderer.buildCurvedPath(0, 0, 100, 100);

      final metrics = renderer.curvePath.computeMetrics().first;
      final straightLineDistance = sqrt(100 * 100 + 100 * 100); // ~141.42

      // With zero curvature, path length should be very close to straight line
      expect(metrics.length, closeTo(straightLineDistance, 0.1));
    });

    test('CurvedEdgeRenderer does not duplicate nodes for self loops', () {
      final graph = Graph();
      final node = Node.Id('self');

      graph.addEdge(node, node);

      expect(graph.nodes.length, 1);
      expect(graph.edges.length, 1);
      expect(graph.nodes.single, node);
    });
  });
}

double _radialComponent(Offset vector, Offset radial) =>
    (vector.dx * radial.dx) + (vector.dy * radial.dy);
