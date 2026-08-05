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
- [ ] **API contract known** — N/A while AD-05 holds (no remote API in MVP;
      `docs/api-spec.md` deliberately does not exist yet). When the backend
      lands: endpoints, shapes, error format, pagination there first, and build
      against a fake implementing the same interface.
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
├── entities/       <name>_entity.dart
├── repositories/   <name>_repository.dart          # abstract contract
├── models/         <name>_model.dart               # read model / value object / enum
├── usecases/       <verb>_<noun>_use_case.dart     # only when warranted
└── failures/       <name>_failure.dart             # only when feature-specific
```

**The folder does not replace the suffix.** `entities/deck_entity.dart`, not
`entities/deck.dart`: the role is carried by the *file name*, which
`memox.naming.domain_file_role_suffix` enforces and which several guard scopes
select on. `check_architecture.sh` additionally pairs each folder with its
required suffix. See `assets/feature_blueprint.md` — it is the authority on
layout, and this block is a summary of it.

- Entities are immutable, with value equality, in domain language. Entity state
  is the enum or sealed class from `docs/business-rules.md`, so illegal states
  are unrepresentable rather than merely unlikely.
- The repository contract is written from what presentation needs, not from what
  the API happens to offer. If the API needs three calls for one screen, the
  contract still has one method and the implementation makes three.
- Business validation belongs here — it is the same regardless of UI, and here
  it can be unit-tested without a widget or a server.
- **One use case per interaction** (AD-12). It takes the repository *contract*,
  never an implementation, and it is where the input validation lives — a
  controller that validates and a repository that validates the same rule again
  is the shape this replaced.
- **A rule that needs the tree as it stands at the moment of writing stays in the
  repository**, inside `runInTransaction`. Depth limits, content locks, emptiness
  checks, subtree moves. A use case above the repository would put the check
  outside the transaction, which is a race between the check and the write.
- **A pass-through use case with optional parameters must forward every one of
  them, and gets a test proving it.** Optional params have defaults, so a
  dropped `sort:` or `searchTerm:` compiles clean and analyzes clean — the
  card list shipped exactly this ("Showing 3 of 1", inert sort control) and
  only end-to-end runs caught it. The lock is cheap: a fake repository that
  records every parameter it receives, one assert per param
  (`watch_card_list_items_use_case_test.dart` is the template).

## Step 2 — Data

Details: `flutter-data-layer`.

```
features/<feature>/data/
├── repositories/   <name>_repository_impl.dart
├── mappers/        <name>_mapper.dart              # Row → Entity, AggregateResult → ReadModel
├── datasources/    <name>_dao.dart
└── models/         <name>_model.dart               # DTOs — none exist yet
```

`models/` is present and empty on purpose: **there is no DTO layer**. `dio` is
deliberately not a dependency (AD-05), Drift is the source of truth (AD-01), and a
DTO would be a second shape for data that already has two. It gets files with the
first real request, not in anticipation of one.

Order: the DAO first, then the mapper, then the repository. The repository is
where Drift exceptions become `Failure`s — nowhere else. **There is no cache or
sync policy to apply.** Reads come from `watch()` streams straight off the table;
sync bookkeeping is deliberately deferred (AD-01), so a cache layer here would be
a guess at a requirement that does not exist.

SQL goes in `.drift` files so `drift_dev` type-checks it at build time (AD-02).
No business SQL in Dart. Multi-step writes run inside `dao.runInTransaction`, and
every guard that can refuse runs *before* the first mutation.

## Step 3 — Presentation

Details: `flutter-state-riverpod` for state, `flutter-design-system` for UI,
`flutter-navigation` for routes.

```
features/<feature>/presentation/
├── screens/        <name>_screen.dart
├── controllers/    <name>_controller.dart
├── states/         <name>_state.dart
├── widgets/        <section>_widget.dart
└── providers/      # only when a provider is not a controller
```

MX-VIS-001 derives each screen's required audit path by stripping **only** the
`presentation` segment, so the `screens/` folder is preserved in the companion
path: `test/visual_audit/screens/features/<f>/screens/<name>_visual_audit_test.dart`.
A file holding a provider must still be named `_controller.dart`, not
`_provider.dart` — the guard's widget scopes forbid
`ref.watch(...RepositoryProvider)` and exempt controllers by that suffix, which is
where that read belongs.

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
      Pure input/output — no database, no widget.
- [ ] Repository tests against **real in-memory SQLite**, not a mocked executor.
      What is in doubt is the SQL: the cascade, the transaction rollback, the NULL
      semantics of a predicate. A mocked data source would only prove the code
      calls the API it was written to call, which is the one thing nobody doubts.
      Use `test/database/support/test_database.dart` and a per-feature harness.
      There is no cache fallback to cover — see Step 2.
- [ ] Mapper tests, including a null field and an unknown enum value.
- [ ] Controller tests: initial state, loading→loaded, loading→error, refresh,
      submit success, submit failure, duplicate submit.
- [ ] Widget tests for the states that matter — at least loaded, empty, error —
      against a **fake of the domain contract**, not a real database. Driving Drift
      from a widget test leaves its stream-notification timer pending at teardown
      and `flutter_test` fails the test for that rather than for the behaviour.
- [ ] Route tests through the real router: cold start, deep link, back, and the
      branch state if the route sits in the navigation shell.
- [ ] A strict visual audit companion per production screen (MX-VIS-001), one
      call per state, PASS in light and dark.
- [ ] Golden tests if this feature added a shared component.
- [ ] Every new screen registered in the Widgetbook catalog (`widgetbook/`): a
      use-case that mounts the screen inside a `ProviderScope` with the domain
      contract faked, knobs selecting the states worth looking at (empty, a
      few items, long Vietnamese names, error). A new shared component gets a
      knob-driven playground there too. This is the human-inspection
      counterpart of the audits above — the machine checks catch overlap and
      contrast, the catalog is where a person turns the viewport and theme and
      *looks*. `widgetbook/README.md` has the how-to.

`assets/feature_blueprint.md` has the table of which test belongs at which level,
and the counts the Deck slice ended up with as a size reference.

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
