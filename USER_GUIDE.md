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
* Desktop and tablet layouts use `GraphViewCanvasToolbar`; phone layouts use the bottom `MobileAutomatonControls` tray. Both surfaces expose the available canvas tools, undo/redo, and viewport commands for their layout.【F:lib/presentation/widgets/graphview_canvas_toolbar.dart†L27-L190】【F:lib/presentation/widgets/mobile_automaton_controls.dart†L15-L193】
* Phone layouts split canvas commands from workspace shortcuts. `MobileAutomatonControls` owns the bottom canvas tray, while the top `CanvasQuickActions` surface shows Help and conditionally exposes Simulate, Algorithms, and TM Metrics when the current automaton supports them. FSA, PDA, and TM pages use this split below the mobile breakpoint; tablet and desktop layouts render the canvas toolbar instead.【F:lib/presentation/widgets/mobile_automaton_controls.dart†L15-L193】【F:lib/presentation/widgets/canvas_quick_actions.dart†L3-L50】【F:lib/presentation/pages/fsa_page/fsa_page_behavior.dart†L420-L459】【F:lib/presentation/pages/pda_page.dart†L330-L367】【F:lib/presentation/pages/tm_page.dart†L219-L256】

### Core Actions

* **Add State** – Enable the Add State tool (or trigger the callback) and tap the canvas to drop a node at the tapped world coordinates. The controller assigns unique IDs/labels and marks the first state as initial automatically.【F:lib/presentation/widgets/automaton_graphview_canvas.dart†L254-L303】【F:lib/features/canvas/graphview/graphview_canvas_controller.dart†L60-L119】
* **Move State** – Drag a node to reposition it; the controller normalizes the delta according to the current zoom level before persisting the new coordinates via `AutomatonProvider`.【F:lib/presentation/widgets/automaton_graphview_canvas.dart†L304-L332】【F:lib/features/canvas/graphview/graphview_canvas_controller.dart†L121-L150】
* **Add Transition** – Activate the Transition tool, then tap a source state and a destination state to open the inline editor. Saving updates the edge snapshot and forwards the mutation to the provider, ensuring tape/stack metadata stays aligned for advanced automata.【F:lib/presentation/widgets/automaton_graphview_canvas_interactions.dart†L314-L364】【F:lib/presentation/widgets/automaton_graphview_canvas_interactions.dart†L445-L475】【F:lib/features/canvas/graphview/graphview_canvas_controller.dart†L152-L214】
* **Select and Edit** – With the Select tool active, single-tap a state to select it; double-tap, long-press, or secondary-click it to open state properties. Tap a transition path to edit it directly; overlapping paths open a chooser first.【F:lib/presentation/widgets/automaton_graphview_canvas_interactions.dart†L165-L246】【F:lib/presentation/widgets/automaton_graphview_canvas_interactions.dart†L314-L364】【F:lib/presentation/widgets/automaton_graphview_canvas_interactions.dart†L445-L501】
* **Viewport and History Controls** – Use toolbar or mobile-tray buttons to zoom in/out, fit content, reset the view, and undo/redo. Pan and pinch gestures manipulate the viewport directly. Keyboard shortcuts cover tool selection and undo/redo; they do not replace the viewport buttons.【F:lib/presentation/widgets/graphview_canvas_toolbar.dart†L100-L184】【F:lib/presentation/widgets/mobile_automaton_controls.dart†L73-L144】【F:lib/presentation/widgets/automaton_graphview_canvas.dart†L57-L75】【F:lib/features/canvas/graphview/graphview_viewport_highlight_mixin.dart†L145-L179】
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
2. Single-tap a state to select it; double-tap, long-press, or secondary-click to edit it; tap a transition path to edit that transition. Add, drag, rename, and delete states/transitions and confirm each change reaches the owning provider.【F:lib/presentation/widgets/automaton_graphview_canvas_interactions.dart†L165-L246】【F:lib/presentation/widgets/automaton_graphview_canvas_interactions.dart†L314-L501】【F:lib/features/canvas/graphview/graphview_canvas_controller.dart†L60-L214】
3. Trigger zoom in/out, fit, reset, undo, redo, and add-state actions from the layout's control surface, then confirm pan and pinch gestures update the viewport without changing the graph model.【F:lib/presentation/widgets/graphview_canvas_toolbar.dart†L100-L184】【F:lib/presentation/widgets/mobile_automaton_controls.dart†L73-L144】【F:lib/features/canvas/graphview/graphview_viewport_highlight_mixin.dart†L145-L179】
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
* Treat canvas interaction documentation as part of the definition of done. Changes to gestures or control surfaces must update `kHelpContent`, this guide, and the focused widget tests together so user instructions stay aligned with the shipped UI.【F:lib/core/constants/help_content.dart†L16-L117】【F:test/widget/presentation/automaton_graphview_canvas_test.dart†L322-L496】【F:test/widget/presentation/graphview_canvas_toolbar_test.dart†L278-L319】【F:test/widget/presentation/mobile_automaton_controls_test.dart†L29-L174】
