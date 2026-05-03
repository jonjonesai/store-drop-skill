# Create Homepage

You are creating ONE page: the homepage. Do not touch any other page.

## Setup

```bash
source "$HOME/kadence-skill/mega-kadence-skill/.archon/lib/bridge.sh"
source "$HOME/kadence-skill/mega-kadence-skill/.archon/lib/intake.sh"
source "$HOME/kadence-skill/mega-kadence-skill/.archon/lib/pages.sh"
bridge_check_env || exit 1
```

Read intake from `$ARTIFACTS_DIR/intake.json`. Read the golden template at `templates/homepage.html` — it is proven block markup, do NOT modify the block structure.

## Steps

### 1. Substitute copy

In the template, replace:
- `CuteMerch` → intake `brand_name`
- "Adorable Designs, Everyday Products" → headline you generate from niche (≤ 7 words)
- "Cute animal illustrations on tees..." → subheadline you generate from niche (≤ 18 words)
- "Our Story" body → 2-sentence story from niche + brand_name
- `[fluentform id="2"]` → keep as-is unless `GET /wp-json/fluentform/v1/forms` returns a different ID for the subscription form

**CRITICAL: every Kadence block in the markup must include `kbVersion:2` in its block attributes (e.g. `<!-- wp:kadence/rowlayout {"uniqueID":"..._12","kbVersion":2} -->`). Without it, Kadence's CSS engine will not emit the per-block CSS and the page will look broken.**

### 2. Create the page

```
POST /pages/ensure  with  {"title":"<brand_name>","slug":"home","status":"publish","type":"page","content":"<transformed-html>"}
```

Save the returned `id`.

### 3. Force-publish + set required meta

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

`_kad_post_vertical_padding` MUST be `"disable"`. The value `"hide"` does nothing and leaves a white gap above the hero.

### 4. Write artifact

```bash
pages_write_one home <ID> /
```

Then print one line: `CREATED: home id=<ID>` and stop.
