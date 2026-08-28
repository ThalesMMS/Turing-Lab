# Regular-language hard-edge certification

Issue #335 covers finite-state automata, DFA/NFA transformations, regular
languages, and the supported regular-expression dialect. The executable
inventory is `tool/hard_edge/families/regular_matrix.dart`: 22 core paths and
three provider paths. Every inventory entry names its live entry points,
property IDs, source file, and exact evidence command.

## Local command

Run the whole family without selecting unrelated hard-edge cases:

```text
dart run tool/hard_edge_regular.dart
```

The command accepts stable `--seed`, `--cases`, `--max-word-length`,
`--max-words`, and `--max-configurations` bounds. `--property` reproduces one
registrable property. Reports are written below `build/hard-edge/regular` by
default. Output paths are confined to the repository, including through
existing symbolic links or junctions. Exit status is 0 for passed, 1 for
failed, 2 for incomplete bounded evidence, and 64 for usage errors.

Provider evidence needs Flutter and remains explicit:

```text
flutter test test/unit/presentation/automaton_providers_integration_test.dart
flutter test test/unit/presentation/automaton_simulation_stale_test.dart
flutter test test/unit/providers/regex_editor_provider_test.dart
```

The central runner's five-second default is intentionally too short for a cold
Flutter compiler and also counts time spent waiting for the serialized provider
queue. Use the explicit 60-second catalog budget when exercising the fragment
with parallel jobs:

```text
dart run tool/hard_edge_cases.dart run --manifest test/fixtures/hard_edge/regular/catalog.fragment.json --jobs 4 --timeout-seconds 60
```

## Evidence matrix

The family runner executes 20 properties. The core matrix maps all 22 paths to
these checks:

| Area | Executable properties |
| --- | --- |
| Model and simulation | `regular.model-integrity`, `regular.generated-oracle`, `regular.trace-replay`, `regular.resource-outcomes` |
| DFA/NFA transformations | `regular.determinization`, `regular.lambda-removal`, `regular.completion`, `regular.minimization` |
| Language operations | `regular.boolean-algebra`, `regular.prefix-suffix`, `regular.structural-closures`, `regular.equivalence-witness` |
| Regular expressions | `regular.regex-oracle`, `regular.regex-simplification`, `regular.regex-analysis`, `regular.fa-regex-roundtrip` |
| Regular grammars | `regular.grammar-roundtrip` |
| Generated assurance | `regular.generated-shrink`, `regular.mutations` |

`regular.inventory` verifies that all 25 source paths still exist and retain an
evidence mapping. The JSON report embeds the full entry-point matrix, so a
passing summary cannot silently omit an inventoried implementation.

## Oracle and limits

The primary oracle is an independently implemented epsilon-NFA explorer over
token vectors. It does not call the production simulator. A separate recursive
AST evaluator covers the public regex nodes, including union, concatenation,
star, plus, optional, wildcard, shortcut, character set, epsilon, and empty
language. A separate clarity-first subset construction and Moore partition
refinement provide references for determinization and minimum quotient size.
State renaming and insertion-order reversal are explicit metamorphisms.
Further differential and metamorphic checks cover lambda removal, total
completion, minimization idempotence, Boolean truth
tables, prefix/suffix closure, concatenation, reversal, Kleene star,
equivalence witnesses, simplification, FA/regex round trips, and regular
grammar round trips.

Bounded enumeration is evidence, not an equivalence proof. Reaching a word or
configuration limit produces `bounded`, never rejection or success. Timeout,
cancellation, and stale-generation outcomes also remain distinct. Exact
product traversal is used for the equivalence-witness property.

Generation uses the shared xorshift32 `GenerationContext` and
`AutomatonGenerator`. Catalog fixtures supply the replay seed, case count,
expected check status, regex acceptance examples, finite-language automaton,
and resource-outcome expectations; changing those values changes the verdict.
Materialization preserves that payload while replacing the generated seed.
`shrink_probe.json` contains the real incomplete-DFA witness for the
skip-completion semantic variant. The central shrink command registers
`regularFailureFixtureShrinker` (`DomainShrinker<Object?>`) together with
`regularFailureFixtureIsValid` and `regularFailureFixtureIsApplicable`; the
adapter delegates automaton reductions to the shared `AutomatonShrinker` with a
128-attempt cap. Replay-before-shrink and replay-after-shrink both execute the
regular property adapter. Three semantic variants of production behavior are
registered:

- `flip-initial-acceptance`
- `ignore-epsilon-reachability`
- `skip-dfa-completion`

The required mutation score is explicitly 1.0, so all three must be killed;
the mutation executor applies only the requested operator and reports a
survivor independently. The catalog fragment has one descriptor for each of
the 25 inventory entries, one explicit simulator-resource descriptor, plus the
mutation entries. It lives in
`test/fixtures/hard_edge/regular/catalog.fragment.json`; its fixtures are
independently authored and covered by the repository Apache-2.0 license. The
three provider descriptors require Flutter. Their executor serializes the
separately listed focused Flutter tests, starts each with `Process.start`, and
kills its process tree after 55 seconds. Windows uses `taskkill /T /F`. On POSIX,
the executor suspends the Flutter parent, snapshots descendants with `ps`,
suspends each discovered wave, kills descendants deepest-first, and finally
kills the parent. If `ps` is unavailable, it still kills the parent and reports
the timed-out provider as a violation, but descendant cleanup cannot be
guaranteed. The executor returns a definitive pass or violation, so `--jobs 4`
does not launch competing Flutter compilers or convert provider coverage into
an incomplete result. The `fsa-simulator` catalog descriptor maps explicitly to
`regular.trace-replay`, whose check invokes every listed simulator entry point.

## Reference anchors

The implementation follows the anchors recorded in
`docs/reference-deviations.md`: epsilon closure over all accepted aliases,
standard subset construction, collision-safe total completion, standard
concatenation/star/reversal constructions, exact DFA product traversal, and the
documented regex codec and dialect. No JFLAP-derived fixture is introduced by
this family.

## Regression coverage

The certification added regressions for:

- mixed epsilon/consuming strongly connected components being misclassified as
  finite languages;
- UTF-16 code-unit expansion rejecting valid supplementary-plane character
  ranges;
- escaped character-class dashes such as `[a\-z]` being expanded as ranges
  instead of the literal set `a`, `-`, `z`;
- time-derived regex-conversion identities preventing deterministic replay;
- repeated regex branches publishing colliding fragment IDs and changing the
  recognized language;
- a zero DFA timeout occasionally completing because its boundary comparison
  was not inclusive;
- a completed simulation publishing into a replacement automaton document.

Central integration still consists only of registering
`RegularHardEdgeExecutor`, `RegularHardEdgeMutationExecutor`, and the three
regular shrink exports named above; merging the catalog fragment; and linking
this document from the shared testing guide.
