# Turing Lab Roadmap

This roadmap explains the intended direction after the Apple v1.0 baseline.
It is not a commitment to specific dates. `V1_SCOPE.md` remains authoritative
for the current release scope, while this document records what is planned,
deferred, or explicitly out of scope.

GitHub issue #306 is the sole live implementation Epic. The machine-readable
phase and dependency map for its children is
[`docs/issue-roadmap.json`](docs/issue-roadmap.json). Validate the map locally
with `python3 tool/check_issue_roadmap.py --github` before changing phases or
adding work to the Epic.

## Current Baseline: v1.0

Turing Lab v1.0 focuses on a stable educational core:

- FSA, Grammar, PDA, TM, Regex, and Pumping Lemma workspaces.
- Validated FSA and grammar file workflows where release coverage exists.
- PDA and TM simulation/editing workflows with SVG export, but without PDA/TM
  JFLAP or JSON round-trip file support.
- Apple release validation for iPhone, iPad, and macOS, plus an Android signing
  workflow.

## v1.1 Direction: Stabilization And Interoperability

The next milestone should prioritize reliability and file compatibility before
adding new machine families.

- Complete PDA JFLAP XML import/export with round-trip validation.
- Complete PDA JSON import/export with round-trip validation.
- Complete TM JFLAP XML import/export with round-trip validation.
- Complete TM JSON import/export with round-trip validation.
- Expand import/export diagnostics so malformed files explain the exact
  unsupported construct.
- Keep release documentation synchronized with the actual QA matrix for each
  shipped platform.

Rationale: users moving from JFLAP need dependable file workflows. This work
also reduces data-loss risk before the project expands into new model types.

## v1.2 Direction: JFLAP Parity Gaps

After the existing workspaces have stronger persistence and release coverage,
Turing Lab can broaden feature parity.

- Multi-tape Turing machines.
- Mealy and Moore machines.
- Brute-force parser visualization for grammar workflows.
- Richer visual explanations for algorithm steps.
- Guided tutorials and classroom-oriented walkthroughs.

Rationale: these are visible JFLAP capability gaps, but they touch modeling,
UI, simulation, persistence, and file interoperability. They should follow the
v1.1 stabilization work rather than ship as partial features.

## Capability Matrix

| Capability | Turing Lab v1.0 status | Roadmap |
| --- | --- | --- |
| DFA/NFA editing and simulation | Shipped | Continue hardening |
| DFA minimization and FSA conversions | Shipped | Continue hardening |
| FSA JFLAP XML round-trip | Shipped | Continue compatibility testing |
| FSA JSON round-trip | Shipped | Continue compatibility testing |
| Grammar editing and parsing workflows | Shipped | Continue hardening |
| Grammar JFLAP import/export | Shipped | Continue compatibility testing |
| PDA editing and simulation | Shipped | Continue hardening |
| PDA SVG export | Shipped | Continue hardening |
| PDA JFLAP/XML round-trip | Deferred | v1.1 target |
| PDA JSON round-trip | Deferred | v1.1 target |
| Single-tape TM editing and simulation | Shipped | Continue hardening |
| TM SVG export | Shipped | Continue hardening |
| TM JFLAP/XML round-trip | Deferred | v1.1 target |
| TM JSON round-trip | Deferred | v1.1 target |
| Multi-tape TM | Not implemented | v1.2 candidate |
| Regex workflows | Shipped | Continue hardening |
| Pumping Lemma practice | Shipped | Continue hardening |
| Mealy/Moore machines | Not implemented | v1.2 candidate |
| Brute-force parser visualization | Not implemented | v1.2 candidate |

## Platform Roadmap

| Platform | Current status | Next step |
| --- | --- | --- |
| iPhone / iPad | Apple v1.0 release target | Keep `release/APPLE_QA_MATRIX.md` current |
| macOS | Apple v1.0 release target | Complete manual archived-build desktop QA |
| Android | Supported build target with signing workflow | Add a formal Android QA/release checklist |
| Web | Preview/classroom demo target | Document web-specific QA and export limitations |
| Windows | Preview/community-supported target | Add release checklist before claiming release support |
| Linux | Preview/community-supported target | Add release checklist before claiming release support |

Windows and Linux directories are present because Flutter supports those
desktop targets, but the repository does not yet include platform release
evidence equivalent to Apple or Android. Until those checklists exist, treat
Windows and Linux as development or community-supported builds.
