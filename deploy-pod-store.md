# Deploy POD Store — Keystone Recipe

> The end-to-end orchestrator. Takes intake answers and produces a fully branded, 7-page POD store. Every step references a specific recipe. Target: under 15 minutes, zero manual steps.

## Prerequisites

Before running this recipe, confirm:

1. **Bridge credentials exist.** Check `.env` for `BRIDGE_URL`, `BRIDGE_USER`, `BRIDGE_PASS`, `BRIDGE_SITE`. If missing, stop and ask the student to paste their credentials from WP Admin → Settings → Mega Kadence Bridge.

2. **Bridge is reachable.** Test with:
   ```bash
   curl -s "${BRIDGE_URL}/info" -u "claude-bot:${BRIDGE_PASS}"
   ```
   If this returns an error, see `references/hostinger-gotchas.md` for common blockers (disabled app passwords, missing CGIPassAuth).

3. **WooCommerce is active.** Check the `/info` response for WooCommerce version. If not installed, the student needs to install it first (WP Admin → Plugins → Add New → WooCommerce → Install → Activate).

4. **Kadence theme is active.** Check the `/info` response for `theme: kadence`.

## Intake Answers Required

All 6 answers from `INTAKE.md`:

| # | Answer | Variable | Used By |
|---|---|---|---|
| Q1 | Store name | `brand_name` | Every recipe |
| Q2 | Niche | `niche` | Homepage copy, About copy, font inference |
| Q3 | Light or dark | `mode` | set-palette, all page recipes |
| Q4 | Brand color | `primary_color` | set-palette |
| Q5 | Product categories | `categories` | WC category + product creation (this file) |
| Q6 | Logo | `logo_file` | Logo upload (this file) |

Derived variables:
- `tone` — inferred from niche using `references/tone-font-pairings.md`
- `heading_font` / `body_font` — looked up from tone
- `email` — derived from domain or asked separately if needed for legal pages
- `tagline` — AI-generated from niche + brand name (max 7 words)
- `usp` — AI-generated from niche (one sentence, what makes them different)

## Execution — 16 Steps

### Step 1: Set site title

```bash
curl -s -X POST "${BRIDGE_URL}/option/blogname" \
  -u "claude-bot:${BRIDGE_PASS}" \
  -H "Content-Type: application/json" \
  -d '{"value": "${BRAND_NAME}"}'

curl -s -X POST "${BRIDGE_URL}/option/blogdescription" \
  -u "claude-bot:${BRIDGE_PASS}" \
  -H "Content-Type: application/json" \
  -d '{"value": "${TAGLINE}"}'
```

### Step 2: Apply palette

Execute `recipes/set-palette.md` with `mode` and `primary_color` from intake.

### Step 3: Apply fonts by tone

Execute `recipes/set-fonts-by-tone.md` with `tone` inferred from niche.

### Step 4: Apply Kadence Pro POD preset (if Pro is installed)

```bash
# Check if Pro is available
PRO_CHECK=$(curl -s "${BRIDGE_URL}/kadence-pro/config" -u "claude-bot:${BRIDGE_PASS}")

# If Pro is installed, enable POD-recommended modules
if echo "$PRO_CHECK" | jq -e '.config' > /dev/null 2>&1; then
  curl -s -X POST "${BRIDGE_URL}/kadence-pro/preset/pod" \
    -u "claude-bot:${BRIDGE_PASS}"
fi
```

If Pro is not installed, skip. All page recipes gracefully degrade without Pro.

### Step 5: Create WC product categories from intake Q5

Parse the student's Q5 answer into individual category names. Create each via the bridge:

```bash
# Example: student said "T-Shirts, Hoodies, Mugs"
for CATEGORY in "T-Shirts" "Hoodies" "Mugs"; do
  SLUG=$(echo "$CATEGORY" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
  curl -s -X POST "${BRIDGE_URL}/woo/categories/create" \
    -u "claude-bot:${BRIDGE_PASS}" \
    -H "Content-Type: application/json" \
    -d "{\"name\": \"${CATEGORY}\", \"slug\": \"${SLUG}\"}"
done
```

Save the returned category IDs for use in placeholder products.

### Step 6: Create 4 placeholder WC products (if none exist)

