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

Read intake from `$ARTIFACTS_DIR/intake.json`. Read the golden template at `templates/about.html` — keep block structure as-is.

## Steps

### 1. Substitute copy

Replace in the template:
- `CuteMerch` → intake `brand_name`
- Story copy → 3-paragraph story you generate from niche + brand_name (origin, mission, what makes you different)
- Value descriptions (3 of them) → derive from niche

**Every Kadence block must include `kbVersion:2` in attributes.** Otherwise the CSS engine drops the block.

### 2. Create the page

```
POST /pages/ensure  with  {"title":"About","slug":"about","status":"publish","type":"page","content":"<transformed-html>"}
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
pages_write_one about <ID> /about/
```

Then print one line: `CREATED: about id=<ID>` and stop.
