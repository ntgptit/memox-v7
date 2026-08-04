# Dynamic SQL

One sentence carries the whole design:

> Dynamic SQL means **composing query structure through a type-safe API**, never
> concatenating SQL text.

Anything built by string interpolation loses all three things this project relies
on at once — compile-time checking, automatic stream dependencies, and safety
against whatever the user typed into a search box.

## Two things called "dynamic", only one of which is a decision

**A dynamic value** is a fixed query with a bound parameter:

```sql
SELECT * FROM cards WHERE deck_id = :deckId;
```

Nothing to design here. Bind it and move on.

**A dynamic structure** is a query whose *shape* changes: a filter that may or may
not apply, a sort the user picks, an optional join, a different projection. That
is what the rest of this file is about — and the shape has to come from a closed
set you control, not from a string that arrives from the UI.

## Pick the lowest level that works

| Level | Use | When |
|---|---|---|
| 1 | Static named query in `.drift` | The shape is fixed. Always prefer this |
| 2 | Dart template in `.drift` — `$predicate`, `$order`, `$limit` | The `WHERE`/`ORDER BY`/`LIMIT` varies but the `SELECT`, the joins and the result type do not |
| 3 | Dart query builder in the DAO | The structure varies too much for one statement to express honestly |
| 4 | `customSelect` / `customUpdate` | Drift cannot express the SQL at all |

**Level 2 is this project's default for a varying query**, because it keeps the
statement — the projection, the joins, the tag `GROUP_CONCAT` — in SQL where
`drift_dev` still type-checks it, while letting Dart decide the filter.
`cardListItems` in `lib/core/database/queries/card.drift` is the worked example:

```sql
cardListItems:
SELECT c.**, s.**, ( … ) AS tag_names
FROM cards c
INNER JOIN card_review_states s ON s.card_id = c.id
WHERE $predicate
ORDER BY $order
LIMIT :limit;
```

Drift inlines `$predicate` as real SQL, so `all` emits `c.deck_id = ?` and
`flagged` emits `c.deck_id = ? AND c.is_flagged = 1` — the same text separate
statements would have emitted, and the same query plan. A template can also
declare a default (`$predicate = TRUE`) for callers that pass nothing.

Level 4 is a last resort, and it costs you the two things Drift was doing for
free: you must declare `readsFrom` on a read and `updates` on a write, or the
streams that should react go silent. See `riverpod-drift.md`.

## Compose predicates; never build a catch-all

The tempting shape is one statement that covers every combination:

```sql
-- Don't.
WHERE (:deckId IS NULL OR deck_id = :deckId)
  AND (:status IS NULL OR status = :status)
  AND (:fromDate IS NULL OR created_at >= :fromDate)
```

It reads as less duplication and costs the index: SQLite decides index usage per
`WHERE` term, and an `OR` chain is optimisable only in specific shapes. With ten
optional filters it is also a single condition block nobody can reason about.
This project rejected exactly that chain in `card_list_query_mapper.dart` — the
comment there records why.

Compose instead: **a filter that is not applied contributes no SQL.**

```dart
final predicates = <Expression<bool>>[
  _deckPredicate(criteria.deckId),
  _statusPredicate(criteria.statuses),
  _createdPredicate(criteria.createdFrom, criteria.createdTo),
].nonNulls.toList();

if (predicates.isNotEmpty) query.where((_) => Expression.and(predicates));
```

Each builder is a small pure function returning `Expression<bool>?` — null when
the filter is absent. Pure means: no database access, no mutation, no knowledge
of the UI. That is what makes them unit-testable one at a time, and it is what
lets a list and its count share one definition of "due" instead of two copies
that drift apart. `card_list_query_mapper.dart` names each rule after the
business rule it implements (`dueNowPredicate` — BR-22, `isNewPredicate` —
BR-90), which is why the pill count and the list it opens can never disagree.

## Values are bound; structure comes from an enum

```dart
cards.deckId.equals(deckId);                  // value → bound
cards.status.isIn(codes);                     // values → bound
Variable<String>(term.toLowerCase());         // value → bound
```

```dart
// Both wrong, and the second is wrong even with no user input in sight.
customSelect("SELECT * FROM cards WHERE deck_id = '$deckId'");
final sql = 'SELECT * FROM cards ORDER BY ${criteria.sortColumn}';
```

Parameter binding works for **values only**. A table name, a column name,
`ASC`/`DESC`, an operator or a whole clause cannot be bound — which means every
one of them must come from a closed set defined in Dart. If a column name can
reach SQL from outside the app, so can anything else.

So: **sorting is an enum, never a string.**

```dart
OrderBy cardListOrder(CardListSort sort, Cards c, CardReviewStates s) =>
    switch (sort) {
      CardListSort.newest => OrderBy([
        OrderingTerm.desc(c.createdAt),
        OrderingTerm.desc(c.id),          // tie-breaker, always
      ]),
      CardListSort.dueFirst => OrderBy([
        OrderingTerm.asc(s.dueAt),
        OrderingTerm.desc(c.createdAt),
        OrderingTerm.desc(c.id),
      ]),
    };
```

The exhaustive `switch` is the point: adding a sort is a compile error until it
is mapped, and the UI has no way to express a sort that does not exist. Rules
that come with it:

- Every sort ends in a unique tie-breaker.
- A cursor must carry **every** column in the ordering it pages through.
- Changing the sort invalidates the cursor and the window — see the window-reset
  behaviour in `card_list_filter_controller.dart`.
- Every sort a user can pick should have an index that serves it, or it is a full
  sort wearing a `LIMIT`.

## Pass a criteria object, not a parameter list

Once a query takes more than three or four optional inputs, the signature stops
being readable and every layer it crosses repeats it:

