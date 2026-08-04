# Dynamic SQL: semantics, limits and consistency

`dynamic-sql.md` covers *how* to compose a query safely — bind values, take
structure from enums, prefer `$predicate` over string building. This file covers
what goes wrong **after** the query is safe and type-checked: conditions that
mean two things, text that does not compare the way you assumed, results that
disagree with their own count, and pages that lose rows.

Ten rules, each with an ID so a review finding can cite it the way it cites a
BR.

| ID | Rule |
|---|---|
| DYN-01 | A nullable parameter must not mean both "no filter" and "IS NULL" |
| DYN-02 | Complex boolean logic is an expression tree with bounded depth, not a flat list |
| DYN-03 | Timestamp ranges are half-open `[from, to)` |
| DYN-04 | Literal search and full-text expression are two APIs |
| DYN-05 | Unicode folding, collation and tokenizer are a written contract |
| DYN-06 | Every dynamic query obeys a query budget |
| DYN-07 | A cursor carries the query, filter and sort it was issued for |
| DYN-08 | Mandatory scope is never an optional filter |
| DYN-09 | Criteria are canonicalised before a query is built |
| DYN-10 | Dynamic writes state their conflict and concurrency semantics |

---

## DYN-01 · One parameter, one meaning

`String? deckId` can mean three different things, and the type cannot tell you
which: *do not filter*, *find rows where `deck_id IS NULL`*, or *the filter has
not been initialised yet*. SQL makes the distinction real — SQLite evaluates
three-valued logic, and `col = NULL` is never true, so "no filter" and "is null"
produce completely different result sets.

When a column is genuinely nullable and both meanings are reachable, model the
filter instead of the value:

```dart
sealed class FilterValue<T> { const FilterValue(); }
final class AnyValue<T>    extends FilterValue<T> { const AnyValue(); }
final class EqualsValue<T> extends FilterValue<T> { const EqualsValue(this.value); final T value; }
final class IsNullValue<T> extends FilterValue<T> { const IsNullValue(); }

Expression<bool>? deckFilter(FilterValue<String> filter) => switch (filter) {
  AnyValue()                  => null,                       // contributes no SQL
  EqualsValue(:final value)   => cards.deckId.equals(value),
  IsNullValue()               => cards.deckId.isNull(),
};
```

Where only one meaning exists, a nullable parameter is fine — but say so in the
signature's documentation, because the next person will assume the other one.

This project already relies on the distinction in the read direction:
`dueNowPredicate` is `due_at IS NULL OR due_at <= :now`, because a never-scheduled
card is due. Null there is a *state*, not an absent filter.

The related smell, and this repo has one: a parameter that is only meaningful in
combination with another. `watchCardListItems(..., DateTime? now)` requires `now`
when the filter is `dueNow` and rejects it at runtime with an `ArgumentError`
otherwise. A criteria object can make that unrepresentable rather than checked —
see the criteria section of `dynamic-sql.md`.

## DYN-02 · Boolean structure is a tree

A flat `List<Expression<bool>>` joined with `AND` covers most filters, and when
it stops covering them the temptation is to bolt an `OR` into one element and
move on. That is where precedence bugs live: SQLite gives `NOT`, `AND`, `OR`,
`BETWEEN`, `IN` and `COLLATE` different precedences, so a query that parses fine
can mean something other than it looks like.

If real disjunction is needed, model it:

```dart
sealed class FilterNode { const FilterNode(); }
final class AndNode extends FilterNode { const AndNode(this.children); final List<FilterNode> children; }
final class OrNode  extends FilterNode { const OrNode(this.children);  final List<FilterNode> children; }
final class NotNode extends FilterNode { const NotNode(this.child);    final FilterNode child; }
```

- Group explicitly; never rely on implicit precedence.
- Drop empty groups; collapse single-child groups.
- Bound the depth (DYN-06).
- Do not allow `NOT` over arbitrary predicates — negating a nullable comparison
  rarely means what the user expects.
- **The UI never submits a tree.** The application builds nodes from a
  whitelist of business-meaningful filters; a free-form predicate tree from the
  client is a query language, and a query language is an attack surface plus an
  unbounded performance liability.

## DYN-03 · Half-open time ranges

Use `created_at >= :from AND created_at < :to`, not `BETWEEN :from AND :to`.

