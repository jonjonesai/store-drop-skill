#!/usr/bin/env bash
# deploy.sh — single entry point. Asks for credentials and store details
# interactively (no editor required), then runs the Archon deploy workflow.
#
# Usage:
#   ./deploy.sh              # interactive — prompts for anything missing
#   ./deploy.sh --reset      # re-prompt even if .env / intake.json exist
#   ./deploy.sh --intake     # only refresh intake.json, keep .env
#
# Pre-requisites: Archon CLI plus Codex, Claude, or Pi. Interactive runs ask
# which provider to use and open its native login flow when authentication is
# missing. Explicit --provider/--model flags keep automated runs non-interactive.

set -euo pipefail
cd "$(dirname "$0")"

RESET_ENV=0
RESET_INTAKE=0
PROVIDER=""
MODEL=""
DRY_RUN=0
ARCHON_DRY_RUN=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --reset) RESET_ENV=1; RESET_INTAKE=1 ;;
    --intake) RESET_INTAKE=1 ;;
    --provider) shift; PROVIDER="${1:?--provider requires codex, claude, or pi}" ;;
    --model) shift; MODEL="${1:?--model requires a model id}" ;;
    --dry-run) DRY_RUN=1 ;;
    --archon-dry-run) ARCHON_DRY_RUN=1 ;;
    --validate)
      python3 -m unittest discover -s tests -v
      archon validate workflows deploy-pod-store
      archon validate commands
      exit 0 ;;
    --help|-h)
      sed -n '2,16p' "$0" | sed 's/^# //'
      exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done

build_runner() {
  RUNNER=(python3 scripts/run-store-drop.py)
  [ -z "$PROVIDER" ] || RUNNER+=(--provider "$PROVIDER")
  [ -z "$MODEL" ] || RUNNER+=(--model "$MODEL")
}

build_runner
if [ "$DRY_RUN" = 1 ]; then
  "${RUNNER[@]}" --dry-run
  exit $?
fi
if [ "$ARCHON_DRY_RUN" = 1 ]; then
  "${RUNNER[@]}" --archon-dry-run
  exit $?
fi

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
# Step 0 — AI provider and account login
# ============================================================

if [ -z "$PROVIDER" ]; then
  if [ ! -t 0 ]; then
    fail "No interactive terminal. Choose an AI with --provider codex, --provider claude, or --provider pi."
  fi

  echo
  say "===== Choose your AI ====="
  echo "Store Drop can use your own account with any supported provider:"
  echo "  1) Codex (OpenAI)"
  echo "  2) Claude (Anthropic)"
  echo "  3) Pi (other supported or OpenAI-compatible models)"
  while true; do
    read -r -p "  Choose 1, 2, or 3: " PROVIDER_CHOICE
    case "$PROVIDER_CHOICE" in
      1|codex) PROVIDER="codex"; break ;;
      2|claude) PROVIDER="claude"; break ;;
      3|pi) PROVIDER="pi"; break ;;
      *) warn "Please choose 1, 2, or 3." ;;
    esac
  done
fi

if [ "$PROVIDER" = "pi" ] && [ -z "$MODEL" ]; then
  if [ ! -t 0 ]; then
    fail "Pi automation requires --model backend/model."
  fi
  read -r -p "  Pi model (backend/model) [openai/gpt-5.6]: " MODEL
  MODEL="${MODEL:-openai/gpt-5.6}"
fi

build_runner
if ! "${RUNNER[@]}" --check-auth; then
  echo
  if [ ! -t 0 ]; then
    fail "The selected provider is not authenticated. Log in interactively, then re-run this command."
  fi
  case "$PROVIDER" in
    codex)
      LOGIN_LABEL="Codex"
      LOGIN_COMMAND=(codex login)
      ;;
    claude)
      LOGIN_LABEL="Claude"
      LOGIN_COMMAND=(claude)
      echo "In Claude, run /login, complete authentication, then run /exit to return here."
      ;;
    pi)
      LOGIN_LABEL="Pi"
      LOGIN_COMMAND=(pi /login)
      ;;
  esac
  say "===== Connect your ${LOGIN_LABEL} account ====="
  read -r -p "  Start the secure ${LOGIN_LABEL} login now? [Y/n]: " START_LOGIN
  case "${START_LOGIN:-y}" in
    y|Y|yes|YES) ;;
    *) fail "Login is required before deployment. Re-run when you are ready." ;;
  esac
  command -v "${LOGIN_COMMAND[0]}" >/dev/null 2>&1 || \
    fail "${LOGIN_COMMAND[0]} is not installed or not on PATH. Install it, then re-run Store Drop."
  "${LOGIN_COMMAND[@]}"
  "${RUNNER[@]}" --check-auth || \
    fail "${LOGIN_LABEL} authentication was not detected. Complete login, then re-run Store Drop."
