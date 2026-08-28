# Deterministic algorithm testing

Turing Lab's hard-edge-case framework is a pure-Dart test tool for the
algorithm certification issues tracked by the master roadmap. It complements
focused unit tests and the JFLAP compatibility corpus; it does not replace
either one.

The framework keeps four facts explicit for every generated case:

- the versioned pseudorandom generator, root seed, generation mode, and size
  budget;
- the materialized token-aware case, with stable IDs and canonical JSON;
- oracle applicability and limits, including partial evidence;
- the exact local reproduction command.

Consequently, filtering a family, changing worker count, or reordering a
catalog cannot change the case associated with a seed. A generator version
change also cannot silently claim that an old seed reproduces the same bytes.

## Commands

Run `dart run tool/hard_edge_cases.dart --help` for the complete option list.
The common workflows are:

```bash
# One property and seed
dart run tool/hard_edge_cases.dart run \
  --family framework --property framework.reproducibility --seed 334

# A deterministic range, repeated to check flakiness
dart run tool/hard_edge_cases.dart repeat \
  --family framework --property framework.reproducibility \
  --seed-start 334 --seed-count 1 --repeat 3 --jobs 1

# Replay or minimize a materialized failure
dart run tool/hard_edge_cases.dart replay --fixture build/hard-edge/failures/case.json
dart run tool/hard_edge_cases.dart shrink --failure build/hard-edge/failures/case.json

# Promote an already minimized case into the regression catalog
dart run tool/hard_edge_cases.dart promote \
  --failure build/hard-edge/minimized/case.json --issue 334

# Catalog coverage and registered mutation probes
dart run tool/hard_edge_cases.dart summary
dart run tool/hard_edge_cases.dart mutate --family framework

# Rebuild strict family fixtures and the central manifest after descriptors change
dart run tool/hard_edge/build_family_catalog.dart

# Run the integrated family campaigns
dart run tool/hard_edge_cases.dart run \
  --family regular --jobs 4 --timeout-seconds 60
dart run tool/hard_edge_cases.dart run --family grammar
dart run tool/hard_edge_cases.dart run --family pda

# Bounded local campaign through the canonical QA reporter
tool/qa.sh --only properties
```

`run` and `repeat` write human-readable and machine-readable reports under
`build/hard-edge/` by default. Generated failure and minimized-case files are
build artifacts and are not committed automatically. `promote` is deliberately
explicit because it changes the versioned fixture catalog. Failure reports use
the materialized artifact for exact replay and retain the seed command
separately for generator debugging. Replay, shrink, and promotion reject an
artifact when its embedded fixture no longer matches its SHA-256 digest.
If generation fails before producing a fixture, the report emits only the seed
regeneration command and does not claim that a `null` fixture is replayable.

All commands are local. Reports set `remotelyVerified` to `false`. Exit code
`0` means every selected applicable case passed and no applicable mutation
survived; `1` means a property violation, invalid fixture, external timeout, or
surviving mutation; `2` means the selected work was only bounded,
inapplicable, or not run; `64` means invalid command configuration; and `127`
means a required local tool is missing. An unavailable optional reference tool
is never reported as a pass.

Family-specific inventories, typed outcomes, and focused reproduction commands
are documented in `REGULAR_HARD_EDGE_CERTIFICATION.md`,
`GRAMMAR_HARD_EDGE_CERTIFICATION.md`, and
`PDA_HARD_EDGE_CERTIFICATION.md`. The catalog builder rewrites committed
fixtures and their digests; run it only after descriptor changes and review the
resulting manifest diff.

## Adding a family property

Every property added by issues #335 through #341 must use the shared contracts
rather than a private `Random` loop:

1. Select or compose a token-aware generator and declare a versioned budget.
2. Register the family, algorithm, property, supported platforms, and oracle
   version in the hard-edge catalog.
3. Return a typed oracle result. `notApplicable` and `boundedUnknown` are not
   definitive answers.
4. Compare canonical semantics through an explicit adapter; never depend on
   state IDs, insertion order, `Set` iteration, or display labels.
5. Supply a domain shrinker and keep both the artifact replay and seed
   regeneration commands emitted by the runner in the failure report. Register
   the family's typed shrinker plus validity and applicability predicates with
   the central CLI; the generic JSON fallback is reserved for the shared
   framework's synthetic fixtures.
6. For traces, replay every step and compare the replayed final state with the
   reported result.
7. Exercise the exact acceptance, rejection, invalid, conflict, timeout,
   cancellation, bounded-unknown, and stale-request categories applicable to
   the algorithm.

Logical limits such as steps, configurations, frontier size, retained bytes,
or cancellation checks belong to the generated case and are deterministic.
Wall-clock timeouts protect materialization and execution in the runner itself
and are reported separately from an algorithm's typed timeout result.

## Fixture provenance

The hard-edge catalog separates independently authored, generated,
JFLAP-derived, and historical regression fixtures. Every committed fixture
records its SHA-256 digest, source, license, generator and oracle versions,
property, seed when applicable, regression issue, and supported platforms.
The license identifier must map to a committed license text. Apache-2.0
fixtures point to `LICENSE.txt`; JFLAP-derived bytes use
`LicenseRef-JFLAP-7.1` and point to `LICENSE_JFLAP.txt`.

JFLAP is an offline reference only. Its source is available at `../JFLAP`, but
tests must not invoke a network service or assume that JFLAP's hash iteration,
unseeded layouts, Java-character tokenization, or mutable simulator ordering is
deterministic. Prefer independently authored fixtures and small clarity-first
oracles. If bytes are derived from JFLAP, record the exact source revision, a
SHA-256 digest of the source bytes, and the licensing basis before committing
them.

## Mutation testing

Mutation descriptors are deterministic and scoped to a pure-Dart algorithm or
framework contract. A mutation is `killed` only when its registered property
detects the injected defect. A surviving applicable mutation fails the command;
an unavailable prerequisite is `notRun` and makes the campaign incomplete.
The framework's own tests include known defects so reproducibility, shrinking,
oracle limits, stale-result detection, fixture promotion, and mutation-survivor
reporting are tested rather than assumed.
