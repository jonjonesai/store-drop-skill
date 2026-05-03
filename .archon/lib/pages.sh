#!/usr/bin/env bash
# Per-page artifact helpers. Each create-* AI node writes one page-{slug}.json.
# A merge step combines them into pages.json for downstream consumers.
#
# IMPORTANT — multi-dir resolution:
# Archon AI sessions and bash nodes may resolve ARTIFACTS_DIR to *different*
# paths (each AI session can get its own conversation-hash dir, while bash
# nodes use the workflow-level dir). To survive that, this lib WRITES to both
# the active ARTIFACTS_DIR and a well-known fallback (/tmp/archon-artifacts),
# and READS from the union of both. Without this, AI-written artifacts may
# be invisible to subsequent bash nodes.

PAGES_DIR_PRIMARY="${ARTIFACTS_DIR:-/tmp/archon-artifacts}"
PAGES_DIR_FALLBACK="/tmp/archon-artifacts"
mkdir -p "$PAGES_DIR_PRIMARY"  2>/dev/null
mkdir -p "$PAGES_DIR_FALLBACK" 2>/dev/null

# Back-compat alias for older code that referenced PAGES_DIR.
PAGES_DIR="$PAGES_DIR_PRIMARY"

# pages_write_one <slug> <id> <url>
# Writes to BOTH the primary and fallback dirs so any reader can find it.
pages_write_one() {
  local slug="$1"
  local id="$2"
  local url="$3"
  local payload
  payload=$(python3 -c "import json,sys;json.dump({'id':int('$id'),'slug':'$slug','url':'$url'},sys.stdout)")
  printf '%s' "$payload" > "$PAGES_DIR_PRIMARY/page-${slug}.json"
  if [ "$PAGES_DIR_PRIMARY" != "$PAGES_DIR_FALLBACK" ]; then
    printf '%s' "$payload" > "$PAGES_DIR_FALLBACK/page-${slug}.json"
  fi
}

# pages_merge  ->  writes pages.json (object keyed by slug) into BOTH dirs.
# Reads page-*.json from BOTH dirs; primary wins on duplicate slugs.
pages_merge() {
  python3 - "$PAGES_DIR_PRIMARY" "$PAGES_DIR_FALLBACK" <<'PY'
import os, sys, json, glob
dirs = sys.argv[1:]
out = {}
# Walk in REVERSE so the primary dir (first arg) overrides the fallback.
for d in reversed(dirs):
    for f in sorted(glob.glob(os.path.join(d, "page-*.json"))):
        try:
            with open(f) as fh:
                entry = json.load(fh)
        except Exception:
            continue
        slug = entry.get("slug")
        if slug:
            out[slug] = entry
for d in dirs:
    if not os.path.isdir(d):
        continue
    with open(os.path.join(d, "pages.json"), "w") as fh:
        json.dump(out, fh, indent=2)
print(f"merged {len(out)} pages into pages.json")
for slug, e in sorted(out.items()):
    print(f"  {slug}: id={e.get('id')} url={e.get('url')}")
PY
}

# pages_get_id <slug>  ->  prints page ID, searches both dirs
pages_get_id() {
  local slug="$1"
  local f
  for f in "$PAGES_DIR_PRIMARY/page-${slug}.json" "$PAGES_DIR_FALLBACK/page-${slug}.json"; do
    if [ -f "$f" ]; then
      python3 -c "import json,sys;print(json.load(open('$f')).get('id',''))" 2>/dev/null
      return 0
    fi
  done
  echo ""
  return 1
}

# pages_check_url <url-path>  ->  asserts render returns 200, prints PASS/FAIL
# Requires bridge.sh + assert.sh to be sourced first.
pages_check_url() {
  local url="$1"
  local desc="${2:-render $url}"
  local status
  status="$(bridge_render_status "$url")"
  if [ "$status" = "200" ]; then
    assert_pass "$desc (200)"
  else
    assert_fail "$desc — got $status"
  fi
}
