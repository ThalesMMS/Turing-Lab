# Multi-tape to single-tape TM reduction

Implementation: `lib/core/algorithms/tm/tm_multi_tape_reducer.dart`
(`TMMultiTapeReducer`, `TMMultiTapeReductionChecker`). Chained into
`TMToGrammarConverter.build` for the TM to unrestricted grammar conversion
(issue #438). Tests: `test/unit/core/tm/tm_multi_tape_reducer_test.dart` and
the multi-tape cases in `test/unit/core/tm/tm_to_unrestricted_grammar_test.dart`.

## Supported domain

- Source machine: `TM` with `tapeCount` k ≥ 2, no building blocks, acceptance
  policy `finalState`, blank symbol outside the input alphabet, and a valid
  model (`TM.validate()` empty). Every transition is a k-vector of
  (read, write, move); nondeterminism is allowed.
- Not supported (fails closed with structured diagnostics, never a partial
  machine): building-block projects (`building-blocks-unsupported`; inline or
  remove them first, their own reduction needs a separate scope), halting or
  mixed acceptance policies (`acceptance-policy-unsupported`), invalid
  machines, and single-tape sources (`already-single-tape`, outcome
  `notApplicable`).

## Encoding

The reduced machine has one two-way infinite tape whose cells are either an
input symbol of Σ (before initialisation) or a composite cell

```
⟨s₁,…,s_k|h₁…h_k⟩   sᵢ ∈ Γ, hᵢ ∈ {0,1}
```

with sᵢ the symbol of track i and hᵢ = 1 when head i sits on the cell. There
is no native 2k-track support in the model: every composite is one ordinary
tape symbol string, and the report's `cells` map decodes it. The reduced
blank is `⟨B,…,B|0…0⟩`; the reduced input alphabet is Σ unchanged; the tape
alphabet is Σ ∪ all `|Γ|^k · 2^k` composites. Track alignment: cell j of the
reduced tape holds position j of every source tape, so a head that moves
left of the start writes composites into the blank region on the left.

## Construction

Phases of the reduced state space (all generated lazily by breadth-first
search from the initial state):

1. `initializeFirst` / `initializeRest`: sweep right over the plain input,
   rewriting each symbol a as `⟨a,B,…|0…0⟩`; the first cell also receives
   every head marker (`|1…1`). On empty input the first cell becomes
   `⟨B,…|1…1⟩` directly.
2. `rewind`: sweep left to the marked first cell.
3. `read(q, reads)`: from a cell at or left of every head, sweep right
   collecting the symbol under each marked track into `reads`. When all k
   reads are known, choose (nondeterministically, one reduced transition per
   candidate) a source transition t ∈ δ(q, reads) and apply it to the current
   cell.
4. `apply(t, done, pendingLeft)`: sweep left. On each cell, first place the
   markers of tracks that moved left from the cell on the right
   (`pendingLeft`), then for each still-unprocessed marked track write its
   symbol and move its marker: stay keeps it, left defers it to the next
   cell, right needs an `excursion` (write, step right, add the marker, step
   left, `resume`). The sweep ends when all k tracks are done and nothing is
   pending; the machine is then at or left of every head and enters
   `read(t.target, ∅)`.

Reduced `read(q, ∅)` states are accepting exactly when q is accepting, so a
source machine that enters a final state accepts as soon as its step has been
applied. A `read` state with no applicable source transition halts without
accepting, matching the source under final-state acceptance.

## Invariants

- Exactly one marker per track exists on the tape after initialisation.
- Every `read(q, ∅)` state is entered with the head at or left of all markers,
  so a rightward sweep always finds all k reads.
- Every `apply` sweep starts at the rightmost marked cell and processes each
  marked track exactly once (`done` set), including markers it moved.
- One source step costs O(span) reduced steps, where span is the distance
  between the leftmost and rightmost head; the differential checker scales the
  reduced step budget by `reducedStepFactor` for that reason.

## Budgets and diagnostics

`TMMultiTapeReductionLimits` bounds the expansion: `maxTapeSymbols`
(composite count, checked before generation), `maxStates` and
`maxTransitions` (checked during generation). Any overflow returns
`budgetExceeded` with the offending `count` and `limit` in a structured
`tm.multi-tape-reduction.*-budget` message. When chained into the grammar
conversion those become `constructionLimit` reports with
`detailCode: multi-tape-reduction-<code>`.

## Provenance

`TMMultiTapeReductionReport.stateProvenance` records the phase, source state,
source transition, partial reads and done/pending tape sets of every reduced
state; `transitionProvenance` records the phase, the served source state, the
applied source transition and the tapes it wrote. The grammar report keeps
the reduction and `TMToGrammarConstructionReport.sourceReferencesForOriginal`
maps production provenance back to source states and transitions, which the
construction workspace uses to highlight the source machine.

## Evidence

`TMMultiTapeReductionChecker.check` runs the source through the multi-tape
analyzer and the reduction through the single-tape analyzer on sampled inputs
under explicit step, configuration and time limits. Outcomes are
`matchingAcceptance`, `matchingRejection`, `mismatch`, `boundedUnknown`
(a limit or timeout on either side) or `invalid`. `isProof` is always false:
finite samples are evidence, and a bounded run is neither a rejection nor a
confirmation. The grammar differential checker applies the same rule with the
multi-tape analyzer on the source side.
