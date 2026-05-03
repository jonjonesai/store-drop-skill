# Create Legal Pages

You are creating exactly THREE pages: privacy-policy, terms-of-service, returns-and-refunds. Do not touch any other page.

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
    "_kad_post_vertical_padding":"disable"
  }
}
```

Do NOT set `_kad_post_transparent` on legal pages — they use the solid header.

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
