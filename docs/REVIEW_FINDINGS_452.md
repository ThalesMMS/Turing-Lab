# Revalidation of review findings #452

The findings were checked on `codex/open-issues`, after the mechanical #448
import migration. The following changes address the still-reproducible cases.

| Area | Result |
| --- | --- |
| CNF nullable expansion | Overflow-safe bound before subset enumeration; regression cases with 32, 64 and 128 nullable positions. |
| LR(1) marker | Fresh end marker, including grammars declaring both `$` and `$$`; literal tokens remain parseable. |
| CFG to PDA | Fresh bottom symbol; atomic push boundaries survive editing and stack preview. |
| Grammar/FSA conversion | Undeclared terminal rejected; epsilon aliases excluded from generated grammar terminals. |
| Regex simplification | Concatenation resolved before removing a complete empty union operand in both direct and teaching paths. |
| Empty regex language | Fragment and completion steps allow no accepting state instead of throwing. |
| TM language exploration | Shortlex token lists passed to `analyzeTokens`, retained for witness replay. |
| PDA diagnostics | Incremental retained-memory estimate; lambda operations excluded from push/pop sets; simulation documentation corrected. |
| TM validation | Deterministic conflict categorized as validation. |
| TM controls | Trimmed integer fields and shared bounds checked before candidate estimates, including time profiling. |
| Async analysis | Exceptions finish the active request; trace loading cancellation is generation-aware; block/multitape failures reset busy state. |
| Semantic revision | Acceptance policy participates in request invalidation. |
| TM presentation | Localized limit/space descriptions and configured empty-string notation. |
| Manual conversion | Changed requirement resets local form state; equivalent rebuild retains the draft; late restart/branch completion ignores disposed widgets. |
| Grammar teaching | Typed localized step/witness labels; graph viewport skips Tab traversal and takes keyboard focus only after an explicit click. |
| Language comparison | Original subset-construction diagnostic retained and state-limit exhaustion classified as inconclusive. Tested with an eleven-state NFA requiring 1024 DFA states. |
| Grammar SVG | Fresh terminal sink is present, so terminal edges render. The existing `stateId\|symbol` key already matched the shared renderer and was retained. |
| Plurals | Explicit zero/one/other branches for conversion summaries/evidence, reduction budgets and witness depth, including Portuguese zero. |
| Literal inventories | Reviewed changed sources, localized new copy, preserved the inherited migration debt and recorded one exact existing compatibility key. |

## Findings already satisfied before this patch

- `BruteForceCFGParser` uses `(existingSignatures?.length ?? 0)` in its result-cap
  check; a null set does not bypass the cap.
- `RegexAnalyzer._computeNestingDepth` already tracks escapes and character classes.
- `DFAOperations` already reports the missing initial-state error in English.
- The building-block XML codec already reserves each block ID before recursive
  decoding and rejects reuse under a different tag as a duplicate identity.
- #448 removed all provisional barrels; the production algorithm inventory keeps
  its 344 entries and no longer lists those deleted paths as exclusions.

## Allowlist classification review

`Self-loop transitions must have a control point` and
`Non-deterministic transition from` are exact legacy diagnostic matching tokens,
consumed by validation adapters instead of displayed by those call sites. Their
protocol classification is retained with a specific compatibility rationale.
`4+ building blocks` is the JFLAP source-format version descriptor in persisted
metadata, not a block count or error sentence. `machine-schema-invalid` is a
stable structured codec code and already has no prose allowance. No scanner
rule was broadened.

## Validation

Targeted regressions cover algorithm boundaries, atomic stack editing/preview,
request failure and invalidation, disposal, SVG edges, and bilingual plurals.
The complete local QA commands and results are recorded in `AGENTS.md` and
`CLAUDE.md` after the candidate run. All results are local only.
