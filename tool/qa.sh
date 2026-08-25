#!/usr/bin/env bash
#
# qa.sh
# Turing Lab
#
# Canonical local QA entrypoint. GitHub-hosted test CI is intentionally
# disabled for this repository, so this script is the gate: it orchestrates the
# existing suites and scripts, reports every category independently as
# `passed`, `failed`, `skipped` or `not_run`, and fails closed when the Flutter
# or Dart toolchain is unavailable.
#
# Nothing here runs remotely. The summary it writes is local evidence only.
#
#   tool/qa.sh --help
#   tool/qa.sh                      # default `code` preset
#   tool/qa.sh --preset canvas
#   tool/qa.sh --only unit,analyze
#
set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

readonly CATEGORIES="prereqs format analyze unit widget integration graphview responsive golden screenshots apple"
readonly PRESETS="code quick canvas grammar tm responsive golden screenshots apple all"

readonly EXIT_OK=0
readonly EXIT_FAILED=1
readonly EXIT_INCOMPLETE=2
readonly EXIT_USAGE=64
readonly EXIT_NO_TOOLCHAIN=127

readonly WIDGET_STABLE_TARGETS="\
test/widget/presentation/simulation_panel_test.dart \
test/widget/presentation/trace_viewers_test.dart \
test/widget/presentation/workflow_localization_test.dart \
test/widget/presentation/grammar_algorithm_panel_test.dart \
test/widget/presentation/grammar_simulation_panel_test.dart \
test/widget/presentation/pda_algorithm_panel_test.dart \
test/widget/presentation/pda_tm_simulation_panel_scaffold_test.dart \
test/widget/presentation/tm_algorithm_panel_test.dart"

readonly UNIT_TARGETS="test/unit/ test/core/ test/features/ test/app_store/ test/website/"
readonly GENERATED_L10N="lib/l10n/app_localizations.dart lib/l10n/app_localizations_en.dart lib/l10n/app_localizations_pt.dart"

usage() {
  cat <<'USAGE'
Usage: tool/qa.sh [options]

Canonical local QA entrypoint for Turing Lab. This repository does not run
GitHub-hosted test CI; every result below is produced on this machine and is
never remotely verified.

Categories (reported independently):
  prereqs      Toolchain discovery, `flutter pub get`, generated-l10n drift
  format       Changed-file `dart format` plus the English comment/doc check
  analyze      `flutter analyze --no-fatal-infos` on the root package
  unit         test/unit/, test/core/, test/features/, test/app_store/, test/website/
  widget       test/widget/ (see --widget-scope)
  integration  test/integration/ (device-free smoke and IO round-trips)
  graphview    The vendored graphview package: pub get, analyze, tests, benchmarks
  responsive   test/responsive/ and test/tablet_layout_test.dart
  golden       test/goldens/ comparison only; this script never re-records
  screenshots  App Store capture into a scratch directory, then validation
  apple        Apple L1 headless smoke, L2 device journeys, L3 manual matrix

Presets:
  code         prereqs format analyze unit widget integration   (default)
  quick        prereqs format analyze unit
  canvas       prereqs analyze graphview responsive golden, plus canvas-named
               unit/widget suites
  grammar      prereqs analyze, plus grammar/CFG-named unit/widget suites
  tm           prereqs analyze, plus Turing-machine-named unit/widget suites
  responsive   prereqs responsive
  golden       prereqs golden
  screenshots  prereqs screenshots
  apple        prereqs apple
  all          every category

Options:
  -h, --help                 Show this help and exit
      --list                 List categories and presets, then exit
      --preset NAME          Select a preset (default: code)
      --all                  Same as --preset all
      --only IDS             Comma-separated category ids to run
      --skip IDS             Comma-separated category ids to skip by explicit
                             opt-in (reported as `skipped`, never as `passed`)
      --skip-l10n            Skip only the generated-localization drift check
      --skip-graphview-benchmarks
                             Skip only the two graphview interaction benchmarks.
                             They assert wall-clock frame budgets and are
                             sensitive to machine load.
      --allow-missing-toolchain
                             Opt in to skipping everything when Flutter/Dart is
                             unavailable. Without this flag a missing toolchain
                             is a hard failure (exit 127).
      --format-all           Format-check the whole tree instead of changed files
      --base SHA             Base revision for the changed-file format check
      --widget-scope SCOPE   `stable` (default) runs the eight historically
                             green presentation suites; `all` runs test/widget/,
                             which still contains documented baseline failures
      --apple-target NAME    iphone | ipad | macos, required for Apple L2
      --apple-device ID      Device id passed to `flutter test -d`, required for
                             Apple L2
      --screenshots-scope S  `all` (default) captures the full matrix; `smoke`
                             captures one macOS slot
      --screenshots-output D Capture directory (default: REPORT_DIR/screenshots).
                             Never defaults to the tracked screenshots/ tree.
      --report-dir DIR       Summary and log directory (default: build/qa)
      --no-report            Do not write the summary artifact
      --quiet                Send step output to the log files only
      --dry-run              Print the plan without executing anything
      --flutter PATH         Flutter executable (env: FLUTTER_BIN)
      --dart PATH            Dart executable (env: DART_BIN)

Exit codes:
  0    every selected category passed or was skipped by explicit opt-in
  1    at least one selected category failed
  2    nothing failed, but a selected category could not run
  64   usage error
  127  required Flutter/Dart toolchain unavailable and no explicit opt-in

The `apple` category always ends `not_run`, and therefore exits 2, because
level L3 is the manual release matrix in release/APPLE_QA_MATRIX.md and no
local command can close it. `--preset all` inherits that; add `--skip apple`
when you want the rest of the matrix to report a clean exit 0.

Examples:
  tool/qa.sh
  tool/qa.sh --preset grammar
  tool/qa.sh --only analyze,unit --base origin/main
  tool/qa.sh --preset apple --apple-target macos --apple-device macos
  tool/qa.sh --all --widget-scope all
USAGE
}

