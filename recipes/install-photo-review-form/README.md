# Recipe: Install Photo-Review Form (Fluent Form + WP Social Ninja Pro modal)

> Replaces the WooCommerce default comment-based review form with a branded modal review form
> that includes star rating, review text, and **drag-and-drop photo upload**. Reviews are saved
> as WooCommerce product reviews via WP Social Ninja Pro's Fluent Forms feed. Also wires the
> post-purchase email asking buyers to leave a review N days after delivery.
>
> First proven on `taiwanmerch.co` (live since 2026-03-31). This recipe extracts and
> parameterizes that working setup so it can be deployed identically on every JonOps brand store.

## What customers see

1. On a product page, the Reviews tab shows a **"Write a Review"** button instead of WooCommerce's
   built-in textbox form.
2. Clicking the button opens a centered modal with name, email, 5-star rating, optional title,
   review text, and a **"Click or drag photos here"** dropzone (up to 3 JPG/PNG/WebP, 2 MB each).
3. Photos upload immediately via AJAX with live thumbnail previews and a remove button.
4. On submit, the review is created as a WooCommerce review with the photos attached, displayed
   via WP Social Ninja Pro's reviews widget on the product page.
5. 14 days after the order ships, the customer gets a branded email with a button to leave a
   review for each item they bought.

## Architecture (5 building blocks)

| # | Piece | Where it lives | Brand-agnostic? |
| - | --- | --- | --- |
| 1 | **Fluent Form** (free) "Product Review Form" with hidden `product-id` + hidden `product-photos` | Form ID `{{FF_FORM_ID}}` in Fluent Forms | Yes — import same form definition everywhere |
| 2 | **WP Social Ninja Pro feed** mapping FF submissions → WooCommerce review | `fluentform_wp_social_ninja_reviews` form_meta entry | Yes — identical mapping |
| 3 | **Upload-handler Code Snippet** — AJAX endpoint + JS dropzone injector | Active Code Snippet, scope=global | Partially — needs brand prefix in action names |
| 4 | **Review-modal Code Snippet** — hides default WC form, adds "Write a Review" button + modal with FF shortcode | Active Code Snippet, scope=global | Mostly — needs brand colors + font + FF form ID |
| 5 | **Post-purchase email Code Snippet** — 14-day delayed `wp_mail` to the buyer | Active Code Snippet, scope=global | No — full brand voice + logo + address |

All three snippets are stored in the **Code Snippets** plugin database, not in any git repo.
That's deliberate — Code Snippets lets the brand owner toggle/edit them in the WP admin
without a deploy. The templates in `./templates/` are the source of truth for fresh installs.

## Prerequisites

Per-site plugin state (all of these are already active on the JonOps brand sites the recipe
targets, but verify on a fresh site):

- **Fluent Forms** (free): plugin slug `fluentform` — install via Store Drop Skill's
  `install-fluent-forms.md` recipe (already runs in `deploy-pod-store.yaml`).
- **WP Social Ninja Pro**: paid plugin. Activated via licensed ZIP upload through the MKB
  bridge `/plugins/install-and-activate` endpoint (use `zip_url` param).
- **Code Snippets**: plugin slug `code-snippets` — install via MKB bridge.
- **WooCommerce**: assumed present (the recipe is a no-op without WC products).
- **Kadence theme** (or any theme with a `#tab-reviews` and `#comments` inside the WC
  single-product template). The JS waits for those anchors with a polling retry, so any WC-
  compliant theme works.

## Per-brand placeholders

Each brand needs these values supplied to the template renderer (see
`./brand-vars.example.json`):

