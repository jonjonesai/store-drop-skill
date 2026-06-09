# Recipe: Disable Generated Image Sizes (Thumbnail Spam)

> Drops a mu-plugin that stops WordPress core, Kadence, and WooCommerce from generating thumbnail variants on every upload. The original image is preserved; all sub-sizes are skipped.

## Why this exists

Out of the box, every image uploaded to a WP + Kadence + WooCommerce stack writes **6+ extra files** to `wp-content/uploads/`:

| Source | Sizes generated | Exposed in UI? |
|---|---|---|
| WP core | `thumbnail`, `medium`, `large` | Yes — Settings > Media |
| WP core (hidden) | `medium_large` (768w), `1536x1536`, `2048x2048` | **No** |
| WooCommerce | `woocommerce_thumbnail`, `woocommerce_single`, `woocommerce_gallery_thumbnail` | Customizer > WooCommerce > Product Images (with enforced minimums) |
| Kadence / other plugins | Theme-registered sizes via `add_image_size()` | **No** |

Setting Settings > Media to all zeros disables only the first row. The rest are registered in PHP and bypass that UI entirely. This is why a student says "I tried to zero it out but it's limiting me" — the UI accepts zeros, but uploads still spawn 6+ files.

The fix is a mu-plugin that filters `intermediate_image_sizes_advanced` to return an empty array, which is the single hook WP consults before generating any resized file. Same hook used by every "Disable Image Sizes" plugin on wp.org, but as a mu-plugin it can't be deactivated by accident and doesn't show up in the Plugins list for students to bump.

## Inputs Required

None. The mu-plugin is identical for every site.

## Prerequisites

- Mega Kadence Bridge installed and active (any version with `/wp-eval`, i.e. v1.0.0+)
- `claude-bot` user with `administrator` role
- `wp-content/mu-plugins/` directory exists (WP creates it on demand; the recipe creates it if missing)

## Execution

### Step 1: Confirm bridge is up

```bash
source "$HOME/kadence-skill/store-drop-skill/.archon/lib/bridge.sh"
bridge_check_env || exit 1
curl -s -u "claude-bot:${BRIDGE_PASS}" "${BRIDGE_URL}/info" | jq -r .success
```

Expect `true`.

### Step 2: Snapshot current state

```bash
python3 <<'PY'
import base64, json, os, urllib.request
php = """
return [
  'core_settings' => [
    'thumbnail_w' => get_option('thumbnail_size_w'),
    'medium_w'    => get_option('medium_size_w'),
    'medium_large_w' => get_option('medium_large_size_w'),
    'large_w'     => get_option('large_size_w'),
  ],
  'registered_sizes' => get_intermediate_image_sizes(),
];
"""
url = os.environ['BRIDGE_URL']; pw = os.environ['BRIDGE_PASS']
auth = base64.b64encode(f'claude-bot:{pw}'.encode()).decode()
req = urllib.request.Request(f'{url}/wp-eval',
    data=json.dumps({'code': php}).encode(),
    headers={'Authorization': 'Basic ' + auth, 'Content-Type': 'application/json'},
    method='POST')
print(urllib.request.urlopen(req, timeout=30).read().decode())
PY
```

Record the `registered_sizes` array — this is the list of sizes that will *stop* being generated after Step 3.

### Step 3: Write the mu-plugin

```bash
python3 <<'PY'
import base64, json, os, urllib.request

mu = b"""<?php
/**
 * Plugin Name: MEGA - Disable Generated Image Sizes
 * Description: Stops WordPress core, Kadence, and WooCommerce from generating thumbnail variants on upload. Original is preserved; all registered sub-sizes are skipped.
 * Version: 1.0.0
 * Author: MEGA
 */
if (!defined('ABSPATH')) exit;

add_filter('intermediate_image_sizes_advanced', function ($sizes) { return []; }, 99);
add_filter('intermediate_image_sizes',          function ($sizes) { return []; }, 99);
add_filter('big_image_size_threshold', '__return_false');
"""

b64 = base64.b64encode(mu).decode()
php = (
  'if (!is_dir(WPMU_PLUGIN_DIR)) { wp_mkdir_p(WPMU_PLUGIN_DIR); } '
  'file_put_contents(WPMU_PLUGIN_DIR . "/mega-disable-thumbnails.php", base64_decode("' + b64 + '")); '
  'return ["bytes" => filesize(WPMU_PLUGIN_DIR . "/mega-disable-thumbnails.php")];'
)
url = os.environ['BRIDGE_URL']; pw = os.environ['BRIDGE_PASS']
auth = base64.b64encode(f'claude-bot:{pw}'.encode()).decode()
req = urllib.request.Request(f'{url}/wp-eval',
    data=json.dumps({'code': php}).encode(),
    headers={'Authorization': 'Basic ' + auth, 'Content-Type': 'application/json'},
    method='POST')
print(urllib.request.urlopen(req, timeout=30).read().decode())
PY
```

