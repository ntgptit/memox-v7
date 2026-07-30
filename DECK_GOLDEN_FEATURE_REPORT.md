# Deck Golden Feature Hardening Report

## Commit reviewed

| | |
|---|---|
| Base commit | `d53f9349244a5e7612564675bb9110c52a4ec4f6` (`main`) |
| Branch | `feat/deck-golden-hardening` |
| Head | `d3e0ca1` |
| Commits | 9 |
| Baseline | 788 tests, `flutter analyze` 0 issues, guard 0 violations, **no CI** |
| Now | 844 tests, `flutter analyze` 0 issues, guard 0 violations, CI on PR + `main` |

Every defect below was passing every test that existed. None of them was found by a
failing check; all were found by reading the code as a stranger would and then
building a check that could tell the two designs apart.

---

## Changes completed

### 1 · BR-01 has one owner, and it is a type

`DeckEntity.nameProblem` and `DeckEntity.validateName` are gone. `DeckName`
(`domain/models/deck_name_model.dart`) has a private constructor and a `parse` that
returns either the value or a typed `DeckValidationProblem`, so an invalid deck name
cannot be constructed. The repository contract takes a `DeckName`, so "has this been
validated?" is answered by the signature.

**It ran three times, not twice.** The use case called it, the repository called
`validateName` again, and the screen re-derived the problem from the raw text to
decide which field to mark.

**Why the screen was re-deriving** is the part worth carrying forward.
`ValidationFailure` carried `Map<String, String> fieldErrors`, and *both halves were
wrong*: the key was a repeated string literal nothing checked, and the value was a
human-readable message the UI is forbidden to render — so presentation ignored the
value and computed the answer itself. It is now `Set<Enum> problems`. `Enum` because
`core/` may not import a feature; on the base class because `Failure` is `sealed`, so
a feature cannot add a subtype.

One attempt reports every wrong field: a blank name *and* an unchosen scheduler come
back together, which a single `Failure.reason` could not express.
`deckSubmitFailure` now takes only the `Failure`, so re-deriving cannot be
reintroduced without changing its signature.

**Acceptance:** `grep 'schedulerType'|fieldErrors` in `lib/` → empty.
`grep validateName|nameProblem(` in `data/` + `presentation/` → empty. Copy stayed
in ARB; no key changed.

### 2 · `DeckDetail` is one coherent read

`Stream<DeckDetail> watchDeckDetail(String deckId)` — one `LEFT JOIN` in
`deck.drift`, one contract method, one `WatchDeckDetailUseCase`. `deckDetailProvider`
composes nothing. `DeckDetail` moved from the controller to `domain/models/` because
the repository returns it.

The screen used to watch `childDecks` and then await `getDeckById` per emission,
under a comment claiming the two facts "arrive together". They did not. The action
set is computed from `content_type` **and** from the children being empty (BR-68), so
a rename or a create landing between the reads produced a screen assembled from two
instants.

No rows → `NotFoundFailure`; one row with a null child → the deck exists and has no
children. Those two must stay distinguishable: one is a dead route, the other an
empty state.

**Acceptance:** `deck_detail_read_test.dart` counts SQL statements through a real
`QueryInterceptor` — 11 tests covering initial read, child ordering, rename, add
child, delete child, move child away, `mayOfferReset` following the same emission,
never-existed, and deleted-while-watched.

### 3 · The move-target stream has no second query

`watchAllDecks` is unfiltered by contract, so the deck being moved is already in
every emission. The use case asked for it again anyway, per emission, from a later
snapshot — so `buildDeckMoveTargets` could take depth and subtree membership from one
tree and the source from another. The source now comes from the list it is given;
absent means deleted elsewhere, which is a typed `NotFoundFailure` rather than an
empty picker.

`watchChildDecks`, `getDeckById` and the `childDecks` .drift query are deleted from
the contract, the DAO and the fake. After both changes nothing called them, and dead
surface in a reference implementation is what gets cloned.

**Acceptance:** `watch_deck_move_targets_test.dart` asserts one repository read per
subscription and three emissions costing three reads, not six.

### 4 · The due count refreshes when a card comes due