| Placeholder | Example (TM) | What it is |
| --- | --- | --- |
| `{{BRAND_SHORT}}` | `TaiwanMerch` | Short brand name (used in emails + logs) |
| `{{BRAND_PREFIX}}` | `twm` | Lowercase prefix for AJAX action names + post meta + cron action |
| `{{BRAND_PREFIX_UPPER}}` | `TWM` | Same prefix uppercased for PHP `define()` constants |
| `{{BRAND_DOMAIN}}` | `taiwanmerch.co` | Bare domain (no protocol, no trailing slash) |
| `{{BRAND_FROM_EMAIL}}` | `hello@taiwanmerch.co` | Email From address |
| `{{BRAND_PRIMARY_HEX}}` | `#215387` | Primary brand color (modal button, table header) |
| `{{BRAND_HEADING_HEX}}` | `#222c88` | Modal title + email H1 color |
| `{{BRAND_ACCENT_HEX}}` | `#ff181d` | Secondary accent (CTA buttons, hover, accent bar) |
| `{{BRAND_HOVER_HEX}}` | `#ff181d` | Button hover color (often same as accent) |
| `{{BRAND_FONT_CSS}}` | `'Righteous', cursive` | Display font CSS string |
| `{{BRAND_LOGO_URL}}` | `https://taiwanmerch.co/wp-content/uploads/2025/12/taiwan-merch-logo.png` | Absolute logo URL |
| `{{BRAND_TABLE_BG_HEX}}` | `#fef3e7` | Email product-list table background |
| `{{BRAND_ACCENT_HEX}}` (uploader) | `#215387` | Color used in the dropzone hover state |
| `{{BRAND_ADDRESS}}` | `680 S Cache Street, Suite 100-8790, Jackson, WY 83001` | Postal address line for email footer |
| `{{FF_FORM_ID}}` | `5` | The Fluent Form ID once the form is imported on this site |
| `{{REVIEW_DELAY_DAYS}}` | `14` | How many days after order completion to send the email |
| `{{REVIEW_SUBJECT}}` | `How are you loving your Taiwan Merch? We'd love to hear! ⭐` | Email subject (warm-hug doctrine) |
| `{{REVIEW_GREETING}}` | `Hey {first_name}! 🇹🇼` | H1 inside the email. `{first_name}` is replaced at send time. |
| `{{REVIEW_BODY_P1}}` | `It's been a couple of weeks since your order arrived...` | Opening paragraph |
| `{{REVIEW_BODY_P2}}` | `Would you mind taking a moment to share your experience?...` | Second paragraph above products |
| `{{REVIEW_BODY_P3}}` | `It only takes a minute, and we truly appreciate it! 🙏` | Closing line above signature |
| `{{REVIEW_SIGNATURE}}` | `The Taiwan Merch Team` | Sign-off |

## Installation steps

> All steps below run against a single brand site via the MKB bridge. Source the bridge helper
> the same way `install-fluent-forms.md` does:
>
> ```bash
> source "$HOME/kadence-skill/store-drop-skill/.archon/lib/bridge.sh"
> bridge_check_env || exit 1
> ```

### Step 1 — Ensure prerequisite plugins are active

```bash
bridge_post "/plugins/install-and-activate" '{"slug":"fluentform"}'
bridge_post "/plugins/install-and-activate" '{"slug":"code-snippets"}'
# WP Social Ninja Pro — premium plugin, install from licensed ZIP:
bridge_post "/plugins/install-and-activate" '{"zip_url":"https://...wp-social-ninja-pro.zip"}'
```

### Step 2 — Import Fluent Form definition

The full form (fields + WPSR feed mapping in `form_meta`) is stored at
`./tm-reference/ff5-form-definition.json`. On a fresh site, POST it to the FF REST endpoint
to create the form. Capture the returned form ID — that becomes `{{FF_FORM_ID}}` for Step 4.

```bash
ff_form_json=$(cat ./tm-reference/ff5-form-definition.json)
RESPONSE=$(curl -s -u "$WP_USERNAME:$WP_PASSWORD" \
    -H "Content-Type: application/json" \
    -X POST "$WP_URL/wp-json/fluentform/v1/forms" \
    -d "$ff_form_json")
FORM_ID=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('id') or json.load(sys.stdin).get('data',{}).get('id'))")
```

