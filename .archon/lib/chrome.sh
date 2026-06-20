#!/usr/bin/env bash
# Deterministic chrome (header / footer / nav / logo) operations.
# All payloads are fixed JSON or simple substitutions of intake values.
# Source AFTER bridge.sh, intake.sh, pages.sh.
#
# Public functions:
#   chrome_ensure_menu       <name> <slug1> [<slug2> ...]
#   chrome_get_menu_id       <name>
#   chrome_assign_menu_locations <primary-menu-id> <footer-menu-id>
#   chrome_upload_logo       <url>                # echoes media ID
#   chrome_set_logo_config   <logo-id-or-empty>
#   chrome_configure_header_builder
#   chrome_configure_sticky_transparent
#   chrome_set_header_bg     <mode>
#   chrome_configure_footer_builder <brand_name> <tagline>
#   chrome_set_footer_bg     <mode>
#   chrome_set_per_page_transparent

# ---------- MENU HELPERS ----------

# Echo the menu ID for a given name, or empty if not found.
chrome_get_menu_id() {
  local name="$1"
  bridge_get "/menus" \
    | python3 -c "
import sys, json
name = '$name'
data = json.load(sys.stdin)
menus = data.get('menus') or data
if isinstance(menus, dict):
    menus = menus.get('menus', [])
for m in (menus or []):
    if m.get('name') == name:
        print(m.get('id') or m.get('term_id') or '')
        break
" 2>/dev/null
}

