# memox-v7

Flutter application, rebuilt from scratch against `docs/checklist.md`.

**Stack:** Flutter (stable) · Riverpod 3.x + codegen · GoRouter · Drift/SQLite · Material 3 + design tokens
**Architecture:** Pragmatic Clean Architecture, feature-first.

**`AGENTS.md` exists for agents that load that filename instead of this one, and
it is a pointer — keep it one.** Nothing in this file is Claude-specific, so the
moment `AGENTS.md` starts restating a rule there are two contracts, and the one
nobody edits is the one somebody follows.

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
  to `card` or `deck`, and from then on it holds only that. **Emptying a
  sub-deck puts it back to `unset`** — the system maintains the type in the
  same transaction as the delete or move that removed the last direct child
  (BR-163); there is no manual reset. A root deck stays `deck` forever. Resolve the
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

**Deck and Card are the two worked examples. Read them before building a third
feature** — `.claude/skills/flutter-feature-slice/assets/feature_blueprint.md`
first, then `lib/features/deck/README.md` and `lib/features/card/README.md`.

What transfers is the **method**: how a slice is layered, where a rule is
enforced, what a use case is allowed to know, how a failure carries its reason,
which test sits at which level. What does **not** transfer is either feature's
business — the deck tree, `content_type`, scheduler-on-root, the card's flag and
tags all exist because those features needed them, and a feature that does not
need them and grows them anyway has copied the wrong half (AD-17).

Two examples rather than one on purpose: a single reference cannot tell "this is
the method" apart from "this is how that feature happened to be built". Where
Deck and Card differ, the difference is the answer — `card/README.md` records
what Card did differently and why it was still right.

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
├── di/           one provider per contract the feature needs
└── presentation/ screens/ · controllers/ · states/ · widgets/ · providers/
                  widgets/ holds exactly four buckets, one level deep:
                  sections/ · items/ · overlays/ · support/   (AD-15)
