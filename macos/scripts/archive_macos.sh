#!/usr/bin/env bash
# Builds the macOS Release app, archives it, and copies the archived .app bundle
# to a stable output path for QA and release validation.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MACOS_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_ROOT="$(cd "${MACOS_DIR}/.." && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
WORKSPACE_PATH="${WORKSPACE_PATH:-${MACOS_DIR}/Runner.xcworkspace}"
SCHEME_NAME="${SCHEME_NAME:-Runner}"
TARGET_NAME="${TARGET_NAME:-Runner}"
CONFIGURATION_NAME="${CONFIGURATION_NAME:-Release}"
ARCHIVE_PATH="${ARCHIVE_PATH:-${REPO_ROOT}/build/macos/archive/${SCHEME_NAME}.xcarchive}"
APP_OUTPUT_DIR="${APP_OUTPUT_DIR:-${REPO_ROOT}/build/macos/app}"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-${REPO_ROOT}/build/macos/derived_data}"
MIN_FLUTTER_VERSION="${MIN_FLUTTER_VERSION:-3.27.0}"
MACOS_BUILD_ROOT="${REPO_ROOT}/build/macos"
discover_flutter_bin

echo "==> Validating Flutter and macOS toolchain"
require_command xcodebuild
require_command ditto

FLUTTER_VERSION_OUTPUT="$("${FLUTTER_BIN}" --version)"
XCODE_VERSION_OUTPUT="$(xcodebuild -version)"
FLUTTER_VERSION="$(awk 'NR==1 { print $2; exit }' <<<"${FLUTTER_VERSION_OUTPUT}")"
XCODE_VERSION="$(awk '/Xcode/ { print $2; exit }' <<<"${XCODE_VERSION_OUTPUT}")"

if [[ -z "${FLUTTER_VERSION}" ]]; then
  echo "Error: Could not determine the installed Flutter version." >&2
  exit 1
fi

if [[ -z "${XCODE_VERSION}" ]]; then
  echo "Error: Could not determine the installed Xcode version." >&2
  exit 1
fi

if ! version_gte "${FLUTTER_VERSION}" "${MIN_FLUTTER_VERSION}"; then
  echo "Error: Flutter ${MIN_FLUTTER_VERSION}+ is required, but '${FLUTTER_VERSION}' is installed." >&2
  exit 1
fi

if ! command -v pod >/dev/null 2>&1; then
  echo "Error: CocoaPods is not installed or 'pod' is not in PATH." >&2
  echo "Install CocoaPods before running the macOS archive workflow on a clean machine." >&2
  exit 1
fi

echo "Flutter ${FLUTTER_VERSION}"
echo "Xcode ${XCODE_VERSION}"
"${FLUTTER_BIN}" doctor -v

validate_release_configuration

APP_BUNDLE_PATH="${APP_BUNDLE_PATH:-${APP_OUTPUT_DIR}/${PRODUCT_NAME}.app}"

mkdir -p "${MACOS_BUILD_ROOT}"
MACOS_BUILD_ROOT="$(cd "${MACOS_BUILD_ROOT}" && pwd -P)"
ARCHIVE_ROOT="${MACOS_BUILD_ROOT}/archive"
APP_ROOT="${MACOS_BUILD_ROOT}/app"
DERIVED_DATA_ROOT="${MACOS_BUILD_ROOT}/derived_data"

ARCHIVE_PATH="$(validate_managed_path ARCHIVE_PATH "${ARCHIVE_PATH}" "${ARCHIVE_ROOT}" ".xcarchive")"
APP_BUNDLE_PATH="$(validate_managed_path APP_BUNDLE_PATH "${APP_BUNDLE_PATH}" "${APP_ROOT}" ".app")"
DERIVED_DATA_PATH="$(validate_managed_path DERIVED_DATA_PATH "${DERIVED_DATA_PATH}" "${DERIVED_DATA_ROOT}")"
ARCHIVE_DIR="$(validate_managed_path ARCHIVE_DIR "$(dirname "${ARCHIVE_PATH}")" "${ARCHIVE_ROOT}")"
APP_BUNDLE_DIR="$(validate_managed_path APP_BUNDLE_DIR "$(dirname "${APP_BUNDLE_PATH}")" "${APP_ROOT}")"
ARCHIVED_APP_PATH="${ARCHIVE_PATH}/Products/Applications/${PRODUCT_NAME}.app"

mkdir -p "${ARCHIVE_DIR}" "${APP_BUNDLE_DIR}" "${DERIVED_DATA_PATH}"
rm -rf "${ARCHIVE_PATH}" "${APP_BUNDLE_PATH}"

echo "==> flutter pub get"
(cd "${REPO_ROOT}" && "${FLUTTER_BIN}" pub get)

echo "==> pod install"
(cd "${MACOS_DIR}" && pod install)

echo "==> Running flutter build macos --release"
(cd "${REPO_ROOT}" && "${FLUTTER_BIN}" build macos --release)

echo "==> Archiving ${SCHEME_NAME} (${CONFIGURATION_NAME})"
xcodebuild \
  -workspace "${WORKSPACE_PATH}" \
  -scheme "${SCHEME_NAME}" \
  -configuration "${CONFIGURATION_NAME}" \
  -destination "generic/platform=macOS" \
  -archivePath "${ARCHIVE_PATH}" \
  -derivedDataPath "${DERIVED_DATA_PATH}" \
  -allowProvisioningUpdates \
  archive

if [[ ! -d "${ARCHIVED_APP_PATH}" ]]; then
  echo "Error: Archived app bundle '${ARCHIVED_APP_PATH}' was not created." >&2
  exit 1
fi

echo "==> Copying archived app bundle to ${APP_BUNDLE_PATH}"
ditto "${ARCHIVED_APP_PATH}" "${APP_BUNDLE_PATH}"

echo "Archive created at ${ARCHIVE_PATH}"
echo "Archived .app bundle copied to ${APP_BUNDLE_PATH}"

# App Store upload options after this archive step:
# 1. Open the .xcarchive in Xcode Organizer and choose "Distribute App" to export
#    a Mac App Store .pkg for upload.
# 2. Or run ./macos/scripts/archive_app_store.sh to export build/macos/export/Turing Lab.pkg
#    for Apple Transporter or xcrun altool upload flows.
# Example altool usage after exporting a .pkg:
#   xcrun altool --upload-app --type macos --file build/macos/export/Turing Lab.pkg \
#     --username "<apple-id>" --password "<app-specific-password>"