```dart
// Hard to read, easy to transpose two arguments, and repeated at every layer.
watchCards(String deckId, {int limit, CardListFilter filter, CardListSort sort,
           String? searchTerm, DateTime? now});
```

An immutable criteria object with explicit defaults collapses that to one
argument and gives the combination a name and a place to be validated:

```dart
final class CardListCriteria {
  const CardListCriteria({
    required this.deckId,
    this.filter = CardListFilter.all,
    this.sort = CardListSort.newest,
    this.searchTerm,
    this.now,
    this.limit = kCardWindowSize,
  });
  …
}
```

What a criteria object must not contain: an `Expression`, a Drift table or
column, or a column name that came from the UI. It describes *what the user
asked for* in domain vocabulary; turning that into SQL is the DAO's job and
happens in one place.

**Where this project stands:** the card list read threads six parameters through
DAO → data source → repository → use case (`watchCardListItems`). It works and it
is typed, but it is at the size where the criteria object starts paying for
itself — particularly `now`, which is required only for one filter value and is
enforced with a runtime `ArgumentError` today. A criteria object could make that
combination unrepresentable instead of merely checked. Treat this as a refactor
worth proposing, not as a rule the existing code violates.

## Decide what an empty collection means

`statuses = {}` has two defensible readings — "do not filter by status" and
"match nothing" — and letting it fall through to `IN ()` picks one by accident.
State the choice in code:

```dart
// This project's convention: an empty filter is no filter.
if (statuses.isEmpty) return null;
return cards.status.isIn(statuses.map((s) => s.code));
```

The same question applies to a blank search term, and the card list answers it
explicitly: `if (term.isEmpty) return predicate` — an empty box narrows nothing.

## Dynamic filters, stable shape

The boundary that keeps dynamic SQL maintainable:

> **Filters may vary. The result shape, the join graph and write commands should
> not.**

**Do not make the projection dynamic.** A query with `includeDeck`,
`includeStatistics`, `includeHistory` flags has an unstable result type, unclear
stream dependencies, and a query plan that changes per call. Write separate read
models instead — `watchCardsByDeck`, `watchCardListItems`,
`cardStateCountsByDeck` are four statements here precisely because they answer
four questions. A varying *result shape* is the signal to split the query, where
a varying *filter* is not.

**Do not make joins optional to reuse one query.** Fix the join graph per read
model and vary only the predicate over the tables already joined. When the
question is merely "does a related row exist", use `existsQuery` rather than a
join — a join for existence multiplies rows and then needs a `DISTINCT` to undo
the damage.

**Do not make writes dynamic.** `updateFlashcard(String id, Map<String, dynamic>
fields)` cannot enforce which fields may change together, cannot be audited, and
cannot be type-checked. Name the command instead — `updateCardContent`,
`archiveCard`, `setCardFlag` — and write the specific columns. `setCardFlag` in
`card_dao.dart` writes exactly one column with a comment explaining that a
whole-row `Companion` would let a caller change `front` while meaning to toggle a
mark.

## Search is not a filter

`front LIKE 'abc%'` is a filter. "Contains the keyword, in either side, ignoring
case, ranked by relevance" is a different feature, and growing the same dynamic
`WHERE` to hold it is how one query ends up serving two jobs badly.

Keep `searchX` and `listX` separate. Note that a leading wildcard (`%keyword%`)
can never use an index — this project accepts the scan because the deck predicate
has already narrowed it, and uses `instr()` rather than `LIKE` so that `%` typed
by a user is an ordinary character. If search ever needs ranking or diacritic
folding at scale, that is FTS5, not a longer `WHERE`.

## Bound the combinations you support

Ten optional filters is 1,024 combinations; you cannot index them all, so decide
which ones exist:

- **Leading filters** shape the indexes — here, `deck_id` and the due predicate.
- **Secondary filters** apply after the set is already small.
- **Unsupported combinations** are refused at the contract, not silently served
  by a slow plan.

Design indexes from the query shapes you actually allow, in the order
equality → range → sort. One "super index" over every filter column does not
serve them all: SQLite uses a composite index left-to-right and generally stops
using later columns as equality constraints once a range condition is hit.

Good dynamic SQL supports the combinations someone chose. Not every combination.

## Then read the semantics rules

Everything above makes a dynamic query *safe and type-checked*. It does not stop
it from being **wrong**: a nullable filter that means two things, a `BETWEEN` that
drops the last millisecond of a day, a case-insensitive search that is only
case-insensitive for ASCII, a cursor reused across a different sort, or a
mandatory scope somebody forgot to pass.

`dynamic-sql-semantics.md` holds those as DYN-01…DYN-10, with the failure each one
prevents. Read it before shipping a query whose shape a user can change.

## Review checklist

- [ ] Criteria are immutable, with explicit defaults, carrying no Drift types.
- [ ] No table or column name arrives from the UI; no interpolation into SQL.
- [ ] Values are bound — `Variable`, or a typed Drift expression.
- [ ] An absent filter contributes no SQL; no `(:x IS NULL OR col = :x)` chains.
- [ ] Sorting comes from an enum with an exhaustive `switch`, every branch ending
      in a tie-breaker.
- [ ] Cursor fields match the ordering exactly.
- [ ] Empty-collection semantics stated in code.
- [ ] Result shape and join graph are fixed per read model; only filters vary.
- [ ] Writes are named commands over specific columns.
- [ ] `customSelect` declares `readsFrom`; `customUpdate` declares `updates`;
      `CustomExpression` holds a constant fragment and no user input.
- [ ] Every query has a `LIMIT`, or a stated reason it cannot.
- [ ] Tests: each filter alone, each sort, the main combinations, empty criteria,
      and pagination that neither duplicates nor drops a row.
- [ ] `EXPLAIN QUERY PLAN` checked for the combinations that matter.
