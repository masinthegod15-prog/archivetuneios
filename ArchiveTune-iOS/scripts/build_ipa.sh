#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="$ROOT/ArchiveTune.xcodeproj"
SCHEME="ArchiveTune"
TEAM_ID="${DEVELOPMENT_TEAM:-}"
BUNDLE_ID="${PRODUCT_BUNDLE_IDENTIFIER:-moe.rukamori.archivetune.ios}"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This script must run on macOS with Xcode installed." >&2
  exit 2
fi
if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "xcodebuild was not found. Install Xcode and its command-line tools first." >&2
  exit 2
fi
if [[ -z "$TEAM_ID" ]]; then
  echo "Set DEVELOPMENT_TEAM to your Apple Developer Team ID." >&2
  exit 2
fi

BUILD_DIR="$ROOT/build"
ARCHIVE_PATH="$BUILD_DIR/ArchiveTune.xcarchive"
EXPORT_DIR="$BUILD_DIR/ipa"
OPTIONS="$BUILD_DIR/ExportOptions.plist"
mkdir -p "$BUILD_DIR"
cp "$ROOT/scripts/ExportOptions.plist" "$OPTIONS"
/usr/libexec/PlistBuddy -c "Set :teamID $TEAM_ID" "$OPTIONS" >/dev/null

xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE_PATH" \
  -allowProvisioningUpdates \
  DEVELOPMENT_TEAM="$TEAM_ID" \
  PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_ID" \
  archive

xcodebuild \
  -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportOptionsPlist "$OPTIONS" \
  -exportPath "$EXPORT_DIR" \
  -allowProvisioningUpdates

echo "IPA export complete: $EXPORT_DIR"
