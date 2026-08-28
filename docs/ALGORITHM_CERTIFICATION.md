# Local algorithm certification

Issue #342 adds one fail-closed command for the final local certification:

```shell
dart run tool/hard_edge_cases.dart certify --full --profile qa \
  --output build/hard-edge/certification
```

The command is local and manual. It does not imply remote verification or a
GitHub status check. The generated report records `remotelyVerified: false`.

## Selection and repetition

The full command runs catalog properties, the repository-wide cross-family
matrix, and registered semantic mutation probes. The existing catalog runner
still supplies the family, property, seed, repeat, job, timeout, and case-cap
controls:

```shell
dart run tool/hard_edge_cases.dart certify --family pda
dart run tool/hard_edge_cases.dart certify --family grammar \
  --property parser-bounds --seed-start 342 --seed-count 8 --repeat 3
dart run tool/hard_edge_cases.dart certify --mutation-only --family codec
dart run tool/hard_edge_cases.dart certify --regression-only
```

`--mutation-only` and `--regression-only` are mutually exclusive. `--full` is
the explicit spelling of the default mode and cannot be combined with either
mode. A family or property filter marks the repository-wide cross-family phase
as `skipped`; it does not present a subset as full integration evidence.

Seed ranges materialize new fixtures through each registered family generator.
Repeats rematerialize and execute the same seed. Any change in typed outcome,
fixture fingerprint, status, or message records the case as flaky and fails the
certification. `--regression-only` selects only catalog entries whose source
kind is `historicalRegression`. An empty selection is `not_run`, never
`passed`.

## Status and prerequisite rules

The final report uses four status strings:

| Status | Meaning |
| --- | --- |
| `passed` | The phase ran and every declared contract matched. |
| `failed` | A property, expected outcome, mutation threshold, prerequisite, parity row, or repeat contract failed. |
| `skipped` | The user explicitly selected a mode or filter that excludes the phase. |
| `not_run` | No matching work ran, or evidence remained unavailable or inconclusive. |

The command exits `0` only for `passed`, `1` for a failed certification, `2`
for `not_run` or an explicit incomplete result, `64` for invalid configuration,
and `127` when a required local tool is missing. It probes every required tool
before property or mutation execution. Missing Flutter therefore prevents a
Flutter-backed selection from passing, in line with `AGENTS.md`.

The environment block records the Git revision and dirty-worktree state, Dart
and Flutter versions, OS name/version, probe commands, and prerequisite
statuses. A Git revision is mandatory. The command records its exact invocation
and wall-clock durations for the whole run, each phase, and every property case.
An unfiltered full run requires Dart, Git, and Flutter before it starts owner
evidence. Filtered and mode-specific runs require only the tools used by their
selected catalog cases or mutations.

## Mutation policy

`test/fixtures/hard_edge/certification_policy.v1.json` defines reviewed
thresholds per family. Every registered probe currently targets a semantic
boundary with a deterministic oracle, so each family requires a `1.0` kill
ratio and zero survivors. The report keeps killed, survived, and `not_run`
counts separate, lists every survivor ID, and fails when a family lacks a
policy row.

The same policy owns the quarantine inventory. A quarantine must name a check,
issue, owner, reason, and review condition. Quarantined checks appear as
`skipped`, and any active quarantine prevents the overall result from passing.
The committed policy currently has no quarantines.

## Cross-family and JFLAP evidence

The cross-family phase reads
`test/fixtures/hard_edge/cross_family/matrix.v1.json` and compares every actual
typed outcome with the declared outcome. A row that expects `boundedUnknown`
can satisfy its bounded contract, but the row remains `certified: false`. The
JSON, Markdown, and HTML reports count these rows separately and never describe
them as universal proof. Repeats also compare the complete cross-family report
for instability.

The JFLAP phase reads every fragment under `docs/jflap-parity/`, rejects
duplicate IDs or unknown statuses, and reports exact status counts. Any
`partial`, `planned`, or `missing` row is a residual gap and fails the final
certification. Its owning issue numbers remain visible in the report; an empty
owner list is additionally marked `unowned`.

The repository inventory phase reads
`test/fixtures/hard_edge/repository_algorithm_inventory.v1.json`, reruns source
discovery, and requires the committed entries and exclusions to match exactly.
Static reachability is not execution evidence. An unfiltered full certification
therefore runs every unique inventory `evidenceCommand` serially. Each command
has a timeout, status, exit code, duration, and log artifact. Family/property,
mutation-only, and regression-only selections mark this phase `skipped` because
they are not full-repository evidence. The report also reads
`test/fixtures/hard_edge/repository/regression_index.json` and lists reviewed
mutation exclusions, including the cross-family batch layer's direct
batch-versus-single evidence and its explicit lack of a standalone mutation
operator.

## Reports and indexes

The output directory contains:

- `certification-report.json`, the canonical machine-readable result;
- `certification-report.md` and `certification-report.html`, human-readable
  views of the same statuses;
- `hard-edge-report.json` and `.md` when property cases ran;
- `mutation-report.json` and `.md` when mutation probes ran;
- replayable failure artifacts produced by the property runner.

The final report includes the selected seed catalog and a catalog-wide index of
committed `historicalRegression` fixtures with issue, seed, fixture path, and
reproduction command. If the catalog has no historical fixture, the index says
so instead of inferring coverage from ordinary generated cases.
