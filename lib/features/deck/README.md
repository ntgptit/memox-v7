# features/deck

The first complete vertical slice, and the one the next feature is cloned from.

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

| Kind | Name |
|---|---|
| Routes | `RouteNames.decks` (`/`), `RouteNames.deckDetail` (`decks/:deckId`) |
| Screens | `RootDeckListScreen`, `DeckDetailScreen` |
| Contract | `DeckRepository` (`domain/deck_repository.dart`) |
| Entity | `DeckEntity`, plus the read models `RootDeckSummary`, `DeckMoveTarget`, `DeckDeletionImpact` |
| Enums | `SchedulerType`, `DeckContentType`, `DeckNameProblem` |

Everything else in this folder is internal. Another feature that needs deck data
takes `DeckRepository` from `app/di/deck_repository_provider.dart` — never a DAO,
a mapper, a controller or a widget from here. `check_architecture.sh` rule 3
makes the wrong version an error rather than a review comment.

## 3 · Data flow

```
widget → controller → DeckRepository (contract) → DeckDao → .drift query → SQLite
                            ↑
SQLite → watch() Stream → mapper → entity → AsyncValue → MxAsyncView → widget
```

Reads are `Stream` (`watch`), writes are `Future`. Nothing refreshes manually: a
write lands in SQLite, the stream re-emits, every screen watching it rebuilds.

There is no use-case layer here. A `Future<List<X>> call() => repo.getAll()` is a
file, an indirection and a test for no benefit — the controller calls the
repository. Add a use case when it holds real logic or has a second caller.

## 4 · Providers, by role

The classification matters more than the count: a provider that both reads and
writes is the thing this split exists to prevent.

**Infrastructure** — `keepAlive`, one instance for the app's life:

- `appDatabaseProvider` (`core/database/`) — the open database
- `deckRepositoryProvider` (`app/di/`) — the only place `DeckRepositoryImpl` is
  named. It lives outside the feature so a fake can be substituted without the
  test importing `data/`.

**Query** — `autoDispose` (the default), one per question, read-only:

- `rootDeckSummariesProvider` — the list screen, aggregates included
- `deckDetailProvider(deckId)` — one deck plus its children
- `deckMoveTargetsProvider(deckId)` — legal move destinations (UC-09)
- `deckDeletionImpactProvider(deckId)` — what a delete would take with it
- `deckListNowProvider` — the `now` the due predicate is evaluated against,
  held so the whole screen agrees on one instant

Every stream query carries `@Riverpod(retry: noAutomaticRetry)`. Riverpod 3
otherwise retries a failed provider ten times with a backoff reaching 6.4s while
reporting `AsyncLoading`, so a failed local read spins for ~13 seconds before the
error state appears. A local SQLite read that failed will fail again.

**Command** — one controller per mutation, each with its own submit state.

The state itself is **not** Deck's: `DeckSubmitState` is a typedef onto
`SubmitState<DeckFormProblem>` in `core/state/`, so the four fields and the three
policy getters (`canSubmit`, `shouldClose`, `shouldClearDraft`) live once for every
feature. Deck supplies only its problem enum and two accessors. See
`deck_submit_state.dart`.

`createRootDeckController` · `createSubDeckController` ·
`renameDeckController(deckId)` · `deleteDeckController(deckId)` ·
`resetContentTypeController(deckId)` · `moveDeckController(deckId)`

Six providers rather than one `DeckController` with six methods. A single
notifier would need one `isSubmitting` and one `failure` for six operations, so a
failed rename would light up the delete button's error — and the file would grow
a method per use case forever.

**Input state** — `autoDispose`, one entry:

- `deckListNowProvider` — a `DateTime`, the instant the due counts are measured
  against. Neither a query nor a mutation: a value the UI owns that a query is
  parameterized by. It refreshes on app resume (via `AppLifecycleListener`, not a
  periodic timer) because that is the moment hours have passed and cards became
  due while nothing was watching.

No search or filter state exists yet. When one arrives it is widget state or its
own small provider, never a field on a command controller.

### The two properties that make this classification worth keeping

**Nothing mixes roles, and it is structural rather than disciplined.** A query is a
top-level function returning `Stream`/`Future` — it has no `state` setter, so it
*cannot* mutate. A command is a `Notifier` holding only its submit state — it reads
no query. Verified: the six write controllers reference exactly one provider between
them, `deckRepositoryProvider`.

**Every dependency edge runs from a shorter-lived provider to a longer-lived one.**

```
appDatabase ← deckRepository ← { 4 queries, 6 commands }      (keepAlive ← autoDispose)
clock       ← deckListNow    ← rootDeckSummaries              (the one autoDispose ← autoDispose edge, one-way)
```

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

- `DeckEntity.nameProblem` returns `DeckNameProblem?` — BR-01's trim and
  200-character limit, as an enum rather than a message. `deckNameFormProblem`
  spells it as the form's own `DeckFormProblem` in one switch, and
  `context.deckFormError` turns that into ARB copy. The domain owns the *rule*;
  the form owns how it is displayed.
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

## 8 · Cloning this for a new feature

Read `feature_blueprint.md` first — it has the folder-layout rules the three
enforcers actually accept, the footprint table of what a new feature touches
outside its own folder, and the extractions that were tried and rejected.

Two things people get wrong on the first clone:

- **The layout is flat.** `domain/deck_entity.dart`, not
  `domain/entities/deck.dart`. The role is carried by the file *suffix*, which
  `memox.naming.domain_file_role_suffix` enforces, and MX-VIS-001 derives each
  screen's audit path by stripping only the `presentation` segment — a
  `screens/` subfolder relocates every companion file.
- **Promote to `shared/` on the second caller, not the first.** One caller is a
  guess at what varies; the second one shows you.
