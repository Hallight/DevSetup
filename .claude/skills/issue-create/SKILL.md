---
name: issue-create
description: Use when creating or updating issues (Linear, Jira, GitHub), writing issues, formatting issues, planning implementation of a project's acceptance criteria, or breaking down work into issues. This includes batch creation of multiple issues.
---

# Issue Standards

Use this skill when creating, updating, or batch-creating issues in the project's tracker (Linear / Jira / GitHub Issues — see project CLAUDE.md). **This skill MUST be loaded before writing any issue** — whether it's a single issue or a set of issues for a project.

## Issue Template

```
## Description
[Outcome-focused — what problem does this solve for users? No implementation details here.]

## Acceptance Criteria
- [ ] [Verifiable state after the PR is deployed to prod]

## Testing Specifications
### API Tests
- [Endpoint contract tests: status codes, response shapes, auth enforcement — use the project's API-test suite per CLAUDE.md]

### Browser Tests
- [User flow tests: form submissions, redirects, state persistence, route guards — use the project's browser-test suite per CLAUDE.md]

## Technical Guidance
[Files to change, implementation approach, known gotchas, relevant docs/links.]

## Approvers
- Developer: <engineering-approver per project CLAUDE.md>
- Product: <product-approver if user-facing, else N/A>
```

## Rules

- **Description**: User impact in plain language. Implementation details go in Technical Guidance only.
- **Acceptance Criteria**: Must be verifiable in prod after merge. Not "PR passes CI" — "Feature works in prod" (i.e., observable behavior at the project's prod URL).
- **Approvers**: Use the project CLAUDE.md's required-approvers convention. Add a Product approver for any user-facing functionality.
- **Testing Specifications**: Feature issues must specify both API-level tests (endpoint contracts: status codes, response shapes, auth) and browser-level tests (user flows: form submissions, redirects, state). The template has both sections — fill in each with concrete test cases tied to the Acceptance Criteria.
- **Full-stack by default**: Feature issues should include both backend and frontend work where possible. This enables end-to-end testing during PR review. Only split frontend from backend when: (1) the backend is a prerequisite with no UI yet (e.g., infrastructure/tables), or (2) the combined scope would be too large for one PR.
- **Right-sizing**: One PR a reviewer can meaningfully assess — typically 3+ coherent changes or one non-trivial feature/fix. Group related cleanup by concern area. Don't mix risky prod changes with safe cleanup.
- **Project alignment**: Every issue must tie to at least one project Acceptance Criterion.
- **Labels**: Every issue needs at least one — `Bug` (broken behavior, failing CI), `Feature` (new capability), `Improvement` (enhancement, cleanup, docs).
- **Priority**: Default to the parent project's priority. Override only when the user explicitly specifies a different level. Do not use priority to encode execution order — use `blockedBy` relationships for sequencing.
- **Related issues**: Wire `relatedTo` links for issues sharing a codebase area, consolidated issues, or interdependent implementations.

## Project-Level Standards

Every project in the tracker must define explicit Acceptance Criteria in its description — outcome-focused, covering the full deliverable scope, verifiable in prod.
