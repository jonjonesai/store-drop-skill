# Promotion Audit — Kadence Logic to Lift From Skill Into MKB

> Generated 2026-05-09 from a read of `SKILL.md`, `deploy-pod-store.md`, and `recipes/*.md`.
> Companion to `~/repos/mega-kadence-bridge/docs/MKB-V2-ABILITY-ROSTER.md`, which scopes the receiving endpoints.

## Premise

This skill currently encodes Kadence-fluent operations directly in recipe markdown — large `POST /css` blobs with `!important` overrides, hand-tuned `theme_mods/batch` payloads, complex Header Builder JSON. None of that is POD-store-specific. It's Kadence mastery, and it belongs in MKB so every future Drop skill (Editorial, Portfolio, Course, Local-Service) inherits it for free instead of recopying these blobs.

The skill should become a thin orchestrator over high-level MKB calls. Today it's a thick orchestrator over low-level MKB calls.

## Audit

Ranked by **leverage** (how many recipes / future skills reuse the logic) × **gnarliness** (how easily a fresh agent gets it wrong).

### 1. Dark-mode CSS injection — HIGHEST PRIORITY

**Where:** `recipes/set-palette.md` Step 3b (lines 142-155), and again in `deploy-pod-store.md` Step 2b (lines 121-128). ~600 chars of `!important` CSS, copy-pasted between recipes.

**Why MKB:** Every dark-mode Kadence site needs this exact override CSS — without it, body text and headings render on `entry-content-wrap` with dark defaults that make text invisible. Not POD-specific.

**Promote to:** `POST /palette/apply-mode-overrides`
- Input: `{"mode": "light" | "dark"}`
- Action: Sets `site_background`, `content_background` (empty string for dark — critical!), `mobile_navigation_color`, AND injects the doctrine CSS via the existing `/css` endpoint (or an internal handler).
- Output: same envelope as `/css` + the resolved CSS string echoed back.

### 2. Mobile trigger / drawer CSS — HIGHEST PRIORITY

**Where:** `deploy-pod-store.md` Step 15b (lines 297-313) + `recipes/build-nav-menus.md` Gotcha 11 (lines 380-408). Two CSS blobs (light + dark variants), each ~1KB, hand-coded with `!important`.

**Why MKB:** The hamburger trigger and slide-out drawer ALWAYS need this CSS to look correct on Kadence. Theme_mods don't reach the relevant selectors. Universal Kadence requirement.

**Promote to:** `POST /header/apply-mobile-trigger-style`
- Input: `{"mode": "light" | "dark", "accent_palette_slot": "palette1", "label_palette_slot": "palette9"}`
- Action: emits the CSS variant for the chosen mode against the chosen palette slots.
- Output: rendered CSS + snapshot id.

### 3. Brand-driven palette application — HIGH PRIORITY

**Where:** `recipes/set-palette.md` (entire file, 180 lines). Encodes:
- 9-slot role assignment (palette1=primary CTA, palette3=headings, etc.)
- Color name resolution ("forest green" → `#228B22`, 10 entries)
- Auto-brightening for dark mode (HSL lightness < 40 → shift to 65)
- WCAG 4.5:1 contrast verification
- Light vs dark mode palette3-8 defaults

**Why MKB:** This is the canonical Kadence palette doctrine. Applies to every Kadence site, not just POD. Currently expressed as instructions an agent follows by hand.

**Promote to:** `POST /palette/apply-from-brand`
- Input: `{"primary": "#hex" | "name" | null, "mode": "light" | "dark", "auto_brighten": true, "contrast_check": true}`
- Action: resolves color name → hex, brightens if needed, fills slots 3-8 from mode defaults, checks contrast, writes via existing `/palette` endpoint, returns the resolved palette + any contrast warnings.
- Output: `{palette: {...}, warnings: [...], snapshot_id}`

### 4. Tone → font pair application — HIGH PRIORITY

**Where:** `recipes/set-fonts-by-tone.md` (entire file, 124 lines) + `references/tone-font-pairings.md`. 10 tones × 2 fonts × per-element size table.

**Why MKB:** Typography mastery on Kadence applies to every site. Font pairings + size scales are the doctrine; the recipe just looks them up.

**Promote to:** `POST /typography/apply-by-tone`
- Input: `{"tone": "Bold & Rebellious" | "Modern & Minimal" | ... | "auto", "niche": "string" (optional, for auto-tone-inference)}`
- Action: looks up the pair, applies `heading_font` / `base_font` / `h1-h3_font` theme_mods using the standard size scale.
- Output: resolved tone + applied fonts + snapshot id.

