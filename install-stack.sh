#!/usr/bin/env bash
#
# install-stack.sh — the missing install gate for store-drop.
#
# Stands up the full required plugin/theme stack on a fresh WordPress via the
# Mega Kadence Bridge, so deploy-pod-store can run. Free plugins install by
# wp.org slug; premium artifacts install from short-TTL presigned R2 URLs,
# checksum-verified against premium-manifest.json (the sha256 trust list).
#
# Prereqs:
#   - MKB v1.4.0+ active on the target (themes/install-from-url + sha256 installs)
#   - .env with BRIDGE_URL / BRIDGE_USER / BRIDGE_PASS / BRIDGE_SITE
#   - rclone remote for R2 named by $R2_REMOTE (default: r2), bucket from manifest
#
# Usage: ./install-stack.sh [--dry-run]
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST="$HERE/premium-manifest.json"
R2_REMOTE="${R2_REMOTE:-r2}"
PRESIGN_TTL="${PRESIGN_TTL:-600}"   # seconds
DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

# shellcheck disable=SC1091
set -a; source "$HERE/.env"; set +a
B="${BRIDGE_URL%/}"
AUTH=(-u "${BRIDGE_USER}:${BRIDGE_PASS}")

log()  { printf '\033[1;36m▶ %s\033[0m\n' "$*"; }
ok()   { printf '\033[1;32m  ✓ %s\033[0m\n' "$*"; }
fail() { printf '\033[1;31m  ✗ %s\033[0m\n' "$*" >&2; exit 1; }

# Mint a short-TTL presigned GET URL for an R2 object_key. Abstracted so the
# host can change without touching the install logic.
mint_url() {
  local object_key="$1"
  rclone link --expire "${PRESIGN_TTL}s" "${R2_REMOTE}:${BUCKET}/${object_key}" 2>/dev/null \
    || fail "presign failed for ${object_key} (is the '${R2_REMOTE}' rclone remote configured?)"
}

manifest_field() { python3 -c "import json,sys;a=[x for x in json.load(open('$MANIFEST'))['artifacts'] if x['name']==sys.argv[1]][0];print(a[sys.argv[2]])" "$1" "$2"; }
BUCKET="$(python3 -c "import json;print(json.load(open('$MANIFEST'))['bucket'])")"

post() { # post <path> <json>
  curl -fsS "${AUTH[@]}" -X POST -H 'Content-Type: application/json' -d "$2" "${B}/$1"
}

# ── Premium delivery: token mode (customer) vs rclone mode (operator) ──────────
# Customer flow: deploy.sh provides STORE_DROP_TOKEN; we ask MEGA for the
# presigned premium URLs (MEGA holds the R2 keys + gates on credit balance).
# No token → fall back to operator-side rclone presigning below.
STORE_DROP_TOKEN="${STORE_DROP_TOKEN:-}"
MEGA_STORE_DROP_ENDPOINT="${MEGA_STORE_DROP_ENDPOINT:-https://mega-worker-production.up.railway.app/store-drop/premium-manifest}"
PREMIUM_MANIFEST_JSON=""   # populated in token mode

fetch_premium_manifest() {
  [[ -z "$STORE_DROP_TOKEN" ]] && return 0   # operator/rclone mode
  log "Requesting premium plugins from MEGA (token-gated)…"
  local resp
  resp="$(curl -sS --max-time 30 -X POST -H 'Content-Type: application/json' \
    -d "{\"token\":\"${STORE_DROP_TOKEN}\"}" "$MEGA_STORE_DROP_ENDPOINT" 2>/dev/null)"
  if ! printf '%s' "$resp" | grep -q '"artifacts"'; then
    local msg
    msg="$(printf '%s' "$resp" | python3 -c 'import json,sys;print(json.load(sys.stdin).get("error","unreadable response"))' 2>/dev/null || printf '%s' "$resp")"
    fail "MEGA declined the store-drop token: ${msg}"
  fi
  PREMIUM_MANIFEST_JSON="$resp"
  ok "premium manifest received ($(printf '%s' "$resp" | python3 -c 'import json,sys;print(len(json.load(sys.stdin)["artifacts"]))' 2>/dev/null) artifacts, keys never left MEGA)"
}

# premium_field <name> <field> — read a field from the token-fetched manifest.
premium_field() {
  python3 -c "import json,sys;a=[x for x in json.loads(sys.argv[3])['artifacts'] if x['name']==sys.argv[1]][0];print(a.get(sys.argv[2],''))" \
    "$1" "$2" "$PREMIUM_MANIFEST_JSON"
}