Check if products already exist:

```bash
PRODUCT_COUNT=$(curl -s "${BRIDGE_URL}/woo/products" \
  -u "claude-bot:${BRIDGE_PASS}" | jq '.total // (.products | length)')
```

If `PRODUCT_COUNT` is 0, create 4 placeholder products so the Featured Products section isn't empty.

**Important bridge field names:** The bridge uses `name` (not `title`), `categories` as a flat array of term IDs (not `[{"id":16}]`), and does not support `featured` during creation. Set featured status via post meta after creation.

```bash
PLACEHOLDERS=(
  '{"name":"Sample Tee -- Replace with MEGA","status":"publish","regular_price":"29.99","short_description":"Placeholder product. Generate real ones at app.mega.management.","categories":[${FIRST_CAT_ID}]}'
  '{"name":"Sample Hoodie -- Replace with MEGA","status":"publish","regular_price":"49.99","short_description":"Placeholder product. Generate real ones at app.mega.management.","categories":[${FIRST_CAT_ID}]}'
  '{"name":"Sample Mug -- Replace with MEGA","status":"publish","regular_price":"18.99","short_description":"Placeholder product. Generate real ones at app.mega.management.","categories":[${FIRST_CAT_ID}]}'
  '{"name":"Sample Tote -- Replace with MEGA","status":"publish","regular_price":"19.99","short_description":"Placeholder product. Generate real ones at app.mega.management.","categories":[${FIRST_CAT_ID}]}'
)

PRODUCT_IDS=()
for PRODUCT_JSON in "${PLACEHOLDERS[@]}"; do
  RESULT=$(curl -s -X POST "${BRIDGE_URL}/woo/products/create" \
    -u "claude-bot:${BRIDGE_PASS}" \
    -H "Content-Type: application/json" \
    -d "$PRODUCT_JSON")
  PID=$(echo "$RESULT" | jq -r '.id')
  PRODUCT_IDS+=("$PID")
done

# Set all 4 as featured (bridge doesn't support featured flag during creation)
for PID in "${PRODUCT_IDS[@]}"; do
  curl -s -X POST "${BRIDGE_URL}/posts/${PID}" \
    -u "claude-bot:${BRIDGE_PASS}" \
    -H "Content-Type: application/json" \
    -d '{"meta":{"_featured":"yes"}}'
done
```

Assign each placeholder to the first category from Q5. These are starter products — the student replaces them with real MEGA-generated products later.

### Step 7: Build homepage

Execute `recipes/deploy-homepage.md`. Save returned page ID as `HOME_ID`.

### Step 8: Build About page

Execute `recipes/deploy-about.md`. Save returned page ID as `ABOUT_ID`.

### Step 9: Build Contact page

Execute `recipes/deploy-contact.md`. Save returned page ID as `CONTACT_ID`.

### Step 10: Deploy legal pages

Execute `recipes/deploy-legal-pages.md`. Save returned page IDs as `PRIVACY_ID`, `TERMS_ID`, `RETURNS_ID`.

### Step 11: Get Shop page ID

WooCommerce auto-creates a Shop page on activation. Find it:

```bash
SHOP_ID=$(curl -s "${BRIDGE_URL}/posts/find?slug=shop&type=page" \
  -u "claude-bot:${BRIDGE_PASS}" | jq -r '.id')
```

### Step 12: Wire navigation menus, header, and footer

Execute `recipes/build-nav-menus.md` with all collected page IDs and brand context. This recipe now handles:

- **Menus:** Primary (About, Contact, Shop) + Footer (Shop, About, Contact, Privacy, Terms, Returns)
- **Logo:** Set `custom_logo` if provided, or configure text logo via `logo_layout: ["title_only"]`
- **Header:** Sticky header, builder slots (logo left, nav + cart right), mobile hamburger
- **Transparent header:** Enable globally, then set `_kad_post_transparent: "enable"` on Home/About/Contact pages. Shop/Product/Legal use solid header.
- **Footer:** 3-column layout: Col 1 = brand name + tagline + copyright, Col 2 = footer nav menu, Col 3 = social icons (if provided, hidden if not). Dark bg on light sites, light bg on dark sites.

### Step 13: Set homepage as front page

