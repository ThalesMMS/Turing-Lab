#!/usr/bin/env bash
# Builds a signed Android release APK and copies it to a stable output path.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANDROID_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_ROOT="$(cd "${ANDROID_DIR}/.." && pwd)"
APK_SOURCE="${APK_SOURCE:-${REPO_ROOT}/build/app/outputs/flutter-apk/app-release.apk}"
APK_OUTPUT="${APK_OUTPUT:-${REPO_ROOT}/build/android/app/turing-lab-release.apk}"
KEY_PROPERTIES_FILE="${ANDROID_DIR}/key.properties"

discover_flutter_bin() {
  if [[ -n "${FLUTTER_BIN:-}" ]]; then
    if [[ -x "${FLUTTER_BIN}" ]]; then
      return 0
    fi
    echo "Error: Flutter was not found at FLUTTER_BIN='${FLUTTER_BIN}'." >&2
    exit 1
  fi

  if [[ -n "${TURING_LAB_FLUTTER_BIN:-}" ]]; then
    FLUTTER_BIN="${TURING_LAB_FLUTTER_BIN}"
    if [[ -x "${FLUTTER_BIN}" ]]; then
      return 0
    fi
    echo "Error: Flutter was not found at TURING_LAB_FLUTTER_BIN='${FLUTTER_BIN}'." >&2
    exit 1
  fi

  if command -v flutter >/dev/null 2>&1; then
    FLUTTER_BIN="$(command -v flutter)"
    return 0
  fi

  if [[ -x "/opt/homebrew/bin/flutter" ]]; then
    FLUTTER_BIN="/opt/homebrew/bin/flutter"
    return 0
  fi

  if [[ -x "/usr/local/bin/flutter" ]]; then
    FLUTTER_BIN="/usr/local/bin/flutter"
    return 0
  fi

  echo "Error: Flutter was not found on PATH or in the known default locations." >&2
  echo "Set FLUTTER_BIN to your local Flutter binary before running this script." >&2
  exit 1
}

require_release_signing() {
  if [[ -f "${KEY_PROPERTIES_FILE}" ]]; then
    return 0
  fi

  if [[ -n "${TURING_LAB_KEYSTORE_PASSWORD:-}" &&
        -n "${TURING_LAB_KEY_ALIAS:-}" &&
        -n "${TURING_LAB_KEY_PASSWORD:-}" ]]; then
    return 0
  fi

  echo "Error: Release signing is not configured." >&2
  echo "Run ./android/scripts/create_key_properties.sh or export TURING_LAB_KEYSTORE_PASSWORD, TURING_LAB_KEY_ALIAS, and TURING_LAB_KEY_PASSWORD." >&2
  exit 1
}

discover_flutter_bin
require_release_signing

echo "==> flutter pub get"
(cd "${REPO_ROOT}" && "${FLUTTER_BIN}" pub get)

echo "==> flutter build apk --release"
set +e
(cd "${REPO_ROOT}" && "${FLUTTER_BIN}" build apk --release)
BUILD_EXIT=$?
set -e
if [[ "${BUILD_EXIT}" -ne 0 ]]; then
  echo "Error: flutter build apk --release failed." >&2
  exit "${BUILD_EXIT}"
fi

if [[ ! -f "${APK_SOURCE}" ]]; then
  echo "Error: Expected APK was not created at '${APK_SOURCE}'." >&2
  exit 1
fi

mkdir -p "$(dirname "${APK_OUTPUT}")"
cp "${APK_SOURCE}" "${APK_OUTPUT}"

echo "Release APK copied to ${APK_OUTPUT}"
