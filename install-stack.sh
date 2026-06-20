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
  local name="$1" key sha url
  key="$(manifest_field "$name" object_key)"; sha="$(manifest_field "$name" sha256)"
  log "premium plugin: $name ($key)"
  [[ $DRY_RUN == 1 ]] && { ok "(dry-run) would mint+install $key sha=${sha:0:12}…"; return; }
  url="$(mint_url "$key")"
  local r; r="$(post_retry 'plugins/install-and-activate' "{\"zip_url\":\"$url\",\"sha256\":\"$sha\"}")" \
    && ok "$name installed (sha-verified)" \
    || fail "$name -> $r"
}

install_premium_theme() { # artifact-name
  local name="$1" key sha sty url
  key="$(manifest_field "$name" object_key)"; sha="$(manifest_field "$name" sha256)"; sty="$(manifest_field "$name" stylesheet)"
  log "premium theme: $name ($key)"
  [[ $DRY_RUN == 1 ]] && { ok "(dry-run) would mint+install theme $key stylesheet=$sty"; return; }
  url="$(mint_url "$key")"
  local r; r="$(post_retry 'themes/install-from-url' "{\"url\":\"$url\",\"sha256\":\"$sha\",\"stylesheet\":\"$sty\",\"activate\":true}")" \
    && ok "$name installed + activated" \
    || fail "$name -> $r"
}

# --- Order matters: theme first, then free blocks, then pro blocks, then the rest ---
log "Stack install → ${BRIDGE_SITE}"

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
