# What memox-v7 has already settled

Read this before proposing a structural change. Everything below is in the code
today; some of it deliberately differs from generic Drift guidance, and the
difference is a decision, not an oversight. Changing any of it is a task of its
own, with its own WBS entry — never a drive-by inside feature work.

## The layout

```
lib/core/database/
├── app_database.dart            @DriftDatabase(include:), schemaVersion, MigrationStrategy
├── connection.dart              the ONLY file in lib/ that opens a database (AD-08)
├── app_database_provider.dart   @Riverpod(keepAlive: true), closes on dispose
├── query_log_interceptor.dart   debug-only statement logging, tree-shaken in release
├── tables/                      decks.drift · cards.drift · tags.drift · study.drift
└── queries/                     deck.drift · card.drift · tag.drift · study.drift

lib/features/<feature>/data/
├── datasources/                 <feature>_dao.dart · *_data_source.dart
├── mappers/                     row → entity, one file per shape
└── repositories/                <feature>_repository_impl.dart

drift_schemas/                   drift_schema_v1.json · drift_schema_v2.json
test/drift/generated/            schema.dart · schema_v1.dart · schema_v2.dart (verifier)
test/database/                   migration_test.dart · invariants_test.dart
```

**Tables and queries are central, DAOs are feature-owned.** A generic
feature-first checklist will tell you to put `deck_schema.drift` under
`lib/features/deck/data/local/`. This project does not, and the reason is that
the schema is a single interlocking object: `cards` references `decks`,
`review_history` references both, and the recursive deck query walks a tree that
three features read. Splitting the `.drift` files by feature would put
cross-feature foreign keys in whichever folder won an argument, while the DAO —
the part that genuinely belongs to one feature — is already feature-owned.

If you are working in a *different* repo, the feature-owned layout is fine. Here,
do not migrate to it as part of unrelated work.

## Connection and PRAGMA

- Opened through `driftDatabase()` from `drift_flutter`, which uses a background
  isolate on native and the WASM worker on web. One call handles both because web
  is the E2E channel (AD-04) and must genuinely open.
- `PRAGMA foreign_keys = ON` in `beforeOpen`. Without it every
  `ON DELETE CASCADE` in the schema is a comment — SQLite defaults enforcement
  **off per connection**, so deletes would silently orphan rows.
- **No WAL, no `busy_timeout`, no read pool, no `synchronous` override.** Not an
  omission: this app has one writer and no read isolates, so the tuning would buy
  nothing measurable and would cost the web build (WAL does not work the same way
  there). Add one only with a benchmark attached, and put it in `connection.dart`
  so "which PRAGMAs are set" keeps a single answer.
- Nothing in the connection path logs a path, an argument or a row. Card content
  and learning history are private (AD-08); a database log leaks all of it at
  once. Debug builds log statement *text* and duration only.

## Identity, time and enums

| Contract | What this repo does | Why it matters later |
|---|---|---|
| Primary key | `TEXT` UUID, client-generated, from day one | The backend cannot renumber rows a device already created |
| Ownership | nullable `owner_id` on user tables | Auth arrives without a migration (AD-03) |
| Enums | stable lowercase text codes — `eight_box`, `sm2`, `unset`, `card`, `deck`, `scheduled`, `relearning` | An ordinal would change meaning the day a value is inserted in the middle |
| Timestamps | `DATETIME` columns; **no `build.yaml`**, so Drift's default storage applies | See the warning below |

**The `DATETIME` storage mode is an open contract.** With no `build.yaml`, Drift
stores `DATETIME` as Unix epoch **seconds** and hands back a `DateTime` with no
UTC flag preserved. That is workable while everything is local, and it becomes a
decision the moment a backend exists: ISO-8601 text keeps the offset and debugs
easily, epoch integers sort and compare uniformly. Changing the mode after
release is a data migration over every timestamp column, so **pin the choice
before the first sync ships**, not after. If you are the one who settles it,
write it into `docs/architecture.md` and add the `build.yaml` option in the same
commit as the migration.

## Reads, windows and pagination

The card list uses a **growing `LIMIT` window** — 50, then 100, then 150 — re-read
whole on every change, with no `OFFSET` and no cursor. A generic checklist will
recommend keyset pagination for lists that grow, and it is right in general.
Here the trade was measured and made deliberately (M4.10ar): re-reading the whole
window means an insert above it cannot duplicate or drop a row the way a shifting
offset does, and the cost is bounded by the *window*, not the deck (1.75 / 4.29 /
16.87 ms at 50 / 200 / 800 rows).

Keyset pagination is not banned — it is deferred with a stated trigger: the first
flow that seeks deep without reading what comes before it. The composite index
`(deck_id, created_at, id)` is already shaped for it.

**Counts are a separate statement from rows.** `COUNT(*) OVER ()` beside a
`LIMIT` forces SQLite to materialise every matching row, which destroys the early
stop that the `LIMIT` plus index exists to buy. The list and its count share one
`$predicate` so they can never disagree about what "due" means.

## Two traps this schema has already paid for

**Resolve the root through `root_deck_id`, never `COALESCE(parent_deck_id, id)`.**
That expression means "my parent, or me if I have none", which is the correct
root only in a one-level tree — from the third level down it silently returns the
level-2 deck. It is dangerous precisely because it works in every test fixture
anyone writes by hand. Every deck carries a denormalised `root_deck_id`,
including the root itself, so the resolution is a column read rather than a
recursion inside the hottest query in the app.

**Moving a subtree rewrites `root_deck_id` for every node in it, in one
transaction.** Miss a node and it points at the wrong root: queries still run and
merely return less than they should, which is corruption that reports itself as a
missing card rather than as an error. `docs/data-model.md` carries the query that
detects it, and `test/database/invariants_test.dart` runs it.

## What this schema does *not* do

Knowing the negatives prevents half of the bad suggestions:

- **No soft delete.** There is no `deleted_at` anywhere. If you introduce one,
  every existing query becomes wrong until it filters — that is a project-wide
  change, not a column.
- **No sync bookkeeping.** No `is_synced`, no `version`, no tombstones. Deferred
  on purpose (AD-01) and cheap to add later precisely because IDs, timestamps and
  layer boundaries are already sync-shaped.
- **No encryption.** A door left open in `connection.dart`, not a feature.
- **No `build.yaml`.** Adding one changes code generation for the whole repo —
  treat it as a schema-level decision.
- **No SRS columns in `cards`.** Content, schedule and history are three tables
  with three lifetimes; a "just one column" that puts a due date on `cards` breaks
  reset (BR-41) and BR-10 at once.

## Invariants are executable here

`test/database/invariants_test.dart` runs the project's data invariants against a
real SQLite database — every card has exactly one review state, no deck nests
deeper than ten levels, no review state carries a stale generation, and so on.
They are the reason a schema change can be trusted beyond the diff.

**A new invariant belongs in that file, not in a comment.** If a change
introduces a rule the schema cannot express as a constraint, the invariant test
is where it becomes checkable. `invariant_queries.dart` holds the SQL so the test
reads as a list of claims.
