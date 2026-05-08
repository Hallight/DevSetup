---
name: issue-implement
description: Use when the user asks to implement an issue, start work on a ticket, or says "implement <ISSUE-ID>", "work on this issue", "start on <ISSUE-ID>", "pick up this ticket".
---

# Implement Issue

Full end-to-end workflow for implementing an issue: fetch the spec, branch, implement, test, open a PR, and stop for review.

## Instructions

### 1. Fetch the issue

Get the full issue from the project's tracker (Linear / Jira / GitHub Issues — see project CLAUDE.md) using the issue ID (e.g. `ABC-7`). Read the following sections carefully before writing any code:
- **Description** — the user-facing problem being solved
- **Acceptance Criteria** — what must be true in prod when done
- **Testing Specifications** — how to verify each AC
- **Technical Guidance** — files to change, approach, gotchas
- **Approvers** — who must approve the PR before merge

### 2. Create a worktree for the branch

Branch name follows the project's branch convention (see CLAUDE.md). Common pattern: lowercase issue ID (e.g. `abc-7`). Some CIs (e.g. those that derive preview-stack names from branches) disallow slashes — never use a tracker-generated branch name with slashes if so.

```bash
# Fetch latest main and store repo root
REPO_ROOT=$(git rev-parse --show-toplevel)
git fetch origin main

# Create worktree with the correct branch name
git worktree add "$REPO_ROOT/.claude/worktrees/<branch>" -b <branch> origin/main

# Copy any untracked config files the project lists in its CLAUDE.md
# (or use the project's worktree-include configuration if defined)
WORKTREE="$REPO_ROOT/.claude/worktrees/<branch>"
# e.g. cp "$REPO_ROOT/.env" "$WORKTREE/.env" 2>/dev/null
# Project CLAUDE.md should enumerate the exact list

# Switch into the worktree — ALL subsequent steps run from here
cd "$WORKTREE"
```

> **Important:** All remaining steps (implement, verify, commit, PR) run inside the worktree directory. File paths in steps 3–5 are relative to the worktree root, which is a full copy of the repo.

### 3. Implement the changes

- Read every file you will touch before editing
- Follow CLAUDE.md conventions for the layer being changed (API, infra, frontend, etc.)
- Work through the Technical Guidance section top to bottom
- Do not add scope beyond what the issue specifies

### 4. Verify locally

If the project has a `/verify-local` skill, delegate to it — that skill encodes the project's specific lint/test/build commands.

Otherwise, run the verification appropriate to what was changed per project CLAUDE.md (lint, unit tests, build, e2e). If frontend or e2e specs changed, run the project's e2e suite per its CLAUDE.md instructions.

Fix any failures before pushing.

### 5. Open a PR

Use the `pr-create` skill — it commits, pushes, switches to the bot account, creates the PR, requests reviewers from the Approvers section, executes verifiable test plan steps, and posts evidence.

### 6. Stop

**Do not merge.** Wait for all approvers listed in the issue to approve on GitHub. CI green is not sufficient — approval is required. Report the PR URL and which approvers still need to review.
