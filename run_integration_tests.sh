#!/bin/bash
# Integration test runner for Turing Lab.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null || true)"

if [ -z "$REPO_ROOT" ]; then
    REPO_ROOT="$SCRIPT_DIR"
fi

if command -v flutter >/dev/null 2>&1; then
    FLUTTER_BIN="$(command -v flutter)"
elif [ -x /opt/homebrew/bin/flutter ]; then
    FLUTTER_BIN="/opt/homebrew/bin/flutter"
else
    FLUTTER_BIN=""
fi

echo "========================================="
echo "Turing Lab Integration Tests"
echo "========================================="
echo "Repository: $REPO_ROOT"
echo ""

cd "$REPO_ROOT"

# Verify Flutter is available
if [ -z "$FLUTTER_BIN" ]; then
    export SKIP_INTEGRATION_TESTS="true"
    echo "ERROR: Flutter SDK not found in PATH"
    echo ""
    echo "Please install Flutter or add it to your PATH:"
    echo "  export PATH=\"\$PATH:/path/to/flutter/bin\""
    echo ""
    echo "Or ensure it is available at /opt/homebrew/bin/flutter"
    echo ""
    echo "SKIP: Flutter not available, integration tests skipped."
    exit 0
fi

echo "Flutter SDK found: $("$FLUTTER_BIN" --version | head -n1)"
echo ""

# Ensure dependencies are installed
echo "Installing dependencies..."
"$FLUTTER_BIN" pub get
echo ""

# Run the integration tests
echo "Running integration tests..."
echo ""
echo "Command: $FLUTTER_BIN test test/integration/io/"
echo "========================================="
echo ""

set +e
"$FLUTTER_BIN" test test/integration/io/
TEST_EXIT_CODE=$?
set -e

echo ""
echo "========================================="
if [ $TEST_EXIT_CODE -eq 0 ]; then
    echo "SUCCESS: All integration tests passed."
else
    echo "FAILURE: Some integration tests failed."
    echo ""
    echo "Next steps:"
    echo "  1. Review the test failures above"
    echo "  2. Fix any issues in the affected implementation"
    echo "  3. Re-run this script"
fi

echo "========================================="
exit $TEST_EXIT_CODE