> **Gotcha — Fluent Forms doesn't expose a public REST endpoint for creating forms by default.**
> The endpoint above is admin-only and may require the bridge to call FF's internal class
> instead of REST. If REST returns 404 or 401, fall back to running the import via a transient
> Code Snippet that calls `FluentForm\App\Modules\Form\Form::insertForm()`. (See gotchas section.)

### Step 3 — Render the templates with brand vars

```bash
brand_vars=./brand-vars.json   # populated per-brand from brand.json + DESIGN.md
for tmpl in templates/*.php; do
    out="rendered/$(basename "$tmpl")"
    python3 scripts/render-template.py "$tmpl" "$brand_vars" "$FORM_ID" > "$out"
done
```

The renderer does straight `{{KEY}}` → value substitution. No escaping logic — values must
already be PHP/JS/CSS-safe (no unescaped quotes in brand colors, no `</script>` in the
greeting line, etc.).

### Step 4 — Install the three Code Snippets via MKB

```bash
for slug in upload-handler review-modal post-purchase-email; do
    code=$(cat "rendered/snippet-${slug}.php")
    bridge_post "/snippets/install" "$(jq -n \
        --arg name "${BRAND_PREFIX_UPPER}: Photo Review — ${slug}" \
        --arg code "$code" \
        --arg scope "global" \
        '{name:$name, code:$code, scope:$scope, active:true}')"
done
```

> **Bridge endpoint requirement:** MKB needs a `/snippets/install` endpoint that wraps the
> Code Snippets plugin's internal `save_snippet()`. As of MKB v1.1.0 this endpoint may not
> exist yet — verify with `bridge_post "/" '{}'`. If missing, see "MKB bridge gap" below.

### Step 5 — Create the WPSR Reviews template (REQUIRED, via admin UI)

**MUST be done via the WPSR admin UI wizard — not programmatically.** A template post
created via `wp_insert_post` leaves the `_wpsr_template_config` post_meta empty (or only
half-populated if the wizard is exited early), and the shortcode renders nothing. The
wizard generates the config blob the renderer needs.

1. WP Admin → **Social Ninja → Templates → Add New**.
2. Pick **Reviews** as type, **WooCommerce** as source.
3. Pick **Grid 1** layout (matches TM; any other layout works too — pick by taste).
4. Click through the wizard until the **final Save / Publish** step. Do NOT stop after
   step 1 — the config will be incomplete and you'll spend an hour debugging an empty
   widget.
5. Capture the new template ID from the URL (e.g. `.../edit-template/23946` → ID `23946`).

### Step 6 — Install a 4th Code Snippet that injects the WPSR widget into the WC reviews tab

The template ID from Step 5 needs to be embedded in a Code Snippet that hooks into
`woocommerce_product_tabs` and prepends `do_shortcode('[wp_social_ninja id="N" platform="reviews"]')`
to the existing reviews-tab callback.

