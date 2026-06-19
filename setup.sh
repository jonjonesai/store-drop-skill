#!/usr/bin/env bash
# ============================================================
# Mega Management — Store Drop one-command setup
# Installs everything: git/curl, Claude Code, Archon, the skill.
# Handles the PATH automatically — no "command not found", ever.
# Usage:  curl -fsSL <this-url> | bash
# ============================================================
set -e

say() { printf '\n\033[1;36m→ %s\033[0m\n' "$1"; }

cat <<'BANNER'

  🌋  MEGA STORE DROP — SETUP
  Installing everything your machine needs. One coffee, one command.

BANNER

say "Installing base tools (git, curl)..."
sudo apt-get update -qq
sudo apt-get install -y -qq git curl

say "Installing Claude Code..."
curl -fsSL https://claude.ai/install.sh | bash

# Put Claude (and friends) on PATH permanently — silently, so the user
# never sees a "command not found" or has to run anything by hand.
if ! grep -qs '.local/bin' "$HOME/.bashrc"; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
fi
export PATH="$HOME/.local/bin:$PATH"

say "Installing Archon..."
curl -fsSL https://archon.diy/install | bash

say "Getting the Store Drop skill..."
mkdir -p "$HOME/kadence-skill"
if [ ! -d "$HOME/kadence-skill/store-drop-skill" ]; then
  git clone -q https://github.com/jonjonesai/store-drop-skill "$HOME/kadence-skill/store-drop-skill"
fi

cat <<'DONE'

  ✅  ALL SET. Two steps left:

      1.  Open a fresh terminal, then log in to Claude:
              claude

      2.  Drop your store:
              cd ~/kadence-skill/store-drop-skill && ./deploy.sh

DONE
