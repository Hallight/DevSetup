# `.claude/` — version-controlled Claude Code config

This folder holds the personal Claude Code customizations that are tracked in this repo so they can be cloned onto any machine and synced into `~/.claude/`.

## Layout

- **`skills/`** — canonical source for personal Claude skills (branch-checkout, branch-cleanup, branch-merge-main, branch-update-all, commit-push, issue-create, issue-implement, personal-skills-sync, pr-create, pr-merge, pr-respond, trello-create, trello-implement). Each subdirectory is one skill, containing a `SKILL.md`. On a configured machine, `~/.claude/skills/<name>` is a junction (Windows) or symlink (macOS/Linux) into this folder, so editing a `SKILL.md` here or there is the same edit.
  - `/personal-skills-sync` — runs the OS-appropriate script under `../scripts/` to set up the skill links described above. Once linked it's available from any project; on first bootstrap run the script directly (below).
- **`commands/`** — repo-scoped slash commands. Currently:
  - `/personal-secrets-pull` — fetches personal secrets (AWS creds, Claude MCP servers) from AWS Secrets Manager into local files. See `../personal-secrets/README.md`.
  - `/personal-secrets-push` — uploads the local files back to AWS Secrets Manager (also handles the initial seeding by creating the secrets the first time).

## Bootstrap on a new machine

```
git clone <this repo>
cd DevSetup
```

On first bootstrap the `personal-skills-sync` skill isn't linked yet, so run the script directly from the repo root:

- Windows: `pwsh -File scripts/personal-skills-sync.ps1`
- macOS / Linux: `bash scripts/personal-skills-sync.sh`

Once that first run links the skills, you can re-sync from any project later by running `/personal-skills-sync`.

## "Skip if exists" semantics

The sync script never deletes or overwrites anything under `~/.claude/skills/`. If a skill already exists at the target path — as a real directory, a junction, or a symlink — the script skips it and tells you which ones were skipped.

That means on a machine that already has personal skills installed under `~/.claude/skills/`, the first run will skip everything. To switch a machine over to the repo-managed copies, remove (or move aside) the existing directory at `~/.claude/skills/<name>` first, then re-run the script. Re-runs after the link is in place are no-ops.

## Editing flow

- Edit a `SKILL.md` either through the symlinked path under `~/.claude/skills/<name>/SKILL.md` or directly in this repo at `.claude/skills/<name>/SKILL.md` — they're the same file once linked.
- `git status` from the repo root will show the change.
- Commit and push from the repo as normal.