Expect `{"success":true,"result":{"bytes":541},...}`.

### Step 4: Verify on a fresh request

mu-plugins auto-load on every request, so a follow-up call sees the filters live.

```bash
python3 <<'PY'
import base64, json, os, urllib.request
php = """
$probe = ['thumbnail' => ['width' => 150, 'height' => 150, 'crop' => 1]];
return [
  'filter_strips_sizes' => empty(apply_filters('intermediate_image_sizes_advanced', $probe)),
  'registered_names'    => get_intermediate_image_sizes(),
  'big_threshold'       => apply_filters('big_image_size_threshold', 2560),
];
"""
url = os.environ['BRIDGE_URL']; pw = os.environ['BRIDGE_PASS']
auth = base64.b64encode(f'claude-bot:{pw}'.encode()).decode()
req = urllib.request.Request(f'{url}/wp-eval',
    data=json.dumps({'code': php}).encode(),
    headers={'Authorization': 'Basic ' + auth, 'Content-Type': 'application/json'},
    method='POST')
print(urllib.request.urlopen(req, timeout=30).read().decode())
PY
```

Pass criteria:
- `filter_strips_sizes` → `true`
- `registered_names` → `[]`
- `big_threshold` → `false`

### Step 5: Flush cache

```bash
curl -s -X POST "${BRIDGE_URL}/cache/flush" -u "claude-bot:${BRIDGE_PASS}"
```

### Step 6: Report

```
PASS: Disabled generated image sizes on $BRIDGE_SITE.
Before: <N> sizes generated per upload.
After:  0 sub-sizes; only the original is kept.
```

## Verification (real upload)

Upload a test image via Media Library and SSH in to inspect:

```bash
ls -la wp-content/uploads/$(date +%Y/%m)/ | grep -E '\-[0-9]+x[0-9]+\.|\-scaled\.'
```

Expect zero matches — no `-300x300.jpg`, no `-768x1024.jpg`, no `-scaled.jpg`. Only the original filename.

## Tradeoffs (tell the student)

- **WooCommerce product galleries** fall back to serving the original. If the original is huge (e.g. 4000×4000), product pages get slower. Recommend students resize before upload, or pair this recipe with a CDN/image-optimizer (LiteSpeed image opt., Cloudinary, Bunny).
- **`srcset` responsive images** stop working. Browsers will always download the original. Acceptable for storefronts where most product photos are already web-sized; not acceptable for high-traffic editorial sites.
- **Existing thumbnails are NOT deleted.** This recipe only stops *future* generation. If a student wants to reclaim disk space, follow up with a `wp media regenerate --delete` pass (out of scope for this recipe).

## Rollback

```bash
python3 <<'PY'
import base64, json, os, urllib.request
php = 'return unlink(WPMU_PLUGIN_DIR . "/mega-disable-thumbnails.php");'
url = os.environ['BRIDGE_URL']; pw = os.environ['BRIDGE_PASS']
auth = base64.b64encode(f'claude-bot:{pw}'.encode()).decode()
req = urllib.request.Request(f'{url}/wp-eval',
    data=json.dumps({'code': php}).encode(),
    headers={'Authorization': 'Basic ' + auth, 'Content-Type': 'application/json'},
    method='POST')
print(urllib.request.urlopen(req, timeout=30).read().decode())
PY
```

mu-plugin removed → next upload regenerates all the original sizes again.

## Gotchas

1. **mu-plugins do NOT recurse into subdirectories.** The file must sit directly in `wp-content/mu-plugins/`, not in a sub-folder.
2. **Object cache may serve stale metadata.** If a student inspects an old upload and still sees `sizes` array populated, that's the *historical* attachment metadata, not new behavior. New uploads after Step 3 will have an empty `sizes` array.
3. **Image-optimizer plugins (Smush, ShortPixel, LiteSpeed Image Opt.)** sometimes register their own sizes via `add_image_size()`. This filter strips them too. If a student depends on one of those, run this recipe *after* installing their optimizer and confirm visually.
4. **WooCommerce Customizer settings appear unchanged.** The Customizer > WooCommerce > Product Images panel still shows 300/600/100 values — that's WC reading its option store, not the runtime sizes. Don't waste time trying to zero them in the UI; the filter wins at runtime.
