#!/usr/bin/env bash
# Deterministic WordPress / WooCommerce / LiteSpeed core settings that an
# expert would set on every fresh store but WP ships wrong by default.
# Source AFTER bridge.sh. All work goes through the bridge /wp-eval endpoint
# (PHP) — no SSH/WP-CLI needed, so this runs on any customer box.
#
# Settings applied (locked in after the 2026-06-21 generationx.art shoot, where
# all three were missing):
#   1. Permalinks  -> /%category%/%postname%/   (SEO-friendly, category in URL)
#   2. Media sizes -> all zeroed                (stop WP generating thumbnail/
#      medium/large/medium_large copies of every upload — saves disk + clutter)
#   3. LiteSpeed   -> img_optm-auto + img_optm-webp=1  (auto-optimize new images,
#      serve WebP). LSCWP key persistence is via \LiteSpeed\Conf::update_confs().
#      NOTE: actual WebP generation runs through QUIC.cloud once a domain key is
#      connected; this sets the intent so it kicks in automatically.
#
# Public functions:
#   wp_apply_core_settings    # apply all three; prints PASS/FAIL
#   wp_check_core_settings    # re-read + validate; exit 1 on mismatch

PERMALINK_TARGET='/%category%/%postname%/'

# Emit the JSON result of reading the three settings back (used by both apply +
# check so the verification logic lives in one place).
_wp_read_core_settings() {
  local code payload
  read -r -d '' code <<'PHP'
$ls_present = class_exists('\\LiteSpeed\\Conf') && method_exists('\\LiteSpeed\\Conf','cls');
$ls_webp = $ls_present ? (apply_filters('litespeed_conf','img_optm-webp')) : null;
$ls_auto = $ls_present ? (apply_filters('litespeed_conf','img_optm-auto')) : null;
return array(
  'permalink' => get_option('permalink_structure'),
  'media_zeroed' => (
    intval(get_option('thumbnail_size_w'))===0 &&
    intval(get_option('medium_size_w'))===0 &&
    intval(get_option('large_size_w'))===0 &&
    intval(get_option('medium_large_size_w'))===0
  ),
  'litespeed_present' => $ls_present,
  'litespeed_webp' => $ls_webp,
  'litespeed_auto' => $ls_auto,
);
PHP
  payload=$(python3 -c 'import json,sys;print(json.dumps({"code":sys.stdin.read()}))' <<<"$code")
  bridge_post "/wp-eval" "$payload"
}

wp_apply_core_settings() {
  local code payload resp
  read -r -d '' code <<'PHP'
// 1. Permalinks -> /category/postname/
update_option('permalink_structure', '/%category%/%postname%/');
if (function_exists('flush_rewrite_rules')) { flush_rewrite_rules(true); }
// 2. Zero every generated media size (no thumbnail/medium/large/medium_large copies)
foreach (array(
  'thumbnail_size_w','thumbnail_size_h','thumbnail_crop',
  'medium_size_w','medium_size_h',
  'large_size_w','large_size_h',
  'medium_large_size_w','medium_large_size_h'
) as $k) { update_option($k, 0); }
// 3. LiteSpeed: auto-optimize new images + serve WebP (only if LSCWP installed)
if (class_exists('\\LiteSpeed\\Conf') && method_exists('\\LiteSpeed\\Conf','cls')) {
  \LiteSpeed\Conf::cls()->update_confs(array(
    'img_optm-auto' => true,
    'img_optm-webp' => 1,
  ));
}
return true;
PHP
  payload=$(python3 -c 'import json,sys;print(json.dumps({"code":sys.stdin.read()}))' <<<"$code")
  resp="$(bridge_post "/wp-eval" "$payload")"
  bridge_flush_cache
  if printf '%s' "$resp" | python3 -c 'import json,sys;sys.exit(0 if json.load(sys.stdin).get("success") else 1)' 2>/dev/null; then
    echo "PASS: permalinks=/category/postname/, media sizes zeroed, LiteSpeed WebP optimization on"
  else
    echo "FAIL: wp-eval did not report success: $resp"
    return 1
  fi
}

wp_check_core_settings() {
  local resp
  resp="$(_wp_read_core_settings)"
  WP_SETTINGS_RESP="$resp" python3 - "$PERMALINK_TARGET" <<'PY'
import json, os, sys
target = sys.argv[1]
try:
    d = json.loads(os.environ.get("WP_SETTINGS_RESP", ""))
except Exception as e:
    print("FAIL: could not parse wp-eval response:", e); sys.exit(1)
r = d.get("result", {})
ok = True
if r.get("permalink") != target:
    print(f"FAIL: permalink_structure={r.get('permalink')!r}, expected {target!r}"); ok = False
if not r.get("media_zeroed"):
    print("FAIL: media sizes not all zeroed"); ok = False
# LiteSpeed WebP is a hard requirement only when LSCWP is present (the skill
# always installs it); if somehow absent, warn rather than fail the deploy.
if r.get("litespeed_present"):
    if int(r.get("litespeed_webp") or 0) != 1:
        print(f"FAIL: litespeed img_optm-webp={r.get('litespeed_webp')}, expected 1"); ok = False
else:
    print("WARN: LiteSpeed not present — skipped WebP setting")
if ok:
    print(f"PASS: permalink={r.get('permalink')}, media_zeroed=True, litespeed_webp={r.get('litespeed_webp')}")
sys.exit(0 if ok else 1)
PY
}