# Clear all items from a menu (by ID). Bridge has no DELETE endpoint for
# menu items, so we go through wp-eval. Idempotent — safe on empty menus.
chrome_clear_menu_items() {
  local menu_id="$1"
  [ -z "$menu_id" ] && return 0
  local payload
  payload=$(python3 -c "
import json
code = 'foreach (wp_get_nav_menu_items(' + '$menu_id' + ') ?: [] as \$it) { wp_delete_post(\$it->ID, true); }'
print(json.dumps({'code': code}))
")
  bridge_post "/wp-eval" "$payload" >/dev/null
}

# Idempotently ensure a menu with the given name exists and contains exactly
# the given items in slug order. If the menu already exists, its existing
# items are wiped first so we don't accumulate broken/duplicate items from
# prior partial runs. Page IDs come from per-page artifacts via pages_get_id.
# Echoes the final menu ID on success.
chrome_ensure_menu() {
  local name="$1"
  shift
  local slugs=("$@")

  local menu_id
  menu_id="$(chrome_get_menu_id "$name")"

  if [ -z "$menu_id" ]; then
    local resp
    resp="$(bridge_post "/menus/create" "$(python3 -c "import json,sys;print(json.dumps({'name':'$name'}))")")"
    menu_id="$(printf '%s' "$resp" | python3 -c "import json,sys;d=json.load(sys.stdin);print(d.get('id') or d.get('menu',{}).get('id',''))" 2>/dev/null)"
  else
    # Reusing an existing menu — clear its items first so we don't end up
    # with leftovers from a prior partial run interleaved with new items.
    chrome_clear_menu_items "$menu_id"
  fi

  if [ -z "$menu_id" ]; then
    echo "FAIL: could not create or find menu '$name'" >&2
    return 1
  fi

  local slug page_id
  for slug in "${slugs[@]}"; do
    page_id="$(pages_get_id "$slug")"
    if [ -z "$page_id" ]; then
      # Fall back to bridge lookup for pages not in artifacts (e.g. shop).
      page_id="$(bridge_get "/posts/find?slug=${slug}&type=page" \
        | python3 -c "import json,sys;print(json.load(sys.stdin).get('id',''))" 2>/dev/null)"
    fi
    [ -z "$page_id" ] && { echo "WARN: no page for slug=$slug, skipping" >&2; continue; }
    # type=post_type is REQUIRED for object/object_id to take effect.
    # Without it, WP defaults to type=custom and treats the item as a
    # bare custom-URL link with empty title — broken.
    bridge_post "/menus/${menu_id}/items" \
      "$(python3 -c "import json,sys;print(json.dumps({'type':'post_type','object':'page','object_id':int('$page_id'),'title':''}))")" \
      >/dev/null
  done

  echo "$menu_id"
}

# ---------- MENU LOCATIONS ----------

chrome_assign_menu_locations() {
  local primary="$1" footer="$2"
  bridge_post "/theme-mod/nav_menu_locations" \
    "$(python3 -c "import json,sys;print(json.dumps({'value':{'primary':int('$primary'),'footer':int('$footer')}}))")" \
    >/dev/null
}

# ---------- LOGO ----------

# chrome_upload_logo <url>  ->  echoes the new media ID
chrome_upload_logo() {
  local url="$1"
  local resp
  resp="$(bridge_post "/media/upload-from-url" \
    "$(python3 -c "import json,sys;print(json.dumps({'url':'$url','title':'Logo','alt':'Site logo'}))")")"
  printf '%s' "$resp" | python3 -c "import json,sys;print(json.load(sys.stdin).get('id',''))" 2>/dev/null
}

# Set logo theme_mods. Pass empty string for text-only logo.
chrome_set_logo_config() {
  local logo_id="$1"
  local payload
  if [ -n "$logo_id" ] && [ "$logo_id" != "0" ]; then
    payload=$(python3 -c "
import json
print(json.dumps({'mods':{
  'custom_logo': int('$logo_id'),
  'logo_width': {'size':{'desktop':280,'tablet':140,'mobile':120},'unit':{'desktop':'px','tablet':'px','mobile':'px'}},
  'logo_layout': {'include':{'desktop':'logo','tablet':'logo','mobile':'logo'},'layout':{'desktop':'standard','tablet':'','mobile':''}}
}}))
")
  else
    payload=$(python3 -c "
import json
print(json.dumps({'mods':{
  'logo_layout': {'include':{'desktop':'title','tablet':'title','mobile':'title'},'layout':{'desktop':'standard','tablet':'','mobile':''}}
}}))
")
  fi
  bridge_post "/theme-mods/batch" "$payload" >/dev/null
}

# ---------- HEADER BUILDER ----------

chrome_configure_header_builder() {
  local payload
  payload=$(python3 -c "
import json
print(json.dumps({'mods':{
  'header_desktop_items': {
    'top':    {'top_left':[],'top_left_center':[],'top_center':[],'top_right_center':[],'top_right':[]},
    'main':   {'main_left':['logo'],'main_left_center':[],'main_center':[],'main_right_center':[],'main_right':['navigation','cart']},
    'bottom': {'bottom_left':[],'bottom_left_center':[],'bottom_center':[],'bottom_right_center':[],'bottom_right':[]}
  },
  'header_mobile_items': {
    'top':    {'top_left':[],'top_left_center':[],'top_center':[],'top_right_center':[],'top_right':[]},
    'main':   {'main_left':['mobile-logo'],'main_left_center':[],'main_center':[],'main_right_center':[],'main_right':['popup-toggle','cart']},
    'bottom': {'bottom_left':[],'bottom_left_center':[],'bottom_center':[],'bottom_right_center':[],'bottom_right':[]},
    'popup':  {'popup_content':['mobile-navigation']}
  }
}}))
")
  bridge_post "/theme-mods/batch" "$payload" >/dev/null
}

chrome_configure_sticky_transparent() {
  local payload
  payload=$(python3 -c "
import json
print(json.dumps({'mods':{
  'header_sticky': True,
  'header_main_height': {'size':{'desktop':68,'tablet':60,'mobile':51},'unit':{'desktop':'px','tablet':'px','mobile':'px'}},
  'transparent_header_enable': True,
  'transparent_header_page': False,
  'transparent_header_post': True,
  'transparent_header_archive': True,
  'transparent_header_device': 'all',
  'transparent_header_background': {'desktop':{'color':''}},
  'transparent_header_navigation_color': {'color':'palette9','hover':'palette1','active':'palette1'},
  'transparent_header_site_title_color': {'color':'palette9'}
}}))
")
  bridge_post "/theme-mods/batch" "$payload" >/dev/null
}

# Light: white header. Dark: dark header.
chrome_set_header_bg() {
  local mode="${1:-light}"
  local color
  if [ "$mode" = "dark" ]; then
    color='palette8'
  else
    color='palette9'
  fi
  local payload
  payload=$(python3 -c "
import json
print(json.dumps({'mods':{
  'header_main_background':   {'desktop':{'color':'$color'}},
  'header_sticky_background': {'desktop':{'color':'$color'}}
}}))
")
  bridge_post "/theme-mods/batch" "$payload" >/dev/null
}

# ---------- FOOTER BUILDER ----------

chrome_configure_footer_builder() {
  local brand="$1" tagline="$2"
  local html
  html="<p><strong>${brand}</strong></p>\n<p>${tagline}</p>\n<p>{copyright} {year} ${brand}. All rights reserved.</p>"
  local payload
  payload=$(python3 -c "
import json
brand = '$brand'; tagline = '$tagline'
html = '<p><strong>' + brand + '</strong></p>\n<p>' + tagline + '</p>\n<p>{copyright} {year} ' + brand + '. All rights reserved.</p>'
print(json.dumps({'mods':{
  'footer_items': {
    'top':    {'top_1':[],'top_2':[],'top_3':[],'top_4':[],'top_5':[]},
    'middle': {'middle_1':['footer-html'],'middle_2':['footer-navigation'],'middle_3':[],'middle_4':[],'middle_5':[]},
    'bottom': {'bottom_1':[],'bottom_2':[],'bottom_3':[],'bottom_4':[],'bottom_5':[]}
  },
  'footer_middle_columns': '2',
  'footer_middle_layout': 'equal',
  'footer_html_content': html
}}))
")
  bridge_post "/theme-mods/batch" "$payload" >/dev/null
}

# Footer is ALWAYS a dark surface (palette3) with light text (palette9),
# regardless of mode — matches FOOTER_CSS in dark-mode-css.sh. We only set the
# theme_mods here; the text/link/footer + form-button colors are enforced by CSS
# in inject_mode_css, which replaces the custom CSS slot LAST (so any /css we
# wrote here would be clobbered — don't write it here).
chrome_set_footer_bg() {
  local payload
  payload=$(python3 -c "
import json
print(json.dumps({'mods':{
  'footer_wrap_background': {'desktop':{'color':'palette3'}},
  'footer_html_color': {'color':'palette9'},
  'footer_link_color': {'color':'palette9','hover':'palette1'},
  'footer_navigation_colors': {'color':'palette9','hover':'palette1'}
}}))
")
  bridge_post "/theme-mods/batch" "$payload" >/dev/null
}

# ---------- PER-PAGE TRANSPARENT META ----------

chrome_set_per_page_transparent() {
  local slug pid resp
  for slug in home about contact; do
    pid="$(pages_get_id "$slug")"
    [ -z "$pid" ] && { echo "WARN: no $slug artifact, skipping" >&2; continue; }
    bridge_post "/posts/${pid}" \
      "$(python3 -c 'import json,sys;print(json.dumps({"meta":{"_kad_post_transparent":"disable"}}))')" \
      >/dev/null
  done
}