`rootDeckSummaries` returns `nextDueAt` — `MIN(due_at) WHERE due_at > :now`, a scalar
subquery in the same statement as the counts, one index seek through
`idx_review_states_due`. `RootDeckList` arms a single one-shot `Timer` for it; when it
fires, `DeckListNow` moves, the query re-runs at the new instant, and the next
emission arms the next timer. Never more than one pending, none at all when nothing
is scheduled, none after the screen closes. Resume still refreshes.

The old comment said a periodic timer had been "considered and rejected" because
resume catches the same boundary. It does not: a user sitting on the list when a card
came due saw a badge saying 3 while the session it launches handed out 4.

`> :now` **strictly**. A card due exactly at `:now` is already counted as due, so
including it would make the delay zero, the guard against a zero-delay timer would
refuse to arm, and the genuinely-next boundary would never get a wake-up — the same
staleness, reintroduced by one character. There is a test for that character.

`kMaxDueBoundaryDelay = 1 day` is a **ceiling, not an interval**: on the web a
`Timer` is `setTimeout`, whose delay is a 32-bit signed millisecond count, so a
boundary past ~24.8 days fires immediately and becomes a busy loop. Web is the E2E
channel.

**The clock has one owner.** Both repository implementations defaulted their clock to
`DateTime.now()`. That made "now" two things — a provider the whole tree can override,
and a private static nothing could reach — and the unreachable one is what wins in
production. `clock` is required, the fallbacks are gone, `app/di/` passes
`clockProvider`, and `lib/features/` contains no `DateTime.now()`.

### 5 · Documentation matches the code

`docs/architecture.md` gains **AD-13** with the full decision record. Corrected in
`AD-12`, `CLAUDE.md`, `feature_blueprint.md`, `feature_checklist.md`,
`lib/features/deck/README.md`, `flutter-project-setup/SKILL.md`,
`flutter-data-layer/references/networking.md` and `docs/wbs.md` (M4.10b, all nine
template fields; superseded claims struck through in the ledger's existing
convention rather than edited to look as if they were never made).

Three claims were false rather than merely stale: the "arrive together" comment, the
"periodic timer considered and rejected" comment, and the blueprint's advice to "fix
the rule upstream in the guard repository, which this repo may not edit" — the guard
is vendored *here*, and two of its rules were false-positive on prose.

**The nine-step submit flow** is written out in the blueprint and the deck README:

1. widget calls `submit` with the raw text;
2. controller returns unless `state.canSubmit`;
3. controller sets `isSubmitting: true`, clearing the previous attempt;
4. controller calls the use case with the **raw** string — no validation, no trim;
5. use case parses into the value object, collecting *every* problem, and throws one
   `ValidationFailure` carrying the whole `Set`;
6. use case calls the repository with validated values;
7. repository runs inside `_guard`, and `runInTransaction` when multi-step: the rules
   needing the tree at write time (BR-55, BR-62, BR-68, UC-09) and the mapping of any
   driver exception to a `Failure`;
8. controller checks `ref.mounted`, then sets `outcome` or `deckSubmitFailure(...)`;
9. widget renders ARB copy from the problems or `failure.reason`, and performs the
   side effect once, on the transition.

The controller owns 2, 3 and 8. The list exists because five of the other six are the
parts people put in a controller by reflex.

### 6 · The command/query guard parses an AST

`command_query_separation_test.dart` uses `package:analyzer`. The regex version cost
real coverage twice: it counted public methods **per file** (a file holding a query
controller and the input-state notifier it reads looked like one class with four
methods, so it failed on correct code), and it forbade the *word* `navigateTo`
wherever it appeared — including in the comment explaining the rule.

The AST made a distinction possible that regex could not: there are **three** kinds of
notifier, not two.

| kind | identified by | allowed |
|---|---|---|
| command controller | `build` returns a `SubmitState` | `build`, `submit`, `reset` |
| query controller | `build` returns a `Stream`/`Future` | `build` |
| input-state notifier | anything else | `build` + at most one mutator |

Two new rules: forbidden names (`select*`/`search*`/`navigate*`/`show{Error,Snack}*`)
checked against **declared member names** only, and no controller or use case may
name `BuildContext` in any type annotation — a name can be worked around, a type
cannot.

A seventh check runs last on counters the others fill in and prints them:
`{usecases: 10, controllers: 8, command controllers: 6, query controllers: 1,
input-state notifiers: 1, controller and use-case members: 45}`. Zero in any of them
is a failure.

