# Mega Kadence Skill — Hardening Plan

> Goal: every user on every supported machine gets a successful Store Drop on the first run, with no manual debug, no version pinning, no dev-machine workarounds. Failures are loud, recoverable, and never silent. This document tracks the specific bugs we've hit and the structural changes that prevent the whole class.

Authored 2026-05-09 after the cutemerch.love laptop deploy session that surfaced ~6 failure modes in one sitting.

---

## Failure modes observed (root cause, not symptom)

1. **Fresh-install regression at `apply-theme-config`** — Claude Code 2.1.138 changed Archon's `skills_agent_created` path so the spawned agent loses Bash/HTTP tools. Patched `0f46e9a` by dropping the `skills:` field. Class of bug: **upstream tool-version drift**.

2. **AI nodes flailing on real work** — `apply-theme-config` took 2m15s; the H1-change session took 1m49s with multiple `/posts/{id}/render` 404s before finding a working path. Class of bug: **AI nondeterminism on jobs that don't need judgment**.

3. **WordPress "Suggested text:" leaking onto live legal pages** — `/pages/ensure` is idempotent, returns existing draft IDs, does NOT replace content. The recipe had a "if it pre-existed, also add content" conditional the AI agent missed. Patched `44ea759`. Class of bug: **conditional behavior that depends on AI memory**.

4. **CSS overwritten by /css POST** — The endpoint REPLACES customizer Additional CSS, doesn't append. Hit it twice this session. Class of bug: **destructive endpoint without read-modify-write**.

5. **Footer CSS not mode-aware** — apply-theme generates dark-mode-styled footer CSS (white text on white default bg) for light-mode sites. Class of bug: **mode-blind CSS generation**.

6. **Bridge password rotates on every "Copy Environment Variables" click** — Causes stale `.env` files across machines. Confusing UX. Class of bug: **side effect not surfaced**.

---

## Hardening levers, ordered by impact

### Tier 1 — eliminate AI nondeterminism on deterministic work

**The single highest-impact lever.** Most AI nodes do mechanical work (palette lookup → POST, font lookup → POST, page-content templating → POST). They don't need judgment. They need correctness.

**Action:** Convert these nodes to bash:
- `apply-theme-config` — palette + fonts + dark CSS injection are all table-driven. Tagline generation is the ONLY judgment step; split that into its own AI node, leave the rest as bash.
- `create-products-and-categories` — already deterministic structurally. Audit for AI-written variability.
- `create-legal-pages` — boilerplate substitution + WP block wrapping. Pure transformation, no judgment.
- `set-front-page-and-report` — set option + emit summary. Deterministic.

**Keep AI for:** tagline generation, homepage hero copy, about-page narrative, contact-page invitation. These are creative writes.

**Effect:** Failure rate per deploy drops from "a few percent of nodes flake" to "only the 4 creative-write nodes can flake." Validators already gate the creative writes. Net deploy reliability rises sharply.

### Tier 2 — make every write idempotent AND non-destructive

**The CSS overwrite was a 30-second mistake that broke production styling.** No write endpoint should be destructive without explicit user opt-in.

**Action:**
- **Bridge `/css` endpoint** — change to APPEND-with-marker semantics. The skill writes between `/* MEGA-KADENCE-SKILL:start */` and `/* MEGA-KADENCE-SKILL:end */` markers; existing CSS outside the markers is preserved. (Bridge plugin change.)
- **Bridge `/posts/{id}` content updates** — already overwrite, but should auto-snapshot (already does via `mkb_*` snapshots). Surface the snapshot ID in every response and document `POST /snapshot/{id}/restore` for rollback. (Already exists in MKB; document + expose.)
- **Per-page meta updates** — should MERGE existing meta with new values, not replace. (Already does via WP API semantics, but verify and document.)

### Tier 3 — mode-aware codegen, not mode-blind

**The footer CSS broke because it was written for dark mode and shipped for light mode.**

**Action:**
- Split CSS generators into `light_footer_css()`, `dark_footer_css()`, `light_drawer_css()`, `dark_drawer_css()`. Pick by `mode` from intake. No more universal dark CSS.
- Same for theme_mods that vary by mode (header bg, footer bg, mobile nav colors).
- Add a validator: render `/`, `/contact/`, `/privacy-policy/` in headless Chrome, screenshot, OCR-check legibility (no white-on-white, no dark-on-dark). (Hard but high-value; could be a Chromium + Tesseract step.)

### Tier 4 — atomic operations exposed as flags

**Redeploying for one fix is wasteful.** Right now if a user wants to refresh legal pages after editing boilerplate, the only path is full `./deploy.sh`.

