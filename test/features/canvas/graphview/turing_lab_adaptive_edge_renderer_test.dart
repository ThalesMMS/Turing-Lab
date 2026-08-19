import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphview/graphview_turing_lab.dart';
import 'package:turing_lab/features/canvas/graphview/turing_lab_adaptive_edge_renderer.dart';

class _InspectableTuringLabAdaptiveEdgeRenderer
    extends TuringLabAdaptiveEdgeRenderer {
  _InspectableTuringLabAdaptiveEdgeRenderer()
      : super(
          config: EdgeRoutingConfig(
            anchorMode: AnchorMode.dynamic,
            routingMode: RoutingMode.bezier,
            enableRepulsion: true,
          ),
          renderMode: TuringLabEdgeRenderMode.groupedFsa,
        );

  Paint? lastStrokePaint;
  Paint? lastArrowPaint;
  Path? lastGeometryPath;
  int geometryPaintCount = 0;

  @override
  void paintEdgeGeometry(
    Canvas canvas,
    Edge edge,
    Paint paint,
    EdgePathGeometry geometry,
  ) {
    geometryPaintCount++;
    lastGeometryPath = geometry.path;
    lastStrokePaint = Paint()
      ..color = paint.color
      ..style = paint.style
      ..strokeWidth = paint.strokeWidth
      ..strokeCap = paint.strokeCap;
  }

  @override
  void paintEdgeArrow(
    Canvas canvas,
    Edge edge,
    Paint paint,
    EdgePathGeometry geometry,
  ) {
    lastArrowPaint = Paint()
      ..color = paint.color
      ..style = paint.style;
  }

  @override
  void renderAnimatedParticlesOnPath(
    Canvas canvas,
    Edge edge,
    Paint paint,
    Path path,
  ) {}
}

Offset _pathMidpoint(Path path) {
  final metric = path.computeMetrics().first;
  return metric.getTangentForOffset(metric.length * 0.5)!.position;
}

bool _pathIntersectsRect(Path path, Rect rect, {double padding = 0}) {
  final iterator = path.computeMetrics().iterator;
  if (!iterator.moveNext()) {
    return false;
  }
  final metric = iterator.current;

  final probe = rect.inflate(padding);
  const samples = 24;
  for (var index = 0; index <= samples; index++) {
    final tangent =
        metric.getTangentForOffset(metric.length * (index / samples));
    if (tangent != null && probe.contains(tangent.position)) {
      return true;
    }
  }
  return false;
}

int _pathContourCount(Path path) {
  return path.computeMetrics().length;
}

class _ThrowingSourceEdge extends Edge {
  _ThrowingSourceEdge(super.source, super.destination);

  @override
  Node get source => throw StateError('forced routing failure');

  @override
  set source(Node value) {}
}

