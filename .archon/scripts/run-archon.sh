#!/usr/bin/env bash
# run-archon.sh — invoke Archon with explicit OAuth credentials so it
# never spawns a nested `claude` CLI subprocess.
#
# Why: Archon's default "global auth" mode spawns the system `claude`
# binary as a subprocess. When invoked from inside a Claude Code session,
# that subprocess inherits CLAUDE_CODE_* env vars, detects "I'm nested,"
# and deadlocks. Setting an explicit OAuth token routes Archon directly
# to the Anthropic API and skips the spawn entirely.
#
# Reference: https://github.com/coleam00/Archon/issues/1067
#
# This wrapper reads the current OAuth token from Claude Code's
# credentials file each call, so it stays fresh as the token rotates.
#
# Usage:
#   ./.archon/scripts/run-archon.sh workflow run deploy-pod-store
#   ./.archon/scripts/run-archon.sh workflow list
#   ./.archon/scripts/run-archon.sh chat "hello"
#
# Prerequisite: run `claude` once interactively to authenticate. The
# token then lives in ~/.claude/.credentials.json and refreshes on use.

set -euo pipefail

CRED="$HOME/.claude/.credentials.json"

if [ ! -f "$CRED" ]; then
  echo "ERROR: $CRED not found." >&2
  echo "       Run 'claude' once interactively to authenticate, then retry." >&2
  exit 1
fi

TOKEN="$(python3 -c "
import json, sys
try:
  d = json.load(open('$CRED'))['claudeAiOauth']
  print(d.get('accessToken',''))
except Exception as e:
  sys.exit(1)
" 2>/dev/null)"

if [ -z "$TOKEN" ]; then
  echo "ERROR: could not extract accessToken from $CRED." >&2
  echo "       The file shape may have changed. Run 'claude' to re-auth." >&2
  exit 1
fi

EXPIRES_MS="$(python3 -c "
import json
print(json.load(open('$CRED'))['claudeAiOauth'].get('expiresAt', 0))
" 2>/dev/null || echo 0)"
NOW_MS="$(($(date +%s) * 1000))"

if [ "$EXPIRES_MS" -gt 0 ] && [ "$EXPIRES_MS" -le "$NOW_MS" ]; then
  echo "WARN: OAuth token expired. Run 'claude' once to refresh." >&2
fi

# Strip every parent Claude-Code env var so any fallback subprocess spawn
# cannot detect that it is nested. Belt-and-suspenders alongside the
# explicit token.
unset CLAUDECODE                 || true
unset CLAUDE_CODE_ENTRYPOINT     || true
unset CLAUDE_CODE_EXECPATH       || true
unset CLAUDE_CODE_SSE_PORT       || true
unset CLAUDE_CODE_REMOTE_FETCH_PORT || true
unset ANTHROPIC_API_KEY          || true   # explicit OAuth must win

# Tell Archon to use explicit auth and silence the nested-detection warning.
export CLAUDE_USE_GLOBAL_AUTH=false
export CLAUDE_CODE_OAUTH_TOKEN="$TOKEN"
export ARCHON_SUPPRESS_NESTED_CLAUDE_WARNING=1

exec archon "$@"