list_surface() {
  echo "Categories:"
  local category
  for category in $CATEGORIES; do
    printf '  %s\n' "$category"
  done
  echo ""
  echo "Presets:"
  local preset
  for preset in $PRESETS; do
    printf '  %-12s %s\n' "$preset" "$(preset_categories "$preset")"
  done
}

die_usage() {
  echo "error: $1" >&2
  echo "Run 'tool/qa.sh --help' for the full option list." >&2
  exit "$EXIT_USAGE"
}

in_list() {
  case " $2 " in
  *" $1 "*) return 0 ;;
  *) return 1 ;;
  esac
}

preset_categories() {
  case "$1" in
  code) echo "prereqs format analyze unit widget integration" ;;
  quick) echo "prereqs format analyze unit" ;;
  canvas) echo "prereqs analyze unit widget graphview responsive golden" ;;
  grammar) echo "prereqs analyze unit widget" ;;
  tm) echo "prereqs analyze unit widget" ;;
  responsive) echo "prereqs responsive" ;;
  golden) echo "prereqs golden" ;;
  screenshots) echo "prereqs screenshots" ;;
  apple) echo "prereqs apple" ;;
  all) echo "$CATEGORIES" ;;
  *) return 1 ;;
  esac
}

# Name fragments used to narrow unit/widget/golden targets for the focused
# module presets. Empty means "run the whole category".
preset_patterns() {
  case "$1" in
  canvas) echo "canvas graphview" ;;
  grammar) echo "grammar cfg cyk glc" ;;
  tm) echo "tm turing tape" ;;
  *) echo "" ;;
  esac
}

