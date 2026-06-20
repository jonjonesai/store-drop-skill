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

### 1. Substitute copy → write content file (structure preserved byte-for-byte)

Do the substitution with python `.replace()` on the template file so block structure (maxWidth, kbVersion, padding, real newlines) is preserved exactly — only the copy strings change. Generate the brand copy first, then run a single python step:

```bash
python3 - <<'PY'
brand = "BRAND_NAME_FROM_INTAKE"
src = open("templates/about.html", encoding="utf-8").read()
src = src.replace("CuteMerch", brand)
# Replace the story paragraphs (origin/mission/difference) and the 3 value
# descriptions with copy you generate from the niche, matching each exact
# placeholder string in the template. Do NOT touch block attributes.
open("/tmp/archon-artifacts/about-content.html", "w", encoding="utf-8").write(src)
print("about-content.html written")
PY
```

If a `.replace()` target is not found it silently leaves the placeholder — acceptable, and far better than corrupting the page. Match the template strings exactly. Every Kadence block already carries `kbVersion:2` — leave it.

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
