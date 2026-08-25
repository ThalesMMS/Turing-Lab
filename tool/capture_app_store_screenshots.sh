#!/usr/bin/env bash
#
# capture_app_store_screenshots.sh
# Turing Lab
#
# Local-only entry point for App Store screenshot capture. It resolves the
# Flutter and Dart toolchain, makes sure package resolution is current, and
# hands the selection to tool/app_store/app_store_capture_cli.dart, which
# drives one isolated `flutter test` process per slot, writes the run manifest
# and validates the resulting directory.
#
# This pipeline never runs in CI and is never discovered by `flutter test`.
#
#   tool/capture_app_store_screenshots.sh --help
#   tool/capture_app_store_screenshots.sh --all --output build/screenshots/candidate
#   tool/capture_app_store_screenshots.sh --profile iphone-6.9 --screen fsa --locale en
#
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FLUTTER_BIN="${FLUTTER_BIN:-$(command -v flutter || echo /opt/homebrew/bin/flutter)}"
DART_BIN="${DART_BIN:-$(dirname "$FLUTTER_BIN")/dart}"
CLI_ENTRY="tool/app_store/app_store_capture_cli.dart"

if [[ ! -x "$FLUTTER_BIN" ]]; then
  echo "Flutter SDK not found at '$FLUTTER_BIN'. Set FLUTTER_BIN." >&2
  exit 1
fi

if [[ ! -x "$DART_BIN" ]]; then
  DART_BIN="$(command -v dart || true)"
fi

if [[ -z "$DART_BIN" || ! -x "$DART_BIN" ]]; then
  echo "Dart SDK not found. Set DART_BIN to the dart executable." >&2
  exit 1
fi

if [[ -n "${TIMEOUT_SECONDS:-}" ]]; then
  echo "TIMEOUT_SECONDS is no longer honored; pass --timeout <seconds> instead." >&2
  exit 64
fi

skip_pub_get=0
wants_help=0
for arg in "$@"; do
  case "$arg" in
    --skip-pub-get) skip_pub_get=1 ;;
    -h|--help) wants_help=1 ;;
  esac
done

cd "$ROOT_DIR"

if [[ ! -f .dart_tool/package_config.json ]]; then
  skip_pub_get=0
elif [[ "$wants_help" -eq 1 ]]; then
  skip_pub_get=1
fi

if [[ "$skip_pub_get" -eq 0 ]]; then
  "$FLUTTER_BIN" pub get >/dev/null
fi

export FLUTTER_BIN
export APP_STORE_REPO_ROOT="$ROOT_DIR"

exec "$DART_BIN" run "$CLI_ENTRY" "$@"
