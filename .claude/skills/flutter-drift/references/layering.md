# DAO, data source, repository: who does what

Four types sit between SQLite and a use case, and the reason there are four
rather than two is that each one is where a different kind of change lands. When
they blur, a schema change reaches the UI and a UI change reaches the schema.

```
AppDatabase      opens, composes, migrates. Nothing else.
   ↑
DAO              generated queries, query composition, transactions, batches.
                 Speaks Drift rows and companions.
   ↑
Data source      coordinates DAOs, maps database exceptions to data-layer
                 failures. No domain rules.
   ↑
Repository       maps rows to entities, chooses local/remote, owns cache and
                 sync policy. Returns domain types and `Failure`, only.
```

## `AppDatabase`

Its whole job: open and close, aggregate the schema, declare the migration
strategy, expose DAOs. Every business query it grows is a query no feature owns.

The one in this repo is a `@DriftDatabase(include: {...})` list, a
`schemaVersion`, and a `MigrationStrategy`. Keep it that way — an `AppDatabase`
with a hundred methods on it is the failure mode this split exists to prevent,
and it arrives one convenient method at a time.

## DAO

**May:** call generated queries, compose query builders, run `transaction` and
`batch`, return Drift rows / `Selectable` / typed result classes.

**Must not:** know domain entities, apply domain rules, build SQL strings, return
a UI model.

One DAO per bounded context — not one per table, and not one `CommonDao`. A DAO
per table forces a coordinator above it for every join; a single shared DAO
becomes the `AppDatabase` problem with an extra file.

Write the specific columns. A `Companion` covering the whole row lets a caller
change `front` while meaning to toggle a flag, which is why `setCardFlag` in
`card_dao.dart` writes exactly one column and says so in a comment.

## Local data source

Exists when a read needs more than one DAO, or when the mapping of database
exceptions to failures deserves a home of its own. It is a seam, not ceremony —
`CardListReadDataSource` was split out because the list surface (windowed rows,
filter counts) is a different job from the create/edit/tag/flag writes, and
because the repository file was outgrowing the size guard.

**May:** call DAOs, combine them, translate `SqliteException` /
`DriftWrappedException` into typed failures.

**Must not:** hold domain rules, return Drift rows to the repository's *caller*,
or open anything.

If a feature has one DAO and no exception-mapping to speak of, skip this layer.
An empty pass-through class is worse than no class.

## Repository implementation

**May:** map rows to entities, decide local vs remote, own cache/sync policy,
run cross-DAO work inside one transaction.

**Must not:** build SQL, leak a Drift type upward, or return anything but domain
entities, domain models and `Failure`.

The mapping is the boundary. `cardEntityFromRow` and friends are ordinary
functions with no Drift import in their signature's *output*, which is what makes
them unit-testable and what makes the backend swap possible later.

**Map exceptions here, once.** A constraint violation is not a user-facing
message: it is a `ConflictFailure` with a reason the UI can render in its own
words. `core/error/drift_error_mapper.dart` reads `SqliteException.resultCode` so
that "unique constraint failed" becomes a typed failure rather than a string
somebody parses.

## What may cross each boundary

| Type | DAO | Data source | Repository | Use case | UI |
|---|:--:|:--:|:--:|:--:|:--:|
| Drift row / `Companion` | ✅ | ✅ | receives only | ❌ | ❌ |
| `Selectable` / query builder | ✅ | ❌ | ❌ | ❌ | ❌ |
| `SqliteException` | ✅ | ✅ | caught here | ❌ | ❌ |
| Domain entity / model | ❌ | ❌ | ✅ | ✅ | ✅ |
| `Failure` | ❌ | ✅ | ✅ | ✅ | ✅ |

Read the table as: the first row is why `check_drift.sh` fails a presentation
file that imports `package:drift`, and the last two are why a use case can be
tested with no database at all.

## Streams are mapped before they leave

```dart
Stream<List<CardEntity>> watchCards(String deckId) =>
    _dao.watchCardsByDeck(deckId).map(
          (rows) => rows.map(cardEntityFromRow).toList(growable: false),
        );
```

Mapping inside the stream keeps the reactivity and drops the Drift type at the
same boundary a `Future` would. A repository that returns
`Stream<List<Card>>` — the generated row — has moved the boundary to whoever
listens, and that is always the UI.

## Testing this split

- **Mappers** get their own unit tests, with no database: a row in, an entity
  out, including every nullable and every enum code.
- **DAOs** get tests against `NativeDatabase.memory()` — that is where a
  constraint, a cascade and a transaction rollback are provable.
- **Repositories** get tests that assert the *domain* result and the failure
  mapping, not the SQL.
- **Use cases** get tests with a fake repository and no database at all. If that
  is hard, something below has leaked upward.
