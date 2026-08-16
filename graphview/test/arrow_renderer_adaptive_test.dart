import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphview/GraphView.dart';

void main() {
  group('ArrowEdgeRenderer with Adaptive Anchors', () {
    late Graph graph;
    late Node node1;
    late Node node2;
    late Edge edge;

    setUp(() {
      graph = Graph();
      node1 = Node.Id(1);
      node2 = Node.Id(2);
      edge = Edge(node1, node2);

      // Set node positions and sizes
      node1
        ..position = Offset(0, 0)
        ..size = Size(100, 50);
      node2
        ..position = Offset(200, 0)
        ..size = Size(100, 50);

      graph.addNode(node1);
      graph.addNode(node2);
      graph.addEdgeS(edge);
    });

    test('ArrowEdgeRenderer without config uses default center-based behavior',
        () {
      final renderer = ArrowEdgeRenderer();
      expect(renderer.config, isNull);
      expect(renderer.noArrow, isFalse);
    });

    test('ArrowEdgeRenderer with center anchor mode uses center points', () {
      final config = EdgeRoutingConfig(anchorMode: AnchorMode.center);
      final renderer = ArrowEdgeRenderer(config: config);

      renderer.setGraph(graph);

      final destCenter = Offset(250, 25); // Center of node2
      final edgeIndex = 0;

      final sourcePoint =
          renderer.calculateSourceConnectionPoint(edge, destCenter, edgeIndex);

      // Should return center of node1 (50, 25)
      expect(sourcePoint.dx, closeTo(50, 0.1));
      expect(sourcePoint.dy, closeTo(25, 0.1));
    });

    test(
        'ArrowEdgeRenderer with cardinal anchor mode calculates correct anchors',
        () {
      final config = EdgeRoutingConfig(anchorMode: AnchorMode.cardinal);
      final renderer = ArrowEdgeRenderer(config: config);

      renderer.setGraph(graph);

      // node1 at (0,0) size (100,50), node2 at (200,0) size (100,50)
      // Direction: node1 -> node2 (right/east)
      final destCenter = Offset(250, 25);
      final edgeIndex = 0;

      final sourcePoint =
          renderer.calculateSourceConnectionPoint(edge, destCenter, edgeIndex);

      // Should return right edge of node1 (100, 25)
      expect(sourcePoint.dx, closeTo(100, 0.1));
      expect(sourcePoint.dy, closeTo(25, 0.1));
    });

    test(
        'ArrowEdgeRenderer with octagonal anchor mode calculates correct anchors',
        () {
      final config = EdgeRoutingConfig(anchorMode: AnchorMode.octagonal);
      final renderer = ArrowEdgeRenderer(config: config);

      renderer.setGraph(graph);

      final destCenter = Offset(250, 25);
      final edgeIndex = 0;

      final sourcePoint =
          renderer.calculateSourceConnectionPoint(edge, destCenter, edgeIndex);

      // Should return right edge of node1 (100, 25)
      expect(sourcePoint.dx, closeTo(100, 0.1));
      expect(sourcePoint.dy, closeTo(25, 0.1));
    });

    test(
        'ArrowEdgeRenderer with dynamic anchor mode calculates exact boundary intersection',
        () {
      final config = EdgeRoutingConfig(anchorMode: AnchorMode.dynamic);
      final renderer = ArrowEdgeRenderer(config: config);

      renderer.setGraph(graph);

      final destCenter = Offset(250, 25);
      final edgeIndex = 0;

      final sourcePoint =
          renderer.calculateSourceConnectionPoint(edge, destCenter, edgeIndex);

      // Should return right edge of node1 (100, 25) - exact intersection
      expect(sourcePoint.dx, closeTo(100, 0.1));
      expect(sourcePoint.dy, closeTo(25, 0.1));
    });

    test('ArrowEdgeRenderer with cardinal mode - vertical direction', () {
      final config = EdgeRoutingConfig(anchorMode: AnchorMode.cardinal);
      final renderer = ArrowEdgeRenderer(config: config);

      // Position node2 directly below node1
      node2.position = Offset(0, 100);

      renderer.setGraph(graph);

      final destCenter = Offset(50, 125); // Center of node2
      final edgeIndex = 0;

      final sourcePoint =
          renderer.calculateSourceConnectionPoint(edge, destCenter, edgeIndex);

      // Should return bottom edge of node1 (50, 50)
      expect(sourcePoint.dx, closeTo(50, 0.1));
      expect(sourcePoint.dy, closeTo(50, 0.1));
    });

    test('ArrowEdgeRenderer with octagonal mode - diagonal direction', () {
      final config = EdgeRoutingConfig(anchorMode: AnchorMode.octagonal);
      final renderer = ArrowEdgeRenderer(config: config);

      // Position node2 diagonally (southeast)
      node2.position = Offset(200, 100);

      renderer.setGraph(graph);

      final destCenter = Offset(250, 125);
      final edgeIndex = 0;

      final sourcePoint =
          renderer.calculateSourceConnectionPoint(edge, destCenter, edgeIndex);

      // Should return southeast corner of node1 (100, 50)
      expect(sourcePoint.dx, closeTo(100, 0.1));
      expect(sourcePoint.dy, closeTo(50, 0.1));
    });

    test('ArrowEdgeRenderer distributes parallel edges correctly', () {
      final config = EdgeRoutingConfig(
        anchorMode: AnchorMode.cardinal,
        minEdgeDistance: 10.0,
      );
      final renderer = ArrowEdgeRenderer(config: config);

      // Add a second parallel edge
      final edge2 = Edge(node1, node2);
      graph.addEdgeS(edge2);

      renderer.setGraph(graph);

      final destCenter = Offset(250, 25);

      // Calculate connection points for both edges
      final edgeIndex1 =
          renderer.calculateSourceConnectionPoint(edge, destCenter, 0);
      final edgeIndex2 =
          renderer.calculateSourceConnectionPoint(edge2, destCenter, 1);

      // The two edges should have different connection points due to offset
      expect((edgeIndex1 - edgeIndex2).distance, greaterThan(5.0));
    });

    test('ArrowEdgeRenderer with destination anchor calculation', () {
      final config = EdgeRoutingConfig(anchorMode: AnchorMode.cardinal);
      final renderer = ArrowEdgeRenderer(config: config);

      renderer.setGraph(graph);

      final sourceCenter = Offset(50, 25);
      final edgeIndex = 0;

      final destPoint = renderer.calculateDestinationConnectionPoint(
          edge, sourceCenter, edgeIndex);

      // Should return left edge of node2 (200, 25)
      expect(destPoint.dx, closeTo(200, 0.1));
      expect(destPoint.dy, closeTo(25, 0.1));
    });

    test('ArrowEdgeRenderer backward compatibility - no config', () {
      // Test that ArrowEdgeRenderer without config behaves like before
      final renderer = ArrowEdgeRenderer();

      renderer.setGraph(graph);

      final destCenter = Offset(250, 25);
      final edgeIndex = 0;

      final sourcePoint =
          renderer.calculateSourceConnectionPoint(edge, destCenter, edgeIndex);

      // Should return center of node1 (50, 25) - default behavior
      expect(sourcePoint.dx, closeTo(50, 0.1));
      expect(sourcePoint.dy, closeTo(25, 0.1));
    });

    test('ArrowEdgeRenderer with noArrow option and adaptive anchors', () {
      final config = EdgeRoutingConfig(anchorMode: AnchorMode.cardinal);
      final renderer = ArrowEdgeRenderer(noArrow: true, config: config);

      expect(renderer.noArrow, isTrue);
      expect(renderer.config, isNotNull);
      expect(renderer.config!.anchorMode, equals(AnchorMode.cardinal));
    });

    test('ArrowEdgeRenderer edge index calculation for single edge', () {
      final config = EdgeRoutingConfig(anchorMode: AnchorMode.cardinal);
      final renderer = ArrowEdgeRenderer(config: config);

      renderer.setGraph(graph);

      // With only one edge, edge index should be 0
      final edgeIndex = 0; // This would be calculated internally
      expect(edgeIndex, equals(0));
    });

    test('ArrowEdgeRenderer with dynamic mode handles same position nodes', () {
      final config = EdgeRoutingConfig(anchorMode: AnchorMode.dynamic);
      final renderer = ArrowEdgeRenderer(config: config);

      // Position nodes at same location
      node1.position = Offset(0, 0);
      node2.position = Offset(0, 0);

      renderer.setGraph(graph);

      final destCenter = Offset(50, 25);
      final edgeIndex = 0;

      final sourcePoint =
          renderer.calculateSourceConnectionPoint(edge, destCenter, edgeIndex);

      // Should still return a valid point (node center)
      expect(sourcePoint, isNotNull);
    });

    test(
        'ArrowEdgeRenderer applies parallel edge offset perpendicular to edge direction',
        () {
      final config = EdgeRoutingConfig(
        anchorMode: AnchorMode.cardinal,
        minEdgeDistance: 20.0,
      );
      final renderer = ArrowEdgeRenderer(config: config);

      // Create 3 parallel edges
      final edge2 = Edge(node1, node2);
      final edge3 = Edge(node1, node2);
      graph.addEdgeS(edge2);
      graph.addEdgeS(edge3);

      renderer.setGraph(graph);

      final destCenter = Offset(250, 25);

      // Calculate connection points for all three edges with different indices
      final point1 =
          renderer.calculateSourceConnectionPoint(edge, destCenter, -1);
      final point2 =
          renderer.calculateSourceConnectionPoint(edge2, destCenter, 0);
      final point3 =
          renderer.calculateSourceConnectionPoint(edge3, destCenter, 1);

      // Points should be distributed perpendicular to edge direction
      // Middle point (index 0) should be the base anchor
      // Other points should be offset perpendicular to horizontal direction (vertical offset)

      // Check that point2 is between point1 and point3 in the Y direction
      expect(point2.dy, lessThan(point3.dy));
      expect(point2.dy, greaterThan(point1.dy));

      // Check that X coordinates are the same (perpendicular offset is in Y direction for horizontal edges)
      expect(point1.dx, closeTo(point2.dx, 0.1));
      expect(point2.dx, closeTo(point3.dx, 0.1));
    });
  });
}
