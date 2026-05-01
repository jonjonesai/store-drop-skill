# Kadence Block Patterns — Reusable Markup Snippets

> The proven block markup for every section type used by this skill. All snippets include `kbVersion:2` — the single most critical attribute for API-created blocks.

## Critical Rules

1. **Every `kadence/rowlayout` and `kadence/column` MUST include `"kbVersion":2`** in the block comment JSON. Without it, Kadence falls back to legacy rendering — bare `<div>` elements with no CSS classes. All padding, max-width, grid, and responsive styles break.

2. **Every block needs a unique `uniqueID`**. Generate a 6-character alphanumeric string per block instance. No two blocks on a page should share a `uniqueID`.

3. **Use actual UTF-8 characters**, never `\uXXXX` escape sequences. Kadence renders block content as-is — escapes appear as literal text.

4. **Fullwidth pages need `maxWidth:1290` on rows** to contain text while backgrounds go edge-to-edge.

5. **Palette references use `"palette1"` through `"palette9"`** — Kadence resolves these to CSS custom properties `var(--global-palette1)` etc.

6. **Inner HTML must match save() output to avoid "Attempt Block Recovery" warnings.** Key rules:
   - `kadence/column` save() outputs: `<div class="wp-block-kadence-column kadence-column${uniqueID}"><div class="kt-inside-inner-col">...inner blocks...</div></div>`. Do NOT use `inner-column-1` classes.
   - `kadence/advancedheading` save() outputs: `<h1 class="kt-adv-heading${uniqueID} wp-block-kadence-advancedheading" data-kb-block="kb-adv-heading${uniqueID}">content</h1>`. The `data-kb-block` attribute is REQUIRED.
   - `kadence/advancedbtn` save() outputs: `<div class="wp-block-kadence-advancedbtn kb-buttons-wrap kb-btns${uniqueID}">...inner blocks...</div>`.
   - `kadence/rowlayout` save() returns only `<InnerBlocks.Content />` — no wrapper HTML. Any wrapper div is acceptable.
   - `kadence/singlebtn` and `kadence/infobox` are fully dynamic (PHP-rendered) — their inner HTML is ignored by WordPress block validation. Use empty inner HTML: `<!-- /wp:kadence/singlebtn -->`.
   - **Do NOT use `kadence/infobox` for API-created content.** Its save() generates complex HTML with icon SVGs that is impossible to reproduce correctly from the API. Use `kadence/advancedheading` + `wp:paragraph` blocks inside columns instead. Infobox icons can be added later in the editor.

7. **Header/footer builder item keys use row prefixes.** Desktop header: `main_left`, `main_right`. Footer: `middle_1`, `middle_2`. NOT bare `left`/`right` or `1`/`2`.

8. **`logo_layout` is an object, not an array.** Use `{"include":{"desktop":"logo"},"layout":{"desktop":"standard"}}`. NOT `["logo_only"]`.

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

## Pattern: Hero Section

Full-width hero with dark overlay, centered text, dual CTA buttons. First section on homepage — uses 80px top padding for header clearance.

