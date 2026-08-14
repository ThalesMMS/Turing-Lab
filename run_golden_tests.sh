#!/bin/bash
# Golden test verification script for Turing Lab.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null || true)"

if [ -z "$REPO_ROOT" ]; then
    REPO_ROOT="$SCRIPT_DIR"
fi

cd "$REPO_ROOT"

if command -v flutter >/dev/null 2>&1; then
    FLUTTER_BIN="$(command -v flutter)"
elif [ -x /opt/homebrew/bin/flutter ]; then
    FLUTTER_BIN="/opt/homebrew/bin/flutter"
else
    FLUTTER_BIN=""
fi

echo "=== Turing Lab Golden Test Suite ==="
echo "Repository: $REPO_ROOT"
echo ""

# Check Flutter availability
if [ -z "$FLUTTER_BIN" ]; then
    export SKIP_GOLDEN_TESTS="true"
    echo "ERROR: Flutter SDK not found"
    echo ""
    echo "Please install Flutter: https://flutter.dev/docs/get-started/install"
    echo "Or ensure Flutter is in your PATH (or available at /opt/homebrew/bin/flutter)"
    echo ""
    echo "SKIP: Flutter not available, golden tests skipped."
    exit 0
fi

echo "Flutter SDK found: $("$FLUTTER_BIN" --version | head -n 1)"
echo ""

# Run pub get
echo "Installing dependencies..."
"$FLUTTER_BIN" pub get
echo ""

# Run golden tests
echo "Running golden tests..."
echo "This verifies the current visual regression suites under test/goldens/."
echo ""
echo "Golden test files:"
echo ""
find test/goldens -maxdepth 2 -type f -name '*goldens_test.dart' | sort
echo ""

# Allow the test command to fail so we can print the summary.
set +e
"$FLUTTER_BIN" test test/goldens/

# Capture exit code
EXIT_CODE=$?
set -e

echo ""
echo "=== Golden Test Results Summary ==="
echo ""

if [ $EXIT_CODE -eq 0 ]; then
    echo "SUCCESS: All golden tests passed."
    echo ""
    echo "No visual regressions were detected in test/goldens/."
else
    echo "GOLDEN TEST FAILURES DETECTED"
    echo ""
    echo "Visual regression detected! Review the output above to identify failures."
    echo ""
    echo "Common Causes:"
    echo "1. UI changes made without updating golden files"
    echo "2. Font rendering differences across platforms"
    echo "3. Screen size or device configuration changes"
    echo ""
    echo "Troubleshooting:"
    echo "1. Review test failures in output above"
    echo "2. Check for visual differences in test/goldens/**/failures/"
    echo "3. If changes are intentional, update golden files:"
    echo "   ./tool/update_goldens.sh"
    echo "4. Review updated golden images before committing"
    echo ""
    echo "Update Workflow:"
    echo "  # Update ALL golden files"
    echo "  ./tool/update_goldens.sh"
    echo ""
    echo "  # Update specific test file"
    echo "  ./tool/update_goldens.sh test/goldens/canvas/automaton_canvas_goldens_test.dart"
    echo ""
    echo "  # Review changes"
    echo "  git diff test/goldens/"
    echo ""
    echo "  # Re-run to verify"
    echo "  ./run_golden_tests.sh"
fi

exit $EXIT_CODE
