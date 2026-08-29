#!/bin/bash
#
# local_qa_test.sh
# Turing Lab
#
# Smoke tests for tool/qa.sh, the canonical local QA entrypoint. Every case
# drives the script with the fake Flutter/Dart fixtures so the assertions are
# about the reporting contract - fail-closed on a missing toolchain, and a
# per-category `passed` / `failed` / `skipped` / `not_run` verdict - rather than
# about the real suites.

set -eu

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
QA="$REPO_ROOT/tool/qa.sh"
FAKE_FLUTTER="$REPO_ROOT/test/scripts/fixtures/fake_flutter.sh"
FAKE_DART="$REPO_ROOT/test/scripts/fixtures/fake_dart.sh"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

if [ ! -x "$QA" ]; then
    echo "expected $QA to exist and be executable" >&2
    exit 1
fi

CASE_INDEX=0

# run_case <name> <expected-exit> <expected-substring> -- <argv...>
# Environment assignments may precede the command via `env`.
run_case() {
    name="$1"
    expected_exit="$2"
    expected_text="$3"
    shift 3

    CASE_INDEX=$((CASE_INDEX + 1))
    output="$TMP_DIR/$name.log"
    set +e
    "$@" >"$output" 2>&1
    actual_exit=$?
    set -e

    if [ "$actual_exit" -ne "$expected_exit" ]; then
        echo "$name: expected exit $expected_exit, got $actual_exit" >&2
        cat "$output" >&2
        exit 1
    fi
    if ! grep -Fq "$expected_text" "$output"; then
        echo "$name: missing output: $expected_text" >&2
        cat "$output" >&2
        exit 1
    fi
}

assert_output_contains() {
    name="$1"
    expected_text="$2"
    if ! grep -Fq "$expected_text" "$TMP_DIR/$name.log"; then
        echo "$name: missing output: $expected_text" >&2
        cat "$TMP_DIR/$name.log" >&2
        exit 1
    fi
}

fake_qa() {
    env FAKE_PUB_EXIT="${FAKE_PUB_EXIT:-0}" \
        FAKE_ANALYZE_EXIT="${FAKE_ANALYZE_EXIT:-0}" \
        FAKE_TEST_EXIT="${FAKE_TEST_EXIT:-0}" \
        FAKE_FORMAT_EXIT="${FAKE_FORMAT_EXIT:-0}" \
        "$QA" --flutter "$FAKE_FLUTTER" --dart "$FAKE_DART" --skip-l10n "$@"
}

# --- Usage surface -----------------------------------------------------------

run_case help 0 "Canonical local QA entrypoint" "$QA" --help
assert_output_contains help "127  required Flutter/Dart toolchain unavailable"

run_case list 0 "prereqs format analyze unit widget integration" "$QA" --list

run_case unknown_option 64 "unknown option: --nope" "$QA" --nope
run_case unknown_category 64 "unknown category: nope" "$QA" --only nope
run_case unknown_preset 64 "unknown preset: nope" "$QA" --preset nope
run_case unknown_widget_scope 64 "unknown --widget-scope: partial" "$QA" --widget-scope partial

# --- Fail closed on a missing toolchain (issue #195 contract) ----------------

run_case missing_toolchain 127 "QA_STATUS unit=failed reason=missing_flutter" \
    "$QA" --flutter /does/not/exist --dart /does/not/exist --only unit --no-report
assert_output_contains missing_toolchain "QA_RESULT failed"

run_case missing_toolchain_opt_in 0 "QA_STATUS unit=skipped reason=missing_flutter_opt_in" \
    "$QA" --flutter /does/not/exist --dart /does/not/exist --only unit \
    --allow-missing-toolchain --no-report
assert_output_contains missing_toolchain_opt_in "QA_RESULT skipped"

run_case missing_toolchain_env_opt_in 0 "QA_RESULT skipped" \
    env ALLOW_MISSING_FLUTTER=1 "$QA" --flutter /does/not/exist --dart /does/not/exist \
    --only unit --no-report

# --- Category verdicts -------------------------------------------------------

run_case analyze_pass 0 "QA_STATUS analyze=passed" fake_qa --only analyze --no-report
assert_output_contains analyze_pass "QA_RESULT passed"

run_case analyze_fail 1 "QA_STATUS analyze=failed reason=command_failed" \
    env FAKE_ANALYZE_EXIT=23 "$QA" --flutter "$FAKE_FLUTTER" --dart "$FAKE_DART" \
    --skip-l10n --only analyze --no-report
assert_output_contains analyze_fail "QA_RESULT failed"
assert_output_contains analyze_fail "exit_code=23"