```

**`widgets/` is bucketed, and the bucket list is fixed.** A widget sits in
`sections/` (a band the screen composes), `items/` (the repeated row and its
parts), `overlays/` (sheets, dialogs, forms and their `showX` functions) or
`support/` (presentation mapping used across buckets) — never directly in
`widgets/`, never deeper, never in a fifth name. AD-15 owns the contract and
the placement questions; `architecture_boundary_test.dart` and the guard's
`widgets_grouped_into_buckets` rule both enforce it, so an invented folder
fails the suite rather than becoming a precedent.

**`features/` never imports `app/`** (AD-13). The composition root sees a feature;
the reverse makes a feature depend on the shell it happens to be mounted in, and
cloning it then means editing `app/` too. So `di/` declares the provider as the
*domain contract* and `app/di/repository_bindings.dart` binds the implementation;
a constant both the router and a screen speak — a route name — lives in `core/`.
`check_architecture.sh` rule 4b and `test/app/architecture_boundary_test.dart`
both enforce it.

Plural folder names, and **the folder does not replace the suffix** —
`entities/deck_entity.dart`, not `entities/deck.dart`. The guards match on the
file name, and several of their scopes select files by it, so a mis-suffixed file
silently leaves the scope of the rules meant to cover it.
`check_architecture.sh` pairs each folder with the suffix it admits.

**A use case per interaction**, and this overrides the older "only when it holds
real logic" guidance: uniformity is what makes a new feature a clone rather than a
judgement call at every operation. Six of Deck's ten apply the input validation
that used to run three times — in a controller, again in the repository, and a
third time in the widget that re-derived which field was wrong. The four read ones
are thin, and that is the accepted cost (AD-12).

**One interaction is not one statement** (AD-13). A screen that needs two facts at
once gets **one** read returning both, not two use cases composed in a controller —
two reads are two snapshots, and the screen can then render one fact from before a
write and the other from after it. A count that expires carries its expiry from the
same statement.

**An input rule belongs to a type, not a layer** (AD-13). Moving validation into
one layer stops it being duplicated by convention; moving it into a value object
with a private constructor stops it structurally, and the repository contract's
signature then answers "has this been validated?" without anyone reading the
implementation.

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
Controllers never hold a `BuildContext`; `command_query_separation_test.dart`
checks that by parsing the AST, because the words appear in the prose of every file
that explains the rule.

**Nothing in a feature reads the wall clock.** `clockProvider` is passed in from the
composition root, and `lib/features/` contains no `DateTime.now()`. A private
fallback inside a repository made "now" two things — a provider the whole tree can
override, and a static nothing can reach — and the unreachable one is what wins in
production (AD-13).

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
| `domain/` | `_entity` · `_repository` · `_use_case` · `_model` · `_failure` · `_scheduler` · `_mode` |
| `data/` | `_repository_impl` · `_mapper` · `_dao` · `_data_source` · `_model` · `_loader` |
| `di/` | `_provider` · `_bindings` |
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
accessibility checked, every new screen and new shared component registered in
the Widgetbook catalog (`widgetbook/` — see its README), docs and WBS updated,
CI green.

Run `.claude/skills/flutter-workflow/scripts/dod_check.sh` for the mechanical
half of that list. The judgement half is still yours.

### A change a person can see ends in the gallery

`test/demo/` is the only picture this project has of itself — the real screens
on a real device size, committed as PNGs. **When a change moves any of them,
regenerate the goldens and republish the gallery in the same turn:**

```bash
flutter test --tags golden --update-goldens
python .claude/skills/flutter-testing/scripts/build_screen_gallery.py
```

Then publish `build/screen_gallery.html` as an Artifact **at the existing
URL** — https://claude.ai/code/artifact/e8a68227-1582-407c-88c2-ff25d66bd9d8 —
so the owner's tab keeps showing the current app instead of a fork of it.
Publishing without that URL makes a second gallery, and two galleries mean
nobody knows which one is the app.

**Why this is a rule and not a courtesy.** A screenshot the owner is reviewing
against is a claim about what shipped, and a stale one is a wrong claim that
looks right — the failure mode that cost this project four review rounds on
one screen. The gallery reads the *committed* goldens and renders nothing
itself, so regenerating them first is not optional: build it from stale PNGs
and it is confidently wrong.

The page carries the commit it was built from in its header, which is what
makes a stale tab recognisable rather than merely wrong.

During the inner loop, `.claude/skills/flutter-workflow/scripts/dod_check.sh
--changed --base origin/main` MUST build the same immutable feature × layer ×
risk verification plan used by PR CI. It runs only the selected host tests and
Widgetbook surface. Layer ownership provides the starting set; reverse Dart
imports add app, integration and cross-feature test consumers, and existing
untracked tests are discoverable locally. Golden-only changes use runnable
non-golden surrogates **locally**, because the local loop excludes the golden
tag; **pixel comparison is a PR gate now** — `ci.yml` runs `goldens (windows)`
whenever the plan sets `needs_goldens`, which any code change or any change to
`test/demo/` does. It used to live only in `ci-full.yml`, which is
`workflow_dispatch:`, so nothing compared a committed PNG against a fresh
render unless a person remembered: #337 relaid out six components, committed no
goldens, went green, and left 26 stale pictures on `main`. Unknown
paths and schema/shared/router/native/tooling changes promote themselves to the
full non-golden host suite. A selected mandatory tool or guard missing from the
environment MUST fail rather than report a skip. The default command without
`--changed` remains the final full local gate; targeted success is not release
evidence.

### A new feature means re-running the integration suite, on a device

**Adding anything under `lib/features/` is not done until `integration_test/`
has been run on an emulator and is green.** CI does not run it and deliberately
will not: an Android emulator on a GitHub runner costs 30–45 minutes a run and
is the flakiest thing in a pipeline, which buys less than it costs. So this is a
local gate, and it is on you.

```bash
flutter test integration_test/ -d emulator-5554 --flavor development
```

The flavor is required — the app has three and Gradle produces no APK without
one. The baseline is **8 passing, 0 failing**; anything less is a regression
until proven otherwise, against `origin/main` and not against a hunch.

**Eight, not sixty-seven, since the testing-pyramid refactor.** Business
correctness moved to `flutter test`, which CI runs on every PR — 133 of 133
scenarios in `docs/it-scenarios/14-host-coverage-map.md`. What is left on a
device is what a host cannot reach: the engine's bootstrap, a real file on
device storage, an OS deep link, Android's back gesture, and a release build
that does not run. A scenario added here that walks a business rule is in the
wrong place, and it is the copy that rots — it stays green while the rule
changes underneath it, because nobody looks at a device suite until it is
already red.

**This rule exists because the suite was broken for seventy PRs and nobody
knew.** It was recorded 60/60 green, and by the time it was next run it was
0/66. Three causes, none of them a test being wrong:

- a startup fixture seeder copied the shipped decks back **one frame after** the
  suite wiped the database;
- `deckRepositoryBinding` grew a dependency on a second feature's contract, and
  a hand-written binding list in the test harness did not have it — so every
  scenario threw in `setUp`;
- the schema's `learned_at` split (BR-90, BR-151) changed what "due" means, and
  the fixture that simulates a learned card was never updated.

Every one of them is *a rule or a wire changed, and the thing that simulates it
did not follow* — which is exactly what a unit test cannot see and an
integration test exists to catch. All three passed `flutter analyze`, the full
unit suite and the guard on the way in.

**`lib/app/` counts too, and that is where two of the three came from.** A
binding, a startup widget or a route touches every feature at once; the suite is
the only thing that notices.

## Commits

Conventional Commits: `feat(auth): ...`, `fix(sync): ...`, `chore(deps): ...`.
Scope is the feature name. Keep PRs small and single-purpose — no drive-by
refactors outside the stated scope.

**Sync with `main` before merging, and delete the branch only after.** Work here
runs in worktrees and PRs land while you work, so the base you branched from is
usually not the base you are merging into:

```bash
git fetch origin --prune
git merge-base --is-ancestor origin/main HEAD || git merge origin/main
```

Diverged means resolve, then **run the gate again** — `flutter analyze`,
`flutter test`, the guard, `check_docs.py` — because the run that passed against
the old base says nothing about the new one. When the merge-base is older than
you thought, resetting onto `origin/main` and re-applying is often cleaner than
resolving: `docs/wbs.md` is the file two PRs touch most, and a rebuild also picks
up documents that landed meanwhile.

Then merge, **confirm it merged**, and only then delete:

```bash
gh pr merge <n> --squash
gh pr view <n> --json state -q .state      # must print MERGED
git push origin --delete <branch>
```

Deleting the branch first makes GitHub auto-close the PR, and a PR closed that
way **cannot be reopened** — the only way forward is a new PR. This has cost two
PRs already (#160, #173). Do not use `gh pr merge --delete-branch` as a shortcut:
it also fails outright when `main` is checked out in another worktree, which is
the normal state here.

**Never force-push a branch a cloud session is working on.** A session started
from the phone or the web clones this repository fresh and checks out the
**commit** it was started at, not the branch name. Force-pushing rewrites that
branch's history and orphans the old tip: the branch still exists, the SHA no
longer resolves, and every later attempt to open that session dies at
`The requested branch or commit was not found in the repository` — after the
clone step has already reported success, which is what makes it read like a
network fault instead of a ref problem.

The orphaned commit survives only in whichever local clone happened to fetch it
before the force-push, and only until `git gc` runs there. Push it back before
touching anything else:

```bash
git push origin <sha>:refs/heads/rescue/<what-it-was>-<sha>
git clone --bare <repo> /tmp/verify.git && git --git-dir=/tmp/verify.git cat-file -t <sha>
```

`git fetch` names the damage in passing and it is easy to read past — the `+`
and the `...` are the whole signal:

```
 + edcd3558...df536ea3  claude/app-theme-review-vc0mha -> origin/...  (forced update)
```

**Local-only branches are invisible to a cloud session too.** It resolves
everything against the remote, so a worktree branch that was never pushed —
including whatever the *primary* checkout happens to be sitting on — cannot be
a base. Keep `D:/workspace/memox-v7` on `main`, and check with
`git worktree list` against `git ls-remote --heads origin` when a session will
not start.
