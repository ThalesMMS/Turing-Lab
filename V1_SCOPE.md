# Turing Lab Apple v1.0 Scope

This document is the authoritative scope for the first Apple release of Turing Lab on iPhone, iPad, and native macOS.

## Shipping modules

Turing Lab Apple v1.0 ships these six modules:

1. FSA
2. Grammar
3. PDA
4. TM
5. Regex
6. Pumping Lemma

## Module scope

### FSA
- In scope: creation, editing, simulation, and validated algorithm flows
- File support:
  - JFLAP XML import/export
  - JSON import/export
  - SVG export
  - PNG export on native platforms

### Grammar
- In scope: stable grammar editing, parsing, and conversion workflows that are ready for public release
- File support:
  - JFLAP grammar import/export
  - SVG export

### PDA
- In scope: Apple-ready canvas editing, examples, and simulation flows
- File support:
  - SVG export only

### TM
- In scope: Apple-ready canvas editing, examples, and simulation flows
- File support:
  - SVG export only

### Regex
- In scope: stable regex validation, testing, comparison, simplification, and automaton-conversion workflows
- File support:
  - No file import/export in v1.0

### Pumping Lemma
- In scope: guided pumping lemma practice and validation workflow
- File support:
  - No file import/export in v1.0

## Release limitations

- PNG export is unavailable on web builds.
- PDA JFLAP XML and JSON import/export are deferred because they do not yet have round-trip validation coverage for v1.0.
- TM JFLAP XML and JSON import/export are deferred because they do not yet have round-trip validation coverage for v1.0.
- Two known PDA validation test failures remain in the existing baseline; they are non-blocking for Apple v1.0 and must not expand into broader regressions.

## Release copy guidance

- Public-facing copy must describe Turing Lab as shipping FSA, Grammar, PDA, TM, Regex, and Pumping Lemma workflows.
- In-app navigation and help content must only expose supported v1.0 capabilities.
