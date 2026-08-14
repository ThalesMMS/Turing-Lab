# GraphView Turing Lab Fork

This is the vendored GraphView fork used by Turing Lab. It is not maintained as a
general-purpose graph layout package in this repository. The app imports the
restricted `package:graphview/graphview_turing_lab.dart` barrel so the supported
surface stays aligned with what Turing Lab actually uses.

## Retained Surface

- Core graph model: `Graph`, `Node`, `Edge`, `LineType`, and edge labels.
- Widget/controller APIs: `GraphView`, `GraphView.builder`,
  `GraphViewController`, `GraphObserver`, and node dragging configuration.
- Retained layout: `SugiyamaAlgorithm` with `SugiyamaConfiguration`.
- Retained renderers: `ArrowEdgeRenderer`, `AdaptiveEdgeRenderer`,
  `AnimatedEdgeRenderer`, `CurvedEdgeRenderer`, `OrthogonalEdgeRenderer`, and
  `SugiyamaEdgeRenderer`.
- Routing helpers: `EdgeRoutingConfig`, `AnchorMode`, `RoutingMode`,
  `EdgeRepulsionSolver`, and vector utilities.

The removed layout families are documented in `CHANGELOG.md`. Fork-specific
patches and test coverage are inventoried in `FORK_PATCHES.md`.

## Usage

```dart
import 'package:graphview/graphview_turing_lab.dart';

final graph = Graph()
  ..addEdge(Node.Id('start'), Node.Id('end'));

final algorithm = SugiyamaAlgorithm(SugiyamaConfiguration());

GraphView.builder(
  graph: graph,
  algorithm: algorithm,
  builder: (node) => Text('${node.key?.value}'),
);
```

Use `GraphView.builder` and `Node.Id` for new code. The deprecated widget-backed
node API is covered in `MIGRATION.md`.

## Development

Run package checks from this directory:

```sh
flutter pub get
flutter test --concurrency=1
flutter analyze
```

When changing app-facing API, also run the Turing Lab canvas tests from the
repository root.
