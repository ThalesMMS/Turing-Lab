#!/bin/bash

set -eu

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="$REPO_ROOT/web/scripts/build_web.sh"
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
    env -u FLUTTER_BIN -u TURING_LAB_FLUTTER_BIN -u WEB_BASE_HREF \
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
    mkdir -p "$worktree/web/scripts" "$worktree/docs"
    mkdir -p "$worktree/docs/assets/screenshots"
    cp "$SCRIPT" "$worktree/web/scripts/build_web.sh"
    chmod +x "$worktree/web/scripts/build_web.sh"
    printf '<html>support</html>\n' >"$worktree/docs/support.html"
    printf '<html>privacy</html>\n' >"$worktree/docs/privacy.html"
    printf '<html>marketing</html>\n' >"$worktree/docs/marketing.html"
    printf '# apple privacy\n' >"$worktree/docs/APP_PRIVACY_APPLE.md"
    printf 'site css\n' >"$worktree/docs/assets/site.css"
    printf 'marketing icon\n' >"$worktree/docs/assets/icon-192.png"
    printf 'social preview\n' >"$worktree/docs/assets/social-preview.png"
    printf 'fsa screenshot\n' >"$worktree/docs/assets/screenshots/fsa.webp"
    printf '%s\n' "$worktree"
}

WORKTREE="$(prepare_worktree)"
WORKTREE_SCRIPT="$WORKTREE/web/scripts/build_web.sh"

run_case missing_flutter 1 \
    "Error: Flutter was not found" \
    FLUTTER_BIN=/does/not/exist \
    "$WORKTREE_SCRIPT"

run_case build_failure 17 \
    "Error: flutter build web --release failed." \
    FAKE_BUILD_EXIT=17 \
    FLUTTER_BIN="$FAKE_FLUTTER" \
    "$WORKTREE_SCRIPT"

run_case build_success 0 \
    "Release web build ready at" \
    FLUTTER_BIN="$FAKE_FLUTTER" \
    "$WORKTREE_SCRIPT"

INDEX="$WORKTREE/build/web/index.html"
if [ ! -f "$INDEX" ]; then
    echo "expected web index at $INDEX" >&2
    exit 1
fi
if ! grep -Fxq 'fake-web' "$INDEX"; then
    echo "web index did not contain the fake payload" >&2
    exit 1
fi
if [ ! -f "$WORKTREE/build/web/support.html" ]; then
    echo "expected support.html in the web build" >&2
    exit 1
fi
if [ ! -f "$WORKTREE/build/web/privacy.html" ]; then
    echo "expected privacy.html in the web build" >&2
    exit 1
fi
if [ ! -f "$WORKTREE/build/web/marketing.html" ]; then
    echo "expected marketing.html in the web build" >&2
    exit 1
fi
if [ ! -f "$WORKTREE/build/web/APP_PRIVACY_APPLE.md" ]; then
    echo "expected APP_PRIVACY_APPLE.md in the web build" >&2
    exit 1
fi
if [ ! -f "$WORKTREE/build/web/assets/site.css" ]; then
    echo "expected marketing site stylesheet in the web build" >&2
    exit 1
fi
if [ ! -f "$WORKTREE/build/web/assets/icon-192.png" ]; then
    echo "expected marketing icon in the web build" >&2
    exit 1
fi
if [ ! -f "$WORKTREE/build/web/assets/social-preview.png" ]; then
    echo "expected social preview in the web build" >&2
    exit 1
fi
if [ ! -f "$WORKTREE/build/web/assets/screenshots/fsa.webp" ]; then
    echo "expected marketing screenshot in the web build" >&2
    exit 1
fi
if [ ! -f "$WORKTREE/build/web/.nojekyll" ]; then
    echo "expected .nojekyll in the web build" >&2
    exit 1
fi

echo "build_web.sh smoke tests passed"
