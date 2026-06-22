# Store-Drop fixes — 2026-06-22 (generationx.art settings audit)

Three core-settings omissions Jon flagged on the live generationx.art store.
All fixed live on gx via the bridge AND baked into the skill so every future
drop sets them automatically. Per the standing rule: fix in the skill, verify,
document. See `feedback_lock_flagged_problems_into_skill`.

Implementation: new lib `.archon/lib/wp-settings.sh` (`wp_apply_core_settings` /
`wp_check_core_settings`), wired into `deploy-pod-store.yaml` as the
`enforce-wp-settings` + `check-wp-settings` nodes (run after content-style,
before products). All over the bridge `/wp-eval` — no SSH/WP-CLI, works on any
customer box.

| # | Omission | Fix | Verified on gx |
|---|----------|-----|----------------|
| 1 | Permalinks were `/%postname%/` | `permalink_structure` → `/%category%/%postname%/` + `flush_rewrite_rules()` | ✅ reads `/%category%/%postname%/` |
| 2 | Media sizes were stock (150/300/1024/768) — WP generates a copy of every upload at each size | Zero **all** of `thumbnail/medium/large/medium_large_size_{w,h}` + `thumbnail_crop` | ✅ all 0 |
| 3 | LiteSpeed image optimization off | `\LiteSpeed\Conf::cls()->update_confs(['img_optm-auto'=>true,'img_optm-webp'=>1])` — auto-optimize new images, serve WebP | ✅ `img_optm-webp=1` |

## Notes
- **LiteSpeed WebP (#3):** the toggle is set; actual WebP *generation* runs
  through QUIC.cloud once a domain key is connected (LSCWP requests one
  automatically on first optimization). The skill sets the intent so it kicks in
  without the customer touching anything. LSCWP 7.8.1 stores config via
  `\LiteSpeed\Conf::update_confs()`; the legacy `litespeed.conf` option array is
  lazily created and was empty on the fresh box.
- **Deferred to Phase 2 (spam protection):** FluentForms honeypot (keyless,
  easy to automate now) + reCAPTCHA. reCAPTCHA needs per-domain Google
  site/secret keys, so "solve reCAPTCHA for the user" = either auto-mint keys via
  a Google API or ship a shared MEGA key — design call for Phase 2. Logged in
  `docs/STORE-DROP-PHASE-2.md`.
