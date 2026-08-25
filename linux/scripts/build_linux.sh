#!/usr/bin/env bash
# Builds a relocatable Linux release bundle and copies it to a stable output path.
# Must run on Linux (or WSL). Flutter does not cross-compile desktop targets.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LINUX_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_ROOT="$(cd "${LINUX_DIR}/.." && pwd)"
BUNDLE_OUTPUT="${BUNDLE_OUTPUT:-${REPO_ROOT}/build/linux/app}"

flutter_linux_arch() {
  case "$(uname -m)" in
    x86_64) printf 'x64\n' ;;
    aarch64|arm64) printf 'arm64\n' ;;
    *)
      echo "Error: Unsupported Linux architecture '$(uname -m)'." >&2
      exit 1
      ;;
  esac
}

require_linux_host() {
  if [[ "${TURING_LAB_SKIP_HOST_CHECK:-}" == "1" ]]; then
    return 0
  fi
  if [[ "$(uname -s)" != "Linux" ]]; then
    echo "Error: Linux builds must run on Linux." >&2
    echo "Run ./linux/scripts/build_linux.sh on a Linux machine or in WSL." >&2
    exit 1
  fi
}

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

require_linux_host
discover_flutter_bin

FLUTTER_ARCH="$(flutter_linux_arch)"
BUNDLE_SOURCE="${BUNDLE_SOURCE:-${REPO_ROOT}/build/linux/${FLUTTER_ARCH}/release/bundle}"

echo "==> flutter pub get"
(cd "${REPO_ROOT}" && "${FLUTTER_BIN}" pub get)

echo "==> flutter build linux --release"
set +e
(cd "${REPO_ROOT}" && "${FLUTTER_BIN}" build linux --release)
BUILD_EXIT=$?
set -e
if [[ "${BUILD_EXIT}" -ne 0 ]]; then
  echo "Error: flutter build linux --release failed." >&2
  exit "${BUILD_EXIT}"
fi

if [[ ! -x "${BUNDLE_SOURCE}/turing_lab" ]]; then
  echo "Error: Expected Linux bundle was not created at '${BUNDLE_SOURCE}'." >&2
  exit 1
fi

rm -rf "${BUNDLE_OUTPUT}"
mkdir -p "${BUNDLE_OUTPUT}"
cp -R "${BUNDLE_SOURCE}/." "${BUNDLE_OUTPUT}/"

echo "Release Linux bundle copied to ${BUNDLE_OUTPUT}"