# post_retry <path> <json> — POST and retry on transient failure. The
# free-plugin installs pull from wp.org synchronously; on a slow host the
# download can exceed the bridge's PHP max_execution_time and 500 mid-run.
# The install-and-activate endpoint is idempotent (already-installed returns
# success:true), so retrying converges. Without this, a single transient 500
# aborts the whole stack install — observed twice in one run on a fresh box.
# Echoes the last response body; returns non-zero only if every attempt failed.
post_retry() {
  local path="$1" body="$2" attempts="${POST_ATTEMPTS:-6}" i r
  for ((i=1; i<=attempts; i++)); do
    r="$(curl -sS --max-time 180 "${AUTH[@]}" -X POST -H 'Content-Type: application/json' -d "$body" "${B}/${path}" 2>/dev/null)"
    if printf '%s' "$r" | grep -q '"success":true'; then printf '%s' "$r"; return 0; fi
    [[ $i -lt $attempts ]] && { printf '\033[1;33m  … attempt %d/%d failed, retrying in 4s\033[0m\n' "$i" "$attempts" >&2; sleep 4; }
  done
  printf '%s' "$r"; return 1
}

install_free_plugin() { # slug
  log "free plugin: $1"
  [[ $DRY_RUN == 1 ]] && { ok "(dry-run) would install-and-activate $1"; return; }
  local r; r="$(post_retry 'plugins/install-and-activate' "{\"slug\":\"$1\"}")" \
    && ok "$1: $(echo "$r" | python3 -c 'import sys,json;d=json.load(sys.stdin);print(d.get("message",d.get("plugin","")))')" \
    || fail "$1 -> $r"
}

install_premium_plugin() { # artifact-name
  local name="$1" sha url
  log "premium plugin: $name"
  if [[ -n "$PREMIUM_MANIFEST_JSON" ]]; then           # token mode (customer)
    sha="$(premium_field "$name" sha256)"
    [[ $DRY_RUN == 1 ]] && { ok "(dry-run) $name (token)"; return; }
    url="$(premium_field "$name" url)"
  else                                                  # rclone mode (operator)
    local key; key="$(manifest_field "$name" object_key)"; sha="$(manifest_field "$name" sha256)"
    [[ $DRY_RUN == 1 ]] && { ok "(dry-run) would mint+install $key sha=${sha:0:12}…"; return; }
    url="$(mint_url "$key")"
  fi
  local r; r="$(post_retry 'plugins/install-and-activate' "{\"zip_url\":\"$url\",\"sha256\":\"$sha\"}")" \
    && ok "$name installed (sha-verified)" \
    || fail "$name -> $r"
}

install_premium_theme() { # artifact-name
  local name="$1" sha sty url
  log "premium theme: $name"
  if [[ -n "$PREMIUM_MANIFEST_JSON" ]]; then           # token mode (customer)
    sha="$(premium_field "$name" sha256)"; sty="$(premium_field "$name" stylesheet)"
    [[ $DRY_RUN == 1 ]] && { ok "(dry-run) theme $name (token)"; return; }
    url="$(premium_field "$name" url)"
  else                                                  # rclone mode (operator)
    local key; key="$(manifest_field "$name" object_key)"; sha="$(manifest_field "$name" sha256)"; sty="$(manifest_field "$name" stylesheet)"
    [[ $DRY_RUN == 1 ]] && { ok "(dry-run) would mint+install theme $key stylesheet=$sty"; return; }
    url="$(mint_url "$key")"
  fi
  local r; r="$(post_retry 'themes/install-from-url' "{\"url\":\"$url\",\"sha256\":\"$sha\",\"stylesheet\":\"$sty\",\"activate\":true}")" \
    && ok "$name installed + activated" \
    || fail "$name -> $r"
}

# --- Order matters: theme first, then free blocks, then pro blocks, then the rest ---
log "Stack install → ${BRIDGE_SITE}"
fetch_premium_manifest   # token mode: pulls presigned premium URLs from MEGA

install_premium_theme  "Kadence"               # Kadence theme 1.5.0 (R2)
install_free_plugin    "kadence-blocks"        # free blocks (Pro depends on it)
install_premium_plugin "Kadence Blocks Pro"    # productcarousel etc. (R2)
install_free_plugin    "woocommerce"
install_free_plugin    "woo-stripe-payment"    # Stripe gateway (customer connects acct, phase 2)
install_free_plugin    "printful-shipping-for-woocommerce"  # Printful POD integration (customer connects acct, phase 2)
install_free_plugin    "fluentform"            # free FF (Pro extends it)
install_premium_plugin "Fluent Forms Pro"      # (R2)
install_free_plugin    "fluent-crm"            # free FluentCRM base (Pro/Campaign extends it)
install_premium_plugin "FluentCRM Pro"         # (R2) slug fluentcampaign-pro
install_free_plugin    "seo-by-rank-math"
install_free_plugin    "litespeed-cache"       # idempotent if already active

# --- Verify ---
log "Post-install verification"
curl -fsS "${AUTH[@]}" "${B}/info" | python3 -c "import sys,json;d=json.load(sys.stdin);print('  theme:',d.get('theme'),'| woo:',d.get('woocommerce_active'),'| kadence_pro:',d.get('kadence_pro_active'))"
curl -fsS "${AUTH[@]}" -X POST "${B}/cache/flush" >/dev/null && ok "cache flushed"
ok "stack install complete"
