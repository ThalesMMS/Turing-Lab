# GraphView Performance Notes

Current performance notes for the Turing Lab graphview-based automaton canvas.

## Scope

This document summarizes the current local benchmark results, practical size limits observed in the widget-test harness, and how to rerun the benchmarks.

For Apple release profiling workflow and trace capture, use:

- [release/APPLE_PERFORMANCE_PROFILING.md](../release/APPLE_PERFORMANCE_PROFILING.md)
- [release/APPLE_PERFORMANCE_BASELINE.md](../release/APPLE_PERFORMANCE_BASELINE.md)

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