```html
<!-- wp:kadence/rowlayout {"uniqueID":"${UID_ROW}","kbVersion":2,"columns":1,"colLayout":"equal","align":"full","padding":["80","60","60","60"],"tabletPadding":["60","40","40","40"],"mobilePadding":["40","20","20","20"],"bgColor":"palette8","overlay":"#000000","overlayOpacity":45,"verticalAlignment":"middle"} -->
<div class="wp-block-kadence-rowlayout alignfull">
<!-- wp:kadence/column {"id":1,"uniqueID":"${UID_COL}","kbVersion":2,"textAlign":["center","center","center"]} -->
<div class="wp-block-kadence-column inner-column-1">
<div class="kt-inside-inner-col">

<!-- wp:kadence/advancedheading {"uniqueID":"${UID_H1}","level":1,"htmlTag":"h1","color":"#ffffff","fontSize":["42","36","28"],"fontWeight":"800","lineHeight":["1.2","1.2","1.2"],"align":"center","margin":["","","20",""],"marginType":"px"} -->
<h1 class="wp-block-kadence-advancedheading" style="text-align:center">Your Headline Here</h1>
<!-- /wp:kadence/advancedheading -->

<!-- wp:kadence/advancedheading {"uniqueID":"${UID_SUB}","level":2,"htmlTag":"p","color":"rgba(255,255,255,0.85)","fontSize":["18","17","16"],"fontWeight":"400","lineHeight":["1.7","1.7","1.7"],"align":"center","margin":["","","30",""]} -->
<p class="wp-block-kadence-advancedheading" style="text-align:center">Subheadline text — 18 words max.</p>
<!-- /wp:kadence/advancedheading -->

<!-- wp:kadence/advancedbtn {"uniqueID":"${UID_BTNS}","hAlign":"center"} -->
<div class="wp-block-kadence-advancedbtn">
<!-- wp:kadence/singlebtn {"uniqueID":"${UID_BTN1}","text":"Shop Now","link":"/shop/","color":"#ffffff","background":"palette1","borderRadius":4,"paddingBT":16,"paddingLR":40,"fontWeight":"700","fontSize":18} -->
<div class="wp-block-kadence-singlebtn"><a class="kt-button" href="/shop/">Shop Now</a></div>
<!-- /wp:kadence/singlebtn -->
</div>
<!-- /wp:kadence/advancedbtn -->

</div>
</div>
<!-- /wp:kadence/column -->
</div>
<!-- /wp:kadence/rowlayout -->
```

**Variables:** `${UID_ROW}`, `${UID_COL}`, `${UID_H1}`, `${UID_SUB}`, `${UID_BTNS}`, `${UID_BTN1}` — replace with generated 6-char IDs.

---

## Pattern: Features / Stats Row

3-4 column row with large numbers + labels. Dark surface background.

```html
<!-- wp:kadence/rowlayout {"uniqueID":"${UID_ROW}","kbVersion":2,"columns":3,"colLayout":"equal","align":"full","padding":["60","60","60","60"],"bgColor":"palette7","tabletColumns":"2","mobileColumns":"1"} -->
<div class="wp-block-kadence-rowlayout alignfull">

<!-- wp:kadence/column {"id":1,"uniqueID":"${UID_C1}","kbVersion":2,"textAlign":["center","center","center"]} -->
<div class="wp-block-kadence-column inner-column-1">
<div class="kt-inside-inner-col">
<!-- wp:kadence/advancedheading {"uniqueID":"${UID_NUM}","level":2,"color":"palette1","fontSize":["48","40","36"],"fontWeight":"900","lineHeight":["1","1","1"],"align":"center"} -->
<h2 class="wp-block-kadence-advancedheading" style="text-align:center">45+</h2>
<!-- /wp:kadence/advancedheading -->
<!-- wp:kadence/advancedheading {"uniqueID":"${UID_LBL}","htmlTag":"p","color":"palette4","fontSize":["12","12","12"],"fontWeight":"700","textTransform":"uppercase","letterSpacing":"1","align":"center","margin":["8","","",""]} -->
<p class="wp-block-kadence-advancedheading" style="text-align:center">Product Types</p>
<!-- /wp:kadence/advancedheading -->
</div>
</div>
<!-- /wp:kadence/column -->

<!-- Repeat kadence/column for each stat -->

</div>
<!-- /wp:kadence/rowlayout -->
```

---

## Pattern: Brand Story (Two-Column 50/50)

Image left, text right. Stacks on mobile.

