# features/deck

The first complete vertical slice, and one of the two the next feature takes its
method from — `features/card` is the other, and where the two differ is the
answer to what was method and what was Deck (AD-17).

This file answers the questions a new feature has to answer about itself. It is
**not** the place for architecture rules — those live in
`.claude/skills/flutter-feature-slice/assets/feature_blueprint.md`, which is
derived from this feature and is the authority when the two disagree.

## 1 · What business problem it owns

Deck management: UC-06 through UC-09. Creating a root deck with its scheduler,
creating sub-decks, renaming, deleting with an impact confirmation, resetting a
deck's content type, and moving a subtree.

It owns the **deck tree** and nothing else. Card content belongs to
`features/card` (M4.9b moved it there); scheduling belongs to the review slice.

## 2 · Public entry points

| Kind | Where to read it |
|---|---|
| Routes | `RouteNames.decks` (`/`), `RouteNames.deckDetail` (`decks/:deckId`), `RouteNames.starterLibrary` (`starter`) — the template catalog an empty library offers (UC-01) |
| Screen | `DeckListScreen(parentDeckId?)` — **one** screen, recursive; `StarterLibraryScreen` — the starter catalog. M4.10c merged the root list and the detail view once the only difference left was which data they were given |
| Contract | `DeckRepository` (`domain/repositories/deck_repository.dart`) |
| Entity | `DeckEntity` |
| Value object | `DeckName` — the only way to construct a valid deck name (BR-01) |
| Read models | the files in `domain/models/` — `DeckSummary` carries `overdueDayCount`, `scheduleStatus` (BR-161) and the due partition `overdueCardCount`/`dueTodayCardCount` (BR-162), normalised by the mapper from the aggregate's `oldestDueAt` and `overdueCount`; widgets never touch time |
| Enums | the files in `domain/models/` and `domain/failures/` |

**The last two rows point at folders rather than listing names, and that is a
correction.** They used to be lists, and every one of the names in them was
wrong by the time anyone read it — a read model renamed in M4.10c, a type that
was folded into another and deleted. A list of identifiers in prose is a second
copy of something the compiler already maintains, and the copy is the one that
lies. What belongs here is why a thing exists, not that it exists.

Everything else in this folder is internal. Another feature that needs deck data
takes `DeckRepository` from `di/deck_repository_provider.dart` — never a DAO, a
mapper, a controller or a widget from here. `check_architecture.sh` rule 3 makes
the wrong version an error rather than a review comment.

The provider lives **in this feature** and is bound at the composition root. It
used to live in `app/di/`, which meant this feature imported `app/` — see §4.

## 3 · Data flow

```
widget → controller → DeckRepository (contract) → DeckDao → .drift query → SQLite
                            ↑
SQLite → watch() Stream → mapper → entity → AsyncValue → MxAsyncView → widget
```

Reads are `Stream` (`watch`), writes are `Future`. Nothing refreshes manually: a
write lands in SQLite, the stream re-emits, every screen watching it rebuilds.

Ten use cases in `domain/usecases/`, one per interaction (AD-12). Each takes the
repository **contract**, never an implementation.

Three of the six write use cases hold input validation, and that is why they are
not indirection. (The other three — delete, reset and move — validate nothing:
their rules need the tree as it stands at write time and stay in the repository.
So the split is *five that do something and five that forward*, not the
read/write line it is tempting to draw.) BR-01 used to run **three** times for
one submit: the controller
called `DeckEntity.nameProblem`, the repository called `DeckEntity.validateName`
again, and the screen re-derived the problem from the raw text to decide which
field to mark. Three owners, free to disagree, while the documentation said there
was one. There is now a `DeckName` value object that cannot hold an invalid value,
the repository contract asks for one, and the answer to "has this been validated?"
is the signature.

Two of the four read use cases are thin, which is the accepted cost of a uniform
layer; the other two do real work — the move-target read raises its own
`NotFoundFailure`, and `SearchDecksUseCase` scopes and builds trails in memory.
Two more are gone rather than thin: `WatchDeckChildrenUseCase` and
`GetDeckByIdUseCase` were composed in a controller to build one screen's read
model, and that composition was two database snapshots — see §3.1.

