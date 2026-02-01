#!/usr/bin/env bash
set -e
# Install Flutter on Vercel (Flutter is not in the default image).
# Use "stable" so Dart is 3.8+ and flutter_lints ^6.0.0 resolves. Pin via FLUTTER_VERSION if needed.
# We skip "flutter doctor" so install doesn't fail on missing Android/Chrome (we only need web).
FLUTTER_REF="${FLUTTER_VERSION:-stable}"
if [ ! -d "flutter" ]; then
  git clone --depth 1 --branch "$FLUTTER_REF" https://github.com/flutter/flutter.git
fi
export PATH="$PWD/flutter/bin:$PATH"
flutter config --enable-web
flutter pub get