```dart
final from = DateTime.utc(2026, 8, 4);
final to   = DateTime.utc(2026, 8, 5);          // exclusive
cards.createdAt.isBiggerOrEqualValue(from) & cards.createdAt.isSmallerThanValue(to);
```

`BETWEEN` is inclusive on both ends, so "all of 4 August" becomes a hunt for
`23:59:59.999` — and whether that is milliseconds, microseconds or seconds
depends on the storage mode, which means the boundary row is included on one
platform and dropped on another. Half-open ranges also tile: consecutive periods
never overlap and never leave a gap, which is what makes day → week → month a
change of arguments rather than a change of logic.

Boundary inclusivity is a decision to make once and write down, not per query.
This repo made it for the due boundary: a card due exactly at `:now` counts as
due, so the *next* due instant is `MIN(due_at) WHERE due_at > :now` — strictly
greater, or the "next" card is one that is already waiting.

## DYN-04 · Literal search is not query syntax

`100%` typed into a search box means the characters `1 0 0 %`. `flutter AND
riverpod` typed into an FTS box means an operator expression. One API cannot
serve both without guessing, so make the caller say which:

```dart
sealed class SearchInput { const SearchInput(); }
final class LiteralSearch      extends SearchInput { const LiteralSearch(this.text); final String text; }
final class FullTextExpression extends SearchInput { const FullTextExpression(this.expression); final String expression; }
```

For literal search under `LIKE`, `%` and `_` must be escaped and the statement
needs an `ESCAPE` clause. This project sidesteps that entirely by using
`instr(haystack, needle) > 0`, which has no pattern language at all — every
character is itself and the term stays a bound variable. `%` and `100%` both have
tests.

Never pass a raw user string to `MATCH`. FTS5 parses it as an expression, so an
unbalanced quote is a runtime error and an operator the user did not mean to type
silently changes the results.

## DYN-05 · Folding is a contract, and this repo is inconsistent about it

**SQLite's `lower()` and `COLLATE NOCASE` fold ASCII only.** They do not touch
`Ê`, `Đ`, `Ô`, or anything else outside a–z. For an app whose content is Korean
and Vietnamese, that is not a detail.

This project already knows it. `tags.drift` says so in the schema, and stores a
`name_folded` column written by Dart's `toLowerCase()` — full Unicode folding at
write time — with the unique index on that column rather than on `name COLLATE
NOCASE`. `card_tag_dao_test.dart` inserts `Động từ` twice and requires the second
to fail; that test is what proved the point.

**Card search did not get the same treatment.** `searchPredicate` compares
`instr(lower(front), :term)` where the needle is lowered in Dart and the haystack
is lowered by SQLite:

| Side | Folded by | `CÔNG` becomes |
|---|---|---|
| needle (search term) | Dart `toLowerCase()` — full Unicode | `công` |
| haystack (stored text) | SQLite `lower()` — ASCII only | `cÔng` |

So a card stored as `CÔNG NGHỆ` cannot be found by typing `công nghệ`. Korean is
unaffected (no case), lowercase Vietnamese is unaffected, and uppercase
Vietnamese entries are not — which is why this survives casual testing. The fix
is the pattern the same repo already uses: fold once at write time into a
column and compare against that.

Whatever an app decides, decide it explicitly and write it down:

- Is search case-sensitive?
- Does `ê` match `e`? Does `Đ` match `D`?
- Is Korean matched by syllable or by jamo?
- Is text Unicode-normalised (NFC/NFD) before storage? Two visually identical
  strings can be different byte sequences, and only normalisation makes them
  compare equal.
- Is sorting by code point or by language rules?

Store a normalised column when the answer needs one. And treat the FTS5
tokenizer configuration as **part of the schema**: changing `unicode61` options,
`remove_diacritics` or the token characters changes what the index contains, so
it needs a migration and a test, not an edit.

## DYN-05a · Index collation must match the query

```sql
-- If the query says this…
ORDER BY name COLLATE NOCASE

-- …the index must say it too, or the index is not used.
CREATE INDEX idx_decks_name_nocase ON decks (name COLLATE NOCASE);
```

Collation affects comparison, equality, ordering, uniqueness *and* index
eligibility. A `BINARY` index does not serve a `NOCASE` query. The folded-column
approach avoids the whole question: the comparison is byte-for-byte, so an
ordinary index works.

## DYN-06 · Query budget