### 3.1 · One interaction is one read

Two screens used to build their read model from two queries, and both looked
correct because a quiet database gives two snapshots the same answer.

- **The deck screen** watched `childDecks` and then awaited `getDeckById` per
  emission, with a comment claiming the two facts "arrive together". They did not.
  The action set is computed from `content_type` *and* from the children being
  empty (BR-68), so a rename or a create landing between the reads produced a
  screen assembled from two instants. There is now one statement behind
  `watchDeckList`, one contract method, and the snapshot it returns lives in
  `domain/models/` because the repository returns it.
- **The move picker** read every deck, then asked for the source deck again — a
  deck that was already in the list it had just been handed, re-read from a later
  snapshot. The source now comes from the same emission; absent means it was
  deleted elsewhere, which is a typed `NotFoundFailure`.

The read tests under `test/features/deck/data/` count SQL statements through a
real `QueryInterceptor`, because no assertion about the *values* can tell the two
designs apart. That is the shape to copy: when a claim is about how something is
read rather than what it returns, measure it.

### 3.2 · The submit flow, end to end

Nine steps, for every one of the six write operations. Worth reading once before
cloning, because five of the nine are the parts people put in the wrong layer.

1. **Widget** calls `controller.submit(...)` with the raw text the user typed.
2. **Controller** returns immediately unless `state.canSubmit` — a double tap
   cannot create two decks.
3. **Controller** sets `isSubmitting: true`, which also clears the previous
   attempt's problems and failure.
4. **Controller** calls the use case with the **raw** string. It does not validate;
   it does not trim.
5. **Use case** parses `DeckName.parse(rawName)` and collects every
   `DeckValidationProblem` — BR-01 and, for a root, BR-11 — then throws one
   `ValidationFailure` carrying the whole `Set`. Both fields are reported from one
   attempt, which a single `Failure.reason` could not do.
6. **Use case** calls the repository with a `DeckName` and a non-null
   `SchedulerType`. Nothing re-checks BR-01 below this line.
7. **Repository** runs inside `_guard`, and inside `runInTransaction` when the
   write is multi-step. This is where the rules that need the tree *at write time*
   live — BR-55 depth, BR-62's content lock, BR-68's emptiness, UC-09's move rules
   — and where any Drift or SQLite exception becomes a domain `Failure`.
8. **Controller** checks `ref.mounted` after the await, then sets either
   `outcome: disposition.outcome` or `deckSubmitFailure(failure)` — which splits a
   `ValidationFailure` into typed per-field `problems` and leaves anything else as
   an opaque `failure`.
9. **Widget** renders ARB copy chosen from `problems` or from `failure.reason`, and
   performs the side effect — pop, clear draft — exactly once, from
   `shouldClose` / `shouldClearDraft`.

What a controller keeps is presentation only: steps 2, 3, 8. **It does not
validate, and it does not read a repository.**

What deliberately stays in the repository: BR-55 depth, BR-62's first-child content
lock, BR-68's emptiness checks and UC-09's move rules. Each needs the tree as it
stands at the moment of writing and runs inside `runInTransaction`; a use case
above the repository would put the check outside the transaction, which is a race
between the check and the write.

## 4 · Providers, by role

The classification matters more than the count: a provider that both reads and
writes is the thing this split exists to prevent.

**Infrastructure** — `keepAlive`, one instance for the app's life:

- `appDatabaseProvider` (`core/database/`) — the open database
- `deckRepositoryProvider` (`di/`) — declared **here**, typed as the domain
  contract, with a body that throws. `deckRepositoryBinding` in
  `app/di/repository_bindings.dart` is what satisfies it, installed by
  `buildRootWidget`; that is the only place `DeckRepositoryImpl` is named.

  It used to be declared in `app/di/`, which meant `features/deck/` imported
  `app/` — a feature depending on the shell it happens to be mounted in. Cloning
  meant editing `app/di/` too, and forgetting would fail inside the *new* feature
  rather than at the root where the omission was.

  It is in `di/` and not `presentation/providers/` because
  `provider_convention_test.dart` forbids `keepAlive` under
  `features/*/presentation/`, and a repository handle has to be `keepAlive`. That
  rule is right; the placement was wrong.

