# Persistence Audit

Date: 2026-09-06 (supersedes the 2026-04-22 audit)

## Summary

- Offline examples are bundled assets loaded through `rootBundle` from `assets/examples/`; the loading path does not depend on network access.
- User settings persist in `SharedPreferences` through `SharedPreferencesSettingsRepository`.
- Simulation trace history and the active step-by-step trace persist in `SharedPreferences` through `TracePersistenceService`.
- The active editor session persists in `SharedPreferences` through `ActiveSessionPersistenceService` while Auto Save is enabled, and it is restored on cold start. The 2026-04-22 claim that the editor model lived only in Riverpod memory is obsolete.
- Teaching workspaces keep two further local stores: grammar teaching sessions (`SharedPreferencesGrammarTeachingSessionStore`) and manual conversion sessions (`SharedPreferencesManualConversionSessionStore`).

## Offline behavior

- Examples are packaged with the app and loaded from local assets.
- `ExamplesService` treats a partial cache as partial, avoiding incorrect "library already loaded" behavior after a single example lookup.
- Full-library loads also warm per-category caches, so repeated category reads do not re-open the asset bundle unnecessarily.

## Settings persistence

- Settings survive relaunch through `SharedPreferences`.
- Malformed or type-mismatched keys fall back per setting instead of aborting the whole settings load.
- Unsupported theme-mode values fall back to `system`.
- The empty-string symbol lives under `settings_empty_string_symbol`; the legacy `settings_epsilon_symbol` key is migrated before `runApp`.

## Trace persistence and restoration

- Trace history survives relaunch and is loaded at startup.
- The active current trace restores on startup, including the saved step index.
- `UnifiedTraceNotifier.setTrace()` persists the active trace immediately, so a user does not need to navigate a step before relaunch recovery works.
- Malformed persisted trace history and metadata are sanitized entry-by-entry so one bad record does not discard the whole store.
- Malformed `current_trace` payloads are cleared during restoration instead of repeatedly failing every launch.

## Active session persistence and cold-start restoration

- `ActiveSessionPersistenceService` (`lib/data/services/active_session_persistence_service.dart`) implements `ActiveSessionRepository` over `SharedPreferences` under the `active_editor_session` key. It honours `settings_auto_save`: when Auto Save is off the snapshot is cleared and startup restore is skipped.
- `activeSessionPersistenceProvider` restores one saved `ActiveSessionSnapshot` during app startup and then listens to the editor providers, debouncing writes and flushing pending snapshots when the app becomes inactive, hidden, paused or detached.
- `ActiveSessionSnapshotCodec` (`lib/data/services/active_session_snapshot_codec.dart`) writes envelope version `ActiveSessionSnapshot.currentVersion` (3). Each document is stored under its stable `FormalSystemKey` (`type:variant`) with the module's `DocumentSchemaId`, `DocumentSchemaVersion` and typed JSON payload, plus per-document annotation collections. Version 0 and 1 payloads are decoded through the historical workspace index and rewritten in the current envelope.
- `ActiveSessionModuleRegistry` (`lib/data/services/active_session_module_registry.dart`) wraps `DefaultFormalSystemRegistry` and supplies the JSON session capability for every registered module. Modules that ship their own session capability (unrestricted grammar, L-systems, Mealy, Moore) keep it; the built-in FSA, grammar, PDA, TM, regex and both Pumping Lemma variants receive one from the registry.
- Restored formal systems and their session namespaces:

  | Formal system | `FormalSystemKey` | Schema | Session namespace |
  | --- | --- | --- | --- |
  | Finite automaton | `fsa:standard` | `turing-lab.fsa` v1 | `session.fsa` |
  | Context-free grammar | `grammar:standard` | `turing-lab.grammar` v1 | `session.grammar` |
  | Unrestricted grammar | `grammar:unrestricted` | `turing-lab.unrestricted-grammar` v1 | `session.grammar.unrestricted.v1` |
  | Pushdown automaton | `pda:single-stack` | `turing-lab.pda` v1 | `session.pda` |
  | Turing machine | `tm:single-tape` | `turing-lab.tm` v1 | `session.tm` |
  | Regular expression | `regex:standard` | `turing-lab.regex` v1 | `session.regex` |
  | Pumping Lemma (regular) | `pumping-lemma:regular` | `turing-lab.pumping-lemma.regular` v1 | `session.pumping-lemma.regular` |
  | Pumping Lemma (context-free) | `pumping-lemma:context-free` | `turing-lab.pumping-lemma.context-free` v1 | `session.pumping-lemma.context-free` |
  | Mealy machine | `transducer:mealy` | `turing-lab.mealy` v1 | `session.transducer.mealy.v1` |
  | Moore machine | `transducer:moore` | `turing-lab.moore` v1 | `session.transducer.moore.v1` |
  | L-system | `l-system:deterministic-context-free` | `turing-lab.l-system` v1 | `session.l-system.v1` |

- Pumping Lemma documents carry the problem, the decomposition session and the challenge progress; `PumpingLemmaWorkspace._loadDocument` reconciles stored progress against the current content versions before restoring it.
- Unsupported data is preserved rather than destroyed: a newer envelope version is copied to `active_editor_session_unsupported_v<N>` and a newer document schema to `active_editor_session_unsupported_<type>_<variant>_v<N>`, then the launch continues without that document. Malformed JSON or a corrupt schema identity is cleared and ignored (fail-open).

## Teaching and manual-conversion stores

- `SharedPreferencesGrammarTeachingSessionStore` stores normalization, LL(1) and LR(1) teaching sessions under `grammar_teaching_session.v1.<kind>.<grammarId>.<revision>`, where `kind` is `normalization`, `parse.ll1` or `parse.lr1`. Entries are keyed by grammar revision, so editing the grammar invalidates the stored session; saving under a new revision removes the same grammar's entries for earlier revisions.
- `SharedPreferencesManualConversionSessionStore` stores manual FA to regex, FA to grammar and regex to FA sessions under `manual_conversion_session.<workspaceKey>`, validated against the source document id and revision on load.

## Remaining risk

- Cold-start restoration is a single snapshot: there is no recent-session history or explicit checkpoint list.
- Flutter state-restoration APIs are not wired for page/widget UI restoration (`restorationScopeId`, `RestorationMixin`, restorable controllers). Relaunch recovery is data-level, not navigation/UI-state restoration.
- Lifecycle flushes are best-effort: platform termination can still end the process before an asynchronous `SharedPreferences` write completes.
- Nothing in local storage has a portable backup or export path.

## Recommended follow-up

- Consider a recent-session stack or explicit editor checkpoints if classroom workflows need multiple recoverable drafts.
- Add an explicit corrupted-data recovery path in the UI if users need visibility when stored traces, sessions or teaching data are discarded or parked under an unsupported-backup key.
