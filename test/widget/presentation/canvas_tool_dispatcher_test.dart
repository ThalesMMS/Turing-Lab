import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/presentation/widgets/automaton_canvas_tool.dart';
import 'package:turing_lab/presentation/widgets/automaton_graphview/canvas_tool_dispatcher.dart';

void main() {
  CanvasToolDispatcher dispatcher([AutomatonCanvasTool? tool]) =>
      CanvasToolDispatcher(
        initialTool: tool ?? AutomatonCanvasTool.selection,
        doubleTapMinTime: const Duration(milliseconds: 40),
        doubleTapTimeout: const Duration(milliseconds: 300),
      );

  group('selection tool', () {
    test('empty tap clears selection, edge tap edits edges', () {
      final d = dispatcher();
      expect(
        d.resolveCanvasTap(
          nodeId: null,
          hasEdgeHits: false,
          isDragging: false,
          now: Duration.zero,
        ),
        isA<CanvasTapClearSelection>(),
      );
      expect(
        d.resolveCanvasTap(
          nodeId: null,
          hasEdgeHits: true,
          isDragging: false,
          now: Duration.zero,
        ),
        isA<CanvasTapEditEdges>(),
      );
    });

    test('a tap that ends a drag is ignored', () {
      final d = dispatcher();
      expect(
        d.resolveCanvasTap(
          nodeId: 'q0',
          hasEdgeHits: false,
          isDragging: true,
          now: Duration.zero,
        ),
        isA<CanvasTapIgnored>(),
      );
    });

    test('second press on the same node inside the window opens context', () {
      final d = dispatcher();
      final first = d.resolveNodeTap(
        'q0',
        now: const Duration(milliseconds: 0),
      );
      expect(first, isA<CanvasTapSelectNode>());
      expect((first as CanvasTapSelectNode).openContext, isFalse);

      d.registerPointerDown('q0', const Duration(milliseconds: 120));
      final second = d.resolveNodeTap(
        'q0',
        now: const Duration(milliseconds: 130),
      );
      expect((second as CanvasTapSelectNode).openContext, isTrue);

      // The double tap consumed the tracking; a third tap starts over.
      d.registerPointerDown('q0', const Duration(milliseconds: 200));
      final third = d.resolveNodeTap(
        'q0',
        now: const Duration(milliseconds: 210),
      );
      expect((third as CanvasTapSelectNode).openContext, isFalse);
    });

    test('presses outside the window or on another node do not arm', () {
      final d = dispatcher();
      d.resolveNodeTap('q0', now: Duration.zero);
      d.registerPointerDown('q0', const Duration(milliseconds: 10));
      expect(
        (d.resolveNodeTap('q0', now: const Duration(milliseconds: 15))
                as CanvasTapSelectNode)
            .openContext,
        isFalse,
      );
      d.registerPointerDown('q1', const Duration(milliseconds: 100));
      expect(
        (d.resolveNodeTap('q1', now: const Duration(milliseconds: 110))
                as CanvasTapSelectNode)
            .openContext,
        isFalse,
      );
      d.registerPointerDown('q1', const Duration(milliseconds: 900));
      expect(
        (d.resolveNodeTap('q1', now: const Duration(milliseconds: 910))
                as CanvasTapSelectNode)
            .openContext,
        isFalse,
      );
    });

    test('drags reset tap tracking', () {
      final d = dispatcher();
      d.resolveNodeTap('q0', now: Duration.zero);
      d.resetTapTracking();
      d.registerPointerDown('q0', const Duration(milliseconds: 100));
      expect(
        (d.resolveNodeTap('q0', now: const Duration(milliseconds: 110))
                as CanvasTapSelectNode)
            .openContext,
        isFalse,
      );
    });
  });

  group('add-state tool', () {
    test('adds only on an empty, non-dragging tap', () {
      final d = dispatcher(AutomatonCanvasTool.addState);
      expect(
        d.resolveCanvasTap(
          nodeId: null,
          hasEdgeHits: true,
          isDragging: false,
          now: Duration.zero,
        ),
        isA<CanvasTapAddState>(),
      );
      expect(
        d.resolveCanvasTap(
          nodeId: 'q0',
          hasEdgeHits: false,
          isDragging: false,
          now: Duration.zero,
        ),
        isA<CanvasTapIgnored>(),
      );
      expect(
        d.resolveCanvasTap(
          nodeId: null,
          hasEdgeHits: false,
          isDragging: true,
          now: Duration.zero,
        ),
        isA<CanvasTapIgnored>(),
      );
      expect(
        d.resolveNodeTap('q0', now: Duration.zero),
        isA<CanvasTapIgnored>(),
      );
    });
  });

  group('transition tool', () {
    test('first node becomes the source, second completes the transition', () {
      final d = dispatcher(AutomatonCanvasTool.transition);
      expect(
        d.resolveCanvasTap(
          nodeId: null,
          hasEdgeHits: false,
          isDragging: false,
          now: Duration.zero,
        ),
        isA<CanvasTapIgnored>(),
      );
      final begin = d.resolveCanvasTap(
        nodeId: 'q0',
        hasEdgeHits: false,
        isDragging: false,
        now: Duration.zero,
      );
      expect((begin as CanvasTapBeginTransition).nodeId, 'q0');
      expect(d.transitionSourceId, 'q0');

      final complete =
          d.resolveNodeTap('q0', now: Duration.zero)
              as CanvasTapCompleteTransition;
      expect(complete.sourceId, 'q0');
      expect(complete.targetId, 'q0');
      expect(d.transitionSourceId, isNull);
    });

    test('switching tools drops the pending source', () {
      final d = dispatcher(AutomatonCanvasTool.transition);
      d.resolveNodeTap('q0', now: Duration.zero);
      final change = d.setActiveTool(AutomatonCanvasTool.selection)!;
      expect(change.clearedTransitionSource, isTrue);
      expect(change.clearedSelection, isFalse);
      expect(d.transitionSourceId, isNull);

      // Coming back does not resume the old operation.
      expect(
        d
            .setActiveTool(AutomatonCanvasTool.transition)!
            .clearedTransitionSource,
        isFalse,
      );
      expect(
        d.resolveNodeTap('q1', now: Duration.zero),
        isA<CanvasTapBeginTransition>(),
      );
    });

    test('clearing the source by node id only matches the pending node', () {
      final d = dispatcher(AutomatonCanvasTool.transition);
      d.resolveNodeTap('q0', now: Duration.zero);
      expect(d.clearTransitionSourceIf('q1'), isFalse);
      expect(d.transitionSourceId, 'q0');
      expect(d.clearTransitionSourceIf('q0'), isTrue);
      expect(d.transitionSourceId, isNull);
      expect(d.clearTransitionSource(), isFalse);
    });
  });

  test('setting the same tool is a no-op and leaving selection clears it', () {
    final d = dispatcher();
    expect(d.setActiveTool(AutomatonCanvasTool.selection), isNull);
    final change = d.setActiveTool(AutomatonCanvasTool.addState)!;
    expect(change.clearedSelection, isTrue);
    expect(change.clearedTransitionSource, isFalse);
    expect(d.activeTool, AutomatonCanvasTool.addState);
  });
}
