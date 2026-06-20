# Create Homepage

You are creating ONE page: the homepage. Do not touch any other page.

**Heartbeat rule:** every ~20 seconds during your work, echo a single status line to stdout starting with `[homepage]` so the user watching the terminal knows you are still active. Examples: `[homepage] reading intake`, `[homepage] generating hero copy`, `[homepage] composing brand story`, `[homepage] calling /pages/ensure`, `[homepage] writing artifact`.

## Setup

```bash
source "$HOME/kadence-skill/store-drop-skill/.archon/lib/bridge.sh"
source "$HOME/kadence-skill/store-drop-skill/.archon/lib/intake.sh"
source "$HOME/kadence-skill/store-drop-skill/.archon/lib/pages.sh"
bridge_check_env || exit 1
```

Read intake from `$ARTIFACTS_DIR/intake.json`.

> ⚠️ **NEVER inline page HTML into a JSON string yourself, and never POST `content` directly via curl.** Doing so corrupts every newline into the literal letter `n` (`\n` → `\\n` → wp_unslash → `n`), producing `>nn<` garbage across the page. Page content is written **only** by `pages_ensure_from_file`, which reads a file and encodes it correctly. Your job is to produce the substituted HTML *as a file*, nothing more.

## Steps

### 1. Fill the sentinel tokens → write content file (structure preserved byte-for-byte)

The template uses `{{SENTINEL}}` tokens for the brand-critical copy. Fill them with python `.replace()` so block structure (maxWidth, kbVersion, padding, real newlines) is preserved exactly. Generate copy from the niche in the BRAND VOICE, then run ONE python step. **Every `{{...}}` must be filled** — any left in the file HALTS the build (pages_ensure_from_file refuses content containing `{{`), so nothing half-substituted can ship.

```bash
python3 - <<'PY'
repl = {
  "{{HOME_HEADLINE}}": "hero H1 from niche, <= 7 words, brand voice",
  "{{HOME_SUBHEAD}}":  "hero subhead from niche, <= 18 words",
  "{{HOME_STORY_1}}":  "Our Story paragraph 1 — origin, brand voice",
  "{{HOME_STORY_2}}":  "Our Story paragraph 2 — craft / what makes it different",
  "{{BRAND}}":         "BRAND_NAME_FROM_INTAKE",
}
src = open("templates/homepage.html", encoding="utf-8").read()
for k, v in repl.items():
    src = src.replace(k, v)
# Keep [fluentform id="2"] unless GET /wp-json/fluentform/v1/forms shows a
# different subscription-form ID — then also .replace('id="2"','id="<that>"').
assert "{{" not in src, "unfilled sentinel remains: " + src[src.index("{{"):src.index("{{")+40]
open("/tmp/archon-artifacts/home-content.html", "w", encoding="utf-8").write(src)
print("home-content.html written, all sentinels filled")
PY
```

The generic trust badges and section headings carry no token and stay as-is — that's fine, they're brand-neutral. **Do NOT modify block attributes; only fill tokens.** The `assert "{{" not in src` is a safety net — if it trips, fix the dict and re-run.

### 2. Create + force-overwrite the page (deterministic write)

```bash
ID=$(pages_ensure_from_file home "BRAND_NAME_FROM_INTAKE" /tmp/archon-artifacts/home-content.html)
echo "home id=$ID"
```

`pages_ensure_from_file` both creates the page **and** force-overwrites its body from the file (correct JSON encoding), so it is safe to re-run and robust to a pre-existing "home" page. Do NOT POST `content` any other way.

### 3. Set required meta (no content here)

```bash
bridge_post "/posts/$ID" '{"status":"publish","meta":{"_kad_post_title":"hide","_kad_post_feature":"hide","_kad_post_vertical_padding":"disable","_kad_post_layout":"fullwidth","_kad_post_transparent":"disable"}}' >/dev/null
```

`_kad_post_vertical_padding` MUST be `"disable"` (the value `"hide"` leaves a white gap above the hero). `_kad_post_transparent` MUST be `"disable"` (solid header — prevents the body invading the header).

### 4. Write artifact

```bash
pages_write_one home "$ID" /
```

Then print one line: `CREATED: home id=$ID` and stop.
