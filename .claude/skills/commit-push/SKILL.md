---
name: commit-push
description: Use when the user asks to commit changes, stage and commit, push to remote, or says "commit this", "push my changes", "commit and push", "save my work".
---

# Commit and Push

Commit all staged changes and push to remote.

## Pre-computed Context

```bash
# Current branch
git branch --show-current

# Git status (staged and unstaged)
git status --short

# Recent commits for style reference
git log --oneline -5
```

## Instructions

1. Review the git status output above
2. **Resolve the bot account** — all commits are authored by the developer's `-claude` bot account. Discover it from `gh auth status` rather than appending `-claude` to the current login: the active `gh` account may *already be* the bot, in which case appending yields a nonexistent `…-claude-claude` (a 404 that silently corrupts the author string).
   ```bash
   BOT_USER=$(gh auth status 2>&1 | grep 'Logged in to github.com account' | grep -- '-claude' | awk '{print $7}')
   BOT_ID=$(gh api "users/${BOT_USER}" --jq '.id')
   BOT_AUTHOR="${BOT_USER} <${BOT_ID}+${BOT_USER}@users.noreply.github.com>"
   ```
3. If there are unstaged changes, stage them with `git add -A`
4. Analyze the changes and create a descriptive commit message following the project conventions:
   - Format: `type: description` (feat, fix, chore, docs, refactor)
   - Keep it concise but descriptive
   - Always end with: `Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>`
5. Create the commit with `--author` to attribute to the bot account:
   ```bash
   git commit --author="$BOT_AUTHOR" -m "..."
   ```
6. Push to the current branch
7. Report the commit hash and branch
8. Watch CI until all checks pass or fail:
   ```bash
   gh pr list --head $(git branch --show-current) --json number --jq '.[0].number' \
     | xargs -I{} gh pr checks {} --watch
   ```
   - If all checks pass — report the run URL and confirm CI is green
   - If any check fails — report the failing job name and URL, then diagnose and fix

## Example

```bash
BOT_USER=$(gh auth status 2>&1 | grep 'Logged in to github.com account' | grep -- '-claude' | awk '{print $7}')
BOT_ID=$(gh api "users/${BOT_USER}" --jq '.id')
BOT_AUTHOR="${BOT_USER} <${BOT_ID}+${BOT_USER}@users.noreply.github.com>"

git add -A && git commit --author="$BOT_AUTHOR" -m "$(cat <<'EOF'
feat: Add customer analytics dashboard

- Add lifetime value calculation
- Add job completion rate metrics
- Add AR aging summary

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)" && git push origin $(git branch --show-current)
```
