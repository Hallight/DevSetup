---
name: pr-create
description: Use when the user asks to create a pull request, open a PR, submit code for review, or says "create a PR", "open a pull request", "submit a PR".
---

# Create Pull Request

Create a GitHub pull request with proper formatting.

## Pre-computed Context

```bash
# Current branch
git branch --show-current

# Commits on this branch vs main
git log main..HEAD --oneline 2>/dev/null || git log origin/main..HEAD --oneline

# Changed files
git diff main --name-only 2>/dev/null || git diff origin/main --name-only

# Check if branch is pushed
git status -sb | head -1
```

## Instructions

1. **Verify the branch name is compatible with the project's CI conventions** — some CIs (e.g. those that derive preview-stack names from branch names) disallow slashes. Check project CLAUDE.md for branch-naming rules. If the current branch violates them, rename before pushing:
   ```bash
   git branch -m <new-name>
   ```

2. **Switch to the bot account and verify** — PRs **must** be opened by the developer's `-claude` bot account, not the developer's own account. This is non-negotiable; do not run `gh pr create` until the verification below confirms the bot is active.

   `gh auth switch --user` is case-sensitive and the bot login may not match `${DEV_USER}-claude` exactly (e.g. lowercase). Discover both names from `gh auth status`:

   ```bash
   DEV_USER=$(gh auth status 2>&1 | grep 'Logged in to github.com account' | grep -v -- '-claude' | awk '{print $7}')
   BOT_USER=$(gh auth status 2>&1 | grep 'Logged in to github.com account' | grep -- '-claude' | awk '{print $7}')
   BOT_ID=$(gh api "users/${BOT_USER}" --jq '.id')
   BOT_AUTHOR="${BOT_USER} <${BOT_ID}+${BOT_USER}@users.noreply.github.com>"

   gh auth switch --user "${BOT_USER}"

   # Verify — `gh pr create` will silently use whatever the active account is.
   ACTIVE=$(gh api user --jq '.login')
   if [ "$ACTIVE" != "$BOT_USER" ]; then
     echo "ERROR: expected active gh account = ${BOT_USER}, got ${ACTIVE}. Stop." >&2
     exit 1
   fi
   echo "Active gh account: $ACTIVE — proceeding under bot."
   ```

   Git commits use `--author="$BOT_AUTHOR"` because `gh auth` only affects API calls, not git.

3. **Ensure branch is pushed**: If not pushed, push with `git push -u origin $(git branch --show-current)`

4. **Analyze all commits** on this branch (not just the latest!)

5. **Derive the issue ID** per project CLAUDE.md branch convention (commonly: uppercase the branch name, e.g. `abc-5` → `ABC-5`). If the project has no issue tracker, skip this and the issue link below.

6. **Fetch the issue** (if applicable) to get the Approvers section and Testing Specifications. The project CLAUDE.md should specify which tracker (Linear, Jira, GitHub Issues) and the URL pattern.

7. **Create PR** (reconfirm `$ACTIVE` from step 2 still equals `$BOT_USER` if any earlier step might have switched accounts; abort if not) with this format:

```bash
gh pr create --title "type(ISSUE-ID): Brief description" --body "$(cat <<'EOF'
## Summary

<Issue link per project CLAUDE.md, if applicable>

- Bullet point 1
- Bullet point 2

## Test plan
- [ ] Step 1
- [ ] Step 2
EOF
)"
```

8. **Request reviewers** per project CLAUDE.md (e.g. from the issue's `## Approvers` section):
   ```bash
   gh pr edit <number> --add-reviewer <github-username>
   ```

9. **Watch CI** until all checks pass or fail:
   ```bash
   gh pr checks <number> --watch
   ```
   Do not proceed to the next step until CI completes.

10. **Execute every verifiable test plan step** — lint, curl probes, CI checks. Do not leave items unchecked unless blocked on an external action. If the project CLAUDE.md specifies post-deploy probes (e.g. branch-preview endpoint checks), include them in the test plan and execute them once the relevant CI job passes.

11. **Update PR description** with checked boxes (`- [x]`) after each step is verified.

12. **Post a PR comment** with evidence (command output, HTTP status, CI run link). Do not embed evidence inline in the description.

13. **Return the PR URL**

14. **Switch back to the developer account**:
    ```bash
    gh auth switch --user "$DEV_USER"
    ```

## PR Title Conventions

- `feat(ISSUE-ID):` - New feature
- `fix(ISSUE-ID):` - Bug fix
- `chore(ISSUE-ID):` - Maintenance, dependencies
- `docs(ISSUE-ID):` - Documentation
- `refactor(ISSUE-ID):` - Code refactoring
