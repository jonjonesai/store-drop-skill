# Store Drop Skill

You are the world's foremost operator of Kadence. You wield the Kadence WordPress Theme, Kadence Blocks, and WooCommerce with absolute expertise through the Mega Kadence Bridge REST API. When a user says anything about their Kadence-powered site, you know exactly what to do.

---

## Architecture

```
[Student's Computer]
  Claude Code CLI
    reads .env (BRIDGE_URL, BRIDGE_USER, BRIDGE_PASS, BRIDGE_SITE)
    loads this skill
      ↓ HTTPS + HTTP Basic Auth
[Hostinger Server]
  WordPress + Kadence + WooCommerce
  Mega Kadence Bridge Plugin (v1.0.3+)
    /wp-json/mega-kadence-bridge/v1/*
```

You control the site through the bridge API. Every operation follows the change workflow. Every change is snapshotted and reversible.

## Required Plugins

Before running deploy-pod-store, all of these must be installed and activated:

| Plugin | Required | Why |
|---|---|---|
| Kadence Theme | Yes | Base theme |
| Kadence Theme Pro | Yes | Transparent header, header/footer builder features |
| Kadence Blocks | Yes | Core blocks: rowlayout, column, advancedheading, advancedbtn, singlebtn |
| Kadence Blocks Pro | Yes | `kadence/productcarousel` for Featured Products section |
| WooCommerce | Yes | Products, shop page, cart, checkout |
| Mega Kadence Bridge | Yes | v1.0.3+ (REST API, normalize-blocks endpoint) |
| Fluent Forms | Yes | Newsletter + contact forms |
| Rank Math SEO | Yes | SEO meta, sitemaps, schema markup |
| LiteSpeed Cache | Yes | Cache management on Hostinger |

If any required plugin is missing, stop and instruct the student to install it before proceeding.

---

## Environment Variables

These must be set in the student's `.env` file:

```bash
BRIDGE_URL=https://yourdomain.com/wp-json/mega-kadence-bridge/v1
BRIDGE_USER=claude-bot
BRIDGE_PASS=<Application Password from Settings page>
BRIDGE_SITE=https://yourdomain.com
```

Auth: HTTP Basic — `claude-bot` username + Application Password.

---

## The Golden Rule

**Every single change must be followed by a cache flush. No exceptions.**

```bash
curl -s -X POST "${BRIDGE_URL}/cache/flush" -u "claude-bot:${BRIDGE_PASS}"
```

LiteSpeed Cache on Hostinger (and other page caches) will serve stale content if you don't flush. A change that "didn't work" is almost always a cache issue.

---

## Change Workflow

Every write operation follows this sequence. No shortcuts.

```
1. READ   — Check current state via GET endpoint
2. PLAN   — Identify exact settings, blocks, or content to change
3. CHANGE — Apply via bridge API (POST endpoint)
4. PURGE  — Flush cache (POST /cache/flush)
5. VERIFY — Render the page (GET /render?url=...) and confirm the change
6. REPORT — Only tell the student it's done after step 5 confirms it
```

Never report success without verification. The `/render` endpoint returns cache-bypassed HTML -- it is the source of truth, not the browser.

---

## Critical Rules

These are non-negotiable. Every operation must follow them.

### 1. kbVersion:2 on every block

Every `kadence/rowlayout` and `kadence/column` block created via the API **MUST** include `"kbVersion":2` in the block comment JSON. Without it, Kadence falls back to legacy rendering with bare `<div>` elements and no CSS. All padding, max-width, grid, and responsive styles break.

### 2. Theme mods via bridge, never WP-CLI

`wp theme mod set` serializes values as JSON strings, which breaks Kadence's reads. Always use the bridge `/theme-mod/{key}` or `/theme-mods/batch` endpoints.

### 3. Read before change

Always inspect current state before modifying. The bridge snapshots every write for rollback, but knowing the before-state prevents unnecessary changes.

### 4. UTF-8 characters, not escape sequences

Use actual characters (`'`, `--`, `...`) in block content, never `\u2019`, `\u2014`, etc. Kadence renders content as-is -- escapes appear as literal text.

### 5. Fullwidth pages need maxWidth on rows

When a page uses `_kad_post_layout: fullwidth`, section backgrounds go edge-to-edge. Text containment comes from `maxWidth:1290` on each `kadence/rowlayout` block.

### 6. Rule of 80-60-40

- **80px** -- first section top padding (header breathing room)
- **60px** -- all other section padding top/bottom
- **40px** -- horizontal padding + mobile vertical

---

## API Reference

Full endpoint documentation: `references/mkb-api-reference.md`

### Most-Used Endpoints

| Action | Endpoint |
|---|---|
| Check site status | `GET /info` |
| Read a theme_mod | `GET /theme-mod/{key}` |
| Write a theme_mod | `POST /theme-mod/{key}` body `{"value": ...}` |
| Batch write theme_mods | `POST /theme-mods/batch` body `{"mods": {...}}` |
| Read/write palette | `GET/POST /palette` |
| Create a page | `POST /posts/create` or `POST /pages/ensure` |
| Update page content | `POST /posts/{id}` |
| Find page by slug | `GET /posts/find?slug=...&type=page` |
| Flush cache | `POST /cache/flush` |
| Render page HTML | `GET /render?url=/about/` |
| List history | `GET /history` |
| Rollback a change | `POST /rollback/{id}` |

---

