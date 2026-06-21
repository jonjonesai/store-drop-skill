#!/usr/bin/env bash
# Single source of truth for mode-specific CSS.
# Source AFTER bridge.sh.
# Public functions:
#   inject_mode_css <mode>     # mode = "dark" | "light"
#   apply_dark_bg_mods         # only meaningful for dark mode

# ---------- Dark-mode rule blocks ----------

DARK_CSS_BODY_TEXT='body, .entry-content, .entry-content-wrap, p, h1, h2, h3, h4, h5, h6, li, td, th { color: var(--global-palette4) !important; }
h1, h2, h3, h4, h5, h6, .kt-adv-heading, .kt-blocks-info-box-title { color: var(--global-palette3) !important; }
/* Higher-specificity overrides for standard-WP-block pages (legal/etc.) */
.entry-content, .entry-content p, .entry-content li, .entry-content td, .entry-content th,
.single-content, .single-content p, .single-content li,
.entry-content > *, .single-content > * { color: var(--global-palette4) !important; }
.entry-content h1, .entry-content h2, .entry-content h3, .entry-content h4, .entry-content h5, .entry-content h6,
.single-content h1, .single-content h2, .single-content h3, .single-content h4, .single-content h5, .single-content h6,
.wp-block-heading { color: var(--global-palette3) !important; }'

DARK_CSS_LOGO='.site-title, .site-title a, .site-branding .brand, .site-branding a.brand { color: var(--global-palette9) !important; }
.site-header-wrap, #masthead { background: var(--global-palette8) !important; }'

DARK_CSS_HERO_PADDING='.entry-content-wrap { padding: 0 !important; background: transparent !important; }
.content-area { margin-top: 0 !important; margin-bottom: 0 !important; }
/* Kill the "boxed" content style white card on legal/standard-WP pages */
.content-style-boxed .site,
.content-style-boxed .content-container,
.content-style-boxed .content-container .content-bg,
.content-style-boxed .entry-content,
.content-style-boxed .single-entry,
.content-style-boxed .loop-entry { background: transparent !important; box-shadow: none !important; }'

DARK_CSS_LINKS='a { color: var(--global-palette1); }
a:hover { color: var(--global-palette2); }'

# ---------- Footer CSS — applies in BOTH modes ----------
# SOP: footer is always a dark surface with light text, regardless of mode.
# Without these rules, footer text inherits body color which may match the
# footer background (invisible text). Verified against light-mode run #4
# where the brand HTML in the left footer column rendered black-on-black.
FOOTER_CSS='.site-footer-wrap, .site-bottom-footer-wrap, .site-middle-footer-wrap, .site-top-footer-wrap { color: var(--global-palette9) !important; }
.site-footer-wrap p, .site-footer-wrap span, .footer-html, .footer-html * { color: var(--global-palette9) !important; }
.site-footer-wrap h1, .site-footer-wrap h2, .site-footer-wrap h3, .site-footer-wrap h4, .site-footer-wrap h5, .site-footer-wrap h6, .site-footer-wrap strong, .footer-html strong { color: var(--global-palette9) !important; }
.site-footer-wrap a, .footer-navigation a { color: var(--global-palette9) !important; }
.site-footer-wrap a:hover, .footer-navigation a:hover { color: var(--global-palette1) !important; }'

# ---------- Form CSS — brand the FluentForms submit button (applies in BOTH modes) ----------
# Must live in this bundle (not chrome.sh) because inject_mode_css REPLACES the
# custom CSS slot last, clobbering any earlier /css injection.
FORM_CSS='.fluentform .ff-btn-submit, .ff-btn-submit { background-color: var(--global-palette1) !important; border-color: var(--global-palette1) !important; color: var(--global-palette9) !important; }
.fluentform .ff-btn-submit:hover, .ff-btn-submit:hover { background-color: var(--global-palette2) !important; border-color: var(--global-palette2) !important; }'

# ---------- Layout CSS — contain page-content rows to 1290 centered ----------
# Full-width Kadence rows keep their edge-to-edge background but their CONTENT
# must be capped at 1290 and centered. The maxWidth block attribute does this,
# but the Claude-driven create-page nodes don't reliably preserve it, so we
# enforce it deterministically here (inject_mode_css owns the CSS slot, runs
# last). Only targets .wp-block-kadence-rowlayout (page content) — header/footer
# use different wrappers and are unaffected.
LAYOUT_CSS='.wp-block-kadence-rowlayout .kt-row-column-wrap { max-width: 1290px !important; margin-left: auto !important; margin-right: auto !important; }
/* Content vertical padding is hidden (for the homepage hero), which leaves the Woo breadcrumb jammed flush under the header. Give it its own top clearance. */
.kadence-breadcrumbs { padding-top: 2rem !important; padding-bottom: 0.5rem !important; }'