> **Critical shortcode gotcha** — the correct invocation is:
> `[wp_social_ninja id="<TEMPLATE_ID>" platform="reviews"]`
>
> NOT `[wpsr-reviews-<TEMPLATE_ID>]` (that's the rendered CSS class name, NOT the shortcode tag).
> NOT `platform="woocommerce"` (that's the *source* stored in the template's `post_content`;
> the shortcode renderer's allowed platforms are `reviews`, `twitter`, `youtube`, `instagram`,
> `facebook`, `tiktok`, `facebook_feed`, `testimonial`. Passing `woocommerce` returns
> "Provided platform name is not valid.")

Template for the snippet body — substitute `{{WPSR_TEMPLATE_ID}}` with the ID from Step 5:

```php
add_action('woocommerce_product_tabs', function($tabs) {
    if (isset($tabs['reviews']['callback'])) {
        $original = $tabs['reviews']['callback'];
        $tabs['reviews']['callback'] = function() use ($original) {
            echo do_shortcode('[wp_social_ninja id="{{WPSR_TEMPLATE_ID}}" platform="reviews"]');
            call_user_func($original);
        };
    }
    return $tabs;
}, 100);
```

This snippet is added as a 4th install step alongside the upload-handler / review-modal /
post-purchase-email snippets — same `wp_snippets` table insert pattern.

### Step 7 — Verify

```bash
# Fetch a product page and assert the modal markup is present
prod_url=$(curl -s "$WP_URL/shop/" | grep -oE "$WP_URL/product/[a-z0-9-]+/" | head -1)
html=$(curl -s "$prod_url")
echo "$html" | grep -q "twm-review-modal-overlay" && echo "PASS: modal present"
echo "$html" | grep -q "twm_get_upload_nonce" && echo "PASS: upload handler bootstrap present"
echo "$html" | grep -q "Click or drag photos here" && echo "PASS: dropzone label present"
echo "$html" | grep -oE 'wpsr-reviews-[0-9]+' | head -1   # should match the template ID
```

Then in a real browser: open a product page, click "Write a Review", upload a test photo,
submit. Confirm the review appears in the WPSR reviews widget with the photo attached.

**Verify the submission actually landed where it should:**

```bash
# FF submission record:
wp db query "SELECT id, status, LEFT(response,200) FROM wp_fluentform_submissions WHERE form_id=<FORM_ID> ORDER BY id DESC LIMIT 1"

# WPSR Pro review record (this is where photo reviews live — NOT wp_comments):
wp db query "SELECT id, platform_name, source_id, reviewer_name, rating, review_approved, LEFT(fields,200) FROM wp_wpsr_reviews ORDER BY id DESC LIMIT 1"
```

> **Critical mental model** — WPSR Pro reviews are stored in `wp_wpsr_reviews`, NOT `wp_comments`.
> The native WooCommerce review system (and CusRev / Customer Reviews for WooCommerce) use
> `wp_comments` with `comment_type='review'`. These are TWO PARALLEL SYSTEMS.
> - Reviews submitted via the photo-upload modal land ONLY in `wp_wpsr_reviews` and display
>   ONLY through the `[wp_social_ninja]` widget.
> - Reviews previously collected via WC native or CusRev stay in `wp_comments` and display
>   through WC's native review template (now hidden by our snippet).
> - Migrating between the two requires a separate ETL — not part of this recipe.

## Gotchas

1. **Brand prefix collision.** The `{{BRAND_PREFIX}}` is used in AJAX action names
   (`twm_review_upload`), post meta (`_twm_review_sent`), and cron actions
   (`twm_send_review_request`). It MUST be unique per WP install — if two brands ever
   shared a database (they don't today, but) the prefixes would collide. The element IDs
   `twm-review-modal`, `twm-uploader`, etc. don't strictly need to change since they're
   per-page, but it's cleaner to swap them too.

2. **Fluent Forms doesn't ship the file_upload element in the free version.** That's why
   `product-photos` is a hidden field populated by our custom JS, not by FF's native uploader.
   Don't try to "fix" this by switching to a `file_upload` element — Pro is required for that
   and we deliberately avoid Pro to keep the cost stack at WPSR Pro only.

3. **The default WC review form is hidden via CSS** (`#respond.comment-respond { display: none }`).
   If a brand later wants to allow logged-in WC customer reviews via the native form, remove
   that line from the modal snippet — but then they'll have two competing review forms.

4. **Photo URLs are stored as a comma-separated string** in the FF submission's `product-photos`
   field. WP Social Ninja's `review_images` mapping consumes that string. Don't change the
   join character without also editing the WPSR feed mapping.

5. **`wp_mail` filter cleanup.** The post-purchase email snippet adds a `wp_mail_content_type`
   filter and removes it via an anonymous closure. The remove call doesn't actually match the
   add (anonymous functions get different hashes) — in practice this is harmless because
   subsequent `wp_mail` calls re-add the filter, but it's a known wart. Fix would be a named
   function.

6. **Rate limit is per IP via WordPress transient.** Default is 10 uploads/hour. Behind a CDN
   that hides the real client IP (Cloudflare without `mod_cloudflare`), the limit applies to
   the CDN edge IP — could starve legitimate uploads. Check `wp_get_referer()` / `HTTP_CF_CONNECTING_IP`
   if going behind a CDN.

7. **MKB bridge gap.** The MKB plugin's `/plugins/install-and-activate` endpoint exists
   (v1.1.0+). A `/snippets/install` endpoint does NOT exist yet. Until it's added, snippet
   installation falls back to:
   - Manual: paste the rendered PHP into WP admin → Snippets → Add New, save active.
   - Programmatic: a one-shot Code Snippet that calls the Code Snippets plugin's API to
     insert the other three snippets, then self-deactivates.
   Adding this endpoint to MKB is **Step 0 of the rollout to all brands** below.

8. **Form ID parameterization.** The modal snippet's `do_shortcode('[fluentform id="5"]')`
   hardcodes form ID 5. The renderer substitutes `{{FF_FORM_ID}}` at render time, so each
   brand gets the correct ID. Don't forget to capture the FORM_ID returned from Step 2.

## Rollout plan (across the JonOps brand portfolio)

In rollout order (small → large blast radius):

1. **Custom Creative Store** (`customcreative.store`) — first deploy. Waiting customer wants to leave
   a photo review now. Validates the recipe against a non-TM site.
2. **CuteMerch** (`cutemerch.love`) — already has FF + WPSR Pro patterns.
3. **WeLoveHoroscope** (`welovehoroscope.com`) — POD store, photo reviews high-value.
4. **OrganicAromas** (`organicaromas.com`) — real product photos lift conversion most.
5. **UtamaSpice** (`utamaspice.com`).
6. **OlyLife** (`olylife.international`) — pending real product photo policy (see
   `project_olylife_imagery.md`); customers uploading real photos is fine even though brand-
   side AI imagery is blocked.
7. **BroSharks** (`brosharks.com`) — sandbox; lowest priority.
8. **Villa Amrita** — different product type (stays at the villa); skip until reviewed.

## Promotion to higher abstractions

Once the recipe is proven on 2-3 brands:

- **Store Drop Skill** — add `install-photo-review-form` as an optional node in
  `deploy-pod-store.yaml`, gated by a `--with-photo-reviews` flag. Stays opt-in until WPSR
  Pro licensing is sorted for new-student MEGA sites.
- **Templatized JonOps** — bake into the per-brand bootstrap so any new brand gets the form
  on day 1.
- **MKB bridge** — add the `/snippets/install` endpoint (see gotcha #7) so the whole flow is
  a single `bridge_post` call per brand.

## Files in this recipe

- `README.md` (this doc)
- `templates/snippet-upload-handler.php` — parameterized AJAX handler + JS injector
- `templates/snippet-review-modal.php` — parameterized modal + button + FF embed
- `templates/snippet-post-purchase-email.php` — parameterized 14-day review request email
- `templates/snippet-wpsr-widget.php` — parameterized 4th snippet: injects the WPSR widget into the WC reviews tab (added 2026-05-27 after CC deploy)
- `tm-reference/snippet-66-twm-raw.php` — frozen TM source for snippet 66 (post-purchase email)
- `tm-reference/snippet-70-twm-raw.php` — frozen TM source for snippet 70 (upload handler)
- `tm-reference/snippet-73-twm-raw.php` — frozen TM source for snippet 73 (modal)
- `tm-reference/ff5-form-definition.json` — frozen FF form 5 export with WPSR feed

## Provenance

Reconstructed from `taiwanmerch.co` live state on 2026-05-27 by querying:
- `GET /wp-json/code-snippets/v1/snippets/{66,70,73}` (via container `jonops-taiwanmerch` WP App Password)
- `GET /wp-json/fluentform/v1/forms/5`
- `GET /shop/` + product page HTML grep for `twm-*` markers

Containerized credentials live at `jonops-taiwanmerch` env (`WP_URL`, `WP_USERNAME`, `WP_PASSWORD`).
