# Grammar toolkit (analysis + transformations)

This document describes the grammar analysis and transformation tooling exposed in Turing Lab’s Grammar page. It is intended to be **educational**: the tool prefers returning structured diagnostics (warnings/errors) instead of crashing, and it explains the limitations of certain checks (notably ambiguity vs LL(1) conflicts).

## Scope

The toolkit currently provides:

- Structured diagnostics for common CFG issues:
  - Malformed productions / symbol set problems
  - Unreachable non-terminals
  - Unproductive non-terminals
- Parsing feedback with **farthest position**, **expected symbols**, and optional **derivation tree** on success.
- Transformations with step history:
  - CNF (Chomsky Normal Form)
  - GNF (Greibach Normal Form)

> Note: The app supports multiple parsing backends (Earley, PetitParser, and simple parsers). Parse feedback is “best effort”: some backends can provide richer expected-sets and/or derivation structure than others.

## Diagnostic model

Internally, grammar checks produce a list of `GrammarDiagnostic` entries.

Each diagnostic includes:

- `severity`: `info | warning | error`
- `code`: stable string identifier (suitable for future filtering)
- `message`: UI-facing explanation
- `symbols`: affected symbols (when applicable)
- `productionIds`: affected productions (when applicable)

The UI renders these diagnostics in algorithm panels and transformation reports.

## Analyses

### Malformed production checks

The analyzer validates common structural problems and reports them as diagnostics:

- Missing/invalid start symbol (e.g., start not in the non-terminal set)
- Empty productions
- Empty LHS
- LHS not a single non-terminal
- Unknown RHS symbols
- Epsilon (`λ`) misuse

Design goal: these checks should **not throw**; they emit diagnostics and let other analyses proceed.

### Unreachable non-terminals

Reachability is computed from `startSymbol` by traversing **non-terminal references** that appear on the RHS of productions.

A non-terminal is reported as unreachable when it is never visited.

Edge-case behavior:

- Missing/invalid start symbol is reported as a diagnostic.
- Unknown RHS symbols are reported (typically warning) and ignored for reachability unless they are known non-terminals.

### Unproductive non-terminals

A non-terminal is productive if it can derive a string of terminals (possibly empty, if epsilon is allowed).

The analyzer computes productive symbols via a fixed-point iteration:

1. Seed productive set with LHS of productions whose RHS is empty/epsilon.
2. Repeatedly add LHS if all RHS symbols are terminals or already-productive non-terminals.
3. Anything not marked productive at convergence is reported as unproductive.

Unknown RHS symbols are diagnosed; for productivity they are treated conservatively (the tool attempts to avoid crashing and may treat unknown symbols as terminals to continue analysis).

### Ambiguity indicators (LL(1) conflicts)

The “ambiguity” output is intentionally worded to avoid a common misconception:

- **LL(1) parse table conflicts mean the grammar is not LL(1)**.
- **Not LL(1) does not imply true ambiguity**.

In other words, the tool can reliably identify **non-LL(1)** behavior via conflicts, but it cannot in general decide ambiguity for arbitrary CFGs.

## Parse feedback

When you run a parse attempt, the tool returns a `GrammarParseReport` containing:

- `accepted`: whether the input is accepted
- `farthestPosition`: best-known farthest input index reached (useful on failure)
- `expectedSymbols`: best-effort set of symbols that could have been valid next
- `message`: human-readable explanation
- `trees`: optional derivation/parse tree(s) on success

Ambiguity hint:

- For some grammars/inputs, the Earley backend may be able to produce multiple valid parses.
- The UI should present this as an **“ambiguity witness for this input”**, not as a global guarantee.

## Transformations

All transformations return:

- Final transformed grammar
- `steps`: a list of `GrammarTransformationStep` entries (operation name, rationale, before/after snapshots, changed symbols/productions)
- `diagnostics`: warnings/errors encountered during transformation

### CNF (Chomsky Normal Form)

The CNF pipeline is implemented as a best-effort educational conversion. Typical steps:

1. **Precondition checks** and warnings (CFG assumptions)
2. **New start symbol** if the start symbol appears on any RHS
3. **Eliminate epsilon-productions**, preserving `S → ε` only when needed
4. **Eliminate unit productions** (A → B)
5. **Remove useless symbols** (unreachable/unproductive)
6. **Replace terminals in long RHS** with fresh non-terminals
7. **Binarize** productions longer than 2 symbols

Language-preservation note:

- Removing epsilon/unit/useless symbols is standard, but whether `ε` is preserved depends on whether the original grammar could derive `ε` and whether the transformation chooses to keep `S → ε`.
- The transformer emits diagnostics when it has to make an assumption.

### GNF (Greibach Normal Form)

GNF conversion is exposed when available from the underlying CFG toolkit implementation. It produces step history and emits warnings if a strict “is GNF” check fails after conversion.

## Reference implementations

See `docs/reference-deviations.md` for the recorded reference sources and any intentional educational deviations.