fi
ok "Using your ${PROVIDER} account"

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

# Parse, never source, dotenv. Values containing spaces, quotes, hashes, or
# application-password groupings remain data and are never shell code.
python3 scripts/config-file.py validate .env || fail ".env is not valid dotenv"
python3 scripts/config-file.py set .env AI_PROVIDER "$PROVIDER"
if [ -n "$MODEL" ]; then
  python3 scripts/config-file.py set .env AI_MODEL "$MODEL"
fi
BRIDGE_URL="$(python3 scripts/config-file.py get .env BRIDGE_URL)"
BRIDGE_USER="$(python3 scripts/config-file.py get .env BRIDGE_USER)"
BRIDGE_PASS="$(python3 scripts/config-file.py get .env BRIDGE_PASS)"
BRIDGE_SITE="$(python3 scripts/config-file.py get .env BRIDGE_SITE)"
: "${BRIDGE_USER:=store-drop-agent}"
export BRIDGE_URL BRIDGE_USER BRIDGE_PASS BRIDGE_SITE
source .archon/lib/bridge.sh
INFO="$(bridge_get "/info" || true)"
if ! printf '%s' "$INFO" | grep -q '"success":true'; then
  fail "Could not reach bridge at $BRIDGE_URL. Check that the plugin is active and your credentials are correct."
fi
SITE_NAME="$(printf '%s' "$INFO" | python3 -c 'import json,sys;print(json.load(sys.stdin).get("name",""))' 2>/dev/null || echo '')"
ok "Bridge reachable — site: $SITE_NAME"

# ============================================================
# Step 1a — store-drop token (proves you're a paid MEGA member)
# ============================================================
# The token gates the licensed premium plugins: install-stack.sh sends it to
# MEGA, which checks your credit balance and hands back the download links.
# Buying credits includes the store-drop skill. Stored in .env for install-stack.
if [ "$RESET_ENV" = 1 ] || ! grep -q '^STORE_DROP_TOKEN=' .env 2>/dev/null; then
  echo
  say "===== Store-drop token ====="
  echo "Paste your store-drop token (MEGA → Settings → Generate store-drop token)."
  echo "Leave blank only if your site already has the premium stack installed."
  read -r -p "  Token: " SDT
  if [ -n "$SDT" ]; then
    python3 scripts/config-file.py set .env STORE_DROP_TOKEN "$SDT"
    ok "Token saved"
  fi
fi

# ============================================================
# Step 1b — ensure the store stack is installed
# ============================================================
# deploy-pod-store assumes Kadence + WooCommerce + the Fluent stack are present.
# On a fresh site they aren't, so install them now via install-stack.sh (which
# reuses the .env we just wrote). If the stack is already there we skip it.
# This is what makes deploy.sh a single command end-to-end.
STACK_OK="$(printf '%s' "$INFO" | python3 -c '
import json,sys
try:
    d=json.load(sys.stdin)
    print("yes" if (bool(d.get("woocommerce_active")) and str(d.get("theme","")).lower().startswith("kadence")) else "no")
except Exception:
    print("no")' 2>/dev/null)"
if [ "$STACK_OK" = "yes" ]; then
  ok "Store stack already installed"
else
  echo
  say "===== Installing store stack ====="
  echo "Your site needs the Kadence theme + store plugins. Installing now (~2-3 min)…"
  echo
  [ -x ./install-stack.sh ] || fail "install-stack.sh not found or not executable."
  ./install-stack.sh || fail "Stack install failed — see the output above, then re-run ./deploy.sh"
  ok "Store stack installed"
fi

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
  'facts': {
    'confirmed_organization_facts': [],
    'approved_policies': {
      'shipping': '', 'returns': '', 'guarantee': '',
      'donation_impact': '', 'service_levels': '',
    },
  },
  'launch': {'enable_sales': False, 'approved_by': ''},
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

"${RUNNER[@]}"
