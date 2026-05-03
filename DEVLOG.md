# DEVLOG

Chronological history of significant changes to the Mega Kadence Skill.

---

## Session 5 — 2026-05-03 (evening)

**Mission:** dry-run the shipped harness on cutemerch.love from the second-brain VPS, polish anything Jon's eye catches, lock the skill before the Tier 1 demo video shoot.

**Outcome:** dry-run passed clean (43/43 nodes, 12.3 min wall time, 7/7 pages live). One visual gap caught by user-eye after the workflow declared SUCCESSFUL. Fix codified as a 7th permanent bug fix. Workflow node count 43 → 45.

### What happened on the dry-run

- Cloned skill repo to `~/kadence-skill/mega-kadence-skill/` on the second-brain VPS (Hetzner, user `jon`). Hardcoded path matched, lib sourcing worked.
- Installed Archon CLI v0.3.10 user-local at `~/.local/bin/archon` (`INSTALL_DIR=~/.local/bin curl -fsSL https://archon.diy/install | bash`). No sudo needed.
- First `./deploy.sh` failed at `apply-theme` node with: *"Claude Code not found. Archon requires the Claude Code executable to be reachable at a configured path."*
- Root cause: this VPS has `claude` at `/usr/bin/claude` (system install), not the install.sh-default `~/.local/bin/claude`. The OAuth wrapper unsets `CLAUDE_CODE_EXECPATH`, which Archon falls back from. **Not a skill bug — environmental.** A fresh-WSL student following the README's `curl claude.ai/install.sh` puts `claude` at `~/.local/bin/claude`, where Archon finds it natively.
- Fix: wrote `~/.archon/config.yaml` with `assistants: claude: claudeBinaryPath: /usr/bin/claude`. Re-ran. **Worth adding a README troubleshooting line** for any future user installing claude from apt/npm/system path.
- Second run: clean. All 7 pages live. cutemerch.love deployed end-to-end.

### Bug #7 — content-style-boxed white band before footer

**Symptom (caught by Jon's eye, not by any validator):** every page rendered a thin white band between the last alignfull section and the dark footer. Not a CSS or palette issue — a Kadence layout default.

**Root cause:** Kadence defaults pages to `content-style-boxed` + `content-vertical-padding-show`, which wrap each page in a card with vertical padding. Brand landing pages built from `alignfull` blocks need `unboxed` + `padding-hide`; otherwise the parent card's bottom padding shows through as the body color (white in light mode, dark in dark — but visible on the dark footer in light).

**Diagnosis path:** read body class on rendered homepage. Found `content-width-fullwidth content-style-boxed content-vertical-padding-show`. Probed theme_mods via `/theme-mod/{key}` — `page_content_style`, `page_vertical_padding`, `post_content_style`, `post_vertical_padding` all returned `false` (unset). Kadence was using its theme defaults.

**Live fix on cutemerch.love (validated):** four `POST /theme-mod/{key}` calls + `/cache/flush`. Body class flipped to `content-style-unboxed content-vertical-padding-hide`. Band gone.

**Fix codified into the workflow** as Phase 2b (after `check-palette`, before `create-products`):
- New node `enforce-content-style` (bash) — sets all four theme_mods then flushes cache.
- New node `check-content-style` (bash validator) — `bridge_render("/")`, asserts `content-style-unboxed` AND `content-vertical-padding-hide` are present in the body class.
- `create-products` `depends_on` updated from `[check-palette]` to `[check-content-style]`.

### Lib addition

`lib/bridge.sh` gained `bridge_post_theme_mod <key> <value>` — symmetric with the existing `bridge_get_theme_mod`. Single-line wrapper around `bridge_post`. Useful for any future bash node that needs to set theme_mods deterministically.

### Files changed

```
.archon/lib/bridge.sh                              # +bridge_post_theme_mod helper
.archon/workflows/deploy-pod-store.yaml            # +enforce-content-style, +check-content-style; create-products depends_on
DEVLOG.md                                          # +Session 5
HANDOFF.md                                         # bugs 6 → 7
```

### Files unchanged but worth noting

- `apply-theme-config.md` — NOT modified. The fix is intentionally outside the AI command. Bash + validator is enforcement; AI command should stay narrow on palette/fonts/title.
- `recipes/` and `templates/` — untouched. The fix is theme-mod-level, not page-content-level.

### Validation

- YAML parse: 45 nodes, well-formed.
- `bash -n` syntax check on new nodes: both pass.
- Lib helper smoke test: `bridge_post_theme_mod page_content_style "unboxed"` returned `success: true` against the live cutemerch.love bridge.
- End-to-end re-run on cutemerch.love NOT performed (would take another 12 min). Trade-off accepted: harness halt-loud-on-failure means a node-level bug surfaces with a clear error message, not silent failure.

### Open items / future work

- Re-run a full clean deploy from a fresh wipe to confirm bug #7 fix integrates cleanly with Phase 5b. Low risk (Phase 5b mode-CSS rules are CSS injection, orthogonal to layout theme_mods) but worth doing once before next student deploy.
- Consider adding `INSTALL_DIR=~/.local/bin` as the README's recommended Archon install (matches Claude Code's default install dir, sidesteps any `/usr/local/bin` permission issues).
- README troubleshooting section should mention: *"If Archon errors with 'Claude Code not found' on workflow run, your `claude` binary is at a non-default path. Set it in `~/.archon/config.yaml`: `assistants: { claude: { claudeBinaryPath: /path/to/claude } }`."*

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
