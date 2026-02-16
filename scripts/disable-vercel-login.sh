#!/usr/bin/env bash
# Disable Vercel Deployment Protection (login requirement) for this project.
# Run once; then the deployment URL will be publicly accessible without logging in.
#
# Prerequisites:
#   1. Create a token at https://vercel.com/account/tokens (with "Full Account" or project access)
#   2. Set it: export VERCEL_TOKEN=your_token_here
#   Or pass: VERCEL_TOKEN=your_token ./scripts/disable-vercel-login.sh

set -e
PROJECT_ID="${VERCEL_PROJECT_ID:-prj_UmhGHX5mQ9bNSKip2NI0tqA9oWa7}"
TEAM_ID="${VERCEL_TEAM_ID:-team_c0kfODLbBEclmVI57vWiZAS2}"

if [ -z "${VERCEL_TOKEN}" ]; then
  echo "Error: VERCEL_TOKEN is not set."
  echo "Create a token at https://vercel.com/account/tokens then run:"
  echo "  export VERCEL_TOKEN=your_token"
  echo "  ./scripts/disable-vercel-login.sh"
  exit 1
fi

echo "Disabling deployment protection (login) for project $PROJECT_ID ..."
curl -s -X PATCH "https://api.vercel.com/v9/projects/${PROJECT_ID}?teamId=${TEAM_ID}" \
  -H "Authorization: Bearer ${VERCEL_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"ssoProtection":null}' | head -c 500
echo ""
echo "Done. The app should now be reachable without logging in."
echo "URL: https://dechen-study-nicephorus-projects.vercel.app"
