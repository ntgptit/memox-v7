---
name: flutter-feature-slice
description: The end-to-end workflow for building one feature as a vertical slice in this Flutter app — the pre-flight checks that must pass before any code is written, then domain, then data, then presentation, then tests, docs and WBS update. Use this skill for any request to build, add, implement or finish a feature or screen — "add login", "build the deck list", "implement search", "finish the profile screen" — because it sequences the other flutter-* skills correctly and catches the missing use case, undefined state, or unagreed API contract before they turn into rework. Covers checklist phase 14, and it is the usual entry point for feature work.
---

# Building a feature as a vertical slice

Covers checklist Phase 14. This is the loop you run for every feature, and it
composes the other skills rather than repeating them.

**Vertical slice means: database to screen, one feature at a time.** One feature
working end to end proves the architecture and surfaces integration problems
while they are still cheap. Four features each half-built prove nothing and hide
the same problems until they are expensive.

## Step 0 — Pre-flight, before writing any code

Do not skip this because the feature "seems obvious". Every item here that turns
out to be open becomes rework, and the rework is always larger than the check.

- [ ] **Use case approved** — exists in `docs/use-cases.md` with main,
      alternative and error flows.
- [ ] **Business rules clear** — the `BR-xx` rules this feature enforces are
      written, and validation rules have their exact user-facing messages.
- [ ] **Design available** — or an explicit agreement to use existing components
      with no new visual design.
- [ ] **State matrix decided** — which of initial / loading / loaded / empty /
      error / refreshing / submitting occur, and what each shows.
- [ ] **API contract known** — endpoints, shapes, error format, pagination in
      `docs/api-spec.md`. If the backend does not exist yet, agree the contract
      and build against a fake implementing the same interface.
- [ ] **Data model known** — entities, tables, whether a migration is needed.
- [ ] **Acceptance criteria written** in the WBS entry, checkable by someone
      else.
- [ ] **Dependencies identified** — which features or shared components this
      needs, and whether they exist yet.

If something is missing, stop and get it. Load `flutter-product-spec` if the
gap is a use case or business rule. Report which item is open and what you need
— building on an assumption and being wrong costs far more than asking.

The exception worth naming: if the user has heard the gap and says build it
anyway, build it. State the assumption you are proceeding on, record it in the
WBS entry, and continue with the full scope.

## Step 1 — Domain

Layer rules: `flutter-architecture`. No Flutter, no Dio, no Drift here.

```
features/<feature>/domain/
├── entity/      <name>_entity.dart
├── repository/  <name>_repository.dart      # abstract contract
└── usecase/     <verb>_<noun>_use_case.dart # only when warranted
```

- Entities are immutable, with value equality, in domain language. Entity state
  is the enum or sealed class from `docs/business-rules.md`, so illegal states
  are unrepresentable rather than merely unlikely.
- The repository contract is written from what presentation needs, not from what
  the API happens to offer. If the API needs three calls for one screen, the
  contract still has one method and the implementation makes three.
- Business validation belongs here — it is the same regardless of UI, and here
  it can be unit-tested without a widget or a server.
- **Create a use case only when it holds real logic or has more than one
  caller.** `Future<List<X>> call() => repo.getAll();` is a file, an
  indirection and a test for no benefit. Call the repository from the
  controller.

## Step 2 — Data

Details: `flutter-data-layer`.

```
features/<feature>/data/
├── model/       <name>_model.dart          # DTO
├── remote/      <name>_remote_data_source.dart
├── local/       <name>_local_data_source.dart, <name>_dao.dart
└── repository/  <name>_repository_impl.dart
```

Order matters here: DTOs and data sources first, then the mapper, then the
repository. The repository is where exceptions become `Failure`s and where the
cache/sync policy from `docs/architecture.md` is applied — nowhere else.

If the backend is not ready, implement the contract with a fake that returns
realistic data *including* error and empty cases. A fake that only ever succeeds
means the error states never get built, which is exactly the gap this step is
supposed to close.

## Step 3 — Presentation

Details: `flutter-state-riverpod` for state, `flutter-design-system` for UI,
`flutter-navigation` for routes.

```
features/<feature>/presentation/
├── state/       <name>_state.dart
├── controller/  <name>_controller.dart
├── screen/      <name>_screen.dart
└── widget/      <section>_widget.dart
```

Build state and controller before the screen. Writing the state model first
forces the state matrix to be real, and the screen then becomes a rendering of
something already decided rather than the place where the decisions get made
implicitly.

While building the screen:

- Use existing components and tokens. Do not invent visual design mid-feature —
  if the design is genuinely missing, raise it rather than improvising, because
  an improvised variant becomes another thing to reconcile later.
- Do not create a shared component for this feature's first use. Build it
  locally; promote it to `shared/` when a second real caller appears and shows
  you what actually varies.
- Split the screen into section widgets — separate classes, not `_buildX()`
  methods.
- **Render every state in the matrix.** Empty is the one that gets skipped, and
  it is the first thing a new user sees.
- Check dark mode, a 320px screen, 2.0× text scale, and keyboard-open before
  calling the screen done — not in a later pass, when fixing it means
  restructuring.

## Step 4 — Tests

Details: `flutter-testing`.

Minimum for a feature to be done:

- [ ] Unit tests for domain logic and validation, including the rule violations.
- [ ] Repository tests with a mocked data source, covering the failure paths and
      the cache fallback.
- [ ] Mapper tests, including a null field and an unknown enum value.
- [ ] Controller tests: initial state, loading→loaded, loading→error, refresh,
      submit success, submit failure, duplicate submit.
- [ ] Widget tests for the states that matter — at least loaded, empty, error.
- [ ] Integration test for the main flow.
- [ ] Golden tests if this feature added a shared component.

## Step 5 — Close it out

- [ ] `.claude/skills/flutter-workflow/scripts/dod_check.sh` passes.
- [ ] `python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v7` clean
      (`flutter analyze` does not cover the Riverpod and layering rules).
- [ ] `docs/wbs.md` updated in this commit — status, and anything descoped with
      the reason.
- [ ] Docs the feature changed (data model, API spec, architecture decisions)
      updated in the same commit.
- [ ] Full Definition of Done reviewed:
      `.claude/skills/flutter-workflow/references/definition-of-done.md`.
- [ ] Conventional commit scoped to the feature: `feat(<feature>): ...`.

`assets/feature_checklist.md` is a copy-paste version of all of the above to
paste into a WBS entry or PR description.

`assets/feature_blueprint.md` is the same ground covered from the other
direction: what the *existing* `features/deck` slice settled, measured against
the code rather than described in the abstract. Read it before starting the
second feature of a kind — it records which folder layouts the guards actually
accept, what already lives in `core/` and `shared/` so you do not rebuild it,
the five steps every write controller follows, which test belongs at which level,
and the one duplication that was left in place along with the three extractions
that were tried and rejected. It is the answer to "how much of feature 1 can I
copy", with the parts that must not be copied named.

## The failure modes this ordering prevents

- **Screen first, then data.** The state model ends up shaped by widget
  convenience, and the error states never appear because the fake never failed.
- **All features' domains, then all their data.** Nothing is demonstrable, and
  the first integration reveals problems in every feature at once.
- **Tests last, after the demo.** They get written to match what the code does,
  which is not the same as what the acceptance criteria say.
- **Promoting a component on first use.** The abstraction is a guess; the second
  caller then needs a parameter, and the third needs a flag that changes the
  layout.