run_case unit_fail 1 "QA_STATUS unit=failed reason=command_failed" \
    env FAKE_TEST_EXIT=24 "$QA" --flutter "$FAKE_FLUTTER" --dart "$FAKE_DART" \
    --skip-l10n --only unit --no-report

run_case properties_pass 0 "QA_STATUS properties=passed" \
    fake_qa --only properties --no-report
assert_output_contains properties_pass "tool/hard_edge_cases.dart run --profile qa"

run_case properties_fail 1 "QA_STATUS properties=failed reason=command_failed" \
    env FAKE_PROPERTIES_EXIT=25 "$QA" --flutter "$FAKE_FLUTTER" --dart "$FAKE_DART" \
    --skip-l10n --only properties --no-report
assert_output_contains properties_fail "exit_code=25"

run_case code_excludes_properties 0 "QA_STATUS properties=not_run reason=not_selected" \
    fake_qa --preset code --base HEAD --no-report

run_case pub_get_fail 1 "QA_STATUS prereqs=failed reason=command_failed" \
    env FAKE_PUB_EXIT=22 "$QA" --flutter "$FAKE_FLUTTER" --dart "$FAKE_DART" \
    --skip-l10n --only analyze --no-report

run_case format_fail 1 "QA_STATUS format=failed reason=command_failed" \
    env FAKE_FORMAT_EXIT=31 "$QA" --flutter "$FAKE_FLUTTER" --dart "$FAKE_DART" \
    --skip-l10n --format-all --only format --no-report
assert_output_contains format_fail \
    "QA_STATUS format.native-shell-localization=passed"
assert_output_contains format_fail \
    "python3 test/tool/native_shell_localization_contract_test.py"
assert_output_contains format_fail \
    "QA_STATUS format.pseudo-localization=passed"
assert_output_contains format_fail \
    "run tool/localization/check_pseudo_localization.dart"
assert_output_contains format_fail \
    "QA_STATUS format.educational-content=passed"
assert_output_contains format_fail \
    "python3 tool/check_educational_content.py"
assert_output_contains format_fail \
    "QA_STATUS format.localization-validator-tests=passed"
assert_output_contains format_fail \
    "python3 -m unittest discover -s test/tool -p '*_test.py'"

NO_REPORT_DIR="$TMP_DIR/no-report"
run_case format_no_report 0 "QA_STATUS format=passed" \
    fake_qa --only format --base HEAD --report-dir "$NO_REPORT_DIR" --no-report
if [ -e "$NO_REPORT_DIR" ]; then
    echo "did not expect format artifacts at $NO_REPORT_DIR with --no-report" >&2
    exit 1
fi

FORMAT_REPORT_DIR="$TMP_DIR/format-report"
run_case format_report 0 "QA_STATUS format.arb-resources=passed" \
    fake_qa --only format --base HEAD --report-dir "$FORMAT_REPORT_DIR"
if [ ! -f "$FORMAT_REPORT_DIR/arb-resources.json" ]; then
    echo "expected ARB resource report at $FORMAT_REPORT_DIR/arb-resources.json" >&2
    exit 1
fi
if [ ! -f "$FORMAT_REPORT_DIR/domain-message-prose.json" ]; then
    echo "expected domain-message report at $FORMAT_REPORT_DIR/domain-message-prose.json" >&2
    exit 1
fi
if command -v python3 >/dev/null 2>&1; then
    python3 -c "import json,sys; report=json.load(open(sys.argv[1])); assert report['status'] == 'passed'" \
        "$FORMAT_REPORT_DIR/arb-resources.json"
    python3 -c "import json,sys; report=json.load(open(sys.argv[1])); assert report['violationCount'] == 0" \
        "$FORMAT_REPORT_DIR/domain-message-prose.json"
fi

# --- Skipped is never a pass -------------------------------------------------

run_case explicit_skip 0 "QA_STATUS analyze=skipped reason=explicit_opt_in" \
    fake_qa --only analyze,unit --skip analyze --no-report

run_case skip_l10n 0 "QA_STATUS prereqs.l10n=skipped reason=explicit_opt_in" \
    fake_qa --only analyze --no-report

run_case skip_graphview_benchmarks 0 "QA_STATUS graphview.benchmarks=skipped reason=explicit_opt_in" \
    fake_qa --only graphview --skip-graphview-benchmarks --no-report

# --- Focused subsets leave the rest explicitly not run -----------------------

run_case focused_subset 0 "QA_STATUS widget=not_run reason=not_selected" \
    fake_qa --only unit --no-report
