# Educational content certification

`educational_content.v1.json` is a source-backed inventory of the enumerated
shipped catalogs and instructional-content boundaries. `pendingSourceGaps`
records any known shipped source family outside the entry matrix. The current
inventory has no such gap, but pending human review still blocks `--certify`.
Educational copy follows the bilingual terms and usage rules in
`terminology.v1.json` and `TERMINOLOGY.md`; both paths are part of the manifest
so maintainers cannot remove the glossary contract unnoticed.

Run the structural and certification checks with:

```console
python tool/check_educational_content.py
python tool/check_educational_content.py --certify
python test/tool/check_educational_content_test.py
python test/tool/educational_content_manifest_contract_test.py
```

Structural validation discovers IDs from the configured help, example, Pumping
Lemma, and versioned instruction catalogs and requires an exact manifest match.
The executable evidence contract repeats that comparison in a test, including
canonical formal payload hashes. Instruction hashes cover only the
locale-neutral ID, content version, and formal argument keys. Asset-backed
hashes exclude localized display metadata. The ten code-backed examples use
`canonicalRuntimeJsonV1`: a focused Flutter test executes their three catalogs
and hashes each recursively key-sorted `toJson` payload. Pumping hashes cover
the language, theorem and representation constraints, pumping length,
accepted/rejected expected answers, expected outcome, and source revision.
Each Pumping exercise also declares a positive content version. Persisted
progress records that version and discards scores for changed or removed
exercise content while migrating older version-one records.

The manual-conversion instruction catalog resolves its 22 versioned references
through a presentation-owned EN/PT-BR copy source. Runtime values are supplied
as formal arguments by the requirement model rather than embedded in localized
copy. Each entry also provides a concise screen-reader description. These
sources prove availability, not human approval. The manifest records these
alternatives as `presentUnreviewed`; locale, accessibility, technical,
editorial, and provenance review states remain pending until their respective
evidence is recorded.

The nine grammar-teaching references follow the same boundary across
normalization stages, editable parse tables, bounded search, LR(1) exploration,
and user-controlled derivations. Their presentation copy resolves from typed
workspace state on every build, so changing locale does not replace the active
teaching session or draft. Availability and accessible descriptions are covered
by executable tests, while all human review dimensions remain pending.

Profiles can only describe shipped content. Removed content belongs in
`nonShippingEntries`, with rationale, removal version, owner, and an existing
removal-evidence file; a source-discovered ID cannot be moved there. An approved
review dimension must have a matching `reviewEvidence` record containing a
reviewer ID and role, the reviewed content version, an ISO review date, and an
existing evidence path. Pending or missing review remains visible as a
certification blocker.
