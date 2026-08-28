# Graph hard-edge certification

Issue #341 certifies the graph layout engine and the canvas contracts that
preserve document meaning around it. The fixtures are independently authored;
JFLAP 7.1 graph classes were inspected only as workflow references. JFLAP's
unseeded layouts and hash-iteration ordering are not deterministic oracles for
Turing Lab. The intended parity boundaries remain recorded in
`docs/reference-deviations.md`.

## Family matrix

| Area | Live implementation | Certified property or evidence |
| --- | --- | --- |
| Constructive layouts | `lib/core/graph_layout/graph_layout_engine.dart` | One catalog case each for circle, two-circle, spiral, hierarchical, Sugiyama, component packing, seeded force, and seeded random; stable seed, finite coordinates, topology counts, safe bounds, disconnected components, loops, parallel and bidirectional edges |
| Geometric transforms | `lib/core/graph_layout/graph_layout_engine.dart` | Reflection, 90/180/270-degree rotation, fit, fill, and restore cases; deterministic affine result, finite coordinates, complete stable-ID map, and restore equality |
| Validation and scope | `graph_layout_models.dart`, `graph_layout_engine.dart`, `graph_layout_task.dart` | Dangling endpoints fail closed with finite fallback; selection and pins preserve excluded positions; existing cancellation/resource cases run in document-adapter evidence |
| Typed document updates | `graph_layout_document_adapter.dart` | FSA, PDA, TM, Mealy, and Moore positions and type-specific transition metadata; free and attached annotations; the focused adapter suite is mandatory Flutter evidence |
| FSA/PDA/TM mapping | `lib/features/canvas/graphview/graphview_*_mapper.dart` | Snapshot round trips preserve stable IDs, labels, control points, PDA atomic stack symbols, TM multi-tape operations, and document metadata |
| Mealy/Moore mapping | `lib/presentation/transducers/graphview_transducer_canvas_controller.dart` | Typed input/output transition data, provider identity, and controller synchronization |
| Snapshot/history/IDs | `graphview_canvas_models.dart`, `graphview_snapshot_codec*.dart`, `base_graphview_canvas_controller.dart` | Lossless JSON/snapshot history, invalid entries, ID/label allocation, undo/redo, drag coalescing, one semantic commit, and generated event-history replay |
| Viewport/selection/lifecycle | `automaton_graphview/canvas_*`, `graphview_viewport_highlight_mixin.dart` | Screen/world round trip tolerances, singular-matrix identity fallback, zero/stale viewports, hit testing, controller attach/detach/dispose ownership, provider races, and responsive changes |
| Routing/render cache | `turing_lab_adaptive_edge_renderer*.dart`, `automatic_transition_route_planner.dart`, `grouped_fsa_geometry.dart` | Self-loop/parallel-edge geometry, safe labels, highlight revision behavior, cache invalidation, and deterministic routing |
| Read-only previews | `read_only_fsa_graphview_canvas.dart` | Read-only isolation from providers, history and highlight mutation |

The functional Flutter evidence case runs `test/features/canvas/graphview/`,
the Mealy and Moore controller/workspace tests, the read-only canvas test, and
the annotation/highlight suites. A separate viewport property exercises a
singular and non-finite transformation matrices. The document-adapter case runs
the complete graph-layout engine test. This keeps lifecycle and UI contracts in
their native Flutter harness while the 18 pure layout/validation cases and the
generated event-history case remain runnable with Dart alone.
`graphBoundaryInventory` names every mapper, controller, history, viewport,
routing, highlight, and read-only boundary. The focused matrix test scans all
three production roots and requires every Dart source to be either inventoried
or explicitly classified as a support file, so a new boundary cannot silently
drift outside the matrix.

## Fixtures, properties, and shrinking

The deterministic fixture combines duplicate labels with unique IDs, an
isolated node, cycles, a self-loop, parallel and reverse edges, and large
positive/negative coordinates. Catalog materialization replaces only the
uint32 seed. Every layout must return exactly one finite position per source ID,
preserve source node/edge counts, and reproduce byte-equivalent coordinates for
the same graph/settings/seed. Constructive layouts must remain within the target
bounds. Validation cases distinguish invalid topology from a valid rejection.

`GraphFailureFixtureShrinker` reduces injected event sequences before removing
edges and nodes with their incident edges. Event candidates are replayed through
the production snapshot history codec, remain schema-valid/applicable, and are
accepted only while the original failure signature is preserved. The focused
regression proves the result is a local minimum: no remaining valid candidate
has the same signature. Every graph candidate retains unique node IDs and valid
endpoints, so a minimized failure remains meaningful rather than becoming a
schema accident.

Flutter evidence still executes reviewed fixed harnesses, not injected UI
events. Generated seed ranges therefore report only those Flutter-backed
properties as `notApplicable`, and the shrink registry rejects their fixtures;
it never claims to minimize an input the harness did not consume. The separate
`graph.event-history-replay` property is generated, injected, replayable, and
shrinkable with Dart alone.

## Mutation and performance gates

The family has five certification-only semantic adapter mutations. Three cover
layout completeness, seed sensitivity, and pinned-node preservation. One drops
an edge after the real `GraphViewAutomatonMapper` mapping boundary, and one
truncates the real platform history codec payload. Canonical mapping/history
round trips must pass and both mutants must fail. All five must be killed.

Wall-clock assertions run only under `graph.performance-benchmark`, separate
from `graph.canvas-contracts`. The report therefore identifies a load-sensitive
failure by property instead of presenting it as a functional canvas violation.
The evidence process has a 50-second budget inside the central 60-second case
budget. On Windows, timeout runs blocking `taskkill /T /F` and awaits the root
exit. On POSIX, it enumerates descendants with `ps`, freezes the captured tree,
forces those PIDs to exit, verifies they are gone, and then awaits the root and
both output streams. Enumeration failure is fatal rather than silently claiming
tree cleanup. A child-plus-grandchild regression records the descendant PID and
uses a delayed sentinel to prove the runner does not return while that process
survives. Vendored GraphView benchmarks remain part of the repository's separate
GraphView QA category and are load-sensitive as documented in `AGENTS.md`.

## Local reproduction

Run the complete family, including Flutter canvas evidence:

```shell
dart run tool/hard_edge_graph.dart --jobs 1
```

Run only a pure property or its mutations:

```shell
dart run tool/hard_edge_graph.dart --property graph.layout-sugiyama
dart run tool/hard_edge_cases.dart mutate --family graph \
  --output build/hard-edge/graph-mutations
```

Reports include algorithm, property, seed, outcome, and the local-only warning.
The certification was authored with Flutter 3.44.4 and Dart 3.12.2 on Windows;
the exact executed commands and outcomes belong in the issue completion note.
