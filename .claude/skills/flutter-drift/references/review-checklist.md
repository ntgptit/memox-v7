# Reviewing a database change

Run `scripts/check_drift.sh` first — it decides everything decidable by reading
the source, so the review can be about design. What follows is the judgement half.

## Reject on sight

These are not style opinions. Each one has a failure mode that shows up in
production and not in the diff.

**Boundary**

- A widget or controller calling `database.select(...)`, a DAO, or importing
  `package:drift`.
- A repository returning a Drift-generated row, a `Companion`, or a `Selectable`.
- A domain entity carrying a Drift annotation, or a domain file importing
  `core/database`.
- SQL strings scattered through Dart instead of `.drift` files.
- A transaction started from presentation, or a transaction object passed upward.
- Any file other than `connection.dart` opening a database in `lib/`.
- A second `AppDatabase` instance, or a database provider made `family` or
  `autoDispose`.

**Correctness**

- A list query with no `ORDER BY`, or `LIMIT` without one.
- `ORDER BY` with no unique tie-breaker under a `LIMIT`.
- `customSelect` without `readsFrom`, or a raw write that does not declare the
  tables it changes — the stream goes quiet and the UI shows stale data.
- An enum persisted as an ordinal.
- A local `DateTime.now()` used as a stored instant, or a non-UTC value stored.
- Mixed epoch seconds and milliseconds.
- A constraint the code relies on that exists only in a form validator.
- `NOT IN` against a subquery that can yield `NULL`.
- A `catch` that swallows a database exception and returns an empty list — the
  screen then shows "no cards" for what is actually a failure.

**Migration**

- `.drift` changed and `schemaVersion` not bumped.
- `schemaVersion` bumped with no committed snapshot for it.
- An already-released migration edited, "tidied", or squashed.
- `NOT NULL` / `UNIQUE` / `CHECK` added with no backfill or duplicate check.
- Application queries called inside a migration step.
- Seed data written in `onUpgrade` rather than `onCreate`.
- Migration "tested" by deleting the app and reinstalling.

**Performance**

- A new index with no query named in its comment.
- `COUNT(*) OVER ()` beside a `LIMIT`.
- A loop of inserts where a batch belongs.
- A network call inside a transaction.
- A correlated subquery in a list query, with no thought about row count.
- Selecting large `BLOB`/`JSON` columns a screen never renders.

## Questions the diff cannot answer

Ask these; they are where the real defects hide.

1. **What happens to rows that already exist?** Every new constraint and every new
   `NOT NULL` has a population it was not designed for.
2. **Which query does this index serve?** If nobody can name it, it is cost with
   no benefit.
3. **Does the stream re-emit for every write that should change this screen?**
   Including writes made by another feature.
4. **Is this one atomic write or several?** If several statements must all land or
   none, is that actually a transaction?
5. **What does the UI show when this read fails?** `noAutomaticRetry` providers
   need an error state with a way out, or the screen is a dead end.
6. **If the backend landed tomorrow, would this need to change?** Client-generated
   IDs, UTC timestamps and stable enum codes are what make the answer "no".
7. **Does a fresh install produce the same schema as an upgrade?** Answer it by
   asserting it, not by reasoning about it.

## Definition of Done for a database PR

Merge only when all of these are true. The first block is about the change, the
second about the evidence.

**The change**

- [ ] The schema change has a stated business reason, referencing a BR or UC.
- [ ] Table and column names follow the conventions; no UI names, no ambiguous
      abbreviations.
- [ ] Every nullable column has a documented meaning for `NULL`.
- [ ] Every relationship has a foreign key with a deliberately chosen
      `ON DELETE`.
- [ ] Business invariants are expressed as `UNIQUE` / `CHECK` where SQLite can
      hold them, and as an invariant test where it cannot.
- [ ] Enums stored as stable text codes; timestamps stored in UTC.
- [ ] Every list query has deterministic ordering with a tie-breaker.
- [ ] Each new index names the query it serves and the measurement that justifies
      it.
- [ ] No Drift type crosses the repository boundary.

**The evidence**

- [ ] `schemaVersion` bumped and the snapshot committed.
- [ ] Migration step written; the released steps untouched.
- [ ] Migration test upgrades from **every** supported version to current.
- [ ] Data-integrity test asserts values, not just row counts.
- [ ] `PRAGMA integrity_check` returns `ok`; `PRAGMA foreign_key_check` returns
      nothing.
- [ ] Fresh install and upgrade end at the same schema.
- [ ] DAO / repository / mapper tests pass, including constraint violations
      mapping to the right `Failure`.
- [ ] Stream invalidation tested for insert, update and delete.
- [ ] `bash .claude/skills/flutter-drift/scripts/check_drift.sh` clean.
- [ ] `dart format`, `flutter analyze` (zero errors *and* warnings),
      `flutter test` all pass.
- [ ] Generated code regenerated and committed — no diff after a fresh
      `build_runner build`.
- [ ] `docs/data-model.md` and `docs/wbs.md` updated in the same commit.

## Writing up findings

Order by cost of being wrong: data loss → correctness → boundary → performance →
convention. For each finding give the failure scenario, not just the rule: "a
deck deleted while a session is open leaves review states behind, because this
foreign key has no `ON DELETE`" travels further than "missing ON DELETE".

If a finding is a genuine design trade rather than a defect, say so and state
both sides. A review that files every deviation as a bug trains people to ignore
the review.
