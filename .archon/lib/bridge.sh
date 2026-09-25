#!/usr/bin/env bash
# Shared bridge helpers for Archon bash nodes.
# Source from any bash node:
#   source "${STORE_DROP_ROOT:-$PWD}/.archon/lib/bridge.sh"

_bridge_load_env() {
  if [ -n "${BRIDGE_URL:-}" ] && [ -n "${BRIDGE_PASS:-}" ]; then
    return 0
  fi
  local candidates=(
    "${STORE_DROP_ROOT:-$PWD}/.env"
    "/tmp/archon-bridge/.env"
    "${ARCHON_PROJECT_ROOT:-}/.env"
  )
  local f
  for f in "${candidates[@]}"; do
    if [ -n "$f" ] && [ -f "$f" ]; then
      local helper="${STORE_DROP_ROOT:-$PWD}/scripts/config-file.py"
      [ -f "$helper" ] || continue
      BRIDGE_URL="$(python3 "$helper" get "$f" BRIDGE_URL)"
      BRIDGE_USER="$(python3 "$helper" get "$f" BRIDGE_USER)"
      BRIDGE_PASS="$(python3 "$helper" get "$f" BRIDGE_PASS)"
      BRIDGE_SITE="$(python3 "$helper" get "$f" BRIDGE_SITE)"
      export BRIDGE_URL BRIDGE_USER BRIDGE_PASS BRIDGE_SITE
      return 0
    fi
  done
  return 1
}
_bridge_load_env

: "${BRIDGE_USER:=store-drop-agent}"
bridge_check_env() {
  if [ -z "${BRIDGE_URL:-}" ] || [ -z "${BRIDGE_PASS:-}" ]; then
    echo "FAIL: BRIDGE_URL or BRIDGE_PASS missing from environment" >&2
    return 1
  fi
}

bridge_curl() {
  local netrc rc
  netrc="$(mktemp)"
  chmod 600 "$netrc"
  BRIDGE_NETRC="$netrc" python3 - <<'PY'
import os, urllib.parse
host = urllib.parse.urlsplit(os.environ["BRIDGE_URL"]).hostname or ""
def q(value): return '"' + value.replace('\\', '\\\\').replace('"', '\\"') + '"'
with open(os.environ["BRIDGE_NETRC"], "w", encoding="utf-8") as fh:
    fh.write(f"machine {host} login {q(os.environ['BRIDGE_USER'])} password {q(os.environ['BRIDGE_PASS'])}\n")
PY
  curl --netrc-file "$netrc" "$@"
  rc=$?
  command rm -f -- "$netrc"
  return "$rc"
}

bridge_get() {
  bridge_curl -s --max-time 15 "${BRIDGE_URL}$1"
}

bridge_post() {
  printf '%s' "$2" | bridge_curl -s --max-time 30 -X POST "${BRIDGE_URL}$1" \
    -H "Content-Type: application/json" --data-binary @-
}

bridge_post_file() {
  bridge_curl -s --max-time 30 -X POST "${BRIDGE_URL}$1" \
    -H "Content-Type: application/json" --data @"$2"
}

# bridge_mutate <write-path> <payload> [read-path]
# Snapshot, validate, mutate, flush, read back, and journal verified state.
bridge_mutate() {
  local write_path="$1" payload="$2" read_path="${3:-$1}" previous response verified journal
  printf '%s' "$payload" | python3 -c 'import json,sys; json.load(sys.stdin)' >/dev/null 2>&1 \
    || { echo "FAIL: invalid or empty JSON payload for $write_path" >&2; return 1; }
  previous="$(bridge_get "$read_path" || true)"
  response="$(bridge_post "$write_path" "$payload")"
  printf '%s' "$response" | python3 -c 'import json,sys; json.load(sys.stdin)' >/dev/null 2>&1 \
    || { echo "FAIL: mutation $write_path returned invalid JSON" >&2; return 1; }
  bridge_flush_cache || return 1
  verified="$(bridge_get "$read_path" || true)"
  [ -n "$verified" ] || { echo "FAIL: empty read-back after $write_path" >&2; return 1; }
  journal="${ARTIFACTS_DIR:-/tmp/archon-artifacts}/mutation-journal.jsonl"
  mkdir -p "$(dirname "$journal")"
  MUTATION_PATH="$write_path" BEFORE="$previous" AFTER="$verified" python3 - "$journal" <<'PY'
import json, os, sys
def safe(value):
    try: return json.loads(value)
    except Exception: return {"captured": bool(value)}
with open(sys.argv[1], "a", encoding="utf-8") as fh:
    fh.write(json.dumps({"path": os.environ["MUTATION_PATH"], "before": safe(os.environ["BEFORE"]), "after": safe(os.environ["AFTER"])}) + "\n")
PY
  printf '%s' "$response"
}

bridge_render() {
  bridge_curl -s --max-time 30 "${BRIDGE_URL}/render?url=$1" \
    | python3 -c 'import sys,json;print(json.load(sys.stdin).get("html",""))' 2>/dev/null
}

bridge_render_status() {
  bridge_curl -s --max-time 30 "${BRIDGE_URL}/render?url=$1" \
    | python3 -c 'import sys,json;print(json.load(sys.stdin).get("status","?"))' 2>/dev/null
}

bridge_get_css() {
  bridge_get "/css" \
    | python3 -c 'import sys,json;print(json.load(sys.stdin).get("css",""))' 2>/dev/null
}

bridge_get_theme_mod() {
  # Compact JSON (no spaces after , or :) so validator regexes can match
  # without whitespace tolerance. python's default json.dumps inserts
  # ", " and ": " separators, which would break naive '"key":[0-9]+' patterns.
  bridge_get "/theme-mod/$1" \
    | python3 -c 'import sys,json;v=json.load(sys.stdin).get("value");print(json.dumps(v, separators=(",",":")) if v is not None else "")' 2>/dev/null
}

bridge_post_theme_mod() {
  # Set a single theme_mod. Usage: bridge_post_theme_mod <key> <value>
  # Symmetric with bridge_get_theme_mod.
  bridge_mutate "/theme-mod/$1" "{\"value\":\"$2\"}" "/theme-mod/$1"
}

bridge_flush_cache() {
  local attempt response
  for attempt in 1 2 3; do
    response="$(bridge_post "/cache/flush" '{}' || true)"
    if printf '%s' "$response" | grep -q '"success"[[:space:]]*:[[:space:]]*true'; then
      return 0
    fi
    [ "$attempt" -lt 3 ] && sleep "$attempt"
  done
  echo "FAIL: cache flush failed after 3 attempts" >&2
  return 1
}
