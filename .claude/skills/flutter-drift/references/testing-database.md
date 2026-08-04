# Testing the database

`flutter-testing` owns the general strategy. This file is the database-specific
part: what to test, and which tests are worth writing at all.

The filter to apply: **a test that inserts a row and reads it back proves almost
nothing** — it re-asserts that SQLite works. The tests that earn their place
assert the guarantees you are *relying on*: a constraint rejects, a cascade
deletes, a transaction rolls back whole, a stream re-emits, a plan uses the
index.

## Setup discipline

```dart
final db = AppDatabase(NativeDatabase.memory());
addTearDown(db.close);
```

- One fresh in-memory database **per test**. Sharing one across tests makes
  failures order-dependent, which is the most expensive kind to diagnose.
- Always `addTearDown(db.close)`. A leaked handle fails a *later*, unrelated
  test.
- `NativeDatabase.memory()` for almost everything. Reach for a real file only
  when the thing under test is the file itself — the connection setup, a backup,
  or WAL behaviour.
- Foreign keys are per-connection. If the test database is not built through the
  app's own `MigrationStrategy`, `PRAGMA foreign_keys = ON` has to be set in the
  fixture or every cascade test silently passes.

## What to cover

**Schema guarantees** — the reason the constraint is in the schema at all:

- [ ] `UNIQUE` rejects the duplicate (and the error maps to the right `Failure`).
- [ ] Foreign key rejects an orphan.
- [ ] `ON DELETE CASCADE` actually deletes the children.
- [ ] `ON DELETE RESTRICT` actually refuses.
- [ ] `CHECK` rejects the out-of-range value.
- [ ] `NOT NULL` and every default behave as the migration promised.

**Values that convert** — every lossy boundary:

- [ ] Every enum code round-trips, including one the app does not know if that
      case is reachable.
- [ ] Every timestamp round-trips, including UTC-ness and a value on the far side
      of a day boundary.
- [ ] `NULL` vs empty string stays distinguishable where the domain relies on it.

**Query behaviour**:

- [ ] Ordering is what the query claims, including the tie-breaker: insert two
      rows with the same sort value and assert the order is stable across reads.
- [ ] Aggregates on an empty table return what the code expects — `SUM` gives
      `NULL`, not `0`.
- [ ] Each filter alone, then the combinations that are actually supported.
- [ ] An empty search term / empty collection filter does what the convention
      says (see `dynamic-sql.md`).
- [ ] Pagination neither duplicates nor drops a row across a window growth or a
      cursor step — `card_list_window_test.dart` does this by growing the window
      over a deck and comparing the id sets.

**Plans, for the queries that matter**:

```dart
final plan = await db.customSelect('EXPLAIN QUERY PLAN $sql').get();
expect(plan.map((r) => r.data.values.join(' ')).join('\n'),
       isNot(contains('USE TEMP B-TREE')));
```

This is how "the index is used" stops being a claim. `card_list_window_test.dart`
pins exactly that for the card window: the composite index supplies the order, so
`LIMIT` stops early instead of sorting the deck and putting a lid on it.

**Transactions and batches**:

- [ ] A failure in the middle rolls back *everything*, including the writes that
      already succeeded — assert the database is unchanged, not just that it
      threw.
- [ ] A batch writes all rows and is atomic under the same failure.
- [ ] A transaction that spans two DAOs uses one connection (a test that seeds
      through DAO A and asserts through DAO B inside one transaction).

**Streams** — the failures here are silent, so they need explicit tests:

- [ ] Insert → the watching stream emits.
- [ ] Update → it emits.
- [ ] Delete → it emits.
- [ ] For a joined or subquery-backed read, a write to **each** contributing table
      emits.
- [ ] A `customSelect` with `readsFrom` emits; one without it is the bug this
      test catches.

Use `expectLater(stream, emitsInOrder([...]))` rather than sleeping.

**Migrations** — see `migrations.md`; the short version is: every supported
version to current, assert values and not just counts, then `PRAGMA
integrity_check` and `PRAGMA foreign_key_check`.

## Invariants: assert them both ways

`test/database/invariants_test.dart` runs the project's 15 data invariants
against a real database, and its pattern is worth copying anywhere a rule is
expressed as a query:

1. seed **valid** data → the invariant query returns nothing;
2. seed data with **exactly one** deliberate violation → the same query fires.

The second half is the one people skip, and skipping it is how a query that can
never return a row passes "no violations found" perfectly while enforcing
nothing. Introducing exactly one defect is what proves the query fired on its own
subject rather than on collateral damage from the fixture.

The fixture also has to be deep enough to be honest: this one builds a
three-level tree, because a one-level fixture would let the root-resolution
invariants pass even with the `COALESCE(parent_deck_id, id)` bug that BR-57
forbids.

## Repository and provider tests

- Repository tests assert **domain** results and failure mapping — a constraint
  violation surfacing as `ConflictFailure`, a missing row as `NotFoundFailure` —
  never the SQL that produced them.
- Provider tests override at `appDatabaseProvider` with an in-memory database, so
  the repositories under test are the real ones:

  ```dart
  final container = ProviderContainer(overrides: [
    appDatabaseProvider.overrideWithValue(AppDatabase(NativeDatabase.memory())),
  ]);
  addTearDown(container.dispose);
  ```

- Assert loading → data → error transitions, and that a command tapped twice
  writes once.
- Never depend on test execution order; each test seeds what it needs.

## What not to test

- Drift's own generated code, or SQLite's correctness.
- The exact SQL text a query builder emits — that pins an implementation detail
  and breaks on every Drift upgrade. Assert the *result*, or the query plan.
- Every one of 1,024 filter combinations. Test each filter alone, the
  combinations the product actually offers, and the empty criteria.
