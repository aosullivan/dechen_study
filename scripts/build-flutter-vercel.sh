#!/usr/bin/env bash
set -e
# Build Flutter web on Vercel. Expects Flutter to be installed by install-flutter-vercel.sh.
# Writes .env from Vercel env vars so the app has Supabase config at runtime.
if [ -n "$SUPABASE_URL" ] && [ -n "$SUPABASE_ANON_KEY" ]; then
  echo "SUPABASE_URL=$SUPABASE_URL" > .env
  echo "SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY" >> .env
  echo "window.SUPABASE_URL='$SUPABASE_URL';window.SUPABASE_ANON_KEY='$SUPABASE_ANON_KEY';" > web/supabase_config.js
fi
export PATH="$PWD/flutter/bin:$PATH"
flutter build web --release --dart-define=APP_ENV=prod
