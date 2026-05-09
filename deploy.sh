#!/usr/bin/env bash
# deploy.sh — single entry point. Asks for credentials and store details
# interactively (no editor required), then runs the Archon deploy workflow.
#
# Usage:
#   ./deploy.sh              # interactive — prompts for anything missing
#   ./deploy.sh --reset      # re-prompt even if .env / intake.json exist
#   ./deploy.sh --intake     # only refresh intake.json, keep .env
#
# Pre-requisites (one-time setup, see README): WSL (if Windows), Claude Code,
# Archon CLI, this repo cloned to ~/kadence-skill/store-drop-skill.

set -euo pipefail
cd "$(dirname "$0")"

RESET_ENV=0
RESET_INTAKE=0
case "${1:-}" in
  --reset) RESET_ENV=1; RESET_INTAKE=1 ;;
  --intake) RESET_INTAKE=1 ;;
  --help|-h)
    sed -n '2,12p' "$0" | sed 's/^# //'
    exit 0 ;;
esac

# $'...' makes bash interpret the escape sequences (vs. literal backslashes)
GREEN=$'\033[0;32m'; CYAN=$'\033[0;36m'; YELLOW=$'\033[0;33m'; RED=$'\033[0;31m'; BOLD=$'\033[1m'; NC=$'\033[0m'
say()  { printf '%s%s%s\n' "$CYAN" "$1" "$NC"; }
ok()   { printf '%s✓ %s%s\n' "$GREEN" "$1" "$NC"; }
warn() { printf '%s! %s%s\n' "$YELLOW" "$1" "$NC"; }
fail() { printf '%s✗ %s%s\n' "$RED" "$1" "$NC" >&2; exit 1; }

cat <<BANNER

${BOLD}Mega Kadence Deploy${NC}
This will set up your branded WordPress storefront on the site whose
bridge credentials you provide. Takes about 17 minutes total — 2 min
of interactive prompts up front, then ~15 min of automated build.
Press Ctrl+C anytime to cancel.

BANNER

# ============================================================
# Step 1 — bridge credentials
# ============================================================

if [ "$RESET_ENV" = 1 ] || [ ! -s .env ]; then
  echo
  say "===== Bridge credentials ====="
  echo "Go to WordPress: Settings → Mega Kadence Bridge"
  echo "Click 'Copy Environment Variables', then paste below."
  printf 'When done, press %sCtrl+D%s on a new line:\n' "$YELLOW" "$NC"
  echo
  cat > .env.tmp
  if ! grep -q "^BRIDGE_URL=" .env.tmp || ! grep -q "^BRIDGE_PASS=" .env.tmp; then
    rm -f .env.tmp
    fail ".env paste missing BRIDGE_URL or BRIDGE_PASS. Run again and paste the full env block."
  fi
  mv .env.tmp .env
  ok "Saved bridge credentials to .env"
else
  ok "Using existing .env (run with --reset to re-enter)"
fi

# Quick sanity: source the .env and try /info
set -a; . ./.env; set +a
: "${BRIDGE_USER:=claude-bot}"
INFO="$(curl -s --max-time 10 "${BRIDGE_URL}/info" -u "${BRIDGE_USER}:${BRIDGE_PASS}" || true)"
if ! printf '%s' "$INFO" | grep -q '"success":true'; then
  fail "Could not reach bridge at $BRIDGE_URL. Check that the plugin is active and your credentials are correct."
fi
SITE_NAME="$(printf '%s' "$INFO" | python3 -c 'import json,sys;print(json.load(sys.stdin).get("name",""))' 2>/dev/null || echo '')"
ok "Bridge reachable — site: $SITE_NAME"

# ============================================================
# Step 2 — intake (6 questions, interactive)
# ============================================================

ask_required() {
  local var="$1" prompt="$2" answer
  while true; do
    read -r -p "  $prompt: " answer
    if [ -n "$answer" ]; then
      printf -v "$var" '%s' "$answer"
      return
    fi
    warn "Required — please answer."
  done
}

ask_choice() {
  local var="$1" prompt="$2" choices="$3" answer
  local choice_pat="^($(echo "$choices" | tr '/' '|'))$"
  while true; do
    read -r -p "  $prompt [$choices]: " answer
    if echo "$answer" | grep -qE "$choice_pat"; then
      printf -v "$var" '%s' "$answer"
      return
    fi
    warn "Please answer one of: $choices"
  done
}

ask_hex() {
  local var="$1" prompt="$2" answer
  while true; do
    read -r -p "  $prompt: " answer
    if echo "$answer" | grep -qE '^#[0-9a-fA-F]{6}$'; then
      printf -v "$var" '%s' "$answer"
      return
    fi
    warn "Please enter a 6-digit hex like #FF1493 (include the #)."
  done
}

ask_optional() {
  local var="$1" prompt="$2" default="$3" answer
  read -r -p "  $prompt [$default]: " answer
  printf -v "$var" '%s' "${answer:-$default}"
}

if [ "$RESET_INTAKE" = 1 ] || [ ! -s intake.json ]; then
  echo
  say "===== Store details ====="
  echo "Tell me about your store. Six quick questions:"
  echo

  ask_required BRAND_NAME "Brand name (e.g. CuteMerch)"
  ask_required NICHE      "What do you sell? (one sentence — e.g. 'cute animal designs on tees and mugs')"
  ask_choice   MODE       "Light or dark mode" "light/dark"
  ask_hex      COLOR      "Brand color hex (e.g. #FF1493)"
  ask_optional CATEGORIES "Product categories (comma-separated)" "T-Shirts, Mugs, Tote Bags"
  ask_optional LOGO       "Logo URL, or 'skip' for text-only" "skip"

  BRAND_NAME="$BRAND_NAME" NICHE="$NICHE" MODE="$MODE" COLOR="$COLOR" \
  CATEGORIES="$CATEGORIES" LOGO="$LOGO" \
  python3 -c "
import json, os
data = {
  'brand_name': os.environ['BRAND_NAME'],
  'niche': os.environ['NICHE'],
  'mode': os.environ['MODE'],
  'color': os.environ['COLOR'],
  'categories': os.environ['CATEGORIES'],
  'logo': os.environ['LOGO'],
}
print(json.dumps(data, indent=2))
" > intake.json
  echo
  ok "Saved store details to intake.json"
else
  CURRENT_BRAND="$(python3 -c 'import json;print(json.load(open("intake.json")).get("brand_name",""))' 2>/dev/null || echo '')"
  ok "Using existing intake.json (brand: $CURRENT_BRAND — run with --intake to re-enter)"
fi

# ============================================================
# Step 3 — run the workflow
# ============================================================

echo
say "===== Deploying ====="
echo "Running the Archon workflow. Takes about 15 minutes."
echo "You'll see [node] Started/Completed lines as it progresses."
echo

# Filter cosmetic 'claude.rate_limit_event' log lines from Archon's stdout.
# These are billing-tier display warnings (mismatch between Pro tier rate limit
# and PAYG overage), purely cosmetic, but they read as broken to a fresh student.
# Suppressing them keeps the on-screen scroll focused on actual workflow events.
set -o pipefail
./.archon/scripts/run-archon.sh workflow run deploy-pod-store 2>&1 \
  | grep --line-buffered -v -E '"claude\.rate_limit_event"|"out_of_credits"'
