# Recipe: Build Navigation Menus + Header & Footer Configuration

> Creates the primary header menu and footer menu, assigns them to Kadence's menu locations, configures the full header layout (logo, sticky, transparent), and configures the 3-column footer (brand + nav + social).

## Inputs Required

| Input | Source | Example |
|---|---|---|
| `brand_name` | Intake Q1 | `CuteMerch` |
| `tagline` | Derived from niche | `Adorable designs for everyday life` |
| `mode` | Intake Q3 | `light` |
| `logo_id` | From logo upload (or empty) | `123` or empty |
| `social_handles` | Intake (optional) | `{"instagram":"cutemerch","facebook":"cutemerch"}` |
| Page IDs | Created by prior recipes | `{home: 42, about: 43, contact: 44, shop: 45}` |
| Legal page IDs | Created by deploy-legal-pages | `{privacy: 50, terms: 51, returns: 52}` |

## Primary Menu (Header)

Standard POD store navigation: About, Contact, Shop.

### Step 1: Create the menu

```bash
MENU_RESPONSE=$(curl -s -X POST "${BRIDGE_URL}/menus/create" \
  -u "claude-bot:${BRIDGE_PASS}" \
  -H "Content-Type: application/json" \
  -d '{"name": "Primary Navigation"}')

PRIMARY_MENU_ID=$(echo "$MENU_RESPONSE" | jq -r '.id // .term_id')
```

### Step 2: Add menu items

```bash
# About
curl -s -X POST "${BRIDGE_URL}/menus/${PRIMARY_MENU_ID}/items" \
  -u "claude-bot:${BRIDGE_PASS}" \
  -H "Content-Type: application/json" \
  -d '{"title": "About", "object_id": ${ABOUT_ID}, "object": "page", "type": "post_type"}'

# Contact
curl -s -X POST "${BRIDGE_URL}/menus/${PRIMARY_MENU_ID}/items" \
  -u "claude-bot:${BRIDGE_PASS}" \
  -H "Content-Type: application/json" \
  -d '{"title": "Contact", "object_id": ${CONTACT_ID}, "object": "page", "type": "post_type"}'

# Shop (WooCommerce shop page)
curl -s -X POST "${BRIDGE_URL}/menus/${PRIMARY_MENU_ID}/items" \
  -u "claude-bot:${BRIDGE_PASS}" \
  -H "Content-Type: application/json" \
  -d '{"title": "Shop", "object_id": ${SHOP_ID}, "object": "page", "type": "post_type"}'
```

## Footer Menu

Quick links: Shop, About, Contact, Privacy, Terms, Returns.

### Step 1: Create the footer menu

```bash
FOOTER_RESPONSE=$(curl -s -X POST "${BRIDGE_URL}/menus/create" \
  -u "claude-bot:${BRIDGE_PASS}" \
  -H "Content-Type: application/json" \
  -d '{"name": "Footer Navigation"}')

FOOTER_MENU_ID=$(echo "$FOOTER_RESPONSE" | jq -r '.id // .term_id')
```

### Step 2: Add items

```bash
curl -s -X POST "${BRIDGE_URL}/menus/${FOOTER_MENU_ID}/items" \
  -u "claude-bot:${BRIDGE_PASS}" -H "Content-Type: application/json" \
  -d '{"title": "Shop", "object_id": ${SHOP_ID}, "object": "page", "type": "post_type"}'

curl -s -X POST "${BRIDGE_URL}/menus/${FOOTER_MENU_ID}/items" \
  -u "claude-bot:${BRIDGE_PASS}" -H "Content-Type: application/json" \
  -d '{"title": "About", "object_id": ${ABOUT_ID}, "object": "page", "type": "post_type"}'

curl -s -X POST "${BRIDGE_URL}/menus/${FOOTER_MENU_ID}/items" \
  -u "claude-bot:${BRIDGE_PASS}" -H "Content-Type: application/json" \
  -d '{"title": "Contact", "object_id": ${CONTACT_ID}, "object": "page", "type": "post_type"}'

curl -s -X POST "${BRIDGE_URL}/menus/${FOOTER_MENU_ID}/items" \
  -u "claude-bot:${BRIDGE_PASS}" -H "Content-Type: application/json" \
  -d '{"title": "Privacy Policy", "object_id": ${PRIVACY_ID}, "object": "page", "type": "post_type"}'

curl -s -X POST "${BRIDGE_URL}/menus/${FOOTER_MENU_ID}/items" \
  -u "claude-bot:${BRIDGE_PASS}" -H "Content-Type: application/json" \
  -d '{"title": "Terms of Service", "object_id": ${TERMS_ID}, "object": "page", "type": "post_type"}'

curl -s -X POST "${BRIDGE_URL}/menus/${FOOTER_MENU_ID}/items" \
  -u "claude-bot:${BRIDGE_PASS}" -H "Content-Type: application/json" \
  -d '{"title": "Returns & Refunds", "object_id": ${RETURNS_ID}, "object": "page", "type": "post_type"}'
```

