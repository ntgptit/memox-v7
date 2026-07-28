# WBS — work breakdown and progress ledger

_Last updated: YYYY-MM-DD_

This file is the single source of truth for project progress. Update it in the
same commit as the work it describes. A task is marked done only when it meets
the Definition of Done — see
`.claude/skills/flutter-workflow/references/definition-of-done.md`.

Status values: `todo` · `in-progress` · `blocked` · `done` · `descoped`

## Progress summary

| Milestone | Status | Notes |
|---|---|---|
| M0 Foundation | todo | |
| M1 <first vertical slice> | todo | |

---

## M0 · Foundation

### T0.1 · <task name>

- **Status:** todo
- **Goal:** <one sentence>
- **Scope:** <what is in; and explicitly what is out, if it is likely to be assumed in>
- **Output:** <files, docs, or config this produces>
- **Acceptance criteria:**
  - [ ] <checkable by someone who did not do the work>
- **Dependencies:** <task IDs, or none>
- **Tests required:** <specific tests, or "none — config only" with the reason>
- **Checklist phases:** <e.g. 2.3, 3.1>

### T0.2 · ...

---

## M1 · <first vertical slice>

Build one feature end to end before starting a second. A slice that reaches from
the database to the screen proves the architecture; four half-features prove
nothing and hide the integration problems until later.

### T1.1 · ...

---

## Deferred and descoped

| Item | Decision | Reason | Revisit when |
|---|---|---|---|

Anything dropped mid-task goes here rather than being silently omitted — a
future session reading a `done` task will otherwise assume the omitted part
exists.

## Known technical debt

| Item | Incurred in | Cost of leaving it | Planned repayment |
|---|---|---|---|