**Action:** Add subcommands or flags to `deploy.sh`:
- `./deploy.sh --refresh-legal` — re-runs only the legal pages flow.
- `./deploy.sh --refresh-css` — re-runs only CSS injection (light/dark + FF).
- `./deploy.sh --change-palette --color #FF1493` — re-runs only the palette node.
- `./deploy.sh --change-mode dark` — re-runs theme + CSS for the new mode.

Each is a slice of the existing DAG, gated to the relevant nodes.

### Tier 5 — automated compatibility matrix

**Today's "validated on Jon's laptop" is single-environment.** Mak runs Mac, students may run Linux desktop, future Claude Code versions will land.

**Action:** GitHub Actions workflow that runs `./deploy.sh` end-to-end on:
- ubuntu-latest (Linux desktop / WSL surrogate)
- macos-latest (Mac)
- windows-latest with WSL2 (closest to a Windows user)

…against an ephemeral test WP install (Hostinger or LocalWP container) on every PR + nightly cron.

Status badge in README. Failed runs block the merge. New users can READ the matrix and know their setup is supported before they buy in.

### Tier 6 — collapse the WP plugin foothold

**7 plugins is a lot of "go install these manually" friction**, and Kadence Pro / Kadence Blocks Pro are paid + license-gated.

**Action:** Two paths, both viable:
- **Hostinger snapshot template** — one-click "Restore Mega Kadence template" that has all 7 plugins pre-installed, license-keyed. This is what the Store Drop VSL actually demos.
- **Bridge auto-install for free plugins** — already in workflow for Fluent Forms (`ensure-fluent-forms` node). Extend to WC, Rank Math, LiteSpeed if not pre-installed.

Kadence Pro license gate is unavoidable without buying an OEM license — flag it as a one-time setup cost in the docs.

### Tier 7 — bridge UX hardening

**The "rotates password every time you click Copy Environment Variables" is a footgun.**

**Action (MKB plugin change):**
- "Copy Environment Variables" should ROTATE only on first call OR on explicit "Regenerate" click.
- Add a "Last rotated: {date}" line under the button so users see they're invalidating an old credential.
- Add a `GET /info` field `bridge_credentials_age_seconds` so the skill can warn when creds are old.

### Tier 8 — observability and recovery

**When something fails today, the user sees a JSON traceback.** They don't know what to do next.

**Action:**
- Add a deploy-end summary banner: total time, nodes passed/failed, snapshot IDs for each phase, link to the live site.
- Add a `deploy.sh --doctor` flag that runs read-only checks (bridge auth, plugin versions, theme version, free disk, bridge endpoint coverage) and prints a green/red checklist.
- Auto-retry transient bridge failures (HTTP 000 / 5xx) once with a 3-minute pause (per `feedback_wp_rest_retry` standing rule).
- On any AI-node failure, capture the agent's full transcript to `$ARTIFACTS_DIR/{node}-transcript.log` so post-mortems aren't blocked by lost context.

### Tier 9 — documentation that matches reality

**The README undersells the pre-flight setup and oversells "10 minutes."**

**Action:**
- Distinguish "first-ever setup" (~5-10 min: install Claude Code, Archon, clone, auth) from "per-deploy" (~15 min: bridge creds, 6 questions, DAG).
- Document EVERY one-time-setup gotcha: WSL on Windows, Hostinger snapshot template, Kadence Pro license source.
- Add a TROUBLESHOOTING section for every Tier 1-8 failure mode with the actual fix command.

---

## Sequencing recommendation

**Before any creator-pitch goes out** (Mak / Heckmans / Heather):

1. Tier 1 (deterministic bash where possible) — biggest reliability lever.
2. Tier 2 (non-destructive writes) — kills the CSS-overwrite class of bug.
3. Tier 3 (mode-aware codegen) — kills the footer-invisible class.
4. Tier 5 (CI matrix on Mac at minimum) — validates the public claim.
5. Tier 9 (honest README) — sets correct expectations.

**Post-pitch, ongoing:**
6. Tier 4 (atomic ops).
7. Tier 6 (snapshot template + auto-install).
8. Tier 7 (MKB UX).
9. Tier 8 (observability).

---

## Acceptance gate before a public pitch

The skill ships only when:

- [ ] CI matrix green on macos-latest, ubuntu-latest, and Windows+WSL.
- [ ] All AI nodes either have validators that catch their failure modes, OR have been converted to deterministic bash.
- [ ] `./deploy.sh` runs end-to-end on a freshly-cloned skill + freshly-installed WP + bare Hostinger snapshot in under 20 minutes, with zero "Suggested text:" leaks, visible footer text in both modes, and brand-colored Fluent Forms buttons.
- [ ] README's "first-ever setup" + "per-deploy" sections accurately match the test runs.
- [ ] At least one beta tester not named Jon has run `./deploy.sh` end-to-end on their own machine without intervention.

If all 5 are checked, the pitch can land honestly. If not, hold the pitch.
