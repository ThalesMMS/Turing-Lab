# Fork Patches

This document inventories Turing Lab fork-specific changes to the `graphview`
package. It is organized by system area so maintainers can see which patches
remain part of the fork surface, which files they touch, and why they diverge
from the upstream package.

The Turing Lab app imports the restricted `graphview_turing_lab.dart` barrel. The
retained layout surface is intentionally narrow: core graph/widget/controller
APIs, edge renderers, routing helpers, and Sugiyama layered layout support.

Status markers:

- **Required**: core fork functionality depends on this patch.
- **Optional**: enhances UX or performance but can be disabled or avoided by
  configuration.
- **Experimental**: under development or not fully stable.

## Quick Reference

| Category | Patch Count |
| --- | ---: |
| Edge rendering | 5 |
| Performance | 2 |
| Interaction | 3 |
| Animation | 3 |
| API | 5 |
| **Total** | **18** |

## Edge Rendering Patches

| Patch Name | Affected Files | Status | Rationale |
| --- | --- | --- | --- |
| `AdaptiveEdgeRenderer` | `lib/edgerenderer/AdaptiveEdgeRenderer.dart` | **Required** | Adds adaptive connection points and routes edges through 4 routing modes (`direct`, `orthogonal`, `bezier`, `bundling`) and 4 anchor modes (`center`, `cardinal`, `octagonal`, `dynamic`). Routing is wrapped in a try/catch and falls back to a direct path if routing throws; `bundling` is currently unimplemented and degrades to `direct` with an assert-only debug log. |
| `AnimatedEdgeRenderer` | `lib/edgerenderer/AnimatedEdgeRenderer.dart` | **Optional** | Adds particle flow animation on edges. It is selected explicitly as a renderer and can be avoided when static edge rendering is preferred. |
| `OrthogonalEdgeRenderer` | `lib/edgerenderer/OrthogonalEdgeRenderer.dart` | **Optional** | Adds Manhattan-style L-shaped edge paths for graphs where right-angle routing is easier to read than direct lines. |
| Routing infrastructure | `lib/edgerenderer/routing/EdgeRoutingConfig.dart`, `lib/edgerenderer/routing/EdgeRepulsionSolver.dart`, `lib/edgerenderer/routing/VectorUtils.dart` | **Required** | Centralizes anchor mode, routing mode, movement threshold, and edge repulsion configuration used by adaptive routing. |
| Per-edge rendering and labels | `lib/Graph.dart`, `lib/edgerenderer/ArrowEdgeRenderer.dart`, `lib/edgerenderer/EdgeRenderer.dart` | **Required** | Allows each `Edge` to carry `renderer`, `label`, `labelStyle`, `labelPosition`, `labelFollowsEdgeDirection`, and `labelWidget`; adds the `EdgeLabelPosition` enum so labels can be placed at start, middle, or end of an edge. |

## Performance Patches

| Patch Name | Affected Files | Status | Rationale |
| --- | --- | --- | --- |
| Path caching in `RenderCustomLayoutBox` | `lib/renderobject/RenderCustomLayoutBox.dart` | **Required** | Adds `_pathCache`, `dirtyEdges`, and `_movementThreshold` so repeated paints can reuse edge paths unless relevant graph or node movement changes invalidate them. |
| Dirty edge tracking during node drag | `lib/renderobject/RenderCustomLayoutBox.dart`, `lib/Graph.dart` | **Required** | Invalidates only incoming and outgoing edges for a dragged node once movement crosses the threshold, avoiding full edge cache rebuilds for local interaction. |

## Interaction Patches

| Patch Name | Affected Files | Status | Rationale |
| --- | --- | --- | --- |
| `GraphViewController` navigation and visibility API | `lib/controller/GraphViewController.dart`, `lib/widget/GraphView.dart` | **Required** | Provides `animateToNode`, `jumpToNode`, `zoomToFit`, `resetView`, `collapseNode`, `expandNode`, and `toggleNodeExpanded` for programmatic navigation and visibility control. |
| `NodeDraggingConfiguration` | `lib/config/NodeDraggingConfiguration.dart`, `lib/renderobject/RenderCustomLayoutBox.dart`, `lib/widget/GraphView.dart` | **Optional** | Adds node dragging with `enabled`, `onNodeDragStart`, `onNodeDragUpdate`, `onNodeDragEnd`, and `nodeLockPredicate` hooks. It can be disabled when graph positions should remain fixed. |
| Visibility tracking maps | `lib/controller/GraphViewController.dart`, `lib/delegate/GraphChildDelegate.dart` | **Required** | Tracks `collapsedNodes`, `hiddenBy`, and `expandingNodes` so collapsed subgraphs stay hidden while nested collapse and expansion states remain consistent. |

## Animation Patches

| Patch Name | Affected Files | Status | Rationale |
| --- | --- | --- | --- |
| Expand/collapse animation | `lib/renderobject/RenderCustomLayoutBox.dart`, `lib/renderobject/GraphViewWidget.dart`, `lib/controller/GraphViewController.dart` | **Optional** | Adds `enableAnimation`, `animatedPositions`, and fade-in/fade-out handling for collapsing and expanding edges. Consumers can pass `animated: false` to disable it. |
| `AnimatedEdgeConfiguration` | `lib/edgerenderer/AnimatedEdgeRenderer.dart` | **Optional** | Provides particle animation parameters such as speed, count, size, color, spacing, and opacity for animated edge flows. |
| Dual animation controllers in `_GraphViewState` | `lib/widget/GraphView.dart` | **Required** | Separates `_panController` for viewport navigation from `_nodeController` for expand/collapse animation so graph navigation and node visibility transitions do not share timing state. |

