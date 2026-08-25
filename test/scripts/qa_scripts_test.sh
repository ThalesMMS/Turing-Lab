#!/bin/bash

set -eu

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FAKE_FLUTTER="$REPO_ROOT/test/scripts/fixtures/fake_flutter.sh"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

run_case() {
    name="$1"
    expected_exit="$2"
    expected_text="$3"
    shift 3

    output="$TMP_DIR/$name.log"
    set +e
    env "$@" >"$output" 2>&1
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

run_case static_missing 127 \
    "QA_STATUS static_analysis=failed reason=missing_flutter" \
    TURING_LAB_FLUTTER_BIN=/does/not/exist "$REPO_ROOT/run_static_analysis.sh"
run_case static_missing_allowed 0 \
    "QA_STATUS static_analysis=skipped reason=missing_flutter" \
    ALLOW_MISSING_FLUTTER=1 TURING_LAB_FLUTTER_BIN=/does/not/exist \
    "$REPO_ROOT/run_static_analysis.sh"
run_case static_failure 23 \
    "QA_STATUS static_analysis=failed exit_code=23" \
    FAKE_ANALYZE_EXIT=23 TURING_LAB_FLUTTER_BIN="$FAKE_FLUTTER" \
    "$REPO_ROOT/run_static_analysis.sh"
run_case static_success 0 "QA_STATUS static_analysis=passed" \
    TURING_LAB_FLUTTER_BIN="$FAKE_FLUTTER" "$REPO_ROOT/run_static_analysis.sh"

run_case suite_missing 127 "QA_RESULT failed reason=missing_flutter" \
    TURING_LAB_FLUTTER_BIN=/does/not/exist "$REPO_ROOT/run_full_test_suite.sh"
run_case suite_missing_allowed 0 "QA_RESULT skipped" \
    ALLOW_MISSING_FLUTTER=1 TURING_LAB_FLUTTER_BIN=/does/not/exist \
    "$REPO_ROOT/run_full_test_suite.sh"
run_case suite_pub_failure 22 \
    "QA_STATUS flutter_test=skipped reason=dependency_failure" \
    FAKE_PUB_EXIT=22 TURING_LAB_FLUTTER_BIN="$FAKE_FLUTTER" \
    "$REPO_ROOT/run_full_test_suite.sh"
run_case suite_analyzer_failure 23 \
    "QA_STATUS flutter_analyze=failed exit_code=23" \
    FAKE_ANALYZE_EXIT=23 TURING_LAB_FLUTTER_BIN="$FAKE_FLUTTER" \
    "$REPO_ROOT/run_full_test_suite.sh"
run_case suite_test_failure 24 \
    "QA_STATUS flutter_test=failed exit_code=24" \
    FAKE_TEST_EXIT=24 TURING_LAB_FLUTTER_BIN="$FAKE_FLUTTER" \
    "$REPO_ROOT/run_full_test_suite.sh"
run_case suite_success 0 "QA_RESULT passed" \
    TURING_LAB_FLUTTER_BIN="$FAKE_FLUTTER" "$REPO_ROOT/run_full_test_suite.sh"

bash "$REPO_ROOT/test/scripts/local_qa_test.sh"

echo "QA script smoke tests passed"
