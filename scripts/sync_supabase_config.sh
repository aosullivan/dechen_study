#!/usr/bin/env bash
# Sync .env Supabase credentials to web/supabase_config.js for local analytics.
# Run from project root: bash scripts/sync_supabase_config.sh

set -e
cd "$(dirname "$0")/.."

if [ ! -f .env ]; then
  echo "No .env found. Create one with SUPABASE_URL and SUPABASE_ANON_KEY."
  exit 1
fi

# Read from .env (supports SUPABASE_URL or SUPABASE_URL_TEST for local)
source_env() {
  local key=$1
  grep -E "^${key}=" .env 2>/dev/null | cut -d= -f2- | sed "s/^['\"]//;s/['\"]$//" | tr -d '\r'
}

URL=$(source_env SUPABASE_URL)
KEY=$(source_env SUPABASE_ANON_KEY)
if [ -z "$URL" ] || [ -z "$KEY" ]; then
  URL=$(source_env SUPABASE_URL_TEST)
  KEY=$(source_env SUPABASE_ANON_KEY_TEST)
fi

if [ -z "$URL" ] || [ -z "$KEY" ]; then
  echo "No SUPABASE_URL/SUPABASE_ANON_KEY or SUPABASE_URL_TEST/SUPABASE_ANON_KEY_TEST in .env"
  exit 1
fi

# Escape single quotes for JS
URL_ESC=$(echo "$URL" | sed "s/'/\\\\'/g")
KEY_ESC=$(echo "$KEY" | sed "s/'/\\\\'/g")

echo "window.SUPABASE_URL='$URL_ESC';window.SUPABASE_ANON_KEY='$KEY_ESC';" > web/supabase_config.js
echo "Wrote web/supabase_config.js from .env"