```html
<!-- wp:kadence/rowlayout {"uniqueID":"${UID_ROW}","kbVersion":2,"columns":2,"colLayout":"equal","align":"full","padding":["60","60","60","60"],"maxWidth":1290,"bgColor":"palette8"} -->
<div class="wp-block-kadence-rowlayout alignfull">

<!-- wp:kadence/column {"id":1,"uniqueID":"${UID_C1}","kbVersion":2} -->
<div class="wp-block-kadence-column inner-column-1">
<div class="kt-inside-inner-col">
<!-- wp:image {"sizeSlug":"large"} -->
<figure class="wp-block-image size-large"><img src="${IMAGE_URL}" alt="${ALT_TEXT}"/></figure>
<!-- /wp:image -->
</div>
</div>
<!-- /wp:kadence/column -->

<!-- wp:kadence/column {"id":2,"uniqueID":"${UID_C2}","kbVersion":2,"verticalAlignment":"middle"} -->
<div class="wp-block-kadence-column inner-column-2">
<div class="kt-inside-inner-col">
<!-- wp:kadence/advancedheading {"uniqueID":"${UID_H2}","level":2,"color":"palette3","fontSize":["28","24","22"],"fontWeight":"700","margin":["","","20",""]} -->
<h2 class="wp-block-kadence-advancedheading">Our Story</h2>
<!-- /wp:kadence/advancedheading -->
<!-- wp:paragraph {"style":{"color":{"text":"var(--global-palette4)"}}} -->
<p style="color:var(--global-palette4)">Brand story paragraph. Max 60 words per paragraph, max 3 paragraphs.</p>
<!-- /wp:paragraph -->
</div>
</div>
<!-- /wp:kadence/column -->

</div>
<!-- /wp:kadence/rowlayout -->
```

---

## Pattern: Trust Row (3 Info Boxes)

Replaces testimonials on new stores (which look broken with zero reviews).

```html
<!-- wp:kadence/rowlayout {"uniqueID":"${UID_ROW}","kbVersion":2,"columns":3,"colLayout":"equal","align":"full","padding":["60","60","60","60"],"bgColor":"palette7","tabletColumns":"3","mobileColumns":"1"} -->
<div class="wp-block-kadence-rowlayout alignfull">

<!-- wp:kadence/column {"id":1,"uniqueID":"${UID_C1}","kbVersion":2,"textAlign":["center","center","center"]} -->
<div class="wp-block-kadence-column inner-column-1">
<div class="kt-inside-inner-col">
<!-- wp:kadence/infobox {"uniqueID":"${UID_IB1}","hAlign":"center","mediaType":"icon","mediaIcon":[{"icon":"fe_shield","size":80,"color":"palette1"}],"title":"Satisfaction Guaranteed","titleFont":[{"size":["22","",""],"weight":"700"}],"titleColor":"palette3","contentText":"Something wrong? Tell us. We'll make it right -- every time.","textColor":"palette4"} -->
<div class="wp-block-kadence-infobox">
<div class="kt-blocks-info-box-media-container"><div class="kt-blocks-info-box-media kt-info-icon-animate-none"></div></div>
<div class="kt-infobox-textcontent">
<h3 class="kt-blocks-info-box-title">Satisfaction Guaranteed</h3>
<p class="kt-blocks-info-box-text">Something wrong? Tell us. We'll make it right -- every time.</p>
</div>
</div>
<!-- /wp:kadence/infobox -->
</div>
</div>
<!-- /wp:kadence/column -->

<!-- wp:kadence/column {"id":2,"uniqueID":"${UID_C2}","kbVersion":2,"textAlign":["center","center","center"]} -->
<div class="wp-block-kadence-column inner-column-2">
<div class="kt-inside-inner-col">
<!-- wp:kadence/infobox {"uniqueID":"${UID_IB2}","hAlign":"center","mediaType":"icon","mediaIcon":[{"icon":"fe_truck","size":80,"color":"palette1"}],"title":"Fast, Free Shipping Over ${THRESHOLD}","titleFont":[{"size":["22","",""],"weight":"700"}],"titleColor":"palette3","contentText":"Orders over ${THRESHOLD} ship free. Tracked, reliable, to your door.","textColor":"palette4"} -->
<div class="wp-block-kadence-infobox">
<div class="kt-blocks-info-box-media-container"><div class="kt-blocks-info-box-media kt-info-icon-animate-none"></div></div>
<div class="kt-infobox-textcontent">
<h3 class="kt-blocks-info-box-title">Fast, Free Shipping Over ${THRESHOLD}</h3>
<p class="kt-blocks-info-box-text">Orders over ${THRESHOLD} ship free. Tracked, reliable, to your door.</p>
</div>
</div>
<!-- /wp:kadence/infobox -->
</div>
</div>
<!-- /wp:kadence/column -->

<!-- wp:kadence/column {"id":3,"uniqueID":"${UID_C3}","kbVersion":2,"textAlign":["center","center","center"]} -->
<div class="wp-block-kadence-column inner-column-3">
<div class="kt-inside-inner-col">
<!-- wp:kadence/infobox {"uniqueID":"${UID_IB3}","hAlign":"center","mediaType":"icon","mediaIcon":[{"icon":"fe_star","size":80,"color":"palette1"}],"title":"Original Art, Original Designs","titleFont":[{"size":["22","",""],"weight":"700"}],"titleColor":"palette3","contentText":"Every piece is designed by ${BRAND_NAME} -- not resold, not templated.","textColor":"palette4"} -->
<div class="wp-block-kadence-infobox">
<div class="kt-blocks-info-box-media-container"><div class="kt-blocks-info-box-media kt-info-icon-animate-none"></div></div>
<div class="kt-infobox-textcontent">
<h3 class="kt-blocks-info-box-title">Original Art, Original Designs</h3>
<p class="kt-blocks-info-box-text">Every piece is designed by ${BRAND_NAME} -- not resold, not templated.</p>
</div>
</div>
<!-- /wp:kadence/infobox -->
</div>
</div>
<!-- /wp:kadence/column -->

</div>
<!-- /wp:kadence/rowlayout -->
```

