# DEVLOG

Chronological history of significant changes to the Mega Kadence Skill.

---

## Session 4 — 2026-05-03

**Mission:** turn the harness from "internal-test-grade prototype" into a student-grade product. Fix the Archon session-hang. Validate dark mode end-to-end. Build a turnkey rookie experience.

**Outcome:** all goals hit. First fully-clean Archon run completed (run #5, dark mode, 0 failures across 43 nodes). Rookie student flow validated end-to-end from a fresh WSL terminal — `./deploy.sh` + 6 answers + 15 min wait + working site.

### Major changes

**Architecture — workflow decomposition (continued from Session 3b):**
- Workflow now has 43 nodes (was 14). 7 AI nodes (was 4 monoliths, now atomic), 36 bash nodes (was 26).
- Phase 5 chrome work fully decomposed from `configure-header-footer-nav.md` AI monolith into 17 deterministic bash nodes.
- Phase 4 page creation split into 4 atomic AI commands (`create-homepage`, `create-about`, `create-contact`, `create-legal-pages`) replacing the `create-all-pages` monolith.
- Phase 5b mode-CSS enforcement layer added: `apply-dark-bg-mods` + `inject-mode-css` + 4 granular validators (`check-body-text-color`, `check-logo-color`, `check-hero-padding`, `check-drawer-colors`).
- Removed redundant early `check-dark-css` validator — Phase 5b is authoritative.

**Lib system — single source of truth for shared bash:**
- `lib/bridge.sh` — `bridge_get/post/render`, multi-path .env loading, compact JSON output for theme_mods
- `lib/assert.sh` — PASS/FAIL helpers + `assert_grep`
- `lib/intake.sh` — read intake.json fields
- `lib/pages.sh` — per-page artifacts; reads + writes BOTH the workflow ARTIFACTS_DIR and the `/tmp/archon-artifacts` fallback
- `lib/chrome.sh` — deterministic chrome ops (10 functions, every payload smoke-tested)
- `lib/dark-mode-css.sh` — single source of truth for mode-specific CSS bundles

**Session-hang fix — `.archon/scripts/run-archon.sh`:**
- Root cause (issue #1067 in Archon): default global-auth path spawns nested `claude` subprocess that deadlocks on `CLAUDE_CODE_*` parent env vars.
- Wrapper reads OAuth token from `~/.claude/.credentials.json` at each invocation, exports `CLAUDE_CODE_OAUTH_TOKEN` + `CLAUDE_USE_GLOBAL_AUTH=false`, strips parent CLAUDE_CODE_* vars.
- Verified: every AI session this run logs `authMode: "explicit"` — never spawns the `claude` subprocess.

**Student onboarding — `deploy.sh` (NEW):**
- Single entry point for students. Replaces "edit YAML test values, run archon directly."
- If `.env` missing: prompts for paste-block (no editor required), validates, sanity-checks `/info` reaches the bridge.
- If `intake.json` missing: prompts the 6 questions one at a time with validation (mode must be light/dark, color must be 6-digit hex, required fields re-prompt if blank).
- Then exec's the wrapper to run the workflow.
- Flags: `--reset` (re-prompt everything), `--intake` (only refresh intake).
- Welcome banner explains what's about to happen.

**Workflow intake refactor:**
- Removed hardcoded test values from the `intake` node.
- Now reads `intake.json` from canonical repo path with placeholder validation (blocks runs with `"YourBrand"` or unedited example values).
- Copies to both ARTIFACTS_DIR and `/tmp/archon-artifacts` for AI/bash dir mismatch resilience.

**README.md — full student rewrite:**
- "One-time setup" section walks through WSL + Claude Code + Archon install + repo clone.
- "Per-deploy" section is just: install bridge plugin → click Copy Env Variables → run `./deploy.sh`.
- Added troubleshooting section + repository layout map.

### Six bugs caught by harness validation (each fixed permanently)

| # | Bug | Where the fix lives |
|---|---|---|
| 1 | `check-homepage` hit `/` (blog index) instead of `/home/` | YAML — validator URL |
| 2 | `pages.sh` PAGES_DIR resolved at source-time; AI/bash nodes used different ARTIFACTS_DIR | `lib/pages.sh` — dual-dir read+write |
| 3 | `chrome_ensure_menu` missing `type:"post_type"`; menus filled with broken custom-link items | `lib/chrome.sh` — pass type, also clear items on re-use |
| 4 | `bridge_get_theme_mod` emitted JSON with `: ` spaces; validator regex couldn't match | `lib/bridge.sh` — compact JSON separators |
| 5 | `check-per-page-transparent` hit non-existent endpoint, expected string but got array | YAML — full post + accept list-or-string |
| 6 | Footer text invisible (light mode) + legal page headings invisible (dark mode boxed-style card) | `lib/dark-mode-css.sh` — universal FOOTER_CSS + boxed-card transparency override |

### Validation runs

- **Run #1:** failed at `check-homepage` (URL bug #1)
- **Run #2:** failed at `check-homepage` again (turned out to be the URL bug, same as #1 — confirmed by manual diagnosis of rendered HTML)
- **Run #3:** failed at `normalize-blocks` (artifact dir mismatch bug #2)
- **Run #4:** failed at `check-per-page-transparent` (endpoint bug #5). Manual completion of remaining nodes verified the deploy works end-to-end. **Light mode validated.**
- **Run #5:** **first fully-clean Archon run.** All 43 nodes green, `anyFailed: false`. Dark mode validated end-to-end. The 4 dark-mode failure modes from prior cold-Claude testing are now caught (and passed) by deterministic validators.
- **Run #6:** rookie student simulation from a fresh WSL terminal. `./deploy.sh` + 6 answers + 15 min wait → DEPLOYMENT SUCCESSFUL. Light mode, peachy-pink (#E8697A) brand. **Student flow validated.**

### Files added

```
deploy.sh                                          # Student entry point
HANDOFF.md                                         # Doc for next Claude
DEVLOG.md                                          # This file
.env.example                                       # Bridge creds template
intake.json.example                                # Intake template
.archon/lib/bridge.sh
.archon/lib/assert.sh
.archon/lib/intake.sh
.archon/lib/pages.sh
.archon/lib/chrome.sh
.archon/lib/dark-mode-css.sh
.archon/scripts/run-archon.sh                      # OAuth wrapper
.archon/commands/create-homepage.md
.archon/commands/create-about.md
.archon/commands/create-contact.md
.archon/commands/create-legal-pages.md
```

### Files removed (orphans from decomposition)

```
.archon/commands/configure-header-footer-nav.md    # Replaced by 17 chrome bash nodes
.archon/commands/create-all-pages.md               # Replaced by 4 atomic page commands
```

### Files modified

```
.archon/workflows/deploy-pod-store.yaml            # 14 → 43 nodes
.gitignore                                         # Added intake.json + __pycache__
README.md                                          # Full student-grade rewrite
```

### Open items

- Repo path is hardcoded to `~/kadence-skill/mega-kadence-skill/` in bash node sources. Future cleanup: use `ARCHON_PROJECT_ROOT` or wrapper-set env.
- `apply-theme-config.md` could be further decomposed for symmetry.
- `set-front-page-and-report.md` could be replaced with bash (keeping AI for the summary printing is the only reason to keep it AI).

---

## Session 3b — 2026-05-02 (summarized from SESSION-4-MEMO.md)

Mega Kadence Skill v1.0 + Mega Kadence Bridge v1.0.3 shipped. Archon workflow installed and partially working — preflight, intake, apply-theme, check-palette, check-dark-css, create-products, check-products all passed in one run. Hung on `create-pages` node (Claude session spawning issue, not yet root-caused).

Cold Claude reproducibility tests:
- Light mode: 3 successful deployments
- Dark mode: failed every time with the same 4 issues (logo dark, body text dark, white space at hero, mobile drawer wrong colors)

Key discoveries codified into the workflow this session:
- Kadence has NO theme_mods for body text color, heading color, or site title color — must inject CSS via `POST /css`
- `_kad_post_vertical_padding` is `"disable"` not `"hide"`
- Header items use `main_left` not `left`. Footer items use `middle_1` not `1`. Mobile trigger is `popup-toggle` not `mobile-trigger`. Mobile logo is `mobile-logo` not `logo`. Mobile nav is `mobile-navigation` not `navigation`
- Logo layout is an OBJECT not an array
- Archon strips .env files — bash nodes source from absolute `$HOME` path
- All Kadence blocks are server-rendered — block recovery warnings come from mismatched inner HTML, fixed by `/normalize-blocks`

---

## Pre-Session-3b history

See git log for changes prior to Session 3b. Notable milestones:
- 9867354 — `feat: Archon workflow — enforced deploy sequence with bash validation` (Session 3b initial Archon work)
- 4ed3ebb — `fix: dark mode CSS injection — theme_mods don't exist for text colors`
- 88fe016 — `feat: golden templates + mobile trigger CSS fix`
- ef0be1d — `fix: normalize-blocks step, required plugins, forms integration`