**Query** — `autoDispose` (the default), one per question, read-only. They live in
`presentation/controllers/`; the one worth knowing about before you read them is
`deckListProvider(parentDeckId)`, which serves **both** levels of the recursive
screen: the decks at that level with their aggregate counts **and** `nextDueAt`,
the instant those counts expire. It is a `StreamNotifier` rather than a function
provider because arming the due-boundary timer needs `listenSelf`, which is a
notifier method. The others — move targets, deletion impact, search results —
are function providers, and the difference is exactly that: a notifier only when
something must happen *to* the stream.

Every stream query carries `@Riverpod(retry: noAutomaticRetry)`. Riverpod 3
otherwise retries a failed provider ten times with a backoff reaching 6.4s while
reporting `AsyncLoading`, so a failed local read spins for ~13 seconds before the
error state appears. A local SQLite read that failed will fail again.

**Command** — one controller per mutation, each with its own submit state.

The state itself is **not** Deck's: `DeckSubmitState` is a typedef onto
`SubmitState<DeckValidationProblem>` in `core/state/`, so the four fields and the
policy getters (`canSubmit`, `shouldClose`, `shouldClearDraft`, `hasProblem`) live
once for every feature. Deck supplies only its problem enum and two accessors. See
`deck_submit_state.dart`.

`deckSubmitFailure` takes only the `Failure`. It used to take the raw name as well,
so that presentation could re-derive which field was wrong — which is what made
BR-01 have three owners. It cannot be reintroduced without changing the
signature.

`createRootDeckController` · `createSubDeckController` ·
`renameDeckController(deckId)` · `deleteDeckController(deckId)` ·
`resetContentTypeController(deckId)` · `moveDeckController(deckId)`

Six providers rather than one `DeckController` with six methods. A single
notifier would need one `isSubmitting` and one `failure` for six operations, so a
failed rename would light up the delete button's error — and the file would grow
a method per use case forever.

**Input state** — `autoDispose`. Five of them now: the due-count clock below, and
the list's filter, sort, summary-visibility and search-query choices. Each is a
notifier holding **one** value with **one** mutator, which is what keeps it out
of the command category; `command_query_separation_test.dart` counts that.

- `deckListNowProvider` — a `DateTime`, the instant the due counts are measured
  against. Neither a query nor a mutation: a value the UI owns that a query is
  parameterized by. Two things move it, and both are needed:

  - **app resume**, via `AppLifecycleListener` — the phone was in a pocket and
    hours passed while nothing was watching;
  - **a due boundary being crossed with the screen open** — `DeckList` arms a
    single one-shot `Timer` for `nextDueAt`, which comes from the same statement as
    the counts. When it fires the clock moves, the query re-runs, and the next
    emission arms the next timer.

  Resume alone was the whole mechanism, and the comment here recorded that a
  periodic timer had been "considered and rejected" because resume catches the same
  boundary. It does not: a user sitting on the list when a card came due saw a
  badge saying 3 while the session it launches handed out 4. The replacement is not
  a periodic timer either — it is one wake scheduled from the data, so a screen
  with nothing due has no timer at all.

Search and filter arrived as exactly that shape — their own small providers,
never a field on a command controller. A filter kept on a submit controller
would be cleared by a failed submit, and the list would silently change what it
was showing because a rename went wrong.

### The two properties that make this classification worth keeping

**Nothing mixes roles, and it is structural rather than disciplined.** A query is a
top-level function returning `Stream`/`Future` — it has no `state` setter, so it
*cannot* mutate. A command is a `Notifier` holding only its submit state — it reads
no query. Verified: the six write controllers read **use-case providers only**,
one each, and `deckRepositoryProvider` appears nowhere under `presentation/`
except in `providers/deck_use_case_provider.dart`, which is dependency wiring and
nothing else.

