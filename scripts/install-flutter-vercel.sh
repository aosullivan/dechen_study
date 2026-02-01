#!/usr/bin/env bash
set -e
# Install Flutter on Vercel (Flutter is not in the default image).
# Uses a fixed stable version to avoid surprises; match your .metadata / CI if needed.
FLUTTER_VERSION="${FLUTTER_VERSION:-3.24.0}"
if [ ! -d "flutter" ]; then
  git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git
fi
export PATH="$PWD/flutter/bin:$PATH"
flutter doctor
flutter config --enable-web
flutter pub get