**Variables:** `${THRESHOLD}` = free shipping threshold (default `$50`). `${BRAND_NAME}` = from intake Q1.

---

## Pattern: Secondary CTA Band

Full-width accent-color band with centered headline + button.

```html
<!-- wp:kadence/rowlayout {"uniqueID":"${UID_ROW}","kbVersion":2,"columns":1,"colLayout":"equal","align":"full","padding":["80","60","60","60"],"bgColor":"palette1"} -->
<div class="wp-block-kadence-rowlayout alignfull">
<!-- wp:kadence/column {"id":1,"uniqueID":"${UID_COL}","kbVersion":2,"textAlign":["center","center","center"]} -->
<div class="wp-block-kadence-column inner-column-1">
<div class="kt-inside-inner-col">

<!-- wp:kadence/advancedheading {"uniqueID":"${UID_H2}","level":2,"color":"#ffffff","fontSize":["36","30","24"],"fontWeight":"800","lineHeight":["1.2","1.2","1.3"],"align":"center","margin":["","","20",""]} -->
<h2 class="wp-block-kadence-advancedheading" style="text-align:center">Shop the Collection</h2>
<!-- /wp:kadence/advancedheading -->

<!-- wp:kadence/advancedbtn {"uniqueID":"${UID_BTNS}","hAlign":"center"} -->
<div class="wp-block-kadence-advancedbtn">
<!-- wp:kadence/singlebtn {"uniqueID":"${UID_BTN}","text":"Browse All Products","link":"/shop/","color":"palette1","background":"#ffffff","borderRadius":4,"paddingBT":18,"paddingLR":48,"colorHover":"#ffffff","backgroundHover":"transparent","borderHover":"#ffffff","fontWeight":"700","fontSize":18} -->
<div class="wp-block-kadence-singlebtn"><a class="kt-button" href="/shop/">Browse All Products</a></div>
<!-- /wp:kadence/singlebtn -->
</div>
<!-- /wp:kadence/advancedbtn -->

</div>
</div>
<!-- /wp:kadence/column -->
</div>
<!-- /wp:kadence/rowlayout -->
```

---

## Pattern: Newsletter Placeholder (Phase 1)

Simple info box. Phase 2 replaces with Fluent Forms + reCAPTCHA.

