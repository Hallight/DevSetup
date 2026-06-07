---
name: branch-checkout
description: Use when checking out a branch into a worktree — creating a new feature branch off origin/main for implementation work, or checking out an existing local/remote branch to inspect or build on. Says "check out <branch> in a worktree", "make a worktree for <branch>", "worktree off main". Other skills (issue-implement, trello-implement, pr-merge) delegate their worktree creation here.
---

# Worktree Checkout

Create a git worktree at the project's **standard location** and switch into it. This is the single source of truth for *where* worktrees live and *how* they're set up; other skills delegate here instead of restating the commands.

## The standard

- **Location**: always `$REPO_ROOT/.claude/worktrees/<branch>`. Never a sibling of the repo, never anywhere else — tooling (preview-stack naming, cleanup skills) assumes this path.
- **Branch name**: no slashes. Some CIs derive preview-stack names from the branch (e.g. `{branch}.api.meeplemates.com`), and slashes break stack init. For tracker-driven work follow the project's branch convention (see CLAUDE.md — e.g. `mm-{idShort}` lowercase). For an existing branch, take its name as-is.

## Two modes

### Mode A — new branch off `origin/main`

For starting fresh implementation work (issue-implement, trello-implement) or a hotfix (pr-merge step 5).

```bash
REPO_ROOT=$(git rev-parse --show-toplevel)
git -C "$REPO_ROOT" fetch origin main

BRANCH="<branch>"   # e.g. mm-89 — lowercase, no slashes
git -C "$REPO_ROOT" worktree add "$REPO_ROOT/.claude/worktrees/$BRANCH" -b "$BRANCH" origin/main
```

### Mode B — check out an existing branch

For inspecting or building on a branch that already exists locally or on the remote (e.g. `ue_v5-5_upgrade`). Omit `-b`; git creates a local branch tracking `origin/<branch>` automatically when the remote branch exists.

```bash
REPO_ROOT=$(git rev-parse --show-toplevel)
git -C "$REPO_ROOT" fetch origin --prune   # make sure the remote ref is current

BRANCH="<branch>"
git -C "$REPO_ROOT" worktree add "$REPO_ROOT/.claude/worktrees/$BRANCH" "$BRANCH"
```

If a local branch of that name already exists, `worktree add "$path" "$BRANCH"` checks it out. If only the remote ref exists, git creates the tracking branch. If neither exists, this errors — confirm the branch name and that you've fetched.

## After the worktree exists

Copy any untracked config files the project's CLAUDE.md lists as worktree-includes (e.g. `.env`, local credential files). These are gitignored, so a fresh worktree won't have them.

```bash
WORKTREE="$REPO_ROOT/.claude/worktrees/$BRANCH"
# Copy only what the project CLAUDE.md enumerates, e.g.:
# cp "$REPO_ROOT/.env" "$WORKTREE/.env" 2>/dev/null
```

Then switch in — **all subsequent work runs from the worktree**:

```bash
cd "$WORKTREE"
```

> The worktree is a full checkout of the repo. File paths in any downstream steps are relative to the worktree root, not the primary checkout.

## Report

State the worktree path, the branch, and the HEAD commit it landed on so the caller (or user) can confirm. The primary checkout and its dirty files are untouched by a worktree add.

## Pairs with

- **`/branch-cleanup`** — removes a worktree + its local branch when the work is done or the PR has merged.
