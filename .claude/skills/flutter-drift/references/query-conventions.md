# Query conventions

## Why SQL lives in `.drift`

`drift_dev` parses `.drift` files at build time: it type-checks the SQL against
the schema, resolves nullability, and generates a typed API. A typo in a column
name is a build error. The same SQL in a Dart string is checked when a user runs
it.

That is the whole argument, and it has a corollary: **never assemble SQL by
concatenating strings.** Beyond the injection risk, a concatenated query is
invisible to the analyzer, to the stream-dependency tracker and to the next
reader. If a query genuinely varies, use Drift's `$predicate` / `$order`
placeholders, which are inlined as real SQL and composed from typed expressions
in Dart.

## File organisation

Tables in `tables/*.drift`, queries in `queries/*.drift`, one pair per bounded
area (`deck`, `card`, `tag`, `study`). A query file imports the table files it
reads:

```sql
import '../tables/cards.drift';
```

Two failure modes worth naming:

- **One `database.drift` with everything in it.** It grows to thousands of lines,
  the generated file grows with it, and the analyzer slows down for everyone.
- **The same SQL copied into two feature files.** Two definitions of "due" drift
  apart, and the bug is a screen that shows 23 while the session offers 21. If two
  features need the same predicate, one of them owns it and the other imports it.

## Formatting

```sql
-- The management list for one deck, newest first, bounded by the caller's window.
--
-- `created_at`, never `updated_at`: editing an old card would otherwise move it
-- to the top and take the reader's place in the list with it.
watchCardsByDeck:
SELECT
  card.id,
  card.deck_id,
  card.front,
  card.back,
  card.created_at
FROM cards AS card
WHERE card.deck_id = :deckId
ORDER BY
  card.created_at DESC,
  card.id DESC
LIMIT :limit;
```

- Keywords upper case, identifiers `snake_case`, generated name `lowerCamelCase`.
- One clause per line; one column per line once the list is long enough to scroll.
- Two-space indent, terminating `;` always.
- Aliases mean something: `card`, `deck`, `session` — not `a`, `b`, `t1`.
- Named parameters (`:deckId`, `:limit`), never positional or interpolated.
- Comments explain **why**, not what the syntax does. `-- select the cards` is
  noise; `-- DESC because a just-created card must appear first (UC-04 A4)` is the
  reason someone will need when they consider changing it.

## Naming a query for what it promises

The prefix is a contract with the caller. Keeping it honest is what lets a reader
know whether to handle `null` without opening the implementation.

| Prefix | Promise |
|---|---|
| `get…` | expected to exist; absence is an error the caller must handle |
| `find…` | may legitimately be absent; returns nullable |
| `list…` | one snapshot, `Future<List<T>>` |
| `watch…` | reactive stream, re-emits on change |
| `count…` | aggregate; must behave on an empty table |
| `exists…` | boolean; use `EXISTS`, not `COUNT(*) > 0` |
| `search…` | user-supplied input; expect a scan and say so |

Writes name the intent, not the table:

```
insertDeck            updateDeckName        archiveDeck
softDeleteDeck        restoreDeck           deleteDeckPermanently
upsertSyncMetadata
```

`updateDeck` taking twenty nullable parameters is a use case that was never
identified. Split it by what the user actually did. `save` is banned outright —
it hides whether the row is created, updated or both, which is exactly the fact a
reader needs.

## `SELECT` rules

- **List columns explicitly** for anything that feeds a projection or crosses a
  layer. `SELECT *` is fine for one whole table when the row class *is* the
  result; in a join it is ambiguous the moment either table gains a column.
- In Drift, prefer `table.**` in joins — it maps each star to its own row class
  and keeps the existing mappers usable, where a flat select needs a hand-written
  result class that duplicates both.
- **Qualify every column in a join**, and alias any name that appears twice.
- **Every list query that reaches the UI has `ORDER BY`.** SQLite's default order
  is not defined and changes with the query plan; a list that reorders itself
  after an unrelated index is added is a bug nobody will reproduce.
- **`ORDER BY` ends in a unique tie-breaker**, normally `id`. Without it, two rows
  sharing a timestamp can swap places between reads — which looks like flicker in
  a list and like a duplicate/missing row in a paginated one.
- **Never `LIMIT` without `ORDER BY`.** "The first 50" is meaningless until
  "first" is defined.
- Aggregates must handle the empty table: `SUM` returns `NULL`, not `0`. Coalesce
  in SQL or default in Dart, but do it deliberately.
- Do not select large `BLOB`/`JSON` columns a screen does not render — they are
  read, decoded and thrown away on every re-emission of the stream.
- Prefer `EXISTS` to `COUNT(*)` when the question is yes/no; it stops at the first
  match.
- Prefer `NOT EXISTS` to `NOT IN` when the subquery can produce `NULL` — `NOT IN`
  against a set containing `NULL` yields `NULL`, and the row silently disappears
  from the result.
- Watch correlated subqueries in list queries: one that runs per row is an N+1
  inside a single statement. It is sometimes the right trade (a `GROUP_CONCAT` of
  tag names avoids a read per row and keeps the stream dependency), but it should
  be a decision, with the row count in mind.

## Pagination

This project's default is the **growing `LIMIT` window** described in
`project-baseline.md`. Use it unless a flow seeks deep without reading what comes
before it.

When keyset pagination is the right answer, the shape is:

```sql
listCardsAfterCursor:
SELECT card.id, card.deck_id, card.front, card.created_at
FROM cards AS card
WHERE card.deck_id = :deckId
  AND (
    card.created_at > :cursorCreatedAt
    OR (card.created_at = :cursorCreatedAt AND card.id > :cursorId)
  )
ORDER BY card.created_at ASC, card.id ASC
LIMIT :limit;
```

Three things make it correct, and all three are easy to omit:

1. The cursor carries **every** column in the `ORDER BY`, or rows with equal
   timestamps are skipped or repeated.
2. The ordering is deterministic — same tie-breaker rule as above.
3. A composite index matches the ordering, or the "seek" is a full sort with a lid
   on it.

Never paginate by the index of an item in a UI list: inserts and deletes shift it
under the reader.

## Designing an index from a query

Order the columns by how the query uses them:

1. columns compared with `=`
2. one range column (`<`, `>`, `BETWEEN`)
3. columns in `ORDER BY`

SQLite uses a multi-column index left-to-right, so `(deck_id, created_at, id)`
serves `WHERE deck_id = ? ORDER BY created_at, id` **and** every lookup a plain
`(deck_id)` index would serve. Keeping both is pure cost: two B-trees maintained
on every insert, one of them redundant.

- **Do not create an index without a query you can name.** Write the query in the
  index's comment, as `cards.drift` does.
- **Verify with `EXPLAIN QUERY PLAN`** before claiming a speed-up. The signal to
  hunt is `USE TEMP B-TREE FOR ORDER BY` — it means SQLite read everything and
  sorted it, and any `LIMIT` was applied after the work was already done.
- A **partial index** is worth it when the filtered subset is much smaller than
  the table (`WHERE deleted_at IS NULL`, `WHERE is_suspended = 0`).
- A `UNIQUE` constraint already creates an index — do not add a second one on the
  same columns.
- After adding or changing indexes, `PRAGMA optimize` on a long-lived connection
  lets SQLite refresh its statistics.

Record the measurement in the PR. "Faster" without a number is how an index that
does nothing survives three refactors.
