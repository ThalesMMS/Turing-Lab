# GraphView Performance Notes

Current performance notes for the Turing Lab graphview-based automaton canvas.

## Scope

This document summarizes the current local benchmark results, practical size limits observed in the widget-test harness, and how to rerun the benchmarks.

For Apple release profiling and trace capture, use the tracked helpers:

- [`tool/start_apple_profile_run.sh`](../tool/start_apple_profile_run.sh)
- [`tool/record_xctrace_attach.sh`](../tool/record_xctrace_attach.sh)

## Tested Limits

These are local widget-test results on the current Apple Silicon development machine. They are useful as regression checks, not as release sign-off data for physical iPhone or iPad hardware.

### Large Automata Synchronization

Current local results:

| Scenario | Result |
| --- | --- |
| 400-state DFA sync | `22.0ms` |
| 400-state NFA sync | `11.5ms` |
| 300-state PDA sync | `5.6ms` |
| 300-state TM sync | `4.6ms` |

Interpretation: controller synchronization remains bounded for the current large fixtures.

### Drag

Current local results:

| Scenario | Result | 16ms target |
| --- | --- | --- |
| 500-node tree | `12.49ms/move` | meets |
| 1000-node tree | `39.84ms/move` | misses |
| 2000-node tree | `146.50ms/move` | misses |

Interpretation: in the local harness, single-node drag remains smooth only around the 500-node tree fixture. Larger trees still need further work or real-device confirmation before they can be called smooth.

### Zoom And Pan

Current local results:

| Scenario | Result | Relayouts |
| --- | --- | --- |
| 500-node grid | `34.52ms avg` | `0` |
| 1000-node grid | `134.35ms avg` | `0` |
| 2000-node grid | `530.53ms avg` | `0` |

Interpretation: viewport transforms are correctly avoiding relayout, but they do not yet meet a 16ms frame budget in the widget-test harness.

### Highlight Playback

Current local results:

| Scenario | Phase 2 baseline | Current |
| --- | --- | --- |
| 240-state NFA highlight cycle | `46.11ms/cycle` | `33.06ms/cycle` |

Interpretation: highlight playback improved materially after the edge-renderer cache work, but it is still above a 16ms frame budget in this local harness.

## Remaining Limitations

- Physical iPhone and iPad profile traces are still required for release sign-off.
- The current local data does not prove stable memory usage under long stress loops. Memory validation remains pending.
- Large drag and zoom/pan scenarios above the 500-node local tree case do not currently satisfy a 16ms budget in widget tests.
- Snapshot-history serialization has not yet been validated with real-device traces for UI-thread blocking.

## Local Benchmark Commands

Run the Phase 1 performance suite:

```bash
flutter test \
  graphview/test/interaction_performance_test.dart \
  test/widget/presentation/automaton_graphview_canvas_performance_test.dart
```

Run the targeted renderer regression tests:

```bash
flutter test \
  test/features/canvas/graphview/turing_lab_adaptive_edge_renderer_test.dart
```

Run the Apple profiling helpers for manual profile sessions:

```bash
./tool/start_apple_profile_run.sh ios <device-id>
./tool/record_xctrace_attach.sh "Time Profiler" Runner
./tool/record_xctrace_attach.sh "Allocations" Runner
```

## Current Conclusion

The implemented renderer optimizations improved highlight playback and did not regress the existing benchmark suite. They did not materially change drag or zoom/pan costs in the widget-test harness. Real-device Apple profiling and memory tracing are still required before the release acceptance criteria can be closed.

## Simulation Responsiveness On The UI Isolate

Finite-automaton simulation runs on the UI isolate. Since #432 the DFA loop,
the traced NFA loop and the untraced NFA recognizer hand the event loop back
through `CooperativeYield` after every 8 ms of work instead of after fixed step
counts. `test/unit/core/fsa/automaton_simulation_blocking_benchmark_test.dart`
records the longest gap between 1 ms heartbeat ticks (the longest stall) and
the wall time of the same run inside a worker isolate, including result
transfer. Local results on the Apple Silicon development machine, debug test
runner, 2026-09-06:

| Scenario | Stall before | Stall after (cooperative) | Stall in isolate | Wall cooperative / isolate |
| --- | --- | --- | --- | --- |
| DFA 50 states, 5 000 symbols | `34ms` | `17ms` | `2ms` | `84ms` / `50ms` |
| DFA 50 states, 50 000 symbols | `49ms` | `15ms` | `3ms` | `836ms` / `781ms` |
| NFA 6 ε-branches, 2 000 symbols (hits the 10 000-node trace budget) | `~1230ms` (never yielded) | `30ms` | `2ms` | `1234ms` / `1165ms` |
| NFA 40 ε-branches, 500 symbols (hits the trace budget) | `~1180ms` (never yielded) | `25ms` | `3ms` | `1186ms` / `1145ms` |