`analyzer` is now a declared dev dependency; it was reachable transitively through
`build_runner`, which a `build_runner` upgrade could remove.

### 7 · `features/` no longer imports `app/`

Two directions were wrong. `presentation/providers/` imported
`app/di/deck_repository_provider.dart`, and two screens imported
`app/router/route_names.dart`.

**The repository provider inverts.** `features/deck/di/deck_repository_provider.dart`
declares it as the domain contract with a body that throws;
`app/di/repository_bindings.dart` supplies the implementation and `buildRootWidget`
installs it with one line. Cloning no longer starts by editing `app/`, and a forgotten
binding fails at the root rather than inside the new feature.

It landed in `presentation/providers/` first and `provider_convention_test.dart`
rejected it — nothing under `features/*/presentation/` may be `keepAlive`. That rule
is right and the placement was wrong: this is the feature's dependency seam, so it
gets its own layer. `autoDispose` was the alternative and would rebuild the repository
on every navigation.

**`RouteNames` + `RoutePathParams` moved to `core/navigation/`.** Inverting was not an
option: a route belongs to the table, not to one screen, so the router cannot take its
names from the features. They are a vocabulary neither side owns — the `clockProvider`
argument. `RoutePaths` deliberately stayed in `app/router/`: a path is the app's URL
contract and only the route table asserts it.

**Enforced by** `check_architecture.sh` rule 4b and
`test/app/architecture_boundary_test.dart`. The Dart version strips comments before
matching, because this file's own prose names `lib/app/`.

**Accepted trade-off:** a missing binding is a `StateError` on first read rather than a
compile error. Bounded — the first read happens as the feature's first screen mounts —
and covered by two tests, one asserting the real root binds it and one asserting an
unbound read fails with a message naming where the binding goes.

### 8 · Riverpod pinned to the majors in the lock

`flutter_riverpod ^3.3.2`, `riverpod_annotation ^4.0.3`, `riverpod_generator ^4.0.4`
— from `pubspec.lock`, which did not change. They were all `any`, which is not a small
imprecision when the state layer is codegen against `$Notifier`, `@Riverpod(retry:)`,
`Notifier.listenSelf` and `noAutomaticRetry`.

`test/app/dependency_pinning_test.dart` makes it a gate: not `any`, a **caret** bound
whose major matches the lock, the two majors are the pair that go together, any
remaining `any` has a comment above it, and the checks read a real pubspec and a lock
with more than fifty entries.

Form rather than exact version, because pub already rejects a constraint it cannot
satisfy — the run aborts before any test executes. What resolves happily and is still
wrong is `>=3.0.0`.

### 9 · Every gate runs on CI

There was none. `.github/workflows/ci.yml` runs on `pull_request` and `push` to
`main`: `pub get` → generate → **generated-code check** → format → analyze →
architecture → guard → docs → 844 tests → test-count floor → goldens (+ failure
artifact), plus a parallel `web build` job.

`flutter-version-file: .fvmrc` rather than a hardcoded number, and
`--no-web-resources-cdn` on the web build — two technical-debt entries this repo had
recorded and that the first draft of the workflow was violating. Without the CDN flag,
Flutter fetches CanvasKit from `gstatic.com` at runtime even though it is bundled, so
in an environment that blocks the CDN the app silently fails to render.

**Generated-code staleness.** `.gitignore` said CI "fails if the tree is dirty" after
generating. It cannot: the output is gitignored. `check_generated.sh` is the mechanism
that claim needed — no generated file tracked, every declared `part` present, and a
clean rebuild byte-identical to the incremental one. It also runs in `dod_check.sh`
with `--skip-rebuild`.

**Counts and zero scope.** `check_architecture.sh` prints
`scanned 109 files under lib — features 54 (domain 27, data 10, presentation 16,
di 2)` and treats a zero as a violation. `check_generated.sh` prints three counts and
fails on zero declared parts. The AST guard prints its class counts. A `test count
floor` step fails below 700.

### 10 · Found during the final re-review: BR-11 had two owners too

`_requireRealScheduler` in the repository threw
`ValidationFailure(schedulerMissing)` for `SchedulerType.unknown`. Redundant —
`SchedulerType.unknown` has no `dbValue`, so the write was already *impossible* — and
the wrong kind of error: `unknown` comes only from reading an unrecognised database
value, so no form can create it, and "please choose a scheduler" would have answered a
programming error.