void main() {
  group('TuringLabAdaptiveEdgeRenderer', () {
    late Graph graph;
    late Node source;
    late Node destination;
    late Edge edge;
    late _InspectableTuringLabAdaptiveEdgeRenderer renderer;

    setUp(() {
      graph = Graph();
      source = Node.Id('source')
        ..position = const Offset(0, 0)
        ..size = const Size(100, 60);
      destination = Node.Id('destination')
        ..position = const Offset(220, 0)
        ..size = const Size(100, 60);
      edge = Edge(
        source,
        destination,
        key: const ValueKey('edge-id'),
        label: 'edge',
      );

      graph
        ..addNode(source)
        ..addNode(destination)
        ..addEdgeS(edge);

      renderer = _InspectableTuringLabAdaptiveEdgeRenderer()..setGraph(graph);
    });

    test('uses thicker strokes for selected edges', () {
      renderer.updateAppearance(
        highlightedEdgeIds: const <String>{},
        selectedEdgeIds: const <String>{'edge-id'},
        baseColor: Colors.black,
        highlightColor: Colors.blue,
        labelSurfaceColor: Colors.white,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      renderer.renderEdge(canvas, edge, Paint()..color = Colors.black);

      expect(renderer.lastStrokePaint, isNotNull);
      expect(renderer.lastStrokePaint!.strokeWidth, equals(4.0));
      expect(renderer.lastStrokePaint!.color, equals(Colors.black));
    });

    test('uses highlight styling when the edge is selected and highlighted',
        () {
      renderer.updateAppearance(
        highlightedEdgeIds: const <String>{'edge-id'},
        selectedEdgeIds: const <String>{'edge-id'},
        baseColor: Colors.black,
        highlightColor: Colors.orange,
        labelSurfaceColor: Colors.white,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      renderer.setAnimationValue(0.35);
      renderer.renderEdge(canvas, edge, Paint()..color = Colors.black);

      expect(renderer.lastStrokePaint, isNotNull);
      expect(renderer.lastStrokePaint!.strokeWidth, equals(4.0));
      expect(
        renderer.lastStrokePaint!.color.toARGB32(),
        equals(Colors.orange.toARGB32()),
      );
      expect(renderer.lastArrowPaint, isNotNull);
      expect(
        renderer.lastArrowPaint!.color.toARGB32(),
        equals(Colors.orange.toARGB32()),
      );
    });

    test('renders only one arrow for grouped same-direction transitions', () {
      final groupedEdge = Edge(
        source,
        destination,
        key: const ValueKey('edge-id-2'),
        label: 'second',
      );
      graph.addEdgeS(groupedEdge);
      renderer.setGraph(graph);

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      renderer.renderEdge(canvas, edge, Paint()..color = Colors.black);
      renderer.renderEdge(canvas, groupedEdge, Paint()..color = Colors.black);

      expect(renderer.geometryPaintCount, equals(1));
    });

    test('keeps regular grouped FSA edge geometry solid', () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      renderer.renderEdge(canvas, edge, Paint()..color = Colors.black);

      expect(renderer.lastGeometryPath, isNotNull);
      expect(_pathContourCount(renderer.lastGeometryPath!), equals(1));
    });

    test('uses dashed geometry for epsilon grouped FSA edges', () {
      edge.label = 'ε';
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      renderer.renderEdge(canvas, edge, Paint()..color = Colors.black);

      expect(renderer.lastGeometryPath, isNotNull);
      expect(_pathContourCount(renderer.lastGeometryPath!), greaterThan(1));
    });

    test('uses dashed geometry for epsilon self-loop grouped FSA edges', () {
      final loopEdge = Edge(
        source,
        source,
        key: const ValueKey('epsilon-loop'),
        label: 'ε',
      );
      graph.addEdgeS(loopEdge);
      renderer.setGraph(graph);
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      renderer.renderEdge(canvas, loopEdge, Paint()..color = Colors.black);

      expect(renderer.lastGeometryPath, isNotNull);
      expect(_pathContourCount(renderer.lastGeometryPath!), greaterThan(1));
    });

    test('updates grouped representative after explicit cache invalidation',
        () {
      final groupedEdge = Edge(
        source,
        destination,
        key: const ValueKey('edge-id-2'),
        label: 'zz-top',
      );
      graph.addEdgeS(groupedEdge);
      renderer.setGraph(graph);

      expect(renderer.debugGroupRepresentativeId(edge), equals('edge-id'));

      groupedEdge.label = 'aa-first';
      expect(
        renderer.debugGroupRepresentativeId(edge),
        equals('edge-id'),
        reason: 'Representative stays stale until caches are invalidated.',
      );

      renderer.invalidateEdgeCaches();

      expect(renderer.debugGroupRepresentativeId(edge), equals('edge-id-2'));
    });

    test('clears cached label painters when highlight colors change', () {
      renderer.updateAppearance(
        highlightedEdgeIds: const <String>{'edge-id'},
        selectedEdgeIds: const <String>{},
        baseColor: Colors.black,
        highlightColor: Colors.blue,
        labelSurfaceColor: Colors.white,
      );

      expect(renderer.debugGroupedLabelRectForEdge(edge), isNotNull);
      expect(renderer.debugLabelPainterCacheSize, greaterThan(0));

      renderer.updateAppearance(
        highlightedEdgeIds: const <String>{'edge-id'},
        selectedEdgeIds: const <String>{},
        baseColor: Colors.black,
        highlightColor: Colors.orange,
        labelSurfaceColor: Colors.white,
      );

      expect(renderer.debugLabelPainterCacheSize, equals(0));
    });

    test('keeps label painters cached across render cycles', () {
      expect(renderer.debugGroupedLabelRectForEdge(edge), isNotNull);
      final cachedPainterCount = renderer.debugLabelPainterCacheSize;

      renderer.prepareForRenderCycle();

      expect(renderer.debugLabelPainterCacheSize, equals(cachedPainterCount));
    });

    test('legacy absolute control point does not pin automatic geometry', () {
      setTuringLabEdgeControlPoint(edge, const Offset(-800, -900));

      renderer.prepareForRenderCycle();
      final geometry = renderer.geometryForEdge(edge)!;

      expect(geometry.pathGeometry.bounds.left, greaterThan(-100));
      expect(geometry.pathGeometry.bounds.right, lessThan(400));
    });

    test('geometry follows live node position in the next generation', () {
      renderer.prepareForRenderCycle();
      final before = renderer.geometryForEdge(edge)!.pathGeometry.pointAt(0.5);

      destination.position = const Offset(220, 180);
      graph.markModified();
      renderer.prepareForRenderCycle();
      final geometry = renderer.geometryForEdge(edge)!;
      final during = geometry.pathGeometry.pointAt(0.5);

      expect((during - before).distance, greaterThan(40));
      expect(
        (geometry.pathGeometry.start - renderer.getNodeCenter(source)).distance,
        closeTo(30, 0.5),
      );
    });

    test('position-only generation reuses an unrelated cached route', () {
      final otherSource = Node.Id('other-source')
        ..position = const Offset(0, 400)
        ..size = const Size(100, 60);
      final otherDestination = Node.Id('other-destination')
        ..position = const Offset(220, 400)
        ..size = const Size(100, 60);
      final unrelatedEdge = Edge(
        otherSource,
        otherDestination,
        key: const ValueKey('unrelated-edge'),
        label: 'other',
      );
      graph
        ..addNode(otherSource)
        ..addNode(otherDestination)
        ..addEdgeS(unrelatedEdge);
      renderer.prepareForRenderCycle();
      final movedBefore = renderer.geometryForEdge(edge);
      final unrelatedBefore = renderer.geometryForEdge(unrelatedEdge);

      destination.position = const Offset(220, 180);
      graph.markModified();
      renderer.prepareForRenderCycle();

      expect(renderer.geometryForEdge(unrelatedEdge), same(unrelatedBefore));
      expect(renderer.geometryForEdge(edge), isNot(same(movedBefore)));
    });

    test('distinct standard loops receive distinct paths', () {
      final firstLoop = Edge(
        source,
        source,
        key: const ValueKey('loop-a'),
        label: 'first',
      );
      final secondLoop = Edge(
        source,
        source,
        key: const ValueKey('loop-b'),
        label: 'second',
      );
      graph
        ..addEdgeS(firstLoop)
        ..addEdgeS(secondLoop);
      renderer.renderMode = TuringLabEdgeRenderMode.standard;
      renderer.prepareForRenderCycle();

      final firstGeometry = renderer.geometryForEdge(firstLoop)!.pathGeometry;
      final secondGeometry = renderer.geometryForEdge(secondLoop)!.pathGeometry;

      expect(firstGeometry.bounds, isNot(equals(secondGeometry.bounds)));
    });

    test('standard PDA/TM label card clears its painted path', () {
      renderer.renderMode = TuringLabEdgeRenderMode.standard;
      edge.label = 'a, Z/AZ';
      renderer.prepareForRenderCycle();

      final geometry = renderer.geometryForEdge(edge)!;
      final labelRect = renderer.debugLabelRectForEdge(edge);

      expect(labelRect, isNotNull);
      expect(
        _pathIntersectsRect(
          geometry.pathGeometry.path,
          labelRect!,
          padding: 8,
        ),
        isFalse,
      );
    });

    test('standard label rect changes with the live route generation', () {
      renderer.renderMode = TuringLabEdgeRenderMode.standard;
      renderer.prepareForRenderCycle();
      final before = renderer.debugLabelRectForEdge(edge)!;

      destination.position = const Offset(220, 180);
      graph.markModified();
      renderer.prepareForRenderCycle();

      expect(renderer.debugLabelRectForEdge(edge), isNot(equals(before)));
    });

    test('caps label painter cache at 200 entries', () {
      for (var index = 0; index < 220; index++) {
        graph.addEdgeS(
          Edge(
            source,
            destination,
            key: ValueKey('edge-cache-$index'),
            label: 'label-$index',
          ),
        );
      }
      renderer.setGraph(graph);

      expect(renderer.debugGroupedLabelRectForEdge(edge), isNotNull);
      expect(renderer.debugLabelPainterCacheSize, lessThanOrEqualTo(200));
      expect(renderer.debugGroupedEdgeCacheSize, equals(1));
    });

    test('separates opposing vertical transitions into different lanes', () {
      destination.position = const Offset(0, 220);

      final opposingEdge = Edge(
        destination,
        source,
        key: const ValueKey('edge-opposing'),
        label: 'return',
      );
      graph.addEdgeS(opposingEdge);
      renderer.setGraph(graph);

      final forwardPath = renderer.debugGroupedPathForEdge(edge);
      final backwardPath = renderer.debugGroupedPathForEdge(opposingEdge);

      expect(forwardPath, isNotNull);
      expect(backwardPath, isNotNull);

      final forwardMidpoint = _pathMidpoint(forwardPath!);
      final backwardMidpoint = _pathMidpoint(backwardPath!);
      expect(
        (forwardMidpoint.dx - backwardMidpoint.dx).abs(),
        greaterThan(20),
      );
    });

    test('places opposing vertical labels on opposite sides of the pair', () {
      destination.position = const Offset(0, 220);

      final opposingEdge = Edge(
        destination,
        source,
        key: const ValueKey('edge-opposing'),
        label: 'return',
      );
      graph.addEdgeS(opposingEdge);
      renderer.setGraph(graph);

      final forwardRect = renderer.debugGroupedLabelRectForEdge(edge);
      final backwardRect = renderer.debugGroupedLabelRectForEdge(opposingEdge);

      expect(forwardRect, isNotNull);
      expect(backwardRect, isNotNull);
      expect(
        (forwardRect!.center.dx - 50) * (backwardRect!.center.dx - 50),
        lessThan(0),
      );
    });

    test('keeps grouped same-direction label cards clear of the edge path', () {
      final groupedEdge = Edge(
        source,
        destination,
        key: const ValueKey('edge-id-2'),
        label: 'second',
      );
      graph.addEdgeS(groupedEdge);
      renderer.setGraph(graph);

      final path = renderer.debugGroupedPathForEdge(edge);
      final rect = renderer.debugGroupedLabelRectForEdge(edge);

      expect(path, isNotNull);
      expect(rect, isNotNull);
      expect(_pathIntersectsRect(path!, rect!, padding: 8), isFalse);
    });

    test('keeps self-loop grouped labels clear of the loop path', () {
      final selfLoop = Edge(
        source,
        source,
        key: const ValueKey('loop-id'),
        label: 'loop',
      );
      graph.addEdgeS(selfLoop);
      renderer.setGraph(graph);

      final path = renderer.debugGroupedPathForEdge(selfLoop);
      final rect = renderer.debugGroupedLabelRectForEdge(selfLoop);

      expect(path, isNotNull);
      expect(rect, isNotNull);
      expect(_pathIntersectsRect(path!, rect!, padding: 8), isFalse);
      expect(rect.left - path.getBounds().right, lessThanOrEqualTo(14));
      expect(rect.center.dx - path.getBounds().right, lessThanOrEqualTo(16));
      expect(rect.center.dy, lessThan(path.getBounds().center.dy));
    });

    test('GraphView AdaptiveEdgeRenderer routing fallback never throws', () {
      final baseRenderer = AdaptiveEdgeRenderer(
        config: EdgeRoutingConfig(
          anchorMode: AnchorMode.dynamic,
          routingMode: RoutingMode.bezier,
        ),
      )..setGraph(graph);
      final throwingEdge = _ThrowingSourceEdge(source, destination);

      final fallbackPath = baseRenderer.routeEdgePath(
        Offset.zero,
        const Offset(100, 0),
        throwingEdge,
      );
      expect(
          fallbackPath.getBounds(), equals(const Rect.fromLTWH(0, 0, 100, 0)));
    });
  });
}
