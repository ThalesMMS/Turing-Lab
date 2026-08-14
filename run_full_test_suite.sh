#!/bin/bash
# Full test suite runner for Turing Lab.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null || true)"

if [ -z "$REPO_ROOT" ]; then
    REPO_ROOT="$SCRIPT_DIR"
fi

cd "$REPO_ROOT"

if [ -n "${TURING_LAB_FLUTTER_BIN:-}" ]; then
    FLUTTER_BIN="$TURING_LAB_FLUTTER_BIN"
elif command -v flutter >/dev/null 2>&1; then
    FLUTTER_BIN="$(command -v flutter)"
elif [ -x /opt/homebrew/bin/flutter ]; then
    FLUTTER_BIN="/opt/homebrew/bin/flutter"
else
    FLUTTER_BIN=""
fi

echo "=== Turing Lab Full Test Suite ==="
echo "Repository: $REPO_ROOT"
echo ""

# Check Flutter availability
if [ -z "$FLUTTER_BIN" ] || [ ! -x "$FLUTTER_BIN" ]; then
    echo "ERROR: Flutter SDK not found"
    echo ""
    echo "Please install Flutter: https://flutter.dev/docs/get-started/install"
    echo "Or ensure Flutter is in your PATH (or available at /opt/homebrew/bin/flutter)"
    echo ""
    if [ "${ALLOW_MISSING_FLUTTER:-0}" = "1" ]; then
        echo "QA_STATUS flutter_analyze=skipped reason=missing_flutter"
        echo "QA_STATUS flutter_test=skipped reason=missing_flutter"
        echo "QA_RESULT skipped"
        exit 0
    fi
    echo "QA_STATUS flutter_analyze=failed reason=missing_flutter"
    echo "QA_STATUS flutter_test=failed reason=missing_flutter"
    echo "QA_RESULT failed reason=missing_flutter"
    exit 127
else
    echo "Flutter SDK found: $("$FLUTTER_BIN" --version | head -n 1)"
fi
echo ""

EXIT_CODE=0
ANALYZE_STATUS="skipped"
TEST_STATUS="skipped"

# Run pub get
echo "Installing dependencies..."
set +e
"$FLUTTER_BIN" pub get
PUB_GET_EXIT_CODE=$?
set -e
echo ""

if [ $PUB_GET_EXIT_CODE -ne 0 ]; then
    echo "QA_STATUS flutter_pub_get=failed exit_code=$PUB_GET_EXIT_CODE"
    echo "QA_STATUS flutter_analyze=skipped reason=dependency_failure"
    echo "QA_STATUS flutter_test=skipped reason=dependency_failure"
    echo "QA_RESULT failed"
    exit $PUB_GET_EXIT_CODE
fi
echo "QA_STATUS flutter_pub_get=passed exit_code=0"

echo "Running static analysis..."
echo ""

echo "Running full test suite..."
echo "This may take several minutes..."
echo "See AGENTS.md for current test breakdown and expectations."
echo ""

set +e
"$FLUTTER_BIN" analyze
ANALYZE_EXIT_CODE=$?
"$FLUTTER_BIN" test
TEST_EXIT_CODE=$?
set -e

if [ $ANALYZE_EXIT_CODE -eq 0 ]; then
    ANALYZE_STATUS="passed"
else
    ANALYZE_STATUS="failed"
    EXIT_CODE=$ANALYZE_EXIT_CODE
fi
if [ $TEST_EXIT_CODE -eq 0 ]; then
    TEST_STATUS="passed"
else
    TEST_STATUS="failed"
    if [ $EXIT_CODE -eq 0 ]; then
        EXIT_CODE=$TEST_EXIT_CODE
    fi
fi

echo ""
echo "=== Test Results Summary ==="
echo ""

echo "QA_STATUS flutter_analyze=$ANALYZE_STATUS exit_code=$ANALYZE_EXIT_CODE"
echo "QA_STATUS flutter_test=$TEST_STATUS exit_code=$TEST_EXIT_CODE"

if [ $EXIT_CODE -eq 0 ]; then
    echo "QA_RESULT passed"
    echo "SUCCESS: Test command completed without failures."
    echo ""
    echo "See AGENTS.md for current test breakdown and expectations."
else
    echo "QA_RESULT failed"
    echo "TEST FAILURES DETECTED"
    echo ""
    echo "Review the output above to identify failing tests."
    echo ""
    echo "See AGENTS.md for current test breakdown and expectations."
    echo ""
    echo "Troubleshooting:"
    echo "1. Verify failures match the known baseline in AGENTS.md"
    echo "2. Check for new regressions outside the documented failing suites"
    echo "3. Run specific test categories:"
    echo "   - Core algorithms: $FLUTTER_BIN test test/unit/"
    echo "   - Widget tests: $FLUTTER_BIN test test/widget/"
    echo "   - Integration tests: $FLUTTER_BIN test test/integration/"
    echo "4. Run static analysis: $FLUTTER_BIN analyze"
fi

exit $EXIT_CODE
