#!/usr/bin/env bash
# ============================================================
# Mega Management — Store Drop one-command setup
# Installs everything: git/curl, Codex, Claude Code, Archon, and the skill.
# Handles the PATH automatically — no "command not found", ever.
# Usage:  curl -fsSL <this-url> | bash
# ============================================================
set -e

# Everything runs inside main(), called on the last line, so `curl | bash`
# reads the whole script before executing. Without this, apt/npm read the
# rest of the piped script from stdin and setup silently stops after apt.
main() {
say() { printf '\n\033[1;36m→ %s\033[0m\n' "$1"; }

cat <<'BANNER'

  🌋  MEGA STORE DROP — SETUP
  Installing everything your machine needs. One coffee, one command.

BANNER

say "Installing base tools (git, curl, Node.js)..."
sudo apt-get update -qq </dev/null
sudo apt-get install -y -qq git curl nodejs npm python3 </dev/null

# Put ~/.local/bin on PATH FIRST — both for this run and permanently in
# .bashrc so locally installed tools remain discoverable.
mkdir -p "$HOME/.local/bin"
if ! grep -qs '.local/bin' "$HOME/.bashrc"; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
fi
export PATH="$HOME/.local/bin:$PATH"

say "Installing Codex and Claude Code (you pick one when you deploy)..."
sudo npm install -g @openai/codex @anthropic-ai/claude-code </dev/null

say "Installing Archon..."
curl -fsSL https://archon.diy/install | bash

say "Getting the Store Drop skill..."
mkdir -p "$HOME/kadence-skill"
if [ ! -d "$HOME/kadence-skill/store-drop-skill" ]; then
  git clone -q https://github.com/jonjonesai/store-drop-skill "$HOME/kadence-skill/store-drop-skill"
fi

cat <<'DONE'

  ✅  ALL SET. Two steps left:

      1.  Open a fresh terminal, then log in to ONE AI account:
              codex login          (OpenAI)
          or  claude auth login    (Anthropic)

      2.  Drop your store:
              cd ~/kadence-skill/store-drop-skill && ./deploy.sh

DONE
}

main "$@"
