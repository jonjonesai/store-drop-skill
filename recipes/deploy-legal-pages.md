# Recipe: Deploy Legal Pages

> Creates the 4 legal pages (Privacy Policy, Terms of Service, Returns & Refunds, Cookie Policy) with brand-specific variable substitution. Uses `/pages/ensure` for idempotent re-runs.

## Inputs Required

| Input | Source | Example |
|---|---|---|
| `brand_name` | Intake Q1 | `CuteMerch` |
| `email` | Intake Q6 (or derived) | `hello@cutemerch.love` |
| `domain` | From .env `BRIDGE_SITE` | `https://cutemerch.love` |
| `year` | Current year | `2026` |

## Important

**Legal text is NEVER AI-generated.** These are static boilerplate templates with variable substitution only. The source templates are in `boilerplate/`. Students should have a lawyer review before going live with high-revenue stores.

## Execution

### Step 1: Perform variable substitution

For each boilerplate file, replace:
- `{brand_name}` → student's brand name
- `{email}` → student's business email
- `{domain}` → site URL from .env
- `{year}` → current year

### Step 2: Create each page via `/pages/ensure`

`/pages/ensure` is idempotent — if the page already exists (by slug), it returns the existing page instead of creating a duplicate. Safe for re-runs.

#### Privacy Policy

```bash
curl -s -X POST "${BRIDGE_URL}/pages/ensure" \
  -u "claude-bot:${BRIDGE_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Privacy Policy",
    "slug": "privacy-policy",
    "status": "publish",
    "content": "<!-- wp:paragraph -->\n<p>${SUBSTITUTED_PRIVACY_CONTENT}</p>\n<!-- /wp:paragraph -->"
  }'
```

Save the returned `id` as `PRIVACY_ID`.

#### Terms of Service

```bash
curl -s -X POST "${BRIDGE_URL}/pages/ensure" \
  -u "claude-bot:${BRIDGE_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Terms of Service",
    "slug": "terms-of-service",
    "status": "publish",
    "content": "<!-- wp:paragraph -->\n<p>${SUBSTITUTED_TERMS_CONTENT}</p>\n<!-- /wp:paragraph -->"
  }'
```

Save the returned `id` as `TERMS_ID`.

#### Returns & Refunds

```bash
curl -s -X POST "${BRIDGE_URL}/pages/ensure" \
  -u "claude-bot:${BRIDGE_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Returns & Refunds",
    "slug": "returns-and-refunds",
    "status": "publish",
    "content": "<!-- wp:paragraph -->\n<p>${SUBSTITUTED_RETURNS_CONTENT}</p>\n<!-- /wp:paragraph -->"
  }'
```

Save the returned `id` as `RETURNS_ID`.

#### Cookie Policy (optional)

Only create if the student targets EU/UK customers or requests it.

```bash
curl -s -X POST "${BRIDGE_URL}/pages/ensure" \
  -u "claude-bot:${BRIDGE_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Cookie Policy",
    "slug": "cookie-policy",
    "status": "publish",
    "content": "<!-- wp:paragraph -->\n<p>${SUBSTITUTED_COOKIE_CONTENT}</p>\n<!-- /wp:paragraph -->"
  }'
```

### Step 3: Publish and set page meta

**Important:** `/pages/ensure` may return a pre-existing draft page (e.g. WordPress auto-creates a Privacy Policy draft seeded with "Suggested text:" boilerplate). It does NOT update the status or content of existing pages. ALWAYS follow up with an explicit `POST /posts/{id}` that includes `content` (not just status + meta) to force-replace the WP-default boilerplate with the brand-substituted content. The `content` field is mandatory on every iteration — never conditional, never optional.

```bash
# Map of PAGE_ID -> substituted content (built from boilerplate/ in Step 1)
declare -A CONTENT_MAP=(
  [$PRIVACY_ID]="$SUBSTITUTED_PRIVACY_CONTENT"
  [$TERMS_ID]="$SUBSTITUTED_TERMS_CONTENT"
  [$RETURNS_ID]="$SUBSTITUTED_RETURNS_CONTENT"
)

for PAGE_ID in "${!CONTENT_MAP[@]}"; do
  BODY=$(PAGE_CONTENT="${CONTENT_MAP[$PAGE_ID]}" python3 -c '
import os, json
print(json.dumps({
  "status": "publish",
  "content": os.environ["PAGE_CONTENT"],
  "meta": {
    "_kad_post_title": "hide",
    "_kad_post_feature": "hide",
    "_kad_post_vertical_padding": "disable",
    "_kad_post_layout": "normal"
  }
}))')
  curl -s -X POST "${BRIDGE_URL}/posts/${PAGE_ID}" \
    -u "claude-bot:${BRIDGE_PASS}" \
    -H "Content-Type: application/json" \
    -d "$BODY"
done
```

The `python3 -c json.dumps(...)` pattern handles all quote/apostrophe escaping in legal prose — never hand-construct the JSON via shell-only quoting.

### Step 4: Flush cache

```bash
curl -s -X POST "${BRIDGE_URL}/cache/flush" -u "claude-bot:${BRIDGE_PASS}"
```

### Step 5: Verify

Use `recipes/verify-deployment.md` for each legal page:

```bash
for SLUG in privacy-policy terms-of-service returns-and-refunds; do
  STATUS=$(curl -s "${BRIDGE_URL}/render?url=/${SLUG}/" \
    -u "claude-bot:${BRIDGE_PASS}" | jq -r '.status')
  echo "${SLUG}: ${STATUS}"
done
```

All should return `200`.

## Content Formatting

When inserting the boilerplate content into WordPress, convert the plain text sections into WordPress paragraph blocks. Each section heading should be a `<!-- wp:heading -->` block, and each paragraph a `<!-- wp:paragraph -->` block.

Example conversion:

```
Input:  "INFORMATION WE COLLECT\n\nWe collect information..."
Output: "<!-- wp:heading {\"level\":2} -->\n<h2>Information We Collect</h2>\n<!-- /wp:heading -->\n\n<!-- wp:paragraph -->\n<p>We collect information...</p>\n<!-- /wp:paragraph -->"
```

Use title case for headings (not ALL CAPS from the template).

## Output

Returns a map of page IDs for use by `build-nav-menus`:

```json
{
  "privacy": 50,
  "terms": 51,
  "returns": 52,
  "cookie": 53
}
```
