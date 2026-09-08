# Golden review #455

## Reproduction environment

The reviewed native environment is macOS 26.6.2 (25G83), arm64, Flutter 3.47.2,
Dart 3.13.2. `test/flutter_test_config.dart` loads the font manifest with
`golden_toolkit` 0.15.0: MaterialIcons and the package's Roboto Regular font.
The tests use English localization, their explicit light/dark themes, pixel
ratio 1 and the viewports declared in each golden suite. Settings now pins
English explicitly. Each reviewed PNG's dimensions and hashes are recorded in
`review_455_manifest.json`.

The baseline update source revision is `a4e52623`. It includes the fixture
repairs described below; no production layout was changed to match the PNGs.
The PNG comparison environment above is supported by this review. Other SDK,
platform and font combinations have not been certified by these images. This
is not a reason to ignore a new mismatch: compare it with this environment and
inspect the actual image first.

## Diagnosis

| Source and environment | Outcome before re-recording |
| --- | --- |
| `35906261`, Flutter 3.47.2 / Dart 3.13.2 | 24 passed, 135 failed |
| `35906261`, Flutter 3.44.8 / Dart 3.12.2 | 48 passed, 111 failed |
| `2d77630d`, Flutter 3.47.2 / Dart 3.13.2 | 24 passed, the same 135 filenames failed |

The old-SDK comparison used a detached app checkout and a detached Flutter
3.44.8 SDK. Its test configuration included the browser-only font guard from
#456; the native font-loading path was unchanged. Thus the old toolchain did
not restore the old green baseline: 111 failures also reproduce there.
Exactly 24 additional differences occur with Flutter 3.47.2: the 15 import-error
dialogs and nine simulation panels. Inspection shows small text/control rendering
differences with the same content and layout, rather than missing application
content. These are toolchain-sensitive comparisons, not proof of a single
underlying renderer cause.

All 135 master/candidate pairs were inspected in contact sheets, with full-size
inspection of suspicious fixtures. Changes were classified as follows:

- Canvas geometry: the intended `kAutomatonCanvasFitMaxScale` change from 1.75 to
  1 in `387210af` stops enlarging small diagrams. State/edge positions, initial
  arrows, accepting rings and labels remain present. Diagnostic controls and
  their reserved space are also newer than the PNGs.
- Formal notation: the current empty-string policy displays epsilon by default,
  and TM transition labels expose their tape number. PDA and TM editors show
  the current compact controls. These behaviors predate this issue branch.
- Grammar and workspace UI: production alternatives are grouped, the compact
  workspace selector replaces the old bottom navigation, and the algorithms
  panel includes manual DFA completion. The implementation already contained
  those features before the import migration.
- Settings fixture defect: all 12 candidate Settings images showed an
  `ErrorWidget` because the golden harness omitted `sharedPreferencesProvider`.
  The harness now supplies the same required startup dependency as the app,
  and asserts that no exception/ErrorWidget is present before capture. The
  repaired light/dark/mobile/tablet/desktop images were inspected again.
- Regex fixture defects: positional field lookups wrote test words into the
  newer alphabet field, and comparison/result captures never opened their
  collapsed dock panel. The tests now select the existing input keys, open the
  intended panel, assert match/non-match results and bring comparison/result
  content into view. All repaired captures were inspected again.

No red error screen, lost expected regex result, or unrelated new layout was
approved as a replacement baseline. The retained viewport clipping of large
scrollable forms is the test's declared capture area, not an overflow exemption.

## Reviewed update

Only suites containing reviewed differences were selected. The Help-page
baselines were not selected. The resulting changed PNG paths must match the
manifest's reviewed set; unchanged files keep their old bytes.

```bash
bash tool/update_goldens.sh --canvas --dialogs --simulation \
  test/goldens/pages/algorithm_panel_goldens_test.dart \
  test/goldens/pages/fsa_page_goldens_test.dart \
  test/goldens/pages/grammar_page_goldens_test.dart \
  test/goldens/pages/home_page_goldens_test.dart \
  test/goldens/pages/pda_page_goldens_test.dart \
  test/goldens/pages/regex_page_goldens_test.dart \
  test/goldens/pages/settings_page_goldens_test.dart \
  test/goldens/pages/tm_page_goldens_test.dart

flutter test test/goldens/ --reporter expanded
```

The final result is recorded with the other candidate QA in `AGENTS.md` and
`CLAUDE.md`. Logs and review contact sheets are local artifacts under
`build/issue-work/`; all execution was local, with no remote verification.

## PR #461 capture-state follow-up

Source revision `a814b58a` repairs the capture setup on 2026-09-08 using the
same macOS 26.6.2, Flutter 3.47.2, Dart 3.13.2, fonts, English locale, suite
light/dark themes and pixel ratio 1 recorded above. No production equivalence
rendering was changed.

- `pumpWidgetBuilder` had reset the algorithm and simulation panels to its
  default 800 x 600 surface, overriding each fixture's declared size. Both
  helpers now pass `surfaceSize: size` and assert the rendered size and absence
  of exceptions or error widgets. This corrects all affected captures using
  those helpers, including distinct desktop/tablet/mobile empty panels.
- The algorithm equivalence results already existed below the visible area.
  The fixtures now reveal and assert the positive/negative details and icons
  produced by the existing `_buildEquivalenceResult` implementation.
- Simulation captures now reveal and assert the selected Step 1, 2 or 3 details
  after the existing playback controls select that step.
- The custom general Settings capture now reveals and checks both disabled
  Auto Save and Show Tooltips switches. The intentionally identical defaults
  and explicit light-theme captures retain their exact previous bytes.

All 22 affected before/candidate pairs were visually reviewed before updating,
with full-size inspection of result and settings details. Their regenerated
hashes match those reviewed candidates. The named equivalence, simulation-step,
empty-viewport and custom/default Settings groups have distinct image hashes.
Two previously unchanged simulation empty-panel PNGs join the original 135-image
manifest, bringing its reviewed set to 137. Per-image `sourceRevision` overrides
the original source revision for these 22 captures; prior review hashes and
sizes remain recorded where available. Old SDK failure classifications describe
the original review, not a new Flutter 3.44.8 run.

```bash
bash tool/update_goldens.sh \
  test/goldens/pages/algorithm_panel_goldens_test.dart \
  test/goldens/pages/settings_page_goldens_test.dart \
  test/goldens/simulation/simulation_panel_goldens_test.dart
bash tool/qa.sh --only golden --report-dir build/qa/pr461-goldens --quiet
```

The selected update passed 37 tests; the complete golden comparison passed all
159 tests. Logs and six before/candidate contact sheets are under
`build/issue-work/461-*`. These results are local only, not remotely verified.
