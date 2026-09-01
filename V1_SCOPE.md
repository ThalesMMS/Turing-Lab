# Turing Lab Apple 1.0 Scope

This document describes the feature surface in the current Apple 1.0 build
line. Feature availability does not imply App Store approval, tester access, or
completed physical-device QA.

## Shipping workspaces

The application exposes these registered formal-system families:

1. Finite-state automata
2. Context-free grammars
3. Unrestricted grammars
4. Pushdown automata
5. Turing machines
6. Regular expressions
7. Regular and context-free Pumping Lemma exercises
8. Mealy transducers
9. Moore transducers
10. L-systems

The TM workspace supports single-tape, multi-tape, and reusable building-block
documents. The grammar surface includes bounded brute-force parsing and guided
derivation tools.

## Interoperability surface

- FSA: JFLAP XML and versioned JSON import/export, SVG, and native PNG.
- Context-free grammar: JFLAP grammar import/export and SVG.
- Unrestricted grammar: JFLAP XML and versioned JSON import/export.
- PDA: JFLAP XML and versioned JSON import/export, plus SVG.
- TM: JFLAP XML and versioned JSON import/export for supported single-tape,
  multi-tape, and building-block documents, plus SVG.
- Regex: JFLAP XML and versioned JSON import/export.
- Pumping Lemma: JFLAP XML and versioned JSON with explicit loss reporting.
- Mealy and Moore: JFLAP XML and versioned JSON import/export, SVG, and PNG.
- L-system: JFLAP XML and versioned JSON import/export, SVG, and PNG.

`docs/JFLAP_COMPATIBILITY.md` and `docs/JFLAP_PARITY_MATRIX.md` are the detailed
sources for supported semantics, intentional deviations, and loss policy.

## Release boundaries

- PNG export is unavailable in web builds.
- Parametric L-system expressions are preserved but not executed.
- Lossy JFLAP conversions require visible diagnostics and consent where the
  source format cannot represent local semantics.
- Apple archive, compliance, tester assignment, review, and physical-device QA
  remain release operations, not feature flags.
- Native macOS release readiness still requires the manual checklist under
  `release/`.

## Public-copy guidance

Public copy may name every shipping workspace above. It must describe format
support as scoped rather than implying that every format is lossless for every
formal system.

Do not describe a build as App Store-available, TestFlight-ready, or macOS
release-ready unless the current live service state and manual QA evidence
support that claim.
