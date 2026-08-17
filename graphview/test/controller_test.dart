import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphview/GraphView.dart';

SugiyamaAlgorithm buildTestAlgorithm() =>
    SugiyamaAlgorithm(SugiyamaConfiguration());

Widget buildOverlappingControllerViews({
  required Graph graph,
  required GraphViewController controller,
  required bool includeOldView,
  required bool includeCurrentView,
}) {
  Widget buildView(String id) {
    return Positioned.fill(
      key: ValueKey(id),
      child: GraphView.builder(
        graph: graph,
        algorithm: buildTestAlgorithm(),
        controller: controller,
        builder: (node) => const SizedBox(width: 20, height: 20),
      ),
    );
  }

  return MaterialApp(
    home: Scaffold(
      body: Stack(
        children: [
          if (includeOldView) buildView('old-view'),
          if (includeCurrentView) buildView('current-view'),
        ],
      ),
    ),
  );
}

Future<void> pumpOldThenOverlappingView(
  WidgetTester tester, {
  required Graph graph,
  required GraphViewController controller,
}) async {
  await tester.pumpWidget(
    buildOverlappingControllerViews(
      graph: graph,
      controller: controller,
      includeOldView: true,
      includeCurrentView: false,
    ),
  );
  await tester.pumpAndSettle();
  await tester.pumpWidget(
    buildOverlappingControllerViews(
      graph: graph,
      controller: controller,
      includeOldView: true,
      includeCurrentView: true,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('GraphView Controller Tests', () {
    testWidgets('initial viewport scale respects a minimum above one', (
      WidgetTester tester,
    ) async {
      final graph = Graph()..addNode(Node.Id('target'));

      await tester.pumpWidget(
        MaterialApp(
          home: GraphView.builder(
            graph: graph,
            algorithm: buildTestAlgorithm(),
            minScale: 1.5,
            maxScale: 2,
            builder: (_) => const SizedBox(width: 20, height: 20),
          ),
        ),
      );
      await tester.pump();

      final viewer = tester.widget<InteractiveViewer>(
        find.byType(InteractiveViewer),
      );
      expect(
        viewer.transformationController!.value.getMaxScaleOnAxis(),
        closeTo(1.5, 0.001),
      );
    });

    testWidgets('reset viewport scale respects configured bounds', (
      WidgetTester tester,
    ) async {
      final graph = Graph()..addNode(Node.Id('target'));
      final transformationController = TransformationController(
        Matrix4.diagonal3Values(2, 2, 1)..setTranslationRaw(40, 60, 0),
      );
      final controller = GraphViewController(
        transformationController: transformationController,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: GraphView.builder(
            graph: graph,
            algorithm: buildTestAlgorithm(),
            controller: controller,
            minScale: 1.5,
            maxScale: 2,
            builder: (_) => const SizedBox(width: 20, height: 20),
          ),
        ),
      );
      await tester.pumpAndSettle();

      controller.resetView();
      await tester.pumpAndSettle();

      expect(
        transformationController.value.getMaxScaleOnAxis(),
        closeTo(1.5, 0.001),
      );
      expect(
          transformationController.value.getTranslation().x, closeTo(0, 0.001));
      expect(
          transformationController.value.getTranslation().y, closeTo(0, 0.001));

      await tester.pumpWidget(const SizedBox.shrink());
      transformationController.dispose();
    });

    testWidgets('animateToNode centers the target node',
        (WidgetTester tester) async {
      // Setup graph
      final graph = Graph();
      final targetNode = Node.Id('target');
      targetNode.key = const ValueKey('target');
      final otherNode = Node.Id('other');

      graph.addEdge(targetNode, otherNode);

      final transformationController = TransformationController();
      final controller = GraphViewController(
          transformationController: transformationController);
      final algorithm = buildTestAlgorithm();

      // Build widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: GraphView.builder(
                graph: graph,
                algorithm: algorithm,
                controller: controller,
                builder: (node) => Container(
                  width: 100,
                  height: 50,
                  color: Colors.blue,
                  child: Text(node.key?.value ?? ''),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Get the actual position of target node after algorithm runs
      final actualNodePosition = targetNode.position;
      final nodeCenter = Offset(
        actualNodePosition.dx + targetNode.width / 2,
        actualNodePosition.dy + targetNode.height / 2,
      );

      // Get initial transformation
      final initialMatrix = transformationController.value;

      // Animate to target node
      controller.animateToNode(const ValueKey('target'));

      // Let animation complete
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Verify transformation changed
      final finalMatrix = transformationController.value;
      expect(finalMatrix, isNot(equals(initialMatrix)));

      // With viewport size 400x600, center should be at (200, 300)
      // Expected translation should center the node at viewport center
      final expectedTranslationX =
          200 - nodeCenter.dx; // viewport_center_x - node_center_x
      final expectedTranslationY =
          300 - nodeCenter.dy; // viewport_center_y - node_center_y

      expect(finalMatrix.getTranslation().x, closeTo(expectedTranslationX, 5));
      expect(finalMatrix.getTranslation().y, closeTo(expectedTranslationY, 5));
    });

    testWidgets('animateToNode handles non-existent node gracefully',
        (WidgetTester tester) async {
      final graph = Graph();
      final node = Node.Id('exists');
      graph.nodes.add(node);

      final transformationController = TransformationController();
      final controller = GraphViewController(
          transformationController: transformationController);
      final algorithm = buildTestAlgorithm();

      await tester.pumpWidget(
        MaterialApp(
          home: GraphView.builder(
            graph: graph,
            algorithm: algorithm,
            controller: controller,
            builder: (node) => Container(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final initialMatrix = transformationController.value;

      // Try to animate to non-existent node
      controller.animateToNode(const ValueKey('nonexistent'));
      await tester.pumpAndSettle();

      // Matrix should remain unchanged
      final finalMatrix = transformationController.value;
      expect(finalMatrix, equals(initialMatrix));
    });

    testWidgets('jumpToFocusedNode centers the focused node',
        (WidgetTester tester) async {
      final graph = Graph();
      final targetNode = Node.Id('target');
      targetNode.key = const ValueKey('target');
      final otherNode = Node.Id('other');

      graph.addEdge(targetNode, otherNode);

      final transformationController = TransformationController();
      final controller = GraphViewController(
          transformationController: transformationController);
      final algorithm = buildTestAlgorithm();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: GraphView.builder(
                graph: graph,
                algorithm: algorithm,
                controller: controller,
                builder: (node) => Container(
                  width: 100,
                  height: 50,
                  color: Colors.blue,
                  child: Text(node.key?.value ?? ''),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final nodeCenter = Offset(
        targetNode.position.dx + targetNode.width / 2,
        targetNode.position.dy + targetNode.height / 2,
      );

      controller.focusedNode = targetNode;
      controller.jumpToFocusedNode();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      final matrix = transformationController.value;
      expect(matrix.getTranslation().x, closeTo(200 - nodeCenter.dx, 5));
      expect(matrix.getTranslation().y, closeTo(300 - nodeCenter.dy, 5));
      expect(controller.focusedNode, isNull);
    });

    testWidgets('does not dispose caller-owned transformation controller',
        (WidgetTester tester) async {
      final graph = Graph();
      final node = Node.Id('target');
      graph.addNode(node);

      final transformationController = TransformationController();
      final controller = GraphViewController(
          transformationController: transformationController);

      await tester.pumpWidget(
        MaterialApp(
          home: GraphView.builder(
            graph: graph,
            algorithm: buildTestAlgorithm(),
            controller: controller,
            builder: (node) => const SizedBox(width: 20, height: 20),
          ),
        ),
      );

      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();

      expect(
        () => transformationController.value = Matrix4.identity(),
        returnsNormally,
      );

      transformationController.dispose();
    });

    testWidgets(
        'keeps owned transformation controller alive until the controller '
        'is disposed', (WidgetTester tester) async {
      final graph = Graph();
      final node = Node.Id('target');
      graph.addNode(node);

      final transformationController = TransformationController();
      final controller = GraphViewController(
        transformationController: transformationController,
        ownsTransformationController: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: GraphView.builder(
            graph: graph,
            algorithm: buildTestAlgorithm(),
            controller: controller,
            builder: (node) => const SizedBox(width: 20, height: 20),
          ),
        ),
      );

      await tester.pumpWidget(const SizedBox.shrink());

      // The view detaching must not dispose an owned controller: the
      // GraphViewController may still be reattached to another view.
      expect(
        () => transformationController.value = Matrix4.identity(),
        returnsNormally,
      );

      controller.dispose();

      expect(
        () => transformationController.value = Matrix4.identity()
          ..translateByDouble(1.0, 0.0, 0.0, 1.0),
        throwsFlutterError,
      );

      // Disposing again is a no-op.
      expect(controller.dispose, returnsNormally);
    });

    testWidgets(
        'defers owned transformation controller disposal while a view is '
        'attached', (WidgetTester tester) async {
      final graph = Graph();
      final node = Node.Id('target');
      graph.addNode(node);

      final transformationController = TransformationController();
      final controller = GraphViewController(
        transformationController: transformationController,
        ownsTransformationController: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: GraphView.builder(
            graph: graph,
            algorithm: buildTestAlgorithm(),
            controller: controller,
            builder: (node) => const SizedBox(width: 20, height: 20),
          ),
        ),
      );

      // Dispose while the view is still attached: the transformation
      // controller must stay usable until the view detaches.
      controller.dispose();
      expect(
        () => transformationController.value = Matrix4.identity(),
        returnsNormally,
      );

      await tester.pumpWidget(const SizedBox.shrink());

      expect(
        () => transformationController.value = Matrix4.identity()
          ..translateByDouble(1.0, 0.0, 0.0, 1.0),
        throwsFlutterError,
      );
    });

    testWidgets('reattaches when the GraphView controller changes',
        (WidgetTester tester) async {
      final graph = Graph();
      final node = Node.Id('target');
      graph.addNode(node);

      final firstTransformationController = TransformationController(
        Matrix4.identity()..translateByDouble(12.0, 18.0, 0.0, 1.0),
      );
      final secondTransformationController = TransformationController();
      final firstController = GraphViewController(
        transformationController: firstTransformationController,
      );
      final secondController = GraphViewController(
        transformationController: secondTransformationController,
      );

      Widget build(GraphViewController controller) {
        return MaterialApp(
          home: GraphView.builder(
            graph: graph,
            algorithm: buildTestAlgorithm(),
            controller: controller,
            builder: (node) => const SizedBox(width: 20, height: 20),
          ),
        );
      }

      await tester.pumpWidget(build(firstController));
      await tester.pumpAndSettle();

      expect(firstController.hasAttachedView, isTrue);
      expect(secondController.hasAttachedView, isFalse);

      await tester.pumpWidget(build(secondController));
      await tester.pumpAndSettle();

      expect(firstController.hasAttachedView, isFalse);
      expect(secondController.hasAttachedView, isTrue);
      expect(
        secondTransformationController.value.getTranslation().x,
        equals(12.0),
      );
      expect(
        secondTransformationController.value.getTranslation().y,
        equals(18.0),
      );

      await tester.pumpWidget(const SizedBox.shrink());
      firstTransformationController.dispose();
      secondTransformationController.dispose();
    });

    testWidgets('stale detach keeps the newest attached view operable', (
      WidgetTester tester,
    ) async {
      final graph = Graph()..addNode(Node.Id('target'));
      final transformationController = TransformationController();
      final controller = GraphViewController(
        transformationController: transformationController,
      );

      await pumpOldThenOverlappingView(
        tester,
        graph: graph,
        controller: controller,
      );

      await tester.pumpWidget(
        buildOverlappingControllerViews(
          graph: graph,
          controller: controller,
          includeOldView: false,
          includeCurrentView: true,
        ),
      );

      expect(controller.hasAttachedView, isTrue);

      transformationController.value = Matrix4.identity()
        ..translateByDouble(40.0, 60.0, 0.0, 1.0);
      controller.resetView();
      await tester.pumpAndSettle();

      expect(
        transformationController.value.getTranslation().x,
        closeTo(0, 0.001),
      );
      expect(
        transformationController.value.getTranslation().y,
        closeTo(0, 0.001),
      );

      await tester.pumpWidget(const SizedBox.shrink());
      transformationController.dispose();
    });

    testWidgets('stale detach does not complete pending owned disposal', (
      WidgetTester tester,
    ) async {
      final graph = Graph()..addNode(Node.Id('target'));
      final transformationController = TransformationController();
      final controller = GraphViewController(
        transformationController: transformationController,
        ownsTransformationController: true,
      );

      await pumpOldThenOverlappingView(
        tester,
        graph: graph,
        controller: controller,
      );

      controller.dispose();
      await tester.pumpWidget(
        buildOverlappingControllerViews(
          graph: graph,
          controller: controller,
          includeOldView: false,
          includeCurrentView: true,
        ),
      );

      expect(controller.hasAttachedView, isTrue);

      void listener() {}

      expect(
        () => transformationController.addListener(listener),
        returnsNormally,
      );
      transformationController.removeListener(listener);

      await tester.pumpWidget(const SizedBox.shrink());

      expect(
        () => transformationController.addListener(listener),
        throwsFlutterError,
      );
    });
  });

  group('Collapse Tests', () {
    late GraphViewController controller;

    setUp(() {
      controller = GraphViewController();
    });

    tearDown(() {
      controller.dispose();
    });

    // Helper function to create a graph with multiple branches
    Graph createComplexGraph() {
      final g = Graph();

      final root = Node.Id(0);
      final branch1 = Node.Id(1);
      final branch2 = Node.Id(2);
      final leaf1 = Node.Id(3);
      final leaf2 = Node.Id(4);
      final leaf3 = Node.Id(5);
      final leaf4 = Node.Id(6);

      g.addEdge(root, branch1);
      g.addEdge(root, branch2);
      g.addEdge(branch1, leaf1);
      g.addEdge(branch1, leaf2);
      g.addEdge(branch2, leaf3);
      g.addEdge(branch2, leaf4);

      return g;
    }

    test('Complex graph - multiple branches', () {
      final g = createComplexGraph();
      final root = g.getNodeAtPosition(0);

      controller.collapseNode(g, root);

      final edges = controller.getCollapsingEdges(g);

      // Should get all 6 edges (root->branch1, root->branch2, branch1->leaf1, branch1->leaf2, branch2->leaf3, branch2->leaf4)
      expect(edges.length, 6);
    });

    test('Nested collapse preserves original hide relationships', () {
      final graph = Graph();
      final parent = Node.Id(0);
      final child = Node.Id(1);
      final grandchild = Node.Id(2);

      graph.addEdge(parent, child);
      graph.addEdge(child, grandchild);

      final controller = GraphViewController();
      addTearDown(controller.dispose);

      // Step 1: Collapse child
      controller.collapseNode(graph, child);

      expect(controller.isNodeVisible(graph, parent), true);
      expect(controller.isNodeVisible(graph, child), true);
      expect(controller.isNodeVisible(graph, grandchild), false);
      expect(
          controller.hiddenBy[grandchild], child); // grandchild hidden by child

      // Step 2: Collapse parent
      controller.collapseNode(graph, parent);

      expect(controller.isNodeVisible(graph, parent), true);
      expect(controller.isNodeVisible(graph, child), false);
      expect(controller.isNodeVisible(graph, grandchild), false);
      expect(controller.hiddenBy[child], parent); // child hidden by parent
      expect(controller.hiddenBy[grandchild],
          child); // grandchild STILL hidden by child!

      // Step 3: Get collapsing edges for parent
      controller.collapsedNode = parent;
      final parentEdges = controller.getCollapsingEdges(graph);

      // Should only include parent -> child, NOT child -> grandchild
      expect(parentEdges.length, 1);
      expect(parentEdges.first.source, parent);
      expect(parentEdges.first.destination, child);

      // Step 4: Expand parent
      controller.expandNode(graph, parent);

      expect(controller.isNodeVisible(graph, parent), true);
      expect(controller.isNodeVisible(graph, child), true);
      expect(
          controller.isNodeVisible(graph, grandchild), false); // Still hidden!
      expect(controller.hiddenBy[grandchild], child); // Still hidden by child!

      // Step 5: Expand child
      controller.expandNode(graph, child);

      expect(controller.isNodeVisible(graph, parent), true);
      expect(controller.isNodeVisible(graph, child), true);
      expect(controller.isNodeVisible(graph, grandchild), true); // Now visible!
      expect(controller.hiddenBy.containsKey(grandchild), false);
    });

    test('Expanding cyclic graph does not recurse forever', () {
      final graph = Graph();
      final a = Node.Id('a');
      final b = Node.Id('b');
      final c = Node.Id('c');

      graph.addEdge(a, b);
      graph.addEdge(b, c);
      graph.addEdge(c, a);

      controller.expandNode(graph, a);

      expect(controller.expandingNodes[b], isTrue);
      expect(controller.expandingNodes[c], isTrue);
      expect(controller.expandingNodes.containsKey(a), isFalse);
    });

    test('Collapsing cyclic graph does not hide collapsed root', () {
      final graph = Graph();
      final a = Node.Id('a');
      final b = Node.Id('b');
      final c = Node.Id('c');

      graph.addEdge(a, b);
      graph.addEdge(b, c);
      graph.addEdge(c, a);

      controller.collapseNode(graph, a);

      expect(controller.hiddenBy[a], isNull);
      expect(controller.hiddenBy[b], a);
      expect(controller.hiddenBy[c], a);
    });
  });
}
