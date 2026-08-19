# Canvas performance budgets

These budgets are targets to keep the automaton canvas responsive during pan/zoom/drag interactions.

## Frame budget (target)

- **60Hz devices**: 16.7ms per frame total
  - UI thread (build/layout): target **< 8ms**
  - Raster thread (paint/composite): target **< 8ms**

## Interaction targets

- Drag latency: no perceivable lag; aim for **< 1 frame** delay on state drag.
- Pan/zoom: avoid sustained jank during continuous gestures.

## Memory targets

- No unbounded allocation growth during repeated pan/zoom/drag.
- For large graphs, transient allocations are expected during layout/routing, but the heap should stabilize after interactions stop.

## Graph-size tiers

Use these tiers consistently in profiling and regression checks:

- **Small**: ~25 nodes / ~40 edges
- **Medium**: ~150 nodes / ~250 edges
- **Large**: ~500 nodes / ~900 edges

(Exact topology matters; prefer a representative mix of parallel edges, self loops, and crossings.)
