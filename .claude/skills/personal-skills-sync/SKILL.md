---
name: personal-skills-sync
description: Use when linking this repo's personal Claude config into ~/.claude — installing/syncing personal skills onto a machine, setting up skill junctions/symlinks, or after adding a new skill to the DevSetup repo. Says "sync my skills", "link my skills", "install personal skills", "run personal-skills-sync".
---

# Personal Skills Sync

Run the OS-appropriate script that links each skill under the DevSetup repo's `.claude/skills/<name>` into `~/.claude/skills/<name>` (directory junction on Windows, symlink on macOS/Linux). The script **never overwrites or deletes** anything at the target — it skips any entry that already exists (real dir, junction, or symlink).

Run this after adding a new skill to the repo so the new skill becomes available in `~/.claude/skills`.

## 1. Locate the repo

This skill's real files live in the DevSetup repo at `<repo>/.claude/skills/personal-skills-sync/`, reached through the `~/.claude/skills/personal-skills-sync` junction/symlink. A skill runs from an arbitrary working directory, so resolve the repo root from this skill's own location rather than assuming the cwd is the repo. The repo root is three levels above the skill directory.

**Windows (PowerShell):**

```powershell
$link = Join-Path $env:USERPROFILE '.claude\skills\personal-skills-sync'
$real = (Get-Item -LiteralPath $link).Target   # junction target; $null if not linked
if (-not $real) { $real = $link }
$repo = (Get-Item -LiteralPath $real).Parent.Parent.Parent.FullName
```

**macOS / Linux (bash):**

```bash
link="$HOME/.claude/skills/personal-skills-sync"
real="$(readlink -f "$link" 2>/dev/null || echo "$link")"
repo="$(cd "$real/../../.." && pwd)"
```

If the skill isn't linked yet (first-time bootstrap), there's nothing to resolve — just `cd` into the cloned DevSetup repo and use it as `$repo`.

## 2. Run the matching script

The scripts self-locate via their own path, so invoking by absolute path works from any cwd.

- **Windows** → `& "$repo\scripts\personal-skills-sync.ps1"` (fall back to `powershell -File "$repo\scripts\personal-skills-sync.ps1"` if `pwsh` is unavailable).
- **macOS / Linux** → `bash "$repo/scripts/personal-skills-sync.sh"`.

Do **not** modify the scripts. Do **not** delete anything in the user's home directory.

## 3. Report

Show the script output verbatim and summarize the final `<n> linked, <n> skipped` line.

If anything was skipped, list the skipped names and remind the user: to link them, first remove (or move aside) the existing entry at `~/.claude/skills/<name>`, then re-run this skill. Re-runs after a link is in place are no-ops.
