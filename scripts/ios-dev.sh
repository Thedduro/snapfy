#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_PATH="${PROJECT_PATH:-$PROJECT_ROOT/snapfy.xcodeproj}"
SCHEME="${SCHEME:-snapfy}"
CONFIGURATION="${CONFIGURATION:-Debug}"
DEVICE="${DEVICE:-iPhone 17 Pro}"
BUNDLE_ID="${BUNDLE_ID:-thedduro.snapfy}"
APP_NAME="${APP_NAME:-snapfy}"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-$HOME/Library/Developer/Xcode/DerivedData/snapfy-cli}"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/ios-dev.sh list-devices
  ./scripts/ios-dev.sh boot
  ./scripts/ios-dev.sh build
  ./scripts/ios-dev.sh run
  ./scripts/ios-dev.sh test
  ./scripts/ios-dev.sh logs
  ./scripts/ios-dev.sh clean

Environment overrides:
  DEVICE="iPhone 17 Pro"
  SCHEME="snapfy"
  CONFIGURATION="Debug"
  DERIVED_DATA_PATH="$HOME/Library/Developer/Xcode/DerivedData/snapfy-cli"
EOF
}

resolve_udid() {
  local line
  line="$(
    xcrun simctl list devices available |
      grep -F "    $DEVICE (" |
      head -n 1 || true
  )"

  if [[ -z "$line" ]]; then
    echo "Simulator device not found: $DEVICE" >&2
    exit 1
  fi

  echo "$line" | sed -E 's/.*\(([A-F0-9-]+)\) \(.*/\1/'
}

ensure_simulator_open() {
  open -a Simulator >/dev/null 2>&1 || true
}

boot_device() {
  local udid="$1"

  ensure_simulator_open

  if ! xcrun simctl list devices booted | grep -F "$udid" >/dev/null 2>&1; then
    xcrun simctl boot "$udid" >/dev/null 2>&1 || true
  fi

  xcrun simctl bootstatus "$udid" -b
}

build_app() {
  local udid="$1"

  xcodebuild \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -destination "platform=iOS Simulator,id=$udid" \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    build
}

test_app() {
  local udid="$1"

  xcodebuild \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -destination "platform=iOS Simulator,id=$udid" \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    test
}

app_path() {
  echo "$DERIVED_DATA_PATH/Build/Products/${CONFIGURATION}-iphonesimulator/${APP_NAME}.app"
}

install_app() {
  local udid="$1"
  local built_app

  built_app="$(app_path)"
  if [[ ! -d "$built_app" ]]; then
    echo "Built app not found: $built_app" >&2
    exit 1
  fi

  xcrun simctl install "$udid" "$built_app"
}

launch_app() {
  local udid="$1"

  xcrun simctl terminate "$udid" "$BUNDLE_ID" >/dev/null 2>&1 || true
  xcrun simctl launch "$udid" "$BUNDLE_ID"
}

stream_logs() {
  local udid="$1"

  xcrun simctl spawn "$udid" log stream \
    --style compact \
    --predicate "process == \"$APP_NAME\""
}

clean_build_artifacts() {
  rm -rf "$DERIVED_DATA_PATH"
}

main() {
  local action="${1:-run}"
  local udid=""

  case "$action" in
    list-devices)
      xcrun simctl list devices available
      ;;
    boot)
      udid="$(resolve_udid)"
      boot_device "$udid"
      ;;
    build)
      udid="$(resolve_udid)"
      build_app "$udid"
      ;;
    run)
      udid="$(resolve_udid)"
      boot_device "$udid"
      build_app "$udid"
      install_app "$udid"
      launch_app "$udid"
      ;;
    test)
      udid="$(resolve_udid)"
      boot_device "$udid"
      test_app "$udid"
      ;;
    logs)
      udid="$(resolve_udid)"
      boot_device "$udid"
      stream_logs "$udid"
      ;;
    clean)
      clean_build_artifacts
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
