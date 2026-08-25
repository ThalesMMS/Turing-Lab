#!/bin/bash

set -eu

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="$REPO_ROOT/linux/scripts/build_linux.sh"
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
    env -u FLUTTER_BIN -u TURING_LAB_FLUTTER_BIN -u TURING_LAB_SKIP_HOST_CHECK \
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
    mkdir -p "$worktree/linux/scripts"
    cp "$SCRIPT" "$worktree/linux/scripts/build_linux.sh"
    chmod +x "$worktree/linux/scripts/build_linux.sh"
    printf '%s\n' "$worktree"
}

WORKTREE="$(prepare_worktree)"
WORKTREE_SCRIPT="$WORKTREE/linux/scripts/build_linux.sh"

if [ "$(uname -s)" != "Linux" ]; then
    run_case wrong_host 1 \
        "Error: Linux builds must run on Linux." \
        FLUTTER_BIN="$FAKE_FLUTTER" \
        "$WORKTREE_SCRIPT"
fi

run_case missing_flutter 1 \
    "Error: Flutter was not found" \
    TURING_LAB_SKIP_HOST_CHECK=1 \
    FLUTTER_BIN=/does/not/exist \
    "$WORKTREE_SCRIPT"

run_case build_failure 17 \
    "Error: flutter build linux --release failed." \
    TURING_LAB_SKIP_HOST_CHECK=1 \
    FAKE_BUILD_EXIT=17 \
    FLUTTER_BIN="$FAKE_FLUTTER" \
    "$WORKTREE_SCRIPT"

run_case build_success 0 \
    "Release Linux bundle copied to" \
    TURING_LAB_SKIP_HOST_CHECK=1 \
    FLUTTER_BIN="$FAKE_FLUTTER" \
    "$WORKTREE_SCRIPT"

COPIED_BIN="$WORKTREE/build/linux/app/turing_lab"
if [ ! -f "$COPIED_BIN" ]; then
    echo "expected copied binary at $COPIED_BIN" >&2
    exit 1
fi
if ! grep -Fxq 'fake-bin' "$COPIED_BIN"; then
    echo "copied binary did not contain the fake payload" >&2
    exit 1
fi
if ! grep -Fxq 'fake-lib' "$WORKTREE/build/linux/app/lib/libflutter_linux_gtk.so"; then
    echo "copied bundle is missing lib/" >&2
    exit 1
fi
if ! grep -Fxq 'fake-data' "$WORKTREE/build/linux/app/data/icudtl.dat"; then
    echo "copied bundle is missing data/" >&2
    exit 1
fi

echo "build_linux.sh smoke tests passed"
