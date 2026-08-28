# PDA hard-edge certification

The PDA campaign is an independently authored, deterministic certification
layer for issue #337. It executes production algorithms and compares simulator
results with a separate breadth-first explorer. It does not reuse the
production simulator's queue, configuration key, transition application, or
acceptance helpers.

## Reference anchors

The intended parity target remains JFLAP 7.1 as recorded in
`docs/reference-deviations.md`, especially `PDAStepByStateSimulator.java`,
`PDATransition.java`, `CFGToPDALLConverter.java`, and
`CFGToPDALRConverter.java`. The explorer is not a port of those sources; this
independence is deliberate so it can detect shared implementation mistakes.

## Executable matrix

| Property | Production paths exercised |
| --- | --- |
| `oracle-parity` | synchronous NPDA simulation and configuration search |
| `cooperative-parity` | cooperative/batched simulation against synchronous simulation |
| `normalization-conversion` | PDA normalization followed by PDA-to-CFG conversion |
| `simplification` | PDA simplification followed by language replay |
| `language-emptiness` | constructive language-emptiness analysis and witness validation |
| `cfg-conversions` | every public general converter entrypoint (`convert`, `canConvertToPDA`, `analyzeConversion`, and the `convertGrammarToPDA`/`canConvertGrammarToPDA`/`analyzeGrammarToPDAConversion` variants), standard, Greibach, LL, LR, and differential paths |
| `serialization` | PDA model JSON, versioned JSON codec, and JFLAP XML codec round trips |
| `resource-outcomes` | production and oracle configuration, depth, time, memory, cancellation, and stale-request separation |
| `mutation-checks` | four injected production-search defects: push omission, reversed push order, stack-free configuration identity, and acceptance before input consumption |
| `validation-determinism-analysis` | transition and model validation, determinism classification, `PDAAnalysis`, accepted-string generation, and rejected-string generation |
| `trace-reconstruction` | transition IDs, remaining input, reconstructed token stacks, and the final simulation outcome |
| `invalid-model` | invalid machine outcome kept distinct from rejection and bounded search; duplicate transition IDs and dangling endpoints rejected by the production codec; stale endpoint object copies execute by stable ID and serialize back to canonical state instances |
| `metamorphic-renaming-order` | state, transition, input, and stack-symbol renaming plus reversed set insertion order |
| `compound-conversions` | CFG to PDA to CFG and PDA to CFG to PDA, followed by bounded comparisons, plus direct PDA-to-CFG production-limit and cancellation outcomes |
| `bounded-language-evidence` | the simplifier's sampled comparison and differential-checker `boundedUnknown` result |
| `unicode-prefix-stack-symbols` | Unicode and multi-character atomic pushes with shared prefixes |
| `shortest-bfs-witness` | independent and production breadth-first searches return the one-transition witness even when a lexically earlier two-transition branch exists |

The matrix and its stable algorithm/property descriptors are exported by
`tool/hard_edge/families/pda_family.dart`. The shared-runner adapters are
`PdaHardEdgePropertyExecutor` and `PdaHardEdgeMutationExecutor` in
`tool/hard_edge/families/pda_executor.dart`. `pdaFixtureShrinker` and
`pdaMutationProbeDescriptors` are the corresponding registrable shrink and
mutation surfaces.

The mutation threshold is 4/4 killed production variants, with zero survivors.
Each probe keeps the PDA and input unchanged, runs the canonical production
search against the independent oracle, then injects one semantic defect through
the `@visibleForTesting` `simulateNPDAForCertification` entrypoint and
`PDASimulationSemanticVariant`. The normal synchronous and cooperative APIs
cannot select non-canonical semantics. Any survivor fails the family and must
be reviewed; the current corpus has no justified survivors.

Shrinking follows the selected property. It reduces the main PDA/input and also
reduces grammar payloads used by CFG conversions and nested PDA/input fixtures
used by mutation checks. Replay therefore receives the counterexample that
actually caused the property failure instead of an unrelated base PDA.

## Local commands

Run the complete matrix and materialize one replayable fixture per property:

```sh
dart run tool/hard_edge/families/pda_cases.dart run --seed 337 --output build/hard-edge/pda-337
```

Replay one exact property fixture:

```sh
dart run tool/hard_edge/families/pda_cases.dart replay --fixture build/hard-edge/pda-337/fixtures/unicode-prefix-stack-symbols.json
```

Run all mutation probes, or shrink a supplied mutation-killing fixture:

```sh
dart run tool/hard_edge/families/pda_cases.dart mutate
dart run tool/hard_edge/families/pda_cases.dart shrink --fixture fixture.json --operator ignore-push --output minimized.json
```

Every report records `remotelyVerified: false`. A native pass does not claim web
parity. Web parity should be reported only after the same test is executed by a
browser test runner; a JavaScript compilation check alone is insufficient.
The parity test is pure algorithm code and therefore uses the portable
`package:test` harness rather than `flutter_test`'s `dart:ui` harness:

```sh
dart test test/unit/tool/hard_edge_pda_web_parity_test.dart
dart test -p chrome test/unit/tool/hard_edge_pda_web_parity_test.dart
```

Both commands execute the same synchronous/cooperative fixtures. The Chrome
command runs the compiled test in a real local browser; it is not merely a web
compile check. Results remain local and never set `remotelyVerified` to true.

## Internal simulator ownership

The matrix assigns private simulator helpers to the public operation that calls
them. They are implementation steps, not separately callable algorithms.

| Internal file | Helper ownership |
| --- | --- |
| `pda_simulator_validation.dart` | `_validateInput` is covered by synchronous, cooperative, analysis, and invalid-model cases. |
| `pda_simulator_analysis.dart` | `_analyzePDA`, state, transition, stack-operation, reachability, input-length, and deadline helpers are covered through `PDASimulator.analyzePDA`. |
| `pda_simulator_generation.dart` | the predicate and recursive accepted/rejected generators are covered through `findAcceptedStrings` and `findRejectedStrings`. |
| `pda_simulator_search.dart` | transition application, configuration identity, trace construction, and acceptance helpers are covered through synchronous/cooperative simulation, oracle parity, trace reconstruction, and Unicode-prefix cases. |

The compound comparison returns `boundedUnknown` as its own outcome when either
side exhausts a budget. It never treats an incomplete comparison as a match.

## Central integration

The catalog builder adds one case for every entry in
`pdaHardEdgeCaseDescriptors`. The shared dispatcher routes family `pda` to
`PdaHardEdgePropertyExecutor`, registers the mutation executor and fixtures, and
registers `pdaHardEdgeShrinkAdapter(...)`. Its JSON wrapper decodes with
`PdaHardEdgeFixture.fromJson`, delegates candidates to `PdaFixtureShrinker`,
and re-encodes with `PdaHardEdgeFixture.toJson`; its built-in validity predicate
requires a valid PDA except for the intentionally invalid `invalid-model`
property. Pass a closure that reruns the selected property or mutation and
returns whether the failure remains as `isApplicable`. Route minimized
artifacts back through the family replay command. This prevents the central
shrink command from falling back to generic JSON shrinking and keeps
central coverage granular by algorithm, property, and seed instead of treating
the complete campaign as one opaque case.
