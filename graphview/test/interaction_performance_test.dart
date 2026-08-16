import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphview/GraphView.dart';

import 'support/large_graph_perf_fixtures.dart';

void main() {
  group('GraphView interaction correctness', () {
    for (final nodeCount in [500, 1000, 2000]) {
      testWidgets(
        'single-node drag invalidates only connected edges on $nodeCount-node tree',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(960, 720));
          addTearDown(() => tester.binding.setSurfaceSize(null));

          final fixture = createLargeGraphFixture(
            nodeCount: nodeCount,
            topology: GraphTopology.tree,
          );
          final algorithm = CountingStaticLayoutAlgorithm();
          final dragNode = fixture.nodes.reduce(
            (left, right) =>
                left.position.dx <= right.position.dx ? left : right,
          );
          final connectedEdges = {
            ...fixture.graph.getInEdges(dragNode),
            ...fixture.graph.getOutEdges(dragNode),
          }.length;

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SizedBox(
                  width: 960,
                  height: 720,
                  child: GraphView.builder(
                    graph: fixture.graph,
                    algorithm: algorithm,
                    animated: false,
                    builder: (node) => const SizedBox(width: 24, height: 24),
                  ),
                ),
              ),
            ),
          );
          await tester.pump();

          final renderBox = tester.renderObject<RenderCustomLayoutBox>(
              find.byType(GraphViewWidget));
          final initialDragPosition = dragNode.position;
          final gesture = await tester.startGesture(
            dragNode.position + const Offset(12, 12),
          );
          await tester.pump();

          const moveCount = 5;
          var maxDirtyEdges = 0;
          for (var index = 0; index < moveCount; index++) {
            await gesture.moveBy(const Offset(6, 0));
            maxDirtyEdges = math.max(
              maxDirtyEdges,
              renderBox.getDirtyEdges().length,
            );
            await tester.pump();
          }
          await gesture.up();
          await tester.pump();

          expect(
            dragNode.position,
            isNot(equals(initialDragPosition)),
            reason: 'The gesture must move the selected node',
          );
          expect(
            maxDirtyEdges,
            inInclusiveRange(1, connectedEdges),
            reason:
                'Dragging one node should only invalidate its connected edges',
          );
        },
      );
    }

    for (final nodeCount in [500, 1000, 2000]) {
      testWidgets(
        'zoom and pan updates avoid relayout on $nodeCount-node grid',
        (tester) async {
          final fixture = createLargeGraphFixture(
            nodeCount: nodeCount,
            topology: GraphTopology.grid,
          );
          final algorithm = CountingStaticLayoutAlgorithm();
          final transformationController = TransformationController();
          final graphController = GraphViewController(
            transformationController: transformationController,
          );
          final trackedNodes = fixture.nodes.take(5).toList(growable: false);
          final originalPositions =
              trackedNodes.map((node) => node.position).toList(growable: false);

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SizedBox(
                  width: 960,
                  height: 720,
                  child: GraphView.builder(
                    graph: fixture.graph,
                    algorithm: algorithm,
                    animated: false,
                    controller: graphController,
                    builder: (node) => const SizedBox(width: 24, height: 24),
                  ),
                ),
              ),
            ),
          );
          await tester.pump();

          final initialRunCount = algorithm.runCount;
          const updateCount = 5;

          for (var index = 0; index < updateCount; index++) {
            final scale = 1.0 + ((index % 5) * 0.03);
            transformationController.value = Matrix4.diagonal3Values(
              scale,
              scale,
              1.0,
            )..setTranslationRaw(-12.0 * index, -8.0 * (index % 6), 0.0);
            await tester.pump();
          }

          expect(
            algorithm.runCount,
            equals(initialRunCount),
            reason: 'Viewport transforms must not trigger layout recalculation',
          );
          for (var index = 0; index < trackedNodes.length; index++) {
            expect(
                trackedNodes[index].position, equals(originalPositions[index]));
          }

          await tester.pumpWidget(const SizedBox.shrink());
          transformationController.dispose();
        },
      );
    }
  });
}
