---
name: branch-update-all
description: Use when the user asks to sync all local branches/worktrees with their remotes, refresh everything from origin, or says "update branches", "pull all", "sync worktrees", "refresh local", "update all branches". Stashes dirty work, pulls each worktree, auto-merges main into behind branches, removes worktrees whose PR has merged, and reports a summary.
---

# Update All Branches / Worktrees

Bring every local worktree in this repo in sync with `origin`. For each worktree: stash any dirty work, fast-forward (or merge) the branch from its upstream, then auto-merge `origin/main` into any feature branch that's behind. Restore stashes at the end. Then clean up worktrees whose PR has been merged. Designed to be a safe one-shot refresh before starting new work or before running `/issue-implement` or `/branch-merge-main`.

## Relationship to other skills

- **Run before `/issue-implement`** — that skill creates a worktree off `origin/main`. Refreshing first means the new worktree starts from the latest main and the local main is current for reference.
- **Run before `/branch-merge-main`** — that skill merges main into one branch. This skill does the same merge for *every* behind feature branch in one pass. After running this, `/branch-merge-main` on any specific branch will usually be a no-op.
- **Reuses `/pr-merge` step 6** — for worktrees whose PR is already merged, this skill performs the same worktree-and-local-branch cleanup that `/pr-merge` step 6 does. The PR-state check is what gates the deletion; a missing upstream alone is not enough.

## Pre-computed Context

```bash
# All worktrees
git worktree list --porcelain

# Recent network activity (helps detect stale fetches)
git remote -v
```

## Instructions

### 1. Fetch everything once, up front

```bash
git fetch --all --prune --tags
```

`--prune` cleans up refs for remote branches that have been deleted (merged PRs etc.). Note any pruned refs to mention in the final summary.

### 2. Enumerate worktrees

```bash
git worktree list --porcelain
```

Parse into a list of `(path, branch)` pairs. Skip entries that are:
- **Detached HEAD** (`detached` line in porcelain output) — report but don't touch.
- **Bare** worktrees — skip silently.
- **Locked** worktrees (`locked` line) — report and skip.

Order the list so the worktree on `main` is processed **first**, others after.

### 3. For each worktree, run the per-worktree update

All work for a given worktree runs inside it. Use `git -C "$WT"` or `cd "$WT"` — either works; pick one and stay consistent.

Initialize per-worktree state to report at the end:
- `stash_ref` (empty unless we stash)
- `pull_result` ("up-to-date" | "fast-forwarded N" | "merged" | "no-upstream" | "conflicts-resolved" | "skipped: <reason>")
- `merge_main_result` (only for non-main branches; "already-current" | "merged" | "conflicts-resolved" | "n/a")
- `pop_result` ("clean" | "conflicts-resolved" | "no-stash")

#### 3a. Stash dirty work (if any)

```bash
cd "$WT"
DIRTY=$(git status --porcelain)
if [ -n "$DIRTY" ]; then
  TS=$(date +%Y%m%d-%H%M%S)
  git stash push -u -m "branch-update-all auto-stash $TS"
  # Capture the stash ref we just created so we can pop the *right* one later
  STASH_REF=$(git stash list --format='%gd %gs' | grep "branch-update-all auto-stash $TS" | awk '{print $1}')
fi
```

Use `-u` to include untracked files. Do **not** use `-a` — that picks up `.gitignored` build artifacts which is rarely what the user wants.

Capture the stash ref by message rather than assuming `stash@{0}`. Concurrent stashes from other tooling could shift the index.

#### 3b. Pull from upstream

Determine upstream:

```bash
UPSTREAM=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || true)
```

If empty, set `pull_result="no-upstream"` and skip to step 3c.

For the **main** worktree:

```bash
git pull --ff-only origin main
```

For **feature** worktrees, try fast-forward first; if the branch has diverged, fall back to a merge commit:

```bash
if git pull --ff-only; then
  : # up-to-date or fast-forwarded
elif git pull --no-rebase --no-edit; then
  : # merge commit created
else
  # Conflicts. Resolve them.
  CONFLICTS=$(git diff --name-only --diff-filter=U)
  # For each file in $CONFLICTS: read, understand both sides, edit to resolve.
  # Then:
  git add <each-resolved-file>
  git commit --no-edit
fi
```

Conflict resolution mirrors `/branch-merge-main` step 6 — read each conflicted file, decide what the correct combined content is from context, edit it, stage, then commit with `--no-edit` to keep git's generated merge message.

If the main worktree's `pull --ff-only` fails, that means someone has committed directly to local `main` and it diverged from `origin/main`. **Do not merge.** Stop processing this worktree, set `pull_result="skipped: local main diverged from origin/main"`, and surface it loudly in the final summary so the user can investigate.

#### 3c. Auto-merge `origin/main` into feature branches that are behind

Skip this step entirely for the main worktree.

Check if the feature branch is behind `origin/main`:

```bash
BEHIND=$(git rev-list --count HEAD..origin/main)
```

If `BEHIND` is 0, set `merge_main_result="already-current"` and move on.

Otherwise merge (same flow as `/branch-merge-main` step 5–7, minus the CI watch which we batch at the end):

```bash
git merge --no-edit origin/main
```

