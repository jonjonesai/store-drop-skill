# Store-Drop Phase 2 — backlog (living list)

Phase 1 = drop a complete, live, branded store from blank WordPress. Phase 2 =
make it *optimally configured and connected* automatically, so the customer
gets a store set up the way an expert would set it up — not just built.

This is a living doc. We add to it and keep building items in.

---

## Workstream 1 — Auto-connect (collapse Video 2 into Video 1)
The deploy already builds the store; make it also **hand the keys to MEGA** so the
customer never does the manual connect.
- [ ] Deploy mints the **Woo REST keys** (MKB `/woo/api-keys/generate` exists — call it after Woo installs).
- [ ] Deploy captures the **WP username + app password** (already in the bridge creds) for MEGA's `/wp-json/wp/v2/media` uploads.
- [ ] **MEGA ingest endpoint** — receive the bundle (token-authed) and store it on the user's record (`woo_url/key/secret`, `wp_username/app_password`). Fields already exist in `users_db`.
- [ ] Result: after the drop, MEGA can publish products into the store with zero manual setup.
- Note: Printful + Stripe stay customer-connected (their own external accounts).

## Workstream 2 — Premium plugin bucket expansion
Add more licensed plugins to R2 so the drop installs a fuller pro stack. Jon owns
the licenses (unlimited-site tiers); Claude wires the install + delivery.
- [x] **Rank Math Pro** — in the bucket as `plugins/seo-by-rank-math-pro-3.0.115.zip` (slug `seo-by-rank-math-pro`, sha256 `faa6c84f8d2743050ace0150d1a66cfe0aa2f8be7a981aa6600b6f4256aa37be`). Free `seo-by-rank-math` already installs; Pro layers on top (needs free active first). **Claude wiring in progress:** `premium-manifest.json` + MEGA `store_drop_delivery.PREMIUM_ARTIFACTS` + `install-stack.sh` activation order.
- [ ] **Fluent Affiliate** — let customers run an affiliate program out of the box (fits the Fluent stack already bundled: FluentForms + FluentCRM). Jon: drop the zip in R2 + ping; Claude wires it.
- [ ] Others — TBD; the bucket + manifest pattern is now repeatable, so each new licensed plugin is just: Jon buckets the zip → Claude adds the manifest entry + install step.

## Workstream 3 — Optimal store settings (Jon's expertise → automated)
The ideal WooCommerce / WordPress / Rank Math configuration a fresh store should
ship with. **Jon fills this from experience; Claude builds each into the workflow
as a deterministic bridge call.** Seed list below — expand freely:

### WordPress core
- [x] **Permalinks → `/%category%/%postname%/`** — `enforce-wp-settings` node (2026-06-22)
- [x] **Media sizes all zeroed** — no thumbnail/medium/large/medium_large copies per upload (2026-06-22)
- [x] **LiteSpeed image WebP optimization on** — `img_optm-auto` + `img_optm-webp=1` (2026-06-22; full conversion via QUIC.cloud once domain key connects)
- [ ] Timezone / date format
- [ ] Discourage-search-engines = OFF (store is public — done via coming-soon, confirm WP `blog_public=1`)
- [ ] Comments off on products
- [ ] *(Jon: add your settings…)*

### Spam protection (Jon flagged 2026-06-22; deferred here from the settings pass)
- [ ] **FluentForms honeypot** — keyless, fully automatable now over the bridge; turn on by default.
- [ ] **reCAPTCHA "solved for the user"** — needs per-domain Google site/secret keys. Design call: auto-mint via a Google reCAPTCHA API, or ship a shared MEGA key, or have MEGA hold keys and inject. Pick the approach, then wire it into the forms step.

### WooCommerce
- [ ] Store address / base country
- [ ] Currency + position
- [ ] Selling locations / shipping destinations
- [ ] Tax — enable? config?
- [ ] Shipping zones / flat-rate defaults
- [ ] Checkout — guest checkout, account creation on checkout, field tidy-up
- [ ] Product settings — reviews, stock display, placeholder image
- [ ] Order/email settings — from-name, from-address, branding
- [ ] *(Jon: the rest of your optimum WooCommerce settings…)*

### Rank Math (after Pro is bundled)
- [ ] Setup-wizard config (site type, schema, titles)
- [ ] Sitemap on
- [ ] Local/brand schema
- [ ] *(Jon: your SEO defaults…)*

---

## How we work this
Jon dumps the settings he knows are optimal; Claude turns each into a deterministic
step in `deploy-pod-store.yaml` (bridge `/option/*`, `/theme-mod/*`, or `/wp-eval`),
verifies it on a real build, and checks the box. Same discipline as Phase 1:
fixed in the skill, verified, documented. See [feedback: lock flagged problems in].
