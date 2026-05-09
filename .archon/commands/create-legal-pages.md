# Create Legal Pages

You are creating exactly THREE pages: privacy-policy, terms-of-service, returns-and-refunds. Do not touch any other page.

**Heartbeat rule:** every ~20 seconds during your work, echo a single status line to stdout starting with `[legal]` so the user watching the terminal knows you are still active. Examples: `[legal] reading boilerplate`, `[legal] substituting placeholders for privacy-policy`, `[legal] calling /pages/ensure for terms`, `[legal] writing artifacts`.

**Quoting discipline (CRITICAL):** legal prose contains apostrophes, quotes, and special characters. Bash heredocs and shell single-quoting will tangle these and force a self-correct cycle that adds 2-3 minutes per page. To avoid the issue entirely:

- Build EVERY API request body using `python3 -c '...' << EOF` heredocs that read inputs from environment variables, then call `json.dumps()` to produce properly-escaped JSON.
- NEVER hand-construct a JSON string with embedded apostrophes or quotes via shell-only quoting.

Pattern (use exactly this shape):
```bash
TITLE="Privacy Policy"
SLUG="privacy-policy"
CONTENT_HTML="<...the wrapped wp blocks...>"
BODY=$(TITLE="$TITLE" SLUG="$SLUG" CONTENT="$CONTENT_HTML" python3 -c '
import os, json
print(json.dumps({
  "title": os.environ["TITLE"],
  "slug": os.environ["SLUG"],
  "status": "publish",
  "type": "page",
  "content": os.environ["CONTENT"],
}))')
bridge_post "/pages/ensure" "$BODY"
```

The python3 step handles ALL quote escaping. Apostrophes in the content pass through unchanged. No self-correct cycle.

## Setup

```bash
source "$HOME/kadence-skill/mega-kadence-skill/.archon/lib/bridge.sh"
source "$HOME/kadence-skill/mega-kadence-skill/.archon/lib/intake.sh"
source "$HOME/kadence-skill/mega-kadence-skill/.archon/lib/pages.sh"
bridge_check_env || exit 1
```

Read intake from `$ARTIFACTS_DIR/intake.json`. Read the three boilerplate files:

- `boilerplate/privacy-policy.md`
- `boilerplate/terms-of-service.md`
- `boilerplate/returns-and-refunds.md`

Each contains a `## Content` block of plain prose with placeholders `{brand_name}`, `{email}`, `{year}`, `{domain}`.

## For each of the 3 pages

### 1. Build the content

Substitute placeholders:
- `{brand_name}` → intake `brand_name`
- `{email}` → derive `info@<domain>` from bridge site URL
- `{year}` → current year
- `{domain}` → bare domain from bridge site URL (no protocol, no path)

Wrap the prose in standard WordPress blocks (NOT Kadence blocks — these pages don't need `kbVersion`):
- One `<!-- wp:heading -->` per ALL-CAPS section title (e.g. "INFORMATION WE COLLECT")
- One `<!-- wp:paragraph -->` per text block
- Use `<!-- wp:list -->` for any bullet lists

### 2. Create the page

```
POST /pages/ensure  with  {"title":"<Title>","slug":"<slug>","status":"publish","type":"page","content":"<wrapped-html>"}
```

Title casing:
- `privacy-policy` → "Privacy Policy"
- `terms-of-service` → "Terms of Service"
- `returns-and-refunds` → "Returns & Refunds"

WordPress may have a pre-existing draft Privacy Policy. The `/pages/ensure` endpoint returns the existing ID; that's fine — proceed to force-publish in step 3.

### 3. Force-publish + meta

```
POST /posts/{id}  with  {
  "status":"publish",
  "meta":{
    "_kad_post_title":"hide",
    "_kad_post_feature":"hide",
    "_kad_post_vertical_padding":"disable",
    "_kad_post_layout":"normal"
  }
}
```

Do NOT set `_kad_post_transparent` on legal pages — they use the solid header.

`_kad_post_layout: "normal"` is REQUIRED on legal pages. The site-wide Kadence customizer default is set to `fullwidth` for the homepage / about / contact / shop pages, so legal pages would inherit fullwidth and render long legal copy edge-to-edge — unreadable. `"normal"` overrides per-page so legal text wraps at content width.

### 4. Write artifact

```bash
pages_write_one privacy-policy <ID> /privacy-policy/
pages_write_one terms-of-service <ID> /terms-of-service/
pages_write_one returns-and-refunds <ID> /returns-and-refunds/
```

(Use the right ID for each.)

After all 3 are done, print:

```
CREATED: privacy-policy id=<ID>
CREATED: terms-of-service id=<ID>
CREATED: returns-and-refunds id=<ID>
```

and stop.