### Step 3: Assign both menus to locations

```bash
curl -s -X POST "${BRIDGE_URL}/theme-mod/nav_menu_locations" \
  -u "claude-bot:${BRIDGE_PASS}" \
  -H "Content-Type: application/json" \
  -d '{"value": {"primary": ${PRIMARY_MENU_ID}, "footer": ${FOOTER_MENU_ID}}}'
```

**Note:** When setting `nav_menu_locations`, you must include ALL locations in a single call. Setting just `footer` would clear `primary`.

---

## Header Configuration

### Logo

If the student provided a logo (logo_id is set):

```bash
curl -s -X POST "${BRIDGE_URL}/theme-mods/batch" \
  -u "claude-bot:${BRIDGE_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
    "mods": {
      "custom_logo": ${LOGO_ID},
      "logo_width": {"size": {"desktop": 280, "tablet": 140, "mobile": 120}, "unit": {"desktop": "px", "tablet": "px", "mobile": "px"}},
      "logo_layout": {"include":{"desktop":"logo","tablet":"logo","mobile":"logo"},"layout":{"desktop":"standard","tablet":"","mobile":""}}
    }
  }'
```

If no logo was provided, use the text-based site title:

```bash
curl -s -X POST "${BRIDGE_URL}/theme-mods/batch" \
  -u "claude-bot:${BRIDGE_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
    "mods": {
      "logo_layout": {"include":{"desktop":"title","tablet":"title","mobile":"title"},"layout":{"desktop":"standard","tablet":"","mobile":""}},
      "brand_typography": {
        "family": "inherit",
        "google": false,
        "weight": "700",
        "size": {"desktop": 28, "tablet": 24, "mobile": 20},
        "sizeType": "px"
      }
    }
  }'
```

The site title comes from `blogname` (set in Step 1 of deploy-pod-store).

### Header Builder Slots

```bash
curl -s -X POST "${BRIDGE_URL}/theme-mods/batch" \
  -u "claude-bot:${BRIDGE_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
    "mods": {
      "header_desktop_items": {
        "top":    {"top_left":[],"top_left_center":[],"top_center":[],"top_right_center":[],"top_right":[]},
        "main":   {"main_left":["logo"],"main_left_center":[],"main_center":[],"main_right_center":[],"main_right":["navigation","cart"]},
        "bottom": {"bottom_left":[],"bottom_left_center":[],"bottom_center":[],"bottom_right_center":[],"bottom_right":[]}
      },
      "header_mobile_items": {
        "top":    {"top_left":[],"top_left_center":[],"top_center":[],"top_right_center":[],"top_right":[]},
        "main":   {"main_left":["mobile-logo"],"main_left_center":[],"main_center":[],"main_right_center":[],"main_right":["popup-toggle","cart"]},
        "bottom": {"bottom_left":[],"bottom_left_center":[],"bottom_center":[],"bottom_right_center":[],"bottom_right":[]},
        "popup":  {"popup_content":["mobile-navigation"]}
      },
      "primary_navigation_style": "underline",
      "header_sticky": true,
      "header_main_height": {"size": {"desktop": 68, "tablet": 60, "mobile": 51}, "unit": {"desktop": "px", "tablet": "px", "mobile": "px"}}
    }
  }'
```

### Transparent Header

Per DEVLOG locked-in design: transparent header on Home/About/Contact, solid on Shop/Product/Legal.

Kadence's transparent header is controlled per-page via post meta `_kad_post_transparent`. The global `transparent_header_enable` setting enables the feature site-wide, then individual pages opt in.

```bash
# Enable transparent header globally
curl -s -X POST "${BRIDGE_URL}/theme-mods/batch" \
  -u "claude-bot:${BRIDGE_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
    "mods": {
      "transparent_header_enable": true,
      "transparent_header_page": false,
      "transparent_header_post": true,
      "transparent_header_archive": true,
      "transparent_header_device": "all",
      "transparent_header_background": {"desktop": {"color": ""}},
      "transparent_header_navigation_color": {
        "color": "palette9",
        "hover": "palette1",
        "active": "palette1"
      },
      "transparent_header_site_title_color": {
        "color": "palette9"
      }
    }
  }'
```

Then set `_kad_post_transparent` = `"enable"` on Home, About, and Contact pages:

```bash
for PAGE_ID in ${HOME_ID} ${ABOUT_ID} ${CONTACT_ID}; do
  curl -s -X POST "${BRIDGE_URL}/posts/${PAGE_ID}" \
    -u "claude-bot:${BRIDGE_PASS}" \
    -H "Content-Type: application/json" \
    -d '{"meta": {"_kad_post_transparent": "enable"}}'
done
```

