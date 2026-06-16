---
name: trello-create
description: Use when creating or updating Trello cards, writing cards, formatting cards, planning implementation by breaking work into Trello cards, or batch-creating multiple cards on a Trello-tracked project. Use this — not /issue-create — when the project's CLAUDE.md identifies Trello as the issue tracker.
---

# Trello Card Standards

Use this skill when creating, updating, or batch-creating cards on the project's Trello board (board id and active-list id come from the project's CLAUDE.md → "Issue Tracker" section). **This skill MUST be loaded before writing any card** — single or batch.

This skill is the Trello counterpart to `/issue-create` and uses the **same card template, rules, and quality bar**. There is exactly one Trello-specific difference, and it is mechanical: **Acceptance Criteria are realized as a native Trello checklist** named `Acceptance criteria` (checkable, with a progress count) rather than inline `- [ ]` lines in the description — that checklist is what `/trello-implement` reads. Everything else below mirrors `/issue-create` section-for-section.

## Card Template

**Card name** — one short imperative line. Avoid noisy prefixes like `[FEATURE]`. The branch convention (`mm-{idShort}`) already supplies tracking context.

**Card description** — markdown, the same sections as `/issue-create`, in this order:

```markdown
## Description
[Outcome-focused — what problem does this solve for users? No implementation details here.]

## Acceptance Criteria
[On Trello these live in the native `Acceptance criteria` checklist, NOT inline here — see below. This heading documents the contract; do not duplicate the items in the description.]

## Testing Specifications
### API Tests
- [Endpoint contract tests: status codes, response shapes, auth enforcement — use the project's API-test suite per CLAUDE.md. Write `N/A` if the card has no API surface.]

### Browser Tests
- [User flow tests: form submissions, redirects, state persistence, route guards — use the project's browser-test suite per CLAUDE.md. Write `N/A` if the card has no web UI.]

### Manual / In-Editor / On-Device
- [For UE game/AR work with no API or browser surface: the in-editor or on-device steps that verify the behavior — e.g. "open project in UE 5.5, widget renders, button launches chess on Quest hardware". Write `N/A` for pure services/infra cards.]

## Technical Guidance
- `path/to/file` — [what changes and why]
- [Implementation approach, known gotchas, sequencing notes.]
- [Manual pre-merge steps the agent must NOT auto-execute — installs, credentials, DNS cutovers, marketplace/paid downloads, irreversible infra. Call these out explicitly so they aren't run automatically.]
- [Links to plan files, prior cards, gold-standard repos, vendor docs, prior conversations.]

## Approvers
- Developer: <engineering-approver per project CLAUDE.md / repo owner>
- Product: <product-approver if user-facing, else N/A>
```

**Acceptance criteria checklist** — a separate Trello checklist named exactly `Acceptance criteria`, holding the items that the `## Acceptance Criteria` heading refers to (the checklist is canonical — do not also inline them). Each item is a verifiable post-merge state: observable in prod, or on a real device for game changes. Not "PR passes CI." Create via `mcp__trello__create_checklist` then `mcp__trello__add_checklist_item` per item.

**Approvers / Members** — assign the Developer (and Product, if user-facing) approvers as card members via `idMembers` / `mcp__trello__assign_member_to_card`. If unsure, fall back to the repo owner per project CLAUDE.md or `git config remote.origin.url`.

**Labels** — at least one. Pull existing labels via `mcp__trello__get_board_labels` and reuse where possible; only `mcp__trello__create_label` when no existing label fits. (`/issue-create` uses work-type labels Bug/Feature/Improvement; the MeepleMates board instead uses area + owner labels — see Rules.)

**List** — default to the project's active list (`Next-up` on the MeepleMates board, id in CLAUDE.md). Trello has no native priority field, so list placement + position encode priority: keep higher-priority cards on the active list nearer the top, and only move to a backlog/feature list if the user explicitly says so.

## Rules

These mirror `/issue-create`'s rules. Where Trello/this board differs, it's called out.

- **Description**: User impact in plain language. Implementation details go in Technical Guidance only.
- **Acceptance Criteria**: Must be verifiable in prod after merge (or on a real device for game changes). Not "PR passes CI" — "Feature works in prod" / "Behavior X visible at URL Y" / "Asset Z loads on Quest hardware". Lives in the native `Acceptance criteria` checklist.
- **Approvers**: Use the project CLAUDE.md's required-approvers convention, assigned as card members. Add a Product approver for any user-facing functionality.
- **Testing Specifications**: Feature cards must specify the tests that prove the Acceptance Criteria. For services work that means both API-level tests (endpoint contracts: status codes, response shapes, auth) and browser-level tests (user flows). For UE game/AR work that has no API or browser surface, fill in the **Manual / In-Editor / On-Device** subsection instead with concrete in-editor/on-device steps. Mark inapplicable subsections `N/A` — don't delete them.
- **Full-vertical by default**: A card should include both backend and frontend (or, for the game, both logic and the UMG/Blueprint surface) where possible, so the change is end-to-end testable during review. Only split when (1) one half is a prerequisite with no UI/consumer yet (e.g. infrastructure/tables, an editor plugin with nothing driving it), or (2) the combined scope would be too large for one PR.
- **Right-sizing**: One PR a reviewer can meaningfully assess — typically 3+ coherent changes or one non-trivial feature/fix. Group related cleanup by concern area. Don't mix risky prod changes with safe cleanup. Bundle when splitting would only create churn.
- **Project alignment**: Every card must trace to a stated project goal or roadmap item (see Project-Level Standards). If you cannot find one, surface that to the user before creating the card.
- **Labels (MeepleMates board)**: this board uses area + owner labels rather than `/issue-create`'s Bug/Feature/Improvement. `UE` (engine-side work in `Source/` or `Content/`), `Non-UE` (services / infra / non-engine tooling), `Both Task` (cross-cutting), plus team-member ownership labels (`Matt Task`, `Levi Task`) and area labels (`Networking`, `OEM`, etc.). Pick the area + the owner; don't default to "Both Task" when the work is clearly one side.
- **Priority**: Trello has no priority field — encode it with list + position (active list, nearer the top = higher). Don't use position to encode execution order; capture dependencies in Technical Guidance or by linking the blocking card.
- **Related cards**: Link cards that share a codebase area, are consolidated, or are interdependent — reference the other card's short URL in Technical Guidance (Trello auto-renders a card short URL as an attached card link).
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
