---
name: pr-respond
description: Use when the user asks to address PR feedback, respond to review comments, fix PR comments, or says "respond to the PR", "address the feedback", "fix the PR comments", "there's feedback on the PR".
---

# Respond to PR Feedback

Fetch all review comments on the current branch's open PR, implement the requested changes, and reply to every comment with what was done.

**Replying to each comment is not optional** — every comment must receive a direct reply explaining the fix, update, or clarification before this skill is complete.

## Pre-computed Context

```bash
# Current branch
git branch --show-current

# Open PR for this branch
gh pr list --head $(git branch --show-current) --json number,title,url
```

## Instructions

1. **Find the PR** for the current branch using the pre-computed context.

2. **Fetch all feedback** — both top-level review comments and inline code comments:
   ```bash
   PR=<number>
   # Review body + state
   gh pr view $PR --comments --json comments,reviews,body
   # Inline code comments
   gh api repos/:owner/:repo/pulls/$PR/comments --jq '.[] | {path:.path, line:.line, body:.body, id:.id}'
   ```

3. **Read every referenced file** before making changes. Never edit code you haven't read.

4. **Implement all requested changes** in a single pass. Address every comment — do not skip any.

5. **Resolve bot account** — derive the bot username and author string from the current developer:
   ```bash
   DEV_USER=$(gh api user --jq '.login')
   BOT_USER="${DEV_USER}-claude"
   BOT_ID=$(gh api "users/${BOT_USER}" --jq '.id')
   BOT_AUTHOR="${BOT_USER} <${BOT_ID}+${BOT_USER}@users.noreply.github.com>"
   gh auth switch --user "${BOT_USER}"
   ```

6. **Reply to every inline comment** — this is required, not optional. Reply immediately after implementing the change so nothing is missed:
   ```bash
   gh api repos/:owner/:repo/pulls/$PR/comments/$COMMENT_ID/replies \
     -f body="Done — <specific description of what changed and why>"
   ```
   - Code change → explain what was changed and the approach taken
   - Question → answer it directly, with a code reference if relevant
   - Disagreement with project conventions → explain the convention and what was done instead

7. **Reply to top-level review comments** the same way:
   ```bash
   gh pr comment $PR --body "<reply text>"
   ```

8. **Commit and push** with `--author` to attribute to the bot account:
   ```bash
   git add -A && git commit \
     --author="$BOT_AUTHOR" \
     -m "$(cat <<'EOF'
   fix: address PR feedback

   Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
   EOF
   )" && git push
   ```
   Then watch CI:
   ```bash
   gh pr checks $PR --watch
   ```

9. **Post a final summary comment** once all changes are pushed and CI passes:
    ```bash
    gh pr comment $PR --body "$(cat <<'EOF'
    ## Feedback addressed

    - **[file:line]** <comment summary> → <what changed>
    - **[file:line]** <comment summary> → <what changed>

    All comments replied to individually above.
    EOF
    )"
    ```

10. **Switch back to the developer account**:
    ```bash
    gh auth switch --user "$DEV_USER"
    ```

11. **Return** the PR URL and commit hash.

## Notes

- Every comment must have a reply — do not leave any comment without a response.
- If a comment is a question rather than a change request, answer it in the reply without modifying code.
- If a requested change conflicts with project conventions (see CLAUDE.md), note the conflict in the reply and implement the convention-compliant version.
- Do not mark the PR ready for re-review — leave that to the author.
