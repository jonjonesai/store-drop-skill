# Apply Theme Configuration

**Credentials:** Read bridge credentials from `~/kadence-skill/mega-kadence-skill/.env` (or `$ARTIFACTS_DIR/.env`). The file contains BRIDGE_URL, BRIDGE_USER, BRIDGE_PASS, BRIDGE_SITE. Use these for all API calls.

Read the intake answers from `$ARTIFACTS_DIR/intake.json`.

## Steps

### 1. Apply palette

Read `recipes/set-palette.md`. Apply the 9-slot palette via `POST /palette` based on the student's `mode` (light/dark) and `color`.

Use the palette values from the Mode-Specific Checklist in `deploy-pod-store.md`.

### 2. Apply fonts

Read `references/tone-font-pairings.md`. Look up the font pair from the inferred `tone`. Apply via `POST /theme-mods/batch` with `heading_font` and `base_font`.

### 3. Dark mode overrides (ONLY if mode = "dark")

**This step is CRITICAL for dark mode. Skip for light mode.**

**A) Set background theme_mods:**
```
POST /theme-mods/batch with:
- site_background: {"desktop": {"color": "palette8"}}
- content_background: {"desktop": {"color": ""}}
- mobile_navigation_color: {"color": "palette9", "hover": "palette1", "active": "palette1", "background": "palette8", "divider": "palette6"}
```

**B) Inject dark mode CSS via POST /css:**
```
body, .entry-content, .entry-content-wrap, p, h1, h2, h3, h4, h5, h6 { color: var(--global-palette4) !important; }
h1, h2, h3, h4, h5, h6, .kt-adv-heading, .kt-blocks-info-box-title { color: var(--global-palette3) !important; }
.site-title, .site-title a, .site-branding .brand, .site-branding a.brand { color: var(--global-palette9) !important; }
.site-header-wrap, #masthead { background: var(--global-palette8) !important; }
.entry-content-wrap { padding: 0 !important; background: transparent !important; }
.content-area { margin-top: 0 !important; margin-bottom: 0 !important; }
a { color: var(--global-palette1); }
a:hover { color: var(--global-palette2); }
```

**Without this CSS, dark mode sites WILL have invisible text. There are no theme_mod alternatives — Kadence does not have keys like brand_typography_color or heading_color.**

### 4. Set site title and tagline

```
POST /option/blogname with brand_name
POST /option/blogdescription with <generated tagline>
```

**The tagline must be a 3-7 word phrase that captures the essence of `niche`. It must NOT equal `brand_name`.**

Examples (don't copy verbatim — generate one that fits this brand):
- `niche: "cute animal designs on tees and mugs"` → `"where cuteness meets quality"` or `"merch for animal lovers everywhere"`
- `niche: "minimalist tech accessories"` → `"clean tools for clear minds"` or `"tech that gets out of your way"`

Brand voice rules (apply always): no exclamation marks. No em dashes. Lowercase except proper nouns.

Echo the tagline you wrote so the validator can confirm: `echo "TAGLINE: <your-tagline>"`.

### 5. Flush cache

```
POST /cache/flush
```

Save a confirmation to `$ARTIFACTS_DIR/theme-applied.json` with the palette colors and mode used.