Interpretation: the cooperative slices remove the multi-second freezes and keep
stalls within one or two frames; the residual NFA stall is the synchronous
construction of the truncated computation tree at the end of the run. A worker
isolate would remove that residual stall but adds a spawn per run, a copy of
the automaton and of up to 10 000 trace nodes, and a separate web strategy,
for a wall time that is within noise of the cooperative run. FSA therefore
stays on the cooperative path; PDA and TM keep the existing isolate runner.
The benchmark is load-sensitive: rerun it alone on an idle machine before
calling a change a regression.

## Automatic Route Cache Reuse (500-State DFA)

`test/features/canvas/graphview/turing_lab_adaptive_edge_renderer_cache_benchmark_test.dart`
drives the edge renderer with a 500-state ring DFA (1 000 transitions: `a`
to the next state and a `b` self-loop per state) and reads the renderer's own
counters (`debugRouteCacheHits`, `debugRouteLayoutRuns`,
`debugRouteGroupsPlanned`, `debugLastCyclePhaseMicros`). Local results on the
Apple Silicon development machine, debug test runner, 2026-09-06 (#434):

| Interaction | Route cache | Cycle before | Cycle after | Dominant cost after |
| --- | --- | --- | --- | --- |
| First layout | 1 000 groups planned, 1 full replan | `544ms` | `453ms` | planner (inherent) |
| Pan/zoom, 60 equivalent-container rebuilds | 60/60 hits, 0 groups planned | `78ms` per cycle | `0.4ms` per cycle | label rects (`~0.25ms`) |
| Drag one state, 30 frames | 30 partial replans, 6.9 groups per frame, 0 full replans | `101ms` per frame | `31ms` per frame | planner candidate scoring (`~29ms`) |
| Edit one transition label | 1 full replan (edge identities change) | `465ms` | `411ms` | planner (inherent) |

What the measurement found and what changed:

- The route geometry cache already behaved correctly: viewport-only rebuilds
  never replanned, and a drag replanned only the groups incident to the moved
  state plus the neighbours it now obstructs.
- The pan/zoom cost was not in routing. The vendored
  `AdaptiveEdgeRenderer` required the identical `Graph` instance to reuse its
  repulsion offsets, so every equivalent container GraphView hands out on a
  rebuild recomputed repulsion for all 1 000 edges (`~72ms`). The cache is now
  keyed by content (edge identities, node centers, config). The grouped-edge
  and opposing-traffic caches were also rebuilt per container and now follow
  the new container.
- During a drag the same repulsion pass ran again because node centers
  changed, although the grouped FSA mode never reads those offsets. The FSA
  canvas now disables base repulsion in that mode; the standard PDA/TM mode
  still uses it, where it remains `O(edges × nodes)` per node move.
- Partial replans now hand the planner only the cached paths and states
  within 320 px of an affected group (plus the looping state's radius for a
  self-loop group), which the planner's clearance and loop falloff rules make
  provably sufficient. It did not change the drag cost:
  the remaining `~29ms` is the planner sampling five candidate curves per
  request through `PathMetric`, which is inherent work rather than a cache
  miss and is left as a follow-up.
- Editing a transition changes edge identities and stays a full replan by
  design.

These are widget-test VM timings, not device frame times; the benchmark is
load-sensitive and only asserts the cache counters.

## Batch Execution Responsiveness

`test/unit/core/batch_execution/batch_parallelism_benchmark_test.dart` runs
500 balanced-parentheses words (10 to 23 symbols, half rejected) through
`GrammarBatchExecutor` with the `auto` parser strategy and compares the
shared-isolate runner with a pool of worker isolates that each take a
contiguous slice and merge results in input order. Local results, Apple
Silicon development machine, debug test runner, 2026-09-06 (#433):

| Configuration | Wall time | Longest stall on the calling isolate |
| --- | --- | --- |
| Shared isolate, concurrency 1, before | `89ms` | `90ms` |
| Shared isolate, concurrency 4, before | `36ms` | `36ms` |
| Shared isolate, concurrency 1, after per-case yield | `104ms` | `16ms` |
| Shared isolate, concurrency 4, after per-case yield | `37ms` | `28ms` |
| Isolate pool, 2 workers | `16ms` | `2ms` |
| Isolate pool, 4 workers | `8–9ms` | `2ms` |

Per-case outcomes are identical in every configuration and stay in input
order. Throughput and responsiveness are reported separately: the pool
multiplies throughput by roughly 6 to 10 on this batch, but the whole batch
already finishes in about 0.1 s on the shared isolate, and the runner now
yields between synchronous cases (`CooperativeYield`), so progress and
cancellation stay responsive. A reusable pool is not introduced: it would
need sendable executors, per-worker progress and cancellation plumbing and a
web fallback for a gain that only matters on batches far larger or slower
than the measured one. Re-evaluate with a heavier grammar or a longer word
list before adding one.
