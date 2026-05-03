#!/usr/bin/env bash
# Read keys from intake.json.

INTAKE_FILE="${ARTIFACTS_DIR:-/tmp/archon-artifacts}/intake.json"

intake_get() {
  [ -f "$INTAKE_FILE" ] || { echo ""; return 1; }
  python3 -c "import sys,json;print(json.load(open('$INTAKE_FILE')).get('$1',''))" 2>/dev/null
}

intake_mode()  { intake_get mode; }
intake_brand() { intake_get brand_name; }
intake_color() { intake_get color; }
