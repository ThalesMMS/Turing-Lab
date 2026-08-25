import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:graphview/GraphView.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Graph', () {
    test('Graph Node counts are correct', () {
      final graph = Graph();
      var node1 = Node.Id('One');
      var node2 = Node.Id('Two');
      var node3 = Node.Id('Three');
      var node4 = Node.Id('Four');
      var node5 = Node.Id('Five');
      var node6 = Node.Id('Six');
      var node7 = Node.Id('Seven');
      var node8 = Node.Id('Eight');
      var node9 = Node.Id('Nine');

      graph.addEdge(node1, node2);
      graph.addEdge(node1, node4);
      graph.addEdge(node2, node3);
      graph.addEdge(node2, node5);
      graph.addEdge(node3, node6);
      graph.addEdge(node4, node5);
      graph.addEdge(node4, node7);
      graph.addEdge(node5, node6);
      graph.addEdge(node5, node8);
      graph.addEdge(node6, node9);
      graph.addEdge(node7, node8);
      graph.addEdge(node8, node9);

      expect(graph.nodeCount(), 9);

      graph.removeNode(Node.Id('One'));
      graph.removeNode(Node.Id('Ten'));

      expect(graph.nodeCount(), 8);

      graph.addNode(Node.Id('Ten'));

      expect(graph.nodeCount(), 9);
    });

    test('calculateGraphBounds returns zero rect for empty graph', () {
      final graph = Graph();

      expect(graph.calculateGraphBounds(), Rect.zero);
      expect(graph.calculateGraphSize(), Size.zero);
    });

    test('addNode ignores duplicate logical nodes', () {
      final graph = Graph();
      final node = Node.Id('duplicate');

      graph.addNode(node);
      final generation = graph.generation;
      graph.addNode(Node.Id('duplicate'));

      expect(graph.nodeCount(), 1);
      expect(graph.generation, generation);
    });

    test('keyless nodes compare by identity', () {
      final graph = Graph();
      final first = Node.Id('first')..key = null;
      final second = Node.Id('second')..key = null;

      graph.addNode(first);
      graph.addNode(second);

      expect(first == second, isFalse);
      expect(graph.nodeCount(), 2);
    });

    test('getNodeAtPosition throws clear bounds errors', () {
      final graph = Graph();
      graph.addNode(Node.Id('only'));

      expect(() => graph.getNodeAtPosition(-1), throwsRangeError);
      expect(() => graph.getNodeAtPosition(1), throwsRangeError);
    });

    test('addEdge allows distinct parallel edges', () {
      final graph = Graph();
      final source = Node.Id('source');
      final destination = Node.Id('destination');

      graph.addEdge(source, destination, label: 'first');
      graph.addEdge(source, destination, label: 'second');
      graph.addEdge(source, destination, controlPoint: const Offset(10, 20));
      graph.addEdge(source, destination, label: 'first');

      expect(graph.edges.length, 3);
      expect(graph.edges.map((edge) => edge.label), contains('first'));
      expect(graph.edges.map((edge) => edge.label), contains('second'));
      expect(
        graph.edges.any((edge) => edge.controlPoint == const Offset(10, 20)),
        true,
      );
    });

    test('removeEdgeFromPredecessor bumps generation when edges are removed',
        () {
      final graph = Graph();
      final observer = _RecordingGraphObserver();
      graph.graphObserver.add(observer);
      final source = Node.Id('source');
      final destination = Node.Id('destination');
      graph.addEdge(source, destination);
      final generation = graph.generation;
      observer.notifications = 0;

      graph.removeEdgeFromPredecessor(source, destination);

      expect(graph.edges, isEmpty);
      expect(graph.generation, generation + 1);
      expect(observer.notifications, 1);
    });

    test('removeEdge notifies graph observers when an edge is removed', () {
      final graph = Graph();
      final observer = _RecordingGraphObserver();
      graph.graphObserver.add(observer);
      final edge = graph.addEdge(Node.Id('source'), Node.Id('destination'));
      observer.notifications = 0;

      graph.removeEdge(edge);

      expect(graph.edges, isEmpty);
      expect(observer.notifications, 1);
    });

    test('markModified notifies graph observers', () {
      final graph = Graph();
      final observer = _RecordingGraphObserver();
      graph.graphObserver.add(observer);
      final node = Node.Id('source');
      graph.addNode(node);
      observer.notifications = 0;
      final generation = graph.generation;

      node.position = const Offset(10, 20);
      graph.markModified();

      expect(graph.generation, generation + 1);
      expect(observer.notifications, 1);
    });

    test('toJson uses stable node identifiers', () {
      final graph = Graph();
      final source = Node.Id('source');
      final destination = Node.Id('destination');

      graph.addEdge(source, destination);

      final output = jsonDecode(graph.toJson()) as Map<String, dynamic>;

      expect(output['nodes'], ['source', 'destination']);
      expect(output['edges'], [
        {'from': 'source', 'to': 'destination'}
      ]);
    });

    test('Node Hash Implementation is performant', () {
      final graph = Graph();

      var rows = 1000000;

      var integerNode = Node.Id(1);
      var stringNode = Node.Id('123');
      var stringNode2 = Node.Id('G9Q84H1R9-1619338713.000900');
      var widgetNode = Node.Id(Text('Lovely'));
      var widgetNode2 = Node.Id(Text('Lovely'));
      var doubleNode = Node.Id(5.6);

      graph.addEdge(integerNode, Node.Id(4));

      var nodes = [
        integerNode,
        stringNode,
        stringNode2,
        widgetNode,
        widgetNode2,
        doubleNode
      ];

      for (var node in nodes) {
        var stopwatch = Stopwatch()..start();
        for (var i = 1; i <= rows; i++) {
          node.hashCode;
        }
        var timeTaken = stopwatch.elapsed.inMilliseconds;
        print('Time taken: $timeTaken ms for ${node.runtimeType} node');
        expect(timeTaken < 100, true);
      }
    });

    test('Graph does not duplicate nodes for self loops', () {
      final graph = Graph();
      final node = Node.Id('self');

      graph.addEdge(node, node);

      expect(graph.nodes.length, 1);
      expect(graph.edges.length, 1);
      expect(graph.nodes.single, node);
    });

    test('ArrowEdgeRenderer builds self-loop path', () {
      final renderer = ArrowEdgeRenderer();
      final node = Node.Id('self')
        ..size = const Size(40, 40)
        ..position = const Offset(100, 100);

      final edge = Edge(node, node);
      final result = renderer.buildSelfLoopPath(edge);

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

    test('SugiyamaAlgorithm handles single node self loop', () {
      final graph = Graph();
      final node = Node.Id('self')..size = const Size(40, 40);

      graph.addEdge(node, node);

      final config = SugiyamaConfiguration()
        ..nodeSeparation = 20
        ..levelSeparation = 20;

      final algorithm = SugiyamaAlgorithm(config);

      expect(() => algorithm.run(graph, 0, 0), returnsNormally);
      expect(graph.nodes.length, 1);
    });
  });
}

class _RecordingGraphObserver implements GraphObserver {
  int notifications = 0;

  @override
  void notifyGraphInvalidated() {
    notifications++;
  }
}

double _radialComponent(Offset vector, Offset radial) =>
    (vector.dx * radial.dx) + (vector.dy * radial.dy);