Removed. The use case owns "must be chosen"; the type owns "must be real". The
structural signal that this was right: `deck_repository_impl.dart` then no longer used
`deck_validation_failure.dart` and the analyzer reported the unused import. **The data
layer now references no validation rule at all.**

---

## Tests

| | baseline | now |
|---|---|---|
| `flutter test` | 788 pass | **844 pass** |
| `flutter analyze` | 0 issues | 0 issues |
| `check_architecture.sh` | clean (1 pre-existing large-file warning) | clean, same warning |
| code verification guard | 0 violations, 66 rules | 0 violations, 66 rules |
| `check_docs.sh` | clean | clean |
| `flutter build web --release --no-web-resources-cdn` | not run | succeeds |
| CI | **did not exist** | 2 jobs, 14 + 5 steps |

New test files:

- `test/features/deck/domain/deck_name_test.dart` — BR-01's own cases, including that
  the limit is measured after trimming and that re-parsing is idempotent
- `test/features/deck/domain/watch_deck_move_targets_test.dart` — repository call
  counts, source from the same emission, typed not-found
- `test/features/deck/data/deck_detail_read_test.dart` — statement counting through a
  real `QueryInterceptor`, plus the emission cases
- `test/features/deck/presentation/deck_submit_state_test.dart` — presentation reads
  problems, never derives them
- `test/features/deck/presentation/deck_list_now_controller_test.dart`
- `test/features/deck/presentation/root_deck_list_due_boundary_test.dart` — the timer,
  on fake time
- `test/app/architecture_boundary_test.dart`
- `test/app/dependency_pinning_test.dart`

Five `nextDueAt` cases were added to `deck_repository_summary_test.dart` *because* a
fault injection went undetected — see the table below.

---

## Fault injection evidence

Twenty-four injections. Every one was reverted, and the suite re-run green afterwards.

### The counting tests (task 2, 3)

| # | Injection | Result |
|---|---|---|
| 1 | reinstate the two-read shape in `watchDeckDetail` | the 2 counting tests failed with the second `SELECT * FROM decks WHERE id = ?1` in the message; **the other 9 behavioural tests passed** — which is the point |
| 2 | re-read the tree per emission in the move use case | 3 of 5 failed |
| 3 | return a placeholder instead of throwing for a missing source | exactly the 2 not-found tests failed |

### The due boundary (task 4)

| # | Injection | Result |
|---|---|---|
| 4 | never arm the timer | 2 of 5 boundary tests failed |
| 5 | arm but never cancel | 3 failed, including the two-timers case |
| 6 | remove the `kMaxDueBoundaryDelay` ceiling | the ceiling test failed |
| 7 | `>=` instead of `>` in the boundary SQL | **PASSED — a real gap.** 5 `nextDueAt` tests were added; re-injected, and it then fails on the exactly-at-now case and on the count parity |
| 8 | drop `.toUtc()` in the mapper | 2 failed |

Injection 7 also exposed a **live bug**: drift reads a stored `DateTime` back as a
*local* value, so `nextDueAt` reached the domain model in the wrong zone until the
mapper was corrected. Caught only because the new test compared instants.

### The DI boundary (task 7)

| # | Injection | Result |
|---|---|---|
| 9 | a screen imports `app/router/route_paths.dart` | shell rule 4b reported it |
| 10 | rename `di/deck_repository_provider.dart` to drop the suffix | suffix check warned |
| 11 | root drops the binding line | the bootstrap binding test failed |
| 12 | `di/` imports `data/repositories/deck_repository_impl.dart` | the implementation-leak test failed |
| 13 | point the boundary test at a directory that does not exist | failed rather than passing on an empty scan |

### The AST guard (task 6)

| # | Injection | Result |
|---|---|---|
| 14 | a use case grows a second public method | rule 1 failed |
| 15 | a command controller grows a second command | rule 2 failed |
| 16 | a query controller grows a command | rule 3 failed |
| 17 | an input-state notifier grows a second mutator | rule 4 failed |
| 18 | a controller declares `selectDeck` | rules 3 and 5 failed |
| 19 | a controller takes a `BuildContext` parameter | rules 3 and 6 failed |
| 20 | **control:** those same names in a comment only | **all seven passed** — under the old implementation this would have failed |
| 21 | the `/usecases/` path stops matching | rule 7 failed on the empty scan |