If conflicts:
1. `git diff --name-only --diff-filter=U` → list of files
2. Resolve each one (read, edit, stage)
3. `git commit --no-edit`

Then push the merge commit so remote stays in sync with the work we just did:

```bash
git push origin "$(git branch --show-current)"
```

Set `merge_main_result` to `"merged"` or `"conflicts-resolved"` accordingly. Capture the pushed branch name for the CI-watch step at the end.

#### 3d. Pop the stash (if we made one)

```bash
if [ -n "$STASH_REF" ]; then
  if git stash pop "$STASH_REF"; then
    POP_RESULT="clean"
  else
    # Pop produced conflicts. Resolve in the working tree but DO NOT commit —
    # the user's WIP is uncommitted by definition.
    CONFLICTS=$(git diff --name-only --diff-filter=U)
    # Resolve each file; the user-edited combined content is the WIP they wanted.
    # After resolving, mark conflicts done so the stash entry is dropped:
    git add <each-resolved-file>
    # Note: do NOT commit. The user's WIP stays staged/unstaged for them to commit.
    git stash drop "$STASH_REF" 2>/dev/null || true
    POP_RESULT="conflicts-resolved"
  fi
fi
```

**Critical:** never commit the popped WIP. The reason we stashed was to keep that work out of the merge commits. After popping, leave the changes in the working tree exactly as the user had them (just possibly with conflict-resolution edits applied).

If the pop genuinely fails in a way you can't auto-resolve (e.g. file deleted upstream and modified locally in a non-obvious way), leave the stash **un-dropped** and report it in the summary — the user can pop it manually.

### 4. Clean up worktrees whose PR has been merged

After the per-worktree loop in step 3, identify feature worktrees that correspond to merged PRs and remove them. **Do not** run this during the loop — removing a worktree from inside the loop interferes with iteration and (on Windows) Git's file locks.

A worktree is a cleanup candidate when **both** are true:
1. Its upstream tracking ref no longer exists (the remote branch was deleted — typically by `--delete-branch` on PR merge). After `fetch --prune` this shows up as either `pull_result="no-upstream"` from step 3b, or `git rev-parse --abbrev-ref --symbolic-full-name @{u}` failing for that branch.
2. `gh pr list --head "$BRANCH" --state all --limit 1` reports the PR's state as `MERGED`.

Both checks are required. Condition 1 alone could mean a brand-new local branch that was never pushed, or a PR closed without merging — neither should be auto-deleted. The `MERGED` check is the safety gate.

For each candidate, the two-condition check above is the safety gate — once it passes, delegate the removal to the **`/branch-cleanup`** skill with the worktree's branch name. It owns the Windows-safe removal sequence and the `branch -D` squash-merge handling.

Record `(branch, "cleaned-up")` for each successful removal so the summary reflects it. If the PR state lookup returns `CLOSED` (closed without merging) or anything other than `MERGED`, leave the worktree alone and surface it in the summary as `pr-closed-unmerged` so the user can decide.

### 5. Final summary

After all worktrees are processed, print a table:

```
Worktree            Branch          Pull              Merge main         Stash               Cleanup
------------------- --------------- ----------------- ------------------ ------------------- -------------
.../main            main            fast-forwarded 3  n/a                no-stash            n/a
.../abc-7           abc-7           up-to-date        merged             clean               kept
.../abc-12          abc-12          merged            conflicts-resolved conflicts-resolved  kept
.../abc-15          abc-15          no-upstream       skipped            no-stash            removed (PR #41)
.../abc-22          abc-22          no-upstream       skipped            no-stash            kept (pr-closed-unmerged)
```

Then, if any feature branch was merged with `origin/main` and pushed, list their open PRs and their CI status:

```bash
for BR in $MERGED_BRANCHES; do
  PR=$(gh pr list --head "$BR" --state open --json number,url -q '.[0]')
  [ -n "$PR" ] && echo "$BR: $(echo "$PR" | jq -r .url)"
done
```

Do **not** block on `gh pr checks --watch` for every branch — that could mean watching N pipelines serially. List the PR URLs and note that the user can run `/branch-merge-main <branch>` (no-op) to attach to CI for a specific one, or check them at their leisure.

Finally, surface anything that needs the user's attention:
- Worktrees skipped (detached, locked, diverged main).
- Worktrees cleaned up because the PR was merged (report branch + PR number).
- Worktrees whose upstream was pruned but PR is not in `MERGED` state — flag as `pr-closed-unmerged` or `pr-not-found` for the user to investigate.
- Branches where the stash pop left conflicts (now resolved but uncommitted — the user's WIP is intact).
- Any stash that couldn't be popped and was left in `git stash list`.

## Safety rules

- Never `--force`, never `reset --hard`, never `clean -fd`.
- Never `commit` the contents of a popped stash — that's the user's uncommitted WIP.
- Only delete a worktree/local branch when its PR state is `MERGED`. A missing upstream alone is not sufficient — it could be a never-pushed local branch or a PR closed without merging.
- Never delete the worktree you're currently `cd`'d into. Always `cd` outside the worktree before `git worktree remove`.
- Never delete the main worktree or the `main` branch.
- Stash messages always include `branch-update-all auto-stash <timestamp>` so the user can locate them after the fact.
- If local `main` has diverged from `origin/main`, stop on that worktree and report — don't paper over it with a merge commit on main.
