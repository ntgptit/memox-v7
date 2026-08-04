# Migrations

A migration is the only code in this app that runs **once per device, on data you
cannot see, and cannot be retried after it fails halfway**. Treat it accordingly.

## The workflow

```bash
# 1. Before touching the schema — make sure the current version is snapshotted.
ls drift_schemas/                     # drift_schema_v1.json, drift_schema_v2.json …

# 2. Change the .drift files.

# 3. Bump schemaVersion in lib/core/database/app_database.dart.

# 4. Regenerate code and the schema snapshot for the new version.
dart run build_runner build --delete-conflicting-outputs
dart run drift_dev schema dump lib/core/database/app_database.dart drift_schemas/
dart run drift_dev schema generate drift_schemas/ test/drift/generated/

# 5. Write the onUpgrade step.
# 6. Write the data-integrity test.
# 7. Run the suite.
flutter test test/database/
```

`dart run drift_dev make-migrations` automates steps 4–6 (snapshot, step file,
test scaffold) and is the path Drift now recommends for new schema work. This
repo's v1 → v2 step is hand-written and predates that; **do not retrofit it** —
rewriting a released migration is the one thing this document forbids outright.
If you adopt `make-migrations`, do it for the *next* version only, in its own
task, and keep the existing step untouched.

Everything in step 4's output is committed: the snapshot JSON, the generated
verifier under `test/drift/generated/`, and the migration test. The snapshot is
what the test upgrades *from*; without it, "v1 still opens" is a claim nobody can
run, and it cannot be regenerated once the `.drift` files have moved on.

## Rules that do not bend

- **A released migration is immutable.** Not "avoid changing" — immutable.
  Devices that already ran it will not run it again, so an edit means two
  populations with different schemas and one build that assumes both are the
  same.
- **`schemaVersion` only goes up**, one at a time, and every version between the
  oldest supported and the current one must have a snapshot.
- **Never delete user data to make a migration simpler.** If the migration is
  hard, the migration is hard.
- **Never call current application queries inside a migration.** The generated
  API always expects the *latest* schema; running it against a half-upgraded
  database throws or, worse, reads a column that does not exist yet. Use
  `customStatement` / raw SQL for data movement inside a step.
- **Seed data only in `onCreate`** (or gated on `details.wasCreated`). Seeding in
  `onUpgrade` duplicates rows on every existing device.

## Changing a column safely

Adding a nullable or defaulted column is the cheap case, and it is why the v1 → v2
step here is four `addColumn` calls and two `createTable` calls with no row
rewrite: a v1 card upgrades without a value being invented for it.

The expensive cases, and what each one needs *before* the constraint lands:

| Change | Do this first |
|---|---|
| Add `NOT NULL` | add nullable → backfill every row → then enforce |
| Add `UNIQUE` | find and resolve duplicates; decide which row wins |
| Add `CHECK` | find rows that violate it; fix or exclude them |
| Add a foreign key | find orphans; delete or repoint them |
| Rename / drop a column | check indexes, views, triggers and foreign keys that name it |
| Change a type or storage mode | this is a rewrite of every row — plan it as its own task |

SQLite's `ALTER TABLE` is limited; anything beyond add-column/rename is the
twelve-step table rebuild (create new table, copy, drop, rename). Drift's
`TableMigration` does this for you, and it is far safer than hand-writing it.

## Testing a migration

Three separate claims, and passing one does not imply the others:

1. **The schema arrives.** Upgrade from every supported snapshot to current and
   assert the resulting schema matches — that is what the generated verifier in
   `test/drift/generated/` is for.
2. **The data survives with its meaning.** Insert realistic rows at the old
   version, upgrade, then assert on *values*, not just row counts. A migration
   that keeps every row and puts the wrong default in a column passes a count
   check and fails a user.
3. **The invariants still hold.** Run `test/database/invariants_test.dart` after
   the upgrade, not only against a freshly created database.

Test **every supported version to current**, not just the previous one. A user who
skipped three releases runs v1 → v4 in one launch, and that path has its own bugs.

After any migration test, assert the database is structurally sound:

```sql
PRAGMA integrity_check;   -- must return exactly 'ok'
PRAGMA foreign_key_check; -- must return no rows
```

They check different things: `integrity_check` looks at pages, indexes and
constraints; it does **not** validate foreign keys. Running only the first is how
a migration that orphans rows passes.

## When a migration test fails

Read the failure before changing anything — the two common causes need opposite
fixes:

- **Schema mismatch** (a column, index or table differs from the snapshot): the
  step is incomplete. Add the missing `addColumn` / `createIndex`. Do **not**
  regenerate the snapshot to match the code; the snapshot is the specification.
- **Data assertion failure**: the step ran but moved data wrongly. Fix the step.

If the mismatch is in a version that has already shipped, neither fix applies —
the correct move is a *new* version that repairs the damage forward.

## Fresh install and upgrade are two different tests

`onCreate` calls `createAll()` and produces the schema from today's `.drift`
files. `onUpgrade` produces it by accumulating steps. They can diverge — a
`createIndex` forgotten in the upgrade step gives new users the index and
existing users none, and every query still runs, just slower for half the
population. Assert both paths end at the same schema.
