# Rename Plan — `mega-kadence-skill` → `store-drop-skill`

> Executed: NOT YET. Drafted 2026-05-09. Run when you're ready.

## Why rename

`mega-kadence-skill` reads like "the skill for Kadence" — but it isn't. The bridge (MKB) is what makes Claude fluent in Kadence; this directory is one *outcome* (a 7-page POD store, branded "Store Drop"). Future outcomes (Editorial Drop, Portfolio Drop, Course Drop, Local-Service Drop) will be siblings of this one, all consuming the same MKB substrate.

The current name conflates the two layers and pre-emptively claims the namespace future skills should occupy.

Locked decisions:
- **MKB keeps its name** (`mega-kadence-bridge`). It is the Kadence vocabulary.
- **This skill becomes `store-drop-skill`.** It is one outcome built on MKB.
- **Brand surface** says "Store Drop" (already locked in memory `project_store_drop_naming` 2026-05-09).

## Scope of the rename

| Layer | Action | Risk | Reversible? |
|---|---|---|---|
| Local directory `~/kadence-skill/mega-kadence-skill/` → `~/kadence-skill/store-drop-skill/` | `mv` | Low | Trivial |
| GitHub repo `jonjonesai/mega-kadence-skill` → `jonjonesai/store-drop-skill` | GH rename in settings | Low — GitHub redirects old URL forever | Yes (rename back) |
| Internal doc references (14 files) | Find/replace `mega-kadence-skill` → `store-drop-skill` | Trivial | Trivial |
| SKILL.md identity (H1 + intro) | Edit | Trivial | Trivial |
| Claude Code project state at `~/.claude/projects/-home-jon-kadence-skill-mega-kadence-skill` | Becomes orphaned; new path gets fresh state | Low | Project dir will appear under new path on next CC session |
| Archon worktrees at `~/.archon/workspaces/.../mega-kadence-skill/` | Stale references — clean separately or let them age out | Low | New worktrees generated against renamed path |

## Pre-flight

```bash
cd ~/kadence-skill/mega-kadence-skill
git status                    # working tree must be clean
git pull origin main           # sync first
```

## Execution

Run as a single block (paste into a shell). Each command is idempotent enough to re-run after a partial failure.

```bash
set -euo pipefail

OLD=mega-kadence-skill
NEW=store-drop-skill
PARENT=~/kadence-skill

# 1. Rename local directory.
cd "$PARENT"
mv "$OLD" "$NEW"
cd "$NEW"

# 2. Rewrite internal references in tracked files.
git ls-files -z | xargs -0 sed -i "s|$OLD|$NEW|g"

# 3. Commit the doc rename.
git add -A
git commit -m "chore: rename skill from $OLD to $NEW (Store Drop is one outcome built on MKB)"

# 4. Update SKILL.md identity (manual review recommended; the sed pass above
#    handles the literal slug, but the H1 'Mega Kadence Skill' is a different
#    string and should be edited deliberately).
#
#    Edit SKILL.md:
#      "# Mega Kadence Skill" → "# Store Drop Skill"
#      Intro paragraph: rephrase to make Store Drop the named output.
#
#    Then:
git add SKILL.md
git commit -m "rename: SKILL.md identity → Store Drop Skill"

# 5. Update remote URL after GitHub repo rename (do step 6 first if not done).
git remote set-url origin "https://github.com/jonjonesai/$NEW.git"
git push origin main
```

## GitHub repo rename (step 6)

In the browser: github.com/jonjonesai/mega-kadence-skill → Settings → scroll to bottom of the General tab → Rename → enter `store-drop-skill` → confirm.

GitHub keeps a redirect from the old name forever, so any historical URLs (Archon docs, prior Claude conversations, etc.) will still resolve. Update local remote URL via step 5 above.

## Post-flight verification

```bash
cd ~/kadence-skill/$NEW
grep -rn "mega-kadence-skill" --include="*.md" --include="*.json" --include="*.sh" .
# Should return zero results, OR only references in CHANGELOG / DEVLOG / RENAME-PLAN
# explicitly preserving the historical name.

git remote -v
# Should show: origin  https://github.com/jonjonesai/store-drop-skill (fetch/push)

git push origin main
# Should succeed.
```

Then in Claude Code:
- Open the new directory in a fresh CC session.
- Confirm the skill loads via SKILL.md normally.
- Old `~/.claude/projects/-home-jon-kadence-skill-mega-kadence-skill/` can be deleted manually after confirming nothing's needed from prior conversation history.

## What does NOT get renamed

- **MKB** (`mega-kadence-bridge`). Stays exactly as is.
- **Mega platform** branding. "Mega" is the parent; Store Drop is one product.
- **Future Drop skills** (`editorial-drop-skill`, `portfolio-drop-skill`, etc.) — those don't exist yet. No premature directory creation.
- **`recipes/deploy-pod-store.md` filename**. The keystone recipe stays as-is — it's the literal POD-store deployment recipe. Future Drops have their own keystone recipes.

## Decision log

| When | What | Authorized by |
|---|---|---|
| 2026-05-09 | Bright line locked: MKB = vocabulary, Store Drop = one outcome | Jon |
| 2026-05-09 | Rename authorized in principle | Jon |
| TBD       | Execution | Pending Jon's "go" |
