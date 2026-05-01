# Recipe: Deploy Homepage

> Builds the 7-section canonical homepage using Kadence Blocks via the MKB bridge API. Every block includes `kbVersion:2`. All spacing follows the Rule of 80-60-40.

## Inputs Required

| Input | Source | Example |
|---|---|---|
| `brand_name` | Intake Q1 | `CuteMerch` |
| `niche` | Intake Q2 | `funny golden retriever shirts` |
| `mode` | Intake Q3 | `dark` |
| `tagline` | Derived from niche + USP | `Original designs for retriever lovers` |
| `shop_url` | WooCommerce shop page | `/shop/` |
| `threshold` | Free shipping threshold | `$50` |

## Prerequisites

Before running this recipe:
1. Palette must be applied (`recipes/set-palette.md`)
2. Fonts must be applied (`recipes/set-fonts-by-tone.md`)
3. WooCommerce must be active (for shop URL and featured products section)

## The 7 Canonical Sections

Every deployed homepage has these in this order:

1. **Hero** — Full-width, dark overlay, centered white text, primary CTA
2. **Featured Products** — 4 desktop / 3 tablet / 1 mobile from WC
3. **Brand Story** — Two-column 50/50, image + AI-generated copy
4. **Trust Row** — 3 info boxes (Satisfaction / Shipping / Original Art)
5. **Secondary CTA Band** — Full-width accent band + "Shop the Collection"
6. **Newsletter Placeholder** — "Coming soon" info text (Phase 2: Fluent Forms)
7. **Footer** — Handled by `build-nav-menus.md` (theme_mods, not page content)

The footer is section 7 but is configured via theme_mods in `build-nav-menus`, not as page content. The homepage content itself has 6 sections.

## Execution

### Step 1: Generate unique IDs

Generate a 6-character alphanumeric ID for every block. A typical homepage needs ~30-40 unique IDs. Generate them all upfront to avoid collisions.

### Step 2: Build section content

Construct the full page content by concatenating all 6 section blocks. Reference `references/kadence-block-patterns.md` for the exact markup patterns.

#### Section 1: Hero

Use the **Hero Section** pattern from `kadence-block-patterns.md`.

Variable substitution:
- H1: Student's tagline (max 7 words). If no explicit tagline, generate from niche. Example: `"Designs That Make Retrievers Famous"`
- Subheadline: One sentence expanding the tagline (max 18 words). Example: `"Original art for golden retriever lovers — designed with love, printed on demand."`
- CTA button: `"Shop Now"` → links to `/shop/`
- Top padding: **80px** (first section, header breathing room)
- Bottom padding: **60px**
- Background: `palette8` with dark overlay at 45% opacity
- All text: white / rgba white

#### Section 2: Featured Products

```html
<!-- wp:kadence/rowlayout {"uniqueID":"${UID}","kbVersion":2,"columns":1,"colLayout":"equal","align":"full","padding":["60","60","60","60"],"bgColor":"palette8"} -->
<div class="wp-block-kadence-rowlayout alignfull">
<!-- wp:kadence/column {"id":1,"uniqueID":"${UID}","kbVersion":2,"textAlign":["center","center","center"]} -->
<div class="wp-block-kadence-column inner-column-1">
<div class="kt-inside-inner-col">

<!-- wp:kadence/advancedheading {"uniqueID":"${UID}","level":2,"color":"palette3","fontSize":["28","24","22"],"fontWeight":"700","align":"center","margin":["","","20",""]} -->
<h2 class="wp-block-kadence-advancedheading" style="text-align:center">Featured Products</h2>
<!-- /wp:kadence/advancedheading -->

<!-- wp:woocommerce/product-collection {"query":{"featured":true,"perPage":4},"displayLayout":{"type":"flex","columns":4,"shrinkColumns":true},"tagName":"div"} -->
<!-- (WooCommerce handles rendering — this block pulls featured products automatically) -->
<!-- /wp:woocommerce/product-collection -->

</div>
</div>
<!-- /wp:kadence/column -->
</div>
<!-- /wp:kadence/rowlayout -->
```

**If no products exist yet:** The keystone recipe (`deploy-pod-store.md`) creates 4 placeholder products before this page is built, so this section always has content to display.

**Fallback if WC product collection block is unavailable:** Use a simple heading + "Products coming soon" paragraph. The student can replace it once they've synced products from MEGA.

#### Section 3: Brand Story

Use the **Brand Story (Two-Column 50/50)** pattern from `kadence-block-patterns.md`.

Variable substitution:
- H2: `"Our Story"` or `"About ${brand_name}"`
- Body copy: AI-generated from intake answers. Guidelines:
  - Max 3 paragraphs, max 60 words each
  - Tone matches the selected font pairing tone
  - Must mention the niche and what makes the brand unique
  - No generic filler — specific to this student's answers