Plus low-level companion: `POST /typography/apply-pair`
- Input: `{"heading": {family, weight, variant, google}, "body": {family, weight, variant, google}, "scale": "compact" | "standard" | "spacious"}`
- For agents that already know what fonts they want.

### 5. Header builder configuration — HIGH PRIORITY

**Where:** `recipes/build-nav-menus.md` "Header Configuration" section (lines 110-237). Includes:
- Logo configuration (image vs text title — `logo_layout` is famously gnarly, see Gotcha 1 line 359)
- Header Builder slots (`header_desktop_items` / `header_mobile_items` — Gotchas 9 + 10 enumerate the slot-name footguns)
- Sticky header
- Transparent header (global enable + per-page meta + nav color overrides — Gotchas 5 + 6)

**Why MKB:** Every Kadence site has a header. The Builder JSON is a famous footgun (`main_left` not `left`, `popup-toggle` not `mobile-trigger`, etc.). Lifting this into MKB gives every agent header-mastery on day 1.

**Promote to:**
- `POST /header/configure` — high-level: `{layout: "logo-left-nav-right-with-cart", sticky: true, transparent: false, height: {desktop, tablet, mobile}, mode: "light"|"dark"}`. Internally emits the right Builder JSON.
- `POST /header/builder/set-slots` — low-level: `{desktop: {row, col, items}, mobile: {...}}`. Validates slot names, errors clearly.
- `POST /header/transparent` — `{enable: bool, pages: [post_ids], post_types: ["page"], color_overrides: {...}}`. Sets the global flag AND the per-page `_kad_post_transparent` meta.
- `POST /branding/logo` — `{image_id: int|null, title_only: bool, width: {desktop, tablet, mobile}}`. Internally emits `logo_layout` correctly.

### 6. Footer builder configuration — HIGH PRIORITY

**Where:** `recipes/build-nav-menus.md` "Footer Configuration" section (lines 245-336). `footer_items` slot map (Gotcha 8: bare numbers fail, `top_1`/`middle_1`/`bottom_1` required), column-count, spacing, social slot, footer HTML widget content, mode-specific bg + text color.

**Why MKB:** Same case as header. Universal Kadence need, gnarly Builder JSON.

**Promote to:** `POST /footer/configure`
- Input: `{layout: "brand-nav-social" | "brand-nav" | "centered-stack", brand: {name, tagline, copyright_text}, menu_id: int, social: [{platform, url}], mode: "light"|"dark"}`
- Output: applied theme_mods + snapshot id.

### 7. Per-page Kadence meta — MEDIUM PRIORITY

**Where:** `recipes/deploy-homepage.md` Step 4 + multiple recipes. Raw `POST /posts/{id}` with `meta: {_kad_post_title: "hide", _kad_post_layout: "fullwidth", _kad_post_vertical_padding: "disable", _kad_post_transparent: "enable"}`.

**Why MKB:** The `_kad_*` meta family is documented by Kadence but the agent has to remember key names. Wrapping in a typed endpoint surfaces autocomplete-friendly names.

**Promote to:** `POST /posts/{id}/kadence-meta`
- Input: named keys: `{hide_title: bool, hide_featured_image: bool, layout: "default"|"fullwidth"|"narrow", vertical_padding: "default"|"disable", transparent_header: "enable"|"disable"|"inherit"}`
- Action: writes the corresponding `_kad_*` post meta.

### 8. Multi-location nav menu assignment — MEDIUM PRIORITY

**Where:** `recipes/build-nav-menus.md` Step 3 (lines 100-106) + Gotcha 4 (line 365). The `nav_menu_locations` theme_mod is a single value containing ALL locations — setting only one clears the others.

**Why MKB:** A foot-gun that costs every fresh agent one cycle. MKB should hide it.

**Promote to:** `POST /menus/assign-locations`
- Input: `{primary?: int, secondary?: int, footer?: int, ...other_locations}`
- Action: reads existing `nav_menu_locations`, merges in the provided keys, writes back. Agent only specifies what it wants to set.

### 9. Kadence pattern library — MEDIUM PRIORITY (high upside)

**Where:** `references/kadence-block-patterns.md` (referenced from every page recipe). The skill maintains a pattern library (Hero, Trust Row, Brand Story 50/50, Secondary CTA Band, Newsletter Placeholder, Featured Products) and the recipes reference patterns by name.

**Why MKB:** Every Drop skill — Store Drop, Editorial Drop, Portfolio Drop — wants a pattern library. Lifting the patterns into MKB makes them available across all skills, with parameterization.

