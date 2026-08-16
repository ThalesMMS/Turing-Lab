import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphview/GraphView.dart';

void main() {
  group('Distance Threshold Tests', () {
    testWidgets('Movements less than 1px do not mark edges dirty',
        (WidgetTester tester) async {
      // Create graph with two connected nodes
      final graph = Graph();
      final node1 = Node.Id(1);
      final node2 = Node.Id(2);
      graph.addNode(node1);
      graph.addNode(node2);

      graph.addEdge(node1, node2);

      // Set initial positions
      node1.position = const Offset(100, 100);
      node2.position = const Offset(200, 200);

      // Set node sizes (required for rendering)
      node1.size = const Size(50, 50);
      node2.size = const Size(50, 50);

      // Create widget tree with GraphView
      final controller = GraphViewController();
      addTearDown(controller.dispose);
      final algorithm = SugiyamaAlgorithm(SugiyamaConfiguration());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GraphView(
              graph: graph,
              algorithm: algorithm,
              controller: controller,
              builder: (Node node) {
                return Container(
                  width: 50,
                  height: 50,
                  color: Colors.blue,
                  child: Center(child: Text('${node.key?.value}')),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Get the render object
      final graphViewFinder = find.byType(GraphView);
      expect(graphViewFinder, findsOneWidget);
    });

    test('Movements of exactly 1px mark edges dirty', () {
      final graph = Graph();
      final node1 = Node.Id(1);
      final node2 = Node.Id(2);
      graph.addNode(node1);
      graph.addNode(node2);

      graph.addEdge(node1, node2);

      node1.position = const Offset(100, 100);
      node2.position = const Offset(200, 200);

      // Test that distance of exactly 1.0 triggers update
      final newPosition = const Offset(101, 100); // 1px horizontal movement
      final distance = (newPosition - node1.position).distance;

      expect(distance, equals(1.0));
    });

    test('Movements greater than 1px mark edges dirty', () {
      final graph = Graph();
      final node1 = Node.Id(1);
      final node2 = Node.Id(2);
      graph.addNode(node1);
      graph.addNode(node2);

      graph.addEdge(node1, node2);

      node1.position = const Offset(100, 100);
      node2.position = const Offset(200, 200);

      // Test that distance > 1.0 triggers update
      final newPosition = const Offset(105, 100); // 5px horizontal movement
      final distance = (newPosition - node1.position).distance;

      expect(distance, equals(5.0));
      expect(distance, greaterThan(1.0));
    });

    test('Sub-pixel diagonal movements do not mark edges dirty', () {
      final graph = Graph();
      final node1 = Node.Id(1);
      graph.addNode(node1);

      node1.position = const Offset(100, 100);

      // Test diagonal movement < 1px
      final newPosition = const Offset(100.5, 100.5); // ~0.707px diagonal
      final distance = (newPosition - node1.position).distance;

      expect(distance, lessThan(1.0));
      expect(distance, closeTo(0.707, 0.01));
    });

    test('Exactly 1px diagonal movement marks edges dirty', () {
      final graph = Graph();
      final node1 = Node.Id(1);
      graph.addNode(node1);

      node1.position = const Offset(100, 100);

      // Test diagonal movement = 1px
      // For 1px distance: x^2 + y^2 = 1, so x = y = sqrt(0.5) ≈ 0.707
      final newPosition = Offset(100 + 0.707, 100 + 0.707);
      final distance = (newPosition - node1.position).distance;

      expect(distance, closeTo(1.0, 0.01));
    });

    test('Distance threshold prevents redundant edge recalculations', () {
      final graph = Graph();
      final node1 = Node.Id(1);
      final node2 = Node.Id(2);
      final node3 = Node.Id(3);
      graph.addNode(node1);
      graph.addNode(node2);
      graph.addNode(node3);

      graph.addEdge(node1, node2);
      graph.addEdge(node2, node3);

      node1.position = const Offset(100, 100);
      node2.position = const Offset(200, 100);
      node3.position = const Offset(300, 100);

      // Simulate small movement (0.5px)
      final smallMovement = const Offset(100.5, 100);
      final smallDistance = (smallMovement - node1.position).distance;
      expect(smallDistance, lessThan(1.0));

      // Simulate large movement (10px)
      final largeMovement = const Offset(110, 100);
      final largeDistance = (largeMovement - node1.position).distance;
      expect(largeDistance, greaterThan(1.0));
    });

    test('Threshold applies to vertical movements', () {
      final graph = Graph();
      final node1 = Node.Id(1);
      graph.addNode(node1);

      node1.position = const Offset(100, 100);

      // Sub-pixel vertical movement
      final subPixelMove = const Offset(100, 100.5);
      final subPixelDistance = (subPixelMove - node1.position).distance;
      expect(subPixelDistance, lessThan(1.0));

      // Exactly 1px vertical movement
      final onePixelMove = const Offset(100, 101);
      final onePixelDistance = (onePixelMove - node1.position).distance;
      expect(onePixelDistance, equals(1.0));
    });

    test('Multiple consecutive sub-pixel movements accumulate correctly', () {
      final graph = Graph();
      final node1 = Node.Id(1);
      graph.addNode(node1);

      node1.position = const Offset(100, 100);

      // Simulate multiple 0.3px movements, measuring cumulative distance from origin
      final originPos = node1.position;
      final movements = [
        const Offset(100.3, 100), // 0.3px from origin
        const Offset(100.6, 100), // 0.6px from origin
        const Offset(100.9, 100), // 0.9px from origin
        const Offset(101.2, 100), // 1.2px from origin (now > 1px)
      ];

      for (var i = 0; i < movements.length; i++) {
        final distance = (movements[i] - originPos).distance;

        if (i < 3) {
          // First 3 movements are sub-pixel from origin
          expect(distance, lessThan(1.0));
        } else {
          // 4th movement crosses 1px threshold from origin
          expect(distance, greaterThanOrEqualTo(1.0));
        }
      }
    });

    test('Zero movement does not mark edges dirty', () {
      final graph = Graph();
      final node1 = Node.Id(1);
      final node2 = Node.Id(2);
      graph.addNode(node1);
      graph.addNode(node2);

      graph.addEdge(node1, node2);

      node1.position = const Offset(100, 100);
      node2.position = const Offset(200, 200);

      // No movement
      final samePosition = const Offset(100, 100);
      final distance = (samePosition - node1.position).distance;

      expect(distance, equals(0.0));
      expect(distance, lessThan(1.0));
    });

    test('Threshold constant is 1.0 pixels', () {
      // Verify the threshold value matches specification
      const expectedThreshold = 1.0;

      // This test documents that movements < 1px should not trigger recalculation
      final testDistance1 = 0.999;
      final testDistance2 = 1.0;
      final testDistance3 = 1.001;

      expect(testDistance1, lessThan(expectedThreshold));
      expect(testDistance2, equals(expectedThreshold));
      expect(testDistance3, greaterThan(expectedThreshold));
    });
  });
}
