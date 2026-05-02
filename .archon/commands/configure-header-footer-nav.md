# Configure Header, Footer, and Navigation

Read intake from `$ARTIFACTS_DIR/intake.json` and page IDs from `$ARTIFACTS_DIR/pages.json`.

## Steps

### 1. Create primary navigation menu

Check if "Primary Navigation" already exists via `GET /menus`. If it exists, reuse it. If not, create:

```
POST /menus/create with {"name": "Primary Navigation"}
```

Add items: About, Contact, Shop (use page IDs from pages.json).

### 2. Create footer legal menu

Check if "Footer Legal" exists. Create if not:

```
POST /menus/create with {"name": "Footer Legal"}
```

Add items: Privacy Policy, Returns & Refunds, Terms of Service (legal page IDs only — NOT Shop/About/Contact).

### 3. Assign menu locations

```
POST /theme-mod/nav_menu_locations with {"value": {"primary": PRIMARY_MENU_ID, "footer": FOOTER_MENU_ID}}
```

**Include ALL locations in one call.** Setting just one clears the other.

### 4. Logo configuration

If student provided a logo: upload via `POST /media/upload-from-url`, then set `custom_logo` theme_mod.

If no logo (student skipped): use text logo.

**Logo layout is an OBJECT, not an array:**
```json
{"include": {"desktop": "logo", "tablet": "logo", "mobile": "logo"}, "layout": {"desktop": "standard", "tablet": "", "mobile": ""}}
```
For text-only: replace `"logo"` with `"title"` in include values.

### 5. Header builder configuration

**Keys use ROW PREFIXES. `main_left` NOT `left`.**

```
POST /theme-mods/batch with:
{
  "header_desktop_items": {
    "top": {"top_left":[],"top_left_center":[],"top_center":[],"top_right_center":[],"top_right":[]},
    "main": {"main_left":["logo"],"main_left_center":[],"main_center":[],"main_right_center":[],"main_right":["navigation","cart"]},
    "bottom": {"bottom_left":[],"bottom_left_center":[],"bottom_center":[],"bottom_right_center":[],"bottom_right":[]}
  },
  "header_mobile_items": {
    "top": {"top_left":[],"top_left_center":[],"top_center":[],"top_right_center":[],"top_right":[]},
    "main": {"main_left":["mobile-logo"],"main_left_center":[],"main_center":[],"main_right_center":[],"main_right":["popup-toggle","cart"]},
    "bottom": {"bottom_left":[],"bottom_left_center":[],"bottom_center":[],"bottom_right_center":[],"bottom_right":[]},
    "popup": {"popup_content":["mobile-navigation"]}
  }
}
```

**Mobile components: `popup-toggle` NOT `mobile-trigger`. `mobile-logo` NOT `logo`. `mobile-navigation` NOT `navigation`.**

### 6. Sticky + transparent header

```
header_sticky: true
header_main_height: {"size":{"desktop":68,"tablet":60,"mobile":51},"unit":{"desktop":"px","tablet":"px","mobile":"px"}}
transparent_header_enable: true
transparent_header_page: false
transparent_header_post: true
transparent_header_archive: true
transparent_header_device: "all"
transparent_header_background: {"desktop":{"color":""}}
transparent_header_navigation_color: {"color":"palette9","hover":"palette1","active":"palette1"}
transparent_header_site_title_color: {"color":"palette9"}
```

Header background per mode:
- Light: `header_main_background` = `palette9`, `header_sticky_background` = `palette9`
- Dark: `header_main_background` = `palette8`, `header_sticky_background` = `palette8`

### 7. Footer configuration

**Keys use ROW PREFIXES. `middle_1` NOT `1`.**

```
footer_items: {"top":{"top_1":[],...},"middle":{"middle_1":["footer-html"],"middle_2":["footer-navigation"],...},"bottom":{"bottom_1":[],...}}
footer_middle_columns: "2"
footer_middle_layout: "equal"
footer_html_content: "<p><strong>BRAND_NAME</strong></p>\n<p>TAGLINE</p>\n<p>{copyright} {year} BRAND_NAME. All rights reserved.</p>"
```

Footer background per mode:
- Light: `footer_wrap_background` = `palette3` (dark), text = `palette5`, links = `palette1`
- Dark: `footer_wrap_background` = `palette7` (surface), text = `palette5`, links = `palette1`

### 8. Mobile trigger + drawer CSS

**Inject via POST /css.** Theme_mods alone don't style the trigger reliably.

**LIGHT mode CSS:**
```
.mobile-toggle-open-container .menu-toggle-open { background: var(--global-palette1) !important; color: var(--global-palette9) !important; border: none !important; border-radius: 4px !important; }
.popup-drawer .drawer-inner, .mobile-drawer-content { background: var(--global-palette9) !important; }
.mobile-navigation a, .drawer-navigation a { color: var(--global-palette3) !important; }
```

**DARK mode CSS:**
```
.mobile-toggle-open-container .menu-toggle-open { background: var(--global-palette1) !important; color: var(--global-palette9) !important; border: none !important; border-radius: 4px !important; }
.popup-drawer .drawer-inner, .mobile-drawer-content { background: var(--global-palette8) !important; }
.mobile-navigation a, .drawer-navigation a { color: var(--global-palette9) !important; }
```

**The difference: drawer bg is palette9 (white) for light, palette8 (dark) for dark. Text is palette3 (dark) for light, palette9 (white) for dark.**

### 9. Set transparent header per-page

Set `_kad_post_transparent: "enable"` on Home, About, Contact pages.
Shop, legal pages use solid header (don't set this meta).

### 10. Flush cache

```
POST /cache/flush
```