Shop, Product, and Legal pages use the default (solid header) by not setting this meta.

**Gotcha:** When transparent header is enabled, the header text/nav colors must be set to light colors (palette9 = white) so they're visible on dark hero backgrounds. The sticky header should revert to solid background on scroll.

### Sticky Header Colors

```bash
curl -s -X POST "${BRIDGE_URL}/theme-mods/batch" \
  -u "claude-bot:${BRIDGE_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
    "mods": {
      "header_sticky_background": {"desktop": {"color": "${MODE_HEADER_BG}"}},
      "header_main_background": {"desktop": {"color": "${MODE_HEADER_BG}"}},
      "mobile_trigger_color": {"color": "palette9", "background": "palette1"},
      "mobile_trigger_background": {"color": "palette1", "hover": "palette2"}
    }
  }'
```

Where `${MODE_HEADER_BG}` is:
- Light mode: `palette9` (white header)
- Dark mode: `palette8` (dark header)

---

## Footer Configuration

Kadence footer uses a builder system with 3 rows (top/middle/bottom) and up to 5 columns per row.

### 2-Column Footer Layout

```bash
curl -s -X POST "${BRIDGE_URL}/theme-mods/batch" \
  -u "claude-bot:${BRIDGE_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
    "mods": {
      "footer_items": {
        "top":    {"top_1": [], "top_2": [], "top_3": [], "top_4": [], "top_5": []},
        "middle": {"middle_1": ["footer-html"], "middle_2": ["footer-navigation"], "middle_3": ["${SOCIAL_OR_EMPTY}"], "middle_4": [], "middle_5": []},
        "bottom": {"bottom_1": [], "bottom_2": [], "bottom_3": [], "bottom_4": [], "bottom_5": []}
      },
      "footer_middle_columns": "2",
      "footer_middle_layout": "equal",
      "footer_middle_column_spacing": {"size": {"desktop": 30, "tablet": 20, "mobile": 15}, "unit": "px"},
      "footer_middle_top_spacing": {"size": {"desktop": 40, "tablet": 30, "mobile": 20}, "unit": "px"},
      "footer_middle_bottom_spacing": {"size": {"desktop": 40, "tablet": 30, "mobile": 20}, "unit": "px"}
    }
  }'
```

Where `${SOCIAL_OR_EMPTY}` is `"footer-social"` if social handles were provided, or empty `""` if not (column 3 hidden).

### Column 1: Brand Name + Tagline (HTML Widget)

```bash
curl -s -X POST "${BRIDGE_URL}/theme-mod/footer_html_content" \
  -u "claude-bot:${BRIDGE_PASS}" \
  -H "Content-Type: application/json" \
  -d '{"value": "<p><strong>${BRAND_NAME}</strong></p>\n<p>${TAGLINE}</p>\n<p>{copyright} {year} ${BRAND_NAME}. All rights reserved.</p>"}'
```

`{copyright}` and `{year}` are Kadence template tags — they render as the copyright symbol and current year.

### Column 2: Footer Navigation

Already wired via `nav_menu_locations.footer` in step 3 above. Kadence's `footer-navigation` item automatically pulls from the assigned footer menu.

### Column 3: Social Icons (if provided)

If the student provided social handles in the intake:

```bash
curl -s -X POST "${BRIDGE_URL}/theme-mods/batch" \
  -u "claude-bot:${BRIDGE_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
    "mods": {
      "footer_social_items": [
        {"id": "instagram", "enabled": true, "source": "icon", "url": "https://instagram.com/${INSTAGRAM_HANDLE}", "icon": "instagram", "label": "Instagram"},
        {"id": "facebook", "enabled": true, "source": "icon", "url": "https://facebook.com/${FACEBOOK_HANDLE}", "icon": "facebook", "label": "Facebook"}
      ],
      "footer_social_align": {"desktop": "center", "tablet": "center", "mobile": "center"},
      "footer_social_style": "outline",
      "footer_social_icon_size": {"size": {"desktop": 20}, "unit": "px"},
      "footer_social_show_label": false,
      "footer_social_color": {
        "color": "palette5",
        "hover": "palette1"
      }
    }
  }'
```

If no social handles were provided, omit `"footer-social"` from `footer_items.middle.3` (set to empty). The column simply won't render.

### Footer Background

Apply dark/light footer background per site mode. The footer background should contrast with the main site — dark footer on light sites, light footer on dark sites:

```bash
curl -s -X POST "${BRIDGE_URL}/theme-mods/batch" \
  -u "claude-bot:${BRIDGE_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
    "mods": {
      "footer_wrap_background": {"desktop": {"color": "${FOOTER_BG}"}},
      "footer_middle_widget_content": {"color": "${FOOTER_TEXT}", "linkColor": "${FOOTER_LINK}", "linkHoverColor": "palette1"},
      "footer_html_link_color": {"color": "${FOOTER_LINK}", "hover": "palette1"}
    }
  }'
```