PRESET="code"
ONLY=""
SKIP=""
SKIP_L10N=0
SKIP_GRAPHVIEW_BENCHMARKS=0
ALLOW_MISSING_TOOLCHAIN="${ALLOW_MISSING_FLUTTER:-0}"
FORMAT_ALL=0
FORMAT_BASE="${QA_FORMAT_BASE:-}"
WIDGET_SCOPE="stable"
APPLE_TARGET=""
APPLE_DEVICE=""
SCREENSHOTS_SCOPE="all"
SCREENSHOTS_OUTPUT=""
REPORT_DIR="build/qa"
WRITE_REPORT=1
QUIET=0
DRY_RUN=0
FLUTTER_OVERRIDE="${FLUTTER_BIN:-${TURING_LAB_FLUTTER_BIN:-}}"
DART_OVERRIDE="${DART_BIN:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
  -h | --help)
    usage
    exit "$EXIT_OK"
    ;;
  --list)
    list_surface
    exit "$EXIT_OK"
    ;;
  --preset)
    [[ $# -ge 2 ]] || die_usage "--preset requires a value"
    PRESET="$2"
    shift 2
    ;;
  --all)
    PRESET="all"
    shift
    ;;
  --only)
    [[ $# -ge 2 ]] || die_usage "--only requires a value"
    ONLY="$(echo "$2" | tr ',' ' ')"
    shift 2
    ;;
  --skip)
    [[ $# -ge 2 ]] || die_usage "--skip requires a value"
    SKIP="$SKIP $(echo "$2" | tr ',' ' ')"
    shift 2
    ;;
  --skip-l10n)
    SKIP_L10N=1
    shift
    ;;
  --skip-graphview-benchmarks)
    SKIP_GRAPHVIEW_BENCHMARKS=1
    shift
    ;;
  --allow-missing-toolchain)
    ALLOW_MISSING_TOOLCHAIN=1
    shift
    ;;
  --format-all)
    FORMAT_ALL=1
    shift
    ;;
  --base)
    [[ $# -ge 2 ]] || die_usage "--base requires a value"
    FORMAT_BASE="$2"
    shift 2
    ;;
  --widget-scope)
    [[ $# -ge 2 ]] || die_usage "--widget-scope requires a value"
    WIDGET_SCOPE="$2"
    shift 2
    ;;
  --apple-target)
    [[ $# -ge 2 ]] || die_usage "--apple-target requires a value"
    APPLE_TARGET="$2"
    shift 2
    ;;
  --apple-device)
    [[ $# -ge 2 ]] || die_usage "--apple-device requires a value"
    APPLE_DEVICE="$2"
    shift 2
    ;;
  --screenshots-scope)
    [[ $# -ge 2 ]] || die_usage "--screenshots-scope requires a value"
    SCREENSHOTS_SCOPE="$2"
    shift 2
    ;;
  --screenshots-output)
    [[ $# -ge 2 ]] || die_usage "--screenshots-output requires a value"
    SCREENSHOTS_OUTPUT="$2"
    shift 2
    ;;
  --report-dir)
    [[ $# -ge 2 ]] || die_usage "--report-dir requires a value"
    REPORT_DIR="$2"
    shift 2
    ;;
  --no-report)
    WRITE_REPORT=0
    shift
    ;;
  --quiet)
    QUIET=1
    shift
    ;;
  --dry-run)
    DRY_RUN=1
    shift
    ;;
  --flutter)
    [[ $# -ge 2 ]] || die_usage "--flutter requires a value"
    FLUTTER_OVERRIDE="$2"
    shift 2
    ;;
  --dart)
    [[ $# -ge 2 ]] || die_usage "--dart requires a value"
    DART_OVERRIDE="$2"
    shift 2
    ;;
  *)
    die_usage "unknown option: $1"
    ;;
  esac
done

preset_categories "$PRESET" >/dev/null || die_usage "unknown preset: $PRESET (expected one of: $PRESETS)"

case "$WIDGET_SCOPE" in
stable | all) ;;
*) die_usage "unknown --widget-scope: $WIDGET_SCOPE (expected stable or all)" ;;
esac

case "$SCREENSHOTS_SCOPE" in
all | smoke) ;;
*) die_usage "unknown --screenshots-scope: $SCREENSHOTS_SCOPE (expected all or smoke)" ;;
esac

if [[ -n "$APPLE_TARGET" ]]; then
  case "$APPLE_TARGET" in
  iphone | ipad | macos) ;;
  *) die_usage "unknown --apple-target: $APPLE_TARGET (expected iphone, ipad or macos)" ;;
  esac
fi

SELECTED=""
if [[ -n "$ONLY" ]]; then
  for candidate in $ONLY; do
    in_list "$candidate" "$CATEGORIES" || die_usage "unknown category: $candidate (expected one of: $CATEGORIES)"
    in_list "$candidate" "$SELECTED" || SELECTED="$SELECTED $candidate"
  done
  # Every other category depends on a resolved toolchain and current packages.
  in_list "prereqs" "$SELECTED" || SELECTED="prereqs$SELECTED"
  PRESET="custom"
  ORDERED=""
  for candidate in $CATEGORIES; do
    in_list "$candidate" "$SELECTED" && ORDERED="$ORDERED $candidate"
  done
  SELECTED="$ORDERED"
else
  SELECTED="$(preset_categories "$PRESET")"
fi

for candidate in $SKIP; do
  in_list "$candidate" "$CATEGORIES" || die_usage "unknown category in --skip: $candidate"
done

PATTERNS="$(preset_patterns "$PRESET")"

resolve_tool() {
  local override="$1" name="$2" fallback="$3"
  if [[ -n "$override" ]]; then
    echo "$override"
    return 0
  fi
  if command -v "$name" >/dev/null 2>&1; then
    command -v "$name"
    return 0
  fi
  if [[ -x "$fallback" ]]; then
    echo "$fallback"
    return 0
  fi
  return 1
}

FLUTTER=""
DART=""
FLUTTER="$(resolve_tool "$FLUTTER_OVERRIDE" flutter /opt/homebrew/bin/flutter || true)"
if [[ -n "$FLUTTER" && -x "$FLUTTER" ]]; then
  DART="$(resolve_tool "$DART_OVERRIDE" dart "$(dirname "$FLUTTER")/dart" || true)"
else
  DART="$(resolve_tool "$DART_OVERRIDE" dart /opt/homebrew/bin/dart || true)"
fi

TOOLCHAIN_REASON=""
if [[ -z "$FLUTTER" || ! -x "$FLUTTER" ]]; then
  TOOLCHAIN_REASON="missing_flutter"