### Pinning, CI, and the guard rules (tasks 8, 9)

| # | Injection | Result |
|---|---|---|
| 22 | `flutter_riverpod: any` | 2 checks failed |
| 23 | `flutter_riverpod: ">=3.0.0"` — resolves cleanly | the caret check failed |
| 24 | `collection: any` with no comment | the unexplained-`any` check failed |
| 25 | break the lock parser's regex | 3 checks failed, including the coverage one |
| 26 | `riverpod_annotation: ^4.9.9` | **pub itself** failed version solving before any test ran — why the check tests form, not an exact match |
| 27 | `git add -f` a `.g.dart` | "generated file is committed" |
| 28 | delete a file a `part` declares | "declared part is missing" |
| 29 | break the `part` regex so nothing matches | "zero scope" |
| 30 | `LIB` at a missing directory with `pubspec.yaml` present | exit 1 — **it used to exit 0** |
| 31 | make the `/features/` counter match nothing | "zero scope: features" |
| 32 | a real `DateTime.now()` in a test | rule fired |
| 33 | **control:** a comment naming `DateTime.now()` | did **not** fire |
| 34 | real commented-out code (`// final legacy = …;`) | rule fired, twice |
| 35 | **control:** prose starting with `for` and `final` | did **not** fire |
| 36 | a real `part of` in `card_repository_impl.dart` | the boundary guard still fired after comment-stripping |
| 37 | test-output summaries of `+12` and of nothing at all | floor tripped on both |

The three control rows (20, 33, 35) are the ones that matter most: each is a case the
previous implementation reported as a violation, which is how a guard ends up
punishing the comment that explains it.

---

## Remaining risks

1. **CI has never executed on GitHub.** Every step was verified locally in the order
   the workflow runs them, including the web build, but no run exists yet. The first
   PR is where `subosito/flutter-action@v2` with `flutter-version-file: .fvmrc`, the
   Ubuntu `python` name, and the golden-artifact glob are proven. Nothing in the
   workflow is exotic; the risk is a step name or a runner path, not a gate.
2. **The `/di/` suffix check is a `warn`, not an `error`** — like all fifteen of its
   siblings in `check_architecture.sh`, so it does not fail the guard. Promoting the
   whole suffix family is a separate change.
3. **The comment-stripping in three guards handles line comments only.** A `/* */`
   block or a string literal containing a forbidden token would still match. Doing
   this correctly means most of a lexer; the AST guard has no such gap, the shell ones
   do, and each says so rather than overclaiming.
4. **A missing repository binding is a runtime error, not a compile error.** Two tests
   cover it and the failure is immediate on launch, but the compile-time guarantee is
   genuinely gone.
5. **`SchedulerType.unknown` reaching a write now surfaces as a generic `Failure`**
   rather than a specific one. That is a programming error either way, and it is more
   honest than a form message, but the diagnostic is less pointed than the deleted
   guard's.
6. **The Flutter pin is enforced in CI, not on developer machines.** `.fvmrc` is now
   the single source for CI, but a local `flutter` of any version still builds. The
   debt entry records the remaining half: a `flutter --version` check in
   `dod_check.sh`.
7. **`memox.state_management.no_generated_ref_subclass` is still a live false
   positive** on `ConsumerWidget`. It needs Riverpod-version awareness the pattern
   language cannot express, so the workaround (a plain widget wrapping `Consumer`)
   stands. Unlike the two rules fixed here, this one is not a text-versus-code
   problem.
8. **The Card feature carries one unfinished consequence.** `CardEntity.validateSide`
   still holds its rule as a static method rather than a value object. Its clock
   fallback was removed and its problem enum is typed, but the `DeckName` treatment
   belongs with M4.11's presentation slice, not ahead of it.

---

## Changed files

**Domain (deck)**
- `A domain/models/deck_name_model.dart`
- `A domain/models/deck_detail_model.dart`
- `A domain/models/root_deck_list_snapshot_model.dart`
- `A domain/usecases/watch_deck_detail_use_case.dart`
- `A domain/usecases/watch_root_deck_list_use_case.dart`
- `D domain/usecases/watch_deck_children_use_case.dart`
- `D domain/usecases/get_deck_by_id_use_case.dart`
- `D domain/usecases/watch_root_deck_summaries_use_case.dart`
- `M domain/entities/deck_entity.dart` · `domain/repositories/deck_repository.dart`
- `M domain/usecases/{create_root_deck,create_sub_deck,rename_deck,watch_deck_move_targets}_use_case.dart`