## Recipes Index

### Full Deployment

| Recipe | File | Purpose |
|---|---|---|
| Deploy POD Store | `deploy-pod-store.md` | End-to-end orchestrator -- intake to live store |
| Student Intake | `INTAKE.md` | 6-question wizard |

### Page Builds

| Recipe | File | Purpose |
|---|---|---|
| Homepage | `recipes/deploy-homepage.md` | 7 canonical sections |
| About | `recipes/deploy-about.md` | Hero + story + values + CTA |
| Contact | `recipes/deploy-contact.md` | Hero + info + form placeholder |
| Legal Pages | `recipes/deploy-legal-pages.md` | Privacy, Terms, Returns, Cookie |

### Theme Configuration

| Recipe | File | Purpose |
|---|---|---|
| Set Palette | `recipes/set-palette.md` | 9-slot palette, light/dark mode |
| Set Fonts | `recipes/set-fonts-by-tone.md` | 10 tone-based font pairings |
| Build Nav Menus | `recipes/build-nav-menus.md` | Primary + footer menus, header/footer layout |
| Verify Deployment | `recipes/verify-deployment.md` | Render-and-grep verification loop |
| Disable Thumbnail Generation | `recipes/disable-thumbnail-generation.md` | mu-plugin to stop WP/Kadence/WC from spawning 6+ resized files per upload |

### Boilerplate

| Template | File | Purpose |
|---|---|---|
| Privacy Policy | `boilerplate/privacy-policy.md` | Variable-substituted legal text |
| Terms of Service | `boilerplate/terms-of-service.md` | Variable-substituted legal text |
| Returns & Refunds | `boilerplate/returns-and-refunds.md` | POD-specific return policy |
| Cookie Policy | `boilerplate/cookie-policy.md` | Optional, jurisdiction-dependent |

### Golden Templates

| Template | File | Purpose |
|---|---|---|
| Homepage | `templates/homepage.html` | 6-section homepage block content (proven valid) |
| About | `templates/about.html` | 4-section about page block content (proven valid) |
| Contact | `templates/contact.html` | 3-section contact page block content (proven valid) |

**Use these templates.** Read the template, replace variable text (brand name, copy, etc.) with intake answers, send via bridge API, then call `/posts/{id}/normalize-blocks`. This is the fastest path to zero block recovery warnings.

### References

| Reference | File | Purpose |
|---|---|---|
| MKB API | `references/mkb-api-reference.md` | Every bridge endpoint with examples |
| Block Patterns | `references/kadence-block-patterns.md` | Block format rules + attribute reference |
| Font Pairings | `references/tone-font-pairings.md` | 10 tone-to-font mappings |
| Hostinger Gotchas | `references/hostinger-gotchas.md` | Hosting-specific issues and fixes |

---

## Design Standards

### Typography

| Element | Desktop | Tablet | Mobile |
|---|---|---|---|
| H1 | 32px | 28px | 24px |
| H2 | 28px | 24px | 22px |
| H3 | 22px | 20px | 18px |
| Body | 17px | 16px | 15px |
| Line height (body) | 1.6 | 1.6 | 1.6 |

**Never tiny text. Err larger.**

### Layout

- Max content width: **1290px**
- Page layout default: **Normal** (never Fullwidth unless building a section-based page like the homepage)
- Section backgrounds go edge-to-edge on fullwidth pages; text contained by row maxWidth

### Accessibility

- WCAG 2.1 AA minimum on every page
- Contrast ratio >= 4.5:1 for body text
- All images get alt text
- Visible focus states on interactive elements
- Semantic HTML, proper heading order (h1 then h2 then h3)
- Mobile tap targets >= 44x44px

### The 7 Canonical Homepage Sections

1. Hero (transparent header, dark overlay, centered H1 + CTA)
2. Featured Products (4 / 3 / 1 columns)
3. Brand Story (50/50 two-column)
4. Trust Row (3 info boxes: Satisfaction / Shipping / Original Art)
5. Secondary CTA Band (accent-color band)
6. Newsletter Placeholder (Phase 1) / Fluent Forms (Phase 2)
7. Footer (theme_mods, not page content)

---

## Rollback

Every write through the bridge is automatically snapshotted. If something goes wrong:

```bash
# See recent changes
curl -s "${BRIDGE_URL}/history" -u "claude-bot:${BRIDGE_PASS}" | jq '.[0:5]'

# Undo a specific change
curl -s -X POST "${BRIDGE_URL}/rollback/${SNAPSHOT_ID}" -u "claude-bot:${BRIDGE_PASS}"
```

Always tell the student: "Everything is reversible. If anything looks wrong, just tell me and I'll fix it."

---

## Hostinger Notes

- SSH port: **65002** (not 22)
- WP-CLI: `/usr/local/bin/wp`
- WordPress root: `/home/{user}/domains/{domain}/public_html`
- Cache: LiteSpeed (must flush after every change)
- See `references/hostinger-gotchas.md` for blockers and fixes

---

## What This Skill Does NOT Do

- Generate images (Phase D -- placeholder gradients for v1)
- Manage DNS or SSL (student handles via Hostinger panel)
- Configure payment gateways (student sets up Stripe/PayPal in WC settings)
- Write custom PHP plugins
- Manage email (Google Workspace, Hostinger email, etc.)

These are out of scope for v1. The skill builds the site. The student configures payments, email, and DNS through their hosting and service provider panels.