Ten optional filters is 1,024 shapes; a user with a paste buffer can make any of
them enormous. Bound them at the application boundary, well below whatever
SQLite's own limits happen to be on this build:

```dart
final class QueryBudget {
  static const maxPageSize      = 100;
  static const maxKeywordLength = 200;
  static const maxIds           = 500;   // IN-list size
  static const maxOrBranches    = 10;
  static const maxFilterDepth   = 4;
  static const maxSortTerms     = 3;
}
```

Relying on SQLite's parameter limit as the ceiling is a bug waiting for a
different build to expose it. Reject over-budget criteria at the boundary with a
typed failure — not by truncating silently, which produces a wrong answer that
looks right.

**Do not split an oversized `IN` list naively.** Running ten queries of 500 ids
and concatenating the results breaks global ordering, `LIMIT`, aggregates,
de-duplication and cursors all at once. The honest options: cap the id count,
merge properly after batching, put the ids in a temporary table and join, or —
usually best — change the use case so it queries by parent or filter instead of
by thousands of ids.

## DYN-06a · Row filters and aggregate filters are different

```sql
WHERE status = 'active'      -- before grouping
GROUP BY deck_id
HAVING COUNT(*) >= 10        -- after grouping
```

These belong to separate types in the API, because "count only active cards" and
"only decks with ten or more" are different questions and mixing them into one
`filters` list produces silently wrong numbers:

```dart
watchDeckStatistics(
  rowFilter: CardFilter(status: active),
  aggregateFilter: DeckAggregateFilter(minimumCardCount: 10),
);
```

## DYN-07 · A cursor belongs to its query

A cursor holding only `(createdAt, id)` is valid for exactly one ordering. Reuse
it after the sort, filter or search term changed and rows are skipped or
repeated. Bind it to its context:

```dart
final class CardCursor {
  const CardCursor({
    required this.queryVersion,   // bumped when the query shape changes in code
    required this.criteriaHash,   // fingerprint of the canonicalised criteria
    required this.sort,
    required this.createdAt,      // every column in the ORDER BY…
    required this.id,             // …including the tie-breaker
  });
}
```

A cursor whose `criteriaHash` or `sort` no longer matches must be **rejected**,
not silently used. This project gets the same property a different way: changing
the filter, the sort or the search term invalidates `cardListWindowProvider`, so
the window restarts rather than carrying a position into a different result set.

## DYN-07a · Decide what pagination promises when data changes

Keyset pagination is stable *within* a snapshot. Across separate queries there is
no snapshot: sort by `updated_at DESC`, load page 1, let a row on page 2 be
edited, and it can jump to the front — appearing twice or not at all. Pick a
contract and state it:

1. accept eventual consistency (fine for a management list);
2. restart from the top when the underlying data changes;
3. carry a `snapshotAt` in the cursor and filter `updated_at <= :snapshotAt`;
4. order only by immutable columns — which is why this project sorts by
   `created_at`, never `updated_at`: editing an old card would otherwise move it
   to the top and take the reader's place with it;
5. hold a long read transaction — almost never right on mobile.

## DYN-08 · Mandatory scope is not a filter

Some predicates are not optional: `deleted_at IS NULL`, `owner_id = :current`,
`workspace_id = :current`, any access-control condition. Exposing them as
criteria fields means every caller can forget one, and the one that forgets is a
data leak rather than a wrong list.

```dart
Expression<bool> mandatoryScope(QueryContext context) =>
    cards.deletedAt.isNull() & cards.ownerId.equals(context.ownerId);

final predicate = mandatoryScope(context) & optionalFilters(criteria);
```

Cases that legitimately need the scope removed get their **own named query** —
`watchDeletedCardsForRecovery`, not `includeDeleted: true`. A boolean that turns
an ordinary query into a privileged one is a boolean somebody will pass from a UI
state one day.

This matters here before auth exists: `owner_id` is nullable and unused today, so
when auth lands it must arrive as mandatory scope in one place, not as a criteria
field threaded through every read.

## DYN-09 · Canonicalise criteria first

Equivalent criteria must produce the same query — otherwise the cache key, the
cursor fingerprint and the logs all treat `""`, `"   "` and `null` as three
different searches.

