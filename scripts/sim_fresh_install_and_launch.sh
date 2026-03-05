#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

BUNDLE_ID="${BUNDLE_ID:-com.dechen.study}"
SIM_UDID_INPUT="${1:-${SIM_UDID:-}}"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/sim_fresh_install_and_launch.sh [SIMULATOR_UDID]

Environment overrides:
  BUNDLE_ID   App bundle id (default: com.dechen.study)
  SIM_UDID    Simulator UDID (used when positional arg is omitted)

Behavior:
  1) Boot simulator
  2) Terminate app
  3) Uninstall app (clears app data)
  4) flutter clean
  5) flutter pub get
  6) flutter build ios --simulator --debug
  7) simctl install + launch
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ -n "${SIM_UDID_INPUT}" && ! "${SIM_UDID_INPUT}" =~ ^[A-F0-9-]{36}$ ]]; then
  echo "Invalid simulator UDID: ${SIM_UDID_INPUT}"
  usage
  exit 1
fi

pick_sim_udid() {
  local udid=""

  if [[ -n "${SIM_UDID_INPUT}" ]]; then
    echo "${SIM_UDID_INPUT}"
    return 0
  fi

  # Prefer a currently booted simulator.
  udid="$(xcrun simctl list devices | sed -n 's/.*(\([A-F0-9-]\{36\}\)) (Booted).*/\1/p' | head -n1)"
  if [[ -n "${udid}" ]]; then
    echo "${udid}"
    return 0
  fi

  # Fallback to the first shutdown simulator listed.
  udid="$(xcrun simctl list devices | sed -n 's/.*(\([A-F0-9-]\{36\}\)) (Shutdown).*/\1/p' | head -n1)"
  if [[ -n "${udid}" ]]; then
    echo "${udid}"
    return 0
  fi

  return 1
}

SIM_UDID="$(pick_sim_udid || true)"
if [[ -z "${SIM_UDID}" ]]; then
  echo "No iOS Simulator device found."
  exit 1
fi

echo "Using simulator: ${SIM_UDID}"
echo "Bundle ID: ${BUNDLE_ID}"

echo "Booting simulator (if needed)..."
xcrun simctl boot "${SIM_UDID}" >/dev/null 2>&1 || true
open -a Simulator --args -CurrentDeviceUDID "${SIM_UDID}"
xcrun simctl bootstatus "${SIM_UDID}" -b

echo "Terminating existing app process..."
xcrun simctl terminate "${SIM_UDID}" "${BUNDLE_ID}" >/dev/null 2>&1 || true

echo "Uninstalling existing app..."
xcrun simctl uninstall "${SIM_UDID}" "${BUNDLE_ID}" >/dev/null 2>&1 || true

# Keep CocoaPods happy in non-interactive shells.
export LANG="${LANG:-en_US.UTF-8}"
export LC_ALL="${LC_ALL:-en_US.UTF-8}"

echo "Cleaning Flutter artifacts..."
flutter clean

echo "Resolving dependencies..."
flutter pub get

echo "Building iOS simulator app (debug)..."
flutter build ios --simulator --debug

APP_PATH=""
for candidate in \
  "build/ios/iphonesimulator/Runner.app" \
  "build/ios/Debug-iphonesimulator/Runner.app"; do
  if [[ -d "${candidate}" ]]; then
    APP_PATH="${candidate}"
    break
  fi
done

if [[ -z "${APP_PATH}" ]]; then
  echo "Could not find built app bundle (Runner.app)."
  exit 1
fi

echo "Installing app: ${APP_PATH}"
xcrun simctl install "${SIM_UDID}" "${APP_PATH}"

echo "Launching app..."
xcrun simctl launch "${SIM_UDID}" "${BUNDLE_ID}"

echo "Done."
