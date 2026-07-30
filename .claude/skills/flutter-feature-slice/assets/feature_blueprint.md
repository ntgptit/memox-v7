# Feature blueprint — derived from `features/deck` (M4.9…M4.10)

The Deck feature is the reference implementation. This file records **what to copy,
what to rename, and what must not be copied**, measured against the code as it
stands rather than as an ideal.

It is not a folder template to scaffold blindly. The repo's guards select files by
*suffix*, and MX-VIS-001 derives an audit path from a screen's location, so the
layout below is load-bearing — a plausible-looking alternative breaks a gate.

## The layout

```
lib/features/<feature>/
├── domain/
│   ├── entities/       <name>_entity.dart
│   ├── repositories/   <name>_repository.dart          (the contract)
│   ├── models/         <name>_model.dart               (read models, enums)
│   ├── usecases/       <verb>_<noun>_use_case.dart     (one per interaction)
│   └── failures/       <name>_failure.dart             (reason enums + refusal helpers)
├── data/
│   ├── repositories/   <name>_repository_impl.dart
│   ├── mappers/        <name>_mapper.dart
│   ├── datasources/    <name>_dao.dart
│   └── models/         <name>_model.dart               (DTOs — none yet, AD-05)
└── presentation/
    ├── screens/        <name>_screen.dart
    ├── controllers/    <name>_controller.dart
    ├── states/         <name>_state.dart
    ├── widgets/        <name>_widget.dart
    └── providers/      <name>_provider.dart            (dependency wiring only)
```