elif [[ -z "$DART" || ! -x "$DART" ]]; then
  TOOLCHAIN_REASON="missing_dart"
fi

# Parallel arrays; macOS ships bash 3.2, which has no associative arrays.
STEP_CATEGORY=()
STEP_ID=()
STEP_DESCRIPTION=()
STEP_COMMAND=()
STEP_STATUS=()
STEP_REASON=()
STEP_EXIT=()
STEP_SECONDS=()

status_rank() {
  case "$1" in
  passed) echo 0 ;;
  skipped) echo 1 ;;
  not_run) echo 2 ;;
  failed) echo 3 ;;
  *) echo 3 ;;
  esac
}

set_category_status() {
  local category="$1" status="$2" reason="$3"
  local touched current current_rank new_rank
  eval "touched=\${CATEGORY_TOUCHED_${category}:-0}"
  if [[ "$touched" -eq 1 ]]; then
    eval "current=\${CATEGORY_STATUS_${category}}"
    current_rank="$(status_rank "$current")"
    new_rank="$(status_rank "$status")"
    [[ "$new_rank" -le "$current_rank" ]] && return 0
  fi
  eval "CATEGORY_TOUCHED_${category}=1"
  eval "CATEGORY_STATUS_${category}=\"\$status\""
  eval "CATEGORY_REASON_${category}=\"\$reason\""
}

category_status() {
  local value
  eval "value=\${CATEGORY_STATUS_$1:-not_run}"
  echo "$value"
}

category_reason() {
  local value
  eval "value=\${CATEGORY_REASON_$1:-not_selected}"
  echo "$value"
}

for category in $CATEGORIES; do
  eval "CATEGORY_TOUCHED_${category}=0"
  eval "CATEGORY_STATUS_${category}=not_run"
  eval "CATEGORY_REASON_${category}=not_selected"
done

record_step() {
  local category="$1" id="$2" description="$3" command="$4" status="$5" reason="$6" exit_code="$7" seconds="$8"
  STEP_CATEGORY+=("$category")
  STEP_ID+=("$id")
  STEP_DESCRIPTION+=("$description")
  STEP_COMMAND+=("$command")
  STEP_STATUS+=("$status")
  STEP_REASON+=("$reason")
  STEP_EXIT+=("$exit_code")
  STEP_SECONDS+=("$seconds")
  set_category_status "$category" "$status" "$reason"
  printf 'QA_STATUS %s.%s=%s reason=%s exit_code=%s seconds=%s\n' \
    "$category" "$id" "$status" "$reason" "$exit_code" "$seconds"
}

LOG_DIR=""

step_log_path() {
  [[ -n "$LOG_DIR" ]] || {
    echo "/dev/null"
    return 0
  }
  echo "$LOG_DIR/$1.$2.log"
}

# Runs one command, streams and captures its output, and records the outcome.
# Usage: exec_step <category> <id> <description> <display-command> -- <argv...>
exec_step() {
  local category="$1" id="$2" description="$3" display="$4"
  shift 4
  [[ "${1:-}" == "--" ]] && shift

  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo ""
    echo "--- ${category}.${id}: ${description}"
    echo "    \$ ${display}"
    record_step "$category" "$id" "$description" "$display" not_run dry_run - 0
    return 0
  fi

  local log started finished elapsed code
  log="$(step_log_path "$category" "$id")"
  echo ""
  echo "--- ${category}.${id}: ${description}"
  echo "    \$ ${display}"
  started="$(date +%s)"
  if [[ "$QUIET" -eq 1 ]]; then
    "$@" >"$log" 2>&1
    code=$?
  else
    "$@" 2>&1 | tee "$log"
    code=${PIPESTATUS[0]}
  fi
  finished="$(date +%s)"
  elapsed=$((finished - started))
  if [[ "$code" -eq 0 ]]; then
    record_step "$category" "$id" "$description" "$display" passed - "$code" "$elapsed"
  else
    record_step "$category" "$id" "$description" "$display" failed command_failed "$code" "$elapsed"
  fi
  return 0
}

skip_step() {
  record_step "$1" "$2" "$3" "$4" skipped "$5" - 0
}

unrun_step() {
  record_step "$1" "$2" "$3" "$4" not_run "$5" - 0
}

in_graphview() {
  (
    cd "$ROOT_DIR/graphview" && "$@"
  )
}

git_diff_generated_l10n() {
  git diff --exit-code -- $GENERATED_L10N
}

format_changed() {
  PATH="$(dirname "$DART"):$PATH" "$ROOT_DIR/tool/check_changed_dart_format.sh" "$@"
}

