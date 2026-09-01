# Turing Lab Roadmap

This roadmap records durable engineering priorities after completion of the
large JFLAP-parity implementation program. It is not a commitment to dates or
store availability.

The historical implementation Epic `#306` closed on August 27, 2026. No issue
was open in `ThalesMMS/Turing-Lab-dev` when this document was refreshed on
September 1, 2026. Re-query GitHub before treating that snapshot as current.

## Current product baseline

The registered application surface now includes:

- FSA, PDA, and TM editors with simulation, traces, diagnostics, and exports;
- single-tape, multi-tape, and building-block TM documents;
- context-free and unrestricted grammar workflows;
- bounded grammar parsers, guided derivations, and conversion workspaces;
- regular-expression editing, comparison, generation, and conversion;
- regular and context-free Pumping Lemma exercises;
- Mealy and Moore transducer editors and simulators;
- L-system generation, turtle rendering, examples, and exports;
- typed JFLAP/JSON interoperability with explicit compatibility diagnostics;
- offline examples, session restoration, responsive Material 3 UI, and help.

The detailed implementation evidence lives in `docs/JFLAP_PARITY_MATRIX.md`.

## Near-term priorities

### Release completion

- Complete App Store Connect compliance and tester/review decisions with live
  evidence and explicit authorization.
- Complete native macOS manual QA and synchronize its build number before the
  next archive.
- Keep Android closed-testing and signing evidence current.
- Preserve a reproducible GitHub Pages publication for the web app and its
  support/privacy pages.

### Reliability and interoperability

- Continue hard-edge certification for malformed, adversarial, and lossy file
  inputs.
- Keep the compatibility corpus deterministic and versioned.
- Preserve explicit unsupported results instead of silently approximating
  semantics.
- Expand differential evidence when a stable upstream reference exists.

### Classroom experience

- Improve guided tutorials without duplicating algorithm implementations.
- Extend visual explanations and accessibility for complex traces.
- Keep phone, tablet, desktop, and web interaction patterns aligned.
- Add features only through the typed formal-system extension boundary.

### Platform maturity

| Platform | Current status | Next evidence |
| --- | --- | --- |
| iPhone / iPad | Apple 1.0 release line under distribution validation | Live App Store/TestFlight state and physical-device QA |
| macOS | Native archive path exists | Manual archived-build desktop QA and synchronized version |
| Android | Signed build and closed-testing path exists | Maintain release checklist and live track evidence |
| Web | Published Flutter target | Repeatable build/deploy verification and browser smoke tests |
| Windows | Development/community target | Add a release checklist before claiming support |
| Linux | Development/community target | Add a release checklist before claiming support |

## Planning rule

New work belongs in a live issue with acceptance criteria and validation. Do not
reintroduce completed parity items as roadmap promises merely because an older
README or release draft still mentions them.
