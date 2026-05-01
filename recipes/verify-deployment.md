# Recipe: Verify Deployment

> The render-and-grep verification loop. Call this after every page creation or theme change to confirm the change is live.

## The Rule

**Never report success without verification.** The `/render` endpoint returns cache-bypassed HTML — it's the source of truth, not the browser.

## Single Page Verification

### Step 1: Render the page

```bash
RENDER=$(curl -s "${BRIDGE_URL}/render?url=${PAGE_PATH}" \
  -u "claude-bot:${BRIDGE_PASS}")

STATUS=$(echo "$RENDER" | jq -r '.status')
HTML=$(echo "$RENDER" | jq -r '.html')
LENGTH=$(echo "$RENDER" | jq -r '.length')
```

### Step 2: Check HTTP status

```bash
if [ "$STATUS" != "200" ]; then
  echo "FAIL: ${PAGE_PATH} returned status ${STATUS}"
  exit 1
fi
```

### Step 3: Check for expected content markers

Each page type has specific markers to verify:

#### Homepage

```bash
echo "$HTML" | grep -c "wp-block-kadence-rowlayout"  # Kadence rows rendered
echo "$HTML" | grep -c "${BRAND_NAME}"                # Brand name appears
echo "$HTML" | grep -c "Shop Now\|Browse All"         # CTA buttons present
echo "$HTML" | grep -c "kt-row-column-wrap"           # kbVersion:2 active (NOT bare divs)
```

**Critical:** If you see `kb-row-layout-id` but NOT `kt-row-column-wrap`, the blocks are missing `kbVersion:2` and all CSS is broken.

#### About Page

```bash
echo "$HTML" | grep -c "About\|Our Story"
echo "$HTML" | grep -c "wp-block-kadence-rowlayout"
```

#### Contact Page

```bash
echo "$HTML" | grep -c "Contact\|Get in Touch"
echo "$HTML" | grep -c "wp-block-kadence-rowlayout"
```

#### Legal Pages

```bash
echo "$HTML" | grep -c "${BRAND_NAME}"   # Brand name substituted
echo "$HTML" | grep -c "Privacy\|Terms\|Returns\|Cookie"
```

#### Shop Page

```bash
echo "$HTML" | grep -c "woocommerce\|products"
```

### Step 4: Check palette is applied

```bash
echo "$HTML" | grep -c "global-palette1\|--global-palette"
```

If 0 matches, the palette was not applied or cache was not flushed.

### Step 5: Check for kbVersion:2 rendering

```bash
# Good: kt-row-column-wrap present (kbVersion:2 active)
KB_V2=$(echo "$HTML" | grep -c "kt-row-column-wrap")

# Bad: bare div without Kadence classes (kbVersion:2 missing)
BARE=$(echo "$HTML" | grep -c "kb-row-layout-id.*<div" | head -1)

if [ "$KB_V2" -eq 0 ] && [ "$BARE" -gt 0 ]; then
  echo "FAIL: kbVersion:2 missing — blocks rendering without Kadence CSS"
fi
```

## Full Site Verification

Run after `deploy-pod-store` completes. Checks every page in sequence.

```bash
PAGES=("/" "/about/" "/contact/" "/shop/" "/privacy-policy/" "/terms-of-service/" "/returns-and-refunds/")
PASS=0
FAIL=0

for PAGE in "${PAGES[@]}"; do
  STATUS=$(curl -s "${BRIDGE_URL}/render?url=${PAGE}" \
    -u "claude-bot:${BRIDGE_PASS}" | jq -r '.status')
  
  if [ "$STATUS" = "200" ]; then
    PASS=$((PASS + 1))
    echo "PASS: ${PAGE}"
  else
    FAIL=$((FAIL + 1))
    echo "FAIL: ${PAGE} (status: ${STATUS})"
  fi
done

echo ""
echo "Results: ${PASS} passed, ${FAIL} failed out of ${#PAGES[@]} pages"
```

## Verification Report Format

After full-site verification, report to the student:

```
Deployment verified:

| Page | Status | URL |
|---|---|---|
| Homepage | PASS | https://yourdomain.com/ |
| About | PASS | https://yourdomain.com/about/ |
| Contact | PASS | https://yourdomain.com/contact/ |
| Shop | PASS | https://yourdomain.com/shop/ |
| Privacy Policy | PASS | https://yourdomain.com/privacy-policy/ |
| Terms of Service | PASS | https://yourdomain.com/terms-of-service/ |
| Returns & Refunds | PASS | https://yourdomain.com/returns-and-refunds/ |

All 7 pages live and rendering correctly.
```

## Common Failure Modes

| Symptom | Cause | Fix |
|---|---|---|
| Status 404 | Page not created or wrong slug | Check `/posts/find?slug=...` |
| Status 200 but empty content | Page exists but has no content blocks | Re-run the page recipe |
| No `kt-row-column-wrap` in HTML | Missing `kbVersion:2` on row/column blocks | Re-create page content with `kbVersion:2` |
| Brand name missing | Placeholder substitution failed | Update post content with correct brand name |
| Palette not applied | Cache not flushed after palette change | Run `/cache/flush` |
| Old content still showing | LiteSpeed serving stale cache | Run `/cache/flush`, wait 5 seconds, re-render |
| White flash / wrong background | Dark mode `content_background` not cleared | Set `content_background` to empty string |
