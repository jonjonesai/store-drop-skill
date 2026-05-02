# Kadence Block Patterns — Proven Markup Reference

> Every pattern in this file is extracted from a working deployment that passed WordPress block validation with zero "Attempt Block Recovery" warnings. Use these exact formats.

## Golden Templates

For complete page content, use the proven templates in `templates/`:
- `templates/homepage.html` — 6-section homepage
- `templates/about.html` — 4-section about page
- `templates/contact.html` — 3-section contact page

Read these templates, replace the variable text (brand name, copy, etc.) with intake answers, and send via the bridge API. This is the fastest path to a valid deployment.

## Critical Format Rules

### 1. kbVersion:2

Every `kadence/rowlayout` and `kadence/column` MUST include `"kbVersion":2`. Without it, Kadence falls back to legacy rendering with no CSS.

### 2. Column HTML format

The inner HTML for `kadence/column` MUST match this exact pattern:

```html
<div class="wp-block-kadence-column kadence-column${UID}"><div class="kt-inside-inner-col">
...inner blocks...
</div></div>
```

- Class MUST be `kadence-column${UID}` — direct concatenation, no space, no dash
- Do NOT use `inner-column-1`, `inner-column-2`, etc.
- The `kt-inside-inner-col` wrapper is required

### 3. Heading HTML format

The inner HTML for `kadence/advancedheading` MUST include `data-kb-block`:

```html
<h1 class="kt-adv-heading${UID} wp-block-kadence-advancedheading" data-kb-block="kb-adv-heading${UID}">Text here</h1>
```

- Class: `kt-adv-heading${UID} wp-block-kadence-advancedheading`
- `data-kb-block`: `kb-adv-heading${UID}`
- Tag matches `level` attribute: h1 for level 1, h2 for level 2, p for htmlTag "p"
- No inline styles — styling comes from block attributes, not HTML style=""

### 4. Button group HTML format

```html
<div class="wp-block-kadence-advancedbtn kb-buttons-wrap kb-btns${UID}">
<!-- wp:kadence/singlebtn ... -->
<!-- /wp:kadence/singlebtn -->
</div>
```

- `singlebtn` is dynamic (PHP-rendered) — use empty inner HTML
- Button text, link, colors go in the block comment attributes only

### 5. Dynamic blocks — empty inner HTML

These blocks render via PHP. Their inner HTML is ignored by WordPress validation. Use empty:

```html
<!-- wp:kadence/singlebtn {"uniqueID":"...","text":"Shop Now","link":"/shop/",...} -->
<!-- /wp:kadence/singlebtn -->
```

```html
<!-- wp:kadence/productcarousel {"uniqueID":"...","postColumns":[4,3,1],...} -->
<!-- /wp:kadence/productcarousel -->
```

Dynamic blocks: `kadence/singlebtn`, `kadence/productcarousel`, `kadence/infobox`

### 6. Do NOT use kadence/infobox from API

Even though infobox is dynamic, its save.js generates complex icon SVGs that are version-fragile. Use `kadence/advancedheading` + `wp:paragraph` instead for trust row / values content.

### 7. Row layout — no wrapper HTML needed

`kadence/rowlayout` save() returns only `<InnerBlocks.Content />`. WordPress doesn't validate wrapper HTML for this block. The PHP renderer generates the full row/column structure.

### 8. Standard WordPress blocks

`wp:paragraph` and `wp:heading` use standard WordPress format:

```html
<!-- wp:paragraph {"align":"center"} -->
<p class="has-text-align-center">Text here.</p>
<!-- /wp:paragraph -->

<!-- wp:heading {"level":2} -->
<h2>Heading here</h2>
<!-- /wp:heading -->
```

### 9. Shortcode blocks

For Fluent Forms and other shortcodes:

```html
<!-- wp:shortcode -->
[fluentform id="2"]
<!-- /wp:shortcode -->
```

### 10. Dark mode: all text must be light

On dark mode sites, Kadence defaults many text elements to near-black. You MUST explicitly set light colors via theme_mods for: site title (`brand_typography_color`), headings (`heading_color`), body text (`base_font_color`), links (`link_color`), transparent header nav (`transparent_header_navigation_color`), and transparent header site title (`transparent_header_site_title_color`). See `recipes/set-palette.md` Step 3b.

### 11. `_kad_post_vertical_padding` value is `"disable"` not `"hide"`

