# Feature UI inventory reconciliation (#453)

The 2026-09-07 audit starts from `35906261`, where the feature-UI gate reported
740 unapproved violations and 53 stale entries. The committed inventory did
not distinguish new prose from previously inventoried text after source edits.

Every stale entry was matched to its exact historical source digest. The
[per-file audit](feature_ui_reconciliation_453.json) records the revision, old
path and resolution, so each source can be inspected with `git show REV:PATH`.
Forty-four files retain identical literal multisets. The other nine contain
reviewed bilingual example additions, formal rendering, extracted formatters,
retired status messages, or equivalent formatter expressions.

The exact-literal allowances added by this audit cover:

- Paired English/Portuguese counterexample and parametric-tree educational copy,
  already selected by the existing runtime locale resolvers.
- SVG/XML syntax, CSS, geometry and element identities. These templates are
  serialized data, not translated UI copy; their allowances include occurrence
  limits and do not cover arbitrary future literals in those files.
- Report composition that already uses localized classification/diagnostic
  resolvers, formal language and production data, integer input notation, the
  canonical product name, and the internal DFA-completion action identity.

The grammar SVG title now preserves the document name directly, removing the
untranslated English suffix. A regression test covers English and Portuguese
names and XML escaping. Five formatter templates moved out of
`grammar_algorithm_panel.dart` retain their source-proven legacy ownership;
they were not newly approved as translated messages.

After removing the #448 provisional barrels, the scope contains 322 files.
The gate reports zero unapproved violations and zero inventory drift, with
1,967 inherited legacy violations in 114 files. These remaining entries are
owned by #453 through `migrationOwnerIssue`; this is an accurate inventory,
not a claim that all feature prose has been migrated. The scanner and its
fail-closed branch/occurrence checks remain enabled. The subsequent #452 fixes localize three more inherited messages, reducing the
final legacy count to 1,964 without changing the 114-file ownership scope.
The final gate still reports zero unapproved violations and zero inventory drift.

## Local verification

- `bash tool/qa.sh --only format --base HEAD --report-dir build/qa/issue-453 --quiet`:
  prerequisites and every format/policy step passed, including feature literals,
  educational content, ARB branches, validator tests and language checks.
- Focused example/content, print-builder and literal-scanner suites: 37 passed.
- `flutter test test/unit/presentation/grammar_svg_title_test.dart --reporter expanded`:
  one bilingual export-title regression passed.

The canonical run did not select analysis, unit, widget, integration, properties,
GraphView, responsive, golden, screenshots or Apple categories. The focused tests
above are separate evidence, not passes for those whole categories. All results
were obtained locally with Flutter 3.47.2 / Dart 3.13.2 and were not remotely
verified.
