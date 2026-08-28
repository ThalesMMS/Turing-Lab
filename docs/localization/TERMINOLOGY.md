# Localization terminology

`terminology.v1.json` is the machine-readable EN/PT-BR terminology source for
shared interface copy. Stable `id` values let validation and translation tools
refer to a concept without treating either displayed language as an identifier.
Its current `technical-reviewed` status records an independent engineering
review for issue #163. Editorial review remains pending; this status does not
claim review by a professional translator or subject editor.

Each entry records the preferred source and target terms, an English definition,
and a usage note. Mathematical notation and serialized document values are not
translated unless an entry explicitly says otherwise. Feature owners may extend
the glossary, but should reuse an existing term when the concept is the same.
`educational_content.v1.json` references this guide and the machine-readable
catalog. Educational-content maintainers should run the manifest checks in
`EDUCATIONAL_CONTENT.md` after changing either file.

Run the shared-literal audit with:

```shell
dart run tool/localization_literal_scan.dart \
  --json build/localization/shared-ui-report.json
```

The scanner reads an exact file list and an exact path-and-literal allowlist from
`tool/localization/`. A reported allowlist classification is not a permanent
exemption: each entry has a rationale and an occurrence limit.

The canonical format gate also scans every Dart file below `lib/presentation`
and `lib/features`:

```shell
dart run tool/localization_literal_scan.dart \
  --scope tool/localization/feature_ui_scope.v1.json \
  --inventory docs/localization/feature_ui_literal_inventory.v1.json \
  --json build/localization/feature-ui-report.json
```

The feature inventory records source and finding digests for files that still
contain probable user-facing literals. It does not approve those literals. Its
`migrationOwnerIssue` and `zeroUserVisibleProseClaim` fields keep that debt
explicit. A new Dart file, a new finding, a changed legacy producer, or a stale
inventory entry fails the scan. The JSON report keeps known legacy findings
separate from unapproved findings and inventory drift, with exact source lines.

After reviewing a deliberate change, regenerate the inventory with
`--write-inventory docs/localization/feature_ui_literal_inventory.v1.json` in
place of `--inventory`, then rerun the normal command. Do not update the
inventory merely to make the gate pass.
