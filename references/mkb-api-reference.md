# Mega Kadence Bridge — API Reference

> Quick-reference for every MKB v1.0.2 endpoint used by this skill. Full source at [github.com/jonjonesai/mega-kadence-bridge](https://github.com/jonjonesai/mega-kadence-bridge).

## Auth

Every request uses **HTTP Basic Authentication**.

```
Username: claude-bot
Password: <Application Password from .env BRIDGE_PASS>
```

All examples below use `-u "claude-bot:${BRIDGE_PASS}"` shorthand.

**Base URL:** `${BRIDGE_URL}` (e.g. `https://yourdomain.com/wp-json/mega-kadence-bridge/v1`)

---

## Core

### GET /info

Returns site, theme, plugin, and PHP version info.

```bash
curl -s "${BRIDGE_URL}/info" -u "claude-bot:${BRIDGE_PASS}"
```

Response: `{ "wordpress": "6.9.4", "php": "8.3", "theme": "kadence", "theme_version": "1.4.5", "bridge_version": "1.0.0", ... }`

### GET /render?url=...

Returns cache-bypassed HTML of any page. Use for verification after every change.

```bash
curl -s "${BRIDGE_URL}/render?url=/about/" -u "claude-bot:${BRIDGE_PASS}"
```

Response: `{ "url": "...", "status": 200, "html": "<html>...", "length": 45861 }`

### POST /cache/flush

Clears all cache layers: WP object cache, LiteSpeed, transients, Kadence CSS cache.

```bash
curl -s -X POST "${BRIDGE_URL}/cache/flush" -u "claude-bot:${BRIDGE_PASS}"
```

**Call this after EVERY write operation. No exceptions.**

### GET /plugins

Lists all installed plugins with status.

```bash
curl -s "${BRIDGE_URL}/plugins" -u "claude-bot:${BRIDGE_PASS}"
```

---

## Theme Customization

### GET /theme-mod/{key}

Read a single Kadence theme_mod.

```bash
curl -s "${BRIDGE_URL}/theme-mod/header_main_layout" -u "claude-bot:${BRIDGE_PASS}"
```

### POST /theme-mod/{key}

Write a single Kadence theme_mod. Key is in the URL, value in the body.

```bash
curl -s -X POST "${BRIDGE_URL}/theme-mod/header_sticky" \
  -u "claude-bot:${BRIDGE_PASS}" \
  -H "Content-Type: application/json" \
  -d '{"value": true}'
```

### POST /theme-mods/batch

Write multiple theme_mods in one call. Use this for multi-key writes (fonts, header config, etc.).

```bash
curl -s -X POST "${BRIDGE_URL}/theme-mods/batch" \
  -u "claude-bot:${BRIDGE_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
    "mods": {
      "base_font": {"family": "Inter", "google": true, "weight": "400", "variant": "400"},
      "heading_font": {"family": "Anton", "google": true, "weight": "400", "variant": "regular"}
    }
  }'
```

### GET|POST /option/{key}

Read or write a WordPress option (not a theme_mod).

```bash
# Read
curl -s "${BRIDGE_URL}/option/show_on_front" -u "claude-bot:${BRIDGE_PASS}"

# Write
curl -s -X POST "${BRIDGE_URL}/option/show_on_front" \
  -u "claude-bot:${BRIDGE_PASS}" \
  -H "Content-Type: application/json" \
  -d '{"value": "page"}'
```

### GET|POST /palette

Read or write the Kadence global 9-slot color palette.

```bash
# Read
curl -s "${BRIDGE_URL}/palette" -u "claude-bot:${BRIDGE_PASS}"

# Write — must be a JSON string with "active":"palette" wrapper
curl -s -X POST "${BRIDGE_URL}/palette" \
  -u "claude-bot:${BRIDGE_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
    "palette": {
      "active": "palette",
      "palette": [
        {"slug": "palette1", "color": "#FF5500", "name": "Primary CTA"},
        {"slug": "palette2", "color": "#E04A00", "name": "CTA Hover"},
        {"slug": "palette3", "color": "#FFFFFF", "name": "Headings"},
        {"slug": "palette4", "color": "#E0E0E0", "name": "Body Text"},
        {"slug": "palette5", "color": "#999999", "name": "Muted Text"},
        {"slug": "palette6", "color": "#333333", "name": "Borders"},
        {"slug": "palette7", "color": "#1A1A1A", "name": "Light Surface"},
        {"slug": "palette8", "color": "#0A0A0A", "name": "Page Background"},
        {"slug": "palette9", "color": "#FFFFFF", "name": "Pure White"}
      ]
    }
  }'
```

**Gotcha:** Kadence stores the palette as a JSON string in `wp_options['kadence_global_palette']`, not as a PHP array. The bridge handles serialization — just send the JSON object above.

### GET|POST /css

Read or write site-wide custom CSS (Additional CSS in Customizer).

```bash
curl -s -X POST "${BRIDGE_URL}/css" \
  -u "claude-bot:${BRIDGE_PASS}" \
  -H "Content-Type: application/json" \
  -d '{"css": ".site-header { border-bottom: 1px solid var(--global-palette6); }"}'
```

### GET /settings

Returns all Kadence-prefixed theme_mods.

### GET /settings/all

Returns every theme_mod on the site.

---

## Content

### GET /posts

List posts with filters.

```bash
curl -s "${BRIDGE_URL}/posts?type=page&status=publish&per_page=50" \
  -u "claude-bot:${BRIDGE_PASS}"
```

### GET /posts/{id}

Read a single post/page by ID. Includes meta.

### POST /posts/{id}

Update a post/page. Supports `title`, `content`, `status`, `slug`, `meta`.

```bash
curl -s -X POST "${BRIDGE_URL}/posts/42" \
  -u "claude-bot:${BRIDGE_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
    "meta": {
      "_kad_post_title": "hide",
      "_kad_post_layout": "fullwidth",
      "_kad_post_vertical_padding": "disable"
    }
  }'
```

### POST /posts/create

Create a new post or page.

```bash
curl -s -X POST "${BRIDGE_URL}/posts/create" \
  -u "claude-bot:${BRIDGE_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "About Us",
    "content": "<!-- wp:kadence/rowlayout {\"uniqueID\":\"abc123\",\"kbVersion\":2,...} -->...",
    "type": "page",
    "status": "publish",
    "slug": "about"
  }'
```

### GET /posts/find?slug=...

Find a post by slug. Idempotency helper — check if a page exists before creating it.

```bash
curl -s "${BRIDGE_URL}/posts/find?slug=about&type=page" \
  -u "claude-bot:${BRIDGE_PASS}"
```

### POST /pages/ensure

Create a page only if it doesn't already exist (by slug). Returns the page whether created or found. **Use this for idempotent deploys.**

```bash
curl -s -X POST "${BRIDGE_URL}/pages/ensure" \
  -u "claude-bot:${BRIDGE_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Privacy Policy",
    "slug": "privacy-policy",
    "content": "...",
    "status": "publish"
  }'
```

### GET /menus

List all navigation menus.

### POST /menus/create

Create a new navigation menu.

```bash
curl -s -X POST "${BRIDGE_URL}/menus/create" \
  -u "claude-bot:${BRIDGE_PASS}" \
  -H "Content-Type: application/json" \
  -d '{"name": "Primary Navigation"}'
```

### POST /menus/{id}/items

Add a menu item to a menu.

```bash
curl -s -X POST "${BRIDGE_URL}/menus/${MENU_ID}/items" \
  -u "claude-bot:${BRIDGE_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Shop",
    "object_id": 42,
    "object": "page",
    "type": "post_type"
  }'
```

For custom links (like Home):

```bash
curl -s -X POST "${BRIDGE_URL}/menus/${MENU_ID}/items" \
  -u "claude-bot:${BRIDGE_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Home",
    "url": "/",
    "type": "custom"
  }'
```

---

## Media

### GET /media

List media library items.

### POST /media/upload-from-url

Sideload a remote image into the media library.

```bash
curl -s -X POST "${BRIDGE_URL}/media/upload-from-url" \
  -u "claude-bot:${BRIDGE_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://res.cloudinary.com/example/image/upload/v1/logo.png",
    "title": "Brand Logo",
    "alt": "Store logo"
  }'
```

Returns: `{ "id": 123, "url": "https://yourdomain.com/wp-content/uploads/2026/05/logo.png", ... }`

---

## Kadence

### GET /blocks

List all registered Kadence blocks.

### GET|POST /kadence-pro/config

Read or write Kadence Pro feature flags (which Pro modules are enabled).

### POST /kadence-pro/preset/pod

Enable all POD-recommended Kadence Pro modules in one call.

```bash
curl -s -X POST "${BRIDGE_URL}/kadence-pro/preset/pod" \
  -u "claude-bot:${BRIDGE_PASS}"
```

### GET /header

Returns current header configuration snapshot.

### GET /footer

Returns current footer configuration snapshot.

---

## WooCommerce (only when WC is active)

### GET /woo/status

WooCommerce version, currency, active status.

### GET|POST /woo/settings

Read or write WooCommerce settings.

### GET /woo/products

List products with filters.

### GET|POST /woo/products/{id}

Read or update a product.

### POST /woo/products/create

Create a new product.

```bash
curl -s -X POST "${BRIDGE_URL}/woo/products/create" \
  -u "claude-bot:${BRIDGE_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Classic Unisex Tee",
    "type": "simple",
    "status": "publish",
    "regular_price": "29.99",
    "description": "Premium quality print-on-demand tee.",
    "short_description": "Soft, comfortable, made to order.",
    "categories": [{"id": 15}]
  }'
```

### GET /woo/categories

List product categories.

### POST /woo/categories/create

Create a product category.

```bash
curl -s -X POST "${BRIDGE_URL}/woo/categories/create" \
  -u "claude-bot:${BRIDGE_PASS}" \
  -H "Content-Type: application/json" \
  -d '{"name": "T-Shirts", "slug": "t-shirts"}'
```

### GET /woo/orders

List orders.

---

## History & Rollback

### GET /history

List recent change snapshots (last 50, ring buffer).

### GET /history/{id}

Get a specific snapshot.

### POST /rollback/{id}

Revert a change by snapshot ID.

```bash
curl -s -X POST "${BRIDGE_URL}/rollback/mkb_1712838600_a3f2c1" \
  -u "claude-bot:${BRIDGE_PASS}"
```

**Supported:** `theme_mod_set`, `option_set`, `palette_set`, `css_set`, `post_update`, `kadence_pro_config_set`, `kadence_pro_preset_pod`.

**Unsupported (returns 400):** `wp_eval`, `theme_mods_batch_set`, `media_upload`, `product_create`. These require manual restoration.
