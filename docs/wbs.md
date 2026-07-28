# WBS — work breakdown and progress ledger

_Last updated: 2026-07-28_

Single source of truth for project progress. Update it in the same commit as the
work it describes. A task is `done` only when it meets the Definition of Done in
`.claude/skills/flutter-workflow/references/definition-of-done.md`.

Status values: `todo` · `in-progress` · `blocked` · `done` · `descoped`

## Progress summary

| Milestone | Status | Notes |
|---|---|---|
| M0 · Development harness | done | Skills, checklist and enforcement scripts in place |
| M1 · Product definition (Phase 0–1) | **todo — next** | Blocked on product input from the owner |
| M2 · Project foundation (Phase 2–3, 6) | todo | Needs M1: platforms and offline/online decide the dependency set |
| M3 · Architecture & design system (Phase 4–5, 7, 12–13) | todo | |
| M4 · Router & data foundation (Phase 8, 10–11) | todo | |
| M5 · First vertical slice (Phase 14) | todo | Scope decided in M1 |
| M6 · Test suite (Phase 15) | todo | Runs alongside M5, not after |
| M7 · CI/CD (Phase 19) | todo | Can start once M2 lands |
| M8 · Release (Phase 16–18, 20–22) | todo | |

---

## M0 · Development harness

### T0.1 · Skill harness for the 22-phase checklist

- **Status:** done
- **Goal:** Encode `docs/checklist.md` as invocable skills so each phase has one
  place that holds its rules, and so phase order is enforced rather than
  remembered.
- **Scope:** 11 skills under `.claude/skills/`, the canonical checklist,
  root `CLAUDE.md`, document templates. Out of scope: any Flutter source code.
- **Output:**
  - `docs/checklist.md`, `docs/README.md`, `docs/wbs.md`
  - `CLAUDE.md` — non-negotiables that apply in every phase
  - `.claude/skills/flutter-workflow` — router, phase index, Definition of Done,
    `scripts/dod_check.sh`
  - `.claude/skills/flutter-product-spec` — Phase 0–1 + four document templates
  - `.claude/skills/flutter-project-setup` — Phase 2, 3, 6 + dependency and
    flavor references
  - `.claude/skills/flutter-architecture` — Phase 4–5, `analysis_options.yaml`,
    `scripts/check_architecture.sh`
  - `.claude/skills/flutter-design-system` — Phase 7, 12, 13 + token, component
    and a11y/l10n references
  - `.claude/skills/flutter-navigation` — Phase 8
  - `.claude/skills/flutter-state-riverpod` — Phase 9
  - `.claude/skills/flutter-data-layer` — Phase 10–11 + networking and
    persistence references
  - `.claude/skills/flutter-feature-slice` — Phase 14 + per-feature checklist
  - `.claude/skills/flutter-testing` — Phase 15
  - `.claude/skills/flutter-ship` — Phase 16–22 + CI reference
- **Acceptance criteria:**
  - [x] Every checklist phase maps to exactly one owning skill
        (`flutter-workflow/references/phase-index.md`).
  - [x] `check_architecture.sh` detects domain→framework imports,
        presentation→data imports, cross-feature imports, core/shared→feature
        imports, swallowed exceptions, `print` in `lib/`, naming-suffix
        violations and oversized files — verified against a fixture.
  - [x] `check_architecture.sh` reports zero violations on conforming code —
        verified against a fixture.
  - [x] Both scripts exit 0 with a clear message when the Flutter project does
        not exist yet.
- **Dependencies:** none
- **Tests required:** fixture-based verification of both scripts (done manually
  during authoring; see the note under Technical debt).
- **Checklist phases:** meta — supports all

---

## M1 · Product definition — next

Blocked on input only the product owner can give. The five answers that unblock
the most downstream work, in order of leverage:

1. **Offline-first, online-first, or hybrid?** Decides whether Drift is the
   source of truth or a cache, and therefore the shape of every repository.
2. **Which platforms ship at launch?** Decides plugin choices and responsive scope.
3. **Is there authentication, and are there roles?** Reaches into the router,
   the network layer, storage and the whole test setup.
4. **What data is sensitive?** Decides secure storage, database encryption and
   log redaction.
5. **What is genuinely in the MVP?**

### T1.1 · Product requirements

- **Status:** todo
- **Goal:** Answer the five questions above and record them.
- **Output:** `docs/product.md`, `docs/mvp.md`
- **Acceptance criteria:**
  - [ ] Problem, users and core value stated.
  - [ ] Platform, data-posture, auth and sensitive-data decisions recorded with
        their consequences.
  - [ ] Features classified must / should / nice / out, each with a completion
        condition.
- **Dependencies:** product owner input
- **Tests required:** none — document only
- **Checklist phases:** 0.1, 0.2

### T1.2 · Use cases and business rules

- **Status:** todo
- **Goal:** Specify each must-have feature to the point where it can be built
  without further questions.
- **Output:** `docs/use-cases.md`, `docs/business-rules.md`
- **Acceptance criteria:**
  - [ ] Every must-have feature has a use case with actor, trigger,
        preconditions, main / alternative / error flows, and postconditions.
  - [ ] Business rules numbered `BR-xx`.
  - [ ] Validation rules carry the exact user-facing message.
  - [ ] Every entity has an explicit state machine with illegal transitions
        listed.
- **Dependencies:** T1.1
- **Tests required:** none — document only
- **Checklist phases:** 0.3

### T1.3 · WBS for M2–M5

- **Status:** todo
- **Goal:** Break the first milestones into task-level detail.
- **Output:** this file, extended
- **Acceptance criteria:**
  - [ ] M2–M4 broken to tasks with acceptance criteria and dependencies.
  - [ ] M5 scoped to one vertical slice that exercises database → screen.
  - [ ] Later milestones left at feature granularity — planning them to task
        level now guarantees replanning.
- **Dependencies:** T1.2
- **Tests required:** none
- **Checklist phases:** 1.1, 1.2

---

## Deferred and descoped

| Item | Decision | Reason | Revisit when |
|---|---|---|---|
| Flutter toolchain verification | deferred | `flutter` is not installed in the authoring environment; `flutter doctor` and a clean build could not be run | Phase 2.1, in an environment with Flutter |

## Known technical debt

| Item | Incurred in | Cost of leaving it | Planned repayment |
|---|---|---|---|
| `check_architecture.sh` has no automated test of its own | T0.1 | A regression in the checker silently stops enforcing boundaries | Add `test/tools/` fixtures running the script over known-good and known-bad trees, once `test/` exists (M6) |
| `analysis_options.yaml` not yet applied | T0.1 | The lint set is written but unenforced until a project exists | Copy from `flutter-architecture/references/` during Phase 2.3 and confirm every listed rule is recognised by the analyzer version in use |
