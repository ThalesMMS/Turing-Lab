> This changelog documents the Turing Lab-maintained fork of [`nabil6391/graphview`](https://github.com/nabil6391/graphview). Fork-specific technical changes are inventoried in [FORK_PATCHES.md](FORK_PATCHES.md).

## Turing Lab Fork Releases (versions 1.5.0+)

## 1.5.3 (2026-06-22)

- **REMOVED**: Unused layout families outside the Turing Lab app surface:
    - Tree, radial, balloon, circle, tidier-tree, mindmap, force-directed, Barnes-Hut, and Eiglsperger layout implementations
    - Layout-specific tests and legacy force-directed painter widget code
- **RETAINED**: Core graph APIs, controller/widget/renderobject support, adaptive/animated/orthogonal/curved/arrow edge renderers, routing helpers, and Sugiyama layered layout support
- **DOCUMENTED**: Updated [FORK_PATCHES.md](FORK_PATCHES.md) to reflect the restricted Turing Lab-maintained surface

## 1.5.2 (2026-04-19)

- **IMPROVED**: Enhanced deprecation warnings with clearer migration guidance
    - Updated deprecation messages for `Node()` constructor, `Node.data` field, and `getNodeAtUsingData()` method
    - All deprecated APIs now point to recommended alternatives: `Node.Id()` constructor and `GraphView.builder()` pattern
- **NEW**: Added comprehensive [MIGRATION.md](MIGRATION.md) guide
    - Step-by-step migration instructions from deprecated to current API
    - Before/after code examples for common use cases
    - Timeline and FAQ for upgrading
- **DEPRECATION TIMELINE**: Deprecated Node APIs will be removed in v2.0.0 (planned Q3 2026)
    - See [MIGRATION.md](MIGRATION.md) for complete migration guide
    - Update your code to use `Node.Id()` and `GraphView.builder()` pattern before upgrading to v2.0.0

## 1.5.1 (2025-10-17)

- **IMPROVED**: Fix zoom-to-fit for hidden nodes.
- **NEW**: Add fade-in support for edges.
- **NEW**: Add loopback support.

## 1.5.0 (2025-10-02)

- **MAJOR UPDATE**: Added 5 new layout algorithms
    - BalloonLayoutAlgorithm: Radial tree layout with circular child arrangements around parents
    - CircleLayoutAlgorithm: Arranges nodes in circular formations with edge crossing reduction
    - RadialTreeLayoutAlgorithm: Converts tree structures to polar coordinate system
    - TidierTreeLayoutAlgorithm: Improved tree layout with better spacing and positioning
    - MindmapAlgorithm: Specialized layout for mindmap-style distributions
- **NEW**: Node expand/collapse functionality with GraphViewController
    - `collapseNode()`, `expandNode()`, `toggleNodeExpanded()` methods
    - Hierarchical visibility control with animated transitions
    - Initial collapsed state support via `setInitiallyCollapsedNodes()`
- **NEW**: Advanced animation system
    - Smooth expand/collapse animations with customizable duration
    - Node scaling and opacity transitions during state changes
    - `toggleAnimationDuration` parameter for fine-tuning animations
- **NEW**: Enhanced GraphView.builder constructor
    - `animated`: Enable/disable smooth animations (default: true)
    - `autoZoomToFit`: Automatically zoom to fit all nodes on initialization
    - `initialNode`: Jump to specific node on startup
    - `panAnimationDuration`: Customizable navigation movement timing
    - `centerGraph`: Center the graph within the viewport
    - `controller`: GraphViewController for programmatic control
- **NEW**: Navigation and pan control features
    - `jumpToNode()` and `animateToNode()` for programmatic navigation
    - `zoomToFit()` for automatic viewport adjustment
    - `resetView()` for returning to origin
    - `forceRecalculation()` for layout updates
- **IMPROVED** TreeEdgeRenderer with curved/straight connection options
- **IMPROVED**: Better performance with caching for graphs
- **IMPROVED**: Sugiyama Algorithm with postStraighten and additional strategies

## Upstream Releases (inherited, versions 0.1.0-1.2.0)

The upstream version history is preserved below for continuity and reference.

## 1.2.0 (2023-04-29)

- Resolved overlapping issue for the Sugiyama algorithm (#56, #93, #87)
- Added Enum for Coordinate Assignment in Sugiyama : DownRight, DownLeft, UpRight, UpLeft, Average(Default)

## 1.1.1 (2021-12-28)

- Fixed bug for SugiyamaAlgorithm where horizontal placement was overlapping
- Buchheim Algorithm Performance Improvements

## 1.1.0 (2021-12-10)

- Massive Sugiyama Algorithm Performance Improvements! (5x times faster)
- Encourage usage of Node.id(int) for better performance
- Added tests to better check regressions

## 1.0.0 (2021-09-23)

- Full Null Safety Support
- Sugiyama Algorithm Performance Improvements
- Sugiyama Algorithm TOP_BOTTOM Height Issue Solved (#48)

## 1.0.0-nullsafety.0 (2021-05-08)

- Null Safety Support

## 0.7.0 (2021-05-07)

- Added methods for builder pattern and deprecated directly setting Widget Data in nodes.

## 0.6.7 (2021-02-23)

- Fix rect value not being set in FruchtermanReingoldAlgorithm (#27)

## 0.6.6 (2021-01-11)

- Fix Index out of range for Sugiyama Algorithm (#20)

## 0.6.5 (2020-12-24)

- Fix edge coloring not picked up by TreeEdgeRenderer (#15)
- Added Orientation Support in Sugiyama Configuration (#6)

## 0.6.1 (2020-09-17)

- Fix coloring not happening for the whole graphview
- Fix coloring for sugiyama and tree edge render
- Use interactive viewer correctly to make the view constrained

## 0.6.0 (2020-09-06)

- Add coloring to individual edges. Applicable for ArrowEdgeRenderer
- Add example for focused node for Force Directed Graph. It also showcases dynamic update

## 0.5.1 (2020-08-21)

- Fix a bug where the paint was not applied after setstate.
- Proper Key validation to match Nodes and Edges

## 0.5.0 (2020-08-17)

- Minor Breaking change. We now pass edge renderers as part of Layout
- Added Layered Graph (SugiyamaAlgorithm)
- Added Paint Object to change color and stroke parameters of the edges easily
- Fixed a bug whereby the onTap in GestureDetector and InkWell was not working

## 0.1.2 (2020-08-11)

- Used part of library properly. Now we can only implement single graphview

## 0.1.0 (2020-08-10)

- Initial release.
