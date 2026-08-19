# Canvas perf checklist (manual)

This checklist is intended for release candidates and for validating changes touching GraphView/canvas rendering.

## Setup

- Use **physical devices** (at least one phone and one tablet).
- Build in **profile** mode.
- Ensure the test graph sizes match the tiers in [canvas_performance_budgets.md](./canvas_performance_budgets.md).

## What to capture

For each tier (small/medium/large):

1. **DevTools performance trace**
   - Record 10–20 seconds while:
     - initial render
     - pan continuously
     - pinch-zoom continuously
     - drag a node repeatedly
   - Export the trace (`.json`) and save under `docs/performance/profiling/`.

2. **Metrics summary**
   - Worst frame time (UI + raster)
   - Average frame time (UI + raster)
   - Jank count / missed frames

3. **Memory snapshot**
   - Capture a heap snapshot before and after the interaction segment.

## Pass/Fail guidance

- Fail if interactions produce sustained jank in small graphs.
- For medium/large graphs, occasional jank can be acceptable, but regressions vs previous captures should be investigated.
