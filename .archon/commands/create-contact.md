# Create Contact Page

You are creating ONE page: contact. Do not touch any other page.

**Heartbeat rule:** every ~20 seconds during your work, echo a single status line to stdout starting with `[contact]` so the user watching the terminal knows you are still active. Examples: `[contact] reading intake`, `[contact] generating copy`, `[contact] calling bridge`.

## Setup

```bash
source "$HOME/kadence-skill/mega-kadence-skill/.archon/lib/bridge.sh"
source "$HOME/kadence-skill/mega-kadence-skill/.archon/lib/intake.sh"
source "$HOME/kadence-skill/mega-kadence-skill/.archon/lib/pages.sh"
bridge_check_env || exit 1
```

Read intake from `$ARTIFACTS_DIR/intake.json`. Read the golden template at `templates/contact.html` — keep block structure as-is.

## Steps

### 1. Substitute copy and replace form area with email CTA

Replace in the template:
- `CuteMerch` → intake `brand_name`
- Email placeholder → derive `info@<domain>` from the bridge site URL
- **`[fluentform id="1"]` shortcode → REMOVE entirely. Replace with a Kadence info-box block that has:**
  - A heading: "Email us"
  - A paragraph: "We read every message and reply within one business day."
  - A button styled with `kb-btn-global-fill` linking to `mailto:info@<domain>`

**Why no Fluent Form by default:** Fluent Forms' REST API silently drops form_fields content sent via App Password auth, so the workflow cannot reliably pre-create a form with input fields. The graceful path is to ship a clean email CTA out of the box. Students can later replace this block with `[fluentform id=N]` after creating a form via the FF admin UI (~30 seconds).

**Every Kadence block must include `kbVersion:2` in attributes.** Without it the page looks broken.

The page must contain a `mailto:` link in the rendered HTML — the validator greps for `mailto:`. If you fail to embed one, the validator halts loud.

### 2. Create the page

```
POST /pages/ensure  with  {"title":"Contact","slug":"contact","status":"publish","type":"page","content":"<transformed-html>"}
```

Save the returned `id`.

### 3. Force-publish + meta

```
POST /posts/{id}  with  {
  "status":"publish",
  "meta":{
    "_kad_post_title":"hide",
    "_kad_post_feature":"hide",
    "_kad_post_vertical_padding":"disable",
    "_kad_post_layout":"fullwidth",
    "_kad_post_transparent":"enable"
  }
}
```

### 4. Write artifact

```bash
pages_write_one contact <ID> /contact/
```

Then print one line: `CREATED: contact id=<ID>` and stop.
