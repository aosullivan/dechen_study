#!/usr/bin/env bash
set -e
# Build Flutter web on Vercel. Expects Flutter to be installed by install-flutter-vercel.sh.
# Writes .env and web/supabase_config.js from Vercel env vars so the app and analytics page work.
if [ -n "$SUPABASE_URL" ] && [ -n "$SUPABASE_ANON_KEY" ]; then
  echo "SUPABASE_URL=$SUPABASE_URL" > .env
  echo "SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY" >> .env
  # Escape single quotes for JS (key may contain none)
  SUPABASE_URL_ESC="${SUPABASE_URL//\'/\\\'}"
  SUPABASE_ANON_KEY_ESC="${SUPABASE_ANON_KEY//\'/\\\'}"
  echo "window.SUPABASE_URL='$SUPABASE_URL_ESC';window.SUPABASE_ANON_KEY='$SUPABASE_ANON_KEY_ESC';" > web/supabase_config.js
else
  echo "::warning:: SUPABASE_URL and/or SUPABASE_ANON_KEY not set. Add them in Vercel Project Settings → Environment Variables, then redeploy. Analytics and usage stats will not work until then."
fi
export PATH="$PWD/flutter/bin:$PATH"
flutter build web --release --dart-define=APP_ENV=prod
