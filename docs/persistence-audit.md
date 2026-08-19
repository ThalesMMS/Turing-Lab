# Persistence Audit

Date: 2026-04-22

## Summary

- Offline examples are bundled assets loaded through `rootBundle` from `assets/examples/`; the loading path does not depend on network access.
- User settings persist in `SharedPreferences` through `SharedPreferencesSettingsRepository`.
- Simulation trace history and the active step-by-step trace persist in `SharedPreferences` through `TracePersistenceService`.
- The in-editor automaton model is not restored on cold start. Current editor state remains in Riverpod memory, so closing the app without exporting or explicitly saving elsewhere still loses that work.

## Offline behavior

- Examples are packaged with the app and loaded from local assets.
- `ExamplesService` now treats a partial cache as partial, avoiding incorrect "library already loaded" behavior after a single example lookup.
- Full-library loads now also warm per-category caches, so repeated category reads do not re-open the asset bundle unnecessarily.

## Settings persistence

- Settings survive relaunch through `SharedPreferences`.
- Malformed or type-mismatched keys now fall back per setting instead of aborting the whole settings load.
- Unsupported theme-mode values fall back to `system`.

## Trace persistence and restoration

- Trace history survives relaunch and is loaded at startup.
- The active current trace now restores on startup, including the saved step index.
- `UnifiedTraceNotifier.setTrace()` now persists the active trace immediately, so a user no longer needs to navigate a step before relaunch recovery works.
- Malformed persisted trace history and metadata are sanitized entry-by-entry so one bad record does not discard the whole store.
- Malformed `current_trace` payloads are cleared during restoration instead of repeatedly failing every launch.

## Remaining risk

- Cold-start restoration is limited to settings and traces. There is no equivalent persistence path wired into dependency injection for the editor's current automaton/session state.
- Flutter state-restoration APIs are not yet wired for page/widget UI restoration (`restorationScopeId`, `RestorationMixin`, restorable controllers). Relaunch recovery here is data-level, not full navigation/UI-state restoration.

## Recommended follow-up

- Decide whether the current automaton should autosave locally, and if yes, add a dedicated persistence path for the active editor flow rather than keeping it in Riverpod memory only.
- Add an explicit corrupted-data recovery path in the UI if users need visibility when stored traces are discarded.
