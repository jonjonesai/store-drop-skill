# Create Contact Page

You are creating ONE page: contact. Do not touch any other page.

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

Do the substitution with python `.replace()` on the template file so block structure (maxWidth, kbVersion, padding, real newlines) is preserved exactly — only the copy strings change. Run a single python step like this, with the real intake values:

```bash
python3 - <<'PY'
brand = "BRAND_NAME_FROM_INTAKE"
email = "info@DOMAIN"          # derive DOMAIN from the bridge site URL; or use intake email
src = open("templates/contact.html", encoding="utf-8").read()
src = src.replace("CuteMerch", brand)
src = src.replace("hello@cutemerch.love", email)
# Keep [fluentform id="1"] unless GET /wp-json/fluentform/v1/forms shows a
# different contact-form ID — then .replace('id="1"','id="<that>"').
open("/tmp/archon-artifacts/contact-content.html", "w", encoding="utf-8").write(src)
print("contact-content.html written")
PY
```

The Fluent Form shortcode must survive into the file — the validator greps the render for `fluentform` / `ff-el-form`. The empty form still renders and passes.

### 2. Create + force-overwrite the page (deterministic write)

```bash
ID=$(pages_ensure_from_file contact "Contact" /tmp/archon-artifacts/contact-content.html)
echo "contact id=$ID"
```

This both creates the page and force-overwrites its body from the file with correct JSON encoding. Do NOT POST `content` any other way.

### 3. Set required meta (no content here)

```bash
bridge_post "/posts/$ID" '{"status":"publish","meta":{"_kad_post_title":"hide","_kad_post_feature":"hide","_kad_post_vertical_padding":"disable","_kad_post_layout":"fullwidth","_kad_post_transparent":"enable"}}' >/dev/null
```

### 4. Write artifact

```bash
pages_write_one contact "$ID" /contact/
```

Then print one line: `CREATED: contact id=$ID` and stop.