assert_output_contains focused_subset "QA_STATUS unit=passed"
assert_output_contains focused_subset "QA_STATUS golden=not_run reason=not_selected"

SHADOW_FIND_DIR="$TMP_DIR/shadow-find"
mkdir -p "$SHADOW_FIND_DIR"
printf '#!/bin/sh\nexit 99\n' >"$SHADOW_FIND_DIR/find"
chmod +x "$SHADOW_FIND_DIR/find"
run_case preset_grammar 0 "QA_STATUS integration=not_run reason=not_selected" \
    env PATH="$SHADOW_FIND_DIR:$PATH" "$QA" --flutter "$FAKE_FLUTTER" \
    --dart "$FAKE_DART" --skip-l10n --preset grammar --no-report
assert_output_contains preset_grammar "grammar_cnf_transformer_test.dart"

run_case preset_tm 0 "QA_STATUS unit=passed" fake_qa --preset tm --no-report
assert_output_contains preset_tm "tm_validation_test.dart"

run_case preset_localization 0 "QA_STATUS responsive=passed" \
    fake_qa --preset localization --base HEAD --no-report
assert_output_contains preset_localization "QA_STATUS golden=not_run reason=not_selected"
assert_output_contains preset_localization "QA_STATUS graphview=not_run reason=not_selected"

run_case preset_canvas 0 "QA_STATUS graphview=passed" \
    fake_qa --preset canvas --no-report
assert_output_contains preset_canvas "automaton_canvas_goldens_test.dart"

run_case default_widget_scope 0 "Widget suites (scope: all)" \
    fake_qa --only widget --no-report
assert_output_contains default_widget_scope "test/widget/"

# --- Unmet prerequisites are incomplete, not a pass --------------------------

run_case apple_without_device 2 "QA_STATUS apple.l2-journeys=not_run" \
    fake_qa --only apple --no-report
assert_output_contains apple_without_device "QA_STATUS apple.l3-manual=not_run reason=manual_only"
assert_output_contains apple_without_device "QA_RESULT incomplete"

# The Apple category can never report `passed`: level L3 is the manual release
# matrix, which automation is not allowed to close.
run_case apple_with_device 2 "QA_STATUS apple.l2-journeys=passed" \
    fake_qa --only apple --apple-target macos --apple-device macos --no-report
assert_output_contains apple_with_device "APPLE_RELEASE_TARGET=macos"
assert_output_contains apple_with_device "QA_STATUS apple=not_run reason=manual_only"

run_case apple_opted_out 0 "QA_STATUS apple=skipped reason=explicit_opt_in" \
    fake_qa --only apple,unit --skip apple --no-report

# --- Plan mode ---------------------------------------------------------------

run_case dry_run 0 "QA_RESULT plan" "$QA" --preset all --dry-run
assert_output_contains dry_run "PLAN ONLY"
assert_output_contains dry_run "properties.framework"

# --- Summary artifact --------------------------------------------------------

REPORT_DIR="$TMP_DIR/report"
run_case summary_artifact 0 "QA_RESULT passed" \
    fake_qa --only analyze --report-dir "$REPORT_DIR"

for artifact in "$REPORT_DIR/qa-summary.md" "$REPORT_DIR/qa-summary.json"; do
    if [ ! -f "$artifact" ]; then
        echo "expected summary artifact at $artifact" >&2
        exit 1
    fi
done
if ! grep -Fq '"remotelyVerified": false' "$REPORT_DIR/qa-summary.json"; then
    echo "qa-summary.json must record that results were not remotely verified" >&2
    exit 1
fi
if ! grep -Fq '| analyze | `passed` |' "$REPORT_DIR/qa-summary.md"; then
    echo "qa-summary.md must record a per-category verdict" >&2
    exit 1
fi
if [ ! -f "$REPORT_DIR/logs/analyze.root.log" ]; then
    echo "expected a per-step log at $REPORT_DIR/logs/analyze.root.log" >&2
    exit 1
fi
if command -v python3 >/dev/null 2>&1; then
    python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$REPORT_DIR/qa-summary.json"
fi

# --- The entrypoint never re-records goldens or writes approved screenshots ---

if grep -q -- '--update-goldens' "$QA"; then
    echo "tool/qa.sh must never re-record golden baselines" >&2
    exit 1
fi
if grep -q 'screenshots/app_store' "$QA"; then
    echo "tool/qa.sh must never target the tracked screenshots/app_store tree" >&2
    exit 1
fi

echo "local QA entrypoint smoke tests passed ($CASE_INDEX cases)"
