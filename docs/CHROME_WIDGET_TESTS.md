# Chrome widget tests

The local Chrome configuration verified for issue #456 is Flutter 3.47.2,
Dart 3.13.2, Google Chrome 152.0.7977.76, and macOS 26.6.2 (25G83), arm64.
Run the affected suites from the repository root:

```sh
CHROME_EXECUTABLE='/Applications/Google Chrome.app/Contents/MacOS/Google Chrome' \
  flutter test --platform chrome \
  test/widget/presentation/trace_playback_workspace_test.dart \
  test/widget/presentation/floating_diagnostic_panel_test.dart \
  --reporter expanded
```

On 2026-09-07 this command executed 13 tests successfully. A local outer
120-second process-group deadline bounded the investigation; it was not reached.
The same suites also execute on the native Flutter tester. These are local
results, not remotely verified QA, and do not certify every Web widget suite.

## Diagnosis and regression boundary

The original `35906261` checkout, without source changes, compiled and launched
Chrome for `floating_diagnostic_panel_test.dart` but executed no cases within a
100-second deadline. Browser console capture showed a 404 for
`widget/presentation/assets/FontManifest.json`. The suite's global
`testExecutable` awaited `golden_toolkit` 0.15.0's `loadAppFonts` before calling
`testMain`, preventing suite registration on Web. The same source with only the
Web font-loading guard executed the single test and exited 0 in 48.2 seconds;
both affected suites then passed 13 tests in 36.4 seconds.

`test/flutter_test_config.dart` now loads fonts explicitly only on native
platforms, where the approved goldens require them. Browser engine initialization
owns Web fonts. No package upgrade, SDK patch, application behavior change, or
native golden update is needed for this runner fix.

The console also reported a null-check exception in `test` 1.31.1's
`host.dart.js`, at `main_closure.call$0` line 15409. Its source dereferences the
`#play` element, which Flutter's host page does not contain. The host establishes
the suite channel before that exception: it subsequently starts the iframe and
connects the suite. Actual case execution after the font guard distinguishes
this secondary host exception from the blocking global test configuration.

An interrupted run remains **not run**, even if Flutter prints `No tests ran`
and exits 0 during shutdown. A passing application Web build or an interactive
smoke test does not replace a completed browser test result. Keep the original
failure record in `AGENTS.md` and `CLAUDE.md` as historical provenance.

The final issue-branch check also ran
`test/unit/core/algorithms/review_boundary_regressions_test.dart` alongside both
widget suites. Chrome executed all 25 tests successfully in 56.6 seconds,
including the 32/64/128-position CNF overflow cases and fresh-symbol/empty-language
regressions. The external bound was 180 seconds for this larger selection. This
is local browser execution; it does not certify physical devices or Apple L2/L3.
