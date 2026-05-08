---
description: Symlink the repo's .claude/skills/* into ~/.claude/skills/ (skips entries that already exist).
---

Run the sync script that matches the user's OS to create directory junctions / symlinks from `~/.claude/skills/<name>` into this repo's `.claude/skills/<name>`. The script never overwrites or deletes anything at the target — it skips any entry that already exists.

1. Detect the OS:
   - Windows → run `pwsh -File scripts/personal-skills-sync.ps1` from the repo root (fall back to `powershell -File` if `pwsh` is not on PATH).
   - macOS / Linux → run `bash scripts/personal-skills-sync.sh` from the repo root.

2. Show the script output verbatim and summarize the final `<n> linked, <n> skipped` line.

3. If anything was skipped, list the skipped names and remind the user that to link them they must first remove (or move aside) the existing entry at `~/.claude/skills/<name>`, then re-run `/personal-skills-sync`.

Do not modify the scripts themselves. Do not delete anything in the user's home directory.
