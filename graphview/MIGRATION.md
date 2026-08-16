# GraphView Migration Guide

This guide helps you migrate from the deprecated Node API to the modern builder pattern introduced in GraphView 0.7.0 and improved in subsequent versions.

## Table of Contents

- [Why Migrate?](#why-migrate)
- [What's Deprecated?](#whats-deprecated)
- [What's New?](#whats-new)
- [Migration Steps](#migration-steps)
- [Code Examples](#code-examples)
- [Timeline](#timeline)
- [FAQ](#faq)

## Why Migrate?

The new builder pattern API offers several advantages over the deprecated widget-based approach:

### Benefits

1. **Better Separation of Concerns**: Node data structure is separate from widget presentation logic
2. **Improved Performance**: Nodes are identified by simple IDs rather than widget hashcodes, enabling better caching
3. **More Flexible**: Build different widgets for the same node in different contexts
4. **Type Safety**: Use any type as node ID (int, String, custom objects) instead of relying on widget instances
5. **Easier Testing**: Test graph logic without creating widgets
6. **Flutter Best Practices**: Follows the builder pattern used throughout Flutter (ListView.builder, GridView.builder, etc.)

## What's Deprecated?

The following APIs are deprecated and will be removed in version 2.0.0:

### 1. Node Constructor with Widget
```dart
@Deprecated('Use Node.Id(id) constructor and GraphView.builder with builder pattern instead. See MIGRATION.md for details.')
Node(Widget data, {Key? key})
```

### 2. Node.data Field
```dart
@Deprecated('Use Node.Id(id) constructor and GraphView.builder with builder pattern instead. See MIGRATION.md for details.')
Widget? data;
```

### 3. Graph.getNodeAtUsingData Method
```dart
@Deprecated('Use Node.Id(id) constructor and getNodeUsingId(id) instead. See MIGRATION.md for details.')
Node getNodeAtUsingData(Widget data)
```

## What's New?

### 1. Node.Id Constructor
Create nodes using simple IDs instead of widgets:

```dart
Node.Id(dynamic id)  // id can be int, String, or any object
```

### 2. GraphView.builder Constructor
Build widgets dynamically using a builder function:

```dart
GraphView.builder({
  required Graph graph,
  required Algorithm algorithm,
  required Widget Function(Node) builder,  // Build widgets on demand
  GraphViewController? controller,
  Paint? paint,
  bool animated = true,
  ValueKey? initialNode,
  bool autoZoomToFit = false,
  Duration? panAnimationDuration,
  Duration? toggleAnimationDuration,
  bool centerGraph = false,
})
```

### 3. Graph.getNodeUsingId Method
Retrieve nodes by their ID:

```dart
Node getNodeUsingId(dynamic id)  // Returns node with matching ValueKey(id)
```

## Migration Steps

Follow these steps to migrate your code:

### Step 1: Update Node Creation

**Before (Deprecated):**
```dart
final node1 = Node(Text('Node 1'));
final node2 = Node(Container(child: Text('Node 2')));
```

**After (Current):**
```dart
final node1 = Node.Id(1);
final node2 = Node.Id(2);
// Or use string IDs:
// final node1 = Node.Id('node1');
// final node2 = Node.Id('node2');
```

### Step 2: Update Graph Construction

**Before (Deprecated):**
```dart
final graph = Graph();
final widget1 = rectangleWidget(1);
final widget2 = rectangleWidget(2);
final node1 = Node(widget1);
final node2 = Node(widget2);
graph.addEdge(node1, node2);
```

**After (Current):**
```dart
final graph = Graph();
final node1 = Node.Id(1);
final node2 = Node.Id(2);
graph.addEdge(node1, node2);
```

### Step 3: Update GraphView Widget

**Before (Deprecated):**
```dart
GraphView(
  graph: graph,
  algorithm: algorithm,
  paint: paint,
)
```

**After (Current):**
```dart
GraphView.builder(
  graph: graph,
  algorithm: algorithm,
  paint: paint,
  builder: (Node node) {
    // Build widget based on node ID
    final id = node.key!.value;
    return rectangleWidget(id);
  },
)
```

### Step 4: Update Node Retrieval

**Before (Deprecated):**
```dart
final widget = Text('Find me');
final node = graph.getNodeAtUsingData(widget);
```

**After (Current):**
```dart
final nodeId = 'node123';
final node = graph.getNodeUsingId(nodeId);
// Or use getNodeUsingKey if you have a ValueKey:
// final node = graph.getNodeUsingKey(ValueKey(nodeId));
```

### Step 5: Update Node Access in Builder

The builder function receives a Node object. Access its ID using `node.key.value`:

```dart
builder: (Node node) {
  final id = node.key!.value;

  // Build different widgets based on ID
  if (id == 1) {
    return Text('Root Node');
  } else if (id is String && id.startsWith('leaf')) {
    return Icon(Icons.circle);
  } else {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        boxShadow: [BoxShadow(color: Colors.blue[100]!, spreadRadius: 1)],
      ),
      child: Text('Node $id'),
    );
  }
}
```

## Code Examples

### Complete Example: Layered Layout

**Before (Deprecated):**
```dart
class TreeViewPage extends StatefulWidget {
  @override
  _TreeViewPageState createState() => _TreeViewPageState();
}

class _TreeViewPageState extends State<TreeViewPage> {
  final Graph graph = Graph()..isTree = true;

  @override
  void initState() {
    super.initState();

    final node1 = Node(rectangleWidget(1));
    final node2 = Node(rectangleWidget(2));
    final node3 = Node(rectangleWidget(3));

    graph.addEdge(node1, node2);
    graph.addEdge(node1, node3);
  }

  Widget rectangleWidget(int id) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        boxShadow: [BoxShadow(color: Colors.blue[100]!, spreadRadius: 1)],
      ),
      child: Text('Node $id'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GraphView(
        graph: graph,
        algorithm: SugiyamaAlgorithm(SugiyamaConfiguration()),
      ),
    );
  }
}
```

**After (Current):**
```dart
class TreeViewPage extends StatefulWidget {
  @override
  _TreeViewPageState createState() => _TreeViewPageState();
}

class _TreeViewPageState extends State<TreeViewPage> {
  final Graph graph = Graph();
  final GraphViewController controller = GraphViewController();

  @override
  void initState() {
    super.initState();

    final node1 = Node.Id(1);
    final node2 = Node.Id(2);
    final node3 = Node.Id(3);

    graph.addEdge(node1, node2);
    graph.addEdge(node1, node3);
  }

  Widget rectangleWidget(int id) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        boxShadow: [BoxShadow(color: Colors.blue[100]!, spreadRadius: 1)],
      ),
      child: Text('Node $id'),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GraphView.builder(
        graph: graph,
        algorithm: SugiyamaAlgorithm(SugiyamaConfiguration()),
        controller: controller,
        builder: (Node node) {
          final id = node.key!.value as int;
          return rectangleWidget(id);
        },
      ),
    );
  }
}
```

### GraphViewController ownership

`GraphViewController()` creates and owns its viewport
`TransformationController`. The object that creates the
`GraphViewController` must call `dispose()`; if a graph view is still attached,
the viewport controller stays alive until that view detaches.

When a `TransformationController` is supplied, it remains caller-owned by
default. Pass `ownsTransformationController: true` only when ownership should
transfer to the `GraphViewController`.

### Example: Dynamic Graph with Different Node Types

**After (Current):**
```dart
class MultiTypeGraphPage extends StatefulWidget {
  @override
  _MultiTypeGraphPageState createState() => _MultiTypeGraphPageState();
}

class _MultiTypeGraphPageState extends State<MultiTypeGraphPage> {
  final Graph graph = Graph();

  @override
  void initState() {
    super.initState();

    // Use different ID types for different node types
    final rootNode = Node.Id('root');
    final categoryNode1 = Node.Id('category_1');
    final categoryNode2 = Node.Id('category_2');
    final itemNode1 = Node.Id(101);  // int IDs for items
    final itemNode2 = Node.Id(102);
    final itemNode3 = Node.Id(103);

    graph.addEdge(rootNode, categoryNode1);
    graph.addEdge(rootNode, categoryNode2);
    graph.addEdge(categoryNode1, itemNode1);
    graph.addEdge(categoryNode1, itemNode2);
    graph.addEdge(categoryNode2, itemNode3);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GraphView.builder(
        graph: graph,
        algorithm: SugiyamaAlgorithm(SugiyamaConfiguration()),
        builder: (Node node) {
          final id = node.key!.value;

          // Build different widgets based on ID type
          if (id == 'root') {
            return Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.home, color: Colors.white),
            );
          } else if (id is String && id.startsWith('category_')) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                id.replaceAll('_', ' ').toUpperCase(),
                style: TextStyle(color: Colors.white),
              ),
            );
          } else if (id is int) {
            return Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('Item $id'),
            );
          }

          return Container(); // Fallback
        },
      ),
    );
  }
}
```

### Example: Using Advanced Features

The new API unlocks advanced features:

```dart
GraphView.builder(
  graph: graph,
  algorithm: algorithm,
  controller: controller,

  // Enable smooth animations
  animated: true,

  // Auto-zoom to fit all nodes on initialization
  autoZoomToFit: true,

  // OR jump to a specific node on startup (mutually exclusive with autoZoomToFit)
  // initialNode: ValueKey(1),

  // Customize animation durations
  panAnimationDuration: Duration(milliseconds: 600),
  toggleAnimationDuration: Duration(milliseconds: 400),

  // Center the graph in a large viewport
  centerGraph: true,

  // Dynamic builder with interaction
  builder: (Node node) {
    return GestureDetector(
      onTap: () {
        // Use controller features
        controller.toggleNodeExpanded(graph, node, animate: true);
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [BoxShadow(color: Colors.blue[100]!, spreadRadius: 1)],
        ),
        child: Text('Node ${node.key?.value}'),
      ),
    );
  },
)
```

### Example: Programmatic Navigation

With the new API and GraphViewController:

```dart
final controller = GraphViewController();

// Jump to a node instantly
controller.jumpToNode(ValueKey(5));

// Animate to a node smoothly
controller.animateToNode(ValueKey(10));

// Zoom to fit all visible nodes
controller.zoomToFit();

// Reset view to origin
controller.resetView();

// Toggle node expansion with animation
controller.toggleNodeExpanded(graph, node, animate: true);

// Set initially collapsed nodes
controller.setInitiallyCollapsedNodes(graph, [node1, node2, node3]);
```

## Timeline

| Version | Status | Notes |
|---------|--------|-------|
| **0.7.0** | Initial deprecation | Builder pattern introduced, old API deprecated |
| **1.5.0** | Enhanced builder API | Added animations, navigation, expand/collapse features |
| **1.5.3** | Current | Restricted the Turing Lab fork surface to retained app APIs |
| **1.6.0** | Planned | Further improvements to builder pattern |
| **2.0.0** | Planned removal | Deprecated APIs will be removed (estimated Q3 2026) |

### Deprecation Notice Timeline

- **Now - Version 1.9.x**: Deprecated APIs still work but show warnings. Migration is recommended.
- **Version 2.0.0**: Deprecated APIs will be completely removed. Migration is required.

We recommend migrating as soon as possible to take advantage of new features and ensure your code is ready for the next major version.

## FAQ

### Q: Can I use both old and new APIs in the same project?

**A:** Yes, during the deprecation period (until version 2.0.0), both APIs work. However, you cannot mix them for the same GraphView instance. Each GraphView must use either the old constructor or the new `.builder()` constructor consistently.

### Q: What if I have complex node data besides the widget?

**A:** Use a data model class as your node ID, or maintain a separate Map for node metadata:

```dart
// Option 1: Custom data class as ID
class NodeData {
  final int id;
  final String label;
  final Color color;

  NodeData(this.id, this.label, this.color);

  @override
  bool operator ==(Object other) =>
    identical(this, other) || other is NodeData && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

final node = Node.Id(NodeData(1, 'Root', Colors.blue));

// Option 2: Separate metadata map
final Map<int, NodeMetadata> nodeData = {
  1: NodeMetadata(label: 'Root', color: Colors.blue),
  2: NodeMetadata(label: 'Child', color: Colors.green),
};

final node = Node.Id(1);

// In builder:
builder: (Node node) {
  final id = node.key!.value as int;
  final metadata = nodeData[id]!;
  return buildNodeWidget(metadata);
}
```

### Q: How do I handle dynamic node addition with the new API?

**A:** Node addition is actually simpler with the new API:

```dart
// Old way - had to create widget first
final widget = buildWidget(data);
final node = Node(widget);
graph.addEdge(parentNode, node);
setState(() {}); // Rebuild to show new widget

// New way - just add node, widget built automatically
final node = Node.Id(nextId++);
graph.addEdge(parentNode, node);
setState(() {}); // Builder creates widget on demand
```

### Q: Will my existing graphs/data structures break?

**A:** No. The Graph class and its edge/node structure remain the same. Only the way you create nodes and display them changes. Your graph algorithms, serialization, and logic remain compatible.

### Q: What about performance?

**A:** The new API is **faster**:
- Node lookup by ID uses ValueKey comparison instead of widget hashcode
- Widgets are built on-demand only when visible
- Better caching support in graph algorithms
- Reduced memory footprint (no widget instances stored in nodes)

### Q: Can I migrate incrementally?

**A:** Yes, if your app has multiple GraphView instances, you can migrate them one at a time. Just note that each individual GraphView instance must fully use either the old or new pattern.

### Q: How do I migrate tests?

**Before:**
```dart
test('graph should contain node', () {
  final widget = Text('test');
  final node = Node(widget);
  graph.addNode(node);

  expect(graph.containsData(widget), true);
  expect(graph.getNodeAtUsingData(widget), node);
});
```

**After:**
```dart
test('graph should contain node', () {
  final nodeId = 'test';
  final node = Node.Id(nodeId);
  graph.addNode(node);

  expect(graph.contains(node: node), true);
  expect(graph.getNodeUsingId(nodeId), node);
});
```

### Q: Where can I find more examples?

**A:** In this vendored Turing Lab fork, the old example app has been removed.
Use the package tests and the Turing Lab app canvas integration as the current
examples of the retained builder API.

### Q: What if I encounter issues during migration?

**A:**
1. Check this migration guide for common patterns
2. Review the package tests and Turing Lab app canvas integration
3. Run `flutter analyze` to catch deprecated API usage
4. Open an issue on GitHub if you find a use case not covered here

### Q: Are there any breaking changes besides the deprecated APIs?

**A:** No. The migration to the builder pattern is the only change. All other APIs (Graph, Edge, algorithms, configurations) remain fully compatible.

---

## Need Help?

If you have questions or encounter issues during migration:

- **Documentation**: See [README.md](README.md) for full API reference
- **Examples**: Check the package tests and Turing Lab app canvas integration
- **Issues**: Report problems at https://github.com/nabil6391/graphview/issues
- **Discussions**: Ask questions in GitHub Discussions

We're committed to making this migration as smooth as possible. The new builder pattern provides a more robust foundation for future GraphView features!

## Complete Fork API Reference

This migration guide covers the core `Node.Id()` and `GraphView.builder()` migration path. For the full Turing Lab fork API surface, use [FORK_PATCHES.md](FORK_PATCHES.md) as the authoritative technical inventory of fork-specific APIs, behavior changes, affected files, rationale, and test coverage.

Relevant fork API sections:

- [Edge Rendering Patches](FORK_PATCHES.md#edge-rendering-patches) - `AdaptiveEdgeRenderer`, routing and anchor modes, per-edge renderers, and edge labels.
- [Performance Patches](FORK_PATCHES.md#performance-patches) - path caching and dirty edge tracking.
- [Interaction Patches](FORK_PATCHES.md#interaction-patches) - `GraphViewController` navigation and visibility APIs, plus `NodeDraggingConfiguration`.

Working demonstrations of fork features are covered by package tests and the
Turing Lab app canvas integration.