- Image: Placeholder gradient or solid color block for v1. Phase D adds Flux-generated lifestyle images.

#### Section 4: Trust Row

Use the **Trust Row (3 Info Boxes)** pattern from `kadence-block-patterns.md`.

Variable substitution:
- `${THRESHOLD}` → free shipping threshold (default `$50`)
- `${BRAND_NAME}` → from intake Q1

The three boxes are always:
1. **Satisfaction Guaranteed** — Icon: shield. "Something wrong? Tell us. We'll make it right -- every time."
2. **Fast, Free Shipping Over ${THRESHOLD}** — Icon: truck. "Orders over ${THRESHOLD} ship free. Tracked, reliable, to your door."
3. **Original Art, Original Designs** — Icon: star. "Every piece is designed by ${BRAND_NAME} -- not resold, not templated."

#### Section 5: Secondary CTA Band

Use the **Secondary CTA Band** pattern from `kadence-block-patterns.md`.

Variable substitution:
- H2: `"Shop the Collection"` or a niche-specific variant like `"Find Your Perfect Retriever Tee"`
- Button: `"Browse All Products"` → `/shop/`

#### Section 6: Newsletter Placeholder

Use the **Newsletter Placeholder** pattern from `kadence-block-patterns.md`.

- H2: `"Stay in the Loop"`
- Body: `"Join the club for first access to drops and discounts -- coming soon."`

Phase 2 replaces this with a real Fluent Forms email capture + reCAPTCHA.

### Step 3: Create the page

```bash
curl -s -X POST "${BRIDGE_URL}/pages/ensure" \
  -u "claude-bot:${BRIDGE_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "${BRAND_NAME}",
    "slug": "home",
    "status": "publish",
    "content": "${ALL_SECTIONS_CONCATENATED}"
  }'
```

Save the returned `id` as `HOME_ID`.

### Step 4: Set page meta

```bash
curl -s -X POST "${BRIDGE_URL}/posts/${HOME_ID}" \
  -u "claude-bot:${BRIDGE_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
    "meta": {
      "_kad_post_title": "hide",
      "_kad_post_feature": "hide",
      "_kad_post_vertical_padding": "disable",
      "_kad_post_layout": "fullwidth"
    }
  }'
```

**Critical:** Homepage must be `fullwidth` layout so section backgrounds go edge-to-edge. Text containment comes from `maxWidth:1290` on each row block.

### Step 5: Set as front page

This is handled by the keystone recipe (`deploy-pod-store.md`) after all pages are created:

```bash
curl -s -X POST "${BRIDGE_URL}/option/show_on_front" \
  -u "claude-bot:${BRIDGE_PASS}" \
  -H "Content-Type: application/json" \
  -d '{"value": "page"}'

curl -s -X POST "${BRIDGE_URL}/option/page_on_front" \
  -u "claude-bot:${BRIDGE_PASS}" \
  -H "Content-Type: application/json" \
  -d '{"value": ${HOME_ID}}'
```

### Step 6: Flush and verify

```bash
curl -s -X POST "${BRIDGE_URL}/cache/flush" -u "claude-bot:${BRIDGE_PASS}"
```

Verify using `recipes/verify-deployment.md`:
- Check for `kt-row-column-wrap` (kbVersion:2 active)
- Check for brand name in content
- Check for CTA button text
- Check for all 6 section row IDs

## Copy Generation Guidelines

When generating AI copy for the hero headline, subheadline, and brand story:

| Element | Max Words | Constraints |
|---|---|---|
| Hero H1 | 7 | Punchy, niche-specific, no generic "Welcome to" |
| Hero subheadline | 18 | Expands on H1, mentions what they sell |
| Brand story H2 | 5 | "Our Story", "About ${brand_name}", or similar |
| Brand story P1 | 60 | Origin or motivation |
| Brand story P2 | 60 | What makes them different |
| Brand story P3 | 60 | Promise to the customer |
| CTA H2 | 7 | Action-oriented, niche-relevant |
| Button text | 3 | "Shop Now", "Browse All", etc. |

## Gotchas

1. **`kbVersion:2` on every rowlayout and column.** Without it, no Kadence CSS applies. This is the #1 cause of "my page looks broken."

2. **Fullwidth layout + maxWidth on rows.** The page layout must be `fullwidth` for backgrounds to go edge-to-edge. Each row's `maxWidth:1290` contains the text.

3. **80px first section, 60px all others.** The first section needs extra top padding for sticky header clearance. Using the same padding everywhere creates a gap that's either too large (top) or too small (first section hidden behind header).

4. **Use actual UTF-8 characters.** Never `\u2019` — write `'`. Never `\u2014` — write `--`. Kadence renders block content as-is.

5. **Hero `minHeight` with `vh` creates massive gaps.** Use padding only, not minHeight. The hero's visual height comes from content + padding, not a fixed viewport-relative height.
