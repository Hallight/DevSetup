---
name: issue-implement
description: Use when the user asks to implement an issue, start work on a ticket, or says "implement <ISSUE-ID>", "work on this issue", "start on <ISSUE-ID>", "pick up this ticket".
---

# Implement Issue

Full end-to-end workflow for implementing an issue: fetch the spec, branch, implement, test, open a PR, write learnings back to the tracker, and stop for review.

## Instructions

### 1. Fetch the issue

Get the full issue from the project's tracker (Linear / Jira / GitHub Issues — see project CLAUDE.md) using the issue ID (e.g. `ABC-7`). Read the following sections carefully before writing any code:
- **Description** — the user-facing problem being solved
- **Acceptance Criteria** — what must be true in prod when done
- **Testing Specifications** — how to verify each AC
- **Technical Guidance** — files to change, approach, gotchas
- **Approvers** — who must approve the PR before merge

Also fetch the issue's **relations** (blocks / blockedBy / relatedTo) — step 6 needs them. If the title starts with `Spike:` or `Decision:`, or the issue is otherwise research rather than a feature, expect step 6 to be a large part of the work, not a footnote.

### 2. Create a worktree for the branch

Use the **`/branch-checkout`** skill (Mode A — new branch off `origin/main`) to create and switch into the worktree. It owns the standard location and config-copy.

Branch name follows the project's branch convention (see CLAUDE.md). Common pattern: lowercase issue ID (e.g. `abc-7`). Some CIs (e.g. those that derive preview-stack names from branches) disallow slashes — never use a tracker-generated branch name with slashes if so.

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

### 6. Write learnings back to the tracker

The PR records *what changed*. The tracker is where *what was learned* has to live, because the next issue's implementer reads the ticket, not the diff.

**On the issue itself — always:**
- Comment with the PR link and a per-AC status table: done / blocked (with the reason and the exact unblock procedure) / deferred (with why). Partial completion is a valid outcome; a silent partial is not.
- Move the issue to the project's in-progress / in-review status and attach the PR as a link.

**On related issues — whenever a finding changes their assumptions:**
- Walk the relations from step 1. For each downstream issue whose Technical Guidance, Acceptance Criteria, or design rules are affected by what you learned, post **one comment on that issue** containing: what was learned, the measured evidence (numbers, not adjectives), and what it means for *that issue specifically*. Link the PR or doc that holds the detail.
- Classify each finding as it lands:
  - **Confirms** a downstream assumption → still say so. A design rule that has been empirically validated is worth more than one that was merely asserted; record the number that validated it.
  - **Contradicts** issue text (wrong library, wrong column, wrong data range, wrong constraint) → comment **and patch the issue body**. Comments get skimmed; stale guidance gets followed.
  - **Blocks** a downstream issue → comment on the blocked issue naming precisely what unblocks it.
- Do not post to issues the finding does not touch. One precise comment beats a broadcast.

**Spike and decision tickets specifically:** the deliverable *is* the knowledge, so this step is the deliverable. A spike whose findings only exist in a PR description has not shipped. Do this before reporting done, not after being asked.

### 7. Stop

**Do not merge.** Wait for all approvers listed in the issue to approve on GitHub. CI green is not sufficient — approval is required. Report the PR URL, which approvers still need to review, and which related issues received learnings in step 6.