**Data (deck, card)**
- `M data/datasources/deck_dao.dart` · `data/mappers/deck_mapper.dart`
- `M data/repositories/deck_repository_impl.dart`
- `M lib/features/card/data/card_repository_impl.dart` · `card/domain/card_entity.dart`

**Presentation (deck)**
- `A presentation/controllers/deck_list_now_controller.dart`
- `A presentation/controllers/root_deck_list_controller.dart`
- `D presentation/controllers/root_decks_controller.dart`
- `M presentation/controllers/{deck_detail,deck_write}_controller.dart`
- `M presentation/providers/deck_use_case_provider.dart`
- `M presentation/states/deck_submit_state.dart`
- `M presentation/screens/{root_deck_list,deck_detail}_screen.dart`
- `M presentation/widgets/{deck_form,deck_labels}_widget.dart`

**Feature DI, core, app**
- `A lib/features/deck/di/deck_repository_provider.dart`
- `A lib/app/di/repository_bindings.dart` · `D lib/app/di/deck_repository_provider.dart`
- `R lib/app/router/route_names.dart → lib/core/navigation/route_names.dart`
- `M lib/core/error/failure.dart` · `lib/core/database/queries/deck.drift`
- `M lib/app/bootstrap.dart` · `app/router/app_router.dart` · `app/fallback/route_not_found_screen.dart`

**Tests** — 8 added, 1 renamed, 26 modified (full list in `git diff --name-status`)

**Docs**
- `M docs/architecture.md` (AD-13, AD-12 corrections) · `docs/wbs.md` (M4.10b) · `CLAUDE.md`
- `M lib/features/deck/README.md`
- `M .claude/skills/flutter-feature-slice/assets/{feature_blueprint,feature_checklist}.md`
- `M .claude/skills/flutter-project-setup/SKILL.md` · `flutter-data-layer/references/networking.md`

**CI and harness**
- `A .github/workflows/ci.yml` · `A .claude/skills/flutter-workflow/scripts/check_generated.sh`
- `M .claude/skills/flutter-architecture/scripts/check_architecture.sh` · `flutter-workflow/scripts/dod_check.sh`
- `M code-verification-guard-v2/registries/common/common-convention-rules.yaml`
- `M code-verification-guard-v2/registries/projects/memox-v7/rules/memox-testing-rules.yaml`
- `M pubspec.yaml`

**Generated** — not committed (gitignored). 20 files regenerated;
`check_generated.sh` asserts none is tracked, every declared `part` exists, and a
clean rebuild is byte-identical.

---

## Template readiness verdict

### READY

| Criterion | Status |
|---|---|
| All P1 defects closed | yes — 4 planned, 1 more found in the final review, 3 found incidentally |
| AST guard fault-injected | yes — 8 injections, including 1 control proving comments no longer trip it |
| Code and blueprint consistent | yes — `check_docs.sh` clean; no doc claims a shape the code does not have |
| Full test suite passes | yes — 844, `flutter analyze` 0, guard 0, docs clean, web build succeeds |
| No validation-ownership contradiction | yes — BR-01 is a type; BR-11 splits "chosen" (use case) from "real" (type); the data layer references no validation rule |
| No mixed-snapshot `DeckDetail` | yes — one statement, proved by counting statements, not by asserting values |
| No second query in the move-target emission | yes — proved by repository call counts |
| CI exists and runs | exists and is complete; **has not yet executed on GitHub** |

The last row is the one qualification, and it is not a blocker: every step was run
locally in the workflow's order, including the web build. The verdict is READY with
the standing note that the first PR is what proves the runner, and that a red first
run is a workflow-syntax problem rather than a gate that does not hold.

**Cloning to Card may proceed.** What makes it safe is not that the tests are green —
they were green before all of this — but that the four defects a clone would have
duplicated are gone, and that each is now held by a check which has been shown to
fail when the defect returns.

One instruction for whoever does it: read §3.2 of `lib/features/deck/README.md`
before writing a line. Five of the nine submit steps belong outside the controller,
and that is the mistake this feature made three times.
