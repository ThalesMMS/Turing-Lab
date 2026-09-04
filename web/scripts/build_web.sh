#!/usr/bin/env bash
# Builds the Flutter web release and adds GitHub Pages extras
# (support/privacy pages and .nojekyll).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WEB_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_ROOT="$(cd "${WEB_DIR}/.." && pwd)"
WEB_OUTPUT="${WEB_OUTPUT:-${REPO_ROOT}/build/web}"

if [[ -z "${WEB_BASE_HREF:-}" ]]; then
  if [[ -n "${GITHUB_REPOSITORY:-}" ]]; then
    WEB_BASE_HREF="/${GITHUB_REPOSITORY##*/}/"
  else
    WEB_BASE_HREF="/Turing-Lab/"
  fi
fi

if [[ "${WEB_BASE_HREF}" != */ ]]; then
  WEB_BASE_HREF="${WEB_BASE_HREF}/"
fi

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

copy_pages_extra() {
  local source="$1"
  local destination="$2"
  if [[ ! -f "${source}" ]]; then
    echo "Error: Required Pages file '${source}' is missing." >&2
    exit 1
  fi
  cp "${source}" "${destination}"
}

discover_flutter_bin

echo "==> flutter pub get"
(cd "${REPO_ROOT}" && "${FLUTTER_BIN}" pub get)

echo "==> flutter build web --release --base-href ${WEB_BASE_HREF}"
set +e
(cd "${REPO_ROOT}" && "${FLUTTER_BIN}" build web --release --base-href "${WEB_BASE_HREF}")
BUILD_EXIT=$?
set -e
if [[ "${BUILD_EXIT}" -ne 0 ]]; then
  echo "Error: flutter build web --release failed." >&2
  exit "${BUILD_EXIT}"
fi

if [[ ! -f "${WEB_OUTPUT}/index.html" ]]; then
  echo "Error: Expected web index was not created at '${WEB_OUTPUT}/index.html'." >&2
  exit 1
fi

copy_pages_extra "${REPO_ROOT}/docs/support.html" "${WEB_OUTPUT}/support.html"
copy_pages_extra "${REPO_ROOT}/docs/privacy.html" "${WEB_OUTPUT}/privacy.html"
copy_pages_extra "${REPO_ROOT}/docs/marketing.html" "${WEB_OUTPUT}/marketing.html"
copy_pages_extra \
  "${REPO_ROOT}/docs/APP_PRIVACY_APPLE.md" \
  "${WEB_OUTPUT}/APP_PRIVACY_APPLE.md"
mkdir -p "${WEB_OUTPUT}/assets/screenshots"
copy_pages_extra "${REPO_ROOT}/docs/assets/site.css" "${WEB_OUTPUT}/assets/site.css"
copy_pages_extra \
  "${REPO_ROOT}/docs/assets/icon-192.png" \
  "${WEB_OUTPUT}/assets/icon-192.png"
copy_pages_extra \
  "${REPO_ROOT}/docs/assets/social-preview.png" \
  "${WEB_OUTPUT}/assets/social-preview.png"
copy_pages_extra \
  "${REPO_ROOT}/docs/assets/screenshots/fsa.webp" \
  "${WEB_OUTPUT}/assets/screenshots/fsa.webp"
: >"${WEB_OUTPUT}/.nojekyll"

echo "Release web build ready at ${WEB_OUTPUT}"
