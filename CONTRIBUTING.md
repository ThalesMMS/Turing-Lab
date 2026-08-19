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

This repository does not run GitHub-hosted CI. Contributors are responsible for
running the checks relevant to their changes and reporting the exact commands
and outcomes in the pull request.

At minimum, run:

```bash
dart format .
flutter analyze --no-fatal-infos
```

Run focused tests for the code you changed, for example:

```bash
flutter test test/unit/
flutter test test/integration/
flutter test test/widget/path_to_changed_feature_test.dart
```

The broad suite can be run with `flutter test`, but it may include work-in-
progress cases outside the scope of a contribution. Never report a suite as
passing unless the command completed with zero failures. If a required check
cannot be run, state that clearly and explain why.

## Pull Requests

- Use a focused branch and a descriptive title.
- Summarize the problem and the chosen solution.
- List every validation command and its outcome.
- Include screenshots or recordings for visible UI changes.
- Call out algorithm reference sources and intentional compatibility
  deviations.
- Keep licensing and attribution files intact.

Commit messages should follow `<scope>: <summary>`, for example:

```text
core: add DFA minimization guard
presentation: improve simulation trace layout
```
