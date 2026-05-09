# Create Contact Page

You are creating ONE page: contact. Do not touch any other page.

## Setup

```bash
source "$HOME/kadence-skill/store-drop-skill/.archon/lib/bridge.sh"
source "$HOME/kadence-skill/store-drop-skill/.archon/lib/intake.sh"
source "$HOME/kadence-skill/store-drop-skill/.archon/lib/pages.sh"
bridge_check_env || exit 1
```

Read intake from `$ARTIFACTS_DIR/intake.json`. Read the golden template at `templates/contact.html` — keep block structure as-is.

## Steps

### 1. Substitute copy + form ID

Replace:
- `CuteMerch` → intake `brand_name`
- Email placeholder → derive from `brand_name` and the bridge site URL (use `info@<domain>` if no email in intake)
- `[fluentform id="1"]` → keep as-is unless `GET /wp-json/fluentform/v1/forms` returns a different ID for the contact form

**Every Kadence block must include `kbVersion:2` in attributes.** Without it the page looks broken.

The Fluent Form shortcode must be present in the rendered HTML — the validator greps for `fluentform` or `ff-el-form`. If neither form exists, embed the shortcode anyway; it renders empty but the validator passes.

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