collect_targets() {
  local dirs="$1" patterns="$2"
  local existing="" dir pattern expression=""
  for dir in $dirs; do
    [[ -e "$ROOT_DIR/$dir" ]] && existing="$existing $dir"
  done
  [[ -n "$existing" ]] || return 0
  if [[ -z "$patterns" ]]; then
    echo "$existing"
    return 0
  fi
  set -f
  for pattern in $patterns; do
    if [[ -z "$expression" ]]; then
      expression="-name *${pattern}*_test.dart"
    else
      expression="$expression -o -name *${pattern}*_test.dart"
    fi
  done
  find $existing -type f \( $expression \) 2>/dev/null | sort | tr '\n' ' '
  set +f
}

# ---------------------------------------------------------------------------
# Header
# ---------------------------------------------------------------------------

GIT_REVISION="$(git rev-parse --short HEAD 2>/dev/null || echo unknown)"
STARTED_AT="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"

echo "========================================="
echo "Turing Lab local QA"
echo "========================================="
echo "Repository:  $ROOT_DIR"
echo "Revision:    $GIT_REVISION"
echo "Started:     $STARTED_AT (UTC)"
echo "Host:        $(uname -s) $(uname -m)"
echo "Preset:      $PRESET"
echo "Selected:    $(echo $SELECTED)"
[[ -n "$(echo $SKIP)" ]] && echo "Opted out:   $(echo $SKIP)"
[[ -n "$PATTERNS" ]] && echo "Name filter: $PATTERNS"
echo "Flutter:     ${FLUTTER:-<not found>}"
echo "Dart:        ${DART:-<not found>}"
echo ""
echo "Local execution only. GitHub-hosted test CI is intentionally disabled for"
echo "this repository; no result below was verified remotely."

