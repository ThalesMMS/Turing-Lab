#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: tool/update_goldens.sh [--all] [--canvas] [--dialogs] [--pages] [--simulation] [path ...]

Updates Flutter golden baselines with `flutter test --update-goldens`.

Examples:
  tool/update_goldens.sh
  tool/update_goldens.sh --pages
  tool/update_goldens.sh test/goldens/canvas/automaton_canvas_goldens_test.dart

Environment:
  FLUTTER_BIN=/path/to/flutter        Override Flutter discovery.
  UPDATE_GOLDENS_SKIP_PUB_GET=1       Skip `flutter pub get`.
USAGE
}

resolve_flutter() {
  if [[ -n "${FLUTTER_BIN:-}" ]]; then
    echo "$FLUTTER_BIN"
  elif command -v flutter >/dev/null 2>&1; then
    command -v flutter
  elif [[ -x /opt/homebrew/bin/flutter ]]; then
    echo "/opt/homebrew/bin/flutter"
  else
    return 1
  fi
}

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if ! FLUTTER_BIN="$(resolve_flutter)"; then
  echo "ERROR: Flutter SDK not found." >&2
  echo "Set FLUTTER_BIN=/path/to/flutter or add flutter to PATH." >&2
  exit 1
fi

targets=()

if [[ $# -eq 0 ]]; then
  targets=("test/goldens/")
else
  for arg in "$@"; do
    case "$arg" in
      --all)
        targets+=("test/goldens/")
        ;;
      --canvas)
        targets+=("test/goldens/canvas/")
        ;;
      --dialogs)
        targets+=("test/goldens/dialogs/")
        ;;
      --pages)
        targets+=("test/goldens/pages/")
        ;;
      --simulation)
        targets+=("test/goldens/simulation/")
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      -*)
        echo "ERROR: Unknown option: $arg" >&2
        usage >&2
        exit 2
        ;;
      *)
        targets+=("$arg")
        ;;
    esac
  done
fi

echo "=== Turing Lab Golden Baseline Update ==="
echo "Repository: $ROOT_DIR"
echo "Flutter: $("$FLUTTER_BIN" --version | head -n 1)"
echo ""
echo "Targets:"
printf '  %s\n' "${targets[@]}"
echo ""

if [[ "${UPDATE_GOLDENS_SKIP_PUB_GET:-}" != "1" ]]; then
  "$FLUTTER_BIN" pub get
  echo ""
fi

"$FLUTTER_BIN" test --update-goldens "${targets[@]}"

echo ""
echo "Review updated golden files before committing:"
echo "  git diff --stat -- test/goldens/"
echo "  git status --short -- test/goldens/"
echo "  ./run_golden_tests.sh"