Plural folder names, which is both the industry convention (Clean Architecture,
Reso Coder's Flutter template, Very Good Ventures, the Android architecture guide)
and what `check_architecture.sh` now checks.

**The folder does not replace the suffix.** `domain/entities/deck_entity.dart`, not
`domain/entities/deck.dart`. Two enforcers depend on the suffix and neither looks
at the folder:

- `memox.naming.{domain,data,presentation}_file_role_suffix` match on the file
  name, and other guard scopes select files by that same suffix. A mis-suffixed
  file silently leaves the scope of the rules meant to cover it — which is why
  `deck_labels_widget.dart` keeps `_widget` although it holds an extension.
- `check_architecture.sh`'s `check_suffix` pairs each folder with its required
  suffix: `/domain/entities/` → `_entity.dart`, `/presentation/screens/` →
  `_screen.dart`, and eight more.

**A note on that second one, because it is the reason this layout is worth having
rather than just conventional.** Until M4.10 `check_suffix` was written against
*singular* folder names — `/domain/entity/`, `/presentation/screen/` — which the
flat layout did not have either. All six calls matched **zero files**. They ran,
found nothing to look at, and passed. A check that cannot fail reads as coverage
and is worse than no check. Nesting with the plural names put 23 files under them;
fault injection confirms a wrongly-suffixed file is now reported.

**MX-VIS-001 keeps everything below `presentation`.** The audit path is derived by
stripping only that one segment, so a screen at
`features/deck/presentation/screens/x_screen.dart` needs its companion at
`test/visual_audit/screens/features/deck/screens/x_screen_visual_audit_test.dart`.
The `screens/` folder is preserved, not flattened.

**One folder is still empty**, and one is empty for a reason worth reading:

| Folder | State |
|---|---|
| `domain/usecases/` | **10 files** — one per interaction. See below. |
| `domain/failures/` | **3 files** — reason enums plus the refusal helper every write use case shares. |
| `presentation/providers/` | **1 file** — the use-case wiring. |
| `data/datasources/` | the DAO. An abstract `LocalDataSource` over a Drift DAO would be an interface with one implementation and no second candidate. |
| `data/models/` | **empty.** Drift's generated row class *is* the data model, and it lives in `core/database/` because the schema is shared across features. A per-feature DTO would be a second shape for one row, and `dio` is not a dependency (AD-05), so there is no wire format to model either. It gets files with the first real request. |

### The use case layer

Ten use cases, one per interaction, each taking the repository contract and
exposing `call`. Two things make them more than indirection:

**They hold the validation, and it used to run twice.** `DeckEntity.nameProblem`
ran in the controller *and* again inside the repository, in two layers, with
nothing to catch the two disagreeing. It runs in the use case now — the layer that
owns BR-01 — and both the controller and the repository stopped duplicating it.

**A controller keeps only what is presentation:** the double-submit guard, the
submitting flag, the `ref.mounted` check after an await, and turning a `Failure`
into per-field state. It no longer reads a repository at all.

What deliberately did **not** move into a use case: BR-55 depth, BR-62's
first-child content lock, BR-68's emptiness checks, and UC-09's move rules. Every
one of those needs the tree *as it stands at the moment of writing* and runs inside
`runInTransaction`. A use case above the repository would put the check outside the
transaction, which is a race between the check and the write — so the rule would be
in a tidier place and wrong. The use case is the entry point; the transaction is
where a tree-shaped rule belongs.

**Refusal travels as `ValidationFailure.fieldErrors`, not `Failure.reason`.** A
form can fail on two fields at once — a blank name *and* no scheduler chosen — and
`reason` holds one value. The keys come from `DeckField`, are identifiers rather
than copy, and `deckSubmitFailure` maps them to the per-field problems the screen
renders.

### `presentation/providers/` versus `controllers/`

A controller holds state and exposes commands. A provider here holds nothing and
exposes one use case. The distinction is enforced, not stylistic: the guard's
widget scope excludes files by suffix, so `_provider` was added to the allowed
presentation suffixes *and* to that scope's exclusions at M4.10 — a file whose job
is dependency wiring reads a repository by definition, and must not have to borrow
the `_controller` exemption to do it.

`app/di/` still holds the repository provider. That is the composition root: the
one place `DeckRepositoryImpl` is named, so a test can substitute the
implementation from outside the feature. A use case has no implementation to choose
between, so its wiring travels with the feature.

Use-case providers are `autoDispose`, like everything else under
`features/*/presentation/`. Constructing one is a field assignment, so an exception
to that rule would buy nothing and cost the rule its teeth —
`test/app/provider_convention_test.dart` enforces it and caught this while the
layer was being added.

### Command and query, with numbers instead of judgement

The failure mode is a `DeckNotifier` that grows `loadDecks`, `createDeck`,
`deleteDeck`, `selectDeck`, `searchDeck`, `navigateToDeck`, `showError`. Each
addition is individually reasonable and it never arrives as one commit, so a review
will not catch it. A method count will.

`test/app/command_query_separation_test.dart` holds four counts:

| Check | Rule |
|---|---|
| a use case | exactly **one** public method — one interaction |
| a command controller | only `build`, `submit`, `reset` |
| an input-state notifier | one value and at most one mutator |
| any controller or use case | no `select*`, `search*`, `navigateTo*`, `show{Error,Snack}*` |

A command controller is identified by what its state **is** — `build` returns a
submit state — rather than by where the file sits. That matters because
`DeckListNow` is a notifier under `controllers/` that is *not* a command: it holds
the instant the due counts are measured against. It is bounded by the third check
rather than exempted from the second, so "the thing that holds the odds and ends"
cannot become the God Notifier by a different route.

The first check found a live violation on the run that introduced it:
`WatchDeckChildrenUseCase` held the children stream *and* a deck read. Two queries
in one class is the same shape as eight methods in one notifier, only smaller. It
was split into `GetDeckByIdUseCase`, and `deckDetail` composes the two —
composition is what a controller is for.

**All four were fault-injected, and two were vacuous when written.** One had
`replaceAll(r'', '/')` where an escaped backslash was intended, so every path became
garbage and `contains('/controllers/')` was false for every file: the loop body
never ran and the check passed by looking at nothing. Both bugs were invisible while
the codebase was clean, which is the whole argument for injecting a failure before
trusting a green check.

## What `core/` and `shared/` already provide — do not re-create

| Need | Use |
|---|---|
| "now", injectable and testable | `core/time/clock_provider.dart` |
| turn off Riverpod's retry ladder on a local read | `core/state/retry_policy.dart` — `noAutomaticRetry` |
| failure types | `core/error/failure.dart` |
| Drift exception → `Failure` | `core/error/drift_error_mapper.dart` |
| the open database | `core/database/app_database_provider.dart` |
| spacing / radius / icon size / colours / text | `core/theme/*` — never a literal |
| screen chrome, list row, buttons, inputs, sheets, dialogs, empty/error/loading | `shared/widgets/mx_*` |
| the three `AsyncValue` cases, with the loading policy stated | `shared/widgets/mx_async_view.dart` — `MxAsyncView<T>` |
| close-on-success vs stay-open-on-success | `core/state/submit_outcome.dart` — `SubmitDisposition` / `SubmitOutcome` |
| one mutation's status, and the success policy | `core/state/submit_state.dart` — `SubmitState<P>`; a feature adds only its problem enum |
| provider failures and state transitions in the log | `core/state/provider_observer.dart` — installed in `bootstrap` |
| which SQL ran, and how long it took | `core/database/query_log_interceptor.dart` — debug builds only |
| localized strings | `lib/l10n/*.arb` + `context.l10n` |

**The rule that makes this checkable:** every import a feature makes to the
outside must resolve to `core/`, `shared/`, `l10n/` or `app/`. A feature reaching
into another feature's `data/` or `presentation/` is an error
(`check_architecture.sh` rule 3). Verify with:

```bash
git grep -nE "import '[^']*features/[a-z_]+/(data|presentation)/" -- lib/features
```

Anything a second feature would need from the first belongs in `core/` **before**
the clone, not after. Both entries in the table's first two rows were originally
inside `features/deck/presentation/` and were moved for exactly this reason.

## Domain purity

`domain/` compiles as plain Dart: no Flutter, no Drift, no Riverpod, no
`json_annotation`. `freezed_annotation` and `meta` are allowed — pure-Dart
annotation packages. Enforced by `check_architecture.sh` rule 1 and
`memox.architecture.domain_no_infrastructure_import`.

A Drift row must never appear above the repository. The mapper is the boundary:

- `data/<name>_mapper.dart` — `Row → Entity`, and `AggregateResult → ReadModel`
- read models live in `domain/` as `_model.dart`, not on the entity: a count that
  is only true at one instant does not belong on the type every write path uses

## Riverpod

Codegen only. `@riverpod` on a function for a read, on a class for anything with
commands. No manual `Provider`/`StateProvider`/`StateNotifierProvider`, no
`ChangeNotifier` — `memox.state_management.*` rejects all of them.

**Reads** are `AsyncValue`, consumed with `.when(loading:, data:, error:)`. Not
`hasValue`, not `requireValue`. Put `@Riverpod(retry: noAutomaticRetry)` on every
one that reads the local database.

**Writes** are a class notifier whose state is a form/submit state, *not*
`AsyncValue<void>`. The reason is concrete: a mutation has to distinguish "this
field is invalid" from "the operation failed" from "it succeeded, close the
sheet". `AsyncError(ValidationFailure)` collapses the first two, and the widget
then has to destructure a failure to find out which field to mark. See
`deck_submit_state.dart` for the shape:

```dart
isSubmitting · Set<P> problems · Failure? failure · SubmitOutcome? outcome
                                              → canSubmit · shouldClose · shouldClearDraft
```

Every `submit` follows the same five steps, in this order:

1. `if (!state.canSubmit) return;` — the double-submit guard
2. validate locally against the domain rule, and return with a field problem set
3. `state = const XSubmitState(isSubmitting: true);`
4. `await` the repository; `if (!ref.mounted) return;` **before** touching state
5. success → `outcome: disposition.outcome`; `on Failure` → map onto a problem or
   `failure`. A failure sets **no outcome at all**, so neither success transition
   fires and the input survives.

Never clear the user's input on failure. The widget owns the text, so a failed
write cannot destroy it — that is the point of keeping the controller out of it.

A controller never holds a `BuildContext` and never navigates. It reports an
outcome and the widget reacts via `ref.listen` or `didUpdateWidget`, on the
*transition* rather than the value, so a sheet closes once instead of on every
rebuild.

**The five things a controller must not touch**, verified by grep across every
controller, repository and domain file in the feature: `BuildContext`, the router
(`goNamed`/`context.go`/`Navigator`), a dialog (`showDialog`/`showModalBottomSheet`),
a snackbar (`ScaffoldMessenger`/`SnackBar`), and an `AnimationController`. All five
return nothing. The only `package:flutter` import in a controller is
`root_decks_controller.dart` taking `AppLifecycleListener` — not a widget, holds no
context, and the alternative was a controller keeping a reference into the widget
tree.

The direction is the point: a controller reports, the widget decides. Success pops,
failure renders, created navigates — and each of those is a line in a widget, where
a `BuildContext` legitimately exists.

**On protecting the side effect from re-running**, one honest note. Three of the
four sites use `ref.listen`, which Riverpod calls only on a change, so the explicit
`previous?.shouldClose` check there is a second layer. The fourth,
`_FormHost.didUpdateWidget`, is called on every parent rebuild and needs its guard
in principle — but fault injection showed that removing it does **not** produce a
double pop today, because the state after a success is terminal: nothing changes it
again, so the `Consumer` above it is not rebuilt again. Keep the guard; do not
believe a comment that says it is load-bearing today.

What is worth testing is the behaviour rather than the line.
`side_effect_once_test.dart` pumps *through* the close — keyboard insets changing
on the way out, as they do on a device — and asserts the sheet is gone, the screen
that opened it is still mounted, and the repository received exactly one write.
Before it, every test in the feature called `pumpAndSettle` once and checked the
repository, which a double pop or a sheet that failed to close would not have
changed.

`autoDispose` (the generator default) for anything per-screen; `keepAlive` only
for the database and the repositories.

### The state class is shared; the five steps are not

**`core/state/submit_state.dart` holds `SubmitState<P>`** — `isSubmitting`,
`Set<P> problems`, `Failure? failure`, `SubmitOutcome? outcome`, and the three
policy getters. A feature supplies only its own problem enum:

```dart
enum DeckFormProblem { nameEmpty, nameTooLong, schedulerMissing }

typedef DeckSubmitState = SubmitState<DeckFormProblem>;

extension DeckSubmitProblems on DeckSubmitState {
  DeckFormProblem? get nameProblem => firstProblemOf(kDeckNameProblems);
  bool get isSchedulerMissing =>
      problems.contains(DeckFormProblem.schedulerMissing);
}
```

The extension is what keeps the questions specific while the storage is shared: a
widget still asks `state.nameProblem`, so **no widget changed** when this was
extracted. `firstProblemOf` narrows the set to the values belonging to one input,
which is the case a plain `problems.isNotEmpty` gets wrong — a form that failed
only on the scheduler must leave the name field clean.

`problems` is a `Set` because a form can fail in more than one place at once.
Creating a root deck with a blank name and no scheduler chosen marks both; marking
whichever check ran first sends the user round twice.

**What the sharing actually buys is the three getters.** They are the success
policy, and the policy has been wrong once: `canSubmit` was
`!isSubmitting && !isDone`, which latched shut on any success and would have let an
*add another* form accept exactly one entry. Copied per feature, that is a policy
that can differ between two features for no visible reason.
`test/core/state/submit_state_test.dart` asserts it at the level it is shared —
including that the equality is by value, because a widget detects the success
transition by comparing the old state with the new one, and identity equality on
the `Set` would fire the side effect on every rebuild.

**The five steps stay written out per operation.** Six times in Deck, about eight
lines each. Three extractions were tried and rejected:

- an extension on the generated base couples app code to riverpod's
  `$`-prefixed internal `$Notifier`;
- a runner taking `read`/`write`/`isMounted` callbacks replaces eight readable
  lines with four lines of plumbing per call site;
- a `BaseController` hides the `ref.mounted` check, which is the one line that
  must be visible.

One implementation detail worth copying rather than rediscovering: validate on the
**inputs**, not on `problems.isNotEmpty`. The latter reads better and costs the
type promotion — the compiler cannot see through a set that a nullable argument is
non-null below, and the alternative is a `!` on the very value the rule exists to
protect.

## Data layer

- one DAO per feature, receiving an already-open `AppDatabase`; nothing but
  `core/database/connection.dart` opens one (AD-08)
- **all SQL in `.drift` files** so `drift_dev` type-checks it at build time
  (AD-02). No business SQL in Dart.
- **query → `Stream` (`watch`), mutation → `Future`.** Reads re-emit on every
  write, from any screen, which is what removes manual refresh.
- multi-step writes go through `dao.runInTransaction`, and every guard that can
  refuse runs **before** the first mutation, so a refused write leaves no trace
- aggregate in SQL, never per row in Dart. One statement with grouped subqueries
  joined once; a Dart loop over rows is the N+1.
- pass `now` in as a parameter. A query that reads the SQL clock cannot be tested
  at its own boundary.

### Bound every read whose row count the user controls

Deck got away without this: a user has tens of root decks, and the tree is capped
at 10 levels (BR-55). **Cards are the first table with no such ceiling**, and
`cardsByDeck` as it stands today selects the whole deck.

Measured on real in-memory SQLite, one deck of 5,000 cards, debug VM:

| read | time |
|---|---|
| whole deck, as `cardsByDeck` is written now | **37.8 ms** + 0.4 ms to map |
| first page of 50 | **1.6 ms** |
| page 99 via `LIMIT ... OFFSET` | 2.7 ms |
| page 99 via keyset | **1.1 ms** |

37.8 ms is more than two 60fps frames, and a `watch()` stream re-runs the whole
query on **every** write to `cards` — so editing one card re-reads all 5,000.
Mapping is not the problem (0.4 ms); the query is.

Three rules follow, in the order they matter:

1. **A list query that can grow without bound takes a page size.** Write it that
   way in the same commit as the query. Retrofitting it later is not a SQL change
   — it changes the state shape, the controller and the widget.
2. **Keyset, not `OFFSET`.** `WHERE (created_at, id) > (:afterCreatedAt, :afterId)
   ORDER BY created_at, id LIMIT :pageSize`. `OFFSET` costs the rows it skips, and
   worse, it *shifts* when a row is inserted above the window — a user who adds a
   card mid-scroll sees a duplicate or misses one. The ordering column pair must
   be unique, which is why `id` is in it.
3. **Do not build a generic `PaginatedNotifier<T>` for the first list.** Same rule
   as shared components: one caller is a guess at what varies. The scroll-end
   listener likewise stays inside the screen until a second list needs it.

`cardsDueForReview` (M5) is the other unbounded read: a session currently loads
every due card in the tree.

### Local-first, and what sync will and will not change

Sync is deferred (AD-01), and the deferral is a decision with a scope — knowing
which half is already paid for is what stops each feature inventing a quarter of
a sync layer:

**Already in place, because it is expensive to retrofit:**

- repository contracts in `domain/`, written from what presentation needs rather
  than from Drift's shape. This is the whole of "backend-ready": adding a remote
  source changes `*_repository_impl.dart` and nothing above it.
- reads are `watch()` streams, so a future sync writing to the table updates every
  screen with no invalidation call added anywhere
- **client-generated UUID primary keys**, so a row created offline needs no
  server round trip to have an identity
- nullable `owner_id` on `decks`, so rows survive the arrival of accounts (AD-03)
- `created_at` / `updated_at` maintained on **every** write, from an injected
  clock. This is the one that cannot be added later: a column added in v2 has no
  true value for rows written in v1, and last-write-wins has nothing to compare.

**Deliberately absent — do not add per feature:**

- `is_synced` / `is_pending_sync` / `server_id`. There is no writer that could set
  them to anything but the same constant and no reader that could act on them, so
  they would be columns whose tests assert a literal. AD-01 is explicit: a write
  to Drift *is* a successful write, and there is no "sending" state.
- an outbox table, a queue, a retry policy, a conflict resolution rule. Conflict
  policy is undecided and is a **product** question (which side wins when the same
  card was edited on two devices), not one to settle inside a feature's repository.
- `dio`, and `data/remote/` (AD-05). `EnvConfig.apiBaseUrl` deliberately points at
  a `.invalid` host so a premature request fails at DNS instead of reaching
  something real.

`ConflictFailure` already exists, but it means a **local** constraint violation —
a duplicate primary key mapped from `SqliteException` extended code 11. It is not
a sync conflict and must not be reused as one.

### A failure carries *why* as a value, not as a sentence

`Failure.reason` is an `Enum?` on the base type. `Enum` and not a feature type
because `core/` must not import a feature, and on the base because `Failure` is
**sealed** — a feature cannot declare its own subtype, so the reason has to travel
on an existing one.

The alternative was live in Deck until M4.10 and is worth stating as the failure
mode, because it looks harmless: fifteen different refusals each threw
`ConflictFailure(message: '<its own English sentence>')`, and the one place that
maps a failure to copy could only say `ConflictFailure() => deckConflictMessage`.
**Fifteen distinct reasons arrived at the user as one sentence** — not because
anyone chose that, but because the reason was encoded in a string the UI is
forbidden to render.

A feature declares its reasons in `domain/failures/*_failure.dart` (the `_failure`
suffix is required there, and `check_architecture.sh` checks it), the repository
throws `ConflictFailure(reason: ...)`, and presentation matches on the reason's
type:

```dart
ConflictFailure(reason: final DeckMoveRejection rejection) =>
    deckMoveRejectionText(rejection),
ConflictFailure(reason: final DeckConflictReason reason) => deckConflict(reason),
ConflictFailure() => l10n.deckConflictMessage,   // no reason: a duplicate key
```

Each helper switches exhaustively over its own enum, so a new reason fails to
compile until it has copy. `message` keeps a diagnostic for the log — and now
reads like one (`'Refused: the parent already holds cards.'`) rather than like
user copy that nothing was allowed to show.

### A rule the UI predicts and the repository enforces belongs in one function

UC-09 was implemented **twice** in Deck: as a pure function behind the move picker,
and again as eight `ConflictFailure` throws inside `moveDeck`, with no import
between them. Two spellings of one rule set, free to drift, and only the first had
tests.

The fix is not to move the rule up out of `data/`. The guards must run **inside**
`runInTransaction` so a refused write leaves no trace and a concurrent move cannot
slip between the check and the write — a use case above the repository would put
that check outside the transaction. That constraint is real and it is why the rules
were there.

What separates cleanly is the **decision** from the **fact-gathering**, because the
two callers gather differently:

- the picker has every deck in one query and derives depth in memory;
- `moveDeck` asks SQLite for each fact separately, inside the transaction.

So the shared function takes *facts*, not a tree:

```dart
DeckMoveRejection? deckMoveRejection({
  required DeckEntity source,
  required DeckEntity target,
  required bool isTargetInSourceSubtree,
  required SchedulerType? sourceRootScheduler,
  ...
})
```

Both callers reach it, the order of checks is defined once — so the picker and the
write path report the same reason for the same situation — and the rule is pure, so
all eight rejections are tested with no database and no widget. One of the eight
(`sourceIsRoot`) previously existed only in the repository, where the picker could
never see it.

`deck_move_rule_test.dart` also asserts that **every enum value is reachable**
through the function. A value with no rule producing it is a reason that can never
be shown, which reads as coverage in the ARB file.

### Adding a table or a column

The migration foundation is built and needs nothing from a new feature except
that it be used:

- `AppDatabase.migration` has `onCreate` and, in `beforeOpen`,
  `PRAGMA foreign_keys = ON`. That pragma is not decoration: SQLite defaults FK
  enforcement **off per connection**, so without it every `ON DELETE CASCADE` in
  the schema is a comment and deletes silently leave rows nothing can reach.
  `migration_test.dart` and `schema_test.dart` both read the pragma back rather
  than trusting the declaration.
- **`drift_schemas/drift_schema_v1.json` is committed**, and
  `SchemaVerifier.startAt(1)` asserts the `.drift` sources still build exactly
  that. This is the piece that cannot be recovered once the source moves on, and
  it is what makes the first real migration testable at all.
- There is **no placeholder `onUpgrade`**, and a test asserts
  `GeneratedHelper.versions == [1]`. A handler written against a version that does
  not exist reads like a decision and is a guess.

So, for a feature that changes the schema: bump `schemaVersion`, write the real
`onUpgrade` step, dump the new snapshot, and add the data-preservation test
(v1 rows still readable after migrating to v2). Until a v2 exists there is nothing
to assert — the harness is proven at v1, which is as far as honesty goes.

## Errors

`Failure` is the only error type that crosses the repository boundary. Every
repository method runs inside a guard that rethrows domain failures untouched and
maps anything else through `mapDatabaseError`. Streams too — `handleError`, or a
raw `DriftWrappedException` reaches a widget.

`Failure.message` is a **sanitized diagnostic string, not a UI API.** It is safe
to print — into a log, a test failure, a debugger — and it is deliberately not
localized, because `core/` and `domain/` cannot reach the ARB bundle. Production
UI therefore maps the failure **type** to ARB copy and never renders `message`; a
screen that did would show English to a Vietnamese user with no test failing
anywhere. `cause` is for logs only and is never rendered at all.

There is no "fall back to `message`" rule, on purpose: a fallback like that only
ever fires on the error paths nobody looked at, which is precisely where an
untranslated diagnostic would surface.

**The five distinctions, and where each is decided.** `core/error/failure.dart`
has nine subtypes; five of them carry different meaning to a user, and the split
happens in two places rather than one:

| Distinction | Decided by |
|---|---|
| validation | the repository's own guard, *before* the write — 25 explicit `ConflictFailure`/`NotFoundFailure` throws across Deck and Card |
| not found | a guard, or a foreign-key violation (the row vanished between the check and the write) |
| conflict / duplicate | a primary-key or unique violation — the one the user can act on |
| database | any other SQLite error, plus `NOT NULL` and `CHECK` violations |
| unexpected | an error with no persistence origin at all |

**Read the result code, not the message.** `mapDatabaseError` classifies a
constraint violation by `SqliteException.extendedResultCode` — 1555/2067 for
uniqueness, 787 for a foreign key, 1299/1811 for `NOT NULL`/`CHECK`. Verified
against a real database. A text match cannot do this job: all three kinds put the
literal `constraint failed` in their message, so matching the prose lumps together
the one case the user can act on with the two they cannot. Doing that told the user
"choose a different name" for a deck that had been deleted, and for a `NOT NULL`
bug they had no part in.

A text fallback stays for errors arriving without a code, and it classifies by kind
too — a fallback that is more optimistic than the primary path is a fallback that
hides the difference it exists to preserve.

`sqlite3` is therefore a **direct** dependency, not a transitive one: the file whose
stated job is to know what a persistence exception looks like should say so in
`pubspec.yaml`. Import `package:sqlite3/common.dart`, never `sqlite3.dart` — the
latter pulls in `dart:ffi` and web is a required build target (AD-04).

**On the read path the distinctions collapse to two, and that is correct.** A read
can be "the thing is gone" (offer a way back, not a retry that will fail forever) or
"the read failed" (offer a retry). `deck_detail_screen.dart` tests
`error is NotFoundFailure` for exactly that. The list screen has one branch because
a missing list is an empty list, not an error. This becomes a compiler-checked
switch at M9, when a network read failure will deserve copy of its own — not
before, because a switch whose every branch returns the same string is machinery
without a decision inside it. See `deck_labels_widget.dart` for the
switch, and `MxAsyncView` for why no shared default error UI exists.

## Presentation

- `MxContentShell` for the screen; the `Mx*` component for anything it contains.
  No raw `Card`, styled `ListTile`, bare button, or hand-rolled empty/error
  surface when an `Mx` equivalent exists.
- no literal colour, text style, spacing, radius or duration — `ui_surfaces` is
  scoped for exactly that
- no user-visible string outside ARB; every key needs a `description`, and
  `placeholders` must come **before** `description` in the metadata block or the
  i18n rule reads the entry as undescribed
- a screen composes; it holds no query and no business rule
- a feature widget with a real second responsibility gets its own
  `_widget.dart` file **inside the feature** — never in `shared/`, which must not
  know a domain type

### Promoting something to `shared/` — the different bar

A bad feature widget costs one screen. A bad shared component costs every screen
that adopts it, and the cost arrives later, when changing it means touching all of
them. Five rules, each one measured against the twelve `Mx*` components rather
than asserted:

**1 · No state coupling, at all.** All twelve are `StatelessWidget` — no
`ConsumerWidget`, no `WidgetRef`, no provider read anywhere. The single
`flutter_riverpod` import in `shared/` is `mx_async_view.dart` taking an
`AsyncValue<T>` as a *type*; it never touches `ref`. A shared component receives
data through its constructor and reports through callbacks. Check it with:

```bash
git grep -nE "Consumer|WidgetRef|ref\.(watch|read|listen)" -- lib/shared
```

**2 · No raw `Color` or `TextStyle` parameter. Ever.** This is the refusal that
keeps a design system a system, and it is the one most often argued away as
flexibility. A `Color? backgroundColor` means the third feature paints a button a
colour the theme never approved, and by then the parameter has four callers and
cannot be removed. The sanctioned escape hatch is a **closed variant enum** —
`MxActionButtonVariant`, `MxConfirmDialogVariant`, `MxActionSheetActionVariant` —
so a new appearance is a decision made once in the theme rather than at a call
site. `git grep -nE "final (Color|TextStyle)\??" -- lib/shared` returns nothing,
and it must stay that way.

**3 · Slots where the variation is a widget, not a flag.** `MxListTile` takes
`Widget? leading` / `Widget? trailing` so one feature can pass a chevron, another a
switch, another a price. `MxContentShell` takes `List<Widget>? actions`.
`MxAsyncView` takes three builders. What none of them take is a boolean that
selects between two layouts — that is the shape a mega-widget grows from.

**4 · Paired optional parameters get an `assert`.** `MxEmptyState` had
`actionLabel` and `onAction` both optional, and the build read
`if (actionLabel != null && onAction != null)`. Passing one without the other
**dropped the button silently**: the screen looked deliberately action-free, no
exception, no failing test. `MxErrorState` had the same shape with
`retryLabel`/`onRetry`, which is worse — an error the user can read and cannot act
on. Both now assert the pair.

Worth knowing about `const` constructors and asserts: at a `const` call site the
assert is evaluated by the **analyzer**, so a violation is
`const_eval_throws_exception` at compile time rather than a runtime failure. Since
screens build these as `const`, most violations never reach a test run. It also
means the test for the assert must use a non-`const` invocation — a `const` one
fails `flutter analyze` instead of passing.

**5 · The stress suite, not a gallery screen.**
`test/shared/widgets/mx_stress_test.dart` renders **every** component at 320x640,
`TextScaler.linear(2.0)`, with Vietnamese copy long enough to wrap, in light *and*
dark, and asserts two things: `takeException()` is null, and
`meetsGuideline(androidTapTargetGuideline)` passes. Before it existed the tap-target
guideline ran for two of twelve components.

The Vietnamese copy is not decoration. It is one of the two shipped locales, runs
~25% longer than the English for the same sentence, and its diacritics raise the
line box — a Column sized against English overflows there and nowhere else.

A `SharedWidgetGallery` **screen** was considered and rejected: it would be
production code needing an MX-VIS-001 audit companion, it would ship inside the
app, and nothing would fail when it rotted. The suite runs on every commit and
names the component that broke. It also carries a coverage assertion — the specimen
list is diffed against `lib/shared/widgets/`, so a new component cannot join the
folder without joining the suite. That assertion caught a missing `MxContentShell`
on its first run.

**6 · A component that animates forever gets a `RepaintBoundary`.** Two do:
`MxLoadingState` and a submitting `MxActionButton`. A `markNeedsPaint` travels up
to the nearest repaint boundary, so without one that is the enclosing layer and
*everything sharing it* repaints on every frame of the spin, at 60fps, for as long
as the spinner is on screen.

Measured rather than assumed. A sibling `CustomPaint` beside `MxLoadingState`, over
10 animation frames:

| | extra sibling paints |
|---|---|
| before | **10** — one per frame |
| after | **0** |

The button case matters more than the full-screen one: that spinner sits inside a
form or a dialog, so the fields the user is still looking at were being repainted
to move an arc. `mx_repaint_isolation_test.dart` pins both, and counts paints
rather than measuring milliseconds — a paint count is deterministic, and a timing
assertion in CI is a flaky test with a performance-shaped name. It also asserts the
idle button as a control, so the test cannot pass by measuring nothing. The 56
goldens are unchanged: a repaint boundary alters layers, not pixels.

`const` needs no rule here. `analysis_options.yaml` promotes
`prefer_const_constructors`, `prefer_const_declarations` and
`prefer_const_literals_to_create_immutables` to **error**, so a missing `const` is a
failed build rather than a review comment.

`Opacity` needs no rule either, and the usual advice to avoid it does not apply to
the one use in `shared/`. `MxActionButton` wraps its hidden label in
`Opacity(opacity: 0, alwaysIncludeSemantics: true)`, and `RenderOpacity.paint`
returns before painting the child when alpha is 0 (`proxy_box.dart`) — no
`saveLayer`, no child paint. The saveLayer cost the advice is about belongs to
*fractional* opacity. `alwaysIncludeSemantics` is not optional there: at alpha 0 the
subtree leaves the semantics tree, and the button announced as "button, disabled"
with no name.

Nothing in `shared/` owns a controller. `MxTextField` takes a
`TextEditingController` from the caller, which is correct rather than lazy — the
draft belongs to the widget that owns the form, for the reasons in the success
policy above. If a shared component ever needs an `AnimationController`, it becomes
a `StatefulWidget` and disposes it there; a caller must never be handed a lifecycle
it did not ask for.

One asymmetry to keep in mind while reading it: **components pass, and screens are
where the caller can still get it wrong.** `MxContentShell.isScrollable` defaults
to `false` and has to — a body that already scrolls (`ListView`) must not be nested
in another scroll view, which fails outright rather than overflowing. A fixed body
that forgets to opt in overflows silently, and only at large text scale or on a
short screen. The Deck screens each carry a `320 x 2.0` case for this reason; a new
screen should too, and nothing currently forces it.

### Platform adaptivity — not now, and the reason is not preference

**There is no `ios/` directory.** Only `android/` and `web/` (AD-04: Android is the
release target, web is the E2E channel, iOS is deferred). A `Switch.adaptive` or a
`CupertinoAlertDialog` branch would be a code path that no build target can produce
and no test can execute — dead code that looks like diligence, and that doubles the
golden and audit surface for a platform the project does not ship.

What is *not* deferred, because web is a real build target:

- **Safe area** is handled: `MxActionSheet` and `MxContentShell` wrap in `SafeArea`,
  and the navigation bar is a Scaffold `bottomNavigationBar`, which subtracts its
  own height from the body's `MediaQuery` and pads for the home indicator.
- **Focus** is themed explicitly — `app_theme.dart` resolves `WidgetState.focused`
  for buttons, inputs and the nav indicator, and `app_theme_test.dart` asserts the
  focus-ring colour. That is the keyboard story, and it is the one that matters for
  a Playwright suite driving the web build.
- **Hover** falls back to Material's default overlay. It works and it is not
  asserted anywhere — a deliberate gap, not an oversight, since no production
  target has a pointer.
- **Scrollbars** come from `MaterialScrollBehavior`, which adds them on web and
  desktop without configuration.

When iOS is picked up, the seam is the theme and the `.adaptive()` constructors —
not a `Platform.isIOS` branch inside a component. Nothing in `shared/` reads
`Platform` or `defaultTargetPlatform` today, and that is worth keeping.

### Localization inside a shared component

**A shared component never reads ARB and never carries a default string.** Every
label is a required or optional parameter documented "already-localized", including
the ones most likely to be defaulted — `confirmLabel`, `cancelLabel`, `retryLabel`,
`actionLabel`. `git grep -nE "this\.[a-zA-Z]+ = '" -- lib/shared` returns nothing,
and it must keep returning nothing: a default `'Cancel'` is a string that ships in
English to every locale and that no ARB file owns, so no translator ever sees it.

Two enforcers, and they cover different ground: the guard's i18n rule runs on
`lib/features/*/presentation` and `lib/shared`, while
`test/l10n/no_hardcoded_strings_test.dart` scans **all** of `lib/` — including
`lib/app/**`, which the guard rule deliberately skips and which is where the two
hardcoded strings it once had actually lived.

Counts go through ICU plurals in the ARB (`{count, plural, =0{} =1{} other{}}`), not
through string concatenation in Dart. There is no `NumberFormat` or `DateFormat`
anywhere yet because no component displays a formatted number or date — Review (M5)
is where intervals, due dates and streaks arrive, and that is when locale-aware
formatting becomes a real requirement rather than a precaution.

## Tests, and the level each belongs at

| What | Where | Against |
|---|---|---|
| SQL, cascade, transaction, rollback, invariants | `test/features/<f>/data/` | **real in-memory SQLite** — never a mocked executor |
| pure rules (validation, eligibility, arithmetic) | `test/features/<f>/domain/` | nothing — plain input/output |
| state machine, double-submit, failure mapping | `test/features/<f>/presentation/` | a fake of the **domain contract** |
| screen states, action matrix, responsive, semantics | `test/features/<f>/presentation/` | the same fake |
| routes, deep links, back, branch state | `test/app/router/` | the real router |
| colour coverage per state × theme | `test/visual_audit/screens/features/<f>/` | strict, through the real router |

**Do not drive a real Drift database from a widget test.** The stream
notification timer is still pending when the tree is torn down, and
`flutter_test` fails the test for that rather than for the behaviour. Assert
persistence in the data tests, assert the UI with a fake.

Deck's counts, as a size reference: 11 aggregate/due-parity integration · 16
domain · 12 read controller · 38 write controller · 49 widget · 6 route · 16
strict audit states.

A fake lives in `test/features/<f>/presentation/support/` and implements the
**domain contract**. Reads are supplied as *builders*, not values: a
single-subscription stream can only be listened to once, and retry listens twice.
Writes record their arguments so a widget test can assert what the form sent.

Keep files under 400 lines and 500 logical lines — `common.no_large_source_file`
and `common.max_file_lines`. Split at group boundaries, sharing the preamble, so
no fixture exists twice.

## Seeing what the app is doing

Three things are wired up already. All three are diagnostics, and all three are
constrained by the same rule, so it is worth stating once: **AD-08 forbids logging
card content at any level, and explicitly permits IDs.** A diagnostic that prints
a value is the most natural thing to write and the easiest privacy leak in the
codebase, because it is added while debugging and read only after release.

**Provider failures — `core/state/provider_observer.dart`.** Installed in
`bootstrap`, failures always, state transitions only when
`EnvConfig.logLevel == LogLevel.debug`. The asymmetry is earned: Riverpod 3 retries
a failed provider ten times with a backoff reaching 6.4 s, showing `AsyncLoading`
throughout — so without this, one broken read is thirteen seconds of spinner and
no exception in the log. `providerDidFail` fires on every attempt, which makes it
self-describing. A transition prints the **type** of each value, never the value:
`AsyncData<List<DeckEntity>>(37)`, with a list length because "3 → 0" is the
question and a count is not content.

**SQL — `core/database/query_log_interceptor.dart`.** Statement text, elapsed
microseconds, row count, and the `BEGIN` / `COMMIT` / `ROLLBACK` around a
transaction. Debug builds only, gated on `kDebugMode` rather than `EnvConfig`
because a compile-time constant lets the tree shaker remove it from release output
entirely.

Nine of the fourteen `QueryInterceptor` hooks are overridden. The three transaction
boundaries are not optional decoration: statements *inside* a transaction are
intercepted, so without them a rolled-back write logged its inserts and their row
ids and then went silent — byte-identical to a successful write. The log did not
merely omit the rollback, it asserted the opposite. That matters here because
`createCard` writes a card and its review state as one unit (BR-09) and reset
writes a generation change as one (BR-11); "did this commit" is the question those
operations exist to answer. The remaining five hooks (`dialect`,
`transactionCanBeNested`, `beginExclusive`, `ensureOpen`, `close`) stay at their
pass-through defaults — no I/O to time, or once per connection where a line is
noise.

> **Do not set `driftRuntimeOptions.debugPrint = true`.** It is the obvious answer
> and the wrong one: drift's own logging prints bound variables next to the
> statement, so the first `INSERT INTO cards` puts a flashcard's front and back
> into the log. The interceptor never reads `args` at all — a structural omission
> rather than a rule to remember — and
> `test/core/database/query_log_interceptor_test.dart` proves it by inserting
> content that would be unmistakable in the output.

Two caveats, both asserted in tests so nobody rediscovers them the slow way: a
*failed* statement is not logged (it travels to the repository, which maps it to a
`Failure`; logging both makes one problem look like two), and drift's own
`onCreate` / `beforeOpen` statements are invisible because drift runs them
underneath any interceptor — so `CREATE TABLE` and `PRAGMA foreign_keys = ON` never
appear. `test/database/migration_test.dart` covers those by reading the schema and
the pragma back out of SQLite, which is better evidence than a log line.

**Fakes — `test/features/<f>/presentation/support/`.** Already the standard for
widget and controller tests, described above. There is no Widgetbook or Storybook
and none is proposed: component rendering is already covered by 26 goldens and 16
strict visual-audit states, and a third rendering surface would be a third place
for a component to look right while the app looks wrong.

## Before you clone — the honest checklist

```bash
# nothing reaches into another feature
git grep -nE "import '[^']*features/[a-z_]+/(data|presentation)/" -- lib/features

# no literal user-visible string
flutter test test/l10n/no_hardcoded_strings_test.dart

# every gate the project actually has
.claude/skills/flutter-workflow/scripts/dod_check.sh
.claude/skills/flutter-workflow/scripts/check_docs.sh --db build/invariant_fixture_clean.db
```

### The real footprint of a new feature

"Nothing outside the feature folder" is false, and stating it that way hides
work. A new feature touches these, and only these:

| Path | Why |
|---|---|
| `lib/features/<feature>/` | the slice itself |
| `lib/app/di/<feature>_repository_provider.dart` | the composition root — `presentation/` may not import `data/`, `domain/` may not import Riverpod, `core/` may not import a feature, so nothing else *can* hold it |
| `lib/app/router/route_names.dart` · `route_paths.dart` · `app_router.dart` | the route, its name, and its path-parameter constants |
| `lib/l10n/app_en.arb` · `app_vi.arb` | every user-visible string, both locales, each with a description |
| `test/features/<feature>/` | domain · data on real SQLite · controller · widget |
| `test/visual_audit/screens/features/<feature>/` | one strict companion per production screen (MX-VIS-001) |
| `docs/wbs.md` | one entry, updated in the same commit as the code |
| `lib/core/database/tables/*.drift` · `queries/*.drift` | **only if** the feature needs a table or query that does not exist. A new query is additive against schema v1; a new *table* is a migration and a separate decision. |

The test that matters is not "did I avoid touching anything" — it is **"did I have
to touch `core/` or `shared/` to make the second feature work?"** If yes, that
thing belonged there before the clone, and moving it is part of finishing feature
one rather than part of starting feature two. Three things failed exactly that
test and were moved or extracted: `clock_provider`, `retry_policy`, and
`MxAsyncView`.

## Practical patterns — the four things feature 1 got asked about

These are the parts that are cheap to get right once and expensive to retrofit.
Each entry says what `features/deck` actually does, so the answer is checkable
rather than aspirational.

### Route arguments, and returning from a form

Route args go in as a **family provider parameter**, not through a widget
constructor that then pushes them into state:

```dart
@Riverpod(retry: noAutomaticRetry)
Stream<DeckDetail> deckDetail(Ref ref, String deckId) { ... }
```

The screen takes the id, the provider takes the id, and the id is read from
`state.pathParameters[RoutePathParams.deckId]` in exactly one place — the route
table. Path-parameter names are constants because the two halves (written at the
call site, read in the route table) live in different files and a typo compiles.

**Nothing returns data through `Navigator.pop`.** A form writes to the database
and the list re-renders because its `watch()` stream re-emits. `pop` carries only
a UI choice — which row of an action sheet was tapped, whether a discard was
confirmed — never a record:

```bash
git grep -n "Navigator.of(.*).pop(" -- lib
```

Every hit should be a sheet or dialog dismissal. A record coming back that way is
a second source of truth racing the stream, and the two disagree the first time a
write is slow.

### Forms

Simple form: the widget owns a `TextEditingController`, and the controller
(Riverpod) sees the value only at submit. That is what makes "a failed write keeps
the input" true without anyone implementing it — the text never left the widget.

Reset happens **on open**, from the tap that shows the form, not from `dispose`.
Two reasons, both real: Riverpod refuses a provider mutation inside `build`,
`initState` or `dispose`; and a reset scheduled from `dispose` races the
controller's own teardown, so an autoDispose provider with no listeners left is
already gone by the time the callback runs, and touching its `Ref` throws.

A multi-step or cross-field form would move the field values into the notifier
state, beside the field problems. Deck did not need it — one name and one radio
group. Do not reach for it before a form has state that must outlive its widget.

#### Success has two kinds, and the difference is not optional

Every Deck form closes when it succeeds, so the draft in the widget's
`TextEditingController` vanished with the widget and nobody had to clear it. A
form with *Save and add another* stays open, and cloning Deck's pattern into one
reproduces three bugs at once:

1. the transition to "done" pops the sheet, closing an editor the user asked to
   keep open;
2. if it does not close, the controller still holds the text of the record that
   was just saved — and `reset()` on the notifier cannot reach widget-local state;
3. `canSubmit` was `!isSubmitting && !isDone`, so the *next* entry could not be
   submitted at all until something called `reset()`.

`core/state/submit_outcome.dart` names the distinction so none of the three can
happen quietly:

```dart
enum SubmitDisposition { close, addAnother }        // passed in
enum SubmitOutcome { savedAndClose, savedAndContinue } // reported back
```

**Only the creators take a disposition.** Rename, delete, reset and move have
nothing to add another of, so they do not accept one and always report
`savedAndClose` — the type makes the wrong call impossible rather than merely
unlikely. `close` is the default, so a form that does not care is unchanged.

The submit state exposes the two questions a widget actually asks, rather than
making every call site re-derive them from the enum:

```dart
bool get canSubmit      => !isSubmitting && outcome != SubmitOutcome.savedAndClose;
bool get shouldClose    => outcome == SubmitOutcome.savedAndClose;
bool get shouldClearDraft => outcome == SubmitOutcome.savedAndContinue;
```

Note `canSubmit`: a `savedAndContinue` success deliberately leaves it **true**.
Only `savedAndClose` latches it shut, and only because the form is on its way out.

**The widget half of the contract.** React to the *transition*, never the value —
`ref.listen`, or `didUpdateWidget` comparing against the old state. On
`shouldClearDraft`, in this order:

1. clear the draft controllers the widget owns;
2. clear the field errors;
3. return the submit state to idle (`reset()`);
4. move focus back to the first field.

Clear **only after** the repository confirmed the write. A draft cleared
optimistically is a record the user typed and lost. A failure — validation or
persistence — reports **no outcome at all**, so neither `shouldClose` nor
`shouldClearDraft` fires and the input survives untouched.

Do not move the `TextEditingController` into the notifier to make add-another
easier. The draft stays widget-local; what the notifier gains is the outcome, not
the text.

Nothing is handed back through `Navigator.pop` in either case. The list behind
re-renders because its `watch()` stream re-emitted.

**Test matrix.** `test/features/deck/presentation/submit_disposition_test.dart`
covers the state machine, and it exists in the Deck feature even though Deck has no
add-another form — because M4.11's card editor does, and the bugs live in the state
machine rather than in the widget:

| Case | Expected |
|---|---|
| disposition omitted | `savedAndClose`, `shouldClose`, `canSubmit == false` |
| rename / delete / reset / move | always `savedAndClose` |
| `addAnother` succeeds | `savedAndContinue`, `shouldClose == false`, `shouldClearDraft` |
| `addAnother` twice in sequence | both writes land, no `reset()` in between |
| two concurrent taps, one entry | one write — the double-submit guard still holds |
| `close` twice | one write; the second is latched out |
| validation failure | no outcome, draft untouched |
| persistence failure | no outcome, `canSubmit` true so it can be retried |
| `reset()` after `addAnother` | back to the idle state |

The widget half — that the controllers are actually cleared and focus actually
moves — belongs to the first form that has one. Asserting it against a form that
does not exist would be testing a stand-in rather than the thing.

### invalidate vs refresh

`ref.invalidate` — drop the state and let the next read rebuild it. This is the
retry button: nothing needs the new value as a return, and the rebuild reads it
anyway.

`ref.refresh` — invalidate **and** read immediately, returning the new value. Use
it only when the caller needs that value in the same statement.

Deck uses `invalidate` everywhere and `refresh` nowhere, which is the expected
ratio: a `refresh` whose result is discarded is an `invalidate` with extra steps.

### Search, filter and debounce

Not present — deck search is out of MVP scope. When it lands, the debounce belongs
**in the provider**, not in the `TextField`: the widget reports every keystroke and
the provider decides how often to ask the database. Debouncing in the widget ties
the query cadence to one input control, and the second caller — a filter chip, a
restored search term, a deep link — skips it silently.

### Stream subscriptions

Every stream reaches the UI through `ref.watch` on a stream provider, so Riverpod
owns the subscription and cancels it on dispose. There is no manual `.listen` and
no `StreamSubscription` field anywhere in `lib/`:

```bash
git grep -nE "\.listen\(|StreamSubscription" -- lib | grep -v "ref.listen"
```

That should stay empty. A notifier holding its own subscription has to cancel it
in `dispose`, and the leak when it does not is invisible until an unrelated test
hangs.

## Two things deliberately NOT built

Both are standard advice that does not fit a local-first app. Skipping them is a
decision, not an omission.

**No shimmer or skeleton loading.** Skeletons exist to mask network latency. These
reads are local SQLite and finish in single-digit milliseconds, so a skeleton
would render a fake layout for less than a frame and then swap it — motion that
says "slow" about something that is not. `MxAsyncView` uses a labelled spinner.
Revisit when a read crosses a network; `dio` is deliberately absent today (AD-05).

**No optimistic UI and no rollback.** An optimistic update buys the gap between
"now" and "when the write lands". For a Drift write on the same isolate that gap
is about a millisecond, after which the `watch()` stream re-emits the real row.
Paying for it means a parallel copy of the truth, a rollback path, and a window
where the screen shows something the database never accepted — to hide latency
that does not exist. Revisit alongside sync (AD-01 defers it), where the window is
genuine.

## Known guard false positive

`memox.state_management.no_generated_ref_subclass` matches the two-argument
`build` signature `ConsumerWidget` requires, reading Riverpod 3's widget-side ref
type as a Riverpod 2 generated `Ref` subclass. It fires on every `ConsumerWidget`
anyone writes.

Work around it the way Deck does — a plain widget wrapping `Consumer`, which is
better rebuild scoping anyway — and fix the rule upstream in the guard
repository, which this repo may not edit.
