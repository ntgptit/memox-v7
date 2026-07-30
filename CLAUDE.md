# memox-v7

Flutter application, rebuilt from scratch against `docs/checklist.md`.

**Stack:** Flutter (stable) · Riverpod 3.x + codegen · GoRouter · Drift/SQLite · Material 3 + design tokens
**Architecture:** Pragmatic Clean Architecture, feature-first.

## Reading order

Read these two before anything else, in this order:

1. **this file** — constraints that apply in every phase
2. **`docs/document-conventions.md`** — how documents are written and read: the
   MUST/SHOULD/MAY keywords, the required header, the templates, and the rule
   that one fact lives in exactly one place

Then, only what the task actually touches:

`docs/product.md` → `docs/architecture.md` (AD-xx) → `docs/business-rules.md`
(BR-xx) → `docs/data-model.md` → `docs/use-cases.md` (UC-xx) → `docs/wbs.md`.

`docs/checklist.md` is reference — look things up, do not read it end to end.

Two rules that prevent the most damage:

- **Prose without a MUST/SHOULD/MAY keyword is explanation, not a rule.** Do not
  derive a new constraint from it, and do not treat a code example as a spec.
- **Do not edit a document whose Status is `frozen for MVP`** unless the task
  names that file explicitly. Those documents are the contract the code is
  written against; a convenience edit made while doing something else is how
  spec and code drift apart without anyone noticing.

## What memox is, and what it is not yet

Flashcard / spaced-repetition vocabulary app. The decisions below are settled;
the reasoning and the full consequences are in `docs/architecture.md` (AD-01…08),
and they are the ones most likely to be violated by accident:

- **Local-first, backend-ready.** Drift is the source of truth; repositories read
  from `watch()` streams. A Spring Boot backend comes later — the repository
  contract exists so that it can, without `domain/` or `presentation/` changing.
  Never let a Drift-generated type serve as a domain entity; that is exactly what
  destroys this property, and it only shows up when the backend lands.
- **SQL lives in `.drift` files**, not Dart table classes, so `drift_dev`
  type-checks queries at build time.
- **No auth yet, auth-ready.** One local profile. Tables carry a nullable
  `owner_id`; IDs are client-generated UUIDs from day one. No login screen, no
  token storage, no `AuthRepository` — do not build them.
- **No network yet.** `dio` is deliberately not a dependency. Add it with the
  first real request.
- **Android is the release target.** Web must keep building because it is the
  E2E channel (Flutter Web + Playwright), but it is not a production target.
  iOS is deferred.
- **Decks nest up to 10 levels — the root is level 1 — and each holds one kind
  of thing.** Creating or moving a deck past level 10 is refused before
  anything is written (BR-55). A root deck holds only sub-decks — never cards.
  A new sub-deck starts `content_type = unset`; the first child created sets it
  to `card` or `deck`, and from then on it holds only that. Emptying a deck
  does not reset the type; that is a separate confirmed action. Resolve the
  root via `root_deck_id` — **never** `COALESCE(parent_deck_id, id)`, which
  silently returns the wrong deck from the third level down.
- **Scheduler belongs to the root deck and is locked after the first review.**
  MVP ships both `eight_box` and `sm2`; every root deck must pick one at
  creation. Every descendant inherits type, version and generation. After the
  first `scheduled` review the choice is locked — changing it requires Reset
  learning progress. Moving a subtree under a root with a different scheduler or
  generation is blocked, never silently converted.
- **`review_kind` and session `status`/`end_reason` are stored, never inferred.**
  Deriving `review_kind` by diffing before/after state is wrong for a `scheduled`
  review of a box-8 card, and history written with the wrong label cannot be
  recomputed later.
- **The two schedulers have different action sets** — `eight_box` uses
  `forgotten`/`remembered`, `sm2` uses `again`/`hard`/`good`/`easy`. The review
  UI renders buttons from the scheduler's `supportedActions`; hardcoding four
  buttons is wrong for half the decks.
- **`scheduler_generation` is on the deck, the card state, the session and every
  history row.** Reset increments it. A review written from a session whose
  generation is stale must be rejected, not applied — otherwise a reset silently
  un-resets itself.
- **Content, schedule and history are three tables.** `cards` holds content only
  — no SRS columns, no generation; content survives every reset.
  `card_review_states` holds the schedule, `review_history` is append-only and is
  kept across resets. Editing a card must never touch a review state.
- **Reset and scheduler change run in one Drift transaction.** A deck must never
  have two active schedulers, or card state from two generations.
- **Starter decks are templates; users get a copy.** Template updates never
  overwrite a user's copy, and re-opening the app never creates a duplicate.
- **Private data is broader than it looks:** card content, notes, learning
  history, imports, media and backups. Never log card content at any level.
  Media lives in the app-private directory. Export only on explicit request.

Deliberately deferred, and cheap to add later because migration testing is in
place from the start: sync bookkeeping columns (`isPendingSync`, `version`),
SM-2 parameters, database encryption.

## Before anything runs

Generated code is not committed (`.gitignore` explains why). A fresh clone will
not analyze, test or run until you generate it:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

Hundreds of analyzer errors right after cloning almost always means this step
was skipped, not that the code is broken.

## How work is driven here

`docs/checklist.md` is the canonical 22-phase plan. `docs/wbs.md` is the live
progress ledger — it is the single source of truth for what is done, in flight,
and blocked. Update it in the same commit as the code it describes; a WBS that
lags the code is worse than no WBS, because the next session trusts it.