```dart
CardListCriteria normalise(CardListCriteria input) {
  final keyword = input.keyword?.trim();
  return input.copyWith(
    keyword: (keyword == null || keyword.isEmpty) ? null : keyword,
    statuses: input.statuses.toSet(),
    limit: input.limit.clamp(1, QueryBudget.maxPageSize),
  );
}
```

Canonicalisation belongs in **one** place — trim text, absent-vs-empty, dedupe
collections, clamp page size, convert local time to UTC, normalise date ranges,
reject impossible ranges and unsupported combinations. Spread across predicate
builders, it stops being reproducible, and two callers that "look the same"
produce two different queries.

## DYN-09a · Query builders are pure functions

Same input, same query shape, same ordering, same parameters, same table
dependencies. A builder must not read `DateTime.now()`, a random source, a global,
the current locale, mutable provider state, or a feature flag mid-build. Pass
what it needs:

```dart
buildQuery(criteria: criteria, context: QueryContext(nowUtc: nowUtc, ownerId: ownerId));
```

`now` in particular: read the clock **once** per operation, at the use case, and
pass the instant down. Two predicates each calling `now()` are measured against
two different instants milliseconds apart — a difference that is invisible until
it puts a card on the wrong side of a due boundary. This project already routes
every "now" through `clockProvider` for exactly this reason, and forbids
`DateTime.now()` inside features.

Purity is also what makes a builder snapshot-testable and a production bug
reproducible from its criteria.

## DYN-10 · Dynamic writes state their semantics

**Concurrency.** A blind `UPDATE … WHERE id = :id` overwrites whatever changed
while the editor was open. Where that matters, make the update conditional:

```sql
UPDATE cards
SET front = :front, version = version + 1, updated_at = :updatedAt
WHERE id = :id AND version = :expectedVersion;
```

Then check the affected row count — zero means someone else wrote first, and that
is a `ConflictFailure`, not a success. This becomes essential the moment there is
background sync, autosave, import, or a second isolate. There is no `version`
column here yet; it is the natural place for one when sync arrives.

**Conflict target.** An upsert's conflict target is business semantics, not a
runtime option — SQLite fires `DO UPDATE` / `DO NOTHING` off a specific
uniqueness constraint. So write named upserts rather than a generic one taking
`conflictColumns`:

```
upsertCardById            conflict on the primary key
upsertTagByFoldedName     conflict on (owner, name_folded) — find-or-create
```

Each one must answer: which unique key defines the conflict, which fields update,
which must never be overwritten (`created_at`, usually), how the version moves,
and whether a soft-deleted row is restored. `card_tags` here uses
`insertOrIgnore` because the pair *is* the primary key, so adding a tag twice is
a no-op rather than an error the repository must interpret.

## Observability for dynamic queries

Two calls to one method can produce very different SQL, so a log line naming only
the method hides the slow shape. Log a **fingerprint**, never the values:

```
query=watchCardListItems filters=deck,status,keyword,dateRange
sort=createdAtDesc pagination=window pageSize=50 durationMs=18 rows=50
```

Never log the keyword itself — it is card content, and content is private at
every level (AD-08). The fingerprint is what makes it possible to see which
combination is slow, which shape stopped using an index after a migration, and
which criteria return far more rows than a screen can use.

## What to pin with tests

Do not snapshot whole generated SQL — it breaks on every Drift upgrade and pins
nothing meaningful. Pin the properties instead:

- [ ] Mandatory scope is present in every query that must carry it (DYN-08).
- [ ] Every sort ends in a tie-breaker, and the cursor predicate matches the sort
      direction (DYN-07).
- [ ] Empty criteria produce no `WHERE` beyond mandatory scope (DYN-09).
- [ ] Date ranges use `< to` (DYN-03).
- [ ] A literal search for `%` and `100%` matches literally (DYN-04).
- [ ] Uppercase and lowercase non-ASCII match according to the stated folding
      policy (DYN-05).
- [ ] "No filter" and "IS NULL" produce different result sets (DYN-01).
- [ ] Over-budget criteria are rejected, not truncated (DYN-06).
- [ ] Page size is always bounded.
- [ ] Aggregate conditions land in `HAVING`, row conditions in `WHERE` (DYN-06a).
- [ ] Count and rows are built from the same canonicalised criteria (DYN-09).
- [ ] `EXPLAIN QUERY PLAN` checked for the shapes that matter, on a fixture big
      enough for the planner to make a real choice.
