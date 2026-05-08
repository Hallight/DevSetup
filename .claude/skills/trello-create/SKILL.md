---
name: trello-create
description: Use when creating or updating Trello cards, writing cards, formatting cards, planning implementation by breaking work into Trello cards, or batch-creating multiple cards on a Trello-tracked project. Use this — not /issue-create — when the project's CLAUDE.md identifies Trello as the issue tracker.
---

# Trello Card Standards

Use this skill when creating, updating, or batch-creating cards on the project's Trello board (board id and active-list id come from the project's CLAUDE.md → "Issue Tracker" section). **This skill MUST be loaded before writing any card** — single or batch.

This skill is the Trello counterpart to `/issue-create`. The quality bar is the same; only the format differs (Trello cards split acceptance criteria into a separate checklist instead of inlining them in the description).

## Card Template

**Card name** — one short imperative line. Avoid noisy prefixes like `[FEATURE]`. The branch convention (`mm-{idShort}`) already supplies tracking context.

**Card description** — markdown, in this exact section order so `/trello-implement` can parse it:

```markdown
## Goal
[Outcome-focused — what problem does this solve, or what capability does it unlock? No implementation steps here.]

## Files to create/modify
- `path/to/file` — [what changes and why]
- [Implementation guidance, known gotchas, sequencing notes.]

## Pre-flight
- [Manual steps that must happen before the PR can merge — installs, credentials, infra clicks, data migrations the agent should not auto-execute.]
- [Omit this section if there are none.]

## Reference
- [Links to plan files, prior cards, gold-standard repos, vendor docs, prior conversations.]
```

**Acceptance criteria** — separate Trello checklist named exactly `Acceptance criteria`. Each item is a verifiable post-merge state. Create via `mcp__trello__create_checklist` then `mcp__trello__add_checklist_item` per item.

**Members** — assign approvers via `idMembers`. If unsure, fall back to the repo owner per project CLAUDE.md or `git config remote.origin.url`.

**Labels** — at least one. Pull existing labels via `mcp__trello__get_board_labels` and reuse where possible; only `mcp__trello__create_label` when no existing label fits the area.

**List** — default to the project's active list (`Next-up` on the MeepleMates board, id in CLAUDE.md). Place on a backlog/feature list only if the user explicitly says so.

## Rules

- **Goal**: User/developer impact in plain language. Implementation belongs only in `## Files to create/modify`.
- **Acceptance criteria**: Each item must be observable in prod (or on a real device for game changes). Not "PR passes CI" — "Feature works in prod" / "Behavior X visible at URL Y" / "Asset Z loads on Quest hardware".
- **Pre-flight**: Reserve for things the implementing agent should NOT auto-execute — DNS cutovers, paid plugin installs, credential rotation, marketplace downloads, irreversible infra. If there are none, omit the section entirely; do not leave an empty `## Pre-flight`.
- **Right-sizing**: One PR a reviewer can meaningfully assess. Split when scope is large enough that a reviewer would want to land it in stages; bundle when splitting would just create churn.
- **Project alignment**: Every card must trace to a stated project goal or roadmap item. If you cannot find one, surface that to the user before creating the card.
- **Labels (MeepleMates board)**: `UE` (engine-side work in `Source/` or `Content/`), `Non-UE` (services / infra / non-engine tooling), `Both Task` (cross-cutting), plus any team-member ownership labels (`Matt Task`, `Levi Task`) and area labels (`Networking`, `OEM`, etc.) that apply. Pick the area + the owner; don't default to "Both Task" when the work is clearly one side.
- **Branch hint**: If the card is intended to be picked up by `/trello-implement`, expect the branch name to be `mm-{idShort}` lowercase (no slashes — Pulumi preview stack names derive from branch names per root CLAUDE.md).

## Operational steps

1. **Set the active board** via `mcp__trello__set_active_board` using the board id from project CLAUDE.md.
2. **Fetch lists and labels** in parallel: `mcp__trello__get_lists`, `mcp__trello__get_board_labels`. Cache the active-list id and any labels you'll reuse.
3. **Draft the card** — name, description (in the section order above), acceptance-criteria items, label ids, member ids. Show the draft to the user before posting unless they have already pre-approved batch creation.
4. **Create the card** via `mcp__trello__add_card_to_list` (returns the new card id and shortLink).
5. **Add the checklist** via `mcp__trello__create_checklist` with name `Acceptance criteria`, then `mcp__trello__add_checklist_item` for each item, scoped to the new card id.
6. **Assign members** via `mcp__trello__assign_member_to_card` if approvers are known.
7. **Verify** by fetching the card with `mcp__trello__get_card` (`includeMarkdown: true`) and confirming the description, checklist, labels, and members all rendered correctly. Report the card's short URL back to the user.

## Batch creation

When creating multiple cards (e.g. breaking down a project), draft *all* cards first, then show the user the full set as a numbered list with title + one-line goal each. Wait for approval before posting any. After approval, create them in dependency order (least-dependent first) so reviewers can land them in the same order without rebases.

## Project-Level Standards

A Trello project (here, the board itself) should have its overarching goals/Acceptance Criteria captured somewhere durable — in the root `CLAUDE.md`, a pinned card, or a project doc. Cards must trace back to one of those goals; otherwise either add the goal first or push back on the work item.
