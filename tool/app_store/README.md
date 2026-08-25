# App Store screenshot capture

Local-only pipeline that renders the Apple App Store screenshot set. It is not
wired into GitHub Actions and consumes no hosted CI minutes, and `flutter test`
never runs it: the capture entry point is `test/app_store/app_store_capture_runner.dart`,
whose name deliberately omits the `_test` suffix so default test discovery
skips it.

## Commands

```bash
# Everything the tool accepts.
tool/capture_app_store_screenshots.sh --help

# One named profile/screen case into a candidate directory.
tool/capture_app_store_screenshots.sh \
  --profile iphone-6.9 --screen fsa --locale en --theme light \
  --output build/screenshots/candidate

# The complete release-approved matrix.
tool/capture_app_store_screenshots.sh --all --output build/screenshots/candidate

# Resolve a selection without capturing, or re-check an existing directory.
tool/capture_app_store_screenshots.sh plan --all
tool/capture_app_store_screenshots.sh validate --all --output screenshots/app_store
```

Omitting `--output` writes to `screenshots/app_store`, the release-approved set
that is tracked in git. Use `--output` for every candidate or debug run so an
experiment can never overwrite an approved slot.

## Selection

| Flag | Values |
| --- | --- |
| `--profile` | `iphone-6.9`, `iphone-6.5`, `iphone-5.5`, `ipad-13`, `macos` |
| `--screen` | `fsa`, `grammar`, `pda`, `tm`, `regex` (slot stems and aliases such as `01-fsa` or `fsa-editor` also resolve) |
| `--locale` | `en` (default), `pt` |
| `--theme` | `light` (default), `dark` |
| `--all` | The complete approved matrix; cannot be combined with the selectors above |

Every flag except `--all` is repeatable, and omitted dimensions fall back to
every profile, every screen, and the release default locale and theme. Approved
slots are named `<profile>/<slot>-<screen>.png`; a non-default locale or theme
appends `-<locale>` and `-dark`, so variants never collide with an approved
file.

## Determinism

Each slot runs in its own `flutter test` process, so no state survives from one
screenshot to the next. Within a process the harness pins the physical size,
device pixel ratio, safe-area insets, text scale, locale, theme, accessibility
features and animation speed; replaces the settings repository with an
in-memory one; resets SharedPreferences and the injection container; loads only
offline asset fixtures with a frozen clock; and restores every view override in
`addTearDown`. The simulation workspace renders the measured execution time of
a run, so the harness also pins that duration; otherwise two identical runs
would differ by the millisecond the simulator happened to take.

Waits are state based and bounded. `--settle` caps how many frames any stage
may pump before it reports the condition it was still waiting for, and no stage
uses `pumpAndSettle` or a fixed sleep. Stages that need the real event loop
(asset fixtures, PNG encoding) run through `runAsync` under a wall clock budget
derived from `--timeout`.

## Failure handling

A failed capture prints the profile, screen, locale, theme, target path, stage,
pending condition, current workspace route, visible text, any Flutter
exceptions, and a one-line command that reruns exactly that slot. The run then
stops with a non-zero exit unless `--best-effort` is supplied, in which case it
continues and reports every failure at the end.

`--timeout` bounds the whole capture process; the harness's own in-test budget
and per-stage budgets sit inside it, so a stuck stage is reported before the
outer timeout has to kill anything. `--fault block-prepare` and
`--fault block-settle` deliberately block a capture to verify the diagnostics
path end to end.

## Output contract

Every run writes `manifest.json` at the output root, recording for each
attempted slot: path, profile, screen, slot index, locale, theme, logical size,
pixel size, device pixel ratio, source revision, UTC timestamp, whether the slot
belongs to the approved matrix, and the capture status with the failure reason.
Rerunning one slot replaces only that row.

After capturing, the tool validates the directory: required pixel dimensions,
filename-to-slot mapping, missing slots, byte-identical duplicates, and
unexpected files. Sweeping for unexpected files only happens when the run
covered the whole approved matrix; a partial rerun checks just the slots it
selected. Pass `--no-validate` to skip the checks.

## Tests

`test/app_store/app_store_capture_config_test.dart` and
`test/app_store/app_store_field_entry_test.dart` are ordinary discovered tests
covering the profile and screen catalogue, slot filenames, CLI parsing, the
manifest, the validator, and the labelled field lookup. They never render the
image matrix.
