# Contributing to Turing Lab

Thank you for helping improve Turing Lab. The project is under active
development, so keep changes focused and discuss compatibility-sensitive work
before investing in a large implementation.

## Before You Start

- Search existing issues and pull requests for related work.
- Open an issue before changing core automata, grammar, PDA, Turing machine, or
  file-format behavior.
- Use the upstream implementations linked from [README.md](README.md) when working on
  algorithm parity. Explain the source consulted and any intentional deviation
  in the pull request.
- Report security vulnerabilities privately as described in
  [SECURITY.md](SECURITY.md).

## Local Setup

Install Flutter 3.27.0 or newer with Dart 3.6.0 or newer, then run:

```bash
git clone https://github.com/ThalesMMS/Turing-Lab.git
cd Turing-Lab
flutter pub get
```

## Development Guidelines

- Follow Dart conventions and use two-space indentation.
- Keep Riverpod providers immutable and model-driven.
- Preserve the clean-architecture boundaries under `lib/core/`, `lib/data/`,
  and `lib/presentation/`.
- Keep changes surgical. Do not refactor unrelated code in the same pull
  request.
- Add or update tests for behavior changes.
- Do not commit build output, local credentials, generated screenshots, IDE
  state, or machine-specific configuration.

## Local Validation

**Root Flutter QA is local and manual.** GitHub-hosted test CI is intentionally
disabled for this repository because the GitHub Actions limits are too small for
its Flutter, GraphView, golden, screenshot, integration and Apple surface. The
root `.github/workflows/ci.yml` workflow was deleted and must not be
reintroduced, here or on another hosted provider. No repository-owned GitHub
Actions workflow is committed. The public web artifact is published separately
to `ThalesMMS/Turing-Lab`'s `gh-pages` branch, and GitHub's system-managed
Pages deployment is not test CI. The policy and workflow inventory live in
[docs/BRANCH_PROTECTION.md](docs/BRANCH_PROTECTION.md).

Nothing is verified for you. You run the checks, and you report them.

### The canonical entrypoint

```bash
tool/qa.sh --help     # every option, category and preset
tool/qa.sh            # the default `code` preset
```

`tool/qa.sh` orchestrates the existing suites and scripts and reports each
category independently:

`prereqs`, `format`, `analyze`, `unit`, `widget`, `integration`, `properties`,
`graphview`, `responsive`, `golden`, `screenshots`, `apple`.

Each category ends in exactly one of four states, and only the first is a pass:

| State | Meaning |
| --- | --- |
| `passed` | The command exited zero on your machine. |
| `failed` | The command exited non-zero. |
| `skipped` | Not executed because you passed an explicit opt-out flag. |
| `not_run` | Not selected, or a prerequisite was missing. |

If the Flutter or Dart toolchain is unavailable, the entrypoint fails closed
with exit code 127. Use `--allow-missing-toolchain` only when you intend to
report the run as skipped; it is never a pass.

### Focused subsets

Match the effort to the change instead of running the whole release matrix:

```bash
tool/qa.sh --preset quick                  # prereqs, format, analyze, unit
tool/qa.sh --preset code                   # the default; adds widget + integration
tool/qa.sh --preset canvas                 # graphview, responsive, goldens, canvas suites
tool/qa.sh --preset grammar                # grammar/CFG-named unit and widget suites
tool/qa.sh --preset tm                     # Turing-machine-named unit and widget suites
tool/qa.sh --preset responsive             # responsive viewport matrix
tool/qa.sh --preset golden                 # golden comparison
tool/qa.sh --preset screenshots            # App Store capture and validation
tool/qa.sh --preset apple --apple-target macos --apple-device macos
tool/qa.sh --only analyze,unit             # any explicit category list
tool/qa.sh --only properties               # bounded deterministic property profile
tool/qa.sh --dry-run --all                 # print the plan, execute nothing
```

Every run writes `build/qa/qa-summary.md`, `build/qa/qa-summary.json` and
per-step logs under `build/qa/logs/`.

The underlying commands remain usable on their own, for example:

```bash
dart format .
flutter analyze --no-fatal-infos
flutter test test/unit/
flutter test test/widget/path_to_changed_feature_test.dart
```

Changes to document codecs, JFLAP mappings, canonical JSON, or compatibility
fixtures must also run the offline corpus:

```bash
dart run tool/compatibility_corpus.dart
```

Report its exact `CORPUS_RESULT`, disclose `notRun` cases, and include any
approved loss with its linked issue. Regenerate `docs/JFLAP_COMPATIBILITY.md`
with `--update-public` whenever the versioned manifest changes.

Algorithm property, fuzzing, oracle, or edge-case changes must use the shared
framework documented in [docs/ALGORITHM_TESTING.md](docs/ALGORITHM_TESTING.md).
Report the exact family, property, seed or seed range, generator/oracle version,
and `PROPERTY_RESULT`. Preserve the emitted reproduction command for failures,
and promote only reviewed minimized fixtures with explicit provenance and a
regression issue. A bounded or inapplicable oracle result is incomplete, not a
pass.

The broad `flutter test` run executes the complete test tree. `AGENTS.md`
records its current result and elapsed-time baseline.

## Pull Requests

- Use a focused branch and a descriptive title.
- Summarize the problem and the chosen solution.
- **List every validation command and its exact outcome.** Paste the category
  table from `build/qa/qa-summary.md`, or the `QA_STATUS` lines, rather than
  writing "tests pass".
- **Disclose everything you did not run.** Name the categories that ended
  `skipped` or `not_run` and say why. A skipped, unavailable or interrupted
  check is not a pass, and an untouched category is not evidence.
- Never state or imply that a result was verified remotely. It was not.
- If a failure matches a documented baseline in `AGENTS.md`, say so and link the
  baseline; otherwise treat it as a regression.
- Include screenshots or recordings for visible UI changes.
- Call out algorithm reference sources and intentional compatibility
  deviations.
- Keep licensing and attribution files intact.

Commit messages should follow `<scope>: <summary>`, for example:

```text
core: add DFA minimization guard
presentation: improve simulation trace layout
```
