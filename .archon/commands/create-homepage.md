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

### 1. Substitute copy → write content file (structure preserved byte-for-byte)

Do the substitution with python `.replace()` on the template file so block structure (maxWidth, kbVersion, padding, real newlines) is preserved exactly — only the copy strings change. Generate the brand copy first, then run a single python step with those strings:

```bash
python3 - <<'PY'
brand       = "BRAND_NAME_FROM_INTAKE"
headline    = "HEADLINE you generate from niche, <= 7 words"
subheadline = "SUBHEADLINE you generate from niche, <= 18 words"
story       = "Two-sentence brand story from niche + brand_name."
src = open("templates/homepage.html", encoding="utf-8").read()
src = src.replace("CuteMerch", brand)
src = src.replace("Adorable Designs, Everyday Products", headline)
src = src.replace("Cute animal illustrations on tees, hoodies, mugs, and more. Quality products that make you smile.", subheadline)
# Replace the "Our Story" body paragraph with `story` (match the exact
# placeholder paragraph text in the template). Keep [fluentform id="2"] unless
# GET /wp-json/fluentform/v1/forms shows a different subscription-form ID.
open("/tmp/archon-artifacts/home-content.html", "w", encoding="utf-8").write(src)
print("home-content.html written")
PY
```

If a `.replace()` target string is not found it silently leaves the placeholder — that is acceptable (placeholder copy, intact structure) and far better than corrupting the page. Match the template strings exactly. **Do NOT modify block attributes; only change copy.** Every Kadence block already carries `kbVersion:2` in the template — leave it.

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
