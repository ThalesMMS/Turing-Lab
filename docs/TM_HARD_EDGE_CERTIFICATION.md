# Turing-machine hard-edge certification

Issue #338 certifies the live single-tape, multi-tape, and building-block
Turing-machine algorithms. The inventory is
`tool/hard_edge/families/tm_matrix.dart`. It records 19 implementation paths,
their public entry points, and the executable properties that cover them.

## Local command

Run only this family:

```text
dart run tool/hard_edge_tm.dart
```

`--seed`, `--cases`, `--max-steps`, and `--max-configurations` define the
generated scope. `--property` runs one property. Reports are written below
`build/hard-edge/tm/` and state `remotelyVerified: false`. Exit status is 0 for
passed, 1 for failed, 2 for incomplete evidence, and 64 for invalid options.

The shared catalog fragment can run with parallel jobs without launching a
Flutter compiler:

```text
dart run tool/hard_edge_cases.dart run --manifest test/fixtures/hard_edge/tm/catalog.fragment.json --jobs 4 --timeout-seconds 60
dart run tool/hard_edge_cases.dart mutate --manifest test/fixtures/hard_edge/tm/catalog.fragment.json --timeout-seconds 60
dart test -p chrome test/unit/tool/hard_edge_tm_web_parity_test.dart -r expanded --timeout 2m
```

The last command compiles and executes the cooperative runner and bounded
analyzer in Chrome. It compares acceptance plus typed step, configuration,
timeout, and cancellation results with a checked-in snapshot that the native
property recomputes. A VM execution of the web backend is not counted as
browser-platform evidence.

## Properties

| Property | Evidence |
| --- | --- |
| `tm.inventory` | Unique IDs, existing sources, and a qualified execution-evidence marker for every public entry point on all 19 paths |
| `tm.model-serialization` | Vector JSON replay, derived variant, canonical blank padding, negative heads, and vector-length validation |
| `tm.oracle-parity` | Generated two-tape DTM writes, head moves, and final configurations plus varied accepting/rejecting/cyclic NTMs compared with the independent sparse-tape interpreter |
| `tm.runner-parity` | Synchronous DTM/NTM, cooperative simulation, native isolate runner, web runner, adapters, structural analysis, and typed step/configuration/timeout/cancel snapshots |
| `tm.outcome-lattice` | Accepted, halted rejection, deterministic cycle proof, step/configuration/timeout bounds, cancellation, and invalid input |
| `tm.multi-tape-atomicity` | Complete-vector matching, simultaneous writes/moves, immutable source tapes, negative coordinates, and k=1 compatibility |
| `tm.reachability-language` | Structural versus semantic reachability, shortest BFS witnesses, shortlex enumeration, and four language outcomes |
| `tm.metrics-trace` | Direct transition counts, read/write/movement counters, visited span, maximum nonblank cells, and bounded time/space profiles |
| `tm.building-blocks` | Shared tape/head calls, returns, dependency diagnostics, recursion rejection, limits, cancellation, deterministic inlining, and source maps |
| `tm.grammar-conversion` | Movement, boundary, acceptance, and cleanup production families, complete provenance, unsupported multi-tape diagnostics, and bounded differential evidence |
| `tm.trace-replay` | Every retained multi-tape operation replayed through the production kernel to the recorded configuration and outcome |
| `tm.generated-shrink` | Machine/input reduction that preserves the exact divergence signature until a validated one-deletion fixed point |
| `tm.mutations` | Four executable altered semantics rejected by the same oracle/property that first validates production, with a required score of 1.0 |

## Independent oracle and limits

`IndependentTmOracle` does not call `TMExecutionKernel`,
`TMExecutionAnalyzer`, `TMSimulator`, or a runner backend. It owns its sparse
integer-coordinate tapes, vector matching, simultaneous operations,
configuration keys, and BFS queue. It accepts an NTM if any branch accepts and
rejects only after the finite reachable queue is exhausted. A repeated
configuration proves a cycle only for a deterministic machine. For an NTM it
is evidence used to close one explored branch.

Step and configuration caps return `boundedUnknown`. Timeout and cancellation
remain separate typed causes in production results. The oracle and the bounded
TM-to-grammar checker provide finite counterexample evidence. Neither claims a
general halting, nontermination, or language-equivalence proof.

The generated stream uses the shared versioned xorshift32 generator with seed
338. Each generated DTM performs two atomic operations over two tapes; the
comparison includes the final sparse cells, both head coordinates, final state,
step count, and outcome. Separate NTM witnesses cover acceptance after an
earlier rejecting branch, acceptance alongside a cycle, and finite cyclic
rejection. Reports include the exact seed, case count, bounds,
algorithm/property matrix, and local-only verification marker.

## Metrics

Time is the number of executed transitions. Space reports the logical span
between the minimum and maximum visited head coordinates and the maximum
simultaneous nonblank-cell count. Multi-tape metrics retain one value per tape
and the maximum simultaneous total. Building-block entry and return steps use
the common execution bound, while transition metrics count only transition
steps. A sampled or bounded profile stays incomplete.

## Shrink and mutation

The shrink adapter tests every one-token and one-transition deletion. It also
removes noninitial states with their incident transitions and tries each input
and tape-alphabet symbol except the blank. A reduction is accepted only when
the complete TM remains valid and the exact read-vector plus production and
mutant transition-ID signature still reproduces. Certification continues to a
one-deletion fixed point and checks that no remaining candidate preserves the
signature. The tracked seed therefore reduces a redundant input token, a decoy
transition, and the symbols made unused by that transition while retaining the
one token and transition needed by the divergence.

The mutation threshold is 1.0. Every registered operator must be killed:

- `clamp-left-head-at-zero`
- `partial-multi-tape-read-match`
- `reject-on-first-halted-ntm-branch`
- `skip-building-block-return`

A survivor fails the mutation command. Each probe first checks production
against its independent oracle or semantic property, then executes the named
altered implementation through a dedicated seam and applies the same expected
result. A production failure is reported separately from a surviving mutant.

## Reference anchors and provenance

The parity anchors are recorded in `docs/reference-deviations.md`. The local
JFLAP 7.1 source paths inspected for this certification are:

- `../JFLAP/automata/turing/TMTransition.java:67-238`
- `../JFLAP/automata/turing/TMSimulator.java:102-344`
- `../JFLAP/automata/turing/TuringMachineBuildingBlocks.java:196-331`
- `../JFLAP/automata/turing/TuringToGrammarConverter.java`

JFLAP requires equal nonempty tape-operation vectors and matches every tape
before a transition fires. Turing Lab preserves those rules but uses immutable
ordered vectors and applies all writes and moves atomically. Tape 0 alone
receives input locally; JFLAP's string-array initializer can initialize each
tape separately. This family tests the documented local contract.

JFLAP recursively embeds building-block machines and returns to a parent when
the child halts. Turing Lab uses stable references, an explicit call stack, and
rejects direct or indirect recursion before execution. Inline expansion is a
separate local operation.

JFLAP's historical grammar converter flattens cell encodings and does not
implement stay moves. Turing Lab keeps token boundaries and emits a dedicated
stay family with provenance. Multi-tape machines and unresolved blocks return
typed unsupported diagnostics instead of an approximation.

All fixtures below `test/fixtures/hard_edge/tm/` were independently authored
for issue #338 and are covered by the repository Apache-2.0 license. The
catalog records SHA-256 for each exact fixture. No JFLAP source or example bytes
were copied into the corpus.
