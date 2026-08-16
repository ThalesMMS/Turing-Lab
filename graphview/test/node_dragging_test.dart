import 'package:flutter/widgets.dart';
import 'package:graphview/GraphView.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NodeDraggingConfiguration', () {
    test('Default configuration has correct initial values', () {
      final config = NodeDraggingConfiguration();

      expect(config.enabled, true);
      expect(config.enabled, NodeDraggingConfiguration.DEFAULT_ENABLED);
      expect(config.onNodeDragStart, isNull);
      expect(config.onNodeDragUpdate, isNull);
      expect(config.onNodeDragEnd, isNull);
      expect(config.onNodePointerDown, isNull);
      expect(config.canDragPredicate, isNull);
    });

    test('Configuration with enabled false disables dragging', () {
      final config = NodeDraggingConfiguration(enabled: false);

      expect(config.enabled, false);
    });

    test('Configuration with custom callbacks stores them correctly', () {
      var dragStartCalled = false;
      var dragUpdateCalled = false;
      var dragEndCalled = false;

      final config = NodeDraggingConfiguration(
        onNodeDragStart: (node) {
          dragStartCalled = true;
        },
        onNodeDragUpdate: (node, position) {
          dragUpdateCalled = true;
        },
        onNodeDragEnd: (node, finalPosition) {
          dragEndCalled = true;
        },
      );

      expect(config.onNodeDragStart, isNotNull);
      expect(config.onNodeDragUpdate, isNotNull);
      expect(config.onNodeDragEnd, isNotNull);

      final testNode = Node.Id(1);
      final testPosition = const Offset(10, 20);

      config.onNodeDragStart?.call(testNode);
      expect(dragStartCalled, true);

      config.onNodeDragUpdate?.call(testNode, testPosition);
      expect(dragUpdateCalled, true);

      config.onNodeDragEnd?.call(testNode, testPosition);
      expect(dragEndCalled, true);
    });

    test('node pointer callback remains available when dragging is disabled',
        () {
      Node? capturedNode;
      PointerDownEvent? capturedEvent;
      final event = const PointerDownEvent(position: Offset(12, 24));
      final config = NodeDraggingConfiguration(
        enabled: false,
        onNodePointerDown: (node, pointerEvent) {
          capturedNode = node;
          capturedEvent = pointerEvent;
        },
      );
      final node = Node.Id('pointer-target');

      config.onNodePointerDown?.call(node, event);

      expect(capturedNode, same(node));
      expect(capturedEvent, same(event));
    });

    test('onNodeDragStart callback receives correct node', () {
      Node? capturedNode;

      final config = NodeDraggingConfiguration(
        onNodeDragStart: (node) {
          capturedNode = node;
        },
      );

      final testNode = Node.Id('test-node');
      config.onNodeDragStart?.call(testNode);

      expect(capturedNode, equals(testNode));
    });

    test('onNodeDragUpdate callback receives correct node and position', () {
      Node? capturedNode;
      Offset? capturedPosition;

      final config = NodeDraggingConfiguration(
        onNodeDragUpdate: (node, position) {
          capturedNode = node;
          capturedPosition = position;
        },
      );

      final testNode = Node.Id('test-node');
      final testPosition = const Offset(100.5, 200.75);
      config.onNodeDragUpdate?.call(testNode, testPosition);

      expect(capturedNode, equals(testNode));
      expect(capturedPosition, equals(testPosition));
    });

    test('onNodeDragEnd callback receives correct node and final position', () {
      Node? capturedNode;
      Offset? capturedFinalPosition;

      final config = NodeDraggingConfiguration(
        onNodeDragEnd: (node, finalPosition) {
          capturedNode = node;
          capturedFinalPosition = finalPosition;
        },
      );

      final testNode = Node.Id('test-node');
      final finalPosition = const Offset(150.25, 250.5);
      config.onNodeDragEnd?.call(testNode, finalPosition);

      expect(capturedNode, equals(testNode));
      expect(capturedFinalPosition, equals(finalPosition));
    });

    test('canDragPredicate returns correct values', () {
      final config = NodeDraggingConfiguration(
        canDragPredicate: (node) {
          // Allow dragging if node ID is even number
          if (node.key?.value is int) {
            return (node.key!.value as int) % 2 == 0;
          }
          return true;
        },
      );

      final evenNode = Node.Id(2);
      final oddNode = Node.Id(3);

      expect(config.canDragPredicate?.call(evenNode), true);
      expect(config.canDragPredicate?.call(oddNode), false);
    });

    test('canDragPredicate with node.locked property', () {
      final config = NodeDraggingConfiguration(
        canDragPredicate: (node) {
          return !node.locked;
        },
      );

      final lockedNode = Node.Id(1);
      lockedNode.locked = true;

      final unlockedNode = Node.Id(2);
      unlockedNode.locked = false;

      expect(config.canDragPredicate?.call(lockedNode), false);
      expect(config.canDragPredicate?.call(unlockedNode), true);
    });

    test('Configuration with all parameters set', () {
      var startCount = 0;
      var updateCount = 0;
      var endCount = 0;

      final config = NodeDraggingConfiguration(
        enabled: false,
        onNodeDragStart: (node) => startCount++,
        onNodeDragUpdate: (node, position) => updateCount++,
        onNodeDragEnd: (node, finalPosition) => endCount++,
        canDragPredicate: (node) => true,
      );

      expect(config.enabled, false);
      expect(config.onNodeDragStart, isNotNull);
      expect(config.onNodeDragUpdate, isNotNull);
      expect(config.onNodeDragEnd, isNotNull);
      expect(config.canDragPredicate, isNotNull);

      final testNode = Node.Id(1);
      final testPosition = const Offset(0, 0);

      config.onNodeDragStart?.call(testNode);
      config.onNodeDragUpdate?.call(testNode, testPosition);
      config.onNodeDragEnd?.call(testNode, testPosition);

      expect(startCount, 1);
      expect(updateCount, 1);
      expect(endCount, 1);
    });

    test('Callbacks can be called multiple times', () {
      var updateCount = 0;
      final positions = <Offset>[];

      final config = NodeDraggingConfiguration(
        onNodeDragUpdate: (node, position) {
          updateCount++;
          positions.add(position);
        },
      );

      final testNode = Node.Id(1);

      config.onNodeDragUpdate?.call(testNode, const Offset(0, 0));
      config.onNodeDragUpdate?.call(testNode, const Offset(10, 10));
      config.onNodeDragUpdate?.call(testNode, const Offset(20, 20));

      expect(updateCount, 3);
      expect(positions.length, 3);
      expect(positions[0], const Offset(0, 0));
      expect(positions[1], const Offset(10, 10));
      expect(positions[2], const Offset(20, 20));
    });

    test('canDragPredicate can handle different node types', () {
      final config = NodeDraggingConfiguration(
        canDragPredicate: (node) {
          final value = node.key?.value;
          if (value is String) {
            return value.startsWith('draggable-');
          }
          if (value is int) {
            return value > 0;
          }
          return true;
        },
      );

      final draggableStringNode = Node.Id('draggable-node');
      final nonDraggableStringNode = Node.Id('locked-node');
      final positiveIntNode = Node.Id(5);
      final zeroIntNode = Node.Id(0);

      expect(config.canDragPredicate?.call(draggableStringNode), true);
      expect(config.canDragPredicate?.call(nonDraggableStringNode), false);
      expect(config.canDragPredicate?.call(positiveIntNode), true);
      expect(config.canDragPredicate?.call(zeroIntNode), false);
    });

    test('Callbacks handle nodes with different key types', () {
      final capturedNodes = <Node>[];

      final config = NodeDraggingConfiguration(
        onNodeDragStart: (node) {
          capturedNodes.add(node);
        },
      );

      final intNode = Node.Id(1);
      final stringNode = Node.Id('test');
      final widgetNode = Node.Id(const Text('widget'));

      config.onNodeDragStart?.call(intNode);
      config.onNodeDragStart?.call(stringNode);
      config.onNodeDragStart?.call(widgetNode);

      expect(capturedNodes.length, 3);
      expect(capturedNodes[0], equals(intNode));
      expect(capturedNodes[1], equals(stringNode));
      expect(capturedNodes[2], equals(widgetNode));
    });

    test('Configuration can be updated after creation', () {
      final config = NodeDraggingConfiguration();

      expect(config.enabled, true);

      config.enabled = false;
      expect(config.enabled, false);

      config.enabled = true;
      expect(config.enabled, true);
    });

    test('Callbacks can be assigned after configuration creation', () {
      final config = NodeDraggingConfiguration();

      expect(config.onNodeDragStart, isNull);

      var called = false;
      config.onNodeDragStart = (node) {
        called = true;
      };

      expect(config.onNodeDragStart, isNotNull);
      config.onNodeDragStart?.call(Node.Id(1));
      expect(called, true);
    });
  });
}