# ---------- Table CSS — DARK MODE ONLY ----------
# WooCommerce/theme content tables ship LIGHT cell backgrounds; in dark mode the
# light body text renders light-on-light and disappears (reported: the MEGA
# size-guide page's size charts were whited out). Make content tables
# transparent-bg + light text + visible borders so they read on the dark page.
# Scoped to content areas — header/footer tables are untouched.
DARK_CSS_TABLE='.entry-content table th, .entry-content table td, .entry-content-wrap table th, .entry-content-wrap table td, .single-content table th, .single-content table td, .woocommerce table th, .woocommerce table td { background-color: transparent !important; color: var(--global-palette4) !important; border-color: var(--global-palette6) !important; }
.entry-content table, .entry-content-wrap table, .single-content table, .woocommerce table { border-color: var(--global-palette6) !important; }
.entry-content table th, .entry-content-wrap table th, .single-content table th, .woocommerce table th { color: var(--global-palette3) !important; }
/* MEGA size-guide structure ships a near-white .product-section wrapper that shows through the transparent cells — make it transparent so the dark page reads through */
.size-guide .product-section, .product-section, .size-guide .tab-content, .size-guide .unit-tabs { background-color: transparent !important; color: var(--global-palette4) !important; }
.size-guide h1, .size-guide h2, .size-guide h3, .size-guide h4, .size-guide .product-section strong { color: var(--global-palette3) !important; }'

# ---------- Drawer CSS — varies by mode ----------

drawer_css_for_mode() {
  local mode="$1"
  local drawer_text drawer_bg close_color
  if [ "$mode" = "dark" ]; then
    drawer_text='palette9'   # white
    drawer_bg='palette8'     # dark
    close_color='palette9'
  else
    drawer_text='palette3'   # dark
    drawer_bg='palette9'     # white
    close_color='palette3'
  fi
  cat <<EOF
.mobile-toggle-open-container .menu-toggle-open, .mobile-toggle-open-container .menu-toggle-open:focus { background: var(--global-palette1) !important; color: var(--global-palette9) !important; border: none !important; border-radius: 4px !important; padding: 8px 10px !important; }
.mobile-toggle-open-container .menu-toggle-open:hover { background: var(--global-palette2) !important; }
.mobile-toggle-open-container .menu-toggle-open .menu-toggle-icon svg { fill: var(--global-palette9) !important; }
.mobile-navigation a, .drawer-navigation a { color: var(--global-${drawer_text}) !important; }
.mobile-navigation a:hover, .drawer-navigation a:hover { color: var(--global-palette1) !important; }
.popup-drawer .drawer-inner, .mobile-drawer-content { background: var(--global-${drawer_bg}) !important; }
.popup-drawer .drawer-header .menu-toggle-close { color: var(--global-${close_color}) !important; }
EOF
}

# ---------- Bundle builders ----------

build_dark_css_bundle() {
  printf '%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n' \
    "$DARK_CSS_BODY_TEXT" \
    "$DARK_CSS_LOGO" \
    "$DARK_CSS_HERO_PADDING" \
    "$DARK_CSS_LINKS" \
    "$FOOTER_CSS" \
    "$FORM_CSS" \
    "$LAYOUT_CSS" \
    "$DARK_CSS_TABLE" \
    "$(drawer_css_for_mode dark)"
}

build_light_css_bundle() {
  printf '%s\n%s\n%s\n%s\n' \
    "$FOOTER_CSS" \
    "$FORM_CSS" \
    "$LAYOUT_CSS" \
    "$(drawer_css_for_mode light)"
}

# ---------- Public actions ----------

# Inject mode-appropriate CSS (replaces the custom CSS slot). Idempotent.
inject_mode_css() {
  local mode="${1:-light}" css payload
  if [ "$mode" = "dark" ]; then
    css="$(build_dark_css_bundle)"
  else
    css="$(build_light_css_bundle)"
  fi
  payload=$(python3 -c 'import json,sys;print(json.dumps({"css":sys.stdin.read()}))' <<<"$css")
  bridge_post "/css" "$payload" >/dev/null
  bridge_flush_cache
}

# Apply dark-mode background theme_mods. No-op for light mode.
apply_dark_bg_mods() {
  local mode="${1:-light}"
  [ "$mode" = "dark" ] || return 0
  local payload
  payload='{"mods":{"site_background":{"desktop":{"color":"palette8"}},"content_background":{"desktop":{"color":""}},"mobile_navigation_color":{"color":"palette9","hover":"palette1","active":"palette1","background":"palette8","divider":"palette6"}}}'
  bridge_post "/theme-mods/batch" "$payload" >/dev/null
  bridge_flush_cache
}
