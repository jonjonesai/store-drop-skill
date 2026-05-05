# Kadence color overrides — the two-layer rule

When changing a visible background or accent color on a Kadence site via the bridge, defining the global palette token at `:root` is necessary but **not sufficient**. Kadence has area-specific theme_mods (e.g. `header_main_background`) that get baked into the generated CSS, and those override the global palette unless you flip them too.

Caught on cutemerch.love during the 2026-05-04 iterative styling session — header was rendering white even though `--global-palette8` was redefined to `#F8F2E5` cream at `:root`. Root cause: `header_main_background` was set to `palette9` (white), and Kadence's generated CSS painted the inner container that color directly, bypassing the body-level palette.

## The rule

To change a visible color reliably, do all three:

1. **Define the global palette token at `:root`** via the bridge `/css` endpoint:
   ```css
   :root { --global-palette8: #F8F2E5 !important; }
   ```

2. **Flip the area-specific Kadence theme_mod** to point at the palette slot (or an explicit hex):
   ```bash
   curl -X POST "$BRIDGE_URL/theme-mod/header_main_background" \
     -H 'Content-Type: application/json' \
     -u "$BRIDGE_USER:$BRIDGE_PASS" \
     -d '{"value":{"desktop":{"color":"palette8"}}}'
   ```

3. **Belt-and-suspenders CSS override** on the inner container (Kadence's dynamic CSS sometimes paints inner wrappers independently — `!important` makes sure your value wins):
   ```css
   .site-header-row-container-inner { background: var(--global-palette8) !important; }
   ```

4. **Flush cache** via `POST /cache/flush`.

## Common area theme_mods to know

| theme_mod | Governs | Default |
|---|---|---|
| `site_background` | Body / page bg | `palette8` |
| `content_background` | Per-page content area bg | empty (inherits) |
| `header_main_background` | Main header row (logo + nav band) | `palette9` (white) |
| `header_top_background` | Top utility bar | `false` (inherits) |
| `header_bottom_background` | Bottom header row | `false` |
| `footer_main_background` | Main footer row | (varies) |
| `footer_top_background` | Top footer row | `false` |
| `footer_bottom_background` | Bottom footer row | `false` |

`logo_width` is a similar pattern but for sizing — its value is `{"size":{"desktop":250,"tablet":190,"mobile":150},"unit":{"desktop":"px",...}}`. Same pattern: `POST /theme-mod/logo_width` with the new structure.

## When to anticipate the gotcha

Any time you:
- Change body/page background color → also flip `site_background` and `content_background`.
- Change header background → also flip `header_main_background` (and `_top_`, `_bottom_` if they're explicitly set).
- Change footer background → flip the three `footer_*_background` keys.
- Change palette accent (palette1) → :root is usually enough; Kadence's hardcoded fallback `var(--global-palette1, #3182CE)` falls through to blue if `:root` doesn't override it, but no separate theme_mod is binding accents to a literal color.

## How the workflow handles this in `apply-theme-config`

The current workflow's Phase 1 sets palette via `POST /palette` and applies dark-mode theme_mods (`site_background`, `content_background`, `mobile_navigation_color`) when mode = dark. It does NOT touch `header_main_background` or footer area mods. Future iteration: extend `apply-theme-config` to also bind header/footer backgrounds to brand-coherent palette slots, OR document the post-deploy edits a student would make in plain English to Claude (the bridge era pattern that Beat 3.8 of the Tier 1 video demonstrates).