The `.claude/skills/` directory holds one skill per area of the checklist. Start
with **flutter-workflow** when you do not know which phase you are in — it routes
to the right skill and refuses to let phases run out of order.

Phases run in dependency order, not checklist order: business requirements →
use cases → WBS → foundation → architecture boundaries → theme/tokens → minimal
shared components → router → data foundation → features as vertical slices →
tests → CI/CD → release. Do not build UI for a flow whose business rules are
still open; the rework costs more than the wait.

## Non-negotiables

These are the rules that survive every phase. Everything else is guidance.

**Layering.** `domain/` imports no Flutter, no Dio, no Drift — only Dart and
other domain code. If a domain file needs `package:flutter`, the abstraction is
wrong. `data/` implements domain contracts. Features never import another
feature's `data/` or `presentation/` internals.

**The dependency direction is `presentation → domain use case → domain contract ←
data impl`** (AD-12). A controller calls a use case; it does **not** read a
repository. Each feature is laid out as:

```
lib/features/<feature>/
├── domain/       entities/ · repositories/ · models/ · usecases/ · failures/
├── data/         repositories/ · mappers/ · datasources/ · models/
└── presentation/ screens/ · controllers/ · states/ · widgets/ · providers/
```

Plural folder names, and **the folder does not replace the suffix** —
`entities/deck_entity.dart`, not `entities/deck.dart`. The guards match on the
file name, and several of their scopes select files by it, so a mis-suffixed file
silently leaves the scope of the rules meant to cover it.
`check_architecture.sh` pairs each folder with the suffix it admits.

**A use case per interaction**, and this overrides the older "only when it holds
real logic" guidance: uniformity is what makes a new feature a clone rather than a
judgement call at every operation. Six of Deck's ten hold the input validation
that used to run twice — once in a controller and again in the repository. The
four read ones are thin, and that is the accepted cost (AD-12).

**What must NOT move into a use case:** any rule that needs the data *as it stands
at the moment of writing*. Depth limits, first-child locks, emptiness checks and
subtree moves run inside `runInTransaction`; hoisting them above the repository
puts the check outside the transaction, which is a race between the check and the
write. The rule would be in a tidier place and be wrong.

**`presentation/providers/` is dependency wiring only.** Anything holding state or
a command is a `_controller`. The distinction decides which guard rules apply, so
it is not stylistic.

**Control flow.** Guard clauses, early return, fail fast. Avoid `else` — an
`else` branch usually means a guard clause was skipped. Never swallow errors
with `catch (_) {}`; if a failure is genuinely ignorable, catch it narrowly and
say why in a comment.

**No magic values.** Strings and numbers that carry meaning belong in a const, an
enum, or a sealed class. Finite states are enums or sealed classes, never loose
strings or a pile of booleans.

**UI discipline.** No business logic in `build()`. No API calls or database
access from a widget. No hardcoded colors, text styles, or padding — everything
comes from design tokens. No user-visible string outside the ARB files.

**State.** Immutable. Data and task-status are separate concerns — one
`isLoading` boolean for every operation on a screen is a bug waiting to happen.
Controllers never hold a `BuildContext`.

**Errors.** Data-layer exceptions map to a domain `Failure` at the repository
boundary. The UI never sees a `DioException`. User-facing messages never leak
stack traces, URLs, or SQL.

**Security.** Tokens live in secure storage and are cleared on logout. No
secrets in the repo. No sensitive data in logs, at any level.

## Naming

Files are `snake_case` with a suffix that states the role. The suffix is
load-bearing, not decoration: guard scopes select files by it, so the wrong
suffix removes a file from the rules meant to cover it.

| Layer | Allowed suffixes |
|---|---|
| `domain/` | `_entity` · `_repository` · `_use_case` · `_model` · `_failure` · `_scheduler` |
| `data/` | `_repository_impl` · `_mapper` · `_dao` · `_data_source` · `_model` · `_loader` |
| `presentation/` | `_screen` · `_controller` · `_state` · `_widget` · `_provider` · `_page` · `_view` |

Two that bite:

- a file holding a provider is `_controller.dart` when it holds state or a
  command, and `_provider.dart` only when it does dependency wiring;
- a `presentation/` file with no widget in it still needs one of these suffixes.
  Deck's `deck_labels_widget.dart` holds a `BuildContext` extension and keeps
  `_widget` deliberately — renaming it to `_extension.dart` was tried and reverted
  because it dropped the file out of the widget scope.

Booleans read as predicates: `isX`, `hasX`, `canX`, `shouldX`. Avoid `Utils`,
`Manager`, `Helper` unless the responsibility is genuinely that and is named
precisely.

## Definition of Done

No task is done until: scope matches the WBS entry, acceptance criteria pass,
`dart format` clean, `flutter analyze` clean (zero errors *and* warnings),
related tests pass, UI uses tokens and was checked in light + dark + small
screen + large text scale, loading/empty/error/success all covered, basic
accessibility checked, docs and WBS updated, CI green.

Run `.claude/skills/flutter-workflow/scripts/dod_check.sh` for the mechanical
half of that list. The judgement half is still yours.

## Commits

Conventional Commits: `feat(auth): ...`, `fix(sync): ...`, `chore(deps): ...`.
Scope is the feature name. Keep PRs small and single-purpose — no drive-by
refactors outside the stated scope.
