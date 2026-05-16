# Rename Log — `mega-kadence-skill` → `store-drop-skill`

> Executed (local): 2026-05-09. GitHub repo rename: pending (Jon, browser).

## Why this happened

`mega-kadence-skill` read like "the skill for Kadence." It isn't. MKB (Mega Kadence Bridge) is what makes any AI fluent in Kadence; this directory is one *outcome* — the 7-page POD store, branded "Store Drop." Future outcomes (Editorial Drop, Portfolio Drop, Course Drop, Local-Service Drop, Charity Drop) will be siblings, all consuming the same MKB substrate.

Locked architectural decisions (2026-05-09):
- **MKB keeps its name** (`mega-kadence-bridge`). It is the Kadence vocabulary.
- **This skill is `store-drop-skill`.** It is one outcome built on MKB.
- **Brand surface** says "Store Drop" (locked in memory `project_store_drop_naming`).

See memory `feedback_mkb_vs_skill_bright_line` for the layering doctrine that future sessions should enforce.

## What was done in this session

1. ✅ Local directory: `mv ~/kadence-skill/mega-kadence-skill ~/kadence-skill/store-drop-skill`
2. ✅ Internal slug references: 16 tracked files had `mega-kadence-skill` → `store-drop-skill`
3. ✅ Internal title references: 8 tracked files had `Mega Kadence Skill` → `Store Drop Skill`
4. ✅ SKILL.md H1 updated via the title pass.
5. ✅ Pre-rename checkpoint commit (`fc7c544`): the two new docs (RENAME-PLAN.md, PROMOTION-AUDIT.md) committed before the rename.
6. ✅ Rename commit: documented in this same session.
7. ✅ Stale git worktree registrations pruned with `git worktree prune`.

## What is still pending (Jon's hand)

8. ⏳ **GitHub repo rename.** Browser action only — GitHub Settings page for `jonjonesai/mega-kadence-skill` → bottom of the General tab → "Rename" → enter `store-drop-skill` → confirm. GitHub keeps a redirect from the old name forever, so historical URLs (Archon docs, prior Claude conversations) still resolve.

9. ⏳ **Local remote URL update.** After step 8:
   ```bash
   cd ~/kadence-skill/store-drop-skill
   git remote set-url origin https://github.com/jonjonesai/store-drop-skill.git
   ```

10. ⏳ **Push** (Jon's call):
    ```bash
    git push origin main
    ```
    Branch is currently 6 commits ahead of origin (4 pre-existing + this session's checkpoint + this session's rename commit).

11. ⏳ **Cleanup, optional.** Old Claude Code project state at `~/.claude/projects/-home-jon-kadence-skill-mega-kadence-skill/` is now orphaned. Safe to delete after confirming nothing's needed from prior conversation history. New CC sessions in the renamed dir create fresh state at `~/.claude/projects/-home-jon-kadence-skill-store-drop-skill/`.

12. ⏳ **Archon workspace cleanup, optional.** `~/.archon/workspaces/kadence-skill/mega-kadence-skill/` contains 9 stale Archon worktrees. They were pruned from the git worktree registry but the disk files remain. New Archon DAG runs will generate fresh worktrees at the new path. Safe to `rm -rf` the old workspaces dir at your convenience.

## What did NOT get renamed (intentional)

- **MKB** (`mega-kadence-bridge`). Stays exactly as is.
- **Mega platform** branding. "Mega" is the parent; Store Drop is one product on it.
- **`recipes/deploy-pod-store.md` filename.** Still the keystone recipe — it's the literal POD-store deployment recipe. Future Drop skills will have their own keystone recipes (e.g. `deploy-editorial-site.md`, `deploy-portfolio-site.md`).
- **Future Drop skills.** No premature directory creation — they don't exist yet.

## Decision log

| When | What | Authorized by |
|---|---|---|
| 2026-05-09 | Bright line locked: MKB = vocabulary, Store Drop = one outcome | Jon |
| 2026-05-09 | Rename approved in principle | Jon |
| 2026-05-09 | Local rename + sed pass executed | Jon ("I agreed to all the skill stuff") |
| TBD       | GitHub repo rename + push | Pending Jon |
