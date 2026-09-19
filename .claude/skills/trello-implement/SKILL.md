---
name: trello-implement
description: Use when the user asks to implement a Trello card, work on a card, or says "implement card <short-link>", "pick up Trello <short-link>", "work on card 89", "implement mm-89".
---

# Implement Trello Card

Full end-to-end workflow for implementing a Trello card: fetch the spec, branch, implement, test, open a PR, write learnings back to the board, and stop for review. Mirrors `/issue-implement` but pulls from Trello (no Linear tracker).

## Instructions

### 1. Fetch the card

Get the full card from Trello using the user-supplied identifier. Two ID formats are accepted:

- **Short link** — 8-character alphanumeric (e.g. `yQhCgdvg`). Pass directly to `mcp__trello__get_card` as the `cardId`.
- **idShort** — numeric (e.g. `89`, `mm-89`). Strip any `mm-` prefix; resolve to a card by listing the project's board (board id is in the project's CLAUDE.md → "Issue Tracker" section) and finding the matching `idShort`. Then fetch via `mcp__trello__get_card`.

From the card, gather:

- **`name`** → card title (used in PR title)
- **`desc`** → markdown description. Cards follow the `/trello-create` template, which mirrors `/issue-create`. Parse these sections:
  - `## Description` → user-facing problem (= Linear "Description")
  - `## Testing Specifications` → API / Browser / Manual-in-editor-on-device test cases that prove the acceptance criteria
  - `## Technical Guidance` → file paths, approach, gotchas, and any manual pre-merge steps the agent must NOT auto-execute
  - `## Approvers` → Developer/Product approver roles (also reflected in card members)
- **Acceptance criteria** → use `mcp__trello__get_checklist_items` (or the items embedded in `mcp__trello__get_card` output) on the card's checklist named "Acceptance criteria". These items are the verifiable acceptance criteria — every box must be true in prod when the PR merges. (= Linear "Acceptance Criteria")
- **`idMembers`** → approvers. If empty, fall back to the repo owner (per project CLAUDE.md or `git config remote.origin.url`).
- **`idShort`** and **`shortLink`** → context for branch + PR naming.
- **Related cards** → Trello has no relations graph, so collect them by hand: cards attached to this card, card URLs or `mm-N` references in `desc` (look for "Depends on", "Blocks", "See also"), and neighbouring cards in the same list. Step 6 needs this list. If the card name starts with `Spike:` or `Decision:`, or the card is otherwise research rather than a feature, expect step 6 to be a large part of the work, not a footnote.

If the card has no `## Description` or no "Acceptance criteria" checklist, **stop and ask the user** before proceeding — under-specified work is a recipe for scope creep.

### 2. Create a worktree for the branch

Use the **`/branch-checkout`** skill (Mode A — new branch off `origin/main`) to create and switch into the worktree. It owns the standard location and config-copy.

Branch name follows the project's branch convention (see CLAUDE.md). For Trello-tracked projects, this is typically `mm-{idShort}` lowercase (e.g. `mm-89` for idShort 89). **No slashes** — preview-stack names derive from branch names.

> **Important:** All remaining steps (implement, verify, commit, PR) run inside the worktree directory. File paths in steps 3–5 are relative to the worktree root.

### 3. Implement the changes

- Read every file you will touch before editing
- Follow CLAUDE.md conventions for the layer being changed (API, infra, frontend, etc.)
- Work through the `## Technical Guidance` section top to bottom
- Satisfy the `## Testing Specifications` — write/run the API, browser, or manual/in-editor/on-device tests it lists
- Tick off acceptance-criteria items mentally as you complete them — every checklist item must be satisfied
- Do not add scope beyond what the card specifies
- Surface any manual pre-merge steps (called out in Technical Guidance) to the user before merge — do not auto-execute them

### 4. Verify locally

If the project has a `/verify-local` skill, delegate to it — that skill encodes the project's specific lint/test/build commands.

Otherwise, run the verification appropriate to what was changed per project CLAUDE.md (lint, unit tests, build, e2e). If frontend or e2e specs changed, run the project's e2e suite per its CLAUDE.md instructions.

Fix any failures before pushing.

### 5. Open a PR

Use the `/pr-create` skill — it commits, pushes, switches to the bot account, creates the PR, requests reviewers, executes verifiable test plan steps, and posts evidence.

When invoking `/pr-create`:

- **PR title**: `[mm-<idShort>] <card title>` (e.g. `[mm-89] Bootstrap Pulumi + CI/CD with /health deploy`).
- **PR body**: include a "Closes Trello card: <short-url>" line so the card and PR are linked. Include the acceptance-criteria checklist as a Markdown checklist in the PR body so reviewers can verify each item.
- **Approvers**: pass the Trello card's `idMembers` (resolved to GitHub usernames if needed). Fall back to repo owner if empty.

### 6. Write learnings back to the board

The PR records *what changed*. The board is where *what was learned* has to live, because the next card's implementer reads the card, not the diff.

**On the card itself — always:**
- `mcp__trello__add_comment` with the PR link and a per-AC status table: done / blocked (with the reason and the exact unblock procedure) / deferred (with why). Partial completion is a valid outcome; a silent partial is not.
- Tick completed acceptance-criteria items via `mcp__trello__update_checklist_item`; leave blocked ones unticked so the card stays honest.
- `mcp__trello__move_card` to the board's in-progress / in-review list, and `mcp__trello__attach_data_to_card` (or a URL attachment) with the PR so the link is on the card, not just in a comment.

**On related cards — whenever a finding changes their assumptions:**
- Walk the related-cards list from step 1. For each card whose Technical Guidance, acceptance criteria, or design rules are affected by what you learned, `mcp__trello__add_comment` **once on that card** with: what was learned, the measured evidence (numbers, not adjectives), and what it means for *that card specifically*. Link the PR or doc that holds the detail.
- Classify each finding as it lands:
  - **Confirms** a downstream assumption → still say so. A design rule that has been empirically validated is worth more than one that was merely asserted; record the number that validated it.
  - **Contradicts** card text (wrong library, wrong column, wrong data range, wrong constraint) → comment **and patch the card `desc`** via `mcp__trello__update_card_details`. Comments get skimmed; stale guidance gets followed.
  - **Blocks** a downstream card → comment on the blocked card naming precisely what unblocks it.
- Do not post to cards the finding does not touch. One precise comment beats a broadcast.

**Spike and decision cards specifically:** the deliverable *is* the knowledge, so this step is the deliverable. A spike whose findings only exist in a PR description has not shipped. Do this before reporting done, not after being asked.

### 7. Stop

**Do not merge.** Wait for all approvers (card members) to approve on GitHub. CI green is not sufficient — approval is required. Report:

- The PR URL
- Which approvers still need to review
- Which related cards received learnings in step 6
- Any manual pre-merge steps from the card (called out in Technical Guidance) that must happen before merge (e.g. "delete CDK-owned Route 53 record")
