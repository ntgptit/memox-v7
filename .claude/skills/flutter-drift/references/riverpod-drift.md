# Drift and Riverpod: lifetime, streams, transactions

## Provider lifetime matrix

| Provider | Lifetime | Why |
|---|---|---|
| `appDatabase` | `@Riverpod(keepAlive: true)` | Reopening per screen re-runs `beforeOpen` and leaves any held stream listening to a closed executor |
| DAO / data source | keep-alive (or plain `final` inside the repository) | Stateless wrappers around the database; disposing them buys nothing |
| Repository | keep-alive when stateless | Nothing to release, and re-creating it drops nothing useful |
| Query provider (`watch…`) | `autoDispose` (the codegen default) | Leaving the screen should drop the subscription |
| Screen controller | `autoDispose` | Its state belongs to a screen that is gone |

Two hard nos:

- **The database provider is never a `family`.** A `family` mints one instance per
  argument, so two arguments mean two connections to one file — and Drift's
  update notifications do not cross instances, which shows up as "some streams do
  not refresh".
- **The database is never `watch`ed from a widget.** A widget that watches it
  rebuilds on nothing useful and has reached past three layers to do it.

Dispose deliberately:

```dart
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final database = AppDatabase.open();
  ref.onDispose(() => unawaited(database.close()));
  return database;
}
```

`onDispose` takes a synchronous callback, so `close()`'s future has to be
explicitly unawaited or it is discarded silently — which `discarded_futures`
promotes to an error precisely because a database that never finishes closing
locks the file for the next open.

## Streams are the source of truth

A Drift `watch()` re-emits whenever a table it reads is written. That is the
whole reactivity model, and it means:

- **Do not copy a list out of a stream into mutable notifier state.** Two copies
  of the same fact diverge; the one the UI reads is the stale one.
- **Do not manually refresh after a write.** If the stream does not re-emit, the
  dependency is wrong — fix that, do not paper over it with an invalidate.
- **Do not subscribe in a widget.** `ref.watch` on a stream provider is the whole
  API; `listen()` inside `initState` leaks.
- **Keep command state separate from query state.** A write in flight is not the
  data; one `isLoading` shared by both is the bug where a delete spinner appears
  on a rename.

## Stream invalidation

Drift tracks table dependencies for SQL it parsed — everything in `.drift` files
and everything built with the typed API. It cannot track SQL it did not parse.

```dart
// Drift cannot see which tables this reads. Say so, or the stream never updates.
db.customSelect(
  'SELECT COUNT(*) AS total FROM cards WHERE deck_id = ?',
  variables: [Variable<String>(deckId)],
  readsFrom: {cards},          // ← without this it emits once and goes silent
).watchSingle();
```

The same applies in reverse: a raw `customUpdate` / `customStatement` that writes
must declare `updates:` (or the affected tables), or no stream learns anything
changed and the UI keeps showing pre-write data until something else touches the
table.

The reliable way to avoid the whole class of bug is to keep reusable SQL in
`.drift`, where Drift resolves dependencies itself.

Worth testing explicitly, because the failure is silent: insert → expect the
stream emits; update → expect it emits; delete → expect it emits. For a joined
query, write to **both** sides and assert both re-emit.

## Transactions

Use one when several writes form a single invariant:

```dart
Future<void> createCard(...) => _dao.runInTransaction(() async {
  await _dao.insertCard(card);              // content
  await _dao.insertReviewState(state);      // BR-09: exactly one, same transaction
  await _deckDao.lockContentType(deckId);   // BR-62: first child fixes the type
});
```

Rules, each of which exists because breaking it produced a real class of bug:

- **Keep it short.** A transaction holds a write lock; everything else waits.
- **No network calls inside.** The lock would be held for a timeout's duration.
- **No user interaction inside.** A confirm dialog inside a transaction is a lock
  held until someone comes back from lunch.
- **No side effects before commit.** Do not emit an event, write a log line the
  user sees, or navigate until the transaction has returned.
- **Never catch an exception inside and report success.** A rollback that the
  caller is told succeeded is data loss with a green checkmark.
- **Do not wrap a single statement.** It is already atomic.
- **Cross-DAO work must share one database instance** — which is why there is
  exactly one, and why DAOs receive it rather than opening their own.
- **Never let a transaction object escape the data layer.** Presentation cannot
  hold something whose validity ends when the closure returns.

Checks that need the data *as it stands at the moment of writing* — depth limits,
first-child locks, emptiness checks, subtree moves — belong **inside** the
transaction. Hoisting them into a use case for tidiness puts the check outside the
lock, which is a race between the check and the write.

## Batches

For many rows of the same shape, a batch is the right tool: it is atomic like a
transaction and reuses prepared statements, so an import of a thousand cards is
one round of work rather than a thousand.

```dart
await db.batch((batch) => batch.insertAll(cards, companions));
```

A `for` loop of single inserts inside a transaction is the anti-pattern — correct,
but linear in round trips.

## Testing providers over a database

```dart
final container = ProviderContainer(
  overrides: [appDatabaseProvider.overrideWithValue(AppDatabase(NativeDatabase.memory()))],
);
addTearDown(container.dispose);
```

- One fresh in-memory database per test; never share one across tests, because
  order dependence is the hardest test failure to diagnose.
- Always close the database (`addTearDown`), or the suite leaks handles and later
  tests fail for unrelated reasons.
- Override at the **database** provider, not at each repository: the repositories
  under test are then the real ones, which is the point.
- Test the three async states, and test that a command tapped twice does not write
  twice.
