#!/usr/bin/env bash
# Shared bridge helpers for Archon bash nodes.
# Source from any bash node:
#   source "$HOME/kadence-skill/mega-kadence-skill/.archon/lib/bridge.sh"

_bridge_load_env() {
  local candidates=(
    "$HOME/kadence-skill/mega-kadence-skill/.env"
    "/tmp/archon-bridge/.env"
    "${ARCHON_PROJECT_ROOT:-}/.env"
  )
  local f
  for f in "${candidates[@]}"; do
    if [ -n "$f" ] && [ -f "$f" ]; then
      set -a
      # shellcheck disable=SC1090
      . "$f"
      set +a
      return 0
    fi
  done
  return 1
}
_bridge_load_env

: "${BRIDGE_USER:=claude-bot}"
BRIDGE_AUTH="${BRIDGE_USER}:${BRIDGE_PASS:-}"

bridge_check_env() {
  if [ -z "${BRIDGE_URL:-}" ] || [ -z "${BRIDGE_PASS:-}" ]; then
    echo "FAIL: BRIDGE_URL or BRIDGE_PASS missing from environment" >&2
    return 1
  fi
}

bridge_get() {
  curl -s --max-time 15 "${BRIDGE_URL}$1" -u "$BRIDGE_AUTH"
}

bridge_post() {
  curl -s --max-time 30 -X POST "${BRIDGE_URL}$1" \
    -u "$BRIDGE_AUTH" \
    -H "Content-Type: application/json" \
    -d "$2"
}

bridge_render() {
  curl -s --max-time 30 "${BRIDGE_URL}/render?url=$1" -u "$BRIDGE_AUTH" \
    | python3 -c 'import sys,json;print(json.load(sys.stdin).get("html",""))' 2>/dev/null
}

bridge_render_status() {
  curl -s --max-time 30 "${BRIDGE_URL}/render?url=$1" -u "$BRIDGE_AUTH" \
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
  bridge_post "/theme-mod/$1" "{\"value\":\"$2\"}"
}

bridge_flush_cache() {
  bridge_post "/cache/flush" '{}' >/dev/null
}