```html
<!-- wp:kadence/rowlayout {"uniqueID":"${UID_ROW}","kbVersion":2,"columns":1,"colLayout":"equal","align":"full","padding":["60","60","60","60"],"bgColor":"palette8"} -->
<div class="wp-block-kadence-rowlayout alignfull">
<!-- wp:kadence/column {"id":1,"uniqueID":"${UID_COL}","kbVersion":2,"textAlign":["center","center","center"]} -->
<div class="wp-block-kadence-column inner-column-1">
<div class="kt-inside-inner-col">

<!-- wp:kadence/advancedheading {"uniqueID":"${UID_H2}","level":2,"color":"palette3","fontSize":["28","24","22"],"fontWeight":"700","align":"center","margin":["","","15",""]} -->
<h2 class="wp-block-kadence-advancedheading" style="text-align:center">Stay in the Loop</h2>
<!-- /wp:kadence/advancedheading -->

<!-- wp:kadence/advancedheading {"uniqueID":"${UID_P}","htmlTag":"p","color":"palette4","fontSize":["17","16","15"],"fontWeight":"400","align":"center"} -->
<p class="wp-block-kadence-advancedheading" style="text-align:center">Join the club for first access to drops and discounts -- coming soon.</p>
<!-- /wp:kadence/advancedheading -->

</div>
</div>
<!-- /wp:kadence/column -->
</div>
<!-- /wp:kadence/rowlayout -->
```

---

## Pattern: Page Hero (About / Contact)

Used on interior pages. Inherits header breathing room via 80px top padding.

```html
<!-- wp:kadence/rowlayout {"uniqueID":"${UID_ROW}","kbVersion":2,"columns":1,"colLayout":"equal","align":"full","padding":["80","60","60","60"],"bgColor":"palette7","verticalAlignment":"middle"} -->
<div class="wp-block-kadence-rowlayout alignfull">
<!-- wp:kadence/column {"id":1,"uniqueID":"${UID_COL}","kbVersion":2,"textAlign":["center","center","center"]} -->
<div class="wp-block-kadence-column inner-column-1">
<div class="kt-inside-inner-col">

<!-- wp:kadence/advancedheading {"uniqueID":"${UID_H1}","level":1,"color":"palette3","fontSize":["36","30","26"],"fontWeight":"800","align":"center","margin":["","","15",""]} -->
<h1 class="wp-block-kadence-advancedheading" style="text-align:center">${PAGE_TITLE}</h1>
<!-- /wp:kadence/advancedheading -->

<!-- wp:kadence/advancedheading {"uniqueID":"${UID_SUB}","htmlTag":"p","color":"palette4","fontSize":["18","17","16"],"fontWeight":"400","align":"center"} -->
<p class="wp-block-kadence-advancedheading" style="text-align:center">${SUBTITLE}</p>
<!-- /wp:kadence/advancedheading -->

</div>
</div>
<!-- /wp:kadence/column -->
</div>
<!-- /wp:kadence/rowlayout -->
```

---

## Pattern: Values Row (About Page)

3-column row with H3 headings and body text. Used for mission/values on About page.

```html
<!-- wp:kadence/rowlayout {"uniqueID":"${UID_ROW}","kbVersion":2,"columns":3,"colLayout":"equal","align":"full","padding":["60","60","60","60"],"maxWidth":1290,"bgColor":"palette8","tabletColumns":"1","mobileColumns":"1"} -->
<div class="wp-block-kadence-rowlayout alignfull">

<!-- wp:kadence/column {"id":1,"uniqueID":"${UID_C1}","kbVersion":2} -->
<div class="wp-block-kadence-column inner-column-1">
<div class="kt-inside-inner-col">
<!-- wp:kadence/advancedheading {"uniqueID":"${UID_VH1}","level":3,"color":"palette1","fontSize":["22","20","18"],"fontWeight":"700","margin":["","","10",""]} -->
<h3 class="wp-block-kadence-advancedheading">${VALUE_TITLE}</h3>
<!-- /wp:kadence/advancedheading -->
<!-- wp:paragraph {"style":{"color":{"text":"var(--global-palette4)"}}} -->
<p style="color:var(--global-palette4)">${VALUE_DESCRIPTION}</p>
<!-- /wp:paragraph -->
</div>
</div>
<!-- /wp:kadence/column -->

<!-- Repeat for values 2 and 3 -->

</div>
<!-- /wp:kadence/rowlayout -->
```

---

## Generating Unique IDs

Every block needs a unique `uniqueID`. Generate a 6-character lowercase alphanumeric string. In the skill context, Claude generates these at page-build time. They must be unique within a page but don't need to be globally unique.

Format: `[a-z0-9]{6}` — e.g. `a3f2c1`, `b7d9e4`, `x1y2z3`.
