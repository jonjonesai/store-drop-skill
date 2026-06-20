# Create About Page

You are creating ONE page: about. Do not touch any other page.

**Heartbeat rule:** every ~20 seconds during your work, echo a single status line to stdout starting with `[about]` so the user watching the terminal knows you are still active. Examples: `[about] reading intake`, `[about] generating brand story`, `[about] calling /pages/ensure`.

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

The template uses `{{SENTINEL}}` tokens for every piece of brand copy. Fill them with python `.replace()` so block structure (maxWidth, kbVersion, padding, real newlines) is preserved exactly. Generate copy from the niche, then run ONE python step. **You must replace every token below** — any `{{...}}` left in the file will HALT the build (pages_ensure_from_file refuses content containing `{{`), so nothing half-substituted can ever ship.

```bash
python3 - <<'PY'
repl = {
  "{{BRAND}}":            "BRAND_NAME_FROM_INTAKE",
  "{{ABOUT_SUB}}":        "one-line hero subhead from the niche",
  "{{ABOUT_STORY_1}}":    "origin paragraph — why this brand exists, in the brand voice",
  "{{ABOUT_STORY_2}}":    "second paragraph — mission / what makes it different",
  "{{ABOUT_VAL1_TITLE}}": "value 1 title (2-3 words)",
  "{{ABOUT_VAL1_DESC}}":  "value 1 description (1-2 sentences from the niche)",
  "{{ABOUT_VAL2_TITLE}}": "value 2 title",
  "{{ABOUT_VAL2_DESC}}":  "value 2 description",
  "{{ABOUT_VAL3_TITLE}}": "value 3 title",
  "{{ABOUT_VAL3_DESC}}":  "value 3 description",
  "{{ABOUT_CTA_HEADING}}":"closing CTA heading, in the brand voice",
}
src = open("templates/about.html", encoding="utf-8").read()
for k, v in repl.items():
    src = src.replace(k, v)
assert "{{" not in src, "unfilled sentinel remains: " + src[src.index("{{"):src.index("{{")+40]
open("/tmp/archon-artifacts/about-content.html", "w", encoding="utf-8").write(src)
print("about-content.html written, all sentinels filled")
PY
```

Write copy in the BRAND VOICE from the intake niche — never generic. Do NOT touch block attributes; only fill the tokens. The `assert "{{" not in src` line is a safety net — if it trips, you missed a token; fix the dict and re-run.

### 2. Create + force-overwrite the page (deterministic write)

```bash
ID=$(pages_ensure_from_file about "About" /tmp/archon-artifacts/about-content.html)
echo "about id=$ID"
```

This both creates the page and force-overwrites its body from the file with correct JSON encoding. Do NOT POST `content` any other way.

### 3. Set required meta (no content here)

```bash
bridge_post "/posts/$ID" '{"status":"publish","meta":{"_kad_post_title":"hide","_kad_post_feature":"hide","_kad_post_vertical_padding":"disable","_kad_post_layout":"fullwidth","_kad_post_transparent":"enable"}}' >/dev/null
```

### 4. Write artifact

```bash
pages_write_one about "$ID" /about/
```

Then print one line: `CREATED: about id=$ID` and stop.
