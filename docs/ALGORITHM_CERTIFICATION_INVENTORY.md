# Repository algorithm inventory

Issue #342 uses a generated inventory instead of a second hand-maintained list
of class names. `tool/hard_edge/repository_algorithm_inventory.dart` scans the
production directories that contain algorithms, parsers, simulators,
converters, codecs, mappings, layouts, render preparation, proof-game rules,
and shared batch execution. Path rules assign one primary owner from issues
#335 through #342.

Each inventory row records the source file, public production entry points,
owner issue and family, property or oracle evidence, regression fixture root,
resource and cancellation review, mutation scope or exclusion rationale, and
the exact local evidence command. The validator follows Dart imports from the
evidence tests to the production file and requires the reachable executable
graph to reference a declared public entry point outside its own declaration
file. A similar test name or a barrel import alone is not enough. If the command
cannot reach and reference the source, validation fails.

Files with no public production declaration remain in the machine-readable
exclusion list with a reason. New matching production files change the generated
fixture and fail the drift test until their source ownership and evidence are
reviewed.

The JFLAP parity validator applies the same ownership rule to residual gaps.
Statuses that still describe missing, partial, or planned work require at least
one open issue when `--github` is selected. Intentional format differences need
a recorded product decision. In particular, Pumping Lemma JFLAP persistence is
an intentional lossy-format deviation. Issue #343 owns only localization of the
disclosure text; closed issue #339 remains the historical implementation owner.

## Commands

```text
dart run tool/build_repository_algorithm_inventory.dart --check
flutter test test/unit/tool/repository_algorithm_inventory_test.dart
python tool/check_jflap_parity_matrix.py --github
```

Regenerate reviewed inventory changes with:

```text
dart run tool/build_repository_algorithm_inventory.dart --write
python tool/check_jflap_parity_matrix.py --write
```

These commands run locally. They never report remote verification. The family
commands stored in the inventory remain the executable semantic evidence; the
inventory check validates ownership, source reachability, and metadata drift.