## API Patches

| Patch Name | Affected Files | Status | Rationale |
| --- | --- | --- | --- |
| `GraphView.builder()` constructor | `lib/widget/GraphView.dart`, `lib/GraphView.dart`, `lib/delegate/GraphChildDelegate.dart` | **Required** | Establishes the current builder API with `builder`, `controller`, `initialNode`, `autoZoomToFit`, `panAnimationDuration`, `toggleAnimationDuration`, `centerGraph`, and `nodeDraggingConfig`. |
| `Node.Id()` constructor pattern | `lib/Graph.dart`, `MIGRATION.md` | **Required** | Replaces widget-backed `Node()` construction with stable ID-backed nodes, improving cache behavior and separating graph data from widget presentation. |
| `Graph.getNodeUsingId()` | `lib/Graph.dart`, `MIGRATION.md` | **Required** | Replaces deprecated `getNodeAtUsingData()` lookup with ID-based lookup that matches the `Node.Id()` migration path. |
| `GraphObserver` and graph generation tracking | `lib/Graph.dart`, `lib/renderobject/RenderCustomLayoutBox.dart` | **Required** | Notifies render objects when the graph changes and increments `graph.generation` for dirty tracking and cache invalidation. |
| New enums | `lib/Graph.dart`, `lib/edgerenderer/routing/EdgeRoutingConfig.dart` | **Required** | Adds `LineType`, `EdgeLabelPosition`, `AnchorMode`, and `RoutingMode` to make rendering styles, label placement, anchor selection, and routing modes explicit API choices. |

## File Reference Appendix

| Category | Source Files | Test Coverage |
| --- | --- | --- |
| Edge rendering | `lib/edgerenderer/AdaptiveEdgeRenderer.dart`, `lib/edgerenderer/AnimatedEdgeRenderer.dart`, `lib/edgerenderer/ArrowEdgeRenderer.dart`, `lib/edgerenderer/CurvedEdgeRenderer.dart`, `lib/edgerenderer/EdgeRenderer.dart`, `lib/edgerenderer/OrthogonalEdgeRenderer.dart`, `lib/edgerenderer/routing/EdgeRoutingConfig.dart`, `lib/edgerenderer/routing/EdgeRepulsionSolver.dart`, `lib/edgerenderer/routing/VectorUtils.dart`, `lib/Graph.dart` | `test/anchor_calculation_test.dart`, `test/arrow_renderer_adaptive_test.dart`, `test/backward_compatibility_test.dart`, `test/curved_edge_renderer_test.dart`, `test/edge_label_test.dart`, `test/edge_repulsion_integration_test.dart`, `test/edge_repulsion_test.dart`, `test/edge_routing_config_test.dart`, `test/per_edge_renderer_test.dart`, `test/performance_test.dart`, `test/routing_algorithms_test.dart`, `test/vector_utils_test.dart` |
| Performance | `lib/renderobject/RenderCustomLayoutBox.dart`, `lib/Graph.dart` | `test/dirty_tracking_test.dart`, `test/distance_threshold_test.dart`, `test/path_caching_test.dart`, `test/performance_test.dart` |
| Interaction | `lib/controller/GraphViewController.dart`, `lib/config/NodeDraggingConfiguration.dart`, `lib/delegate/GraphChildDelegate.dart`, `lib/renderobject/RenderCustomLayoutBox.dart`, `lib/widget/GraphView.dart` | `test/controller_tests.dart`, `test/node_dragging_test.dart` |
| Animation | `lib/edgerenderer/AnimatedEdgeRenderer.dart`, `lib/renderobject/GraphViewWidget.dart`, `lib/renderobject/RenderCustomLayoutBox.dart`, `lib/widget/GraphView.dart` | `test/backward_compatibility_test.dart`, `test/controller_tests.dart`, `test/per_edge_renderer_test.dart` |
| API | `lib/Graph.dart`, `lib/GraphView.dart`, `lib/controller/GraphViewController.dart`, `lib/delegate/GraphChildDelegate.dart`, `lib/renderobject/RenderCustomLayoutBox.dart`, `lib/widget/GraphView.dart`, `MIGRATION.md` | `test/backward_compatibility_test.dart`, `test/controller_tests.dart`, `test/edge_label_test.dart`, `test/graph_test.dart`, `test/per_edge_renderer_test.dart` |

## Migration Cross-References

See [MIGRATION.md](MIGRATION.md) for patches that affect the deprecated API
migration path:

- Prefer `Node.Id()` over widget-based `Node()` construction.
- Move widget creation into `GraphView.builder()` instead of storing widgets on
  graph nodes.
- Use `Graph.getNodeUsingId()` in place of `Graph.getNodeAtUsingData()`; the
  deprecation warnings for `Node()`, `Node.data`, and `getNodeAtUsingData()`
  point users to the builder and ID-based API.