**Promote to:** `POST /pages/insert-pattern`
- Input: `{post_id: int, position: "append"|"prepend"|int, pattern: "hero"|"trust-row"|"brand-story-2col"|"cta-band"|"newsletter"|"featured-products"|..., variables: {brand_name, tagline, cta_url, ...}}`
- Action: emits valid Kadence block markup with `kbVersion:2`, populated variables, palette tokens (no inline hex), and inserts into the target page. Calls `/posts/{id}/normalize-blocks` afterward.
- Output: inserted block ids + snapshot id.

Plus discovery: `GET /patterns` — list patterns + their parameter schemas.

### 10. Site identity batch — MEDIUM PRIORITY

**Where:** `deploy-pod-store.md` Step 1 — sets `blogname` + `blogdescription`. Plus per-recipe scattering of related identity bits (favicon, social-default OG image, footer copyright).

**Why MKB:** Identity should be one atomic call.

**Promote to:** `POST /site/identity`
- Input: `{name?, tagline?, favicon_id?, default_og_image_id?, copyright_text?}`
- Action: writes to `blogname`, `blogdescription`, `site_icon`, custom `mkb_default_og_image` option, and Kadence's footer credit override.

### 11. Diagnostics audit — DEFER, but name it

**Where:** Doesn't exist.

**Why:** Novamira-port idea applied to Kadence. An agent (or Jon) calls this and gets a punch list of doctrinal violations on the current site: inline hex codes in custom CSS, raw `<div>` markup where Kadence blocks could be used, `_kad_*` meta inconsistencies, missing alt text, palette slots referenced in CSS that aren't defined, font families not loaded.

**Promote to:** `GET /diagnostics`
- Output: `{violations: [{rule, severity, location, suggestion}], summary: {pass_count, fail_count}}`

Defer to v2.1 — needs ruleset definition, scope-creep risk for v2.0.

### 12. WC product placeholder seeder — POD-specific, KEEP IN SKILL

**Where:** `deploy-pod-store.md` Step 6 — creates 4 placeholder products if none exist.

**Why NOT MKB:** This is genuinely POD/store-specific. It belongs in the Store Drop skill, not MKB. Editorial Drop and Portfolio Drop won't want it. Keep here.

## Summary table

| # | Skill location | New MKB endpoint | Priority |
|---|---|---|---|
| 1 | dark-mode CSS injection (set-palette.md, deploy-pod-store.md) | `POST /palette/apply-mode-overrides` | Highest |
| 2 | mobile trigger CSS (deploy-pod-store.md, build-nav-menus.md) | `POST /header/apply-mobile-trigger-style` | Highest |
| 3 | 9-slot palette + name resolve + brighten + WCAG (set-palette.md) | `POST /palette/apply-from-brand` | High |
| 4 | tone → fonts (set-fonts-by-tone.md) | `POST /typography/apply-by-tone` + `/apply-pair` | High |
| 5 | header builder + transparent + logo (build-nav-menus.md) | `POST /header/configure` + `/header/builder/set-slots` + `/header/transparent` + `/branding/logo` | High |
| 6 | footer builder (build-nav-menus.md) | `POST /footer/configure` | High |
| 7 | _kad_* post meta (deploy-homepage.md, others) | `POST /posts/{id}/kadence-meta` | Medium |
| 8 | nav_menu_locations merge-safe (build-nav-menus.md) | `POST /menus/assign-locations` | Medium |
| 9 | Kadence pattern library (references/kadence-block-patterns.md) | `POST /pages/insert-pattern` + `GET /patterns` | Medium (high upside) |
| 10 | site identity (deploy-pod-store.md Step 1) | `POST /site/identity` | Medium |
| 11 | diagnostics audit (does not exist) | `GET /diagnostics` | Defer to v2.1 |
| 12 | WC placeholder seeder | KEEP IN SKILL — POD-specific | — |

## Rollout sequence

If shipping in waves:

- **Wave 1 (v1.3):** #1 + #2 — kills the two giant `!important` CSS blobs that are the most-error-prone parts of the skill. Smallest scope, highest ROI.
- **Wave 2 (v1.4):** #3 + #4 — palette + typography mastery. The two "set my brand" calls.
- **Wave 3 (v1.5):** #5 + #6 + #7 + #8 + #10 — header/footer/meta/menu/identity. Biggest endpoint count but each is small.
- **Wave 4 (v2.0):** #9 — the pattern library. Bigger lift; needs schema design.
- **Wave 5 (v2.1):** #11 — diagnostics.

Each wave shrinks the skill's recipes by replacing block-of-curl with `POST /one-endpoint`. The skill becomes thin orchestration; MKB becomes the actual Kadence vocabulary.
