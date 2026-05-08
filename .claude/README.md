# `.claude/` — version-controlled Claude Code config

This folder holds the personal Claude Code customizations that are tracked in this repo so they can be cloned onto any machine and synced into `~/.claude/`.

## Layout

- **`skills/`** — canonical source for personal Claude skills (commit-push, issue-create, issue-implement, pr-create, pr-merge, pr-merge-main, pr-respond, trello-create, trello-implement). Each subdirectory is one skill, containing a `SKILL.md`. On a configured machine, `~/.claude/skills/<name>` is a junction (Windows) or symlink (macOS/Linux) into this folder, so editing a `SKILL.md` here or there is the same edit.
- **`commands/`** — repo-scoped slash commands. Currently:
  - `/personal-skills-sync` — runs the OS-appropriate script under `../scripts/` to set up the skill links described above.

## Bootstrap on a new machine

```
git clone <this repo>
cd DevSetup
```

Then either:

- From inside Claude Code with this repo open: run `/personal-skills-sync`.
- Or run the script directly:
  - Windows: `pwsh -File scripts/personal-skills-sync.ps1`
  - macOS / Linux: `bash scripts/personal-skills-sync.sh`

## "Skip if exists" semantics

The sync script never deletes or overwrites anything under `~/.claude/skills/`. If a skill already exists at the target path — as a real directory, a junction, or a symlink — the script skips it and tells you which ones were skipped.

That means on a machine that already has personal skills installed under `~/.claude/skills/`, the first run will skip everything. To switch a machine over to the repo-managed copies, remove (or move aside) the existing directory at `~/.claude/skills/<name>` first, then re-run the script. Re-runs after the link is in place are no-ops.

## Editing flow

- Edit a `SKILL.md` either through the symlinked path under `~/.claude/skills/<name>/SKILL.md` or directly in this repo at `.claude/skills/<name>/SKILL.md` — they're the same file once linked.
- `git status` from the repo root will show the change.
- Commit and push from the repo as normal.
