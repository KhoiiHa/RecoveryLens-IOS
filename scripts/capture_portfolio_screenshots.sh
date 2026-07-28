#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_PATH="$ROOT_DIR/RecoveryLens/RecoveryLens.xcodeproj"
SCREENSHOT_DIR="$ROOT_DIR/docs/screenshots"
WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/recoverylens-screenshots.XXXXXX")"
RESULT_BUNDLE="$WORK_DIR/RecoveryLensScreenshots.xcresult"
ATTACHMENT_DIR="$WORK_DIR/attachments"
DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
DESTINATION="${RECOVERYLENS_DESTINATION:-platform=iOS Simulator,name=iPhone 17,OS=26.5}"

cleanup() {
    rm -rf "$WORK_DIR"
}
trap cleanup EXIT

mkdir -p "$SCREENSHOT_DIR" "$ATTACHMENT_DIR"

DEVELOPER_DIR="$DEVELOPER_DIR" xcodebuild test \
    -quiet \
    -project "$PROJECT_PATH" \
    -scheme RecoveryLens \
    -destination "$DESTINATION" \
    -parallel-testing-enabled NO \
    -only-testing:RecoveryLensUITests/RecoveryLensUITests/testCapturePortfolioScreenshots \
    -resultBundlePath "$RESULT_BUNDLE"

DEVELOPER_DIR="$DEVELOPER_DIR" xcrun xcresulttool export attachments \
    --path "$RESULT_BUNDLE" \
    --output-path "$ATTACHMENT_DIR"

for name in 01-dashboard 02-week-overview 03-check-in; do
    source_file_name="$(
        python3 -c '
import json
import sys

with open(sys.argv[1], encoding="utf-8") as manifest_file:
    manifest = json.load(manifest_file)

for test in manifest:
    for attachment in test["attachments"]:
        if attachment["suggestedHumanReadableName"].startswith(sys.argv[2]):
            print(attachment["exportedFileName"])
            raise SystemExit
' "$ATTACHMENT_DIR/manifest.json" "$name"
    )"
    source_file="$ATTACHMENT_DIR/$source_file_name"

    if [[ -z "$source_file_name" || ! -f "$source_file" ]]; then
        print -u2 "Screenshot-Anhang fehlt: $name"
        exit 1
    fi

    cp "$source_file" "$SCREENSHOT_DIR/$name.png"
done

print "Portfolio-Screenshots aktualisiert: $SCREENSHOT_DIR"
