# Changelog

This file summarizes release-facing changes. It records implemented behavior,
not App Store approval or tester availability; live distribution state belongs
in the release evidence.

## 1.0.0 (2026-09-04)

- Completed the Turing Lab identity migration across code, packages, platform
  runners, release tooling, documentation, and public links.
- Expanded the typed formal-system registry with unrestricted grammar, Mealy,
  Moore, and L-system modules.
- Added single-tape, multi-tape, and building-block TM document workflows.
- Added bounded brute-force parsing, guided derivations, dependency analysis,
  and additional grammar/automata conversions.
- Added typed JFLAP and JSON codecs for PDA, TM, regex, Pumping Lemma,
  transducers, unrestricted grammar, and L-system documents.
- Added explicit compatibility, loss-consent, cancellation, and bounded-unknown
  results across hard-edge workflows.
- Published the Flutter web app with co-located support and privacy pages under
  the canonical GitHub Pages root.
- Kept QA local and manual through `tool/qa.sh`; no repository-owned GitHub
  Actions workflow is committed.

### Workspaces

- Finite-state automata with editing, simulation, minimization, conversions,
  traces, and visual exports.
- Context-free and unrestricted grammars with parsing, transformations,
  derivations, conversions, and examples.
- Pushdown automata with configurable acceptance, simulation, diagnostics,
  conversions, codecs, and exports.
- Turing machines with single/multi-tape execution, reusable building blocks,
  diagnostics, codecs, and exports.
- Regular expressions with validation, testing, comparison, generation,
  simplification, persistence, and automaton conversion.
- Regular and context-free Pumping Lemma exercises with persisted progress.
- Mealy and Moore transducers with editing, simulation, examples, codecs, and
  visual exports.
- L-systems with bounded generation, advanced supported rule semantics, turtle
  rendering, examples, codecs, and visual exports.

### Application shell

- Material 3 UI with light/dark themes and responsive phone, tablet, desktop,
  and web layouts.
- Offline examples, contextual help, session restoration, undo/redo, and
  model-aware import/export actions.
- Registry-driven navigation and capability filtering.

### Distribution surfaces

- iOS/iPadOS and native macOS archive paths with manual Apple release gates.
- Signed Android build and closed-testing workflow.
- Flutter web publication at `https://thalesmms.github.io/Turing-Lab/` with
  support and privacy pages in the same artifact.

### Explicit boundaries

- PNG export is unavailable on web builds.
- Parametric L-system expressions are preserved but not executed.
- Some JFLAP fields cannot represent richer local semantics; affected exports
  report losses instead of silently discarding them.
- Store approval, compliance, tester assignment, and physical-device QA remain
  independent release evidence.
