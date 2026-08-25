#!/bin/bash

set -eu

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="$REPO_ROOT/android/scripts/build_apk.sh"
FAKE_FLUTTER="$REPO_ROOT/test/scripts/fixtures/fake_flutter.sh"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

if [ ! -f "$SCRIPT" ]; then
    echo "expected $SCRIPT to exist" >&2
    exit 1
fi

run_case() {
    name="$1"
    expected_exit="$2"
    expected_text="$3"
    shift 3

    output="$TMP_DIR/$name.log"
    set +e
    env -u TURING_LAB_KEYSTORE_PASSWORD -u TURING_LAB_KEY_ALIAS -u TURING_LAB_KEY_PASSWORD \
        -u TURING_LAB_KEYSTORE_PATH -u FLUTTER_BIN -u TURING_LAB_FLUTTER_BIN \
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

prepare_worktree() {
    worktree="$TMP_DIR/worktree"
    rm -rf "$worktree"
    mkdir -p "$worktree/android/scripts"
    cp "$SCRIPT" "$worktree/android/scripts/build_apk.sh"
    chmod +x "$worktree/android/scripts/build_apk.sh"
    printf '%s\n' "$worktree"
}

WORKTREE="$(prepare_worktree)"
WORKTREE_SCRIPT="$WORKTREE/android/scripts/build_apk.sh"

run_case missing_flutter 1 \
    "Error: Flutter was not found" \
    FLUTTER_BIN=/does/not/exist \
    TURING_LAB_KEYSTORE_PASSWORD=secret \
    TURING_LAB_KEY_ALIAS=upload \
    TURING_LAB_KEY_PASSWORD=secret \
    "$WORKTREE_SCRIPT"

run_case missing_signing 1 \
    "Error: Release signing is not configured." \
    FLUTTER_BIN="$FAKE_FLUTTER" \
    "$WORKTREE_SCRIPT"

run_case build_failure 17 \
    "Error: flutter build apk --release failed." \
    FAKE_BUILD_EXIT=17 \
    FLUTTER_BIN="$FAKE_FLUTTER" \
    TURING_LAB_KEYSTORE_PASSWORD=secret \
    TURING_LAB_KEY_ALIAS=upload \
    TURING_LAB_KEY_PASSWORD=secret \
    "$WORKTREE_SCRIPT"

run_case build_success 0 \
    "Release APK copied to" \
    FLUTTER_BIN="$FAKE_FLUTTER" \
    TURING_LAB_KEYSTORE_PASSWORD=secret \
    TURING_LAB_KEY_ALIAS=upload \
    TURING_LAB_KEY_PASSWORD=secret \
    "$WORKTREE_SCRIPT"

COPIED_APK="$WORKTREE/build/android/app/turing-lab-release.apk"
if [ ! -f "$COPIED_APK" ]; then
    echo "expected copied APK at $COPIED_APK" >&2
    exit 1
fi
if ! grep -Fxq 'fake-apk' "$COPIED_APK"; then
    echo "copied APK did not contain the fake payload" >&2
    exit 1
fi

echo "build_apk.sh smoke tests passed"
