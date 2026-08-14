# Turing Lab GraphView Surface

This is the app-supported import surface for the vendored GraphView fork. The
full `package:graphview/GraphView.dart` barrel stays available for GraphView's
own package tests and legacy layouts, but Turing Lab app code should import:

```dart
import 'package:graphview/graphview_turing_lab.dart';
```

## Current Turing Lab Importers

Source files:

- `lib/presentation/widgets/automaton_graphview_canvas.dart`
- `lib/features/canvas/graphview/base_graphview_canvas_controller.dart`
- `lib/features/canvas/graphview/graphview_canvas_controller.dart`
- `lib/features/canvas/graphview/graphview_viewport_highlight_mixin.dart`
- `lib/features/canvas/graphview/turing_lab_adaptive_edge_renderer.dart`

Test files:

- `test/widget/presentation/automaton_graphview_canvas_test.dart`
- `test/features/canvas/graphview/graphview_canvas_controller_test.dart`
- `test/features/canvas/graphview/turing_lab_adaptive_edge_renderer_test.dart`

## Exported Symbols

Core graph primitives:

- `Graph`, `Node`, `Edge`, `GraphObserver`, `GraphExtension`
- `LineType`, `EdgeLabelPosition`

GraphView widget and controller:

- `GraphView`, `GraphViewController`, `NodeDraggingConfiguration`
- `NodeWidgetBuilder`, `EdgeWidgetBuilder`
- `OnNodeDragStart`, `OnNodeDragUpdate`, `OnNodeDragEnd`

Layout:

- `Algorithm`
- `SugiyamaAlgorithm`, `SugiyamaConfiguration`
- `BendPointShape`, `SharpBendPointShape`, `CurvedBendPointShape`,
  `MaxCurvedBendPointShape`

Edge rendering:

- `RenderCycleAware`
- `EdgeRenderer`, `ArrowEdgeRenderer`, `AdaptiveEdgeRenderer`
- `AnimatedEdgeRenderer`, `AnimatedEdgeConfiguration`
- `EdgeRoutingConfig`, `AnchorMode`, `RoutingMode`
- `ARROW_LENGTH`

This intentionally excludes unused layout families such as tree, radial,
balloon, mindmap, force-directed, Barnes-Hut, and Eiglsperger.