```bash
curl -s -X POST "${BRIDGE_URL}/option/show_on_front" \
  -u "claude-bot:${BRIDGE_PASS}" \
  -H "Content-Type: application/json" \
  -d '{"value": "page"}'

curl -s -X POST "${BRIDGE_URL}/option/page_on_front" \
  -u "claude-bot:${BRIDGE_PASS}" \
  -H "Content-Type: application/json" \
  -d "{\"value\": ${HOME_ID}}"
```

### Step 14: Upload logo (if provided)

If the student provided a logo file in Q6, upload it first and pass the media ID to the build-nav-menus recipe (which handles `custom_logo` + `logo_width` + `logo_layout`):

```bash
# If it's a URL (Cloudinary, etc.)
LOGO_RESPONSE=$(curl -s -X POST "${BRIDGE_URL}/media/upload-from-url" \
  -u "claude-bot:${BRIDGE_PASS}" \
  -H "Content-Type: application/json" \
  -d '{"url": "${LOGO_URL}", "title": "${BRAND_NAME} Logo", "alt": "${BRAND_NAME} logo"}')

LOGO_ID=$(echo "$LOGO_RESPONSE" | jq -r '.id')
```

If no logo was provided, `LOGO_ID` stays empty. The build-nav-menus recipe handles both cases — logo image or text-based site title.

### Step 15: Flush all caches

```bash
curl -s -X POST "${BRIDGE_URL}/cache/flush" -u "claude-bot:${BRIDGE_PASS}"
```

### Step 16: Verify every page + report

Execute `recipes/verify-deployment.md` with full site verification.

Then print the final summary to the student:

```
Your store is live!

| Page | Status | URL |
|---|---|---|
| Homepage | PASS | ${BRIDGE_SITE}/ |
| About | PASS | ${BRIDGE_SITE}/about/ |
| Contact | PASS | ${BRIDGE_SITE}/contact/ |
| Shop | PASS | ${BRIDGE_SITE}/shop/ |
| Privacy Policy | PASS | ${BRIDGE_SITE}/privacy-policy/ |
| Terms of Service | PASS | ${BRIDGE_SITE}/terms-of-service/ |
| Returns & Refunds | PASS | ${BRIDGE_SITE}/returns-and-refunds/ |

Brand: ${BRAND_NAME}
Palette: ${MODE} mode, primary ${PRIMARY_COLOR}
Font: ${HEADING_FONT} / ${BODY_FONT}
Products: ${PRODUCT_COUNT} (${PLACEHOLDER_NOTE})
Categories: ${CATEGORIES}

What's next:
1. Open ${BRIDGE_SITE} in your browser and check each page
2. If you have a hero image, upload it and say "set my hero image"
3. When you're ready to add real products, open MEGA and start creating designs
4. Each design generates products that sync directly to your shop

Everything is reversible. If anything looks wrong, just tell me and I'll fix it.
```

## Idempotency

This recipe is safe to run multiple times on the same site:
- `/pages/ensure` returns existing pages instead of creating duplicates
- Palette and font overwrites are harmless (latest wins)
- Menu creation may create duplicates — check for existing menus by name before creating
- Placeholder products should only be created if product count is 0

## Rollback

Every write operation through the bridge is automatically snapshotted. To undo the entire deployment:

```bash
# List all snapshots
curl -s "${BRIDGE_URL}/history" -u "claude-bot:${BRIDGE_PASS}" | jq '.[] | {id, operation, target}'

# Rollback a specific change
curl -s -X POST "${BRIDGE_URL}/rollback/${SNAPSHOT_ID}" -u "claude-bot:${BRIDGE_PASS}"
```

For a full site reset, rollback in reverse chronological order.

## Timing Budget

| Step | Target |
|---|---|
| Steps 1-4 (theme config) | 1 min |
| Steps 5-6 (WC setup) | 1 min |
| Steps 7-10 (page creation) | 5 min |
| Steps 11-13 (nav + front page) | 1 min |
| Step 14 (logo) | 30 sec |
| Steps 15-16 (flush + verify) | 1 min |
| **Total** | **~10 min** |

Buffer for API latency and copy generation: 5 min. **Hard ceiling: 15 minutes.**
