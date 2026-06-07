---
name: branch-cleanup
description: Use when removing a worktree and its local branch — after a PR merges, when abandoning a branch, or cleaning up stale worktrees. Says "remove the worktree", "delete the branch and worktree", "clean up <branch>". Other skills (pr-merge, branch-update-all) delegate their worktree removal here. Windows-safe (handles file-lock races on git worktree remove).
---

# Worktree Cleanup

Remove a worktree at the project's standard location and its local branch. This is the single source of truth for the removal sequence; other skills delegate here.

## Precondition — the caller decides *whether* to delete

This skill does the mechanical removal. It does **not** decide if deletion is safe — the caller must have already established that:

- **pr-merge** calls this right after a confirmed `--squash --delete-branch` merge.
- **branch-update-all** calls this only when the remote branch was pruned **and** `gh pr list --head "$BRANCH" --state all` reports the PR state as `MERGED`. A missing upstream alone is not enough (could be a never-pushed local branch or a PR closed without merging).

Never delete the `main` branch or the primary worktree.

## The removal sequence (Windows-safe)

On Windows, any prior `cd` into the worktree keeps file handles open for a while after the shell command returns, so `git worktree remove` can fail with `Permission denied` and orphan the directory on disk. The sequence below defends against that: `cd` out first, try the clean removal, then `rm -rf` as a backstop in case removal got partway (metadata gone, directory still present).

```bash
REPO_ROOT=$(git rev-parse --show-toplevel)
BRANCH="<branch>"   # or: BRANCH=$(gh pr view <number> --json headRefName -q '.headRefName')
WORKTREE="$REPO_ROOT/.claude/worktrees/$BRANCH"

# 1. Move cwd out of any worktree first — the root drive is always safe.
cd "$REPO_ROOT/.."

# 2. Clean removal if git still tracks it.
if git worktree list --porcelain | grep -q "^worktree $WORKTREE$"; then
  git -C "$REPO_ROOT" worktree remove --force "$WORKTREE" 2>/dev/null \
    || echo "git worktree remove failed; will rm -rf instead"
fi

# 3. Backstop: force-delete the directory if it survived, then prune metadata.
[ -d "$WORKTREE" ] && rm -rf "$WORKTREE"
git -C "$REPO_ROOT" worktree prune

# 4. Delete the local branch.
git -C "$REPO_ROOT" branch -D "$BRANCH" 2>/dev/null && echo "Deleted local branch: $BRANCH"
```

### Why `branch -D`, not `-d`

These projects **squash-merge**. A squash merge replays the branch's work as a single new commit on main, so git still sees the branch's original commits as "unmerged" — `branch -d` would refuse with "not fully merged". `-D` forces it, which is correct once the PR is confirmed merged. (The MERGED-state / post-merge precondition above is what makes the force safe.)

## Report

State which worktree directory and local branch were removed. If `git worktree remove` failed and the `rm -rf` backstop fired, say so. If a branch couldn't be deleted, surface it rather than swallowing the error.

## Pairs with

- **`/branch-checkout`** — creates a worktree at the standard location.
