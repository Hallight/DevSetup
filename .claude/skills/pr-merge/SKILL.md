---
name: pr-merge
description: Use when the user asks to merge a PR, land a branch, or says "merge the PR", "merge this", "ship to main".
---

# Merge PR

Merge the PR, then watch any project-defined post-merge cleanup and deploy pipelines. Open a hotfix PR if anything fails.

## Pre-requisites

The project's required-approvers gate must be met before merging. Project CLAUDE.md specifies who must approve (e.g. an `## Approvers` section on a Linear/Jira/GitHub issue). Do not skip this check.

## Instructions

### 1. Confirm approvals

```bash
gh pr reviews <number> --json state,author \
  | jq '.[] | select(.state == "APPROVED") | .author.login'
```

Cross-reference against the project's required-approvers list. If any required approver has not approved, stop and report who is missing.

### 2. Merge

```bash
DEV_USER=$(gh auth status 2>&1 | grep 'Logged in to github.com account' | grep -v '\-claude' | awk '{print $7}')
BOT_USER=$(gh auth status 2>&1 | grep 'Logged in to github.com account' | grep -- '-claude' | awk '{print $7}')
gh auth switch --user "$BOT_USER"
gh pr merge <number> --squash --delete-branch
gh auth switch --user "$DEV_USER"
```

`gh auth switch --user` is case-sensitive, so don't assume the bot login is `${DEV_USER}-claude` — discover it from `gh auth status` (it may differ in case).

### 3. Watch pre-merge cleanup workflow (if any)

If the project runs a pre-merge cleanup workflow on PR close (e.g. tearing down a branch preview stack), watch it. The project CLAUDE.md should specify the workflow file name and which job to watch:

```bash
sleep 5
gh run list --branch <branch> --workflow <pre-merge-workflow.yml> --limit 1 --json databaseId \
  | jq -r '.[0].databaseId' \
  | xargs gh run watch
```

If the cleanup fails, the branch infra is still live and may leak resources. Open a hotfix PR (see step 5).

### 4. Watch the post-merge deploy pipeline (if any)

If the project deploys on merge to main, watch the run triggered by the push:

```bash
gh run list --branch main --workflow <post-merge-workflow.yml> --limit 1 --json databaseId \
  | jq -r '.[0].databaseId' \
  | xargs gh run watch
```

Report each job result as it completes. If all jobs pass, run any post-merge prod verification commands listed in the project CLAUDE.md (e.g. curling a prod health endpoint).

### 4b. Execute and check off post-merge test plan items

Read the PR description's `## Test plan` section. For every item that was left unchecked because it required a post-merge deploy (e.g. prod endpoint verification), execute the verification now and update the PR description to check the box (`- [x]`). Post a PR comment with the evidence (command output, HTTP status codes) for each newly verified item.

### 5. If any job fails — open a hotfix PR (reusing the just-closed branch name)

The hotfix PR **must** be on the same branch name as the PR that just merged — `--delete-branch` removed it on remote, so the name is free to re-use, and reusing it keeps the hotfix attached to the same issue/card and the same preview-stack name (some CIs key Pulumi stack names off branch names; reusing avoids leaking a "hotfix-X-Y" stack into the state backend).

```bash
# Discover the original branch from the merged PR
ORIG_BRANCH=$(gh pr view <merged-pr-number> --json headRefName -q '.headRefName')

# Refresh main in the primary checkout, then create a fresh worktree on the same branch name
REPO_ROOT=$(git rev-parse --show-toplevel)
git -C "$REPO_ROOT" fetch origin main
git worktree add "$REPO_ROOT/.claude/worktrees/$ORIG_BRANCH" -b "$ORIG_BRANCH" origin/main

cd "$REPO_ROOT/.claude/worktrees/$ORIG_BRANCH"
# ... fix the failure ...
```

Then use the `pr-create` skill to open the PR. Reference the failed run URL in the PR description. The skill's bot-account verification ensures the hotfix PR is also opened under the bot, not the developer.

Do **not** close the originating issue (Linear/Jira/GitHub/Trello) until the hotfix lands and prod is verified.

### 6. Clean up local worktree and branch

If a worktree or local branch exists for this branch, remove them. **Critical on Windows**: any prior `cd` into the worktree directory keeps file handles open for a while after the shell command returns, which makes `git worktree remove` fail with `Permission denied` and leaves the directory orphaned on disk. The fix is to `cd` somewhere outside the worktree first, then run the removal, and follow up with an explicit `rm -rf` as a backstop in case `git worktree remove` got partway through (metadata removed, directory still on disk).

```bash
REPO_ROOT=$(git rev-parse --show-toplevel)
BRANCH=$(gh pr view <number> --json headRefName -q '.headRefName')
WORKTREE="$REPO_ROOT/.claude/worktrees/$BRANCH"

# Move cwd out of any worktree first (root drive is always safe).
cd "$REPO_ROOT/.."

if git worktree list --porcelain | grep -q "^worktree $WORKTREE$"; then
  git -C "$REPO_ROOT" worktree remove --force "$WORKTREE" 2>/dev/null \
    || echo "git worktree remove failed; will rm -rf instead"
fi

# Backstop: if the directory still exists (Windows file-lock case or partial
# removal), force-delete it. Also prune the metadata so `git worktree list` is clean.
[ -d "$WORKTREE" ] && rm -rf "$WORKTREE"
git -C "$REPO_ROOT" worktree prune

git -C "$REPO_ROOT" branch -d "$BRANCH" 2>/dev/null && echo "Deleted local branch: $BRANCH"
```

### 7. Confirm and close

Once the post-merge pipeline is green and prod endpoints respond correctly:
- Report the run URL and the prod verification results
- Close the originating issue per project CLAUDE.md (e.g. mark Linear issue done)