if [[ "$WRITE_REPORT" -eq 1 && "$DRY_RUN" -eq 0 ]]; then
  LOG_DIR="$REPORT_DIR/logs"
  mkdir -p "$LOG_DIR" || {
    echo "error: cannot create report directory $REPORT_DIR" >&2
    exit "$EXIT_USAGE"
  }
  rm -f "$LOG_DIR"/*.log 2>/dev/null || true
fi

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo ""
  echo "PLAN ONLY: --dry-run prints the command surface and executes nothing."
fi

# ---------------------------------------------------------------------------
# Fail-closed toolchain gate
# ---------------------------------------------------------------------------

TOOLCHAIN_BLOCKED=0
EXIT_OVERRIDE=""

if [[ -n "$TOOLCHAIN_REASON" && "$DRY_RUN" -eq 0 ]]; then
  TOOLCHAIN_BLOCKED=1
  echo ""
  echo "ERROR: required toolchain unavailable ($TOOLCHAIN_REASON)."
  echo "Install Flutter 3.27.0+ / Dart 3.6.0+, or point --flutter/--dart at them."
  if [[ "$ALLOW_MISSING_TOOLCHAIN" == "1" ]]; then
    echo "Skipping by explicit opt-in (--allow-missing-toolchain). This is not a pass."
    for category in $CATEGORIES; do
      in_list "$category" "$SELECTED" || continue
      record_step "$category" toolchain "Requires the Flutter/Dart toolchain" "(not executed)" \
        skipped "${TOOLCHAIN_REASON}_opt_in" - 0
    done
  else
    echo "Pass --allow-missing-toolchain to opt in to skipping instead of failing."
    EXIT_OVERRIDE="$EXIT_NO_TOOLCHAIN"
    for category in $CATEGORIES; do
      in_list "$category" "$SELECTED" || continue
      record_step "$category" toolchain "Requires the Flutter/Dart toolchain" "(not executed)" \
        failed "$TOOLCHAIN_REASON" - 0
    done
  fi
fi

# ---------------------------------------------------------------------------
# Categories
# ---------------------------------------------------------------------------

run_category() {
  local category="$1"
  if ! in_list "$category" "$SELECTED"; then
    return 0
  fi
  if in_list "$category" "$SKIP"; then
    skip_step "$category" opted-out "Category skipped on request" "(not executed)" explicit_opt_in
    return 0
  fi
  "category_${category}"
}

category_prereqs() {
  exec_step prereqs flutter-version "Flutter toolchain version" \
    "$FLUTTER --version" -- "$FLUTTER" --version
  exec_step prereqs dart-version "Dart toolchain version" \
    "$DART --version" -- "$DART" --version
  exec_step prereqs pub-get "Resolve root package dependencies" \
    "$FLUTTER pub get" -- "$FLUTTER" pub get

  if [[ "$SKIP_L10N" -eq 1 ]]; then
    skip_step prereqs l10n "Generated localization drift" \
      "$FLUTTER gen-l10n && git diff --exit-code -- lib/l10n/app_localizations*.dart" explicit_opt_in
    return 0
  fi
  if ! command -v git >/dev/null 2>&1; then
    unrun_step prereqs l10n "Generated localization drift" \
      "git diff --exit-code -- lib/l10n/app_localizations*.dart" missing_git
    return 0
  fi
  exec_step prereqs l10n-generate "Regenerate localization sources" \
    "$FLUTTER gen-l10n" -- "$FLUTTER" gen-l10n
  exec_step prereqs l10n-drift "Generated localization matches the committed sources" \
    "git diff --exit-code -- lib/l10n/app_localizations*.dart" -- git_diff_generated_l10n
}

category_format() {
  if [[ "$FORMAT_ALL" -eq 1 ]]; then
    exec_step format dart-format "Format check for the whole tree" \
      "$DART format --output=none --set-exit-if-changed ." -- \
      "$DART" format --output=none --set-exit-if-changed .
  else
    exec_step format dart-format "Format check for changed Dart files" \
      "$(echo tool/check_changed_dart_format.sh $FORMAT_BASE)" -- format_changed "$FORMAT_BASE"
  fi

  if command -v python3 >/dev/null 2>&1; then
    exec_step format comment-language "Comments and docs are English" \
      "python3 tool/check_comment_docs_english.py" -- \
      python3 tool/check_comment_docs_english.py
    return 0
  fi
  if [[ "$ALLOW_MISSING_TOOLCHAIN" == "1" ]]; then
    skip_step format comment-language "Comments and docs are English" \
      "python3 tool/check_comment_docs_english.py" missing_python3_opt_in
  else
    record_step format comment-language "Comments and docs are English" \
      "python3 tool/check_comment_docs_english.py" failed missing_python3 - 0
  fi
}

category_analyze() {
  exec_step analyze root "Static analysis of the root package" \
    "$FLUTTER analyze --no-fatal-infos" -- "$FLUTTER" analyze --no-fatal-infos
}

category_unit() {
  local targets
  targets="$(collect_targets "$UNIT_TARGETS" "$PATTERNS")"
  if [[ -z "$(echo $targets)" ]]; then
    unrun_step unit suites "Device-free logic suites" \
      "$FLUTTER test <no matching targets>" no_matching_targets
    return 0
  fi
  exec_step unit suites "Device-free logic suites" \
    "$FLUTTER test $(echo $targets)" -- "$FLUTTER" test $targets
}

category_widget() {
  local targets scope
  if [[ -n "$PATTERNS" ]]; then
    targets="$(collect_targets "test/widget/" "$PATTERNS")"
    scope="name filter '$PATTERNS'"
  elif [[ "$WIDGET_SCOPE" == "all" ]]; then
    targets="test/widget/"
    scope="all"
  else
    targets="$WIDGET_STABLE_TARGETS"
    scope="stable"
  fi
  if [[ -z "$(echo $targets)" ]]; then
    unrun_step widget suites "Widget suites" \
      "$FLUTTER test <no matching targets>" no_matching_targets
    return 0
  fi
  exec_step widget suites "Widget suites (scope: $scope)" \
    "$FLUTTER test $(echo $targets)" -- "$FLUTTER" test $targets
}

category_integration() {
  exec_step integration suites "Device-free integration and IO round-trips" \
    "$FLUTTER test test/integration/" -- "$FLUTTER" test test/integration/
}

category_graphview() {
  exec_step graphview pub-get "Resolve vendored graphview dependencies" \
    "(cd graphview && $FLUTTER pub get)" -- in_graphview "$FLUTTER" pub get
  exec_step graphview analyze "Static analysis of the vendored graphview package" \
    "(cd graphview && $FLUTTER analyze --no-fatal-infos)" -- in_graphview "$FLUTTER" analyze --no-fatal-infos
  exec_step graphview tests "Vendored graphview test suite" \
    "(cd graphview && $FLUTTER test)" -- in_graphview "$FLUTTER" test
  if [[ "$SKIP_GRAPHVIEW_BENCHMARKS" -eq 1 ]]; then
    skip_step graphview benchmarks "Graphview interaction benchmarks" \
      "(cd graphview && $FLUTTER test benchmark/interaction_benchmark_test.dart --concurrency=1)" explicit_opt_in
    return 0
  fi
  exec_step graphview benchmark-drag "Graphview single-node drag benchmark" \
    "(cd graphview && $FLUTTER test benchmark/interaction_benchmark_test.dart --concurrency=1 --name 'single-node drag')" -- \
    in_graphview "$FLUTTER" test benchmark/interaction_benchmark_test.dart --concurrency=1 --name "single-node drag"
  exec_step graphview benchmark-viewport "Graphview zoom and pan benchmark" \
    "(cd graphview && $FLUTTER test benchmark/interaction_benchmark_test.dart --concurrency=1 --name 'zoom and pan')" -- \
    in_graphview "$FLUTTER" test benchmark/interaction_benchmark_test.dart --concurrency=1 --name "zoom and pan"
}

category_responsive() {
  exec_step responsive matrix "Responsive viewport matrix and overflow gate" \
    "$FLUTTER test test/responsive/ --concurrency=1" -- \
    "$FLUTTER" test test/responsive/ --concurrency=1
  exec_step responsive tablet "Tablet layout suite" \
    "$FLUTTER test test/tablet_layout_test.dart" -- \
    "$FLUTTER" test test/tablet_layout_test.dart
}

category_golden() {
  local targets
  targets="$(collect_targets "test/goldens/" "$PATTERNS")"
  if [[ -z "$(echo $targets)" ]]; then
    unrun_step golden compare "Golden comparison" \
      "$FLUTTER test <no matching targets>" no_matching_targets
    return 0
  fi
  exec_step golden compare "Golden comparison (never re-records)" \
    "$FLUTTER test $(echo $targets)" -- "$FLUTTER" test $targets
  echo ""
  echo "    Intentional visual changes are re-recorded separately with"
  echo "    ./tool/update_goldens.sh; tool/qa.sh never writes golden baselines."
}

category_screenshots() {
  local output="$SCREENSHOTS_OUTPUT"
  [[ -n "$output" ]] || output="$REPORT_DIR/screenshots"
  local selection
  if [[ "$SCREENSHOTS_SCOPE" == "smoke" ]]; then
    selection="--profile macos --screen fsa"
  else
    selection="--all"
  fi
  exec_step screenshots capture "App Store capture into $output" \
    "tool/capture_app_store_screenshots.sh $selection --output $output" -- \
    "$ROOT_DIR/tool/capture_app_store_screenshots.sh" $selection --output "$output"
  exec_step screenshots validate "Validate the captured directory" \
    "tool/capture_app_store_screenshots.sh validate $selection --output $output" -- \
    "$ROOT_DIR/tool/capture_app_store_screenshots.sh" validate $selection --output "$output"
}

category_apple() {
  exec_step apple l1-smoke "Apple L1 headless release smoke" \
    "$FLUTTER test test/integration/apple_release_smoke_test.dart --concurrency=1" -- \
    "$FLUTTER" test test/integration/apple_release_smoke_test.dart --concurrency=1

  if [[ -n "$APPLE_TARGET" && -n "$APPLE_DEVICE" ]]; then
    exec_step apple l2-journeys "Apple L2 device journeys on $APPLE_DEVICE" \
      "$FLUTTER test integration_test/apple_release_user_journeys_test.dart -d $APPLE_DEVICE --dart-define=APPLE_RELEASE_TARGET=$APPLE_TARGET --dart-define=APPLE_RELEASE_DEVICE=$APPLE_DEVICE" -- \
      "$FLUTTER" test integration_test/apple_release_user_journeys_test.dart \
      -d "$APPLE_DEVICE" \
      "--dart-define=APPLE_RELEASE_TARGET=$APPLE_TARGET" \
      "--dart-define=APPLE_RELEASE_DEVICE=$APPLE_DEVICE"
  else
    unrun_step apple l2-journeys "Apple L2 device journeys" \
      "$FLUTTER test integration_test/apple_release_user_journeys_test.dart -d <device> --dart-define=APPLE_RELEASE_TARGET=<target> --dart-define=APPLE_RELEASE_DEVICE=<device>" \
      needs_--apple-target_and_--apple-device
  fi

  unrun_step apple l3-manual "Apple L3 release artifacts and manual matrix" \
    "release/APPLE_QA_MATRIX.md" manual_only
}

if [[ "$TOOLCHAIN_BLOCKED" -eq 0 ]]; then
  for category in $CATEGORIES; do
    run_category "$category"
  done
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

OVERALL="passed"
HAS_FAILURE=0
HAS_INCOMPLETE=0
HAS_PASSED=0
for category in $CATEGORIES; do
  in_list "$category" "$SELECTED" || continue
  case "$(category_status "$category")" in
  failed) HAS_FAILURE=1 ;;
  not_run) HAS_INCOMPLETE=1 ;;
  passed) HAS_PASSED=1 ;;
  esac
done

if [[ "$DRY_RUN" -eq 1 ]]; then
  OVERALL="plan"
elif [[ "$HAS_FAILURE" -eq 1 ]]; then
  OVERALL="failed"
elif [[ "$HAS_INCOMPLETE" -eq 1 ]]; then
  OVERALL="incomplete"
elif [[ "$HAS_PASSED" -eq 0 ]]; then
  OVERALL="skipped"
fi

echo ""
echo "========================================="
echo "Category summary"
echo "========================================="
printf '%-13s %-9s %s\n' "CATEGORY" "STATUS" "REASON"
for category in $CATEGORIES; do
  printf '%-13s %-9s %s\n' "$category" "$(category_status "$category")" "$(category_reason "$category")"
  echo "QA_STATUS ${category}=$(category_status "$category") reason=$(category_reason "$category")"
done
echo ""
echo "QA_RESULT $OVERALL"
echo ""
echo "passed  = the command exited zero on this machine"
echo "failed  = the command exited non-zero"
echo "skipped = not executed because of an explicit opt-in flag; not a pass"
echo "not_run = not selected, or a prerequisite was missing; not a pass"
echo ""
echo "Results are local. GitHub-hosted test CI is intentionally disabled for this"
echo "repository, so nothing above was verified remotely. Quote these exact"
echo "commands and outcomes in the pull request."

json_escape() {
  printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

if [[ "$WRITE_REPORT" -eq 1 && "$DRY_RUN" -eq 0 ]]; then
  mkdir -p "$REPORT_DIR"
  summary_md="$REPORT_DIR/qa-summary.md"
  summary_json="$REPORT_DIR/qa-summary.json"

  {
    echo "# Turing Lab local QA summary"
    echo ""
    echo "- Result: \`$OVERALL\`"
    echo "- Started: $STARTED_AT (UTC)"
    echo "- Revision: \`$GIT_REVISION\`"
    echo "- Preset: \`$PRESET\`"
    echo "- Selected: \`$(echo $SELECTED)\`"
    echo "- Flutter: \`$FLUTTER\`"
    echo "- Dart: \`$DART\`"
    echo ""
    echo "Local execution only. GitHub-hosted test CI is intentionally disabled"
    echo "for this repository; nothing in this file was verified remotely."
    echo ""
    echo "| Category | Status | Reason |"
    echo "| --- | --- | --- |"
    for category in $CATEGORIES; do
      echo "| $category | \`$(category_status "$category")\` | $(category_reason "$category") |"
    done
    echo ""
    echo "| Step | Status | Exit | Seconds | Command |"
    echo "| --- | --- | --- | --- | --- |"
    index=0
    while [[ "$index" -lt "${#STEP_ID[@]}" ]]; do
      echo "| ${STEP_CATEGORY[$index]}.${STEP_ID[$index]} | \`${STEP_STATUS[$index]}\` | ${STEP_EXIT[$index]} | ${STEP_SECONDS[$index]} | \`${STEP_COMMAND[$index]}\` |"
      index=$((index + 1))
    done
  } >"$summary_md"

  {
    echo "{"
    echo "  \"result\": \"$OVERALL\","
    echo "  \"startedAt\": \"$STARTED_AT\","
    echo "  \"revision\": \"$GIT_REVISION\","
    echo "  \"preset\": \"$(json_escape "$PRESET")\","
    echo "  \"selected\": \"$(json_escape "$(echo $SELECTED)")\","
    echo "  \"flutter\": \"$(json_escape "$FLUTTER")\","
    echo "  \"dart\": \"$(json_escape "$DART")\","
    echo "  \"remotelyVerified\": false,"
    echo "  \"categories\": ["
    first=1
    for category in $CATEGORIES; do
      [[ "$first" -eq 1 ]] || echo ","
      first=0
      printf '    {"id": "%s", "status": "%s", "reason": "%s"}' \
        "$category" "$(category_status "$category")" "$(json_escape "$(category_reason "$category")")"
    done
    echo ""
    echo "  ],"
    echo "  \"steps\": ["
    index=0
    first=1
    while [[ "$index" -lt "${#STEP_ID[@]}" ]]; do
      [[ "$first" -eq 1 ]] || echo ","
      first=0
      printf '    {"category": "%s", "id": "%s", "status": "%s", "reason": "%s", "exitCode": "%s", "seconds": "%s", "command": "%s"}' \
        "${STEP_CATEGORY[$index]}" "${STEP_ID[$index]}" "${STEP_STATUS[$index]}" \
        "$(json_escape "${STEP_REASON[$index]}")" "${STEP_EXIT[$index]}" "${STEP_SECONDS[$index]}" \
        "$(json_escape "${STEP_COMMAND[$index]}")"
      index=$((index + 1))
    done
    echo ""
    echo "  ]"
    echo "}"
  } >"$summary_json"

  echo ""
  echo "Summary written to:"
  echo "  $summary_md"
  echo "  $summary_json"
  [[ -n "$LOG_DIR" ]] && echo "  $LOG_DIR/"
fi

if [[ -n "$EXIT_OVERRIDE" ]]; then
  exit "$EXIT_OVERRIDE"
fi

case "$OVERALL" in
plan | passed | skipped) exit "$EXIT_OK" ;;
failed) exit "$EXIT_FAILED" ;;
*) exit "$EXIT_INCOMPLETE" ;;
esac
