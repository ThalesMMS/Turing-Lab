# Responsive viewport matrix and no-overflow gate

Structural responsive coverage for the release-visible pages. It is independent
of golden images: nothing here compares pixels, so a golden rebaseline can never
hide a layout exception.

## Canonical local command

```bash
flutter test test/responsive/ --concurrency=1
```

`--concurrency=1` keeps the faked view metrics deterministic across cases.

## Layout

| File | Role |
| --- | --- |
| `responsive_viewport_matrix.dart` | The only place viewport sizes, device pixel ratios, safe areas, platforms, breakpoints, text scales and locales are declared. |
| `responsive_harness.dart` | Mounts the real pages, applies and restores one matrix entry, captures framework errors, drives live resizes. |
| `responsive_fixtures.dart` | Populated FSA, PDA, TM, grammar and regex documents loaded before assertions. |
| `responsive_workspaces.dart` | Maps each workspace to its real page, quick-actions tab and navigation index. |
| `responsive_workspace_pages_test.dart` | FSA, Grammar, PDA, TM and Regex across the full matrix. |
| `responsive_shell_pages_test.dart` | Home shell, Settings, About, Help and the language comparison viewer. |
| `responsive_resize_transitions_test.dart` | Live resizes across the 1024 and 1400 bands, with state-preservation checks. |
| `responsive_text_scale_and_locale_test.dart` | English and Portuguese at text scales 1.0, 1.3 and 2.0, plus dark mode. |

`test/tablet_layout_test.dart` reuses the same matrix and harness for the
tablet-band layout checks.

## The matrix

Viewports: narrow phone `320x568`, standard phone `390x844`, large phone
`430x932`, tablet portrait `834x1194`, tablet landscape `1194x834`, split-view
window `507x1194`, constrained pane `800` inside a `1600x900` window, desktop
`1280x800` and desktop `1440x900`. Text scales: `1.0`, `1.3`, `2.0`. Locales:
`en`, `pt`.

Change a value in `responsive_viewport_matrix.dart` and every suite follows; do
not recopy sizes into individual tests.

## What makes a case fail

`ResponsiveErrorRecorder` takes over `FlutterError.onError` for the duration of
a test, so `RenderFlex` overflow, unbounded constraints and any other framework
error is collected instead of being swallowed. `assertNoLayoutErrors` pumps once
more, drains pending timers and then fails with every error it saw, dumping the
full diagnostics - including the offending widget's source location - to the
console. Cases additionally assert that core actions stay hit-testable, inside
the window, and at or above the platform touch target.

## Adding a surface

1. Mount the real page through `pumpResponsiveSurface`, `pumpResponsiveHome` or
   `pumpResponsiveWorkspace`; do not rebuild navigation or toolbars by hand.
2. Load fixtures with `loadResponsiveFixtures` when the surface reads a
   document.
3. Finish with `await surface.assertNoLayoutErrors('<what and where>')`.