Where:
- Light mode: `${FOOTER_BG}` = `palette3` (#0A0A0A dark), `${FOOTER_TEXT}` = `palette5` (muted), `${FOOTER_LINK}` = `palette6` (light gray)
- Dark mode: `${FOOTER_BG}` = `palette7` (#1A1A1A surface), `${FOOTER_TEXT}` = `palette5` (muted), `${FOOTER_LINK}` = `palette4` (body text)

---

## Flush and Verify

```bash
curl -s -X POST "${BRIDGE_URL}/cache/flush" -u "claude-bot:${BRIDGE_PASS}"

# Verify primary nav appears
curl -s "${BRIDGE_URL}/render?url=/" -u "claude-bot:${BRIDGE_PASS}" \
  | jq -r '.html' | grep -c 'primary-navigation'

# Verify footer brand name
curl -s "${BRIDGE_URL}/render?url=/" -u "claude-bot:${BRIDGE_PASS}" \
  | jq -r '.html' | grep -o "${BRAND_NAME}. All rights reserved"

# Verify transparent header on homepage
curl -s "${BRIDGE_URL}/render?url=/" -u "claude-bot:${BRIDGE_PASS}" \
  | jq -r '.html' | grep -c 'header-transparent'
```

## Gotchas

1. **`logo_layout` is an object with `include` and `layout` keys.** It is NOT an array or string. Use `{"include":{"desktop":"logo"},"layout":{"desktop":"standard"}}` for logo, or `{"include":{"desktop":"title"},"layout":{"desktop":"standard"}}` for text title. Using `["logo_only"]` silently fails and renders an empty brand link.

2. **Cart icon only appears when WooCommerce is active.** The `"cart"` item in header slots is silently ignored if WC isn't installed.

3. **Footer shows Kadence credit by default.** Always set `footer_html_content` or the footer says "Powered by Kadence WP".

4. **`nav_menu_locations` is a single theme_mod containing ALL locations.** Setting it with only one key clears the others. Always include every location in the value.

5. **Transparent header nav colors must be light.** On a transparent header over a dark hero, the nav text defaults to dark and is invisible. Always set `transparent_header_navigation_color.color` to `palette9` (white).

6. **Sticky header must have its own background color.** Without `header_sticky_background`, the header goes transparent on scroll too, making nav text invisible over content.

7. **`_kad_post_transparent` values:** `"enable"` forces transparent on that page, `"disable"` forces solid, `""` (empty) inherits global. Only set on pages that should have transparent header.

8. **`footer_items` keys use row prefixes.** The column keys are `top_1`, `middle_1`, `bottom_1` — NOT `1`, `2`, `3`. Using bare numbers silently fails and renders an empty footer.

9. **`header_desktop_items` keys also use row prefixes.** The column keys are `main_left`, `main_right`, `top_left`, `bottom_center`, etc. — NOT `left`, `right`. Using bare direction names silently fails and renders an empty header.

10. **Mobile header component names differ from desktop.** The hamburger trigger is `popup-toggle` (NOT `mobile-trigger`). The mobile logo is `mobile-logo` (NOT `logo`). The mobile popup nav is `mobile-navigation` (NOT `navigation`). These map to template files in `template-parts/header/`.

11. **Mobile trigger requires custom CSS on transparent header pages.** Theme_mods alone don't reliably style the trigger when transparent header is active. Always inject this CSS via `POST /css` after setting theme_mods:

```css
.mobile-toggle-open-container .menu-toggle-open,
.mobile-toggle-open-container .menu-toggle-open:focus {
  background: var(--global-palette1) !important;
  color: var(--global-palette9) !important;
  border: none !important;
  border-radius: 4px !important;
  padding: 8px 10px !important;
}
.mobile-toggle-open-container .menu-toggle-open:hover {
  background: var(--global-palette2) !important;
}
.mobile-toggle-open-container .menu-toggle-open .menu-toggle-icon svg {
  fill: var(--global-palette9) !important;
}
.mobile-navigation a, .drawer-navigation a {
  color: var(--global-palette3) !important;
}
.mobile-navigation a:hover, .drawer-navigation a:hover {
  color: var(--global-palette1) !important;
}
.popup-drawer .drawer-inner, .mobile-drawer-content {
  background: var(--global-palette9) !important;
}
.popup-drawer .drawer-header .menu-toggle-close {
  color: var(--global-palette3) !important;
}
```

12. **Menu creation fails silently on duplicate names.** `POST /menus/create` returns empty when a menu with the same name already exists. Always check `GET /menus` first and reuse existing menus, or delete-then-create.