The correct value to suppress Kadence's default content-area padding is the string `"disable"`. Using `"hide"` has no effect and leaves a white gap above the content.

### 12. No trailing empty paragraphs

Content MUST NOT end with an empty paragraph. Strip `<!-- wp:paragraph --><p></p><!-- /wp:paragraph -->` and trailing whitespace before saving.

---

## Block Attribute Reference

### kadence/rowlayout

```json
{
  "uniqueID": "home_hero",
  "kbVersion": 2,
  "columns": 1,
  "colLayout": "equal",
  "align": "full",
  "padding": ["80", "60", "60", "60"],
  "tabletPadding": ["60", "40", "40", "40"],
  "mobilePadding": ["40", "20", "20", "20"],
  "bgColor": "palette7",
  "verticalAlignment": "middle",
  "maxWidth": 1290,
  "mobileColumns": "1"
}
```

- `padding`: array `[top, right, bottom, left]` as strings
- `bgColor`: palette slug string like `"palette7"`
- `maxWidth`: integer, used on fullwidth pages to contain text
- First section: `padding[0]` = `"80"` (header clearance). All others: `"60"`.

### kadence/column

```json
{
  "uniqueID": "home_hc",
  "kbVersion": 2,
  "verticalAlignment": "middle",
  "bgColor": "palette6",
  "borderRadius": [8, 8, 8, 8],
  "minHeight": 300,
  "minHeightUnit": "px"
}
```

### kadence/advancedheading

```json
{
  "uniqueID": "home_h1",
  "level": 1,
  "htmlTag": "h1",
  "color": "palette3",
  "fontSize": ["", "", ""],
  "fontWeight": "800",
  "align": "center"
}
```

- `fontSize`: array `[desktop, tablet, mobile]` — empty strings inherit from theme
- `htmlTag`: overrides the tag. Use `"p"` for paragraph-styled headings
- `color`: palette slug or hex

### kadence/advancedbtn

```json
{
  "uniqueID": "home_btns",
  "hAlign": "center"
}
```

### kadence/singlebtn

```json
{
  "uniqueID": "home_btn1",
  "text": "Shop Now",
  "link": "/shop/",
  "color": "palette9",
  "background": "palette1",
  "backgroundHover": "palette2",
  "typography": [{"size": ["", "", ""], "sizeType": "px", "weight": "700"}]
}
```

### kadence/productcarousel (requires Kadence Blocks Pro)

```json
{
  "uniqueID": "home_pc1",
  "postColumns": [4, 3, 1],
  "autoPlay": false,
  "arrowStyle": "none",
  "dotStyle": "dark"
}
```

- `postColumns`: array `[desktop, tablet, mobile]`
- Pulls all published products by default. Featured products display when products have `_featured: yes` meta.

---

## Spacing Standard: Rule of 80-60-40

- **80px** — first section top padding (header breathing room)
- **60px** — all other section padding top/bottom
- **40px** — horizontal padding + mobile vertical

### Element Margins

- H1: 0 top, 20px bottom
- H2: 10px top, 20px bottom
- H3: 10px top, 15px bottom
- Body paragraph: 0 top, 25px bottom
- CTA button: 30px top margin

---

## Theme Configuration Keys

### Header items (row-prefixed keys)

```json
{
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
  }
}
```

- Desktop: `logo`, `navigation`, `cart`
- Mobile: `mobile-logo`, `popup-toggle`, `cart`, `mobile-navigation`

### Footer items (row-prefixed keys)

```json
{
  "footer_items": {
    "top":    {"top_1":[],"top_2":[],"top_3":[],"top_4":[],"top_5":[]},
    "middle": {"middle_1":["footer-html"],"middle_2":["footer-navigation"],"middle_3":[],"middle_4":[],"middle_5":[]},
    "bottom": {"bottom_1":[],"bottom_2":[],"bottom_3":[],"bottom_4":[],"bottom_5":[]}
  },
  "footer_middle_columns": "2"
}
```

### Logo layout (object, NOT array)

```json
{
  "logo_layout": {
    "include": {"desktop": "logo", "tablet": "logo", "mobile": "logo"},
    "layout": {"desktop": "standard", "tablet": "", "mobile": ""}
  }
}
```

For text-only (no logo image): replace `"logo"` with `"title"` in the include values.
