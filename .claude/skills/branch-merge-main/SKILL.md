---
name: branch-merge-main
description: Use when the user asks to merge main into the current branch, sync with main, rebase on main, update from main, or says "merge main", "pull main", "sync with main".
---

# Merge Main into Feature Branch

Pull the latest `main`, merge it into a feature branch (in its worktree), resolve any conflicts, push, and verify CI passes.

## Instructions

### 1. Determine target feature branch

The user may pass a branch name (e.g. `mai-74`). Otherwise, use the current branch if it's not `main`. If the current branch is `main` and no branch was passed, stop and ask which branch to target.

### 2. Locate worktrees

```bash
git worktree list
```

From the output, note two paths:
- `MAIN_WORKTREE` — path on the line ending in `[main]`
- `TARGET_WORKTREE` — path on the line ending in `[<target-branch>]`

If no worktree exists for the target branch, stop and tell the user.

### 3. Pull the latest main

Fast-forward `main` in its own worktree (substituting the actual path):

```bash
git -C <MAIN_WORKTREE> pull --ff-only origin main
```

### 4. Switch to the target worktree

```bash
cd <TARGET_WORKTREE>
```

All subsequent git commands run inside the target worktree.

### 5. Merge main into the feature branch

```bash
git merge main
```

### 6. Handle merge conflicts

If the merge produces conflicts:

1. List all conflicted files:
   ```bash
   git diff --name-only --diff-filter=U
   ```
2. For each conflicted file, read it, understand both sides, and resolve the conflict by editing the file to keep the correct combination of changes.
3. Stage each resolved file:
   ```bash
   git add <file>
   ```
4. Complete the merge:
   ```bash
   git commit --no-edit
   ```

If the merge is clean, the merge commit is created automatically — skip to step 7.

### 7. Push

```bash
git push origin $(git branch --show-current)
```

### 8. Watch CI

Find the open PR and watch its checks:

```bash
PR=$(gh pr list --head "$(git branch --show-current)" --state open --json number -q '.[0].number')
[ -n "$PR" ] && gh pr checks "$PR" --watch
```

Report each job's result. If all jobs pass, confirm to the user. If any job fails:

1. Check the failure logs:
   ```bash
   gh run view <run-id> --log-failed | tail -50
   ```
2. Determine if the failure is related to the merge or pre-existing.
3. If merge-related, fix the issue, commit, push, and re-watch CI.
4. If pre-existing, report it to the user and note it is not caused by the merge.
