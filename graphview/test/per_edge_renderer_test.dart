import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Per-Edge Renderer', () {
    test('Edge can be created with custom renderer', () {
      final node1 = Node.Id('Node1');
      final node2 = Node.Id('Node2');
      final customRenderer = ArrowEdgeRenderer();

      final edge = Edge(node1, node2, renderer: customRenderer);

      expect(edge.renderer, isNotNull);
      expect(edge.renderer, equals(customRenderer));
    });

    test('Edge without custom renderer has null renderer', () {
      final node1 = Node.Id('Node1');
      final node2 = Node.Id('Node2');

      final edge = Edge(node1, node2);

      expect(edge.renderer, isNull);
    });

    test('Graph.addEdge can set custom renderer on edge', () {
      final graph = Graph();
      final node1 = Node.Id('Node1');
      final node2 = Node.Id('Node2');
      final customRenderer = CurvedEdgeRenderer();

      final edge = graph.addEdge(node1, node2, renderer: customRenderer);

      expect(edge.renderer, isNotNull);
      expect(edge.renderer, equals(customRenderer));
      expect(graph.edges.first.renderer, equals(customRenderer));
    });

    test('Multiple edges can have different custom renderers', () {
      final graph = Graph();
      final node1 = Node.Id('Node1');
      final node2 = Node.Id('Node2');
      final node3 = Node.Id('Node3');

      final arrowRenderer = ArrowEdgeRenderer();
      final curvedRenderer = CurvedEdgeRenderer();

      final edge1 = graph.addEdge(node1, node2, renderer: arrowRenderer);
      final edge2 = graph.addEdge(node2, node3, renderer: curvedRenderer);
      final edge3 = graph.addEdge(node3, node1);

      expect(edge1.renderer, equals(arrowRenderer));
      expect(edge2.renderer, equals(curvedRenderer));
      expect(edge3.renderer, isNull);
    });

    test('Self-loop edge can have custom renderer', () {
      final graph = Graph();
      final node = Node.Id('self');
      final customRenderer = ArrowEdgeRenderer(noArrow: true);

      final edge = graph.addEdge(node, node, renderer: customRenderer);

      expect(edge.renderer, isNotNull);
      expect(edge.renderer, equals(customRenderer));
      expect(graph.nodes.length, 1);
      expect(graph.edges.length, 1);
    });

    test('AnimatedEdgeRenderer can be used as custom renderer', () {
      final graph = Graph();
      final node1 = Node.Id('Node1');
      final node2 = Node.Id('Node2');

      final animatedRenderer = AnimatedEdgeRenderer(
        animationConfig: const AnimatedEdgeConfiguration(
          animationSpeed: 2.0,
          particleCount: 5,
          particleSize: 4.0,
        ),
      );

      final edge = graph.addEdge(node1, node2, renderer: animatedRenderer);

      expect(edge.renderer, equals(animatedRenderer));
      expect(
          (edge.renderer as AnimatedEdgeRenderer)
              .animationConfig
              .animationSpeed,
          2.0);
      expect(
          (edge.renderer as AnimatedEdgeRenderer).animationConfig.particleCount,
          5);
    });

    test(
        'CurvedEdgeRenderer with custom curvature can be used as custom renderer',
        () {
      final graph = Graph();
      final node1 = Node.Id('Node1');
      final node2 = Node.Id('Node2');

      final curvedRenderer = CurvedEdgeRenderer(curvature: 0.8);

      final edge = graph.addEdge(node1, node2, renderer: curvedRenderer);

      expect(edge.renderer, equals(curvedRenderer));
      expect((edge.renderer as CurvedEdgeRenderer).curvature, 0.8);
    });

    test('Edge renderer is preserved when edge is added to graph', () {
      final graph = Graph();
      final node1 = Node.Id('Node1');
      final node2 = Node.Id('Node2');
      final customRenderer = ArrowEdgeRenderer(noArrow: true);

      final edge = Edge(node1, node2, renderer: customRenderer);
      graph.addEdgeS(edge);

      expect(graph.edges.first.renderer, equals(customRenderer));
      expect(graph.edges.first.renderer, same(edge.renderer));
    });

    test('Edge custom renderer works with edge paint', () {
      final graph = Graph();
      final node1 = Node.Id('Node1');
      final node2 = Node.Id('Node2');
      final customPaint = Paint()..color = Colors.red;
      final customRenderer = CurvedEdgeRenderer();

      final edge = graph.addEdge(
        node1,
        node2,
        paint: customPaint,
        renderer: customRenderer,
      );

      expect(edge.paint, equals(customPaint));
      expect(edge.renderer, equals(customRenderer));
    });

    test('Edge custom renderer works with edge label', () {
      final graph = Graph();
      final node1 = Node.Id('Node1');
      final node2 = Node.Id('Node2');
      final customRenderer = CurvedEdgeRenderer();

      final edge = graph.addEdge(
        node1,
        node2,
        label: 'Test Label',
        labelStyle: const TextStyle(fontSize: 14),
        renderer: customRenderer,
      );

      expect(edge.label, equals('Test Label'));
      expect(edge.renderer, equals(customRenderer));
    });

    test('Graph with mixed renderer and non-renderer edges', () {
      final graph = Graph();
      final node1 = Node.Id('Node1');
      final node2 = Node.Id('Node2');
      final node3 = Node.Id('Node3');
      final node4 = Node.Id('Node4');

      final customRenderer = ArrowEdgeRenderer(noArrow: true);

      graph.addEdge(node1, node2, renderer: customRenderer);
      graph.addEdge(node2, node3);
      graph.addEdge(node3, node4, renderer: customRenderer);
      graph.addEdge(node4, node1);

      final edgesWithRenderer =
          graph.edges.where((e) => e.renderer != null).toList();
      final edgesWithoutRenderer =
          graph.edges.where((e) => e.renderer == null).toList();

      expect(edgesWithRenderer.length, 2);
      expect(edgesWithoutRenderer.length, 2);
    });

    test('Edge renderer survives node removal from graph', () {
      final graph = Graph();
      final node1 = Node.Id('Node1');
      final node2 = Node.Id('Node2');
      final node3 = Node.Id('Node3');
      final customRenderer = CurvedEdgeRenderer();

      graph.addEdge(node1, node2, renderer: customRenderer);
      final edge2 = graph.addEdge(node2, node3, renderer: customRenderer);

      graph.removeNode(node1);

      expect(graph.edges.length, 1);
      expect(graph.edges.first, equals(edge2));
      expect(graph.edges.first.renderer, equals(customRenderer));
    });

    test('Different edge renderer types can coexist in same graph', () {
      final graph = Graph();
      final node1 = Node.Id('Node1');
      final node2 = Node.Id('Node2');
      final node3 = Node.Id('Node3');
      final node4 = Node.Id('Node4');

      final arrowRenderer = ArrowEdgeRenderer();
      final curvedRenderer = CurvedEdgeRenderer(curvature: 0.6);
      final animatedRenderer = AnimatedEdgeRenderer();

      graph.addEdge(node1, node2, renderer: arrowRenderer);
      graph.addEdge(node2, node3, renderer: curvedRenderer);
      graph.addEdge(node3, node4, renderer: animatedRenderer);

      expect(graph.edges[0].renderer, isA<ArrowEdgeRenderer>());
      expect(graph.edges[1].renderer, isA<CurvedEdgeRenderer>());
      expect(graph.edges[2].renderer, isA<AnimatedEdgeRenderer>());
    });
  });
}