That sentence used to say the opposite — that the write controllers referenced
`deckRepositoryProvider` between them. It was true when it was written and the
use-case layer superseded it; left standing, it described an AD-12 violation as
though it were the design, in the one file the next feature is told to read
first. Worth naming rather than quietly fixing: **a stale doc does not degrade
into vagueness, it degrades into confident wrongness**, and this section is the
one a new feature reads its structure from.

**Every dependency edge runs from a shorter-lived provider to a longer-lived one.**

```
appDatabase ← deckRepository ← use-case providers ← { queries, commands }
clock       ← deckListNow    ← deckList                (the one autoDispose ← autoDispose edge, one-way)
```

`deckList` also *writes* to `deckListNow` when its timer fires — through
`ref.read(...notifier).refresh()`, from a timer callback rather than from `build`.
That is not an edge back up the graph: it is an imperative nudge, and the
dependency direction is unchanged.

Maximum depth three, and a cycle would need an edge back up the lifetime order. So
keeping the layers honest is also what keeps the graph acyclic — otherwise Riverpod
tells you at runtime, on the path nobody exercised.

**`test/app/provider_convention_test.dart` enforces three of these**, because a
convention in a README decays at the first clone: no `keepAlive` under
`features/*/presentation/`, every family key a `String` or `int` (an object key is
compared by identity, so a fresh instance is cached on every rebuild), and every
async provider carrying `noAutomaticRetry`. All three were fault-injected to prove
they fail.

`ref.invalidate` appears at exactly **two** sites, both the retry button on an error
state. `ref.refresh` appears nowhere — a refresh keeps the previous value while
re-reading, which is wrong for a retry: the previous value is the error.

## 5 · Where the business rules are

In `domain/`, expressed so that the illegal case cannot be represented rather
than merely checked:

- `DeckName` (`domain/models/deck_name_model.dart`) is the **single owner of
  BR-01** — the trim and the 200-character limit, in a type whose private
  constructor means an invalid value cannot exist. `DeckName.parse` returns the
  value or a typed `DeckValidationProblem`; `context.deckFormError` turns that into
  ARB copy. The domain owns the *rule*; the form owns how it is displayed.

  The limit is measured **after** trimming, and an over-length name is refused
  rather than truncated — there is no truncated value for a caller to persist by
  accident.
- `SchedulerType` owns BR-11's "and `unknown` is not a choice" half, because
  `SchedulerType.unknown` has no `dbValue` — the write is *impossible*, not merely
  refused. There used to be a `_requireRealScheduler` guard in the repository as
  well, throwing `ValidationFailure(schedulerMissing)`; it was redundant, and it
  reported a **form** problem for a state no user can cause, so "please choose a
  scheduler" would have answered a programming error. The use case owns "must be
  chosen"; the type owns "must be real".
- `buildDeckMoveTargets` — a pure function returning every candidate with its
  rejection reason (depth, cycle, content type, scheduler mismatch). UC-09's
  whole rule set, testable with no database and no widget.
- depth and cycle enforcement runs in `data/` **before the first mutation**,
  inside the transaction, because it needs the tree (BR-55, AD-10)

A rule in a widget or in a DAO is the defect this section exists to prevent. The
form validates for the *user's* benefit; the repository refuses for the *data's*.

## 6 · How errors are converted

```
SqliteException → mapDatabaseError → Failure → controller state → ARB copy
```

Every repository method runs inside `_guard`, and every stream inside
`_guardStream`, which rethrow domain failures untouched and map anything else.
A `DriftWrappedException` never leaves `data/`.

`Failure.message` is a **sanitized diagnostic, not a UI string** — it is not
localized and production UI must not render it. `deck_labels_widget.dart` maps the
failure *type* to ARB copy. There is deliberately no "fall back to `message`"
rule: a fallback like that only fires on the paths nobody looked at.

Validation failure, not-found, conflict (a duplicate key, SQLite extended code
11) and database failure are four different states, not one "something went
wrong".

## 7 · How to test it

Mirrors `test/features/deck/`, and the level matters:

| Level | Against | Example |
|---|---|---|
| domain | nothing | `deck_move_target_test.dart` — 16 cases, pure |
| data | **real in-memory SQLite** | `deck_repository_summary_test.dart` — the SQL is what is in doubt |
| controller | `FakeDeckRepository` | initial, loading→loaded, failure, double submit |
| widget | `FakeDeckRepository` | loaded, empty, error, interaction |
| route | the real router | cold start, deep link, back, branch state |
| visual audit | strict, per state | MX-VIS-001 companion, light and dark |

**Widget tests use the fake, never real Drift** — not a preference: driving Drift
from a widget test leaves its stream-notification timer pending at teardown and
`flutter_test` fails the test for that instead of for the behaviour. Assert
persistence in the data tests.

`test/features/deck/presentation/support/` holds the fake and the pump harness.
The fake implements the **domain contract** and supplies reads as *builders*,
because a single-subscription stream can only be listened to once and a retry
listens twice.

## 8 · Taking this as a reference for a new feature

**Take the method, not the shape** (AD-17). The tree, `content_type` and
scheduler-on-root below are this feature's business; a feature that does not need
them and grows them anyway has read the wrong half. `lib/features/card/README.md`
is the control case — it was built to these same rules and came out shaped
differently in almost every countable way.

Read `feature_blueprint.md` first — it has the folder-layout rules the three
enforcers actually accept, the section on what does *not* transfer, the footprint
table of what a new feature touches outside its own folder, and the extractions
that were tried and rejected.

What people get wrong first:

- **`domain/` and `data/` are bucketed too, not just `presentation/widgets/`.**
  `domain/` is `entities/` · `repositories/` · `models/` · `usecases/` ·
  `failures/`; `data/` is `repositories/` · `mappers/` · `datasources/` ·
  `models/`. Nothing sits directly in `domain/` or `data/`, and an invented name
  like `data/local/` is not a bucket. This is enforced now, and it was added
  *because* it had already gone wrong: Card and Review were laid out flat, and
  the suffix rules in `check_architecture.sh` select files by these exact path
  fragments — so both features matched **zero** rules and passed every check by
  being invisible to it, while the app-wide scope counters stayed green because
  Deck alone satisfied them.
- **The folder does not replace the suffix.** `domain/entities/deck_entity.dart`,
  not `domain/entities/deck.dart`. The role is carried by the file name, which
  `memox.naming.domain_file_role_suffix` enforces and which
  `check_architecture.sh` pairs with the folder it sits in.
- **`data/models/` is the only folder kept empty, and the reason is not
  laziness.**
  Drift's generated row class *is* the data model and lives in `core/database/`
  because the schema is shared; a per-feature DTO would be a second shape for one
  row, and with no `dio` (AD-05) there is no wire format to model either.
- **`di/` is a layer, not a folder of convenience.** One file per contract the
  feature needs, declared as the domain type. It may import `domain/` and Riverpod
  and nothing else — `test/app/architecture_boundary_test.dart` fails if it names
  an implementation, because the moment it does, `presentation/` can reach Drift
  through it and AD-01 is gone with no import looking wrong.
- **`presentation/providers/` is wiring only.** Anything holding state or a command
  is a `_controller` — the guard's widget scope exempts files by that suffix, so
  putting a controller in `providers/` would change which rules apply to it.
- **Promote to `shared/` on the second caller, not the first.** One caller is a
  guess at what varies; the second one shows you.
- **`presentation/widgets/` is bucketed — `sections/` · `items/` · `overlays/` ·
  `support/`, one level deep, nothing at the root (AD-15).** Placing a widget is
  four questions asked in order, stopping at the first yes: opens over the
  screen? → `overlays/`. The repeated row or a part only it uses? → `items/`.
  Composed directly into body/chrome? → `sections/`. Serves more than one
  bucket? → `support/`. The bucket list is app-wide and fixed — a fifth name is
  an AD-15 change, and both `architecture_boundary_test.dart` and the guard
  fail on an invented folder. When cloning, create a bucket with its first real
  file; never scaffold empty ones.
