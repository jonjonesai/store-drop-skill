#!/usr/bin/env bash
# Compatibility entrypoint. Provider authentication belongs to Archon's native
# adapters; Store Drop never reads or re-exports provider credential files.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

if [ "$#" -ge 3 ] && [ "$1" = workflow ] && [ "$2" = run ] && [ "$3" = deploy-pod-store ]; then
  shift 3
  exec python3 scripts/run-store-drop.py "$@"
fi

echo "run-archon.sh now delegates Store Drop provider selection." >&2
echo "Use: ./deploy.sh [--provider codex|claude|pi] [--model MODEL]" >&2
exit 2
