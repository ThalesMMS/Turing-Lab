import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphview/GraphView.dart';

import '../test/support/large_graph_perf_fixtures.dart';

void main() {
  group('GraphView interaction benchmarks', () {
    testWidgets('single-node drag stays within frame budget on 2000-node tree',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(960, 720));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final fixture = createLargeGraphFixture(
        nodeCount: 2000,
        topology: GraphTopology.tree,
      );
      final algorithm = CountingStaticLayoutAlgorithm();
      final dragNode = fixture.nodes.reduce(
        (left, right) => left.position.dx <= right.position.dx ? left : right,
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
        find.byType(GraphViewWidget),
      );
      final initialDragPosition = dragNode.position;
      final gesture = await tester.startGesture(
        dragNode.position + const Offset(12, 12),
      );
      await tester.pump();

      const moveCount = 60;
      final stopwatch = Stopwatch()..start();
      var maxDirtyEdges = 0;
      for (var index = 0; index < moveCount; index++) {
        await gesture.moveBy(const Offset(6, 0));
        maxDirtyEdges = math.max(
          maxDirtyEdges,
          renderBox.getDirtyEdges().length,
        );
        await tester.pump();
      }
      stopwatch.stop();

      await gesture.up();
      await tester.pump();

      final averageMoveMs = stopwatch.elapsedMicroseconds / moveCount / 1000.0;
      debugPrint(
        'Drag benchmark (2000 nodes): '
        '${averageMoveMs.toStringAsFixed(2)}ms/move, '
        'dirtyEdges=$maxDirtyEdges/$connectedEdges',
      );

      expect(
        averageMoveMs,
        lessThan(250.0),
        reason: 'Average drag move should stay below 250.0ms',
      );
      expect(
        dragNode.position,
        isNot(equals(initialDragPosition)),
        reason: 'The benchmark gesture must move the selected node',
      );
      expect(
        maxDirtyEdges,
        inInclusiveRange(1, connectedEdges),
        reason: 'Dragging one node should only invalidate connected edges',
      );
    });

    testWidgets('zoom and pan stay within frame budget on 2000-node grid',
        (tester) async {
      final fixture = createLargeGraphFixture(
        nodeCount: 2000,
        topology: GraphTopology.grid,
      );
      final algorithm = CountingStaticLayoutAlgorithm();
      final transformationController = TransformationController();
      final graphController = GraphViewController(
        transformationController: transformationController,
      );

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
      const updateCount = 40;
      final samples = <Duration>[];
      for (var index = 0; index < updateCount; index++) {
        final stopwatch = Stopwatch()..start();
        final scale = 1.0 + ((index % 5) * 0.03);
        transformationController.value = Matrix4.diagonal3Values(
          scale,
          scale,
          1.0,
        )..setTranslationRaw(-12.0 * index, -8.0 * (index % 6), 0.0);
        await tester.pump();
        stopwatch.stop();
        samples.add(stopwatch.elapsed);
      }

      final averageUpdateMs = averageMilliseconds(samples);
      final medianUpdateMs = medianMilliseconds(samples);
      debugPrint(
        'Zoom/pan benchmark (2000 nodes): '
        '${averageUpdateMs.toStringAsFixed(2)}ms avg, '
        '${medianUpdateMs.toStringAsFixed(2)}ms median, '
        'layoutRuns=${algorithm.runCount - initialRunCount}',
      );

      expect(
        algorithm.runCount,
        equals(initialRunCount),
        reason: 'Viewport transforms must not trigger layout recalculation',
      );
      expect(
        averageUpdateMs,
        lessThan(700.0),
        reason: 'Average transform update should stay below 700.0ms',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      graphController.dispose();
      transformationController.dispose();
    });
  });
}
