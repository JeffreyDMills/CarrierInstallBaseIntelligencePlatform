#!/bin/bash
# Cowork ship — commit, push, wait for Vercel green
#
# Usage:
#   Double-click in Finder       → prompts for a commit message
#   ./ship.command "msg"         → from Terminal, uses the arg as message

set -e
cd "$(dirname "$0")"

KEYS=~/Desktop/Cowork/keys.txt
VERCEL_TOKEN=$(grep '^VERCEL_TOKEN=' "$KEYS" | cut -d= -f2-)
GITHUB_TOKEN=$(grep '^GITHUB_TOKEN=' "$KEYS" | cut -d= -f2-)
GH_AUTH="Authorization: Basic $(printf 'x-access-token:%s' "$GITHUB_TOKEN" | base64)"
MANIFEST=~/Desktop/Cowork/projects.json
SLUG=$(basename "$PWD")

if [ -f "$MANIFEST" ]; then
  VERCEL_APP=$(python3 -c "import json; m=json.load(open('$MANIFEST')); print(m['projects'].get('$SLUG',{}).get('vercelApp',''))" 2>/dev/null)
fi
VERCEL_APP=${VERCEL_APP:-$SLUG}

echo ""
echo "═══════════════════════════════════════════"
echo "  Ship: $SLUG → $VERCEL_APP"
echo "═══════════════════════════════════════════"
echo ""

# Get commit message
if [ -n "$1" ]; then
  MSG="$1"
else
  echo "What changed? (one line, then return)"
  read -r MSG
  if [ -z "$MSG" ]; then
    echo "✗ Commit message required."
    read -p "Press return to close..."
    exit 1
  fi
fi

# Stage + commit if there are changes
if [ -z "$(git status --porcelain)" ]; then
  echo "ℹ No file changes. Will still check latest Vercel deploy."
else
  echo "→ Staging..."
  git add .
  echo "→ Committing: $MSG"
  git -c user.email='jeff.mills@toptal.com' -c user.name='Jeff Mills' commit -m "$MSG"
fi

SHA=$(git rev-parse --short HEAD)
echo "→ HEAD: $SHA"

# Push if ahead of remote
AHEAD=$(git rev-list --count @{u}..HEAD 2>/dev/null || echo 0)
if [ "$AHEAD" -gt 0 ]; then
  echo "→ Pushing $AHEAD commit(s) to origin/main..."
  git -c http.extraHeader="$GH_AUTH" push origin main
else
  echo "ℹ Already in sync with origin."
fi

# Poll Vercel
echo ""
echo "→ Waiting for Vercel deploy..."
START=$(date +%s)
TIMEOUT=180
LAST_STATE=""

while true; do
  RESPONSE=$(curl -s -H "Authorization: Bearer $VERCEL_TOKEN" \
    "https://api.vercel.com/v6/deployments?app=$VERCEL_APP&limit=1")

  STATE=$(echo "$RESPONSE" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin); deps = d.get('deployments') or []
    print(deps[0].get('state','UNKNOWN') if deps else 'NONE')
except: print('PARSE_ERR')
" 2>/dev/null)

  URL=$(echo "$RESPONSE" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin); deps = d.get('deployments') or []
    print(deps[0].get('url','') if deps else '')
except: print('')
" 2>/dev/null)

  DEP_SHA=$(echo "$RESPONSE" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin); deps = d.get('deployments') or []
    s = deps[0].get('meta',{}).get('githubCommitSha','') if deps else ''
    print(s[:7])
except: print('')
" 2>/dev/null)

  ELAPSED=$(($(date +%s) - START))

  case "$STATE" in
    READY)
      echo ""
      echo "✓ READY  https://$URL"
      echo "  commit: $DEP_SHA  time: ${ELAPSED}s"
      read -p "Press return to close..."
      exit 0
      ;;
    ERROR|CANCELED)
      echo ""
      echo "✗ $STATE — see https://vercel.com/dashboard"
      read -p "Press return to close..."
      exit 1
      ;;
    *)
      if [ "$STATE" != "$LAST_STATE" ]; then
        echo "  $STATE (${ELAPSED}s)"
        LAST_STATE="$STATE"
      fi
      ;;
  esac

  if [ $ELAPSED -gt $TIMEOUT ]; then
    echo ""
    echo "⏱ Timeout after ${TIMEOUT}s. Last state: $STATE"
    read -p "Press return to close..."
    exit 1
  fi

  sleep 3
done
