# Changelog

All notable release-facing changes for Turing Lab are tracked here. The project
is still work in progress; `V1_SCOPE.md` remains the source of truth for the
Apple v1.0 release scope.

## Unreleased

- Complete the product rename to Turing Lab across Dart identifiers, package
  imports, platform runners, release tooling, documentation, examples, and
  tracked paths; CI now rejects accidental reintroduction of the former name.
- Continue stabilizing the Apple v1.0 release path for iPhone, iPad, and
  native macOS.
- Track known test-suite baselines and release blockers in `AGENTS.md` and the
  `release/` documentation.
- Keep the roadmap in `ROADMAP.md` aligned with deferred JFLAP parity work.

## 1.0.0 Baseline

This baseline describes the public v1.0 app scope currently documented for
Apple platforms.

### Added

- FSA workspace for creating, editing, simulating, minimizing, and converting
  finite automata.
- Grammar workspace with editing, parsing, FIRST/FOLLOW, CNF/GNF, and supported
  conversion workflows.
- PDA workspace with canvas editing, examples, simulation, trace visualization,
  and SVG export.
- TM workspace for single-tape Turing machines with canvas editing, examples,
  simulation, trace visualization, and SVG export.
- Regex workspace for validation, sample testing, comparison, simplification,
  sample generation, and automaton conversion.
- Pumping Lemma practice workflow.
- Offline examples bundled from `assets/examples/`.
- Material 3 UI with responsive layouts for phone, tablet, desktop, and web
  form factors.

### File Interoperability

- FSA: JFLAP XML import/export, JSON import/export, SVG export, and PNG export
  on native platforms.
- Grammar: JFLAP grammar import/export and SVG export.
- PDA: SVG export only in v1.0.
- TM: SVG export only in v1.0.
- Regex and Pumping Lemma: no file import/export in v1.0.

### Platform Status

- iPhone and iPad are Apple v1.0 release targets with release QA tracked in
  `release/APPLE_QA_MATRIX.md`.
- macOS is an Apple v1.0 release target with supplemental validation tracked in
  `release/MACOS_QA_CHECKLIST.md` and
  `release/MACOS_PLATFORM_VALIDATION.md`.
- Android has a release signing workflow documented in the README.
- Web, Windows, and Linux are maintained as Flutter targets but do not yet have
  release checklists equivalent to the Apple and Android paths.

### Known Limitations

- PDA JFLAP XML and JSON import/export are deferred until round-trip validation
  is complete.
- TM JFLAP XML and JSON import/export are deferred until round-trip validation
  is complete.
- TM support is single-tape only.
- Mealy and Moore machines are not implemented.
- Brute-force parser visualization is not implemented.
- PNG export is unavailable on web builds.
- Manual archived-build desktop QA is still tracked separately in the release
  documentation before macOS is called fully release-ready.
