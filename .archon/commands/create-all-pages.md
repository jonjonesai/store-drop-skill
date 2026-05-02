# Create All Pages

**Credentials:** Read bridge credentials from `~/kadence-skill/mega-kadence-skill/.env` or `/tmp/archon-bridge/.env`. Source the file to get BRIDGE_URL, BRIDGE_USER, BRIDGE_PASS, BRIDGE_SITE. Use HTTP Basic Auth with BRIDGE_USER:BRIDGE_PASS for all API calls.

Read the intake answers from `$ARTIFACTS_DIR/intake.json`.

## Golden Templates

**USE THE GOLDEN TEMPLATES.** Read these files and adapt the content:

- `templates/homepage.html` — 6-section homepage
- `templates/about.html` — 4-section about page
- `templates/contact.html` — 3-section contact page

Replace the variable text (brand name, tagline, copy) with the student's intake answers. Keep the block structure EXACTLY as-is — the templates are proven to pass block validation.

## Steps

### 1. Create homepage

Read `templates/homepage.html`. Replace:
- "Adorable Designs, Everyday Products" with the student's headline (generate from niche, max 7 words)
- "Cute animal illustrations on tees..." with a subheadline (generate from niche, max 18 words)
- "CuteMerch" with the brand name everywhere
- "Our Story" content with brand-specific copy (generate from niche + USP)
- Trust row text if needed (usually keep as-is)
- `[fluentform id="2"]` — check if form ID 2 exists via `GET /wp-json/fluentform/v1/forms`. Use the subscription/newsletter form ID.

```
POST /pages/ensure with {"title": "BRAND_NAME", "slug": "home", "status": "publish", "type": "page", "content": "..."}
```

Then force-publish and set meta:
```
POST /posts/{id} with {"status": "publish", "meta": {"_kad_post_title": "hide", "_kad_post_feature": "hide", "_kad_post_vertical_padding": "disable", "_kad_post_layout": "fullwidth", "_kad_post_transparent": "enable"}}
```

**`_kad_post_vertical_padding` must be `"disable"` — NOT `"hide"`. Using `"hide"` creates a white gap.**

### 2. Create about page

Read `templates/about.html`. Replace brand name, story copy, and value descriptions with intake-driven content.

Same meta as homepage.

### 3. Create contact page

Read `templates/contact.html`. Replace brand name and email.

The contact form shortcode: check if Fluent Forms contact form exists via `GET /wp-json/fluentform/v1/forms`. Use the contact form ID: `[fluentform id="1"]`.

Same meta as homepage.

### 4. Create legal pages

Create Privacy Policy, Terms of Service, Returns & Refunds using `POST /pages/ensure`. Use standard WordPress heading + paragraph blocks (not Kadence blocks). Replace brand name and email from intake.

Force-publish after ensure (WordPress may have a pre-existing Privacy Policy draft):
```
POST /posts/{id} with {"status": "publish", "meta": {"_kad_post_title": "hide", "_kad_post_feature": "hide", "_kad_post_vertical_padding": "disable"}}
```

### 5. Normalize blocks

Call `POST /posts/{id}/normalize-blocks` on every Kadence-block page (homepage, about, contact). Legal pages don't need it (they use standard WP blocks).

### 6. Flush cache

```
POST /cache/flush
```

Save all page IDs to `$ARTIFACTS_DIR/pages.json`.
