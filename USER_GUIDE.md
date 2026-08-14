# Turing Lab User Guide Supplement

_Nota: migração em andamento._

## Table of Contents

* [Working with the GraphView Canvas](#working-with-the-graphview-canvas)
* [Unified Trace Management](#unified-trace-management)
* [Manual Verification Checklist](#manual-verification-checklist)
* [Troubleshooting](#troubleshooting)
* [Maintenance & Extensibility Notes](#maintenance--extensibility-notes)

## Working with the GraphView Canvas

* The automaton workspace now embeds the GraphView-based canvas by default, wiring highlight playback and toolbar state directly to the Flutter widget tree—no feature toggle or iframe bridge is required.【F:lib/presentation/widgets/automaton_graphview_canvas.dart†L23-L116】
* Riverpod remains the single source of truth: `GraphViewCanvasController` converts provider state into GraphView snapshots and replays user interactions (creation, drag, rename, deletion) back into the notifiers so the entire UI stays synchronized.【F:lib/features/canvas/graphview/graphview_canvas_controller.dart†L14-L156】【F:lib/presentation/providers/automaton_provider.dart†L25-L219】
* The GraphView toolbar exposes viewport controls, undo/redo, and optional drawing tools for desktop, tablet, and phone layouts, keeping the canvas commands consistent across platforms.【F:lib/presentation/widgets/graphview_canvas_toolbar.dart†L6-L138】
* The mobile (phone) layout only presents the same actions plus simulator shortcuts inside `MobileAutomatonControls`, a bottom tray that preserves screen real estate while remaining thumb-accessible. Rendering is gated by the `isMobile` conditional: FSA, PDA, and TM pages treat screen widths below 1024px as mobile and render `MobileAutomatonControls` only when `isMobile` is `true`; tablet and desktop layouts pass `isMobile: false` to the canvas-with-toolbar path and do not render `MobileAutomatonControls`.【F:lib/presentation/widgets/mobile_automaton_controls.dart†L1-L132】

### Core Actions

* **Add State** – Enable the Add State tool (or trigger the callback) and tap the canvas to drop a node at the tapped world coordinates. The controller assigns unique IDs/labels and marks the first state as initial automatically.【F:lib/presentation/widgets/automaton_graphview_canvas.dart†L254-L303】【F:lib/features/canvas/graphview/graphview_canvas_controller.dart†L60-L119】
* **Move State** – Drag a node to reposition it; the controller normalizes the delta according to the current zoom level before persisting the new coordinates via `AutomatonProvider`.【F:lib/presentation/widgets/automaton_graphview_canvas.dart†L304-L332】【F:lib/features/canvas/graphview/graphview_canvas_controller.dart†L121-L150】
* **Add or Edit Transition** – Select a source and destination node while the Transition tool is active to open the inline editor. Saving updates the edge snapshot and forwards the mutation to the provider, ensuring tape/stack metadata stays aligned for advanced automata.【F:lib/presentation/widgets/automaton_graphview_canvas.dart†L333-L494】【F:lib/features/canvas/graphview/graphview_canvas_controller.dart†L152-L214】
* **Viewport Controls** – Use the toolbar (or keyboard shortcuts) to zoom, fit to content, reset the view, and traverse undo/redo history; every command proxies to the shared controller so pointer and touch gestures stay in sync.【F:lib/presentation/widgets/graphview_canvas_toolbar.dart†L33-L138】【F:lib/features/canvas/graphview/base_graphview_canvas_controller.dart†L17-L220】
* **Highlight Playback** – Running a simulation pushes highlight payloads into `GraphViewSimulationHighlightChannel`, which drives the canvas highlight notifier and clears it automatically after playback ends.【F:lib/presentation/widgets/automaton_graphview_canvas.dart†L41-L84】【F:lib/features/canvas/graphview/graphview_highlight_channel.dart†L5-L19】【F:lib/core/services/simulation_highlight_service.dart†L8-L101】

## Unified Trace Management

### Overview

* `UnifiedTraceNotifier` centralizes trace persistence for every simulator, loading history and statistics as soon as an automaton context (type and optional ID) is set, and keeping SharedPreferences-backed storage in sync with UI state.【F:lib/presentation/providers/unified_trace_provider.dart†L135-L213】【F:lib/presentation/providers/unified_trace_provider.dart†L281-L309】【F:lib/data/services/trace_persistence_service.dart†L16-L86】
* History is capped at 50 runs to preserve storage across phone, tablet, and desktop targets; older entries are pruned automatically when new traces are added.【F:lib/data/services/trace_persistence_service.dart†L17-L49】

### Saving and Restoring Traces

* Run a simulation via the **Simulation › Simulate** button in the side panel; every successful run pushes a `SimulationResult` into the notifier, which immediately saves the trace, associates automaton metadata, and refreshes any history widgets bound to the provider.【F:lib/presentation/widgets/simulation_panel.dart†L92-L154】【F:lib/presentation/providers/unified_trace_provider.dart†L204-L214】【F:lib/data/services/trace_persistence_service.dart†L23-L49】
* Connect your Trace History command (drawer entry, sheet, or overflow action) to `loadTraceFromHistory(traceId)`; the notifier rehydrates the immutable trace, resets the viewer to the first step, and exposes filtered lists for type- or automaton-specific menus.【F:lib/presentation/providers/unified_trace_provider.dart†L117-L176】【F:lib/presentation/providers/unified_trace_provider.dart†L330-L344】
* Metadata such as acceptance verdict, automaton identifiers, and execution time are preserved so future UI surfaces can filter by model or input string without recomputing the simulation.【F:lib/data/services/trace_persistence_service.dart†L60-L118】

### Navigating Steps

* Enable **Step-by-Step Mode** using the toggle in the Simulation panel; this binds the trace viewer to `UnifiedTraceState.currentStepIndex` and emits highlights into the canvas.【F:lib/presentation/widgets/simulation_panel.dart†L351-L412】【F:lib/presentation/providers/unified_trace_provider.dart†L18-L112】
* Use the transport controls (Previous/Play–Pause/Next/Reset) to move through configurations. Each interaction calls the notifier navigation helpers, persists the new cursor position, and keeps highlights synchronized.【F:lib/presentation/widgets/simulation_panel.dart†L520-L616】【F:lib/presentation/providers/unified_trace_provider.dart†L113-L149】【F:lib/data/services/trace_persistence_service.dart†L86-L115】
* Large traces can be folded inside the viewer; expand collapsed sections to skim hundreds of steps without losing selection state.【F:lib/presentation/widgets/trace_viewers/base_trace_viewer.dart†L31-L108】

### Cleaning History and Handling Errors

* Clear the in-memory trace using the **Reset** icon in the Step-by-Step controls, which resets the cursor and clears highlights before the notifier drops the persisted snapshot.【F:lib/presentation/widgets/simulation_panel.dart†L520-L616】【F:lib/presentation/providers/unified_trace_provider.dart†L221-L236】
* Surface a **Clear All Traces** action in the same menu where you list saved runs; wiring it to `clearAllTraces()` removes saved simulations, current selections, and cached metadata from SharedPreferences.【F:lib/presentation/providers/unified_trace_provider.dart†L237-L252】【F:lib/data/services/trace_persistence_service.dart†L118-L140】
* Any I/O failure surfaces a toast/banner sourced from `errorMessage`; check device storage quotas if saves/imports begin to fail.【F:lib/presentation/providers/unified_trace_provider.dart†L155-L176】【F:lib/presentation/providers/unified_trace_provider.dart†L248-L272】

### Exporting and Importing

* Offer an **Export JSON** command alongside history management actions; `exportTraceHistory()` bundles traces, metadata, and timestamps into a portable payload for backups.【F:lib/presentation/providers/unified_trace_provider.dart†L253-L266】【F:lib/data/services/trace_persistence_service.dart†L140-L189】
* Pair an **Import JSON** option with `importTraceHistory(json)`, which merges stored traces, refreshes statistics, and updates any bound history lists; duplicates are overwritten by trace ID, so segment exports per cohort when sharing between devices.【F:lib/presentation/providers/unified_trace_provider.dart†L264-L309】【F:lib/data/services/trace_persistence_service.dart†L140-L213】
* Statistics (total runs, acceptance ratio, per-type counts) are recalculated after each import/export cycle and can drive dashboards or educator analytics modules.【F:lib/presentation/providers/unified_trace_provider.dart†L273-L309】【F:lib/data/services/trace_persistence_service.dart†L189-L213】

## Manual Verification Checklist

1. Open the automaton workspace and confirm existing automata render inside the GraphView canvas with overlays active.【F:lib/presentation/widgets/automaton_graphview_canvas.dart†L187-L236】
2. Add, drag, rename, and delete states/transitions; every change should propagate to the inspector panels maintained by `AutomatonProvider` and related notifiers.【F:lib/features/canvas/graphview/graphview_canvas_controller.dart†L60-L214】【F:lib/presentation/providers/automaton_provider.dart†L25-L219】
3. Trigger zoom, fit, reset, undo, redo, and add-state actions via the toolbar and gesture targets, confirming the controller updates the viewport accordingly.【F:lib/presentation/widgets/graphview_canvas_toolbar.dart†L33-L138】【F:lib/features/canvas/graphview/base_graphview_canvas_controller.dart†L17-L220】
4. Run a simulation and ensure highlights follow the active step while clearing when playback stops.【F:lib/features/canvas/graphview/graphview_highlight_channel.dart†L5-L19】【F:lib/core/services/simulation_highlight_service.dart†L57-L101】
5. Execute `flutter analyze` (and `flutter test` when suites exist) before requesting review.

## Troubleshooting

* **Canvas not updating** – Verify the controller is still attached and that `synchronize` is invoked after mutating automata outside the canvas scope; stale listeners or an outdated snapshot can prevent GraphView from rebuilding.【F:lib/features/canvas/graphview/base_graphview_canvas_controller.dart†L57-L166】
* **Transition edits not sticking** – Ensure the inline overlay is saved; dismissing it cancels the mutation. Confirm the mapper rebuilds the automaton snapshot so provider state matches the canvas representation.【F:lib/presentation/widgets/automaton_graphview_canvas.dart†L333-L494】【F:lib/features/canvas/graphview/graphview_automaton_mapper.dart†L7-L130】
* **Highlights not clearing** – Check that `SimulationHighlightService` is pointing to the GraphView channel and that `clear()` is invoked when simulators finish processing.【F:lib/presentation/widgets/automaton_graphview_canvas.dart†L41-L84】【F:lib/core/services/simulation_highlight_service.dart†L57-L101】

## Maintenance & Extensibility Notes

* Debug logging for GraphView flows is centralized under `AutomatonProvider` and the canvas controllers. Run the app in debug/profile mode to see messages such as `addState`, `removeTransition`, undo/redo counters, and highlight sanitization directly in the console; these traces originate from `_traceGraphView` and `_logGraphViewBase` helpers.【F:lib/presentation/providers/automaton_provider.dart†L33-L367】【F:lib/features/canvas/graphview/base_graphview_canvas_controller.dart†L17-L290】
* `SimulationHighlightService` now tracks `dispatchCount`/`lastHighlight` and records when indices are out of range—helpful when diagnosing highlight desynchronization between simulator panels and the canvas.【F:lib/core/services/simulation_highlight_service.dart†L8-L126】
* Canvas-specific controllers (`GraphViewCanvasController`, `GraphViewTmCanvasController`, `GraphViewPdaCanvasController`) include granular logs for state/transition mutations and snapshot merges; reuse these helpers when introducing new gestures or automation to keep observability consistent.【F:lib/features/canvas/graphview/graphview_canvas_controller.dart†L14-L214】【F:lib/features/canvas/graphview/graphview_tm_canvas_controller.dart†L16-L212】【F:lib/features/canvas/graphview/graphview_pda_canvas_controller.dart†L16-L212】
