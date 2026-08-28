# Formal-systems hard-edge certification

Issue #339 certifies the pure-Dart behavior shared by deterministic finite-state
transducers, Lindenmayer systems and turtle rendering, and the two Pumping Lemma
environments. The family ID is `formal-systems`.

## Local commands

```sh
dart run tool/hard_edge_formal_systems.dart run --seed 339 --count 4
dart run tool/hard_edge_formal_systems.dart repeat --seed 339 --count 4
dart run tool/hard_edge_formal_systems.dart summary --seed 339 --count 1
dart run tool/hard_edge_formal_systems.dart mutate --seed 339
flutter test test/unit/tool/formal_systems_hard_edge_test.dart
```

`run` writes JSON and Markdown under
`build/qa/formal-systems-hard-edge/`. Every result sets
`remotelyVerified` to `false`.

## Executable inventory

| Area | Live algorithms | Evidence |
| --- | --- | --- |
| Transducer structure | model serialization, analyzer, transition index, graph mapping, maximal-munch tokenizer | complete deterministic machines, duplicate input diagnostics, Unicode and multi-character boundaries, insertion-order-independent JSON |
| Transducer execution | Mealy and Moore simulators, synchronous and cooperative execution, trace retention, batch runner | independent output runner, initial Moore output, cumulative trace replay, bounded suffix storage, ordered batch output, and complete sync/async parity for success, invalid machine/input, incomplete, bounded, and cancelled outcomes |
| Transducer comparison | exact and bounded comparators | renamed-state equivalence, shortest distinguishing input, finite comparison remains inconclusive |
| L-system expansion | synchronous and cooperative expanders, growth estimator, context and stochastic selection, generation retention | independent parallel expander, identity and epsilon replacements, provenance replay, every typed bound, cancellation, same-seed reproduction |
| Turtle and export | turtle interpreter, bounds, fit transform, SVG exporter | independent command replay, branch restoration, negative bounds, invalid stacks, cancellation, segment limits, deterministic SVG geometry |
| Pumping decompositions | Regular and Context-Free decomposition validation, pumping, and enumeration | independent token-range reconstruction, complete small decomposition counts, distinct theorem types, simultaneous CFL pumping |
| Pumping environment | evidence, session controller, progress migration, document model, curated membership catalog | explicit quantifier transition model, retry/restart isolation, stale session rejection, theorem-owned migration, typed round trips, finite evidence never becomes proof |

The 29 exported descriptors are the integration inventory. The family test
requires the descriptor IDs and executed record IDs to match exactly.

## Independent checks

The transducer oracle indexes transitions without calling the product
simulator. It emits Moore's initial state output and then follows explicit token
boundaries. Short words are also compared exhaustively by the production exact
and bounded comparators.

The L-system oracle builds each generation from one immutable source word.
Symbols without a rule survive and an empty successor deletes its predecessor.
The turtle oracle independently replays the draw, move, turn, push, and pop
subset used by the reviewed geometry case. It then compares every segment and
the complete signed bounds.

The Pumping Lemma oracle reconstructs output from typed segment ranges. A
separate combinatorial loop counts every small CFL decomposition. Large
exponents use `pumpBounded`; the implementation checks a saturated output-size
estimate before any repeated-token allocation.

When an older stored session contains an exponent that exceeds the current
token limit, decoding resets that attempt to the exponent-choice stage. The
codec reports normalized fidelity and a diagnostic instead of restoring an
unusable evidence step.

## Replay, shrinking, and mutation

The reviewed replay corpus lives in
`test/fixtures/hard_edge/formal_systems/`. It is independently authored under
the repository Apache-2.0 license:

- `transducer_unicode_tokens.json` preserves a complete Mealy machine and token
  input;
- `l_system_parallel_epsilon.json` preserves a parallel expansion document and
  generation count;
- `pumping_token_decomposition.json` preserves a Regular decomposition,
  exponent, pumping length, and output limit.

`FormalSystemsFailureFixtureShrinker` dispatches by payload kind. It reduces
transducer input, transitions, and noninitial states; L-system generation count,
axiom, and productions; or pumping exponent and segment tokens. Domain
validation rejects malformed or theorem-invalid candidates before replay. The
shrinker also requires every candidate to preserve the source artifact's oracle
agreement or divergence. The central runner separately requires the selected
property to keep failing before accepting a reduction. The three reviewed
replay fixtures are passing witnesses, not recorded production failures. Fixed
matrix fixtures have no reducible payload.

Replay applicability comes only from schema checks and bounded independent
oracle preconditions. A production outcome that is invalid, bounded, or
otherwise different remains an applicable counterexample and can still be
shrunk. Pumping replay compares completed and bounded outcomes as distinct
typed results.

The property-level semantic mutation threshold is 3/3 with no survivors. Each
probe runs production through a private certification adapter, first canonically
and then with one semantic defect. The same property and independent oracle
must accept the canonical execution and reject the mutant:

- omit Moore's initial output;
- rewrite an L-system sequentially instead of in parallel;
- pump only one of the two CFL segments.

## Reference boundary

The parity anchors and intentional deviations remain in
`docs/reference-deviations.md`, especially the deterministic transducer,
Pumping Lemma, and Lindenmayer sections. The local fixtures do not copy JFLAP
examples or source bytes. Parametric L-system execution remains unsupported and
must return a typed diagnostic. PNG rasterization is a platform adapter over the
certified immutable geometry; this pure-Dart family certifies the geometry and
vector preparation, not a platform image codec.
